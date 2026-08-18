local ObsidianTypes = require("./obsidian/Library.d")
local Library = (require("./obsidian/Library") :: any) :: ObsidianTypes.Library

local Obsidian = {
    Library = Library,
    Types = require("./obsidian/Library.d"),
    SaveManager = require("./obsidian/addons/SaveManager"),
    ThemeManager = require("./obsidian/addons/ThemeManager"),
    Themes = Library.Themes,
}

function Obsidian.create(First, Second)
    return Library:Create(if First == Obsidian then Second else First)
end

Obsidian.mount = Obsidian.create

return setmetatable(Obsidian, {
    __index = Library,
})
