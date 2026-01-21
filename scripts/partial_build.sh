#!/bin/bash
set -e

# Define variables from environment
export WORKSPACE=${WORKSPACE:? "WORKSPACE must be set"}
export OUT_DIR=${OUT_DIR:? "OUT_DIR must be set"}
export BUILD_DATE=${BUILD_DATE:-$(date +%Y%m%d)}

# Kernel source configuration (Mandatory)
export SRC_DIR=${SRC_DIR:? "SRC_DIR must be set"}
export KERNEL_NAME=${KERNEL_NAME:? "KERNEL_NAME must be set"}
export KERNEL_DEFCONFIG_PATH=${KERNEL_DEFCONFIG_PATH:? "KERNEL_DEFCONFIG_PATH must be set"}

# Optional configuration with sensible defaults
export KERNEL_DEVICE=${KERNEL_DEVICE:-"gki"}
export KERNEL_PATCH_REPO_URL=${KERNEL_PATCH_REPO_URL:-https://github.com/SukiSU-Ultra/SukiSU_patch}
export HOOK_VARIANT=${HOOK_VARIANT:-syscall}
export SUSFS_BRANCH=${SUSFS_BRANCH:-gki-android13-5.15}
export USE_ZRAM=${USE_ZRAM:-false}
export ZRAM_PATCH_VERSION=${ZRAM_PATCH_VERSION:-5.15}
export USE_KPM=${USE_KPM:-false}

export ENABLE_CCACHE=${ENABLE_CCACHE:-true}
export CCACHE_DIR=${CCACHE_DIR:-"${WORKSPACE}/ccache"}

export ENABLE_ANYKERNEL3=${USE_ANYKERNEL3:-true}
export ENABLE_KERNELSU=${ENABLE_KERNELSU:-true}
export ENABLE_KERNELSU_SFS=${ENABLE_KERNELSU_SFS:-true}
export kernelsu_branch=${kernelsu_branch:-Stable}
export kernelsu_variant=${kernelsu_variant:-SukiSU}
export KSU_BRANCH=""

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

echo "Checking if source exists in $(pwd)..."
if [ ! -d "$KERNEL_NAME" ]; then
    echo "Error: Kernel source directory $KERNEL_NAME not found in $(pwd)!"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

echo "PATH Variable: $PATH"

# Handle matrix/params JSON if provided (matching GitHub Actions logic)
# Use a default for THREADS if not a number
if ! [[ "$THREADS" =~ ^[0-9]+$ ]]; then
    export THREADS=$(nproc --all)
fi

# Ensure CC is absolute path if possible
CLANG_PATH="/app/clang/bin/clang"
if [ -x "$CLANG_PATH" ]; then
    CC_VAL="$CLANG_PATH"
else
    CC_VAL="clang"
fi

if [ "$ENABLE_CCACHE" = "true" ]; then
    CC_VAL="ccache $CC_VAL"
fi

# Base make arguments using LLVM=1 for Clang-based builds
MAKE_ARGS=(
    -j"${THREADS}"
    O="${OUT_DIR}"
    ARCH="${ARCH}"
    LLVM=1
    LLVM_IAS=1
    CC="${CC_VAL}"
    HOSTCC="clang"
    HOSTCXX="clang++"
)

if [ -n "$params" ] && [ "$params" != "null" ]; then
    echo "Processing params JSON..."
    JSON_CC=$(echo "$params" | jq -r ".CC // empty")
    if [ -n "$JSON_CC" ]; then
        CC_VAL="$JSON_CC"
        if [ "$ENABLE_CCACHE" = "true" ] && [[ "$CC_VAL" != ccache* ]]; then
            CC_VAL="ccache $CC_VAL"
        fi
        # Update CC in arguments
        for i in "${!MAKE_ARGS[@]}"; do
            if [[ "${MAKE_ARGS[$i]}" == CC=* ]]; then
                MAKE_ARGS[$i]="CC=${CC_VAL}"
            fi
        done
    fi
    # Add external commands to MAKE_ARGS
    while read -r ext; do
        if [ -n "$ext" ]; then
            MAKE_ARGS+=("$ext")
        fi
    done < <(echo "$params" | jq -r '.externalCommands | to_entries[] | "\(.key)=\(.value)"' 2>/dev/null || true)
fi

MAKE_ARGS+=(BUILD_SHARED_LIBS=ON)

echo "Build Arguments: ${MAKE_ARGS[*]}"

# Determine the branch for SukiSU KernelSU
if [[ "$kernelsu_branch" == "Stable" && "$kernelsu_variant" == "SukiSU" ]]; then
    export KSU_BRANCH="-s susfs-main"
elif [[ "$kernelsu_branch" == "Dev" && "$kernelsu_variant" == "SukiSU" ]]; then
    export KSU_BRANCH="-s susfs-test"
fi

cd "$SRC_DIR/$KERNEL_NAME"

echo "Setup Toolchains..."
if [ -n "$toolchains" ]; then
    export GITHUB_PATH=$(mktemp)
    bash "$SCRIPT_DIR/setup_toolchains.sh"
    while read -r p; do
        export PATH="$p:$PATH"
    done < "$GITHUB_PATH"
    rm "$GITHUB_PATH"
else
    echo "No toolchains JSON provided, using system defaults."
fi

echo "Setup KernelSU..."
if [ "$ENABLE_KERNELSU" = "true" ]; then
    bash "$SCRIPT_DIR/setup_kernelsu.sh"
fi

echo "Setup KSU SUSFS..."
if [[ "$ENABLE_KERNELSU" == "true" && "$ENABLE_KERNELSU_SFS" == "true" ]]; then
    bash "$SCRIPT_DIR/setup_susfs.sh"
fi

echo "Apply Patches..."
bash "$SCRIPT_DIR/apply_patches.sh"

echo "Applying Mountify configuration settings..."
CONFIG_FILE="./arch/$ARCH/configs/$KERNEL_DEFCONFIG_PATH"
echo "CONFIG_OVERLAY_FS=y" >> "$CONFIG_FILE"

if [ "$baseband_guard" = "true" ]; then
    echo "Enabling kernel-level baseband protection support..."
    wget -O- "$BASEBAND_GUARD_URL" | bash
    sed -i '/^config LSM$/,/^help$/{ /^[[:space:]]*default/ { /baseband_guard/! s/lockdown/lockdown,baseband_guard/ } }' ./security/Kconfig
    echo "CONFIG_BBG=y" >> "$CONFIG_FILE"
fi

echo "Configuring SUSFS..."
bash "$SCRIPT_DIR/config_susfs.sh"

echo "Enabling ThinLTO..."
sed -i 's/^CONFIG_LTO=n/CONFIG_LTO=y/' "$CONFIG_FILE"
sed -i 's/^CONFIG_LTO_CLANG_FULL=y/CONFIG_LTO_CLANG_THIN=y/' "$CONFIG_FILE"
sed -i 's/^CONFIG_LTO_CLANG_NONE=y/CONFIG_LTO_CLANG_THIN=y/' "$CONFIG_FILE"
grep -q '^CONFIG_LTO_CLANG_THIN=y' "$CONFIG_FILE" || echo 'CONFIG_LTO_CLANG_THIN=y' >> "$CONFIG_FILE"

echo "Commit to avoid dirty..."
rm android/abi_gki_protected_exports_* || echo "No protected exports!"
git config --global user.email "bot@kernelsu.org"
git config --global user.name "KernelSUBot"
git add -A && git commit -a -m "Add KernelSU" || echo "Nothing to commit"

echo "Starting kernel build..."
export KBUILD_BUILD_TIMESTAMP="Wed Oct 25 05:41:09 UTC 2023"
export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-Docker-Builder}
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-builder}

