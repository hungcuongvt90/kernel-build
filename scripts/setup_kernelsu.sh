#!/bin/bash
set -e

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
