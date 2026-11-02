"""Checks MonHub sources with luau-lsp: syntax, types and lints.

    python tools/check.py              every module under src/
    python tools/check.py FILE ...     only these files (their requires are still read)

luau-lsp runs without Roblox definitions, so Roblox and executor globals and every type
annotation that names a Roblox class would be reported as unknown. Modules also add
fields to shared tables such as Library and Tab, which the type checker reports as
missing keys. Those lines are dropped when the field is assigned somewhere in src/, so a
misspelled field still shows. Everything else is printed and makes the exit code 1.
"""

import os
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
HOME = pathlib.Path.home()

ROBLOX = """
game workspace script plugin shared settings UserSettings Instance Enum UDim UDim2 Vector2 Vector3
Vector2int16 Vector3int16 CFrame Color3 ColorSequence ColorSequenceKeypoint NumberSequence
NumberSequenceKeypoint NumberRange Rect TweenInfo Font Ray RaycastParams OverlapParams Region3
BrickColor PhysicalProperties DateTime Random Axes Faces PathWaypoint SharedTable Content task
typeof tick time wait delay spawn warn elapsedTime version gcinfo utf8 buffer stats debug
"""

EXECUTOR = """
getgenv getrenv getsenv gethui get_hidden_gui gethiddenui protectgui syn cloneref clonereference
getcustomasset getsynasset readfile writefile appendfile isfile isfolder makefolder listfiles
delfile delfolder request http_request http setclipboard toclipboard sethiddenproperty
gethiddenproperty setscriptable identifyexecutor getexecutorname loadstring getconnections
hookfunction newcclosure iscclosure firesignal fireclick getrawmetatable setrawmetatable
getnamecallmethod checkcaller Drawing crypt base64_encode base64_decode base64 isrbxactive
iswindowactive keypress keyrelease mouse1click setfpscap getfpscap queue_on_teleport
queueonteleport getthreadidentity setthreadidentity getfenv setfenv
"""

KNOWN = set((ROBLOX + EXECUTOR).split())
LINE = re.compile(r"^(?P<path>.+?)\((?P<line>\d+),(?P<col>\d+)\): (?P<kind>\w+): (?P<message>.*)$")
UNKNOWN_GLOBAL = re.compile(r"Unknown global '([^']+)'")
SHARED_FIELD = re.compile(r"(?:Cannot add property|Key) '([^']+)' (?:to table|not found in table)")
ASSIGNED = re.compile(r"[.:](\w+)\s*=[^=]|function\s+[\w.]+[.:](\w+)\s*\(|^\s*(\w+)\s*=[^=]|\[\"(\w+)\"\]\s*=")


def assigned_fields():
    """Every name that some module assigns as a table field or defines as a method."""
    names = set()
    for path in SRC.rglob("*.luau"):
        if "notes" in path.parts:
            continue
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            for match in ASSIGNED.finditer(line):
                names.update(group for group in match.groups() if group)
    return names


def luau_lsp():
    candidates = [
        os.environ.get("MONHUB_LUAU_LSP"),
        shutil.which("luau-lsp"),
        str(HOME / "AppData" / "Local" / "Real" / "real-3.0.1" / "bin" / "luau-lsp.exe"),
    ]
    for candidate in candidates:
        if candidate and pathlib.Path(candidate).is_file():
            return candidate
    print("error: luau-lsp not found; set MONHUB_LUAU_LSP to its path", file=sys.stderr)
    sys.exit(2)


def analyze(files):
    """Runs luau-lsp on the files and returns the problem lines that matter."""
    result = subprocess.run(
        [luau_lsp(), "analyze", "--platform", "standard", "--no-flags-enabled", *map(str, files)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        cwd=SRC,
    )
    problems = []
    fields = assigned_fields()
    for raw in (result.stdout + result.stderr).splitlines():
        match = LINE.match(raw.strip())
        if not match:
            continue
        message = match["message"]
        if match["kind"] == "UnknownType":
            continue
        if match["kind"] == "TypeError":
            unknown = UNKNOWN_GLOBAL.search(message)
            if unknown and unknown.group(1) in KNOWN:
                continue
            if message.startswith("Unknown type"):
                continue
            shared = SHARED_FIELD.search(message)
            if shared and shared.group(1) in fields:
                continue
        path = match["path"].replace("\\", "/")
        problems.append(f"{path}({match['line']},{match['col']}): {match['kind']}: {message}")
    return sorted(set(problems))


def syntax_errors(files):
    """Only the syntax errors, for checking bundled output where types are noise."""
    result = subprocess.run(
        [luau_lsp(), "analyze", "--platform", "standard", *map(str, files)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return [line for line in (result.stdout + result.stderr).splitlines() if "SyntaxError" in line]


def main():
    if len(sys.argv) > 1:
        files = [pathlib.Path(name).resolve() for name in sys.argv[1:]]
    else:
        files = sorted(path for path in SRC.rglob("*.luau") if "notes" not in path.parts)
    problems = analyze(files)
    for line in problems:
        print(line)
    print(f"{len(problems)} problem(s) in {len(files)} file(s)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
