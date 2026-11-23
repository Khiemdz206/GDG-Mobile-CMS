# Backend Supabase

App dùng [Supabase](https://supabase.com) làm backend. Supabase cho sẵn:

- **Auth**: đăng ký, đăng nhập, quản lý mật khẩu và phiên đăng nhập. App không tự lưu token.
- **Database Postgres**: dữ liệu của CLB. App đọc/ghi thẳng bằng SDK `supabase_flutter`.
- **RLS (Row Level Security)**: luật trong database quyết định ai được đọc/sửa dòng nào. Đây là lớp bảo vệ thật; ẩn nút trên app không phải là bảo mật.

Cấu trúc database nằm trong [supabase/migrations/](../supabase/migrations). Mọi thay đổi bảng/quyền phải là một file migration mới và đi qua PR.

## 1. Tạo project (làm một lần, người quản lý repo làm)

1. Vào https://supabase.com/dashboard → **New project**. Đặt tên `gdg-cms`, chọn region **Singapore**, lưu mật khẩu database vào nơi an toàn.
2. Mở **SQL Editor** → **New query**, dán toàn bộ nội dung file [supabase/migrations/20261123000000_initial_schema.sql](../supabase/migrations/20261123000000_initial_schema.sql) → **Run**.
   Mong đợi: `Success. No rows returned`. Vào **Table Editor** thấy 3 bảng `profiles`, `events`, `event_participants`.
3. **Authentication → Sign In / Providers → Email**: bật Email.
   - Đang phát triển, có thể tắt **Confirm email** để đăng ký xong vào app luôn.
   - Khi dùng thật nên bật lại. Lúc đó đăng ký xong người dùng phải bấm link trong email rồi mới đăng nhập được.
4. **Project Settings → API Keys**: copy **Project URL** và **Publishable key** (`sb_publishable_...`).
   **Không bao giờ** dùng secret key (`sb_secret_...`) hay `service_role` trong app: key đó bỏ qua mọi RLS.

## 2. Nối app với Supabase (mỗi thành viên làm trên máy mình)

1. Copy file mẫu:

   ```powershell
   Copy-Item env.example.json env.json
   ```

2. Mở `env.json`, điền URL và publishable key người quản lý gửi. `env.json` đã nằm trong `.gitignore`, không commit file này.
3. Chạy app:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

   Dùng VS Code thì bấm F5 với cấu hình **GDG CMS** (đã có sẵn trong `.vscode/launch.json`).

Quên bước 1–2 thì app hiện màn hình báo thiếu cấu hình thay vì chạy.

## 3. Bảng và quyền

| Bảng | Lưu gì | Ai đọc | Ai ghi |
|---|---|---|---|
| `profiles` | username, họ tên, role (`Member`/`Leader`/`Admin`) | Thành viên đã đăng nhập | Tự sửa họ tên của mình; role chỉ đổi trong Dashboard |
| `events` | tiêu đề, mô tả, địa điểm, `start_at` | Thành viên đã đăng nhập | Leader/Admin |
| `event_participants` | ai xác nhận tham gia sự kiện nào | Thành viên đã đăng nhập | Mỗi người tự thêm/xoá dòng của mình |

- Hồ sơ được **tự tạo** khi đăng ký, nhờ trigger `on_auth_user_created`. Role mặc định là `Member`.
- Email nằm ở Supabase Auth, không lặp lại trong `profiles`.

**Cấp quyền Leader cho một người**: SQL Editor, chạy

```sql
update public.profiles set role = 'Leader' where username = 'ten_username';
```

**Thêm sự kiện thử** (trong Dashboard, SQL Editor chạy với quyền admin nên không bị RLS chặn):

```sql
insert into public.events (title, description, location, start_at)
values ('Workshop Flutter', 'Làm app đầu tiên với Flutter', 'D3-301', now() + interval '7 days');
```

## 4. Thay đổi database

1. Tạo file mới trong `supabase/migrations/`, tên bắt đầu bằng thời gian: `YYYYMMDDHHMMSS_mo_ta.sql`. **Không sửa file migration đã chạy.**
2. Mỗi bảng mới phải `enable row level security` và có policy rõ ràng.
3. Mở PR; trong mô tả ghi bảng/quyền nào thay đổi.
4. Merge xong, người quản lý chạy file đó trong SQL Editor, hoặc dùng `supabase db push` nếu đã cài [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started).
