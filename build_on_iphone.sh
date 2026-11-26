#!/bin/bash
# ============================================================
# SplitPlay2 - Biên dịch trực tiếp trên iPhone Jailbreak
# Chạy script này trên NewTerm / MobileTerminal hoặc qua SSH
# ============================================================
set -e

echo "=== SplitPlay2 - iOS On-Device Compiler ==="

# 1. Kiểm tra Theos trên iPhone
if [ -z "$THEOS" ]; then
    if [ -d "/var/jb/var/mobile/theos" ]; then
        export THEOS=/var/jb/var/mobile/theos
    elif [ -d "$HOME/theos" ]; then
        export THEOS=$HOME/theos
    else
        echo "Theos chưa được cài trên iPhone. Đang tải..."
        git clone --recursive https://github.com/theos/theos.git $HOME/theos
        export THEOS=$HOME/theos
    fi
fi
export PATH=$THEOS/bin:$PATH

echo "Theos: $THEOS"

# 2. Biên dịch
echo "Bắt đầu compile..."
make clean
make package FINALPACKAGE=1

# 3. Cài đặt tự động
DEB=$(ls packages/*.deb 2>/dev/null | head -1)
if [ -n "$DEB" ]; then
    echo "Build thành công: $DEB"
    echo "Đang cài đặt vào hệ thống..."
    dpkg -i "$DEB"
    echo "Respring để kích hoạt..."
    killall -9 SpringBoard
else
    echo "Build thất bại, vui lòng kiểm tra lỗi bên trên!"
fi
