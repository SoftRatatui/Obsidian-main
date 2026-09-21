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

local GraphiteTheme = {
    FontColor = "e6e6e6",
    MutedFontColor = "a3a3a3",
    MainColor = "262626",
    TopBarColor = "212121",
    SurfaceColor = "1c1c1c",
    RaisedColor = "212121",
    ElementColor = "262626",
    HoverColor = "2f2f2f",
    AccentColor = "aeb4bc",
    AccentSoftColor = "3e4041",
    BackgroundColor = "121212",
    OutlineColor = "3d3d3d",
    ShadowColor = "030303",
    WarningColor = "d4a259",
    DestructiveColor = "c4505c",
    RedColor = "e26b78",
    DarkColor = "000000",
    WhiteColor = "f5f5f5",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local SlateTheme = {
    FontColor = "e4e8ec",
    MutedFontColor = "9aa3ad",
    MainColor = "292d32",
    TopBarColor = "23262a",
    SurfaceColor = "1d2023",
    RaisedColor = "23262a",
    ElementColor = "292d32",
    HoverColor = "343940",
    AccentColor = "9fb0c2",
    AccentSoftColor = "353c45",
    BackgroundColor = "15171a",
    OutlineColor = "434a52",
    ShadowColor = "030405",
    WarningColor = "d4a259",
    DestructiveColor = "c4505c",
    RedColor = "e26b78",
    DarkColor = "040506",
    WhiteColor = "f4f7fa",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local PewterTheme = {
    FontColor = "ececed",
    MutedFontColor = "aaaab0",
    MainColor = "37373b",
    TopBarColor = "313134",
    SurfaceColor = "2b2b2e",
    RaisedColor = "313134",
    ElementColor = "37373b",
    HoverColor = "424248",
    AccentColor = "c3c6cc",
    AccentSoftColor = "4b4c52",
    BackgroundColor = "232325",
    OutlineColor = "53535a",
    ShadowColor = "0a0a0c",
    WarningColor = "d4a259",
    DestructiveColor = "c8535f",
    RedColor = "e4707d",
    DarkColor = "0d0d0f",
    WhiteColor = "f7f7f8",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local GlassRegularTheme = {
    FontColor = "eef0f3",
    MutedFontColor = "9ba3ad",
    MainColor = "212429",
    TopBarColor = "1c1e22",
    SurfaceColor = "17181b",
    RaisedColor = "1c1e22",
    ElementColor = "212429",
    HoverColor = "2b2f35",
    AccentColor = "8fa8c4",
    AccentSoftColor = "2c333d",
    BackgroundColor = "0e0f11",
    OutlineColor = "464c55",
    ShadowColor = "020304",
    WarningColor = "d4a259",
    DestructiveColor = "c4505c",
    RedColor = "e26b78",
    DarkColor = "040506",
    WhiteColor = "f7f9fb",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local GlassThinTheme = {
    FontColor = "f1f3f6",
    MutedFontColor = "a2aab4",
    MainColor = "1d2025",
    TopBarColor = "17191d",
    SurfaceColor = "131417",
    RaisedColor = "17191d",
    ElementColor = "1d2025",
    HoverColor = "272b31",
    AccentColor = "9ab2cd",
    AccentSoftColor = "28303a",
    BackgroundColor = "0b0c0e",
    OutlineColor = "4d545e",
    ShadowColor = "010203",
    WarningColor = "d4a259",
    DestructiveColor = "c4505c",
    RedColor = "e26b78",
    DarkColor = "020304",
    WhiteColor = "f9fbfd",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local GlassThickTheme = {
    FontColor = "eaedf1",
    MutedFontColor = "959ca6",
    MainColor = "25282d",
    TopBarColor = "202226",
    SurfaceColor = "1b1c20",
    RaisedColor = "202226",
    ElementColor = "25282d",
    HoverColor = "2f333a",
    AccentColor = "849cb7",
    AccentSoftColor = "30363f",
    BackgroundColor = "121316",
    OutlineColor = "414750",
    ShadowColor = "030405",
    WarningColor = "d4a259",
    DestructiveColor = "c4505c",
    RedColor = "e26b78",
    DarkColor = "060709",
    WhiteColor = "f6f8fa",
    BackgroundImage = "",
    FontFace = "GothamMedium",
}

local GlassSurfaces = { TopBar = true, Sidebar = true, Popup = true, Content = false }

local MaterialTiers = {
    Opaque = { Transparency = 0, Scrim = 0, BorderTransparency = 0.46 },
    UltraThin = { Transparency = 0.3, Scrim = 0.28, BorderTransparency = 0.66 },
    Thin = { Transparency = 0.22, Scrim = 0.25, BorderTransparency = 0.62 },
    Regular = { Transparency = 0.12, Scrim = 0.18, BorderTransparency = 0.58 },
    Thick = { Transparency = 0.06, Scrim = 0.12, BorderTransparency = 0.52 },
    UltraThick = { Transparency = 0.03, Scrim = 0.08, BorderTransparency = 0.48 },
}

local TierOrder = { "Opaque", "UltraThick", "Thick", "Regular", "Thin", "UltraThin" }
local TierLabels = {
    Opaque = "Solid",
    UltraThick = "Ultra thick",
    Thick = "Thick",
    Regular = "Regular",
    Thin = "Thin",
    UltraThin = "Ultra thin",
}

local function Material(Tier, Highlight, Shadow)
    local Preset = MaterialTiers[Tier] or MaterialTiers.Opaque
    return {
        Tier = Tier,
        Transparency = Preset.Transparency,
        Scrim = Preset.Scrim,
        BorderTransparency = Preset.BorderTransparency,
        Highlight = Highlight,
        Shadow = Shadow,
    }
end

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
    Material = nil,
    ReduceTransparency = false,
    WatermarkFollowsMaterial = true,
    ThemeNames = {
        "Default", "Metal", "Midnight", "Steel", "Sage", "Ash",
        "Graphite", "Slate", "Pewter",
        "Glass Regular", "Glass Thin", "Glass Thick",
        "Deuteranopia", "Protanopia", "High Contrast",
    },
    BuiltInThemes = {
        Default = { 1, table.clone(DefaultTheme) },
        Metal = { 2, table.clone(MetalTheme) },
        Midnight = { 3, table.clone(MidnightTheme) },
        Steel = { 4, table.clone(SteelTheme) },
        Sage = { 5, table.clone(SageTheme) },
        Ash = { 6, table.clone(AshTheme) },
        Graphite = { 7, table.clone(GraphiteTheme) },
        Slate = { 8, table.clone(SlateTheme) },
        Pewter = { 9, table.clone(PewterTheme) },
        ["Glass Regular"] = { 10, table.clone(GlassRegularTheme) },
        ["Glass Thin"] = { 11, table.clone(GlassThinTheme) },
        ["Glass Thick"] = { 12, table.clone(GlassThickTheme) },
        Deuteranopia = { 13, table.clone(DeuteranopiaTheme) },
        Protanopia = { 14, table.clone(ProtanopiaTheme) },
        ["High Contrast"] = { 15, table.clone(HighContrastTheme) },
    },
    AccessibilityThemes = {
        { "Deuteranopia", DeuteranopiaTheme },
        { "Protanopia", ProtanopiaTheme },
        { "High Contrast", HighContrastTheme },
    },
    ThemeGroupOrder = { "Dark", "Grey", "Glass", "Accessibility", "Custom" },
    ThemeGroups = {
        Default = "Dark",
        Metal = "Dark",
        Midnight = "Dark",
        Steel = "Dark",
        Sage = "Dark",
        Ash = "Dark",
        Graphite = "Grey",
        Slate = "Grey",
        Pewter = "Grey",
        ["Glass Regular"] = "Glass",
        ["Glass Thin"] = "Glass",
        ["Glass Thick"] = "Glass",
        Deuteranopia = "Accessibility",
        Protanopia = "Accessibility",
        ["High Contrast"] = "Accessibility",
    },
    ThemeMaterials = {
        Default = Material("Opaque", 1, 1),
        Metal = Material("Opaque", 1, 1),
        Midnight = Material("Opaque", 1.1, 1.15),
        Steel = Material("Opaque", 1, 1),
        Sage = Material("Opaque", 1, 1),
        Ash = Material("Opaque", 0.95, 1),
        Graphite = Material("Opaque", 1, 1),
        Slate = Material("Opaque", 1, 1),
        Pewter = Material("Opaque", 0.8, 0.85),
        ["Glass Regular"] = Material("Regular", 1.15, 1.2),
        ["Glass Thin"] = Material("Thin", 1.25, 1.3),
        ["Glass Thick"] = Material("Thick", 1.05, 1.1),
        Deuteranopia = Material("Opaque", 1, 1),
        Protanopia = Material("Opaque", 1, 1),
        ["High Contrast"] = Material("Opaque", 0, 0),
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

local ContrastSurfaces = {
    { Key = "BackgroundColor", Label = "the window backdrop", Glass = true },
    { Key = "TopBarColor", Label = "the title bar", Glass = true },
    { Key = "SurfaceColor", Label = "panels", Glass = true },
    { Key = "MainColor", Label = "content", Glass = false },
    { Key = "ElementColor", Label = "controls", Glass = false },
}
local BodyContrastTarget = 4.5
local CodePrefix = "MONHUB1:"
local BrightBackdrop = Color3.new(1, 1, 1)
local BlackScrim = Color3.new(0, 0, 0)

local DefaultMaterial = {
    Tier = "Opaque",
    Transparency = 0,
    Scrim = 0,
    BorderTransparency = 0.46,
    Highlight = 1,
    Shadow = 1,
    ReduceTransparency = false,
}

local function ClampUnit(Value, Fallback)
    local Number = tonumber(Value)
    if not Number or Number ~= Number then return Fallback end
    return math.clamp(Number, 0, 1)
end

local function ClampStrength(Value, Fallback)
    local Number = tonumber(Value)
    if not Number or Number ~= Number then return Fallback end
    return math.clamp(Number, 0, 2)
end

local function NormalizeMaterial(Source)
    local Tier = typeof(Source) == "table" and MaterialTiers[Source.Tier] and Source.Tier or "Opaque"
    local Preset = MaterialTiers[Tier]
    Source = typeof(Source) == "table" and Source or {}
    return {
        Tier = Tier,
        Transparency = ClampUnit(Source.Transparency, Preset.Transparency),
        Scrim = ClampUnit(Source.Scrim, Preset.Scrim),
        BorderTransparency = ClampUnit(Source.BorderTransparency, Preset.BorderTransparency),
        Highlight = ClampStrength(Source.Highlight, 1),
        Shadow = ClampStrength(Source.Shadow, 1),
        ReduceTransparency = Source.ReduceTransparency == true,
    }
end

local function ThemeMaterial(Name)
    local Stored = ThemeManager.ThemeMaterials[Name]
    if not Stored and typeof(Name) == "string" and string.find(string.lower(Name), "glass", 1, true) then
        Stored = MaterialTiers.Regular
    end
    local Resolved = NormalizeMaterial(Stored)
    Resolved.ReduceTransparency = ThemeManager.ReduceTransparency == true
    return Resolved
end

local function EffectiveTransparency(Material)
    if Material.ReduceTransparency then return 0 end
    return ClampUnit(Material.Transparency, 0)
end

local function EffectiveSurface(Surface, Material)
    local Transparency = EffectiveTransparency(Material)
    if Transparency <= 0 or typeof(Surface) ~= "Color3" then return Surface end
    local Backdrop = BrightBackdrop:Lerp(BlackScrim, ClampUnit(Material.Scrim, 0))
    return Surface:Lerp(Backdrop, Transparency)
end

local function ReadMaterial()
    local Library = ThemeManager.Library
    if not (Library and type(Library.GetDesignToken) == "function") then
        return table.clone(DefaultMaterial)
    end
    return NormalizeMaterial({
        Tier = Library:GetDesignToken("Glass.Tier", "Opaque"),
        Transparency = Library:GetDesignToken("Glass.NominalTransparency", 0),
        Scrim = Library:GetDesignToken("Glass.Scrim", 0),
        BorderTransparency = Library:GetDesignToken("Glass.BorderTransparency", 0.46),
        Highlight = Library:GetDesignToken("Elevation.Highlight", 1),
        Shadow = Library:GetDesignToken("Elevation.Shadow", 1),
        ReduceTransparency = Library:GetDesignToken("Glass.ReduceTransparency", false),
    })
end

local function WriteMaterial(Source)
    local Library = ThemeManager.Library
    if not (Library and type(Library.SetDesign) == "function") then return false end
    local Resolved = NormalizeMaterial(Source)
    local Transparency = EffectiveTransparency(Resolved)
    local Enabled = Transparency > 0
    ThemeManager.ReduceTransparency = Resolved.ReduceTransparency
    ThemeManager.Material = Resolved
    Library:SetDesign({
        Elevation = {
            Highlight = Resolved.Highlight,
            Shadow = Resolved.Shadow,
        },
        Glass = {
            Enabled = Enabled,
            Tier = Resolved.Tier,
            Transparency = Transparency,
            NominalTransparency = Resolved.Transparency,
            Scrim = Enabled and Resolved.Scrim or 0,
            BorderTransparency = Resolved.BorderTransparency,
            ReduceTransparency = Resolved.ReduceTransparency,
            AllowNested = false,
            Surfaces = table.clone(GlassSurfaces),
        },
    })
    return true
end

local function SnapshotWatermark()
    local Library = ThemeManager.Library
    local Style = Library and Library.WatermarkStyle
    if typeof(Style) ~= "table" then return nil end
    return {
        BackgroundTransparency = tonumber(Style.BackgroundTransparency) or 0,
        OutlineTransparency = tonumber(Style.OutlineTransparency) or 0.18,
    }
end

local function ApplyWatermark(Style)
    local Library = ThemeManager.Library
    if not (Library and typeof(Style) == "table" and type(Library.SetWatermarkOptions) == "function") then return false end
    local Applied = pcall(Library.SetWatermarkOptions, Library, {
        BackgroundTransparency = ClampUnit(Style.BackgroundTransparency, 0),
        OutlineTransparency = ClampUnit(Style.OutlineTransparency, 0.18),
    })
    return Applied
end

local function WatermarkForMaterial(Material)
    local Transparency = EffectiveTransparency(Material)
    if Transparency <= 0 then return nil end
    return {
        BackgroundTransparency = Transparency,
        OutlineTransparency = Material.BorderTransparency,
    }
end

local function ContrastRatio(First, Second)
    local Library = ThemeManager.Library
    if not (Library and typeof(First) == "Color3" and typeof(Second) == "Color3") then return 21 end
    local High = math.max(Library:GetLuminance(First), Library:GetLuminance(Second))
    local Low = math.min(Library:GetLuminance(First), Library:GetLuminance(Second))
    return (High + 0.05) / (Low + 0.05)
end

local function WorstBodyContrast(Font)
    local Library = ThemeManager.Library
    if not Library then return 21, nil, false end
    local Material = ThemeManager.Material or ReadMaterial()
    local Worst, WorstKey, WorstLabel, Translucent = 21, nil, nil, false
    for _, Entry in ContrastSurfaces do
        local Surface = Library.Scheme[Entry.Key]
        if typeof(Surface) == "Color3" then
            local Sampled = Entry.Glass and EffectiveSurface(Surface, Material) or Surface
            local Ratio = ContrastRatio(Font, Sampled)
            if Ratio < Worst then
                Worst, WorstKey, WorstLabel = Ratio, Entry.Key, Entry.Label
                Translucent = Entry.Glass and EffectiveTransparency(Material) > 0
            end
        end
    end
    return Worst, WorstKey, Translucent, WorstLabel
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

local function SnapshotAppearance()
    local Library = ThemeManager.Library
    local Colors = {}
    if not Library then return { Colors = Colors } end
    for _, Key in ThemeColorKeys do
        if typeof(Library.Scheme[Key]) == "Color3" then Colors[Key] = Library.Scheme[Key] end
    end
    return {
        Colors = Colors,
        Material = ThemeManager.Material and table.clone(ThemeManager.Material) or ReadMaterial(),
        Watermark = SnapshotWatermark(),
    }
end

local function RestoreAppearance(Snapshot)
    local Library = ThemeManager.Library
    if not (Library and typeof(Snapshot) == "table") then return false end
    if typeof(Snapshot.Material) == "table" then
        WriteMaterial(Snapshot.Material)
    end
    if Snapshot.Watermark then
        ApplyWatermark(Snapshot.Watermark)
    end
    if typeof(Snapshot.Colors) == "table" and next(Snapshot.Colors) and type(Library.SetPalette) == "function" then
        Library:SetPalette(Snapshot.Colors)
    end
    return true
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

local function RegisterPalette(Name, Source)
    local Library = ThemeManager.Library
    if Library.Themes[Name] then return false end
    local Overrides = {}
    for _, Key in ThemeColorKeys do
        local Parsed, Color = pcall(Color3.fromHex, Source[Key])
        if Parsed then Overrides[Key] = Color end
    end
    return (pcall(Library.RegisterTheme, Library, Name, Overrides, "Default"))
end

function ThemeManager:RegisterBuiltInThemes()
    local Library = ThemeManager.Library
    if not (Library and Library.RegisterTheme and Library.Themes) then return false end
    for _, Name in ThemeManager.ThemeNames do
        local Entry = ThemeManager.BuiltInThemes[Name]
        if Entry and typeof(Entry[2]) == "table" then
            RegisterPalette(Name, Entry[2])
        end
    end
    return true
end

function ThemeManager:RegisterAccessibilityThemes()
    local Library = ThemeManager.Library
    if not (Library and Library.RegisterTheme and Library.Themes) then return false end
    for _, Entry in ThemeManager.AccessibilityThemes do
        RegisterPalette(Entry[1], Entry[2])
    end
    return true
end

function ThemeManager:GetThemeGroup(Name)
    if typeof(Name) ~= "string" then return "Custom" end
    local Group = ThemeManager.ThemeGroups[Name]
    if Group then return Group end
    local Lower = string.lower(Name)
    if string.find(Lower, "glass", 1, true) or string.find(Lower, "frost", 1, true) then return "Glass" end
    if string.find(Lower, "grey", 1, true) or string.find(Lower, "gray", 1, true) then return "Grey" end
    return "Custom"
end

function ThemeManager:GetMaterial()
    return table.clone(ThemeManager.Material or ReadMaterial())
end

function ThemeManager:SetMaterial(Overrides)
    if typeof(Overrides) ~= "table" then return false, "Material overrides must be a table" end
    local Merged = table.clone(ThemeManager.Material or ReadMaterial())
    for _, Key in { "Tier", "Transparency", "Scrim", "BorderTransparency", "Highlight", "Shadow", "ReduceTransparency" } do
        if Overrides[Key] ~= nil then Merged[Key] = Overrides[Key] end
    end
    if Overrides.Tier ~= nil and Overrides.Transparency == nil then
        local Preset = MaterialTiers[Overrides.Tier]
        if Preset then
            Merged.Transparency = Preset.Transparency
            Merged.Scrim = Preset.Scrim
            Merged.BorderTransparency = Preset.BorderTransparency
        end
    end
    if not WriteMaterial(Merged) then return false, "Library does not support design tokens" end
    if ThemeManager.WatermarkFollowsMaterial then
        ApplyWatermark(WatermarkForMaterial(ThemeManager.Material) or ThemeManager.BaseWatermark)
    end
    ThemeManager:SyncMaterialControls()
    ThemeManager:UpdateContrast()
    return true
end

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
    Library.ThemeManager = ThemeManager
    ThemeManager:RegisterBuiltInThemes()
    ThemeManager.BaseWatermark = SnapshotWatermark()
    ThemeManager.Material = ReadMaterial()
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
    ThemeManager:ApplyThemeMaterial(Resolved)
    ThemeManager:SyncFromLibrary(Resolved)
    ThemeManager:UpdatePreviewControls()
    return true
end

function ThemeManager:ApplyThemeMaterial(Name)
    local Material = ThemeMaterial(Name)
    if not WriteMaterial(Material) then
        ThemeManager.Material = Material
        return false
    end
    if ThemeManager.WatermarkFollowsMaterial then
        ApplyWatermark(WatermarkForMaterial(Material) or ThemeManager.BaseWatermark)
    end
    ThemeManager:SyncMaterialControls()
    return true
end

function ThemeManager:PreviewTheme(Name)
    local Library = ThemeManager.Library
    if not Library then return false, "Library is not set" end
    local Colors = ThemePaletteColors(Name)
    if not next(Colors) then return false, "Theme has no palette" end
    if not ThemeManager.Previewing then
        ThemeManager.PreviewSnapshot = SnapshotAppearance()
    end
    ThemeManager.Previewing = true
    ThemeManager.PreviewName = Name
    ThemeManager:ApplyThemeMaterial(FindRegisteredTheme(Name) or Name)
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
    RestoreAppearance(Snapshot)
    ThemeManager:SyncMaterialControls()
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

function ThemeManager:CreateGalleryCard(Parent, Name, Order)
    local Library = ThemeManager.Library
    if not (Library and Parent) then return end

    local Card, Stroke = Library:CreateSurface(Parent, {
        ClassName = "TextButton",
        Role = "Raised",
        RadiusRole = "Card",
    })
    Card.AutoButtonColor = false
    Card.Text = ""
    Card.LayoutOrder = Order
    Card.ClipsDescendants = true

    local Colors = ThemePaletteColors(Name)
    local Material = ThemeMaterial(FindRegisteredTheme(Name) or Name)
    local Translucent = EffectiveTransparency(Material)
    local CardHeight = Library.IsMobile and 56 or 48
    local PreviewSize = 40
    local Inset = 3
    local MockSize = PreviewSize - Inset * 2

    local function Tone(Key)
        return Colors[Key] or Library.Scheme[Key]
    end

    local Preview = Instance.new("Frame")
    Preview.BackgroundColor3 = Tone("BackgroundColor")
    Preview.BorderSizePixel = 0
    Preview.Size = UDim2.fromOffset(PreviewSize, PreviewSize)
    Preview.Position = UDim2.fromOffset(6, Library:CenterOffset(CardHeight, PreviewSize))
    Preview.ClipsDescendants = true
    Preview.Parent = Card

    local PreviewCorner = Instance.new("UICorner")
    PreviewCorner.CornerRadius = UDim.new(0, Library:GetDesignToken("Radius.Indicator", 3))
    PreviewCorner.Parent = Preview

    if Translucent > 0 then
        local Quadrant = PreviewSize // 2
        for _, Cell in { { 0, 0, true }, { Quadrant, 0, false }, { 0, Quadrant, false }, { Quadrant, Quadrant, true } } do
            local Tile = Instance.new("Frame")
            Tile.BackgroundColor3 = Cell[3] and Tone("WhiteColor") or Tone("MutedFontColor")
            Tile.BorderSizePixel = 0
            Tile.Size = UDim2.fromOffset(Quadrant, Quadrant)
            Tile.Position = UDim2.fromOffset(Cell[1], Cell[2])
            Tile.Parent = Preview
        end
    end

    local Mock = Instance.new("Frame")
    Mock.BackgroundColor3 = Tone("BackgroundColor")
    Mock.BackgroundTransparency = Translucent
    Mock.BorderSizePixel = 0
    Mock.Size = UDim2.fromOffset(MockSize, MockSize)
    Mock.Position = UDim2.fromOffset(Inset, Inset)
    Mock.ClipsDescendants = true
    Mock.Parent = Preview

    local MockCorner = Instance.new("UICorner")
    MockCorner.CornerRadius = UDim.new(0, 2)
    MockCorner.Parent = Mock

    for _, Part in {
        { "TopBarColor", 0, 0, MockSize, 7, Translucent },
        { "SurfaceColor", 0, 7, 11, MockSize - 7, Translucent },
        { "ElementColor", 13, 10, 19, 8, 0 },
        { "HoverColor", 13, 21, 19, 5, 0 },
        { "AccentColor", 2, 2, 3, 3, 0 },
        { "FontColor", 2, 11, 7, 2, 0 },
        { "MutedFontColor", 2, 16, 7, 2, 0 },
    } do
        local Piece = Instance.new("Frame")
        Piece.BackgroundColor3 = Tone(Part[1])
        Piece.BackgroundTransparency = Part[6]
        Piece.BorderSizePixel = 0
        Piece.Position = UDim2.fromOffset(Part[2], Part[3])
        Piece.Size = UDim2.fromOffset(Part[4], Part[5])
        Piece.Parent = Mock
    end

    local TextLeft = 6 + PreviewSize + 8
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = Name
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Bottom
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.TextSize = Library:GetDesignToken("Size.Text", 14)
    Label.FontFace = Library.Scheme.Font
    Label.TextColor3 = Library.Scheme.FontColor
    Label.Position = UDim2.fromOffset(TextLeft, 0)
    Label.Size = UDim2.new(1, -(TextLeft + 6), 0.5, 0)
    Label.Parent = Card
    Library:AddToRegistry(Label, { TextColor3 = "FontColor" })

    local Caption = Instance.new("TextLabel")
    Caption.BackgroundTransparency = 1
    Caption.Text = TierLabels[Material.Tier] or "Solid"
    Caption.TextXAlignment = Enum.TextXAlignment.Left
    Caption.TextYAlignment = Enum.TextYAlignment.Top
    Caption.TextTruncate = Enum.TextTruncate.AtEnd
    Caption.TextSize = Library:GetDesignToken("Size.Caption", 12)
    Caption.FontFace = Library.Scheme.Font
    Caption.TextColor3 = Library.Scheme.MutedFontColor
    Caption.Position = UDim2.new(0, TextLeft, 0.5, 1)
    Caption.Size = UDim2.new(1, -(TextLeft + 6), 0.5, -1)
    Caption.Parent = Card
    Library:AddToRegistry(Caption, { TextColor3 = "MutedFontColor" })

    Library:GiveSignal(Card.Activated:Connect(function()
        ThemeManager:PreviewTheme(Name)
    end))

    ThemeManager.GalleryCards[Name] = { Card = Card, Stroke = Stroke, Label = Label, Caption = Caption }
end

function ThemeManager:RebuildGallery(Names)
    local Library = ThemeManager.Library
    local Holder = ThemeManager.GalleryHolder
    if not (Library and Holder and Holder.Parent) then return end
    Names = Names or table.clone(ThemeManager.ThemeNames)

    for _, Section in ThemeManager.GallerySections or {} do
        Library:ReleaseRegistryTree(Section.Root)
        Section.Root:Destroy()
    end
    table.clear(ThemeManager.GalleryCards)
    ThemeManager.GallerySections = {}

    local Grouped = {}
    for _, Name in Names do
        local Group = ThemeManager:GetThemeGroup(FindRegisteredTheme(Name) or Name)
        Grouped[Group] = Grouped[Group] or {}
        table.insert(Grouped[Group], Name)
    end

    local CardHeight = Library.IsMobile and 56 or 48
    local CaptionHeight = 14
    local CaptionGap = 4
    local SectionOrder = 0

    for _, Group in ThemeManager.ThemeGroupOrder do
        local Members = Grouped[Group]
        if Members and #Members > 0 then
            SectionOrder += 1

            local Root = Instance.new("Frame")
            Root.BackgroundTransparency = 1
            Root.LayoutOrder = SectionOrder
            Root.Size = UDim2.new(1, 0, 0, CaptionHeight + CaptionGap + CardHeight)
            Root.Parent = Holder

            local Caption = Instance.new("TextLabel")
            Caption.BackgroundTransparency = 1
            Caption.Text = Group
            Caption.TextXAlignment = Enum.TextXAlignment.Left
            Caption.TextSize = Library:GetDesignToken("Size.Caption", 12)
            Caption.FontFace = Library.Scheme.Font
            Caption.TextColor3 = Library.Scheme.MutedFontColor
            Caption.Size = UDim2.new(1, 0, 0, CaptionHeight)
            Caption.Parent = Root
            Library:AddToRegistry(Caption, { TextColor3 = "MutedFontColor" })

            local Grid = Instance.new("Frame")
            Grid.BackgroundTransparency = 1
            Grid.Position = UDim2.fromOffset(0, CaptionHeight + CaptionGap)
            Grid.Size = UDim2.new(1, 0, 0, CardHeight)
            Grid.Parent = Root

            local Layout = Instance.new("UIGridLayout")
            Layout.CellPadding = UDim2.fromOffset(6, 6)
            Layout.CellSize = UDim2.fromOffset(150, CardHeight)
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = Grid

            for Order, Name in Members do
                ThemeManager:CreateGalleryCard(Grid, Name, Order)
            end

            table.insert(ThemeManager.GallerySections, { Root = Root, Grid = Grid, Layout = Layout, Count = #Members })
        end
    end

    if ThemeManager.GalleryResize then ThemeManager.GalleryResize() end
    ThemeManager:SetGallerySelection(ThemeManager.Previewing and ThemeManager.PreviewName or Library.CurrentTheme)
end

function ThemeManager:BuildGallery(Groupbox)
    local Library = ThemeManager.Library
    if not (Library and Library.CreateSurface) then return end
    ThemeManager.GalleryGroupbox = Groupbox
    ThemeManager.GalleryCards = {}
    ThemeManager.GallerySections = {}

    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.Size = UDim2.new(1, 0, 0, 0)
    Holder.Parent = Groupbox.Container
    ThemeManager.GalleryHolder = Holder

    local CardHeight = Library.IsMobile and 56 or 48
    local CaptionHeight = 14
    local CaptionGap = 4
    local Gap = 6
    local SectionGap = 10
    local MinCardWidth = 150

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, SectionGap)
    Layout.FillDirection = Enum.FillDirection.Vertical
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Holder

    local function Resize()
        if not Holder.Parent then return end
        local Width = math.max(1, math.floor(Holder.AbsoluteSize.X / math.max(Library.DPIScale, 1)))
        local Total = 0
        local Visible = 0
        for _, Section in ThemeManager.GallerySections do
            local Count = math.max(Section.Count, 1)
            local Columns = math.max(1, math.min(Count, math.floor((Width + Gap) / (MinCardWidth + Gap))))
            local CellWidth = math.max(1, math.floor((Width - (Columns - 1) * Gap) / Columns))
            Section.Layout.CellSize = UDim2.fromOffset(CellWidth, CardHeight)
            local Rows = math.ceil(Count / Columns)
            local GridHeight = Rows * (CardHeight + Gap) - Gap
            Section.Grid.Size = UDim2.new(1, 0, 0, GridHeight)
            Section.Root.Size = UDim2.new(1, 0, 0, CaptionHeight + CaptionGap + GridHeight)
            Total += CaptionHeight + CaptionGap + GridHeight
            Visible += 1
        end
        Holder.Size = UDim2.new(1, 0, 0, math.max(0, Total + math.max(0, Visible - 1) * SectionGap))
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
