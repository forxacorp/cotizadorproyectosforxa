# FORXA — Cotizador interno

Herramienta interna para generar proformas en PDF de los 5 proyectos de FORXA
(Mirador de Misicata, AURA, Álabes, Portón del Valle y Arcus Suites & Lofts).
Sitio estático (sin build), con Supabase como backend: base de datos + login
+ fotos.

Vive en el **mismo proyecto de Supabase** que tu web de portafolio público
(`jjdybtskzqpybrltdnss`), pero en tablas separadas con prefijo `cotizador_` y
su propio bucket de Storage (`cotizador-media`) — nada choca con `projects`
ni con `covers`.

A diferencia del portafolio, **todo este sitio requiere iniciar sesión**
(no solo el panel de admin): es material interno, no debe quedar público.

## Arcus Suites & Lofts + corrección de Portón del Valle (esta entrega)

### Arcus Suites & Lofts — proyecto nuevo (5º del cotizador)

Corre `supabase/update_arcus.sql` una vez en el SQL Editor — **obligatorio**,
crea el proyecto y sus 77 unidades.

- **Fuente de datos**: `lista_de_precios_ARCUS__2___1_.xlsx` (no el sitio
  `arcus-landing_final.zip` que también mandaste — ese es un sitio público
  aparte, con su propio Supabase distinto al del cotizador; de ahí solo tomé
  el logo y el color de marca, nunca disponibilidad ni precios).
- **77 unidades cargadas**: 7 locales comerciales, 6 islas comerciales, 41
  lofts y 23 suites. **Omití el departamento 603** como pediste — es el
  único del edificio y en el Excel ya figura "Vendido".
- **Política de compra: copiada de AURA, tal cual pediste** — reserva 2% +
  promesa 8% + cuotas hasta la entrega (30% de abono), 70% restante
  financiado a 10.5%/20 años (el asesor edita tasa y plazo en cada
  cotización). `permite_descuento_manual = false`, igual que AURA.
- **Pendiente, no lo hice porque no lo pediste**: el Excel trae una segunda
  hoja "política comercial" con descuentos automáticos por categoría
  (Signature 3%, Classic 4%, Essential 5% — cada unidad ya quedó etiquetada
  con su categoría en el campo "planta", ej. "Piso 3 · Signature"). El
  cotizador hoy solo soporta un descuento manual libre, no reglas
  automáticas por categoría — si quieres que el sistema lo sugiera solo,
  es un cambio aparte.
- **Fotos**: las 77 fichas técnicas del brochure (`img/fichas/` del zip) ya
  están renombradas al código de cada unidad y listas para subir — ver
  "Fotos de Arcus" más abajo. El logo (`assets/logos/arcus.png`) ya viene
  incluido en este zip, no hace falta subirlo aparte.
- **Sin foto de portada a propósito**: las fotos exteriores/interiores del
  brochure (`img/exterior/`, `img/interior/` del zip que ya tienes) traen el
  logo y una etiqueta tipo "VISTA FRONTAL" o "SALA" incrustados en la propia
  imagen — usarlas tal cual duplicaría el nombre del proyecto (una vez de la
  imagen, otra vez del texto que pone el sitio encima) y dejaría una
  etiqueta suelta sin sentido en la tarjeta. Por eso Arcus usa el degradé de
  su color de marca (café/chocolate) como portada, igual que hacen los
  proyectos sin foto todavía. Si me pasas una toma sin texto incrustado, o
  quieres que recorte una de las que ya tienes, la agrego.

#### Fotos de Arcus — cómo subirlas

1. Descomprime `fotos_arcus.zip` (aparte, en esta entrega) dentro de tu
   carpeta `fotos/`, de forma que quede `fotos/arcus/001.jpg`,
   `fotos/arcus/102.jpg`, etc. (77 archivos, ya nombrados con el código
   exacto de cada unidad — nada que renombrar a mano).
2. Corre `scripts/bulk_upload_fotos.mjs` (Paso 3 más abajo) igual que la
   primera vez — sube también lo nuevo de Arcus sin tocar lo que ya subiste
   de los otros 4 proyectos.

### Portón del Valle — corregí un bug de origen (no era falta de datos)

Corre `supabase/update_porton_lotes.sql` una vez en el SQL Editor —
**obligatorio**, o Portón del Valle sigue mostrando el grid de unidades
vacío en el cotizador.

