#!/usr/bin/env bash
# Applies patches to a checkout, in order. A patch whose change the checkout
# already has (it reverse-applies) is skipped, so one set of patches works for
# XLA commits before and after upstream made the same change.
#
# Usage: apply-patches.sh <checkout> <patch>...
set -euo pipefail

dir=$1
shift
for patch in "$@"; do
  patch=$(realpath "$patch")
  if git -C "$dir" apply --check "$patch" 2>/dev/null; then
    git -C "$dir" apply "$patch"
    echo "applied $patch"
  elif git -C "$dir" apply --check --reverse "$patch" 2>/dev/null; then
    echo "skipped $patch: already in the checkout"
  else
    echo "::error::$patch does not apply to $dir"
    git -C "$dir" apply --check "$patch"
    exit 1
  fi
done
