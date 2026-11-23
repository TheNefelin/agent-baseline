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
- En el patrón BFF no hay refresh en el cliente: el 401 de "credenciales inválidas" en `/auth/login` **debe** mostrarse. Silencia el 401 solo cuando significa "sesión muerta" (hay sesión activa, o la petición es a `/auth/me`).

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

- Además de `??=`: si el SDK ya está en `window`, resuelve al instante (no reinserta el script).
- Envuelve la carga en un **timeout explícito** y resetea el promise cacheado en el `catch` para permitir reintento tras un fallo transitorio de red o CSP.
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
- Filtra cabeceras hop-by-hop (`host`, `connection`, `content-length`, `transfer-encoding`, `content-encoding`, `set-cookie`, `cookie`) y también `x-csrf-token` (ver "No reenviar `X-CSRF-Token` al upstream").

### CSRF (doble envío)

- El BFF emite una cookie legible `csrf_token` (NO HttpOnly) en los endpoints de token.
- El cliente lee la cookie y envía `X-CSRF-Token` en peticiones mutantes (POST/PUT/DELETE/PATCH).
- El BFF compara: cookie == header. Si no coinciden → 403.
- `SameSite=Lax` bloquea el 95% de CSRF; el doble envío cierra el 5% restante.

### Escrituras con firstValueFrom + try/catch/finally

Alternativa al `MutationService` cuando hay pocas escrituras: la página hace `await firstValueFrom(servicio.x())` dentro de `try/catch/finally`, con su signal `loading`:

```ts
async guardar(): Promise<void> {
  this.isSaving.set(true);
  try {
    await firstValueFrom(this.authService.login(this.formData()));
    this.router.navigate(['/home']);
  } catch (err) {
    if (!(err instanceof HttpErrorResponse)) {
      this.errorService.show(this.describeError(err));
    }
    // HTTP: el interceptor ya mostro el toast
  } finally {
    this.isSaving.set(false);
  }
}
```

- El `finally` siempre restaura `loading`/`disabled`; sin él, el botón queda bloqueado.
- En `catch`, distingue HTTP de no HTTP: el interceptor ya mostró los HTTP.
- Para muchos writes (CRUD con modal), prefiere el `MutationService` con `onClose`/`onSuccess`.

### Logger con contexto

Servicio de log centralizado en `core/services` con método `error(context, message, error?)`:

```ts
@Injectable({ providedIn: 'root' })
export class LoggerService {
  error(context: string, message: string, error?: unknown): void {
    console.error(`[${context}] ${message}`, error);
  }
}
```

- Uso: `logger.error('MiComponente', 'accion', err)` → `[MiComponente] accion`.
- Evita `console.error` disperso con formatos distintos y permite filtrar por componente en el log.

### Interceptor CSRF (frontend)

El interceptor corre **también en SSR**: `app.config.ts` se hereda al servidor con `mergeApplicationConfig`, así que `document` no existe en Node y el acceso directo a `document.cookie` lanza `ReferenceError`.

