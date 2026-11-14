"""Builds MonHub from src/ with darklua.

    python tools/build.py          release: dist/ and the repository root
    python tools/build.py --beta   beta/ only: the bundle as Library.<version>.lua and
                                   Library.core.lua, its add-ons, and Library.lua as the
                                   loader that fetches the bundle once per PC
    python tools/build.py --dev    readable bundle plus the release bundle, copied to the test workspace

Every output is compiled with luau-compile before the script reports success.
"""

import argparse
import hashlib
import json
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
ENTRY = SRC / "Library.luau"
ADDON_SRC = SRC / "addons"
DIST = ROOT / "dist"
BETA = ROOT / "beta"
STAGE = ROOT / ".build"
BUNDLE_CONFIG = ROOT / ".darklua.bundle.json"
DEV_CONFIG = ROOT / ".darklua.dev.json"
KEEP_BUILDS = 5
# Clients keep a beta loader for up to half an hour before their hub fetches a newer one,
# so more pinned beta builds stay online than release builds.
KEEP_BETA_BUILDS = 8
BETA_LOADER = ROOT / "tools" / "beta_loader.luau"
# Hub loaders written for the full bundle treat a Library.lua under this size as a broken
# download, so the beta loader is padded past it.
HUB_MINIMUM = 10000
PINNED = re.compile(r"^Library\.[0-9a-f]{12}\.lua$")

