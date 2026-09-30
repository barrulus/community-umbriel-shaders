# Blood In

Wave or blood reveals the window top to bottom. Companion to [Blood Out](../bloodOut/) and [Heartbeat border](../../border/heartbeat/)

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/animation/bloodIn/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/animation/bloodIn/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "blood-drip-in"
duration_ms = 700

```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

Animation selectors are global for the chosen event; per-application animation assignment is not available in this API. Adjust `duration_ms` to change the timing.

## Colours and tuning

Colours are defined in `shader.glsl`. Number of wave peaks can also be adjusted in `shader.glsl`

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. It runs while the selected transition is active. The shader contains loops; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: WinterMyst. License: [MIT](../../LICENSES/WinterMyst-MIT.txt).

