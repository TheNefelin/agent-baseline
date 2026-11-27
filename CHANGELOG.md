# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado semántico.

Criterio de versión:

- **Major**: cambia una regla que altera cómo trabaja el agente (permisos, verificación, flujo).
- **Minor**: skill nueva o ampliada.
- **Patch**: correcciones de texto, frescura, typos.

## [0.6.2] - 2026-11-27

### Corregido
- FastAPI tests.md: regla absoluta de no DROP SCHEMA/DB/truncate sin lista.
  Tests solo ejecutan tests, no crean/eliminan tablas ni BD.
- FastAPI tests.md: convención de archivos .sql (schema + seed + auth) como
  fuente de verdad de las tablas del proyecto.
- FastAPI tests.md: template de repopulate_db.py eliminado (era incorrecto).
- FastAPI SKILL.md: agrega .sql files a estructura y checklist.
- Angular SKILL.md: limpieza de BD solo por tablas del proyecto.
- SQL SKILL.md: convención de archivos .sql versionados.

### Cambiado
- FastAPI SKILL.md: reduce cuerpo a 299 líneas (bajo presupuesto de 7000 tokens).

## [0.6.1] - 2026-11-27

### Corregido
- Regla absoluta: tests nunca crean/eliminan tablas, esquemas ni BD. Solo ejecutan tests y limpian datos (TRUNCATE de tablas del proyecto). Nunca DROP SCHEMA, TRUNCATE sin lista ni drop_all.
- Eliminado template de 
epopulate_db.py de fastapi tests.md (no debe generarse automáticamente).
- Convención de archivos .sql versionados (postgre_schema.sql, postgre_seed.sql, postgre_auth.sql) como fuente de verdad de las tablas del proyecto.
- Angular SKILL.md §10: especifica limpieza solo de tablas del proyecto, referencia fastapi tests.md.
- SQL SKILL.md §4: documenta la convención de archivos .sql versionados.
- FastAPI SKILL.md: actualiza descripción de tests con BD real.

### Agregado
- Regla de indentación (2 espacios, excepto .NET) en AGENTS.md §1.1.
- Nueva skill python-ml (ML clásico en Python) con 7 referencias.
- Anti-patrones documentados con Lucky_IA como caso de estudio.

## [0.6.0] - 2026-11-18

### Agregado
- `angular/references/auth.md`: 12 patrones nuevos del BFF de portfolio-angular (refresh deduplication con inflight map, cache de 10 s, rejected vs unavailable, origin check en CSRF, path traversal en el proxy CRUD, method allowlist por recurso, body sin parsear con Buffer passthrough, `Cache-Control: no-store` en todo el BFF, slash redirect handling 307/308, bad gateway 502 JSON, rate limiting in-memory con 3 tiers y MAX_KEYS, config lazy getters que lanzan si falta).
- `angular/references/feedback.md`: escrituras con `firstValueFrom` + try/catch/finally y Logger con contexto.
- `fastapi/references/uploads.md`: limpieza en fallo (rollback del storage con retry y cleanup on failure), `extract_public_id` con loop hasta la versión.
- `fastapi/references/tests.md`: `repopulate_db.py` (seed idempotente con `--force` y `--test`).
- `dotnet/references/microsoft-skills.md`: referencia a las skills oficiales de Microsoft (`github.com/dotnet/skills`) con guía de uso "tal cual" y tabla de 15 plugins.

### Corregido
- `angular/references/auth.md`: BFF modular (`http/`, `middleware/`, `proxy/`, `services/`), proxy partido por dominio, contrato de error JSON uniforme, `Secure` condicionado al host, guard async de roles, logout fire-and-forget, SDK con timeout y reseteo, CSP con post-proceso (eliminar `content-length`/`etag`), tests del BFF con Vitest puro, CSRF condicional en el BFF y no reenviar `X-CSRF-Token` al upstream.
- `angular/SKILL.md`: el patrón por defecto de SSR pasa a **BFF + cookie `HttpOnly`**; `sessionStorage` queda como variante legacy.
- `angular/SKILL.md`: la regla del 401 pasa de absoluta a condicional; los errores **no HTTP** los muestra la página; `provideZonelessChangeDetection()` es opcional; Vitest es el runner por defecto desde 21+.
- `fastapi/SKILL.md`: `commit()` solo en `get_db()` (una transacción por request); regla de `core/`; excepción consciente para catálogos sin routes; anti-patrón del proveedor reescrito.
- `fastapi/references/errores-rfc9457.md`: el duplicado que viola UNIQUE devuelve `ConflictError` (409).
- `dotnet/SKILL.md`: referencia a las skills oficiales de Microsoft.

