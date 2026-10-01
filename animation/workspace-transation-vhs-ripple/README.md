# Workspace VHS Ripple

A ripple with strong VHS tracking bands, horizontal jitter, RGB separation,
scanlines, and noise over the native workspace slide. The distortion peaks
mid-transition and returns to the original image at both endpoints.

![Synthetic midpoint of Workspace VHS Ripple](preview.png)

Synthetic render of this shader over a desktop illustration at 50% progress.
It illustrates the distortion, not the compositor's workspace movement.

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in
`~/.config/umbriel/shaders/community/animation/workspace-transation-vhs-ripple/`,
keeping the [MIT license](../../LICENSES/Barrulus-MIT.txt).
Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
# Merge into your config; append includes and do not duplicate tables.
[include]
files = ["shaders/community/animation/workspace-transation-vhs-ripple/effect.toml"]

[animation]
enabled = true

[animation.workspaces]
enabled = true
effect = "workspace-transation-vhs-ripple"
duration_ms = 600
curve = "easeout"
```

Append the include to your existing `files` array and merge existing tables;
do not duplicate them. Including the preset registers it; selecting it under
`animation.workspaces` enables it globally for workspace switching.
The identifier intentionally uses the `workspace-transation-` prefix.

## Tuning

The default is 600 ms. Increase `duration_ms` to slow the transition.
`curve` controls the native slide; the distortion follows linear timeline
progress. Spring curves choose their own duration.

In `shader.glsl`, `0.030` controls ripple displacement, `0.080` the tracking
shift, and `0.015` the jitter, all as fractions of the capture dimensions.
The `0.006 + 0.012 * band` expression controls colour separation.
Reduce these values for a subtler result. The shader does not use theme colours.

## Compatibility and cost

Uses Umbriel's preset animation API and GLSL ES 1.00. It postprocesses the
combined workspace view during the built-in slide, rather than independently
rendering outgoing and incoming workspaces. Both endpoints sample the original
input exactly. Intermediate frames retain the displaced central sample's alpha.
Colour processing is SDR-clamped; HDR colour fidelity has not been validated.

Three texture samples per intermediate fragment, no loops, and no previous-frame
feedback. It only runs during the transition. Full-workspace capture cost depends
on output size and inner effects; no performance benchmark is claimed.

The original `workspace-ripple` preset was compiled and tried in a live desktop
session using `umbriel 0.1.0 (e5056a594c3b-dirty)` on 2026-10-01; its stronger
VHS settings were accepted by the contributor. This package preserves that shader
apart from attribution comments and the preset name. See
[validation](../../VALIDATION.md#workspace-vhs-ripple) for packaging checks and limits.

## Attribution

Author/contributor: Barrulus, with Codex assistance. Original implementation,
2026-10-01. License: [MIT](../../LICENSES/Barrulus-MIT.txt).
