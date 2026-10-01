# Solar System

Five planets, rings, and orbiting moons surround a small sun at the pointer.

![Synthetic preview of Solar System](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/cursor/solar-system/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/cursor/solar-system/effect.toml"]

[effects]
cursor = "cursor.solar-system"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

The preset uses `radius = 84` logical pixels around the pointer.

## Configuration options

Edit the existing `[effects.preset."cursor.solar-system"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"cursor"` | Keep this kind: the source implements its `cursor` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `false` | This source does not read the palette; enabling it alone does not recolour the effect. |
| `radius` | `84` | Half-size in logical pixels of the shaded square; 0 shades the whole output. This bounds drawing, not the artwork size; reducing it may clip the effect. Use the GLSL size controls below to resize it. |

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
| `orbit` | `56.0` | Planet orbit radius in logical pixels; lower brings planets closer. |
| `speed` | `0.75` | Planet orbit rate; larger is faster. |
| `radius values per planet` | `3.2, 5.0, 6.3, 5.1, 4.5` | Planet sizes in logical pixels; lower makes smaller planets. Ring sizes follow planet radius. |
| `moon_orbit / second_moon radius` | `14.0 or 10.0 / 15.0` | Moon orbit sizes in logical pixels; lower brings moons closer to their planets. |
| `tint values` | `per-planet vec3 values` | Planet RGB colours in 0–1. |
| `local cull` | `18.0` | Drawing cutoff around each planet; enlarging moons/rings may require a larger cutoff and TOML radius. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a pass over its affected output area and prevents direct scanout while active. The shader contains loops; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