### Cambiado
- `angular/SKILL.md` y `fastapi/SKILL.md`: marker de frescura revalidado contra proyecto real.

## [0.5.0] - 2026-11-18

### Agregado
- `angular/SKILL.md` §6: guard asíncrono de roles separado del guard de sesión (con cookie `HttpOnly` el rol no está disponible de forma síncrona).
- `angular/SKILL.md` §10: Vitest como runner por defecto desde Angular 21+ (`@angular/build:unit-test`, `tsconfig.spec.json` con `types: ["vitest/globals"]`, Karma deprecado).
- `angular/SKILL.md` §10: zoneless por defecto en Angular 22 (sin `zone.js`, `ZONELESS_ENABLED` resuelve `true`); `provideZonelessChangeDetection()` opcional.
- `angular/references/auth.md`: 14 patrones nuevos validados en producción (BFF modular por responsabilidad, proxy partido por dominio, contrato de error JSON uniforme, mapeo de errores HTTP→mensaje, guard CSRF condicional, no reenviar `X-CSRF-Token`, `Secure` condicionado al host, config lazy con `Proxy`, guard async contra `/auth/me`, logout fire-and-forget, SDK con timeout y reseteo, CSP con post-proceso, tests del BFF con Vitest puro, logger con contexto).
- `fastapi/SKILL.md` §5: variante sin `relationship` en modo async (resuelve con `select` explícitos, evita `MissingGreenlet`).
- `fastapi/references/modelos.md`: el ORM mapea exactamente las FKs y tipos del DDL; variante sin `relationship`; `Column(...)` como anotación.
- `fastapi/references/auth.md`: identidad federada en tabla puente, prohibición de merge automático por email (account takeover), `id_token` vs `access_token`, degradación suave en `userinfo`, guard de seeds, `get_user_id` con dos formas de `require_user`.
- `fastapi/references/configuracion-logging.md`: variante `python-dotenv` + clase propia, CORS fail-closed, `expire_on_commit=False` y `get_db()` con commit/rollback.
- `fastapi/references/tests.md`: aislamiento no destructivo (DDL real + rollback por test), desactivar rate limit, test de contrato de la API Key.
- `dotnet/references/microsoft-skills.md`: referencia a las skills oficiales de Microsoft (`github.com/dotnet/skills`) con guía de uso "tal cual" y tabla de plugins.

