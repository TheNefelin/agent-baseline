# Estado del catálogo

## Qué es

Reglas de operación (`AGENTS.md`) más un catálogo de skills reutilizables para agentes de código. Cada skill es un cuerpo corto que se carga siempre y un conjunto de referencias que se leen solo cuando hacen falta.

**16 skills** y **47 casos** de eval de enrutamiento.

## Mapa del proyecto

| Área / tema | Dónde mirar | Cuándo leerlo |
|---|---|---|
| Reglas de operación y permisos | `AGENTS.md` | antes de cualquier tarea |
| Catálogo de skills | `skills/` | al crear, editar o revisar una skill |
| Enrutamiento (descripciones y trampas) | `evals/triggers.json` | al cambiar una `description` |
| Verificación del catálogo | `tools/check.ps1` | antes de cerrar un cambio |
| Presupuesto de tokens | `tools/budget.ps1` | al agregar líneas o skills |
| Memoria sin rutas muertas | `tools/memory.ps1` | al editar este archivo |
| Plantillas de proyecto | `templates/` | al iniciar un proyecto nuevo |

## Estructura

```text
README.md                        qué es, instalación y uso
AGENTS.md                        reglas de operación (112 líneas)
VERSION                          versión actual (semver)
CHANGELOG.md                     historial y criterio de versión
skills/
└── <nombre>/
    ├── SKILL.md                 cuerpo, ≤300 líneas
    └── references/*.md          detalle bajo demanda
evals/triggers.json              47 casos: positivo, ambiguo, frontera, negativo
tools/install.ps1                instalador: -Project, -Workspace, -Update, -Doctor, -Uninstall, -WhatIf
tools/check.ps1                  verificador del catálogo (7 bloques)
tools/budget.ps1                 presupuesto de tokens por skill y por description
tools/memory.ps1                 rutas del mapa de memoria que deben existir
tools/sync.ps1                   copias espejo del workspace sincronizadas por hash
tools/verify.ps1                 corre los cuatro y agrega el resultado
templates/                       plantillas de proyecto y de workspace
```

## Convenciones

- El `name` del frontmatter coincide con el nombre de la carpeta.
- La `description` es el router: ~220 caracteres, con los disparadores reales y el bloque "NO para" nombrando las skills vecinas.
- El cuerpo no repite lo que ya vive en otra skill: se referencia (`sql`, `docker`, etc.).
- Referencias: prosa ≤40 líneas; las que llevan código pueden ser más largas.
- Bloque `> **Frescura:** verificado <fecha> · ámbito · fuente` en cada skill que afirme versiones.
- Los nombres de un proyecto concreto van en `references/ejemplo-referencia.md`, nunca en las secciones normativas.

## Decisiones

| Fecha | Estado | Decisión | Motivo |
|---|---|---|---|
| 2026-10-23 | Aceptado | Instalación **por proyecto**, nunca en la raíz del workspace | Un agente abierto en un subproyecto no ve la carpeta padre |
| 2026-10-23 | Aceptado | Modelo de **dos niveles**: proyecto (trío propio) y workspace (ruteo + composición) | Cada proyecto queda portable; la raíz solo aporta lo transversal |
| 2026-10-23 | Aceptado | El ruteo es **documentado**, no un orquestador en runtime | El `AGENTS.md` de la raíz indica a qué subproyecto derivar |
| 2026-10-23 | Aceptado | Instalación **local por defecto**; el global versionado queda como opción posterior | El catálogo viaja con el repo y paga solo las skills que ese proyecto usa |
| 2026-10-23 | Aceptado | `-Uninstall` borra solo lo que agregó y conserva `DEVELOPMENT.md` y `README.md` | La memoria es del usuario, no del instalador |
| 2026-10-23 | Aceptado | Copias espejo en la carpeta padre (`AGENTS.md` y skill de mantenimiento) | Un agente abierto en la raíz del workspace debe leer las reglas; `sync.ps1` verifica que no deriven |
| 2026-10-23 | Propuesto | `harness/skills/` ignorado en git y materializado con `-Update` | Diffs limpios; falta confirmarlo con el instalador |

## Plantillas

| Archivo | Para qué | Dónde va |
|---|---|---|
| `README.md` | descripción, instalación y uso de un proyecto | raíz del proyecto |
| `DEVELOPMENT.md` | memoria del proyecto: mapa, decisiones, pendientes | raíz del proyecto |
| `SKILL.md` | criterios técnicos propios de un proyecto | raíz del proyecto |
| `session.md` | checkpoint de tarea larga | `.harness/session.md` |
| `AGENTS-workspace.md` | reglas de ruteo de un workspace multi-proyecto | raíz del workspace |
| `DEVELOPMENT-workspace.md` | composición: contratos y decisiones transversales | raíz del workspace |
| `targets/opencode.json` | config del cliente openCode: reglas + skills + permisos | raíz del proyecto, como `opencode.json` |
| `targets/cline.md` | puntero para Cline | `.clinerules/agent-baseline.md` |
| `targets/kilo.md` | puntero para Kilo Code | `.kilocode/rules/agent-baseline.md` |

Todo lo que está en `targets/` es **específico de un cliente**. El catálogo (reglas y skills) es agnóstico; esta carpeta solo traduce a cada cliente. El instalador resuelve `targets\<cliente>.*` según `-Target`: `opencode`, `cline`, `kilo` o `none`.

