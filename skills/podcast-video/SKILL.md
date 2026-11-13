---
name: podcast-video
description: "Edicion de video para podcast y extraccion de shorts: flujo en DaVinci Resolve (Free), comandos FFmpeg, specs por plataforma (TikTok/Reels/Shorts) y manejo de footage de iPhone. NO para `ui-ux-mockup` (diseno visual, no edicion de video), `arduino` (hardware)."
---

# SKILL: Edicion de video para podcast

> **Frescura:** verificado 2026-11-13 · ámbito: DaVinci Resolve 21.2 (Free), FFmpeg 7.x, HandBrake 1.8.x · fuente: documentación oficial de Blackmagic y ffmpeg.org. Al cambiar de major, revalidar.

Edición no lineal de podcast y extracción de shorts/clips. Decisiones opinadas, anti-patrones y patrones; no es un tutorial de cada herramienta.

## Cuándo usar

- Editar un episodio de podcast (audio + video multicámara).
- Extraer shorts/clips verticales para TikTok, Reels o YouTube Shorts.
- Agregar subtítulos, normalizar audio, exportar en formatos por plataforma.
- Automatizar cortes y transcodificación con FFmpeg.

## Cuándo NO usar

| Situación | Skill |
|-----------|-------|
| Diseñar la UI de una app o un mockup | `ui-ux-mockup` |
| Escribir código de la app que acompaña al podcast | la skill del stack (`angular`, `astro`, etc.) |
| Automatizar el deploy del sitio del podcast | `github-actions` |

## Flujo principal

1. **Ingesta** — Importar footage (iPhone, cámara, audio externo) a un proyecto de DaVinci Resolve. Normalizar frame rate y resolución.
2. **Edición** — Timeline multicámara, cortes, transiciones, B-roll. Audio en Fairlight (normalización, noise gate, compresor).
3. **Subtítulos** — Generar subtítulos (manual o auto), revisar y corregir. Estilo por plataforma.
4. **Cortes de shorts** — Identificar momentos de alto impacto (hooks, quotes, reacciones). Extraer clips de 15–60 s.
5. **Exportación** — Render por plataforma con specs correctas (resolución, bitrate, codec, aspect ratio).

## Decisiones y convenciones

- **Fuente única del footage**: importar una vez, reutilizar en timelines (no duplicar archivos).
- **Proxy editing**: generar proxies de baja resolución para edición fluida; reemplazar por los originales al renderizar.
- **Audio primero**: normalizar audio antes de cortar. Un podcast con audio malo no se salva con video bonito.
- **Subtítulos quemados (burned-in)** para shorts: la mayoría se ve sin sonido.
- **Aspect ratio por plataforma**: 9:16 (vertical) para TikTok/Reels/Shorts; 16:9 para YouTube completo.
- **Un solo proyecto por episodio**: no crear proyectos separados para shorts; usar timelines dentro del mismo proyecto.
- **Nomenclatura**: `EP001_full.mp4`, `EP001_short_01.mp4`, `EP001_short_02.mp4`. Siempre con número de episodio y secuencia.

## Anti-patrones / gotchas

| Anti-patrón | Problema | Solución |
|-------------|----------|----------|
| Editar en 4K directo sin proxies | Timeline lento, crashes | Generar proxies (1080p o 720p) para edición |
| Subir el video completo a redes | Baja retención | Cortar shorts de 15–60 s con hook en los primeros 3 s |
| Subtítulos sin revisar | Errores que dañan credibilidad | Revisar siempre; auto-subtítulos son borrador |
| Audio sin normalizar | Volumen inconsistente entre speakers | Normalizar a -14 LUFS (podcast) o -16 LUFS (YouTube) |
| Exportar sin verificar specs | Rechazo por la plataforma | Validar resolución, bitrate, codec y aspect ratio antes de subir |
| Footage de iPhone sin normalizar | Frame rate variable, HDR, orientación | Transcodificar a formato estándar antes de importar |

## Limitaciones de la versión Free

- Sin render en 4K/8K (máx. 3840×2160 a 60 fps, 8-bit en la free).
- Sin efectos de IA (Magic Mask, Voice Isolation, Neural Engine) — exclusivos de Studio.
- Sin text-based editing ni film grain — exclusivos de Studio.
- Sin soporte para 10-bit/120 fps ni resoluciones más allá de 4K.
- Sin exportación a YouTube/Vimeo directa desde Resolve.
- La free incluye multi-user collaboration y HDR grading.

## Cuándo consultar referencias

- Para comandos FFmpeg (cortar, extraer audio, generar shorts): `references/ffmpeg-cortes.md`
- Para el flujo de edición en DaVinci Resolve (importar, multicámara, audio, subtítulos, exportar): `references/davinci-flujo.md`
- Para specs por plataforma y manejo de footage de iPhone: `references/formatos-redes.md`

## Verificación

- [ ] Audio normalizado (LUFS correcto por plataforma).
- [ ] Subtítulos revisados (sin errores ortográficos).
- [ ] Shorts con hook en los primeros 3 segundos.
- [ ] Specs de exportación validadas (resolución, bitrate, codec, aspect ratio).
- [ ] Nomenclatura consistente (`EPxxx_short_NN.mp4`).
- [ ] Footage de iPhone transcodificado a formato estándar antes de importar.