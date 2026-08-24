#!/usr/bin/env bash
set -euo pipefail

kernel_root="$PWD"
ksu_ref="${1:-v4.1.0}"
ksu_repo="${RESUKISU_REPO:-https://github.com/ReSukiSU/ReSukiSU.git}"

if [ -d "$kernel_root/common/drivers" ]; then
  driver_dir="$kernel_root/common/drivers"
  kernel_link="../../KernelSU/kernel"
elif [ -d "$kernel_root/drivers" ]; then
  driver_dir="$kernel_root/drivers"
  kernel_link="../KernelSU/kernel"
else
  echo 'drivers directory not found' >&2
  exit 127
fi

ksu_dir="$kernel_root/KernelSU"
if [ ! -d "$ksu_dir/.git" ]; then
  if [ -e "$ksu_dir" ]; then
    echo "KernelSU exists but is not a Git checkout: $ksu_dir" >&2
    exit 1
  fi
  git clone "$ksu_repo" "$ksu_dir"
fi

git -C "$ksu_dir" fetch --force --tags origin
if ! git -C "$ksu_dir" diff --quiet || ! git -C "$ksu_dir" diff --cached --quiet; then
  git -C "$ksu_dir" stash push --include-untracked --message kokuban-ci-setup
fi
git -C "$ksu_dir" checkout "$ksu_ref"

ln -sfn "$kernel_link" "$driver_dir/kernelsu"

if ! grep -q 'kernelsu/' "$driver_dir/Makefile"; then
  printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$driver_dir/Makefile"
fi

if ! grep -q 'source "drivers/kernelsu/Kconfig"' "$driver_dir/Kconfig"; then
  sed -i '/endmenu/i\source "drivers/kernelsu/Kconfig"' "$driver_dir/Kconfig"
fi

printf 'ReSukiSU integrated from %s at %s\n' "$ksu_repo" "$ksu_ref"