**Clientes que NO necesitan target**: Codex, Cursor y DeepSeek Harness leen `AGENTS.md` en la raíz del proyecto (Cursor y DSH también en subcarpetas), y ese puntero ya lo escribe el instalador. Un target para ellos sería un archivo redundante.

`opencode.json` traduce las reglas de Git y secretos a permisos que el cliente hace cumplir; los punteros de Cline y Kilo solo derivan a `.baseline/AGENTS.md`.

## Instalador

| Comando | Qué hace |
|---|---|
| `-Project <ruta>` | copia `.baseline/` (AGENTS.md, VERSION, skills), escribe el manifiesto y el puntero `AGENTS.md`, y crea o fusiona `opencode.json` |
| `-Workspace <ruta>` | escribe `AGENTS.md` de ruteo y `DEVELOPMENT.md` de composición; no copia skills |
| `-Update` | lee `.baseline.json`, refresca **esas** skills y **ese** target, y reescribe el manifiesto conservando lo previo |
| `-Doctor` | compara hashes del manifiesto y avisa si la versión instalada quedó atrás |
| `-Uninstall` | quita `.baseline/`, el puntero, y `opencode.json` si lo creó el instalador; conserva la memoria |
| `-WhatIf` | imprime el plan sin escribir |

**Contrato de uninstall**: borra solo lo que agregó, deja `.baseline-backup/<fecha>/` con lo reemplazado, y nunca toca `.git`, `DEVELOPMENT.md` ni `README.md`.

## Herramientas

```powershell
# todo en uno (sale 0 si está todo bien)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\tools\verify.ps1

# por separado, con parámetros
.\tools\check.ps1 -MaxBodyLines 300 -MaxDescription 400
.\tools\check.ps1 -Strict -MaxAgeDays 120
.\tools\budget.ps1 -MaxSkillTokens 7000 -MaxDescriptionChars 300
.\tools\memory.ps1 -RequireMap
```

`check.ps1` valida: frontmatter y `name` = carpeta, YAML citado, cuerpo ≤300, referencias citadas y alcanzables, solapamiento Jaccard entre descripciones, los 47 casos de eval, frescura de los marcadores, encoding (UTF-8 sin BOM, LF) e inventario declarado.

`budget.ps1` mide lo que se paga: caracteres de cada description (cada request) y tokens de cada cuerpo (al abrir la skill). Falla si una se pasa del límite.

`memory.ps1` comprueba que cada ruta del mapa de este archivo exista. Un mapa con rutas muertas manda al agente a leer algo que ya no está.

`sync.ps1` compara por hash las copias espejo que viven en la carpeta padre (`AGENTS.md` y la skill de mantenimiento). Si la copia no existe —porque el proyecto se movió— informa "sin copia espejo" y no falla.

## Validado (2026-10-23)

- `check.ps1` en verde: 0 fallos, 0 avisos.
- 16 skills, `name` = carpeta en 16/16.
- 0 referencias rotas, 0 huérfanas, 0 solapamientos sobre 0,5.
- 47/47 casos de eval correctos.
- Todas ≤300 líneas de cuerpo.
- Descripciones: 1.289 → **750 tokens por request** (−42%).
- Peor caso por request: **~6.359 tokens** (`fastapi` con su description).
- Catálogo en disco: ~42.984 tokens (suma de cuerpos, sin references).
- `AGENTS.md`: 222 → 112 líneas, con regla de desempate entre skills, ruteo de workspace y las cuatro reglas recuperadas del repo.
- Instalador probado en proyectos falsos: instalar, `-Doctor`, `-Update`, `-Uninstall` y `-Workspace`; tras el uninstall solo queda `.baseline-backup/`.

## Pendientes

1. `fastapi/references/auth.md` — profundizar: rotación de refresh con detección de reuso, revocación, cookies `HttpOnly`, bloqueo por intentos y tests del flujo.
2. **Modo global versionado** (`~/.baseline/versions/<v>/`): una sola copia, actualizada una vez, con `.baseline.json` por proyecto apuntando a su versión. Requiere decidir el puntero con ruta absoluta y su rotura al cambiar de máquina.
3. **`fleet status` / `fleet update`**: cuando haya más de ~10 proyectos. Necesita el manifiesto (ya existe) y políticas `track`/`pin`/`window`, con `-Canary` para no actualizar 60 proyectos a ciegas.
4. `CONTRIBUTING.md`: criterios para agregar o editar skills (hoy viven en este archivo).
5. `ui-ux-mockup` sigue sin referencias (274 líneas en un solo archivo).
6. Revisar profundidad de `aws`, `azure` y `oci` (102–104 líneas cada una).
7. Evaluar `harness-freshness` como skill 16: audita que las afirmaciones de versión sigan vigentes.

## Cómo agregar una skill

1. Crear `skills/<nombre>/` con `SKILL.md` y frontmatter (`name`, `description`).
2. Escribir la `description` con disparadores y negativos.
3. Mover el detalle a `references/` y citarlo desde el cuerpo.
4. Agregar al menos un caso positivo y uno negativo en `evals/triggers.json`.
5. Ejecutar `tools/check.ps1` y dejarlo en verde.
