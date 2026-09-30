# Shattered Glass

Opening reassembles an irregular fracture map. Closing breaks the window into 41 unequal polygonal shards, with clustered small splinters, large fragments, independent release delays, tumbling, launch velocities, and gravity.

![Synthetic opening frame of Shattered Glass](preview.png)

Synthetic shader render at 55% of opening, not a compositor screenshot. Explore both directions and scrub the timeline in the [interactive preview](../../preview/).

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/shattered-glass/`, keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/shattered-glass/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "shattered-glass"
duration_ms = 900
curve = "linear"

[animation.windows_out]
enabled = true
effect = "shattered-glass"
duration_ms = 800
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the two selectors activate the opening/closing pair. Animation selection is global per event.

## Tuning

Adjust `duration_ms` for speed. The shader uses linear timeline progress and handles its own phase timing, so changing the easing curve does not reshape the effect. Keep `curve = "linear"`; spring curves choose their own duration.

Edit `SHARD_FLIGHT` in the shader to scale flight distances in shorter-window-side units; try 0.6–1.4 (default 1.0). The unequal polygon geometry is baked into the shader to avoid a per-fragment Voronoi search. Per-transition seeds vary movement, not the fracture topology. Colours are defined in the shader; this preset does not read the theme palette.

## Compatibility and cost

Targets `animation.windows_in` and `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. Both visible endpoints return the original premultiplied sample; both hidden endpoints return transparent black. No previous-frame feedback or extra textures are used.

Up to 41 bounded shard candidates per fragment, with early culling, up to nine half-plane distances, and a texture sample only for covering fragments. This is the most expensive effect in the set. No hardware performance benchmark is claimed.

Shards are clipped at the original window bounds. The same seed follows the exact reverse trajectory; separate events receive separate seeds. The fixed fracture topology contains unequal convex polygons rather than a triangle grid.

See the [paired-transition validation report](../../VALIDATION.md#paired-window-transitions) for tested revisions, compilation, endpoint checks, and remaining runtime limitations.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation for this collection, 2026-09-29. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
