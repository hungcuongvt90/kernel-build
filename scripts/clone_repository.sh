#!/bin/bash
set -e

# Define variables from environment
export WORKSPACE=${WORKSPACE:? "WORKSPACE must be set"}
export OUT_DIR=${OUT_DIR:? "OUT_DIR must be set"}
export BUILD_DATE=${BUILD_DATE:-$(date +%Y%m%d)}

# Kernel source configuration (Mandatory)
export SRC_DIR=${SRC_DIR:? "SRC_DIR must be set"}
export KERNEL_NAME=${KERNEL_NAME:? "KERNEL_NAME must be set"}
export KERNEL_REPO=${KERNEL_REPO:? "KERNEL_REPO must be set"}
export KERNEL_BRANCH=${KERNEL_BRANCH:? "KERNEL_BRANCH must be set"}
export KERNEL_DEFCONFIG_PATH=${KERNEL_DEFCONFIG_PATH:? "KERNEL_DEFCONFIG_PATH must be set"}

# Optional configuration with sensible defaults
export KERNEL_DEVICE=${KERNEL_DEVICE:-"gki"}
export KERNEL_PATCH_REPO_URL=${KERNEL_PATCH_REPO_URL:-https://github.com/SukiSU-Ultra/SukiSU_patch}
export HOOK_VARIANT=${HOOK_VARIANT:-tracepoint}
export SUSFS_BRANCH=${SUSFS_BRANCH:-gki-android13-5.15}
export USE_ZRAM=${USE_ZRAM:-false}
export ZRAM_PATCH_VERSION=${ZRAM_PATCH_VERSION:-5.15}
export USE_KPM=${USE_KPM:-true}

export ENABLE_CCACHE=${ENABLE_CCACHE:-true}
export CCACHE_DIR=${CCACHE_DIR:-"${WORKSPACE}/ccache"}

export USE_ANYKERNEL3=${USE_ANYKERNEL3:-true}
export ENABLE_KERNELSU=${ENABLE_KERNELSU:-true}
export ENABLE_KERNELSU_SFS=${ENABLE_KERNELSU_SFS:-true}
export kernelsu_branch=${kernelsu_branch:-Stable}
export kernelsu_variant=${kernelsu_variant:-SukiSU}

# External URLs (Optional override)
export SUSFS_REPO_URL=${SUSFS_REPO_URL:-https://github.com/ShirkNeko/susfs4ksu.git}
export SUKISU_PATCH_REPO_URL=${SUKISU_PATCH_REPO_URL:-https://github.com/SukiSU-Ultra/SukiSU_patch.git}
export WILD_PATCH_REPO_URL=${WILD_PATCH_REPO_URL:-https://github.com/WildKernels/kernel_patches.git}
export ANYKERNEL3_REPO_URL=${ANYKERNEL3_REPO_URL:-https://github.com/WildPlusKernel/AnyKernel3}
export BASEBAND_GUARD_URL=${BASEBAND_GUARD_URL:-https://github.com/vc-teahouse/Baseband-guard/raw/main/setup.sh}
export KPM_PATCH_URL=${KPM_PATCH_URL:-https://raw.githubusercontent.com/ShirkNeko/SukiSU_patch/refs/heads/main/kpm/patch_linux}

export ARCH="arm64"
export kernel_version=5.15
export CC=${CC:-clang}
export baseband_guard=${baseband_guard:-false}

# Script directory (absolute path as installed in Docker)
SCRIPT_DIR="/app/scripts"

# Ensure directories exist
mkdir -p "$WORKSPACE" "$OUT_DIR"

# Initialize ccache
if [ "$ENABLE_CCACHE" = "true" ]; then
    mkdir -p "$CCACHE_DIR"
    export CCACHE_DIR
    ccache -o compression=false -o cache_dir="$CCACHE_DIR"
fi

cd "$SRC_DIR"

echo "Cloning repositories..."

# Clone Kernel
if [ ! -d "$KERNEL_NAME" ]; then
    git clone --recursive --depth=1 -j ${THREADS:-$(nproc)} --branch "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_NAME"
else
    echo "Directory $KERNEL_NAME already exists, skipping clone."
fi

# Clone susfs4ksu
if [ ! -d "susfs4ksu" ]; then
    echo "Cloning susfs4ksu..."
    git clone "$SUSFS_REPO_URL" -b "$SUSFS_BRANCH"
fi

# Clone SukiSU_patch
if [ ! -d "SukiSU_patch" ]; then
    echo "Cloning SukiSU_patch..."
    git clone "$SUKISU_PATCH_REPO_URL"
fi

# Clone kernel_patches (needed for some scripts)
if [ ! -d "kernel_patches" ]; then
    echo "Cloning kernel_patches..."
    git clone "$WILD_PATCH_REPO_URL"
fi

# Clone AnyKernel3
if [ "${ENABLE_ANYKERNEL3:-true}" = "true" ] && [ ! -d "AnyKernel3" ]; then
    echo "Cloning AnyKernel3..."
    git clone --recursive --depth=1 -j ${THREADS:-$(nproc)} "$ANYKERNEL3_REPO_URL" AnyKernel3
fi