# Rainbow Tunnel

A colourful tunnel centred on the pointer, with a surrounding ring.

![Synthetic preview of Rainbow Tunnel](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/cursor/rainbow-tunnel/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/cursor/rainbow-tunnel/effect.toml"]

[effects]
cursor = "cursor.rainbow-tunnel"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

The preset uses `radius = 0` (the whole output).

## Configuration options

Edit the existing `[effects.preset."cursor.rainbow-tunnel"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"cursor"` | Keep this kind: the source implements its `cursor` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `false` | This source does not read the palette; enabling it alone does not recolour the effect. |
| `radius` | `0` | Half-size in logical pixels of the shaded square; 0 shades the whole output. This bounds drawing, not the artwork size; reducing it may clip the effect. Use the GLSL size controls below to resize it. |

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
| `radial frequency` | `0.07` | Larger gives tighter rainbow bands; distances here are buffer pixels. |
| `time multiplier` | `1.0` | Larger makes faster rainbow motion. |
| `fill strength` | `0.09` | Lower makes the rainbow more transparent. |
| `fill outer / inner radii` | `54.0 / 50.0` | Buffer pixels; reduce together for a smaller fill. |
| `ring radius / half-width` | `55.0 / 7.0` | Buffer pixels; lower radius for a smaller ring, lower width for a thinner ring. |
| `glow radius / strength` | `110.0 / 0.3` | Buffer-pixel reach and brightness of the halo; lower for a tighter/fainter halo. |
| `ring colour blend` | `0.9` | Lower makes the ring less opaque. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a pass over its affected output area and prevents direct scanout while active. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
