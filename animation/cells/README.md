# Cells

Opening traces glowing pentagonal lines outward from the centre, fills the cells with the window, then withdraws the lines from the perimeter back to the centre. Closing traces the same lines, empties the cells, and retracts the grid inward.

![Synthetic opening frame of Cells](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/cells/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/cells/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "cells"
duration_ms = 1200
curve = "linear"

[animation.windows_out]
enabled = true
effect = "cells"
duration_ms = 1100
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `CELL_SIZE` for the width of the five-sided cells in logical pixels; try 40–110 (default 64). Centre-out tracing occupies the first 32% of the timeline; inward erasure occupies the last 30%. Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

One texture sample, a bounded nine-centre search, and analytic cell-edge distances per fragment. No hardware performance benchmark is claimed.

The tiling pairs five-sided cells by bisecting hexagons through opposite edge midpoints, with alternating split directions. Every cell is a pentagon; there are no filler diamonds. These are not regular pentagons. Lines add colour over transparent regions.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
