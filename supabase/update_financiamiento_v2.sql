-- ============================================================================
-- FORXA · Cotizador interno — actualización: número de proforma, historial
-- restringido, descuento libre y nuevo esquema de financiamiento (30% / 70%).
-- Pega todo este archivo en Supabase → SQL Editor → New query → Run.
-- Es seguro volver a ejecutarlo (usa "if not exists" / "on conflict").
-- ============================================================================

-- 1) Columnas nuevas en cotizador_proyectos ----------------------------------
alter table public.cotizador_proyectos
  add column if not exists prefijo_proforma text;

-- 2) Columnas nuevas en cotizador_historial ----------------------------------
alter table public.cotizador_historial
  add column if not exists numero_proforma text,
  add column if not exists asesor_nombre text,
  add column if not exists asesor_telefono text,
  add column if not exists promesa numeric,
  add column if not exists abono_total numeric,
  add column if not exists monto_financiado numeric,
  add column if not exists tasa_usada numeric,
  add column if not exists plazo_anios_usado integer,
  add column if not exists numero_cuotas integer,
  add column if not exists monto_cuota numeric;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'cotizador_historial_numero_proforma_key'
  ) then
    alter table public.cotizador_historial
      add constraint cotizador_historial_numero_proforma_key unique (numero_proforma);
  end if;
end $$;

-- 3) Contador atómico de número de proforma (uno por proyecto) --------------
create table if not exists public.cotizador_contador_proforma (
  proyecto_id text primary key references public.cotizador_proyectos(id) on delete cascade,
  ultimo integer not null default 0
);
alter table public.cotizador_contador_proforma enable row level security;

drop policy if exists "Autenticados usan el contador" on public.cotizador_contador_proforma;
create policy "Autenticados usan el contador"
  on public.cotizador_contador_proforma for all to authenticated
  using (true) with check (true);

-- Genera el siguiente número de proforma para un proyecto, ej. "AURA-0007".
-- Incrementa de forma atómica (a prueba de dos asesores generando a la vez).
create or replace function public.siguiente_numero_proforma(p_proyecto_id text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prefijo text;
  v_siguiente integer;
begin
  select coalesce(prefijo_proforma, upper(left(id, 3))) into v_prefijo
  from public.cotizador_proyectos where id = p_proyecto_id;

  if v_prefijo is null then
    v_prefijo := upper(left(p_proyecto_id, 3));
  end if;

  insert into public.cotizador_contador_proforma (proyecto_id, ultimo)
  values (p_proyecto_id, 1)
  on conflict (proyecto_id) do update set ultimo = cotizador_contador_proforma.ultimo + 1
  returning ultimo into v_siguiente;

  return v_prefijo || '-' || lpad(v_siguiente::text, 4, '0');
end;
$$;

grant execute on function public.siguiente_numero_proforma(text) to authenticated;

-- 4) Historial restringido a una sola cuenta ---------------------------------
alter table public.cotizador_admins
  add column if not exists puede_ver_historial boolean not null default false;

-- Antes cualquier asesor autenticado podía LEER todo el historial (aunque no
-- hubiera pantalla para verlo). Ahora solo puede leerlo quien tenga
-- puede_ver_historial = true — el resto sigue pudiendo generar proformas
-- normalmente (eso lo permite la política de "insert" de abajo, que no cambia).
drop policy if exists "Autenticados leen historial" on public.cotizador_historial;
drop policy if exists "Solo quien tiene permiso lee historial" on public.cotizador_historial;
create policy "Solo quien tiene permiso lee historial"
  on public.cotizador_historial for select to authenticated
  using (exists (
    select 1 from public.cotizador_admins a
    where a.user_id = auth.uid() and a.puede_ver_historial = true
  ));

-- Le da acceso al Historial a la cuenta indicada (además de admin general,
-- ya que se guarda en la misma tabla cotizador_admins). Si prefieres que
-- esta cuenta NO administre proyectos/unidades, avísame y lo separamos en
-- una tabla aparte.
insert into public.cotizador_admins (user_id, nombre, puede_ver_historial)
select id, 'CEO FORXA', true from auth.users where email = 'ceo@forxainmobiliaria.com'
on conflict (user_id) do update set puede_ver_historial = true;

-- 5) Prefijos de proforma por proyecto ---------------------------------------
update public.cotizador_proyectos set prefijo_proforma = 'MIS'  where id = 'misicata';
update public.cotizador_proyectos set prefijo_proforma = 'AURA' where id = 'aura';
update public.cotizador_proyectos set prefijo_proforma = 'ALB'  where id = 'alabes';
update public.cotizador_proyectos set prefijo_proforma = 'PDV'  where id = 'porton';

-- 6) Nuevo esquema de financiamiento -----------------------------------------
-- Misicata / AURA / Álabes: reserva 2% + promesa 8% + cuotas hasta la entrega
-- (20%, las pone el asesor) = 30% de abono; 70% a financiar con interés y
-- plazo editables por el asesor.
update public.cotizador_proyectos
set tipo_financiamiento = 'cuotas_entrega', reserva_pct = 0.02, promesa_pct = 0.08
where id in ('misicata', 'aura', 'alabes');

-- Portón del Valle: ya está listo para entrega, así que en vez del desglose
-- por pasos es un solo abono editable (sugerido 30%) + 70% a financiar.
-- reserva_pct se reutiliza aquí como "% de abono sugerido" (promesa_pct no
-- se usa en este esquema).
update public.cotizador_proyectos
set tipo_financiamiento = 'pago_directo', reserva_pct = 0.30, promesa_pct = 0
where id = 'porton';

-- Tasa/plazo por defecto sugeridos para los 4 (el asesor los puede cambiar
-- en cada proforma) — ajústalos aquí si tu tasa real es otra.
update public.cotizador_proyectos
set tasa_default = 10.5, plazo_default_anios = 20
where id in ('misicata', 'aura', 'alabes', 'porton');
