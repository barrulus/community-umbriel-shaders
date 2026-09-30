# Old TV

Closing collapses the picture into a horizontal phosphor line, then a brighter central blink that lingers before winking out. Opening reverses the slower line-and-afterimage sequence.

![Synthetic opening frame of Old TV](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/old-tv/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/old-tv/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "old-tv"
duration_ms = 850
curve = "linear"

[animation.windows_out]
enabled = true
effect = "old-tv"
duration_ms = 900
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `PHOSPHOR_WIDTH` for line-glow width in logical pixels; try 1–3 (default 2). `BLINK_RADIUS` sets the final central glow radius in logical pixels; try 6–14 (default 10). The final fifth of shutdown is reserved for the afterimage. Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

One texture sample and analytic phosphor glows per fragment. No hardware performance benchmark is claimed.

The line and final blink add light over transparent regions. The vertical collapse can look sharper on very small windows.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
