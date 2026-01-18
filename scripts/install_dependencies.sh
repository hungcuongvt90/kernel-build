#!/bin/bash
set -e

sudo apt-get update
sudo apt-get install -y curl git ftp lftp wget libarchive-tools ccache python3-dev
sudo apt-get install -y pngcrush schedtool dpkg-dev liblz4-tool make optipng maven dwarves device-tree-compiler 
sudo apt-get install -y libc6-dev-i386 libelf-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc
sudo apt-get install -y libxml2-utils libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools lzop flex tree
sudo apt-get install -y build-essential bc gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi libssl-dev libfl-dev
sudo apt-get install -y pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl 
sudo apt-get install -y zip unzip tar gzip bzip2 rar unrar llvm g++-multilib bison gperf zlib1g-dev automake lld

PARAMS_JSON="$1"
WORKSPACE_DIR="$2"

if [ -n "$PARAMS_JSON" ] && [ -n "$WORKSPACE_DIR" ]; then
  EXTERNAL_ARGS=""
  while read -r externalCommand; do
    key=$(echo "$externalCommand" | cut -d= -f1)
    value=$(echo "$externalCommand" | cut -d= -f2)
    if [[ "$value" == *"/"* ]]; then
      value="$WORKSPACE_DIR/$value"
    fi
    EXTERNAL_ARGS="$EXTERNAL_ARGS $key=$value"
  done < <(echo "$PARAMS_JSON" | jq -r '.externalCommands | to_entries[] | "\(.key)=\(.value)"')
  
  echo "EXTERNAL_ARGS=$EXTERNAL_ARGS" >> "$GITHUB_ENV"
fi
