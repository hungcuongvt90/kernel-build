#!/bin/bash
set -e

# Combined script for cloning sources, setting up KernelSU, and configuring SUSFS
# Usage: ./setup_kernel_sources.sh <kernel_name> <kernel_repo> <kernel_branch> <susfs_branch> <params_json> <kernelsu_variant> <ksu_branch>

KERNEL_NAME="$1"
KERNEL_REPO="$2"
KERNEL_BRANCH="$3"
SUSFS_BRANCH="$4"
PARAMS="$5"
kernelsu_variant="$6"
KSU_BRANCH="$7"
BRANCH_NAME="$7"

# ============================================================================
# SECTION 1: Clone Sources
# ============================================================================

echo "🌟 Cloning source repositories..."
echo "  Kernel: $KERNEL_REPO (branch: $KERNEL_BRANCH)"
echo "  SUSFS branch: $SUSFS_BRANCH"

# Clone main kernel repository
echo "📦 Cloning kernel repository..."
git clone --recursive --depth=1 -j "$(nproc)" --branch "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_NAME"

ls -la

# Clone supporting repositories
echo "📦 Cloning susfs4ksu..."
git clone https://github.com/ShirkNeko/susfs4ksu.git -b "$SUSFS_BRANCH"

echo "📦 Cloning SukiSU_patch..."
git clone https://github.com/SukiSU-Ultra/SukiSU_patch.git

echo "📦 Cloning kernel_patches..."
git clone https://github.com/WildKernels/kernel_patches.git

# Clone AnyKernel3 (custom or default)
if echo -n "$PARAMS" | jq -e 'has("custom")' > /dev/null; then
  CUSTOM_ANYKERNEL3=$(echo -n "$PARAMS" | jq -r ".custom")
  ANYKERNEL_REPO=$(echo "$CUSTOM_ANYKERNEL3" | jq -r ".repo")
  ANYKERNEL_BRANCH=$(echo "$CUSTOM_ANYKERNEL3" | jq -r ".branch")
  
  echo "📦 Cloning custom AnyKernel3 from $ANYKERNEL_REPO (branch: $ANYKERNEL_BRANCH)..."
  git clone --recursive --depth=1 -j "$(nproc)" --branch "$ANYKERNEL_BRANCH" "$ANYKERNEL_REPO" AnyKernel3
  echo "🤔 Use custom AnyKernel3 => ($ANYKERNEL_REPO)"
else
  echo "📦 Cloning default WildPlus AnyKernel3..."
  git clone --recursive --depth=1 -j "$(nproc)" https://github.com/WildPlusKernel/AnyKernel3 AnyKernel3
  echo "🤔 Use WildPlus Anykernel3 => (https://github.com/WildPlusKernel/AnyKernel3)"
fi

echo "✅ All repositories cloned successfully!"

# ============================================================================
# SECTION 2: Setup KernelSU
# ============================================================================

echo ""
echo "🔧 Setting up KernelSU..."
cd "$KERNEL_NAME"

# Delete old KernelSU
if [ -d "./KernelSU" ]; then
  rm -rf "./KernelSU"
fi
if [ -d "./drivers/kernelsu" ]; then
  rm -rf "./drivers/kernelsu"
fi

if [ "$kernelsu_variant" == "Official" ]; then
  echo "Adding KernelSU Official..."
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s "$KSU_BRANCH"
  echo "Done applying KernelSU Official..."
elif [ "$kernelsu_variant" == "Next" ]; then
  echo "Adding KernelSU Next..."
  curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -s "$KSU_BRANCH"
  echo "Done applying KernelSU Next..."
elif [ "$kernelsu_variant" == "MKSU" ]; then
  echo "Adding KernelSU MKSU..."
  curl -LSs "https://raw.githubusercontent.com/5ec1cff/KernelSU/main/kernel/setup.sh" | bash -s "$KSU_BRANCH"
  echo "Done applying KernelSU MKSU..."
