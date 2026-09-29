# TV Glitch

An old CRT switching on and off: the picture tears into horizontally displaced, tinted noise bands, then collapses into a bright line and a dot. Ported from [Burn-My-Windows](https://github.com/Schneegans/Burn-My-Windows)' TV Glitch effect.

![Synthetic preview of TV Glitch](preview.png)

Preview rendered from this shader over a synthetic window sample; it is not a screenshot of a running session. It shows one intermediate frame of an opening (progress 0.25), not the complete animation.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/animation/tv-glitch/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/animation/tv-glitch/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "tv-glitch"
duration_ms = 750
curve = "linear"

[animation.windows_out]
enabled = true
effect = "tv-glitch"
duration_ms = 750
curve = "linear"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

Keep `curve = "linear"`: the shader applies its own easing to each phase, as the original does, and a second easing curve distorts the timing. `750` ms is the upstream default. The effect also suits `layers` and `scratchpad`. Animation selectors are global for the chosen event; per-application assignment is not available in this API.

On opening, the TV collapse plays in reverse during the first half and the glitch settles over the whole duration. On closing, the glitch builds up across the whole duration and the collapse plays in the second half. Each transition uses `umbriel_random_seed.x` for a different noise pattern.

## Colours and tuning

Edit the constants at the top of `shader.glsl`. They correspond to the upstream settings:

| Constant | Default | Meaning |
| --- | --- | --- |
| `GLITCH_COLOR` | `rgb(100, 160, 255)`, alpha 1 | Straight RGB tint for interference, grain, scan lines and the collapse glow. Alpha 0–1 sets how strongly it is mixed in. |
| `GLITCH_SCALE` | `1.0` | Noise band size; larger values give thinner, busier bands. Useful 0.1–4. |
| `GLITCH_STRENGTH` | `2.0` | Horizontal displacement and interference. Useful 0–4; 0 leaves only the TV collapse. |
| `GLITCH_TIME_SPAN` | `1.5` | How far the noise travels per animation (upstream duration in seconds × speed). Raise it for a more frantic glitch. |
| `SCALING` | `0.5` | Vertical squash at full collapse. |

The remaining constants (`TB_TIME`, `LR_TIME`, `LR_DELAY`, `FF_TIME`, `BLUR_WIDTH`) shape the collapse stages and edge softness, as in the original.

To follow your theme, set `palette = true` in `effect.toml`. The tint then uses `accent_primary`, keeping `GLITCH_COLOR`’s alpha as its strength. With the palette disabled (the default), `GLITCH_COLOR` is used.

## Differences from the original

Displacement, scan-line spacing and grain are measured in logical pixels, so the look does not change with output scale. The upstream noise time was `duration × speed`; Umbriel does not expose the event duration, so it is the `GLITCH_TIME_SPAN` constant. The faint scan-line pattern fades in over the first few percent of the glitch; upstream it stays at full weight when the glitch strength reaches zero, which would leave a tinted pattern on the last opening frame. Sampling and output use Umbriel’s premultiplied alpha.

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). Written against the contract at revision `0bd1b3a5`.

Checked by compiling and linking with the GLES preamble and animation wrapper from Umbriel `2482c642` on Mesa llvmpipe, then rendering offscreen over a synthetic window: the opening ends pixel-identical to the input, the closing starts pixel-identical to the input and ends fully transparent. `umbriel validate` and an interactive compositor session were **not** run for this preset, so runtime behaviour on a real desktop is unverified.

Three texture samples and three simplex-noise evaluations per pixel; no loops and no previous-frame feedback buffers. It runs only while the selected transition is active. No performance benchmark is claimed.

## Attribution

Original shader: Simon Schneegans, [Burn-My-Windows `tv-glitch.frag`](https://github.com/Schneegans/Burn-My-Windows/blob/main/resources/shaders/tv-glitch.frag), combining its TV and Glitch effects (idea by Kurt Wilson). License: [GPL-3.0-or-later](../../LICENSES/BurnMyWindows-GPL-3.0-or-later.txt). This port is distributed under the same license.

Bundled helpers: `hash12`/`hash22` by David Hoskins ([MIT](https://www.shadertoy.com/view/4djSRW)); `simplex2D` by Inigo Quilez ([MIT](https://www.shadertoy.com/view/Msf3WH)).
