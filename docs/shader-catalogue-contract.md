# Draft: community shader metadata and catalogue API

**Status:** Contract under review; generator, validator and a local Noctalia plugin consumer cover 138 licensed effects and ten families. API publication and website delivery remain unimplemented.  
**Audience:** Lemmy and Lysec, repository contributors/maintainers, and Noctalia website and Shaders plugin maintainers.  
**Related:** [Overall proposal](../shader-catalogue-proposal.md).

This contract covers a small authoring format, generated JSON, publication to Noctalia infrastructure, website discovery, and selective installation and configuration through a Noctalia Shaders plugin. Manual downloads and configuration guidance remain available. It requires no compositor changes or access to Noctalia's private API implementation. Endpoint names and field choices below are proposed for review.

**Scope update:** The separate `umbriel-shaders` repository now implements local shader and family browsing, selective installation, global slot activation, one-click Apply, undo and recovery. Shader-specific window/output rules and remote delivery remain deferred, as does `umbriel-config` integration. Wrapper application and lifecycle recovery have been exercised in isolated Umbriel/Noctalia sessions; the original Glow flow also passed desktop review, apply and restore.

## 1. Contribution and ownership

**One contribution per PR can be one effect or a complete family.** A contributor can supply ready-to-use metadata or simply explain what they made, where it should apply, what files belong to it, and its authorship/provenance. Tooling and maintainers help prepare the publication format. Using an LLM does not change the review requirements.

Metadata required for publication is not a prerequisite for asking for help with a submission. Family definitions can be authored by contributors or maintainers. Tags, family membership, and bespoke family artwork are optional; verified uses and licence permission cannot be guessed.

| Owner | Responsibility |
| --- | --- |
| Shader repository | Review contributions; validate shaders, metadata, and configuration; generate the catalogue and file information. |
| Noctalia infrastructure | Publish validated catalogue JSON through the existing webhook/API arrangement; retain the previous publication on failure. |
| Website | Browse effects and families; show recorded previews, requirements, and download/configuration guidance. |
| Noctalia Shaders plugin | Explicit browsing, selective installation, local validation, effect/family application, window rules, installed-file records, and recovery. |
| User | Choose effects, application scope, and changes; use manual downloads/configuration when preferred. |

Lemmy has offered the backend/API. Website frontend and plugin implementation ownership must be agreed separately; the shader maintainers own repository automation and contributor guidance.

## 2. Conventions reused from Noctalia

