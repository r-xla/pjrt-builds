#!/usr/bin/env bash
# Re-vendor the IREE fork's PJRT C API header from the r-xla/pjrt R package.
#
#   ./revendor-from-pjrt.sh <path-to-pjrt> <path-to-iree>
#
# The fork's own third_party/pjrt_c_api/revendor.py copies a header verbatim
# and regenerates the stub table; it deliberately knows nothing about this
# stack and refuses a header whose PJRT_Api fields have been renamed.
#
# pjrt's copy *is* renamed: tools/patch/inst-include-xla-pjrt-c-pjrt_c_api.h.patch
# appends an underscore to every field, because in C++ a member named
# identically to its own type is ambiguous in some contexts. That is a name
# change only -- offsets, sizes and therefore the ABI are untouched -- but the
# IREE tree assigns the upstream names.
#
# So this wrapper reverses pjrt's own patch into a temporary copy and hands
# that to the generic script. Reversing pjrt's patch file, rather than
# reimplementing the rename, means the two can never drift: if pjrt changes
# what it patches, this fails loudly instead of vendoring something subtly
# wrong.
#
# Why vendor from pjrt at all, rather than from an openxla/xla checkout: the
# plugin and its caller must agree on the API exactly. The caller fills each
# _Args struct's struct_size from its own header and the plugin reads it, so a
# skew is not a compile error but a silently truncated struct at run time.
# Taking the header from the client we actually load guarantees the match
# instead of assuming it.
set -euo pipefail

PJRT="${1:?usage: revendor-from-pjrt.sh <path-to-pjrt> <path-to-iree>}"
IREE="${2:?usage: revendor-from-pjrt.sh <path-to-pjrt> <path-to-iree>}"

HEADER="$PJRT/inst/include/xla/pjrt/c/pjrt_c_api.h"
PATCHFILE="$PJRT/tools/patch/inst-include-xla-pjrt-c-pjrt_c_api.h.patch"
SCRIPT="$IREE/integrations/pjrt/third_party/pjrt_c_api/revendor.py"

for f in "$HEADER" "$PATCHFILE" "$SCRIPT"; do
  [ -f "$f" ] || { echo "missing: $f" >&2; exit 1; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$HEADER" "$TMP/pjrt_c_api.h"

# -R reverses pjrt's rename. Without --forward patch would ask questions on a
# mismatch; failing here is the point.
patch -R -s -p1 --input="$PATCHFILE" "$TMP/pjrt_c_api.h"

"$SCRIPT" --from "$TMP/pjrt_c_api.h"

echo
echo "Now rebuild the plugin from scratch -- an incremental build after"
echo "re-vendoring silently mixes API versions."
