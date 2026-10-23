---
name: angular
description: "Angular 21+ signal-based (CSR/SSR): componentes, servicios, httpResource/rxResource, listados paginados, formularios, auth, interceptores, performance, a11y. NO para `astro`, `ui-ux-mockup`, `dotnet`/`fastapi`."
---

# SKILL: Angular 21+ — patrón senior

Guía para construir y revisar aplicaciones Angular **signal-based** con criterio senior. Aplica a **CSR** (SPA) y **SSR**; cuando una regla depende del modo se marca **[CSR]** o **[SSR]**. Los ejemplos son genéricos: los nombres concretos de un proyecto de referencia viven en `references/ejemplo-referencia.md` y no son normativos.

**Referencias** (se leen bajo demanda): `references/crud-page.md` (listados y estado agrupado), `references/auth.md` (login, sesión, interceptores, XSS), `references/feedback.md` (error/éxito/confirmación), `references/ssr.md` (Express, proxy, render mode, build), `references/filtro-catalogo.md` (filtro por catálogo), `references/componentes-select.md` (selects y modelos), `references/ejemplo-referencia.md` (nombres y casos del proyecto real).

---

## Cuándo NO usar

| Situación | Skill |
|---|---|
| Sitios de contenido o SSR con Astro | `astro` |
| Diseño visual o mockups previos a implementar | `ui-ux-mockup` |
| Backend de la API | `dotnet` / `fastapi` |

---

## 0. Versión objetivo

**Piso: Angular 21. Probado: 22.x.** Todo lo que sigue asume ese piso; no se escribe código compatible con versiones anteriores.

> **Frescura:** verificado 2026-10-22 · ámbito: Angular 22.1.4 instalado (`httpResource` como `@publicApi 22.0`, `withIncrementalHydration` exportado por `@angular/core`) · fuente: tipos de los paquetes instalados. Al cambiar de major, revalidar.

| Capacidad | Disponibilidad |
|---|---|
| `signal`, `computed`, `effect`, control flow `@if`/`@for`, `@defer`, `input()`/`output()`/`model()` | 21+ |
| `linkedSignal`, `resource`, `rxResource`, `afterRenderEffect`, `provideZonelessChangeDetection` | 21+ |
| `httpResource` | **22.0** (`@publicApi 22.0`, verificado en los tipos de 22.1.4) |
| Hidratación incremental (`withIncrementalHydration`) | 21+ (verificado: exportado por `@angular/core` en 22.1.4) |

**Prohibido por ser legacy**: `NgModule`, `*ngIf`/`*ngFor`/`*ngSwitch`, decoradores `@Input`/`@Output`/`@ViewChild`, `ChangeDetectorRef.detectChanges()` manual, `Renderer2` salvo integración con librerías de terceros, y `ngOnChanges` para derivar estado (usar `computed`/`linkedSignal`).

**Regla de actualización**: al subir de major, contrastar esta tabla con las release notes antes de usarla. Una fila sin enlace verificado no se cita como hecho.

---

## 1. Principios y su costo

Toda decisión tiene un precio. Estas son las que sostienen una app que crece:

| Decisión | Problema que resuelve | Costo que asume |
|---|---|---|
| Estado con signals, sin `subscribe()` en componentes | Estado reactivo declarativo, sin fugas ni valores stale | curva inicial; `effect()` mal usado crea ciclos |
| `rxResource`/`httpResource` para lecturas | `isLoading`/`error`/`value` gratis y cancelación automática | menos control fino que un observable a mano |
| Un `MutationService` para escrituras | Un solo patrón de guardado, error y cierre de modal | una indirección más al leer el código |
| `onClose` solo en éxito | Si la API falla, el modal conserva lo escrito | el llamador debe cerrar explícitamente al cancelar |
| Servicio base para HTTP | URL, headers y errores en un solo lugar | acopla los features al contrato del servicio base |
| Outputs sin prefijo `on` y sin nombres nativos | Evita confundir outputs con eventos DOM | renombrar (`closed`, `clicked`, `submitted`) |
| `OnPush` en todos los componentes | Menos ciclos de detección con signals | exige estado reactivo; mutar estado fuera de signals rompe el render |
| Fuente única de errores (interceptor) | Sin doble manejo ni mensajes contradictorios | el componente pierde control del mensaje |
| Validación local en formularios | El usuario ve el error junto al campo, no en un modal | más markup que un toast |
| Lint + build en cada cierre | El refactor deja de ser a ciegas | unos segundos por corrida |

