#!/bin/bash

# WHITELIST XIAOMI + GMS CHECKIN (v5.7 - UI CLEAR)

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║       WHITELIST XIAOMI - 19 APP + GMS CHECKIN            ║"
echo "║   GMS reconnect moi 1-6 phut (gms_checkin_timeout_min)    ║"
echo "║   THONG BAO ZALO, MOMO, GRAB, ANDROID AUTO DEN NGAY!     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check for adb
if ! command -v adb &> /dev/null; then
    echo "[LOI] Khong tim thay adb!"
    read -p "Press enter to continue..."
    exit 1
fi

# Check device connection
echo "[1/9] Kiem tra ket noi..."
if ! adb get-state &> /dev/null; then
    echo "[LOI] Khong ket noi duoc!"
    read -p "Press enter to continue..."
    exit 1
fi
echo "[OK] Ket noi thanh cong!"
adb devices | grep device
echo ""

# Check MIUI/HyperOS
echo "[2/9] Kiem tra he thong..."
MIUI_VER=$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
if [ -z "$MIUI_VER" ]; then
    MIUI_VER="Unknown"
fi
echo "Phat hien: MIUI/HyperOS $MIUI_VER"
echo ""

# ================================
# PACKAGE + SERVICE + PROCESS
# ================================

# 1. Google Services (GMS)
PKG_GMS="com.google.android.gms"
SVC_GMS="com.google.android.gms.gcm.GcmService,com.google.android.gms.gcm.nts.SchedulerService,com.google.android.gms.chimera.PersistentApiService"
PROC_GMS="$PKG_GMS,$PKG_GMS.persistent"

# 2. Chrome
PKG_CHROME="com.android.chrome"
SVC_CHROME="org.chromium.chrome.browser.services.gcm.ChromeGcmListenerService,org.chromium.chrome.browser.notifications.NotificationService"
PROC_CHROME="$PKG_CHROME"

# 3. Gmail
PKG_GMAIL="com.google.android.gm"
SVC_GMAIL="com.google.android.gm.notification.GmailFirebaseMessagingService,com.google.android.gm.sync.SyncService"
PROC_GMAIL=""

# 4. Messenger
PKG_MESSENGER="com.facebook.orca"
SVC_MESSENGER="com.facebook.mqttlite.MqttService,com.facebook.push.mqtt.service.MqttPushService"
PROC_MESSENGER=""

# 5. Zalo
PKG_ZALO="com.zing.zalo"
SVC_ZALO="com.zing.zalo.service.ZaloFirebaseMessagingService,com.zing.zalo.background.ZaloBackgroundService"
PROC_ZALO=""

# 6. Telegram
PKG_TELEGRAM="org.telegram.messenger"
SVC_TELEGRAM="org.telegram.messenger.NotificationsService,org.telegram.messenger.KeepAliveJob"
PROC_TELEGRAM="$PKG_TELEGRAM,$PKG_TELEGRAM:persistent"

# 7. WhatsApp
PKG_WA="com.whatsapp"
SVC_WA="com.whatsapp.messaging.MessageService,com.whatsapp.notification.AndroidWear,com.whatsapp.job.WhatsAppJobService"
PROC_WA="$PKG_WA,$PKG_WA:persistent"

# 8. WhatsApp Business
PKG_WAB="com.whatsapp.w4b"
SVC_WAB="com.whatsapp.w4b.messaging.WhatsAppBusinessMessagingService"
PROC_WAB="$PKG_WAB,$PKG_WAB:persistent"

# 9. Techcombank
PKG_TCB="vn.com.techcombank.bb.app"
SVC_TCB="vn.com.techcombank.bb.app.push.FCMMessagingService"
PROC_TCB=""

# 10. Vietcombank
PKG_VCB="com.vcb"
SVC_VCB="com.vcb.mobilebanking.push.FCMService"
PROC_VCB=""

# 11. BIDV
PKG_BIDV="com.vnpay.bidv"
SVC_BIDV="com.vnpay.bidv.push.FCMService"
PROC_BIDV=""

