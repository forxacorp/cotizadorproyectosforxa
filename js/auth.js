// Guardia de sesión compartida por index.html, cotizador.html y admin.html.
// TODO el cotizador requiere login (una cuenta por asesor, creada a mano en
// Supabase → Authentication → Users, igual que en forxa-portafolio).

const CotizadorAuth = (() => {
  let currentUser = null;
  let isAdmin = false;

  async function init() {
    const { data: { session } } = await supabaseClient.auth.getSession();
    currentUser = session ? session.user : null;
    if (currentUser) await checkAdmin();
    return currentUser;
  }

  async function checkAdmin() {
    if (!currentUser) { isAdmin = false; return false; }
    const { data, error } = await supabaseClient
      .from('cotizador_admins')
      .select('user_id')
      .eq('user_id', currentUser.id)
      .maybeSingle();
    isAdmin = !error && !!data;
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

  async function requireAdmin() {
    const user = await requireSession();
    if (!user) return null;
    if (!isAdmin) {
      alert('Tu cuenta no tiene permisos de administrador. Pide a un administrador que te agregue en cotizador_admins.');
      window.location.href = 'index.html';
      return null;
    }
    return user;
  }

  function getUser() { return currentUser; }
  function getIsAdmin() { return isAdmin; }

  return { init, login, logout, requireSession, requireAdmin, getUser, getIsAdmin, checkAdmin };
})();
