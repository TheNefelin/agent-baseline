# Auth (CSR y SSR)

> Detalle de la sección **Auth** de la skill `angular`. Léelo al implementar login, sesión, interceptores o manejo de tokens.

El patrón de auth difiere según el modo.

## [CSR] — Auth directo

- La API se consume directo desde `environment.apiUrl`; el `authInterceptor` añade `Authorization: Bearer <token>`.
- El token se guarda en el navegador (`localStorage` o `sessionStorage` según la app; `localStorage` sobrevive al cierre de pestaña).
- `authInterceptor` (funcional, `HttpInterceptorFn`): lee el token y clona el request con el header.
- Guardo simple: no hay multi-tenant ni proxy.

### Orden de los interceptores (401 → refresh → retry, sin toast falso)

El `authInterceptor` debe ir **por DENTRO** del interceptor de errores:

```ts
provideHttpClient(withInterceptors([errorInterceptor, authInterceptor]))
```

**Por qué importa el orden:** los interceptores se ejecutan de fuera adentro. Si el `authInterceptor` va primero (por fuera), el 401 sube al `errorInterceptor` **antes** de que el refresh lo resuelva → el usuario ve un toast de error aunque la sesión se recupere (falso positivo). Con `authInterceptor` por dentro, el 401 se resuelve (refresh+retry) **antes** de llegar al manejador de errores.

Además, el `errorInterceptor` **no debe mostrar toast en 401**: un 401 que llega ahí ya significa "el refresh falló → sesión muerta → el `authInterceptor` hizo logout+redirect". Un toast extra sería ruido duplicado.

- En el 401: el `authInterceptor` pide `/auth/refresh`, guarda el nuevo par y **reintenta** la petición original; si el refresh falla → limpia sesión + redirige al login.
- **Nunca** reintentar refresh sobre `/auth/refresh` ni `/auth/logout` (evita bucles).

## [CSR/SSR] — SDKs de terceros dentro del servicio, no en `index.html`

> **No** cargar el SDK de un proveedor (`accounts.google.com/gsi/client`, Stripe, etc.) con un `<script>` fijo en `index.html`. Inyectarlo **desde el servicio** que lo usa.

**Problema del `<script>` global:** se carga en **todas** las rutas (aunque el usuario nunca vea el login), y el servicio no sabe cuándo está listo → obliga a *polling* manual de `window.<sdk>` (frágil).

**Patrón (carga bajo demanda, idempotente):**

```ts
@Service()
export class AuthGoogleService {
  private readonly platformId = inject(PLATFORM_ID);
  private readonly isBrowser = isPlatformBrowser(this.platformId);
  private scriptPromise: Promise<void> | null = null;

  private ensureSdkLoaded(): Promise<void> {
    if (!this.isBrowser) return Promise.reject(new Error('Solo navegador'));
    this.scriptPromise ??= this.loadScript().catch((e) => { this.scriptPromise = null; throw e; });
    return this.scriptPromise;
  }

  private loadScript(): Promise<void> {
    return new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = 'https://accounts.google.com/gsi/client';
      s.async = true;
      s.onload = () => resolve();
      s.onerror = () => reject(new Error('No se pudo cargar el SDK'));
      document.head.appendChild(s);
    });
  }
}
```

- `??=` garantiza **una sola** carga aunque haya llamadas concurrentes; el `.catch` resetea para permitir reintento.
- Guarda `isPlatformBrowser()` para SSR; timeout explícito si se desea.
- Encapsula el ciclo de vida del SDK en **un solo lugar** (el servicio), sin acoplar `index.html`.

## [SSR] — Auth multi-tenant (por namespace)

```text
GET /ssr-api/config                    → { googleClientIds } (mapa por namespace)
POST /ssr-api/{namespace}/auth/google  → login con el client ID de ese namespace
GET/POST/DELETE /ssr-api/{namespace}/{resource}  → CRUD con Bearer del namespace
```

- **Sesión**: `sessionStorage` con prefijo `auth.{namespace}.access_token/refresh_token/user` — sobrevive a F5, muere al cerrar la pestaña.
- **⚠️ Seguridad (XSS)**: `sessionStorage`/`localStorage` **no** aíslan los tokens de JavaScript del propio origen: un XSS puede robarlos. Para producción, preferir un **BFF con cookie `HttpOnly` + `Secure` + `SameSite`** para el refresh token (esta app ya tiene BFF `/ssr-api`). Si se mantiene el token en storage, asumir el riesgo y reforzar CSP + sanitización; nunca presentar `sessionStorage` como frontera de seguridad.
- **`sessionSignal(ns)`** reactivo por namespace: `login()`/`logout()` lo actualizan → el UI se desloguea solo cuando el interceptor fuerza logout.
- **authInterceptor**: extrae ns de la URL, añade `Authorization: Bearer`, hace refresh+retry en 401. Si el refresh falla → `logout(ns)` (limpia sesión + signal).
- **Client ID por app**: el BFF expone el mapa y el AuthService lo cachea; lanza error claro si no está configurado.

## [SSR] — No escribir signals durante el render

- **Nunca escribir signals en el constructor ni durante el render**: en SSR el orden de inicialización no es el del navegador y el estado queda inconsistente entre servidor y cliente. Usar `effect()` para reacciones y `afterNextRender`/`afterRenderEffect` para lo que depende del DOM.
- Las escrituras que sí son seguras van en manejadores de eventos o en `effect()`, nunca en el cuerpo del constructor.