---

## 2. Stack asumido

| Capa | Tecnología |
|---|---|
| Framework | Angular 21+ signal-based, standalone |
| Bundling | Angular CLI + `pnpm` (nunca `npm` en un proyecto con `pnpm-lock.yaml`) |
| Estilos | Tailwind 4 + DaisyUI 5 (prescindible: si el proyecto usa otro sistema, el patrón no cambia) |
| Estado | signals, `computed`, `linkedSignal` |
| Datos | `httpResource`/`rxResource` para lecturas; servicio de mutaciones para escrituras |
| Lint | ESLint flat config + `angular-eslint` (TS, templates y accesibilidad) |
| Verificación | `ng build` (valida templates) + `pnpm lint` |

> **TypeScript**: fijar la versión compatible con la del Angular instalado; no actualizar TS por separado.

---

## 3. Estructura de carpetas

```text
proyecto/
├── src/server.ts                  → [SSR] Express + proxy + handlers multipart
├── eslint.config.js               → flat config: tsRecommended + templateRecommended + templateAccessibility
└── src/app/
    ├── core/
    │   ├── services/              → api, auth, error, success, confirm, mutation
    │   └── interceptors/          → auth (Bearer, refresh+retry), error (única fuente)
    ├── shared/
    │   ├── base/                  → paginación y estado de listado reutilizable
    │   ├── components/            → button, loading, modal, pagination, select, toast
    │   ├── models/                → pagination, select-item
    │   └── constants/             → rutas y configuración
    └── features/
        └── {domain}/{feature}/
            ├── models/            → Model + SaveModel (fuente única)
            ├── services/          → CRUD y uploads del recurso
            ├── pages/             → listado y formulario de página completa
            ├── components/        → form (modal), list (tabla), select, selected-list
            └── {feature}.routes.ts
```

**Reglas**: un feature CRUD agrupa `models/` + `services/` + `pages/` + `components/`; los componentes viven junto a su feature, nunca en un `components/` global. Nomenclatura singular y sufijo `-component` en archivo, clase y selector. Las páginas nombran el servicio `<feature>Service` y el recurso `getAll<Feature>RX`; nunca `service` genérico.

---

## 4. Decisiones (los cinco forks reales)

Cada fork tiene un default y una condición de cambio. Sin esta tabla, la guía se vuelve dogma.

| Fork | Default | Cuándo cambiar | Costo del cambio |
|---|---|---|---|
| **Formularios** | Modal CRUD simple: template-driven con `linkedSignal` | Validación cruzada, arrays dinámicos, `dirty`/`touched` por campo, tests de lógica: pasar a reactivo tipado (`FormGroup`) | más código y más ceremonia; mejor testeo |
| **Estado de listado** | Objeto agrupado en la página (`{ dataList, isLoading, isSaving, showModal, selectedItem }`) | Dos o más páginas comparten el mismo estado: extraer a servicio | el estado deja de ser local y hay que limpiarlo al salir |
| **Reutilización de paginación** | Composición (`PaginationState` inyectable) | Todas las páginas son idénticas y el equipo ya usa una clase base | la herencia acopla los features y dificulta el test |
| **Lecturas HTTP** | `httpResource` si el request no necesita operadores | `debounceTime`, `switchMap`, `retry` con backoff, combinación de streams: `rxResource` | más código RxJS y suscripciones que gestionar |
| **Render mode** | Contenido público → `Prerender`; datos por request → `Server`; panel autenticado → `Client` | métricas de campo muestren lo contrario | cambiar de modo altera hidratación, caché y SEO |

---

## 5. Capas

### 5.1 Servicios

