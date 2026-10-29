#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Barrulus
"""Stream PipeWire playback spectrum to Umbriel. Python stdlib + pw-record."""

import argparse
from array import array
from collections import deque
import json
import math
import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time

RATE = 48000
SIZE = 2048
BANDS = 64
STALE = 0.2


class Spectrum:
    """Hann-windowed radix-2 FFT, with log-spaced visual bands."""

    def __init__(self, gain=1.0):
        self.gain = gain
        self.window = [0.5 - 0.5 * math.cos(math.tau * i / (SIZE - 1))
                       for i in range(SIZE)]
        self.scale = 2.0 / sum(self.window)
        bits = SIZE.bit_length() - 1
        self.order = [int(f'{i:0{bits}b}'[::-1], 2) for i in range(SIZE)]
        self.stages = []
        width = 2
        while width <= SIZE:
            roots = [complex(math.cos(-math.tau * i / width),
                             math.sin(-math.tau * i / width))
                     for i in range(width // 2)]
            self.stages.append((width, roots))
            width *= 2
        edges = [40.0 * (16000.0 / 40.0) ** (i / BANDS)
                 for i in range(BANDS + 1)]
        self.bins = [(max(1, int(low * SIZE / RATE)),
                      min(SIZE // 2, max(int(low * SIZE / RATE) + 1,
                                        math.ceil(high * SIZE / RATE))))
                     for low, high in zip(edges, edges[1:])]
        self.levels = [0.0] * BANDS

    def analyze(self, samples, elapsed):
        if samples is None:
            self.levels = [0.0] * BANDS
            return list(self.levels)
        clean = [x if math.isfinite(x) else 0.0 for x in samples]
        mean = sum(clean) / SIZE
        values = [complex((clean[i] - mean) * self.window[i]) for i in self.order]
        for width, roots in self.stages:
            half = width // 2
            for start in range(0, SIZE, width):
                for j, root in enumerate(roots):
                    even = values[start + j]
                    odd = root * values[start + j + half]
                    values[start + j] = even + odd
                    values[start + j + half] = even - odd
        magnitudes = [abs(x) * self.scale * self.gain for x in values[:SIZE // 2]]
        for i, (low, high) in enumerate(self.bins):
            amplitude = max(magnitudes[low:high])
            # -60 dBFS is dark; -6 dBFS reaches full visual intensity.
            target = max(0.0, min(1.0, (20 * math.log10(max(amplitude, 1e-12)) + 60) / 54))
            tau = 0.025 if target > self.levels[i] else 0.15
            self.levels[i] += (target - self.levels[i]) * (1 - math.exp(-elapsed / tau))
            if self.levels[i] < 1 / 255:
                self.levels[i] = 0.0
        return list(self.levels)


class Capture:
    def __init__(self, target):
        properties = json.dumps({'stream.capture.sink': True,
                                 'node.name': 'umbriel-python-analyzer',
                                 'application.name': 'Umbriel Python analyzer'})
        self.process = subprocess.Popen(
            ['pw-record', '--raw', '--format', 'f32', '--rate', str(RATE),
             '--channels', '1', '--latency', '20ms', '--target', target,
             '--properties', properties, '-'],
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE)
        self.samples = deque(maxlen=SIZE)
        self.updated = 0.0
        self.lock = threading.Lock()
        self.worker = threading.Thread(target=self.read, daemon=True)
        self.worker.start()

    def read(self):
        pending = b''
        while True:
            chunk = self.process.stdout.read(4096)
            if not chunk:
                return
            pending += chunk
            end = len(pending) // 4 * 4
            samples = array('f')
            samples.frombytes(pending[:end])
            pending = pending[end:]
            if not samples:
                continue
            with self.lock:
                now = time.monotonic()
                if now - self.updated > STALE:
                    self.samples.clear()
                self.samples.extend(samples)
                self.updated = now

    def snapshot(self):
        with self.lock:
            if time.monotonic() - self.updated > STALE or len(self.samples) < SIZE:
                return None
            return list(self.samples)

    def close(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        self.worker.join(timeout=2)
        self.process.stdout.close()


class Feed:
    def __init__(self, path):
        self.path = path
        self.sock = None

    def send(self, bands):
        if self.sock is None:
            self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            self.sock.settimeout(0.15)
            self.sock.connect(self.path)
        packet = {'cmd': 'effect-audio', 'version': 2,
                  'bands': [round(x, 5) for x in bands]}
        self.sock.sendall((json.dumps(packet, separators=(',', ':'), allow_nan=False) + '\n').encode())
        reply = bytearray()
        deadline = time.monotonic() + 0.15
        while not reply.endswith(b'\n'):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('audio acknowledgement timed out')
            self.sock.settimeout(remaining)
            chunk = self.sock.recv(4096 - len(reply))
            if not chunk:
                raise ConnectionError('audio connection closed')
            reply.extend(chunk)
            if len(reply) >= 4096:
                raise ConnectionError('oversized audio acknowledgement')
        self.sock.settimeout(0.15)
        result = json.loads(reply)
        if result != {'ok': True}:
            raise ConnectionError(str(result.get('err', result)) if isinstance(result, dict) else str(result))

    def close(self):
        if self.sock is not None:
            self.sock.close()
            self.sock = None


def positive(value):
    number = float(value)
    if not math.isfinite(number) or not 0 < number <= 100:
        raise argparse.ArgumentTypeError('must be greater than 0 and at most 100')
    return number


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', default='auto', help='PipeWire output node name or object.serial (default: default output)')
    parser.add_argument('--socket', help='Umbriel socket (default: UMBRIEL_SOCKET, then XDG_RUNTIME_DIR/umbriel-WAYLAND_DISPLAY.sock)')
    parser.add_argument('--gain', type=positive, default=1.0, help='amplitude gain (default: 1; try 2 for quiet audio)')
    parser.add_argument('--fps', type=int, choices=range(10, 61), metavar='10..60', default=30, help='analysis/send rate (default: 30)')
    parser.add_argument('--verbose', action='store_true', help='print capture status and peak band intensity every two seconds')
    args = parser.parse_args()
    if not shutil.which('pw-record'):
        parser.error('pw-record is required; install your distribution\'s PipeWire command-line tools')
    path = args.socket or os.environ.get('UMBRIEL_SOCKET')
    if not path:
        runtime, display = os.environ.get('XDG_RUNTIME_DIR'), os.environ.get('WAYLAND_DISPLAY')
        if not runtime or not display:
            parser.error('run inside Umbriel or supply --socket')
        path = str(Path(runtime) / f'umbriel-{display}.sock')
    stop = threading.Event()
    for signum in (signal.SIGINT, signal.SIGTERM):
        signal.signal(signum, lambda *_: stop.set())
    capture = Capture(args.target)
    feed, spectrum = Feed(path), Spectrum(args.gain)
    previous = time.monotonic()
    retry_at = report_at = 0.0
    last_error = None
    print(f'Capturing playback ({args.target}); sending 64 bands to {path}. Ctrl+C stops.', file=sys.stderr)
    try:
        while not stop.is_set():
            now = time.monotonic()
            if capture.process.poll() is not None:
                raise RuntimeError(f'pw-record exited ({capture.process.returncode}); check PipeWire and --target')
            samples = capture.snapshot()
            bands = spectrum.analyze(samples, max(0.001, now - previous))
            previous = now
            if now >= retry_at:
                try:
                    feed.send(bands)
                    if last_error is not None:
                        print('Audio feed connected.', file=sys.stderr)
                    last_error = None
                except (OSError, ValueError) as error:
                    feed.close()
                    message = str(error)
                    if message != last_error:
                        print(f'Audio feed unavailable: {message}. Retrying; disable any other audio provider.', file=sys.stderr)
                    last_error = message
                    retry_at = time.monotonic() + 1.0
            if args.verbose and now >= report_at:
                print(f'capture={"active" if samples is not None else "idle"} peak={max(bands):.3f} feed={"connected" if feed.sock else "waiting"}', file=sys.stderr)
                report_at = now + 2
            # Leave a full interval between completed sends: analysis/IPC delays
            # must never cause catch-up bursts above Umbriel's 60 Hz limit.
            stop.wait(1 / args.fps)
    finally:
        feed.close()
        capture.close()


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError) as error:
        print(f'error: {error}', file=sys.stderr)
        sys.exit(1)
