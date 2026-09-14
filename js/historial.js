// Historial de proformas: solo lo ve la cuenta con puede_ver_historial = true
// en cotizador_admins (ver supabase/update_financiamiento_v2.sql). El resto
// de asesores sigue generando proformas normalmente, solo no pueden leer
// este historial (ni desde aquí ni consultando la tabla directamente — la
// política de RLS en Supabase lo bloquea a nivel de base de datos).

let HISTORIAL = [];
let PROYECTOS_FILTRO = [];

async function boot() {
  const result = await CotizadorAuth.requireHistorialAccess();
  if (!result) return; // requireSession ya redirigió a index.html (no hay sesión)
  const { user, puedeVerHistorial } = result;

  document.getElementById('header-actions').innerHTML = `
    <span class="user-pill">${user.email}</span>
    <a href="index.html">Ver cotizador</a>
    ${CotizadorAuth.getIsAdmin() ? '<a href="admin.html">Administrar</a>' : ''}
    <button id="logout-btn">Cerrar sesión</button>`;
  document.getElementById('logout-btn').onclick = async () => { await CotizadorAuth.logout(); location.href = 'index.html'; };

  if (!puedeVerHistorial) {
    document.getElementById('sin-permisos').hidden = false;
    document.getElementById('sin-permisos').innerHTML = `
      <div class="card" style="text-align:center;padding:48px 32px;">
        <h3 class="centered">Tu cuenta no tiene acceso al historial</h3>
        <p class="hint" style="max-width:440px;margin:0 auto 18px;">
          El historial de proformas (datos de clientes y montos cotizados) está restringido a una sola
          cuenta. Tu usuario (<strong>${user.email}</strong>) puede seguir generando proformas normalmente
          desde el cotizador. Si esta cuenta sí debería tener acceso, corre esto en el SQL Editor de Supabase:
        </p>
        <pre style="text-align:left;background:var(--crema);border:1px solid var(--border);border-radius:10px;padding:16px 18px;font-size:12.5px;overflow-x:auto;max-width:560px;margin:0 auto 20px;">insert into public.cotizador_admins (user_id, nombre, puede_ver_historial)
select id, '${user.email}', true from auth.users where email = '${user.email}'
on conflict (user_id) do update set puede_ver_historial = true;</pre>
        <a href="index.html" class="btn btn-primary">Ir al cotizador</a>
      </div>`;
    return;
  }

  document.getElementById('historial-content').hidden = false;
  await cargarProyectosFiltro();
  wireFiltros();
  await cargarHistorial();
}

async function cargarProyectosFiltro() {
  const { data } = await supabaseClient.from('cotizador_proyectos').select('id, nombre').order('sort_order');
  PROYECTOS_FILTRO = data || [];
  const sel = document.getElementById('f-proyecto');
  sel.innerHTML = '<option value="">Todos los proyectos</option>' +
    PROYECTOS_FILTRO.map(p => `<option value="${p.id}">${p.nombre}</option>`).join('');
}

function wireFiltros() {
  ['f-proyecto', 'f-buscar', 'f-desde', 'f-hasta'].forEach(id => {
    document.getElementById(id).addEventListener('input', debounce(cargarHistorial, 300));
    document.getElementById(id).addEventListener('change', cargarHistorial);
  });
  document.getElementById('f-limpiar').onclick = () => {
    document.getElementById('f-proyecto').value = '';
    document.getElementById('f-buscar').value = '';
    document.getElementById('f-desde').value = '';
    document.getElementById('f-hasta').value = '';
    cargarHistorial();
  };
  document.getElementById('f-exportar').onclick = exportarExcel;
}

let debounceTimer = null;
function debounce(fn, ms) {
  return (...args) => { clearTimeout(debounceTimer); debounceTimer = setTimeout(() => fn(...args), ms); };
}