# 12. Shopee
PKG_SHOPEE="com.shopee.vn"
SVC_SHOPEE="com.shopee.app.push.fcm.ShopeeFcmService"
PROC_SHOPEE=""

# 13. MoMo
PKG_MOMO="com.mservice.momotransfer"
SVC_MOMO="com.mservice.momotransfer.push.MoMoFirebaseMessagingService,com.mservice.momotransfer.service.MomoJobService"
PROC_MOMO="$PKG_MOMO,$PKG_MOMO:persistent"

# 14. VNPAY
PKG_VNPAY="com.vnpay.app"
SVC_VNPAY="com.vnpay.app.push.FCMService"
PROC_VNPAY=""

# 15. Grab
PKG_GRAB="com.grabtaxi.passenger"
SVC_GRAB="com.grabtaxi.passenger.push.GrabFirebaseMessagingService,com.grabtaxi.passenger.service.GrabJobService"
PROC_GRAB="$PKG_GRAB,$PKG_GRAB:persistent"

# 16. ViettelPay
PKG_VTPAY="com.bplus.vtpay"
SVC_VTPAY="com.bplus.vtpay.push.VTPayFCMService"
PROC_VTPAY=""

# 17. VIB
PKG_VIB="com.vib.myvib"
SVC_VIB="com.vib.myvib.push.MyVibFCMService"
PROC_VIB=""

# 18. TPBank
PKG_TPB="com.tpb.mb.gprsandroid"
SVC_TPB="com.tpb.mb.gprsandroid.push.TPBankFCMService"
PROC_TPB=""

# 19. Android Auto
PKG_AUTO="com.google.android.projection.gearhead"
SVC_AUTO="com.google.android.gms.car.CarFirebaseMessagingService"
PROC_AUTO=""

# EXT
PKG_EXT="com.google.android.ext.services"

# ================================
# FUNCTION: ADD APP
# ================================
add_app() {
    local pkg1="$1"
    local pkg2="$2"
    local svc="$3"
    local proc="$4"
    
    if [ -n "$pkg1" ]; then
        rt_list="${rt_list}${pkg1},"
        power_pkg_list="${power_pkg_list}${pkg1},"
    fi
    if [ -n "$pkg2" ]; then
        rt_list="${rt_list}${pkg2},"
        power_pkg_list="${power_pkg_list}${pkg2},"
    fi
    if [ -n "$proc" ]; then
        power_proc_list="${power_proc_list}${proc},"
    fi
    if [ -n "$svc" ]; then
        power_svc_list="${power_svc_list}${svc},"
    fi
}

