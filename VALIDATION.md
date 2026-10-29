# Validation and limitations

## Shake-reactive cursors (2026-10-27)

Added `cursor.shake-locator` and `cursor.shake-grow`. Both detect repeated,
substantial, fast direction reversals from the two-second pointer path.
Shake Locator reveals three rings that fade within about 0.6 seconds; Shake
Grow adds an arrow beneath the real cursor, accumulating recent shakes toward
an 18× size cap and shrinking away within about 0.8 seconds. The latter does
not resize the actual cursor image. Neither shader reads the continuous clock
or uses previous-frame feedback.

All **137 installation examples** and the combined library pass configuration
validation. Both shaders compile in native Umbriel **0.1.0 (`3667399`)** using
Mesa software rendering. Public preset packaging retains the tested shader
logic; only the experimental preset names and source comments were changed.

At 640×400, Shake Locator's straight travel, single return, tiny jitter, and
slow-shake captures exactly match their quiet frames. Horizontal, vertical,
diagonal, and output-edge shakes reveal rings. Horizontal fading reduces
changed-pixel coverage from 15,397 to 9,774 and then zero. Motion-history expiry
stops effect-driven frames.

Shake Grow uses the same detector. The initial small-arrow version also
rejects those four ordinary-motion cases, disappears when shaking changes to
normal travel, clips at output edges, and stops effect frames after history
expiry. With the published larger size at 1280×900, consecutive shaking
captures measure arrow heights of **173, 354, 549, and 551 logical pixels**.
After shaking stops, the arrow shrinks to 314 pixels and then disappears,
restoring the quiet image exactly. The cap is approximately 560 pixels
including the outline; attainable size depends on the recent reversal count.

Both PNG previews are visually inspected captures from private headless
compositors over synthetic content, with injected pointer movement. Sensitivity
may need tuning for individual mice. Fractional scaling, rotated outputs,
HDR, transparent input, and hardware GPU performance remain unverified.


## Catalogue generator and validator (2026-10-27)

Added `tools/catalogue.py` and 35 focused catalogue checks. The nine-effect,
one-family review fixture is now generated deterministically, with 50 file
records verified against current bytes. `--check` detects stale output without
overwriting it. Committed-source tests verify that production-mode generation
reads only the requested full Git commit, ignoring dirty and untracked files;
draft overlays and invalid revisions are rejected in that mode.

Checks cover restricted preset/activation fields, metadata types and uses,
path containment, symlinks and special files, shader size/entry-point checks,
dependency cycles and overlays, family membership, companion-only entries,
opening-only activation, partial families, requirement conflicts, unknown
compatibility, shared dependency updates, and preserving existing output when
generation or replacement fails. All 47 tools tests pass. The two existing
audio socket tests required a rerun outside the sandbox's socket restriction.

Installed Umbriel 0.1.0 (`3667399`) accepted all ten generated activation recipes
in temporary configuration files. No running-session configuration was changed.
This does not establish GPU compilation, visual suitability, or a successful
live apply/undo transaction. The catalogue fixture remains a non-installable
draft; publication, client download verification, and plugin recovery remain
unimplemented. Licence permission and attribution still require human review.

## Speaker Ripple spectrum-driven motion (2026-10-26)

Removed steady clock-driven wave travel. Bass and a local perimeter spectrum
now directly move the main crests, with separate mid/treble excursions for
finer crests. Inward reach changes with energy; peaks push in and falling
levels recoil. Wave positions use linear group intensities while brightness
keeps a square-root response. No history buffers or beat detection are used.

Validated in native Umbriel `76477c2` with Mesa software rendering and a
version-2 synthetic spectrum producer. All 139 installation examples and the
combined library validate. Across 640×400, 400×640 and 320×240 outputs, 66
captures verify silence/no-feed restoration, noise rejection, isolated bands,
increasing levels and different low/mid/high spectral patterns. Advancing time
with held audio now produces byte-identical images. Changing audio with time
frozen changes the image; returning to the original levels reproduces the
original resting frame exactly. The resting, bass-kick and mixed-spectrum
captures were visually inspected. A 36-frame animated preview uses changing
synthetic spectra and a single frozen clock throughout.

Actual playback timing depends on the provider's update rate and smoothing.
Real-music feel, hardware performance, HDR, transparent input and fractional
scaling remain unverified for this revision.

## Spectrum thin ring and dynamics correction (2026-10-26)

