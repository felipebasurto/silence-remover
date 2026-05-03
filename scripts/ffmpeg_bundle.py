#!/usr/bin/env python3

from __future__ import annotations

import os
import plistlib
import shutil
import subprocess
import sys
from pathlib import Path


HOME_BREW_PREFIXES = ("/opt/homebrew/", "/usr/local/", "/opt/local/")

# Must match app sandbox story; App Store validates nested executables.
FFMPEG_ENTITLEMENTS = Path(__file__).resolve().parent / "ffmpeg-sandbox.entitlements"


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE)
    return result.stdout


def run_bytes(cmd: list[str]) -> bytes:
    result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE)
    return result.stdout


def load_commands(binary: Path) -> list[str]:
    output = run(["otool", "-L", str(binary)])
    deps: list[str] = []
    for line in output.splitlines()[1:]:
        line = line.strip()
        if not line:
            continue
        deps.append(line.split(" ", 1)[0])
    return deps


def is_homebrew_path(path: str) -> bool:
    return path.startswith(HOME_BREW_PREFIXES)


def install_name(binary: Path) -> str:
    return f"@loader_path/{binary.name}"


def relative_dependency(binary: Path, dep_name: str) -> str:
    if binary.parent.name == "Resources":
        return f"@loader_path/../Frameworks/{dep_name}"
    return f"@loader_path/{dep_name}"


