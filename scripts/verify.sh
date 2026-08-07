#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

(
  cd "$repo_root"
  test -s SOURCE_STATE
)

while IFS= read -r patch_name; do
  [ -n "$patch_name" ]
  [ -f "$repo_root/patches/kernel/$patch_name" ]
done < "$repo_root/patches/kernel/series"

while IFS= read -r patch_name; do
  [ -n "$patch_name" ]
  [ -f "$repo_root/patches/sukisu/$patch_name" ]
done < "$repo_root/patches/sukisu/series"

echo "Patch archive structure checks passed"
