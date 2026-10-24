# Diya Glow companion

![Diya Lights and its matching inward artwork](preview.png)

The inward half of the [Diya Lights border](../../border/diya-lights/README.md):
small terracotta lamps and multicoloured sparkling lights, plus their soft glow.
It draws the same artwork at the same positions and clock as the outer border,
so lamps straddle the window edge and remain partly visible at screen edges.
Source alpha is preserved; content deeper than 14 logical pixels stays unchanged.

The border includes this preset automatically. Do not select it as a standalone
window effect. Its focus gate and clock follow
the border, and it disappears in fullscreen.

Keep the shared `diya_*` artwork helpers and constants in [shader.glsl](shader.glsl)
identical to the [border shader](../../border/diya-lights/shader.glsl). See the
border page for paired previews, tuning, activation, validation and cost.

[MIT license](../../LICENSES/Barrulus-MIT.txt).

## Related Diwali effects

- [Diya Lights border](../../border/diya-lights/README.md).
- [Firelit Clouds window effect](../../window/firelit-clouds/README.md).
- [Festival Sparks cursor effect](../../cursor/festival-sparks/README.md).
- [Cloud Puff opening and closing](../../animation/cloud-puff/README.md).
- [Rangoli Iris workspace reveal](../../animation/rangoli-iris/README.md).

Each effect has its own activation example. Diya Lights includes Diya Glow
automatically; do not include or select the overlay separately.
