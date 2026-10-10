# Validation and limitations

The initial collection was checked on 2026-09-27.

## Vampire Blood Wash trailing-scene fix (2026-10-10)

The blood band previously began fading before the outgoing-to-incoming blend
completed, allowing the departing scene to reappear through the trailing edge.
The scene now changes at the leading edge under the opaque blood. Draining blood
uncovers only the incoming scene. Direction, artwork and duration are unchanged.

- A regression check varies only the outgoing texture between black and white
  and measures its contribution at each pixel over 121 progress values. The old
  shader fails when the outgoing scene reappears. The fix passes all 968 frames
  across both directions and landscape/portrait sizes: outgoing contribution
  never increases as progress advances.
- The existing 640-frame endpoint, alpha, scale, overshoot and reversal checks,
  plus 18 direction/reflection checks, also pass.
- Fresh private compositor captures exercise wallpaper, panels and populated
  workspaces in both directions. Empty/populated completion and cancelled swipes
  return pixel-identical resting scenes on Umbriel `0.1.0 (2145668)`.

## Vampire Wake (2026-10-10)

Added `vampire-wake`, a Witchfire-derived crimson cursor ribbon with burgundy
wisps, falling red sparks and fluttering bat silhouettes.

Validation with **Umbriel 0.1.0 (`2145668`)**:

- Compiles and renders in a private headless compositor. Still and animated
  previews show movement over synthetic light and dark content.
- After movement stops and the trail expires, the captured scene returns
  pixel-identically to the initial stationary halo. Four output-edge positions
  also render successfully.
- 288 software-GLES cases cover counts 0/1/2/8/16/64, sparse and dense curves,
  stationary/expired history, large jumps, opaque/translucent/transparent input,
  landscape/portrait logical sizes and scale 1/1.5. Source alpha and SDR
  premultiplication are preserved, with no GL errors.
- Each case is compared with an additional no-history render: absent, single,
  stationary, expired and large-jump paths show no residual trail; valid moving
  paths show a visible effect.
- Individual and combined configuration validation passes. README links resolve.

Animated captures use real pointer timestamps and approximately 80 ms samples;
preview timing is illustrative. Hardware performance, HDR and native rotated or
fractional-scale output composition remain unverified.

## Vampire Blood Wash (2026-10-10)

Added `vampire-blood-wash`, a full-scene reveal with a glossy crimson band.
Downward navigation advances top-left to bottom-right; upward navigation
advances bottom-left to top-right. Both use the current two-scene sampling API.

Validation with **Umbriel 0.1.0 (`2145668`)**:

- Compiles and renders in a private headless compositor with wallpaper, a panel
  and two populated workspaces. Still and animated previews cover both directions.
- Empty-to-empty completion, both populated switch directions and cancelled
  swipes return pixel-identical resting scenes.
- 640 software-GLES frames pass endpoint, overshoot, four-axis, aspect-ratio,
  scale 1/1.5, transparent/translucent/opaque input, premultiplied-alpha and
  reversed-progress checks with distinct outgoing/incoming textures.
- Another 18 GLES frames verify the requested diagonal corners and vertical
  reflection between directions, including a tiny logical target.
- Preset packaging and individual/combined configuration validation pass.

These checks are not hardware performance measurements or native HDR,
rotated-output or fractional-scale composition acceptance tests.

## Recovered workspace reveals (2026-10-10)

Added thirteen full-scene workspace transitions: Iris, Burn, Shatter, Tile
Gravity, Venetian Blinds, Sand Collapse, CRT Scanline, Melt, Dust Cloud,
Glitch Phase, Noctalia Wave, Transporter and Wipe. Their preset/directory names
start with `workspace-` to distinguish them from window lifecycle effects.

Sources were the disposable effects-session reveal bundle (six presets), its
referenced showcase presets (six workspace pairs), and the workspace-reveal
session's Wipe. Backup variants, carousel presentation, window-scene lifecycle
presets and already-collected cursor/window shaders were not imported.

The scene-v1 sources were ported to `animation(vec2)` with `umbriel_sample`
and `umbriel_sample_incoming`. Output size comes from `umbriel_size` and
navigation sign from `umbriel_workspace_axis`. Saved preset parameters became
GLSL constants; shared helpers were embedded for standalone downloads. Iris
and Melt retain their quiet appearance without the unused audio modulation.
Wipe now combines both scenes instead of masking individual workspace roots.

