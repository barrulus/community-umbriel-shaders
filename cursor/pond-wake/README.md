# Pond Wake

A finger drawn through a pond: a curved refractive wake spreads behind the
pointer, stirring curling blue-green wisps and irregular fairy-like flashes. Desktop content bends
through the wavelets, then settles over two seconds. The pointer image stays
unchanged, with a small clear area around its tip.

![Synthetic preview of Pond Wake](preview.png)

Rendered from the shader over synthetic light and dark desktop content with
a crossing pointer path; not a live desktop screenshot.

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in
`~/.config/umbriel/shaders/community/cursor/pond-wake/`, retaining the license
notices below. Merge [config.toml](config.toml) into your configuration:

```toml
[include]
files = ["shaders/community/cursor/pond-wake/effect.toml"]

[effects]
cursor = "cursor.pond-wake"
```

Append to existing include lists and merge existing tables. Including the
preset only registers it; selecting it enables it. See [installation](../../README.md#install).

## Configuration options

Edit the named constants at the top of `shader.glsl`:

| Constant | Default | Meaning |
| --- | --- | --- |
| `WAKE_LIFE` | `2.0` | Fade duration in seconds; use 0.6–2.0, within retained history. |
| `REFRACTION` | `4.5` | Displacement in logical pixels; try 2–7 for subtler or stronger water. |
| `SPREAD` | `18.0` | Wavefront expansion in logical pixels per second; try 10–20. |
| `WAVELENGTH` | `17.0` | Wave spacing in logical pixels; try 12–28. |
| `BIO_GLOW` | `0.72` | Swirling cloud strength; 0 disables it, 0.4 softens it, 1.0 brightens it. |
| `SPARK_STRENGTH` | `0.90` | Drifting glints and irregular flashes; 0 disables them. |
| `CREST_LIGHT` | `0.025` | Faint crest highlights; 0 disables them. |
| `BIO_COLOUR` | `(0.12, 0.85, 0.72)` | Main blue-green colour, blended with blue and mint highlights; independent of the theme. |

The preset's `radius = 88` pads the retained path. Artwork fades out between
65 and 80 logical pixels from the path; if you greatly enlarge the wavefront,
increase both this cutoff and the radius. Refraction and light fade in between
3 and 15 logical pixels from the current pointer. Stationary samples do not
create a permanent ring. Segments longer than 800 pixels are treated as warps.

Save to reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires `umbriel_pointer_path[64]`: the newer two-second cursor history API,
not just the original preset-effects API. Uses sample ages rather than a
continuous clock, so the effect can stop requesting frames after motion ends.
No previous-frame feedback buffers are used.

The shader searches up to 63 curved path segments, with six subdivisions and
distance rejection, two seeded sparks per segment, and a warped noise field
for curling wisps. It uses at most two desktop samples per pixel. The
affected rectangle encloses the path with padding. Long sweeps cost more;
no hardware performance benchmark is claimed. Only the nearest part of a
crossing path supplies the local wake; this is a visual water approximation,
not a fluid simulation. Sparks from overlapping segments remain visible. Sampling is clamped at output edges.

See [validation](../../VALIDATION.md) for tests and limitations.

## Attribution

Barrulus. Refraction inspired by [Ripple Drops](../../window/ripple-drops/);
Clouds and drifting flashes inspired by [Fairy Tail](../fairy-tail/);
time-aware curve interpolation adapted from [Comet](../comet/) and Noctalia's
bundled trail shader. Licenses: [Barrulus MIT](../../LICENSES/Barrulus-MIT.txt)
and [Noctalia MIT](../../LICENSES/Noctalia-MIT.txt).

Contributed on 2026-10-05.
