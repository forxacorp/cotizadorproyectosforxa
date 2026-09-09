// Helpers compartidos: formato de moneda/fecha, matemática de crédito y
// generación de URLs firmadas para el bucket privado cotizador-media.

function fmtMoney(n) {
  if (n === null || n === undefined || isNaN(n)) return '—';
  return '$' + Number(n).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtDate(d) {
  return d.toLocaleDateString('es-EC', { day: 'numeric', month: 'long', year: 'numeric' });
}

// Cuota francesa estándar (usada tanto por AURA/Álabes como por Crédito VIP de Misicata).
function calcCuota(capital, tasaAnualPct, meses) {
  const r = (tasaAnualPct / 100) / 12;
  if (!capital || capital <= 0 || !meses || meses <= 0) return 0;
  if (r === 0) return capital / meses;
  return capital * (r * Math.pow(1 + r, meses)) / (Math.pow(1 + r, meses) - 1);
}

const ESTADO_LABEL = {
  disponible: 'Disponible',
  reservado: 'Reservado',
  vendida: 'Vendida',
  no_disponible: 'No disponible',
};

// El bucket cotizador-media es privado (requiere sesión), así que las URLs
// públicas no sirven: hay que pedir una URL firmada cada vez que se renderiza.
async function signedMediaUrl(path, expiresInSeconds = 3600) {
  if (!path) return null;
  if (/^https?:\/\//.test(path)) return path; // ya es una URL absoluta (externa)
  const { data, error } = await supabaseClient
    .storage
    .from('cotizador-media')
    .createSignedUrl(path, expiresInSeconds);
  if (error) { console.warn('No se pudo firmar la imagen', path, error); return null; }
  return data.signedUrl;
}

async function uploadMedia(file, folder) {
  const ext = file.name.split('.').pop();
  const path = `${folder}/${Date.now()}-${Math.random().toString(36).slice(2,8)}.${ext}`;
  const { error } = await supabaseClient.storage.from('cotizador-media').upload(path, file, { upsert: false });
  if (error) throw error;
  return path; // guardamos el path (no la URL pública, porque el bucket es privado)
}
