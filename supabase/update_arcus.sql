-- ============================================================================
-- FORXA · Cotizador interno — proyecto ARCUS (Suites & Lofts)
--
-- Qué hace: agrega ARCUS como 5º proyecto del cotizador, con sus 77 unidades
-- disponibles (locales, islas, lofts y suites) según
-- lista_de_precios_ARCUS__2___1_.xlsx. El único departamento del edificio
-- (603, ya vendido) se omitió a propósito — no se carga.
--
-- Política de compra: copiada tal cual de AURA, como pediste — reserva 2% +
-- promesa 8% + cuotas hasta la entrega (suma 30%), 70% restante financiado a
-- 10.5% / 20 años (editable por el asesor en cada cotización). No se activó
-- descuento manual (permite_descuento_manual = false), igual que AURA.
--
-- Nota aparte: el Excel trae una segunda hoja "política comercial" con
-- descuentos automáticos por categoría (Signature 3%, Classic 4%,
-- Essential 5%) — no la conecté al sistema porque el cotizador solo soporta
-- un descuento manual libre, no reglas automáticas por categoría. Si quieres
-- que el sistema sugiera ese % según la categoría de cada unidad, es un
-- cambio aparte — avísame.
--
-- Es seguro volver a correrlo ("on conflict do update" en unidades; el
-- proyecto usa "on conflict do nothing" para no pisar cambios que hagas
-- luego desde Administrar).
--
-- Pega esto en: Supabase → SQL Editor → New query → Run.
-- ============================================================================

-- 1) Proyecto ------------------------------------------------------------
insert into public.cotizador_proyectos
  (id, nombre, tagline, ubicacion, color_primario, color_acento, tipo_financiamiento,
   prefijo_proforma, reserva_pct, promesa_pct, tasa_default, plazo_default_anios,
   permite_descuento_manual, monto_descuento_clic, permite_multi_seleccion, sort_order)
values
  ('arcus', 'Arcus Suites & Lofts', 'Suites, lofts y locales comerciales · Remigio Tamariz Crespo',
   'Cuenca, Ecuador', '#3a2c23', '#9c8068', 'cuotas_entrega', 'ARCUS',
   0.02, 0.08, 10.5, 20, false, 0, false, 5)
on conflict (id) do nothing;

-- 2) Unidades (77 — se omitió el departamento 603, ya vendido) -----------
insert into public.cotizador_unidades
  (proyecto_id, codigo, nombre, tipo, planta, area_util_m2, area_total_m2, parqueos, precio, estado)
