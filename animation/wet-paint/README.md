# Wet Paint

Opening pours long, uneven paint streams down the window. Closing slowly drains the window in elongated drips, stretching its content through a broad glossy wet region.

![Synthetic opening frame of Wet Paint](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/wet-paint/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/wet-paint/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "wet-paint"
duration_ms = 1150
curve = "linear"

[animation.windows_out]
enabled = true
effect = "wet-paint"
duration_ms = 1000
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `STREAM_WIDTH` for average drip spacing in logical pixels; try 35–85 (default 58). `DRIP_LENGTH` controls finger length as a fraction of window height; try 0.35–0.70 (default 0.52). Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

One texture sample, interpolated procedural noise, and a bounded three-stream search per fragment. No hardware performance benchmark is claimed.

The effect stretches captured window content into paint; it does not simulate a fluid or leave puddles outside the window.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
