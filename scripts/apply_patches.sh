#!/bin/bash
set -e

# Apply additional patch

if [ "$kernelsu_variant" == "SukiSU" ]; then
    cp ../SukiSU_patch/69_hide_stuff.patch ./
    patch -p1 -F 3 < 69_hide_stuff.patch

    echo "Apply more patches from WildPlus"

    ls -la ../
    ls -la ../kernel_patches/


    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/fix_Makefile.patch ./
    patch -p1 -F 3 < fix_Makefile.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/fix_allowlist.c.patch ./
    patch -p1 -F 3 < fix_allowlist.c.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/fix_kernel_umount.c.patch ./
    patch -p1 -F 3 < fix_kernel_umount.c.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/fix_ksu.c.patch ./
    patch -p1 -F 3 < fix_ksu.c.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/fix_ksud.c.patch ./
    patch -p1 -F 3 < fix_ksud.c.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/fix_sucompat.c.patch ./
    patch -p1 -F 3 < fix_sucompat.c.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/fix_supercalls.c.patch ./
    patch -p1 -F 3 < fix_supercalls.c.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/ksu_toolkit.patch ./
    patch -p1 -F 3 < ksu_toolkit.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/multi_manager.patch ./
    patch -p1 -F 3 < multi_manager.patch

    cp ../kernel_patches/next/susfs_fix_patches/v2.0.0/overwrite_hook_mode.patch ./
    patch -p1 -F 3 < overwrite_hook_mode.patch
else
    cp ../kernel_patches/69_hide_stuff.patch ./
    patch -p1 -F 3 < 69_hide_stuff.patch
fi