elif [ "$kernelsu_variant" == "SukiSU" ]; then
  echo "Adding KernelSU SukiSU..."
  curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s "$KSU_BRANCH"
  # curl -LSs "https://raw.githubusercontent.com/hungcuongvt90/SukiSU-Ultra/main/kernel/setup.sh" | bash -s "$KSU_BRANCH"
  
  # If a manual hash was specified, switch to this commit.
  if [[ -n "$MANUAL_HASH" ]]; then
    git fetch origin "$BRANCH_NAME" --depth=50
    git checkout "$MANUAL_HASH"
    SHORT_HASH=${MANUAL_HASH:0:8}
  fi

  KSU_API_VERSION=$(curl -fsSL "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/Makefile" | grep -m1 "KSU_VERSION_API :=" | awk -F'= ' '{print $2}' | tr -d '[:space:]')
  if [[ -z "$KSU_API_VERSION" || "$(printf '%s\n' "$KSU_API_VERSION" "4.0.0" | sort -V | head -n1)" != "4.0.0" ]]; then
    KSU_API_VERSION="4.0.0"
  fi
  echo "KSU_API_VERSION=$KSU_API_VERSION" >> "$GITHUB_ENV"

  GIT_HASH=$(git rev-parse --short HEAD)
  echo "GIT_HASH=$GIT_HASH"

  # Assembly version number
  if [[ -n "$MANUAL_HASH" ]]; then
    USE_HASH="$SHORT_HASH"
  else
    USE_HASH="$GIT_HASH"
  fi
  if [[ -z "$CUSTOM_TAG" ]]; then
    VERSION_FULL="v$KSU_API_VERSION-$USE_HASH@$BRANCH_NAME"
  else
    VERSION_FULL="v$KSU_API_VERSION-$CUSTOM_TAG@$BRANCH_NAME[$USE_HASH]"
  fi

  # Clean up and write version information to the Makefile
  sed -i '/define get_ksu_version_full/,/endef/d' kernel/Makefile
  sed -i '/KSU_VERSION_API :=/d' kernel/Makefile
  sed -i '/KSU_VERSION_FULL :=/d' kernel/Makefile

  KSU_VERSION=$(expr $(git rev-list --count main 2>/dev/null || echo 13000) + 37185)
  echo "KSUVER=$KSU_VERSION" >> "$GITHUB_ENV"

  cat kernel/Makefile
  
  echo "Done applying KernelSU SukiSU..."
fi

# ============================================================================
# SECTION 3: Setup SUSFS
# ============================================================================

echo ""
echo "🔧 Setting up SUSFS..."

if [ "$kernelsu_variant" == "Official" ]; then
  echo "Applying SUSFS patches for Official KernelSU..."
  cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./
  patch -p1 --forward --fuzz=3 < 10_enable_susfs_for_ksu.patch || true
elif [ "$kernelsu_variant" == "Next" ]; then
  cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./
  patch -p1 --forward --fuzz=3 < 10_enable_susfs_for_ksu.patch || true
  cp ../susfs4ksu/kernel_patches/fs/* ./fs/
  cp ../susfs4ksu/kernel_patches/include/linux/* ./include/linux/
  echo "Applying SUSFS patches for KernelSU-Next..."
  cp ../kernel_patches/next/scope_min_manual_hooks_v1.6.patch ./
  patch -p1 -F 3 < scope_min_manual_hooks_v1.6.patch
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

  # if [ "${HOOK_VARIANT}" == "scope_min_manual" ]; then
  #   echo "Apply scope min manual hook patches"
  #   cp ../SukiSU_patch/hooks/scope_min_manual_hooks_v1.6.patch ./
  #   patch -p1 -F 3 < scope_min_manual_hooks_v1.6.patch
  # else
  #   echo "Apply syscall hook patches"
  #   cp ../SukiSU_patch/hooks/syscall_hooks.patch ./
  #   patch -p1 -F 3 < syscall_hooks.patch
  # fi
else
  echo "Invalid KernelSU variant selected!"
  exit 1
fi

echo "ANYKERNEL3_FILE_NO_KPM=NO.KPM.${kernelsu_variant}.${HOOK_VARIANT}.${KERNEL_NAME}.${BUILD_DATE}" >> "$GITHUB_ENV"
echo "RELEASE_TAG_NAME=NO.KPM.${kernelsu_variant}.${HOOK_VARIANT}.${KERNEL_NAME}.${BUILD_DATE}" >> "$GITHUB_ENV"

echo ""
echo "✅ Kernel sources setup completed successfully!"
