#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

(
  cd "$repo_root"
  test -s SOURCE_STATE
)

check_sha256() {
  local state_key=$1 relative_path=$2 expected actual
  expected="$(sed -n "s/^${state_key}=//p" "$repo_root/SOURCE_STATE")"
  [ -n "$expected" ] || {
    echo "Missing SOURCE_STATE key: $state_key" >&2
    exit 1
  }
  actual="$(sha256sum "$repo_root/$relative_path" | awk '{print $1}')"
  [ "$actual" = "$expected" ] || {
    echo "SHA-256 mismatch: $relative_path" >&2
    exit 1
  }
}

while IFS= read -r patch_name; do
  [ -n "$patch_name" ]
  [ -f "$repo_root/patches/kernel/$patch_name" ]
done < "$repo_root/patches/kernel/series"

while IFS= read -r patch_name; do
  [ -n "$patch_name" ]
  [ -f "$repo_root/patches/sukisu/$patch_name" ]
done < "$repo_root/patches/sukisu/series"

check_sha256 kernel_patch_sha256 \
  patches/kernel/0001-par-android13-sukisu-susfs2.patch
check_sha256 vdec_smmu_patch_sha256 \
  patches/kernel/0002-kirin970-vdec-keep-protected-smr-in-secure-world.patch
check_sha256 sukisu_compat_patch_sha256 \
  patches/sukisu/0001-par-nongki-susfs2-compat.patch
check_sha256 sukisu_offline_patch_sha256 \
  patches/sukisu/0002-reproducible-offline-version.patch
check_sha256 sukisu_sucompat_patch_sha256 \
  patches/sukisu/0003-gate-sucompat-by-authorized-uid.patch
check_sha256 config_sha256 configs/par_susfs2_enforcing.config

echo "Patch archive structure checks passed"
