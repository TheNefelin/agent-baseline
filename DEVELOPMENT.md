# Estado del catálogo

## Qué es

Reglas de operación (`AGENTS.md`) más un catálogo de skills reutilizables para agentes de código. Cada skill es un cuerpo corto que se carga siempre y un conjunto de referencias que se leen solo cuando hacen falta.

**18 skills** y **51 casos** de eval de enrutamiento.

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

## Convenciones

- El `name` del frontmatter coincide con el nombre de la carpeta.
- La `description` es el router: ~220 caracteres, con los disparadores reales y el bloque "NO para" nombrando las skills vecinas.
- El cuerpo no repite lo que ya vive en otra skill: se referencia (`sql`, `docker`, etc.).
- Referencias: prosa ≤40 líneas; las que llevan código pueden ser más largas.
- Bloque `> **Frescura:** verificado <fecha> · ámbito · fuente` en cada skill que afirme versiones.
- Los nombres de un proyecto concreto van en `references/ejemplo-referencia.md`, nunca en las secciones normativas.

## Decisiones

Solo lo que sigue vigente. Lo replaced no se conserva: el historial está en `CHANGELOG.md`.

| Fecha | Estado | Decisión | Motivo |
|---|---|---|---|
| 2026-10-23 | Aceptado | Instalación **por proyecto**, nunca en la raíz del workspace; modelo de **dos niveles** (proyecto y workspace) con ruteo **documentado**, no orquestador en runtime | Un agente abierto en un subproyecto no ve la carpeta padre; cada proyecto queda portable y la raíz solo aporta lo transversal |
| 2026-10-23 | Aceptado | Instalación **local por defecto**; el global versionado queda como opción posterior | El catálogo viaja con el repo y paga solo las skills que ese proyecto usa |
| 2026-10-23 | Aceptado | `-Uninstall` borra solo lo que agregó y conserva `DEVELOPMENT.md` y `README.md` | La memoria es del usuario, no del instalador |
| 2026-10-23 | Aceptado | Copias espejo en la carpeta padre (`AGENTS.md` y skill de mantenimiento), verificadas por hash | Un agente abierto en la raíz del workspace debe leer las reglas; `sync.ps1` detecta la deriva |
| 2026-10-23 | Aceptado | `-Target` por defecto `none`: el instalador no asume ningún cliente | Sin cliente pedido no debe escribir archivos que el proyecto no usa |
| 2026-10-23 | Aceptado | El manifiesto hashea todo `.baseline/` (incluye `VERSION` y `references/*.md`); `-Skills` y `-Target` se validan antes de escribir | `-Doctor` debe detectar cualquier deriva, y un typo no debe dejar `.baseline/` a medias |
| 2026-10-23 | Aceptado | `-Update` deja `skills/` como espejo y, si cambia el target, retira el anterior | `.baseline/skills/` y el campo `skills` del manifiesto deben describir el mismo conjunto, sin archivos huérfanos al migrar de cliente |
| 2026-10-31 | Aceptado | Memoria: presupuesto blando 4.500 y duro 6.000 caracteres, auditoría en la skill `memoria`; el título del mapa empieza por `Mapa` | El historial se paga en cada turno; en un proyecto real 8.663 caracteres bajaron a 4.064 sin perder nada operativo |
| 2026-10-31 | Aceptado | El checkpoint de sesión vive en `.baseline/session.md` y `AGENTS.md` §11 dice cuándo **no** reescribir la memoria | El instalador ya lo crea ahí; las reescrituras por turno solo gastan contexto |
| 2026-11-01 | Aceptado | El puntero `AGENTS.md` declara las skills instaladas con su ruta | Con `-Target none` por defecto, ningún cliente sabía que existían y el agente trabajaba sin ellas |
| 2026-11-08 | Aceptado | Los punteros de Cline y Kilo se generan en código, sin plantilla por cliente | Una plantilla duplicaba el texto y derivaba; `templates/targets/` queda solo para `opencode.json` |
| 2026-11-08 | Aceptado | 0.3.0: adaptadores de descubrimiento **materializados y enlazados** (junction en Windows, symlink en Unix) desde `.baseline/skills` a `.agents/skills` y `.clinerules/skills`; `-Doctor` separa salud de preparación; prohibiciones críticas inline en los punteros | El descubrimiento nativo fuera de openCode fallaba. La fuente única se mantiene en git y el adaptador es local, gitignored y sin duplicar datos |
| 2026-11-08 | Aceptado | `-Doctor` sale 1 si falta el puntero, el target o una skill instalada; la versión atrasada queda como aviso | Un verde estructural no debe ocultar una instalación incoherente |
| 2026-11-11 | Aceptado | Los respaldos van en carpeta única por operación y se numeran si el destino ya existe; los enlaces rotos se borran sin tocar su destino | Dos operaciones en el mismo segundo anidaban `.baseline/.baseline` y un junction con destino ausente quedaba huérfano |

