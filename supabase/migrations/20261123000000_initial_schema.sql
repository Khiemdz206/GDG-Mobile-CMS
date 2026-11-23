-- GDG CMS — schema ban đầu trên Supabase.
--
-- Bảng:
--   profiles            hồ sơ thành viên, 1-1 với auth.users (Supabase Auth giữ email/mật khẩu)
--   events              sự kiện của CLB
--   event_participants  ai đã xác nhận tham gia sự kiện nào
--
-- Nguyên tắc quyền (RLS):
--   - Phải đăng nhập mới đọc được dữ liệu.
--   - Thành viên chỉ sửa được họ tên của chính mình; không tự đổi role/username.
--   - Chỉ Leader/Admin tạo, sửa, xoá sự kiện.
--   - Mỗi người chỉ tự đăng ký/huỷ tham gia cho chính mình.

-- ---------------------------------------------------------------------------
-- Hàm nội bộ (schema private không lộ ra API)
-- ---------------------------------------------------------------------------
create schema if not exists private;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  username    text not null unique
              check (username ~ '^[A-Za-z0-9_.]{3,30}$'),
  first_name  text not null default '' check (char_length(first_name) <= 50),
  last_name   text not null default '' check (char_length(last_name) <= 50),
  role        text not null default 'Member'
              check (role in ('Member', 'Leader', 'Admin')),
  created_at  timestamptz not null default now()
);

comment on table public.profiles is 'Hồ sơ thành viên CLB, tạo tự động khi đăng ký.';

-- Tạo hồ sơ ngay khi có tài khoản mới. Username/họ tên lấy từ metadata lúc đăng ký;
-- role luôn là Member, không tin giá trị client gửi lên.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username, first_name, last_name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'username'), ''), 'user_' || substr(new.id::text, 1, 8)),
    coalesce(trim(new.raw_user_meta_data ->> 'first_name'), ''),
    coalesce(trim(new.raw_user_meta_data ->> 'last_name'), '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

create function private.is_leader()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role in ('Leader', 'Admin')
  );
$$;

grant usage on schema private to authenticated;
grant execute on function private.is_leader() to authenticated;

alter table public.profiles enable row level security;

create policy profiles_read on public.profiles
  for select to authenticated
  using (true);

create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Chỉ cho sửa họ tên; role/username không sửa được từ app.
revoke all on public.profiles from anon;
revoke insert, update, delete on public.profiles from authenticated;
grant update (first_name, last_name) on public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- events
-- ---------------------------------------------------------------------------
create table public.events (
  id           uuid primary key default gen_random_uuid(),
  title        text not null check (char_length(title) between 1 and 200),
  description  text not null default '',
  location     text not null default '',
  start_at     timestamptz,
  notify_to    text[] not null default array['Member', 'Leader', 'Admin'],
  created_by   uuid references public.profiles (id) on delete set null
               default auth.uid(),
  created_at   timestamptz not null default now()
);

create index events_start_at_idx on public.events (start_at);

alter table public.events enable row level security;

create policy events_read on public.events
  for select to authenticated
  using (true);

create policy events_insert_leader on public.events
  for insert to authenticated
  with check ((select private.is_leader()));

create policy events_update_leader on public.events
  for update to authenticated
  using ((select private.is_leader()))
  with check ((select private.is_leader()));

create policy events_delete_leader on public.events
  for delete to authenticated
  using ((select private.is_leader()));

revoke all on public.events from anon;

-- ---------------------------------------------------------------------------
-- event_participants
-- ---------------------------------------------------------------------------
create table public.event_participants (
  event_id    uuid not null references public.events (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade
              default auth.uid(),
  created_at  timestamptz not null default now(),
  primary key (event_id, user_id)
);

create index event_participants_user_idx on public.event_participants (user_id);

alter table public.event_participants enable row level security;

create policy participants_read on public.event_participants
  for select to authenticated
  using (true);

create policy participants_join_self on public.event_participants
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy participants_leave_self on public.event_participants
  for delete to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.event_participants from anon;
revoke update on public.event_participants from authenticated;
