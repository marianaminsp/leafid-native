-- W4 baseline: RLS hardening for core public tables.
-- Safe/idempotent policy reset for existing environments.

begin;

-- Ensure RLS is enabled on known tables when present.
alter table if exists public.profiles enable row level security;
alter table if exists public.trees enable row level security;
alter table if exists public.scans enable row level security;

-- --------
-- profiles
-- --------
drop policy if exists "Insertar perfil propio al registrarse" on public.profiles;
drop policy if exists "Los usuarios editan su propio perfil" on public.profiles;
drop policy if exists "Los usuarios ven su propio perfil" on public.profiles;

create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- -----
-- trees
-- -----
drop policy if exists "Allow public insert" on public.trees;
drop policy if exists "Cualquiera puede ver los árboles" on public.trees;
drop policy if exists "Enable read access for all users" on public.trees;

-- Public read catalog behavior.
create policy "trees_select_public"
on public.trees
for select
to public
using (true);

-- Transitional: keep insert open while app runs without user auth.
-- TODO: move tree writes to edge/service role or authenticated-only ownership.
create policy "trees_insert_public"
on public.trees
for insert
to public
with check (true);

-- -----
-- scans
-- -----
-- This assumes scans has a user ownership column.
-- If the ownership column differs, this policy must be adjusted
-- before applying in production.
drop policy if exists "scans_select_own" on public.scans;
drop policy if exists "scans_insert_own" on public.scans;
drop policy if exists "scans_update_own" on public.scans;
drop policy if exists "scans_delete_own" on public.scans;
drop policy if exists "scans_select_public" on public.scans;
drop policy if exists "scans_insert_public" on public.scans;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'scans'
      and column_name in ('user_id', 'profile_id')
  ) then
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'scans'
        and column_name = 'user_id'
    ) then
      execute $policy$
        create policy "scans_select_own"
        on public.scans
        for select
        to authenticated
        using (auth.uid() = user_id)
      $policy$;

      execute $policy$
        create policy "scans_insert_own"
        on public.scans
        for insert
        to authenticated
        with check (auth.uid() = user_id)
      $policy$;

      execute $policy$
        create policy "scans_update_own"
        on public.scans
        for update
        to authenticated
        using (auth.uid() = user_id)
        with check (auth.uid() = user_id)
      $policy$;

      execute $policy$
        create policy "scans_delete_own"
        on public.scans
        for delete
        to authenticated
        using (auth.uid() = user_id)
      $policy$;
    else
      execute $policy$
        create policy "scans_select_own"
        on public.scans
        for select
        to authenticated
        using (auth.uid() = profile_id)
      $policy$;

      execute $policy$
        create policy "scans_insert_own"
        on public.scans
        for insert
        to authenticated
        with check (auth.uid() = profile_id)
      $policy$;

      execute $policy$
        create policy "scans_update_own"
        on public.scans
        for update
        to authenticated
        using (auth.uid() = profile_id)
        with check (auth.uid() = profile_id)
      $policy$;

      execute $policy$
        create policy "scans_delete_own"
        on public.scans
        for delete
        to authenticated
        using (auth.uid() = profile_id)
      $policy$;
    end if;
  else
    -- Transitional fallback for current schema (no ownership column yet):
    -- allow creating and reading scans so existing app flow keeps working.
    -- Updates/deletes are intentionally not granted.
    execute $policy$
      create policy "scans_select_public"
      on public.scans
      for select
      to public
      using (true)
    $policy$;

    execute $policy$
      create policy "scans_insert_public"
      on public.scans
      for insert
      to public
      with check (true)
    $policy$;
  end if;
end
$$;

commit;
