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
  document.getElementById('f-exportar').onclick = exportarCSV;
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
    <th>N.º</th><th>Fecha</th><th>Proyecto</th><th>Asesor</th><th>Cliente</th>
    <th>Unidad(es)</th><th>Precio final</th><th>Abono</th><th>Financiado</th><th>Cuota/mes</th>
  </tr></thead><tbody>${filas.map(filaHTML).join('')}</tbody></table>`;
}

function filaHTML(f) {
  const fecha = f.created_at ? new Date(f.created_at).toLocaleDateString('es-EC', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '—';
  const unidades = Array.isArray(f.unidades) ? f.unidades.map(u => u.nombre || u.codigo).join(', ') : '';
  return `<tr>
    <td><strong>${f.numero_proforma || '—'}</strong></td>
    <td>${fecha}</td>
    <td>${f.cotizador_proyectos?.nombre || f.proyecto_id || '—'}</td>
    <td>${f.asesor_nombre || '—'}${f.asesor_telefono ? `<br><span class="hint">${f.asesor_telefono}</span>` : ''}</td>
    <td>${f.cliente_nombre || '—'}${f.cliente_telefono ? `<br><span class="hint">${f.cliente_telefono}</span>` : ''}</td>
    <td>${unidades || '—'}</td>
    <td>${fmtMoney(f.precio_final)}</td>
    <td>${fmtMoney(f.abono_total)}</td>
    <td>${fmtMoney(f.monto_financiado)}</td>
    <td>${f.cuota_mensual ? fmtMoney(f.cuota_mensual) : '—'}</td>
  </tr>`;
}

function exportarCSV() {
  if (!HISTORIAL.length) { showToast('No hay filas para exportar con estos filtros.'); return; }
  const headers = ['Número de proforma', 'Fecha', 'Proyecto', 'Asesor', 'Teléfono asesor',
    'Cliente', 'Teléfono cliente', 'Correo cliente', 'Unidad(es)', 'Precio final', 'Descuento',
    'Reserva', 'Promesa', 'Abono total', 'Monto financiado', 'Tasa anual (%)', 'Plazo (años)',
    'N.º cuotas', 'Monto por cuota', 'Cuota mensual estimada', 'Notas'];
  const rows = HISTORIAL.map(f => [
    f.numero_proforma || '', f.created_at ? new Date(f.created_at).toISOString().slice(0, 10) : '',
    f.cotizador_proyectos?.nombre || f.proyecto_id || '', f.asesor_nombre || '', f.asesor_telefono || '',
    f.cliente_nombre || '', f.cliente_telefono || '', f.cliente_correo || '',
    Array.isArray(f.unidades) ? f.unidades.map(u => u.nombre || u.codigo).join(' / ') : '',
    f.precio_final ?? '', f.descuento ?? '', f.reserva ?? '', f.promesa ?? '', f.abono_total ?? '',
    f.monto_financiado ?? '', f.tasa_usada ?? '', f.plazo_anios_usado ?? '',
    f.numero_cuotas ?? '', f.monto_cuota ?? '', f.cuota_mensual ?? '', f.notas || '',
  ]);
  descargarCSV(`historial-proformas-${new Date().toISOString().slice(0, 10)}.csv`, [headers, ...rows]);
}

boot();
