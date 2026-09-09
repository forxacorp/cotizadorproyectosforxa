-- ============================================================================
-- FORXA · Cotizador — actualizar colores de los 4 proyectos ya existentes
-- ============================================================================
-- Por qué: los 4 proyectos se cargaron originalmente con tonos oliva casi
-- idénticos (por eso Álabes, AURA, Misicata y Portón se veían "sin marca
-- propia" entre sí). Este script les da un color distinto y elegante a cada
-- uno; se usa en su tarjeta de portada, en el banner de su cotizador y en
-- botones/precios de esa página.
--
-- Solo hace falta correrlo UNA VEZ, en el SQL Editor de tu proyecto de
-- Supabase (el mismo donde ya corriste schema.sql y seed_data.sql). Si
-- prefieres, también puedes cambiar el color de cada proyecto a mano desde
-- Administrar → Proyectos → Editar (los selectores de color ya están ahí).
-- ============================================================================

update public.cotizador_proyectos set color_primario = '#43573a', color_acento = '#c9bb8e' where id = 'misicata';
update public.cotizador_proyectos set color_primario = '#2d3b52', color_acento = '#aac3d8' where id = 'aura';
update public.cotizador_proyectos set color_primario = '#6a3226', color_acento = '#e2ba86' where id = 'alabes';
update public.cotizador_proyectos set color_primario = '#7c5a2c', color_acento = '#ddc99a' where id = 'porton';