async function cargarHistorial() {
  const list = document.getElementById('historial-list');
  list.innerHTML = '<div class="empty-state">Cargando…</div>';

  const proyectoId = document.getElementById('f-proyecto').value;
  const desde = document.getElementById('f-desde').value;
  const hasta = document.getElementById('f-hasta').value;
  const buscar = document.getElementById('f-buscar').value.trim();

  let query = supabaseClient
    .from('cotizador_historial')
    .select('*, cotizador_proyectos(nombre)')
    .order('created_at', { ascending: false })
    .limit(500);

  if (proyectoId) query = query.eq('proyecto_id', proyectoId);
  if (desde) query = query.gte('created_at', desde + 'T00:00:00');
  if (hasta) query = query.lte('created_at', hasta + 'T23:59:59');

  const { data, error } = await query;
  if (error) { list.innerHTML = `<div class="empty-state">No se pudo cargar el historial: ${error.message}</div>`; return; }

  let filas = data || [];
  if (buscar) {
    const q = buscar.toLowerCase();
    filas = filas.filter(f =>
      (f.cliente_nombre || '').toLowerCase().includes(q) ||
      (f.asesor_nombre || '').toLowerCase().includes(q));
  }

  HISTORIAL = filas;
  document.getElementById('historial-contador').textContent =
    filas.length === 1 ? '1 proforma encontrada' : `${filas.length} proformas encontradas`;

  if (!filas.length) { list.innerHTML = '<div class="empty-state">No hay proformas con estos filtros.</div>'; return; }

  list.innerHTML = `<table class="admin-table"><thead><tr>
    <th>Cliente</th><th>Proyecto</th><th>Unidad(es)</th><th>N.º proforma</th><th>Fecha</th>
    <th>Asesor</th><th>Precio final</th><th>Abono</th><th>Financiado</th><th>Cuota/mes</th>
  </tr></thead><tbody>${filas.map(filaHTML).join('')}</tbody></table>`;
}

