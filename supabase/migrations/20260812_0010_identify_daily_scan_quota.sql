-- Per-user daily cap on identify-plant calls, enforced server-side so a handful of enthusiastic
-- beta testers can't burn through the shared free-tier provider quota (Pl@ntNet / Gemini-direct,
-- see ADR-0004) for every other user on the same day. See ADR-0005.

begin;

alter table if exists public.profiles
  add column if not exists daily_scan_count integer not null default 0;

alter table if exists public.profiles
  add column if not exists daily_scan_reset_at date not null default current_date;

comment on column public.profiles.daily_scan_count is 'identify-plant calls used today; reset to 0 the first time daily_scan_reset_at < current_date.';
comment on column public.profiles.daily_scan_reset_at is 'Date daily_scan_count last reset for. Not a cron — rolled forward lazily on the next call.';

-- Atomic check-and-increment: runs as the calling user (auth.uid()), SECURITY DEFINER so it can
-- write profiles rows that user-scoped RLS wouldn't otherwise allow beyond their own id (which is
-- also all this ever touches). `for update` row-locks the profile row for the duration of this
-- function call, so two concurrent identify requests from the same user can't both read count N
-- and both increment to N+1.
create or replace function public.check_and_increment_daily_scan_quota(p_daily_limit integer default 25)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_count integer;
  v_reset_at date;
begin
  if v_user_id is null then
    raise exception 'check_and_increment_daily_scan_quota requires an authenticated user';
  end if;

  insert into public.profiles (id, daily_scan_count, daily_scan_reset_at)
  values (v_user_id, 0, current_date)
  on conflict (id) do nothing;

  select daily_scan_count, daily_scan_reset_at into v_count, v_reset_at
  from public.profiles
  where id = v_user_id
  for update;

  if v_reset_at < current_date then
    v_count := 0;
    v_reset_at := current_date;
  end if;

  if v_count >= p_daily_limit then
    update public.profiles
    set daily_scan_reset_at = v_reset_at
    where id = v_user_id;
    return false;
  end if;

  update public.profiles
  set daily_scan_count = v_count + 1,
      daily_scan_reset_at = v_reset_at
  where id = v_user_id;

  return true;
end;
$$;

grant execute on function public.check_and_increment_daily_scan_quota(integer) to authenticated;

commit;
