import json
import pathlib
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
REPO = "SoftRatatui/Obsidian-main"
BRANCH = "main"
FOLDER = "Obsidian-main/"

# jsDelivr keeps @main files for up to 12 hours. After a push, ask it to drop
# the files whose names do not change, so every mirror serves the new build.
FIXED = ["version.txt", "Library.lua", "WindUI.version.txt", "WindUI.lua", "Loader.lua", "Load.lua", "Diagnose.lua"]
ROOT_FIXED = ["Library.lua", "Loader.lua", "Diagnose.lua", "vendor/lucide.lua"]


def purge(path):
    url = f"https://purge.jsdelivr.net/gh/{REPO}@{BRANCH}/{FOLDER}{path}"
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "monhub-purge"}), timeout=30) as response:
            body = json.loads(response.read().decode("utf-8") or "{}")
            ok = response.status == 200 and body.get("status") != "error"
            return ok, body.get("status", response.status)
    except Exception as error:
        return False, str(error)


def main():
    names = [f"dist/{name}" for name in FIXED]
    names += [f"dist/addons/{p.name}" for p in sorted((DIST / "addons").glob("*.lua"))]
    names += ROOT_FIXED + [f"addons/{p.name}" for p in sorted((ROOT / "addons").glob("*.lua"))]
    failed = 0
    for name in names:
        ok, detail = purge(name)
        failed += 0 if ok else 1
        print(f"{'ok  ' if ok else 'FAIL'} {name} ({detail})")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
