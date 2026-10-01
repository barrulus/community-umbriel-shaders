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

The checker uses temporary config files. It does not edit or reload your desktop configuration. It detects `umbriel config validate` on newer builds and uses `umbriel validate` on older builds. Neither command compiles GLSL: GPU compilation still needs a renderer check or a compositor session, and its logs should be checked for shader errors.

## Paired window transitions

The ten presets added on 2026-09-29 are `shattered-glass`, `wet-paint`,
`flame-grilled`, `glitch`, `cells`, `void`, `old-tv`, `vhs`, `magic`, and
`triangle-flaps`.

- All 80 installation examples and the combined library pass configuration
  validation using `umbriel 0.1.0 (b1e338492aed-dirty)`.
- All ten compile and link in offscreen GLES with the animation wrapper and
  sampling helpers from that local Umbriel checkout. Rendering used Mesa
  llvmpipe (LLVM 21.1.8); the unused audio-input macro was omitted from the host
  preamble extraction.
- The GLES sweep renders 864 frames per preset: both directions, 12 progress
  values including exact and near endpoints, four logical aspect ratios,
  three random seeds, and opaque, translucent, and empty synthetic textures.
  Every exact visible endpoint matches the input and every hidden endpoint is
  transparent black. SDR premultiplied-alpha and GL-error checks pass; the
  near-endpoint mean channel difference is below 3/255.
- Intermediate opening and closing frames were inspected as synthetic renders.
  The new catalog PNGs are 320×200 opening frames at progress 0.55, logical
  size 640×400, and seed `(0.31, 0.73, 0.19, 0.61)`, composited over dark grey.
- The [browser preview](preview/) compiles the real sources in WebGL 1.
  All 5,760 endpoint/alpha sweep frames pass in Chromium 154 using SwiftShader;
  playback, scrubbing, direction, shape, and transparency controls were checked.

These are offscreen and browser checks, not a live compositor-session pass.
Hardware GPU performance, fractional-scale/rotated output composition, and
interrupted lifecycle transitions remain unverified. Fire, grids, portals,
phosphor glows, and magic intentionally add transient colour where source
alpha is zero; sampled-content effects preserve source transparency.

Default opening/closing durations are 1150/1000 ms for Wet Paint,
1200/1100 ms for Flame Grilled, 800/700 ms for Glitch, 1200/1100 ms for Cells,
850/900 ms for Old TV, and 1300/1200 ms for Triangle Flaps. The browser preview
reads those timings from the corresponding `config.toml`.

## Behaviour to check on your desktop

- Several inner overlays were tuned for a 6-pixel border and a 10-pixel corner radius. Read the preset’s tuning notes if its halves do not line up.
- Window effects sample the composed output while a window is at rest, and the window’s animation capture during transitions. Effects depending on the backdrop can look different in those states.
- Border light brightness can vary with output scale. Borders appear on the focused, decorated, non-fullscreen, non-urgent window.
- Cursor effects are clipped at output boundaries and render on the output holding the pointer. Full-output cursor presets can be more expensive than small-radius presets.
- Procedural loops and multiple texture samples can be expensive over large windows. Static previews are not performance measurements.
- Animation selectors apply globally per event. Test opening and closing endpoints when changing timing or GLSL; the preview is only an intermediate frame.

See [Umbriel’s effects reference](https://github.com/noctalia-dev/umbriel/blob/main/docs/user/effects.md) for the complete rendering contract.

## Workspace VHS Ripple

Added `workspace-transation-vhs-ripple` on 2026-10-01, with a 600 ms workspace
activation example. The preset name retains the requested `transation` spelling.

- All 82 installation examples and the combined library pass configuration
  validation using `umbriel 0.1.0 (e5056a594c3b-dirty)`.
- The same shader, under its original `workspace-ripple` name, compiled in that
  live compositor and the contributor accepted its workspace-switch appearance.
  Packaging changes only the preset name and adds attribution comments.
- Offscreen GLES compilation and 81 synthetic frames pass on Mesa llvmpipe
  (LLVM 21.1.8). Nine progress values, including exact endpoints and values outside
  0–1, were checked at three logical sizes and opaque, translucent, and empty
  input alpha. Endpoint pixels match the input exactly; SDR premultiplied-alpha,
  empty-input, and GL-error checks pass.
- The 640×400 catalog preview is rendered from the shader at progress 0.5 over a
  synthetic desktop. This offscreen check uses a synthetic sampling helper, not
  Umbriel's full capture pipeline, and does not simulate the native slide.

Interrupted switches, fractional scaling, rotated outputs, HDR fidelity, and
hardware performance have not been separately validated for this preset.
