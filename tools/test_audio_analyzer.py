import importlib.util
import json
import math
from pathlib import Path
import socket
import tempfile
import threading
import unittest

spec = importlib.util.spec_from_file_location('audio_analyzer', Path(__file__).with_name('audio-analyzer.py'))
audio = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audio)


def tone(hz, amplitude=0.1):
    return [amplitude * math.sin(math.tau * hz * i / audio.RATE) for i in range(audio.SIZE)]


class SpectrumTests(unittest.TestCase):
    def test_silence_dc_and_invalid_samples(self):
        for value in (0.0, 0.8, float('nan'), float('inf')):
            self.assertEqual(audio.Spectrum().analyze([value] * audio.SIZE, 1), [0.0] * 64)

    def test_tone_position_and_gain(self):
        peaks = []
        for hz in (100, 1000, 10000):
            spectrum = audio.Spectrum()
            bands = spectrum.analyze(tone(hz), 1)
            index = max(range(64), key=bands.__getitem__)
            low, high = spectrum.bins[index]
            self.assertLessEqual(low, hz * audio.SIZE / audio.RATE + 1)
            self.assertGreaterEqual(high, hz * audio.SIZE / audio.RATE - 1)
            self.assertTrue(all(0 <= x <= 1 for x in bands))
            peaks.append(index)
        self.assertEqual(peaks, sorted(set(peaks)))
        quiet = max(audio.Spectrum().analyze(tone(1000, .005), 1))
        louder = max(audio.Spectrum(2).analyze(tone(1000, .005), 1))
        self.assertGreater(louder, quiet)

    def test_decay_and_capture_stall(self):
        spectrum = audio.Spectrum()
        peak = max(spectrum.analyze(tone(1000), 1))
        self.assertLess(max(spectrum.analyze([0.0] * audio.SIZE, .1)), peak)
        self.assertEqual(spectrum.analyze(None, .033), [0.0] * 64)


class FeedTests(unittest.TestCase):
    def exchange(self, replies):
        with tempfile.TemporaryDirectory(prefix='audio-test-') as directory:
            path = str(Path(directory) / 'ipc.sock')
            received, errors = [], []
            with socket.socket(socket.AF_UNIX) as server:
                server.bind(path)
                server.listen(1)
                server.settimeout(2)

                def serve():
                    try:
                        for fragments in replies:
                            connection, _ = server.accept()
                            with connection:
                                connection.settimeout(2)
                                stream = connection.makefile('rb')
                                try:
                                    packet = stream.readline(4097)
                                    self.assertLessEqual(len(packet), 4096)
                                    received.append(json.loads(packet))
                                    for part in fragments:
                                        connection.sendall(part)
                                finally:
                                    stream.close()
                    except Exception as error:
                        errors.append(error)

                worker = threading.Thread(target=serve)
                worker.start()
                feed = audio.Feed(path)
                try:
                    for fragments in replies:
                        if b''.join(fragments) == b'{"ok":true}\n':
                            feed.send([.25] * 64)
                        else:
                            with self.assertRaises((OSError, ValueError)):
                                feed.send([.25] * 64)
                        feed.close()
                finally:
                    feed.close()
                    worker.join(3)
                self.assertFalse(worker.is_alive())
                self.assertEqual(errors, [])
                self.assertEqual(received, [{'cmd': 'effect-audio', 'version': 2,
                                             'bands': [.25] * 64}] * len(replies))

    def test_fragmented_ack_and_reconnect(self):
        self.exchange([[b'{"ok":', b'true}\n'], [b'{"ok":true}\n']])

    def test_rejection_and_disconnect(self):
        self.exchange([[b'{"err":"producer already active"}\n'], [], [b'{"ok":true}\n']])


if __name__ == '__main__':
    unittest.main()
