# Rainbow Overlay

The inner-window half of the rainbow border effect; keeps inward decoration visible.

![Synthetic preview of Rainbow Overlay](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/window/rainbow-overlay/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/window/rainbow-overlay/effect.toml"]

[effects]
window = "rainbow-overlay"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

Normally this is included automatically by its matching border preset. Selecting it as a window effect, as above, applies it to every window.

This inner overlay was tuned for `border_width = 6` and `corner_radius = 10`. Other decoration sizes can misalign it with the outer border; adjust its geometry constants together with the matching border.

## Configuration options

Edit the existing `[effects.preset."rainbow-overlay"]` table in [effect.toml](effect.toml).
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

This is the inward half of [rainbow](../../border/rainbow/). Normally the border
attaches it through `overlay`; then it follows that border's focus gate,
`speed`, and `animated` settings. Selecting it independently with
`[effects] window` applies it to windows regardless of focus and uses its own clock.
To remove the inward artwork, clear the parent border's `overlay` and remove
its unused companion include. Clear any independent window selection too.
Edit shared visual controls in both shaders when keeping the pair.

The geometry assumes a 6-pixel decoration and a 10-pixel outer corner radius:
`ring_width = 6.0`, `ring_radius = vec4(4.0)`, and the `4.0` radius inside
`ring_distance()`. If changing the real decoration, set `ring_width` to the
new border width and both radius values to `max(corner_radius - border_width, 0)`.
For width 3 and radius 10, use 3.0 and 7.0 respectively. Keep `ring_padding`
matched to the parent border preset. These are geometry values, not an opacity control.

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

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a pass per affected window; applying it globally increases the cost with the number and size of visible windows. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
