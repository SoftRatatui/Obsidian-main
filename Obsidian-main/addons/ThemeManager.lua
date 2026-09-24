local getgenv = type(getgenv) == "function" and getgenv or function()
    return if typeof(shared) == "table" then shared else _G
end
local cloneref = cloneref or clonereference or function(Value) return Value end
local HttpService = cloneref(game:GetService("HttpService"))
local NativeIsFolder, NativeIsFile, NativeListFiles = isfolder, isfile, listfiles
local FileSystemAvailable = type(NativeIsFolder) == "function" and type(NativeIsFile) == "function" and type(NativeListFiles) == "function"
    and type(makefolder) == "function" and type(readfile) == "function" and type(writefile) == "function" and type(delfile) == "function"

local function IsFolder(Path)
    local Success, Result = pcall(NativeIsFolder, Path)
    return Success and Result == true
end

local function IsFile(Path)
    local Success, Result = pcall(NativeIsFile, Path)
    return Success and Result == true
end

local function ListFiles(Path)
    local Success, Result = pcall(NativeListFiles, Path)
    return Success and typeof(Result) == "table" and Result or {}
end

local DefaultTheme = {
    FontColor = "f0f1f6",
    MutedFontColor = "969baa",
    MainColor = "21242d",
    TopBarColor = "1c1e26",
    SurfaceColor = "16181e",
    RaisedColor = "1c1e26",
    ElementColor = "21242d",
    HoverColor = "2a2e39",
    AccentColor = "9a8cf5",
    AccentSoftColor = "2a2844",
    BackgroundColor = "0e0f13",
    OutlineColor = "323642",
    ShadowColor = "050608",
    WarningColor = "d09d50",
    DestructiveColor = "c43a4c",
    RedColor = "e85367",
    DarkColor = "000000",
    WhiteColor = "f8f9fc",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local DuskTheme = {
    FontColor = "e0def4",
    MutedFontColor = "908caa",
    MainColor = "2a2741",
    TopBarColor = "1c1a29",
    SurfaceColor = "1f1d2e",
    RaisedColor = "1c1a29",
    ElementColor = "2a2741",
    HoverColor = "34304d",
    AccentColor = "ebbcba",
    AccentSoftColor = "3e3543",
    BackgroundColor = "191724",
    OutlineColor = "403d52",
    ShadowColor = "08070e",
    WarningColor = "f6c177",
    DestructiveColor = "eb6f92",
    RedColor = "eb6f92",
    DarkColor = "0c0b12",
    WhiteColor = "faf9ff",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local DawnTheme = {
    FontColor = "4a4358",
    MutedFontColor = "6c6580",
    MainColor = "e6dbd2",
    TopBarColor = "e9dfd6",
    SurfaceColor = "f6efe8",
    RaisedColor = "e9dfd6",
    ElementColor = "e6dbd2",
    HoverColor = "ddd1c7",
    AccentColor = "ba6679",
    AccentSoftColor = "efdcdd",
    BackgroundColor = "efe6de",
    OutlineColor = "d6c9be",
    ShadowColor = "6b5a50",
    WarningColor = "c0822a",
    DestructiveColor = "b4495a",
    RedColor = "b4495a",
    DarkColor = "1c181e",
    WhiteColor = "fffcf9",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local HoneyTheme = {
    FontColor = "463e33",
    MutedFontColor = "6e6556",
    MainColor = "e5dbcb",
    TopBarColor = "e8dfd0",
    SurfaceColor = "f6f0e6",
    RaisedColor = "e8dfd0",
    ElementColor = "e5dbcb",
    HoverColor = "dbd0bd",
    AccentColor = "b0701a",
    AccentSoftColor = "f0e1c6",
    BackgroundColor = "eee6d8",
    OutlineColor = "d6cab6",
    ShadowColor = "6e5a40",
    WarningColor = "bf6a2a",
    DestructiveColor = "b04a4a",
    RedColor = "b04a4a",
    DarkColor = "1c1812",
    WhiteColor = "fffcf6",
    BackgroundImage = "",
    FontFace = "GothamMedium",
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
    FontFace = "GothamMedium",
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
    FontFace = "GothamMedium",
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
    FontFace = "GothamMedium",
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
    FontFace = "GothamMedium",
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
    FontFace = "GothamMedium",
}

local DeuteranopiaTheme = {
    FontColor = "edf1f6",
    MutedFontColor = "a8b2be",
    MainColor = "1e232b",
    TopBarColor = "1a1f26",
    SurfaceColor = "161a20",
    RaisedColor = "1a1f26",
    ElementColor = "1e232b",
    HoverColor = "282f39",
    AccentColor = "4092e0",
    AccentSoftColor = "25303f",
    BackgroundColor = "101318",
    OutlineColor = "404a58",
    ShadowColor = "03040a",
    WarningColor = "d6a353",
    DestructiveColor = "d1495b",
    RedColor = "e85c74",
    DarkColor = "05060a",
    WhiteColor = "f6f9fc",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local ProtanopiaTheme = {
    FontColor = "f4f1ea",
    MutedFontColor = "beb6a8",
    MainColor = "23211c",
    TopBarColor = "1e1c17",
    SurfaceColor = "1a1814",
    RaisedColor = "1e1c17",
    ElementColor = "23211c",
    HoverColor = "302d26",
    AccentColor = "e8b63a",
    AccentSoftColor = "3a3526",
    BackgroundColor = "12110e",
    OutlineColor = "4e493e",
    ShadowColor = "060504",
    WarningColor = "d1a24a",
    DestructiveColor = "c0554a",
    RedColor = "e06a3a",
    DarkColor = "070604",
    WhiteColor = "faf7f0",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local HighContrastTheme = {
    FontColor = "ffffff",
    MutedFontColor = "d6d6d6",
    MainColor = "121212",
    TopBarColor = "0c0c0c",
    SurfaceColor = "0a0a0a",
    RaisedColor = "0c0c0c",
    ElementColor = "121212",
    HoverColor = "202020",
    AccentColor = "ffd60a",
    AccentSoftColor = "2e2a10",
    BackgroundColor = "000000",
    OutlineColor = "787878",
    ShadowColor = "000000",
    WarningColor = "ffb000",
    DestructiveColor = "ff5555",
    RedColor = "ff5555",
    DarkColor = "000000",
    WhiteColor = "ffffff",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local ThemeManager = {
    ReleaseVersion = "0.0.1-release-3",
    Library = nil,
    FileSystemAvailable = FileSystemAvailable,
    Folder = "ObsidianLibSettings",
    AppliedToTab = false,
    DefaultThemeName = "Default",
    DefaultThemeFileName = "default-v8.txt",
    FallbackThemeName = "Default",
    FallbackThemeLabel = "Default",
    CurrentTheme = "Default",
    ApplyingTheme = false,
    SyncingSelector = false,
    ConfigLoadDepth = 0,
    ConfigLoadOptions = {},
    CustomThemes = {},
    ThemeNames = { "Default", "Metal", "Midnight", "Steel", "Sage", "Ash", "Dusk", "Dawn", "Honey", "Deuteranopia", "Protanopia", "High Contrast" },
    BuiltInThemes = {
        Default = { 1, table.clone(DefaultTheme) },
        Metal = { 2, table.clone(MetalTheme) },
        Midnight = { 3, table.clone(MidnightTheme) },
        Steel = { 4, table.clone(SteelTheme) },
        Sage = { 5, table.clone(SageTheme) },
        Ash = { 6, table.clone(AshTheme) },
        Dusk = { 7, table.clone(DuskTheme) },
        Dawn = { 8, table.clone(DawnTheme) },
        Honey = { 9, table.clone(HoneyTheme) },
        Deuteranopia = { 10, table.clone(DeuteranopiaTheme) },
        Protanopia = { 11, table.clone(ProtanopiaTheme) },
        ["High Contrast"] = { 12, table.clone(HighContrastTheme) },
    },
    AccessibilityThemes = {
        { "Deuteranopia", DeuteranopiaTheme },
        { "Protanopia", ProtanopiaTheme },
        { "High Contrast", HighContrastTheme },
    },
}

local function IsValidFolderPath(Value)
    if typeof(Value) ~= "string" then return false end
    local Normalized = Value:match("^%s*(.-)%s*$"):gsub("\\", "/"):gsub("/+", "/"):gsub("^/", ""):gsub("/$", "")
    if Normalized == "" or Normalized:find('[<>:"|%?%*%z]') then return false end
    for Segment in string.gmatch(Normalized, "[^/]+") do
        if Segment == "." or Segment == ".." or Segment == "" then return false end
    end
    return true
end

local function NormalizeFolderPath(Value)
    return Value:match("^%s*(.-)%s*$"):gsub("\\", "/"):gsub("/+", "/"):gsub("^/", ""):gsub("/$", "")
end

local function IsValidThemeName(Value)
    return typeof(Value) == "string" and Value == Value:match("^%s*(.-)%s*$") and Value:match("^[%w _%-]+$") ~= nil and #Value <= 64
end

local function IsBuiltInTheme(Name)
    if typeof(Name) ~= "string" then return false end
    local LowerName = string.lower(Name)
    for BuiltInName in ThemeManager.BuiltInThemes do
        if string.lower(BuiltInName) == LowerName then return true end
    end
    return false
end

local function FindRegisteredTheme(Name)
    if not (ThemeManager.Library and typeof(Name) == "string") then return nil end
    local LowerName = string.lower(Name)
    for ExistingName in ThemeManager.Library.Themes do
        if string.lower(ExistingName) == LowerName then return ExistingName end
    end
    return nil
end

local ThemeColorKeys = {
    "BackgroundColor", "MainColor", "TopBarColor", "SurfaceColor", "RaisedColor", "ElementColor", "HoverColor",
    "AccentColor", "AccentSoftColor", "OutlineColor", "FontColor", "MutedFontColor", "ShadowColor", "WarningColor",
    "DestructiveColor", "RedColor", "DarkColor", "WhiteColor",
}

local SwatchColorKeys = { "BackgroundColor", "SurfaceColor", "AccentColor", "FontColor" }
local ContrastSurfaceKeys = { "BackgroundColor", "SurfaceColor", "MainColor", "ElementColor" }
local BodyContrastTarget = 4.5
local CodePrefix = "MONHUB1:"

local function ContrastRatio(First, Second)
    local Library = ThemeManager.Library
    if not (Library and typeof(First) == "Color3" and typeof(Second) == "Color3") then return 21 end
    local High = math.max(Library:GetLuminance(First), Library:GetLuminance(Second))
    local Low = math.min(Library:GetLuminance(First), Library:GetLuminance(Second))
    return (High + 0.05) / (Low + 0.05)
end

local function WorstBodyContrast(Font)
    local Library = ThemeManager.Library
    if not Library then return 21, nil end
    local Worst, WorstKey = 21, nil
    for _, Key in ContrastSurfaceKeys do
        local Ratio = ContrastRatio(Font, Library.Scheme[Key])
        if Ratio < Worst then
            Worst, WorstKey = Ratio, Key
        end
    end
    return Worst, WorstKey
end

local function ThemePaletteColors(Name)
    local Library = ThemeManager.Library
    if not Library then return {} end
    local Resolved = Library:ResolveThemeName(Name)
    local Source = Library.Themes[Resolved]
    if not Source and IsValidThemeName(Name) and not IsBuiltInTheme(Name) then
        ThemeManager:GetCustomTheme(Name)
        Resolved = Library:ResolveThemeName(Name)
        Source = Library.Themes[Resolved]
    end
    Source = Source or Library.Scheme
    local Colors = {}
    for _, Key in ThemeColorKeys do
        if typeof(Source[Key]) == "Color3" then Colors[Key] = Source[Key] end
    end
    return Colors
end

local function SnapshotPalette()
    local Library = ThemeManager.Library
    local Snapshot = {}
    if not Library then return Snapshot end
    for _, Key in ThemeColorKeys do
        if typeof(Library.Scheme[Key]) == "Color3" then Snapshot[Key] = Library.Scheme[Key] end
    end
    return Snapshot
end

local function EncodeThemeCode()
    local Library = ThemeManager.Library
    if not Library then return nil, "Library is not set" end
    local Parts = {}
    for _, Key in ThemeColorKeys do
        local Color = Library.Scheme[Key]
        if typeof(Color) ~= "Color3" then return nil, "Missing palette color " .. Key end
        table.insert(Parts, Color:ToHex())
    end
    return CodePrefix .. table.concat(Parts)
end

local function DecodeThemeCode(Code)
    if typeof(Code) ~= "string" then return nil, "No theme code was provided" end
    local Trimmed = Code:match("^%s*(.-)%s*$")
    if Trimmed:sub(1, #CodePrefix) ~= CodePrefix then
        return nil, "Unrecognised theme code, expected a " .. CodePrefix .. " string"
    end
    local Body = Trimmed:sub(#CodePrefix + 1):gsub("%s", "")
    local Expected = #ThemeColorKeys * 6
    if #Body ~= Expected then
        return nil, string.format("Theme code is %d characters, expected %d", #Body, Expected)
    end
    if Body:match("[^0-9a-fA-F]") then
        return nil, "Theme code contains non-hex characters"
    end
    local Overrides = {}
    for Index, Key in ThemeColorKeys do
        local Hex = Body:sub((Index - 1) * 6 + 1, Index * 6)
        local Parsed, Color = pcall(Color3.fromHex, Hex)
        if not Parsed then return nil, "Invalid colour for " .. Key end
        Overrides[Key] = Color
    end
    return Overrides
end

local function ThemeFolder()
    return ThemeManager.Folder .. "/themes"
end

local function ThemePath(Name)
    return ThemeFolder() .. "/" .. Name .. ".json"
end

local function DefaultThemePath()
    return ThemeFolder() .. "/" .. ThemeManager.DefaultThemeFileName
end

local function WriteVerified(Path: string, Content: string): (boolean, string?)
    local Base, Extension = Path:match("^(.*)%.([^./]+)$")
    Base, Extension = Base or Path, Extension or "txt"
    local TemporaryPath = Base .. ".pending." .. Extension
    local BackupPath = Base .. ".backup." .. Extension
    local HadPrevious = IsFile(Path)
    local PreviousContent = nil
    if HadPrevious then
        local ReadOld, OldContent = pcall(readfile, Path)
        if ReadOld and typeof(OldContent) == "string" then
            PreviousContent = OldContent
        else
            return false, "Cannot read the existing file; it has not been overwritten"
        end
    end

    local function RestorePrevious()
        if PreviousContent ~= nil then
            local Restored = pcall(writefile, Path, PreviousContent)
            local ReadBack, RestoredContent = pcall(readfile, Path)
            if not Restored or not ReadBack or RestoredContent ~= PreviousContent then
                return "; could not restore the previous file (backup: " .. BackupPath .. ")"
            end
        elseif IsFile(Path) then
            pcall(delfile, Path)
        end
        return ""
    end

    local WroteTemporary, TemporaryError = pcall(writefile, TemporaryPath, Content)
    if not WroteTemporary then
        return false, "Failed to write temporary file " .. TemporaryPath .. ": " .. tostring(TemporaryError)
    end

    local ReadTemporary, TemporaryContent = pcall(readfile, TemporaryPath)
    if not ReadTemporary or TemporaryContent ~= Content then
        pcall(delfile, TemporaryPath)
        return false, "Temporary file verification failed"
    end

    if PreviousContent ~= nil then
        local WroteBackup = pcall(writefile, BackupPath, PreviousContent)
        local ReadBackup, BackupContent = pcall(readfile, BackupPath)
        if not WroteBackup or not ReadBackup or BackupContent ~= PreviousContent then
            pcall(delfile, TemporaryPath)
            return false, "Cannot verify backup; the existing file has not been overwritten"
        end
    end

    local WroteFinal, FinalError = pcall(writefile, Path, Content)
    if not WroteFinal then
        local Recovery = RestorePrevious()
        pcall(delfile, TemporaryPath)
        return false, "Failed to write file: " .. tostring(FinalError) .. Recovery
    end

    local ReadFinal, FinalContent = pcall(readfile, Path)
    if not ReadFinal or FinalContent ~= Content then
        local Recovery = RestorePrevious()
        pcall(delfile, TemporaryPath)
        return false, "File verification failed" .. Recovery
    end

    pcall(delfile, TemporaryPath)
    return true
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

function ThemeManager:RegisterAccessibilityThemes()
    local Library = ThemeManager.Library
    if not (Library and Library.RegisterTheme and Library.Themes) then return false end
    for _, Entry in ThemeManager.AccessibilityThemes do
        local Name, Source = Entry[1], Entry[2]
        if not Library.Themes[Name] then
            local Overrides = {}
            for _, Key in ThemeColorKeys do
                local Parsed, Color = pcall(Color3.fromHex, Source[Key])
                if Parsed then Overrides[Key] = Color end
            end
            pcall(Library.RegisterTheme, Library, Name, Overrides, "Default")
        end
    end
    return true
end

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
    Library.ThemeManager = ThemeManager
    ThemeManager:RegisterAccessibilityThemes()
    local InitialTheme = Library.CurrentTheme or Library.DefaultTheme or ThemeManager.FallbackThemeName
    if ThemeManager.FileSystemAvailable then
        ThemeManager:BuildFolderTree()
        ThemeManager:ReloadCustomThemes()
        if IsFile(DefaultThemePath()) then
            local DefaultName, HasDefault = ThemeManager:GetDefaultTheme()
            if HasDefault then
                ThemeManager.DefaultThemeName = DefaultName
                InitialTheme = DefaultName
            end
        end
    end
    return ThemeManager:ApplyTheme(InitialTheme)
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
    ThemeManager.SyncingAppearance = true
    for Key, Picker in ThemeManager.PalettePickers or {} do
        if Picker.Value ~= ThemeManager.Library.Scheme[Key] then
            Picker:SetValueRGB(ThemeManager.Library.Scheme[Key])
        end
    end
    ThemeManager.SyncingAppearance = false

    if not ThemeManager.Previewing then
        ThemeManager:SetGallerySelection(Resolved)
    end
    ThemeManager:UpdateContrast()

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
    local Paths = {}
    local Current = ""
    for Segment in string.gmatch(ThemeManager.Folder, "[^/]+") do
        Current = Current == "" and Segment or Current .. "/" .. Segment
        table.insert(Paths, Current)
    end
    table.insert(Paths, ThemeFolder())
    return Paths
end

function ThemeManager:BuildFolderTree()
    if not ThemeManager.FileSystemAvailable then return false, "Filesystem API is unavailable" end
    for _, Path in ThemeManager:GetPaths() do
        if not IsFolder(Path) then
            local Success, ErrorMessage = pcall(makefolder, Path)
            if not Success and not IsFolder(Path) then return false, tostring(ErrorMessage) end
        end
    end
    return IsFolder(ThemeFolder()), IsFolder(ThemeFolder()) and nil or "Failed to create theme folder"
end

function ThemeManager:CheckFolderTree()
    if IsFolder(ThemeFolder()) then return true end
    return ThemeManager:BuildFolderTree()
end

function ThemeManager:SetFolder(Folder)
    assert(IsValidFolderPath(Folder), "Invalid path provided")
    ThemeManager.Folder = NormalizeFolderPath(Folder)
    if ThemeManager.FileSystemAvailable then ThemeManager:BuildFolderTree() end
    return ThemeManager
end

function ThemeManager:SetDefaultThemeFileName(FileName)
    assert(typeof(FileName) == "string" and FileName:match("^[%w_%-]+%.txt$"), "Invalid default theme file name")
    ThemeManager.DefaultThemeFileName = FileName
    return ThemeManager
end

function ThemeManager:ReloadCustomThemes()
    if not ThemeManager.Library then return {}, "Library is not set" end
    local Ready, ErrorMessage = ThemeManager:CheckFolderTree()
    if not Ready then return {}, ErrorMessage end

    for Name in ThemeManager.CustomThemes do
        ThemeManager.Library.Themes[Name] = nil
    end
    table.clear(ThemeManager.CustomThemes)

    local Names = {}
    for _, FilePath in ListFiles(ThemeFolder()) do
        local Normalized = tostring(FilePath):gsub("\\", "/")
        local Name = Normalized:match("([^/]+)%.json$")
        if Name and (Name:lower():match("%.pending$") or Name:lower():match("%.backup$")) then continue end
        if not IsValidThemeName(Name) or IsBuiltInTheme(Name) then continue end
        local Theme = ThemeManager:GetCustomTheme(Name)
        if Theme then table.insert(Names, Name) end
    end
    table.sort(Names, function(First, Second) return string.lower(First) < string.lower(Second) end)
    ThemeManager:RefreshThemeList()
    return Names
end

function ThemeManager:GetCustomTheme(ThemeName)
    if not ThemeManager.Library then return nil, "Library is not set" end
    if not IsValidThemeName(ThemeName) or IsBuiltInTheme(ThemeName) then return nil, "Invalid custom theme name" end
    local ExistingName = FindRegisteredTheme(ThemeName)
    if ExistingName and ExistingName ~= ThemeName then return nil, "Theme name conflicts with " .. ExistingName end
    local Path = ThemePath(ThemeName)
    if not IsFile(Path) then return nil, "Theme file does not exist" end
    local Read, Content = pcall(readfile, Path)
    if not Read then return nil, tostring(Content) end
    local Decoded, Data = pcall(HttpService.JSONDecode, HttpService, Content)
    if not Decoded or typeof(Data) ~= "table" or Data.schema ~= 1 or typeof(Data.colors) ~= "table" then
        return nil, "Invalid theme data"
    end

    local Overrides = {}
    for _, Key in ThemeColorKeys do
        local Hex = Data.colors[Key]
        if typeof(Hex) ~= "string" then return nil, "Missing theme color " .. Key end
        local ValidColor, Color = pcall(Color3.fromHex, Hex)
        if not ValidColor then return nil, "Invalid theme color " .. Key end
        Overrides[Key] = Color
    end
    if typeof(Data.backgroundImage) == "string" then Overrides.BackgroundImage = Data.backgroundImage end
    if typeof(Data.cornerRadius) == "number" then Overrides.CornerRadius = math.clamp(Data.cornerRadius, 0, 18) end
    if typeof(Data.isLight) == "boolean" then Overrides.IsLight = Data.isLight end
    if typeof(Data.fontName) == "string" and ThemeManager.Library.GetFontPreset then
        local FontFace = ThemeManager.Library:GetFontPreset(Data.fontName)
        if FontFace then Overrides.Font = FontFace end
    end

    local Registered, RegisterError = pcall(ThemeManager.Library.RegisterTheme, ThemeManager.Library, ThemeName, Overrides, Data.base or "Default")
    if not Registered then return nil, tostring(RegisterError) end
    ThemeManager.CustomThemes[ThemeName] = Overrides
    return Overrides
end

function ThemeManager:SaveCustomTheme(ThemeName)
    if not ThemeManager.Library then return false, "Library is not set" end
    if not IsValidThemeName(ThemeName) or IsBuiltInTheme(ThemeName) then return false, "Invalid custom theme name" end
    local ExistingName = FindRegisteredTheme(ThemeName)
    if ExistingName and ExistingName ~= ThemeName then return false, "Theme name conflicts with " .. ExistingName end
    local Ready, ErrorMessage = ThemeManager:CheckFolderTree()
    if not Ready then return false, ErrorMessage end
    local Colors = {}
    for _, Key in ThemeColorKeys do
        local Color = ThemeManager.Library.Scheme[Key]
        if typeof(Color) ~= "Color3" then return false, "Missing palette color " .. Key end
        Colors[Key] = Color:ToHex()
    end
    local Data = {
        schema = 1,
        name = ThemeName,
        base = IsBuiltInTheme(ThemeManager.CurrentTheme) and ThemeManager.CurrentTheme or ThemeManager.FallbackThemeName,
        colors = Colors,
        backgroundImage = ThemeManager.Library.Scheme.BackgroundImage or "",
        cornerRadius = ThemeManager.Library:GetDesignToken("Radius.Window", ThemeManager.Library.CornerRadius),
        isLight = ThemeManager.Library.IsLightTheme == true,
        fontName = ThemeManager.Library.CurrentFontName,
    }
    local Encoded, Content = pcall(HttpService.JSONEncode, HttpService, Data)
    if not Encoded then return false, tostring(Content) end
    local Saved, SaveError = WriteVerified(ThemePath(ThemeName), Content)
    if not Saved then return false, SaveError end
    local Theme, LoadError = ThemeManager:GetCustomTheme(ThemeName)
    if not Theme then return false, LoadError end
    ThemeManager:RefreshThemeList()
    return true
end

function ThemeManager:Delete(ThemeName)
    if not IsValidThemeName(ThemeName) or IsBuiltInTheme(ThemeName) then return false, "Invalid custom theme name" end
    ThemeName = FindRegisteredTheme(ThemeName) or ThemeName
    local Path = ThemePath(ThemeName)
    if IsFile(Path) then
        local Deleted, ErrorMessage = pcall(delfile, Path)
        if not Deleted then return false, tostring(ErrorMessage) end
    end
    ThemeManager.CustomThemes[ThemeName] = nil
    if ThemeManager.Library then ThemeManager.Library.Themes[ThemeName] = nil end
    if ThemeManager.CurrentTheme == ThemeName then ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName) end
    if ThemeManager.Library then ThemeManager:RefreshThemeList() end
    return true
end

function ThemeManager:GetDefaultTheme()
    if not ThemeManager.FileSystemAvailable or not IsFile(DefaultThemePath()) then return ThemeManager.DefaultThemeName, true end
    local Read, Name = pcall(readfile, DefaultThemePath())
    if Read and typeof(Name) == "string" then Name = Name:match("^%s*(.-)%s*$") end
    if not Read or not IsValidThemeName(Name) then return ThemeManager.FallbackThemeName, false, tostring(Name) end
    Name = FindRegisteredTheme(Name) or Name
    if not (ThemeManager.Library and ThemeManager.Library.Themes[Name]) then
        ThemeManager:GetCustomTheme(Name)
    end
    if not (ThemeManager.Library and ThemeManager.Library.Themes[Name]) then return ThemeManager.FallbackThemeName, false, "Default theme does not exist" end
    ThemeManager.DefaultThemeName = Name
    return Name, true
end

function ThemeManager:SetDefaultTheme(Theme)
    if not ThemeManager.Library then return false, "Library is not set" end
    Theme = FindRegisteredTheme(Theme) or Theme
    if typeof(Theme) == "string" and not ThemeManager.Library.Themes[Theme] and IsValidThemeName(Theme) then
        ThemeManager:GetCustomTheme(Theme)
    end
    if typeof(Theme) ~= "string" or not ThemeManager.Library.Themes[Theme] then return false, "Theme does not exist" end
    ThemeManager.DefaultThemeName = Theme
    return ThemeManager:ApplyTheme(Theme)
end

function ThemeManager:SaveDefault(ThemeName)
    ThemeName = ThemeName or ThemeManager.CurrentTheme
    ThemeName = FindRegisteredTheme(ThemeName) or ThemeName
    if not IsValidThemeName(ThemeName) or not (ThemeManager.Library and ThemeManager.Library.Themes[ThemeName]) then return false, "Theme does not exist" end
    local Ready, ErrorMessage = ThemeManager:CheckFolderTree()
    if not Ready then return false, ErrorMessage end
    local Saved, SaveError = WriteVerified(DefaultThemePath(), ThemeName)
    if not Saved then return false, SaveError end
    ThemeManager.DefaultThemeName = ThemeName
    return true
end

function ThemeManager:LoadDefault()
    local Name, Success, ErrorMessage = ThemeManager:GetDefaultTheme()
    if not Success then return false, ErrorMessage end
    return ThemeManager:ApplyTheme(Name)
end

function ThemeManager:DeleteDefaultTheme()
    ThemeManager.DefaultThemeName = ThemeManager.FallbackThemeName
    if ThemeManager.FileSystemAvailable and IsFile(DefaultThemePath()) then
        local Deleted, ErrorMessage = pcall(delfile, DefaultThemePath())
        if not Deleted then return false, tostring(ErrorMessage) end
    end
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

    ThemeManager.Previewing = false
    ThemeManager.PreviewSnapshot = nil
    ThemeManager.PreviewName = nil

    ThemeName = FindRegisteredTheme(ThemeName) or ThemeName
    if typeof(ThemeName) == "string" and not Library.Themes[ThemeName] and IsValidThemeName(ThemeName) then
        ThemeManager:GetCustomTheme(ThemeName)
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
    ThemeManager:UpdatePreviewControls()
    return true
end

function ThemeManager:PreviewTheme(Name)
    local Library = ThemeManager.Library
    if not Library then return false, "Library is not set" end
    local Colors = ThemePaletteColors(Name)
    if not next(Colors) then return false, "Theme has no palette" end
    if not ThemeManager.Previewing then
        ThemeManager.PreviewSnapshot = SnapshotPalette()
    end
    ThemeManager.Previewing = true
    ThemeManager.PreviewName = Name
    Library:SetPalette(Colors)
    ThemeManager:SetGallerySelection(Name)
    ThemeManager:UpdatePreviewControls()
    return true
end

function ThemeManager:ApplyPreview()
    if not ThemeManager.Previewing then return false, "No theme preview is active" end
    return ThemeManager:ApplyTheme(ThemeManager.PreviewName)
end

function ThemeManager:CancelPreview()
    local Library = ThemeManager.Library
    if not ThemeManager.Previewing then return false, "No theme preview is active" end
    local Snapshot = ThemeManager.PreviewSnapshot
    ThemeManager.Previewing = false
    ThemeManager.PreviewSnapshot = nil
    ThemeManager.PreviewName = nil
    if Snapshot and next(Snapshot) and Library then
        Library:SetPalette(Snapshot)
    end
    ThemeManager:SetGallerySelection(Library and Library.CurrentTheme)
    ThemeManager:UpdatePreviewControls()
    return true
end

function ThemeManager:UpdatePreviewControls()
    local Active = ThemeManager.Previewing == true
    if ThemeManager.PreviewApplyButton then ThemeManager.PreviewApplyButton:SetVisible(Active) end
    if ThemeManager.PreviewCancelButton then ThemeManager.PreviewCancelButton:SetVisible(Active) end
end

function ThemeManager:SetGallerySelection(Name)
    local Library = ThemeManager.Library
    if not (ThemeManager.GalleryCards and Library) then return end
    local Resolved = typeof(Name) == "string" and Library:ResolveThemeName(Name) or nil
    for CardName, Card in ThemeManager.GalleryCards do
        local Selected = Resolved ~= nil and Library:ResolveThemeName(CardName) == Resolved
        Library:AddToRegistry(Card.Stroke, { Color = Selected and "AccentColor" or "OutlineColor" })
        Card.Stroke.Color = Selected and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
        Card.Stroke.Thickness = Selected and 2 or 1
        Card.Stroke.Transparency = Selected and 0 or Library:GetDesignToken("Stroke.SoftTransparency", 0.46)
    end
end

function ThemeManager:RefreshThemeList()
    if not ThemeManager.Library then return table.clone(ThemeManager.ThemeNames) end
    local Names = table.clone(ThemeManager.ThemeNames)
    local Custom = {}
    for Name in ThemeManager.Library.Themes do
        if not table.find(Names, Name) then
            table.insert(Custom, Name)
        end
    end
    table.sort(Custom, function(First, Second) return string.lower(First) < string.lower(Second) end)
    for _, Name in Custom do table.insert(Names, Name) end
    if ThemeManager.ThemeSelector then
        ThemeManager.ThemeSelector:SetValues(Names)
    end
    ThemeManager:RebuildGallery(Names)
    return Names
end

function ThemeManager:CreateGalleryCard(Name, Order)
    local Library = ThemeManager.Library
    local Holder = ThemeManager.GalleryHolder
    if not (Library and Holder) then return end

    local Card, Stroke = Library:CreateSurface(Holder, {
        ClassName = "TextButton",
        Role = "Raised",
        RadiusRole = "Card",
    })
    Card.AutoButtonColor = false
    Card.Text = ""
    Card.LayoutOrder = Order
    Card.ClipsDescendants = true

    local Colors = ThemePaletteColors(Name)
    local CardHeight = Library.IsMobile and 56 or 48
    local PreviewSize = 40
    local ChipSize = 19
    local ChipStep = ChipSize + 2

    local Preview = Instance.new("Frame")
    Preview.BackgroundColor3 = Colors.BackgroundColor or Library.Scheme.BackgroundColor
    Preview.BorderSizePixel = 0
    Preview.Size = UDim2.fromOffset(PreviewSize, PreviewSize)
    Preview.Position = UDim2.fromOffset(6, Library:CenterOffset(CardHeight, PreviewSize))
    Preview.Parent = Card

    for _, Chip in {
        { Colors.BackgroundColor, 0, 0 },
        { Colors.SurfaceColor, ChipStep, 0 },
        { Colors.AccentColor, 0, ChipStep },
        { Colors.FontColor, ChipStep, ChipStep },
    } do
        local Swatch = Instance.new("Frame")
        Swatch.BackgroundColor3 = Chip[1] or Library.Scheme.SurfaceColor
        Swatch.BorderSizePixel = 0
        Swatch.Size = UDim2.fromOffset(ChipSize, ChipSize)
        Swatch.Position = UDim2.fromOffset(Chip[2], Chip[3])
        Swatch.Parent = Preview
    end

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.TextSize = Library:GetDesignToken("Size.Text", 14)
    Label.FontFace = Library.Scheme.Font
    Label.TextColor3 = Library.Scheme.FontColor
    Label.Position = UDim2.fromOffset(6 + PreviewSize + 8, 0)
    Label.Size = UDim2.new(1, -(6 + PreviewSize + 8 + 6), 1, 0)
    Label.Parent = Card
    Library:AddToRegistry(Label, { TextColor3 = "FontColor" })

    Library:GiveSignal(Card.Activated:Connect(function()
        ThemeManager:PreviewTheme(Name)
    end))

    ThemeManager.GalleryCards[Name] = { Card = Card, Stroke = Stroke, Label = Label }
end

function ThemeManager:RebuildGallery(Names)
    local Library = ThemeManager.Library
    local Holder = ThemeManager.GalleryHolder
    if not (Library and Holder and Holder.Parent) then return end
    Names = Names or table.clone(ThemeManager.ThemeNames)
    for _, Card in ThemeManager.GalleryCards do
        Library:ReleaseRegistryTree(Card.Card)
        Card.Card:Destroy()
    end
    table.clear(ThemeManager.GalleryCards)
    for Order, Name in Names do
        ThemeManager:CreateGalleryCard(Name, Order)
    end
    if ThemeManager.GalleryResize then ThemeManager.GalleryResize() end
    ThemeManager:SetGallerySelection(ThemeManager.Previewing and ThemeManager.PreviewName or Library.CurrentTheme)
end

function ThemeManager:BuildGallery(Groupbox)
    local Library = ThemeManager.Library
    if not (Library and Library.CreateSurface) then return end
    ThemeManager.GalleryGroupbox = Groupbox
    ThemeManager.GalleryCards = {}

    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.Size = UDim2.new(1, 0, 0, 0)
    Holder.Parent = Groupbox.Container
    ThemeManager.GalleryHolder = Holder

    local CardHeight = Library.IsMobile and 56 or 48
    local Gap = 6
    local MinCardWidth = 150

    local Layout = Instance.new("UIGridLayout")
    Layout.CellPadding = UDim2.fromOffset(Gap, Gap)
    Layout.CellSize = UDim2.fromOffset(MinCardWidth, CardHeight)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Holder

    local function Resize()
        if not Holder.Parent then return end
        local Width = math.max(1, math.floor(Holder.AbsoluteSize.X / math.max(Library.DPIScale, 1)))
        local Count = 0
        for _ in ThemeManager.GalleryCards do Count += 1 end
        Count = math.max(Count, 1)
        local Columns = math.max(1, math.min(Count, math.floor((Width + Gap) / (MinCardWidth + Gap))))
        local CellWidth = math.max(1, math.floor((Width - (Columns - 1) * Gap) / Columns))
        Layout.CellSize = UDim2.fromOffset(CellWidth, CardHeight)
        local Rows = math.ceil(Count / Columns)
        Holder.Size = UDim2.new(1, 0, 0, Rows * (CardHeight + Gap) - Gap)
        Library:RequestLayout(Groupbox)
    end
    ThemeManager.GalleryResize = Resize
    Library:GiveSignal(Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(Resize))

    ThemeManager:RefreshThemeList()
end

function ThemeManager:CreateThemeManager(Groupbox)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")
    assert(not ThemeManager.AppliedToTab, "ThemeManager is already applied to a tab")
    local Names = ThemeManager:RefreshThemeList()
    local function Notify(Message)
        if ThemeManager.Library.Notify then ThemeManager.Library:Notify(Message) end
    end

    ThemeManager.ThemeSelector = Groupbox:AddDropdown("ThemeManager_ThemeList", {
        Text = "Theme",
        Values = Names,
        Default = ThemeManager.CurrentTheme,
        Callback = function(Value)
            if not ThemeManager.SyncingSelector then
                ThemeManager:ApplyTheme(Value)
            end
        end,
    })

    ThemeManager:BuildGallery(Groupbox)

    ThemeManager.PreviewApplyButton = Groupbox:AddButton({
        Text = "Apply preview",
        Visible = false,
        Func = function()
            local Name = ThemeManager.PreviewName
            local Applied, ErrorMessage = ThemeManager:ApplyPreview()
            Notify(Applied and string.format("Applied theme %q", tostring(Name)) or "Apply failed: " .. tostring(ErrorMessage))
        end,
    })
    ThemeManager.PreviewCancelButton = Groupbox:AddButton({
        Text = "Cancel preview",
        Visible = false,
        Func = function()
            ThemeManager:CancelPreview()
        end,
    })

    if Groupbox.AddInput and Groupbox.AddButton then
        Groupbox:AddInput("ThemeManager_ThemeCode", {
            Text = "Theme code",
            ClearTextOnFocus = false,
            Placeholder = CodePrefix .. "...",
        })
        Groupbox:AddButton("Export theme code", function()
            local Code, ErrorMessage = EncodeThemeCode()
            if not Code then
                Notify("Export failed: " .. tostring(ErrorMessage))
                return
            end
            local Field = ThemeManager.Library.Options.ThemeManager_ThemeCode
            if Field then Field:SetValue(Code) end
            if ThemeManager.Library.Env and ThemeManager.Library.Env.Clipboard then
                local Copied = pcall(setclipboard, Code)
                Notify(Copied and "Theme code copied to clipboard" or "Clipboard write failed, copy it from the field")
            else
                Notify("Clipboard is unavailable, copy the code from the field")
            end
        end)
        Groupbox:AddButton("Import theme code", function()
            local Field = ThemeManager.Library.Options.ThemeManager_ThemeCode
            local Code = Field and tostring(Field.Value) or ""
            if Code:match("^%s*(.-)%s*$") == "" and ThemeManager.Library.Env and ThemeManager.Library.Env.Clipboard then
                local Read, Clipboard = pcall(function()
                    return type(getclipboard) == "function" and getclipboard() or nil
                end)
                if Read and typeof(Clipboard) == "string" then Code = Clipboard end
            end
            local Overrides, ErrorMessage = DecodeThemeCode(Code)
            if not Overrides then
                Notify("Import failed: " .. tostring(ErrorMessage))
                return
            end
            local Applied, ApplyError = pcall(function()
                ThemeManager.Library:SetPalette(Overrides)
            end)
            Notify(Applied and "Imported theme code" or "Import failed: " .. tostring(ApplyError))
        end)
    end

    if ThemeManager.FileSystemAvailable and Groupbox.AddInput and Groupbox.AddButton then
        Groupbox:AddInput("ThemeManager_CustomThemeName", {
            Text = "Custom theme name",
            ClearTextOnFocus = false,
        })
        Groupbox:AddButton("Save current as custom", function()
            local Input = ThemeManager.Library.Options.ThemeManager_CustomThemeName
            local Name = Input and tostring(Input.Value):match("^%s*(.-)%s*$") or ""
            local Saved, ErrorMessage = ThemeManager:SaveCustomTheme(Name)
            Notify(Saved and string.format("Saved custom theme %q", Name) or "Theme save failed: " .. tostring(ErrorMessage))
        end)
        Groupbox:AddButton("Delete selected custom theme", function()
            local Name = ThemeManager.ThemeSelector.Value
            local Deleted, ErrorMessage = ThemeManager:Delete(Name)
            Notify(Deleted and string.format("Deleted custom theme %q", Name) or "Theme delete failed: " .. tostring(ErrorMessage))
        end)
        Groupbox:AddButton("Use selected theme on startup", function()
            local Name = ThemeManager.ThemeSelector.Value
            local Saved, ErrorMessage = ThemeManager:SaveDefault(Name)
            Notify(Saved and string.format("Startup theme set to %q", Name) or "Default theme failed: " .. tostring(ErrorMessage))
        end)
        Groupbox:AddButton("Reload custom themes", function()
            local _, ErrorMessage = ThemeManager:ReloadCustomThemes()
            Notify(ErrorMessage and "Theme reload failed: " .. tostring(ErrorMessage) or "Custom themes reloaded")
        end)
    end

    ThemeManager.AppliedToTab = true
    ThemeManager:SyncFromLibrary(ThemeManager.CurrentTheme)
    return Groupbox
end

function ThemeManager:CreateGroupBox(Tab, IconName)
    return Tab:AddLeftGroupbox("Themes", IconName or "palette")
end

function ThemeManager:CreateAppearanceManager(Groupbox)
    local Library = ThemeManager.Library
    assert(Library and Library.SetPalette, "Appearance controls require the current MonHub library")
    assert(not ThemeManager.PalettePickers, "Appearance controls already exist")
    ThemeManager.PalettePickers = {}
    local Ready = false
    for _, Field in {
        { "AccentColor", "Accent" },
        { "BackgroundColor", "Background" },
        { "TopBarColor", "Header" },
        { "SurfaceColor", "Panels" },
        { "RaisedColor", "Raised panels" },
        { "ElementColor", "Controls" },
        { "HoverColor", "Hover" },
        { "OutlineColor", "Borders" },
        { "FontColor", "Text" },
        { "MutedFontColor", "Secondary text" },
    } do
        local Key = Field[1]
        Groupbox:AddLabel(Field[2]):AddColorPicker("ThemeManager_" .. Key, {
            Default = Library.Scheme[Key],
            Callback = function(Color)
                if Ready and not ThemeManager.SyncingAppearance then
                    Library:SetPalette({ [Key] = Color })
                end
            end,
        })
        ThemeManager.PalettePickers[Key] = Library.Options["ThemeManager_" .. Key]
    end

    ThemeManager.ContrastLabel = Groupbox:AddLabel({ Text = "", DoesWrap = true, Visible = false })
    ThemeManager.ContrastFixButton = Groupbox:AddButton({
        Text = "Fix text contrast",
        Visible = false,
        Func = function()
            local _, WorstKey = WorstBodyContrast(Library.Scheme.FontColor)
            local Surface = Library.Scheme[WorstKey or "BackgroundColor"]
            Library:SetPalette({ FontColor = Library:GetContrastColor(Surface) })
        end,
    })

    for _, Field in { { "Window", "Window corners" }, { "Card", "Panel corners" }, { "Control", "Control corners" }, { "Indicator", "Checkbox corners" } } do
        local Key = Field[1]
        Groupbox:AddSlider("ThemeManager_Radius_" .. Key, {
            Text = Field[2],
            Default = Library:GetDesignToken("Radius." .. Key, 4),
            Min = 0,
            Max = Key == "Indicator" and 6 or 12,
            Rounding = 0,
            Suffix = "px",
            CallbackOnRelease = true,
            Callback = function(Value)
                if Ready then
                    Library:SetDesign({ Radius = { [Key] = Value } })
                end
            end,
        })
    end
    Groupbox:AddSlider("ThemeManager_ScrollbarThickness", {
        Text = "Menu scrollbar width",
        Default = Library:GetDesignToken("Shell.ScrollbarThickness", 2),
        Min = 0,
        Max = 6,
        Rounding = 0,
        Suffix = "px",
        CallbackOnRelease = true,
        Callback = function(Value)
            if Ready then Library:SetDesign({ Shell = { ScrollbarThickness = Value } }) end
        end,
    })
    for _, Field in { { "Shadows", "Window shadows" }, { "Dividers", "Section dividers" }, { "NavigationIndicator", "Navigation accent line" }, { "AccentScrollbars", "Accent scrollbars" } } do
        local Key = Field[1]
        Groupbox:AddToggle("ThemeManager_Effect_" .. Key, {
            Text = Field[2],
            Default = Library:GetDesignToken("Effects." .. Key, false),
            Callback = function(Value)
                if Ready then
                    Library:SetDesign({ Effects = { [Key] = Value } })
                end
            end,
        })
    end
    Groupbox:AddToggle("ThemeManager_ReducedMotion", {
        Text = "Reduced motion",
        Default = Library:GetDesignToken("Motion.Reduced", false),
        Callback = function(Value)
            if Ready then Library:SetReducedMotion(Value) end
        end,
    })
    Groupbox:AddButton("Reset palette to selected theme", function()
        ThemeManager:ApplyTheme(Library.CurrentTheme)
    end)
    Ready = true
    ThemeManager:UpdateContrast()
    return Groupbox
end

function ThemeManager:UpdateContrast()
    local Library = ThemeManager.Library
    if not (Library and ThemeManager.ContrastLabel) then return end
    local Worst, WorstKey = WorstBodyContrast(Library.Scheme.FontColor)
    local Below = Worst < BodyContrastTarget
    if Below then
        ThemeManager.ContrastLabel:SetText(
            string.format("Text contrast is %.1f:1 against %s, below the 4.5:1 minimum for body text.", Worst, WorstKey or "the background")
        )
    end
    ThemeManager.ContrastLabel:SetVisible(Below)
    if ThemeManager.ContrastFixButton then
        ThemeManager.ContrastFixButton:SetVisible(Below)
    end
end

function ThemeManager:ApplyToTab(Tab, IconName)
    return ThemeManager:CreateThemeManager(ThemeManager:CreateGroupBox(Tab, IconName))
end

function ThemeManager:ApplyToGroupbox(Groupbox)
    return ThemeManager:CreateThemeManager(Groupbox)
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
