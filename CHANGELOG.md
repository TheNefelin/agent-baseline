# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado semántico.

Criterio de versión:

- **Major**: cambia una regla que altera cómo trabaja el agente (permisos, verificación, flujo).
- **Minor**: skill nueva o ampliada.
- **Patch**: correcciones de texto, frescura, typos.

## [0.3.2] - 2026-11-11

### Corregido
- `tools/install.ps1`: los adaptadores de descubrimiento se materializan como **enlaces** (junction en Windows, symlink en Unix) y no como copias. Antes `.agents/skills/` duplicaba los archivos de `.baseline/skills/` en disco.
- `tools/install.ps1`: `Remove-AdapterPath` borra el enlace con `[System.IO.Directory]::Delete`, que quita el enlace incluso si su destino ya no existe y sin tocar el destino. Antes `Get-Item -Force` lanzaba excepción sobre un junction roto y dejaba el enlace huerfano.
- `tools/install.ps1`: cada operación usa su propia carpeta de respaldo (`yyyyMMdd-HHmmss-fff`) y `Backup-File` numera el destino si ya existe. Dos operaciones en el mismo segundo anidaban `.baseline/.baseline` y perdian el respaldo previo.

### Agregado
- `tools/test.ps1`: tres casos nuevos (23 en total): el adaptador es un enlace y no una copia, `-Uninstall` con junction rota no deja enlaces huerfanos, y los respaldos no se anidan entre si.
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
