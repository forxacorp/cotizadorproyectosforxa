#!/usr/bin/env bash
# ============================================================================
# FORXA · Cotizador — subir portadas y fichas (Mac / Linux)
#
# Uso: haz doble clic (si tu Mac lo permite) o corre en Terminal:
#   bash scripts/subir_fotos.sh
#
# Este script:
#   1. Revisa que tengas Node.js instalado.
#   2. Instala la única dependencia que hace falta (@supabase/supabase-js).
#   3. Te pide tu service_role key UNA VEZ, sin mostrarla en pantalla.
#   4. Sube las 4 portadas y las ~80 fichas a Supabase Storage.
# No guarda tu clave en ningún archivo — solo vive en memoria mientras corre.
# ============================================================================
set -e
cd "$(dirname "$0")/.."

echo "FORXA · Cotizador — subida de fotos"
echo "------------------------------------"

if ! command -v node >/dev/null 2>&1; then
  echo "No encuentro Node.js instalado."
  echo "Instálalo desde https://nodejs.org (versión LTS), abre una Terminal nueva"
  echo "y vuelve a correr este script."
  exit 1
fi
echo "✓ Node.js encontrado: $(node -v)"

if [ ! -d "node_modules/@supabase" ]; then
  echo "Instalando dependencia (@supabase/supabase-js)..."
  npm install @supabase/supabase-js --silent
fi
echo "✓ Dependencias listas"

echo ""
echo "Pega tu service_role key de Supabase (Project Settings → API → service_role)."
echo "No se va a mostrar en pantalla mientras la escribes/pegas — es normal."
read -s -p "service_role key: " SUPABASE_SERVICE_ROLE_KEY
echo ""
echo ""

if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo "No ingresaste ninguna clave. Cancelado."
  exit 1
fi

export SUPABASE_SERVICE_ROLE_KEY
node scripts/bulk_upload_fotos.mjs

echo ""
echo "Listo. Recarga el cotizador en el navegador (Cmd+Shift+R) para ver las fotos."
