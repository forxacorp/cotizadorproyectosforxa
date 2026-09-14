-- ============================================================================
-- FORXA · Cotizador — datos iniciales (4 proyectos + unidades)
-- Pega esto DESPUES de schema.sql en el mismo SQL Editor y dale Run.
-- ============================================================================

-- Cada proyecto tiene su propio color_primario/color_acento (se usan en su
-- tarjeta del picker, en el banner de su cotizador y en botones/precios de
-- esa página) para que se distingan claramente entre sí, en vez de compartir
-- casi el mismo tono oliva los cuatro.
-- tipo_financiamiento 'cuotas_entrega' (Misicata/AURA/Álabes): reserva 2% +
-- promesa 8% + cuotas hasta la entrega (20%, las define el asesor) = 30% de
-- abono; el 70% restante se financia con interés/plazo editables.
-- 'pago_directo' (Portón, ya listo para entrega): un solo abono editable
-- (reserva_pct se reutiliza como % de abono sugerido, 30%) + el mismo 70%.
insert into public.cotizador_proyectos (id, nombre, tagline, ubicacion, color_primario, color_acento, tipo_financiamiento, prefijo_proforma, reserva_pct, promesa_pct, tasa_default, plazo_default_anios, permite_descuento_manual, monto_descuento_clic, permite_multi_seleccion, sort_order) values
  ('misicata', 'Mirador de Misicata', 'Condominio privado · Sector Antenas de Misicata, Cuenca', 'Cuenca, Ecuador', '#43573a', '#c9bb8e', 'cuotas_entrega', 'MIS', 0.02, 0.08, 10.5, 20, true, 0, true, 1),
  ('aura', 'AURA', 'Edificio residencial Ordóñez Lasso', 'Cuenca, Ecuador', '#2d3b52', '#aac3d8', 'cuotas_entrega', 'AURA', 0.02, 0.08, 10.5, 20, false, 0, false, 2),
  ('alabes', 'Álabes', 'Suites, departamentos y locales comerciales · Calle del Batán', 'Cuenca, Ecuador', '#6a3226', '#e2ba86', 'cuotas_entrega', 'ALB', 0.02, 0.08, 10.5, 20, false, 0, true, 3),
  ('porton', 'Portón del Valle', 'Lotes y desarrollo residencial · Valle de Yunguilla', 'Yunguilla, Ecuador', '#7c5a2c', '#ddc99a', 'pago_directo', 'PDV', 0.30, 0, 10.5, 20, false, 0, false, 4)
on conflict (id) do update set
  nombre=excluded.nombre, tagline=excluded.tagline, ubicacion=excluded.ubicacion,
  color_primario=excluded.color_primario, color_acento=excluded.color_acento;

