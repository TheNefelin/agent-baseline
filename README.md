# Agent Baseline

Reglas, skills y verificación para que cualquier agente de código trabaje igual de bien en cualquier proyecto: mismos criterios, mismo formato, menos tokens y menos invención.

No es un framework ni un generador de apps. Es el **punto de partida** que un repo hereda para que el agente sepa cómo trabajar ahí.

## Qué incluye

- **`AGENTS.md`** — reglas de operación: permisos, Git, idioma, evidencia, flujo, verificación, memoria.
- **`skills/`** — 16 skills por stack, cada una con un cuerpo corto y referencias que se leen solo cuando hacen falta.
- **`evals/triggers.json`** — 47 casos que comprueban que cada pedido activa la skill correcta (y que los negativos no activan ninguna).
- **`tools/`** — verificación automática: estructura, referencias, solapamiento, frescura, encoding, presupuesto de tokens y memoria.
- **`templates/`** — plantillas para proyectos: `DEVELOPMENT.md` con mapa, `session.md`, `SKILL.md` y permisos de cliente.

## Estructura

```text
AGENTS.md              reglas de operación
DEVELOPMENT.md         memoria del catálogo (decisiones y pendientes)
skills/<nombre>/       SKILL.md + references/
evals/triggers.json    casos de enrutamiento
tools/                 check.ps1, budget.ps1, memory.ps1, verify.ps1
templates/             plantillas para proyectos nuevos
```

## Instalación

**Modo local (recomendado).** El catálogo se copia dentro del proyecto, en `.baseline/`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\tools\install.ps1 -Project D:\Repo\frontend -Skills angular
```

Por defecto `-Target none`: no escribe archivos de cliente. Agrega `-Target opencode` (o `cline`/`kilo`) si quieres configurarlo.

Qué deja en el proyecto:

```text
frontend/
├── .baseline/            AGENTS.md, VERSION y las skills instaladas
├── .baseline.json        manifiesto: versión, skills, hashes
├── AGENTS.md             puntero corto a .baseline/AGENTS.md
├── opencode.json         opcional: config del cliente con -Target opencode
└── .baseline-backup/     respaldo de lo que se reemplazó
```

Si el proyecto no existe o no tiene stack reconocible, el instalador pregunta antes de asumir. Agrega `-WhatIf` para ver el plan sin escribir nada.

```powershell
.\tools\install.ps1 -Project . -WhatIf        # ver el plan
.\tools\install.ps1 -Project . -Doctor        # verificar hashes
.\tools\install.ps1 -Project . -Update        # refrescar según el manifiesto
.\tools\install.ps1 -Project . -Uninstall     # quitar solo lo instalado
```

### Instalar desde GitHub

Si no tienes el catálogo clonado, instálalo en el proyecto desde el repo:

```powershell
git clone --depth 1 https://github.com/TheNefelin/agent-baseline.git "$env:TEMP\agent-baseline"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
& "$env:TEMP\agent-baseline\tools\install.ps1" -Project . -Skills angular -WhatIf
& "$env:TEMP\agent-baseline\tools\install.ps1" -Project . -Skills angular
```

Sin git, descarga el ZIP:

```powershell
Invoke-WebRequest "https://github.com/TheNefelin/agent-baseline/archive/refs/heads/main.zip" -OutFile "$env:TEMP\agent-baseline.zip"
Expand-Archive "$env:TEMP\agent-baseline.zip" "$env:TEMP" -Force
& "$env:TEMP\agent-baseline-main\tools\install.ps1" -Project . -Skills angular
```

`main` es una rama móvil: para reproducibilidad, fija un commit o un tag en lugar de la rama.

**Prompt para un agente** (pégalo en el chat del proyecto):

```text
Instala agent-baseline desde https://github.com/TheNefelin/agent-baseline en este proyecto.
Clona el repo en una carpeta temporal y ejecuta tools/install.ps1 -Project . -Skills <skills> -WhatIf.
Revisa el plan y, si es correcto, instálalo. Verifica con -Doctor. Deja -Target none salvo que te pida
un cliente. No hagas commit ni push.
```

`-Update` y `-Doctor` necesitan el catálogo de nuevo: el proyecto solo conserva `.baseline/` y su manifiesto.

**Modo manual** (si prefieres no ejecutar nada): copia `AGENTS.md` y las skills que uses a `<proyecto>/.baseline/`, y crea un `AGENTS.md` en la raíz que apunte ahí. En un proyecto nuevo, copia además `templates/DEVELOPMENT.md` y completa el mapa.

## Uso con agentes

El formato es `AGENTS.md` + carpeta `skills/` con `SKILL.md` dentro. Eso lo leen openCode, Cline, Kilo Code, Codex y Cursor. Cline y Kilo reciben un puntero en su directorio de reglas; openCode, Codex y Cursor leen `AGENTS.md` directamente (openCode además puede usar `opencode.json`).

La regla es una sola: **la fuente es única**. El contenido vive en `AGENTS.md`; los demás clientes reciben un puntero, nunca una copia.

## Workspace con varios proyectos

Si la carpeta contiene varios proyectos independientes (cada uno con su `.git`), no se instala en la raíz como si fuera uno más. El modelo es de **dos niveles**:

- **Cada proyecto**: su `AGENTS.md`, sus skills y su `DEVELOPMENT.md`. Autosuficiente: se puede mover, abrir solo o pasar a otra carpeta.
- **La raíz**: un `AGENTS.md` de ruteo y un `DEVELOPMENT.md` de composición (qué proyectos hay, cómo se hablan, qué se decidió en transversal). Sin catálogo completo salvo que trabajes siempre desde ahí.

```text
workspace/
├── AGENTS.md              ruteo: qué proyecto es qué y a dónde derivar
├── DEVELOPMENT.md         composición: contratos, puertos, decisiones transversales
├── frontend/              AGENTS.md · DEVELOPMENT.md · sus skills
├── backend/               AGENTS.md · DEVELOPMENT.md · sus skills
└── mockup/                AGENTS.md · DEVELOPMENT.md · sus skills
```

Plantillas: `templates/AGENTS-workspace.md` y `templates/DEVELOPMENT-workspace.md`.

El agente no sabe por sí solo en qué proyecto está: lo sabe porque el `AGENTS.md` de la raíz se lo dice e indica leer el del subproyecto antes de tocar código.

## Verificación

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\tools\verify.ps1
```

Sale `0` si todo está bien, `1` si algo falla. Es el mismo comando que se usa en CI y al cerrar un cambio.

| Comando | Qué valida |
|---|---|
| `check.ps1` | frontmatter, referencias, solapamiento, evals, frescura, encoding, inventario |
| `budget.ps1` | tokens por skill y por descripción |
| `memory.ps1` | rutas del mapa de `DEVELOPMENT.md` que existan |
| `verify.ps1` | los cuatro, agregados |

## Cómo agregar una skill

1. `skills/<nombre>/SKILL.md` con frontmatter (`name`, `description`).
2. `description` con disparadores y el bloque "NO para" nombrando las skills vecinas.
3. El detalle va en `references/` y se cita desde el cuerpo.
4. Al menos un caso positivo y uno negativo en `evals/triggers.json`.
5. `.\tools\verify.ps1` en verde.

Los criterios completos están en `DEVELOPMENT.md`.

## Licencia

MIT — ver [LICENSE](LICENSE).

## Estado

16 skills, 47 casos de eval, verificación en verde (2026-10-23). Los pendientes y las decisiones están en `DEVELOPMENT.md`.
