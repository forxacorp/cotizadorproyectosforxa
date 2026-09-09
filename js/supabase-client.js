// Mismo proyecto de Supabase que ya usa forxa-portafolio (jjdybtskzqpybrltdnss).
// El cotizador vive en tablas separadas (prefijo cotizador_) y su propio bucket
// (cotizador-media), así que comparte credenciales sin chocar con "projects"/"covers".
const SUPABASE_URL = "https://jjdybtskzqpybrltdnss.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqZHlidHNrenFweWJybHRkbnNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5NjI5NDEsImV4cCI6MjEwNDUzODk0MX0.cR_0EeIgcPOqy37Ho9GYt7wpbuQi46epfiYI_m_hjok";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