- **Nunca `HttpClient` en una página o componente**: todo pasa por el servicio del feature y este por el servicio base.
- Query params con `HttpParams`, que ya codifica; `encodeURIComponent` solo si construyes la URL a mano.
- `search` vacío no se envía (`!== ''`); `limit` acotado (1–100) según el contrato de la API.
- Uploads con un único método multipart (`postWithFile<T>()`) y borrado de adjuntos con `deleteResource<T>()`.
- **[CSR]** caché en memoria con TTL solo para catálogos estables, con invalidación explícita.

### 5.2 Listados

- La página implementa `reload()` y conserva sus GETs y mutaciones.
- **Streams puros**: los efectos de paginación (`totalPages.set()`) viven en helpers (`mapPaginated`/`emptyPaginated`), nunca dentro del `map`. Si van en el `map`, la paginación queda stale cuando la request falla.
- Spinner solo en carga inicial: `isLoading() && !hasValue()`; en refetch la lista no se desmonta y conserva el estado de expansión.
- `override` obligatorio al sobrescribir (`noImplicitOverride`), y solo si la firma es compatible: la varianza de `Signal<T>` provoca TS2416 al especializar el payload; en ese caso, un `computed` privado por página es la salida.

### 5.3 Mutaciones

```ts
run<T>(action: Observable<T>, state: { isSaving: WritableSignal<boolean> },
       options?: { successMsg?: string; onSuccess?: () => void; onClose?: () => void }): void {
  state.isSaving.set(true);
  action.pipe(finalize(() => state.isSaving.set(false))).subscribe({
    next: () => { options?.onClose?.(); options?.onSuccess?.(); toast.success(options?.successMsg ?? 'Guardado'); },
    error: (err) => console.error('[MutationService]', err),
  });
}
```

- `next` ya es éxito: no hace falta un flag `succeeded` (un `if (succeeded)` en ese bloque es código muerto).
- `onClose` corre **solo** en éxito: si la API falla, el modal queda abierto con los datos intactos.
- El borrado pide confirmación (`await confirm()` → `boolean`) y pasa el id, no el objeto.
- `isSaving` agrupado por feature, nunca signals sueltas.

### 5.4 Formularios

```ts
protected readonly formData = linkedSignal<SaveModel | null, SaveModel>({
  source: this.model,                                  // input() del modal
  computation: (item) => item ?? this.emptyForm(),     // defaults por campo
});
protected readonly submitForm = output<{ id: number; data: SaveModel }>();
```

- `linkedSignal` con `computation` reacciona al **source**: al cerrar el modal (`null`) el formulario vuelve a defaults sin `effect()` ni `patchValue`.
- `clearTrigger` es para **selects** (limpiar la selección visual), no para el form principal.
- El form emite `{ id, data }`: `id = 0` en creación, `id` real en edición; la página decide create vs update.
- **Regla única de submit**: página completa → `<form (ngSubmit)>` **con `FormsModule` importado**; modal → `<form>` sin evento y botón `type="button"` con `(clicked)`. Sin `FormsModule`, `ngSubmit` no dispara y el navegador hace submit nativo.
- Validación local con `validateFormOnSubmit(): string | null`; el mensaje se muestra junto al campo, nunca como toast ni modal.
- El template lee datos de solo lectura desde `model()`, no desde `formData()`.

### 5.5 Componentes

- Outputs sin prefijo `on` (`submit`, `closed`, `delete`) y sin nombres de eventos nativos (`close`, `click`, `submit`): reglas `no-output-on-prefix` y `no-output-native`. Los **métodos** `onXxx()` sí son correctos.
- `changeDetection: ChangeDetectionStrategy.OnPush` en todos los componentes `app-*`. En zoneless no es obligatorio, pero sigue siendo la estrategia recomendada. **Excepción**: componentes que mutan estado fuera de signals (timers, callbacks de librerías); en ese caso se documenta el motivo o se migra el estado a signals.
- Un output no se invoca como función: `OutputEmitterRef` se emite, no se llama. Nombrar distinto el método y el output evita la colisión.

### 5.6 Selects

