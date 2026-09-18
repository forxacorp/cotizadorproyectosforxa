-- ============================================================================
-- FORXA · Cotizador interno — corrige Portón del Valle (bug de origen)
--
-- Qué encontré: los 33 lotes de Portón del Valle ya estaban cargados en la
-- base de datos (tabla cotizador_inventario_extra, tipo 'lote') — pero el
-- proyecto "porton" tiene tipo_financiamiento = 'pago_directo', y el código
-- del cotizador SOLO busca en esa tabla cuando tipo_financiamiento = 'lote'
-- (ver js/cotizador.js → loadUnidades()). Como nunca coincidían, el
-- cotizador mostraba el grid de unidades de Portón del Valle vacío desde
-- siempre — no es un problema de datos faltantes, es que vivían en la tabla
-- que el código no consulta para ese proyecto.
--
-- La imagen "Mesa_de_trabajo" que pasaste trae exactamente los mismos 31
-- lotes disponibles ya cargados (comparé los 31, cero diferencias en área o
-- precio) — así que no hacía falta recapturar nada, solo corregir dónde
-- vive el dato. Corrección real encontrada: el lote A82 SÍ estaba
-- disponible en la base de datos, pero ya NO aparece en tu lista de
-- disponibles más reciente — lo marqué no_disponible con una nota para que
-- lo confirmes desde Administrar (puede que se haya vendido/reservado).
--
-- Qué hace este script: mueve los 33 lotes a cotizador_unidades (que sí es
-- la tabla que carga 'pago_directo', la política ya configurada para
-- Portón — reserva 30% sugerida + resto financiable — que ya estaba
-- pensada para lotes "listos para entrega", según el comentario original
-- del código). Al final borra las filas viejas de cotizador_inventario_extra
-- para no dejar el mismo dato duplicado en dos tablas.
--
-- Seguro de correr más de una vez (on conflict do update).
-- Pega esto en: Supabase → SQL Editor → New query → Run.
-- ============================================================================

insert into public.cotizador_unidades
  (proyecto_id, codigo, nombre, tipo, planta, terreno_m2, precio, estado, nota)
values
  ('porton', 'A14', 'Lote A14', 'Lote', 'Categoría A', 2546.52, 76395.6, 'disponible', null),
  ('porton', 'A18', 'Lote A18', 'Lote', 'Categoría A', 2597.51, 77925.3, 'disponible', null),
  ('porton', 'A20', 'Lote A20', 'Lote', 'Categoría A', 2570.75, 77122.5, 'disponible', null),
  ('porton', 'A21', 'Lote A21', 'Lote', 'Categoría B', 2394.49, 67045.72, 'disponible', null),
  ('porton', 'A22', 'Lote A22', 'Lote', 'Categoría A', 2572.83, 77184.9, 'disponible', null),
  ('porton', 'A24', 'Lote A24', 'Lote', 'Categoría A', 2506.2, 75186.0, 'disponible', null),
  ('porton', 'A25', 'Lote A25', 'Lote', 'Categoría B', 2344.39, 65642.92, 'disponible', null),
  ('porton', 'A32', 'Lote A32', 'Lote', 'Categoría A', 2501.91, 75057.29999999999, 'disponible', null),
  ('porton', 'A40', 'Lote A40', 'Lote', 'Categoría A', 2687.78, 80633.40000000001, 'disponible', null),
  ('porton', 'A41', 'Lote A41', 'Lote', 'Categoría A', 2626.29, 78788.7, 'disponible', null),
  ('porton', 'A42', 'Lote A42', 'Lote', 'Categoría B', 2889.09, 80894.52, 'disponible', null),
  ('porton', 'A43', 'Lote A43', 'Lote', 'Categoría B', 3302.04, 92457.12, 'disponible', null),
  ('porton', 'A44', 'Lote A44', 'Lote', 'Categoría A', 2965.35, 88960.5, 'disponible', null),
  ('porton', 'A46', 'Lote A46', 'Lote', 'Categoría A', 2898.95, 86968.5, 'disponible', null),
  ('porton', 'A51', 'Lote A51', 'Lote', 'Categoría A', 2507.46, 70208.88, 'disponible', null),
  ('porton', 'A52', 'Lote A52', 'Lote', 'Categoría C', 2601.77, 65044.25, 'disponible', null),
  ('porton', 'A56', 'Lote A56', 'Lote', 'Categoría B', 2759.2, 77257.59999999999, 'disponible', null),
  ('porton', 'A57', 'Lote A57', 'Lote', 'Categoría B', 2507.36, 70206.08, 'disponible', null),
  ('porton', 'A59', 'Lote A59', 'Lote', 'Categoría B', 2684.81, 75174.68, 'disponible', null),
  ('porton', 'A60', 'Lote A60', 'Lote', 'Categoría A', 2735.69, 82070.7, 'disponible', null),
  ('porton', 'A61', 'Lote A61', 'Lote', 'Categoría B', 3116.3, 87256.40000000001, 'disponible', null),
  ('porton', 'A62', 'Lote A62', 'Lote', 'Categoría B', 2887.37, 80846.36, 'disponible', null),
  ('porton', 'A63', 'Lote A63', 'Lote', 'Categoría B', 4843.98, 135631.44, 'disponible', null),
  ('porton', 'A-64', 'Lote A-64', 'Lote', 'Categoría B', 3264.47, 91405.15999999999, 'no_disponible', 'SR OCAMPO CAMBIO POR LOTE A-12'),
  ('porton', 'A71', 'Lote A71', 'Lote', 'Categoría C', 3711.19, 92779.75, 'disponible', null),
  ('porton', 'A72', 'Lote A72', 'Lote', 'Categoría B', 2797.73, 78336.44, 'disponible', null),
  ('porton', 'A73', 'Lote A73', 'Lote', 'Categoría A', 3102.35, 93070.5, 'disponible', null),
  ('porton', 'A74', 'Lote A74', 'Lote', 'Categoría C', 3266.22, 81655.5, 'disponible', null),
  ('porton', 'A75', 'Lote A75', 'Lote', 'Categoría A', 3165.37, 94961.09999999999, 'disponible', null),
  ('porton', 'A76', 'Lote A76', 'Lote', 'Categoría C', 3258.79, 81469.75, 'disponible', null),
  ('porton', 'A77', 'Lote A77', 'Lote', 'Categoría A', 2862.72, 85881.59999999999, 'disponible', null),
  ('porton', 'A81', 'Lote A81', 'Lote', 'Categoría B', 4658.13, 130427.64, 'disponible', null),
  ('porton', 'A82', 'Lote A82', 'Lote', 'Categoría AA', 3411.4, 112576.2, 'no_disponible', 'No aparece en la lista de "unidades disponibles" más reciente (imagen Mesa_de_trabajo) — verificar si se vendió/reservó y corregir estado si corresponde.')
on conflict (proyecto_id, codigo) do update set
  nombre = excluded.nombre, tipo = excluded.tipo, planta = excluded.planta,
  terreno_m2 = excluded.terreno_m2, precio = excluded.precio,
  estado = excluded.estado, nota = excluded.nota;

-- Limpieza: ya migrados a cotizador_unidades, estas filas quedarían
-- duplicadas e inconsistentes con el tiempo si alguien las sigue editando
-- por error en la tabla vieja.
delete from public.cotizador_inventario_extra
where proyecto_id = 'porton' and tipo = 'lote';
