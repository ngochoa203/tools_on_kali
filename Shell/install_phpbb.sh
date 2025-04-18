#!/bin/bash

echo "[+] Cập nhật hệ thống & cài gói cần thiết..."
sudo apt update && sudo apt install apache2 php php-mysql mariadb-server unzip wget -y

echo "[+] Tải phpBB..."
wget https://download.phpbb.com/pub/release/3.3/3.3.11/phpBB-3.3.11.zip
unzip phpBB-3.3.11.zip
sudo mv phpBB3 /var/www/html/forum

echo "[+] Cấp quyền thư mục..."
sudo chown -R www-data:www-data /var/www/html/forum

echo "[+] Khởi động MariaDB và Apache..."
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl start apache2
sudo systemctl enable apache2

echo "[+] Tạo database và user..."
sudo mysql -u root <<EOF
CREATE DATABASE phpbb;
CREATE USER 'phpbbuser'@'localhost' IDENTIFIED BY 'toimat123';
GRANT ALL PRIVILEGES ON phpbb.* TO 'phpbbuser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo ""
echo "✅ Đã xong! Truy cập vào trình duyệt:"
echo "👉 http://localhost/forum"
echo ""
echo "📝 DB: phpbb / User: phpbbuser / Pass: toimat123"
echo "🚀 Làm theo wizard cài phpBB trên web là xong!"

