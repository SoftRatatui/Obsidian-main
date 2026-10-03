import json
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
WORK = ROOT / ".build"
CONFIG = ROOT / ".darklua.json"
DARKLUA = shutil.which("darklua") or str(pathlib.Path.home() / ".aftman" / "bin" / "darklua.exe")


def addon_files():
    files = sorted((ROOT / "addons").glob("*.lua")) + sorted((ROOT / "addons" / "esp").glob("*.lua"))
    names = {}
    for path in files:
        name = path.stem
        if name in names:
            sys.exit(f"Duplicate addon name {name}: {names[name]} and {path}")
        names[name] = path
    return names


def read(path):
    return path.read_text(encoding="utf-8").replace("\r\n", "\n")


def darklua(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [DARKLUA, "process", str(source), str(target), "--config", str(CONFIG)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.exit(f"darklua failed on {source}:\n{result.stdout}\n{result.stderr}")


def build():
    if WORK.exists():
        shutil.rmtree(WORK)
    WORK.mkdir()
    if DIST.exists():
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

    report = {"Library.lua": (DIST / "Library.lua").stat().st_size}
    for path in sorted(DIST.rglob("*.lua")):
        report[str(path.relative_to(DIST)).replace("\\", "/")] = path.stat().st_size
    (DIST / "sizes.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    source_size = (ROOT / "Library.lua").stat().st_size + sum(p.stat().st_size for p in addons.values())
    print(f"sources {source_size // 1024} KB -> dist/Library.lua {report['Library.lua'] // 1024} KB "
          f"(library + {len(addons)} addons + icons)")


if __name__ == "__main__":
    build()
