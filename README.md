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

## Si ya tenías el sitio desplegado (actualización de diseño/errores)

Si ya corriste `schema.sql` y `seed_data.sql` en Supabase y el sitio ya está
en Netlify (`cotizadorproyectosforxa.netlify.app`), **no hace falta repetir
esos pasos.** Para aplicar esta entrega:

1. **Reemplaza los archivos** de tu repositorio con los de este comprimido
   (todo excepto `supabase/` y `fotos/`, que son iguales o solo agregan
   archivos nuevos) y haz `git add . && git commit -m "..." && git push` —
   Netlify vuelve a desplegar solo.
2. **Agrega el logo de cada proyecto** en `assets/logos/` (ver "Rediseño de
   la proforma" abajo) — sin esto, la proforma sigue funcionando pero solo
   muestra el logo de FORXA en el membrete, sin el del proyecto.
3. **Corre `supabase/update_colores_proyecto.sql`** una vez en el SQL Editor
   de Supabase, si todavía no lo hiciste en una entrega anterior. Le da a
   cada proyecto (Misicata, AURA, Álabes, Portón) un color distinto y propio
   para su tarjeta/banner — no afecta a la proforma, que ahora usa siempre
   el azul de marca FORXA (ver abajo).
4. **Si las portadas de los proyectos o las fichas de las unidades todavía no
   se ven**, es porque `scripts/bulk_upload_fotos.mjs` (Paso 3 abajo)
   todavía no se ha corrido contra tu proyecto de Supabase — no es un error
   de código, es que esas imágenes viven en Supabase Storage y hay que
   subirlas una vez con tu `service_role key`. Corre ese paso y aparecerán.

Esta entrega **no cambia nada en Supabase** (ni tablas ni columnas nuevas) —
solo son archivos del sitio (HTML/CSS/JS) más los 4 logos que debes agregar
en `assets/logos/`.

El resto de este README describe el proceso completo desde cero (útil si
alguna vez necesitas volver a montarlo).

## Rediseño de la proforma (documento de cotización)

La proforma que se genera al hacer clic en "Generar proforma" se rediseñó
por completo, con inspiración en una factura/invoice profesional:

- **Membrete con dos logos**: el de FORXA (`assets/logo.png`, ya existente)
  y el del proyecto correspondiente. Para que aparezca el segundo, agrega un
  archivo por proyecto en `assets/logos/`, con el nombre exacto (en
  minúsculas, sin espacios) igual al slug del proyecto:
  - `assets/logos/misicata.png`
  - `assets/logos/aura.png`
  - `assets/logos/alabes.png`
  - `assets/logos/porton.png`
  Si el proyecto todavía no tiene su logo en esa carpeta, el membrete
  simplemente no lo muestra (no rompe nada) — solo se ve el de FORXA.
- **Colores**: toda la proforma usa el azul de marca de FORXA (el mismo
  degradado del login y la portada) para el título, los montos destacados,
  la cuota mensual y los acentos — es fijo para los 4 proyectos, no cambia
  según el color propio de cada uno (ese color de proyecto sigue usándose
  en la tarjeta y el banner del cotizador, solo no en la proforma).
- **Tipografía**: se agregó **Plus Jakarta Sans**, una sans-serif moderna,
  para todo el documento (antes usaba la misma fuente decorativa del resto
  del sitio, que en un documento de precios/números se leía menos limpia).
  Este cambio de tipografía es **solo dentro de la proforma** — el resto del
  sitio (login, portada, panel) sigue con la identidad de siempre.
- **Datos del asesor**: nueva tarjeta "Datos del asesor" en el formulario,
  con nombre y teléfono como campos obligatorios y rellenables (ya no se usa
  el correo de la cuenta con la que se inició sesión) — el navegador los
  recuerda para la próxima vez (con `localStorage`, ese dato nunca sale del
  computador del asesor). Ambos aparecen en el membrete y en el pie de la
  proforma.
- **Dos páginas al imprimir**: la página 1 trae membrete, datos de
  asesor/cliente, desglose de precio por unidad y pie de página; la página 2
  (solo si la unidad tiene foto cargada) trae las fichas fotográficas de
  cada unidad cotizada, separadas con salto de página al imprimir/guardar
  como PDF.
- **Badge de Netlify**: se le dio más aire (padding) a la parte inferior de
  las páginas y se ocultó por CSS en la vista de impresión, para que no
  quede tapando contenido ni apareciendo en el PDF final.

```
├── index.html            → login + selección de proyecto (portadas)
├── cotizador.html         → selección de unidad(es) + proforma
├── admin.html              → panel de administración (solo admins)
├── css/styles.css
├── assets/
│   ├── logo.png            → logo FORXA (ya existente)
│   ├── logo-white.png       → logo FORXA en blanco, para el banner de la portada
│   └── logos/                 → (nuevo) logo de cada proyecto, para el membrete de la proforma
│       ├── misicata.png
│       ├── aura.png
│       ├── alabes.png
│       └── porton.png
├── js/
│   ├── supabase-client.js   → URL + anon key (misma que el portafolio)
│   ├── auth.js                → login/logout + verificación de admin
│   ├── utils.js                 → formato de moneda, cuotas, URLs firmadas
│   ├── cotizador.js               → motor genérico (sirve para los 4 proyectos)
│   └── admin.js                    → CRUD de proyectos y unidades
├── supabase/
│   ├── schema.sql                    → tablas, RLS, bucket privado
│   ├── seed_data.sql                 → los 4 proyectos + ~120 unidades ya cargadas
│   └── update_colores_proyecto.sql   → (nuevo) da un color propio a cada proyecto ya existente
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
Misicata (11 casas + 2 suites, planta baja/alta), 22 de AURA y 34 de Álabes,
más las 4 portadas de proyecto.

**La forma más simple** — corre un solo script, que te va a pedir tu
`service_role key` una vez y hace todo lo demás solo (revisa que tengas
Node.js, instala lo que falta, y sube las 84 imágenes):

- **Mac / Linux**, en Terminal:
  ```bash
  cd forxa-cotizador
  bash scripts/subir_fotos.sh
  ```
- **Windows**: doble clic en `scripts\subir_fotos.bat` (o desde cmd:
  `scripts\subir_fotos.bat`).

La `service_role key` la sacas de **Project Settings → API → service_role**
(es secreta —el script no la guarda en ningún archivo, solo la usa mientras
corre). Si prefieres correrlo a mano en vez del script, el comando de fondo
es:
```bash
npm install @supabase/supabase-js
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key node scripts/bulk_upload_fotos.mjs
```

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

## Notas de esta actualización (corrección de errores reportados)

- **Login que se quedaba abierto después de entrar**: era un bug de CSS — el
  atributo `hidden` de HTML lo estaba ganando una regla `display:flex` más
  específica. Se corrigió con una regla global en `css/styles.css` que hace
  que `hidden` siempre gane, así que ya no debería repetirse en ninguna
  pantalla (login, selección de proyecto, formulario/proforma).
- **No se podía entrar al administrador**: mostraba una alerta bloqueante de
  "sin permisos" y no dejaba ver nada más. Ahora, si tu cuenta no está en
  `cotizador_admins`, la página te lo explica en pantalla (sin bloquear) y te
  da el SQL exacto para agregarte.
- **Alertas bloqueantes (`alert`/`confirm`)**: reemplazadas por avisos y una
  confirmación en pantalla que no congelan la página.
- **Diseño poco de marca**: la pantalla de login y la portada de selección de
  proyecto ahora usan un fondo oscuro con el logo de FORXA en grande; cada
  proyecto tiene su propio color (antes los 4 compartían casi el mismo tono
  oliva) que se ve en su tarjeta, en un banner al entrar a cotizar y en los
  botones/precios de esa página — el logo de FORXA se mantiene fijo en el
  encabezado de todas las páginas.
- **Botones de solo ícono en el panel** (editar, activar/desactivar, guardar,
  eliminar) ahora tienen `aria-label` para lectores de pantalla.
- **Portadas y fichas que no se veían**: no es un bug de código — esas
  imágenes viven en Supabase Storage y hace falta correr
  `scripts/bulk_upload_fotos.mjs` una vez (Paso 3) para subirlas y que cada
  unidad/proyecto quede enlazado a su foto.

## Seguridad

- La `anon key` en `js/supabase-client.js` es pública por diseño — lo que
  protege los datos son las políticas de Row Level Security en
  `supabase/schema.sql` (todo requiere sesión iniciada; solo admins
  escriben).
- Nunca publiques la `service_role key` en este repositorio, en Netlify, ni
  en ningún archivo del sitio — solo se usa una vez, desde tu terminal, para
  `scripts/bulk_upload_fotos.mjs`.
