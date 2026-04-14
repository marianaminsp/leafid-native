-- Profile screen: display fields, lifetime scan counter, and activity feed
-- (`docs/ui-screens/Profile.png`). Client can sync when auth + REST are wired.

begin;

-- ---------------------------------------------------------------------------
-- profiles: role line under display name (avatar/display_name/bio may already exist)
-- ---------------------------------------------------------------------------
alter table if exists public.profiles
  add column if not exists role_title text;

alter table if exists public.profiles
  add column if not exists lifetime_scan_count integer not null default 0;

comment on column public.profiles.role_title is 'Short subtitle on Profile, e.g. Botanical Enthusiast.';
comment on column public.profiles.lifetime_scan_count is 'Total successful identify runs (increment from app even if user does not Save to Herbarium).';

-- ---------------------------------------------------------------------------
-- profile_activities: achievements + collection events for "Recent Discoveries"
-- ---------------------------------------------------------------------------
create table if not exists public.profile_activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  activity_type text not null check (activity_type in ('achievement', 'collection_add')),
  title text not null,
  subtitle text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_profile_activities_user_created
  on public.profile_activities (user_id, created_at desc);

comment on table public.profile_activities is 'Feed rows for Profile / Recent Discoveries (achievements, collection adds).';

alter table public.profile_activities enable row level security;

drop policy if exists "profile_activities_select_own" on public.profile_activities;
create policy "profile_activities_select_own"
on public.profile_activities
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "profile_activities_insert_own" on public.profile_activities;
create policy "profile_activities_insert_own"
on public.profile_activities
for insert
to authenticated
with check (auth.uid() = user_id);

-- Optional: service role / edge can insert achievements for the user.
drop policy if exists "profile_activities_update_own" on public.profile_activities;
create policy "profile_activities_update_own"
on public.profile_activities
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "profile_activities_delete_own" on public.profile_activities;
create policy "profile_activities_delete_own"
on public.profile_activities
for delete
to authenticated
using (auth.uid() = user_id);

commit;
