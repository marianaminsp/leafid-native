-- W4 step 2: introduce ownership column for scans.
-- Keeps compatibility with existing rows while enabling owner-based RLS migration.

begin;

alter table if exists public.scans
  add column if not exists user_id uuid;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'scans'
  ) and not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'scans'
      and constraint_name = 'scans_user_id_fkey'
  ) then
    alter table public.scans
      add constraint scans_user_id_fkey
      foreign key (user_id)
      references auth.users (id)
      on delete set null;
  end if;
end
$$;

create index if not exists idx_scans_user_id on public.scans (user_id);
create index if not exists idx_scans_created_at on public.scans (created_at desc);

commit;