Replaced the visibility adjustment below after feedback that it was too thick
and appeared continuously lit. Gain is now 1.0, with a linear 90% local-band /
10% overall response, no square roots or exponential saturation. The outward
bright core reaches at most two logical pixels, the short halo is cut at eight,
and compositor light is removed. With a connected feed, the underlying native
ring is dimmed to 12% so it cannot hide falling levels. Missing or disconnected
audio restores the normal native ring; connected silence deliberately stays dim.

With Umbriel `76477c2` and Mesa software rendering, 44 native captures cover
640×400 and 400×640 outputs. Noise and return to silence match connected silence;
disconnect matches the original no-feed image. Isolated bands remain visible,
and equal-energy low/mid/high blocks produce distinct regions of the border.
Levels 0.02, 0.1, 0.4 and 0.8 produce increasing differences from silence.
Additional 0.3, 0.6 and 0.95 checks retain substantial changes between ordinary
and peak levels, rather than flattening them. Held audio with a frozen clock is
deterministic. The updated preview and isolated low-band capture were visually
inspected. Configuration validation passed for all 139 examples and the combined
library; the installed preset reloaded and reports compiled. Real-music feel
still needs user assessment; no hardware performance claim is made.

## Spectrum visibility adjustment (2026-10-26)

Lifted quiet audio with gain 1.5 and a smooth exponential response, added a
four-logical-pixel audio-scaled bright core, and raised dark palette colours
to a minimum peak channel of 0.9. The halo retains its 24-pixel allocation;
compositor light now uses intensity 1.4 and threshold 0.2.

With Umbriel `76477c2` and Mesa software rendering, 32 native captures across
640×400 and 400×640 outputs pass silence, noise-floor, disconnected-feed,
isolated-band, increasing-level and frozen-clock checks. The new preview was
visually inspected. At input 0.02, mean image difference from silence rose
from approximately 1.0 to 5.3 RGB byte values. This includes compositor light
and measures image contrast, not calibrated brightness. All 139 installation
examples and the combined library validate. The installed preset was also
reloaded and reported compiled by the running compositor. Hardware performance,
HDR and all theme palettes remain untested.

## Speaker Ripple (2026-10-26)

Added `window.speaker-ripple`: inward-moving rounded pressure rings, bass-led
content displacement and spectrum-responsive colours. Its 64-band scan groups
low/middle/high activity, preserves isolated peaks and rejects noise. It returns
the unchanged source when the feed is absent or silent, and preserves source
alpha when distorting content. No feedback buffers are used.

Validated with installed Umbriel 0.1.0 (`76477c2`) in private headless sessions,
Mesa software rendering and an acknowledged version-2 synthetic spectrum feed:

- All 139 installation examples and the combined library pass configuration
  validation. The selected preset compiles and renders in native Umbriel.
- 48 captures cover 640×400, 400×640 and 320×240 outputs. Missing feed, silence,
  sub-threshold input, return to silence and disconnection produce identical
  baseline PNGs at each size.
- Increasing uniform input through 0.02, 0.1, 0.4 and 0.8 increases mean image
  difference from baseline at every size. Isolated bands 0, 7, 31 and 63 all
  remain visible, with distinct low/high-band images.
- Held audio with a frozen clock is deterministic; advancing the clock changes
  the pressure-ring positions. The shipped preview and bass/treble captures
  were visually inspected over synthetic light and dark content.

Real playback appearance, transparent-input alpha, theme-palette mode, HDR,
fractional scale, rotated outputs and hardware performance have not been
separately tested. The active clock continues to request redraws in silence.

## Spectrum and Music Radiance ports (2026-10-26)

Ported Barrulus's `spectrum` border and `cursor.music-radiance` cursor from
bumbriel `1dafcac5` to the current 64-band spectrum API. Removed named-source
configuration and the old RMS/envelope/band helpers. A bounded scan of all
64 bands now estimates visual activity, with a per-band noise floor and gains
retuned for normalized intensities. Spectrum retains its static angular halo;
Music Radiance retains its expanding rainbow waves and rotating rays.

Validated with installed Umbriel 0.1.0 (`76477c2`) in private headless sessions
using Mesa software rendering and an acknowledged version-2 spectrum feed:

- All 138 installation examples and the combined library pass configuration
  validation. Both new presets compile and render in the native compositor.
- 66 native captures cover 640×400 and 400×640 outputs. Missing feed, zero
  spectrum, sub-threshold input, return to silence and disconnection produce
  identical baseline PNGs for each preset and size.
