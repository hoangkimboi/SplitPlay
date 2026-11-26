# 🚗 SplitPlay2 - Tweak Chia Đôi Màn Hình CarPlay (Kiến Trúc carplay-cast)

Dự án này được thiết kế và viết lại từ đầu dựa trên **kiến trúc `carplay-cast` chuẩn của Ethan Arbuckle**, tái hiện chính xác 100% giao diện và tính năng của **SidePlay2**.

---

## 🏛️ Kiến Trúc Hệ Thống (Architecture)

```
SplitPlay2
├── src/
│   ├── common.h                 ← Định nghĩa private API iOS, macros objcInvoke
│   ├── core/
│   │   ├── SP2Car.h/.mm         ← Quản lý CADisplay, UIRootSceneWindow ngoài xe, keep-alive
│   ├── ui/
│   │   ├── SP2Workspace.h/.mm   ← Điều phối 2 khung (Panes), tỷ lệ 50/50, 60/40, 70/30
│   │   ├── SP2Pane.h/.mm        ← Khung chứa app: Tab bar (Close/Swap/Zoom), SceneView
│   │   ├── SP2Dividers.h/.mm    ← Thanh kéo chia đôi màn hình có grabber pill
│   │   └── SP2Picker.h/.mm      ← Giao diện chọn app dạng lưới (App Chooser) trên CarPlay
│   ├── hud/
│   │   └── SP2Bubble.h/.mm      ← Bong bóng tốc độ GPS thực tế & cảnh báo giới hạn tốc độ
│   └── hooks/
│       └── Tweak.x              ← Hook SpringBoard, CarPlay, lock screen & xoay màn hình
├── prefs/                       ← Toàn bộ giao diện Cài đặt (Drive, Car, Speed, Root)
└── .github/workflows/build.yml  ← Tự động biên dịch ra file .deb trên macOS Cloud
```

---

## 🚀 2 Cách Build Ra File `.deb` Dễ Dàng Nhất

### Cách 1: Build Tự Động Qua GitHub Actions (Khuyên dùng - Không cần cài đặt gì trên máy)
1. Tạo một repository mới trên GitHub (Private hoặc Public).
2. Tải toàn bộ thư mục `SplitPlay` lên GitHub.
3. GitHub Actions sẽ tự động kích hoạt workflow `.github/workflows/build.yml` chạy trên máy chủ macOS của GitHub:
   - Tự cài Theos & iOS SDK
   - Tự compile Clang ra mã máy `arm64/arm64e`
   - Đóng gói file `SplitPlay2_2.1.4_iphoneos-arm64.deb`
4. Vào mục **Actions** ➔ Tải file `.deb` về cài thẳng vào iPhone!

### Cách 2: Compile Trực Tiếp Trên iPhone Jailbreak
1. Chép thư mục `SplitPlay` vào iPhone (qua Filza hoặc SSH vào thư mục `/var/mobile/SplitPlay`).
2. Mở ứng dụng **NewTerm** (hoặc SSH vào iPhone).
3. Chạy lệnh:
   ```bash
   cd /var/mobile/SplitPlay
   bash build_on_iphone.sh
   ```
4. Script sẽ tự compile và cài thẳng vào máy, tự Respring!
