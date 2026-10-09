# Witching Hour

A ragged portal burns through the outgoing workspace, revealing the next one
in place. Pumpkin-orange fire, yellow-hot edges, patches of witch-green flame
and a violet smoky halo travel outward from an off-centre ignition point.
The ignition point follows the workspace navigation axis and direction.

![Witching Hour in a headless Umbriel session](preview.png)

[Watch the animated workspace switch](preview.gif) at the configured 1100 ms speed.

The previews are real headless compositor captures of two populated workspaces
over synthetic content.
Shared wallpaper and panels keep their normal stacking; the fire shades the
participating workspace content and preserves transparent margins.

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together under
`~/.config/umbriel/shaders/community/animation/witching-hour/`, keeping the
[license](../../LICENSES/Barrulus-MIT.txt). Merge [config.toml](config.toml)
into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/witching-hour/effect.toml"]

[animation]
enabled = true

[animation.workspaces]
enabled = true
style = "reveal"
effect = "witching-hour"
duration_ms = 1100
curve = "linear"
```

Append to existing include lists and merge existing tables. Including the
preset registers it; the workspace selection enables it. **`style = "reveal"`
is required.** This is a workspace transition, not a window opening effect.

## Configuration options

Try `duration_ms = 800` for a quicker switch or `1400` to linger over the flames.
Keep `curve = "linear"` for the intended timing; the shader eases the portal
radius internally. Eased progress drives both the mask and flames so a reversed
swipe retraces the effect. Spring curves determine their own duration.

Edit these constants in [shader.glsl](shader.glsl):

| Constant | Default | Effect |
| --- | --- | --- |
| `FIRE_WIDTH` | `0.035` | Flame width as a fraction of the shorter output dimension; try `0.02`–`0.06`. |
| `RAGGEDNESS` | `0.045` | Irregularity of the portal edge in the same units; try `0.02`–`0.08`. |
| `INTENSITY` | `1.0` | Flame and smoke strength, clamped to `0`–`1`; zero keeps the reveal mask. |

The preset uses fixed Halloween colours and does not read the theme palette.
Restore `style = "slide"` and clear `effect = ""` to return to native sliding.

## Compatibility and cost

Requires the new [workspace reveal API](https://github.com/noctalia-dev/umbriel/blob/main/docs/user/animation.md#workspace-reveal),
including `umbriel_workspace_rect` and `umbriel_workspace_axis`. The original
preset-effects API alone is insufficient. Tested with **Umbriel 0.1.0
(`d083f24`)**. The two workspace roots use the same output-space mask with
complementary coverage; exact endpoints return the untouched visible workspace
and transparent black for the hidden workspace.

One source texture sample and four bounded procedural-noise evaluations per
fragment; no previous-frame feedback or texture assets. Reveal rendering also
has compositor capture costs. Hardware performance and HDR are not benchmarked.

Validation includes GLES endpoint, alpha and four-axis checks, plus headless
switches in both directions and swipe cancellation. See the
[validation record](../../VALIDATION.md#witching-hour-workspace-reveal-2026-10-09).

## Attribution

Original shader by Barrulus with Codex assistance.
[MIT license](../../LICENSES/Barrulus-MIT.txt).
