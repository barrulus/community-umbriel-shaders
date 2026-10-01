# Adaptive Text V4

An experimental content-adaptive contrast treatment.

![Synthetic preview of Adaptive Text V4](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/window/adaptive-text-v4/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/window/adaptive-text-v4/effect.toml"]

[effects]
window = "window.adaptive-text-v4"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

## Configuration options

Edit the existing `[effects.preset."window.adaptive-text-v4"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"window"` | Keep this kind: the source implements its `window` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `false` | This source does not read the palette; enabling it alone does not recolour the effect. |

There is no TOML `speed`, `animated`, or `opacity` setting for this kind.
This shader is static; changing the frame cap does not animate it.
Global `[effects] max_fps` limits effect-driven frames, and `in_capture`
controls inclusion in screencopy/image-copy captures. Neither resizes the artwork.

### Shader controls

Edit these values in [shader.glsl](shader.glsl), not in TOML. `#define` is
active GLSL code; comments use `//` or `/* ... */`. Start with small changes
and keep paired shaders in sync. Keep size and duration divisors positive.

| GLSL control or expression | Shipped value | Visual effect |
| --- | --- | --- |
| `RADIUS` | `10.0` | Backdrop-estimation blur radius in buffer pixels; larger separates detail from broader background features. |
| `GAIN` | `2.2` | Amplification of strong detail; 1 leaves detail gain unchanged, larger values increase contrast. |
| `KNEE0` | `0.08` | Detail amplitude where amplification starts; raise it to avoid amplifying wallpaper texture. Keep below KNEE1. |
| `KNEE1` | `0.22` | Detail amplitude where full GAIN is reached; raise it for a more gradual gain ramp. Keep above KNEE0. |
| `DIM` | `0.65` | Brightness multiplier for a bright backdrop, 0–1; lower dims more, 1 disables backdrop dimming. |
| `DIMLO` | `0.30` | Backdrop luminance where dimming begins; raise it to leave more backgrounds untouched. Keep below DIMHI. |
| `DIMHI` | `0.65` | Backdrop luminance where full dimming is reached; keep above DIMLO. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a pass per affected window; applying it globally increases the cost with the number and size of visible windows. The shader contains loops; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
