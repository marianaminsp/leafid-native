-- Public bucket for iOS Preserve uploads (`plant-images`).
-- Objects are stored as `{auth.uid()}/{scan_id}.jpg` for Storage RLS (first path segment = owner).

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'plant-images',
  'plant-images',
  true,
  5242880,
  array['image/jpeg']::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "plant_images_select_public" on storage.objects;
drop policy if exists "plant_images_insert_own_folder" on storage.objects;
drop policy if exists "plant_images_update_own_folder" on storage.objects;
drop policy if exists "plant_images_delete_own_folder" on storage.objects;

create policy "plant_images_select_public"
on storage.objects
for select
to public
using (bucket_id = 'plant-images');

create policy "plant_images_insert_own_folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'plant-images'
  and split_part(name, '/', 1) = auth.uid()::text
);

create policy "plant_images_update_own_folder"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'plant-images'
  and split_part(name, '/', 1) = auth.uid()::text
)
with check (
  bucket_id = 'plant-images'
  and split_part(name, '/', 1) = auth.uid()::text
);

create policy "plant_images_delete_own_folder"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'plant-images'
  and split_part(name, '/', 1) = auth.uid()::text
);

commit;
