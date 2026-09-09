# FORXA — Cotizador interno

Herramienta interna para generar proformas en PDF de los 4 proyectos de FORXA
(Mirador de Misicata, AURA, Álabes y Portón del Valle). Sitio estático (sin
build), con Supabase como backend: base de datos + login + fotos.

Vive en el **mismo proyecto de Supabase** que tu web de portafolio público
(`jjdybtskzqpybrltdnss`), pero en tablas separadas con prefijo `cotizador_` y
su propio bucket de Storage (`cotizador-media`) — nada choca con `projects`
ni con `covers`.

A diferencia del portafolio, **todo este sitio requiere iniciar sesión**
(no solo el panel de admin): es material interno, no debe quedar público.

```
├── index.html            → login + selección de proyecto (portadas)
├── cotizador.html         → selección de unidad(es) + proforma
├── admin.html              → panel de administración (solo admins)
├── css/styles.css
├── js/
│   ├── supabase-client.js   → URL + anon key (misma que el portafolio)
│   ├── auth.js                → login/logout + verificación de admin
│   ├── utils.js                 → formato de moneda, cuotas, URLs firmadas
│   ├── cotizador.js               → motor genérico (sirve para los 4 proyectos)
│   └── admin.js                    → CRUD de proyectos y unidades
├── supabase/
│   ├── schema.sql        → tablas, RLS, bucket privado
│   └── seed_data.sql     → los 4 proyectos + ~120 unidades ya cargadas
├── fotos/                 → fichas extraídas de los brochures (para subir una vez)
└── scripts/bulk_upload_fotos.mjs → sube fotos/ a Supabase Storage de un tirón
```

## Paso 1 — Crear las tablas en Supabase

1. Entra a tu proyecto en [supabase.com](https://supabase.com/dashboard) →
   **SQL Editor** → **New query**.
2. Pega todo `supabase/schema.sql` y dale **Run**.
3. En una query nueva, pega todo `supabase/seed_data.sql` y dale **Run**.
   Esto carga los 4 proyectos y las unidades (precios y estados según tus
   Excel más recientes, con las correcciones ya aplicadas — ver "Notas de los
   datos" abajo).

## Paso 2 — Crear tus usuarios (una cuenta por asesor)

1. **Authentication → Users → Add user** — crea una cuenta por cada asesor
   que vaya a usar el cotizador (correo + contraseña).
2. **Authentication → Providers → Email** → desactiva "Allow new users to
   sign up", igual que en el portafolio.
3. Para que TÚ tengas acceso al panel de administración, corre en el SQL
   Editor (reemplaza el correo):
   ```sql
   insert into public.cotizador_admins (user_id, nombre)
   select id, 'Pablo Calle' from auth.users where email = 'tu-correo@forxa.com'
   on conflict (user_id) do nothing;
   ```
   Repite esa consulta (con otro correo) por cada persona que también deba
   administrar proyectos/unidades — el resto de asesores puede cotizar sin
   estar en esta tabla.

## Paso 3 — Subir las fotos ya extraídas (una sola vez)

La carpeta `fotos/` trae las fichas que ya extraje de tus brochures: 24 de
Misicata (11 casas + 2 suites, planta baja/alta), 22 de AURA y 34 de Álabes.
Para subirlas todas de un tirón:

```bash
cd forxa-cotizador
npm install @supabase/supabase-js
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key node scripts/bulk_upload_fotos.mjs
```

La `service_role key` la sacas de **Project Settings → API → service_role**
(es secreta —úsala solo en tu terminal, nunca la pegues en el código ni la
subas a GitHub). El script sube cada imagen al bucket y actualiza la unidad
correspondiente automáticamente.

**Pendiente:** todavía no extraje las fotos generales de cada proyecto
(ubicación, renders, cronograma) ni las de Portón del Valle (ese proyecto no
tiene ficha por lote, solo brochure general) — puedo hacerlo en una próxima
vuelta si quieres esas imágenes también en el sitio.

## Paso 4 — Probar en tu computadora (opcional)

```bash
cd forxa-cotizador
python3 -m http.server 8080
```

Abre `http://localhost:8080` (te pedirá login) y, si tu usuario es admin,
`http://localhost:8080/admin.html`.

## Paso 5 — Subir a GitHub y desplegar en Netlify

Igual que hiciste con el portafolio:

```bash
cd forxa-cotizador
git init && git add . && git commit -m "Cotizador interno FORXA"
git branch -M main
git remote add origin https://github.com/<tu-usuario>/<tu-repo>.git
git push -u origin main
```

Luego en [app.netlify.com](https://app.netlify.com) → **Add new site →
Import an existing project** → conecta el repo → Deploy. `netlify.toml` ya
trae `noindex` en todo el sitio para que buscadores no lo indexen.

**Importante:** este repositorio no debe ser público en GitHub (a diferencia
del portafolio) porque, aunque los datos están protegidos por RLS, es mejor
que el código de una herramienta interna no quede a la vista de cualquiera.
Usa un repo privado.

## Uso diario

- **Asesores**: entran a `tudominio.com`, inician sesión, eligen el
  proyecto, seleccionan la(s) unidad(es), llenan los datos del cliente y
  generan la proforma (imprimir/guardar como PDF, igual que antes).
- **Administradores**: además ven el enlace "Administrar" — ahí editan
  precio/estado/fotos de cualquier unidad al instante, y pueden agregar un
  proyecto nuevo sin tocar código (solo configuran su fórmula de
  financiamiento: reserva %, promesa %, tasa y plazo).

## Notas de los datos cargados (léelo antes de poner esto en manos del equipo)

- **Casa 9 (Misicata)**: marcada como `no_disponible` por indicación tuya.
- **Álabes**: corregí el error de captura de la unidad **C12** (el estado
  "reservado" estaba escrito dentro de la columna del nombre en el Excel en
  vez de en la columna de estado) — ya quedó como `reservado`.
- **Álabes — pendiente de tu confirmación**: el brochure PDF marca **Local
  01, Local 02, Suite B8 y Suite C9 como VENDIDOS**, pero tu Excel más
  reciente no los tenía así (Local 01 disponible, Local 02 reservado, B8
  disponible, C9 reservado). Como pediste basarme en el Excel, los cargué
  con el estado del Excel — pero si esas 4 unidades ya se vendieron de
  verdad, corrígelas desde el panel de administración antes de que el equipo
  empiece a cotizar con esto.
- **AURA**: ahora están las 22 unidades del edificio (no solo las 10 que
  tenía el sistema anterior), con las 12 ya vendidas marcadas como tal — así
  el historial queda completo aunque solo se puedan cotizar las 10
  disponibles.
- **Misicata**: se agregaron las 13 unidades reales del proyecto (11 casas +
  2 suites) con sus specs técnicas completas (terreno, construcción,
  dormitorios, baños, parqueos) sacadas del brochure. Antes solo había 6
  cargadas.

## Seguridad

- La `anon key` en `js/supabase-client.js` es pública por diseño — lo que
  protege los datos son las políticas de Row Level Security en
  `supabase/schema.sql` (todo requiere sesión iniciada; solo admins
  escriben).
- Nunca publiques la `service_role key` en este repositorio, en Netlify, ni
  en ningún archivo del sitio — solo se usa una vez, desde tu terminal, para
  `scripts/bulk_upload_fotos.mjs`.
