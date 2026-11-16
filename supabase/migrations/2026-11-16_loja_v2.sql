-- ============================================================
-- NICE Store - atualização v2 (rode UMA vez no SQL Editor do Supabase)
-- Seguro para rodar de novo: usa "if not exists" / "or replace".
--
-- O que muda:
--  1. products: detalhes técnicos, desconto, cores com fotos próprias e
--     estoque visível só para administradores (coluna in_stock pública).
--  2. addresses: endereços salvos dos clientes.
--  3. orders: subtotal, desconto do Pix e frete.
--  4. set_user_role(): admin promove/rebaixa usuários.
-- ============================================================

-- ---------- 1. PRODUTOS ----------
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

-- ---------- 2. ENDEREÇOS SALVOS ----------
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

-- ---------- 3. PEDIDOS ----------
alter table public.orders add column if not exists subtotal numeric(10, 2);
alter table public.orders add column if not exists discount numeric(10, 2) not null default 0;
alter table public.orders add column if not exists shipping numeric(10, 2) not null default 0;

-- ---------- 4. PAPEL DOS USUÁRIOS ----------
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
