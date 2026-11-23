# Skills de Microsoft para .NET (referencia externa)

> Las skills del catálogo `dotnet` son una guía general. Para tareas especializadas, Microsoft publica skills oficiales en [`github.com/dotnet/skills`](https://github.com/dotnet/skills) (MIT, formato `agentskills.io`).

## Cómo usarlas "tal cual"

El formato es el mismo que el de este catálogo (`SKILL.md` con frontmatter `name`/`description`, body, `references/`). Se consumen sin adaptación:

1. **Copiar la carpeta** de la skill desde `dotnet/skills` a `.baseline/skills/<nombre>/` del proyecto (o `.agents/skills/<nombre>/` para descubrimiento nativo).
2. Correr `install.ps1 -Project . -Update` para registrarla en el manifiesto.
3. La IA la carga automáticamente por su `description`.

También se instalan con la CLI de skills (`npx skills add https://github.com/dotnet/skills`) o como plugin de Copilot CLI/Claude Code (`/plugin marketplace add dotnet/skills`).

## Plugins disponibles

| Plugin | Cobertura |
|--------|-----------|
| `dotnet` | C# expert, refactoring, breaking changes, MSBuild, setup local SDK |
| `dotnet-aspnetcore` | Web APIs (controllers/minimal APIs), Blazor, middleware, endpoints |
| `dotnet-data` | Entity Framework, Dapper, optimización de queries |
| `dotnet-diag` | Performance, debugging, análisis de incidentes |
| `dotnet-msbuild` | Diagnóstico de builds, optimización, code quality, modernización |
| `dotnet-nuget` | Gestión de dependencias y paquetes |
| `dotnet-upgrade` | Migración entre versiones de .NET |
| `dotnet-maui` | MAUI: setup, diagnóstico, troubleshooting |
| `dotnet-ai` | ML.NET, LLMs, RAG, MCP |
| `dotnet-test` | xUnit/MSTest, cobertura, testability, anti-patrones |
| `dotnet-test-migration` | Migración entre frameworks de test |
| `dotnet-blazor` | Componentes Blazor, interactividad |
| `dotnet-winforms` | Windows Forms moderno |
| `dotnet-template-engine` | Scaffolding y templates |
| `dotnet11` | APIs y features de .NET 11 |

## Cuándo usar las skills de Microsoft vs la skill `dotnet` de este catálogo

- **`dotnet` (este catálogo)**: guía general de arquitectura (Clean Architecture, Dapper/EF Core, auth, errores, testing, MAUI). Buena para empezar un proyecto nuevo.
- **Microsoft (`dotnet/skills`)**: tareas especializadas (MSBuild, NuGet, testing avanzado, Blazor, MAUI, upgrades). Buena para profundizar o para tareas puntuales.

No hay conflicto: Microsoft cubre lo que este catálogo no intenta cubrir. El skill `dotnet` de este catálogo es más compacto (≤300 líneas) y orientado a decisiones de arquitectura; las skills de Microsoft son más detalladas y orientadas a tareas.

## Sobreponerse con el catálogo

Si una skill de Microsoft cubre el mismo tema que una referencia de este catálogo (p. ej. `dotnet-webapi` vs `references/dapper.md`), **preferir la de Microsoft** para ese tema concreto: está mantenida por el equipo de .NET y se actualiza con cada release. Usar este catálogo para lo que Microsoft no cubre (decisiones de arquitectura, patrones de auth, manejo de errores RFC 9457).