## Instalador

| Comando | Qué hace |
|---|---|
| `-Project <ruta>` | copia `.baseline/` (AGENTS.md, VERSION, skills), escribe el manifiesto, el puntero `AGENTS.md` y agrega `.baseline-backup/` a `.gitignore` |
| `-Target <cliente>` | cliente a configurar: `none` (por defecto), `opencode`, `cline` o `kilo`; con `none` no escribe archivos de cliente |
| `-Workspace <ruta>` | escribe `AGENTS.md` de ruteo y `DEVELOPMENT.md` de composición; no copia skills |
| `-Update` | lee `.baseline.json`, refresca el conjunto declarado (reemplaza cada skill y quita las no incluidas), cambia el target si se pide —retirando el anterior— y reescribe el manifiesto |
| `-Doctor` | compara hashes y valida el puntero `AGENTS.md`, los archivos del target, que las skills instaladas coincidan con el manifiesto y que los adaptadores estén sincronizados; avisa de derivas y de versión atrasada |
| `-Uninstall` | quita `.baseline/`, el puntero, el archivo del target, los punteros conocidos de Cline/Kilo y los adaptadores materializados; conserva la memoria y la entrada de `.gitignore` |
| `-WhatIf` | imprime el plan sin escribir |

**Contrato de uninstall**: borra solo lo que agregó, deja `.baseline-backup/<sello>/` con lo reemplazado, y nunca toca `.git`, `DEVELOPMENT.md` ni `README.md`. La entrada de `.gitignore` se conserva porque los respaldos siguen en disco.

## Adaptadores de descubrimiento

Las skills viven en una sola fuente: `.baseline/skills/`. Para que Codex, Cursor, Kilo y openCode las descubran sin configuración, y Cline por su vía propia, el instalador materializa **enlaces** (no copias) en `.agents/skills/` y `.clinerules/skills/`. Ambos paths están en `.gitignore`: en git solo existe la fuente.

| Cliente | Descubre skills en | Reglas en |
|---|---|---|
| openCode | `.agents/skills/` y `.baseline/skills` (por config) | `AGENTS.md` y `opencode.json` |
| Codex, Cursor, Kilo | `.agents/skills/` | `AGENTS.md` |
| Cline | `.clinerules/skills/` | `.clinerules/agent-baseline.md` y `AGENTS.md` |
| DeepSeek Harness | sin verificar | `AGENTS.md` |

El puntero de `AGENTS.md` incluye las prohibiciones críticas (Git mutante, `.env` real, borrado masivo) para que estén en contexto aunque el agente no abra `.baseline/AGENTS.md`.

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

