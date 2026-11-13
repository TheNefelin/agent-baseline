# Specs por plataforma y manejo de footage de iPhone

## 1. Specs de exportación por plataforma

| Plataforma | Resolución | Aspect ratio | Codec video | Bitrate video | Codec audio | Bitrate audio | FPS | Duración máxima |
|------------|-----------|--------------|-------------|---------------|-------------|---------------|-----|-----------------|
| TikTok | 1080×1920 | 9:16 | H.264 | 5-8 Mbps | AAC | 128 kbps | 30 | 10 min (shorts: 60 s) |
| Instagram Reels | 1080×1920 | 9:16 | H.264 | 5-8 Mbps | AAC | 128 kbps | 30 | 90 s |
| YouTube Shorts | 1080×1920 | 9:16 | H.264 | 5-8 Mbps | AAC | 128 kbps | 30 | 60 s |
| YouTube (completo) | 1920×1080 | 16:9 | H.264/H.265 | 8-12 Mbps | AAC | 192 kbps | 30 o 60 | sin límite |
| X (Twitter) | 1280×720 min | 16:9 o 9:16 | H.264 | 5-8 Mbps | AAC | 128 kbps | 30 | 2 min 20 s |
| LinkedIn | 1920×1080 | 16:9 | H.264 | 5-8 Mbps | AAC | 128 kbps | 30 | 10 min |

**Notas:**
- H.264 (AVC) es el codec universal. H.265 (HEVC) da mejor calidad pero menor compatibilidad.
- `-movflags +faststart` siempre para reproducción web inmediata.
- La duración máxima de shorts en TikTok es 60 s, pero los mejores resultados son 15-30 s.

## 2. Specs de audio para podcast

| Métrica | Valor | Nota |
|---------|-------|------|
| LUFS (podcast) | -14 | Estándar de Apple Podcasts, Spotify |
| LUFS (YouTube) | -16 | YouTube normaliza a -14, pero -16 da margen |
| Peak (true peak) | < -1 dB | Evitar clipping |
| Sample rate | 48 kHz | Estándar para video |
| Bitrate audio | 128-192 kbps AAC | 192 para música, 128 para voz |
| Noise gate | -40 a -50 dB | Eliminar ruido de fondo |
| Compressor ratio | 3:1 a 4:1 | Para voz |
| De-esser | 5-8 kHz | Para sibilancias |

## 3. Footage de iPhone

Los iPhones graban en formatos que requieren normalización antes de importar a DaVinci Resolve.

### Formatos de grabación

| Modelo | Codec video | Codec audio | Resolución | FPS | HDR |
|--------|------------|------------|------------|-----|-----|
| iPhone 11-12 | H.264 | AAC | 1080p/4K | 24/30/60 | No (SDR) |
| iPhone 13-15 | HEVC (H.265) | AAC | 1080p/4K | 24/30/60 | Dolby Vision (HDR) |
| iPhone 13+ Pro | ProRes | PCM | 4K | 24/30/60 | SDR/HDR |
| iPhone 16 | HEVC + ProRes | AAC/PCM | 4K | 24/30/60 | Dolby Vision |

### Problemas comunes y soluciones

| Problema | Causa | Solución |
|----------|-------|----------|
| Frame rate variable | iPhone ajusta FPS dinámicamente | Transcodificar con `-r 30` (o 24/60) para forzar FPS constante |
| HDR / Dolby Vision | DaVinci Resolve Free no maneja HDR bien | Convertir a SDR: `ffmpeg -i input.mov -vf "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709:t=bt709:m=bt709:r=tv,format=yuv420p" -c:v libx264 -crf 18 output.mp4` |
| Orientación incorrecta | Metadata de rotación del iPhone | `ffmpeg -i input.mov -vf "transpose=1" output.mp4` (ajustar según rotación) |
| HEVC no compatible | Algunos editores no leen HEVC | Transcodificar a H.264: `ffmpeg -i input.mov -c:v libx264 -crf 18 -c:a aac -b:a 192k output.mp4` |
| Audio de baja calidad | Micrófono del iPhone en ambiente ruidoso | Usar micrófono externo (Rode Wireless, Shure MV88); normalizar en Fairlight |

### Comando de normalización completo para iPhone

```bash
# Convertir footage de iPhone a formato estándar para edición
ffmpeg -i input.mov \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -r 30 -c:v libx264 -crf 18 -preset slow \
  -c:a aac -b:a 192k -ar 48000 -ac 2 \
  -movflags +faststart \
  output.mp4
```

### Verificación de footage antes de importar

```bash
# Ver specs del footage de iPhone
ffprobe -v quiet -print_format json -show_format -show_streams input.mov | \
  python3 -c "import json,sys; d=json.load(sys.stdin); s=d['streams'][0]; print(f\"Codec: {s['codec_name']}, Res: {s['width']}x{s['height']}, FPS: {s['r_frame_rate']}, Dur: {float(d['format']['duration']):.1f}s\")"
```

## 4. Checklist de exportación

Antes de subir, verificar:

- [ ] Resolución correcta por plataforma (1080×1920 para shorts, 1920×1080 para long-form).
- [ ] Aspect ratio correcto (9:16 o 16:9).
- [ ] Codec H.264 (compatibilidad universal).
- [ ] Bitrate dentro del rango de la plataforma.
- [ ] Audio AAC, 48 kHz, sin clipping.
- [ ] Subtítulos quemados y revisados (para shorts).
- [ ] `-movflags +faststart` aplicado.
- [ ] Duración dentro del límite de la plataforma.
- [ ] Nombre de archivo con convención: `EP001_short_01.mp4`.