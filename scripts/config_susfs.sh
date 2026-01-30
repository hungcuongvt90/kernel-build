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
ANDROID_VERSION=${ANDROID_VERSION:-13}

CONFIG_FILE="./arch/$ARCH/configs/$KERNEL_DEFCONFIG"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

echo "Adding configuration settings to $CONFIG_FILE..."
echo "Android Version: $ANDROID_VERSION"
echo "KernelSU Variant: $kernelsu_variant"
echo "Hook Variant: $HOOK_VARIANT"

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

# ============================================================================
# CRITICAL: SELinux Configurations (Required for meta modules)
# ============================================================================
echo "CONFIG_SECURITY_SELINUX=y" >> "$CONFIG_FILE"
echo "CONFIG_SECURITY_SELINUX_DEVELOP=y" >> "$CONFIG_FILE"
echo "CONFIG_SECURITY_SELINUX_BOOTPARAM=y" >> "$CONFIG_FILE"
echo "CONFIG_SECURITY_SELINUX_DISABLE=y" >> "$CONFIG_FILE"
echo "CONFIG_AUDIT=y" >> "$CONFIG_FILE"

# ============================================================================
# CRITICAL: Namespace Configurations (Required for module isolation)
# ============================================================================
echo "CONFIG_NAMESPACES=y" >> "$CONFIG_FILE"
echo "CONFIG_UTS_NS=y" >> "$CONFIG_FILE"
echo "CONFIG_IPC_NS=y" >> "$CONFIG_FILE"
echo "CONFIG_PID_NS=y" >> "$CONFIG_FILE"
echo "CONFIG_NET_NS=y" >> "$CONFIG_FILE"
echo "CONFIG_USER_NS=y" >> "$CONFIG_FILE"
echo "CONFIG_CGROUP_NS=y" >> "$CONFIG_FILE"

# ============================================================================
# CRITICAL: Filesystem Configurations (Required for meta modules)
# ============================================================================
echo "CONFIG_FUSE_FS=y" >> "$CONFIG_FILE"
echo "CONFIG_QUOTA=y" >> "$CONFIG_FILE"
echo "CONFIG_QUOTACTL=y" >> "$CONFIG_FILE"
echo "CONFIG_QFMT_V2=y" >> "$CONFIG_FILE"

# ============================================================================
# CRITICAL: OverlayFS Configurations (Required for module file hiding)
# ============================================================================
echo "CONFIG_OVERLAY_FS=y" >> "$CONFIG_FILE"
echo "CONFIG_OVERLAY_FS_REDIRECT_DIR=y" >> "$CONFIG_FILE"
echo "CONFIG_OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW=y" >> "$CONFIG_FILE"
echo "CONFIG_OVERLAY_FS_INDEX=y" >> "$CONFIG_FILE"
echo "CONFIG_OVERLAY_FS_XINO_AUTO=y" >> "$CONFIG_FILE"

# ============================================================================
# CRITICAL: Init and Device Configurations
# ============================================================================
echo "CONFIG_DEVTMPFS=y" >> "$CONFIG_FILE"
echo "CONFIG_DEVTMPFS_MOUNT=y" >> "$CONFIG_FILE"

# ============================================================================
# CRITICAL: Module Loading Configurations (Required for KPM)
# ============================================================================
echo "CONFIG_MODULES=y" >> "$CONFIG_FILE"
echo "CONFIG_MODULE_UNLOAD=y" >> "$CONFIG_FILE"
echo "CONFIG_MODULE_FORCE_UNLOAD=y" >> "$CONFIG_FILE"

# ============================================================================
# Debug Configurations (Helpful for troubleshooting bootloops)
# ============================================================================
echo "CONFIG_PRINTK=y" >> "$CONFIG_FILE"
echo "CONFIG_DYNAMIC_DEBUG=y" >> "$CONFIG_FILE"
echo "CONFIG_DEBUG_FS=y" >> "$CONFIG_FILE"

# ============================================================================
# Android Version Specific Configurations
# ============================================================================
if [ "$ANDROID_VERSION" -ge 13 ]; then
    echo "Adding Android 13+ specific configurations..."
    echo "CONFIG_ANDROID_BINDERFS=y" >> "$CONFIG_FILE"
    echo "CONFIG_ANDROID_BINDER_IPC=y" >> "$CONFIG_FILE"
    echo "CONFIG_ANDROID_BINDER_DEVICES=\"binder,hwbinder,vndbinder\"" >> "$CONFIG_FILE"
fi

# ============================================================================
# SUSFS Configuration Settings
# ============================================================================
echo "CONFIG_KSU_DEBUG=n" >> "$CONFIG_FILE"
echo "CONFIG_KSU_ALLOWLIST_WORKAROUND=n" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> "$CONFIG_FILE"
echo "CONFIG_KSU_SUSFS_SUS_MAP=y" >> "$CONFIG_FILE"

# ============================================================================
# KernelSU Variant Specific Configurations
# ============================================================================
if [ "$kernelsu_variant" == "Next" ]; then
    echo "Configuring for KernelSU Next..."
    echo "CONFIG_KSU_KPROBES_HOOK=n" >> "$CONFIG_FILE"
    # FIXED: Enable SUS_SU for better meta module compatibility
    echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> "$CONFIG_FILE"
    
elif [ "$kernelsu_variant" == "SukiSU" ]; then
    echo "Configuring for SukiSU..."
    echo "CONFIG_KPM=y" >> "$CONFIG_FILE"
    # FIXED: Enable SUS_SU for better meta module compatibility
    echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> "$CONFIG_FILE"
    
elif [ "$kernelsu_variant" == "MKSU" ]; then
    echo "Configuring for MKSU..."
    # FIXED: Enable SUS_SU for better meta module compatibility
    echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> "$CONFIG_FILE"
    
elif [ "$kernelsu_variant" == "Official" ]; then
    echo "Configuring for Official KernelSU..."
    echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> "$CONFIG_FILE"
fi

# ============================================================================
# Hook Variant Configurations
# ============================================================================
if [ "$HOOK_VARIANT" == "tracepoint" ]; then
    echo "Configuring tracepoint hook..."
    echo "CONFIG_KSU_TRACEPOINT_HOOK=y" >> "$CONFIG_FILE"
    echo "CONFIG_KSU_TAMPER_SYSCALL_TABLE=y" >> "$CONFIG_FILE"
else
    echo "Configuring syscall hook..."
    echo "CONFIG_KSU_SYSCALL_HOOK=y" >> "$CONFIG_FILE"
fi

echo "CONFIG_KSU_MANUAL_HOOK=y" >> "$CONFIG_FILE" # applicable for non-gki kernel only
echo "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y" >> "$CONFIG_FILE"

# Remove check_defconfig
sed -i 's/check_defconfig//' ./build.config.gki

echo "Configuration completed successfully!"
echo "================================================"
echo "Key configurations added for bootloop prevention:"
echo "  ✓ SELinux support enabled"
echo "  ✓ Namespace isolation enabled"
echo "  ✓ OverlayFS with full features"
echo "  ✓ FUSE and quota support"
echo "  ✓ Module loading support"
echo "  ✓ SUSFS_SUS_SU enabled for meta module compatibility"
echo "  ✓ Android $ANDROID_VERSION specific configs"
echo "================================================"
