#!/bin/bash
set -e

# Define variables from environment
export WORKSPACE=${WORKSPACE:? "WORKSPACE must be set"}
export OUT_DIR=${OUT_DIR:? "OUT_DIR must be set"}
export BUILD_DATE=${BUILD_DATE:-$(date +%Y%m%d)}

# Kernel source configuration (Mandatory)
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

cd "$WORKSPACE"

echo "Cloning repositories..."

# Clone Kernel
if [ ! -d "$KERNEL_NAME" ]; then
    git clone --recursive --depth=1 -j $(nproc) --branch "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_NAME"
else
    echo "Directory $KERNEL_NAME already exists, skipping clone."
fi

# Clone susfs4ksu
if [ ! -d "susfs4ksu" ]; then
    git clone "$SUSFS_REPO_URL" -b "$SUSFS_BRANCH"
fi

# Clone SukiSU_patch
if [ ! -d "SukiSU_patch" ]; then
    git clone "$SUKISU_PATCH_REPO_URL"
fi

# Clone kernel_patches (needed for some scripts)
if [ ! -d "kernel_patches" ]; then
    git clone "$WILD_PATCH_REPO_URL"
fi

# Clone AnyKernel3
if [ "$USE_ANYKERNEL3" = "true" ] && [ ! -d "AnyKernel3" ]; then
    git clone --recursive --depth=1 -j $(nproc) "$ANYKERNEL3_REPO_URL" AnyKernel3
fi

echo "PATH Variable: $PATH"

# Handle matrix/params JSON if provided (matching GitHub Actions logic)
export THREADS=${THREADS:-$(nproc --all)}

if [ -n "$params" ]; then
    echo "Processing params JSON..."
    JSON_CC=$(echo "$params" | jq -r ".CC // empty")
    if [ -n "$JSON_CC" ]; then
        CC="$JSON_CC"
    fi
    # Handle externalCommands if needed (some versions of the workflow use it)
    EXTERNAL_ARGS=""
    while read -r ext; do
        EXTERNAL_ARGS="$EXTERNAL_ARGS $ext"
    done < <(echo "$params" | jq -r '.externalCommands | to_entries[] | "\(.key)=\(.value)"' 2>/dev/null || true)
fi

args="-j${THREADS} O=$OUT_DIR ARCH=$ARCH"

if [ "$ENABLE_CCACHE" = "true" ]; then
    args="$args CC=\"ccache $CC\""
else
    args="$args CC=$CC"
fi

args="$args $EXTERNAL_ARGS BUILD_SHARED_LIBS=ON LLVM_IAS=1"

export ARCH=$ARCH
export ARGS=$args

echo "Build Arguments: $args"

# Determine the branch for SukiSU KernelSU
if [[ "$kernelsu_branch" == "Stable" && "$kernelsu_variant" == "SukiSU" ]]; then
    export KSU_BRANCH="-s susfs-main"
elif [[ "$kernelsu_branch" == "Dev" && "$kernelsu_variant" == "SukiSU" ]]; then
    export KSU_BRANCH="-s susfs-test"
fi

cd "$WORKSPACE/$KERNEL_NAME"

echo "Setup Toolchains..."
if [ -n "$toolchains" ]; then
    # Create GITHUB_PATH temp file to capture path updates
    export GITHUB_PATH=$(mktemp)
    bash "$SCRIPT_DIR/setup_toolchains.sh"
    # Apply path updates to current shell
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
# Set build user/host
export KBUILD_BUILD_TIMESTAMP="Wed Oct 25 05:41:09 UTC 2023"
export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-Docker-Builder}
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-builder}

make $ARGS $KERNEL_DEFCONFIG_PATH
make $ARGS

# Artifact collection and AnyKernel3 packing
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
        rm -f Image
        mv oImage Image
        
        export ANYKERNEL3_FILE_WITH_KPM="${kernelsu_variant}-KPM-${HOOK_VARIANT}-${KERNEL_NAME}-${BUILD_DATE}"
        
        echo "Packing AnyKernel3 (With KPM)..."
        cd "$WORKSPACE"
        bash "$SCRIPT_DIR/pack_anykernel.sh" "AnyKernel3" "AnyKernel3_2" "$ANYKERNEL3_FILE_WITH_KPM"
    fi
fi

echo "Build process finished. Zips are available in $WORKSPACE"
echo "All done."