- Uniform inputs at 0.02, 0.1, 0.4 and 0.8 each produce progressively larger
  mean RGB differences from baseline. Isolated peaks in bands 0, 7, 31 and 63
  remain visible; the lowest and highest bands produce different images.
- Held spectra produce identical frames with the animation clock frozen.
  Advancing the clock changes Music Radiance and leaves Spectrum unchanged.
  Music Radiance also renders with its pointer near the output corner.
- Native previews with a synthetic spectrum were generated and visually
  inspected, including the clipped cursor at the output corner. Spectrum's
  preview includes the configured compositor light, which can also emit from
  the native ring during silence.

Real playback appearance, HDR, transparent-input alpha, fractional scaling,
rotation and hardware performance have not been separately tested for these
ports. The cursor reads time even when its audio artwork is invisible, and
both shaders scan all 64 bands per fragment while a feed is available.

## Audio pulse and spectrum compatibility (2026-10-26)

Updated kzzzt and kzzzt Ring from the removed `umbriel_audio_level()` helper
to `umbriel_audio_spectrum(position)`. Their activity estimate samples three
low/middle/high positions; bass and treble now read the real spectrum.
Added optional `shader-audio.glsl` sources beside Pulse and Accent Pulse,
preserving the default sources and their idle pulse during silence.
The READMEs document Noctalia's disabled-by-default audio provider and the
difference between a fresh feed and audible activity.

Validated with installed Umbriel 0.1.0 (`76477c2`), matching upstream
`76477c29d864fa64069e443c350cf671f65bdc31`, in private headless sessions using
Mesa software rendering and a synthetic version-2 spectrum producer:

- All four selected shaders pass configuration loading, compile and render.
  Eight captures each cover missing feed, idle motion, silence, quiet input,
  bass, treble, loud input and disconnection; all audio packets are accepted.
- Fixed-time copies at two seconds produce byte-identical PNGs to the original
  idle shaders with missing, silent, quiet and disconnected feeds. The old
  kzzzt baseline has its obsolete level helper replaced with zero for this
  comparison. Bass, treble and loud input each differ from the idle baseline;
  bass and treble also produce distinct kzzzt results.
- Representative silence and loud-input captures were visually inspected.

These checks use synthetic audio, not real playback through Noctalia. Hardware
performance, HDR, rotation and fractional-scale composition remain unverified.
The three-position activity estimate can miss energy confined to other bands.

## Rolling fractal border (2026-10-25)

Fractal Flow and its companion now sweep a continuous contour through the
iris's nested fractal fields. Folds open, split and merge around the perimeter;
the fixed diamond pattern is removed. Both use an eight-pixel fading reach,
with nine pixels of border padding.

Both compiled on Umbriel 0.1.0 (`28fa214`) across 81 native motion frames.
Each passed 624 supplemental software GLES frames for time, aspect ratios,
scale values, source alpha and SDR premultiplication. A further 54 frames
checked the perimeter seam and maximum reach, with a maximum sampled seam
channel difference of 4/255. Both shaders share identical material helpers.
Native HDR, rotation, fractional scaling and hardware performance remain
unverified.

## Unfolding fractal reveal (2026-10-25)

Fractal Iris now advances through a folded fractal arrival-time field. Its
contours unfold, separate tears open ahead of the front and those holes merge;
the silhouette is not zoomed. A broad coloured lip follows the changing contours.
The thin persistent border and fine window shader retain their existing settings.

The revised iris compiled and rendered in 26 native Umbriel 0.1.0 (`28fa214`)
frames. Software GLES checks passed 624 frames for exact endpoints, monotonic
visibility, central symmetry, alpha and premultiplication. A supplemental
160×100 mask check across nine progress values found detached openings during
the reveal and a single merged opening at completion. Reverse preview is
reverse playback of the captured native frames, not a separate swipe capture.

## Psychedelic kaleidoscope revision (2026-10-25)

Reworked the Psychedelic set with twelve mirrored wedges, rotating animation
ornament, a thin faceted border and small moving window rosettes. Border reach
is five logical pixels per side, with six pixels of padding; window tiles are
56 pixels with a 5.5% maximum tint.

