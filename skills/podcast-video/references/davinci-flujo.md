# Flujo de edición en DaVinci Resolve (Free)

## 1. Ingesta

- Crear proyecto nuevo: `File → New Project`.
- Importar footage: arrastrar archivos a la Media Pool o `File → Import Media`.
- **Proxy editing**: `Project Settings → Master Settings → Working Folders → Proxy Media`. DaVinci genera proxies automáticamente si se configura. Alternativa manual: transcodificar con FFmpeg a 1080p/720p y vincular con "Relink".
- Footage de iPhone: transcodificar a H.264 + AAC antes de importar (ver `formatos-redes.md` §3).

## 2. Organización

- Crear bins en la Media Pool: `Footage`, `Audio`, `B-Roll`, `Graphics`.
- Timeline principal: `Timeline → Create New Timeline` con resolución y frame rate del proyecto (ej. 1080p 30fps o 24fps).
- Si hay multicámara: `Timeline → Create New Timeline → Multicam` y sincronizar por audio o timecode.

## 3. Edición

- **Cortes**: usar `Blade` (B) para cortar, `Delete` para eliminar. Trim con `Trim` (T).
- **Transiciones**: `Effects → Video Transitions`. Usar con moderación (cortes duros son mejores para podcast).
- **B-roll**: insertar clips superpuestos en la pista superior; usar `Composite Mode` para overlays.
- **Multicámara**: cambiar ángulo con el panel de multicámara; el audio principal va en una pista fija.

## 4. Audio (Fairlight)

- Normalizar volumen: `Fairlight → Loudness → Normalize` a **-14 LUFS** (podcast) o **-16 LUFS** (YouTube).
- Noise gate: `Fairlight → Dynamics → Gate` para eliminar ruido de fondo.
- Compresor: `Fairlight → Dynamics → Compressor` (ratio 3:1, threshold -20 dB, attack 10 ms, release 100 ms).
- EQ: recorte de graves (<80 Hz) y presencia (2-4 kHz) para voz.
- De-esser: `Fairlight → Dynamics → De-Esser` para sibilancias.
- Verificar que el audio no clipee (picos < -3 dB).

## 5. Subtítulos

- `Workspace → Subtitle` → `+` para crear pista de subtítulos.
- Generar automáticamente: `Subtitle → Auto Caption` (DaVinci 19+). Revisar y corregir siempre.
- Estilo: fuente legible (Inter, Roboto, Montserrat), tamaño 40-60 px, outline negro, fondo semitransparente para shorts.
- Posición: centro inferior para horizontal; centro para vertical (shorts).

## 6. Cortes de shorts

- Identificar momentos de alto impacto: hooks, quotes, reacciones, preguntas.
- Crear timeline nuevo por cada short: `Timeline → Create New Timeline` con resolución vertical (1080×1920).
- Copiar el clip al timeline vertical, ajustar framing (zoom, pan).
- Agregar subtítulos quemados y un título/overlay si aplica.
- Duración: 15–60 segundos. Hook en los primeros 3 segundos.

## 7. Exportación

- `Deliver → Render`: seleccionar preset por plataforma.
- Codec: H.264 (compatibilidad universal) o H.265 (mejor calidad, menos compatible).
- Audio: AAC, 128-192 kbps, 48 kHz.
- Verificar specs en `formatos-redes.md` antes de renderizar.
- Renderizar a carpeta del proyecto: `exports/EP001/`.

## Limitaciones de la versión Free

- Sin render en 4K/8K (máx. 3840×2160 en algunas configs, pero limitado).
- Sin efectos de IA (Magic Mask, Voice Isolation avanzado) en la versión Free de v18; en v19 algunos se incluyen.
- Sin colaboración multiusuario.
- Sin exportación a YouTube/Vimeo directa desde Resolve.

Para la mayoría de podcasts, la versión Free es suficiente.