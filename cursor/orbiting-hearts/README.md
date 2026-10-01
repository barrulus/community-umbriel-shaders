# Orbiting Hearts

Six small hearts share an evenly spaced orbit around the pointer.

![Synthetic preview of Orbiting Hearts](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/cursor/orbiting-hearts/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/cursor/orbiting-hearts/effect.toml"]

[effects]
cursor = "cursor.orbiting-hearts"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

The preset uses `radius = 64` logical pixels around the pointer.

## Configuration options

Edit the existing `[effects.preset."cursor.orbiting-hearts"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"cursor"` | Keep this kind: the source implements its `cursor` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `false` | This source does not read the palette; enabling it alone does not recolour the effect. |
| `radius` | `64` | Half-size in logical pixels of the shaded square; 0 shades the whole output. This bounds drawing, not the artwork size; reducing it may clip the effect. Use the GLSL size controls below to resize it. |

There is no TOML `speed`, `animated`, or `opacity` setting for this kind.
Motion/strength changes are GLSL edits below.
Global `[effects] max_fps` limits effect-driven frames, and `in_capture`
controls inclusion in screencopy/image-copy captures. Neither resizes the artwork.

### Shader controls

Edit these values in [shader.glsl](shader.glsl), not in TOML. `#define` is
active GLSL code; comments use `//` or `/* ... */`. Start with small changes
and keep paired shaders in sync. Keep size and duration divisors positive.

| GLSL control or expression | Shipped value | Visual effect |
| --- | --- | --- |
| `orbit radius` | `43.0` | Logical pixels; lower brings hearts closer to the pointer. |
| `heart size` | `8.0` | Logical-pixel size before the heartbeat; lower makes smaller hearts. |
| `orbit speed` | `0.85` | Larger orbits faster. |
| `heartbeat frequency` | `1.35` | Larger beats faster. |
| `heart colours` | `the two vec3 values assigned to color` | Change the alternating pink/purple RGB colours. |
| `culling limits` | `58.0 overall / 11.0 per heart` | These bound drawing work, not size controls. If enlarging hearts/orbit, increase them as needed as well as the TOML radius. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a pass over its affected output area and prevents direct scanout while active. The shader contains loops; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