All five shaders compiled and rendered on Umbriel 0.1.0 (`28fa214`).
Refreshed native stills, lifecycle/workspace GIFs and a six-second window-motion
capture. Supplemental software GLES checks passed 624 frames per preset,
including exact animation endpoints, monotonic visibility, central symmetry,
source alpha and SDR premultiplication. The same native HDR, rotation,
fractional-scaling, interruption and GPU-performance limitations apply.

## Psychedelic effects (2026-10-24)

Added [Fractal Iris](animation/fractal-iris/), [Fractal Bloom](animation/fractal-bloom/),
[Fractal Flow](border/fractal-flow/) with its [overlay](window/fractal-flow-overlay/)
and [Fractal Veil](window/fractal-veil/). The [pack](packs/psychedelic/) includes a
combined activation example, native PNG previews and animation GIFs.

All five presets compiled and rendered on Umbriel 0.1.0 (`28fa214`), with the
three persistent passes also rendered together. Supplemental software GLES
checks passed 624 frames per preset using local source wrappers at `4531d927`,
covering endpoints, monotonic animation visibility, alpha preservation and SDR
premultiplication across aspect ratios, scale values and source opacity.
Native HDR, rotation, fractional scaling, interrupted transitions and GPU
performance remain unverified. See the pack README for capture details.

## Diwali effects (2026-10-24)

Added [Diya Lights](border/diya-lights/) and its [Diya Glow companion](window/diya-glow-overlay/),
[Firelit Clouds](window/firelit-clouds/), [Festival Sparks](cursor/festival-sparks/),
[Cloud Puff](animation/cloud-puff/) and [Rangoli Iris](animation/rangoli-iris/).
Each effect's README describes its checks and remaining limitations.

Tested with **Umbriel 0.1.0 (`8449975`)**. All six public presets compiled and
rendered together in a private native compositor session, including opening,
closing and full-scene workspace reveal. Earlier native and software-GLES
checks cover output-edge border visibility, cursor expiry, lifecycle and
workspace endpoints, cancelled swipes and premultiplied alpha. The standalone
installation examples and combined library pass the repository validator.
Native HDR, output rotation, native fractional scaling and hardware performance
remain unverified.

The initial collection was checked on 2026-09-27.

## Ghostly cursor trio (2026-10-15)

Added `ghost-thread`, `spectral-wake` and `frayed-veil`: respectively a broken
pearl filament, a soft curling smoke ribbon and three connected, ragged fabric strips.
Revised after desktop feedback: tails now reach 240/280/240 logical pixels with
1.10/1.30/1.15-second lifetimes and a later fade. The newest endpoint has a flat
cap to remove the line that previously projected ahead of the pointer. Frayed
Veil uses long attached ribbons with local flutter instead of detached puffs.
They share the Ghostly Tear pearl/mint/lavender colours, preserve source alpha
and leave the first three logical pixels around the pointer clear.

Validation with **Umbriel 0.1.0 (`693b689`)**:

- All three compile and render in private headless compositor sessions. Each
  has a still and animated preview over synthetic light/dark content. Stills
  were inspected; motion captures use a figure-eight path followed by a stop.
  All four output corners render successfully for every preset.
- Spectral Wake and Frayed Veil settle pixel-identically to the unmodified idle
  scene. Ghost Thread retains its two small animated resting wisps; comparison
  outside a 21-pixel neighbourhood confirms its moving trail has cleared.
- 288 software-GLES cases per preset (864 total) cover counts 0/1/2/8/16/64,
  curved movement, stationary history, pointer warps, expired samples,
  transparent/translucent/opaque inputs, landscape/portrait and scale 1/1.5.
  Alpha and SDR premultiplication pass without GL errors. Comparisons with
  no-history frames confirm absent/invalid/expired trails draw no residual
  trail, while valid paths remain visible.
- 33 extra full-resolution GLES cases per preset (99 total) cover eight
  movement directions with 2/8/64 samples, plus 512-pixel sweeps at zero elapsed
  time, 0.2 seconds and beyond each lifetime. They confirm no trail ahead of the
  newest endpoint, visible length beyond 75% of each cap, bounded total length,
  and complete expiration. The endpoint regression reproduced the forward line
  on the original Ghost Thread before the fix. Idle wisps have a stable tint,
  independent of the moving path, so they also match the no-history baseline.
- All 125 installation examples in the development checkout and all 120 in
  the upstream publication pass configuration validation, including each
  combined library.

Hardware performance, HDR and native fractional-scale/rotated composition
remain unverified. Animation timing follows real pointer timestamps. Retaining
two seconds of history can enlarge the compositor's affected rectangle beyond
the visible tails. Ghost Thread's idle wisps request continuous frames;
the other two rely on history age and expiry.