Validation with **Umbriel 0.1.0 (`2145668`)**:

- All thirteen compile and render in private headless sessions. Each has a
  still and GIF preview with synthetic wallpaper, a panel and populated
  outgoing/incoming workspaces. Every still was visually inspected.
- For every preset, empty-to-empty completion, both populated switch
  directions and cancelled swipes return pixel-identical resting scenes.
- Each passes 640 software-GLES frames using the installed revision's shader
  declarations: 8,320 frames total. Checks cover exact outgoing/incoming
  endpoints, near endpoints, clamped overshoot, both navigation axes and signs,
  landscape/portrait targets, scale 1/1.5, distinct source/destination colours,
  transparent/translucent/opaque inputs, and reversed progress. Empty input
  remains empty; rendering completes without GL errors.
- SDR premultiplication checks pass for the eleven non-emissive presets.
  Burn and CRT Scanline preserve their original additive light, whose RGB can
  exceed alpha; these were checked for endpoints, empty input and GL errors
  without imposing an SDR colour bound on their emission.
- All 112 installation examples and the combined library pass configuration
  validation. New README file links resolve and catalog entries form one table.

The original artwork and bounded loops are retained. These checks are not
hardware performance measurements or a native HDR/rotated/fractional-scale
output acceptance pass. Animated previews use approximately 40 ms samples.
No personal desktop configuration was changed.



## Witching Hour full-scene reveal (2026-10-10)

Updated the shader for Umbriel `0.1.0 (2145668)`: it samples both the outgoing
scene and `umbriel_sample_incoming`, blends once at output coordinates, and
returns the final scene pixel. Removed the obsolete workspace-root rectangle,
entering/leaving masks and transparent endpoint behavior. The 1100 ms selection
and Halloween artwork are unchanged. Earlier root-based builds are incompatible.

- Compiles and renders in the installed compositor. Fresh still and animated
  previews include a synthetic wallpaper, panel and two populated workspaces.
- An empty-to-empty switch visibly burns across wallpaper and the panel;
  its intermediate frame differs from rest at 66,559 pixels. The completed
  frame is pixel-identical to the resting scene.
- Both populated switch directions finish pixel-identically to their destination
  captures, and a cancelled swipe restores the original scene pixel for pixel.
- 1,920 software-GLES frames using the installed revision's host declarations
  pass exact outgoing/incoming endpoint, clamped overshoot, premultiplied-alpha,
  four-axis, wide/tall size, two-seed, scale 1/1.5 and reversed-progress checks.
  The two input textures have different colours and include equal and unequal
  alpha; transparent input stays transparent and opaque input stays opaque.
- All 99 installation examples and the combined library pass configuration
  validation in this checkout.

Still previews and representative compositor frames were visually inspected.
Native rotated/fractional-scale output composition, HDR and hardware performance
remain unverified. The 2026-10-09 entry below describes the superseded shader.



## Pond Wake and Starlight publication (2026-10-09)

Both cursor presets compile and render in private headless sessions with
installed Umbriel `0.1.0 (d083f24)`. Fresh synthetic captures were visually
inspected. The published files retain their original synthetic catalog previews
and match the locally validated versions below. All 99 installation examples
and the combined library pass configuration validation; the two preset READMEs'
relative file links resolve. No hardware performance benchmark was performed.

## Halloween presets (2026-10-09)

Published Witching Hour, Witchfire, Pumpkin Parade (including its required
inward overlay), and Midnight Fog. Shader and preset files match the user's
installed versions byte for byte at publication preparation. All five presets
report `compiled` in the running Umbriel `0.1.0 (d083f24)` session. All 97
installation examples and the combined library pass configuration validation
in the publication checkout; the new README file links also resolve.

Witchfire, the border with its overlay, and Midnight Fog were previously
compiled, rendered and visually inspected in private headless sessions with
Umbriel `0.1.0 (1d01b3a)`. Supplemental software-GLES checks covered 72 cursor
history/alpha cases and 192 border/overlay cases for growth phases, aspect
ratios, scale, alpha, clear centres and shared geometry. Hardware performance,
HDR and rotated-output composition remain unverified.

## Witching Hour workspace reveal (2026-10-09)

Added `animation/witching-hour` for the new workspace `style = "reveal"`
contract, with a 1100 ms activation example, still image and animated preview.

