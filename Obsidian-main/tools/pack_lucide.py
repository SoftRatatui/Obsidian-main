"""Rewrites src/vendor/Lucide.luau from its table form into one packed string.

    python tools/pack_lucide.py [source.luau]

The source is the table that mstudio45/lucide-roblox-direct ships (the old form of
Lucide.luau). A table of some five thousand constructors costs a hub its compile time on
every start; a string costs almost nothing to compile, and an icon is found in it only
when a script asks for one.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGET = ROOT / "src" / "vendor" / "Lucide.luau"
PITCH = 25
CELL = 24


class Reader:
    """Just enough of a Lua table constructor reader for the Lucide data."""

    def __init__(self, text):
        self.text = text
        self.at = 0

    def skip(self):
        while self.at < len(self.text) and self.text[self.at] in " \t\r\n":
            self.at += 1

    def value(self):
        self.skip()
        char = self.text[self.at]
        if char == "{":
            return self.table()
        if char == '"':
            end = self.text.index('"', self.at + 1)
            item = self.text[self.at + 1:end]
            self.at = end + 1
            return item
        match = re.compile(r"-?\d+").match(self.text, self.at)
        if not match:
            raise SystemExit(f"unexpected {self.text[self.at:self.at + 20]!r}")
        self.at = match.end()
        return int(match.group())

    def table(self):
        self.at += 1
        items, keyed = [], {}
        while True:
            self.skip()
            if self.text[self.at] == "}":
                self.at += 1
                return keyed if keyed else items
            if self.text[self.at] == "[":
                end = self.text.index("]", self.at)
                key = int(self.text[self.at + 1:end])
                self.at = self.text.index("=", end) + 1
                keyed[key] = self.value()
            else:
                items.append(self.value())
            self.skip()
            if self.text[self.at] == ",":
                self.at += 1


def main():
    source = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else TARGET
    text = source.read_text(encoding="utf-8")
    if "local Data = " in text:
        sys.exit(f"{source} is packed already; give the table form as the source")
    start = text.index("local icons = ") + len("local icons = ")
    reader = Reader(text)
    reader.at = start
    names, sheets, registry = reader.value()
    cells = registry[48]
    if len(cells) != len(names):
        sys.exit(f"{len(names)} names but {len(cells)} cells")
    parts = []
    for name, (sheet, size, offset) in zip(names, cells):
        if not re.fullmatch(r"[a-z0-9-]+", name):
            sys.exit(f"name {name!r} would need escaping")
        if size != [CELL, CELL] or offset[0] % PITCH or offset[1] % PITCH:
            sys.exit(f"{name}: cell {size} at {offset} is off the {PITCH} px grid")
        parts.append(f"{name}|{sheet}|{offset[0] // PITCH}|{offset[1] // PITCH}")
    data = ";" + ";".join(parts) + ";"
    sheet_list = ", ".join(f'"{sheet}"' for sheet in sheets)
    out = f'''-- Lucide icons (ISC license) as Roblox spritesheets from mstudio45/lucide-roblox-direct.
-- Every glyph is a 24x24 cell on a 25 px pitch inside a 1024x1024 sheet.
--
-- Packed by tools/pack_lucide.py into one string of ";name|sheet|column|row" entries. The
-- library compiles this file on every start, and a string costs almost nothing to
-- compile where a table of thousands of entries did; an icon is looked up only when asked.
local Lucide = {{}}

local Sheets = {{ {sheet_list} }}
local Pitch, Cell = {PITCH}, {CELL}
local Data = "{data}"

function Lucide.GetAsset(Name: string)
    if type(Name) ~= "string" or not string.match(Name, "^[%w%-]+$") then
        return nil
    end
    local _, Stop = string.find(Data, ";" .. Name .. "|", 1, true)
    if not Stop then
        return nil
    end
    local Sheet, Column, Row = string.match(Data, "^(%d+)|(%d+)|(%d+);", Stop + 1)
    local Url = Sheets[tonumber(Sheet) or 0]
    if not Url then
        return nil
    end
    return {{
        IconName = Name,
        Url = Url,
        ImageRectSize = Vector2.new(Cell, Cell),
        ImageRectOffset = Vector2.new((tonumber(Column) :: number) * Pitch, (tonumber(Row) :: number) * Pitch),
    }}
end

-- Every icon name, in the order of the source.
function Lucide.Names(): {{ string }}
    local Names = {{}}
    for Name in string.gmatch(Data, ";([^|;]+)|") do
        table.insert(Names, Name)
    end
    return Names
end

return Lucide
'''
    TARGET.write_bytes(out.encode("utf-8"))
    print(f"{len(names)} icons, {len(sheets)} sheets, {len(out.encode()) // 1024} KB -> {TARGET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
