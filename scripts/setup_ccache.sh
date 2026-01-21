#!/bin/bash
set -e

# Create output directory
mkdir -p "$OUT_DIR"

# Initialize ccache
ccache -o compression=false -o cache_dir="$CCACHE_DIR"

CONFIG_JSON="$1"
if [ -n "$CONFIG_JSON" ]; then
  HASH=$(echo -n "$CONFIG_JSON" | openssl dgst -sha1 | awk '{print $2}')
  echo "HASH=$HASH" >> "$GITHUB_ENV"
fi