def has_code_signature(binary: Path) -> bool:
    return subprocess.run(
        ["codesign", "-dv", str(binary)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode == 0


def remove_code_signature(binary: Path) -> None:
    if not has_code_signature(binary):
        return

    subprocess.run(
        ["codesign", "--remove-signature", str(binary)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )


def strip_for_app_store(binary: Path) -> None:
    """Remove debug symbols from the shipped Mach-O after dSYMs are emitted."""
    subprocess.run(
        ["strip", "-x", "-S", str(binary)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def emit_third_party_dsym(binary: Path, dsym_dir: Path | None) -> None:
    """Emit a dSYM bundle into Xcode's dSYM folder so App Store Connect symbol upload succeeds."""
    if dsym_dir is None:
        return
    try:
        dsym_dir.mkdir(parents=True, exist_ok=True)
    except OSError:
        return
    out = dsym_dir / f"{binary.name}.dSYM"
    if out.exists():
        shutil.rmtree(out, ignore_errors=True)
    subprocess.run(
        ["dsymutil", str(binary), "-o", str(out)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def sign_binary(binary: Path, *, entitlements: Path | None = None) -> None:
    identity = os.environ.get("EXPANDED_CODE_SIGN_IDENTITY") or "-"
    command = [
        "codesign",
        "--force",
        "--sign",
        identity,
        "--timestamp=none",
    ]
    if os.environ.get("ENABLE_HARDENED_RUNTIME") == "YES":
        command.extend(["--options", "runtime"])
    if entitlements is not None and entitlements.is_file():
        command.extend(["--entitlements", str(entitlements)])
    command.append(str(binary))
    subprocess.run(command, check=True)


def read_entitlements(binary: Path) -> dict[str, object]:
    try:
        data = run_bytes(["codesign", "-d", "--entitlements", ":-", str(binary)])
    except subprocess.CalledProcessError as error:
        stderr = error.stderr.decode("utf-8", errors="replace") if error.stderr else ""
        raise SystemExit(f"could not read entitlements for {binary}: {stderr}") from error
    if not data:
        return {}
    try:
        return plistlib.loads(data)
    except plistlib.InvalidFileException as error:
        raise SystemExit(f"invalid entitlements plist for {binary}") from error


def patch_binary(binary: Path, copied: dict[str, Path], dsym_dir: Path | None) -> None:
    deps = load_commands(binary)
    remove_code_signature(binary)
    if binary.parent.name == "Frameworks":
        subprocess.run(["install_name_tool", "-id", install_name(binary), str(binary)], check=True)

    for dep in deps:
        replacement = copied.get(dep)
        if replacement is None:
            continue
        subprocess.run(
            [
                "install_name_tool",
                "-change",
                dep,
                relative_dependency(binary, replacement.name),
                str(binary),
            ],
            check=True,
        )
    emit_third_party_dsym(binary, dsym_dir)
    strip_for_app_store(binary)
    ffmpeg_entitlements = (
        FFMPEG_ENTITLEMENTS
        if binary.name == "ffmpeg" and binary.parent.name == "Resources"
        else None
    )
    sign_binary(binary, entitlements=ffmpeg_entitlements)


def copy_dependency(dep: str, frameworks_dir: Path, copied: dict[str, Path], queue: list[Path]) -> None:
    if dep in copied:
        return

    resolved = Path(dep).resolve()
    destination = frameworks_dir / Path(dep).name
    shutil.copy2(resolved, destination)
    os.chmod(destination, 0o755)
    copied[dep] = destination
    queue.append(destination)


def embed(app_path: Path) -> None:
    resources_dir = app_path / "Contents" / "Resources"
    frameworks_dir = app_path / "Contents" / "Frameworks"
    ffmpeg_path = resources_dir / "ffmpeg"

    if not ffmpeg_path.exists():
        raise SystemExit(f"missing ffmpeg binary at {ffmpeg_path}")

    frameworks_dir.mkdir(parents=True, exist_ok=True)
    os.chmod(ffmpeg_path, 0o755)

    copied: dict[str, Path] = {}
    queue: list[Path] = [ffmpeg_path]

    while queue:
        binary = queue.pop(0)
        for dep in load_commands(binary):
            if is_homebrew_path(dep):
                copy_dependency(dep, frameworks_dir, copied, queue)

    raw_dsym = os.environ.get("DWARF_DSYM_FOLDER_PATH", "").strip()
    dsym_dir = Path(raw_dsym).resolve() if raw_dsym else None

    patch_binary(ffmpeg_path, copied, dsym_dir)
    for binary in copied.values():
        patch_binary(binary, copied, dsym_dir)


def verify(app_path: Path) -> None:
    resources_dir = app_path / "Contents" / "Resources"
    frameworks_dir = app_path / "Contents" / "Frameworks"
    ffmpeg_path = resources_dir / "ffmpeg"

    required = [
        ffmpeg_path,
        resources_dir / "en.lproj" / "InfoPlist.strings",
        resources_dir / "en.lproj" / "Localizable.strings",
        resources_dir / "es.lproj" / "InfoPlist.strings",
        resources_dir / "es.lproj" / "Localizable.strings",
        resources_dir / "Assets.car",
    ]

    missing = [path for path in required if not path.exists()]
    if missing:
        raise SystemExit("missing bundle contents: " + ", ".join(str(path) for path in missing))

    if not os.access(ffmpeg_path, os.X_OK):
        raise SystemExit(f"ffmpeg is not executable: {ffmpeg_path}")

    ffmpeg_entitlements = read_entitlements(ffmpeg_path)
    required_ffmpeg_entitlements = {
        "com.apple.security.app-sandbox": True,
        "com.apple.security.inherit": True,
    }
    missing_entitlements = [
        key
        for key, expected in required_ffmpeg_entitlements.items()
        if ffmpeg_entitlements.get(key) != expected
    ]
    if missing_entitlements:
        raise SystemExit(
            "ffmpeg is not signed as a sandbox-inheriting helper; missing entitlements: "
            + ", ".join(missing_entitlements)
        )

    inspected = [ffmpeg_path]
    if frameworks_dir.exists():
        inspected.extend(sorted(frameworks_dir.glob("*.dylib")))

    bad_refs: list[str] = []
    for binary in inspected:
        deps = load_commands(binary)
        for dep in deps:
            if is_homebrew_path(dep):
                bad_refs.append(f"{binary}: {dep}")

    if bad_refs:
        raise SystemExit("bundle still references Homebrew dylibs:\n" + "\n".join(bad_refs))


def main() -> None:
    if len(sys.argv) != 3 or sys.argv[1] not in {"embed", "verify"}:
        raise SystemExit("usage: ffmpeg_bundle.py [embed|verify] /path/to/App.app")

    command = sys.argv[1]
    app_path = Path(sys.argv[2]).resolve()

    if command == "embed":
        embed(app_path)
    else:
        verify(app_path)


if __name__ == "__main__":
    main()
