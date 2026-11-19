#!/usr/bin/env bash
# tests/strip-three-layouts.sh — executable coverage for
# `nvidia-drop-driver-userspace` (opencharly/layer-nvidia#28).
#
# The step walks ONE layout list (`libs`) for its baseline, its driver-library
# delete, the nvidia/vdpau/xorg tree removals and its residue re-check. A
# single-path walk leaves `/usr/lib32` (multilib) and a real `/usr/lib64` baked
# while the assertion prints 0. This test EXTRACTS the shipped shell block from
# charly.yml (it is not a copy: the bytes under test are the bytes that build)
# and runs it against a symmetric three-layout fixture.
#
# Arms:
#   NEW  — the shipped list: every driver file and tree is gone from all three
#          layouts, and every `libcudart*` the strip must KEEP survives.
#   MUT  — the list narrowed to one path through the step's own knob: the other
#          two layouts keep their driver files and trees (the list is
#          load-bearing, and the step's own assertion is blind to the narrowing).
#
# Exit 0 iff both arms hold. Run from anywhere: bash tests/strip-three-layouts.sh
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
step=$(sed -n '/id: nvidia-drop-driver-userspace/,/^            - /p' "$root/charly.yml" \
        | sed -n '/^              command: |$/,/^            - /p' \
        | sed '1d;$d' | sed 's/^                //')
case "$step" in
  *'libs=${NVIDIA_STRIP_LIB_DIRS:-/usr/lib /usr/lib32 /usr/lib64}'*) : ;;
  *) echo "FAIL: the extracted step does not carry the ONE layout list (did the step move?)" >&2; exit 1 ;;
esac

scratch=$(mktemp -d) || exit 1
trap 'rm -rf "$scratch"' EXIT

fixture() { # $1 = root
  local r=$1 d
  for d in usr/lib usr/lib32 usr/lib64; do
    mkdir -p "$r/$d/nvidia" "$r/$d/vdpau" "$r/$d/xorg/modules/drivers"
    : > "$r/$d/libcuda.so.1"
    : > "$r/$d/libnvidia-ml.so.1"
    : > "$r/$d/libcudadebugger.so.1"
    : > "$r/$d/libGLX_nvidia.so.0"
    : > "$r/$d/nvidia/libGLX_nvidia.so.0"
    : > "$r/$d/vdpau/libvdpau_nvidia.so.1"
    : > "$r/$d/xorg/modules/drivers/nvidia_drv.so"
    : > "$r/$d/libcudart.so.13"
  done
}

driver_files() { # $1 = root
  find "$1"/usr/lib "$1"/usr/lib32 "$1"/usr/lib64 -maxdepth 1 \
    \( -type f -o -type l \) \
    \( -name 'libnvidia-*.so*' -o -name 'libcuda.so*' -o -name 'libcudadebugger.so*' \) 2>/dev/null | wc -l
}
tree_entries() { # $1 = root
  find "$1"/usr/lib/nvidia "$1"/usr/lib/vdpau \
       "$1"/usr/lib32/nvidia "$1"/usr/lib32/vdpau \
       "$1"/usr/lib64/nvidia "$1"/usr/lib64/vdpau -mindepth 1 2>/dev/null | wc -l
}
runtime_files() { # $1 = root
  find "$1"/usr/lib "$1"/usr/lib32 "$1"/usr/lib64 -maxdepth 1 -name 'libcudart*' 2>/dev/null | wc -l
}

failed=0

# ── NEW: the shipped list, all three layouts ───────────────────────────────────────
new="$scratch/new"
fixture "$new"
if NVIDIA_STRIP_LIB_DIRS="$new/usr/lib $new/usr/lib32 $new/usr/lib64" bash -c "$step" > "$scratch/new.out" 2>&1; then
  n=$(driver_files "$new"); t=$(tree_entries "$new"); k=$(runtime_files "$new")
  if [ "$n" -eq 0 ] && [ "$t" -eq 0 ] && [ "$k" -eq 3 ]; then
    echo "PASS  NEW: 0 driver files and 0 tree entries left across three layouts; 3/3 libcudart* kept"
  else
    echo "FAIL  NEW: driver_files=$n tree_entries=$t libcudart=$k (want 0/0/3)" >&2; failed=1
  fi
else
  echo "FAIL  NEW: the step exited non-zero:" >&2; sed 's/^/      /' "$scratch/new.out" >&2; failed=1
fi

# ── MUT: the same bytes, the list narrowed to one path ─────────────────────────────
mut="$scratch/mut"
fixture "$mut"
if NVIDIA_STRIP_LIB_DIRS="$mut/usr/lib" bash -c "$step" > "$scratch/mut.out" 2>&1; then
  n=$(driver_files "$mut"); t=$(tree_entries "$mut")
  if [ "$n" -eq 6 ] && [ "$t" -ge 4 ]; then
    echo "PASS  MUT: narrowing the list leaves $n driver files and $t tree entries (the list is load-bearing)"
  else
    echo "FAIL  MUT: driver_files=$n tree_entries=$t (want 6 and >=4)" >&2; failed=1
  fi
else
  echo "FAIL  MUT: the step exited non-zero:" >&2; sed 's/^/      /' "$scratch/mut.out" >&2; failed=1
fi

[ "$failed" -eq 0 ] && echo "strip-three-layouts: OK" || { echo "strip-three-layouts: FAIL" >&2; exit 1; }
