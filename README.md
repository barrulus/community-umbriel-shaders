# Community Umbriel Shaders

A collection of reusable GLSL effects for the [Umbriel Wayland compositor](https://github.com/noctalia-dev/umbriel), organised by kind.

This collection includes 74 community presets by Barrulus, six bundled Umbriel examples, and the original minimal animation example. Browse the categories for descriptions, previews, and copyable settings:

| Kind | What it affects |
| --- | --- |
| [Animation](animation/) | Opening, closing, moving, and resizing windows; workspace transitions |
| [Border](border/) | The focused window’s decoration, with optional inner overlays and light |
| [Window](window/) | Window content, including companion border overlays |
| [Screen](screen/) | A whole output |
| [Cursor](cursor/) | The area around the pointer |

Ten new [paired window transitions](animation/) include Shattered Glass, Wet Paint,
Flame Grilled, Glitch, Cells, Void, Old TV, VHS, Magic, and Triangle Flaps.
Use the [interactive preview](preview/) to play or scrub both directions locally.

## Compatibility

Use Umbriel with the preset effects API introduced in [commit `512e2fb3`](https://github.com/noctalia-dev/umbriel/commit/512e2fb3). The `0.1.0` version number alone does not distinguish older builds; check the commit printed by `umbriel --version` when available.

GLSL source and configuration checks are described in [VALIDATION.md](VALIDATION.md).

## Install

### Download individual effects

Choose an effect from the category pages and download its **`effect.toml` and `shader.glsl`**. On GitHub, open each file and use **Download raw file** to save its contents. Keep the linked license notice with your downloaded files.

For example, download [Glow’s preset](cursor/glow/effect.toml) and [shader](cursor/glow/shader.glsl) into:

```text
~/.config/umbriel/shaders/community/cursor/glow/
  effect.toml
  shader.glsl
```

You only need the effects you choose. Their `config.toml` files, READMEs, and previews are references; Umbriel loads the preset and shader files.

Some border effects also need a companion window overlay. Their READMEs link the additional files and show where to save them. Keep the same relative layout; for example, Flowering Vine needs these four files:

```text
~/.config/umbriel/shaders/community/
  border/flowering-vine/
    effect.toml
    shader.glsl
  window/flowering-vine-overlay/
    effect.toml
    shader.glsl
```

The border preset includes its companion automatically. You do not need to select or include the overlay separately.

### Enable your chosen effect

Each effect directory contains `shader.glsl`, `effect.toml` (the preset definition), `config.toml` (a copyable activation example), and a README. **Include `effect.toml`, then select its preset name.** For example, merge this into `~/.config/umbriel/config.toml`:

```toml
[include]
files = [
  "shaders/community/cursor/glow/effect.toml",
]

[effects]
cursor = "glow"
```

If those tables already exist, append the include paths to `files` and add the selectors inside the existing `[effects]` table. Do not paste duplicate TOML tables. `config.toml` files are examples to merge, not files to include. A trailing comma in the `files` array is valid TOML.

The paths above assume the standard config location. Relative include paths resolve from the TOML file containing them; shader paths resolve from the TOML file defining the preset. Any readable directory works, including `~/.config`; `/usr/share` is not required. Keep `effect.toml` with its `shader.glsl`, and retain any companion directory listed in its README.

Save the configuration to reload, then run:

```sh
umbriel validate
```

Including a preset makes it available but does not enable it. Do not define the same preset name twice, for example by including both a bundled preset and its community copy. Border presets include their companion overlay automatically; do not include that overlay separately.

To update an individually downloaded effect, download its files again, including any companion files. Keep your own customised copies separately if you want to preserve your edits.

### Optional: download the whole collection

If you want to browse and try the whole collection locally, you can download the repository ZIP or clone it. For a new installation:

```sh
mkdir -p ~/.config/umbriel/shaders
git clone https://github.com/noctalia-dev/community-umbriel-shaders.git \
  ~/.config/umbriel/shaders/community
```

For the ZIP, extract its contents into `~/.config/umbriel/shaders/community`. Both options use the same include paths as the individual downloads above. If you choose a different location, adjust your include paths accordingly.

To update a Git clone later:

```sh
git -C ~/.config/umbriel/shaders/community pull --ff-only
```

Keep your own edited copies outside that checkout if you want to update without merging shader edits.

## Selecting and disabling effects

The four persistent selectors live under `[effects]`: `border`, `window`, `screen`, and `cursor`. The preset name is shown in each effect’s README; some names contain a literal dot, such as `"window.crt"`.

```toml
[effects]
window = "window.crt" # after including window/crt/effect.toml
cursor = ""           # disable the default cursor effect
```

Animation effects use an event selector instead:

```toml
[include]
files = ["shaders/community/animation/wobbly-lifecycle/effect.toml"]

[animation]
enabled = true

[animation.windows_in]
enabled = true
effect = "wobbly-lifecycle"
duration_ms = 620
curve = "linear"
```

Use `effect = ""` to remove a custom animation selection. Set the event’s `enabled = false` to disable that transition entirely. Each animation README provides suitable events and timing.

Window rules can select or disable border/window effects, and outputs can override the screen effect:

```toml
[[window_rule]]
match.app_id = "^foot$"
border_effect = "paper"          # include border/paper/effect.toml
window_effect = "paper-content" # include window/paper-content/effect.toml

[[window_rule]]
match.app_id = "^mpv$"
window_effect = "off"

[output."HDMI-A-1"]
screen_effect = "off"
```

Replace application and output names with your own. Animation selections are global per event, and cursor effects have no per-window override.

## Theme colours

Presets with `palette = true` can read `accent_primary`, `accent_secondary`, `warning`, and `error` from `[colors]`. `glow` and `accent-pulse` use the primary accent; `cursor-sparkle` uses the palette for its orbiting dots.

```toml
[colors]
accent_primary = "#CBA6F7"
accent_secondary = "#89B4FA"
warning = "#F9E2AF"
error = "#F38BA8"
```

A theme or wallpaper-colour generator can write these settings to an included TOML file. Umbriel reloads config changes; it does not extract a palette from the wallpaper itself. Values in your main config override included values. Most artistic shaders use their own colour constants: enabling the palette does not recolour them unless their GLSL reads `umbriel_palette_at`.

## Troubleshooting

- **`unknown key effects`:** the file was read, but an older Umbriel build does not understand the preset API. Update/rebuild, then log out and back in. Moving the file cannot fix an unrecognised setting.
- **`include not found` or unreadable shader:** check the path, and download both `effect.toml` and `shader.glsl`. Border dependencies must retain their relative directory layout.
- **Unknown preset or wrong kind:** check the selector against the effect’s README and make sure its definition is included.
- **Duplicate preset:** remove the extra definition/include; do not load a bundled preset and its community copy under the same name.
- **No visible change:** selecting the name is required. Borders need a focused, decorated, non-fullscreen, non-urgent window. Animation effects appear only during their event.
- **GLSL compile failure:** inspect Umbriel’s logs for the preset name and driver message. `umbriel validate` checks configuration, not GPU compilation.
- **Effects missing from capture:** window, screen, and cursor effects are excluded from screencopy/image-copy captures by default. Set `[effects] in_capture = true` to include them; this can increase capture cost. Border effects already appear.

## Contributing

For assistant-guided shader creation, use [SKILL.md](SKILL.md). It provides
LLM-agnostic instructions for Umbriel's shader API, preset packaging, and validation.

Use one top-level directory per kind and a lowercase kebab-case directory per effect:

```text
animation/<name>/
border/<name>/
window/<name>/
screen/<name>/
cursor/<name>/
```

Include `shader.glsl`, `effect.toml`, a copyable `config.toml`, and a README with a preview, compatibility, tuning, cost, attribution, and license. A preset definition should not enable itself. Document any companion effects and use relative paths. Do not include personal keybinds, app assignments, machine paths, or binaries.

Shaders use GLSL ES 1.00 and the entry point for their kind: `vec4 animation(vec2 uv)`, `border`, `window`, `screen`, or `cursor`. Do not supply `#version`, `main`, or precision declarations. Return premultiplied RGBA. See the [Umbriel effect API](https://github.com/noctalia-dev/umbriel/blob/main/docs/user/effects.md) for uniforms and sampling semantics.

Check config paths and GLSL compilation, then test the effect in a compositor, including both ends of animation events. Mark any untested behaviour honestly. Keep loops bounded and document previous-frame feedback and other expensive operations.

## Attribution and licensing

Barrulus’s 74 contributed presets are [MIT licensed](LICENSES/Barrulus-MIT.txt). The six bundled Umbriel examples retain [Noctalia’s MIT notice](LICENSES/Noctalia-MIT.txt). Each effect README identifies its source. Keep the appropriate notice when redistributing those shaders.

`animation/tv-glitch` is ported from Simon Schneegans’s [Burn-My-Windows](https://github.com/Schneegans/Burn-My-Windows) and is [GPL-3.0-or-later](LICENSES/BurnMyWindows-GPL-3.0-or-later.txt), like its source.

The pre-existing `animation/example` shader is by Lemmy; its original contribution did not declare a license, and this contribution does not relicense it.
