# Rainbow

A glossy rainbow ripple around the window edge.

![Synthetic preview of Rainbow](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session. It shows the outer shader only; paired inner overlays and compositor light are not shown.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/border/rainbow/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Also download the companion [effect.toml](../../window/rainbow-overlay/effect.toml) and [shader.glsl](../../window/rainbow-overlay/shader.glsl) into `~/.config/umbriel/shaders/community/window/rainbow-overlay/`. This preset includes those files automatically.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/border/rainbow/effect.toml"]

[effects]
border = "rainbow"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

The [rainbow-overlay](../../window/rainbow-overlay/) follows the focused border; it is not applied to every window.

Borders apply to the focused, decorated window. Fullscreen and urgent windows do not display the border effect. The `ring_padding` constant in the shader must match `padding` in `effect.toml`.

## Theme palette

This preset enables `palette = true` in `effect.toml`. Artwork colours follow
Umbriel's `[colors]` accents, warning, and error colours, while retaining shading
and highlights. Set `palette = false` in that preset to restore the original
colours shown in the preview. For a border with a companion overlay, change
both presets together. Shader colour constants are the fallback colours.

## Configuration options

Edit the existing `[effects.preset."rainbow"]` table in [effect.toml](effect.toml).
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
| `overlay` | `"rainbow-overlay"` | Remove this key or use an empty string for the outer decoration only; see below. |

The optional `[effects.preset."rainbow".light]` subtable is absent, so compositor light is off.
Adding it enables light; removing the whole table disables it. Shader-painted glow is separate.

| Light setting | Default if enabled | What changing it does |
| --- | --- | --- |
| `spread` | `80` | Logical-pixel reach; larger spreads light farther. |
| `intensity` | `1.0` | Brightness; lower is dimmer, 0 makes the light invisible. |
| `threshold` | `0.5` | Raise to emit only from brighter ring pixels; lower to include dimmer pixels. |

### Keep only the outer border

To remove the artwork over window content, remove `overlay = "rainbow-overlay"`
from this preset (or set `overlay = ""`). Remove the companion path from
`[include].files` too if nothing else needs it; delete the empty include table
if appropriate. Keep the shader and its padding unchanged. Do not break an
include path or invent an overlay name to disable it. A separately selected
window effect remains independent.

When keeping the [rainbow-overlay companion](../../window/rainbow-overlay/), edit shared artwork
controls in both shaders so they meet at the window edge. Use the border's
`speed` and `animated` settings for their shared clock. See
[copying and narrowing border effects](../../README.md#border-width-padding-and-overlays).

### Shader controls

Edit these values in [shader.glsl](shader.glsl), not in TOML. `#define` is
active GLSL code; comments use `//` or `/* ... */`. Start with small changes
and keep paired shaders in sync. Keep size and duration divisors positive.

| GLSL control or expression | Shipped value | Visual effect |
| --- | --- | --- |
| `WAX_STRENGTH` | `0.75` | Ripple deformation, clamped to 0–1; lower reduces pools and inward bulges. This is not a uniform width multiplier. |
| `WAX_BRIGHTNESS` | `1.0` | RGB brightness multiplier; lower dims the rainbow without thinning it. |
| `WAX_PHASE` | `mod(umbriel_time / 4.0, 1.0)` | Colour/ripple phase. The 4.0 divisor is the loop duration in shader seconds; larger slows the cycle. Prefer the border's TOML speed to slow both passes together. |
| `RIPPLE_INSET` | `16.0` | Inward limit in logical pixels; lower caps inward pools. This is a limit, not a proportional thickness control. |
| `RIPPLE_OUTSET` | `12.0` | Outward limit in logical pixels; lower caps outer pools. The allocated ring plus padding also limits reach. |

### Three ways to make Rainbow narrower

1. **Remove the inward paint:** disable `overlay` on the border and remove its
   unused companion include as described above. This keeps only the outer rainbow.
2. **Thin both painted halves:** in both shaders, replace
   `float width = ring_width;` with `float width = ring_width * 0.5;`.
   Use the same multiplier in both; 0.7 gives a gentler reduction. Keep the
   native geometry macros and padding unchanged. This approximately scales
   thickness, subject to the inset/outset limits and antialiasing.
3. **Reduce the actual decoration:** for example, set `[appearance] border_width = 3`
   in your main configuration. With `corner_radius = 10`, change the overlay's
   `#define ring_width 6.0` to `3.0`, `#define ring_radius vec4(4.0)` to
   `vec4(7.0)`, and the `4.0` in `float radius = min(4.0, ...)` to `7.0`.
   The outer shader calculates its geometry automatically. Keep
   `float width = ring_width;` for this option and leave padding at 14.

For a complete outer-only `rainbow-thin` preset, see the
[copyable example](../../README.md#border-width-padding-and-overlays).

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a focused-border pass. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
