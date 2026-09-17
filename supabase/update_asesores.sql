-- ============================================================================
-- FORXA · Cotizador interno — directorio de asesores (para autocompletar
-- "Datos del asesor" en el formulario cuando Empresa = "FORXA Inmobiliaria")
--
-- Qué hace: crea la tabla cotizador_asesores y la deja precargada con los
-- 12 asesores de Contactos_Asesores.xlsx. El cotizador la lee para mostrar
-- un desplegable con los nombres; al elegir uno, el teléfono se rellena
-- solo (ya no hay que escribirlo a mano). El panel de administración
-- (Administrar → Asesores) permite agregar/editar/quitar asesores después,
-- sin tocar código ni volver a correr este archivo.
--
-- Es seguro volver a ejecutarlo (usa "if not exists" / "on conflict") — si
-- ya corriste esto antes y solo cambiaron datos de contacto en el Excel, se
-- actualizan por nombre; no duplica filas.
--
-- Pega todo este archivo en: Supabase → SQL Editor → New query → Run.
-- ============================================================================

create table if not exists public.cotizador_asesores (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  correo text,
  telefono_codigo text not null default '593',  -- código de país, sin '+' (ver PAISES_TEL en utils.js)
  telefono_numero text not null default '',     -- número local, sin el 0 inicial
  activo boolean not null default true,          -- si no está activo, no aparece en el desplegable del cotizador
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (nombre)
);
alter table public.cotizador_asesores enable row level security;

drop policy if exists "Autenticados leen asesores" on public.cotizador_asesores;
create policy "Autenticados leen asesores"
  on public.cotizador_asesores for select to authenticated using (true);

drop policy if exists "Admins escriben asesores" on public.cotizador_asesores;
create policy "Admins escriben asesores"
  on public.cotizador_asesores for all to authenticated
  using (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.cotizador_admins a where a.user_id = auth.uid()));

-- Datos de Contactos_Asesores.xlsx (12 asesores) --------------------------
insert into public.cotizador_asesores (nombre, correo, telefono_codigo, telefono_numero, activo, sort_order) values
  ('Adrian Rodríguez', 'adrianrodriguezserrano@gmail.com', '593', '958933482', true, 1),
  ('Andrea Cárdenas', 'acardenas@forxainmobiliaria.com', '593', '999280345', true, 2),
  ('Andy Guamán', 'aguaman@forxainmobiliaria.com', '593', '993422773', true, 3),
  ('Daniel Molina', 'dmolina@forxainmobiliaria.com', '593', '987504918', true, 4),
  ('Daniela Vizñay', 'marketing@forxainmobiliaria.com', '593', '939087030', true, 5),
  ('David Palacios', 'dpalacios@forxainmobiliaria.com', '593', '995060561', true, 6),
  ('Deisy Soporte', 'soporte10@zolutium.com', '593', '963204781', true, 7),
  ('Karla Urgiléz', 'info@forxainmobiliaria.com', '593', '939087030', true, 8),
  ('Paola Rodríguez', 'prodriguez@forxainmobiliaria.com', '593', '987907662', true, 9),
  ('Paola Sacquirín', 'psacquirin@forxainmobiliaria.com', '593', '995343442', true, 10),
  ('Verónica Granja', 'vgranja@forxainmobiliaria.com', '593', '987172806', true, 11),
  ('Viviana Ponce', 'vponce@forxainmobiliaria.com', '593', '983362027', true, 12)
on conflict (nombre) do update set
  correo = excluded.correo,
  telefono_codigo = excluded.telefono_codigo,
  telefono_numero = excluded.telefono_numero;

-- Nota: "Deisy Soporte" y "Karla Urgiléz" quedaron con correos genéricos
-- (soporte10@zolutium.com / info@forxainmobiliaria.com) porque así venían
-- en el Excel — corrígelos desde Administrar → Asesores si no son los
-- correos correctos para mostrar en el directorio.
