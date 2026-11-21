-- 딜팟 초기 스키마
-- 실행: supabase db push  (또는 대시보드 SQL Editor에 붙여넣기)
-- 회사 도메인은 이 파일에 쓰지 않는다. 배포 후 대시보드에서 직접 넣는다:
--   insert into private.allowed_email_domains (domain) values ('company.com');

create extension if not exists citext;

-- ─────────────────────────────────────────────
-- 0. 비공개 설정 (API로 노출 안 되는 스키마)
-- ─────────────────────────────────────────────
create schema if not exists private;

create table private.allowed_email_domains (
  domain citext primary key
);

-- 이메일 도메인이 허용 목록에 있는지
create or replace function private.is_allowed_email(email text)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from private.allowed_email_domains d
    where d.domain = split_part(lower(email), '@', 2)
  );
$$;

-- ─────────────────────────────────────────────
-- 1. 가입 차단: Before User Created 훅
--    대시보드 > Authentication > Hooks > Before User Created
--    > Postgres function > public.hook_before_user_created
-- ─────────────────────────────────────────────
create or replace function public.hook_before_user_created(event jsonb)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  user_email text := event -> 'user' ->> 'email';
begin
  if user_email is not null and private.is_allowed_email(user_email) then
    return '{}'::jsonb;  -- 통과
  end if;
  return jsonb_build_object(
    'error', jsonb_build_object(
      'http_code', 403,
      'message', '회사 이메일 계정만 들어올 수 있어요.'
    )
  );
end;
$$;

grant execute on function public.hook_before_user_created to supabase_auth_admin;
grant usage on schema private to supabase_auth_admin;
grant select on private.allowed_email_domains to supabase_auth_admin;
revoke execute on function public.hook_before_user_created from authenticated, anon, public;

-- RLS에서 쓰는 공통 함수: 로그인 + 회사 도메인
create or replace function public.is_member()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null
     and private.is_allowed_email(auth.jwt() ->> 'email');
$$;

-- ─────────────────────────────────────────────
-- 2. 프로필
-- ─────────────────────────────────────────────
create table public.profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  nickname            citext unique
                      check (char_length(nickname) between 2 and 12),
  avatar_path         text,                       -- Storage 경로 (MS 사진 or 직접 업로드)
  nickname_changed_at timestamptz,
  is_admin            boolean not null default false,
  created_at          timestamptz not null default now()
);
comment on column public.profiles.nickname is 'null = 온보딩 전';

-- 가입하면 빈 프로필 자동 생성 → /onboarding에서 닉네임 입력
create or replace function private.handle_new_user()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- 닉네임 30일에 1번 + is_admin은 본인이 못 바꿈
create or replace function private.guard_profile_update()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.is_admin is distinct from old.is_admin
     and current_setting('request.jwt.claim.role', true) = 'authenticated' then
    raise exception '권한을 바꿀 수 없어요.';
  end if;

  if new.nickname is distinct from old.nickname then
    if old.nickname is not null
       and old.nickname_changed_at > now() - interval '30 days' then
      raise exception '닉네임은 30일에 한 번 바꿀 수 있어요.';
    end if;
    new.nickname_changed_at := case when old.nickname is null then null else now() end;
  end if;
  return new;
end;
$$;

create trigger guard_profile_update
  before update on public.profiles
  for each row execute function private.guard_profile_update();

-- ─────────────────────────────────────────────
-- 3. 장르 / 결제수단 (관리자가 추가)
-- ─────────────────────────────────────────────
create table public.genres (
  id         smallint generated always as identity primary key,
  name       text not null unique check (char_length(name) between 1 and 12),
  icon       text not null default 'tag',          -- Lucide 아이콘 이름 (썸네일 대체)
  sort_order smallint not null default 0,
  is_active  boolean not null default true
);

create table public.payment_methods (
  id         smallint generated always as identity primary key,
  name       text not null unique check (char_length(name) between 1 and 12),
  color      text not null check (color ~ '^#[0-9a-fA-F]{6}$'),
  logo_path  text,                                  -- 공식 로고 파일 (Storage)
  sort_order smallint not null default 0,
  is_active  boolean not null default true
);

insert into public.genres (name, icon, sort_order) values
  ('커피', 'coffee', 1), ('편의점', 'store', 2), ('배달', 'bike', 3),
  ('쇼핑', 'shopping-bag', 4), ('기타', 'tag', 99);

