#!/bin/bash
set -e

toolchains_num="$(echo "$toolchains" | jq 'length')"
echo "🤔 There is $toolchains_num defined toolchains."

for ((i=0;i<toolchains_num;i++)); do
  toolchain=$(echo "$toolchains" | jq -r ".[$i]")

  toolchain_name=$(echo "$toolchain" | jq -r ".name")
  
  # From archive
  if echo "$toolchain" | jq -e 'has("url")' > /dev/null; then
    # If from archive
    toolchain_url=$(echo "$toolchain" | jq -r ".url")
    mkdir -p "$toolchain_name"

    # Download archive
    wget -q "$toolchain_url"

    # Get filename
    filename="${toolchain_url##*/}"
    case "$filename" in
      *.zip)
        unzip -d "$toolchain_name" "$filename"
        ;;
      *.tar)
        tar xvf "$filename" -C "$toolchain_name"
        ;;
      *.tar.gz)
        tar zxvf "$filename" -C "$toolchain_name"
        ;;
      *.rar)
        unrar x "$filename" "$toolchain_name"
        ;;
      *)
        echo "unknown file type: $filename"
        ;;
    esac
    # Delete file to avoid duplicate name conflicts 
    rm "$filename"

    echo "🤔 Download $toolchain_name => ($toolchain_url)"
  else
    # If from git
    toolchain_repo=$(echo "$toolchain" | jq -r ".repo")
    toolchain_branch=$(echo "$toolchain" | jq -r ".branch")
    git clone --recursive --depth=1 -j $(nproc) --branch "$toolchain_branch" "$toolchain_repo" "$toolchain_name"

    echo "🤔 Clone $toolchain_name => ($toolchain_repo)"
  fi

  jq -r ".binaryEnv[] | tostring" <<< "$toolchain" | while read -r subPath; do
    echo "$WORKSPACE/$toolchain_name/$subPath" >> "$GITHUB_PATH"
  done
done
