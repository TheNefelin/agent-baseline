# Auth (CSR y SSR)

> Detalle de la sección **Auth** de la skill `angular`. Léelo al implementar login, sesión, interceptores o manejo de tokens.

El patrón de auth difiere según el modo.

## [CSR] — Auth directo (patrón simple, sin BFF)

- La API se consume directo desde `environment.apiUrl`; el `authInterceptor` añade `Authorization: Bearer <token>`.
- El token se guarda en el navegador (`localStorage` o `sessionStorage`); **riesgo XSS conocido** — solo para MVPs sin datos sensibles.
- `authInterceptor` (funcional, `HttpInterceptorFn`): lee el token y clona el request con el header.
- Guard simple: no hay multi-tenant ni proxy.

> **Para producción con datos sensibles**, usar el patrón BFF + HttpOnly de la sección siguiente.

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

## [SSR] — Auth con BFF + HttpOnly + CSRF (patrón senior, recomendado para producción)

El BFF (Express en `src/server/`) es el **único** que conoce la URL real de la API y la API Key. El navegador solo habla con `/ssr-api` (mismo origen).

### Arquitectura

```
Navegador ──cookie HttpOnly──> /ssr-api (BFF/Express) ──X-API-Key + Bearer──> FastAPI
```

- **Tokens**: el BFF guarda `access_token` y `refresh_token` en cookies `HttpOnly; SameSite=Lax; Secure` (prod). El navegador **nunca** ve un token.
- **`environment.apiUrl = '/ssr-api'`** (mismo origen). No hay CORS en el navegador.
- **`authInterceptor` se RETIRA**: el BFF pone el `Authorization: Bearer` leyendo la cookie.
- **`authGuard` es asíncrono**: pregunta `/auth/me` (la cookie no es legible por JS).
- **`AuthStoreService`** solo guarda un flag `hasSession` (no tokens).

### Proxy (src/server/proxy/api-proxy.ts)

- Reenvía `/ssr-api/*` → `${API_URL}/*` añadiendo `X-API-Key`.
- En endpoints de token (`/auth/login`, `/register`, `/google`, `/refresh`): extrae los tokens del JSON, los guarda en cookies HttpOnly y devuelve el body **sin tokens**.
- En 401: intenta refrescar con `refresh_token` cookie y reintenta una vez.
- En `/auth/logout`: borra las cookies.
- Filtra cabeceras hop-by-hop (`host`, `connection`, `content-length`, `transfer-encoding`, `content-encoding`, `set-cookie`, `cookie`).

### CSRF (doble envío)

- El BFF emite una cookie legible `csrf_token` (NO HttpOnly) en los endpoints de token.
- El cliente lee la cookie y envía `X-CSRF-Token` en peticiones mutantes (POST/PUT/DELETE/PATCH).
- El BFF compara: cookie == header. Si no coinciden → 403.
- `SameSite=Lax` bloquea el 95% de CSRF; el doble envío cierra el 5% restante.

### Interceptor CSRF (frontend)

```ts
export const csrfInterceptor: HttpInterceptorFn = (req, next) => {
  const isMutating = ['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method.toUpperCase());
  const isApiRequest = req.url.startsWith('/ssr-api');
  if (isMutating && isApiRequest) {
    const csrfToken = getCookie('csrf_token');
    if (csrfToken) {
      req = req.clone({ setHeaders: { 'X-CSRF-Token': csrfToken } });
    }
  }
  return next(req);
};
```

### CSP con nonces (producción)

- El `<meta>` CSP del `index.html` es permisivo (dev). En producción, el servidor Express envía una **cabecera HTTP** restrictiva con un nonce por request.
- El nonce se inyecta en los scripts inline del HTML (post-proceso) para que pasen la política.
- `Cache-Control: no-store` evita que el navegador cachee HTML con nonce viejo.
- `script-src` sin `unsafe-inline`/`unsafe-eval`; `style-src` mantiene `unsafe-inline` (Tailwind/DaisyUI).

### Configuración del servidor (src/server/)

```
src/server/
├── env.ts          → carga .env (process.loadEnvFile), solo si el proceso no trae config
├── config.ts       → lee/valida process.env (API_URL, API_KEY); sin I/O ni efectos
└── proxy/
    └── api-proxy.ts → proxy + cookies + CSRF + refresh-on-401
```

- `env.ts` se importa **primero** en `server.ts` (deja `process.env` listo).
- `config.ts` es puro: solo lee `process.env` + `required()`.
- El prefijo `/ssr-api` viene de `environment.apiUrl` (fuente única, no hardcodeado).

### allowedHosts (Angular 22)

Angular 22 valida el header `Host` y responde 400 a los no declarados. Configurar en `angular.json`:
```json
"security": { "allowedHosts": ["localhost", "tu-dominio.com"] }
```
O vía env: `NG_ALLOWED_HOSTS=localhost,tu-dominio.com`.

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
