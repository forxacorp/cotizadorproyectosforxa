// Guardia de sesión compartida por index.html, cotizador.html y admin.html.
// TODO el cotizador requiere login (una cuenta por asesor, creada a mano en
// Supabase → Authentication → Users, igual que en forxa-portafolio).

const CotizadorAuth = (() => {
  let currentUser = null;
  let isAdmin = false;
  let puedeVerHistorial = false;

  async function init() {
    const { data: { session } } = await supabaseClient.auth.getSession();
    currentUser = session ? session.user : null;
    if (currentUser) await checkAdmin();
    return currentUser;
  }

  // Una sola consulta a cotizador_admins resuelve tanto "es admin" (¿existe
  // la fila?) como "puede ver el historial" (columna aparte) — son permisos
  // independientes: alguien puede administrar proyectos sin ver el
  // historial de clientes, o viceversa.
  async function checkAdmin() {
    if (!currentUser) { isAdmin = false; puedeVerHistorial = false; return false; }
    const { data, error } = await supabaseClient
      .from('cotizador_admins')
      .select('user_id, puede_ver_historial')
      .eq('user_id', currentUser.id)
      .maybeSingle();
    isAdmin = !error && !!data;
    puedeVerHistorial = !error && !!data && !!data.puede_ver_historial;
    return isAdmin;
  }

  async function login(email, password) {
    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) throw error;
    currentUser = data.user;
    await checkAdmin();
    return currentUser;
  }

  async function logout() {
    await supabaseClient.auth.signOut();
    currentUser = null;
    isAdmin = false;
  }

  // Redirige a index.html si no hay sesión. Devuelve el usuario si la hay.
  async function requireSession() {
    const user = await init();
    if (!user) {
      window.location.href = 'index.html';
      return null;
    }
    return user;
  }

  // A diferencia de requireSession(), NO redirige si el usuario no es admin:
  // admin.html decide cómo mostrar el estado "sin permisos" (ver admin.js),
  // porque un alert()+redirect deja a la persona sin entender qué pasó.
  async function requireAdmin() {
    const user = await requireSession();
    if (!user) return null;
    return { user, isAdmin };
  }

  // Igual que requireAdmin(): no redirige si no tiene permiso, para poder
  // mostrar un aviso en pantalla en vez de un alert()+redirect confuso.
  async function requireHistorialAccess() {
    const user = await requireSession();
    if (!user) return null;
    return { user, puedeVerHistorial };
  }

  function getUser() { return currentUser; }
  function getIsAdmin() { return isAdmin; }
  function getPuedeVerHistorial() { return puedeVerHistorial; }

  return {
    init, login, logout, requireSession, requireAdmin, requireHistorialAccess,
    getUser, getIsAdmin, getPuedeVerHistorial, checkAdmin,
  };
})();
