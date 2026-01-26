#!/bin/bash
set -e

# Expected environment variables:
# ARCH (default: arm64)
# KERNEL_DEFCONFIG (default: gki_defconfig)
# kernelsu_variant
# HOOK_VARIANT
# ANDROID_VERSION

ARCH=${ARCH:-arm64}
KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-gki_defconfig}

CONFIG_FILE="./arch/$ARCH/configs/$KERNEL_DEFCONFIG"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

echo "Adding configuration settings to $CONFIG_FILE..."

# Add KSU configuration settings
echo "CONFIG_KSU=y" >> "$CONFIG_FILE"

# Add additional tmpfs config setting
echo "CONFIG_TMPFS_XATTR=y" >> "$CONFIG_FILE"
echo "CONFIG_TMPFS_POSIX_ACL=y" >> "$CONFIG_FILE"

# Add additional config setting
echo "CONFIG_IP_NF_TARGET_TTL=y" >> "$CONFIG_FILE"
echo "CONFIG_IP6_NF_TARGET_HL=y" >> "$CONFIG_FILE"
echo "CONFIG_IP6_NF_MATCH_HL=y" >> "$CONFIG_FILE"

# Add BBR Config
echo "CONFIG_TCP_CONG_ADVANCED=y" >> "$CONFIG_FILE"
echo "CONFIG_TCP_CONG_BBR=y" >> "$CONFIG_FILE"
echo "CONFIG_NET_SCH_FQ=y" >> "$CONFIG_FILE"
echo "CONFIG_TCP_CONG_BIC=n" >> "$CONFIG_FILE"
echo "CONFIG_TCP_CONG_WESTWOOD=n" >> "$CONFIG_FILE"
echo "CONFIG_TCP_CONG_HTCP=n" >> "$CONFIG_FILE"

# Add SUSFS configuration settings
echo "CONFIG_KSU_DEBUG=n" >> "$CONFIG_FILE"
echo "CONFIG_KSU_ALLOWLIST_WORKAROUND=n" >> "$CONFIG_FILE"
# echo "CONFIG_KSU_MANUAL_SU=n" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> "$CONFIG_FILE"
# echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_MAP=y" >> "$CONFIG_FILE"

if [ "$kernelsu_variant" == "Next" ]; then
    echo "CONFIG_KSU_KPROBES_HOOK=n" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> "$CONFIG_FILE"
elif [ "$kernelsu_variant" == "SukiSU" ]; then
    echo "CONFIG_KPM=y" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> "$CONFIG_FILE"
elif [ "$kernelsu_variant" == "MKSU" ]; then
    echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> "$CONFIG_FILE"
fi

if [ "$HOOK_VARIANT" == "tracepoint" ]; then
    echo "CONFIG_KSU_TRACEPOINT_HOOK=y" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_TAMPER_SYSCALL_TABLE=y" >> "$CONFIG_FILE"
else
    echo "CONFIG_KSU_SYSCALL_HOOK=y" >> "$CONFIG_FILE"
    echo "CONFIG_KPROBES=y" >> "$CONFIG_FILE"
    echo "CONFIG_KRETPROBES=y" >> "$CONFIG_FILE"
fi

echo "CONFIG_KSU_MANUAL_HOOK=y" >> "$CONFIG_FILE" # applicable for non-gki kernel only
echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y" >> "$CONFIG_FILE"

# Remove check_defconfig
sed -i 's/check_defconfig//' ./build.config.gki
