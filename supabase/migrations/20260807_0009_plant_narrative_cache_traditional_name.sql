-- Traditional/indigenous/vernacular name for the species (distinct from both the scientific Latin
-- name and the common English name) — shown on the Botanical Card back alongside the existing
-- narrative fields. Additive/nullable: existing cached rows are unaffected; narrate-plant lazily
-- backfills it on the next cache write for a species that doesn't have one yet.

begin;

alter table if exists public.plant_narrative_cache
  add column if not exists traditional_name text;

commit;
