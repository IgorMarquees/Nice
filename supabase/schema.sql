-- ============================================================
-- NICE Store - schema do Supabase
-- Cole no SQL Editor do Supabase e execute (pode rodar mais de uma vez).
-- ============================================================

-- ---------- PERFIS (nome + papel do usuário) ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'customer' check (role in ('customer', 'admin')),
  created_at timestamptz not null default now()
);

-- Cria o perfil automaticamente quando alguém se cadastra (e-mail, Google ou Apple).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Usuários que já existiam antes deste script
insert into public.profiles (id, email, name)
select id, email, coalesce(raw_user_meta_data->>'name', split_part(email, '@', 1))
from auth.users
on conflict (id) do nothing;

-- Helper usado nas políticas: o usuário logado é admin?
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

alter table public.profiles enable row level security;

drop policy if exists "profiles: ler o proprio ou admin" on public.profiles;
create policy "profiles: ler o proprio ou admin" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles: atualizar o proprio" on public.profiles;
create policy "profiles: atualizar o proprio" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Ninguém muda o próprio "role": só o nome é editável pelo app.
revoke update on public.profiles from anon, authenticated;
grant update (name) on public.profiles to authenticated;

-- ---------- PRODUTOS ----------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  price numeric(10, 2) not null check (price >= 0),
  category text not null,
  images text[] not null default '{}',
  colors text[] not null default '{}',
  sizes text[] not null default '{}',
  stock integer not null default 0 check (stock >= 0),
  is_featured boolean not null default false,
  is_new boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists products_featured_idx on public.products (is_featured) where is_featured;
create index if not exists products_new_idx on public.products (is_new) where is_new;

alter table public.products enable row level security;

drop policy if exists "products: leitura publica" on public.products;
create policy "products: leitura publica" on public.products
  for select to anon, authenticated using (true);

drop policy if exists "products: admin insere" on public.products;
create policy "products: admin insere" on public.products
  for insert to authenticated with check (public.is_admin());
drop policy if exists "products: admin atualiza" on public.products;
create policy "products: admin atualiza" on public.products
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "products: admin exclui" on public.products;
create policy "products: admin exclui" on public.products
  for delete to authenticated using (public.is_admin());

-- ---------- CARRINHO ----------
-- product_id é texto porque produtos da FakeStoreAPI (fallback) usam ids "fake-N".
create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null,
  size text not null default '',
  quantity integer not null check (quantity > 0),
  title text not null,
  unit_price numeric(10, 2) not null,
  image_url text not null default '',
  created_at timestamptz not null default now(),
  unique (user_id, product_id, size)
);

alter table public.cart_items enable row level security;
drop policy if exists "cart: dono" on public.cart_items;
create policy "cart: dono" on public.cart_items
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- PEDIDOS ----------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  items jsonb not null,
  total numeric(10, 2) not null,
  address jsonb not null,
  payment_method text not null,
  status text not null default 'created'
    check (status in ('created', 'paid', 'shipped', 'delivered', 'canceled')),
  created_at timestamptz not null default now()
);

alter table public.orders enable row level security;

drop policy if exists "orders: ler os proprios ou admin" on public.orders;
create policy "orders: ler os proprios ou admin" on public.orders
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "orders: criar o proprio" on public.orders;
create policy "orders: criar o proprio" on public.orders
  for insert to authenticated with check (user_id = auth.uid() and status = 'created');

drop policy if exists "orders: admin atualiza status" on public.orders;
create policy "orders: admin atualiza status" on public.orders
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- STORAGE (fotos dos produtos) ----------
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

drop policy if exists "product-images: leitura publica" on storage.objects;
create policy "product-images: leitura publica" on storage.objects
  for select using (bucket_id = 'product-images');

drop policy if exists "product-images: admin envia" on storage.objects;
create policy "product-images: admin envia" on storage.objects
  for insert to authenticated with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product-images: admin altera" on storage.objects;
create policy "product-images: admin altera" on storage.objects
  for update to authenticated using (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product-images: admin exclui" on storage.objects;
create policy "product-images: admin exclui" on storage.objects
  for delete to authenticated using (bucket_id = 'product-images' and public.is_admin());

-- ---------- PRIMEIRO ADMINISTRADOR ----------
-- 1) Cadastre-se normalmente no app/site com o e-mail que será admin.
-- 2) Rode (trocando o e-mail):
-- update public.profiles set role = 'admin' where email = 'SEU_EMAIL@exemplo.com';
