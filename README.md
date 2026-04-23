# Sound Remover

App nativa de macOS en SwiftUI para cargar un MP3, recortar pausas largas y exportar otro MP3 localmente.

## Ejecutar

```bash
cd /Users/felipe/Downloads/sound-remover
open Package.swift
```

Desde Xcode:

1. Abre el paquete.
2. Selecciona el ejecutable `SoundRemover`.
3. Ejecuta con `Cmd+R`.

También puedes compilar desde terminal:

```bash
swift build
swift run SoundRemover
```

## Qué hace la v1

- Importa `.mp3`.
- Detecta silencios por umbral en dB y duración mínima.
- Permite dos modos: eliminar o reducir pausas.
- Reproduce original y resultado.
- Exporta MP3 a `192 kbps`.

## Notas técnicas

- El target de app incluye un binario `ffmpeg` como recurso para la conversión MP3/WAV/MP3.
- El núcleo de detección y corte vive en `SoundRemoverCore` y tiene tests.
