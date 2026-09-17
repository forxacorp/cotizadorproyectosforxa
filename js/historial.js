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
  await cargarTipologiasFiltro();
  wireFiltros();
  wireTabs();
  document.getElementById('dash-exportar').onclick = () => window.print();
  await cargarHistorial();
}

async function cargarProyectosFiltro() {
  const { data } = await supabaseClient.from('cotizador_proyectos').select('id, nombre').order('sort_order');
  PROYECTOS_FILTRO = data || [];
  const sel = document.getElementById('f-proyecto');
  sel.innerHTML = '<option value="">Todos los proyectos</option>' +
    PROYECTOS_FILTRO.map(p => `<option value="${p.id}">${p.nombre}</option>`).join('');
}

// Tipologías disponibles para filtrar/graficar: se leen una sola vez de todo
// el historial (no del resultado ya filtrado), para que la lista de opciones
// no se vaya reduciendo a medida que se aplican otros filtros.
async function cargarTipologiasFiltro() {
  const { data, error } = await supabaseClient.from('cotizador_historial').select('unidades').limit(2000);
  const sel = document.getElementById('f-tipologia');
  if (error || !data) return;
  const set = new Set();
  data.forEach(row => (Array.isArray(row.unidades) ? row.unidades : []).forEach(u => { if (u.tipo) set.add(u.tipo); }));
  const tipos = Array.from(set).sort((a, b) => a.localeCompare(b, 'es'));
  sel.innerHTML = '<option value="">Todas las tipologías</option>' +
    tipos.map(t => `<option value="${t}">${t}</option>`).join('');
}

function wireFiltros() {
  ['f-proyecto', 'f-tipologia', 'f-buscar', 'f-desde', 'f-hasta'].forEach(id => {
    document.getElementById(id).addEventListener('input', debounce(cargarHistorial, 300));
    document.getElementById(id).addEventListener('change', cargarHistorial);
  });
  document.getElementById('f-limpiar').onclick = () => {
    document.getElementById('f-proyecto').value = '';
    document.getElementById('f-tipologia').value = '';
    document.getElementById('f-buscar').value = '';
    document.getElementById('f-desde').value = '';
    document.getElementById('f-hasta').value = '';
    cargarHistorial();
  };
  document.getElementById('f-exportar').onclick = exportarExcel;
}

// Pestañas Tabla / Dashboard: ambas se calculan sobre el mismo HISTORIAL ya
// cargado y filtrado, así que cambiar de pestaña no vuelve a consultar la BD.
function wireTabs() {
  const btnTabla = document.getElementById('tab-btn-tabla');
  const btnDash = document.getElementById('tab-btn-dashboard');
  const vistaTabla = document.getElementById('vista-tabla');
  const vistaDash = document.getElementById('vista-dashboard');
  btnTabla.onclick = () => {
    vistaTabla.hidden = false; vistaDash.hidden = true;
    btnTabla.classList.add('active'); btnDash.classList.remove('active');
  };
  btnDash.onclick = () => {
    vistaTabla.hidden = true; vistaDash.hidden = false;
    btnDash.classList.add('active'); btnTabla.classList.remove('active');
  };
}

let debounceTimer = null;
function debounce(fn, ms) {
  return (...args) => { clearTimeout(debounceTimer); debounceTimer = setTimeout(() => fn(...args), ms); };
}

