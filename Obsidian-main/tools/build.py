import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
WORK = ROOT / ".build"
CONFIG = ROOT / ".darklua.json"
WINDUI_CONFIG = ROOT / ".darklua.windui.json"
WINDUI = ROOT / "windui"
KEEP_BUILDS = 5
PINNED = re.compile(r"^(Library|WindUI)\.[0-9a-f]{12}\.lua$")
DARKLUA = shutil.which("darklua") or str(pathlib.Path.home() / ".aftman" / "bin" / "darklua.exe")


def addon_files():
    files = sorted((ROOT / "addons").glob("*.lua"))
    names = {}
    for path in files:
        name = path.stem
        if name in names:
            sys.exit(f"Duplicate addon name {name}: {names[name]} and {path}")
        names[name] = path
    return names


def read(path):
    return path.read_text(encoding="utf-8").replace("\r\n", "\n")


def darklua(source, target, config=CONFIG):
    target.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [DARKLUA, "process", str(source), str(target), "--config", str(config)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.exit(f"darklua failed on {source}:\n{result.stdout}\n{result.stderr}")


def build_windui():
    work = WORK / "windui"
    shutil.copytree(WINDUI / "src", work / "src")
    lucide = "local writefile, isfolder, makefolder, getcustomasset = nil, nil, nil, nil\n" + read(ROOT / "vendor" / "lucide.lua")
    (work / "src" / "modules" / "Lucide.lua").write_text(lucide, encoding="utf-8")
    target = DIST / "WindUI.lua"
    darklua(work / "src" / "Init.lua", target, WINDUI_CONFIG)
    header = "-- WindUI 1.6.66, MonHub build. Copyright (c) 2026 Footages. MIT License, see windui/LICENSE.\n"
    body = target.read_bytes().decode("utf-8").replace("\r\n", "\n").rstrip()
    text = (header + body).encode("utf-8")
    target.write_bytes(text)
    return f"{hashlib.sha256(text).hexdigest()[:12]}-{len(text)}"


def build():
    if WORK.exists():
        shutil.rmtree(WORK)
    WORK.mkdir()
    earlier = {}
    if DIST.exists():
        for path in DIST.glob("*.lua"):
            if PINNED.match(path.name):
                earlier[path.name] = (path.read_bytes(), path.stat().st_mtime)
        shutil.rmtree(DIST)
    DIST.mkdir()

    addons = addon_files()
    parts = [
        "local MonHubBundle = { MonHubBundle = true, Modules = {} }",
        "MonHubBundle.Icons = function()",
        "local writefile, isfolder, makefolder, getcustomasset = nil, nil, nil, nil",
        read(ROOT / "vendor" / "lucide.lua"),
        "end",
    ]
    for name, path in addons.items():
        parts += [f"MonHubBundle.Modules.{name} = function(...)", read(path), "end"]
    parts += ["return (function(...)", read(ROOT / "Library.lua"), "end)(MonHubBundle)"]

    bundle = WORK / "Library.luau"
    bundle.write_text("\n".join(parts) + "\n", encoding="utf-8")
    darklua(bundle, DIST / "Library.lua")

    for name, path in addons.items():
        darklua(path, DIST / path.relative_to(ROOT))

    library = DIST / "Library.lua"
    text = library.read_bytes().replace(b"\r\n", b"\n").rstrip()
    library.write_bytes(text)
    version = f"{hashlib.sha256(text).hexdigest()[:12]}-{len(text)}"
    (DIST / "version.txt").write_bytes((version + "\n").encode("ascii"))
    windui_version = build_windui()
    (DIST / "WindUI.version.txt").write_bytes((windui_version + chr(10)).encode("ascii"))
    shutil.copyfile(ROOT / "Loader.lua", DIST / "Loader.lua")
    shutil.copyfile(ROOT / "Diagnose.lua", DIST / "Diagnose.lua")

    current = {
        "Library": f"Library.{version.split('-')[0]}.lua",
        "WindUI": f"WindUI.{windui_version.split('-')[0]}.lua",
    }
    (DIST / current["Library"]).write_bytes(text)
    (DIST / current["WindUI"]).write_bytes((DIST / "WindUI.lua").read_bytes())
    for name, (data, modified) in earlier.items():
        if name not in current.values():
            target = DIST / name
            target.write_bytes(data)
            os.utime(target, (modified, modified))
    for prefix, pinned_name in current.items():
        builds = sorted(
            (path for path in DIST.glob(f"{prefix}.*.lua") if PINNED.match(path.name)),
            key=lambda path: (path.name == pinned_name, path.stat().st_mtime),
            reverse=True,
        )
        for path in builds[KEEP_BUILDS:]:
            path.unlink()

    report = {"Library.lua": library.stat().st_size}
    for path in sorted(DIST.rglob("*.lua")):
        report[str(path.relative_to(DIST)).replace("\\", "/")] = path.stat().st_size
    (DIST / "sizes.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    source_size = (ROOT / "Library.lua").stat().st_size + sum(p.stat().st_size for p in addons.values())
    print(f"sources {source_size // 1024} KB -> dist/Library.lua {report['Library.lua'] // 1024} KB "
          f"(library + {len(addons)} addons + icons), version {version}")
    print(f"windui -> dist/WindUI.lua {report['WindUI.lua'] // 1024} KB, version {windui_version}")


if __name__ == "__main__":
    build()