insert into public.payment_methods (name, color, sort_order) values
  ('네이버페이', '#03c75a', 1), ('카카오페이', '#ffe300', 2), ('토스페이', '#0064ff', 3);

-- ─────────────────────────────────────────────
-- 4. 딜
-- ─────────────────────────────────────────────
create type public.benefit_type as enum ('percent', 'price', 'text');

create table public.deals (
  id             uuid primary key default gen_random_uuid(),
  author_id      uuid references public.profiles (id) on delete set null,  -- 탈퇴해도 글은 남음
  genre_id       smallint not null references public.genres (id),
  title          text not null check (char_length(title) between 1 and 80),
  url            text check (url ~* '^https?://'),
  og_image_url   text,
  benefit_type   public.benefit_type,
  benefit_value  integer check (benefit_value >= 0),         -- percent: 0~100, price: 원
  benefit_text   text check (char_length(benefit_text) <= 12), -- '1+1', '무료' 등
  deadline       date,                                         -- null = 상시, 날짜는 KST 기준
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint benefit_shape check (
    benefit_type is null
    or (benefit_type = 'percent' and benefit_value between 0 and 100 and benefit_text is null)
    or (benefit_type = 'price'   and benefit_value is not null and benefit_text is null)
    or (benefit_type = 'text'    and benefit_text is not null and benefit_value is null)
  )
);

create index deals_created_at_idx on public.deals (created_at desc);
create index deals_deadline_idx   on public.deals (deadline);
create index deals_genre_idx      on public.deals (genre_id);

create table public.deal_payment_methods (
  deal_id           uuid     references public.deals (id) on delete cascade,
  payment_method_id smallint references public.payment_methods (id),
  primary key (deal_id, payment_method_id)
);
create index dpm_payment_idx on public.deal_payment_methods (payment_method_id);

create or replace function private.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end; $$;

create trigger deals_touch before update on public.deals
  for each row execute function private.touch_updated_at();

-- ─────────────────────────────────────────────
-- 5. 반응: 좋아요(공개) / 씀(본인만)
-- ─────────────────────────────────────────────
create table public.likes (
  deal_id    uuid references public.deals (id) on delete cascade,
  user_id    uuid references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (deal_id, user_id)
);

create table public.used_marks (
  deal_id    uuid references public.deals (id) on delete cascade,
  user_id    uuid references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (deal_id, user_id)
);
create index used_marks_user_idx on public.used_marks (user_id);

