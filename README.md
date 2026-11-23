# GDG CMS — app quản lý CLB GDG on Campus HUST

App Flutter cho thành viên CLB: đăng ký/đăng nhập, xem lịch và sự kiện sắp tới, xem và sửa hồ sơ.

- **App**: Flutter, chạy Android và iOS.
- **Backend**: [Supabase](https://supabase.com) (đăng nhập + database). Cấu trúc database nằm trong `supabase/migrations/`. Cách tạo project và nối app: [docs/SUPABASE.md](docs/SUPABASE.md).

## 1. Chạy app lần đầu

Làm tại thư mục gốc của repo (nơi có `pubspec.yaml`).

**Bước 1: Cài Flutter đúng phiên bản.** Nhóm dùng phiên bản ghi trong [`.fvmrc`](.fvmrc). Cách dễ nhất là dùng [FVM](https://fvm.app):

```bash
fvm install
fvm use
```

Không dùng FVM thì cài đúng bản Flutter ghi trong `.fvmrc`. Bản cũ hơn sẽ làm `flutter pub get` sửa `pubspec.lock`; **không commit thay đổi đó**.

**Bước 2: Cài thư viện.**

```bash
flutter pub get
```

Mong đợi: báo `Got dependencies!`, `git status` không thấy `pubspec.lock` bị sửa.

**Bước 3: Điền cấu hình Supabase.** Copy `env.example.json` thành `env.json`, điền URL và publishable key do người quản lý gửi. Chi tiết: [docs/SUPABASE.md](docs/SUPABASE.md#2-nối-app-với-supabase-mỗi-thành-viên-làm-trên-máy-mình). Không commit `env.json`.

**Bước 4: Chạy app.** Mở emulator Android (hoặc cắm máy thật đã bật USB debugging), rồi:

```bash
flutter run --dart-define-from-file=env.json
```

Trong VS Code chỉ cần bấm F5 (cấu hình **GDG CMS** đã truyền sẵn `env.json`).

Mong đợi: app mở màn Onboarding. Đăng ký một tài khoản test bằng email để vào Home.

**Lỗi thường gặp**

| Lỗi | Cách xử lý |
|---|---|
| `The current Dart SDK version is ...` | Flutter cũ hơn bản trong `.fvmrc`; cài đúng bản |
| `No connected devices` | Mở emulator trước, kiểm tra bằng `flutter devices` |
| App báo "Thiếu cấu hình Supabase" | Chưa tạo `env.json` hoặc chạy thiếu `--dart-define-from-file=env.json` |
| Đăng ký xong không vào được app | Project Supabase đang bật xác minh email: mở email, bấm link, rồi đăng nhập |

## 2. Trước khi mở Pull Request

Chạy đủ 3 lệnh sau. CI trên GitHub chạy đúng các lệnh này, lệnh nào lỗi thì PR không được merge:

```bash
dart format lib test
flutter analyze --no-fatal-infos
flutter test
```

Quy trình nhánh, PR và commit message: [docs/BRANCHING_POLICY.md](docs/BRANCHING_POLICY.md). Tóm tắt:

1. Tạo nhánh từ `develop` mới nhất: `feature/...`, `fix/...`.
2. Mở PR vào `develop`, điền đủ mẫu PR.
3. Chờ CI xanh và **một người khác** approve rồi mới merge. Không tự merge PR của mình.
4. `develop` ổn định thì mở PR `develop` → `main` để phát hành.

## 3. Cấu trúc thư mục

```
lib/
├── main.dart                 # Khởi động app, chọn màn đầu tiên theo trạng thái đăng nhập
├── core/
│   ├── config/app_config.dart     # Đọc và kiểm tra cấu hình Supabase
│   ├── network/                   # AuthService (đăng nhập), ProfileService (hồ sơ)
│   ├── router/app_router.dart     # Danh sách route (go_router)
│   ├── theme/                     # Màu, font chữ
│   └── error/error_messages.dart  # Đổi lỗi Supabase/mạng thành câu tiếng Việt
└── features/
    ├── login/ui/             # Onboarding, đăng nhập, đăng ký
    ├── main/ui/home/         # Khung chính 3 tab và trang chủ (lịch)
    ├── main/ui/profile/      # Hồ sơ, sửa hồ sơ, đăng xuất
    ├── events/data/          # Model Event và EventRepository (đọc bảng events)
    ├── events/               # Danh sách, thẻ vuốt và chi tiết sự kiện
    └── post/                 # Mới có khung, chưa dùng
supabase/migrations/          # Cấu trúc database và quyền (RLS)
test/                         # Test tự động (chạy bằng flutter test)
```

Thư viện chính: `supabase_flutter` (đăng nhập, database), `go_router` (điều hướng), `table_calendar`, `flutter_svg`, `google_fonts`.

## 4. Viết test

Test nằm trong `test/`, cấu trúc thư mục giống `lib/`. Test không gọi Supabase thật: tách phần logic (đọc dữ liệu trả về, kiểm tra cấu hình, đổi lỗi thành thông báo) ra hàm riêng rồi test hàm đó. Ví dụ [test/features/events/event_test.dart](test/features/events/event_test.dart) kiểm tra `Event.fromRow` với dữ liệu giống Supabase trả về.

Test phải gọi code thật của app (parse dữ liệu, xử lý lỗi, lưu token). Không viết test chỉ so một hằng số với chính nó.
