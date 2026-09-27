# Validation and limitations

The initial collection was checked on 2026-09-27.

## Scope

- The 63 community presets by Barrulus retain their contributed GLSL without changes.
- Six bundled examples are copied from Umbriel at `c3d0eaafb1e31ee0abd99b547f85b5d52a28d0c7`. The bundled `pulse` preset is named `accent-pulse` here to distinguish it from the cyan community `pulse`; its GLSL is unchanged.
- Lemmy’s existing animation example retains its original GLSL, with activation instructions updated to the preset API.

## Checks performed

| Check | Result |
| --- | --- |
| Individual `config.toml` installation examples | All 70 pass `umbriel validate` |
| All preset definitions loaded together, including border/overlay dependencies | Pass; no duplicate preset definitions |
| Shader compilation and linking with Umbriel’s actual GLES host preamble and kind-specific wrappers | All 70 pass |
| Offscreen rendering over a synthetic input | All 70 render a preview without a GL error |
| GLSL source comparison against the input collection | All sources unchanged |

Configuration validation used the local Umbriel build reporting `umbriel 0.1.0 (8e1b84d9f27a-dirty)`. The GPU compilation check used the host wrappers from `umbrielfx/render/fx_renderer/effect_shader.c` at Umbriel source revision `c3d0eaafb1e31ee0abd99b547f85b5d52a28d0c7`, in a GLES context on Mesa llvmpipe (LLVM 21.1.8, Mesa 26.2.3).

These checks cover parsing, paths, selectors, dependencies, compilation, linking, and an example frame. They do not establish full-session behaviour, performance, compatibility with every GPU, or correct animation endpoints. The shaders were not individually exercised in an interactive compositor session as part of packaging.

Previews are 480×320 synthetic renders at scale 1, time 4.5 seconds, and animation progress 0.55. Animation previews use the opening direction except for water-splash. Border previews show the outer shader without compositor light or the paired inner overlay. They are illustrative frames, not captures of a user’s desktop or complete animations.

## Repeat configuration checks

With Python 3.11+ and a compatible version of Umbriel installed, run from the repository root:

```sh
python3 tools/validate.py
```

To use a particular build:

```sh
python3 tools/validate.py --umbriel /path/to/umbriel
```

The checker uses temporary config files. It does not edit or reload your desktop configuration. `umbriel validate` does not compile GLSL: GPU compilation still needs a renderer check or a compositor session, and its logs should be checked for shader errors.

## Behaviour to check on your desktop

- Several inner overlays were tuned for a 6-pixel border and a 10-pixel corner radius. Read the preset’s tuning notes if its halves do not line up.
- Window effects sample the composed output while a window is at rest, and the window’s animation capture during transitions. Effects depending on the backdrop can look different in those states.
- Border light brightness can vary with output scale. Borders appear on the focused, decorated, non-fullscreen, non-urgent window.
- Cursor effects are clipped at output boundaries and render on the output holding the pointer. Full-output cursor presets can be more expensive than small-radius presets.
- Procedural loops and multiple texture samples can be expensive over large windows. Static previews are not performance measurements.
- Animation selectors apply globally per event. Test opening and closing endpoints when changing timing or GLSL; the preview is only an intermediate frame.

See [Umbriel’s effects reference](https://github.com/noctalia-dev/umbriel/blob/main/docs/user/effects.md) for the complete rendering contract.