```ts
export const csrfInterceptor: HttpInterceptorFn = (req, next) => {
  // El interceptor tambien corre en SSR (app.config.ts se hereda al servidor).
  if (!isPlatformBrowser(inject(PLATFORM_ID))) return next(req);

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

- **Guarda de plataforma obligatoria**: `isPlatformBrowser(PLATFORM_ID)` y salida temprana. Sin ella, el error aparece cuando una ruta con request pasa a `RenderMode.Server`.
- En servidor el token CSRF no aplica: el BFF compara cookie vs header y en el render no hay cookie jar.

### CSRF condicional en el BFF

El BFF exige `X-CSRF-Token` **solo si la petición trae la cookie `csrf_token`**. Sin cookie (login, registro, primer contacto) la petición pasa: si no, el primer POST devolvería 403 y ningún flujo podría arrancar.

Complemento del lado cliente: el interceptor solo añade la cabecera si encuentra la cookie.

### No reenviar `X-CSRF-Token` al upstream

Al hacer forwarding, filtrar también `x-csrf-token`: el CSRF del BFF se deriva de la cookie, nunca de la cabecera que envió el cliente. Reenviarla hacia la API le entrega un token que el BFF no controla.

### CSP con nonces (producción)

- El `<meta>` CSP del `index.html` es permisivo (dev). En producción, el servidor Express envía una **cabecera HTTP** restrictiva con un nonce por request.
- El nonce se inyecta en los scripts inline del HTML (post-proceso) para que pasen la política. El post-proceso reescribe solo `<script>` **sin `src=`** y reemplaza también el `nonce=""` que Angular deja en el build.
- Al reenviar el body editado, elimina `content-length` y `etag` (ya no cuadran) y manda `Cache-Control: no-store` para que no se cachee HTML con nonce viejo.
- `script-src` sin `unsafe-inline`/`unsafe-eval`; `style-src` mantiene `unsafe-inline` (Tailwind/DaisyUI).

### Refresh de sesión (deduplicación + cache + rejected/unavailable)

El BFF es dueño de la sesión. El refresh debe manejar tres casos:

- **Deduplicación inflight**: si llegan dos requests con el mismo refresh token (race condition), solo uno ejecuta el refresh; el otro espera el mismo promise. Evita emitir dos pares de tokens.
- **Cache de 10 s**: si una petición rezagada llega con la cookie vieja justo después del refresh, se sirve el resultado cacheado en vez de rechazar. Se limpia con `setTimeout(...).unref()`.
- **Rejected vs unavailable**: un 401/403 del upstream = "token rechazado" → borrar sesión. Un error de red o 5xx = "no disponible" → no borrar sesión (puede ser transitorio).

```ts
// auth/session.ts
const inflight = new Map<string, Promise<RefreshResult>>();