# ================================
# MENU
# ================================
menu() {
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                   CHỌN ỨNG DỤNG WHITELIST                 ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "[1]  Google Services (GMS)     [11] BIDV SmartBanking"
    echo "[2]  Chrome                    [12] Shopee VN"
    echo "[3]  Gmail                     [13] MoMo Wallet"
    echo "[4]  Messenger                 [14] VNPAY App"
    echo "[5]  Zalo                      [15] Grab Superapp"
    echo "[6]  Telegram                  [16] ViettelPay"
    echo "[7]  WhatsApp (ca nhan)        [17] VIB (MyVIB)"
    echo "[8]  WhatsApp Business         [18] TPBank Mobile"
    echo "[9]  Techcombank               [19] Android Auto"
    echo "[10] Vietcombank"
    echo ""
    echo "[0]  WHITELIST TAT CA"
    echo "[X]  THOAT"
    echo ""
    
    rt_list=""
    power_pkg_list=""
    power_proc_list=""
    power_svc_list=""
    
    read -p "Nhap so (cach nhau dau cach) hoac 0/X: " choice
    
    if [[ "$choice" == "X" ]] || [[ "$choice" == "x" ]]; then
        exit 0
    fi
    
    if [ "$choice" == "0" ]; then
        select_all
    else
        for num in $choice; do
            case $num in
                1)  add_app "$PKG_GMS" "$PKG_EXT" "$SVC_GMS" "$PROC_GMS" ;;
                2)  add_app "$PKG_CHROME" "" "$SVC_CHROME" "$PROC_CHROME" ;;
                3)  add_app "$PKG_GMAIL" "" "$SVC_GMAIL" "$PROC_GMAIL" ;;
                4)  add_app "$PKG_MESSENGER" "" "$SVC_MESSENGER" "$PROC_MESSENGER" ;;
                5)  add_app "$PKG_ZALO" "" "$SVC_ZALO" "$PROC_ZALO" ;;
                6)  add_app "$PKG_TELEGRAM" "" "$SVC_TELEGRAM" "$PROC_TELEGRAM" ;;
                7)  add_app "$PKG_WA" "" "$SVC_WA" "$PROC_WA" ;;
                8)  add_app "$PKG_WAB" "" "$SVC_WAB" "$PROC_WAB" ;;
                9)  add_app "$PKG_TCB" "" "$SVC_TCB" "$PROC_TCB" ;;
                10) add_app "$PKG_VCB" "" "$SVC_VCB" "$PROC_VCB" ;;
                11) add_app "$PKG_BIDV" "" "$SVC_BIDV" "$PROC_BIDV" ;;
                12) add_app "$PKG_SHOPEE" "" "$SVC_SHOPEE" "$PROC_SHOPEE" ;;
                13) add_app "$PKG_MOMO" "" "$SVC_MOMO" "$PROC_MOMO" ;;
                14) add_app "$PKG_VNPAY" "" "$SVC_VNPAY" "$PROC_VNPAY" ;;
                15) add_app "$PKG_GRAB" "" "$SVC_GRAB" "$PROC_GRAB" ;;
                16) add_app "$PKG_VTPAY" "" "$SVC_VTPAY" "$PROC_VTPAY" ;;
                17) add_app "$PKG_VIB" "" "$SVC_VIB" "$PROC_VIB" ;;
                18) add_app "$PKG_TPB" "" "$SVC_TPB" "$PROC_TPB" ;;
                19) add_app "$PKG_AUTO" "" "$SVC_AUTO" "$PROC_AUTO" ;;
            esac
        done
    fi
    
    apply_whitelist
}

# ================================
# SELECT ALL
# ================================
select_all() {
    add_app "$PKG_GMS" "$PKG_EXT" "$SVC_GMS" "$PROC_GMS"
    add_app "$PKG_CHROME" "" "$SVC_CHROME" "$PROC_CHROME"
    add_app "$PKG_GMAIL" "" "$SVC_GMAIL" "$PROC_GMAIL"
    add_app "$PKG_MESSENGER" "" "$SVC_MESSENGER" "$PROC_MESSENGER"
    add_app "$PKG_ZALO" "" "$SVC_ZALO" "$PROC_ZALO"
    add_app "$PKG_TELEGRAM" "" "$SVC_TELEGRAM" "$PROC_TELEGRAM"
    add_app "$PKG_WA" "" "$SVC_WA" "$PROC_WA"
    add_app "$PKG_WAB" "" "$SVC_WAB" "$PROC_WAB"
    add_app "$PKG_TCB" "" "$SVC_TCB" "$PROC_TCB"
    add_app "$PKG_VCB" "" "$SVC_VCB" "$PROC_VCB"
    add_app "$PKG_BIDV" "" "$SVC_BIDV" "$PROC_BIDV"
    add_app "$PKG_SHOPEE" "" "$SVC_SHOPEE" "$PROC_SHOPEE"
    add_app "$PKG_MOMO" "" "$SVC_MOMO" "$PROC_MOMO"
    add_app "$PKG_VNPAY" "" "$SVC_VNPAY" "$PROC_VNPAY"
    add_app "$PKG_GRAB" "" "$SVC_GRAB" "$PROC_GRAB"
    add_app "$PKG_VTPAY" "" "$SVC_VTPAY" "$PROC_VTPAY"
    add_app "$PKG_VIB" "" "$SVC_VIB" "$PROC_VIB"
    add_app "$PKG_TPB" "" "$SVC_TPB" "$PROC_TPB"
    add_app "$PKG_AUTO" "" "$SVC_AUTO" "$PROC_AUTO"
}

