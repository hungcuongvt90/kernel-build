#!/bin/bash
set -e

# Apply additional patch

if [ "$kernelsu_variant" == "SukiSU" ]; then
    cp ../SukiSU_patch/69_hide_stuff.patch ./
    patch -p1 -F 3 < 69_hide_stuff.patch

    echo "Apply more patches from WildPlus"

    PATCH_DIR="../kernel_patches/next/susfs_fix_patches/v2.0.0"
    patches=(
        # "fix_Makefile.patch"
        # "fix_allowlist.c.patch"
        # "fix_kernel_umount.c.patch"
        # "fix_ksu.c.patch"
        # "fix_ksud.c.patch"
        # "fix_sucompat.c.patch"
        # "fix_supercalls.c.patch"
        # "ksu_toolkit.patch"
        # "multi_manager.patch"
        # "overwrite_hook_mode.patch"
    )

    for patch in "${patches[@]}"; do
        cp "$PATCH_DIR/$patch" ./
        patch -p1 -F 3 < "$patch"
    done
else
    cp ../kernel_patches/69_hide_stuff.patch ./
    patch -p1 -F 3 < 69_hide_stuff.patch
fi
