# Contributor tools

## Standalone audio analyser

[`audio-analyzer.py`](audio-analyzer.py) captures PipeWire playback and sends
64 spectrum bands to Umbriel. Use it with an older Noctalia that lacks the
audio provider, or with another shell. Download that one script; it needs
**Python 3.11+ and `pw-record`** (PipeWire's command-line tools), with no pip
packages. It requires Umbriel's **version-2 spectrum protocol**, as shipped
at `76477c2`; it does not support the old single-level version-1 protocol.

```sh
python3 audio-analyzer.py --verbose
```

From this repository, use `python3 tools/audio-analyzer.py --verbose`.
Run it inside the Umbriel session and select an audio-reactive shader.
It captures the default output's playback monitor, not the microphone.
Audio is processed in memory and is not saved. Stop with **Ctrl+C**.
Only one provider can own Umbriel's feed: disable Noctalia's **Provide Audio
to Umbriel** setting if it is enabled before using this script.

```sh
# Stronger response for quiet playback
python3 audio-analyzer.py --gain 2

# Choose an output by its PipeWire node.name or object.serial
python3 audio-analyzer.py --target alsa_output.example --verbose

# Explicit compositor socket, if session environment variables are unavailable
python3 audio-analyzer.py --socket /run/user/1000/umbriel-wayland-0.sock
```

Use `wpctl status -n` and `wpctl inspect ID` to find an output's `node.name`
or `object.serial`; the numeric ID shown by `wpctl status` is not necessarily
its serial. `--target auto` delegates output selection to the PipeWire session
manager. Restart the script when changing outputs if capture does not follow.
`--fps 10` through `--fps 60` adjusts the analysis/send rate (default 30).

The analyser uses a 2,048-sample Hann-windowed FFT at 48 kHz, mono playback,
and 64 logarithmic bands covering approximately 40 Hz–16 kHz. Low bands share
FFT bins because frequency resolution is about 23 Hz. Intensities map -60 to
-6 dBFS into 0–1 with fast attack and slower decay; these are visual values,
not calibrated loudness or an exact match for Noctalia's analyser. Mono mixing
can reduce out-of-phase stereo content. The pure-Python FFT costs more CPU
than a native analyser; lower `--fps` if needed.

The script waits for acknowledgements, sends fresh snapshots during silence,
clears stalled capture, and retries disconnected or rejected feeds once per
second. A lock/unlock or compositor restart therefore does not require
restarting the script. `pw-record` failure exits with a diagnostic; fix the
capture source and rerun. `--verbose` reports capture activity, peak band
intensity and IPC connection status. A connected feed with a zero peak means
silence or the wrong output; a waiting feed reports the IPC error. The bundled
`audio` shader reads only the lowest band, so it can stay dim while higher
bands are active.

References: [PipeWire capture options](https://docs.pipewire.org/page_man_pw-cat_1.html),
[playback-monitor property](https://docs.pipewire.org/group__pw__keys.html),
and [Umbriel spectrum IPC](https://github.com/noctalia-dev/umbriel/blob/main/docs/user/ipc.md#audio-input).

The script is [MIT licensed](../LICENSES/Barrulus-MIT.txt).

## Configuration validation

```sh
python3 tools/validate.py
# Select a particular installed build:
python3 tools/validate.py --umbriel /path/to/umbriel
```

Checks all installation examples, unique preset names, dependencies and the
combined library without editing the user's configuration. It detects the
installed Umbriel validation command. This checks parsing and source loading;
compile and inspect selected shaders in a compositor session separately.

Include relevant commands and results in the PR description, and retain lasting
limitations in the shader's README. Local development logs, browser tooling and
audio-analyser tests are excluded from the tracked repository and checked by CI.