- `check.ps1` — frontmatter y `name` = carpeta, YAML citado, cuerpo ≤300, referencias citadas y alcanzables, solapamiento Jaccard entre descripciones, los 49 casos de eval, frescura, encoding (UTF-8 sin BOM, LF; `.ps1` en ASCII), inventario declarado y entrada de `VERSION` en `CHANGELOG.md`.
- `budget.ps1` — mide lo que se paga: caracteres de cada description (cada request) y tokens de cada cuerpo (al abrir la skill).
- `memory.ps1` — comprueba que cada ruta del mapa de este archivo exista. Un mapa con rutas muertas manda al agente a leer algo que ya no está.
- `sync.ps1` — compara por hash las copias espejo de la carpeta padre. Si la copia no existe, informa y no falla.
- `test.ps1` — tests de integración del instalador.

## Estado verificado

- `tools/verify.ps1` en verde: check, budget, memory, sync y 23/23 casos del instalador.
- 18 skills con `name` = carpeta, 51/51 casos de eval, 0 referencias rotas, 0 huérfanas, 0 solapamientos sobre 0,5, todas ≤300 líneas.
- Ciclo completo en un proyecto temporal con `.git`: `install` → `-Update` → `-Doctor` → `-Uninstall`, sin errores; solo quedan `.git`, `.baseline-backup/` y `.gitignore`.
- Los adaptadores son enlaces verificados: un archivo nuevo en `.baseline/skills/` aparece en `.agents/skills/`.
- **Sin verificar**: la carga real de `opencode.json`, de los punteros y de los adaptadores por sus clientes (no hay ninguno instalado en esta máquina); tampoco se probó `-Workspace` en un workspace real ni la ejecución nativa en Linux/macOS.

## Pendientes

1. `fastapi/references/auth.md` — profundizar: rotación de refresh con detección de reuso, revocación, cookies `HttpOnly`, bloqueo por intentos y tests del flujo.
2. **Modo global versionado** (`~/.baseline/versions/<v>/`): una sola copia, actualizada una vez, con `.baseline.json` por proyecto apuntando a su versión. Requiere decidir el puntero con ruta absoluta y su rotura al cambiar de máquina.
3. **`fleet status` / `fleet update`**: cuando haya más de ~10 proyectos. Necesita el manifiesto (ya existe) y políticas `track`/`pin`/`window`, con `-Canary` para no actualizar 60 proyectos a ciegas.
4. `CONTRIBUTING.md`: criterios para agregar o editar skills (hoy viven en este archivo y en el README).
5. `ui-ux-mockup` sigue sin referencias (274 líneas en un solo archivo).
6. Revisar profundidad de `aws`, `azure` y `oci` (102–104 líneas cada una).
7. Evaluar `harness-freshness` como skill nueva: audita que las afirmaciones de versión sigan vigentes.
8. Verificar en runtime `opencode.json` y los adaptadores (carga de skills y permisos). El esquema ya está validado contra `https://opencode.ai/config.json` (2026-11-01): `permissions` es `array<{action, resource, effect}>` y `skills` es `array<string>`, igual que el template. Falta comprobar que cada cliente los descubra y aplique las reglas.
9. **Soporte multi-target**: `-Target` como lista y conservar las puertas de los clientes no declarados. Hoy cambiar de target borra el puntero anterior (pasar a `opencode` elimina `.clinerules/agent-baseline.md`), y el manifiesto ya guarda `targets` como array.
10. **`-Update` en un workspace**: un workspace no tiene manifiesto, así que `-Update` falla con el mensaje de instalación. Decidir si necesita su propio manifiesto o un refresco de plantillas.
11. El instalador no comprueba que la plantilla que copia exista: si falta `templates/targets/opencode.json`, la fusión se omite en silencio. Validarla antes de escribir.
12. Verificar que cada skill citada en `AGENTS.md` exista en `skills/`; hoy una cita a una skill retirada no rompe `check.ps1`.
13. Unificar la fuente de proxy, CSP y `allowedHosts`: `angular/references/ssr.md` y `auth.md` se solapan y pueden derivar.
