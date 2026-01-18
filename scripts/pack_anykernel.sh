#!/bin/bash
set -e

SOURCE_ANYKERNEL="$1"
TEMP_WORK_DIR="$2"
OUTPUT_ZIP_NAME="$3"

if [ -z "$SOURCE_ANYKERNEL" ] || [ -z "$TEMP_WORK_DIR" ] || [ -z "$OUTPUT_ZIP_NAME" ]; then
  echo "Usage: $0 <source_anykernel_dir> <temp_work_dir> <output_zip_name>"
  exit 1
fi

# Check env vars
if [ -z "$OUT_DIR" ] || [ -z "$ARCH" ] || [ -z "$WORKSPACE" ]; then
  echo "Error: OUT_DIR, ARCH, and WORKSPACE environment variables must be set."
  exit 1
fi

echo "Packing AnyKernel3 from $SOURCE_ANYKERNEL to $TEMP_WORK_DIR with name $OUTPUT_ZIP_NAME.zip"

# Copy AnyKernel3 to temp dir
cp -r "$SOURCE_ANYKERNEL" "$TEMP_WORK_DIR"

# Copy artifacts
if [ -e "$OUT_DIR/arch/$ARCH/boot/Image.gz-dtb" ]; then
  cp -f "$OUT_DIR/arch/$ARCH/boot/Image.gz-dtb" "$TEMP_WORK_DIR/"
else
  if [ -e "$OUT_DIR/arch/$ARCH/boot/Image" ]; then
    cp -f "$OUT_DIR/arch/$ARCH/boot/Image" "$TEMP_WORK_DIR/"
  fi
  if [ -e "$OUT_DIR/arch/$ARCH/boot/dtbo" ]; then
    cp -f "$OUT_DIR/arch/$ARCH/boot/dtbo" "$TEMP_WORK_DIR/"
  fi
  if [ -e "$OUT_DIR/arch/$ARCH/boot/dtbo.img" ]; then
    cp -f "$OUT_DIR/arch/$ARCH/boot/dtbo.img" "$TEMP_WORK_DIR/"
  fi
fi

# Zip
cd "$TEMP_WORK_DIR"
zip -q -r "$OUTPUT_ZIP_NAME.zip" *
cp "$OUTPUT_ZIP_NAME.zip" "$WORKSPACE"

ls -la .
pwd
ls -la "$WORKSPACE"
