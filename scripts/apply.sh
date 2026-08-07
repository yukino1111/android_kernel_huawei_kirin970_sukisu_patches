#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kernel_tree="${1:?Usage: apply.sh KERNEL_TREE SUKISU_TREE}"
sukisu_tree="${2:?Usage: apply.sh KERNEL_TREE SUKISU_TREE}"
kernel_commit="b8f2dd993aa2f67ceefd98b5475fec29c6032f6b"
sukisu_commit="b1d534bc41941b2c818d7a1a1dac341e4aabfc2d"

"$repo_root/scripts/verify.sh"

for tree in "$kernel_tree" "$sukisu_tree"; do
  git -C "$tree" rev-parse --is-inside-work-tree >/dev/null
  [ -z "$(git -C "$tree" status --porcelain --untracked-files=all)" ] || {
    echo "Worktree is not clean: $tree" >&2
    exit 2
  }
done

[ "$(git -C "$kernel_tree" rev-parse HEAD)" = "$kernel_commit" ] || {
  echo "Unexpected kernel commit" >&2
  exit 2
}
[ "$(git -C "$sukisu_tree" rev-parse HEAD)" = "$sukisu_commit" ] || {
  echo "Unexpected SukiSU commit" >&2
  exit 2
}
[ ! -e "$kernel_tree/drivers/kernelsu" ] || {
  echo "drivers/kernelsu already exists" >&2
  exit 2
}

while IFS= read -r patch_name; do
  git -C "$sukisu_tree" apply "$repo_root/patches/sukisu/$patch_name"
done < "$repo_root/patches/sukisu/series"

mkdir -p "$kernel_tree/drivers/kernelsu"
cp -a "$sukisu_tree/kernel/." "$kernel_tree/drivers/kernelsu/"

while IFS= read -r patch_name; do
  git -C "$kernel_tree" apply "$repo_root/patches/kernel/$patch_name"
done < "$repo_root/patches/kernel/series"

echo "Patches applied. No commit was created."
