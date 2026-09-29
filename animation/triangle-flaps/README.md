# Triangle Flaps

Equilateral triangles point alternately up and down. Each independently traces its outline at a random time, then unfolds downward under acceleration to reveal the window. On closing, the triangles hinge downward, fall, and fade at different times.

![Synthetic opening frame of Triangle Flaps](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/triangle-flaps/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/triangle-flaps/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "triangle-flaps"
duration_ms = 1300
curve = "linear"

[animation.windows_out]
enabled = true
effect = "triangle-flaps"
duration_ms = 1200
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `TILE_SIZE` for equilateral side length in logical pixels; try 55–140 (default 85). Each triangle starts independently within the first 43% of the timeline, then takes another 40–52% to complete its motion. Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

Up to 18 candidate triangles per fragment, with inverse perspective projection, trigonometry, and a texture sample only for covering flaps. No hardware performance benchmark is claimed.

Flaps rotate about horizontal upper hinges with perspective foreshortening. Neighboring triangles are checked so closing flaps can fall below their original cells. Outlines add colour over transparent regions. Settled tiles return seamless window content.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
