# Agent Baseline

Reglas, skills y verificación para que cualquier agente de código trabaje igual de bien en cualquier proyecto: mismos criterios, mismo formato, menos tokens y menos invención.

No es un framework ni un generador de apps. Es el **punto de partida** que un repo hereda para que el agente sepa cómo trabajar ahí.

## Qué incluye

- **`AGENTS.md`** — reglas de operación: permisos, Git, idioma, evidencia, flujo, verificación, memoria.
- **`skills/`** — skills por stack, cada una con un cuerpo corto y referencias que se leen solo cuando hacen falta.
- **`evals/triggers.json`** — casos que comprueban que cada pedido activa la skill correcta (y que los negativos no activan ninguna).
- **`tools/`** — verificación automática: estructura, referencias, solapamiento, frescura, encoding, presupuesto de tokens y memoria.
- **`templates/`** — plantillas para proyectos: `DEVELOPMENT.md` con mapa, `session.md`, `SKILL.md` y permisos de cliente.

## Estructura

```text
AGENTS.md              reglas de operación
DEVELOPMENT.md         memoria del catálogo (decisiones y pendientes)
skills/<nombre>/       SKILL.md + references/
evals/triggers.json    casos de enrutamiento
tools/                 check.ps1, budget.ps1, memory.ps1, sync.ps1, test.ps1, verify.ps1, install.ps1
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
└── .baseline-backup/     respaldo de lo que se reemplazó (ignorado por git)
```

Si el proyecto no existe o no tiene stack reconocible, el instalador pregunta antes de asumir. Agrega `-WhatIf` para ver el plan sin escribir nada.

```powershell
.\tools\install.ps1 -Project . -WhatIf        # ver el plan
.\tools\install.ps1 -Project . -Doctor        # verificar hashes
.\tools\install.ps1 -Project . -Update        # refrescar según el manifiesto
.\tools\install.ps1 -Project . -Uninstall     # quitar solo lo instalado
```

`-Update` y `-Doctor` necesitan el catálogo original para funcionar. El proyecto solo conserva `.baseline/` y su manifiesto.

**Prompts para el agente** (pégalos en el chat):

- **Instalar (único proyecto):** `Analiza la estructura. Si hay 1 repositorio .git o es un solo proyecto, instala agent-baseline con tools/install.ps1 -Mode project -Project . Usa -WhatIf primero, detecta o pregunta las skills, deja -Target none salvo que te lo pida explícitamente. Verifica con -Doctor tras instalar. No hagas commit ni push.`
- **Instalar (workspace con varios proyectos):** `Cuenta las carpetas hijas directas con .git. Si hay >=2, instala en modo workspace con tools/install.ps1 -Mode workspace -Workspace .. Usa las plantillas templates/AGENTS-workspace.md y templates/DEVELOPMENT-workspace.md. Cada subproyecto debe seguir siendo autosuficiente. Usa -WhatIf primero. No hagas commit ni push.`
- **Actualizar:** `Actualiza agent-baseline en este proyecto con tools/install.ps1 -Project . -Update usando el manifiesto actual. Revisa con -Doctor tras actualizar. No hagas commit ni push.`
- **Desinstalar:** `Desinstala agent-baseline de este proyecto con tools/install.ps1 -Project . -Uninstall. Conserva AGENTS.md/DEVELOPMENT.md si no son del instalador, respeta opencode.json fusionado y no toques memoria del proyecto. No hagas commit ni push.`

**Modo manual** (si prefieres no ejecutar nada): copia `AGENTS.md` y las skills que uses a `<proyecto>/.baseline/`, y crea un `AGENTS.md` en la raíz que apunte ahí. En un proyecto nuevo, copia además `templates/DEVELOPMENT.md` y completa el mapa.

## Uso con agentes

El formato es `AGENTS.md` + carpeta `skills/` con `SKILL.md` dentro. Eso lo leen openCode, Cline, Kilo Code, Codex y Cursor. Cline y Kilo reciben un puntero en su directorio de reglas; openCode, Codex y Cursor leen `AGENTS.md` directamente (openCode además puede usar `opencode.json`).

La regla es una sola: **la fuente es única**. El contenido vive en `AGENTS.md`; los demás clientes reciben un puntero, nunca una copia.

## Workspace con varios proyectos

Si la carpeta contiene varios proyectos independientes (cada uno con su `.git`), usa el modo **workspace** para enrutar entre ellos. Cada proyecto sigue siendo autosuficiente con su propio `.baseline/`, `AGENTS.md` y `DEVELOPMENT.md`. La raíz queda con `AGENTS.md` de ruteo y `DEVELOPMENT.md` de composición.

**Importante:** No confíes en el menú interactivo en entornos de agentes/CI. Usa explícitamente:

```powershell
# PowerShell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\tools\install.ps1 -Mode workspace -Workspace .
```

```bash
# Linux/macOS con pwsh
pwsh -File ./tools/install.ps1 -Mode workspace -Workspace .
```

Plantillas: `templates/AGENTS-workspace.md` y `templates/DEVELOPMENT-workspace.md`.

## Verificación

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
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

16 skills, 47 casos de eval, verificación en verde. Los pendientes y las decisiones están en `DEVELOPMENT.md`.