HOME = pathlib.Path.home()
DARKLUA = shutil.which("darklua") or str(HOME / ".aftman" / "bin" / "darklua.exe")
LUAU_COMPILE = HOME / "AppData" / "Local" / "Temp" / "monhub-luau-tools" / "luau-compile.exe"
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import check as luau_check  # noqa: E402
WORKSPACE = HOME / "AppData" / "Local" / "Real" / "workspace" / "monhub_rewrite"


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def bundle(source, config, name):
    """Runs darklua on one entry file and returns the output as LF text with one final newline."""
    target = STAGE / "stage" / name
    target.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [DARKLUA, "process", str(source), str(target), "--config", str(config)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(f"darklua failed on {source.name}:\n{result.stdout}{result.stderr}")
    text = target.read_bytes().decode("utf-8").replace("\r\n", "\n")
    return text.rstrip() + "\n"


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def addon_sources():
    return {path.stem: path for path in sorted(ADDON_SRC.glob("*.luau"))}


def remove_stale_addons(folder, names):
    for path in folder.glob("*.lua"):
        if path.stem not in names:
            path.unlink()
            print(f"removed {path.relative_to(ROOT).as_posix()}")


def rotate_builds(current):
    builds = sorted(
        (path for path in DIST.glob("Library.*.lua") if PINNED.match(path.name)),
        key=lambda path: (path.name == current, path.stat().st_mtime),
        reverse=True,
    )
    for path in builds[KEEP_BUILDS:]:
        path.unlink()


def rotate_beta_builds(current):
    builds = sorted(
        (path for path in BETA.glob("Library.*.lua") if PINNED.match(path.name)),
        key=lambda path: (path.name == current, path.stat().st_mtime),
        reverse=True,
    )
    for path in builds[KEEP_BETA_BUILDS:]:
        path.unlink()


def beta_loader(sha, size):
    """tools/beta_loader.luau filled in for one build."""
    text = BETA_LOADER.read_text(encoding="utf-8").replace("\r\n", "\n")
    text = text.replace('"__VERSION__"', f'"{sha}"').replace("__SIZE__", str(size))
    if "__VERSION__" in text or "__SIZE__" in text:
        fail("tools/beta_loader.luau lost its __VERSION__ or __SIZE__ marker")
    length = len(text.encode("utf-8"))
    if length <= HUB_MINIMUM:
        text += "-- " + "-" * (HUB_MINIMUM + 256 - length) + "\n"
    return text


def write_sizes():
    report = {"Library.lua": (DIST / "Library.lua").stat().st_size}
    for path in sorted(DIST.rglob("*.lua")):
        report[path.relative_to(DIST).as_posix()] = path.stat().st_size
    write(DIST / "sizes.json", json.dumps(report, indent=2) + "\n")


def release():
    """Builds dist/ and the repository root. Returns the files to compile."""
    text = bundle(ENTRY, BUNDLE_CONFIG, "Library.lua")
    data = text.encode("utf-8")
    sha = hashlib.sha256(data).hexdigest()[:12]
    version = f"{sha}-{len(data)}"
    pinned = f"Library.{sha}.lua"

    outputs = [DIST / "Library.lua", DIST / pinned, ROOT / "Library.lua"]
    for path in outputs:
        write(path, text)
    write(DIST / "version.txt", version + "\n")
    rotate_builds(pinned)

    addons = addon_sources()
    for name, source in addons.items():
        addon = bundle(source, BUNDLE_CONFIG, f"addons/{name}.lua")
        for folder in (DIST / "addons", ROOT / "addons"):
            write(folder / f"{name}.lua", addon)
            outputs.append(folder / f"{name}.lua")
    remove_stale_addons(DIST / "addons", addons)
    remove_stale_addons(ROOT / "addons", addons)
    write_sizes()
    print(f"version {version}")
    return outputs


def beta():
    """Builds beta/, leaving dist/ and the root alone. The bundle goes to
    Library.<version>.lua and Library.core.lua; Library.lua is the loader, which every
    client on a PC uses to share one downloaded copy of the bundle."""
    text = bundle(ENTRY, BUNDLE_CONFIG, "Library.lua")
    data = text.encode("utf-8")
    sha = hashlib.sha256(data).hexdigest()[:12]
    version = f"{sha}-{len(data)}"
    pinned = f"Library.{sha}.lua"
    write(BETA / pinned, text)
    write(BETA / "Library.core.lua", text)
    write(BETA / "Library.lua", beta_loader(sha, len(data)))
    write(BETA / "version.txt", version + "\n")
    rotate_beta_builds(pinned)
    outputs = [BETA / "Library.lua", BETA / pinned, BETA / "Library.core.lua"]
    addons = addon_sources()
    for name, source in addons.items():
        path = BETA / "addons" / f"{name}.lua"
        write(path, bundle(source, BUNDLE_CONFIG, f"addons/{name}.lua"))
        outputs.append(path)
    remove_stale_addons(BETA / "addons", addons)
    print(f"version {version}")
    return outputs


def development():
    """Builds the readable and the release bundle for the in-game test workspace."""
    readable = bundle(ENTRY, DEV_CONFIG, "MonHub.dev.lua")
    minified = bundle(ENTRY, BUNDLE_CONFIG, "MonHub.min.lua")
    outputs = []
    for name, text in (("MonHub.dev.lua", readable), ("MonHub.min.lua", minified)):
        write(STAGE / name, text)
        outputs.append(STAGE / name)
    write(WORKSPACE / "MonHub.lua", readable)
    write(WORKSPACE / "MonHub.min.lua", minified)
    outputs += [WORKSPACE / "MonHub.lua", WORKSPACE / "MonHub.min.lua"]
    return outputs


def compile_errors(path):
    """luau-compile output for a file, or luau-lsp syntax errors when the compiler is missing."""
    if LUAU_COMPILE.is_file():
        result = subprocess.run([str(LUAU_COMPILE), "--null", str(path)], capture_output=True, text=True)
        return "" if result.returncode == 0 else (result.stdout + result.stderr).strip()
    return "\n".join(luau_check.syntax_errors([path]))


def check(outputs):
    """Compiles every output; returns True when all of them parse and compile."""
    clean = True
    for path in outputs:
        errors = compile_errors(path)
        try:
            label = path.relative_to(ROOT).as_posix()
        except ValueError:
            label = str(path)
        size = path.stat().st_size
        if not errors:
            print(f"ok    {size / 1024:8.1f} KB  {label}")
        else:
            clean = False
            print(f"FAIL  {size / 1024:8.1f} KB  {label}")
            print(errors)
    return clean


def main():
    parser = argparse.ArgumentParser(description="Build MonHub with darklua.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dev", action="store_true", help="readable bundle for the test workspace instead of dist/")
    mode.add_argument("--beta", action="store_true", help="release bundle in beta/ instead of dist/")
    arguments = parser.parse_args()
    if not ENTRY.is_file():
        fail(f"{ENTRY} is missing")
    if not (BUNDLE_CONFIG.is_file() and DEV_CONFIG.is_file()):
        fail("the darklua configs .darklua.bundle.json and .darklua.dev.json are missing")
    STAGE.mkdir(exist_ok=True)
    if arguments.dev:
        outputs = development()
    elif arguments.beta:
        outputs = beta()
    else:
        outputs = release()
    if not check(outputs):
        sys.exit(1)


if __name__ == "__main__":
    main()
