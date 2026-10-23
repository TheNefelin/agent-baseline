# Ejemplo de referencia (no normativo)

> Casos reales del proyecto de referencia que originó esta skill. **No son reglas**: si el proyecto cambia, se actualiza este archivo y `SKILL.md` sigue vigente.

## Nomenclatura usada

| Concepto genérico | Nombre en el proyecto |
|---|---|
| `FeatureModel` / `SaveModel` | `GenreModel`, `AuthorModel`, `SubjectModel`, `EditorialModel`, `FormatModel`, `CopyModel` |
| `{feature}-form-component` | `genre-form-component`, `book-form-component` |
| `{feature}-select-component` | `author-select-component`, `subject-select-component` |
| Filtro por estado | `reservation` y `loan` con `StatusModel` |
| Badge en tiempo real | `NotificationBadgeState` |
| Modo edición en formularios | `isEditMode()` |
| Namespace del BFF | `praxis`, `game-guides`, `portfolio` |

## Badge en tiempo real

Patrón del proyecto: WebSocket como canal primario y polling de 30 s **solo** como fallback cuando el WS cae; `disconnect()` dentro de un `effect()` que observa `isAuthenticated`.

- Un solo canal activo a la vez: nunca WS y polling en paralelo.
- Al hacer logout se desconecta y se limpia el estado del badge.
- El polling se cancela al reconectar el WS.

## Modales CRUD del proyecto

Convención dominante: `<form>` sin evento de submit y botón `type="button"` con `(clicked)`, porque el modal ya está dentro de un formulario de página en algunos casos y el submit nativo recargaría.

- Los formularios de página completa sí usan `(ngSubmit)` con `FormsModule`.
- `onClear*` cierra el modal y limpia `selectedItem`.

## Auth del proyecto

- Login con Google OAuth por namespace; el BFF expone el mapa de client IDs en `/ssr-api/config`.
- Sesión en `sessionStorage` con prefijo `auth.{namespace}.access_token/refresh_token/user`.
- El interceptor extrae el namespace de la URL, añade el Bearer y hace refresh+retry en 401.
- Deuda asumida y documentada: tokens en storage (riesgo XSS) a la espera de migrar a cookie `HttpOnly` en el BFF.

## Cifras de referencia

- `limit` máximo aceptado por la API: 100 (por encima responde 422).
- Paginación por defecto: 10 elementos.
- Autocierre de toasts: 5 s.
