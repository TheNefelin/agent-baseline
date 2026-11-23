# SSR y build

> Detalle de la sección **SSR y build** de la skill `angular`. Aplica **solo** si usas SSR; en CSR no existe `server.ts` ni proxy.

- `src/server.ts`: Express + proxy `/ssr-api/{ruta}` + handlers multipart (`req.is('multipart/form-data')` para validar el upload).
- **Gotcha `pnpm-workspace.yaml` (pnpm 10+)**: si el archivo tiene `allowBuilds` con valores placeholder (`"set this to true or false"`), `pnpm install` falla con `ERR_PNPM_IGNORED_BUILDS`. Setear explícitamente `true`/`false` para cada dependencia con build scripts (esbuild: true, el resto según necesidad). Esto rompe el deploy en Vercel si no se resuelve.
- **Namespace opcional**: con una sola API el proxy es `/ssr-api/{ruta}`; el segmento de namespace solo se justifica cuando hay varias APIs y hay que distinguirlas.
- **Proxy con X-API-Key**: el BFF añade `X-API-Key` a cada request hacia la API. La Key vive en `src/server/config.ts` (lee `process.env`), nunca en el bundle del cliente.
- **`allowedHosts`**: Angular 22 valida el header `Host`. La lista real va en `new AngularNodeAppEngine({ allowedHosts })`, leída de `NG_ALLOWED_HOSTS` (fail-closed **por arranque**: si falta la variable, el servidor no levanta). `angular.json` genera `"allowedHosts": []`: no declares hosts ahí, se ignoran. Detalle en `references/auth.md`. En local, setear `NG_ALLOWED_HOSTS=localhost,127.0.0.1` en `.env`.
- `app.routes.server.ts`: `RenderMode` por página. Dashboards de admin → `RenderMode.Client` (sin prerender, la API disponible al renderizar en el navegador).
- **Prerender vs Server con URLs relativas**: `RenderMode.Server` hereda el origen del request, así que un fetch relativo a `/ssr-api/...` resuelve; `Prerender` corre sin request, sin origen, y cualquier lista que dependa de la API queda vacía en el HTML. Consecuencia: página con datos por request → `Server`, nunca `Client` ni `Prerender`; `Client` es para paneles autenticados sin necesidad de SEO.
- **CSP con nonces (producción)**: el servidor Express genera un nonce por request, lo inyecta en los scripts inline del HTML (post-proceso) y lo pone en la cabecera `Content-Security-Policy`. `Cache-Control: no-store` evita que el navegador cachee HTML con nonce viejo. El `<meta>` CSP del `index.html` es permisivo (dev); la cabecera HTTP tiene prioridad en producción. Detalle del post-proceso en `references/auth.md`.
- **Build de producción**: `ng build` (genera `dist/.../server/server.mjs`); `pnpm serve:ssr` debe apuntar al **servidor Express de producción** (`node dist/.../server/server.mjs`), **nunca** a `ng serve` (dev server sin SSR).
- **Verificación**: `ng build` valida plantillas + `pnpm lint` (0 errores) — ambos antes de declarar una feature terminada.
