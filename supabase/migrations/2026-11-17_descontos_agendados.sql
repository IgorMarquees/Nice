-- ============================================================
-- NICE Store - descontos com período (rode UMA vez no SQL Editor do Supabase)
-- Seguro para rodar de novo. Requer a migração 2026-11-16_loja_v2.sql.
--
-- discount_starts_at / discount_ends_at: período do desconto (null = sem limite).
-- Descontos já existentes continuam valendo (ficam sem início e sem fim).
-- ============================================================

alter table public.products add column if not exists discount_starts_at timestamptz;
alter table public.products add column if not exists discount_ends_at timestamptz;

alter table public.products drop constraint if exists products_discount_period_check;
alter table public.products add constraint products_discount_period_check
  check (discount_starts_at is null or discount_ends_at is null or discount_ends_at > discount_starts_at);

-- As colunas novas também são públicas (a loja precisa saber se o desconto está valendo).
grant select (discount_starts_at, discount_ends_at) on public.products to anon, authenticated;