### Corregido
- `angular/SKILL.md` §6: el patrón por defecto de SSR pasa a **BFF + cookie `HttpOnly`**; `sessionStorage` queda como variante legacy (multi-tenant).
- `angular/references/auth.md`: el interceptor CSRF de ejemplo ahora lleva **guarda de plataforma** (`isPlatformBrowser`): `app.config.ts` se hereda al servidor y `document.cookie` en SSR lanza `ReferenceError` en cuanto una ruta con request pasa a `RenderMode.Server`.
- `angular/references/auth.md`: la regla del 401 pasa de absoluta a condicional: se silencia solo cuando significa "sesión muerta" (hay sesión activa o la petición es a `/auth/me`); un 401 sin sesión (credenciales inválidas) **sí** se muestra, porque en BFF no hay refresh en el cliente.
- `angular/references/auth.md`: `allowedHosts` se documenta **solo** por `NG_ALLOWED_HOSTS` + `AngularNodeAppEngine`, fail-closed **por arranque**. La variante en `angular.json` que aparecía aquí no habilitaba nada y contradecía a `references/ssr.md`.
- `angular/references/auth.md`: `env.ts` documenta las dos variantes de precedencia (entorno del sistema vs `.env` del proyecto) y `config.ts` el patrón lazy con `Proxy`, para que el build SSR no falle sin variables.
- `angular/SKILL.md` §7: la regla de feedback pasa de "las páginas nunca llaman `error.show()`" a "no duplicar": los errores **no HTTP** (SDK, popup OAuth) los muestra la página.
- `angular/SKILL.md` §10 y §13: `provideZonelessChangeDetection()` es opcional en Angular 22 (zoneless por defecto si no se instala `zone.js`), Vitest es el runner por defecto desde 21+, el check de `pnpm lint` es condicional, el de `subscribe()` admite fire-and-forget y `modal-confirm` solo aplica si hay borrados.
- `angular/references/auth.md`: `allowedHosts` y CSP quedan alineados con `references/ssr.md` (fuente única, sin contradicción entre referencias).
- `fastapi/SKILL.md` §4.3 y checklist: `commit()` solo en `get_db()` (una transacción por request); antes §4.3 pedía `commit()` en el repository, lo que contradecía a §4.2.
- `fastapi/SKILL.md` §4.2: regla explícita para `core/` (puede leer el ORM del usuario; los services de `api/` no) y excepción consciente para catálogos sin routes.
- `fastapi/SKILL.md` §11: el anti-patrón del proveedor externo ya no exige `raise_for_status()` (contradecía a sus propias referencias); ahora exige **comprobar el status** y decidir entre error de negocio o degradación suave.
- `fastapi/references/errores-rfc9457.md`: el duplicado que viola UNIQUE devuelve `ConflictError` (409), no `DuplicateNameError` (400); se agregan `ConflictError` y `BadRequestError` a la plantilla.
- `fastapi/references/auth.md`: `get_user_id` documenta las dos formas de `require_user` (payload con `sub` vs perfil con `id`); el token puede llevar o no el `role` (es redundante si el rol siempre se lee de la BD).
- `fastapi/references/tests.md`: se agrega el modo de aislamiento **no destructivo** (DDL real idempotente + rollback por test), que no borra nada y sirve también para BD compartida.
- `CHANGELOG.md`: entradas 0.4.0 y 0.4.1 duplicadas (habían quedado dos bloques de cada una); se conserva una de cada.

### Cambiado
- `angular/SKILL.md` y `fastapi/SKILL.md`: marker de frescura revalidado (Angular 22.2.4–22.2.5 / FastAPI 0.162.7, SQLAlchemy 2.1.8, Pydantic 2.14.3, httpx 0.28.1, pytest 9.2.0, Python 3.14) contra un proyecto real con la suite en verde.
- `dotnet/SKILL.md`: referencia a las skills oficiales de Microsoft (`github.com/dotnet/skills`).

## [0.4.2] - 2026-11-14

### Corregido
- `angular/SKILL.md` §6: el patrón por defecto de SSR pasa a ser **BFF + cookie `HttpOnly`**; `sessionStorage` queda como variante legacy (multi-tenant). Antes la sección que se lee siempre describía el patrón con más riesgo.
- `angular/references/auth.md`: el interceptor CSRF de ejemplo ahora lleva **guarda de plataforma** (`isPlatformBrowser`): `app.config.ts` se hereda al servidor y `document.cookie` en SSR lanza `ReferenceError` en cuanto una ruta con request pasa a `RenderMode.Server`.
- `angular/references/auth.md`: la regla del 401 pasa de absoluta a condicional: se silencia solo cuando significa "sesión muerta" (hay sesión activa o la petición es a `/auth/me`); un 401 sin sesión (credenciales inválidas) **sí** se muestra, porque en BFF no hay refresh en el cliente.
- `angular/references/ssr.md`: `allowedHosts` y CSP quedan alineados con `references/auth.md` (fuente única, sin contradicción entre referencias).
- `angular/references/auth.md`: `env.ts` documenta las dos variantes de precedencia (entorno del sistema vs `.env` del proyecto) y `config.ts` el patrón lazy con `Proxy`, para que el build SSR no falle sin variables.
- `angular/SKILL.md` §7: la regla de feedback pasa de "las páginas nunca llaman `error.show()`" a "no duplicar": los errores **no HTTP** (SDK, popup OAuth) los muestra la página.
- `angular/SKILL.md` §10 y §13: `provideZonelessChangeDetection()` es opcional en Angular 22 (zoneless por defecto si no se instala `zone.js`), Vitest es el runner por defecto desde 21+, el check de `pnpm lint` es condicional, el de `subscribe()` admite fire-and-forget y `modal-confirm` solo aplica si hay borrados.
- `fastapi/SKILL.md` §4.3 y checklist: `commit()` solo en `get_db()` (una transacción por request); antes §4.3 pedía `commit()` en el repository, lo que contradecía a §4.2.
- `fastapi/SKILL.md` §4.2: regla explícita para `core/` (puede leer el ORM del usuario; los services de `api/` no) y excepción consciente para catálogos sin routes.
- `fastapi/SKILL.md` §11: el anti-patrón del proveedor externo ya no exige `raise_for_status()` (contradecía a sus propias referencias); ahora exige **comprobar el status** y decidir entre error de negocio o degradación suave.
- `fastapi/references/errores-rfc9457.md`: el duplicado que viola UNIQUE devuelve `ConflictError` (409), no `DuplicateNameError` (400); se agregan `ConflictError` y `BadRequestError` a la plantilla.
- `fastapi/references/auth.md`: `get_user_id` documenta las dos formas de `require_user` (payload con `sub` vs perfil con `id`); el token puede llevar o no el `role` (es redundante si el rol siempre se lee de la BD).
- `fastapi/references/tests.md`: se agrega el modo de aislamiento **no destructivo** (DDL real idempotente + rollback por test), que no borra nada y sirve también para BD compartida.
- `CHANGELOG.md`: entradas 0.4.0 y 0.4.1 duplicadas (habían quedado dos bloques de cada una); se conserva una de cada.