-- Misicata --------------------------------------------------------------
insert into public.cotizador_unidades (proyecto_id, codigo, nombre, tipo, terreno_m2, construccion_m2, dormitorios, banos, parqueos, precio, aplica_vip, estado) values
  ('misicata', 'casa1', 'Casa 1', 'Casa Tipo 1', 176, 117, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa2', 'Casa 2', 'Casa Tipo 1', 111, 117, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa3', 'Casa 3', 'Casa Tipo 1', 111, 117, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa4', 'Casa 4', 'Casa Tipo 1', 110, 117, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa5', 'Casa 5', 'Casa Tipo 1', 109, 117, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa6', 'Casa 6', 'Casa Tipo 2', 206, 158, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa7', 'Casa 7', 'Casa Tipo 1', 98, 117, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa8', 'Casa 8', 'Casa Tipo 1', 98, 117, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'casa9', 'Casa 9', 'Casa Tipo 1', 98, 117, 3, 2.5, 2, null, true, 'no_disponible'),
  ('misicata', 'casa10', 'Casa 10', 'Casa Tipo 1', 98, 117, 3, 2.5, 2, 115500, true, 'disponible'),
  ('misicata', 'casa11', 'Casa 11', 'Casa Tipo 1', 215, 146, 3, 2.5, 2, null, true, 'vendida'),
  ('misicata', 'suite1', 'Suite 1', 'Suite', 115, 52, 1, 1.5, 1, 77000, true, 'disponible'),
  ('misicata', 'suite2', 'Suite 2', 'Suite', null, 72, 1, 1.5, 1, null, true, 'vendida')
on conflict (proyecto_id, codigo) do update set precio=excluded.precio, estado=excluded.estado;

-- AURA --------------------------------------------------------------------
insert into public.cotizador_unidades (proyecto_id, codigo, nombre, tipo, area_util_m2, area_total_m2, dormitorios, banos, bodega_codigo, precio, estado) values
  ('aura', '201', 'Departamento 201', 'Departamento', 128.32, 145.45, 3, 2.5, '8 (3.79 m²)', 224800, 'disponible'),
  ('aura', '202', 'Departamento 202', 'Departamento', 86.8, 93.27, 2, 2, '14 (3.77 m²)', 148500, 'disponible'),
  ('aura', '203', 'Suite 203', 'Suite', null, null, null, null, null, null, 'vendida'),
  ('aura', '204', 'Departamento 204', 'Departamento', 90.24, 175.21, 2, 2, '19 (3.71 m²)', 198000, 'disponible'),
  ('aura', '301', 'Departamento 301', 'Departamento', null, null, null, null, null, null, 'vendida'),
  ('aura', '302', 'Departamento 302', 'Departamento', 86.8, 93.84, 2, 2, '23 (4.34 m²)', 149000, 'disponible'),
  ('aura', '303', 'Suite 303', 'Suite', null, null, null, null, null, null, 'vendida'),
  ('aura', '304', 'Departamento 304', 'Departamento', 90.24, 96.26, 2, 2, '21 (6.02 m²)', 153300, 'disponible'),
  ('aura', '401', 'Departamento 401', 'Departamento', null, null, null, null, null, null, 'vendida'),
  ('aura', '402', 'Departamento 402', 'Departamento', null, null, null, null, null, null, 'vendida'),
  ('aura', '403', 'Suite 403', 'Suite', null, null, null, null, null, null, 'vendida'),
  ('aura', '404', 'Departamento 404', 'Departamento', 90.24, 94.69, 2, 2, '20 (4.45 m²)', 156000, 'disponible'),
  ('aura', '501', 'Departamento 501', 'Departamento', null, null, null, null, null, null, 'vendida'),
  ('aura', '502', 'Suite 502', 'Suite', 63.45, 69.25, 1, 1.5, '9 (3.10 m²)', 116700, 'disponible'),
  ('aura', '503', 'Suite 503', 'Suite', 46.96, 51.55, 1, 1.5, '7 (4.59 m²)', 92200, 'disponible'),
  ('aura', '504', 'Departamento 504', 'Departamento', 90.24, 94.99, 2, 2, '16 (4.75 m²)', 157000, 'disponible'),
  ('aura', '601', 'Departamento 601', 'Departamento', null, null, null, null, null, null, 'vendida'),
  ('aura', '602', 'Departamento 602', 'Departamento', null, null, null, null, null, null, 'vendida'),
  ('aura', '603', 'Departamento 603', 'Departamento', 90.24, 93.3, 2, 2, '12 (3.06 m²)', 160000, 'disponible'),
  ('aura', '701', 'Departamento 701', 'Departamento', null, null, null, null, null, null, 'vendida'),
  ('aura', '702', 'Suite 702', 'Suite', null, null, null, null, null, null, 'vendida'),
  ('aura', '703', 'Departamento 703', 'Departamento', null, null, null, null, null, null, 'vendida')
on conflict (proyecto_id, codigo) do update set precio=excluded.precio, estado=excluded.estado;

-- AURA · bodegas y parqueaderos que se venden por separado -----------------
insert into public.cotizador_inventario_extra (proyecto_id, codigo, tipo, precio, estado) values
  ('aura', 'parqueadero-5', 'parqueadero', 12000, 'disponible'),
  ('aura', 'parqueadero-6', 'parqueadero', 12000, 'disponible'),
  ('aura', 'parqueadero-14', 'parqueadero', 12000, 'disponible'),
  ('aura', 'bodega-7', 'bodega', 5000, 'disponible'),
  ('aura', 'bodega-13', 'bodega', 3200, 'disponible'),
  ('aura', 'bodega-18', 'bodega', 5200, 'disponible')
on conflict (proyecto_id, tipo, codigo) do nothing;

-- Álabes --------------------------------------------------------------------
insert into public.cotizador_unidades (proyecto_id, codigo, nombre, tipo, planta, area_util_m2, dormitorios, banos, bodega_codigo, bodega_area_m2, precio, precio_preventa, estado) values
  ('alabes', 'A0', 'Suite A0', 'Suite', null, 54.07, 1, 1, '22', 2.75, 86000.0, 80400.0, 'reservado'),
  ('alabes', 'A1', 'Suite A1', 'Suite', null, 54.97, 1, 1, '23', 2.71, 87500.0, 81900.0, 'disponible'),
  ('alabes', 'A2', 'Suite A2', 'Suite', null, 56.31, 1, 1, '24', 2.69, 89500.0, 83600.0, 'disponible'),
  ('alabes', 'A3', 'Monoambiente A3', 'Monoambiente', null, 50.86, 1, 1, '34', 2.33, 81600.0, 76000.0, 'disponible'),
  ('alabes', 'L01', 'Local L01', 'Local', null, 54.3, null, 1, '18', 3.83, 100900.0, 95500.0, 'disponible'),
  ('alabes', 'L02', 'Local L02', 'Local', null, 40.65, null, 1, '19', 3.95, 76500.0, 72500.0, 'reservado'),
  ('alabes', 'L03', 'Local L03', 'Local', null, 40.81, null, 1, '20', 4.06, 76800.0, 72700.0, 'reservado'),
  ('alabes', 'L04', 'Local L04', 'Local', null, 44.77, null, 1, '21', 4.29, 84000.0, 79600.0, 'disponible'),
  ('alabes', 'B0', 'Suite B0', 'Suite', 'PRIMERA PLANTA ALTA', 38.02, 1, 1, '25', 2.68, 66800.0, 61200.0, 'disponible'),
  ('alabes', 'B1', 'Suite B1', 'Suite', 'PRIMERA PLANTA ALTA', 38.51, 1, 1, '26', 2.66, 67900.0, 62200.0, 'disponible'),
  ('alabes', 'B2', 'Suite B2', 'Suite', 'PRIMERA PLANTA ALTA', 39.38, 1, 1, '27', 2.65, 69000.0, 63200.0, 'disponible'),
  ('alabes', 'B3', 'Monoambiente B3', 'Monoambiente', 'PRIMERA PLANTA ALTA', 37.02, 1, 1, '33', 2.4, 64900.0, 59400.0, 'disponible'),
  ('alabes', 'B4', 'Suite B4', 'Suite', 'PRIMERA PLANTA ALTA', 41.83, 1, 1, '28', 2.63, 73500.0, 66900.0, 'disponible'),
  ('alabes', 'B5', 'Suite B5', 'Suite', 'PRIMERA PLANTA ALTA', 47.59, 1, 1, '29', 2.62, 83000.0, 75900.0, 'disponible'),
  ('alabes', 'B6', 'Suite B6', 'Suite', 'PRIMERA PLANTA ALTA', 47.33, 1, 1, '30', 2.6, 82600.0, 75500.0, 'disponible'),
  ('alabes', 'B7', 'Suite B7', 'Suite', 'PRIMERA PLANTA ALTA', 50.14, 1, 1, '31', 2.59, 87400.0, 79900.0, 'disponible'),
  ('alabes', 'B8', 'Suite B8', 'Suite', 'PRIMERA PLANTA ALTA', 38.84, 1, 1, '02', 3.05, 68500.0, 62700.0, 'disponible'),
  ('alabes', 'B9', 'Suite B9', 'Suite', 'PRIMERA PLANTA ALTA', 38.84, 1, 1, '04', 3.05, 68500.0, 62700.0, 'disponible'),
  ('alabes', 'B10', 'Suite B10', 'Suite', 'PRIMERA PLANTA ALTA', 55.85, 1, 1, '16', 3.59, 83774.99999999999, 83774.99999999999, 'vendida'),
  ('alabes', 'B11', 'Suite B11', 'Suite', 'PRIMERA PLANTA ALTA', 57.18, 1, 1.5, '07', 4.76, 101000.0, 92500.0, 'disponible'),
  ('alabes', 'B12', 'Suite B12', 'Suite', 'PRIMERA PLANTA ALTA', 53.16, 1, 1.5, '08', 5.38, 94700.0, 86800.0, 'reservado'),
  ('alabes', 'C0', 'Suite C0', 'Suite', 'SEGUNDA PLANTA ALTA', 38.02, 1, 1, '05', 3.05, 67000.0, 61500.0, 'disponible'),
  ('alabes', 'C1', 'Suite C1', 'Suite', 'SEGUNDA PLANTA ALTA', 38.72, 1, 1, '06', 3.05, 68300.0, 62500.0, 'disponible'),
  ('alabes', 'C2', 'Suite C2', 'Suite', 'SEGUNDA PLANTA ALTA', 39.38, 1, 1, '03', 3.05, 69500.0, 63500.0, 'disponible'),
  ('alabes', 'C3', 'Monoambiente C3', 'Monoambiente', 'SEGUNDA PLANTA ALTA', 36.99, 1, 1, '09', 2.66, 65000.0, 59500.0, 'disponible'),
  ('alabes', 'C4', '2 Dormitorios C4', '2 Dormitorios', 'SEGUNDA PLANTA ALTA', 64.02, 2, 2, '11', 2.95, 111200.0, 101600.0, 'disponible'),
  ('alabes', 'C5', '2 Dormitorios C5', '2 Dormitorios', 'SEGUNDA PLANTA ALTA', 70.19, 2, 2, '12', 3.07, 121800.0, 111300.0, 'disponible'),
  ('alabes', 'C6', '2  Dormitorios C6', '2  Dormitorios', 'SEGUNDA PLANTA ALTA', 66.97, 2, 2, '17', 3.71, 116800.0, 106900.0, 'disponible'),
  ('alabes', 'C7', 'Suite Tipo Loft C7', 'Suite Tipo Loft', 'SEGUNDA PLANTA ALTA', 64.39, 2, 1, '14', 3.33, 112200.0, 102500.0, 'disponible'),
  ('alabes', 'C8', 'Suite C8', 'Suite', 'SEGUNDA PLANTA ALTA', 38.84, 1, 1, '01', 3.58, 68900.0, 63200.0, 'disponible'),
  ('alabes', 'C9', 'Suite C9', 'Suite', 'SEGUNDA PLANTA ALTA', 38.84, 1, 1, '10', 2.81, 68500.0, 62500.0, 'reservado'),
  ('alabes', 'C10', '2 Dormitorios C10', '2 Dormitorios', 'SEGUNDA PLANTA ALTA', 89.92, 2, 2, '15', 3.46, 147900.0, 135600.0, 'disponible'),
  ('alabes', 'C11', '2 Dormitorios C11', '2 Dormitorios', 'SEGUNDA PLANTA ALTA', 83.48, 2, 2, '32', 4, 137500.0, 126000.0, 'reservado'),
  ('alabes', 'C12', '2 Dormitorios C12', '2 Dormitorios', 'SEGUNDA PLANTA ALTA', 105.64, 2, 2, '13', 3.2, 160500.0, 148200.0, 'reservado')
on conflict (proyecto_id, codigo) do update set precio=excluded.precio, estado=excluded.estado, precio_preventa=excluded.precio_preventa;

-- Álabes · parqueaderos de carro y moto --------------------------------------
insert into public.cotizador_inventario_extra (proyecto_id, codigo, tipo, precio, precio_preventa, estado) values
  ('alabes', '1-carro', 'carro', 10200.0, 10200.0, 'disponible'),
  ('alabes', '2-carro', 'carro', 10200.0, 10200.0, 'disponible'),
  ('alabes', '3-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '4-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '5-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '6-carro', 'carro', 12300.0, 12300.0, 'disponible'),
  ('alabes', '7-carro', 'carro', 14600.0, 14600.0, 'disponible'),
  ('alabes', '8-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '9-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '10-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '11-carro', 'carro', 10000.0, 10000.0, 'disponible'),
  ('alabes', '12-carro', 'carro', 10000.0, 10000.0, 'disponible'),
  ('alabes', '13-carro', 'carro', 10000.0, 10000.0, 'disponible'),
  ('alabes', '14-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '15-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '16-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '17-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '18-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '19-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '20-carro', 'carro', 9600.0, 9600.0, 'disponible'),
  ('alabes', '21-carro', 'carro', 13300.0, 13300.0, 'disponible'),
  ('alabes', '22-carro', 'carro', 12500.0, 12500.0, 'disponible'),
  ('alabes', '1-moto', 'moto', 2000.0, 2000.0, 'disponible'),
  ('alabes', '2-moto', 'moto', 2000.0, 2000.0, 'disponible'),
  ('alabes', '3-moto', 'moto', 2000.0, 2000.0, 'disponible'),
  ('alabes', '4-moto', 'moto', 2000.0, 2000.0, 'disponible'),
  ('alabes', '5-moto', 'moto', 2000.0, 2000.0, 'disponible'),
  ('alabes', '6-moto', 'moto', 2000.0, 2000.0, 'disponible')
on conflict (proyecto_id, tipo, codigo) do nothing;

-- Portón del Valle · lotes ---------------------------------------------------
insert into public.cotizador_inventario_extra (proyecto_id, codigo, tipo, categoria, precio, precio_m2, metraje_m2, estado, nota) values
  ('porton', 'A14', 'lote', 'A', 76395.6, 30.0, 2546.52, 'disponible', null),
  ('porton', 'A18', 'lote', 'A', 77925.3, 30.0, 2597.51, 'disponible', null),
  ('porton', 'A20', 'lote', 'A', 77122.5, 30.0, 2570.75, 'disponible', null),
  ('porton', 'A21', 'lote', 'B', 67045.72, 28.0, 2394.49, 'disponible', null),
  ('porton', 'A22', 'lote', 'A', 77184.9, 30.0, 2572.83, 'disponible', null),
  ('porton', 'A24', 'lote', 'A', 75186.0, 30.0, 2506.2, 'disponible', null),
  ('porton', 'A25', 'lote', 'B', 65642.92, 28.0, 2344.39, 'disponible', null),
  ('porton', 'A32', 'lote', 'A', 75057.29999999999, 30.0, 2501.91, 'disponible', null),
  ('porton', 'A40', 'lote', 'A', 80633.40000000001, 30.0, 2687.78, 'disponible', null),
  ('porton', 'A41', 'lote', 'A', 78788.7, 30.0, 2626.29, 'disponible', null),
  ('porton', 'A42', 'lote', 'B', 80894.52, 28.0, 2889.09, 'disponible', null),
  ('porton', 'A43', 'lote', 'B', 92457.12, 28.0, 3302.04, 'disponible', null),
  ('porton', 'A44', 'lote', 'A', 88960.5, 30.0, 2965.35, 'disponible', null),
  ('porton', 'A46', 'lote', 'A', 86968.5, 30.0, 2898.95, 'disponible', null),
  ('porton', 'A51', 'lote', 'A', 70208.88, 28.0, 2507.46, 'disponible', null),
  ('porton', 'A52', 'lote', 'C', 65044.25, 25.0, 2601.77, 'disponible', null),
  ('porton', 'A56', 'lote', 'B', 77257.59999999999, 28.0, 2759.2, 'disponible', null),
  ('porton', 'A57', 'lote', 'B', 70206.08, 28.0, 2507.36, 'disponible', null),
  ('porton', 'A59', 'lote', 'B', 75174.68, 28.0, 2684.81, 'disponible', null),
  ('porton', 'A60', 'lote', 'A', 82070.7, 30.0, 2735.69, 'disponible', null),
  ('porton', 'A61', 'lote', 'B', 87256.40000000001, 28.0, 3116.3, 'disponible', null),
  ('porton', 'A62', 'lote', 'B', 80846.36, 28.0, 2887.37, 'disponible', null),
  ('porton', 'A63', 'lote', 'B', 135631.44, 28.0, 4843.98, 'disponible', null),
  ('porton', 'A-64', 'lote', 'B', 91405.15999999999, 28.0, 3264.47, 'no_disponible', 'SR OCAMPO CAMBIO POR LOTE A-12'),
  ('porton', 'A71', 'lote', 'C', 92779.75, 25.0, 3711.19, 'disponible', null),
  ('porton', 'A72', 'lote', 'B', 78336.44, 28.0, 2797.73, 'disponible', null),
  ('porton', 'A73', 'lote', 'A', 93070.5, 30.0, 3102.35, 'disponible', null),
  ('porton', 'A74', 'lote', 'C', 81655.5, 25.0, 3266.22, 'disponible', null),
  ('porton', 'A75', 'lote', 'A', 94961.09999999999, 30.0, 3165.37, 'disponible', null),
  ('porton', 'A76', 'lote', 'C', 81469.75, 25.0, 3258.79, 'disponible', null),
  ('porton', 'A77', 'lote', 'A', 85881.59999999999, 30.0, 2862.72, 'disponible', null),
  ('porton', 'A81', 'lote', 'B', 130427.64, 28.0, 4658.13, 'disponible', null),
  ('porton', 'A82', 'lote', 'AA', 112576.2, 33.0, 3411.4, 'disponible', null)
on conflict (proyecto_id, tipo, codigo) do update set estado=excluded.estado, precio=excluded.precio;
