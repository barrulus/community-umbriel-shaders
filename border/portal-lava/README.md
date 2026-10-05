# Portal Lava

Violet and orchid pools with sparse magical filaments around the edge.

![Synthetic preview of Portal Lava](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session. It shows the outer shader only; paired inner overlays and compositor light are not shown.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/border/portal-lava/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Also download the companion [effect.toml](../../window/portal-lava-overlay/effect.toml) and [shader.glsl](../../window/portal-lava-overlay/shader.glsl) into `~/.config/umbriel/shaders/community/window/portal-lava-overlay/`. This preset includes those files automatically.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/border/portal-lava/effect.toml"]

[effects]
border = "portal-lava"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

The [portal-lava-overlay](../../window/portal-lava-overlay/) follows the focused border; it is not applied to every window.

Borders apply to the focused, decorated window. Fullscreen and urgent windows do not display the border effect. The `ring_padding` constant in the shader must match `padding` in `effect.toml`.

## Theme palette

This preset enables `palette = true` in `effect.toml`. Artwork colours follow
Umbriel's `[colors]` accents, warning, and error colours, while retaining shading
and highlights. Set `palette = false` in that preset to restore the original
colours shown in the preview. For a border with a companion overlay, change
both presets together. Shader colour constants are the fallback colours.

## Configuration options

Edit the existing `[effects.preset."portal-lava"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"border"` | Keep this kind: the source implements its `border` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `true` | Use theme colours for artwork. Set false to restore the original shader colours. |
| `padding` | `14` | Logical pixels of extra outward drawing space. Keep GLSL `ring_padding` equal to it. Reducing it can clip artwork; it is not a painted-width control. |
| `speed` | `1` | Time multiplier: 0.5 halves speed, 2 doubles it, 0 freezes at time zero. Also controls an attached overlay. |
| `animated` | `true` | Set false to freeze this border and its attached overlay at time zero. |
| `overlay` | `"portal-lava-overlay"` | Remove this key or use an empty string for the outer decoration only; see below. |

The optional `[effects.preset."portal-lava".light]` subtable is absent, so compositor light is off.
Adding it enables light; removing the whole table disables it. Shader-painted glow is separate.

| Light setting | Default if enabled | What changing it does |
| --- | --- | --- |
| `spread` | `80` | Logical-pixel reach; larger spreads light farther. |
| `intensity` | `1.0` | Brightness; lower is dimmer, 0 makes the light invisible. |
| `threshold` | `0.5` | Raise to emit only from brighter ring pixels; lower to include dimmer pixels. |

### Keep only the outer border

To remove the artwork over window content, remove `overlay = "portal-lava-overlay"`
from this preset (or set `overlay = ""`). Remove the companion path from
`[include].files` too if nothing else needs it; delete the empty include table
if appropriate. Keep the shader and its padding unchanged. Do not break an
include path or invent an overlay name to disable it. A separately selected
window effect remains independent.

When keeping the [portal-lava-overlay companion](../../window/portal-lava-overlay/), edit shared artwork
controls in both shaders so they meet at the window edge. Use the border's
`speed` and `animated` settings for their shared clock. See
[copying and narrowing border effects](../../README.md#border-width-padding-and-overlays).

### Shader controls

Edit these values in [shader.glsl](shader.glsl), not in TOML. `#define` is
active GLSL code; comments use `//` or `/* ... */`. Start with small changes
and keep paired shaders in sync. Keep size and duration divisors positive.

| GLSL control or expression | Shipped value | Visual effect |
| --- | --- | --- |
| `BLEED_SPEED` | `0.58` | Rate of flowing/dripping motion; larger positive values move faster. |
| `BLEED_INSET` | `64.0` | Maximum inward drawing reach in logical pixels; reducing this can clip drips rather than proportionally shrink them. |
| `inner band edge` | `-3.6 - 2.0 * wave` | Logical pixels inside the client; reduce both magnitudes for a narrower base band. Drips have separate geometry. |
| `outer band edge` | `min(ring_width, 10.0)` | Outer band reach follows decoration width, capped at 10 logical pixels. |
| `fizz time factor` | `1.25` | Larger makes surface fizz faster; TOML speed scales it too. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a focused-border pass. The shader contains loops; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
