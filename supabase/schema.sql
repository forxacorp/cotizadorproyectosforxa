-- ============================================================================
-- FORXA · Cotizador interno — esquema de Supabase
-- Vive en el MISMO proyecto que tu web de portafolio (jjdybtskzqpybrltdnss),
-- pero en tablas separadas con prefijo cotizador_ y su propio bucket, para
-- que nada choque con la tabla "projects" ni el bucket "covers" que ya usas.
--
-- Pega todo este archivo en: Supabase → SQL Editor → New query → Run.
-- Es seguro volver a ejecutarlo (usa "if not exists" / "on conflict").
-- ============================================================================

-- 0) Extensión necesaria para gen_random_uuid() ------------------------------
create extension if not exists pgcrypto;

-- 1) Tabla de administradores --------------------------------------------------
-- Cualquier usuario autenticado puede USAR el cotizador (ver unidades, generar
-- y guardar proformas). Solo quienes estén en esta tabla pueden crear/editar/
-- borrar proyectos, unidades y subir fotos desde el panel de administración.
create table if not exists public.cotizador_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nombre text,
  created_at timestamptz not null default now()
);
alter table public.cotizador_admins enable row level security;
drop policy if exists "Admins se ven a si mismos" on public.cotizador_admins;
create policy "Admins se ven a si mismos"
  on public.cotizador_admins for select
  to authenticated
  using (true);

-- IMPORTANTE: después de crear tu primer usuario en Authentication → Users,
-- corre esto UNA VEZ reemplazando el correo (esto te da acceso de admin):
--
--   insert into public.cotizador_admins (user_id, nombre)
--   select id, 'Pablo Calle' from auth.users where email = 'tu-correo@forxa.com'
--   on conflict (user_id) do nothing;

