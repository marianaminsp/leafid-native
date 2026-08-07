-- Shared, species-keyed cache for narrate-plant's cultural/historical content (Botanical Spirit,
-- Ethnobotany, Cultural Legacy). Once any user's scan generates content for a species, every later
-- scan of that species — by any user — reads the cached row instead of calling an LLM again.
-- Public read (harmless botanical facts, not user data); writes are service-role only (edge function),
-- so no client can pollute content every user reads from.

begin;

create table if not exists public.plant_narrative_cache (
  scientific_name_key text primary key,
  scientific_name text not null,
  common_name text,
  family text,
  origin_country text,
  botanical_spirit text,
  ethnobotany text,
  cultural_legacy text,
  legacy_fact text,
  colors jsonb,
  source text,
  hit_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.plant_narrative_cache enable row level security;

drop policy if exists "plant_narrative_cache_select_public" on public.plant_narrative_cache;
create policy "plant_narrative_cache_select_public"
on public.plant_narrative_cache
for select
to public
using (true);

-- No insert/update/delete policy for anon/authenticated on purpose — only the service role
-- (used server-side by narrate-plant, which bypasses RLS) can write to this table.

commit;
