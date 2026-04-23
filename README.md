<p align="center">
  <img src="docs/images/app-icon.png" alt="Silence Remover icon" width="128" height="128">
</p>

# Silence Remover

Silence Remover is a native macOS app built with SwiftUI that removes or shortens long pauses in spoken-word MP3 files.

It is designed for podcasters, voiceover creators, audiobook editors, and anyone who wants faster spoken audio without sending files to a cloud service. Import an MP3, analyze silences locally, preview the result, and export a cleaned MP3 in seconds.

![Silence Remover screenshot](docs/images/app-screenshot.png)

## Why this project exists

I built Silence Remover as a personal macOS product that combines product design, audio processing, and native Apple-platform engineering in one project.

The goal is simple: make silence cleanup feel like a polished desktop utility instead of a script or a DAW workflow.

## Highlights

- Native macOS app built with `SwiftUI`
- Local-first workflow with no server dependency
- MP3 import, waveform visualization, silence detection, preview, and MP3 export
- Two editing modes: remove pauses completely or compress them to a target duration
- Bundled `ffmpeg` integration for MP3/WAV conversion
- Test-covered audio processing core separated from the UI layer
- Designed as both an open-source codebase and a product candidate for the Mac App Store

## What it does

1. Import an MP3 file.
2. Detect pauses using a dB threshold and minimum silence duration.
3. Choose between:
   - `Remove pauses`: cut detected silences entirely
   - `Reduce pauses`: keep a smaller, more natural breathing gap
4. Preview the processed result inside the app.
5. Export a new MP3 at `192 kbps`.

## Tech Stack

- `Swift 6`
- `SwiftUI`
- `AVFoundation`
- `Swift Package Manager`
- `ffmpeg`

## Architecture

The project is intentionally split into two main layers:

- `SoundRemover`: the macOS app, UI, playback, resources, and export flow
- `SoundRemoverCore`: reusable audio-processing logic, including file loading, silence detection, waveform generation, and trimming

That split keeps the core logic testable and makes the project easier to present as a serious personal engineering project rather than a one-off prototype.

## Run locally

### Requirements

- `macOS 14+`
- `Xcode 16+` or a recent Swift 6 toolchain

### Open in Xcode

```bash
git clone https://github.com/felipebasurto/silence-remover.git
cd silence-remover
open Package.swift
```

Then run the `SoundRemover` executable target.

### Run from Terminal

```bash
git clone https://github.com/felipebasurto/silence-remover.git
cd silence-remover
swift build
swift run SoundRemover
```

## Build the app bundle

```bash
./scripts/package_app.sh
```

This creates:

```bash
dist/Sound\ Remover.app
```

## Tests

```bash
swift test
```

## Product Direction

This repository is being developed with two goals in mind:

- Open-source the implementation and document the architecture clearly
- Ship a polished Mac utility that can evolve into a Mac App Store release

Because of that, the project is intentionally opinionated about:

- native UX over cross-platform tooling
- local processing over cloud uploads
- small-scope utility software with a strong visual identity

## Privacy

Silence Remover is built around an offline-first workflow. Audio files are processed locally on the device and are not uploaded to a backend service.

## Why it works as a personal project

If you are reviewing this as a portfolio project, Silence Remover demonstrates:

- product thinking: a clear user problem and a focused utility
- systems design: separation between app shell and processing core
- media tooling: real file handling, waveform generation, and audio transformation
- native platform work: macOS UI, app packaging, resources, and playback
- engineering discipline: tests, structured code, and a path toward distribution

## Roadmap

- Security-scoped bookmarks for persistent recent files
- App Sandbox and Mac App Store readiness improvements
- Better packaging, signing, and notarization workflow
- Drag-and-drop polish and larger batch-processing workflows
- Additional export settings and waveform editing controls

## Status

Active personal project.

The current version already works as a native local utility, and the next major step is tightening the distribution path for a Mac App Store-ready release.
