# AGENTS.md — layer-nvidia

Standalone candy repo for the `nvidia` layer — NVIDIA GPU runtime support. The
candy lives in `charly.yml` at the repo root: multi-distro package arms, the
`LD_LIBRARY_PATH` environment, the Vulkan ICD wiring and signature-verification
`plan:` steps, and the embedded `skill:` entity projected into the marketplace
corpus as `/charly-distros:nvidia`.

Canonical files:

- `charly.yml` — the `nvidia:` candy entity and the `nvidia-skill:` skill entity.
- `CHANGELOG/` — per-CalVer release history; read it before changing baked checks.
- `.github/workflows/deploy.yml` — the manifest gate.
- `.github/workflows/tag-on-merge.yml` — CalVer tag + `CHANGELOG/` on merge.
- `README.md` — user overview only; never agent guidance.

## Load these skills first (R0)

- `/charly-distros:nvidia` — the owning skill. GPU runtime, CDI device
  generation, the distro package arms, and verification. Load before editing or
  troubleshooting the layer.
- `/charly-image:layer` — the candy authoring reference (`charly.yml` schema,
  `plan:` step verbs incl. `check:`, per-distro `distro:` arms, package/repo
  sections, and service declarations). Load before editing any entity field or
  plan step.

## Build / validate / test

- `charly box validate` at the repo root — the same structural gate CI runs: the
  manifest must parse and validate at the pinned charly. The CI pin lives in
  `.github/workflows/deploy.yml`; keep the `version:` schema stamp within the
  pinned charly's supported range (do not migrate the stamp past the pin).
- `.github/workflows/deploy.yml` — builds the pinned charly from a CI-time
  checkout and runs `charly box validate`. This is the merge gate.
- The candy's `plan:` `check:` steps are the functional evidence; they must stay
  valid on every distro arm they run on. Where a check only applies to one
  distro family (e.g. a Fedora-only DNF path), scope it in the command itself —
  the check runner does not honour runner-level `exclude-distro` fields.

## Modify this repo

- Edit the `nvidia:` candy entity AND the `nvidia-skill:` skill entity in
  `charly.yml` together. The skill is the projected usage source, so a package,
  distro-arm, or behaviour change that is not mirrored in the skill leaves the
  corpus stale.
- Package changes go in the top-level `package:` or a `distro:` arm; repository
  and signing policy go in the matching `distro:` arm's `repo:` block.
- New behaviour claims belong in the `plan:` as an observable `check:` step, and
  in the skill body. Keep the Fedora signature-verification check intact.

## Landing

- PR-only. Every change lands through a pull request; the org-required
  `charly/pr-validator` validates the diff and body and arms native auto-merge
  on PASS. Direct pushes to `main` are blocked.
- History lives in `CHANGELOG/` (written by `tag-on-merge` at merge time); the
  PR body IS the changelog.
- The authoritative rulebook is the umbrella `AGENTS.md` in
  `opencharly/opencharly` and `charly/AGENTS.md` in the charly repo. Do not
  restate its rules here.
