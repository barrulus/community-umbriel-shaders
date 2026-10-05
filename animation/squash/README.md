# Squash

A bundled squash deformation for window movement.

![Synthetic preview of Squash](preview.png)

Preview rendered from this shader over a synthetic desktop sample; it is not a screenshot of a running session. It shows an intermediate frame, not the complete animation.

## Use

Download [effect.toml](effect.toml) and [shader.glsl](shader.glsl) using GitHub’s **Download raw file** button and save them together in `~/.config/umbriel/shaders/community/animation/squash/`. Keep the license notice linked below with your files. See [installation](../../README.md#install) for details.

Then merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = ["shaders/community/animation/squash/effect.toml"]

[animation]
enabled = true

[animation.windows_move]
enabled = true
effect = "squash"
duration_ms = 350
curve = "easeout"
```

Append the include path to your existing `files` array and merge selectors into existing tables. Including `effect.toml` defines the preset; the selector enables it. [`config.toml`](config.toml) contains the same copyable example.

Animation selectors are global for the chosen event; per-application animation assignment is not available in this API. Adjust `duration_ms` to change the timing.

## Configuration options

Edit the existing `[effects.preset."squash"]` table in [effect.toml](effect.toml).
The [complete configuration reference](../../README.md#configuration-reference) explains
selection, overrides, and accepted ranges. The values below are this preset's shipped
settings, including defaults for omitted keys.

| TOML setting | Shipped value | What changing it does |
| --- | --- | --- |
| `kind` | `"animation"` | Keep this kind: the source implements its `animation` entry point. |
| `shader` | `"shader.glsl"` | Loads the source beside this preset; change the path only when using another compatible source. |
| `palette` | `false` | This source does not read the palette; enabling it alone does not recolour the effect. |

Edit the event tables in your main Umbriel configuration (the activation
example is [config.toml](config.toml)). Larger `duration_ms` gives a slower
transition. Both `[animation] enabled` and the event must be enabled.

| Event | Example duration | Example curve |
| --- | --- | --- |
| `[animation.windows_move]` | `350` ms | `"easeout"` |

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
| `horizontal / vertical compression` | `0.02 / 0.045` | Peak fractional compression; lower gives a subtler squash. Keep small and nonnegative. |

Save and reload; see [reloading edits](../../README.md#reloading-edits).

## Compatibility and cost

Requires Umbriel with the preset effects API introduced in [`512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). See [validation and limitations](../../VALIDATION.md). No previous-frame feedback buffers are used. It runs while the selected transition is active. No performance benchmark is claimed.

## Attribution

Author/contributor: Noctalia. License: [MIT](../../LICENSES/Noctalia-MIT.txt).

Copied from [Umbriel’s bundled squash preset](https://github.com/noctalia-dev/umbriel/tree/c3d0eaafb1e31ee0abd99b547f85b5d52a28d0c7/examples/effects/animation/squash).
