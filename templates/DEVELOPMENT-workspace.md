# Desarrollo del workspace

> Memoria de composición: qué proyectos hay, cómo se hablan y qué se decidió a nivel transversal. El detalle de cada proyecto vive en su propio `DEVELOPMENT.md`; aquí solo lo que los cruza.

## Mapa de proyectos

| Proyecto | Ruta | Stack | Puerto | Depende de | Cuándo leer su DEVELOPMENT.md |
|---|---|---|---|---|---|
| | `frontend/` | | | `backend/` | al tocar UI o contratos de API |
| | `backend/` | | | — | al tocar endpoints o modelos |
| | `mockup/` | | | — | antes de implementar un rediseño |

Esta tabla es el índice: el agente la lee primero y abre solo el destino que corresponde.

## Contratos entre proyectos

| Contrato | Dónde se define | Quién consume | Estado |
|---|---|---|---|
| _(ejemplo)_ API de productos | `backend/` → `/api/products` | `frontend/` | Aceptado |

Un contrato que cambia obliga a tocar los dos lados y a anotarlo acá.

## Decisiones transversales

| Fecha | Estado | Decisión | Motivo |
|---|---|---|---|
| | Aceptado / Propuesto / Pendiente | | |

Solo decisiones que sobrevivan a la sesión. Lo no confirmado se anota como `Pendiente`, no como hecho.

## Estado

- [ ] ...
- **Siguiente paso:** ...

## Pendientes

- ...

## Problemas conocidos

- ...
