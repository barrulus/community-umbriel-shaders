# Starlight

A subtle version of [Pond Wake](../pond-wake/): softly refracted desktop content
and sparse white sparkles that drift, curl and flash behind the pointer.
There is no coloured cloud or water-crest tint. The two-second trail fades
away after motion stops, keeping the pointer image unchanged.

![Synthetic preview of Starlight](preview.png)

Rendered from the shader over synthetic light and dark desktop content with
a crossing pointer path; not a live desktop screenshot.

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in
`~/.config/umbriel/shaders/community/cursor/starlight/`, retaining the license
notices below. Merge [config.toml](config.toml) into your configuration:

```toml
[include]
files = ["shaders/community/cursor/starlight/effect.toml"]

[effects]
cursor = "cursor.starlight"
```

Append to existing include lists and merge existing tables. Including the
preset registers it; selecting it enables it. See [installation](../../README.md#install).

## Configuration options

Edit the constants at the top of `shader.glsl`:

| Constant | Default | Meaning |
| --- | --- | --- |
| `WAKE_LIFE` | `2.0` | Fade duration in seconds; use 0.8–2.0, within retained history. |
| `REFRACTION` | `2.0` | Displacement in logical pixels; 0 leaves only sparkles, 4.5 matches Pond Wake. |
| `SPREAD` | `18.0` | Wavefront expansion in logical pixels per second; try 10–20. |
| `WAVELENGTH` | `17.0` | Wave spacing in logical pixels; try 12–28. |
| `SPARK_STRENGTH` | `0.55` | Neutral sparkle brightness; 0 leaves only distortion, 0.9 brightens the glints. |

Sparkles use fixed white light, independent of the theme palette. Refraction
preserves the sampled desktop colours. The `r < 0.42` rejection threshold
controls sparkle density; increase it for fewer sparks. Halos and flash rays
are softer than Pond Wake's.

The preset's `radius = 88` pads the path. Refraction fades out between 65 and
80 logical pixels from it; increase this cutoff and the radius together if
enlarging the effect. The area within 3 logical pixels of the pointer is clear,
reaching full effect strength at 15 pixels. Stationary samples and segments
longer than 800 pixels are ignored.

Save to reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires the newer `umbriel_pointer_path[64]` API with two-second history.
Uses sample ages instead of a continuous clock, allowing effect-driven frames
to stop when motion history expires. No previous-frame feedback buffers.

Up to 63 curved segments with six subdivisions, distance rejection and two
candidate sparks per segment are evaluated per pixel; at most two desktop
samples are read. The nearest segment supplies refraction while sparks can
overlap. Long paths shade larger rectangles. This version omits Pond Wake's
cloud-noise calculations; hardware performance has not been benchmarked.
Sampling is clamped at output edges. See [validation](../../VALIDATION.md).

## Attribution

Barrulus, adapted from [Pond Wake](../pond-wake/), with ripple refraction from
[Ripple Drops](../../window/ripple-drops/), drifting flashes inspired by
[Fairy Tail](../fairy-tail/), and curve interpolation adapted from
[Comet](../comet/) and Noctalia's bundled trail shader.
Licenses: [Barrulus MIT](../../LICENSES/Barrulus-MIT.txt) and
[Noctalia MIT](../../LICENSES/Noctalia-MIT.txt).

Contributed on 2026-10-05.
