# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado semántico.

Criterio de versión:

- **Major**: cambia una regla que altera cómo trabaja el agente (permisos, verificación, flujo).
- **Minor**: skill nueva o ampliada.
- **Patch**: correcciones de texto, frescura, typos.

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
