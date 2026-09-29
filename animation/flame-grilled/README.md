# Flame Grilled

Opening sweeps tall, rolling flames downward and leaves the window behind. Closing burns slowly upward, consuming the window under a broad orange and yellow flame body.

![Synthetic opening frame of Flame Grilled](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/flame-grilled/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/flame-grilled/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "flame-grilled"
duration_ms = 1200
curve = "linear"

[animation.windows_out]
enabled = true
effect = "flame-grilled"
duration_ms = 1100
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `FLAME_COLUMNS` for tongue density across the window; try 9–22 (default 15). `FLAME_HEIGHT` controls the tallest flames as a fraction of window height; try 0.30–0.65 (default 0.48). Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

One texture sample and two procedural noise evaluations per fragment. No hardware performance benchmark is claimed.

Fire adds its own translucent colour, including over transparent parts of the window. Flames stay inside the captured rectangle.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
