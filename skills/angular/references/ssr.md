# SSR y build

> Detalle de la sección **SSR y build** de la skill `angular`. Aplica **solo** si usas SSR; en CSR no existe `server.ts` ni proxy.

- `src/server.ts`: Express + proxy `/ssr-api/{namespace}/{ruta}` + handlers multipart (`req.is('multipart/form-data')` para validar el upload).
- **Namespace opcional**: con una sola API el proxy es `/ssr-api/{ruta}`; el segmento de namespace solo se justifica cuando hay varias APIs y hay que distinguirlas.
- **`allowedHosts`**: Angular 22 valida el header `Host` y responde 400 a los no declarados. `angular.json` genera `"allowedHosts": []`; declara la lista explícita en `AngularNodeAppEngine` (los hosts reales, no un comodín) y usa `NG_ALLOWED_HOSTS` como override por entorno. En local, `localhost` debe estar contemplado.
- `app.routes.server.ts`: `RenderMode` por página. Dashboards de admin → `RenderMode.Client` (sin prerender, la API disponible al renderizar en el navegador).
- **Prerender vs Server con URLs relativas**: `RenderMode.Server` hereda el origen del request, así que un fetch relativo a `/ssr-api/...` resuelve; `Prerender` corre sin request, sin origen, y cualquier lista que dependa de la API queda vacía en el HTML. Consecuencia: página con datos por request → `Server`, nunca `Client` ni `Prerender`; `Client` es para paneles autenticados sin necesidad de SEO.
- **Build de producción**: `ng build` (genera `dist/.../server/server.mjs`); `npm start` debe apuntar al **servidor Express de producción** (`node dist/.../server/server.mjs`), **nunca** a `ng serve` (dev server sin SSR).
- **Verificación**: `ng build` valida plantillas + `pnpm lint` (0 errores) — ambos antes de declarar una feature terminada.