values
  ('arcus', '001', 'Local 1', 'Local Comercial', 'Planta Baja · Signature', 56.2, 56.2, 1, 144260, 'disponible'),
  ('arcus', '002', 'Local 2', 'Local Comercial', 'Planta Baja · Signature', 55.01, 55.01, 1, 141523, 'disponible'),
  ('arcus', '003', 'Local 3', 'Local Comercial', 'Planta Baja · Signature', 63.26, 63.26, 1, 147846, 'disponible'),
  ('arcus', '004', 'Local 4', 'Local Comercial', 'Planta Baja · Signature', 57.98, 57.98, 1, 136758, 'disponible'),
  ('arcus', '005', 'Local 5', 'Local Comercial', 'Planta Baja · Signature', 61.58, 61.58, 1, 144318, 'disponible'),
  ('arcus', '006', 'Local 6', 'Local Comercial', 'Planta Baja · Signature', 63.03, 63.03, 1, 147363, 'disponible'),
  ('arcus', '007', 'Local 7', 'Local Comercial', 'Planta Baja · Signature', 74.72, 74.72, 1, 171912, 'disponible'),
  ('arcus', 'I1', 'Isla 1', 'Isla Comercial', 'Planta Baja · Classic', 5.2, 5.2, null, 15600, 'disponible'),
  ('arcus', 'I2', 'Isla 2', 'Isla Comercial', 'Planta Baja · Classic', 5.2, 5.2, null, 15600, 'disponible'),
  ('arcus', 'I3', 'Isla 3', 'Isla Comercial', 'Planta Baja · Classic', 5.2, 5.2, null, 15600, 'disponible'),
  ('arcus', 'I4', 'Isla 4', 'Isla Comercial', 'Planta Baja · Classic', 5.2, 5.2, null, 15600, 'disponible'),
  ('arcus', 'I5', 'Isla 5', 'Isla Comercial', 'Planta Baja · Classic', 5.2, 5.2, null, 15600, 'disponible'),
  ('arcus', 'I6', 'Isla 6', 'Isla Comercial', 'Planta Baja · Classic', 5.2, 5.2, null, 15600, 'disponible'),
  ('arcus', '101', 'Loft 101', 'Loft', 'Piso 1 · Essential', 31.98, 98.42, null, 75919.2, 'disponible'),
  ('arcus', '102', 'Suite 102', 'Suite', 'Piso 1 · Signature', 46.71, 60.95, null, 104513.1, 'disponible'),
  ('arcus', '103', 'Suite 103', 'Suite', 'Piso 1 · Signature', 51.69, 97.86, null, 119247.9, 'disponible'),
  ('arcus', '104', 'Loft 104', 'Loft', 'Piso 1 · Classic', 29.8, 59.42, null, 64931.6, 'disponible'),
  ('arcus', '105', 'Loft 105', 'Loft', 'Piso 1 · Classic', 31.67, 60.89, null, 68599.6, 'disponible'),
  ('arcus', '106', 'Loft 106', 'Loft', 'Piso 1 · Classic', 34.54, 64.13, null, 74406.2, 'disponible'),
  ('arcus', '107', 'Loft 107', 'Loft', 'Piso 1 · Classic', 37.21, 66.84, null, 79753.4, 'disponible'),
  ('arcus', '108', 'Loft 108', 'Loft', 'Piso 1 · Classic', 38.9, 67.74, null, 82991.2, 'disponible'),
  ('arcus', '109', 'Suite 109', 'Suite', 'Piso 1 · Signature', 49.3, 120.52, null, 113884.6, 'disponible'),
  ('arcus', '110', 'Suite 110', 'Suite', 'Piso 1 · Signature', 48.23, 123.47, null, 112414.7, 'disponible'),
  ('arcus', '111', 'Loft 111', 'Loft', 'Piso 1 · Essential', 23.8, 78.23, null, 57397.4, 'disponible'),
  ('arcus', '201', 'Loft 201', 'Loft', 'Piso 2 · Essential', 31.98, 36.43, 1, 83364, 'disponible'),
  ('arcus', '202', 'Suite 202', 'Suite', 'Piso 2 · Signature', 46.69, 60.57, 1, 120522.05, 'disponible'),
  ('arcus', '203', 'Suite 203', 'Suite', 'Piso 2 · Signature', 51.69, 65.19, 1, 130660.5, 'disponible'),
  ('arcus', '204', 'Loft 204', 'Loft', 'Piso 2 · Classic', 29.8, 35.31, 1, 79808.1, 'disponible'),
  ('arcus', '205', 'Loft 205', 'Loft', 'Piso 2 · Classic', 31.67, 36.21, 1, 82809.15, 'disponible'),
  ('arcus', '206', 'Loft 206', 'Loft', 'Piso 2 · Classic', 34.54, 39.9, 1, 89285.1, 'disponible'),
  ('arcus', '207', 'Loft 207', 'Loft', 'Piso 2 · Classic', 37.21, 41.78, 1, 94051.95, 'disponible'),
  ('arcus', '208', 'Loft 208', 'Loft', 'Piso 2 · Classic', 38.9, 43.54, 1, 97530.9, 'disponible'),
  ('arcus', '209', 'Suite 209', 'Suite', 'Piso 2 · Signature', 49.3, 57.3, 1, 123937.5, 'disponible'),
  ('arcus', '210', 'Suite 210', 'Suite', 'Piso 2 · Signature', 48.23, 58.76, 1, 121632.18, 'disponible'),
  ('arcus', '211', 'Loft 211', 'Loft', 'Piso 2 · Essential', 23.8, 28.08, null, 51661.8, 'disponible'),
  ('arcus', '301', 'Loft 301', 'Loft', 'Piso 3 · Essential', 31.98, 36.44, 1, 84216.2, 'disponible'),
  ('arcus', '302', 'Suite 302', 'Suite', 'Piso 3 · Signature', 46.69, 61.87, 1, 122612.4, 'disponible'),
  ('arcus', '303', 'Suite 303', 'Suite', 'Piso 3 · Signature', 51.69, 65.22, 1, 132072.9, 'disponible'),
  ('arcus', '304', 'Loft 304', 'Loft', 'Piso 3 · Classic', 29.8, 34.88, 1, 80255.6, 'disponible'),
  ('arcus', '305', 'Loft 305', 'Loft', 'Piso 3 · Classic', 31.67, 36.88, 1, 84195.7, 'disponible'),
  ('arcus', '306', 'Loft 306', 'Loft', 'Piso 3 · Classic', 34.54, 40.26, 1, 90497.4, 'disponible'),
  ('arcus', '307', 'Loft 307', 'Loft', 'Piso 3 · Classic', 37.21, 42.56, 1, 95667.5, 'disponible'),
  ('arcus', '308', 'Loft 308', 'Loft', 'Piso 3 · Classic', 38.9, 43.82, 1, 98779.4, 'disponible'),
  ('arcus', '309', 'Suite 309', 'Suite', 'Piso 3 · Signature', 49.3, 59.25, 1, 124798.5, 'disponible'),
  ('arcus', '310', 'Suite 310', 'Suite', 'Piso 3 · Signature', 48.23, 58.53, 1, 122772, 'disponible'),
  ('arcus', '311', 'Loft 311', 'Loft', 'Piso 3 · Essential', 23.8, 28.02, 1, 67250.4, 'disponible'),
  ('arcus', '401', 'Loft 401', 'Loft', 'Piso 4 · Essential', 31.98, 36.43, 1, 85052, 'disponible'),
  ('arcus', '402', 'Suite 402', 'Suite', 'Piso 4 · Signature', 46.69, 60.57, 1, 123064.75, 'disponible'),
  ('arcus', '403', 'Suite 403', 'Suite', 'Piso 4 · Signature', 51.69, 65.19, 1, 133447.5, 'disponible'),
  ('arcus', '404', 'Loft 404', 'Loft', 'Piso 4 · Classic', 29.8, 35.31, 1, 81408.3, 'disponible'),
  ('arcus', '405', 'Loft 405', 'Loft', 'Piso 4 · Classic', 31.67, 36.21, 1, 84483.45, 'disponible'),
  ('arcus', '406', 'Loft 406', 'Loft', 'Piso 4 · Classic', 34.54, 39.9, 1, 91119.3, 'disponible'),
  ('arcus', '407', 'Loft 407', 'Loft', 'Piso 4 · Classic', 37.21, 41.78, 1, 96003.85, 'disponible'),
  ('arcus', '408', 'Loft 408', 'Loft', 'Piso 4 · Classic', 38.9, 43.54, 1, 99568.7, 'disponible'),
  ('arcus', '409', 'Suite 409', 'Suite', 'Piso 4 · Signature', 49.3, 57.3, 1, 126562.5, 'disponible'),
  ('arcus', '410', 'Suite 410', 'Suite', 'Piso 4 · Signature', 48.23, 58.76, 1, 124201.62, 'disponible'),
  ('arcus', '411', 'Loft 411', 'Loft', 'Piso 4 · Essential', 23.8, 28.08, 1, 67937.4, 'disponible'),
  ('arcus', '501', 'Loft 501', 'Loft', 'Piso 5 · Essential', 31.98, 36.44, 1, 85904.4, 'disponible'),
  ('arcus', '502', 'Suite 502', 'Suite', 'Piso 5 · Signature', 46.69, 61.87, 1, 125174.6, 'disponible'),
  ('arcus', '503', 'Suite 503', 'Suite', 'Piso 5 · Signature', 51.69, 65.22, 1, 134860.35, 'disponible'),
  ('arcus', '504', 'Loft 504', 'Loft', 'Piso 5 · Classic', 29.8, 34.88, 1, 81847.2, 'disponible'),
  ('arcus', '505', 'Loft 505', 'Loft', 'Piso 5 · Classic', 31.67, 36.88, 1, 85883.4, 'disponible'),
  ('arcus', '506', 'Loft 506', 'Loft', 'Piso 5 · Classic', 34.54, 40.26, 1, 92338.8, 'disponible'),
  ('arcus', '507', 'Loft 507', 'Loft', 'Piso 5 · Classic', 37.21, 42.56, 1, 97635, 'disponible'),
  ('arcus', '508', 'Loft 508', 'Loft', 'Piso 5 · Classic', 38.9, 43.82, 1, 100822.8, 'disponible'),
  ('arcus', '509', 'Suite 509', 'Suite', 'Piso 5 · Signature', 49.3, 59.25, 1, 127412.75, 'disponible'),
  ('arcus', '510', 'Suite 510', 'Suite', 'Piso 5 · Signature', 48.23, 58.53, 1, 125338, 'disponible'),
  ('arcus', '511', 'Loft 511', 'Loft', 'Piso 5 · Essential', 23.8, 28.02, 1, 68524.8, 'disponible'),
  ('arcus', '601', 'Loft 601', 'Loft', 'Piso 6 · Classic', 31.98, 36.43, 1, 86740, 'disponible'),
  ('arcus', '602', 'Suite 602', 'Suite', 'Piso 6 · Signature', 46.69, 60.57, 1, 125607.45, 'disponible'),
  ('arcus', '604', 'Loft 604', 'Loft', 'Piso 6 · Classic', 30.83, 35.28, 1, 84296.25, 'disponible'),
  ('arcus', '605', 'Loft 605', 'Loft', 'Piso 6 · Classic', 34.54, 39.9, 1, 92953.5, 'disponible'),
  ('arcus', '606', 'Loft 606', 'Loft', 'Piso 6 · Classic', 37.21, 41.78, 1, 97955.75, 'disponible'),
  ('arcus', '607', 'Loft 607', 'Loft', 'Piso 6 · Classic', 38.9, 43.54, 1, 101606.5, 'disponible'),
  ('arcus', '608', 'Suite 608', 'Suite', 'Piso 6 · Signature', 49.23, 57.23, 1, 129035.25, 'disponible'),
  ('arcus', '609', 'Suite 609', 'Suite', 'Piso 6 · Signature', 48.3, 58.77, 1, 126884.18, 'disponible'),
  ('arcus', '610', 'Loft 610', 'Loft', 'Piso 6 · Classic', 23.8, 28.08, 1, 69213, 'disponible')
on conflict (proyecto_id, codigo) do update set
  nombre = excluded.nombre, tipo = excluded.tipo, planta = excluded.planta,
  area_util_m2 = excluded.area_util_m2, area_total_m2 = excluded.area_total_m2,
  parqueos = excluded.parqueos, precio = excluded.precio, estado = excluded.estado;
