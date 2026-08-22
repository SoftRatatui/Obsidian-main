local getgenv = type(getgenv) == "function" and getgenv or function()
    return if typeof(shared) == "table" then shared else _G
end

local DefaultTheme = {
    FontColor = "eef0f4",
    MutedFontColor = "9297a0",
    MainColor = "1f2227",
    TopBarColor = "1d2025",
    SurfaceColor = "17191d",
    RaisedColor = "1d2025",
    ElementColor = "1f2227",
    HoverColor = "262a31",
    AccentColor = "858da0",
    AccentSoftColor = "272b33",
    BackgroundColor = "111316",
    OutlineColor = "343942",
    ShadowColor = "050608",
    WarningColor = "d09d50",
    DestructiveColor = "c43a4c",
    RedColor = "e85367",
    DarkColor = "000000",
    WhiteColor = "f8f9fc",
    BackgroundImage = "",
    FontFace = "Gotham",
}

local MetalTheme = {
    FontColor = "f0f0f4",
    MutedFontColor = "9a95a3",
    MainColor = "211f2b",
    TopBarColor = "1c1a24",
    SurfaceColor = "15141b",
    RaisedColor = "1c1a24",
    ElementColor = "211f2b",
    HoverColor = "2b2837",
    AccentColor = "8c88c9",
    AccentSoftColor = "2d293a",
    BackgroundColor = "0e0e12",
    OutlineColor = "383443",
    ShadowColor = "050508",
    WarningColor = "d6a353",
    DestructiveColor = "cc4156",
    RedColor = "eb5b73",
    DarkColor = "09090b",
    WhiteColor = "f8f8fa",
    BackgroundImage = "",
    FontFace = "Gotham",
}

local MidnightTheme = {
    FontColor = "e9eef5",
    MutedFontColor = "8692a2",
    MainColor = "19202a",
    TopBarColor = "151b24",
    SurfaceColor = "0f141b",
    RaisedColor = "151b24",
    ElementColor = "19202a",
    HoverColor = "212a37",
    AccentColor = "74849a",
    AccentSoftColor = "1f2732",
    BackgroundColor = "0a0d12",
    OutlineColor = "2c3745",
    ShadowColor = "030406",
    WarningColor = "cb9a4d",
    DestructiveColor = "bf3f51",
    RedColor = "e25266",
    DarkColor = "050608",
    WhiteColor = "f8f9fc",
    BackgroundImage = "",
    FontFace = "Gotham",
}

local SteelTheme = {
    FontColor = "eaf0f4",
    MutedFontColor = "8f9ca6",
    MainColor = "1e262e",
    TopBarColor = "1a2128",
    SurfaceColor = "151b20",
    RaisedColor = "1a2128",
    ElementColor = "1e262e",
    HoverColor = "27333d",
    AccentColor = "7894ae",
    AccentSoftColor = "26323c",
    BackgroundColor = "101418",
    OutlineColor = "34424e",
    ShadowColor = "05080a",
    WarningColor = "cb9d57",
    DestructiveColor = "c04352",
    RedColor = "e15669",
    DarkColor = "06090c",
    WhiteColor = "f6f9fb",
    BackgroundImage = "",
    FontFace = "Gotham",
}

local SageTheme = {
    FontColor = "edf2ef",
    MutedFontColor = "929f98",
    MainColor = "202a24",
    TopBarColor = "1b231e",
    SurfaceColor = "171d19",
    RaisedColor = "1b231e",
    ElementColor = "202a24",
    HoverColor = "29362e",
    AccentColor = "86a394",
    AccentSoftColor = "29372f",
    BackgroundColor = "111512",
    OutlineColor = "38483f",
    ShadowColor = "050806",
    WarningColor = "cd9e56",
    DestructiveColor = "c04550",
    RedColor = "e15868",
    DarkColor = "070a08",
    WhiteColor = "f7faf8",
    BackgroundImage = "",
    FontFace = "Gotham",
}

local AshTheme = {
    FontColor = "f1efeb",
    MutedFontColor = "97928b",
    MainColor = "25211c",
    TopBarColor = "1f1c18",
    SurfaceColor = "191613",
    RaisedColor = "1f1c18",
    ElementColor = "25211c",
    HoverColor = "302b24",
    AccentColor = "a59785",
    AccentSoftColor = "2e2922",
    BackgroundColor = "12100e",
    OutlineColor = "3e372e",
    ShadowColor = "070605",
    WarningColor = "cd9e56",
    DestructiveColor = "c2434f",
    RedColor = "e35767",
    DarkColor = "090807",
    WhiteColor = "f9f7f3",
    BackgroundImage = "",
    FontFace = "Gotham",
}

local ThemeManager = {
    ReleaseVersion = "0.0.1-final-theme-3",
    Library = nil,
    FileSystemAvailable = false,
    Folder = "ObsidianLibSettings",
    AppliedToTab = false,
    DefaultThemeName = "Default",
    DefaultThemeFileName = "default-v7.txt",
    FallbackThemeName = "Default",
    FallbackThemeLabel = "Default",
    CurrentTheme = "Default",
    ApplyingTheme = false,
    SyncingSelector = false,
    ConfigLoadDepth = 0,
    ConfigLoadOptions = {},
    ThemeNames = { "Default", "Metal", "Midnight", "Steel", "Sage", "Ash" },
    BuiltInThemes = {
        Default = { 1, table.clone(DefaultTheme) },
        Metal = { 2, table.clone(MetalTheme) },
        Midnight = { 3, table.clone(MidnightTheme) },
        Steel = { 4, table.clone(SteelTheme) },
        Sage = { 5, table.clone(SageTheme) },
        Ash = { 6, table.clone(AshTheme) },
    },
}

