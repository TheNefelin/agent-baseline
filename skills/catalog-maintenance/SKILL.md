---
name: catalog-maintenance
description: "Crecer el catálogo: crear o editar una skill, description, references, casos de eval, inventario y reglas. Usar al interpretar fallos de check/verify (referencia huérfana, solapamiento, frescura) o al sumar una skill. NO para esquemas de BD (`sql`), código de app (`angular`/`fastapi`/`dotnet`)."
---

# Mantenimiento del catálogo

> Esta skill trata sobre el catálogo mismo, no sobre las apps que se construyen con él.

## Cuándo usar

- Agregar, renombrar o quitar una skill.
- Cambiar una `description` (es el router: decide qué se carga).
- Actualizar el inventario declarado o los casos de eval.
- Interpretar un fallo de `tools/verify.ps1`.

## Cuándo NO usar

| Situación | Dónde |
|---|---|
| Instalar el catálogo en un proyecto | pendiente, futura skill `baseline-install` |
| Escribir código de una aplicación | la skill del stack (`angular`, `fastapi`, `sql`, ...) |
| Diseñar una UI | `ui-ux-mockup` |

## Reglas de estructura

| Regla | Valor | Por qué |
|---|---|---|
| `name` del frontmatter | igual al nombre de la carpeta | si no coincide, el enrutamiento falla |
| `description` | ≤300 caracteres, con disparadores y "NO para ..." | se paga en cada request y es lo único que se lee antes de cargar |
| Cuerpo | ≤300 líneas | el detalle va en `references/` |
| Referencias | prosa ≤40 líneas; con código, sin tope | se leen bajo demanda |
| Vigencia | bloque `verificado YYYY-MM-DD` + ámbito + fuente | sin fecha, el dato envejece sin avisar |
| Nombres de proyecto | solo en `references/ejemplo-referencia.md` | las secciones normativas deben ser genéricas |
| `.ps1` | ASCII puro | un byte >127 suele ser mojibake de consola |

## Agregar una skill

1. Crear `skills/<nombre>/SKILL.md` con `name` y `description`.
2. Escribir el cuerpo con: cuándo usar, cuándo no, criterios y checklist.
3. Mover el detalle a `references/` y citarlo desde el cuerpo con la ruta (`references/x.md`).
4. Agregar casos en `evals/triggers.json`: al menos un positivo y uno negativo.
5. Actualizar el inventario en `DEVELOPMENT.md` (**N skills**, **N casos**).
6. Correr `.\tools\verify.ps1` y dejarlo en verde.

## Editar una description

- Conservar los términos que el usuario escribiría de verdad.
- Nombrar las skills vecinas en el bloque "NO para", con backticks.
- Si cambia el vocabulario, correr `check.ps1`: recalcula el solapamiento Jaccard contra las demás y ejecuta los casos de eval.
- Dos skills que compiten por el mismo pedido se resuelven con negativos explícitos, no acortando.

## Verificación y qué significa cada fallo

| Fallo | Causa | Arreglo |
|---|---|---|
| `frontmatter ausente` | falta el bloque `---` | agregarlo al inicio |
| `name != carpeta` | nombre desalineado | renombrar carpeta o `name` |
| `cuerpo N > 300` | la skill creció | mover detalle a `references/` |
| `referencia no citada` | archivo huérfano en `references/` | citarlo o borrarlo |
| `solapamiento > 0,5` | dos descripciones comparten vocabulario | agregar negativos |
| `eval fallido` | el prompt activa otra skill | ajustar la description, no el caso |
| `frescura vencida` | marcador de más de 180 días | revalidar y actualizar la fecha |
| `encoding` | BOM, CRLF o no-ASCII en `.ps1` | regrabar en UTF-8 sin BOM, LF |
| `inventario` | el conteo declarado no coincide | actualizar `DEVELOPMENT.md` |

## Errores que ya pasaron

- **Description sin comillas con `: ` adentro**: YAML inválido. Entrecomillar siempre.
- **Referencia citada con otro nombre**: `feedback.md` citado como `feedback-ui.md` → huérfana y rota a la vez.
- **Marcador de frescura sin fecha**: el validador lo marca como aviso, y con `-Strict` falla.
- **`.ps1` con acentos**: el editor guarda UTF-8 y el chequeo de encoding lo rechaza.
- **Olvidar el inventario**: el catálogo crece, el README no, y el check falla.

## Checklist

- [ ] `name` = carpeta, `description` ≤300 con negativos
- [ ] Cuerpo ≤300 líneas, detalle en `references/`
- [ ] Referencias citadas y existentes
- [ ] Caso positivo y negativo en `evals/triggers.json`
- [ ] Inventario actualizado en `DEVELOPMENT.md`
- [ ] `.\tools\verify.ps1` en verde
