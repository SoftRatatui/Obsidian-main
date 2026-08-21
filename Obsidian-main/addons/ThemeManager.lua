local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local getgenv = type(getgenv) == "function" and getgenv or function()
    return if typeof(shared) == "table" then shared else _G
end

local NativeIsFolder, NativeIsFile, NativeListFiles = isfolder, isfile, listfiles
local FileSystemAvailable = type(NativeIsFolder) == "function" and type(NativeIsFile) == "function" and type(NativeListFiles) == "function" and type(makefolder) == "function" and type(readfile) == "function" and type(writefile) == "function" and type(delfile) == "function"

local function isfolder(Folder)
    local Success, Result = pcall(NativeIsFolder, Folder)
    return Success and Result == true
end

local function isfile(File)
    local Success, Result = pcall(NativeIsFile, File)
    return Success and Result == true
end

local function listfiles(Folder)
    local Success, Result = pcall(NativeListFiles, Folder)
    return if Success and typeof(Result) == "table" then Result else {}
end


local SchemeIndexes = { "FontColor", "MainColor", "TopBarColor", "AccentColor", "BackgroundColor", "OutlineColor", "WarningColor", "DestructiveColor" }
local InternalSchemeIndexes = { "RedColor", "DarkColor", "WhiteColor" }
local AllSchemeIndexes = { "FontColor", "MainColor", "TopBarColor", "AccentColor", "BackgroundColor", "OutlineColor", "WarningColor", "DestructiveColor", "RedColor", "DarkColor", "WhiteColor" }
local ThemeOptionPrefix = "ThemeManager_"
local SupportedFontFaces = { "BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "RobotoMono", "Roboto", "SourceSans" }

local function GetThemeOptionId(SchemeIndex: string): string
    return ThemeOptionPrefix .. SchemeIndex
end
local ThemeManager = {
    Library = nil,
    FileSystemAvailable = FileSystemAvailable,

    Folder = "ObsidianLibSettings",

    AppliedToTab = false,
    DefaultThemeName = nil,
    DefaultThemeFileName = "default-v5.txt",
    FallbackThemeName = "Default",
    FallbackThemeLabel = "Graphite",
    ApplyingTheme = false,
    ConfigLoadDepth = 0,
    ConfigLoadOptions = {},

    BuiltInThemes = {
        ["Default"] = {
            1,
            { FontColor = "eff1f6", MainColor = "21242b", TopBarColor = "272a32", AccentColor = "858da0", BackgroundColor = "16181d", OutlineColor = "414550", WarningColor = "d09d50", DestructiveColor = "c43a4c", RedColor = "e85367", DarkColor = "000000", WhiteColor = "f8f9fc", BackgroundImage = "", FontFace = "Gotham" },
        },
        ["BBot"] = {
            2,
            { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414", BackgroundImage = "" },
        },
        ["Fatality"] = {
            3,
            { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d", BackgroundImage = "" },
        },
        ["Jester"] = {
            4,
            { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737", BackgroundImage = "" },
        },
        ["Mint"] = {
            5,
            { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737", BackgroundImage = "" },
        },
        ["Tokyo Night"] = {
            6,
            { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232", BackgroundImage = "" },
        },
        ["Ubuntu"] = {
            7,
            { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919", BackgroundImage = "" },
        },
        ["Quartz"] = {
            8,
            { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f", BackgroundImage = "" },
        },
        ["Nord"] = {
            9,
            { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a", BackgroundImage = "" },
        },
        ["Dracula"] = {
            10,
            { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4", BackgroundImage = "" },
        },
        ["Monokai"] = {
            11,
            { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e", BackgroundImage = "" },
        },
        ["Gruvbox"] = {
            12,
            { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945", BackgroundImage = "" },
        },
        ["Solarized"] = {
            13,
            { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75", BackgroundImage = "" },
        },
        ["Catppuccin"] = {
            14,
            { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268", BackgroundImage = "" },
        },
        ["One Dark"] = {
            15,
            { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370", BackgroundImage = "" },
        },
        ["Cyberpunk"] = {
            16,
            { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e", BackgroundImage = "" },
        },
        ["Oceanic Next"] = {
            17,
            { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46", BackgroundImage = "" },
        },
        ["Material"] = {
            18,
            { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242", BackgroundImage = "" },
        }
    }
}

for _, ThemeInfo in ThemeManager.BuiltInThemes do
    local ThemeData = ThemeInfo[2]
    ThemeData.TopBarColor = ThemeData.TopBarColor or ThemeData.MainColor
    ThemeData.WarningColor = ThemeData.WarningColor or "d09d50"
    ThemeData.DestructiveColor = ThemeData.DestructiveColor or "c43a4c"
end

local GraphiteThemeData = table.clone(ThemeManager.BuiltInThemes[ThemeManager.FallbackThemeName][2])
GraphiteThemeData.RedColor = GraphiteThemeData.RedColor or "e85367"
GraphiteThemeData.DarkColor = GraphiteThemeData.DarkColor or "000000"
GraphiteThemeData.WhiteColor = GraphiteThemeData.WhiteColor or "f8f9fc"

local BaseThemeData = table.clone(GraphiteThemeData)

local function NormalizeThemeData(ThemeData)
    local Normalized = table.clone(BaseThemeData)
    local Source = typeof(ThemeData) == "table" and ThemeData or nil

    if Source then
        for Index, Value in Source do
            if Index ~= "VideoLink" and Value ~= nil then
                Normalized[Index] = Value
            end
        end
    end

    if Source and Source.TopBarColor == nil and Source.MainColor ~= nil then
        Normalized.TopBarColor = Source.MainColor
    end

    if Source and Source.FontFace == nil and Source.Font ~= nil then
        Normalized.FontFace = Source.Font
    end

    if Source and Source.RedColor == nil and Source.Red ~= nil then
        Normalized.RedColor = Source.Red
    end
    if Source and Source.DarkColor == nil and Source.Dark ~= nil then
        Normalized.DarkColor = Source.Dark
    end
    if Source and Source.WhiteColor == nil and Source.White ~= nil then
        Normalized.WhiteColor = Source.White
    end

    Normalized.TopBarColor = Normalized.TopBarColor or Normalized.MainColor
    Normalized.WarningColor = Normalized.WarningColor or BaseThemeData.WarningColor
    Normalized.DestructiveColor = Normalized.DestructiveColor or BaseThemeData.DestructiveColor
    Normalized.FontFace = Normalized.FontFace or BaseThemeData.FontFace or "Gotham"
    Normalized.BackgroundImage = Normalized.BackgroundImage or ""

    return Normalized
end

local function ResolveThemeColor(Value, Fallback)
    if typeof(Value) == "Color3" then
        return Value
    end

    if typeof(Value) == "string" then
        local Success, Color = pcall(Color3.fromHex, Value)
        if Success and typeof(Color) == "Color3" then
            return Color
        end
    end

    return Fallback
end

local function ResolveThemeFont(Value)
    if typeof(Value) == "Font" then
        local Family = string.lower(Value.Family)
        for _, FontName in SupportedFontFaces do
            if string.find(Family, string.lower(FontName), 1, true) then
                return Value, FontName
            end
        end

        return Value, "Gotham"
    end

    if typeof(Value) == "EnumItem" then
        return Font.fromEnum(Value), Value.Name
    end

    if typeof(Value) == "string" and Enum.Font[Value] then
        return Font.fromEnum(Enum.Font[Value]), Value
    end

    return Font.fromEnum(Enum.Font.Gotham), "Gotham"
end

local function ApplyThemeData(ThemeData, SynchronizeOptions)
    local Library = ThemeManager.Library
    if not Library then
        return false, "Library is not set"
    end

    local Normalized = NormalizeThemeData(ThemeData)
    ThemeManager.ApplyingTheme = true
    local Success, ErrorMessage = pcall(function()
        local function ApplySchemeColor(SchemeIndex: string, SynchronizeOption: boolean)
            local Fallback = ResolveThemeColor(BaseThemeData[SchemeIndex], Color3.new(1, 1, 1))
            local Color = ResolveThemeColor(Normalized[SchemeIndex], Fallback)
            Library.Scheme[SchemeIndex] = Color

            if SynchronizeOptions and SynchronizeOption then
                local Element = Library.Options[GetThemeOptionId(SchemeIndex)]
                if Element then
                    Element:SetValue(Color)
                end
            end
        end

        for _, SchemeIndex in SchemeIndexes do
            ApplySchemeColor(SchemeIndex, true)
        end

        for _, SchemeIndex in InternalSchemeIndexes do
            ApplySchemeColor(SchemeIndex, false)
        end

        local FontFace, FontName = ResolveThemeFont(Normalized.FontFace)
        Library:SetFont(FontFace, true)

        if SynchronizeOptions and Library.Options.ThemeManager_FontFace then
            Library.Options.ThemeManager_FontFace:SetValue(FontName)
        end

        local BackgroundImage = Normalized.BackgroundImage
        if typeof(BackgroundImage) ~= "string" and typeof(BackgroundImage) ~= "number" then
            BackgroundImage = ""
        end

        Library.Scheme.BackgroundImage = BackgroundImage
        if Library.Window then
            Library.Window:SetBackgroundImage(BackgroundImage)
        end

        if SynchronizeOptions and Library.Options.ThemeManager_BackgroundImage then
            Library.Options.ThemeManager_BackgroundImage:SetValue(tostring(BackgroundImage))
        end

        Library.IsLightTheme = Normalized.IsLight == true
        Library.Scheme.Red = nil
        Library.Scheme.Dark = nil
        Library.Scheme.White = nil
        Library:UpdateColorsUsingRegistry()
    end)
    ThemeManager.ApplyingTheme = false

    if not Success then
        return false, tostring(ErrorMessage)
    end

    return true
end

function ThemeManager:SetLibrary(Library)
    ThemeManager.Library = Library
    Library.ThemeManager = ThemeManager
end

function ThemeManager:SyncFromLibrary()
    if not ThemeManager.AppliedToTab or ThemeManager.ApplyingTheme or ThemeManager.ConfigLoadDepth > 0 then
        return
    end

    local Library = ThemeManager.Library
    ThemeManager.ApplyingTheme = true
    local Success, ErrorMessage = pcall(function()
        for _, SchemeIndex in SchemeIndexes do
            local Element = Library.Options[GetThemeOptionId(SchemeIndex)]
            if Element then
                Element:SetValue(Library.Scheme[SchemeIndex])
            end
        end

        local _FontFace, FontName = ResolveThemeFont(Library.Scheme.Font)
        if Library.Options.ThemeManager_FontFace then
            Library.Options.ThemeManager_FontFace:SetValue(FontName)
        end

        if Library.Options.ThemeManager_BackgroundImage then
            Library.Options.ThemeManager_BackgroundImage:SetValue(tostring(Library.Scheme.BackgroundImage or ""))
        end
    end)
    ThemeManager.ApplyingTheme = false

    if not Success then
        return false, tostring(ErrorMessage)
    end

    return true
end


local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

local function IsStringEmpty(String: string): boolean
    return if typeof(String) == "string" then Trim(String) == "" else true
end

function ThemeManager:BeginConfigLoad()
    ThemeManager.ConfigLoadDepth += 1
    if ThemeManager.ConfigLoadDepth == 1 then
        ThemeManager.ConfigLoadOptions = {}
    end

    return true
end

function ThemeManager:MarkConfigOptionLoaded(OptionId: string)
    if ThemeManager.ConfigLoadDepth > 0 and typeof(OptionId) == "string" then
        ThemeManager.ConfigLoadOptions[OptionId] = true
    end
end

function ThemeManager:EndConfigLoad()
    if ThemeManager.ConfigLoadDepth <= 0 then
        return false, "No theme config load is in progress"
    end

    ThemeManager.ConfigLoadDepth -= 1
    if ThemeManager.ConfigLoadDepth > 0 then
        return true
    end

    local LoadedOptions = ThemeManager.ConfigLoadOptions
    ThemeManager.ConfigLoadOptions = {}

    local Library = ThemeManager.Library
    if not Library then
        return false, "Library is not set"
    end

    local ThemeData = nil
    local ThemeListId = "ThemeManager_ThemeList"
    if LoadedOptions[ThemeListId] then
        local ThemeList = Library.Options[ThemeListId]
        local ThemeName = ThemeList and ThemeList.Value
        if not IsStringEmpty(ThemeName) then
            local CustomThemeData = ThemeManager:GetCustomTheme(ThemeName)
            local BuiltInTheme = ThemeManager.BuiltInThemes[ThemeName]
            ThemeData = CustomThemeData or (BuiltInTheme and BuiltInTheme[2])
        end
    end

    local ShouldApply = ThemeData ~= nil
    if not ThemeData then
        ThemeData = {
            FontFace = Library.Scheme.Font,
            BackgroundImage = Library.Scheme.BackgroundImage,
            IsLight = Library.IsLightTheme
        }

        for _, SchemeIndex in AllSchemeIndexes do
            ThemeData[SchemeIndex] = Library.Scheme[SchemeIndex]
        end
    else
        ThemeData = table.clone(ThemeData)
    end

    for _, SchemeIndex in SchemeIndexes do
        local OptionId = GetThemeOptionId(SchemeIndex)
        if LoadedOptions[OptionId] then
            local Option = Library.Options[OptionId]
            if Option then
                ThemeData[SchemeIndex] = Option.Value
                ShouldApply = true
            end
        end
    end

    if LoadedOptions.ThemeManager_FontFace then
        local FontFace = Library.Options.ThemeManager_FontFace
        if FontFace then
            ThemeData.FontFace = FontFace.Value
            ShouldApply = true
        end
    end

    if LoadedOptions.ThemeManager_BackgroundImage then
        local BackgroundImage = Library.Options.ThemeManager_BackgroundImage
        if BackgroundImage then
            ThemeData.BackgroundImage = BackgroundImage.Value
            ShouldApply = true
        end
    end

    if not ShouldApply then
        return true
    end

    return ApplyThemeData(ThemeData, true)
end

local function IsValidFolderPath(Name: string): boolean
    return typeof(Name) == "string" and (
        Trim(Name) ~= "" and 
        not Name:match("^%s*$") and 
        not Name:find('[<>:"|%?%*%z]')
    )
end


local function SplitPath(Path: string): {string}
	local Result = {}
	local Current = ""

	for Part in string.gmatch(Path, "[^/]+") do
		Current = if Current == "" then Part else (Current .. "/" .. Part)
		table.insert(Result, Current)
	end

	return Result
end

local function GetFolderPath(): false | string
    if IsStringEmpty(ThemeManager.Folder) then
        return false
    end

    return string.format("%s/themes", ThemeManager.Folder)
end

local GetCurrentThemesPath = GetFolderPath


local function GetThemePath(ThemeName: string): false | string
    local CurrentThemesPath = GetCurrentThemesPath()
    return if CurrentThemesPath == false then false else string.format("%s/%s.json", CurrentThemesPath, ThemeName)
end

local function DoesThemeExist(ThemeName: string, IncludeBuiltIn: boolean): boolean
    if ThemeManager.BuiltInThemes[ThemeName] then
        return true
    end

    local ThemePath = GetThemePath(ThemeName)
    return if ThemePath == false then false else isfile(ThemePath)
end

local function GetDefaultThemePath(): false | string
    local CurrentThemesPath = GetCurrentThemesPath()
    return if CurrentThemesPath == false then false else string.format("%s/%s", CurrentThemesPath, ThemeManager.DefaultThemeFileName)
end


function ThemeManager:GetPaths(): {string}
    local FolderPath = GetFolderPath()
    return if FolderPath == false then {} else SplitPath(FolderPath)
end

function ThemeManager:BuildFolderTree(SkipWhenCreated: boolean?)
    if not ThemeManager.FileSystemAvailable then
        return false
    end

    local Paths = ThemeManager:GetPaths()
    if #Paths == 0 then
        return false
    end

    if SkipWhenCreated == true then
        if isfolder(Paths[1]) then
            return true
        end
    end

    for _, Path in Paths do
        if isfolder(Path) then continue end
        
        makefolder(Path)
    end

    return true
end

function ThemeManager:CheckFolderTree()
    return ThemeManager:BuildFolderTree(true)
end

function ThemeManager:SetFolder(Folder: string)
    assert(IsValidFolderPath(Folder), "Invalid path provided")

    ThemeManager.Folder = Folder
    ThemeManager:BuildFolderTree()
end

function ThemeManager:SetDefaultThemeFileName(FileName: string)
    assert(typeof(FileName) == "string" and FileName:match("^[%w_%-]+%.txt$"), "Invalid default theme file name")

    ThemeManager.DefaultThemeFileName = FileName
    ThemeManager.DefaultThemeName = nil
end


function ThemeManager:ReloadCustomThemes()
    local SettingsPath = GetCurrentThemesPath()
    if SettingsPath == false then
        return {}
    end

    local SuccessList, Files = pcall(listfiles, SettingsPath)
    if not (SuccessList and typeof(Files) == "table") then
        ThemeManager.Library:Notify(string.format("Failed to load theme list: %s", tostring(Files)))
        return {}
    end

    local FileNames = {}
    for _, FilePath in Files do
        local Extension = FilePath:match("%.([^.]+)$")
        if not Extension or string.lower(Extension) ~= "json" then
            continue
        end

        local RawFileName = FilePath:match("(.+)%..+$")
        if not RawFileName then continue end

        local Position = RawFileName:gsub("\\", "/"):find("/[^/]*$")
        local FileName = Position and RawFileName:sub(Position + 1) or RawFileName
        if not FileName then continue end

        table.insert(FileNames, FileName)
    end

    return FileNames
end

function ThemeManager:GetCustomTheme(ThemeName: string): any
    if IsStringEmpty(ThemeName) then
        return nil
    end

    local ThemePath = GetThemePath(ThemeName)
    if ThemePath == false or not isfile(ThemePath) then
        return nil
    end

    local SuccessRead, Content = pcall(readfile, ThemePath)
    if not SuccessRead then
        return nil
    end

    local SuccessDecode, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if not SuccessDecode or typeof(Decoded) ~= "table" then
        return nil
    end

    return Decoded
end

function ThemeManager:SaveCustomTheme(ThemeName: string): any
    if IsStringEmpty(ThemeName) then
        return false, "Invalid theme name provided"
    end

    if string.lower(ThemeName) == "default" then
        return false, "Invalid theme name provided"
    end

    local ThemePath = GetThemePath(ThemeName)
    if ThemePath == false then
        return false, "Invalid theme name provided"
    end

    ThemeManager:CheckFolderTree()

    local Library = ThemeManager.Library
    local _FontFace, FontName = ResolveThemeFont(Library.Scheme.Font)
    local ThemeData = {
        FontFace = FontName,
        BackgroundImage = Library.Scheme.BackgroundImage or ""
    }

    for _, SchemeIndex in AllSchemeIndexes do
        local Fallback = ResolveThemeColor(BaseThemeData[SchemeIndex], Color3.new(1, 1, 1))
        ThemeData[SchemeIndex] = ResolveThemeColor(Library.Scheme[SchemeIndex], Fallback):ToHex()
    end

    local SuccessEncode, EncodedData = pcall(HttpService.JSONEncode, HttpService, ThemeData)
    if not SuccessEncode then
        return false, "Failed to encode data"
    end

    local SuccessWrite, ErrorMessage = pcall(writefile, ThemePath, EncodedData)
    if not SuccessWrite then
        return false, "Failed to write theme file: " .. tostring(ErrorMessage)
    end

    return true
end

function ThemeManager:Delete(ThemeName: string): (boolean | string?)
    if IsStringEmpty(ThemeName) then
        return false, "No theme is selected"
    end

    local ThemePath = GetThemePath(ThemeName)
    if ThemePath == false or not isfile(ThemePath) then
        return false, "Theme file does not exist"
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, ThemePath)
    if not SuccessDelete then
        return false, "Failed to delete theme file: " .. tostring(ErrorMessage)
    end

    if ThemeName == ThemeManager.DefaultThemeName then
        ThemeManager:DeleteDefaultTheme()
    end

    return true
end


function ThemeManager:GetDefaultTheme(): (string, boolean, string?)
    ThemeManager:CheckFolderTree()

    local DefaultThemePath = GetDefaultThemePath()
    if DefaultThemePath == false then
        ThemeManager.DefaultThemeName = nil
        return "none", false, "Invalid path provided"
    end

    if not isfile(DefaultThemePath) then
        ThemeManager.DefaultThemeName = nil
        return "none", false, "Default theme is not set"
    end

    local SuccessRead, DefaultThemeName = pcall(readfile, DefaultThemePath)
    if not (SuccessRead and typeof(DefaultThemeName) == "string") then
        ThemeManager.DefaultThemeName = nil
        return "none", false, DefaultThemeName
    end

    DefaultThemeName = Trim(DefaultThemeName)

    local ConfigExists = DoesThemeExist(DefaultThemeName, true)
    if not ConfigExists then
        ThemeManager.DefaultThemeName = nil
        return "none", false, "Theme file not found"
    end

    ThemeManager.DefaultThemeName = DefaultThemeName
    return DefaultThemeName, true
end

function ThemeManager:SetDefaultTheme(Theme: any)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")
    assert(not ThemeManager.AppliedToTab, "Cannot set default theme after applying ThemeManager to a tab!")
    assert(typeof(Theme) == "table", "Theme must be a table")

    local DefaultTheme = NormalizeThemeData(Theme)
    local _, FontName = ResolveThemeFont(DefaultTheme.FontFace)
    DefaultTheme.FontFace = FontName
    DefaultTheme.Font = nil
    DefaultTheme.Red = nil
    DefaultTheme.Dark = nil
    DefaultTheme.White = nil

    for _, SchemeIndex in AllSchemeIndexes do
        local Fallback = ResolveThemeColor(GraphiteThemeData[SchemeIndex], Color3.new(1, 1, 1))
        DefaultTheme[SchemeIndex] = ResolveThemeColor(DefaultTheme[SchemeIndex], Fallback):ToHex()
    end

    if typeof(DefaultTheme.BackgroundImage) ~= "string" and typeof(DefaultTheme.BackgroundImage) ~= "number" then
        DefaultTheme.BackgroundImage = ""
    end

    local ExistingTheme = ThemeManager.BuiltInThemes[ThemeManager.FallbackThemeName]
    ThemeManager.BuiltInThemes[ThemeManager.FallbackThemeName] = { ExistingTheme[1], DefaultTheme }
    BaseThemeData = table.clone(DefaultTheme)

    return ApplyThemeData(DefaultTheme, false)
end

function ThemeManager:SaveDefault(ThemeName: string): (boolean, string?)
    if IsStringEmpty(ThemeName) then
        return false, "No theme is selected"
    end

    ThemeManager:CheckFolderTree()

    local DefaultThemePath = GetDefaultThemePath()
    if DefaultThemePath == false then
        return false, "Invalid path provided"
    end

    if not DoesThemeExist(ThemeName, true) then
        return false, "Theme does not exist"
    end

    local SuccessWrite, ErrorMessage = pcall(writefile, DefaultThemePath, ThemeName)
    if not SuccessWrite then
        return false, ErrorMessage
    end

    ThemeManager.DefaultThemeName = ThemeName
    return true
end

function ThemeManager:LoadDefault()
    local ThemeName, Success, FetchErrorMessage = ThemeManager:GetDefaultTheme()
    if not Success then
        local Applied, ApplyErrorMessage = ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
        if Applied then
            if FetchErrorMessage ~= "Default theme is not set" then
                ThemeManager:SaveDefault(ThemeManager.FallbackThemeName)
            end

            local ThemeList = ThemeManager.Library.Options.ThemeManager_ThemeList
            if ThemeList then
                ThemeManager.ApplyingTheme = true
                ThemeList:SetValue(ThemeManager.FallbackThemeName)
                ThemeManager.ApplyingTheme = false
            end
        end

        if FetchErrorMessage ~= "Default theme is not set" then
            ThemeManager.Library:Notify(string.format("Default theme was unavailable. Applied %s instead.", ThemeManager.FallbackThemeLabel))
        end

        return Applied, ApplyErrorMessage
    end

    local SuccessLoad, LoadErrorMessage = ThemeManager:ApplyTheme(ThemeName)
    if not SuccessLoad then
        local FallbackSuccess, FallbackErrorMessage = ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName)
        if FallbackSuccess then
            ThemeManager:SaveDefault(ThemeManager.FallbackThemeName)
        end
        ThemeManager.Library:Notify(string.format("Failed to apply default theme. Applied %s instead.", ThemeManager.FallbackThemeLabel))
        return FallbackSuccess, FallbackErrorMessage or LoadErrorMessage
    end

    local SelectorId = ThemeManager:GetCustomTheme(ThemeName) and "ThemeManager_CustomThemeList" or "ThemeManager_ThemeList"
    local Selector = ThemeManager.Library.Options[SelectorId]
    if Selector then
        ThemeManager.ApplyingTheme = true
        Selector:SetValue(ThemeName)
        ThemeManager.ApplyingTheme = false
    end

    ThemeManager.Library:Notify(string.format("Successfully applied default theme %q", ThemeName))
    return true
end

function ThemeManager:DeleteDefaultTheme(): (boolean, string?)
    ThemeManager:CheckFolderTree()

    local DefaultThemePath = GetDefaultThemePath()
    if DefaultThemePath == false then
        return false, "Invalid path provided"
    end

    if not isfile(DefaultThemePath) then
        return false, "Default theme is not set"
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, DefaultThemePath)
    if not SuccessDelete then
        return false, ErrorMessage
    end

    ThemeManager.DefaultThemeName = nil
    return true
end


function ThemeManager:ThemeUpdate()
    if ThemeManager.ApplyingTheme or ThemeManager.ConfigLoadDepth > 0 then
        return
    end

    local Library = ThemeManager.Library

    for _, SchemeIndex in SchemeIndexes do
        local Element = Library.Options[GetThemeOptionId(SchemeIndex)]
        if not Element then continue end

        Library.Scheme[SchemeIndex] = Element.Value
    end

    Library:UpdateColorsUsingRegistry()
end

function ThemeManager:ApplyTheme(ThemeName: string)
    if IsStringEmpty(ThemeName) then
        return false, "No theme is selected"
    end

    local CustomThemeData = ThemeManager:GetCustomTheme(ThemeName)
    local Data = CustomThemeData or ThemeManager.BuiltInThemes[ThemeName]
    
    if not Data then
        return false, "Theme not found"
    end
    
    local SchemeData = Data[2]
    local ThemeData = CustomThemeData or SchemeData

    return ApplyThemeData(ThemeData, true)
end


local function ShowDialog(
    Condition: () -> boolean,

    Index: string, 
    Title: string, 
    Description: string,

    DestructiveText: string,
    DestructiveAction: () -> nil
)
    if Condition() == false then
        return DestructiveAction()
    end

    return ThemeManager.Library.Window:AddDialog(Index, {
        Title = Title,
        Description = Description,
        AutoDismiss = false,

        FooterButtons = {
            Cancel = {
                Title = "Cancel",
                Variant = "Ghost",
                Order = 1,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                end
            },

            DestructiveAction = {
                Title = DestructiveText,
                Variant = "Destructive",
                Order = 2,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                    DestructiveAction()
                end
            }
        }
    })
end

function ThemeManager:CreateThemeManager(Themesbox: any)
    assert(ThemeManager.Library, "Library is not set, call ThemeManager:SetLibrary(Library) first.")

    local BuiltInThemesNames = {}
    for Name, _ThemeData in ThemeManager.BuiltInThemes do
        table.insert(BuiltInThemesNames, Name)
    end

    local CustomThemeList, CustomThemeName, ThemeList, FontFace, BackgroundImage, DefaultThemeLabel
    local function FormatBuiltInThemeName(Value: any): any
        if Value == ThemeManager.FallbackThemeName then
            return ThemeManager.FallbackThemeLabel
        end

        return Value
    end
    local function RefreshList()
        CustomThemeList:SetValues(ThemeManager:ReloadCustomThemes())
        CustomThemeList:SetValue(nil)

        ThemeList:SetValues(BuiltInThemesNames)
    end

    local function RefreshDefaultThemeLabel()
        local DefaultThemeName, Success, ErrorMessage = ThemeManager:GetDefaultTheme()
        if not Success and ErrorMessage == "Default theme is not set" then
            DefaultThemeName = ThemeManager.FallbackThemeLabel
        elseif DefaultThemeName == ThemeManager.FallbackThemeName then
            DefaultThemeName = ThemeManager.FallbackThemeLabel
        end

        DefaultThemeLabel:SetText(string.format("Current default theme: %s", DefaultThemeName))
        if CustomThemeList then RefreshList() end
    end

    table.sort(BuiltInThemesNames, function(IndexA, IndexB)
        return ThemeManager.BuiltInThemes[IndexA][1] < ThemeManager.BuiltInThemes[IndexB][1]
    end)

    local function CreateColorOption(Text, SchemeIndex)
        local OptionId = GetThemeOptionId(SchemeIndex)
        Themesbox:AddLabel(Text):AddColorPicker(OptionId, {
            Default = ThemeManager.Library.Scheme[SchemeIndex]
        })

        return ThemeManager.Library.Options[OptionId]
    end

    local BackgroundColor = CreateColorOption("Background color", "BackgroundColor")
    local MainColor = CreateColorOption("Main color", "MainColor")
    local TopBarColor = CreateColorOption("Top bar color", "TopBarColor")
    local AccentColor = CreateColorOption("Accent color", "AccentColor")
    local OutlineColor = CreateColorOption("Outline color", "OutlineColor")
    local FontColor = CreateColorOption("Font color", "FontColor")
    local WarningColor = CreateColorOption("Warning color", "WarningColor")
    local DestructiveColor = CreateColorOption("Danger color", "DestructiveColor")
    
    local FontFaces = SupportedFontFaces
    local CurrentFontFace = "Gotham"
    local CurrentFont = ThemeManager.Library.Scheme.Font
    if typeof(CurrentFont) == "Font" then
        local CurrentFamily = string.lower(CurrentFont.Family)
        for _, FontName in FontFaces do
            if string.find(CurrentFamily, string.lower(FontName), 1, true) then
                CurrentFontFace = FontName
                break
            end
        end
    end

    Themesbox:AddDropdown("ThemeManager_FontFace", {
        Text = "Font Face",
        Default = CurrentFontFace,
        
        Values = FontFaces,
        AllowNull = false,
        Multi = false
    })
    
    Themesbox:AddInput("ThemeManager_BackgroundImage", {
        Text = "Background Image",

        Default = tostring(ThemeManager.Library.Scheme.BackgroundImage or ""),
        Finished = true,
        ClearTextOnFocus = false,
        ClearTextOnBlur = false
    })

    Themesbox:AddDivider()

    Themesbox:AddDropdown("ThemeManager_ThemeList", { 
        Text = "Theme list", 

        Values = BuiltInThemesNames,
        AllowNull = true,
        Multi = false,

        FormatDisplayValue = function(Value: any)
            local DisplayName = FormatBuiltInThemeName(Value)
            if Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", DisplayName)
            end

            return DisplayName
        end,
        FormatListValue = function(Value: any)
            local DisplayName = FormatBuiltInThemeName(Value)
            if Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", DisplayName)
            end

            return DisplayName
        end
    })

    Themesbox:AddButton("Set as default", function()
        local ThemeName = ThemeList.Value
        local Success, ErrorMessage = ThemeManager:SaveDefault(ThemeName)
        if not Success then
            ThemeManager.Library:Notify(string.format("Failed to set default theme: %s", tostring(ErrorMessage)))
            return
        end

        ThemeManager.Library:Notify(string.format("Successfully set default theme to %q", ThemeName))
        RefreshDefaultThemeLabel()
    end)

    Themesbox:AddDivider()

    CustomThemeName = Themesbox:AddInput("ThemeManager_CustomThemeName", { 
        Text = "Custom theme name" 
    })

    Themesbox:AddButton("Create theme", function()
        local Name = CustomThemeName.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Theme name cannot be empty.")
            return
        end

        if string.lower(Name) == "default" then
            ThemeManager.Library:Notify("Invalid theme name provided.")
            return
        end

        ShowDialog(
            function(): boolean
                return ThemeManager:GetCustomTheme(Name) ~= nil
            end,

            "ThemeManager_CreateTheme",
            "Theme already exists",
            string.format("A custom theme named %q already exists. Overwriting it will replace it with your current colors.", Name),

            "Overwrite",
            function()
                local Success, ErrorMessage = ThemeManager:SaveCustomTheme(Name)
                if not Success then
                    ThemeManager.Library:Notify(string.format("Failed to create theme %q: %s", Name, ErrorMessage))
                    return
                end

                ThemeManager.Library:Notify(string.format("Successfully created theme %q", Name))
                RefreshList()
            end
        )
    end)

    Themesbox:AddDivider()

    CustomThemeList = Themesbox:AddDropdown("ThemeManager_CustomThemeList", { 
        Text = "Custom themes",

        Values = ThemeManager:ReloadCustomThemes(), 
        AllowNull = true,
        Multi = false,

        FormatDisplayValue = function(Value: any)
            if Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", Value)
            end

            return Value
        end,
        FormatListValue = function(Value: any)
            if Value == ThemeManager.DefaultThemeName then
                return string.format("%s (default)", Value)
            end

            return Value
        end
    })

    Themesbox:AddButton("Load theme", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        ThemeManager:ApplyTheme(Name)
        ThemeManager.Library:Notify(string.format("Successfully loaded theme %q", Name))
    end)

    Themesbox:AddButton("Overwrite theme", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_OverwriteTheme",
            "Overwrite theme",
            string.format("Are you sure you want to overwrite %q with your current colors? This cannot be undone.", Name),

            "Overwrite",
            function()
                ThemeManager:SaveCustomTheme(Name)
                ThemeManager.Library:Notify(string.format("Successfully overwrote theme %q", Name))
            end
        )
    end)

    Themesbox:AddButton("Delete theme", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_DeleteTheme",
            "Delete theme",
            string.format("Are you sure you want to delete %q? This cannot be undone.", Name),
            
            "Delete",
            function()
                local Success, ErrorMessage = ThemeManager:Delete(Name)
                if not Success then
                    ThemeManager.Library:Notify(string.format("Failed to delete theme: %s", ErrorMessage))
                    return
                end

                ThemeManager.Library:Notify(string.format("Successfully deleted theme %q", Name))
                RefreshDefaultThemeLabel()
            end
        )
    end)

    Themesbox:AddButton("Refresh list", RefreshList)

    Themesbox:AddButton("Set as default", function()
        local Name = CustomThemeList.Value
        if IsStringEmpty(Name) then
            ThemeManager.Library:Notify("Please select a theme first.")
            return
        end

        local Success, ErrorMessage = ThemeManager:SaveDefault(Name)
        if not Success then
            ThemeManager.Library:Notify(string.format("Failed to set default theme: %s", tostring(ErrorMessage)))
            return
        end

        ThemeManager.Library:Notify(string.format("Successfully set default theme to %q", Name))
        RefreshDefaultThemeLabel()
    end)

    Themesbox:AddButton("Reset default", function()
        ShowDialog(
            function(): boolean
                return true
            end,

            "ThemeManager_ResetDefault",
            "Reset default theme",
            "Are you sure you want to clear the default theme? The library will revert to its built-in default on next load.",
            
            "Reset",
            function()
                local Success, ErrorMessage = ThemeManager:DeleteDefaultTheme()
                if not Success then
                    ThemeManager.Library:Notify(string.format("Failed to reset default theme: %s", ErrorMessage))
                    return
                end

                ThemeManager.Library:Notify("Successfully reset default theme.")
                RefreshDefaultThemeLabel()
            end
        )
    end)

    DefaultThemeLabel = Themesbox:AddLabel("Current default theme: ...", true);

    
    CustomThemeList, CustomThemeName, ThemeList, FontFace, BackgroundImage =
        ThemeManager.Library.Options.ThemeManager_CustomThemeList,
        ThemeManager.Library.Options.ThemeManager_CustomThemeName,
        ThemeManager.Library.Options.ThemeManager_ThemeList,
        ThemeManager.Library.Options.ThemeManager_FontFace,
        ThemeManager.Library.Options.ThemeManager_BackgroundImage;

    
    ThemeList:OnChanged(function()
        if ThemeManager.ApplyingTheme or ThemeManager.ConfigLoadDepth > 0 then
            return
        end

        ThemeManager:ApplyTheme(ThemeList.Value)
    end)

    local function UpdateTheme()
        if ThemeManager.ApplyingTheme then
            return
        end

        ThemeManager:ThemeUpdate()
    end

    BackgroundColor:OnChanged(UpdateTheme)
    MainColor:OnChanged(UpdateTheme)
    TopBarColor:OnChanged(UpdateTheme)
    AccentColor:OnChanged(UpdateTheme)
    OutlineColor:OnChanged(UpdateTheme)
    FontColor:OnChanged(UpdateTheme)
    WarningColor:OnChanged(UpdateTheme)
    DestructiveColor:OnChanged(UpdateTheme)
    FontFace:OnChanged(function(Value)
        if ThemeManager.ApplyingTheme or ThemeManager.ConfigLoadDepth > 0 then
            return
        end

        ThemeManager.Library:SetFont(Enum.Font[Value])
    end)
    BackgroundImage:OnChanged(function(Value)
        if ThemeManager.ApplyingTheme or ThemeManager.ConfigLoadDepth > 0 then
            return
        end

        ThemeManager.Library:SetBackgroundImage(Value)
    end)

    
    ThemeManager:LoadDefault()
    ThemeManager.AppliedToTab = true
    RefreshDefaultThemeLabel()

    return Themesbox
end

function ThemeManager:CreateGroupBox(Tab: any, IconName: string)
    return Tab:AddLeftGroupbox("Themes", IconName or "paintbrush")
end

function ThemeManager:ApplyToTab(Tab: any, IconName: string)
    local Groupbox = ThemeManager:CreateGroupBox(Tab, IconName)
    return ThemeManager:CreateThemeManager(Groupbox)
end

function ThemeManager:ApplyToGroupbox(Groupbox: any)
    return ThemeManager:CreateThemeManager(Groupbox)
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
