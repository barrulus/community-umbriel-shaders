# kzzzt Close

Closing overdrives the window's own colours into phosphor and tears it into bands, then blows it out like a fuse, with one overexposed pop and a short fading afterglow of its brightest pixels.

![Closing frame of kzzzt Close](preview.png)

Frame rendered by Umbriel running this shader over a synthetic window sample, in the shader's own colours at 55% of the closing; it is not a screenshot of a desktop session.

## Use

Save [effect.toml](effect.toml) and [shader.glsl](shader.glsl) together in `~/.config/umbriel/shaders/community/animation/kzzzt-close/`, keeping the [MIT license](../../LICENSES/weegs710-MIT.txt). Merge [config.toml](config.toml) into your Umbriel configuration:

```toml
[include]
files = ["shaders/community/animation/kzzzt-close/effect.toml"]

[animation]
enabled = true

[animation.windows_out]
enabled = true
effect = "kzzzt-close"
duration_ms = 700
curve = "linear"
```

Append the include path to an existing `files` array and merge existing tables; do not duplicate them. Including the preset registers it; the selector activates the closing. Animation selection is global per event.

[kzzzt Open](../kzzzt-open/) is the matching opening.

Keep the closing short. Closing reflows the layout at once, and the closing copy is drawn over the window that takes its place for the whole transition.

## Theme palette

This preset enables `palette = true` in `effect.toml`. Artwork colours follow
Umbriel's `[colors]` accents, warning, and error colours, while retaining shading
and highlights. Set `palette = false` in that preset to restore the original
colours (green phosphor with cyan and red colour splits). Shader colour constants are the fallback colours.

## Configuration options

Edit the existing `[effects.preset.kzzzt-close]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"animation"` | Keep this kind: the source implements its `animation` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `true` | Use theme colours for artwork. Set false to restore the original shader colours. |

Edit the event table in your main Umbriel configuration (the activation
example is [config.toml](config.toml)). Larger `duration_ms` gives a slower
transition. Both `[animation] enabled` and the event must be enabled.

| Event | Example duration | Example curve |
| --- | --- | --- |
| `[animation.windows_out]` | `700` ms | `"linear"` |

Use `effect = ""` to clear the custom selection or event `enabled = false`
to disable the transition. Spring curves choose their own duration.
This shader uses linear progress: changing easing does not reshape its internal phases.
Closing `style` does not tune a working custom shader.
There is no animation-preset TOML `speed`; use event timing.

### Shader controls

Edit these values in [shader.glsl](shader.glsl), not in TOML. `#define` is
active GLSL code; comments use `//` or `/* ... */`. Start with small changes
and keep paired shaders in sync. Keep size and duration divisors positive.
The shipped values are what the author uses; other values were not range-tested.

| GLSL control or expression | Shipped value | Visual effect |
| --- | --- | --- |
| `DURATION` | `0.7` | Seconds; set it to `duration_ms` divided by 1000. |
| `PEAK` | `0.5` | Progress at which the surge is at full and the fuse starts to go. Keep it below `POP`. |
| `POP` | `0.86` | Progress of the last overexposed frame. Keep it above `PEAK`: a smoothstep runs from one to the other and reverses otherwise. |
| `TEAR_PX` | `60.0` | Base sideways shift, in logical pixels, of a torn band. It scales with the tension and is larger on the pop frame. |
| `SPLIT_PX` | `9.0` | Base colour split in logical pixels. It scales up with the tension. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Targets `animation.windows_out` with the Umbriel preset effects API and GLSL ES 1.00. The closing starts as the unmodified window and ends fully transparent: on a headless Umbriel the frame 5 ms into the closing differed from the plain window by no pixel more than 3%. No previous-frame feedback or extra textures are used.

28 texture samples per fragment, plus bounded loops. This transition distorts captured window content and adds bloom over it. No hardware performance benchmark is claimed.

The shader steps in hard 30 frames per second jumps and flickers on purpose. It uses the transition's random seed, so every closing looks different.

See [validation and limitations](../../VALIDATION.md) for the collection's tested revisions and remaining runtime limitations.

## Attribution

Author/contributor: weegs710. License: [MIT](../../LICENSES/weegs710-MIT.txt).
