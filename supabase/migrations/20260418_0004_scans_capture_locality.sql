-- Capture metadata for Herbarium / Arboretum: GPS + reverse-geocoded city (Swift `Scan.locality`).

begin;

alter table if exists public.scans
  add column if not exists latitude double precision;

alter table if exists public.scans
  add column if not exists longitude double precision;

alter table if exists public.scans
  add column if not exists locality text;

commit;
