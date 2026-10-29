# Catalogue publication and review

Contributors can keep experiments in this repository and submit them through
ordinary pull requests. Set this flag in an effect's `metadata.toml`, or inside
a `[families.<id>]` table in root `families.toml`:

```toml
publish = false
```

Missing flags mean `false`. Maintainers review and test an entry before approving
`publish = true`. Descriptive tags never override this decision. Published
effects require published dependencies; published families require published
members. To withdraw an entry, set it back to `false` and update any published
dependants or families in the same change.

The upstream migration marks 136 catalogue effects and ten families as eligible.
This fork also retains six additional effects and their family memberships. It does not publish a remote endpoint or claim new visual testing.

## Contributor checks

The read-only **Catalogue checks / Validate catalogue** workflow runs contract
tests and generates a registry from the checked-out commit. It does not deploy,
push commits, or grant a PR permission to publish. Its checks cover metadata and
packaging, not GPU compilation or visual behaviour.

Locally, run:

```sh
python3 -m unittest discover -s tools -p test_catalogue.py
python3 tools/catalogue.py --draft --output /tmp/catalogue.json
python3 tools/catalogue.py --draft --include-unpublished --output /tmp/catalogue-development.json
```

The last command validates experiments as well. Both files are development
snapshots. Production generation accepts only a full committed source revision
and rejects `--include-unpublished`. The plugin's configured local-checkout mode
deliberately includes experiments; its future online consumer must reject draft
snapshots.

## Required repository settings before publication

A contributor can propose `publish = true`; the field is not authorization.
Before enabling an automatic publisher, repository administrators must:

1. Assign the actual maintainer accounts/team as code owners for shader content,
   metadata, families, notices, catalogue tools and `.github/` (including the
   ownership file itself). Reviewing only the flags is insufficient: editing
   an already-published shader also changes what users download.
2. Require pull requests and code-owner approval on the source branch. Dismiss
   stale approvals after new changes, and restrict bypasses to the intended
   maintainers. Require the **Validate catalogue** status check.
3. Limit writes to the generated `catalogue` branch to the publishing workflow
   and intended maintainers. Never publish PR builds or unreviewed PR artifacts.

GitHub documents [code-owner review enforcement](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
and [required reviews on protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches).
These are remote repository settings; adding the generator and validation
workflow does not enable them. No remote review rules have been changed by this
implementation.

## Online delivery plan

The agreed delivery uses raw GitHub files, without GitHub Pages or a separate
API server. After a reviewed source change merges and passes checks, a future
publishing job will generate `catalogue.json` and commit it to a dedicated
`catalogue` branch. Only that trusted job needs write permission.

The plugin will fetch the branch's latest JSON. Shader and preview paths resolve
against the registry's immutable `source.revision`, with downloaded bytes checked
against the recorded sizes and hashes. That revision identifies the source
commit, not the later generated-JSON commit. This is consistent downloading, not
multiple installed shader versions.

Publishing must retain the last good registry on failure and prevent an older,
slower run from replacing a newer result. The source repository identity in the
registry must match the repository where that commit is publicly available;
the current generator names the upstream Noctalia community repository, so a
fork publisher must not publish that identity unchanged.

The publishing job and remote plugin downloads are not implemented by this
publication-flag change. Local filtering and validation are ready for that step.