### Agregado
- `angular/references/auth.md`: BFF modular (`http/`, `middleware/`, `proxy/`, `services/`), proxy partido por dominio, contrato de error JSON uniforme, `Secure` condicionado al host, guard async de roles, logout fire-and-forget, SDK con timeout y reseteo, CSP con post-proceso (eliminar `content-length`/`etag`), tests del servidor con Vitest puro, CSRF condicional en el BFF y no reenviar `X-CSRF-Token` al upstream.
- `fastapi/references/auth.md`: identidad federada en tabla puente, prohibición de merge automático por email (account takeover), `id_token` vs `access_token`, degradación suave en `userinfo`, guard de seeds.
- `fastapi/references/modelos.md`: el ORM mapea exactamente el DDL, variante sin `relationship` en async, `Column(...)` como anotación.
- `fastapi/references/configuracion-logging.md`: variante `python-dotenv` + clase propia, CORS fail-closed, `expire_on_commit=False` y `get_db()` con commit/rollback.
- `fastapi/references/tests.md`: desactivar el rate limit en tests y test de contrato de la API Key.
- `fastapi/references/rate-limiting.md`: los headers `X-RateLimit-*` son opcionales.

### Cambiado
- `angular/SKILL.md` y `fastapi/SKILL.md`: marker de frescura revalidado (Angular 22.2.4–22.2.5 / FastAPI 0.162.7, SQLAlchemy 2.1.8, Pydantic 2.14.3, httpx 0.28.1, pytest 9.2.0, Python 3.14) contra un proyecto real con la suite en verde.

## [0.4.1] - 2026-11-14

### Agregado
- `fastapi/references/auth.md`: clarificación de que `core/dependencies.py` es fachada **opcional** (ambas variantes válidas: facade o deps en `security.py`); gotcha de config (python-dotenv vs pydantic-settings, ambas válidas).
- `fastapi/SKILL.md` §9: mención de python-dotenv como alternativa válida a pydantic-settings.
- `angular/references/ssr.md`: gotcha de `pnpm-workspace.yaml` (pnpm 10+ con `allowBuilds` placeholder rompe `pnpm install` en Vercel); `allowedHosts` fail-closed (sin fallback inseguro, usar `NG_ALLOWED_HOSTS`).
- `angular/references/auth.md`: gotcha del prefijo `/api` doble (la URL del frontend debe cuadrar con la del backend + el prefijo del BFF).

### Cambiado
- `fastapi/references/auth.md`: sección de `dependencies.py` como fachada ahora dice "opcional".

## [0.4.0] - 2026-11-13

