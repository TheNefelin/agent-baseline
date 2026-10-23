# AGENTS.md — workspace multi-proyecto

> Esta carpeta **no es un proyecto**: es un workspace con varios proyectos independientes, cada uno con su repositorio y su stack. Aquí no se instalan dependencias, no se compila y no se corre nada.

## Regla de ruteo

Antes de tocar código, identifica a qué proyecto pertenece la tarea y lee, en este orden:

1. `<proyecto>/AGENTS.md` — reglas de ese proyecto: alcance, permisos, comandos.
2. `<proyecto>/DEVELOPMENT.md` — su mapa: área → dónde mirar → cuándo.
3. El `SKILL.md` del proyecto, si tiene criterios técnicos propios.

**El stack del subproyecto manda.** Este archivo solo aporta lo transversal; si hay conflicto, gana el del proyecto.

## Proyectos

| Proyecto | Ruta | Stack | Qué hace |
|---|---|---|---|
| _(ejemplo)_ frontend | `frontend/` | Angular 22 | interfaz de usuario |
| _(ejemplo)_ backend | `backend/` | FastAPI | API REST |
| _(ejemplo)_ mockup | `mockup/` | HTML/CSS | diseño previo, no producción |

Completar esta tabla al agregar un proyecto: es lo único que le dice al agente qué existe.

## Reglas transversales

- Los comandos (`install`, `build`, `test`) se ejecutan **dentro** de cada proyecto, nunca en la raíz.
- Un cambio que cruza proyectos (contrato de API, tipos compartidos) se hace en los dos y se anota en el `DEVELOPMENT.md` de la raíz.
- No toques el `.git` de un subproyecto desde otro.
- Si el pedido no dice a qué proyecto pertenece y hay más de uno posible, pregunta antes de asumir.
- Los pendientes y decisiones de composición viven en el `DEVELOPMENT.md` de la raíz; los de cada proyecto, en el suyo.
