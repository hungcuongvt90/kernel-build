#!/bin/bash
set -e

if [ "$kernelsu_variant" == "Official" ]; then
  echo "Applying SUSFS patches for Official KernelSU..."
  cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./
  patch -p1 --forward --fuzz=3 < 10_enable_susfs_for_ksu.patch || true
elif [ "$kernelsu_variant" == "Next" ]; then
  echo "Applying SUSFS patches for KernelSU-Next..."
  cp ../kernel_patches/next/next_hooks.patch ./
  patch -p1 -F 3 < next_hooks.patch
elif [ "$kernelsu_variant" == "MKSU" ]; then
  echo "Applying SUSFS patches for MKSU..."
  cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./
  patch -p1 --forward --fuzz=3 < 10_enable_susfs_for_ksu.patch || true
  echo "Applying MKSU specific SUSFS patch..."
  cp ../kernel_patches/mksu/mksu_susfs.patch ./
  patch -p1 < mksu_susfs.patch || true
  cp ../kernel_patches/mksu/fix.patch ./
  patch -p1 < fix.patch || true
elif [ "$kernelsu_variant" == "SukiSU" ]; then
  echo "Applying SUSFS patches for SukiSU..."
  cp ../susfs4ksu/kernel_patches/50_add_susfs_in_${SUSFS_BRANCH}.patch ./
  cp ../susfs4ksu/kernel_patches/fs/* ./fs/
  cp ../susfs4ksu/kernel_patches/include/linux/* ./include/linux/

  patch -p1 < 50_add_susfs_in_${SUSFS_BRANCH}.patch || true

  if [ "${HOOK_VARIANT}" == "scope_min_manual" ]; then
    echo "Apply scope min manual hook patches"
    cp ../SukiSU_patch/hooks/scope_min_manual_hooks_v1.6.patch ./
    patch -p1 -F 3 < scope_min_manual_hooks_v1.6.patch
  else
    echo "Apply syscall hook patches"
    cp ../SukiSU_patch/hooks/syscall_hooks.patch ./
    patch -p1 -F 3 < syscall_hooks.patch
  fi
else
  echo "Invalid KernelSU variant selected!"
  exit 1
fi

echo "ANYKERNEL3_FILE_NO_KPM=${kernelsu_variant} ${HOOK_VARIANT} ${KERNEL_NAME} ${BUILD_DATE} NO KPM" >> "$GITHUB_ENV"
echo "RELEASE_TAG_NAME=${kernelsu_variant} ${HOOK_VARIANT} ${KERNEL_NAME} ${BUILD_DATE} NO KPM" >> "$GITHUB_ENV"