-- 2) Proyectos ------------------------------------------------------------------
create table if not exists public.cotizador_proyectos (
  id text primary key,                          -- slug: 'misicata', 'aura', 'alabes', 'porton'
  nombre text not null,
  tagline text,
  ubicacion text,
  color_primario text not null default '#565a41',
  color_acento text not null default '#cdbd94',
  cover_url text,
  tipo_financiamiento text not null default 'simulacion', -- 'vip_fijo' | 'simulacion' | 'lote'
  reserva_pct numeric not null default 0.02,
  promesa_pct numeric not null default 0.08,
  tasa_default numeric not null default 10.5,
  plazo_default_anios integer not null default 20,
  permite_descuento_manual boolean not null default false,
  monto_descuento_clic numeric not null default 0,
  permite_multi_seleccion boolean not null default true,
  activo boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
alter table public.cotizador_proyectos enable row level security;

drop policy if exists "Autenticados leen proyectos" on public.cotizador_proyectos;
create policy "Autenticados leen proyectos"
  on public.cotizador_proyectos for select to authenticated using (true);

drop policy if exists "Admins escriben proyectos" on public.cotizador_proyectos;
create policy "Admins escriben proyectos"
  on public.cotizador_proyectos for all to authenticated
  using (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

-- 3) Unidades ---------------------------------------------------------------
create table if not exists public.cotizador_unidades (
  id uuid primary key default gen_random_uuid(),
  proyecto_id text not null references public.cotizador_proyectos(id) on delete cascade,
  codigo text not null,                 -- 'casa1', '201', 'A0'...
  nombre text,
  tipo text,
  planta text,
  terreno_m2 numeric,
  construccion_m2 numeric,
  area_util_m2 numeric,
  area_total_m2 numeric,
  dormitorios numeric,
  banos numeric,
  parqueos integer,
  bodega_codigo text,
  bodega_area_m2 numeric,
  precio numeric,
  precio_preventa numeric,
  aplica_vip boolean not null default false,
  fase text,
  estado text not null default 'disponible'
    check (estado in ('disponible','reservado','vendida','no_disponible')),
  foto_url text,
  plano_baja_url text,
  plano_alta_url text,
  nota text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (proyecto_id, codigo)
);
alter table public.cotizador_unidades enable row level security;

drop policy if exists "Autenticados leen unidades" on public.cotizador_unidades;
create policy "Autenticados leen unidades"
  on public.cotizador_unidades for select to authenticated using (true);

drop policy if exists "Admins escriben unidades" on public.cotizador_unidades;
create policy "Admins escriben unidades"
  on public.cotizador_unidades for all to authenticated
  using (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

-- 4) Inventario extra (parqueaderos sueltos, bodegas, lotes) -----------------
create table if not exists public.cotizador_inventario_extra (
  id uuid primary key default gen_random_uuid(),
  proyecto_id text not null references public.cotizador_proyectos(id) on delete cascade,
  codigo text not null,
  tipo text not null,                    -- 'parqueadero' | 'moto' | 'bodega' | 'lote'
  categoria text,
  precio numeric,
  precio_preventa numeric,
  metraje_m2 numeric,
  precio_m2 numeric,
  estado text not null default 'disponible'
    check (estado in ('disponible','reservado','vendida','no_disponible')),
  nota text,
  created_at timestamptz not null default now(),
  unique (proyecto_id, tipo, codigo)
);
alter table public.cotizador_inventario_extra enable row level security;

drop policy if exists "Autenticados leen inventario extra" on public.cotizador_inventario_extra;
create policy "Autenticados leen inventario extra"
  on public.cotizador_inventario_extra for select to authenticated using (true);

drop policy if exists "Admins escriben inventario extra" on public.cotizador_inventario_extra;
create policy "Admins escriben inventario extra"
  on public.cotizador_inventario_extra for all to authenticated
  using (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

-- 5) Historial de proformas (reemplaza el localStorage del HTML original) ---
create table if not exists public.cotizador_historial (
  id uuid primary key default gen_random_uuid(),
  creado_por uuid references auth.users(id),
  proyecto_id text references public.cotizador_proyectos(id),
  cliente_nombre text,
  cliente_telefono text,
  cliente_correo text,
  unidades jsonb not null default '[]'::jsonb,
  descuento numeric not null default 0,
  precio_final numeric,
  reserva numeric,
  saldo_financiar numeric,
  cuota_mensual numeric,
  notas text,
  created_at timestamptz not null default now()
);
alter table public.cotizador_historial enable row level security;

drop policy if exists "Autenticados leen historial" on public.cotizador_historial;
create policy "Autenticados leen historial"
  on public.cotizador_historial for select to authenticated using (true);

drop policy if exists "Autenticados guardan su historial" on public.cotizador_historial;
create policy "Autenticados guardan su historial"
  on public.cotizador_historial for insert to authenticated
  with check (creado_por = auth.uid());

drop policy if exists "Admins borran historial" on public.cotizador_historial;
create policy "Admins borran historial"
  on public.cotizador_historial for delete to authenticated
  using (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

-- 6) Storage: bucket privado para fotos/planos/portadas ----------------------
-- Privado (no público) porque TODO el cotizador requiere login, incluidas
-- las imágenes: se sirven con signed URLs generadas por el cliente autenticado.
insert into storage.buckets (id, name, public)
values ('cotizador-media', 'cotizador-media', false)
on conflict (id) do nothing;

drop policy if exists "Autenticados leen cotizador-media" on storage.objects;
create policy "Autenticados leen cotizador-media"
  on storage.objects for select to authenticated
  using (bucket_id = 'cotizador-media');

drop policy if exists "Admins suben cotizador-media" on storage.objects;
create policy "Admins suben cotizador-media"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'cotizador-media'
    and exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

drop policy if exists "Admins actualizan cotizador-media" on storage.objects;
create policy "Admins actualizan cotizador-media"
  on storage.objects for update to authenticated
  using (bucket_id = 'cotizador-media'
    and exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

drop policy if exists "Admins borran cotizador-media" on storage.objects;
create policy "Admins borran cotizador-media"
  on storage.objects for delete to authenticated
  using (bucket_id = 'cotizador-media'
    and exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

-- 7) Trigger para updated_at en unidades --------------------------------------
create or replace function public.cotizador_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists cotizador_unidades_updated_at on public.cotizador_unidades;
create trigger cotizador_unidades_updated_at
  before update on public.cotizador_unidades
  for each row execute function public.cotizador_set_updated_at();

-- ============================================================================
-- A partir de aquí: proyectos + datos iniciales (generado automáticamente,
-- ver seed_data.sql que se pega justo debajo o se ejecuta por separado).
-- ============================================================================