async function cargarHistorial() {
  const list = document.getElementById('historial-list');
  list.innerHTML = '<div class="empty-state">Cargando…</div>';

  const proyectoId = document.getElementById('f-proyecto').value;
  const tipologia = document.getElementById('f-tipologia').value;
  const desde = document.getElementById('f-desde').value;
  const hasta = document.getElementById('f-hasta').value;
  const buscar = document.getElementById('f-buscar').value.trim();

  let query = supabaseClient
    .from('cotizador_historial')
    .select('*, cotizador_proyectos(nombre, tagline, ubicacion)')
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
  // La tipología vive dentro del jsonb "unidades" de cada proforma (puede
  // traer varias unidades), así que el filtro se aplica en el cliente: se
  // queda la fila si AL MENOS UNA de sus unidades es de esa tipología.
  if (tipologia) {
    filas = filas.filter(f => Array.isArray(f.unidades) && f.unidades.some(u => u.tipo === tipologia));
  }

  HISTORIAL = filas;
  document.getElementById('historial-contador').textContent =
    filas.length === 1 ? '1 proforma encontrada' : `${filas.length} proformas encontradas`;

  if (!filas.length) {
    list.innerHTML = '<div class="empty-state">No hay proformas con estos filtros.</div>';
  } else {
    list.innerHTML = `<table class="admin-table"><thead><tr>
      <th>Cliente</th><th>Proyecto</th><th>Unidad(es)</th><th>N.º proforma</th><th>Fecha</th>
      <th>Asesor</th><th>Precio final</th><th>Abono</th><th>Financiado</th><th>Cuota/mes</th>
    </tr></thead><tbody>${filas.map(filaHTML).join('')}</tbody></table>`;
  }

  renderDashboard(filas);
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

// ============================================================================
// Dashboard de preferencias de compra: KPIs + 3 reportes (rango de
// presupuesto, ubicación preferida, tipología de mayor/menor demanda) sobre
// las proformas que cumplen los filtros de arriba. Se recalcula cada vez que
// cargarHistorial() trae datos nuevos — no hace consultas propias a la BD.
// Las "barras" son simples divs con % de ancho (no una librería de gráficos)
// para que impriman nítidas en el PDF sin depender de un CDN externo.
// ============================================================================

function promedio(arr) { return arr.length ? arr.reduce((a, b) => a + b, 0) / arr.length : 0; }
function numsValidos(filas, campo) {
  return filas.map(f => Number(f[campo])).filter(n => !isNaN(n) && n > 0);
}

function renderDashboard(filas) {
  document.getElementById('kpi-total').textContent = filas.length;
  const precios = numsValidos(filas, 'precio_final');
  const financiados = numsValidos(filas, 'monto_financiado');
  const cuotas = numsValidos(filas, 'cuota_mensual');
  document.getElementById('kpi-ticket').textContent = precios.length ? fmtMoney(promedio(precios)) : '—';
  document.getElementById('kpi-financiado').textContent = financiados.length ? fmtMoney(promedio(financiados)) : '—';
  document.getElementById('kpi-cuota').textContent = cuotas.length ? fmtMoney(promedio(cuotas)) + ' /mes' : '—';

  renderRangosPresupuesto(precios);
  renderUbicaciones(filas);
  renderTipologias(filas);
  renderFiltrosResumenImpresion();
}

// Renderiza una lista de barras horizontales (label / barra / conteo + %)
// dentro del contenedor containerId. entries = [{ label, count }].
function renderBars(containerId, entries) {
  const el = document.getElementById(containerId);
  if (!entries.length) { el.innerHTML = '<div class="empty-state">Sin datos para estos filtros.</div>'; return; }
  const max = Math.max(...entries.map(e => e.count));
  const total = entries.reduce((a, b) => a + b.count, 0);
  el.innerHTML = entries.map(e => `
    <div class="dash-bar-row">
      <div class="dash-bar-label">${e.label}</div>
      <div class="dash-bar-track"><div class="dash-bar-fill" style="width:${max ? (e.count / max * 100) : 0}%"></div></div>
      <div class="dash-bar-count"><strong>${e.count}</strong> (${total ? Math.round(e.count / total * 100) : 0}%)</div>
    </div>`).join('');
}

// Divide el precio final en 5 franjas iguales entre el mínimo y el máximo de
// las proformas filtradas (en vez de rangos fijos en USD) para que el
// reporte tenga sentido tanto en proyectos de $80k como en uno de $300k.
function renderRangosPresupuesto(precios) {
  if (!precios.length) { renderBars('dash-rangos', []); return; }
  const min = Math.min(...precios), max = Math.max(...precios);
  const NUM_BUCKETS = 5;
  let buckets;
  if (min === max) {
    buckets = [{ label: fmtMoney(min), count: precios.length }];
  } else {
    const step = (max - min) / NUM_BUCKETS;
    buckets = Array.from({ length: NUM_BUCKETS }, (_, i) => ({
      from: min + step * i,
      to: i === NUM_BUCKETS - 1 ? max : min + step * (i + 1),
      count: 0,
    }));
    precios.forEach(p => {
      let idx = Math.floor((p - min) / step);
      if (idx >= NUM_BUCKETS) idx = NUM_BUCKETS - 1;
      if (idx < 0) idx = 0;
      buckets[idx].count++;
    });
    buckets.forEach(b => { b.label = `${fmtMoney(b.from)} – ${fmtMoney(b.to)}`; });
  }
  renderBars('dash-rangos', buckets);
}

// "Ubicación preferida": se toma el tagline del proyecto (trae el sector,
// ej. "Sector Antenas de Misicata, Cuenca") y, si no existe, la ubicación
// general o el nombre del proyecto como respaldo.
function renderUbicaciones(filas) {
  const counts = {};
  filas.forEach(f => {
    const proy = f.cotizador_proyectos;
    const label = proy?.tagline || proy?.ubicacion || proy?.nombre || f.proyecto_id || 'Sin proyecto';
    counts[label] = (counts[label] || 0) + 1;
  });
  const entries = Object.entries(counts).map(([label, count]) => ({ label, count })).sort((a, b) => b.count - a.count);
  renderBars('dash-ubicaciones', entries);
}

// Tipología de mayor/menor demanda: cuenta cuántas veces se cotizó cada
// "tipo" de unidad (Casa Tipo 1, Departamento, Suite, Local, Lote…). Una
// proforma con varias unidades cuenta una vez por cada tipo que incluya.
// Los históricos generados antes de esta actualización no traen "tipo"
// guardado y quedan agrupados en "Sin especificar".
function renderTipologias(filas) {
  const counts = {};
  filas.forEach(f => (Array.isArray(f.unidades) ? f.unidades : []).forEach(u => {
    const t = u.tipo || 'Sin especificar';
    counts[t] = (counts[t] || 0) + 1;
  }));
  const entries = Object.entries(counts).map(([label, count]) => ({ label, count })).sort((a, b) => b.count - a.count);
  renderBars('dash-tipologias', entries);

  const resumen = document.getElementById('dash-tipologias-resumen');
  if (entries.length >= 2) {
    resumen.textContent = `Mayor demanda: ${entries[0].label} (${entries[0].count}) · Menor demanda: ${entries[entries.length - 1].label} (${entries[entries.length - 1].count})`;
  } else if (entries.length === 1) {
    resumen.textContent = `Única tipología cotizada en estos filtros: ${entries[0].label}`;
  } else {
    resumen.textContent = 'Cuántas veces se cotizó cada tipo de unidad.';
  }
}

// Encabezado que solo se ve al exportar a PDF: qué filtros estaban activos y
// cuándo se generó, para que el PDF tenga contexto aunque se comparta suelto.
function renderFiltrosResumenImpresion() {
  const el = document.getElementById('dash-print-filtros');
  if (!el) return;
  const proyectoSel = document.getElementById('f-proyecto');
  const proyectoTxt = proyectoSel.value ? proyectoSel.selectedOptions[0].textContent : 'Todos los proyectos';
  const tipologiaSel = document.getElementById('f-tipologia');
  const tipologiaTxt = tipologiaSel.value || 'Todas las tipologías';
  const desde = document.getElementById('f-desde').value;
  const hasta = document.getElementById('f-hasta').value;
  const buscar = document.getElementById('f-buscar').value.trim();
  const partes = [
    `Proyecto: ${proyectoTxt}`,
    `Tipología: ${tipologiaTxt}`,
    desde ? `Desde: ${desde}` : null,
    hasta ? `Hasta: ${hasta}` : null,
    buscar ? `Búsqueda: "${buscar}"` : null,
    `Generado: ${new Date().toLocaleDateString('es-EC', { day: '2-digit', month: '2-digit', year: 'numeric' })}`,
  ].filter(Boolean);
  el.textContent = partes.join(' · ');
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
