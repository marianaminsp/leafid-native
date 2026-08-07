-- Auto-processed hero image for the Botanical Card (Swift `Scan.cardImageURL`).
-- Additive/nullable: existing rows are unaffected, no backfill required — the client
-- lazily generates + patches this in for older scans (see BotanyService.ensureCardImageIfNeeded).

begin;

alter table if exists public.scans
  add column if not exists card_image_url text;

commit;
