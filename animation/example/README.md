# Example

A minimal opening effect that fades the window in while scaling from 96% to full size.

![Synthetic preview of Example](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session. It shows an intermediate frame, not the complete animation.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/animation/example/`. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/animation/example/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "example"
duration_ms = 250
curve = "easeout"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

Animation selectors are global for the chosen event; per-application animation assignment is not available in this API. Adjust `duration_ms` to change the timing.

## Colours and tuning

Colours are defined in `shader.glsl`. Setting `palette = true` alone will not recolour a shader that does not read the palette. Edit its colour constants to customise it.

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. It runs while the selected transition is active. No performance benchmark is claimed.

## Attribution

Original example by Lemmy, retained from this repository. The original contribution did not specify a license; this change does not relicense its shader.
