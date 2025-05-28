#!/bin/bash

# Thông tin Git
GIT_NAME="ngochoa203"
GIT_EMAIL="hongochoa203@gmail.com"

echo "👉 Đang cấu hình Git..."
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo "✅ Git đã được cấu hình: $GIT_NAME <$GIT_EMAIL>"

# Tạo SSH key nếu chưa có
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
  echo "🔑 SSH key đã tồn tại tại $SSH_KEY"
else
  echo "🔑 Tạo SSH key mới..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
fi

# Thêm key vào ssh-agent
echo "🚀 Thêm SSH key vào ssh-agent..."
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

# Hiển thị public key
echo "📋 Dưới đây là SSH public key của bạn, hãy dán vào GitHub:"
echo "--------------------------------------------------------"
cat "${SSH_KEY}.pub"
echo "--------------------------------------------------------"
echo "👉 Vào https://github.com/settings/keys để thêm key."

# Kiểm tra kết nối GitHub
echo "🧪 Kiểm tra kết nối đến GitHub..."
ssh -T git@github.com

echo "✅ Hoàn tất!"
