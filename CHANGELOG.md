# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado semántico.

Criterio de versión:

- **Major**: cambia una regla que altera cómo trabaja el agente (permisos, verificación, flujo).
- **Minor**: skill nueva o ampliada.
- **Patch**: correcciones de texto, frescura, typos.

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
