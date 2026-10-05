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

## Theme palette

This preset enables `palette = true` in `effect.toml`. The glitch tint follows
Umbriel's `[colors] accent_primary`, while retaining `GLITCH_COLOR.a` as its
tint strength. Set `palette = false` in that preset to restore the original
colours shown in the preview. For a border with a companion overlay, change
both presets together. Shader colour constants are the fallback colours.

## Configuration options

Edit the existing `[effects.preset."tv-glitch"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"animation"` | Keep this kind: the source implements its `animation` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `true` | Enable to use accent_primary as the tint, while keeping GLITCH_COLOR.a as tint strength. False uses GLITCH_COLOR. |

Edit the event tables in your main Umbriel configuration (the activation
example is [config.toml](config.toml)). Larger `duration_ms` gives a slower
transition. Both `[animation] enabled` and the event must be enabled.

| Event | Example duration | Example curve |
| --- | --- | --- |
| `[animation.windows_in]` | `750` ms | `"linear"` |
| `[animation.windows_out]` | `750` ms | `"linear"` |

Use `effect = ""` to clear the custom selection or event `enabled = false`
to disable the transition. Spring curves choose their own duration.
This shader uses eased progress: the curve changes its pacing; overshooting curves may revisit phases.
Opening/closing `style` and `scale` do not tune a working custom shader.
There is no animation-preset TOML `speed`; use event timing.

### Shader controls

Edit these values in [shader.glsl](shader.glsl), not in TOML. `#define` is
active GLSL code; comments use `//` or `/* ... */`. Start with small changes
and keep paired shaders in sync. Keep size and duration divisors positive.

| GLSL control or expression | Shipped value | Visual effect |
| --- | --- | --- |
| `GLITCH_COLOR` | `vec4(100.0 / 255.0, 160.0 / 255.0, 1.0, 1.0)` | Straight RGBA tint in 0–1; alpha controls tint strength. With palette enabled, accent_primary replaces RGB but this alpha still applies. |
| `GLITCH_SCALE` | `1.0` | Vertical glitch-pattern frequency; larger gives finer strips. Try 0.1–4. |
| `GLITCH_STRENGTH` | `2.0` | Glitch displacement/interference strength; try 0–4. Zero leaves only the TV collapse. |
| `GLITCH_TIME_SPAN` | `0.75 * 2.0` | Noise-time span traversed during the event; larger runs through more glitch variation, without changing event duration. |
| `BLUR_WIDTH` | `0.01` | Collapse-edge softness in UV units; smaller positive values make sharper edges. |
| `TB_TIME` | `0.7` | Fraction of the TV phase used for top/bottom collapse; larger stretches that phase. Keep positive. |
| `LR_TIME` | `0.4` | Fraction of the TV phase used for left/right collapse; larger stretches that phase. Keep positive. |
| `LR_DELAY` | `0.6` | Point within the TV phase where left/right collapse starts; larger delays it. |
| `FF_TIME` | `0.1` | Fraction of the TV phase used for final fade; larger lengthens that fade. Keep positive. |
| `SCALING` | `0.5` | Vertical scale at full collapse; lower positive values squash more strongly. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Differences from the original

Displacement, scan-line spacing and grain are measured in logical pixels, so the look does not change with output scale. The upstream noise time was `duration × speed`; Umbriel does not expose the event duration, so it is the `GLITCH_TIME_SPAN` constant. The faint scan-line pattern fades in over the first few percent of the glitch; upstream it stays at full weight when the glitch strength reaches zero, which would leave a tinted pattern on the last opening frame. Sampling and output use Umbriel’s premultiplied alpha.

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). Written against the contract at revision `0bd1b3a5`.

Checked by compiling and linking with the GLES preamble and animation wrapper from Umbriel `2482c642` on Mesa llvmpipe, then rendering offscreen over a synthetic window: the opening ends pixel-identical to the input, the closing starts pixel-identical to the input and ends fully transparent. `umbriel validate` and an interactive compositor session were **not** run for this preset, so runtime behaviour on a real desktop is unverified.

Three texture samples and three simplex-noise evaluations per pixel; no loops and no previous-frame feedback buffers. It runs only while the selected transition is active. No performance benchmark is claimed.

## Attribution

Original shader: Simon Schneegans, [Burn-My-Windows `tv-glitch.frag`](https://github.com/Schneegans/Burn-My-Windows/blob/main/resources/shaders/tv-glitch.frag), combining its TV and Glitch effects (idea by Kurt Wilson). License: [GPL-3.0-or-later](../../LICENSES/BurnMyWindows-GPL-3.0-or-later.txt). This port is distributed under the same license.

Bundled helpers: `hash12`/`hash22` by David Hoskins ([MIT](https://www.shadertoy.com/view/4djSRW)); `simplex2D` by Inigo Quilez ([MIT](https://www.shadertoy.com/view/Msf3WH)).
