-- Smokehouse: общие рецепты
-- Выполни этот SQL в Supabase -> SQL Editor -> New query -> Run.

create extension if not exists pgcrypto;

create table if not exists public.public_recipes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Другое',
  ingredients text not null default '',
  preparation text not null default '',
  photo_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.public_recipes enable row level security;

drop policy if exists "public recipes read" on public.public_recipes;
create policy "public recipes read"
on public.public_recipes
for select
to anon, authenticated
using (true);

drop policy if exists "authenticated can insert public recipes" on public.public_recipes;
create policy "authenticated can insert public recipes"
on public.public_recipes
for insert
to authenticated
with check (true);

drop policy if exists "authenticated can update public recipes" on public.public_recipes;
create policy "authenticated can update public recipes"
on public.public_recipes
for update
to authenticated
using (true)
with check (true);

drop policy if exists "authenticated can delete public recipes" on public.public_recipes;
create policy "authenticated can delete public recipes"
on public.public_recipes
for delete
to authenticated
using (true);

insert into storage.buckets (id, name, public)
values ('recipe-photos', 'recipe-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "public read recipe photos" on storage.objects;
create policy "public read recipe photos"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'recipe-photos');

drop policy if exists "authenticated upload recipe photos" on storage.objects;
create policy "authenticated upload recipe photos"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'recipe-photos');

drop policy if exists "authenticated update recipe photos" on storage.objects;
create policy "authenticated update recipe photos"
on storage.objects
for update
to authenticated
using (bucket_id = 'recipe-photos')
with check (bucket_id = 'recipe-photos');

drop policy if exists "authenticated delete recipe photos" on storage.objects;
create policy "authenticated delete recipe photos"
on storage.objects
for delete
to authenticated
using (bucket_id = 'recipe-photos');

-- ВАЖНО:
-- 1) Supabase -> Authentication -> Providers -> Email: включи Email.
-- 2) Создай только свою админ-учётку.
-- 3) Отключи публичную регистрацию (Allow new users to sign up = OFF),
--    чтобы только твоя учётка могла публиковать/редактировать общие рецепты.