function filaHTML(f) {
  const fecha = f.created_at ? new Date(f.created_at).toLocaleDateString('es-EC', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '—';
  const unidades = Array.isArray(f.unidades) ? f.unidades.map(u => u.nombre || u.codigo).join(', ') : '';
  return `<tr>
    <td>${f.cliente_nombre || '—'}${f.cliente_telefono ? `<br><span class="hint">${f.cliente_telefono}</span>` : ''}</td>
    <td>${f.cotizador_proyectos?.nombre || f.proyecto_id || '—'}</td>
    <td>${unidades || '—'}</td>
    <td><strong>${f.numero_proforma || '—'}</strong></td>
    <td>${fecha}</td>
    <td>${f.asesor_nombre || '—'}${f.asesor_telefono ? `<br><span class="hint">${f.asesor_telefono}</span>` : ''}</td>
    <td>${fmtMoney(f.precio_final)}</td>
    <td>${fmtMoney(f.abono_total)}</td>
    <td>${fmtMoney(f.monto_financiado)}</td>
    <td>${f.cuota_mensual ? fmtMoney(f.cuota_mensual) : '—'}</td>
  </tr>`;
}

// Excel (.xlsx) pensado para importar a un CRM (Zolutium u otro) y, a la
// vez, legible para revisar a simple vista en Excel/Sheets: encabezado fijo
// y en negrita, columnas con ancho propio, montos con formato de moneda,
// fecha como fecha real (ordenable) y filtro automático en el encabezado.
// El valor guardado en cada celda sigue siendo un número/fecha plano (no
// texto con '$' ni comas), así que cualquier importador de CRM lo sigue
// leyendo igual que antes — el formato es solo visual.
function num2(n) {
  return (n === null || n === undefined || n === '') ? '' : Math.round(Number(n) * 100) / 100;
}

const EXPORT_COLUMNAS = [
  { header: 'Cliente - Nombre completo', key: 'clienteNombre', width: 24 },
  { header: 'Cliente - Teléfono', key: 'clienteTelefono', width: 17 },
  { header: 'Cliente - Correo', key: 'clienteCorreo', width: 26 },
  { header: 'Proyecto', key: 'proyecto', width: 20 },
  { header: 'Unidad(es)', key: 'unidades', width: 22 },
  { header: 'N.º de proforma', key: 'numeroProforma', width: 15 },
  { header: 'Fecha', key: 'fecha', width: 12, numFmt: 'dd/mm/yyyy' },
  { header: 'Asesor - Nombre', key: 'asesorNombre', width: 20 },
  { header: 'Asesor - Teléfono', key: 'asesorTelefono', width: 17 },
  { header: 'Precio final (USD)', key: 'precioFinal', width: 15, numFmt: '"$"#,##0.00' },
  { header: 'Descuento (USD)', key: 'descuento', width: 14, numFmt: '"$"#,##0.00' },
  { header: 'Reserva (USD)', key: 'reserva', width: 13, numFmt: '"$"#,##0.00' },
  { header: 'Promesa (USD)', key: 'promesa', width: 13, numFmt: '"$"#,##0.00' },
  { header: 'Abono total antes de entrega (USD)', key: 'abonoTotal', width: 20, numFmt: '"$"#,##0.00' },
  { header: 'Monto financiado (USD)', key: 'montoFinanciado', width: 17, numFmt: '"$"#,##0.00' },
  { header: 'Tasa anual (%)', key: 'tasa', width: 13, numFmt: '0.00"%"' },
  { header: 'Plazo (años)', key: 'plazo', width: 12 },
  { header: 'N.º de cuotas', key: 'numCuotas', width: 12 },
  { header: 'Monto por cuota (USD)', key: 'montoCuota', width: 16, numFmt: '"$"#,##0.00' },
  { header: 'Cuota mensual estimada (USD)', key: 'cuotaMensual', width: 18, numFmt: '"$"#,##0.00' },
  { header: 'Notas', key: 'notas', width: 32 },
];

const EXPORT_COLOR_HEADER = 'FF565A41'; // --olive
const EXPORT_COLOR_ZEBRA = 'FFF8F6F0';  // --crema
const EXPORT_COLOR_BORDE = 'FFE4E0D2'; // --border

async function exportarExcel() {
  if (!HISTORIAL.length) { showToast('No hay filas para exportar con estos filtros.'); return; }
  if (typeof ExcelJS === 'undefined') {
    showToast('No se pudo cargar el generador de Excel (revisa tu conexión) e intenta de nuevo.');
    return;
  }

  const wb = new ExcelJS.Workbook();
  wb.creator = 'FORXA Inmobiliaria';
  wb.created = new Date();
  const ws = wb.addWorksheet('Historial', { views: [{ state: 'frozen', ySplit: 1 }] });
  ws.columns = EXPORT_COLUMNAS.map(c => ({ header: c.header, key: c.key, width: c.width }));

  HISTORIAL.forEach(f => {
    ws.addRow({
      clienteNombre: f.cliente_nombre || '',
      clienteTelefono: f.cliente_telefono || '',
      clienteCorreo: f.cliente_correo || '',
      proyecto: f.cotizador_proyectos?.nombre || f.proyecto_id || '',
      unidades: Array.isArray(f.unidades) ? f.unidades.map(u => u.nombre || u.codigo).join(' / ') : '',
      numeroProforma: f.numero_proforma || '',
      fecha: f.created_at ? new Date(f.created_at) : null,
      asesorNombre: f.asesor_nombre || '',
      asesorTelefono: f.asesor_telefono || '',
      precioFinal: num2(f.precio_final),
      descuento: num2(f.descuento),
      reserva: num2(f.reserva),
      promesa: num2(f.promesa),
      abonoTotal: num2(f.abono_total),
      montoFinanciado: num2(f.monto_financiado),
      tasa: num2(f.tasa_usada),
      plazo: f.plazo_anios_usado ?? '',
      numCuotas: f.numero_cuotas ?? '',
      montoCuota: num2(f.monto_cuota),
      cuotaMensual: num2(f.cuota_mensual),
      notas: (f.notas || '').replace(/\r?\n+/g, ' / ').trim(),
    });
  });

  // Formato numérico por columna (moneda/fecha/%) — no afecta el valor real.
  EXPORT_COLUMNAS.forEach(c => { if (c.numFmt) ws.getColumn(c.key).numFmt = c.numFmt; });

  // Encabezado: fondo oliva de marca, texto blanco en negrita, fijo al
  // desplazar (freeze pane) y con filtro automático para ordenar/filtrar.
  const header = ws.getRow(1);
  header.height = 26;
  header.eachCell(cell => {
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXPORT_COLOR_HEADER } };
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
  });
  ws.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: EXPORT_COLUMNAS.length } };

  // Filas: borde suave + franjas alternadas para que sea fácil seguir cada
  // fila con la vista, en vez de una grilla plana sin ningún tipo de guía.
  ws.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return;
    const zebra = rowNumber % 2 === 0;
    row.eachCell({ includeEmpty: true }, cell => {
      cell.border = {
        top: { style: 'thin', color: { argb: EXPORT_COLOR_BORDE } },
        bottom: { style: 'thin', color: { argb: EXPORT_COLOR_BORDE } },
        left: { style: 'thin', color: { argb: EXPORT_COLOR_BORDE } },
        right: { style: 'thin', color: { argb: EXPORT_COLOR_BORDE } },
      };
      if (zebra) cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXPORT_COLOR_ZEBRA } };
      cell.alignment = { ...cell.alignment, vertical: 'middle' };
    });
  });

  const buffer = await wb.xlsx.writeBuffer();
  const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = `historial-proformas-${new Date().toISOString().slice(0, 10)}.xlsx`;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

boot();