### Agregado
- Skill `podcast-video`: edicion de video para podcast y extraccion de shorts. Flujo en DaVinci Resolve (Free), comandos FFmpeg, specs por plataforma (TikTok/Reels/Shorts) y manejo de footage de iPhone. 3 referencias bajo demanda: `davinci-flujo.md`, `ffmpeg-cortes.md`, `formatos-redes.md`. 2 casos de eval (positivo y negativo).
- `evals/triggers.json`: 51 casos (49 + 2 nuevos).
- `AGENTS.md`: regla explícita de que `.baseline/skills/` no se edita en sitio (el manifiesto hashea cada archivo; la edición local rompe `-Doctor` y la pierde el próximo `-Update`).
- `fastapi/references/tests.md`: sección "Mocks y binding de imports" (importar la función rompe `patch("modulo.fn")`; la forma correcta es `from . import modulo` + `modulo.fn()`), y gotcha de `pytest -q` + `addopts = -q` → `-qq` oculta la línea "N passed".
- `fastapi/references/modelos.md`: "Una sola Base declarativa" y "Consolidar a un único `models.py` sin tocar los call sites" (fachada `__init__.py` que reexporta).
- `angular/references/auth.md`: subsección "[SSR] — Sesión en cookie HttpOnly (BFF)": guard asíncrono contra `/auth/me`, CSRF por doble envío, refresh silencioso en el proxy, respuesta de login sin tokens, `AuthStoreService` reducido a flag booleano.

### Cambiado
- `DEVELOPMENT.md` y `README.md`: inventario actualizado a 18 skills y 51 casos.
- `fastapi/SKILL.md` §4.2: clarificación de la frontera de transacción (preferible una transacción por request con `flush()` en el repository y `commit()`/`rollback()` en `get_db()`; commit por método de repository deja datos parciales).
- `fastapi/references/auth.md`: generaliza la regla de `API_KEY` para no asumir `pydantic-settings` (vale también para una `Settings` propia con `_required()`).
- `memoria/SKILL.md`: "Mide y estima el largo antes de escribir" en el Procedimiento (evita la segunda pasada cuando el archivo está cerca del tope duro).

## [0.3.2] - 2026-11-11

### Corregido
- `tools/install.ps1`: los adaptadores de descubrimiento se materializan como **enlaces** (junction en Windows, symlink en Unix) y no como copias. Antes `.agents/skills/` duplicaba los archivos de `.baseline/skills/` en disco.
- `tools/install.ps1`: cada intento de enlace se **verifica** (debe resolver y dejar leer `SKILL.md` a través de él). En Unix `New-Item -ItemType Junction` no falla pero no deja un enlace resoluble, y el instalador daba el adaptador por bueno: el fallo solo aparecía en CI de Linux. Ahora se reintenta con el otro tipo y, en último caso, se copia.
- `tools/install.ps1`: `Remove-AdapterPath` borra el enlace con `[System.IO.Directory]::Delete`, que quita el enlace incluso si su destino ya no existe y sin tocar el destino. Antes `Get-Item -Force` lanzaba excepción sobre un junction roto y dejaba el enlace huerfano.
- `tools/install.ps1`: cada operación usa su propia carpeta de respaldo (`yyyyMMdd-HHmmss-fff`) y `Backup-File` numera el destino si ya existe. Dos operaciones en el mismo segundo anidaban `.baseline/.baseline` y perdian el respaldo previo.

### Agregado
- `tools/test.ps1`: tres casos nuevos (23 en total): el adaptador expone las skills instaladas y propaga la fuente si es un enlace, `-Uninstall` con junction rota no deja enlaces huerfanos, y los respaldos no se anidan entre si.
- `DEVELOPMENT.md`: seccion "Adaptadores de descubrimiento" con la matriz de donde lee cada cliente, y "Estado verificado" que sustituye la bitacora de validaciones.

### Cambiado
- `DEVELOPMENT.md`: poda de 16.979 a 11.512 caracteres (182 a 120 lineas). Se retiran las decisiones superadas, el detalle de plantillas que repetia el README, y la bitacora de sesion; se conservan las decisiones vigentes, el mapa, el contrato del instalador y los 13 pendientes.

## [0.3.1] - 2026-11-11

### Cambiado
- `AGENTS.md` §11: se aclara cuándo **no** reescribir la memoria (solo al cerrar la tarea autorizada o al cambiar mapa/estado/decisión vigente); evita reescrituras por turno sin información nueva.
- `templates/session.md`: el bloque de pruebas se reduce a resultado final; no se vuelcan salidas ni logs.

## [0.3.0] - 2026-11-08

