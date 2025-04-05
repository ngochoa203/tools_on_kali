#!/bin/bash

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "Vui lòng chạy script với quyền root (sudo)." 
   exit 1
fi

# Lấy danh sách các interface Wi-Fi
INTERFACE=$(nmcli device status | grep wifi | awk '{print $1}' | head -n 1)

if [ -z "$INTERFACE" ]; then
    echo "Không tìm thấy card Wi-Fi nào!"
    exit 1
fi

echo "Sử dụng card Wi-Fi: $INTERFACE"

# Tạo 1000 AP Wi-Fi giả mạo
for i in $(seq 1 1000); do
    SSID="Wifi_$i"
    # SSID="VKU-SinhVien_$i"
    echo "Đang tạo AP: $SSID"

    nmcli device wifi hotspot ifname "$INTERFACE" ssid "$SSID" password "12345678"

    sleep 1  # Chờ 1 giây trước khi tạo AP tiếp theo
done

echo "✅ Hoàn thành việc tạo 1000 AP giả mạo!"

# Cấp quyền thực thi
#chmod +x fake_ap.sh

# Chạy script
#./fake_ap.sh

#stop
#nmcli radio wifi off && nmcli radio wifi on