Los 33 lotes de Portón del Valle **ya estaban cargados** desde la primera
entrega (tabla `cotizador_inventario_extra`), pero el proyecto tiene
`tipo_financiamiento = 'pago_directo'`, y el código del cotizador solo
consulta esa tabla cuando el proyecto es de tipo `'lote'` — nunca coincidían,
así que esos 33 lotes nunca llegaron a mostrarse, ni en el cotizador ni en
Administrar. La imagen `Mesa_de_trabajo` que mandaste con la disponibilidad
resultó ser exactamente la misma información ya cargada (comparé los 31
lotes disponibles uno por uno: cero diferencias en área o precio), así que
no hizo falta recapturar nada — el script solo mueve esos 33 lotes a la
tabla que sí se consulta, conservando la política de pago directo que ya
estaba pensada para Portón ("ya está listo para entrega": abono sugerido
30% + resto financiable).

**Corrección real que sí encontré**: el lote **A82** figuraba disponible en
la base, pero no aparece en tu lista de disponibles más reciente. Lo marqué
`no_disponible` con una nota — revísalo desde **Administrar → Portón del
Valle**, columna **Nota** (nueva en esta entrega, antes el panel no
mostraba ese campo para ninguna unidad).

## Motivo de compra, forma de pago y dashboard ampliado (entrega anterior)

**Qué cambia y por qué corre en Supabase:** agrega 2 columnas a
`cotizador_historial`, así que necesita `supabase/update_motivo_forma_pago.sql`
además de `supabase/update_asesores.sql` de la entrega anterior si todavía no
lo corriste. Ambos son igual de seguros que los anteriores (se pueden correr
más de una vez).

- **Motivo de compra**: en "Datos del cliente" hay un campo nuevo — Vivienda
  o Inversión. Queda guardado en el historial para el dashboard; no se
  imprime en la proforma (es un dato interno de FORXA, no algo que el
  cliente necesite ver escrito en su cotización).
- **Forma de pago**: también en "Datos del cliente" — Financiamiento o
  Contado. Con **Contado**, los campos de interés/plazo del financiamiento
  se ocultan automáticamente (para cualquiera de los 5 tipos de proyecto:
  cuotas hasta entrega, pago directo, VIP, simulación o lote) y la proforma
  deja de mostrar tasa/cuota mensual — en su lugar aparece "Saldo a cancelar
  de contado" con el mismo monto que antes se financiaba. **Los montos de
  reserva/promesa/abonos no cambian** — lo único que cambia es que ese saldo
  se paga directo en vez de a través de un banco.
- **Dashboard de preferencias, ampliado y rediseñado** (dentro de
  Historial): además de rango de presupuesto y tipología (ya existían), el
  dashboard ahora muestra:
  - **Distribución de cotizaciones por proyecto** y **proyecto más
    consultado** (gráfico de dona).
  - **Tipo de inmueble más cotizado**, con mayor/menor demanda (dona).
  - **Dormitorios preferidos** (1, 2, 3, 4+).
  - **Metraje promedio cotizado** (m² útiles/construcción, o terreno en el
    caso de lotes).
  - **Precio promedio por proyecto** (ticket de compra, no solo el general).
  - **Demanda por unidad**: qué unidades específicas se cotizan más (top 8).
  - **Demanda por período**: proformas por mes, en línea de tiempo.
  - **Motivo de compra** y **Forma de pago**, con los datos nuevos de
    arriba.
  - Los gráficos (dona/barras/línea) son SVG propio, no una librería externa
    — imprimen nítidos en "Exportar a PDF" sin depender de que el navegador
    tenga activado "Gráficos de fondo" (esa opción solo hace falta para que
    se vea el color de fondo de las tarjetas KPI, no para los gráficos en
    sí).
  - **Dato importante**: motivo de compra, forma de pago, dormitorios y
    metraje solo están disponibles para proformas generadas *después* de
    esta actualización — las anteriores no tienen esos datos guardados y
    simplemente no cuentan en esos reportes (no aparecen como "ceros" ni
    distorsionan los promedios).

## Asesores con autocompletado y dashboard de preferencias (entrega anterior)

