# Hướng dẫn cho AI agent làm việc trên GDG CMS

Đọc README.md, docs/BRANCHING_POLICY.md và docs/GDG_API.md trước khi sửa code.

- Thành viên CLB là sinh viên, thay người theo từng khoá. Ưu tiên cách làm đơn giản, ít bước, dễ giải thích lại; không thêm thư viện hay tầng trừu tượng khi chưa cần.
- Hướng dẫn viết theo thứ tự: cần làm gì → chạy lệnh ở đâu → kết quả mong đợi → lỗi thường gặp. Viết tiếng Việt, giải thích thuật ngữ khi xuất hiện lần đầu.
- Stack: Flutter (phiên bản trong `.fvmrc`), go_router, http, shared_preferences. Backend là `https://gdg-cms.vercel.app`, nằm ngoài repo; chỉ gọi endpoint có trong docs/GDG_API.md. Cần endpoint mới thì ghi rõ là chưa có, không đoán đường dẫn.
- Không trả thành công giả: chưa làm hoặc server lỗi thì hiện lỗi đúng nguyên nhân cho người dùng (mất mạng, sai mật khẩu, hết phiên).
- Code gọi API để trong `lib/core/network/`, không gọi `http` trực tiếp trong widget mới.
- Sửa logic (gọi API, parse dữ liệu, xử lý lỗi) phải có test trong `test/`. Test dùng `MockClient` của package http, không gọi backend thật.
- Trước khi xong việc chạy: `dart format lib test`, `flutter analyze --no-fatal-infos`, `flutter test`.
- Không commit `pubspec.lock` bị sửa do dùng Flutter khác phiên bản `.fvmrc`.
- Không đưa key, mật khẩu, token, keystore hay dữ liệu cá nhân vào Git.
- Nhánh từ `develop`, PR vào `develop`, reviewer khác tác giả. Không push thẳng hoặc force push `develop`/`main`. Chỉ push, tạo PR hoặc deploy khi người dùng yêu cầu.
