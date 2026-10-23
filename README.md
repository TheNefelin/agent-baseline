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

Qué deja en el proyecto:

```text
frontend/
├── .baseline/            AGENTS.md, VERSION y las skills instaladas
├── .baseline.json        manifiesto: versión, skills, hashes
├── AGENTS.md             puntero de 4 líneas a .baseline/AGENTS.md
├── opencode.json         config del cliente (creada o fusionada)
└── .baseline-backup/     respaldo de lo que se reemplazó
```

Si el proyecto no existe o no tiene stack reconocible, el instalador pregunta antes de asumir. Agrega `-WhatIf` para ver el plan sin escribir nada.

```powershell
.\tools\install.ps1 -Project . -WhatIf        # ver el plan
.\tools\install.ps1 -Project . -Doctor        # verificar hashes
.\tools\install.ps1 -Project . -Update        # refrescar según el manifiesto
.\tools\install.ps1 -Project . -Uninstall     # quitar solo lo instalado
```

**Modo manual** (si prefieres no ejecutar nada): copia `AGENTS.md` y las skills que uses a `<proyecto>/.baseline/`, y crea un `AGENTS.md` en la raíz que apunte ahí. En un proyecto nuevo, copia además `templates/DEVELOPMENT.md` y completa el mapa.

## Uso con agentes

El formato es `AGENTS.md` + carpeta `skills/` con `SKILL.md` dentro. Eso lo leen openCode, Cline, Kilo Code, Codex y Cursor (los tres últimos mediante un archivo puntero en su directorio de reglas).

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
| `verify.ps1` | los tres, agregados |

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
