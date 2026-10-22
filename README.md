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

## CDI host layer

`nvidia-cdi-host` is the host-side companion: it composes `nvidia` and configures
a host's containerd for CDI. It runs `nvidia-ctk runtime configure
--runtime=containerd` with a layer-owned drop-in
(`/etc/containerd/conf.d/99-nvidia.toml`), without `--enable-cdi` (ignored on
containerd 2.x) and without `--set-as-default`, and fails closed if the handler
or the config `imports` entry does not land. It enables the toolkit's
`nvidia-cdi-refresh.path` / `.service` so `/var/run/cdi/nvidia.yaml` is
regenerated rather than snapshotted, and links that refreshed file into the
rootless client's config dir (`~/.config/cdi/nvidia.yaml`).

The checks gate on the device, not an exit code: `nvidia-ctk cdi list` exits 0 on
an invalid spec, so the layer asserts that `crictl info` serves the `nvidia`
handler, the list reports `nvidia.com/gpu=all`, and a
`--device nvidia.com/gpu=all` container runs `nvidia-smi -L`. The
`check-nvidia-cdi-host` bed proves that sequence rootful and rootless on a GPU
host; on a host without the GPU it skips visibly with `prereq-gpu-skipped`.

Arch/omarchy only: the Fedora arm is additive and is not claimed until its own
disposable bed exists.

## Layout

- `charly.yml` — the candy manifest: the multi-distro package arms, the
  `LD_LIBRARY_PATH` environment, the Vulkan ICD wiring `plan:`, the `plan:`
  checks, the CDI host layer and its GPU bed, and the embedded `skill:` entity.
- `CHANGELOG/` — per-CalVer release notes.
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
