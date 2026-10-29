# Contributor tools

## Standalone audio analyser

[`audio-analyzer.py`](audio-analyzer.py) captures PipeWire playback and sends
64 spectrum bands to Umbriel. Use it with an older Noctalia that lacks the
audio provider, or with another shell. Download that one script; it needs
**Python 3.11+ and `pw-record`** (PipeWire's command-line tools), with no pip
packages. It requires Umbriel's **version-2 spectrum protocol**, as shipped
at `76477c2`; it does not support the old single-level version-1 protocol.

```sh
python3 audio-analyzer.py --verbose
```

From this repository, use `python3 tools/audio-analyzer.py --verbose`.
Run it inside the Umbriel session and select an audio-reactive shader.
It captures the default output's playback monitor, not the microphone.
Audio is processed in memory and is not saved. Stop with **Ctrl+C**.
Only one provider can own Umbriel's feed: disable Noctalia's **Provide Audio
to Umbriel** setting if it is enabled before using this script.

```sh
# Stronger response for quiet playback
python3 audio-analyzer.py --gain 2

# Choose an output by its PipeWire node.name or object.serial
python3 audio-analyzer.py --target alsa_output.example --verbose

# Explicit compositor socket, if session environment variables are unavailable
python3 audio-analyzer.py --socket /run/user/1000/umbriel-wayland-0.sock
```

Use `wpctl status -n` and `wpctl inspect ID` to find an output's `node.name`
or `object.serial`; the numeric ID shown by `wpctl status` is not necessarily
its serial. `--target auto` delegates output selection to the PipeWire session
manager. Restart the script when changing outputs if capture does not follow.
`--fps 10` through `--fps 60` adjusts the analysis/send rate (default 30).

The analyser uses a 2,048-sample Hann-windowed FFT at 48 kHz, mono playback,
and 64 logarithmic bands covering approximately 40 Hz–16 kHz. Low bands share
FFT bins because frequency resolution is about 23 Hz. Intensities map -60 to
-6 dBFS into 0–1 with fast attack and slower decay; these are visual values,
not calibrated loudness or an exact match for Noctalia's analyser. Mono mixing
can reduce out-of-phase stereo content. The pure-Python FFT costs more CPU
than a native analyser; lower `--fps` if needed.

The script waits for acknowledgements, sends fresh snapshots during silence,
clears stalled capture, and retries disconnected or rejected feeds once per
second. A lock/unlock or compositor restart therefore does not require
restarting the script. `pw-record` failure exits with a diagnostic; fix the
capture source and rerun. `--verbose` reports capture activity, peak band
intensity and IPC connection status. A connected feed with a zero peak means
silence or the wrong output; a waiting feed reports the IPC error. The bundled
`audio` shader reads only the lowest band, so it can stay dim while higher
bands are active.

References: [PipeWire capture options](https://docs.pipewire.org/page_man_pw-cat_1.html),
[playback-monitor property](https://docs.pipewire.org/group__pw__keys.html),
and [Umbriel spectrum IPC](https://github.com/noctalia-dev/umbriel/blob/main/docs/user/ipc.md#audio-input).

Run the focused checks with:

```sh
python3 -m unittest discover -s tools -p 'test_audio_analyzer.py'
```

Validated on 2026-10-26: five focused checks pass for silence, DC/non-finite
input, tone placement, gain, decay, capture stalls, IPC framing, rejection and
reconnection. A temporary PipeWire output carrying 100 Hz, 1 kHz and 10 kHz
tones produced distinct peaks; 332 valid packets reached a private receiver,
including a forced disconnect/reconnect, and silence cleared the levels.
The standalone script also captured the default playback monitor and received
successful acknowledgements from a private Umbriel 0.1.0 (`76477c2`) session.
SIGTERM cleanup passed. Other distributions and audio-device changes have not
been tested. The script is [MIT licensed](../LICENSES/Barrulus-MIT.txt).

## Generate one shader preview

From the repository root:

```sh
python3 tools/render-preview.py cursor/starlight
```

This renders the preset into **`cursor/starlight/preview.png`**, replacing that
image only after rendering succeeds. Use your new preset's directory instead
of `cursor/starlight`, inspect the result, then include the PNG in your PR
alongside `shader.glsl`, `effect.toml`, `config.toml` and the preset README.
There is no batch mode.

To try a render without replacing the catalog image:

```sh
python3 tools/render-preview.py cursor/starlight -o /tmp/starlight.png
```

The tool uses the `umbriel` and `grim` installed on your PATH. It starts a
private headless Umbriel session, displays synthetic light/dark sample content,
selects your preset, and captures the real compositor output. Cursor previews
include a simulated figure-eight pointer path. Native border light and companion
overlays are included when the preset defines them. The pointer image itself
is omitted from the screenshot; the cursor shader is included.

Your desktop session, personal configuration and running applications are not
used. The private session has autostart and Xwayland disabled, its own runtime
and IPC sockets, and effect capture enabled. Its processes and temporary files
are cleaned up after success, failure, or Ctrl+C. Existing preview files survive
failed or cancelled renders.

### Requirements

- Linux and **Python 3.11+**. Only Python's standard library is used; no pip packages.
- **Umbriel** with preset effects, `config validate`, JSON effect/window/output
  inspection, headless rendering and the wlr virtual-pointer protocol. Cursor
  trails also require the pointer-history API used by their shader.
- **grim**, for PNG capture over Wayland screencopy.
- A working **GLES/EGL graphics driver and accessible DRM render device**.
  A running graphical desktop is not required. A container or CI runner must
  expose the graphics device and appropriate driver libraries.

No Umbriel source checkout, compiler, protocol-generation tools, image library,
terminal emulator, or custom compositor build is needed. Keep the bundled
`preview_client.py` beside `render-preview.py`; it provides the sample window
and virtual pointer using a small Wayland protocol client.

### Examples

```sh
# One border preset, with its included overlay and native lighting
python3 tools/render-preview.py border/flowering-vine

# Portrait output
python3 tools/render-preview.py window/crt --size 400x600

# Default output is 640x400; wait longer for a persistent time-based effect
python3 tools/render-preview.py screen/vignette --time 2

# Select the closing animation and a different point in its transition
python3 tools/render-preview.py animation/wet-paint --event windows_out --progress 0.4

# Request Mesa software rendering (a usable render device may still be required)
python3 tools/render-preview.py cursor/starlight --software
```

A preset directory or its `effect.toml` is accepted. If that file defines more
than one preset, supply `--preset NAME`. Relative shader/include paths retain
their normal meaning. `--umbriel /path/to/umbriel` and `--grim /path/to/grim`
can select alternative installed executables.

### Animation and timing

For animation presets, the tool picks the first supported event in the nearby
`config.toml`, falling back to `windows_in`. Supported events are `windows_in`,
`windows_out`, `windows_move` (triggered by maximizing the sample window), and
`workspaces` (switching from the sample workspace to an empty one). Other events
and drag physics are not previewed by this tool.

Workspace previews preserve `animation.workspaces.style` from the preset's
nearby `config.toml`, so reveal presets use the stationary reveal composition.

Preview animations deliberately use a **1600 ms linear transition**, sampled
at progress **0.55**. Change these with `--duration-ms` and `--progress`.
This does not modify the preset's activation example or recommended timings.

If Umbriel provides the optional `clock-freeze` and `clock-advance` test commands,
the tool captures a controlled animation frame. Otherwise it uses wall-clock
waiting and explicitly reports approximate timing. The `--time` option is the
settling delay for persistent effects; for cursors, the 1.8-second pointer path
runs after that delay. Persistent shader clocks and pointer history use real
time, so their frames are not pixel-identical between runs.

### What the preview demonstrates

The image shows the shader running in your installed Umbriel, at scale 1, over
synthetic content. Enabled preset palettes use that compositor's default theme.
It is not a screenshot of your desktop. These new captures include real window
geometry and native composition, so they will differ from older catalog images
made by the offscreen GLSL renderer. GPU, driver and Umbriel versions can also
change the result.

Inspect the image before submitting it. For very wide border artwork, choose
larger dimensions so the effect fits. A still image cannot demonstrate motion
quality, GPU cost, HDR, all output transforms or every app's appearance. State
in your preset README that the preview is a headless compositor capture over
synthetic content, and describe any important limitations.

### Troubleshooting

- **Missing `umbriel` or `grim`:** install them or pass their executable paths.
- **No DRM FD / EGL initialization failed:** make a compatible graphics render
  device available. `--software` requests Mesa software rendering, but does not
  remove Umbriel's render-device requirement. It cannot bypass a sandbox's
  device restrictions.
- **Config rejected:** fix the reported preset/include path or unsupported key.
  The script uses the current `umbriel config validate` command.
- **Preset or overlay did not compile:** fix the GLSL error in the printed
  compositor log. A plain fallback render is not accepted as a successful preview.
- **Missing Wayland protocol or clock command:** update Umbriel for required
  protocol support. Clock commands are optional; approximate timing is supported.
- **Animation looks wrong:** choose the appropriate `--event` and `--progress`.
  Workspace captures include Umbriel's workspace movement, not just the shader.

## Configuration validation

```sh
python3 tools/validate.py
```

Checks all installation examples and the combined library without changing the
user's configuration. This is separate from rendering and does not compile GLSL.
See [validation](../VALIDATION.md).

## Catalogue generation and validation

`catalogue.py` implements the initial [metadata and catalogue contract](../docs/shader-catalogue-contract.md).
It needs **Python 3.11+**, with no pip dependencies. Committed-source generation
also needs Git. It does not contact the network, run contribution code, download
shaders, or change compositor configuration.

By default, only effects and families with an explicit boolean `publish = true`
are included. Missing flags mean `false`. Filtering happens before reading the
entry's preset, notices or media; unpublished entries contribute no downloadable
files or family backlinks. Published dependencies and family members must also
be published, otherwise generation fails.

For local contributor validation, add `--include-unpublished` to a `--draft`
command. This includes and validates experiments too. The option is forbidden
with `--revision`, so a development snapshot cannot become a public registry.
An empty catalogue is valid when all discovered metadata is unpublished.
Invalid TOML or non-boolean publication flags still fail validation.

Regenerate the nine-effect review fixture from the current checkout:

```sh
python3 tools/catalogue.py --draft --metadata-root docs/catalogue-examples \
  --output docs/catalogue-examples/registry.example.json
```

Check that the fixture is current without writing it:

```sh
python3 tools/catalogue.py --draft --metadata-root docs/catalogue-examples \
  --check docs/catalogue-examples/registry.example.json
python3 -m unittest discover -s tools -p 'test_catalogue.py'
```

The draft metadata overlay supplies `metadata.toml` and family definitions.
Runtime presets, shaders, effect activation examples, notices and media come
from their actual repository paths. Draft-only family configurations generate
recipes but do not become fabricated download paths. Every draft has
`draft: true` and `source.revision: null` and is unsuitable for installation.

Once metadata lives beside committed effects and families, generate an index
from a full source commit SHA:

```sh
python3 tools/catalogue.py --revision FULL_SOURCE_COMMIT_SHA \
  --output /tmp/shader-registry.json
```

Replace `FULL_SOURCE_COMMIT_SHA` with the complete 40-character commit ID.
`--root PATH` selects another repository. Committed mode reads metadata and all
referenced bytes directly from that Git tree, ignoring working-tree changes.
It refuses metadata overlays, short revisions, branches, symlinks, executable
files and submodule references. The publisher still needs to ensure the commit
is available in the agreed public repository and that review and shader checks
passed. A locally existing commit alone does not establish those facts.

The generator validates metadata fields and types, the reviewed tags/features
vocabulary, one preset per effect, preset-name uniqueness, kind/use agreement,
transitive dependencies, cycles, companion overlays, family membership,
activation selectors, event-specific settings, and requirement conflicts.
It derives reciprocal family links and records file sizes and SHA-256 values.
Output ordering is deterministic. Validation completes before an atomic output
replacement; failures preserve an existing registry. `--check` compares the
complete generated text and exits nonzero for a stale registry.

The v1 configuration policy is deliberately explicit in `catalogue.py`:

- Presets accept only the supported fields for their kind and required preset
  includes. Commands, providers, pools, optional includes, and unrelated config
  sections are rejected. Shader references must stay inside their own effect;
  contained sibling references are allowed for preset dependencies.
- Recipes accept the four persistent selectors, the documented animation
  slots, approved timing/curve/style/scale fields, and `animation.enabled`.
  Named custom curves and unrecognized fields require a policy review.
  Built-in spring curves cannot also specify an ineffective duration.
- `required_settings` contains conditions, not additional effect selectors.
  Missing activation examples produce `activation: null`. Reviewed examples
  with `effects.max_fps` or `effects.in_capture` remain manual guidance with a
  diagnostic and `activation: null`; other unapproved example settings fail
  validation. Nothing executes a downloaded activation example.
- Notice files are Markdown or text. Downloadable types are TOML, GLSL,
  Markdown, text, PNG, GIF, WebP, MP4, and WebM. Paths cannot expand environment
  variables or escape the repository. Referenced files must be regular,
  non-executable files without symlinks in their paths.
- Text and shaders are limited to 256 KiB per file; media to 32 MiB. Source
  reads are limited to 10,000 files and 512 MiB in total, with dependency depth
  limited to 64. These are initial publication limits, subject to review.

The module also contains pure review helpers, tested against generated data:
`activation_for` filters individual/family recipes to chosen slots, separates
out-of-scope prerequisites for review, and distinguishes supported, unsupported
and unknown capabilities; `library_update` describes a single-snapshot update
and changed downloads. These are not an installer or a validator for arbitrary
remote JSON. The future plugin must verify local bytes, detect customisations,
validate the complete candidate configuration and any prerequisites, and
implement transaction/recovery behaviour. Compatibility evidence is supplied
by the caller; the helpers do not probe the compositor or infer compatibility
from revision strings.

Catalogue validation is separate from `validate.py`'s installed-Umbriel checks.
Entry-point and size checks do not compile GLSL, measure shader complexity, or
prove visual suitability, licensing permission, or graphics-driver safety.
Human review, full configuration validation, compilation and isolated rendering
remain publication gates. No API publication or plugin application is performed
by this tool.

## Preview-tool tests

```sh
python3 -m unittest discover -s tools -p 'test_*.py'
```

These unit checks cover session-target isolation, preset selection, event
selection, capture dimensions and Wayland message handling. Renderer integration
checks and their tested version are recorded in [VALIDATION.md](../VALIDATION.md).

Both preview scripts and their synthetic scene are original code by Barrulus, under the [MIT license](../LICENSES/Barrulus-MIT.txt).

The complete working-tree catalogue now uses root metadata (138 licensed effects,
ten families), without `--metadata-root`. The nine records under
`docs/catalogue-examples` remain historical fixtures. `test_catalogue.py` checks
coverage against every preset directory, with the documented unlicensed example
as its single exception. Companion-only configuration examples are documentation,
not independent activation recipes.
