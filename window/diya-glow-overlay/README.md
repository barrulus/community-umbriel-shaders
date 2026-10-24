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

Both shader files are generated from [shared artwork](../../packs/diwali/tools/diya-material.glsl).
Edit that file and run `python3 packs/diwali/tools/generate_diya.py`
from the repository root to keep both halves aligned. See the border page for
paired previews, tuning, activation, validation and cost.

[MIT license](../../LICENSES/Barrulus-MIT.txt).
