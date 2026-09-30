# VHS

Opening introduces the window through horizontal tape stretch, rolling tracking errors, scanlines, noise, and colour bleed. Closing stretches and distorts the picture as it disappears.

![Synthetic opening frame of VHS](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/vhs/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/vhs/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "vhs"
duration_ms = 750
curve = "linear"

[animation.windows_out]
enabled = true
effect = "vhs"
duration_ms = 650
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `TRACKING_SHIFT` in the shader: Tracking-band displacement as a fraction of window width; try 0.08–0.30. Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

Three texture samples and procedural noise per fragment; no loops. No hardware performance benchmark is claimed.

The animation API exposes the captured window, not the desktop behind it. The opening distortion occupies the incoming window image; it cannot bend the actual background before the window exists.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