# ================================
# APPLY WHITELIST
# ================================
apply_whitelist() {
    if [ -z "$rt_list" ]; then
        echo "[LOI] Chua chon ung dung nao!"
        read -p "Press enter to continue..."
        menu
        return
    fi
    
    # Remove trailing comma
    rt_list="${rt_list%,}"
    power_pkg_list="${power_pkg_list%,}"
    power_proc_list="${power_proc_list%,}"
    power_svc_list="${power_svc_list%,}"
    
    echo ""
    echo "[3/9] rt_pkg_white_list..."
    adb shell settings put system rt_pkg_white_list "$rt_list" &> /dev/null
    
    echo "[4/9] power_pkg_white_list..."
    adb shell settings put system power_pkg_white_list "$power_pkg_list" &> /dev/null
    
    echo "[5/9] power_proc_white_list..."
    adb shell settings put system power_proc_white_list "$power_proc_list" &> /dev/null
    
    echo "[6/9] power_service_white_list..."
    adb shell settings put system power_service_white_list "$power_svc_list" &> /dev/null
    
    echo "[7/9] deviceidle whitelist..."
    IFS=',' read -ra PKGS <<< "$power_pkg_list"
    for pkg in "${PKGS[@]}"; do
        adb shell dumpsys deviceidle whitelist +$pkg &> /dev/null
    done
    
    gms_checkin_menu
}

# ================================
# GMS CHECKIN MENU
# ================================
gms_checkin_menu() {
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║               BAT GMS CHECK-IN (THONG BAO ON DINH)        ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "   Chon thoi gian GMS tu dong ket noi lai (check-in):"
    echo ""
    echo "   [1]  Moi 1 phut  → GMS check-in sau 60 giay"
    echo "   [2]  Moi 2 phut  → GMS check-in sau 120 giay"
    echo "   [3]  Moi 3 phut"
    echo "   [4]  Moi 4 phut"
    echo "   [5]  Moi 5 phut"
    echo "   [6]  Moi 6 phut"
    echo ""
    echo "   [0]  KHONG BAT → Mac dinh ~30 phut (khong toi uu)"
    echo "   [X]  THOAT"
    echo ""
    
    read -p "Nhap so (0-6 hoac X): " gms_choice
    
    if [[ "$gms_choice" == "X" ]] || [[ "$gms_choice" == "x" ]]; then
        complete
        return
    fi
    
    if [ "$gms_choice" == "0" ]; then
        complete
        return
    fi
    
    case $gms_choice in
        1) timeout_min=1 ;;
        2) timeout_min=2 ;;
        3) timeout_min=3 ;;
        4) timeout_min=4 ;;
        5) timeout_min=5 ;;
        6) timeout_min=6 ;;
        *)
            echo ""
            echo "[LOI] Vui long nhap dung so tu 0-6!"
            sleep 2
            gms_checkin_menu
            return
            ;;
    esac
    
    echo ""
    echo "[8/9] Dang dat gms_checkin_timeout_min = $timeout_min phut..."
    adb shell settings put global gms_checkin_timeout_min $timeout_min &> /dev/null
    adb shell settings put global gms_checkin_enabled 1 &> /dev/null
    
    echo "[OK] GMS se tu dong check-in moi $timeout_min phut!"
    
    complete
}

# ================================
# COMPLETE
# ================================
complete() {
    echo ""
    echo "[9/9] HOAN TAT! Hay khoi dong lai may de ap dung day du."
    echo ""
    read -p "Khoi dong lai ngay? (y/N): " reboot
    
    if [[ "$reboot" == "y" ]] || [[ "$reboot" == "Y" ]]; then
        echo "Dang khoi dong lai..."
        adb reboot
    else
        echo "Vui long khoi dong lai thu cong de ap dung."
    fi
    
    echo ""
    echo "KIEM TRA SAU KHI KHOI DONG:"
    echo "   adb shell settings get global gms_checkin_timeout_min"
    echo "   adb shell dumpsys deviceidle whitelist"
    echo ""
    read -p "Press enter to exit..."
    exit 0
}

# ================================
# MAIN
# ================================
menu