## Ghostly Tear Wave (2026-10-15)

Added `animation/ghostly-tear-wave`, a paired window lifecycle preset. Opening
reveals upward/downward from a wavering horizontal centre line; closing consumes
the top and bottom inward until that line disappears. Both fronts use the pale
pearl/mint/lavender wisps and perforated fabric of Ghostly Tear.

- Compiles and renders in private headless **Umbriel 0.1.0 (`693b689`)** sessions.
  Opening and closing have separate stills and GIFs, captured in 40 ms controlled
  clock steps at the configured 1100/950 ms timings. Both stills were inspected.
  Native captures confirm empty-to-visible and visible-to-empty endpoints.
- 1,152 software-GLES frames cover both directions, four logical sizes including
  a short wide window, two seeds, scale 1/1.5, transparent/translucent/opaque
  inputs, exact endpoints, overshoot and repeated progress after reversal.
  Premultiplication, source-alpha bounds and endpoint checks pass. Early opening
  and late closing stay confined to the middle half of the window.
- Another 976 coverage frames across both directions, four sizes and two seeds
  confirm pixelwise monotonic coverage: opening never removes visible fabric,
  and closing never restores it. No GL errors occur.
- All 122 installation examples in the development checkout and the combined
  library pass configuration validation.

Native HDR, fractional-scale and rotated-output composition, interrupted native
lifecycle events and hardware performance remain unverified. The supplemental
GLES checks use a saved host wrapper; native captures use the installed compositor.

## Ghostly Tear Border (2026-10-15)

Added `border/ghostly-tear-border`, a luminous pearl thread with mint/lavender
wisps curling locally and rising outward from the rounded window perimeter.
Revised after desktop feedback to increase visibility and remove circulation:
the noise no longer translates along the perimeter, colour and edge variations
use standing oscillations, and local pulses evolve independently.
The attached `window/ghostly-tear-overlay` adds a matching inward strip capped
at eight logical pixels, with a soft fade and preserved source alpha.

- Compiles and renders in private headless **Umbriel 0.1.0 (`693b689`)**.
  The catalogue PNG and six-second GIF capture synthetic light/dark window
  content; 90 real-time frames were sampled at 15 fps. The still was inspected.
- Native frames two seconds apart differ around the border.
  Their central client regions match pixel-identically, including a comparison
  with the border effect disabled in the same private session.
- 192 software-GLES frames using the saved border host wrapper cover four
  logical sizes, square/rounded/asymmetric corners, 1/6-pixel borders, scale
  1/1.5 and four clocks including 24 hours. All preserve SDR premultiplied alpha,
  keep the client interior empty and stay within the declared outward extent.
  Early frames differ in every geometry/scale combination, confirming movement.
  No GL errors occur.
- At six matching clocks, the revised shader's outer-wisp opacity averages
  3.24 times the original in the sampled straight-edge region, excluding the
  bright inner thread. The outward extent is unchanged.
- The overlay passes 288 additional GLES frames across four sizes, three corner
  configurations, scale 1/1.5, transparent/translucent/opaque input and four
  clocks. Source alpha and premultiplication are preserved; content at least
  eight logical pixels inside the rounded edge stays exactly unchanged.
- Fresh paired compositor captures retain the unchanged central content while
  showing inner wisps at 2,994 sampled top-edge pixels. Both preset programs
  compile; the standalone overlay preview was also captured and inspected.
- All 121 installation examples in the development checkout and the combined
  library pass configuration validation.

Native HDR, fractional-scale and rotated output composition, focus/fullscreen
transitions and hardware performance remain unverified for this preset. The
border and companion use the compositor's standard focus and decoration gating.
The companion adds a window pass; no feedback or compositor light pass is used.

## Ghostly Tear (2026-10-15)

Added `animation/ghostly-tear`: a centred, pale portal with irregular fabric
erosion, detached holes and pearl/mint/lavender edge haze.

- Compiles and renders in a private headless **Umbriel 0.1.0 (`693b689`)**
  session. The catalogue PNG and 1200 ms GIF capture two populated synthetic
  workspaces with wallpaper and a panel. The still was visually inspected.
- Both switch directions finish pixel-identically to their resting destination
  scenes. An empty-to-empty switch and a cancelled swipe also return
  pixel-identical resting captures.
