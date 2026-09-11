# Community Umbriel Shaders

A community collection of reusable GLSL effects for the [Umbriel](https://github.com/noctalia-dev/umbriel) Wayland compositor.

Umbriel currently loads custom **animation** shaders from files named by an
animation event's `shader` setting. This repository keeps community effects
separate from Umbriel's bundled `reveal.glsl` and `squash.glsl`, so they can be
shared, reviewed, and updated independently.

> [!IMPORTANT]
> Umbriel currently exposes custom shaders only for animation events. This
> repository may grow to cover additional shader categories as Umbriel evolves.

## Use an effect

Clone this repository beneath the Umbriel configuration directory (or use any
other local path):

```sh
mkdir -p ~/.config/umbriel/shaders
git clone https://github.com/noctalia-dev/community-umbriel-shaders.git \
  ~/.config/umbriel/shaders/community
```

Reference an effect from the config file that owns the setting. For example, an
effect stored at
`~/.config/umbriel/shaders/community/animation/example/shader.glsl` is selected
like this from `~/.config/umbriel/config.toml`:

```toml
[animation.windows_in]
enabled = true
shader = "shaders/community/animation/example/shader.glsl"
```

Relative paths resolve from the TOML file containing `shader`, including an
included configuration file. Umbriel watches shader files: saving a valid edit
reloads it automatically; `umbriel msg config-reload` reloads it explicitly.
A missing file or GLSL compilation failure leaves the built-in effect active and
reports a diagnostic.

See Umbriel's [animation documentation](https://docs.noctalia.dev/umbriel/animation/)
for the full configuration reference.

## Current shader contract

Animation effects are GLSL ES 1.00 source files. Each source provides exactly
this entry point:

```glsl
vec4 animation(vec2 uv) {
    return umbriel_sample(uv);
}
```

Do not declare `#version`, `main`, or precision qualifiers; Umbriel provides
them. `uv` uses normalized target coordinates, from `(0, 0)` at the top left to
`(1, 1)` at the bottom right. The most useful supplied values are:

| Interface | Purpose |
| --- | --- |
| `umbriel_sample(vec2 uv)` | Samples the current target. Out-of-bounds samples are transparent black. |
| `umbriel_sample_previous(vec2 uv)` | Samples this effect's prior submitted result. It enables per-target feedback. |
| `umbriel_size` | Target width and height in logical units. |
| `umbriel_progress` / `umbriel_clamped_progress` | Eased transition progress, raw or clamped to `0..1`. |
| `umbriel_linear_progress` | Timeline progress before easing. |
| `umbriel_direction` | `1` for opening/showing/focusing and `-1` for closing/hiding/unfocusing. |
| `umbriel_random_seed` | Stable `vec4` of pseudorandom values for one transition. |

Return premultiplied RGBA. Preserve sampled alpha when changing color,
especially for border effects, so transparent parts of a target remain transparent. Effects
run only during a transition, so their endpoints must agree with the ordinary
visible or hidden result.

`umbriel_sample_previous` allocates feedback buffers while the effect runs.
Use it only when an effect truly needs temporal feedback. Custom shaders are
trusted local GPU code: expensive or nonterminating code can stall the renderer,
and active effects disable direct scanout and opaque-region culling. Prefer
short, bounded, inexpensive effects.

## Repository layout

Use a directory per effect, grouped first by the compositor rendering contract:

```text
animation/
  <effect-name>/
    shader.glsl       # GLSL source configured in Umbriel
    README.md         # Preview, intent, constraints, and compatibility
    config.toml       # Minimal copyable Umbriel configuration
```

The directory-per-effect layout keeps source, configuration, screenshots, and
future auxiliary files together without inventing an Umbriel package format.
It also leaves room for future top-level categories with their own documented
APIs. Do not create empty category trees or a generic manifest now: a shader
path is the only current integration contract.

Use lowercase kebab-case effect names. An effect README should state:

- intended animation events and visual behavior;
- the Umbriel version or revision tested;
- performance-sensitive operations, feedback use, and known GPU caveats;
- installation/configuration snippet and a representative preview; and
- the source's author, attribution, and license.

Keep `config.toml` minimal: enable only the event the effect demonstrates and
set its `shader` path relative to a config placed beside the repository. Avoid
including an entire personal Umbriel configuration.

## Contributing

1. Add one self-contained effect under `animation/<effect-name>/`.
2. Keep the shader valid GLSL ES 1.00 and provide `shader.glsl`, `README.md`,
   and a minimal `config.toml`.
3. Test it through the intended Umbriel transition, including both endpoints.
   For a shared show/hide effect, test both directions.
4. Document the tested Umbriel revision, target events, resource cost, and
   license/attribution in the effect README.

Do not submit inline GLSL, generated binaries, personal machine configuration,
or effects that depend on undocumented compositor behavior. Discuss effects that
need a new integration point before submitting them.

## References

- [Umbriel](https://github.com/noctalia-dev/umbriel)
- [Umbriel animation shaders](https://docs.noctalia.dev/umbriel/animation/)
- [Bundled shader examples](https://github.com/noctalia-dev/umbriel/tree/main/examples/shaders)
