-- Emy Bake Studio: pega TODO esto en Supabase > SQL Editor > New query > Run
create table if not exists miembros (user_id uuid primary key references auth.users(id) on delete cascade, rol text not null default 'editor');
create table if not exists pedidos (
  id uuid primary key default gen_random_uuid(),
  cliente text not null check (char_length(cliente) between 1 and 80),
  telefono text, items jsonb not null default '[]', ubicacion text,
  abono numeric(10,2) not null default 0,
  pago text not null default 'Pendiente' check (pago in ('Pagado','Pendiente')),
  entregado boolean not null default false,
  fecha_entrega date not null default current_date, hora text, notas text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  eliminado_at timestamptz,
  creado_por uuid default auth.uid()
);
create index if not exists pedidos_updated_idx on pedidos(updated_at);
alter table miembros enable row level security;
alter table pedidos enable row level security;
create or replace function es_miembro() returns boolean language sql security definer stable set search_path = public
as $$ select exists (select 1 from public.miembros where user_id = auth.uid()) $$;
drop policy if exists "ver mi membresia" on miembros;
create policy "ver mi membresia" on miembros for select to authenticated using (user_id = auth.uid());
drop policy if exists "pedidos leer" on pedidos;
create policy "pedidos leer" on pedidos for select to authenticated using (es_miembro());
drop policy if exists "pedidos crear" on pedidos;
create policy "pedidos crear" on pedidos for insert to authenticated with check (es_miembro());
drop policy if exists "pedidos editar" on pedidos;
create policy "pedidos editar" on pedidos for update to authenticated using (es_miembro()) with check (es_miembro());
-- Ejecuta esto DESPUES de crear los usuarios (Authentication > Users > Add user):
insert into miembros (user_id) select id from auth.users on conflict do nothing;