- The selected shader compiles and renders in a private headless compositor.
  Both directions between two populated synthetic workspaces were captured.
  Finished frames and a cancelled swipe restore the corresponding resting
  workspace pixel for pixel. Initial client interiors match; native focus
  borders change as navigation changes focus.
- 1,296 offscreen GLES frames using the upstream animation wrapper cover
  both root directions, all four navigation axes, wide/tall output sizes,
  two seeds, transparent/translucent/opaque input, exact and near endpoints,
  and clamped overshoot. Endpoint, premultiplied-alpha, complementary-mask
  and GL-error checks pass on Mesa software rendering.
- Twelve cropped-root comparisons check that different scene bounds produce
  the same output-space coverage, within one byte of alpha rounding.
- The still preview and representative intermediate compositor frames were
  visually inspected. The GIF uses 40 ms frozen-clock increments.

These checks do not benchmark hardware performance or verify HDR and rotated
output composition. Fractional scale is covered by offscreen mask checks,
not a native fractional-scale session. No personal configuration was changed.


## Starlight (2026-10-05)

Added `cursor.starlight`, based on Pond Wake with the coloured cloud and crest
lighting removed, neutral white sparkles, softer halos and reduced refraction.

- All 86 installation examples and the combined library pass configuration
  validation with `umbriel 0.1.0 (6adcbc0)`.
- Compiles, links and renders with the cursor wrapper from local Umbriel
  revision `a8cdaca1` on Mesa llvmpipe (LLVM 21.1.8).
- Passes the same 56 offscreen count, age, palette, alpha, scale and path cases
  listed for Pond Wake below. Three additional grayscale tests at alpha 0,
  0.4 and 1 confirm that the output remains neutral and preserves input alpha.
- The synthetic preview was visually inspected over light and dark content.
- Installed and selected in the running `6adcbc0` compositor; runtime inspection
  reports `compiled` and an unsuppressed cursor selection.

Live motion appearance has not been visually inspected by the assistant.
Hardware performance, rotated outputs and HDR composition are unverified;
scale and edge checks use offscreen rendering rather than full composition.

## Pond Wake (2026-10-05)

Added `cursor.pond-wake`: curved pointer-path refraction with spreading wavelets
and blue-green stirred light, based on Ripple Drops and Comet. The glow was
then revised into brighter warped-noise wisps and seeded, curling flashes
inspired by Fairy Tail; all 56 offscreen checks were repeated successfully
and the updated synthetic preview was inspected.

- All 85 installation examples and the combined library pass configuration
  validation with `umbriel 0.1.0 (6adcbc0)`.
- The shader compiles, links and renders using the cursor wrapper from local
  Umbriel cursor revision `a8cdaca1`, on Mesa llvmpipe (LLVM 21.1.8).
- Twenty sample-count / age / palette cases pass: 0, 1, 2, 8 and 64 samples,
  active and expired paths, and both palette settings. Empty, single-sample
  and expired paths preserve the input.
- Thirty-six additional renders cover opaque, 0.4-alpha and empty input at
  scales 1, 1.5 and 2, with crossing, edge-adjacent, stationary and discontinuous
  paths and wrapped birth phases. All preserve uniform input alpha without GL
  errors; stationary and warp-only paths preserve the background.
- The synthetic preview was visually inspected over light and dark content.
- Installed and selected in the running `6adcbc0` compositor; runtime inspection
  reports the preset as `compiled` and the cursor selection as unsuppressed.

Live motion appearance has not been visually inspected by the assistant.
Hardware performance, rotated outputs and HDR composition are not benchmarked.
The scale/edge checks are offscreen sampling tests, not full compositor tests.

## Comet and Fairy Tail (2026-10-05)

Added the tuned cursor presets with oldest-to-newest overlap blending and
pointer-area softening reaching full strength at 52 logical pixels. Shader
sources are based on the personal presets used for visual tuning; Comet also
supports theme palette colours. Both presets enable `palette = true` by default.

- All 84 installation examples and the combined library pass configuration
  validation with `umbriel 0.1.0 (6adcbc0)`.
- Both shaders compile, link and render without GL errors using the cursor
  preamble and wrapper from local Umbriel cursor revision `a8cdaca1` and
  Mesa llvmpipe (LLVM 21.1.8).
- Their synthetic previews use 64 samples on a crossing pointer path over
  light and dark desktop content. Both previews use fallback colours.
  Both previews were visually inspected.