local function IsValidFolderPath(Value)
    return typeof(Value) == "string" and Value:match("%S") ~= nil
end

local function ResolveThemeName(Value)
    if ThemeManager.Library and ThemeManager.Library.ResolveThemeName then
        return ThemeManager.Library:ResolveThemeName(Value)
    end

    if typeof(Value) ~= "string" then
        return ThemeManager.FallbackThemeName
    end

    local Name = string.lower(Value):gsub("[%s_%-]", "")
    if Name == "metal" or Name == "purple" or Name == "blackpurple" or Name == "amethyst" then
        return "Metal"
    end

    if Name == "midnight" or Name == "night" or Name == "dark" then
        return "Midnight"
    end

    if Name == "steel" or Name == "slate" or Name == "bluegray" or Name == "bluegrey" then
        return "Steel"
    end

    if Name == "sage" or Name == "forest" or Name == "green" then
        return "Sage"
    end

    if Name == "ash" or Name == "warmgray" or Name == "warmgrey" or Name == "taupe" then
        return "Ash"
    end

    return "Default"
end

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
    Library.ThemeManager = ThemeManager
    return ThemeManager:ApplyTheme(Library.CurrentTheme or Library.DefaultTheme or ThemeManager.FallbackThemeName)
end

function ThemeManager:SyncFromLibrary(ThemeName)
    local Resolved = ResolveThemeName(ThemeName or (ThemeManager.Library and ThemeManager.Library.CurrentTheme))
    ThemeManager.CurrentTheme = Resolved

    local Selector = ThemeManager.ThemeSelector
    if Selector and Selector.Value ~= Resolved and not ThemeManager.ApplyingTheme then
        ThemeManager.SyncingSelector = true
        pcall(function()
            Selector:SetValue(Resolved)
        end)
        ThemeManager.SyncingSelector = false
    end

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

    local ThemeSelectionLoaded = ThemeManager.ConfigLoadOptions.ThemeManager_ThemeList == true
    table.clear(ThemeManager.ConfigLoadOptions)
    if ThemeSelectionLoaded then
        return true
    end

    return ThemeManager:ApplyTheme(ThemeManager.DefaultThemeName)
end

function ThemeManager:GetPaths()
    return {}
end

function ThemeManager:BuildFolderTree()
    return false, "Custom theme persistence is disabled"
end

function ThemeManager:CheckFolderTree()
    return false, "Custom theme persistence is disabled"
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
    return ThemeManager.DefaultThemeName, true
end

function ThemeManager:SetDefaultTheme(Theme)
    ThemeManager.DefaultThemeName = ResolveThemeName(Theme)
    return ThemeManager:ApplyTheme(ThemeManager.DefaultThemeName)
end

function ThemeManager:SaveDefault(_ThemeName)
    return false, "Theme file persistence is disabled"
end

function ThemeManager:LoadDefault()
    return ThemeManager:ApplyTheme(ThemeManager.DefaultThemeName)
end

function ThemeManager:DeleteDefaultTheme()
    ThemeManager.DefaultThemeName = ThemeManager.FallbackThemeName
    return true
end

function ThemeManager:ThemeUpdate()
    return ThemeManager:ApplyTheme(ThemeManager.CurrentTheme)
end

function ThemeManager:ApplyTheme(ThemeName)
    local Library = ThemeManager.Library
    if not Library then
        return false, "Library is not set"
    end

    local Resolved = ResolveThemeName(ThemeName)
    ThemeManager.ApplyingTheme = true
    local Success, ErrorMessage = pcall(function()
        Library:SetTheme(Resolved)
    end)
    ThemeManager.ApplyingTheme = false

    if not Success then
        return false, tostring(ErrorMessage)
    end

    ThemeManager.CurrentTheme = Resolved
    ThemeManager:SyncFromLibrary(Resolved)
    return true
end

function ThemeManager:CreateThemeManager(Groupbox)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")
    assert(not ThemeManager.AppliedToTab, "ThemeManager is already applied to a tab")

    ThemeManager.ThemeSelector = Groupbox:AddDropdown("ThemeManager_ThemeList", {
        Text = "Theme",
        Values = table.clone(ThemeManager.ThemeNames),
        Default = ThemeManager.CurrentTheme,
        Callback = function(Value)
            if not ThemeManager.SyncingSelector then
                ThemeManager:ApplyTheme(Value)
            end
        end,
    })

    ThemeManager.AppliedToTab = true
    ThemeManager:SyncFromLibrary(ThemeManager.CurrentTheme)
    return Groupbox
end

function ThemeManager:CreateGroupBox(Tab, IconName)
    return Tab:AddLeftGroupbox("Themes", IconName or "palette")
end

function ThemeManager:ApplyToTab(Tab, IconName)
    return ThemeManager:CreateThemeManager(ThemeManager:CreateGroupBox(Tab, IconName))
end

function ThemeManager:ApplyToGroupbox(Groupbox)
    return ThemeManager:CreateThemeManager(Groupbox)
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
