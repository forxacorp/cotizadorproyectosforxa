-- ============================================================================
-- FORXA · Cotizador interno — motivo de compra y forma de pago
--
-- Qué hace: agrega dos columnas a cotizador_historial para que el formulario
-- del cotizador pueda guardar por qué compra el cliente (inversión/vivienda)
-- y cómo va a pagar (financiamiento/contado). Alimentan el nuevo Dashboard
-- de preferencias en historial.html.
--
-- Es seguro volver a correrlo ("if not exists"). No hace falta tocar RLS:
-- estas columnas quedan cubiertas por las políticas que ya existen sobre
-- cotizador_historial (schema.sql).
--
-- Pega esto en: Supabase → SQL Editor → New query → Run.
-- ============================================================================

alter table public.cotizador_historial
  add column if not exists motivo_compra text,   -- 'inversion' | 'vivienda' | null (proformas anteriores a esta entrega)
  add column if not exists forma_pago text default 'financiamiento'; -- 'financiamiento' | 'contado'