- A follow-up pre-push check repeated configuration validation and rendered
  both repository shaders; the resulting previews match the packaged PNGs
  byte for byte. Each shader also passed 20 combinations of sample count
  (0, 1, 2, 8, 64), active/expired ages and fallback/theme palettes, with no
  GL errors. Empty, single-sample and expired paths preserve the background;
  full active paths draw a trail, and all cases preserve opaque alpha.

These presets require the newer `umbriel_pointer_path[64]` API; the older
preset-effects API is not sufficient. This packaging pass did not repeat
live compositor, output-edge, fractional-scale or hardware-performance checks.

## Theme palette adaptation (2026-10-02)

Audited all 82 shaders. Previously only `accent-pulse`, `glow`, `cursor-sparkle`,
and `tv-glitch` read the palette, and `tv-glitch` did not enable it by default.
Added palette support to 65 shaders and enabled it in those presets and
`tv-glitch`, bringing the total to 69. The 13 content-processing effects without
separate coloured artwork remain palette-neutral; the complete exception list
is in [Theme colours](README.md#theme-colours).

New colour mappings affect artwork and existing tint treatments, retaining
shading, highlights, and effect opacity. Rainbow generators interpolate the
palette using their existing phase. Paired borders and overlays use matching
mappings. Faerie Magic maps its finished artwork outside the particle loops;
this avoids the fallback rendering differences observed when palette lookups
were added inside those loops on llvmpipe. All adapted presets retain their
original colours with `palette = false`. Static previews show those original
colours; the browser preview now has a theme-palette toggle.

Validation uses `umbriel 0.1.0 (2040758)`, the GLES preamble and wrappers from
upstream revision `2040758e`, and Mesa llvmpipe (LLVM 21.1.8):

- All 82 installation examples and the combined library pass configuration
  validation.
- All 82 shaders compile and link. Offscreen checks cover two contrasting
  palettes and the disabled palette, four time/progress/direction/alpha cases,
  plus both exact animation endpoints in both directions at input alpha
  0, 0.4, and 1. There are 2,232 rendered frames in total.
- Every palette-enabled preset responds visibly to changing the palette;
  all 13 palette-neutral presets remain unchanged. Switching the palette
  preserves output alpha in the sampled cases.
- Disabled-palette output matches the previous source within one byte per
  channel. Animation endpoints with either palette match the previous source
  within the same tolerance. All renders complete without GL errors.
- The browser's ten paired transitions pass 11,520 WebGL frames across both
  palette modes, checking endpoints and premultiplied alpha with wide, tall,
  small, and square logical sizes, multiple seeds, and opaque/translucent input.
  Representative synthetic palette renders were visually inspected.

These are offscreen and browser checks, not a live compositor-session or
hardware-performance pass. Existing shader limitations remain; these checks
only establish the palette change's behaviour in the sampled cases.

## Documentation cleanup and border counts (2026-10-01)

Shader comments duplicating the READMEs, obsolete Niri configuration examples,
and instructions for generators absent from this repository were removed.
Attribution and implementation notes were retained. A token comparison across
all 82 shaders confirmed that the comment cleanup did not alter executable code.

Fuse and Lightning now accept counts above four. Fuse's spark-emitter loop
also follows `EMBER_COUNT`; zero or negative counts return transparent output
in both shaders. Other colour and geometry clamps remain in place.

Validation used the GLES preamble and border wrapper fetched from upstream
Umbriel `main` at [`2040758e`](https://github.com/noctalia-dev/umbriel/commit/2040758e5a33bed1fe5f56e830951346e13ed02f),
with Mesa llvmpipe (LLVM 21.1.8). No local compositor changes were used as the
shader contract.

- Both shaders compile, link, and render with counts -1, 0, 1, 4, 8, and 16 at
  times 0, 1.35, and 4.5 seconds, using a 320×240 target at scale 1.
- Zero and negative counts render transparent black. Positive counts render
  nonempty, premultiplied output without GL errors.
- Counts 1 and 4 are pixel-identical to the previous source at all three times.
- Counts 8 and 16 produce different output from the lower counts. Fuse at 8
  also differs from a version retaining only four spark emitters, confirming
  that the additional emitters contribute.

These are offscreen checks, not a live compositor or hardware performance test.
Very large counts were not tested; increasing Fuse's count increases spark work.

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
