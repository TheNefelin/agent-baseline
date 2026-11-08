# Agent Baseline

Reglas, skills y verificación para que cualquier agente de código trabaje igual en cualquier proyecto: mismos criterios, mismo formato, menos tokens y menos invención.

No es un framework ni un generador de apps. Es el **punto de partida** que un repo hereda para que el agente sepa cómo trabajar ahí.

## Estructura

```text
AGENTS.md              reglas de operación
DEVELOPMENT.md         memoria del catálogo (decisiones y pendientes)
skills/<nombre>/       SKILL.md + references/
evals/triggers.json    casos de enrutamiento
tools/                 check, budget, memory, sync, test, verify, install
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
├── .agents/skills/       adaptador de descubrimiento (generado, gitignored)
├── opencode.json         opcional: config del cliente con -Target opencode
└── .baseline-backup/     respaldo (agregado a .gitignore)
```

Si el proyecto no existe o no tiene stack reconocible, el instalador pregunta antes de asumir. Agrega `-WhatIf` para ver el plan sin escribir nada.

```powershell
.\tools\install.ps1 -Project . -WhatIf        # ver el plan
.\tools\install.ps1 -Project . -Doctor        # verificar la instalación
.\tools\install.ps1 -Project . -Update        # refrescar según el manifiesto
.\tools\install.ps1 -Project . -Uninstall     # quitar solo lo instalado
```

`-Update` y `-Doctor` necesitan el catálogo original. Tras un `git clone`, las reglas funcionan de inmediato; para materializar los adaptadores de descubrimiento (skills nativas en Cline/Codex/Cursor/Kilo) ejecuta una vez `.\tools\install.ps1 -Project . -Update`.

**Modo manual:** copia `AGENTS.md` y las skills que uses a `<proyecto>/.baseline/`, crea un `AGENTS.md` en la raíz que apunte ahí. En proyecto nuevo, copia además `templates/DEVELOPMENT.md`.

**Workspace con varios proyectos:** si la carpeta contiene varios repos (cada uno con `.git`), usa modo workspace. Cada proyecto sigue siendo autosuficiente.

```powershell
.\tools\install.ps1 -Mode workspace -Workspace .
```

Plantillas: `templates/AGENTS-workspace.md` y `templates/DEVELOPMENT-workspace.md`.

## Prompts para el agente

Copia y pega el que corresponda. El agente clona el catálogo dentro del proyecto, ejecuta el instalador y elimina el clon al terminar.

**Instalar (proyecto único):**

```
Analiza la estructura. Si hay 1 repositorio .git o es un solo proyecto, clona https://github.com/TheNefelin/agent-baseline en una carpeta temporal del proyecto, instala agent-baseline con tools/install.ps1 -Mode project -Project . usando -WhatIf primero, detecta o pregunta las skills, deja -Target none salvo que te lo pida explícitamente. Verifica con -Doctor tras instalar. Elimina la carpeta del catálogo al terminar. No hagas commit ni push.
```

**Instalar (workspace):**

```
Cuenta las carpetas hijas directas con .git. Si hay >=2, clona https://github.com/TheNefelin/agent-baseline en una carpeta temporal, instala en modo workspace con tools/install.ps1 -Mode workspace -Workspace . usando las plantillas templates/AGENTS-workspace.md y templates/DEVELOPMENT-workspace.md. Cada subproyecto debe seguir siendo autosuficiente. Usa -WhatIf primero. Elimina la carpeta del catálogo al terminar. No hagas commit ni push.
```

**Actualizar:**

```
Actualiza agent-baseline en este proyecto con tools/install.ps1 -Project . -Update usando el manifiesto actual. Revisa con -Doctor tras actualizar. No hagas commit ni push.
```

**Desinstalar:**

```
Desinstala agent-baseline de este proyecto con tools/install.ps1 -Project . -Uninstall. Conserva AGENTS.md/DEVELOPMENT.md si no son del instalador, respeta opencode.json fusionado y no toques memoria del proyecto. No hagas commit ni push.
```

## Uso con agentes

El formato es `AGENTS.md` + carpeta `skills/` con `SKILL.md` dentro. Lo leen openCode, Cline, Kilo Code, Codex y Cursor. Cline y Kilo reciben un puntero en su directorio de reglas; openCode, Codex y Cursor leen `AGENTS.md` directamente (openCode además puede usar `opencode.json`).

La regla es una sola: **la fuente es única**. El contenido vive en `AGENTS.md`; los demás clientes reciben un puntero, nunca una copia. Los adaptadores de descubrimiento (`.agents/skills/`, `.clinerules/skills/`) son generados y gitignored.

## Verificación

```powershell
.\tools\verify.ps1
```

Sale `0` si todo está bien, `1` si algo falla.

| Comando | Qué valida |
|---|---|
| `check.ps1` | frontmatter, referencias, solapamiento, evals, frescura, encoding, inventario |
| `budget.ps1` | tokens por skill y por descripción |
| `memory.ps1` | rutas del mapa de `DEVELOPMENT.md` que existan |
| `sync.ps1` | copias espejo si existen |
| `test.ps1` | tests mínimos de integración del instalador |
| `verify.ps1` | todos, agregados |

## Agregar una skill

1. `skills/<nombre>/SKILL.md` con frontmatter (`name`, `description`).
2. `description` con disparadores y el bloque "NO para" nombrando las skills vecinas.
3. El detalle va en `references/` y se cita desde el cuerpo.
4. Al menos un caso positivo y uno negativo en `evals/triggers.json`.
5. `.\tools\verify.ps1` en verde.

Criterios completos en `DEVELOPMENT.md`.

## Licencia

MIT — ver [LICENSE](LICENSE).

## Estado

17 skills, 49 casos de eval, verificación en verde. Los pendientes y las decisiones están en `DEVELOPMENT.md`.