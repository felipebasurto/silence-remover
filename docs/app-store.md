# Mac App Store & release notes

Operational reference for **Audio Silence Remover** distribution—not required to understand or use the app.

**Bundle ID:** `com.felipebasurto.audiosilenceremover` (Mac App Store Connect app **Audio Silence Remover**)

**App Store listing:** [apps.apple.com/app/id6763403196](https://apps.apple.com/app/id6763403196)

---

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
| [`docs/privacy-policy.html`](privacy-policy.html) | Privacy policy page (publish via GitHub **Pages** `/docs` for App Store URL) |
| [`LICENSE`](../LICENSE) | **MIT License** |
| [`AGENTS.md`](../AGENTS.md) | Durable prefs/facts for AI coding agents working in this repo |

---

## Architecture

- **`AudioSilenceRemover`** — single macOS target: `@main`, scenes, `AppState`, services, UI under `UI/`, shared `Resources/`.
- **`AudioSilenceRemover/Core`** — pure processing and file concerns, imported by the app so tests can target the same types without a separate Swift package.
- **`AudioSilenceRemoverTests`** — XCTest / Swift Testing against **Core** (and UI-adjacent state where useful).

### FFmpeg packaging

- An Xcode **Run Script** phase runs `scripts/ffmpeg_bundle.py embed` on the built `.app`, copies required **`.dylib`** dependencies into **`Contents/Frameworks`**, and rewrites load paths (`install_name_tool`) so **`Contents/Resources/ffmpeg`** is self-contained for distribution.
- **`package_app.sh`** archives Release, copies the product to **`dist/`**, runs **`ffmpeg_bundle.py verify`** (no lingering Homebrew paths), then **`codesign --verify --deep --strict`**.

---

## Requirements (release builds)

- **macOS 15+**
- **Xcode 16+** (Swift 6)

Building **Release** / `package_app.sh` assumes a working **`ffmpeg`** on the **build machine** (e.g. Homebrew) so the script can copy and relink its libraries into the bundle. Runtime on end users does **not** require Homebrew.

---

## Release `.app` (local)

```bash
./scripts/package_app.sh
```

Produces **`dist/Audio Silence Remover.app`** (Release archive, verified ffmpeg linkage and codesign). Uses a repo-local **DerivedData** path (`.derivedData/`) so archives stay predictable.

---

## Mac App Store (archive / validation)

- Bundled **`Contents/Resources/ffmpeg`** is **code-signed as a sandbox-inheriting helper** via `scripts/ffmpeg-sandbox.entitlements` (`app-sandbox` + `inherit`). Without sandboxing, App Store Connect reports *“App sandbox not enabled”* for the nested executable; without inheritance, the shipped helper can die during sandbox initialization before FFmpeg writes stderr.
- During **archive** (and other builds where Xcode sets **`DWARF_DSYM_FOLDER_PATH`**), `scripts/ffmpeg_bundle.py` runs **`dsymutil`** on ffmpeg and each embedded **`.dylib`** so those bundles land next to the app’s dSYM; App Store Connect’s *Upload Symbols* step can match UUIDs. After that, **`strip -x -S`** shrinks the shipped Mach-O files.

Re-archive in Xcode after changing `scripts/ffmpeg_bundle.py` or entitlements.

---

## App Store Connect — checklist before “Add for review”

Connect will block submission until these are done:

1. **Privacy policy URL** — In **App Privacy** (left sidebar), paste a **public HTTPS** URL. This repo includes [`docs/privacy-policy.html`](privacy-policy.html). Publish it with **GitHub Pages** (*Settings → Pages → Build and deployment: branch `main`, folder `/docs`*), then use:
   **`https://felipebasurto.github.io/silence-remover/privacy-policy.html`**
   (Push the file to `main` first; if the URL 404s, Pages is not enabled yet.)
2. **App Privacy questionnaire** — Same **App Privacy** section: an **Account Holder or Admin** must complete **Privacy practices** (for a purely local app, Apple’s flow is usually **no data collected** from the app; answer each category truthfully).
3. **Price and availability** — **Monetization → Pricing**: choose a **free** price tier (e.g. **Free**); save.
4. **Copyright** (Mac App Store version page) — Not optional. Use your legal line, e.g. **`2026 Felipe Basurto Barrio`** or **`© 2026 Felipe Basurto Barrio`** (match how you want it shown on the store; avoid leaving the field empty — the “200” in the UI is often **characters remaining**, not the value saved).
5. **Screenshots** — Meet Apple’s **minimum** for Mac (use **Gestor de recursos multimedia** if needed); one screenshot may not be enough for all required display sizes.
6. **App Review information** — **Nombre, apellidos, teléfono y correo** del contacto de revisión are required; “Es necesario iniciar sesión” only applies if the app needs an account (this app does not — leave login blank or indicate not applicable per Apple’s form).

---

## App Store Connect — suggested listing copy

Use or adapt this in **App Store Connect → App Information / Mac App Store** (English primary; add Spanish localization in **App Store** tab if you want).

**Subtitle** (short, under Apple limits):

> Free, local MP3 silence editor — open source.

**Promotional text** (optional; can change anytime without a new binary):

> 100% on your Mac: no cloud upload. Free on the store. Full source code on GitHub so you can see exactly how your files are processed.

**Description** (long):

> Audio Silence Remover is a **free** utility for podcasters, voiceover artists, and anyone working with spoken-word **MP3** files. It detects long silences and either removes them or shortens them so playback feels tighter—**everything runs on your Mac**; your audio is never sent to our servers because there are none.
>
> **Local & private:** Import an MP3, adjust threshold and timing, preview on the waveform, then export a new MP3 (default 192 kbps). App Sandbox keeps access scoped to files you choose.
>
> **Open source:** The complete app source is public at `https://github.com/felipebasurto/silence-remover` under the **MIT License** — free for anyone to use, study, and redistribute under those terms.

**Follow the author:** [@fildotai on X](https://x.com/fildotai)

**Keywords** (comma-separated, no spaces after commas; stay within Apple’s character limit):

> MP3,silence,podcast,voiceover,local,offline,free,open source,audio edit,trim

**Support URL:** your site or the GitHub repo **Issues** page. **Marketing URL:** same GitHub repo is fine.

**Copyright / age rating:** align with your legal entity; the app’s plist copyright string is set in Xcode (`NSHumanReadableCopyright`).

### Spanish (store listing) — optional

**Subtítulo:** Gratis y local: recorta silencios en MP3 — código abierto.

**Descripción (resumen):** Utilidad **gratuita** para acortar o eliminar pausas largas en MP3 de voz. Todo el procesamiento ocurre **en tu Mac**; sin subidas a la nube. **Código abierto** (licencia **MIT**) en GitHub: `felipebasurto/silence-remover`. Sigue al autor en X: **@fildotai**.

---

## Privacy (App Store)

Offline-first: audio is processed locally; nothing is uploaded by this app.

For **App Store Connect**, publish [`docs/privacy-policy.html`](privacy-policy.html) over **HTTPS** (recommended: GitHub Pages from `/docs`; see checklist above).

---

## Product direction

- Ship a focused Mac utility with a clear editorial story.
- Keep the implementation readable as open source and suitable for **Mac App Store** submission (sandbox, signing, metadata) as the next tightening loop.

## Roadmap (short)

- Hardening: export / sandbox edge cases, optional notarization docs in-repo.
- UX: drag-and-drop polish, batch flows, more export options if needed.