-- ─────────────────────────────────────────────
-- 6. 댓글 (대댓글 1단계)
-- ─────────────────────────────────────────────
create table public.comments (
  id         uuid primary key default gen_random_uuid(),
  deal_id    uuid not null references public.deals (id) on delete cascade,
  author_id  uuid references public.profiles (id) on delete set null,
  parent_id  uuid references public.comments (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);
create index comments_deal_idx on public.comments (deal_id, created_at);

create or replace function private.guard_comment_depth()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.parent_id is not null and exists (
    select 1 from public.comments c
    where c.id = new.parent_id and (c.parent_id is not null or c.deal_id <> new.deal_id)
  ) then
    raise exception '답글에는 답글을 달 수 없어요.';
  end if;
  return new;
end; $$;

create trigger comments_depth before insert on public.comments
  for each row execute function private.guard_comment_depth();

-- ─────────────────────────────────────────────
-- 7. 피드용 뷰 (집계 + 내 '씀' 여부)
--    security_invoker: 보는 사람의 RLS가 그대로 적용됨
-- ─────────────────────────────────────────────
create view public.deal_feed with (security_invoker = true) as
select
  d.*,
  coalesce(p.nickname, '탈퇴한 사용자')                         as author_nickname,
  p.avatar_path                                                  as author_avatar_path,
  g.name                                                         as genre_name,
  g.icon                                                         as genre_icon,
  coalesce(
    (select array_agg(dpm.payment_method_id order by pm.sort_order)
       from public.deal_payment_methods dpm
       join public.payment_methods pm on pm.id = dpm.payment_method_id
      where dpm.deal_id = d.id),
    '{}')                                                        as payment_method_ids,
  (select count(*) from public.likes l where l.deal_id = d.id)::int    as like_count,
  (select count(*) from public.comments c where c.deal_id = d.id)::int as comment_count,
  exists (select 1 from public.likes l
           where l.deal_id = d.id and l.user_id = auth.uid())   as liked_by_me,
  exists (select 1 from public.used_marks u
           where u.deal_id = d.id and u.user_id = auth.uid())   as used_by_me,
  (d.deadline is not null
     and d.deadline < (now() at time zone 'Asia/Seoul')::date)  as is_expired
from public.deals d
join public.genres g on g.id = d.genre_id
left join public.profiles p on p.id = d.author_id;

-- ─────────────────────────────────────────────
-- 8. RLS
-- ─────────────────────────────────────────────
alter table public.profiles             enable row level security;
alter table public.genres               enable row level security;
alter table public.payment_methods      enable row level security;
alter table public.deals                enable row level security;
alter table public.deal_payment_methods enable row level security;
alter table public.likes                enable row level security;
alter table public.used_marks           enable row level security;
alter table public.comments             enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

-- 프로필: 회원끼리 읽기, 본인만 수정
create policy "회원은 프로필을 본다" on public.profiles
  for select to authenticated using (public.is_member());
create policy "본인 프로필만 수정" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- 장르·결제수단: 회원 읽기, 관리자 쓰기
create policy "회원은 장르를 본다" on public.genres
  for select to authenticated using (public.is_member());
create policy "관리자가 장르 관리" on public.genres
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "회원은 결제수단을 본다" on public.payment_methods
  for select to authenticated using (public.is_member());
create policy "관리자가 결제수단 관리" on public.payment_methods
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 딜: 회원 읽기·쓰기, 수정·삭제는 작성자 + 관리자
create policy "회원은 딜을 본다" on public.deals
  for select to authenticated using (public.is_member());
create policy "회원은 딜을 올린다" on public.deals
  for insert to authenticated with check (public.is_member() and author_id = auth.uid());
create policy "작성자·관리자만 수정" on public.deals
  for update to authenticated
  using (author_id = auth.uid() or public.is_admin())
  with check (author_id = auth.uid() or public.is_admin());
create policy "작성자·관리자만 삭제" on public.deals
  for delete to authenticated using (author_id = auth.uid() or public.is_admin());

create policy "회원은 딜 결제수단을 본다" on public.deal_payment_methods
  for select to authenticated using (public.is_member());
create policy "딜 작성자·관리자가 결제수단 연결" on public.deal_payment_methods
  for all to authenticated
  using (exists (select 1 from public.deals d where d.id = deal_id
                  and (d.author_id = auth.uid() or public.is_admin())))
  with check (exists (select 1 from public.deals d where d.id = deal_id
                  and (d.author_id = auth.uid() or public.is_admin())));

-- 좋아요: 회원 모두 보기, 본인 것만 누르기/취소
create policy "회원은 좋아요를 본다" on public.likes
  for select to authenticated using (public.is_member());
create policy "본인 좋아요 추가" on public.likes
  for insert to authenticated with check (public.is_member() and user_id = auth.uid());
create policy "본인 좋아요 취소" on public.likes
  for delete to authenticated using (user_id = auth.uid());

-- 씀: 본인만 보고 본인만 바꿈 (남의 씀 기록은 안 보임)
create policy "본인 씀만 본다" on public.used_marks
  for select to authenticated using (user_id = auth.uid());
create policy "본인 씀 추가" on public.used_marks
  for insert to authenticated with check (public.is_member() and user_id = auth.uid());
create policy "본인 씀 취소" on public.used_marks
  for delete to authenticated using (user_id = auth.uid());

-- 댓글: 회원 읽기·쓰기, 삭제는 작성자 + 관리자 (수정 없음)
create policy "회원은 댓글을 본다" on public.comments
  for select to authenticated using (public.is_member());
create policy "회원은 댓글을 단다" on public.comments
  for insert to authenticated with check (public.is_member() and author_id = auth.uid());
create policy "작성자·관리자만 댓글 삭제" on public.comments
  for delete to authenticated using (author_id = auth.uid() or public.is_admin());

-- ─────────────────────────────────────────────
-- 9. 실시간: 새 딜, 댓글, 좋아요 변화를 구독
-- ─────────────────────────────────────────────
alter publication supabase_realtime add table public.deals, public.comments, public.likes;