### Agregado
- Adaptadores de descubrimiento materializados (gitignored): `.agents/skills/` para openCode, Codex, Cursor y Kilo; `.clinerules/skills/` para Cline. Se crean con `-Update` desde `.baseline/skills` y se re-sincronizan en cada actualizacion.
- `-Doctor` distingue salud (exit code) de preparacion (aviso): falta de adaptadores es aviso, no fallo.
- Prohibiciones criticas inline en los punteros (`git commit/push/add`, `.env` real, `DROP`/`TRUNCATE`/`DELETE` masivo) para que esten en contexto aunque el agente no abra `.baseline/AGENTS.md`.
- `.gitignore` recibe las entradas de los adaptadores de descubrimiento (`.agents/skills/`, `.clinerules/`, `.claude/skills/`, `.kilocode/`).

### Cambiado
- `-Update` materializa y re-sincroniza los adaptadores de descubrimiento ademas de `.baseline/`.
- `-Uninstall` retira los adaptadores materializados ademas de los punteros.

## [0.2.3] - 2026-11-08

### Corregido

- `tools/install.ps1`: `.gitignore` recibe una entrada idempotente de `.baseline-backup/` con cabecera propia; antes los respaldos de `-Update` y `-Uninstall` quedaban sin ignorar.
- `-Doctor` valida además el puntero `AGENTS.md`, los archivos del target y que las skills instaladas coincidan con el manifiesto. Antes solo comparaba hashes, así que un puntero sin bloque o con skills retiradas pasaba en verde.
- `-Doctor` y `-Update` sin manifiesto indican el comando exacto de instalación en lugar de terminar con un error sin salida.
- Se eliminaron `templates/targets/cline.md` y `templates/targets/kilo.md`: el instalador genera esos punteros en código desde el mismo cuerpo que `AGENTS.md`, y las plantillas no se usaban.
- `skills/angular/references/auth.md`: eliminado el bloque multi-tenant duplicado y la sección de signals repetida.
- `skills/fastapi/references/auth.md`: `verify_api_key` con `compare_digest` y guardia para cabecera ausente; `dependencies.py` queda como fachada de `verify_api_key`, `require_admin` y `require_user`; `_required()` reemplazado por `API_KEY: str` de `Settings`.

### Agregado

- `tools/check.ps1`: valida que la versión de `VERSION` tenga su entrada `## [x.y.z]` en `CHANGELOG.md`.
- `tools/test.ps1`: casos de targets `cline` y `kilo`, conservación de reglas propias en el puntero, skill nuclear `memoria`, `.gitignore` idempotente, puntero heredado sin duplicación, `-Doctor` sano y en fallo, y `-Update` sin manifiesto.

### Cambiado

- `-Target cline` y `-Target kilo` generan el puntero con marcadores y lista de skills; no dependen de una plantilla por cliente.
- `README.md` y `DEVELOPMENT.md` describen el nuevo alcance de `-Doctor` y la generación de punteros.

## [0.2.2] - 2026-11-01

### Corregido

- El puntero `AGENTS.md` declara las skills instaladas con su ruta: antes solo apuntaba a `.baseline/AGENTS.md`, así que con `-Target none` (default desde 0.1.1) ningún cliente sabía que existían.
- `-Update` reescribe esa lista, de modo que una skill retirada desaparece del puntero.
- `-Skills` acepta la lista separada por comas en un solo argumento (`-Skills "angular,sql"`), que es como llega al invocar el instalador con `-File` desde otro shell.
- `AGENTS.md` §6 indica dónde viven las skills instaladas y que se carga solo la que corresponde.
- `tools/verify.ps1` incluye `tools/test.ps1`: un caso roto del instalador ya no puede pasar desapercibido con la verificación en verde.
- `tools/test.ps1`: el caso del bloque de marcadores usaba `-Skills none`, que la validación rechaza desde 0.1.1; ahora usa una skill real.

## [0.2.1] - 2026-11-01

### Corregido

- Eval `arduino-amb-01`: la description de `ui-ux-mockup` ya no incluye `apps web`, que le daba el mismo puntaje que `arduino` por la palabra común `web`.
- `tools/check.ps1`: los empates de puntaje se resuelven por nombre, así el resultado no depende de la estabilidad de `Sort-Object`.

## [0.2.0] - 2026-10-31

### Agregado

- Skill `memoria`: audita `DEVELOPMENT.md` con presupuesto blando de 4.500 caracteres y tope duro de 6.000, checklist de 6 criterios y salida antes/después. El `DEVELOPMENT.md` del catálogo queda fuera del presupuesto.
- `@Service()` (22.2+) como decorador de servicios de aplicación, con `@Injectable` reservado a alcance o `useFactory` explícito.
- `references/ssr.md`: `allowedHosts` y `NG_ALLOWED_HOSTS`, diferencia entre `Server` y `Prerender` con URLs relativas, y namespace opcional del proxy.
- `references/feedback.md`: montaje único de `modal-error`, `modal-confirm` y `toast` en `app.html`.

