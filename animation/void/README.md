# Void

Opening grows a broad violet vortex around a black core and releases the twisting window. Closing winds the window into the darkness, with luminous ribbons continuously spiralling inward before the portal seals.

![Synthetic opening frame of Void](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/void/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/void/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "void"
duration_ms = 1000
curve = "linear"

[animation.windows_out]
enabled = true
effect = "void"
duration_ms = 850
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `PORTAL_RADIUS` for portal size; try 0.20–0.44 (default 0.36). `PORTAL_BAND` controls the luminous band width; try 0.06–0.15 (default 0.10). Both use fractions of the shorter window side. Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

One texture sample, trigonometry, a logarithmic spiral field, and radial glows per fragment. No hardware performance benchmark is claimed.

The portal adds colour and a black core over transparent regions. Circular geometry preserves aspect ratio. The vortex stays inside the window rectangle.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
