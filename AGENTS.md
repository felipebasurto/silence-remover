## Learned User Preferences

- When the user writes in Spanish, reply in Spanish for conversational explanations.
- Prefer executing setup and tooling locally (install, git, `asc`) rather than instructions-only handoffs when it is safe to run commands.
- Primary UI actions should be visually dominant and easy to find; avoid burying core tasks only in small toolbar controls.
- Visual direction for this app: skeuomorphic styling aligned with the app icon (metal/glossy, cyan accents).
- App Store and public-facing copy should emphasize local-only processing, open source, free, and no user tracking.
- Update README when product behavior or UI changes in a material way.
- Prefer observable diagnostics for audio and FFmpeg flows (logging subsystem, trace files) when debugging sandboxed builds.

## Learned Workspace Facts

- **sound-remover** is an Xcode macOS SwiftUI app project; the Mac App Store listing is **Audio Silence Remover** (macOS only).
- Production bundle ID: `com.felipebasurto.audiosilenceremover`.
- App Store Connect app ID for `asc` and automation: **6763403196**.
- Embedded **ffmpeg** must satisfy App Sandbox requirements like the host app for Mac App Store validation.
- UI strings in-repo are localized for English and Spanish.
- Diagnostics and trace logs live under the sandboxed app container; use Console filtered by bundle ID or the app logging subsystem for live logs.
- There is no App Store Connect MCP server in this workspace by default; use the **asc** CLI and asc-related skills for App Store Connect operations.