- 1,920 software-GLES frames using the saved full-scene animation host wrapper
  cover exact endpoints, overshoot, landscape/portrait sizes, scale 1/1.5,
  two seeds, four navigation axes, differing input alpha and repeated progress
  after reversal. Endpoint, premultiplied-alpha and GL-error checks pass.
- Another 366 coverage-only frames (artwork intensity set to zero) verify that
  the incoming mask never decreases as progress advances. At progress 0.3,
  all six aspect/seed combinations contain detached holes as well as the main
  portal, with 39 satellite holes of at least two test pixels in total.
- All 119 installation examples and the combined library in the development
  checkout pass configuration validation. All 88 installation examples in the
  fork publication and all 117 in the upstream publication, including their
  combined libraries, also pass. Validation uses temporary configurations.

Hardware performance, HDR, native fractional-scale output composition and
output rotation remain unverified. Offscreen tests simulate logical size and
scale; they do not establish those native compositor behaviours.

## Train Tracks (2026-10-10)

Added `cursor.train-tracks`: curved silver rails with brown wooden sleepers,
now capped at 150 logical pixels along the path and fading within 0.45 seconds.
The final 40% of visible path length fades smoothly to reduce text obstruction.

Validation with **Umbriel 0.1.0 (`2145668`)**:

- Compiles and renders in a private headless compositor; the still and animated
  previews use synthetic light/dark content and a figure-eight pointer path.
  The still was visually inspected for rails, sleepers, bends and crossings.
- After motion stops and history expires, the compositor capture returns
  pixel-identically to the initial unmodified scene. Four output-edge captures
  also succeed.
- At the earlier 100-pixel cap, 288 software-GLES cases cover counts 0/1/2/8/16/64, sparse/dense curves,
  stationary/expired history, pointer warps, opaque/translucent/transparent input,
  landscape/portrait logical dimensions, and scale 1/1.5. They preserve alpha
  and SDR premultiplication without GL errors. Comparisons against no-history
  frames confirm valid paths are visible and absent/expired paths draw nothing.
- Nine additional fast-sweep cases cover 512-pixel moves with 2/8/64 samples
  at ages 0/0.2/0.46 seconds. Visible track stays within the 150-pixel cap
  (with one raster pixel of tolerance) and is absent at 0.46 seconds.
- All 118 installation examples and the combined library pass configuration
  validation.

Sleeper spacing varies per retained segment, and very tight bends can fold
the rails. Animated preview timing uses real pointer timestamps. Hardware
performance, HDR, native fractional scaling and output rotation remain unverified.

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
- All 115 installation examples and the combined library pass configuration
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
- All 102 installation examples and the combined library pass configuration
  validation in this checkout.

Still previews and representative compositor frames were visually inspected.
Native rotated/fractional-scale output composition, HDR and hardware performance
remain unverified. The 2026-10-09 entry below describes the superseded shader.



## Witching Hour workspace reveal (2026-10-09)

Added `animation/witching-hour` for the new workspace `style = "reveal"`
contract, with a 1100 ms activation example, still image and animated preview.

- All 102 installation examples and the combined library pass configuration
  validation with installed Umbriel `0.1.0 (d083f24)`.
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
- All seven preview-tool unit checks pass, including a regression check that
  workspace previews retain the activation example's reveal style.

These checks do not benchmark hardware performance or verify HDR and rotated
output composition. Fractional scale is covered by offscreen mask checks,
not a native fractional-scale session. No personal configuration was changed.

## Shareable single-preset preview tool (2026-10-05)

`tools/render-preview.py` uses the installed Umbriel and grim in a private
headless session. It does not use the historical `/tmp` render scripts,
hardcoded library paths, an Umbriel source tree or copied GLSL wrappers.

Tested with system `umbriel 0.1.0 (6adcbc0)`:

- Successful 640×400 captures of Starlight, Flowering Vine with its companion
  overlay, Wet Paint opening, Water Splash closing, Wobbly Move maximization,
  the workspace VHS ripple, and Vignette. CRT also rendered at 400×600.
- All eight images were visually inspected. Vignette additionally exercised
  the Mesa software-rendering option.
- Animation captures used optional frozen-clock commands. A wrapper rejecting
  those commands also successfully rendered a Wet Paint closing frame through
  the release-build fallback, with an approximate-timing notice.
- An intentionally invalid shader failed without replacing an existing PNG.
- SIGTERM during a pending cursor capture reaped the sample client and
  compositor, preserving the previous PNG.
