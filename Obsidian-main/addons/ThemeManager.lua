local getgenv = type(getgenv) == "function" and getgenv or function()
    return if typeof(shared) == "table" then shared else _G
end

local MetalTheme = {
    FontColor = "ebedf1",
    MainColor = "1d1d1d",
    TopBarColor = "131313",
    AccentColor = "82aaff",
    BackgroundColor = "151515",
    OutlineColor = "424242",
    WarningColor = "d09d50",
    DestructiveColor = "c43a4c",
    RedColor = "e85367",
    DarkColor = "0b0b0b",
    WhiteColor = "f5f5f5",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local ThemeManager = {
    Library = nil,
    FileSystemAvailable = false,
    Folder = "ObsidianLibSettings",
    AppliedToTab = false,
    DefaultThemeName = "Metal",
    DefaultThemeFileName = "metal-v6.txt",
    FallbackThemeName = "Metal",
    FallbackThemeLabel = "Metal",
    ApplyingTheme = false,
    ConfigLoadDepth = 0,
    ConfigLoadOptions = {},
    BuiltInThemes = {
        Metal = { 1, table.clone(MetalTheme) },
    },
}

local function IsValidFolderPath(Value)
    return typeof(Value) == "string" and Value:match("%S") ~= nil
end

local function IsMetalName(Value)
    if typeof(Value) ~= "string" then
        return false
    end

    local Name = string.lower(Value)
    return Name == "default" or Name == "metal"
end

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
    Library.ThemeManager = ThemeManager
    return ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
end

function ThemeManager:SyncFromLibrary()
    return true
end

function ThemeManager:BeginConfigLoad()
    ThemeManager.ConfigLoadDepth += 1
    if ThemeManager.ConfigLoadDepth == 1 then
        ThemeManager.ConfigLoadOptions = {}
    end

    return true
end

function ThemeManager:MarkConfigOptionLoaded(OptionId)
    if ThemeManager.ConfigLoadDepth > 0 and typeof(OptionId) == "string" then
        ThemeManager.ConfigLoadOptions[OptionId] = true
    end

    return true
end

function ThemeManager:EndConfigLoad()
    if ThemeManager.ConfigLoadDepth <= 0 then
        return false, "No theme config load is in progress"
    end

    ThemeManager.ConfigLoadDepth -= 1
    if ThemeManager.ConfigLoadDepth > 0 then
        return true
    end

    table.clear(ThemeManager.ConfigLoadOptions)
    return ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
end

function ThemeManager:GetPaths()
    return {}
end

function ThemeManager:BuildFolderTree()
    return false, "Theme persistence is disabled"
end

function ThemeManager:CheckFolderTree()
    return false, "Theme persistence is disabled"
end

function ThemeManager:SetFolder(Folder)
    assert(IsValidFolderPath(Folder), "Invalid path provided")
    ThemeManager.Folder = Folder
end

function ThemeManager:SetDefaultThemeFileName(FileName)
    assert(typeof(FileName) == "string" and FileName:match("^[%w_%-]+%.txt$"), "Invalid default theme file name")
    ThemeManager.DefaultThemeFileName = FileName
end

function ThemeManager:ReloadCustomThemes()
    return {}
end

function ThemeManager:GetCustomTheme(_ThemeName)
    return nil
end

function ThemeManager:SaveCustomTheme(_ThemeName)
    return false, "Custom themes are disabled"
end

function ThemeManager:Delete(_ThemeName)
    return false, "Custom themes are disabled"
end

function ThemeManager:GetDefaultTheme()
    ThemeManager.DefaultThemeName = ThemeManager.FallbackThemeName
    return ThemeManager.FallbackThemeName, true
end

function ThemeManager:SetDefaultTheme(_Theme)
    return ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
end

function ThemeManager:SaveDefault(_ThemeName)
    return false, "Theme persistence is disabled"
end

function ThemeManager:LoadDefault()
    return ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
end

function ThemeManager:DeleteDefaultTheme()
    return false, "Theme persistence is disabled"
end

function ThemeManager:ThemeUpdate()
    return ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
end

function ThemeManager:ApplyTheme(ThemeName)
    local Library = ThemeManager.Library
    if not Library then
        return false, "Library is not set"
    end

    ThemeManager.ApplyingTheme = true
    local Success, ErrorMessage = pcall(function()
        if not IsMetalName(ThemeName) then
            ThemeManager.DefaultThemeName = ThemeManager.FallbackThemeName
        end
        Library:SetTheme("Metal")
    end)
    ThemeManager.ApplyingTheme = false

    if not Success then
        return false, tostring(ErrorMessage)
    end

    ThemeManager.DefaultThemeName = ThemeManager.FallbackThemeName
    return true
end

function ThemeManager:CreateThemeManager(Groupbox)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")
    assert(not ThemeManager.AppliedToTab, "ThemeManager is already applied to a tab")

    local Applied, ErrorMessage = ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
    if not Applied then
        error(ErrorMessage, 0)
    end

    if Groupbox and Groupbox.AddLabel then
        Groupbox:AddLabel("Metal is active.", true)
    end

    ThemeManager.AppliedToTab = true
    return Groupbox
end

function ThemeManager:CreateGroupBox(Tab, IconName)
    return Tab:AddLeftGroupbox("Appearance", IconName or "panel-top")
end

function ThemeManager:ApplyToTab(Tab, IconName)
    return ThemeManager:CreateThemeManager(ThemeManager:CreateGroupBox(Tab, IconName))
end

function ThemeManager:ApplyToGroupbox(Groupbox)
    return ThemeManager:CreateThemeManager(Groupbox)
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