- El select emite el **modelo completo** (`output<Model | null>()`), no el id: el consumidor lo agrega directo y se evita un segundo fetch del catálogo.
- Inputs: `selectedId` para preseleccionar y `clearTrigger` para resetear la selección visual.
- La lista de seleccionados recibe `input<Model[]>([])` y emite `delete`; el handler interno hace `preventDefault()`/`stopPropagation()` antes de emitir.

---

## 6. Auth

- **[CSR]** token en el navegador + interceptor funcional que añade `Authorization: Bearer`.
- **[SSR]** sesión por namespace en `sessionStorage` (`auth.{ns}.access_token/refresh_token/user`), `sessionSignal(ns)` reactivo e interceptor con refresh+retry en 401 y `logout(ns)` si el refresh falla.
- **⚠️ Seguridad**: `localStorage`/`sessionStorage` no aíslan el token de JavaScript del mismo origen; un XSS lo roba. Para producción, preferir BFF con cookie `HttpOnly` + `Secure` + `SameSite`. Nunca presentar el storage como frontera de seguridad.
- No escribir signals durante el constructor ni durante el render: en SSR produce comportamiento inconsistente. Usar `effect()` para reacciones y `afterNextRender`/`afterRenderEffect` para lo que depende del DOM.

---

## 7. Feedback

- **Error → modal** disparado por el interceptor: única fuente. Las páginas no llaman `error.show()`.
- **Éxito → toast** en cola con autocierre (~5 s) y cierre manual, solo en escrituras.
- **Confirmación → promise-based**: `await confirm({ title, message })` resuelve `boolean`; la página no toca los outputs del modal.
- Mensaje real: `err?.error?.detail || err?.message || fallback`; el interceptor ya formatea, no sobrescribir con genéricos.
- Los toasts necesitan `aria-live="polite"` para lectores de pantalla.

---

## 8. [SSR] SSR y build

- `src/server.ts`: Express + proxy `/ssr-api/...` + handlers multipart validados con `req.is('multipart/form-data')`.
- `app.routes.server.ts`: `RenderMode` por ruta (`Prerender` para contenido, `Server` para datos por request, `Client` para paneles autenticados).
- `npm start` apunta al servidor de producción (`node dist/.../server/server.mjs`), nunca a `ng serve`.
- `JSON.parse` sobre respuestas del backend siempre con guarda: una respuesta no-JSON debe devolver `{ detail }`, no un 502 opaco.

---

## 9. Performance

- `@defer` con trigger explícito (`on viewport`, `on interaction`, `on idle`, `on timer`) para todo lo que no está en el primer viewport.
- `NgOptimizedImage` para imágenes de contenido: `ngSrc`, `width`/`height` y `priority` solo en la imagen LCP.
- Rutas lazy con `loadComponent`/`loadChildren`; el bundle inicial no incluye features que no se visitan.
- `@for` siempre con `track`.
- `budgets` en `angular.json` con umbrales que fallen el build si el bundle crece sin control.
- **[SSR]** hidratación incremental (`withIncrementalHydration`) para diferir la hidratación de lo que está bajo el fold.

---

## 10. Testing

- Unitarios con `TestBed`; en zoneless, `provideZonelessChangeDetection()` en el setup y `await fixture.whenStable()` en lugar de `fakeAsync` cuando hay promesas.
- Signals: se leen con `signal()` y se asertan por valor; para `computed`, probar la función pura antes que el componente.
- HTTP: `provideHttpClientTesting()` + `HttpTestingController` para verificar URL, método, params y body; no mockear el servicio base salvo en tests de integración.
- `httpResource`/`rxResource`: probar los estados (`isLoading`, `error`, `value`) con el controlador de testing, no con temporizadores reales.
- e2e para los flujos críticos (login, alta, edición, borrado) con el runner que ya use el proyecto; no introducir uno nuevo sin justificarlo.
- Un test que toca base de datos compartida requiere autorización explícita y limpieza aislada.

---

## 11. Accesibilidad