make "${MAKE_ARGS[@]}" "$KERNEL_DEFCONFIG_PATH"
make "${MAKE_ARGS[@]}"

# Packing
if [ "$USE_ANYKERNEL3" == "true" ]; then
    export ANYKERNEL3_FILE_NO_KPM="${kernelsu_variant}-NO-KPM-${HOOK_VARIANT}-${KERNEL_NAME}-${BUILD_DATE}"
    echo "Packing AnyKernel3 (No KPM)..."
    bash "$SCRIPT_DIR/pack_anykernel.sh" "AnyKernel3" "AnyKernel3_1" "$ANYKERNEL3_FILE_NO_KPM"

    if [[ "$USE_KPM" == "true" && "$kernelsu_variant" == "SukiSU" && "$android_version" != "6.6" ]]; then
        echo "Start to patch KPM..."
        cd "$OUT_DIR/arch/$ARCH/boot/"
        curl -LSs "$KPM_PATCH_URL" -o patch_linux
        chmod +x patch_linux
        ./patch_linux
        rm -f Image && mv oImage Image
        export ANYKERNEL3_FILE_WITH_KPM="${kernelsu_variant}-KPM-${HOOK_VARIANT}-${KERNEL_NAME}-${BUILD_DATE}"
        echo "Packing AnyKernel3 (With KPM)..."
        cd "$WORKSPACE"
        bash "$SCRIPT_DIR/pack_anykernel.sh" "AnyKernel3" "AnyKernel3_2" "$ANYKERNEL3_FILE_WITH_KPM"
    fi
fi

echo "Build process finished. Zips are available in $WORKSPACE"
