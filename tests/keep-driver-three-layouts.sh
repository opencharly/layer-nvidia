#!/usr/bin/env bash
# tests/keep-driver-three-layouts.sh — executable coverage for `nvidia-keeps-distro-driver`
# (opencharly/layer-cuda#34). Replaces tests/strip-three-layouts.sh: that test executed the
# duplicate strip this repo no longer carries, and its subject — "the strip empties ALL three
# layouts" — went with the step. The guard that replaced the strip has the same layout question
# from the other side, and this test keeps it covered.
#
# The guard walks ONE layout list (`CDI_KEEP_LIB_DIRS`) and asserts the distro package's driver
# user-space is PRESENT. Two failure modes matter:
#   - a re-added strip empties every layout       -> the guard must FAIL (that is its whole job)
#   - a guard that only looks at the FIRST layout -> passes on an image whose driver lives in
#                                                    another one (the /usr/lib32 and real
#                                                    /usr/lib64 case layer-nvidia#28 measured)
#
# Arms:
#   OTHER — the driver file is in the THIRD layout and the first two are empty: the guard PASSES,
#           so it really walks the list (a first-path-only guard fails here).
#   EMPTY — every layout is empty: the guard FAILS, naming 0 files (a re-added strip).
#
# Exit 0 iff both arms hold. Run from anywhere: bash tests/keep-driver-three-layouts.sh
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
step=$(awk '/id: nvidia-keeps-distro-driver/{f=1} f && /command: \|/{c=1;next} c && (/^            - / || /^[A-Za-z0-9._-]+:$/){exit} c{sub(/^                /,"");print}' "$root/charly.yml")
case "$step" in
  *'libs=${CDI_KEEP_LIB_DIRS:-/usr/lib /usr/lib32 /usr/lib64}'*) : ;;
  *) echo "FAIL: the extracted check does not carry CDI_KEEP_LIB_DIRS (did the check move?)" >&2; exit 1 ;;
esac

scratch=$(mktemp -d); trap 'rm -rf "$scratch"' EXIT

seed() {  # seed <root> [layout-with-driver]
    mkdir -p "$1/a" "$1/b" "$1/c"
    : > "$1/a/libcudart.so.13"          # the CUDA runtime is NOT driver user-space
    [ -n "${2:-}" ] && : > "$1/$2/libcuda.so.1" && : > "$1/$2/libnvidia-ml.so.1"
    [ -z "${2:-}" ] && : > "$1/a/libcudart_static.a"
    true
}

run_guard() {  # run_guard <root>
    CDI_KEEP_LIB_DIRS="$1/a $1/b $1/c" bash -c "$step"
}

failed=0

# ── OTHER: the driver lives in the THIRD layout ────────────────────────────────────
r="$scratch/other"; seed "$r" c
if out=$(run_guard "$r" 2>&1); then rc=0; else rc=$?; fi
printf 'OTHER arm (rc=%s):\n%s\n' "$rc" "$out" | sed 's/^/  /'
[ "$rc" -eq 0 ] || { echo "FAIL: the guard missed a driver in the third layout" >&2; failed=1; }
case "$out" in
  *'driver user-space files present: 2'*) ;;
  *) echo "FAIL: the guard did not count the two driver files in the third layout" >&2; failed=1 ;;
esac

# ── EMPTY: every layout empty (a re-added strip) ───────────────────────────────────
r="$scratch/empty"; seed "$r"
if out=$(run_guard "$r" 2>&1); then rc=0; else rc=$?; fi
printf 'EMPTY arm (rc=%s):\n%s\n' "$rc" "$out" | sed 's/^/  /'
[ "$rc" -ne 0 ] || { echo "FAIL: the guard PASSED with no driver user-space at all (a re-added strip would be silent)" >&2; failed=1; }

if [ "$failed" -eq 0 ]; then
    echo 'keep-driver-three-layouts: both arms behaved (walks every layout; an emptied image fails)'
else
    echo 'keep-driver-three-layouts: FAILED'
fi
exit "$failed"
