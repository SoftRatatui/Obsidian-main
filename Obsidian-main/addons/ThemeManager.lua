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

local ThemeManager = {
    ReleaseVersion = "0.0.1-release-16",
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

local function ThemeFolder()
    return ThemeManager.Folder .. "/themes"
end

local function ThemePath(Name)
    return ThemeFolder() .. "/" .. Name .. ".json"
end

local function DefaultThemePath()
    return ThemeFolder() .. "/" .. ThemeManager.DefaultThemeFileName
end

local function WriteVerified(Path, Content)
    local Temporary = Path .. ".tmp"
    local HadPrevious = IsFile(Path)
    local Previous
    if HadPrevious then
        local ReadPrevious, PreviousContent = pcall(readfile, Path)
        if ReadPrevious then Previous = PreviousContent end
    end
    local Wrote, ErrorMessage = pcall(writefile, Temporary, Content)
    if not Wrote then return false, tostring(ErrorMessage) end
    local Read, Value = pcall(readfile, Temporary)
    if not Read or Value ~= Content then
        pcall(delfile, Temporary)
        return false, "Temporary theme file verification failed"
    end
    local Final, FinalError = pcall(writefile, Path, Content)
    pcall(delfile, Temporary)
    if not Final then return false, tostring(FinalError) end
    local Verified, FinalValue = pcall(readfile, Path)
    if not Verified or FinalValue ~= Content then
        if Previous ~= nil then
            pcall(writefile, Path, Previous)
        elseif not HadPrevious and IsFile(Path) then
            pcall(delfile, Path)
        end
        return false, "Theme file verification failed"
    end
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

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
    Library.ThemeManager = ThemeManager
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
    return true
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
    return Names
end

function ThemeManager:CreateThemeManager(Groupbox)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")
    assert(not ThemeManager.AppliedToTab, "ThemeManager is already applied to a tab")
    local Names = ThemeManager:RefreshThemeList()
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

    if ThemeManager.FileSystemAvailable and Groupbox.AddInput and Groupbox.AddButton then
        Groupbox:AddInput("ThemeManager_CustomThemeName", {
            Text = "Custom theme name",
            ClearTextOnFocus = false,
        })
        local function Notify(Message)
            if ThemeManager.Library.Notify then ThemeManager.Library:Notify(Message) end
        end
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
    for _, Field in { { "Window", "Window corners" }, { "Card", "Panel corners" }, { "Control", "Control corners" }, { "Indicator", "Checkbox corners" } } do
        local Key = Field[1]
        Groupbox:AddSlider("ThemeManager_Radius_" .. Key, {
            Text = Field[2],
            Default = Library:GetDesignToken("Radius." .. Key, 4),
            Min = 0,
            Max = Key == "Indicator" and 6 or 12,
            Rounding = 0,
            Suffix = "px",
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
    return Groupbox
end

function ThemeManager:ApplyToTab(Tab, IconName)
    return ThemeManager:CreateThemeManager(ThemeManager:CreateGroupBox(Tab, IconName))
end

function ThemeManager:ApplyToGroupbox(Groupbox)
    return ThemeManager:CreateThemeManager(Groupbox)
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