- **Templates:** small TOML catalogue metadata, optional effect-specific README, field allowlists and useful validation errors. [Source](https://github.com/noctalia-dev/community-templates/blob/d4925ebc8c56f43fd153beffa924cb73e3b54111/README.md).
- **Palettes:** deterministic generated JSON with a schema version, maintained by automation rather than contributors. [Generator](https://github.com/noctalia-dev/community-palettes/blob/0132bda247fb305e6d4829917563f4505a64a9a0/.github/workflows/update-registry.js).
- **Plugins:** familiar `name`, `description`, `author`, `license`, and `tags` fields; Git-derived information. The plugin catalogue also manages API release history, which is outside this initial shader contract. [Generator](https://github.com/noctalia-dev/community-plugins/blob/c0db773e3ef7f460c59cfb53c5d721a5a06df617/.github/workflows/scripts/update-catalog.py).

Shader contributions reuse these patterns without requiring plugin entry definitions, translations, per-effect semantic-version bumps, shell hooks, or a plugin-style README checklist. The Shaders plugin itself has its own normal Noctalia plugin manifest and release lifecycle; individual shaders are catalogue content, not separate Noctalia plugins. The public repositories do not establish the private API's exact payload or webhook implementation.

## 3. Authoring files

Existing `<kind>/<slug>/effect.toml`, `shader.glsl`, and `config.toml` retain their meanings and paths. Catalogue-only information lives in a new `metadata.toml`; it is never included in Umbriel configuration.

For an ordinary effect, metadata is approximately:

```toml
publish = false
name = "Blood In"
description = "A descending wave of blood reveals the window."
author = "WinterMyst"
license = "MIT"
notice_files = ["animation/blood-in/README.md"]
uses = ["animation.windows_in"]
tags = ["horror", "blood"]
```

Here the README is a notice file because it currently contains the contributor's full MIT notice. No licence rewrite or new legal convention is necessary to prepare this example.

| Field | Publication rule |
| --- | --- |
| `publish` | Boolean, default `false`. Only explicit `true` is eligible for a public catalogue after maintainer approval. Tags never control publication. |
| `name`, `description`, `author` | Required nonempty strings. `author` is display credit; it is not required to be a GitHub username. Preserve detailed adaptation credits in notice files. Prefer descriptions within the existing plugin convention of 120 characters. |
| `license` | Required licence expression, normally SPDX, reviewed against the actual notices. A family does not relicense its members. |
| `notice_files` | Required nonempty array of repository-relative paths containing all applicable notices and attribution. Existing READMEs may be used. |
| `uses` | Explicit nonempty array for ordinary animation effects. For ordinary persistent effects, derive `effects.<kind>` unless a narrower reviewed declaration is provided. Companions default to `[]`; standalone uses must be explicitly declared and reviewed. Never infer animation uses from a name or tag. |
| `tags` | Optional, default `[]`. Maintainers can supply these from a small documented vocabulary. |
| `role` | Optional `effect` (default) or `companion`. A companion is still downloadable and may have an explicitly supported standalone use. |
| `requirements.features` | Optional additional capability/compatibility labels; every entry also requires the base preset-effects capability. A breaking shader API change gets a distinct label rather than changing an existing label's meaning. These labels are proposed catalogue vocabulary, separate from descriptive tags, not a new compositor API. |
| `required_settings` | Optional map of approved configuration leaf keys to required values. Used for genuine conditions such as workspace reveal mode. |
| `tested_on` | Optional array of build/revision descriptions. Evidence of testing, not a minimum-version claim. |

All metadata file paths are relative to the shader repository root. Existing include and shader paths inside runtime presets remain relative to their defining TOML files. Validation resolves these two conventions explicitly.

The reviewed tag vocabulary now includes `minimal`, `glow`, `geometric`, `horror`, `blood`, `nature`, `water`, `fire`, `glitch`, `retro`, `psychedelic`, `colourful`, `audio-reactive`, `space`, `playful`, `fantasy`, `texture`, `circuit`, `festival`, `particles`, and `romantic`. These describe appearance and behaviour; the generator rejects unreviewed tags. Unknown authoring fields should produce helpful errors; tags are never a substitute for supported uses.

The initial effect identity is its kind/path, for example `animation/blood-in`. Display names may change freely. Keep published paths stable; a future rename must preserve old references or introduce an explicit migration. Catalogue IDs differ from runtime preset names: Blood In selects `blood-drip-in`.

V1 assumes one locally defined preset per effect directory; presets reached through includes are dependencies. A multi-preset submission needs packaging review instead of silently choosing the first preset.

### Supported uses and requirements

Persistent uses are `effects.border`, `effects.window`, `effects.screen`, and `effects.cursor`. Animation uses follow existing configuration slots: `animation.windows_in`, `animation.windows_out`, `animation.windows_move`, `animation.workspaces`, `animation.overview`, `animation.scratchpad`, `animation.border`, `animation.dim_unfocused`, and `animation.layers`. The vocabulary does not imply that an effect supports every slot.

For Workspace Iris, the proposed declaration is:

```toml
uses = ["animation.workspaces"]
tested_on = ["0.1.0 (2145668)"]

[requirements]
features = ["workspace-reveal-full-scene"]

[required_settings]
"animation.workspaces.style" = "reveal"
```

Its 1800 ms duration and linear curve come from the existing activation example and are recommendations. Reveal mode is required. Neither the nominal `0.1.0` version nor a compiler success alone proves the two-scene API is supported.

The example catalogue defines three capability labels: `preset-effects`, `workspace-reveal-full-scene`, and `cursor-pointer-history`. Their explanations are included in `feature_definitions`. The community catalogue targets **latest Umbriel**; maintainers update or withdraw shaders that no longer work with it. No older shader variants are retained for backwards compatibility. Consumers may retain compatible/incompatible/unknown diagnostics internally, without requiring a per-shader compatibility confirmation. A tested revision is never compared lexically as a minimum version. Requirements may be shown as technical details, without an unverified badge solely because runtime capability evidence is absent. The plugin checks available configuration keys and integration commands where possible; unknown shader capabilities remain unknown. Plugin host/API requirements and support for `config-replace` are client requirements, not extra requirements attached to every shader.

Use these capability labels as compatibility tags for the rare breaking API change. For example, a future incompatible pointer-history API would receive a new label rather than redefining `cursor-pointer-history`. Labels identify required interfaces, not shader releases or repository commits. A different source revision alone is not an API mismatch. Consumer checks need evidence for support or incompatibility; neither a label's prose nor its absence from an older client's known vocabulary establishes compatibility.

Combine requirements from every selected effect and its transitive dependencies, and check required settings against the complete candidate configuration. Known incompatibility blocks Apply and explains the mismatch. Missing shader capability evidence does not block or add a confirmation to ordinary **Apply**. The latest-Umbriel policy does not bypass invalid configuration, conflicting required settings, failed file verification, unknown activation fields, or missing plugin integration commands. Ordinary Apply prepares, validates and activates in a single action, including for reveal shaders. A companion with `uses = []` still participates in dependency and compatibility checks; it is not independently selectable for activation.

### Families

`families/<slug>/family.toml` needs `name`, `description`, and a nonempty `members` array of effect IDs. `tags` is optional. `publish` is a boolean defaulting to `false`, just as for effects. The family ID is the folder slug, in a separate namespace from effect IDs.

Only explicitly published effects and families enter the generated registry. Filtering happens before reading their presets, media or notices, so unpublished entries add no files or backlinks. Published effects cannot depend on unpublished effects, and published families cannot include unpublished members; these are generation errors rather than silent omissions. `--draft --include-unpublished` is an explicit local authoring mode and cannot be used for production generation. Maintainer approval is enforced by repository review rules, not inferred from a contributor-supplied field; see [publication and review](catalogue-publication.md).

Member order is display order. Membership is declared only here; the generator adds reverse links to effects. Credits and installation requirements come from selected members and dependencies. A family may contain alternatives for one slot. It need not have a bespoke preview: a page can show its member previews.

An optional adjacent `config.toml` describes a coordinated selection, as illustrated by the draft Vampire family below. The proposed `families/` area is not yet part of the committed repository. A family configuration does not have to select every member. Its selections must refer to members with the appropriate supported uses. Dependencies can supply preset definitions but are not automatically selected as independent effects.

## 4. Review examples

The [example directory](catalogue-examples/) mirrors the intended metadata locations without changing any live effect. It contains:

| Example | What it exercises |
| --- | --- |
| [Glow](catalogue-examples/cursor/glow/metadata.toml) | Standalone effect; inferred persistent use; existing upstream attribution. |
| [Workspace Iris](catalogue-examples/animation/workspace-iris/metadata.toml) | Explicit workspace use, required reveal mode, two notices. |
| [Vampire](catalogue-examples/families/vampire/family.toml) | Contributor-authored family spanning opening, closing, border, workspace, and cursor effects. |
| [Flowering Vine](catalogue-examples/border/flowering-vine/metadata.toml) | A required overlay stored under a different kind. |

Vampire includes Blood In, Blood Out, Heartbeat, Vampire Blood Wash, and Vampire Wake, all present in the current checkout. The [draft coordinated configuration](catalogue-examples/families/vampire/config.toml) combines their current examples. This is an illustrative membership/configuration for review, not a new published family or claim that the complete combination has been visually tested.

[registry.example.json](catalogue-examples/registry.example.json) shows the corresponding generated output, including real file sizes and SHA-256 values from the current checkout. It is a nine-effect subset, not the full repository.

The initial [generator and validator](../tools/catalogue.py) now reproduces this fixture. See the [tool instructions](../tools/README.md#catalogue-generation-and-validation) for regeneration, stale-output checks, committed-source generation, and the current validation limits. Its pure selection/update helpers exercise the contract without installing files or applying configuration.

**The sample has `draft: true` and `source.revision: null`.** Some source files are uncommitted. Inventing a commit would produce broken downloads, so this sample is deliberately not installable. Production requires `draft: false` and a full, existing source commit SHA; the API must never serve a draft as its live catalogue. These examples need refreshing if the source files change.

The local plugin development mode reads an explicitly configured checkout and regenerates these records with its bundled trusted validator; it does not accept draft JSON as a downloadable publication or execute checkout tooling. It installs only selected source files and notices verified against that generated snapshot. Published/API installation must still reject drafts. This local mode currently exposes the nine metadata-backed examples, rather than inferring metadata for the entire collection.

## 5. Generated JSON contract, schema version 1

Proposed generated filename: `registry.json`. Contributors do not edit it. Use deterministic ordering and formatting. Do not embed shader source, README prose, or media bytes in the index.

| Top-level field | Meaning |
| --- | --- |
| `schema_version` | Integer `1`, describing the JSON contract, not an effect release. |
| `draft` | `false` in production; `true` only in review fixtures. |
| `source.repository` | Fixed repository URL: `https://github.com/noctalia-dev/community-umbriel-shaders`. |
| `source.revision` | Full source commit SHA shared by every file reference in this snapshot. |
| `feature_definitions` | Map from capability labels to human-readable explanations. |
| `effects` | Array of effect records, sorted by ID. |
| `families` | Array of family records, sorted by ID. |
| `files` | Map from repository-relative path to `{bytes, sha256}` for referenced downloadable files, documents, examples, and media. Shared files appear once. |

Each effect record contains:

- `id`, `path`, `name`, `description`, `author`, `license`, `notice_files`, `tags`, and `role`.
- Derived `kind`, `preset`, `uses`, and direct `dependencies` (effect IDs, not shell commands or OS packages).
- Reverse `families` links, `requirements.features`, `required_settings`, and `tested_on`.
- `install_files`: that effect's own preset, shader, and notices. Dependencies are resolved separately and recursively.
- `preview`: `{image, animation}`, each a path or `null`; `readme` and `config_example`, each a path or `null`.
- `activation`: a generated, restricted recipe as defined below, or `null` when the example cannot be represented safely.

Family records contain `id`, `path`, `name`, `description`, `members`, `tags`, derived `authors`, `preview`, `activation` (recipe or `null`), and optional `readme` and `config_example`. They do not copy their members' effect records. The draft Vampire record has no live family README, preview, or configuration path; its example recipe is derived from the separately supplied draft configuration, not from a published family file.

All arrays use stable ordering. Missing authoring options become explicit empty arrays/maps or the documented defaults in generated JSON. File sizes are integer byte counts; checksums are lowercase SHA-256 hex strings. They detect mismatched bytes, not trustworthiness of the author or server.

### Generated activation recipes and manual examples

`config_example` remains a link to reviewed, human-readable `config.toml`. The generator produces `activation` from that example; contributors do not maintain another authoring file. A recipe contains `include` (repository-relative preset paths) and `settings` (approved full configuration leaf keys to typed values). For Glow:

```json
{
  "include": ["cursor/glow/effect.toml"],
  "settings": {"effects.cursor": "glow"}
}
```

The generator resolves the example's `shaders/community/` prefix to the repository root. The plugin rebases these top-level paths to its installed snapshot; preset-relative shader and dependency paths remain unchanged. It must not append arbitrary TOML or include a downloaded `config.toml` as a preset.

For v1, approved recipe settings are the four persistent selectors and the supported animation events' `enabled`, `effect`, `duration_ms`, `curve`, and valid event-specific `style`/`scale` keys, plus `animation.enabled`. Validate types, accepted values, selected preset kinds, declared uses, and required settings. Unknown fields are rejected. Examples that need other settings remain manual guidance with `activation: null` until reviewed. Commands, autostart, application matches, window rules, output identities, and executable hooks are not catalogue recipes.

`required_settings` expresses conditions that must hold; other recipe values are recommendations. If a required value is present in a recipe it must agree with the requirement. Applying a selection combines its requirements with the reviewed recommendations and asks the user to resolve conflicts, including shared prerequisites such as enabling animations. A missing recipe does not authorize the plugin to invent timing or parse README prose.

Required conditions cannot select additional effects. The initial generator rejects effect selectors in `required_settings`. Its selection helper reports requirements outside the chosen slots separately as prerequisites for review, rather than silently adding settings for another slot. The first manual-only example settings supported by the validator are `effects.max_fps` and `effects.in_capture`; these produce a diagnostic and `activation: null`. Further settings require explicit policy review.

A family recipe can recommend one preset per slot; membership alone does not choose among alternatives. For every application, whether an individual effect or a family, resolve includes from the chosen effects and dependencies, keep only the settings for the chosen slots, and review their shared prerequisites. Never apply the full recipe merely because one effect or member was selected. For example, selecting Wobbly Lifecycle for window opening applies its opening settings but leaves the closing selection and timing unchanged, even though its example configures both. Competing selections for one slot require a choice.

### Application scope and local window rules

Catalogue `uses` describes suitability. Application scope is selected locally and derived from the effect kind and the installed compositor's supported interface:

| Catalogue use | Local application |
| --- | --- |
| `effects.border` | Global default, matching windows' `border_effect`, or supported temporary window action |
| `effects.window` | Global default, matching windows' `window_effect`, or supported temporary window action |
| `effects.screen` | Global default or a chosen output's `screen_effect` |
| `effects.cursor` | Session-wide selection |
| `animation.<event>` | That event's global selection; no per-application animation rule in the inspected interface |

For a window rule, the plugin maps a chosen border/window preset to the corresponding rule field. It does not apply that recipe's global selector as well. Only supported selections and their required dependencies are installed/applied. If a member requires a global setting, expose that separately rather than silently treating it as window-local. Applying a family to one application must not enable its animations, cursor, or screen members globally.

Local rule records need a stable local identifier, ordered position, match selectors, and an action for each shader field: **Leave unchanged**, **Use this effect**, or **Disable effect**. Store chosen catalogue IDs locally and resolve their runtime preset names at generation. Application IDs, titles, output names, window IDs, and user rules are not published to the API or added to contributor metadata.

The basic rule editor picks an application from `umbriel windows --json` and produces an escaped, anchored app-ID match. Advanced selectors can include titles, tags, content type, and supported window states. Check the installed schema before exposing newer selectors. Persistent rules match identities/states; a runtime window ID belongs only to a temporary action.

For example, the plugin can generate this rule after installing and including Heartbeat:

```toml
[[window_rule]]
match.app_id = "^firefox$"
border_effect = "heartbeat"
```

The wrapper includes the original configuration before appending plugin rules. Matching rules combine by field, with later rules winning. Only shader fields are supplied, so existing geometry, placement, opacity, and other rule fields remain effective. **Leave unchanged** omits the field and exposes existing rules; **Disable effect** emits `"off"`. Removing a plugin rule restores the remaining rule result, which may differ from the global default. Show plugin rule order and explain overlapping matches. [Umbriel window rules](https://docs.noctalia.dev/umbriel/window-rules/).

Runtime overrides have higher precedence than configuration rules. Ordinary global Apply changes the selected kind on current windows/outputs as well as its global default; show this scope in the panel. Snapshot the affected selectors and suppression before switching, then apply to explicit stable targets automatically. Do not require manual resets or change other effect kinds. Future windows still resolve existing rules. A future rule-specific action must target only its chosen scope. [Effect selection](https://docs.noctalia.dev/umbriel/effects/#runtime-selection).

## 6. Selective downloads and companion handling

For a selected effect or set of family members, both website and plugin use the same download manifest:

1. Resolve the transitive dependency graph from the same catalogue snapshot; reject missing references and cycles.
2. Union each selected effect/dependency's `install_files`, deduplicating shared notices and files. The website shows total size; the plugin can subtract verified files already installed.
3. Fetch those files at the pinned revision, preserving repository-relative paths beneath the installation root. Retrieve previews and documentation separately on demand unless a document is a required notice.
4. The website shows manual configuration guidance. The plugin stages downloads, checks paths, sizes, checksums, restricted preset content, and dependency references before making the snapshot available for activation. Downloading alone does not enable an effect.

Publication validation checks file paths, byte counts, checksums, and restricted configuration. The catalogue exposes sizes and checksums for download verification; a browser-side download implementation should verify assembled content against them. The plugin assembles a complete selection automatically. Manual website delivery should make it convenient to obtain all required files with their directory structure; the exact download interaction remains a review decision.

Example: selecting `border/flowering-vine` resolves `window/flowering-vine-overlay`. The download selection contains both presets, both shaders, and their notices. Only the border preset needs a top-level include; the existing include chain supplies the overlay definition. Apply the chosen border preset through `effects.border` or a local `border_effect` rule. Do not also select its companion as a global or rule-level window effect unless the user explicitly chose that separate supported use.

The proposed file URL is:

```text
https://raw.githubusercontent.com/noctalia-dev/community-umbriel-shaders/<source.revision>/<encoded-path>
```

Encode path segments and preserve separators. Accept only the agreed repository/origin, validated relative paths, and a published commit SHA; metadata must not supply arbitrary download hosts or executable hooks. A moved `main` branch does not change an existing snapshot's file URLs. If a pinned file is unavailable, fail rather than substitute the latest file.

Direct downloads come from the user's machine and do not consume Noctalia's authenticated GitHub API quota. They remain subject to GitHub's own delivery limits. No archive service, full repository download, or per-effect release numbering is needed for this draft.

### One installed version and explicit updates

User-owned presets already supplied by the base configuration take precedence over catalogue copies and remain outside plugin update ownership. Comparing them does not adopt or overwrite them.

Keep one committed installed version of each effect and shared dependency. V1 uses one catalogue source revision for the managed library: every installed effect's metadata and files must agree with that snapshot. There is no parallel installation of shader releases and no retained shader-version history. Compatibility labels describe the required compositor API; they do not resolve conflicting bytes or preset definitions.

Adding an effect from the installed snapshot needs only that effect and missing dependencies. Using a newer catalogue for installation or update moves the existing managed library and the new selection to that snapshot together. Check all installed effects and dependency references, show changed effects and compatibility requirements, and fetch only files whose verified hashes differ or are missing. Unchanged files do not need another download. If an installed effect has disappeared, requirements conflict, or a customised file would be replaced, stop and explain what needs resolving; do not silently remove it or keep a second version. A user can defer the update and continue using the existing library offline.

Stage changes outside the active library and validate the complete candidate before switching. Temporary old and candidate files may coexist only for an in-progress transaction or crash recovery. After a successful switch and state recording, remove superseded managed files once no active configuration references them. This temporary staging is not a user-selectable version archive. Updating files referenced by active selections is an explicit Apply operation, since it changes the running effect even if the preset name stays the same; a download-only action must not replace those files.

Manual installation guidance should explain how to preserve customised shaders when replacing files and avoid removing companions still used by other effects. The plugin records the installed source revision, hashes, dependencies, and local selections. Updates must not overwrite customised files silently; removal must retain files needed by other selections. Undo restores selections using the current installed library, not previous shader bytes. An update ends any undo history that requires superseded definitions; show that limitation before applying it. Update checks are explicit, and automatic checks require a separate opt-in.

## 7. Noctalia Shaders plugin integration

### Browser presentation

Lead with preview cards, effect names and visible descriptive tags. Cards show up to two tag chips and a count for additional tags; the shader view shows all tags above its preview. Clicking a tag browses that tag. Text, type and tag filters combine, and Clear resets all three. Descriptive tags aid discovery and never determine activation support.

The normal shader view shows its preview, short description, creator and destination, with Apply, Undo and Restore accessible below the scrolling content. Keep configuration paths, dependencies, licensing, local comparison and the change report behind an optional **Details** view. A short local-copy notice and actionable errors remain visible. Settings, refresh and close belong in the header. The external recording action is explicitly labelled and placed in Details until embedded playback is supported.

### Available host capabilities

Target Noctalia v5's Luau system. A panel supplies browsing and rule controls; a service can own installation/apply operations so closing the panel does not lose an operation. Existing APIs provide HTTP/downloads, files, persistent plugin storage, shared in-memory state, and subprocess execution. Use argument-array `runAsync` calls for dynamic paths and values. Remote previews must be downloaded for `ui.image`. [Runtime API](https://docs.noctalia.dev/noctalia/plugins/development/runtime-api/), [declarative UI](https://docs.noctalia.dev/noctalia/plugins/development/declarative-ui/).

Keep installed shader assets, active configuration generations, undo records, and cached metadata outside `pluginDir()`, which is replaced on update. `pluginDataDir()` is a candidate for persistent records; the final asset/configuration locations must support recovery after plugin removal. Do not depend on in-memory state as the only record of an apply.

Choose `plugin_api` from the actual features used; direct argument arrays require API 24. The inspected bindings expose no general TOML editing or SHA-256 helper. Evaluate a small bundled helper for file verification, include/preset analysis, and configuration generation; do not assume another external installer service is necessary. Native downloads honor Noctalia offline mode. Any helper doing networking must honor the same policy. [Plugin API versions](https://docs.noctalia.dev/noctalia/plugins/development/plugin-api/).

### Candidate configuration and apply transaction

A normal include inside the user's main file cannot override selections in that main file. Prefer a generated wrapper whose includes load the original base config and required presets, followed by plugin-owned selectors, output overrides, and appended window rules. The original file remains editable or declaratively managed. [Include precedence](https://docs.noctalia.dev/umbriel/configuration/#include).

Ordinary **Apply** performs preparation, validation and activation in one action; **Review** is optional. Missing capability evidence does not add a second confirmation. The proposed apply sequence is:

1. Identify and retain the absolute base-config path, including custom `-c` paths. Never use a previous plugin wrapper as the base and recursively include older generations.
2. Resolve the selected snapshot and inspect the base configuration. If a preset already exists locally with the required kind, use that definition as-is, including customised shader bytes, colours, parameters and overlay references. Show **Already exists locally — using your local copy**. Do not rename, shadow or overwrite it, and do not install a replacement or unused catalogue dependencies. An optional comparison against the catalogue is informational; byte/settings differences do not block local reuse. Validate the actual local definition and its dependencies with the compositor. Keep the complete base include graph and any root-only configuration requirements valid.
3. Generate a new candidate at an inactive path, containing only approved plugin changes on top of the base. Preserve the last successful generation and its assets until the transaction succeeds. Do not overwrite files watched by the active configuration while assembling the candidate. Check the full dependency requirements; missing runtime capability evidence is diagnostic only.
4. Run `umbriel config validate -c <candidate>` against the complete configuration. Treat diagnostics as a reason to stop and explain the problem. Detect base-file changes during preparation and revalidate rather than commit a stale plan. Shader-content restrictions apply to downloaded files, not unrelated settings already in the user's base.
5. Invoke `umbriel config-replace <absolute-candidate-path>` and require successful completion before recording the generation as active. The command replaces the active root/watch set and retains the old state on invalid replacement; warnings alone do not reject a replacement, hence the stricter preflight validation. [Config commands](https://docs.noctalia.dev/umbriel/ipc/#config-commands).
6. Apply the selected persistent kind to current stable window/output targets or the cursor, recording previous runtime selectors and suppression in the transaction journal before any mutation. Skip targets that disappear; never fall back to the focused window. Inspect applicable effect state and report compilation failures. Configuration acceptance does not establish successful GPU compilation or prove that every event-specific shader has run. On a detected failure, restore the previous configuration and assets before completing the transaction. On success, record the committed library and configuration, then clean up superseded assets under the one-version policy. Retained selection-undo records must refer only to the current library.

A failed download or validation leaves the active generation intact. A rejected replacement leaves the previous active file/watch set intact. If the process stops between switching and recording state, startup reconciliation must recover or explicitly restore a known generation; it must not assume success from the presence of candidate files. Operation serialization and recovery records belong to the local implementation.

Undo regenerates and validates the previous plugin selections against the current installed library, then switches configuration. It does not restore old shader versions. **Restore original configuration** switches to the base file's current contents after validation. Both operations restore runtime selections and suppression changed by the plugin, including a runtime pool selector and its chosen member, while leaving later external changes alone. Closed windows are skipped. Configured pools can choose a fresh member when their configuration is restored because their hidden selection history is not exposed by IPC. Failure recovery restores both the configuration and affected runtime selections. Removing one plugin rule regenerates the remaining rules and reveals the base behaviour.

### Restart, disable, and capability boundaries

`config-replace` is session-local; it does not change the compositor's next startup command. Prototype restoring the saved selection from local files when the plugin service starts and the correct Umbriel session becomes available. A persistent startup arrangement is an alternative to review, not an assumed side effect. Startup restoration must not download updates or install new effects.

Define disable/uninstall behaviour before release. A proposed default is to restore the base when management is disabled, while leaving active shaders intact across ordinary plugin reloads and Noctalia restarts. Lifecycle callbacks cannot guarantee cleanup after crashes or uninstalling an already-disabled plugin. Keep recovery instructions and referenced files available; never delete assets still used by the compositor. [Plugin lifecycle](https://docs.noctalia.dev/noctalia/plugins/development/entries/#cleaning-up-when-an-entry-exits).

Probe the supported interface and installed schema, not just the nominal Umbriel version. The investigated installation reports Umbriel `0.1.0 (693b689)` and Noctalia `v5.2.1 (4e21d7d)`; those are observations, not established minimum versions. Unsupported config replacement must produce an explicit unsupported/manual-setup path, never a silent direct edit or a false success. Do not switch the configuration of another compositor/session.

Isolated `config validate` probes confirmed that a wrapper can override an original scalar selection while an include inside the original cannot. Live config replacement, generated window-rule behaviour, GPU results, undo, custom configs, and restart/disable recovery remain prototype acceptance work. The integration uses existing interfaces and proposes no compositor changes.

## 8. Catalogue delivery and publication

The agreed first delivery is a raw GitHub file, not a dedicated API endpoint or GitHub Pages site. A publishing workflow will generate `catalogue.json` after reviewed source changes merge and commit it to a dedicated `catalogue` branch. The plugin fetches the latest JSON from that branch and resolves shader and preview files at the exact `source.revision`. See [publication and review](catalogue-publication.md) for the implemented flags, validation workflow and outstanding remote setup.

Only effects and families with `publish = true` enter production output. PR validation is read-only; publication requires trusted post-merge automation and enforced maintainer review on the source branch. Never treat a contributor's publication flag or a successful PR build as permission to publish.

The main plugin browser will show its cached catalogue immediately and refresh in the background, with an explicit Refresh action. Browsing may cache metadata and previews but never installs shader presets or changes the active configuration. Apply downloads missing selected files and dependencies. Existing local presets remain preferred. Offline browsing and installed selections remain usable; reading the public catalogue needs no account or API key. The catalogue host receives no local rules or configuration files.

The inspected native HTTP callback exposes status and body, not response headers. The initial plugin can refresh with a normal GET and compare the source revision; ETag support need not block the consumer.

The generator records the source commit whose bytes were checked, not the later commit containing generated JSON. The repository identity must match where that source commit is publicly available. Publishing replaces the registry atomically, keeps the previous successful registry on failure, and prevents an older run from overwriting a newer result. A failed first publication leaves no catalogue, rather than publishing a fabricated empty success.

Consumers reject unknown schema versions and non-production snapshots. Unknown descriptive fields may be ignored, but unknown capability labels remain diagnostic metadata; unknown activation fields or settings are rejected. Lack of capability evidence does not establish support, but it also does not gate Apply under the latest-Umbriel maintenance policy. New incompatible meanings require a schema-version change; changing a shader does not.

## 9. Review decisions and acceptance examples

Before implementation, agree:

1. **Maintainers:** confirm the publishing repository, code owners and required review rules before enabling the generated `catalogue` branch. Raw GitHub delivery is agreed; no separate API endpoint is required.
2. **Repository maintainers and contributors:** metadata naming, the proposed uses/features vocabulary, notice-file handling, and contribution assistance.
3. **Website maintainers:** effect/family browsing, compatibility presentation, download selection and delivery, and manual configuration guidance.
4. **Plugin maintainers:** activation recipe shape, local rule scope/order, wrapper generation, config-path discovery, helper dependencies, and restart/disable/undo behaviour.
5. **Together:** frontend and plugin ownership, whether one complete registry remains small enough, and whether a later generated 16:9 thumbnail convention would help without adding contributor work.

The examples should demonstrate that:

- Browsing downloads metadata and requested recorded previews, not shaders or the repository archive.
- Glow can be installed independently and applied through the plugin with its existing preset name, then undone; manual installation remains possible.
- Workspace Iris is offered for workspaces, not window opening, and carries reveal-mode and API requirements.
- A contributor can submit the entire Vampire family in one PR. Users can install one member or the family and apply only chosen slots. Applying its border to an application does not enable its animations or cursor globally.
- Flowering Vine installs its overlay exactly once. Global or application-specific border activation does not also select the overlay as a global/rule window effect.
- A companion without explicit standalone uses is installable as a dependency but is not offered as an independent slot selection. Flowering Vine Overlay explicitly declares its existing standalone use.
- Applying Wobbly Lifecycle only to window opening leaves the closing selection and timing unchanged.
- Adding an effect from a newer catalogue reviews changes to the existing library, resolves shared dependencies once, and leaves one committed version per effect. A failed transaction preserves the previous library; a successful update removes superseded shader bytes and does not promise version rollback through Undo.
- Compatibility checks include dependencies. Known API mismatches block Apply; missing shader capability evidence does not gate Apply. The catalogue targets latest Umbriel, and file/configuration checks remain required.
- Picking Firefox generates an exact app-ID rule for Heartbeat. Existing placement and opacity rules remain effective; overlapping shader fields follow the displayed rule order.
- Leave unchanged, Disable effect, removing a rule, undo, and restoring the base produce distinct, documented results. Runtime overrides are reported rather than silently reset.
- Screen/output and session-wide cursor scope are explicit. Unsupported per-application animation choices are not offered.
- Read-only/custom base configs, preset collisions, failed validation, crash recovery, offline startup restoration, and plugin disable/uninstall are exercised before release.
- All required notices survive selective installation, including the notices currently embedded in READMEs.
- Unknown schema versions and failed publication do not produce a broken or partial website catalogue. Unavailable pinned downloads are reported without substituting files from another revision; browsing and downloading never modify local configuration.

The generator and focused tests now exercise metadata, dependencies, files, activation filtering, compatibility decisions and update planning. The example JSON remains a non-installable draft. Committed-source generation reads immutable Git objects; publication still requires review, shader checks, and confirmation that the source commit is publicly available. The local Shaders plugin implements browsing, one-click Apply, local-copy reuse, Undo and Restore; API publication, website downloads and `umbriel-config` integration remain deferred.

### Full catalogue assessment — 2026-10-28

The checkout contains 139 preset directories: 48 animation, 24 border, 22 cursor,
43 window and two screen effects. Root metadata now covers 138 of them, with
154 supported selections, preserved licence notices and existing previews.
`animation/example` remains excluded because its README explicitly says that
Lemmy's original contribution has no declared licence. It has not been relicensed.
The optional `shader-audio.glsl` files in Accent Pulse and Pulse remain documented
manual variants; they are not separately packaged presets in this catalogue.

Ten families are represented: After Dark, Beach Surf, Diwali, Flowering Vine,
Ghostly Tear, kzzzt, Paper, Psychedelic, Vampire and Wobbly. Membership follows
existing packs, documented pairings and related-effects sections. Existing pack
previews and recipes are retained for After Dark and Psychedelic; other family
cards compose member previews. Family pages group members by declared use,
preserve a route back from each member, and expose a fixed **Apply family** action.
The selected uses are prepared and validated as one transaction. Uses with one
member or an explicit family recommendation are preselected; competing members
require a choice or **Keep current**. Skipped uses and unrelated runtime overrides
remain untouched. Companion overlays are resolved by their border, not selected
as global window effects. One Undo restores the whole previous combination;
partial failure rolls back all affected uses. Family-specific settings remain
in effect when a later action changes an unrelated use.
Three overlays (Diya Glow, Fractal Flow and Something’s Watching) remain
companion-only; their examples select the parent border and are not standalone
activation recipes. Other overlays keep the standalone uses explicitly provided
by their existing examples.

The plugin shows 24 shader cards initially and offers Show more; search and
filters always cover the complete catalogue. Root metadata supersedes the nine
historical examples, which remain available as contract fixtures.

Validation: 39 catalogue tests and 64 helper tests; all 154 declared selections
passed configuration validation, GPU compilation, Apply and Restore in a private
software-rendered compositor. The same selections passed with customised local
presets while preserving local file bytes. This does not claim a new visual audit
of every animation endpoint or performance on every GPU. Family navigation and
member-only Apply/Restore are exercised in private Noctalia sessions.
