<p align="center">
  <img src="docs/images/app-icon.png" alt="Audio Silence Remover icon" width="128" height="128">
</p>

# Audio Silence Remover

Native **macOS** app built with **SwiftUI** that removes or shortens long pauses in spoken-word **MP3** files—entirely on your machine.

Built for podcasters, voiceover, and audiobook workflows: import an MP3, tune silence detection, preview, and export a cleaned MP3 (default **192 kbps**) without sending audio to a cloud service.

![Audio Silence Remover screenshot](docs/images/app-screenshot.png)

## Repository layout

Everything lives in one **Xcode project** at the repo root:

| Path | Purpose |
|------|---------|
| `AudioSilenceRemover.xcodeproj` | App + tests; scheme **`AudioSilenceRemover`** |
| `AudioSilenceRemover/` | SwiftUI app: UI, state, playback, export, resources |
| `AudioSilenceRemover/Core/` | Audio pipeline: silence detection, trim, WAV/PCM I/O, MP3 staging, errors |
| `AudioSilenceRemoverTests/` | Unit tests (detector, trimmer, waveform envelope, playback state machine) |
| `scripts/package_app.sh` | Release **archive** → `dist/Audio Silence Remover.app` + **verify** signing |
| `scripts/ffmpeg_bundle.py` | Embeds Homebrew-linked **ffmpeg** dylibs into the `.app` (build phase + verify) |
| `docs/images/` | README assets |

**Bundle ID:** `com.felipebasurto.audiosilenceremover` (matches the Mac App Store Connect app **Audio Silence Remover**).

## Highlights

- **Swift 6** + **SwiftUI** + **AVFoundation**, App **Sandbox** enabled
- **Local-first**: no backend; files stay on disk you control
- **Two modes:** remove silences entirely, or compress them to a target “breathing” length
- **Waveform** preview, **MP3** in/out via bundled **ffmpeg**
- **Recents** persisted with **security-scoped bookmarks** (sandbox-safe reopen)
- **English / Spanish** strings under `AudioSilenceRemover/Resources/{en,es}.lproj/`
- **Distribution path:** Xcode archive + `package_app.sh`; ffmpeg dependencies rewritten into `Contents/Frameworks` so the app does **not** rely on `/opt/homebrew` at runtime

## What it does

1. Import an MP3 (picker or drag-and-drop).
2. Adjust threshold, minimum silence, and (in reduce mode) final pause.
3. Choose **Remove pauses** or **Reduce pauses**.
4. **Process** → preview **Original** / **Result** on the waveform.
5. **Export** a new MP3.

## Architecture

- **`AudioSilenceRemover`** — single macOS target: `@main`, scenes, `AppState`, services, UI under `UI/`, shared `Resources/`.
- **`AudioSilenceRemover/Core`** — pure processing and file concerns, imported by the app so tests can target the same types without a separate Swift package.
- **`AudioSilenceRemoverTests`** — XCTest / Swift Testing against **Core** (and UI-adjacent state where useful).

FFmpeg packaging:

- An Xcode **Run Script** phase runs `scripts/ffmpeg_bundle.py embed` on the built `.app`, copies required **`.dylib`** dependencies into **`Contents/Frameworks`**, and rewrites load paths (`install_name_tool`) so **`Contents/Resources/ffmpeg`** is self-contained for distribution.
- **`package_app.sh`** archives Release, copies the product to **`dist/`**, runs **`ffmpeg_bundle.py verify`** (no lingering Homebrew paths), then **`codesign --verify --deep --strict`**.

## Requirements

- **macOS 15+**
- **Xcode 16+** (Swift 6)

Building **Release** / `package_app.sh` assumes a working **`ffmpeg`** on the **build machine** (e.g. Homebrew) so the script can copy and relink its libraries into the bundle. Runtime on end users does **not** require Homebrew.

## Run in Xcode

```bash
git clone https://github.com/felipebasurto/silence-remover.git
cd silence-remover
open AudioSilenceRemover.xcodeproj
```

Select the **`AudioSilenceRemover`** scheme and run on **My Mac**.

## Build & test from Terminal

```bash
xcodebuild \
  -project AudioSilenceRemover.xcodeproj \
  -scheme AudioSilenceRemover \
  -configuration Debug \
  -destination "platform=macOS" \
  build
```

```bash
xcodebuild \
  -project AudioSilenceRemover.xcodeproj \
  -scheme AudioSilenceRemover \
  -destination "platform=macOS" \
  test
```

Shared test plan: `AudioSilenceRemover.xcodeproj/xcshareddata/xctestplans/AudioSilenceRemover.xctestplan`.

## Release `.app` (local)

```bash
./scripts/package_app.sh
```

Produces **`dist/Audio Silence Remover.app`** (Release archive, verified ffmpeg linkage and codesign). Uses a repo-local **DerivedData** path (`.derivedData/`) so archives stay predictable.

## Logging

FFmpeg resolution and runs log to **`Logger`** with subsystem **`AudioSilenceRemover`**, category **`FFmpeg`** (visible in **Console.app** when debugging).

## Privacy

Offline-first: audio is processed locally; nothing is uploaded by this app.

## Product direction

- Ship a focused Mac utility with a clear editorial story.
- Keep the implementation readable as open source and suitable for **Mac App Store** submission (sandbox, signing, metadata) as the next tightening loop.

## Roadmap (short)

- Hardening: export / sandbox edge cases, optional notarization docs in-repo.
- UX: drag-and-drop polish, batch flows, more export options if needed.

## Status

Active personal project—the app runs as a local utility; distribution is centered on the Xcode archive + scripts above.
