-- NIVEKVERSE Supabase setup
-- Run this in Supabase Dashboard > SQL Editor.
-- IMPORTANT: Create your admin account in Authentication > Users.
-- Keep the Supabase service_role key private. Only use the anon/public key in index.html.

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Other',
  price text not null,
  purchase_url text,
  description text not null default '',
  image_url text,
  download_url text,
  featured boolean not null default false,
  published boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;

drop policy if exists "Anyone can view published products" on public.products;
create policy "Anyone can view published products"
on public.products for select
to anon, authenticated
using (published = true);

-- Authenticated users can manage products. For a real public launch, restrict
-- this to your own admin user by replacing the condition with:
-- using (auth.uid() = 'YOUR-ADMIN-USER-UUID') with check (...).
-- The template below is intentionally not an open anonymous write policy.
drop policy if exists "Authenticated admins manage products" on public.products;
create policy "Authenticated admins manage products"
on public.products for all
to authenticated
using (auth.uid() = 'YOUR-ADMIN-USER-UUID')
with check (auth.uid() = 'YOUR-ADMIN-USER-UUID');

insert into storage.buckets (id, name, public, file_size_limit)
values ('product-previews', 'product-previews', true, 5242880)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit)
values ('product-files', 'product-files', false, 52428800)
on conflict (id) do nothing;

-- Public can view preview images.
drop policy if exists "Public reads product previews" on storage.objects;
create policy "Public reads product previews"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'product-previews');

-- Only your admin user can upload/update/delete preview images and product files.
drop policy if exists "Admin manages product previews" on storage.objects;
create policy "Admin manages product previews"
on storage.objects for all
to authenticated
using (bucket_id = 'product-previews' and auth.uid() = 'YOUR-ADMIN-USER-UUID')
with check (bucket_id = 'product-previews' and auth.uid() = 'YOUR-ADMIN-USER-UUID');

drop policy if exists "Admin manages product files" on storage.objects;
create policy "Admin manages product files"
on storage.objects for all
to authenticated
using (bucket_id = 'product-files' and auth.uid() = 'YOUR-ADMIN-USER-UUID')
with check (bucket_id = 'product-files' and auth.uid() = 'YOUR-ADMIN-USER-UUID');

-- NOTE: This starter stores private file URLs in the products table but does not
-- yet create signed download links. For paid files, deliver downloads manually
-- or add a secure signed-link/fulfilment workflow before selling.
