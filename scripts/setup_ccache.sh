#!/bin/bash
set -e

# Create output directory
mkdir -p "$OUT_DIR"

# Initialize ccache
ccache -o compression=false -o cache_dir="$CCACHE_DIR"