- Six portable unit checks cover inherited-session isolation, ambiguous preset
  selection, closing-event discovery, image dimensions, fragmented Wayland
  events and UTF-8 wire strings.

These captures have native compositor geometry and differ from older catalog
previews. The tool has not been tested on other distributions or GPU drivers.
Persistent clocks and pointer motion are real-time; exact image reproducibility
is not claimed. Required graphics-device access must be provided by the host.

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

## Music Smoke port (2026-10-26)

Ported bumbriel's `window.music-smoke` from `1dafcac5` to the 64-band spectrum
API. Overall activity scans all bands, bass controls billow shape and treble
shifts colour. Removed named-source configuration and the old RMS/level/band
helpers, and retuned gains for normalized intensities.

Validated with Umbriel 0.1.0 (`76477c2`) in private headless sessions using
Mesa software rendering and an acknowledged version-2 spectrum feed:

- All 134 installation examples and the combined library pass configuration
  validation. Music Smoke compiles and renders in the native compositor.
- 36 captures cover 640×400 and 400×640 outputs. Missing feed, zero spectrum,
  sub-threshold input, return to silence and disconnect produce identical
  baseline images at each size.
- Uniform inputs of 0.02, 0.1, 0.4 and 0.8 produce progressively larger mean
  RGB differences from baseline. Isolated peaks at bands 0, 7, 31 and 63 remain
  visible. Equal-energy bass and treble profiles produce different images.
- Held audio produces identical captures with the clock frozen; advancing
  the clock animates the smoke. The synthetic-audio preview was inspected.

Real playback appearance, transparent-input alpha, HDR, fractional scaling,
rotation and hardware performance have not been separately tested. The shader
retains sampled alpha by construction. Its time input can keep frames running
during silence, and the cost scales with the number and size of selected windows.

## Kzzzt spectrum compatibility (2026-10-26)

Updated kzzzt and kzzzt Ring from the removed `umbriel_audio_level()` helper
to `umbriel_audio_spectrum(position)`. Their activity estimate samples three
low/middle/high positions; bass and treble now read the real spectrum.
The READMEs document Noctalia's disabled-by-default audio provider and the
difference between a fresh feed and audible activity.

Validated with installed Umbriel 0.1.0 (`76477c2`), matching upstream
`76477c29d864fa64069e443c350cf671f65bdc31`, in private headless sessions using
Mesa software rendering and a synthetic version-2 spectrum producer:

- Both selected shaders pass configuration loading, compile and render.
  Eight captures each cover missing feed, idle motion, silence, quiet input,
  bass, treble, loud input and disconnection; all audio packets are accepted.
- Fixed-time copies at two seconds produce byte-identical PNGs to the original
  idle shaders with missing, silent, quiet and disconnected feeds. The old
  kzzzt baseline has its obsolete level helper replaced with zero for this
  comparison. Bass, treble and loud input each differ from the idle baseline;
  bass and treble also produce distinct kzzzt results.
- Representative silence and loud-input captures were visually inspected.

These checks use synthetic audio, not real playback through Noctalia. Hardware
performance, HDR, rotation and fractional-scale composition remain unverified.
The three-position activity estimate can miss energy confined to other bands.

## Psychedelic effects (2026-10-25)

Added [Fractal Iris](animation/fractal-iris/), [Fractal Bloom](animation/fractal-bloom/),
[Fractal Flow](border/fractal-flow/) with its [inward overlay](window/fractal-flow-overlay/),
and [Fractal Veil](window/fractal-veil/). The [combined configuration](packs/psychedelic/)
selects the coordinated set; individual READMEs include controls and motion previews.

Tested with **Umbriel 0.1.0 (`28fa214`)**. All five presets compiled and rendered
in private native compositor sessions. The border, overlay and veil also rendered
together. Supplemental software GLES checks using local Umbriel wrappers at
`4531d927` covered 624 frames per preset: four aspect ratios, scales 1/1.5,
source transparency, both animation directions and out-of-range progress.
Animation endpoints, monotonic visibility, window alpha preservation and SDR
premultiplication passed. Another 54 border/overlay checks covered seam alignment
and the eight-pixel reach at three sizes and scales. All installation examples,
the combined preset library and the pack configuration pass configuration validation.

Native HDR, output rotation, native fractional scaling, interrupted transitions
and hardware performance remain unverified.

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
