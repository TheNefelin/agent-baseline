# Comandos FFmpeg para cortes y transcodificación

FFmpeg es el motor detrás de casi todo. Se usa para automatizar cortes de shorts, extraer audio, normalizar y transcodificar.

## 1. Extraer un clip por tiempo

```bash
# Cortar de 00:12:30 a 00:13:15 (45 segundos)
ffmpeg -ss 00:12:30 -i input.mp4 -t 45 -c copy clip.mp4
```

- `-ss` antes de `-i`: seek rápido (keyframe). Más rápido pero menos preciso.
- `-ss` después de `-i`: seek preciso. Más lento pero exacto.
- `-c copy`: sin re-encoding. Instantáneo pero el corte puede no ser exacto en el keyframe.

## 2. Extraer audio

```bash
# Extraer audio como AAC de alta calidad
ffmpeg -i input.mp4 -vn -c:a aac -b:a 192k audio.m4a

# Extraer audio como WAV (sin compresión, para edición)
ffmpeg -i input.mp4 -vn -c:a pcm_s16le audio.wav
```

## 3. Generar un short vertical (9:16) con crop

```bash
# Recortar centro vertical de un video horizontal
ffmpeg -i input.mp4 -vf "crop=ih*9/16:ih" -c:v libx264 -crf 23 -c:a aac -b:a 128k short.mp4
```

- `crop=ih*9/16:ih`: ancho = alto × 9/16, alto = alto original. Centra horizontalmente.
- Para pan manual: `crop=ih*9/16:ih:x:y` con offsets.

## 4. Generar múltiples shorts en lote

```bash
# Script: cortar varios clips de un video
# clips.txt: cada línea "inicio duracion nombre"
# 00:05:00 30 hook.mp4
# 00:12:30 45 quote.mp4
# 00:25:10 20 reaccion.mp4

while read start dur name; do
  ffmpeg -ss "$start" -i input.mp4 -t "$dur" -c copy "$name"
done < clips.txt
```

## 5. Normalizar audio (LUFS)

```bash
# Normalizar a -14 LUFS (podcast) con dos pasos (medir + aplicar)
# Paso 1: medir
ffmpeg -i audio.wav -af loudnorm=I=-14:TP=-1:LRA=11:print_format=json -f null - 2>&1 | grep -A20 "input_i"

# Paso 2: aplicar con los valores del paso 1
ffmpeg -i audio.wav -af "loudnorm=I=-14:TP=-1:LRA=11:measured_I=-16.5:measured_TP=-1.5:measured_LRA=8:measured_thresh=-26.5" -c:a aac -b:a 192k audio_norm.m4a
```

## 6. Transcodificar para redes sociales

```bash
# TikTok / Reels / Shorts: H.264, 1080x1920, 30fps, AAC 128k
ffmpeg -i clip.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 -preset slow -crf 23 -r 30 -c:a aac -b:a 128k -movflags +faststart output.mp4

# YouTube (horizontal): 1080p, H.264, AAC 192k
ffmpeg -i clip.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 -preset slow -crf 20 -c:a aac -b:a 192k -movflags +faststart output.mp4
```

- `-movflags +faststart`: mueve el moov atom al inicio para reproducción web inmediata.
- `-preset slow`: mejor compresión, más lento. `medium` para balance.
- `-crf 23`: calidad constante (18-28; menor = mejor calidad, mayor tamaño).

## 7. Transcodificar footage de iPhone

```bash
# Convertir HEVC (iPhone) a H.264 + AAC para compatibilidad
ffmpeg -i input.mov -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 192k -movflags +faststart output.mp4

# Si el iPhone grabó en ProRes (iPhone 13+ Pro):
ffmpeg -i input.mov -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 192k -movflags +faststart output.mp4
```

## 8. Generar subtítulos (SRT) desde audio

```bash
# Extraer audio y generar SRT con Whisper (openai/whisper)
ffmpeg -i input.mp4 -vn -c:a pcm_s16le audio.wav
whisper audio.wav --model medium --language es --output_format srt --output_dir ./
```

Whisper es open source y genera subtítulos automáticamente. Revisar siempre el resultado.

## 9. Quemar subtítulos en el video

```bash
# Quemar SRT en el video (burned-in)
ffmpeg -i input.mp4 -vf "subtitles=subs.srt:force_style='FontSize=24,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2'" \
  -c:v libx264 -crf 23 -c:a aac -b:a 128k -movflags +faststart output.mp4
```

## 10. Verificar duración y specs

```bash
# Info del video
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

# Duración en segundos
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4
```

## Anti-patrones

| Anti-patrón | Problema | Solución |
|-------------|----------|----------|
| `-c copy` para cortes exactos | El corte puede quedar en un keyframe, no en el tiempo pedido | Usar `-ss` después de `-i` con re-encoding, o aceptar la imprecisión |
| Re-encodear con CRF bajo (10-15) | Archivo enorme, calidad imperceptible | CRF 20-23 para web, 18 para archivo |
| No usar `-movflags +faststart` | El video no se reproduce hasta descargarlo completo | Siempre para web |
| Ignorar frame rate del origen | Stuttering, desincronización A/V | Forzar `-r 30` o `-r 24` según la plataforma |
| Cortar sin verificar el audio | Cortes a mitad de palabra | Verificar con `ffprobe` y escuchar el clip |