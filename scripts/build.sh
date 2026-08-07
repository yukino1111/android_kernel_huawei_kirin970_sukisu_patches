#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kernel_tree="${1:?Usage: build.sh PATCHED_KERNEL_TREE}"
: "${ANDROID_BUILD_ROOT:?Set ANDROID_BUILD_ROOT to a writable Linux filesystem directory}"
: "${TOOLCHAIN_DIR:?Set TOOLCHAIN_DIR to aarch64-linux-android-4.9}"

component_root="$ANDROID_BUILD_ROOT/par/kernel"
out_dir="$component_root/out"
log_dir="$component_root/logs"
artifact_dir="$component_root/artifacts"
config_file="$repo_root/configs/par_susfs2_enforcing.config"
jobs="${JOBS:-$(nproc)}"
build_id="${BUILD_ID:-$(date -u +%Y%m%d-%H%M%S)}"
log_file="$log_dir/build-$build_id.log"
build_artifact_dir="$artifact_dir/$build_id"

[ -x "$TOOLCHAIN_DIR/bin/aarch64-linux-android-gcc" ] || {
  echo "Toolchain not found: $TOOLCHAIN_DIR" >&2
  exit 2
}

mkdir -p "$out_dir" "$log_dir" "$build_artifact_dir"
cp "$config_file" "$out_dir/.config"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export PATH="$TOOLCHAIN_DIR/bin:$PATH"
export KBUILD_BUILD_USER=android
export KBUILD_BUILD_HOST=android-build

{
  echo "BUILD_ID=$build_id"
  echo "KERNEL_TREE=$kernel_tree"
  echo "CONFIG_SHA256=$(sha256sum "$config_file" | awk '{print $1}')"
  make -C "$kernel_tree" O="$out_dir" olddefconfig
  make -C "$kernel_tree" O="$out_dir" -j"$jobs"
  test -s "$out_dir/arch/arm64/boot/Image.gz"
  cp "$out_dir/arch/arm64/boot/Image.gz" "$build_artifact_dir/Image.gz"
  sha256sum "$build_artifact_dir/Image.gz" | tee "$build_artifact_dir/SHA256SUMS"
} 2>&1 | tee "$log_file"

echo "Build completed: $build_artifact_dir/Image.gz"
