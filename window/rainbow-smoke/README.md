# Rainbow Smoke

Flowing rainbow smoke over window content.

![Synthetic preview of Rainbow Smoke](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/window/rainbow-smoke/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/window/rainbow-smoke/effect.toml"]

[effects]
window = "window.rainbow-smoke"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

## Configuration options

Edit the existing `[effects.preset."window.rainbow-smoke"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"window"` | Keep this kind: the source implements its `window` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `false` | This source does not read the palette; enabling it alone does not recolour the effect. |

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
| `DENSITY` | `0.50` | Coverage of the smoke; lower leaves more gaps. |
| `BOIL` | `0.75` | Amount of rolling deformation; lower makes smoother billows. |
| `CHURN` | `0.32` | Rate of rolling deformation; larger positive values churn faster. |
| `RISE` | `0.08` | Upward motion rate; larger positive values rise faster. |
| `OPACITY` | `0.48` | Opacity of the decoration over content; lower is more transparent. Keep between 0 and 1. |
| `HUE_SCALE` | `1.1` | Spatial frequency of colour patches; larger makes smaller patches. |
| `HUE_DRIFT` | `0.05` | Rate of hue cycling; lower changes colours more slowly. |
| `SAT` | `0.95` | Colour saturation; 1 gives strong spectrum colours, lower values give pastels. Keep 0–1. |
| `GLOW` | `0.22` | Glow strength; lower reduces the luminous highlight. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a pass per affected window; applying it globally increases the cost with the number and size of visible windows. The shader contains loops; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
