local ObsidianTypes = require("./Library.d")
local Library = (require("./Library") :: any) :: ObsidianTypes.Library

local Obsidian = {
    Library = Library,
    Types = require("./Library.d"),
    SaveManager = require("./addons/SaveManager"),
    ThemeManager = require("./addons/ThemeManager"),
    CollectionModel = require("./addons/CollectionModel"),
    Themes = Library.Themes,
}

function Obsidian.create(First, Second)
    return Library:Create(if First == Obsidian then Second else First)
end

Obsidian.mount = Obsidian.create

return setmetatable(Obsidian, {
    __index = Library,
})
