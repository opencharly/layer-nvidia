# layer-nvidia

The `layer-nvidia` candy of the [opencharly/charly](https://github.com/opencharly/charly)
candy library, as a standalone repo (the candy de-submodule cutover).

The candy manifest lives at the repo root (`charly.yml`); the charly resolver
fetches this repo at the pinned tag (`@github.com/opencharly/layer-nvidia:v<tag>`).

## Pins

- `charly` — the charly checkout this candy's manifest is validated against,
  cloned into `.ci/charly` at CI time at the pinned tag (no committed
  submodule).

## Gate

`.github/workflows/deploy.yml` builds charly from the pinned checkout and runs
`charly box validate` on this repo's `charly.yml` — the manifest must parse and
validate at the pinned charly (the project schema version tracks the pin).
