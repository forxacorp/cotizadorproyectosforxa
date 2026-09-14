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

// Aviso no bloqueante (reemplaza a alert(), que congela la página hasta que
// alguien hace clic en "Aceptar" — mala práctica de UX para errores de forma).
let toastTimer = null;
function showToast(message, type = 'error') {
  let el = document.getElementById('cotizador-toast');
  if (!el) {
    el = document.createElement('div');
    el.id = 'cotizador-toast';
    el.style.cssText = 'position:fixed;bottom:24px;left:50%;transform:translateX(-50%);z-index:999;max-width:90vw;padding:13px 20px;border-radius:10px;font-size:13.5px;font-family:var(--font-body, sans-serif);box-shadow:0 8px 24px rgba(0,0,0,.18);transition:opacity .2s, transform .2s;';
    document.body.appendChild(el);
  }
  el.textContent = message;
  el.style.background = type === 'error' ? '#a3402f' : (type === 'ok' ? '#565a41' : '#26251f');
  el.style.color = '#fff';
  el.style.opacity = '1';
  el.style.transform = 'translateX(-50%) translateY(0)';
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.style.opacity = '0'; el.style.transform = 'translateX(-50%) translateY(8px)'; }, 4200);
}

// Confirmación no bloqueante (reemplaza a confirm(), que también congela la
// página como alert()). Devuelve una Promise<boolean>.
function showConfirm(message, { confirmLabel = 'Eliminar', cancelLabel = 'Cancelar' } = {}) {
  return new Promise((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    overlay.innerHTML = `
      <div class="modal-box" role="alertdialog" aria-modal="true">
        <p>${message}</p>
        <div class="modal-actions">
          <button type="button" class="btn btn-ghost" data-action="cancel">${cancelLabel}</button>
          <button type="button" class="btn btn-danger" data-action="confirm">${confirmLabel}</button>
        </div>
      </div>`;
    document.body.appendChild(overlay);
    const close = (result) => { overlay.remove(); resolve(result); };
    overlay.addEventListener('click', (e) => { if (e.target === overlay) close(false); });
    overlay.querySelector('[data-action="cancel"]').onclick = () => close(false);
    overlay.querySelector('[data-action="confirm"]').onclick = () => close(true);
    overlay.querySelector('[data-action="confirm"]').focus();
  });
}

// Normaliza un teléfono de Ecuador a formato internacional sin '+' (lo que
// necesita wa.me): admite '0991234567', '+593991234567', '593 99 123 4567', etc.
function normalizarTelefonoEC(tel) {
  let d = (tel || '').replace(/[^\d]/g, '');
  if (!d) return '';
  if (d.startsWith('593')) return d;
  if (d.startsWith('0')) return '593' + d.slice(1);
  if (d.length === 9) return '593' + d; // celular sin el 0 inicial
  return d; // ya trae otro código de país — se respeta tal cual
}

function buildWhatsAppUrl(tel, mensaje) {
  const numero = normalizarTelefonoEC(tel);
  return `https://wa.me/${numero}?text=${encodeURIComponent(mensaje)}`;
}

// Exporta filas (array de arrays, primera fila = encabezados) a un .csv que
// Excel/Google Sheets abren directo con doble clic.
function csvEscape(v) {
  const s = (v === null || v === undefined) ? '' : String(v);
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
}
function descargarCSV(filename, rows) {
  const csv = rows.map(r => r.map(csvEscape).join(',')).join('\r\n');
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' }); // BOM: acentos correctos en Excel
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

async function uploadMedia(file, folder) {
  const ext = file.name.split('.').pop();
  const path = `${folder}/${Date.now()}-${Math.random().toString(36).slice(2,8)}.${ext}`;
  const { error } = await supabaseClient.storage.from('cotizador-media').upload(path, file, { upsert: false });
  if (error) throw error;
  return path; // guardamos el path (no la URL pública, porque el bucket es privado)
}
