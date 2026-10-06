import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

LIBRARY_LOAD = re.compile(
    r'loadstring\(game:HttpGet\(BASE \.\. "Library\.lua\?monhub=" \.\. RELEASE\)\)\(\)'
)
ADDON_LOAD = re.compile(
    r'loadstring\(game:HttpGet\(BASE \.\. "addons/(\w+)\.lua\?monhub=" \.\. RELEASE\)\)\(\)'
)


def long_string(text):
    level = 1
    while f"]{'=' * level}]" in text:
        level += 1
    bar = "=" * level
    return f"[{bar}[\n{text}]{bar}]"


def main():
    args = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
    light = "--light" in sys.argv
    if not args:
        sys.exit("usage: python tools/embed_hub.py [--light] hub.lua [output.lua]")

    hub_path = pathlib.Path(args[0])
    suffix = ".light.lua" if light else ".embedded.lua"
    out_path = pathlib.Path(args[1]) if len(args) > 1 else hub_path.with_suffix(suffix)
    loader = (ROOT / "Loader.lua").read_text(encoding="utf-8").replace("\r\n", "\n")
    hub = hub_path.read_bytes().decode("utf-8")
    newline = "\r\n" if "\r\n" in hub else "\n"

    hub, library_sites = LIBRARY_LOAD.subn("MonHubLoad()", hub)
    if library_sites != 1:
        sys.exit(f"expected one Library.lua download in {hub_path.name}, found {library_sites}")
    hub, addon_sites = ADDON_LOAD.subn(lambda match: f"Library.Addons.{match.group(1)}", hub)

    head = loader + "\n"
    if not light:
        library = (ROOT / "dist" / "Library.lua").read_text(encoding="utf-8")
        head += f"MonHubConfig.Embedded = {long_string(library)}\n\n"
    out_path.write_bytes((head.replace("\n", newline) + hub).encode("utf-8"))
    print(f"{hub_path.name}: library load replaced, {addon_sites} addon loads replaced")
    print(f"wrote {out_path} ({out_path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