**Qué cambia y por qué corre en Supabase:** agrega una tabla nueva
(`cotizador_asesores`), así que necesita `supabase/update_asesores.sql` — es
igual de seguro que las anteriores (usa `if not exists`/`on conflict`, se
puede correr más de una vez).

- **Datos del asesor con autocompletado**: cuando Empresa = "FORXA
  Inmobiliaria", el formulario ya no pide escribir nombre y teléfono a mano
  — aparece un desplegable con los asesores de FORXA (precargado con
  `Contactos_Asesores.xlsx`: 12 personas) y, al elegir un nombre, el
  teléfono se rellena solo. Si alguien no está en la lista todavía, la
  opción **"Otro / no está en la lista"** muestra los campos manuales de
  siempre, para no bloquear a nadie. Con Empresa = "Independiente" el
  formulario sigue siendo 100% manual, como antes.
  - El directorio se administra desde **Administrar → Asesores** (agregar,
    editar teléfono/correo, o desactivar a alguien que ya no trabaja con
    FORXA) — no requiere tocar código ni volver a correr SQL.
  - Es solo un directorio de contacto: **no crea cuentas de acceso** al
    cotizador (eso se sigue haciendo en Supabase → Authentication → Users,
    como siempre).
- **Dashboard de preferencias de compra (dentro de Historial)**: en
  `historial.html`, junto a la tabla de siempre, hay una pestaña nueva
  **"📊 Dashboard de preferencias"** con reportes sobre las proformas que
  cumplen los filtros activos (proyecto, tipología, fechas, cliente/asesor):
  - **Rango de presupuesto**: en cuántas proformas cayó el precio final en
    cada franja (las franjas se calculan solas según el mínimo/máximo de lo
    filtrado, no son fijas).
  - **Ubicación preferida**: sector/proyecto más cotizado.
  - **Tipología de mayor y menor demanda**: qué tipo de unidad (casa,
    suite, departamento, local, lote…) se cotiza más y cuál menos.
  - Se agregó un filtro nuevo, **Tipología / tipo de unidad**, para poder
    aislar el reporte a un solo tipo.
  - **Exportar a PDF**: el botón usa Imprimir del navegador (igual que la
    proforma) con una vista solo del dashboard — sin menú, filtros ni
    tabla. En Chrome/Edge, si los colores de las barras no se ven en el
    PDF, hay que activar **"Gráficos de fondo"** en el diálogo de
    impresión (Más ajustes).
  - **Dato importante**: las proformas generadas *antes* de esta
    actualización no tienen tipología guardada, así que van a aparecer
    agrupadas como "Sin especificar" en ese reporte — no hace falta
    corregir nada, es solo que ese dato no existía todavía cuando se
    generaron.

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
3. **Corre `supabase/update_financiamiento_v2.sql`** una vez en el SQL Editor
   de Supabase — **este paso es obligatorio** para la entrega actual (número
   de proforma, historial restringido, y el nuevo esquema de financiamiento
   30%/70%). Sin correrlo, el sitio actualizado no va a poder generar
   proformas (le van a faltar columnas/función que este archivo crea). Ver el
   detalle en "Número de proforma, historial y financiamiento" más abajo.
4. **Corre `supabase/update_colores_proyecto.sql`** una vez en el SQL Editor,
   si todavía no lo hiciste en una entrega anterior. Le da a cada proyecto
   (Misicata, AURA, Álabes, Portón) un color distinto y propio para su
   tarjeta/banner — no afecta a la proforma, que usa siempre el azul de marca
   FORXA.
5. **Corre `supabase/update_asesores.sql`** una vez en el SQL Editor —
   **obligatorio** para esta entrega (crea la tabla `cotizador_asesores` y
   la precarga con los 12 asesores de `Contactos_Asesores.xlsx`). Sin
   correrlo, el desplegable de "Datos del asesor" del cotizador aparece
   vacío. Ver el detalle en "Asesores con autocompletado y dashboard de
   preferencias" más arriba.
6. **Corre `supabase/update_motivo_forma_pago.sql`** una vez en el SQL
   Editor — **obligatorio** (agrega las columnas `motivo_compra` y
   `forma_pago` a `cotizador_historial`). Sin correrlo, el cotizador no va a
   poder guardar proformas nuevas.
