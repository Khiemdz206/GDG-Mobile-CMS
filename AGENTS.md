# Hướng dẫn cho AI agent làm việc trên GDG CMS

Đọc README.md, docs/BRANCHING_POLICY.md và docs/SUPABASE.md trước khi sửa code.

- Thành viên CLB là sinh viên, thay người theo từng khoá. Ưu tiên cách làm đơn giản, ít bước, dễ giải thích lại; không thêm thư viện hay tầng trừu tượng khi chưa cần.
- Hướng dẫn viết theo thứ tự: cần làm gì → chạy lệnh ở đâu → kết quả mong đợi → lỗi thường gặp. Viết tiếng Việt, giải thích thuật ngữ khi xuất hiện lần đầu.
- Stack: Flutter (phiên bản trong `.fvmrc`), go_router, supabase_flutter. Backend là Supabase; schema và RLS nằm trong `supabase/migrations/`. Đổi bảng/quyền bằng file migration mới, không sửa migration cũ; bảng mới phải bật RLS.
- Quyền được kiểm tra bằng RLS trong database, không chỉ bằng ẩn nút trên app. Không tin role/quyền do client gửi lên.
- App chỉ dùng publishable/anon key, đọc từ `--dart-define-from-file=env.json`. Không đưa secret/service_role key vào code hay Git.
- Không trả thành công giả: chưa làm hoặc server lỗi thì hiện lỗi đúng nguyên nhân cho người dùng (mất mạng, sai mật khẩu, hết phiên).
- Code gọi Supabase để trong service/repository (`lib/core/network/`, `lib/features/*/data/`), không gọi `Supabase.instance` trực tiếp trong widget mới. Lỗi hiện cho người dùng qua `errorMessage()`.
- Sửa logic (parse dữ liệu, kiểm tra cấu hình, xử lý lỗi) phải có test trong `test/`. Test không gọi Supabase thật.
- Trước khi xong việc chạy: `dart format lib test`, `flutter analyze --no-fatal-infos`, `flutter test`.
- Không commit `pubspec.lock` bị sửa do dùng Flutter khác phiên bản `.fvmrc`.
- Không đưa key, mật khẩu, token, keystore hay dữ liệu cá nhân vào Git.
- Nhánh từ `develop`, PR vào `develop`, reviewer khác tác giả. Không push thẳng hoặc force push `develop`/`main`. Chỉ push, tạo PR hoặc deploy khi người dùng yêu cầu.
