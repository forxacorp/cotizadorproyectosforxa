// Sube en bloque las fichas extraídas (carpeta fotos/<proyecto>/<codigo>.jpg)
// al bucket privado cotizador-media, y actualiza foto_url de cada unidad.
//
// Uso:
//   1. npm install @supabase/supabase-js
//   2. SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key node scripts/bulk_upload_fotos.mjs
//
// La service_role key NUNCA va en el código ni en Netlify — solo la usas una
// vez, localmente, para esta carga inicial. Sácala de Supabase → Project
// Settings → API → service_role (secreta, distinta de la anon key).

import { createClient } from '@supabase/supabase-js';
import fs from 'node:fs';
import path from 'node:path';

const SUPABASE_URL = 'https://jjdybtskzqpybrltdnss.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SERVICE_KEY) {
  console.error('Falta SUPABASE_SERVICE_ROLE_KEY en el entorno.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
const FOTOS_DIR = path.join(process.cwd(), 'fotos');

async function subirCovers() {
  const dir = path.join(FOTOS_DIR, '_covers');
  if (!fs.existsSync(dir)) return;
  const files = fs.readdirSync(dir).filter(f => /\.(jpg|jpeg|png)$/i.test(f));
  console.log(`\nportadas: ${files.length} archivos`);
  for (const file of files) {
    const proyectoId = path.basename(file, path.extname(file)); // "misicata.jpg" -> "misicata"
    const storagePath = `proyectos/${proyectoId}/cover${path.extname(file)}`;
    const buffer = fs.readFileSync(path.join(dir, file));
    const { error: upErr } = await supabase.storage
      .from('cotizador-media')
      .upload(storagePath, buffer, { upsert: true, contentType: 'image/jpeg' });
    if (upErr) { console.error('  ✗ subida', file, upErr.message); continue; }
    const { error: updErr } = await supabase
      .from('cotizador_proyectos')
      .update({ cover_url: storagePath })
      .eq('id', proyectoId);
    if (updErr) console.error('  ✗ update', proyectoId, updErr.message);
    else console.log('  ✓', file, '→ portada de', proyectoId);
  }
}

async function main() {
  await subirCovers();
  const proyectos = fs.readdirSync(FOTOS_DIR).filter(f => fs.statSync(path.join(FOTOS_DIR, f)).isDirectory() && f !== '_covers');
  for (const proyecto of proyectos) {
    const dir = path.join(FOTOS_DIR, proyecto);
    const files = fs.readdirSync(dir).filter(f => /\.(jpg|jpeg|png)$/i.test(f));
    console.log(`\n${proyecto}: ${files.length} archivos`);
    for (const file of files) {
      const base = path.basename(file, path.extname(file)); // "casa1_baja" | "201" | "A0"
      const codigo = base.includes('_') ? base.split('_')[0] : base;
      const columna = base.endsWith('_baja') ? 'plano_baja_url'
                     : base.endsWith('_alta') ? 'plano_alta_url'
                     : 'foto_url';
      const storagePath = `unidades/${proyecto}/${file}`;
      const buffer = fs.readFileSync(path.join(dir, file));
      const { error: upErr } = await supabase.storage
        .from('cotizador-media')
        .upload(storagePath, buffer, { upsert: true, contentType: 'image/jpeg' });
      if (upErr) { console.error('  ✗ subida', file, upErr.message); continue; }

      const { error: updErr } = await supabase
        .from('cotizador_unidades')
        .update({ [columna]: storagePath, ...(columna === 'plano_baja_url' ? { foto_url: storagePath } : {}) })
        .eq('proyecto_id', proyecto)
        .eq('codigo', codigo);
      if (updErr) console.error('  ✗ update', codigo, updErr.message);
      else console.log('  ✓', file, '→', codigo, `(${columna})`);
    }
  }
}

main();
