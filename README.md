# nvidia

NVIDIA GPU runtime layer for OpenCharly images.

The `nvidia` candy prepares an image to use an NVIDIA GPU. It installs
`nvidia-container-toolkit` — the `nvidia-ctk` CLI that generates CDI device
specs — together with the per-distro driver libraries, exports
`LD_LIBRARY_PATH=/usr/lib64` so the driver libraries resolve, and prepares
`/etc/vulkan/icd.d` to hold the NVIDIA Vulkan ICD symlinks. It is the GPU
runtime base that GPU-accelerated boxes compose; the CUDA toolchain is a
separate `cuda` layer.

## What it provides

| Property | Value |
|---|---|
| Layer / candy | `nvidia` |
| Package | `nvidia-container-toolkit` (all distros) |
| Binary | `/usr/bin/nvidia-ctk` |
| Environment | `LD_LIBRARY_PATH=/usr/lib64` |
| Directory | `/etc/vulkan/icd.d` (NVIDIA Vulkan ICD / layer symlinks) |
| Service / port | none |

Per-distro driver packages:

- `arch` / `omarchy` — `nvidia-utils`
- `fedora` — `libva-nvidia-driver` (from the negativo17 `fedora-multimedia`
  repo) plus NVIDIA's own `nvidia-container-toolkit` repo, with package
  signature verification enforced (`gpgcheck=1`, overriding NVIDIA's shipped
  `gpgcheck=0`).

## How to use it

Compose the layer by pinning this repo in a box's `candy:` list:

```yaml
my-box:
  candy:
    base: fedora                       # or cachyos / omarchy for the Arch driver layout
    candy:
      - '@github.com/opencharly/layer-nvidia:v2026.245.1541'
```

Once the image is built and the GPU is attached by the runtime:

```bash
nvidia-smi                 # GPU information
nvidia-ctk --version       # CDI toolkit
```

The layer bakes every artifact (package, `nvidia-ctk` binary, exported path,
Vulkan ICD directory) into the image, so it is verifiable without a physical
GPU. A GPU-accelerated box pairs it with `cuda` (CUDA toolkit, cuDNN) — for
example `python-ml`, `jupyter`, `ollama`, and `comfyui`.

## Layout

- `charly.yml` — the candy manifest: the multi-distro package arms, the
  `LD_LIBRARY_PATH` environment, the Vulkan ICD wiring `plan:`, the `plan:`
  checks, and the embedded `skill:` entity.
- `CHANGELOG/` — per-CalVer release notes.
- `.github/workflows/` — the org-wide `charly/pr-validator` gate; no per-repo candy gate.
- `.github/workflows/tag-on-merge.yml` — CalVer tag + `CHANGELOG/` on merge.
- `README.md` — this user overview.

## Related

- Owning skill: `/charly-distros:nvidia`
- CUDA toolkit: `/charly-distros:cuda`
- Derived GPU boxes: `/charly-languages:python-ml`, `/charly-jupyter:jupyter`,
  `/charly-ollama:ollama`, `/charly-comfyui:comfyui`
- Arch/CachyOS GPU base sibling: `cachyos.nvidia` in `opencharly/distro-cachyos`
- [`opencharly/charly`](https://github.com/opencharly/charly) — the charly CLI and image builder
- [`opencharly/opencharly`](https://github.com/opencharly/opencharly) — the umbrella