7. **Corre `supabase/update_arcus.sql`** una vez en el SQL Editor —
   **obligatorio** para esta entrega (crea el proyecto Arcus Suites & Lofts
   y sus 77 unidades). Ver el detalle en "Arcus Suites & Lofts + corrección
   de Portón del Valle" más arriba.
8. **Corre `supabase/update_porton_lotes.sql`** una vez en el SQL Editor —
   **obligatorio** para esta entrega (mueve los 33 lotes de Portón del Valle
   a la tabla que el cotizador sí consulta — sin esto, Portón sigue
   mostrando el grid de unidades vacío).
9. **Si las portadas de los proyectos o las fichas de las unidades todavía no
   se ven**, es porque `scripts/bulk_upload_fotos.mjs` (Paso 3 abajo)
   todavía no se ha corrido contra tu proyecto de Supabase — no es un error
   de código, es que esas imágenes viven en Supabase Storage y hay que
   subirlas una vez con tu `service_role key`. Corre ese paso y aparecerán.

## Número de proforma, historial y financiamiento (esta entrega)

**Qué cambia y por qué corre en Supabase:** a diferencia de la entrega
anterior (solo diseño), esta sí necesita `supabase/update_financiamiento_v2.sql`
porque agrega tablas/columnas nuevas — es igual de seguro (usa
`if not exists`, se puede correr más de una vez), pero no es opcional.

- **Número de proforma automático**: cada proforma generada ahora trae un
  número único (ej. `AURA-0007`), generado por la base de datos (no se puede
  repetir aunque dos asesores generen al mismo tiempo). El prefijo de cada
  proyecto (`MIS`, `AURA`, `ALB`, `PDV`) se configura en **Administrar →
  Proyectos → editar → Prefijo de proforma**, y ya viene precargado para los
  4 proyectos actuales al correr el SQL.
- **Historial de proformas (pantalla nueva, acceso restringido)**: en
  `historial.html` (aparece como enlace "Historial" en el menú, pero **solo
  para una cuenta**) puedes ver, filtrar (por proyecto, cliente/asesor, rango
  de fechas) y exportar a CSV todas las proformas generadas por cualquier
  asesor. El resto de asesores sigue generando proformas normalmente, pero no
  puede ver el historial de nadie — el `update_financiamiento_v2.sql` le da
  ese acceso a **`ceo@forxainmobiliaria.com`** (línea 5 del archivo: cambia
  ese correo antes de correrlo si quieres dárselo a otra cuenta, o corre esto
  después para agregar a alguien más):
  ```sql
  insert into public.cotizador_admins (user_id, nombre, puede_ver_historial)
  select id, 'Nombre', true from auth.users where email = 'otro-correo@forxa.com'
  on conflict (user_id) do update set puede_ver_historial = true;
  ```
  Esta restricción funciona a nivel de base de datos (no solo ocultando el
  botón), así que aunque alguien intente consultar la tabla directamente con
  su sesión, no va a poder ver los datos de clientes de otros asesores.
- **Descuento por negociación**: ya no es "+ / − por clics de $500"; ahora el
  asesor escribe el monto exacto que negoció, en un solo campo. Sigue
  controlado por el interruptor "Permite descuento manual" de cada proyecto
  en el panel.
- **Nuevo esquema de financiamiento — Misicata, AURA y Álabes**: reserva 2%
  + promesa 8% (automáticas) + cuotas hasta la entrega = 30% a abonar antes
  de la entrega; el 70% restante queda como "Monto a financiar", con interés
  anual y plazo editables por el asesor, y la cuota mensual estimada
  resaltada. Las cuotas: el asesor solo escribe **el número de cuotas** — el
  monto de cada una se calcula solo (20% del precio ÷ número de cuotas), así
  que nunca puede quedar descuadrado con la meta.
- **Portón del Valle (ya listo para entrega)**: en vez del desglose por
  pasos, es un solo campo de "Abono antes de la entrega" (USD, sugerido 30%
  del precio pero editable), más el mismo 70% financiado con interés/plazo
  editables.