### Cambiado

- `AGENTS.md` §11: presupuesto medible, tres disparadores de auditoría y el detalle delegado a la skill `memoria`.
- Regla de submit: `(submit)` con `preventDefault()` es válido sin `FormsModule`; `(ngSubmit)` sin `FormsModule` es el antipatrón.
- El mapa se define por el título que empieza por `Mapa`; `## Mapa del proyecto` es la forma canónica.

### Corregido

- El checkpoint de sesión apunta a `.baseline/session.md` en `AGENTS.md` y en `DEVELOPMENT.md`; `.harness/session.md` nunca existió.
- `skills/angular/SKILL.md`: eliminada la sección 15, que duplicaba la cita de `references/ejemplo-referencia.md`.

## [0.1.1] - 2026-10-23

### Cambiado

- `-Target` por defecto `none`: el instalador ya no crea `opencode.json` ni punteros de Cline/Kilo sin pedirlo.
- Rutas portables: el instalador resuelve separadores del sistema; en Linux/macOS requiere `pwsh` (PowerShell 7).
- `-Update` deja `.baseline/skills/` como espejo del conjunto declarado: reemplaza cada skill instalada y quita las que ya no se declaran.

### Corregido

- `-Skills` se valida antes de crear nada: una skill inexistente sale con 1, lista las válidas y no deja `.baseline/` ni el puntero a medias.
- `-Target` inválido se rechaza antes de escribir, también en `-WhatIf`; ya no deja una instalación parcial.
- El manifiesto hashea `.baseline/VERSION` y cada `references/*.md`; `-Doctor` detecta ediciones a mano en las referencias.
- `-Doctor` avisa si el manifiesto está incompleto (sin `VERSION` o con archivos de `.baseline/` sin hash) y recuerda correr `-Update`.
- Cambiar de target con `-Update` quita el archivo del target anterior (con backup); `-Uninstall` también reconoce los punteros conocidos de Cline/Kilo aunque no estén en el manifiesto.
- `-Uninstall` quita los `permissions` que el instalador añadió a un `opencode.json` existente, solo si siguen idénticos a la plantilla.
- `install.ps1` termina con `exit 0` en el flujo correcto, así `$LASTEXITCODE` queda en 0.
- `-Update` respalda `.baseline/` completo: antes `Copy-Item` copiaba el directorio sin su contenido.
- Una instalación sin cliente informa `cliente: none` en vez de `opencode.json: none`.

### Añadido

- README: instalación desde GitHub (clone o ZIP) y un prompt listo para que un agente la ejecute.

### Notas

- `opencode.json` mantiene el esquema de OpenCode v2; sin cliente instalado no se verificó su carga. Queda como pendiente en `DEVELOPMENT.md`.

## [0.1.0] - 2026-10-23

### Añadido

- Instalador `tools/install.ps1` con modos `-Project`, `-Workspace`, `-Update`, `-Doctor`, `-Uninstall` y `-WhatIf`.
- Manifiesto `.baseline.json` con versión, skills, targets y hashes por archivo.
- Skill `catalog-maintenance` para hacer crecer el catálogo.
- `tools/budget.ps1` (presupuesto de tokens), `tools/memory.ps1` (rutas del mapa), `tools/sync.ps1` (copias espejo) y `tools/verify.ps1` (los cuatro).
- Casos de eval de enrutamiento: 47.
- Plantillas de proyecto y de workspace.

### Cambiado

- Descripciones de las skills comprimidas: de 1.289 a 824 tokens por request.
- `AGENTS.md` reducido de 222 a 112 líneas, con regla de desempate entre skills y ruteo de workspace.

### Corregido

- El puntero de `AGENTS.md` ya no se duplica en cada `-Update`: va entre marcadores y se reemplaza en el lugar.
- `-Uninstall` quita solo el bloque del puntero y conserva el contenido propio del proyecto.
- `-Update` sin `-Skills` lee `.baseline.json` y refresca lo declarado.

### Notas

- El modo global (una fuente para todos los proyectos) queda para una versión posterior.