- `<label>` solo con control asociado (`for` + `id` o envoltura); encabezados de sección con `span`, contenedores con `div` (`label-has-associated-control`).
- Elementos clickeables no nativos: `role="button"`, `tabindex="0"` y `keydown.enter`/`keydown.space` (`interactive-supports-focus`, `click-events-have-key-events`).
- Modales: `role="dialog"`, `aria-modal="true"`, foco atrapado dentro (CDK `cdkTrapFocus` si está disponible), cierre con `Esc` y devolución del foco al disparador.
- Toasts y errores asíncronos: `aria-live="polite"`; errores de validación asociados al campo con `aria-describedby`.
- El foco inicial del modal va al primer campo, no al botón de borrar.

---

## 12. Seguridad

- Nada de secretos, tokens ni credenciales en código cliente: todo lo que llega al bundle es público.
- Interpolar texto (Angular escapa por defecto); `innerHTML` solo con contenido propio y sanitizado; `bypassSecurityTrust*` requiere justificación escrita.
- **[SSR]** credenciales de la API solo en el servidor y en variables de entorno; el navegador nunca las recibe.
- BFF con cookie: `HttpOnly` + `Secure` + `SameSite=Lax/Strict` y protección CSRF.
- CSP como defensa en profundidad; no como sustituto del saneamiento.

---

## 13. Checklist universal (10 ítems auditables)

| # | Ítem | Cómo se comprueba |
|---|---|---|
| 1 | `ng build` sin errores (valida templates) | comando |
| 2 | `pnpm lint` sin errores (TS, templates y a11y) | comando |
| 3 | Sin `subscribe()` manual en páginas ni componentes de listado | búsqueda de `.subscribe(` en `features/` |
| 4 | Sin `*ngIf`/`*ngFor`/`NgModule` | búsqueda de `*ngIf`, `NgModule` |
| 5 | Outputs sin prefijo `on` y sin nombres nativos | `no-output-on-prefix`, `no-output-native` |
| 6 | Lecturas con `httpResource`/`rxResource` y estados expuestos | revisión del componente |
| 7 | Formularios con la regla única de submit y `FormsModule` cuando aplica | revisión + build |
| 8 | `OnPush` en componentes, con excepción documentada | búsqueda de `ChangeDetectionStrategy` |
| 9 | A11y: labels asociados, foco en modales, `aria-live` en toasts | lint + revisión |
| 10 | Sin secretos ni credenciales en el cliente | búsqueda de `apiKey`, `secret`, `token =` |

Los criterios específicos de un proyecto (nombres, endpoints, badges en tiempo real) van en `references/ejemplo-referencia.md`, no aquí.

---

## 14. Anti-patrones

| Anti-patrón | Consecuencia |
|---|---|
| `subscribe()` manual para listados | estado stale, fugas, doble fetch |
| `(submit)` en lugar de `(ngSubmit)` | Enter recarga la página y se pierde el formulario |
| `(ngSubmit)` sin `FormsModule` | el evento nunca dispara y el form hace submit nativo |
| Spinner con `isLoading()` a secas | la lista se desmonta en cada refetch |
| `limit` sin tope | el backend responde 422 o degrada |
| Efectos dentro del `map` del recurso | paginación stale cuando falla la request |
| `error.show()` en la página | doble manejo y mensajes contradictorios |
| Outputs `onXxx` o con nombre nativo | colisión con listeners DOM; lint en rojo |
| Select que emite solo el id | obliga a un segundo fetch y vuelve ambiguo el contrato |
| Signals sueltas por feature | estado imposible de seguir y de testear |
| Estado mutado fuera de signals con `OnPush` | el render se congela |
| `*ngIf`/`NgModule` en código nuevo | deuda inmediata; el piso 21+ no lo necesita |
| `JSON.parse` sin guarda en SSR | 502 opaco ante una respuesta no-JSON |
| Tokens en storage presentados como seguros | el XSS los roba; no es una frontera |
| `templateUrl` desactualizado tras renombrar | compila pero el template no carga |
| Comillas dobles e imports relativos | inconsistencia que rompe el lint |

---

## 15. Ejemplo de referencia

Los nombres concretos (`GenreModel`, `book-form-component`, `reservation`, `NotificationBadgeState`, `isEditMode()`) y los casos reales están en `references/ejemplo-referencia.md`. Ese archivo **no es normativo**: si el proyecto cambia de nomenclatura, se actualiza ahí y esta guía sigue siendo válida.
