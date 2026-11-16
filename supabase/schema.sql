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

-- Cria o perfil automaticamente quando alguém se cadastra (e-mail ou Google).
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
-- Colunas da v2 (em bancos antigos são adicionadas aqui).
-- color_variants: [{"name": "Preto", "images": ["url", ...]}]; images = todas as fotos; colors = nomes.
alter table public.products add column if not exists technical_details text not null default '';
alter table public.products add column if not exists discount_percent integer not null default 0;
alter table public.products add column if not exists color_variants jsonb not null default '[]'::jsonb;
alter table public.products add column if not exists in_stock boolean generated always as (stock > 0) stored;

alter table public.products drop constraint if exists products_discount_percent_check;
alter table public.products add constraint products_discount_percent_check
  check (discount_percent between 0 and 90);

-- Cores antigas (só nomes) viram cores sem fotos próprias.
update public.products
set color_variants = (
  select coalesce(jsonb_agg(jsonb_build_object('name', c, 'images', '[]'::jsonb)), '[]'::jsonb)
  from unnest(colors) as c
)
where color_variants = '[]'::jsonb and cardinality(colors) > 0;

-- Estoque só para admin: clientes/visitantes leem todas as colunas, menos "stock".
-- (o app lê as colunas explicitamente; "select *" deixa de funcionar para anon/authenticated)
revoke select on public.products from anon, authenticated;
grant select (
  id, title, description, technical_details, price, discount_percent, category,
  images, colors, color_variants, sizes, in_stock, is_featured, is_new, created_at, updated_at
) on public.products to anon, authenticated;

-- O admin lê o estoque por esta função (verifica is_admin()).
create or replace function public.admin_product_stock()
returns table (id uuid, stock integer)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'not admin' using errcode = '42501';
  end if;
  return query select p.id, p.stock from public.products p;
end;
$$;
revoke all on function public.admin_product_stock() from public, anon;
grant execute on function public.admin_product_stock() to authenticated;

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

alter table public.orders add column if not exists subtotal numeric(10, 2);
alter table public.orders add column if not exists discount numeric(10, 2) not null default 0;
alter table public.orders add column if not exists shipping numeric(10, 2) not null default 0;

drop policy if exists "orders: admin atualiza status" on public.orders;
create policy "orders: admin atualiza status" on public.orders
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- ENDEREÇOS SALVOS ----------
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default '',
  recipient text not null,
  zip text not null,
  street text not null,
  number text not null,
  complement text not null default '',
  neighborhood text not null,
  city text not null,
  state text not null check (state in (
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA',
    'PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
  )),
  created_at timestamptz not null default now()
);
create index if not exists addresses_user_idx on public.addresses (user_id);

alter table public.addresses enable row level security;

drop policy if exists "addresses: dono" on public.addresses;
create policy "addresses: dono" on public.addresses
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "addresses: admin le" on public.addresses;
create policy "addresses: admin le" on public.addresses
  for select to authenticated using (public.is_admin());

-- ---------- PAPEL DOS USUÁRIOS (admin) ----------
-- Só admin muda o papel de alguém, e não pode rebaixar a si mesmo.
create or replace function public.set_user_role(target uuid, new_role text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'not admin' using errcode = '42501';
  end if;
  if new_role not in ('customer', 'admin') then
    raise exception 'invalid role';
  end if;
  if target = auth.uid() and new_role <> 'admin' then
    raise exception 'cannot demote self';
  end if;
  update public.profiles set role = new_role where id = target;
end;
$$;
revoke all on function public.set_user_role(uuid, text) from public, anon;
grant execute on function public.set_user_role(uuid, text) to authenticated;

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