export function refreshSession(refreshToken: string): Promise<RefreshResult> {
  let promise = inflight.get(refreshToken);
  if (!promise) {
    promise = doRefresh(refreshToken);
    inflight.set(refreshToken, promise);
    setTimeout(() => inflight.delete(refreshToken), 10_000).unref();
    void promise.then((r) => {
      if (r.status === 'unavailable') inflight.delete(refreshToken);
    });
  }
  return promise;
}
```

- `doRefresh` usa `AbortSignal.timeout(5_000)` para no colgar si el upstream no responde.
- Maneja redirects 307/308 solo si son same-origin y same-path (sin query).

### Origin check en el guard CSRF

Además del doble envío (cookie vs header), el BFF verifica que el `Origin` de la petición coincida con el `Host`:

```ts
// auth/csrf.ts
const origin = req.headers.origin;
if (origin) {
  try {
    if (new URL(origin).host !== req.headers.host) return fail(res);
  } catch {
    return fail(res);
  }
}
```

Defensa en profundidad: bloquea peticiones cross-origin incluso si el atacante logra enviar la cookie.

### Path traversal en el proxy CRUD

El proxy valida la URL **después** de normalizarla con `new URL`:

```ts
// crud/proxy.ts
if (!reqUrl.startsWith('/') || /%2f|%5c|\\/i.test(reqUrl)) return null;
const target = new URL(basePath + reqUrl, base.origin);
if (target.origin !== base.origin) return null;
if (!target.pathname.startsWith(basePath + '/')) return null;
```

- Valida **después** de normalizar: `..` y `%2e%2e` ya se resolvieron.
- `origin` check previene SSRF.
- `pathname` prefix check previene path traversal.

### Method allowlist por recurso

```ts
// crud/proxy.ts
const RESOURCES: Record<string, readonly string[]> = {
  language: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  project: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  'auth/me': ['GET'],
};
```

Si el método no está permitido → `405 Method Not Allowed` con `Allow` header. Todo lo demás → 404.

### Body sin parsear (Buffer passthrough)

```ts
// bff.ts
bff.use(express.raw({ type: () => true, limit: '5mb' }));
```

El body se reenvía tal cual como `Uint8Array`. Evita `express.json()` que parsea y re-serializa (pierde formato, añade overhead, puede alterar el body). El proxy valida `req.is('multipart/form-data')` para uploads.

### Cache-Control: no-store en todo el BFF

```ts
// bff.ts (middleware global)
bff.use((_req, res, next) => {
  res.setHeader('Cache-Control', 'no-store');
  next();
});
```

Ninguna respuesta del BFF se cachea (navegador ni CDN). Evita que HTML con nonce viejo se cachee.

### Slash redirect handling (307/308)

```ts
// http/forward.ts
if (upstream.status === 307 || upstream.status === 308) {
  const next = slashRedirect(target, upstream.headers.get('location'));
  if (next) upstream = await call(next);
}
```

Solo sigue redirects same-origin y same-path (sin query). Bloquea redirects a otros dominios (SSRF) y a paths distintos.

### Bad gateway (502 JSON)

Si el upstream no responde o devuelve un error de red, el proxy responde:

```ts
res.status(502).json({ type: 'upstream-unavailable', title: 'Upstream Service Unavailable.', status: 502 });
```

Siempre JSON, nunca HTML de error de Express. El cliente parsea `detail`.

### Config lazy (getters que lanzan si falta)

```ts
// config/index.ts
export const serverConfig = {
  get apiUrl() { return required('API_URL'); },
  get apiKey() { return required('API_KEY'); },
  get googleClientId() { return required('GOOGLE_CLIENT_ID'); },
};
```

`required(name)` lanza si la variable falta. Se evalúa en cada acceso, no al importar (el build SSR extrae rutas sin env vars). Más estricto que el patrón `Proxy` que devuelve `''`.

### Public config endpoint

```ts
// auth/public-config.ts
publicConfigRouter.get('/config', (_req, res) => {
  res.json({ googleClientId: serverConfig.googleClientId });
});
```

Expone solo valores públicos (client IDs de OAuth). NUNCA secretos. No exige sesión.

### Rate limiting in-memory con 3 tiers

Rate limiter propio (sin dependencias) con tres tiers independientes:

| Tier | Cuándo | Default |
|------|--------|---------|
| read | GET/HEAD (incluido /auth/me) | 50/min |
| write | POST/PUT/PATCH/DELETE fuera de /auth | 10/min |
| auth | POST/PUT/PATCH/DELETE bajo /auth/* | 5/min |

- **MAX_KEYS = 10_000**: tope de claves en memoria para evitar que un atacante con muchas IPs agote la RAM.
- **Lazy sweep**: limpia entradas expiradas solo cuando se necesita, sin timers (los timers en serverless no son fiables).
- **Limitación documentada**: en serverless (Vercel) cada instancia cuenta por su cuenta, así que el límite real es más alto que el configurado. Es una red de seguridad barata, no la defensa principal.
- **IP del cliente**: solo fiable detrás de un proxy de confianza (Vercel sobrescribe `x-forwarded-for`).

### Configuración del servidor (src/server/)

```
src/server/
├── env.ts          → carga .env (importar PRIMERO en server.ts)
├── config.ts       → lee process.env (lazy, sin I/O)
├── http/           → cookies.ts, proxy-headers.ts (utilidades puras)
├── middleware/     → csp.ts, csrf.ts, json-error.ts, allowed-hosts.ts
├── proxy/          → auth-proxy.ts, api-proxy.ts
└── services/       → session.service.ts (emite/refresca cookies)
```

- Cada carpeta tiene **una** responsabilidad. `http/` y `services/` son funciones puras, testeables sin Express.
- `env.ts` se importa **primero** en `server.ts` (deja `process.env` listo). Hay dos variantes y hay que elegir una: (a) `process.loadEnvFile()` si **el entorno del sistema manda**; (b) parseo manual + `process.env[k]=v` si el `.env` del proyecto **manda** (evita que una variable stale del sistema oculte la config). No las mezcles.
- `config.ts` **no lee `process.env` al importar**: el build SSR extrae rutas y falla si las variables no están. Usa un `Proxy` lazy que evalúa `required()` en cada acceso, y `required()` **no lanzante** (devuelve `''`); la validación real ocurre en el request y responde 500 con "Falta configurar API_URL y API_KEY".
- El prefijo `/ssr-api` viene de `environment.apiUrl` (fuente única, no hardcodeado).

### Proxy partido por dominio

Dos routers, no uno: `auth-proxy` (montado en `/ssr-api/auth`) y `api-proxy` (catch-all en `/ssr-api`). Express usa el primero que matchea: `auth-proxy` se traga login/register/google/refresh/logout/me; `api-proxy` solo reenvía CRUD genérico. Cada router aplica `csrfGuard` + `jsonErrorHandler`.

Ventaja: extraer tokens y emitir cookies nunca se mezcla con el forwarding CRUD.

### Cookies `Secure` condicionadas al host

`Secure` solo si `PRODUCTION=true` **y** el host no es `localhost`/`127.0.0.1`. En dev HTTP las cookies `Secure` no se envían y la sesión se pierde sola. No uses `Secure` incondicional: rompe el login local.

### Contrato de error JSON del BFF

Todo error generado por el BFF responde el mismo cuerpo `{ type, title, status, detail }`:
`400 malformed-json` | `403 csrf-failed` | `502 upstream-unavailable`.

El cliente parsea `detail`; nunca llega HTML de error de Express. Aplica también al 502 por upstream caído y al 400 por JSON malformado.
- **Gotcha del prefijo `/api`**: si el backend monta las rutas bajo `/api` (ej. `app.include_router(auth_router, prefix="/api")`) Y el frontend construye la URL como `/ssr-api/api/auth/...`, el BFF duplica el prefijo (`/api/api/auth/...` → 404). La URL del frontend debe cuadrar con la del backend + el prefijo del BFF: `frontend path (sin /ssr-api) + API_URL = URL del backend`. Verificar con un curl directo al backend antes de desplegar.

### [SSR] — Sesión en cookie HttpOnly (BFF)

Cuando el BFF es dueño de la sesión (tokens en cookies `HttpOnly`), el cliente **no puede** leer ni guardar tokens. Consecuencias:

- **No hay `authInterceptor`**: el BFF pone el `Authorization: Bearer` leyendo la cookie `access_token`. El cliente solo envía las cookies (mismo origen).
- **CSRF por doble envío**: el BFF emite una cookie legible `csrf_token`; el cliente la copia a la cabecera `X-CSRF-Token` en peticiones mutantes. El BFF compara ambas.
- **Guard asíncrono**: como el cliente no sabe si hay sesión, el guard protege la ruta preguntando `/auth/me` (y redirige a login si falla). No vale una comprobación de "presencia" sin red.
- **Respuesta de login sin tokens**: el BFF extrae `access_token`/`refresh_token` de la respuesta del backend, los guarda en cookies y devuelve al cliente solo los datos de negocio.
- **Refresh silencioso en el proxy**: ante un 401, el BFF llama a `/auth/refresh` con la cookie `refresh_token`, emite las cookies nuevas y reintenta la petición original; si falla, borra la sesión.

- `AuthStoreService` del cliente queda reducido a un flag booleano (solo para reaccionar en la UI); la fuente de verdad es el servidor (`/auth/me`).
- **Guard async**: `authGuard` pregunta `/auth/me`: 200 → `setSession()` y `true`; error → `clearSession()` y `UrlTree` a login. El `errorInterceptor` silencia el 401 de `/auth/me` para no mostrar dos mensajes (el guard ya redirige).
- **Roles en un guard aparte**: con cookie `HttpOnly` el rol no está disponible de forma síncrona en el cliente. El guard de sesión responde "¿hay sesión?"; un guard async separado responde "¿el rol permite esta ruta?". El `role` lo trae `/auth/me` (o un claim), nunca lo inventes.
- **Logout fire-and-forget**: dispara la revocación en el servidor sin await (`pipe(take(1)).subscribe({ error: () => undefined })`), limpia la sesión local y navega. El usuario no espera al backend para desloguearse.

### allowedHosts (Angular 22)

Angular 22 valida el header `Host`. La lista real va en el motor, no en `angular.json`:

```ts
new AngularNodeAppEngine({ allowedHosts: getAllowedHosts() });
```

- `angular.json` genera `"security": { "allowedHosts": [] }`: **no declares hosts ahí**, se ignoran.
- Lee la lista de `NG_ALLOWED_HOSTS` (comma-separated) en `src/server/middleware/allowed-hosts.ts`.
- **Fail-closed por arranque**: `getAllowedHosts()` lanza si `NG_ALLOWED_HOSTS` no está definido (o está vacío) y el servidor no levanta. Más simple y seguro que responder 400 a cada host no declarado.
- En local: `NG_ALLOWED_HOSTS=localhost,127.0.0.1` en `.env`.

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