- **Google Sheets**: se evaluó, pero se descartó a favor del historial de
  arriba — un sitio sin servidor propio solo puede "empujar" datos a Sheets
  sin poder confirmar que llegaron bien (si falla, nadie se entera). El
  historial vive en la misma base de datos que ya usa el cotizador, así que
  nunca se pierde un dato, y desde ahí lo exportas a CSV cuando lo
  necesites — pensado para importarlo a un CRM (Zolutium u otro): un valor
  por columna, cliente primero, fechas sin ambigüedad y montos como número
  plano (sin "$" ni comas), sin nada combinado en una misma celda. No
  encontré documentación pública del formato exacto que pide Zolutium — si
  tienen una plantilla propia de importación (usualmente se descarga desde
  el mismo asistente de importar contactos/leads de la plataforma), pásamela
  y ajusto el CSV para que calce exactamente con sus columnas.
- **Botón "Enviar por WhatsApp"**: aparece junto a "Imprimir / Guardar PDF"
  en la proforma, solo si el cliente tiene teléfono registrado. Abre WhatsApp
  (web o app) con un mensaje profesional ya redactado — con el nombre del
  asesor, el proyecto, la unidad, el precio final y el número de proforma —
  que el asesor puede revisar/editar antes de enviarlo (el botón no envía
  nada automáticamente). **Importante**: WhatsApp no permite adjuntar
  archivos desde un enlace como este, así que el asesor todavía debe adjuntar
  el PDF de la proforma manualmente dentro de la conversación.

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
├── historial.html           → (nuevo) historial de proformas — acceso restringido a 1 cuenta
├── css/styles.css
├── assets/
│   ├── logo.png            → logo FORXA (ya existente)
│   ├── logo-white.png       → logo FORXA en blanco, para el banner de la portada
│   └── logos/                 → logo de cada proyecto, para el membrete de la proforma
│       ├── misicata.png
│       ├── aura.png
│       ├── alabes.png
│       └── porton.png
├── js/
│   ├── supabase-client.js   → URL + anon key (misma que el portafolio)
│   ├── auth.js                → login/logout + verificación de admin/historial
│   ├── utils.js                 → formato de moneda, cuotas, URLs firmadas, WhatsApp, CSV
│   ├── cotizador.js               → motor genérico (sirve para los 4 proyectos) + desplegable de asesor + forma de pago
│   ├── admin.js                     → CRUD de proyectos, unidades y asesores
│   ├── historial.js                   → tabla/filtros/export del historial + dashboard de preferencias
│   └── charts.js                        → (nuevo) donut/barras/línea en SVG propio, sin librerías
├── supabase/
│   ├── schema.sql                            → tablas, RLS, bucket privado (ya incluye lo nuevo)
│   ├── seed_data.sql                         → los 4 proyectos + ~120 unidades ya cargadas
│   ├── update_colores_proyecto.sql           → da un color propio a cada proyecto ya existente
│   ├── update_financiamiento_v2.sql          → número de proforma, historial, 30%/70%
│   ├── update_asesores.sql                   → directorio de asesores FORXA
│   ├── update_motivo_forma_pago.sql          → motivo de compra + forma de pago
│   ├── update_arcus.sql                      → (nuevo, obligatorio) proyecto Arcus + 77 unidades
│   └── update_porton_lotes.sql               → (nuevo, obligatorio) corrige el bug de Portón del Valle
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
  precio/estado/fotos de cualquier unidad al instante, pueden agregar un
  proyecto nuevo sin tocar código (solo configuran su fórmula de
  financiamiento: reserva %, promesa %, tasa y plazo), y mantienen el
  directorio de asesores (agregar, editar teléfono/correo, o desactivar a
  quien ya no trabaje con FORXA) que alimenta el desplegable del cotizador.
- **Quien tenga acceso al Historial**: además de la tabla de proformas, tiene
  la pestaña "Dashboard de preferencias" con rango de presupuesto, ubicación
  preferida y tipología de mayor/menor demanda de las proformas filtradas,
  exportable a PDF con el botón "Exportar a PDF".

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
- **Arcus — departamento 603 omitido a propósito**: es el único
  departamento del edificio y en el Excel ya figura "Vendido" — no se
  cargó, como pediste.
- **Portón del Valle — pendiente de tu confirmación**: el lote **A82**
  estaba disponible en la base de datos, pero no aparece en tu lista de
  disponibles más reciente (imagen `Mesa_de_trabajo`). Lo marqué
  `no_disponible` con una nota — confirma desde Administrar si ya se vendió
  o reservó (o si fue un descuido al armar la lista y sigue disponible).

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
