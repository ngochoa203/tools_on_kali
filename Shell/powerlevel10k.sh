#!/bin/bash
set -e

echo "=== Cài đặt Oh My Zsh + Powerlevel10k + plugins cho user thường và root ==="

install_for_user() {
  local USER_HOME=$1
  local USER_NAME=$(stat -c '%U' "$USER_HOME")
  local OH_MY_ZSH_DIR="$USER_HOME/.oh-my-zsh"
  local CUSTOM_DIR="$OH_MY_ZSH_DIR/custom"

  echo ">>> Cài cho user: $USER_NAME ($USER_HOME)"

  if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    sudo -u "$USER_NAME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  mkdir -p "$CUSTOM_DIR/themes"
  mkdir -p "$CUSTOM_DIR/plugins"

  sudo -u "$USER_NAME" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$CUSTOM_DIR/themes/powerlevel10k" || true
  sudo -u "$USER_NAME" git clone https://github.com/zsh-users/zsh-autosuggestions "$CUSTOM_DIR/plugins/zsh-autosuggestions" || true
  sudo -u "$USER_NAME" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM_DIR/plugins/zsh-syntax-highlighting" || true
  sudo -u "$USER_NAME" git clone https://github.com/zsh-users/zsh-history-substring-search "$CUSTOM_DIR/plugins/zsh-history-substring-search" || true
  sudo -u "$USER_NAME" git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "$CUSTOM_DIR/plugins/zsh-autocomplete" || true

  local ZSHRC="$USER_HOME/.zshrc"

  if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "$ZSHRC.backup.$(date +%F-%T)"
    echo "Backup file $ZSHRC thành công."
  fi

  cat > "$ZSHRC" << EOF
export ZSH="$OH_MY_ZSH_DIR"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  zsh-autocomplete
)
source \$ZSH/oh-my-zsh.sh
EOF

  chown "$USER_NAME":"$USER_NAME" "$ZSHRC"
  echo "Đã cấu hình .zshrc cho $USER_NAME."
}

install_for_user "$HOME"
install_for_user "/root"

echo "=== Cài đặt font Nerd Font MesloLGS NF cho toàn hệ thống ==="

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Meslo.zip"
TMPDIR=$(mktemp -d)

echo "Tải font từ $FONT_URL ..."
curl -L "$FONT_URL" -o "$TMPDIR/Meslo.zip"

echo "Giải nén font ..."
unzip -o "$TMPDIR/Meslo.zip" -d "$TMPDIR"

echo "Tạo thư mục font hệ thống nếu chưa có ..."
mkdir -p /usr/share/fonts/truetype/nerd-fonts

echo "Copy font vào thư mục hệ thống ..."
cp "$TMPDIR"/*MesloLGS*.ttf /usr/share/fonts/truetype/nerd-fonts/

echo "Cập nhật cache font ..."
fc-cache -fv

echo "Xóa thư mục tạm ..."
rm -rf "$TMPDIR"

echo "=== Hoàn tất! ==="
echo "Bạn hãy đổi terminal sang font MesloLGS NF (Meslo LG S Regular Nerd Font Complete) để hiển thị Powerlevel10k chuẩn đẹp."
echo "Sau đó chạy lệnh 'exec zsh' hoặc đăng xuất đăng nhập lại."
