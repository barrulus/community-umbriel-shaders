# Blood Sweep

![Synthetic preview of Blood Sweep Animation](preview.png)

Wave of blood sweeps across the screen during a workspace switch, covering the outgoing workspace and revealing the incoming one. Travels top to bottom when switching down and bottom to top when switching up. Companion to [Blood In](../blood-in/), [Blood Out](../blood-out/) and [Heartbeat border](../../border/heartbeat/)

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/animation/blood-sweep/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/animation/blood-sweep/effect.toml"]

[animation]
enabled = true

[animation.workspaces]
enabled = true
style = "reveal"
duration_ms = 700
effect = "blood-sweep"
curve = "linear"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

Animation selectors are global for the chosen event; per-application animation assignment is not available in this API. Adjust `duration_ms` to change the timing; a longer duration gives the drips more time to stretch and retract.

## Testing

Tested on Umbriel [`21456686a8f2`](https://github.com/noctalia-dev/umbriel/commit/21456686a8f21f82a0675cad658ffbeed35269b6) with NVIDIA and Intel GPUs.

## Compatibility and cost

Requires Umbriel's full-scene workspace reveal API, tested on `0.1.0 (21456686a8f2)`. See validation and limitations. No previous-frame feedback buffers are used. It runs while the selected transition is active. The shader samples both workspace scenes and contains a ten-iteration loop; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: WinterMyst. License:

MIT License

Copyright (c) 2026 WinterMyst

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Contributed by WinterMyst on 2026-10-10.
