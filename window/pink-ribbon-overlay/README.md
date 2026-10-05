# Pink Ribbon Overlay

The inner-window half of the pink-ribbon border effect; keeps inward decoration visible.

![Synthetic preview of Pink Ribbon Overlay](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/window/pink-ribbon-overlay/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/window/pink-ribbon-overlay/effect.toml"]

[effects]
window = "pink-ribbon-overlay"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

Normally this is included automatically by its matching border preset. Selecting it as a window effect, as above, applies it to every window.

## Theme palette

This preset enables `palette = true` in `effect.toml`. Artwork colours follow
Umbriel's `[colors]` accents, warning, and error colours, while retaining shading
and highlights. Set `palette = false` in that preset to restore the original
colours shown in the preview. For a border with a companion overlay, change
both presets together. Shader colour constants are the fallback colours.

## Configuration options

Edit the existing `[effects.preset."pink-ribbon-overlay"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"window"` | Keep this kind: the source implements its `window` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `true` | Use theme colours for artwork. Set false to restore the original shader colours. |

There is no TOML `speed`, `animated`, or `opacity` setting for this kind.
Motion/strength changes are GLSL edits below.
Global `[effects] max_fps` limits effect-driven frames, and `in_capture`
controls inclusion in screencopy/image-copy captures. Neither resizes the artwork.

This is the inward half of [pink-ribbon](../../border/pink-ribbon/). Normally the border
attaches it through `overlay`; then it follows that border's focus gate,
`speed`, and `animated` settings. Selecting it independently with
`[effects] window` applies it to windows regardless of focus and uses its own clock.
To remove the inward artwork, clear the parent border's `overlay` and remove
its unused companion include. Clear any independent window selection too.
Edit shared visual controls in both shaders when keeping the pair.

### Shader controls

Edit these values in [shader.glsl](shader.glsl), not in TOML. `#define` is
active GLSL code; comments use `//` or `/* ... */`. Start with small changes
and keep paired shaders in sync. Keep size and duration divisors positive.

| GLSL control or expression | Shipped value | Visual effect |
| --- | --- | --- |
| `RIBBON_INSET` | `30.0` | Inward drawing reach in logical pixels; lower can clip the ribbon rather than make it thinner. |
| `width expression` | `2.4 + 1.8 * (0.5 + 0.5 * twist)` | Ribbon half-width variation in logical pixels; multiply the whole expression by 0.5 for a thinner ribbon in both passes. |
| `travel factor` | `48.0` | Logical pixels per shader second; lower slows travel around the perimeter. |
| `twist time factor` | `0.65` | Lower slows twisting; TOML speed scales both travel and twist. |
| `ribbon_scale()` | `min(1.0, min(ring_size.x, ring_size.y) / 180.0)` | Scale used for the track and hearts. Lower the returned value for smaller ornaments in both passes; ribbon width has its own expression. |
| `ribbon_radius()` | `14.0 * ribbon_scale()` (capped by track size) | Artistic track-corner radius in logical pixels; independent of native rounding. Change both passes together. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. This adds a pass per affected window; applying it globally increases the cost with the number and size of visible windows. The shader contains loops; performance depends on your GPU and the affected area. No performance benchmark is claimed.

## Attribution

Author/contributor: Barrulus. License: [MIT](../../LICENSES/Barrulus-MIT.txt).

Contributed by Barrulus on 2026-09-27.
