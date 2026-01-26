#!/bin/bash
set -e

# Script to clone kernel source and related repositories
# Usage: ./clone_sources.sh <kernel_name> <kernel_repo> <kernel_branch> <susfs_branch> <params_json>

KERNEL_NAME="$1"
KERNEL_REPO="$2"
KERNEL_BRANCH="$3"
SUSFS_BRANCH="$4"
PARAMS="$5"

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
