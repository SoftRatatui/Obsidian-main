local function IsFunction(Value: any): boolean
    return type(Value) == "function"
end

local ExecutorEnvironment = getfenv()
local function GetExecutorGlobal(Name)
    if type(ExecutorEnvironment) ~= "table" then
        return nil
    end
    local Success, Value = pcall(function()
        return ExecutorEnvironment[Name]
    end)
    return Success and Value or nil
end

local SynEnvironment = GetExecutorGlobal("syn")
local SynRequest = if type(SynEnvironment) == "table" then rawget(SynEnvironment, "request") else nil
local SynProtectGui = if type(SynEnvironment) == "table" then rawget(SynEnvironment, "protect_gui") else nil
local ExecutorRequest = GetExecutorGlobal("request") or GetExecutorGlobal("http_request") or SynRequest
local NativeIsFile = GetExecutorGlobal("isfile")
local NativeReadFile = GetExecutorGlobal("readfile")
local NativeWriteFile = GetExecutorGlobal("writefile")
local NativeIsFolder = GetExecutorGlobal("isfolder")
local NativeMakeFolder = GetExecutorGlobal("makefolder")

local function RequestGet(URL: string): (boolean, string)
    local RequestError

    if IsFunction(ExecutorRequest) then
        local Success, Response = pcall(ExecutorRequest, {
            Url = URL,
            Method = "GET",
        })

        if Success then
            local Body = typeof(Response) == "table" and (Response.Body or Response.body) or Response
            local StatusCode = typeof(Response) == "table" and (Response.StatusCode or Response.Status) or nil

            if type(Body) == "string" and #Body > 0 and (type(StatusCode) ~= "number" or (StatusCode >= 200 and StatusCode < 300)) then
                return true, Body
            end

            RequestError = string.format("request returned status %s", tostring(StatusCode or "unknown"))
        else
            RequestError = tostring(Response)
        end
    end

    local Success, Response = pcall(game.HttpGet, game, URL)
    if Success and type(Response) == "string" and #Response > 0 then
        return true, Response
    end

    return false, RequestError or tostring(Response)
end

local CloneRefValue = GetExecutorGlobal("cloneref") or GetExecutorGlobal("clonereference")
local NativeCloneRef = IsFunction(CloneRefValue) and CloneRefValue or nil
local GetHuiValue = GetExecutorGlobal("gethui")
local NativeGetHui = IsFunction(GetHuiValue) and GetHuiValue or nil
local ProtectGuiValue = GetExecutorGlobal("protectgui")
local NativeProtectGui = IsFunction(ProtectGuiValue) and ProtectGuiValue or (IsFunction(SynProtectGui) and SynProtectGui or nil)
local SetClipboardValue = GetExecutorGlobal("setclipboard")
local NativeSetClipboard = IsFunction(SetClipboardValue) and SetClipboardValue or nil
local SetHiddenPropertyValue = GetExecutorGlobal("sethiddenproperty")
local NativeSetHiddenProperty = IsFunction(SetHiddenPropertyValue) and SetHiddenPropertyValue or nil
local SetScriptableValue = GetExecutorGlobal("setscriptable")
local NativeSetScriptable = IsFunction(SetScriptableValue) and SetScriptableValue or nil
local GetCustomAssetValue = GetExecutorGlobal("getcustomasset")
local NativeGetCustomAsset = IsFunction(GetCustomAssetValue) and GetCustomAssetValue or nil
local LoadStringValue = GetExecutorGlobal("loadstring")
local NativeLoadString = IsFunction(LoadStringValue) and LoadStringValue or nil

local cloneref = (NativeCloneRef or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))
local HttpService: HttpService = cloneref(game:GetService("HttpService"))

local NativeGetGenv = GetExecutorGlobal("getgenv")
local getgenv = IsFunction(NativeGetGenv) and NativeGetGenv or function()
    return if typeof(shared) == "table" then shared else _G
end
local setclipboard = NativeSetClipboard
local protectgui = NativeProtectGui or function() end
local gethui = NativeGetHui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139785960036434,
        Path = "Obsidian/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "Obsidian/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    },

    LoadingIcon = {
        RobloxId = 97544096941083,
        Path = "Obsidian/assets/LoadingIcon.png",
        URL = BaseURL .. "assets/LoadingIcon.png",

        Id = nil,
    },

}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                local Created = pcall(makefolder, TraversedPath .. Segment)
                if not Created and not isfolder(TraversedPath .. Segment) then
                    return nil
                end
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(
        AssetName: string,
        RobloxAssetId: number,
        URL: string,
        ForceRedownload: boolean?
    )
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            local Downloaded, Content = RequestGet(AssetData.URL)
            if not Downloaded then
                error(Content)
            end
            writefile(AssetData.Path, Content)
        end)

        return success, errorMessage
    end

    function CustomImageManager.PreloadAssets()
        for AssetName in CustomImageManagerAssets do
            task.defer(CustomImageManager.DownloadAsset, AssetName)
        end
    end
end

local Library = {
    ReleaseVersion = "0.0.1-release-3",
    LocalPlayer = LocalPlayer,
    IsRobloxFocused = true,

    
    DevicePlatform = nil,
    IsMobile = false,

    
    ScreenGui = nil,
    Window = nil,
    WindowContainer = nil,

    
    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    LastSearchTab = nil,
    SearchDebounce = 0.06,

    
    ActiveTab = nil,
    Tabs = {},
    TabButtons = {},

    
    DependencyBoxes = {},

    
    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},
    KeybindMenuRequested = false,
    KeybindMenuVisible = false,
    KeybindMenuTweenInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    KeybindRowTweenInfo = TweenInfo.new(0.075, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    ActiveTweens = setmetatable({}, { __mode = "k" }),

    
    Notifications = {},
    NotifySide = "Right",
    NotifyTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    NotifyCloseTweenInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotificationStyle = {
        Width = 260,
        Margin = 8,
        Gap = 5,
        Padding = 7,
        CornerRadius = 4,
        TextSize = 12,
        TitleTextSize = 12,
        DescriptionTextSize = 11,
        MaxVisible = 4,
        DefaultDuration = 3.5,
        Accent = false,
        ShowProgress = false,
        Dismissible = false,
    },

    
    Dialogues = {},
    ActiveDialog = nil,

    
    ActiveLoading = nil,

    
    Corners = {},
    SpecificCorners = {},

    
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    HoverTweenInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    TabTransitionInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    TabExitTransitionInfo = TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabSwipeOffset = 2,
    TabSwipeFrom = "auto",

    WindowAnimationInfo = TweenInfo.new(0.06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    WindowOpenAnimationInfo = TweenInfo.new(0.085, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    WindowCloseAnimationInfo = TweenInfo.new(0.055, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DialogOverlayOpenAnimationInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    DialogOpenAnimationInfo = TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    DialogOverlayCloseAnimationInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DialogCloseAnimationInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    DropdownTransitionInfo = TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    KeyPickerTransitionInfo = TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),

    GroupboxTweenInfo = TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    RotatingChevronTweenInfo = TweenInfo.new(0.09, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),

    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true
    },

    
    Toggled = false,
    Unloaded = false,

    
    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    
    ToggleKeybind = Enum.KeyCode.RightControl,
    ShowToggleFrameInKeybinds = true,

    NotifyOnError = false,
    ShowCustomCursor = true,
    ForceCheckbox = true,
    TooltipsEnabled = false,
    AppearanceLocked = false,
    ThemeFontOverride = nil,

    CantDragForced = false,
    DraggableElements = {},

    
    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 8,
    DesignRevision = 0,
    Design = {
        Effects = {
            Shadows = false,
            Dividers = false,
            NavigationIndicator = false,
            AccentScrollbars = false,
            ThemeGeometry = false,
        },
        Spacing = {
            Tiny = 3,
            Small = 6,
            Medium = 9,
            Large = 13,
            Section = 12,
        },
        Radius = {
            Window = 8,
            Card = 6,
            Control = 5,
            Popup = 6,
            Indicator = 3,
        },
        Size = {
            TopBar = 52,
            Footer = 22,
            GroupHeader = 38,
            Control = 28,
            Row = 24,
            Icon = 16,
            Text = 14,
            Caption = 12,
        },
        Grid = {
            Row = 24,
            RowGap = 9,
            Indicator = 16,
            IndicatorGap = 9,
            Swatch = 16,
            LabelRow = 18,
            TrackRow = 14,
            Track = 4,
            Thumb = 10,
            ThumbHover = 12,
            ControlGap = 4,
        },
        Stroke = {
            Thickness = 1,
            SoftTransparency = 0.46,
            ControlTransparency = 0.38,
            StrongTransparency = 0.18,
        },
        Opacity = {
            MutedText = 0.38,
            DisabledText = 0.78,
            Divider = 0.62,
            Shadow = 0.44,
            Hover = 0.08,
        },
        Shell = {
            SidebarMin = 184,
            SidebarMax = 214,
            SidebarRatio = 0.255,
            NavigationHeight = 38,
            NavigationGap = 5,
            NavigationPadding = 7,
            NavigationInset = 0,
            ContentPadding = 12,
            SearchHeight = 32,
            HeaderControl = 32,
            HeaderGap = 8,
            ScrollbarThickness = 2,
        },
        Typography = {
            WindowTitle = 16,
            Navigation = 14,
            SectionTitle = 14,
            Body = 14,
            Caption = 12,
        },
        Motion = {
            Scale = 1,
            Reduced = false,
            Hover = { 0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
            Control = { 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
            Fast = { 0.07, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
            Popup = { 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
            Dialog = { 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
            WindowOpen = { 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
            WindowClose = { 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
            TabEnter = { 0.09, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
            TabExit = { 0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
            Notify = { 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
            NotifyClose = { 0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
            TextReveal = { 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
        },
        Addon = {
            HeaderHeight = 38,
            Padding = 10,
            Gap = 8,
            Radius = 6,
            OutlineTransparency = 0.5,
            BackgroundTransparency = 0,
            ControlHeight = 28,
            WindowWidth = 420,
            WindowHeight = 480,
            CellRadius = 5,
            CellPadding = 6,
            SelectionThickness = 1,
            PreviewRatio = 0.58,
            Motion = true,
        },
    },

    
    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(17, 19, 22),
        MainColor = Color3.fromRGB(31, 34, 39),
        TopBarColor = Color3.fromRGB(29, 32, 37),
        SurfaceColor = Color3.fromRGB(23, 25, 29),
        RaisedColor = Color3.fromRGB(29, 32, 37),
        ElementColor = Color3.fromRGB(31, 34, 39),
        HoverColor = Color3.fromRGB(38, 42, 49),
        AccentColor = Color3.fromRGB(162, 154, 232),
        AccentSoftColor = Color3.fromRGB(41, 42, 58),
        OutlineColor = Color3.fromRGB(52, 57, 66),
        FontColor = Color3.fromRGB(238, 240, 244),
        MutedFontColor = Color3.fromRGB(146, 151, 160),
        ShadowColor = Color3.fromRGB(5, 6, 8),
        Font = Font.fromEnum(Enum.Font.GothamMedium),

        RedColor = Color3.fromRGB(232, 83, 103),
        WarningColor = Color3.fromRGB(208, 157, 80),
        DestructiveColor = Color3.fromRGB(196, 58, 76),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.fromRGB(248, 249, 252),

        BackgroundImage = ""
    },

	Registry = {},
	ThemeListeners = {},
	ColorRevision = 0,
	Scales = {},
	ScalesOffset = {},
	ScaleMultipliers = setmetatable({}, { __mode = "k" }),

    
    ImageManager = CustomImageManager,
    ShowCursorBinding = string.sub(tostring({}), 10),

    Notify = nil, Toggle = nil 
}

function Library:Fetch(URL: string): (boolean, string)
    assert(type(URL) == "string" and #URL > 0, "Expected a non-empty URL")
    return RequestGet(URL)
end

local FontHeaders = {
    ["\0\1\0\0"] = true,
    OTTO = true,
    ["true"] = true,
    ttcf = true,
    wOFF = true,
}

local FontWeights = {
    [100] = Enum.FontWeight.Thin,
    [200] = Enum.FontWeight.ExtraLight,
    [300] = Enum.FontWeight.Light,
    [400] = Enum.FontWeight.Regular,
    [500] = Enum.FontWeight.Medium,
    [600] = Enum.FontWeight.SemiBold,
    [700] = Enum.FontWeight.Bold,
    [800] = Enum.FontWeight.ExtraBold,
    [900] = Enum.FontWeight.Heavy,
}

local function ResolveFontWeight(Weight)
    local Numeric = math.clamp(math.floor((tonumber(Weight) or 400) / 100 + 0.5) * 100, 100, 900)
    return Numeric, FontWeights[Numeric] or Enum.FontWeight.Regular
end

local function IsFontData(Data)
    return type(Data) == "string" and #Data >= 4096 and FontHeaders[string.sub(Data, 1, 4)] == true
end

local function EnsureFontFolder(Path)
    if not IsFunction(NativeIsFolder) or not IsFunction(NativeMakeFolder) then
        return false
    end

    local Current = ""
    for Segment in string.gmatch(Path, "[^/]+") do
        Current = Current == "" and Segment or Current .. "/" .. Segment
        if not NativeIsFolder(Current) then
            local Created = pcall(NativeMakeFolder, Current)
            if not Created and not NativeIsFolder(Current) then
                return false
            end
        end
    end

    return true
end

function Library:LoadCustomFont(Name: string, URL: string, Weight: number?): (Font?, string?)
    if type(Name) ~= "string" or Name:match("%S") == nil then
        return nil, "Font name must be a non-empty string"
    end
    if type(URL) ~= "string" or URL:match("^https?://") == nil then
        return nil, "Font URL must use HTTP or HTTPS"
    end
    if not IsFunction(NativeIsFile) or not IsFunction(NativeWriteFile) or not IsFunction(NativeGetCustomAsset) then
        return nil, "Custom font filesystem APIs are unavailable"
    end
    if not EnsureFontFolder("MonHub/assets") then
        return nil, "Unable to create the font cache folder"
    end

    local SafeName = Name:gsub("[^%w_%-]", "_")
    local FontPath = "MonHub/assets/" .. SafeName .. ".ttf"
    local MetadataPath = "MonHub/assets/" .. SafeName .. ".json"
    local ShouldDownload = not NativeIsFile(FontPath)

    if not ShouldDownload and IsFunction(NativeReadFile) then
        local Read, CachedData = pcall(NativeReadFile, FontPath)
        ShouldDownload = not Read or not IsFontData(CachedData)
    end

    if ShouldDownload then
        local Downloaded, FontData = RequestGet(URL)
        if not Downloaded or not IsFontData(FontData) then
            return nil, "Downloaded data is not a valid font"
        end
        local Written, WriteError = pcall(NativeWriteFile, FontPath, FontData)
        if not Written then
            return nil, tostring(WriteError)
        end
    end

    local FontAssetSuccess, FontAsset = pcall(NativeGetCustomAsset, FontPath)
    if not FontAssetSuccess or type(FontAsset) ~= "string" then
        return nil, tostring(FontAsset)
    end

    local FaceWeight, FontWeight = ResolveFontWeight(Weight)
    local Metadata = HttpService:JSONEncode({
        name = Name,
        faces = {
            {
                name = "Regular",
                weight = FaceWeight,
                style = "normal",
                assetId = FontAsset,
            },
        },
    })
    local MetadataWritten, MetadataError = pcall(NativeWriteFile, MetadataPath, Metadata)
    if not MetadataWritten then
        return nil, tostring(MetadataError)
    end

    local MetadataAssetSuccess, MetadataAsset = pcall(NativeGetCustomAsset, MetadataPath)
    if not MetadataAssetSuccess or type(MetadataAsset) ~= "string" then
        return nil, tostring(MetadataAsset)
    end

    local Created, FontFace = pcall(Font.new, MetadataAsset, FontWeight, Enum.FontStyle.Normal)
    if not Created or typeof(FontFace) ~= "Font" then
        return nil, tostring(FontFace)
    end

    return FontFace
end

function Library:SetThemeFont(FontFace): any
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end
    assert(typeof(FontFace) == "Font", "Font or Enum.Font expected")
    Library.ThemeFontOverride = FontFace
    Library:SetFont(FontFace)
    return Library
end

Library.CurrentFontName = "Inter"
Library.FontPresets = {
    { Name = "Inter", Bundled = true },
    { Name = "Builder Sans", Family = "rbxasset://fonts/families/BuilderSans.json", Weight = Enum.FontWeight.Medium },
    { Name = "Gotham", Family = "rbxasset://fonts/families/GothamSSm.json", Weight = Enum.FontWeight.Medium },
    { Name = "Montserrat", Family = "rbxasset://fonts/families/Montserrat.json", Weight = Enum.FontWeight.Medium },
    { Name = "Montserrat Bold", Download = true },
    { Name = "Inter 28pt Medium", Download = true },
    { Name = "Inter 28pt SemiBold", Download = true },
    { Name = "Minecraftia", Download = true },
    { Name = "Proggy Tiny", Download = true },
    { Name = "Verdana", Download = true },
    { Name = "Tahoma 8px", Download = true },
    { Name = "Smallest Pixel 7", Download = true },
    { Name = "Tahoma Bold", Download = true },
    { Name = "Roboto", Family = "rbxasset://fonts/families/Roboto.json", Weight = Enum.FontWeight.Medium },
    { Name = "Source Sans", Family = "rbxasset://fonts/families/SourceSansPro.json", Weight = Enum.FontWeight.SemiBold },
    { Name = "Ubuntu", Family = "rbxasset://fonts/families/Ubuntu.json", Weight = Enum.FontWeight.Regular },
    { Name = "Roboto Mono", Family = "rbxasset://fonts/families/RobotoMono.json", Weight = Enum.FontWeight.Medium },
}

function Library:LoadBundledFont(Name: string): (Font?, string?)
    local Cached = Library.BundledFontCache[Name]
    if Cached ~= nil then
        if Cached == false then
            return nil, "Font previously failed to load"
        end
        return Cached
    end

    local Entry = Library.BundledFonts[Name]
    if not Entry then
        return nil, "Unknown bundled font: " .. tostring(Name)
    end

    local URL = Entry.URL
    if not URL then
        URL = Library.BundledFontBaseURL .. Entry.File
    end
    URL ..= (string.find(URL, "?", 1, true) and "&monhub=" or "?monhub=") .. tostring(Library.ReleaseVersion)

    local Face, Reason = Library:LoadCustomFont(
        Entry.Name,
        URL,
        Entry.Weight
    )

    Library.BundledFontCache[Name] = Face or false
    return Face, Reason
end

function Library:GetFontNames(): { string }
    local Names = {}
    for _, Preset in Library.FontPresets do
        if Preset.Bundled then
            if Library.DefaultFont and not Library.DefaultFontError then
                table.insert(Names, Preset.Name)
            end
        elseif Preset.Download then
            if Library.BundledFontCache[Preset.Name] ~= false then
                table.insert(Names, Preset.Name)
            end
        else
            local Success = pcall(Font.new, Preset.Family, Preset.Weight or Enum.FontWeight.Medium)
            if Success then
                table.insert(Names, Preset.Name)
            end
        end
    end
    return Names
end

function Library:GetFontPreset(Name: string): Font?
    for _, Preset in Library.FontPresets do
        if Preset.Name == Name then
            if Preset.Bundled then
                if Library.DefaultFontError then
                    return nil
                end
                return Library.DefaultFont
            end
            if Preset.Download then
                return (Library:LoadBundledFont(Preset.Name))
            end
            local Success, Value = pcall(Font.new, Preset.Family, Preset.Weight or Enum.FontWeight.Medium)
            if Success then
                return Value
            end
            return nil
        end
    end
    return nil
end

function Library:SetFontByName(Name: string): boolean
    local FontFace = Library:GetFontPreset(Name)
    if not FontFace then
        return false
    end

    Library.CurrentFontName = Name
    Library:SetThemeFont(FontFace)
    return true
end

Library.DefaultFontName = "MonHubInterMedium"
Library.DefaultFontURL = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/assets/Inter-Medium.ttf?monhub=0.0.1-release-3-font-default"
Library.DefaultFontWeight = 500
Library.DefaultFont = nil
Library.DefaultFontError = nil

Library.BundledFontBaseURL = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/assets/"
Library.StorageFontBaseURL = "https://raw.githubusercontent.com/i77lhm/storage/main/fonts/"
Library.BundledFonts = {
    ["Montserrat Bold"] = { File = "Montserrat-Bold.ttf", Name = "MonHubMontserratBold", Weight = 700 },
    ["Inter 28pt Medium"] = { URL = Library.StorageFontBaseURL .. "Inter_28pt-Medium.ttf", Name = "MonHubInter28Medium", Weight = 500 },
    ["Inter 28pt SemiBold"] = { URL = Library.StorageFontBaseURL .. "Inter_28pt-SemiBold.ttf", Name = "MonHubInter28SemiBold", Weight = 600 },
    ["Minecraftia"] = { URL = Library.StorageFontBaseURL .. "Minecraftia-Regular.ttf", Name = "MonHubMinecraftia", Weight = 400 },
    ["Proggy Tiny"] = { URL = Library.StorageFontBaseURL .. "ProggyTiny.ttf", Name = "MonHubProggyTiny", Weight = 400 },
    ["Verdana"] = { URL = Library.StorageFontBaseURL .. "Verdana-Font.ttf", Name = "MonHubVerdana", Weight = 400 },
    ["Tahoma 8px"] = { URL = Library.StorageFontBaseURL .. "fs-tahoma-8px.ttf", Name = "MonHubTahoma8px", Weight = 400 },
    ["Smallest Pixel 7"] = { URL = Library.StorageFontBaseURL .. "smallest_pixel-7.ttf", Name = "MonHubSmallestPixel7", Weight = 400 },
    ["Tahoma Bold"] = { URL = Library.StorageFontBaseURL .. "tahoma_bold.ttf", Name = "MonHubTahomaBold", Weight = 700 },
}
Library.BundledFontCache = {}

Library.DefaultTheme = "Default"
Library.CurrentTheme = "Default"
Library.Themes = {
    Default = {
        BackgroundColor = Color3.fromRGB(17, 19, 22),
        MainColor = Color3.fromRGB(31, 34, 39),
        TopBarColor = Color3.fromRGB(29, 32, 37),
        SurfaceColor = Color3.fromRGB(23, 25, 29),
        RaisedColor = Color3.fromRGB(29, 32, 37),
        ElementColor = Color3.fromRGB(31, 34, 39),
        HoverColor = Color3.fromRGB(38, 42, 49),
        AccentColor = Color3.fromRGB(162, 154, 232),
        AccentSoftColor = Color3.fromRGB(41, 42, 58),
        OutlineColor = Color3.fromRGB(52, 57, 66),
        FontColor = Color3.fromRGB(238, 240, 244),
        MutedFontColor = Color3.fromRGB(146, 151, 160),
        ShadowColor = Color3.fromRGB(5, 6, 8),
        WarningColor = Color3.fromRGB(208, 157, 80),
        DestructiveColor = Color3.fromRGB(196, 58, 76),
        RedColor = Color3.fromRGB(232, 83, 103),
        DarkColor = Color3.new(0, 0, 0),
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        WhiteColor = Color3.fromRGB(248, 249, 252),
        BackgroundImage = "",
        CornerRadius = 8,
        IsLight = false,
    },
    Metal = {
        BackgroundColor = Color3.fromRGB(14, 14, 18),
        MainColor = Color3.fromRGB(33, 31, 43),
        TopBarColor = Color3.fromRGB(28, 26, 36),
        SurfaceColor = Color3.fromRGB(21, 20, 27),
        RaisedColor = Color3.fromRGB(28, 26, 36),
        ElementColor = Color3.fromRGB(33, 31, 43),
        HoverColor = Color3.fromRGB(43, 40, 55),
        AccentColor = Color3.fromRGB(140, 136, 201),
        AccentSoftColor = Color3.fromRGB(45, 41, 58),
        OutlineColor = Color3.fromRGB(56, 52, 67),
        FontColor = Color3.fromRGB(240, 240, 244),
        MutedFontColor = Color3.fromRGB(154, 149, 163),
        ShadowColor = Color3.fromRGB(5, 5, 8),
        WarningColor = Color3.fromRGB(214, 163, 83),
        DestructiveColor = Color3.fromRGB(204, 65, 86),
        RedColor = Color3.fromRGB(235, 91, 115),
        DarkColor = Color3.fromRGB(9, 9, 11),
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        WhiteColor = Color3.fromRGB(248, 248, 250),
        BackgroundImage = "",
        CornerRadius = 8,
        IsLight = false,
    },
    Midnight = {
        BackgroundColor = Color3.fromRGB(10, 13, 18),
        MainColor = Color3.fromRGB(25, 32, 42),
        TopBarColor = Color3.fromRGB(21, 27, 36),
        SurfaceColor = Color3.fromRGB(15, 20, 27),
        RaisedColor = Color3.fromRGB(21, 27, 36),
        ElementColor = Color3.fromRGB(25, 32, 42),
        HoverColor = Color3.fromRGB(33, 42, 55),
        AccentColor = Color3.fromRGB(116, 132, 154),
        AccentSoftColor = Color3.fromRGB(31, 39, 50),
        OutlineColor = Color3.fromRGB(44, 55, 69),
        FontColor = Color3.fromRGB(233, 238, 245),
        MutedFontColor = Color3.fromRGB(134, 146, 162),
        ShadowColor = Color3.fromRGB(3, 4, 6),
        WarningColor = Color3.fromRGB(203, 154, 77),
        DestructiveColor = Color3.fromRGB(191, 63, 81),
        RedColor = Color3.fromRGB(226, 82, 102),
        DarkColor = Color3.fromRGB(5, 6, 8),
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        WhiteColor = Color3.fromRGB(248, 249, 252),
        BackgroundImage = "",
        CornerRadius = 8,
        IsLight = false,
    },
    Steel = {
        BackgroundColor = Color3.fromRGB(16, 20, 24),
        MainColor = Color3.fromRGB(30, 38, 46),
        TopBarColor = Color3.fromRGB(26, 33, 40),
        SurfaceColor = Color3.fromRGB(21, 27, 32),
        RaisedColor = Color3.fromRGB(26, 33, 40),
        ElementColor = Color3.fromRGB(30, 38, 46),
        HoverColor = Color3.fromRGB(39, 51, 61),
        AccentColor = Color3.fromRGB(120, 148, 174),
        AccentSoftColor = Color3.fromRGB(38, 50, 60),
        OutlineColor = Color3.fromRGB(52, 66, 78),
        FontColor = Color3.fromRGB(234, 240, 244),
        MutedFontColor = Color3.fromRGB(143, 156, 166),
        ShadowColor = Color3.fromRGB(5, 8, 10),
        WarningColor = Color3.fromRGB(203, 157, 87),
        DestructiveColor = Color3.fromRGB(192, 67, 82),
        RedColor = Color3.fromRGB(225, 86, 105),
        DarkColor = Color3.fromRGB(6, 9, 12),
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        WhiteColor = Color3.fromRGB(246, 249, 251),
        BackgroundImage = "",
        CornerRadius = 8,
        IsLight = false,
    },
    Sage = {
        BackgroundColor = Color3.fromRGB(17, 21, 18),
        MainColor = Color3.fromRGB(32, 42, 36),
        TopBarColor = Color3.fromRGB(27, 35, 30),
        SurfaceColor = Color3.fromRGB(23, 29, 25),
        RaisedColor = Color3.fromRGB(27, 35, 30),
        ElementColor = Color3.fromRGB(32, 42, 36),
        HoverColor = Color3.fromRGB(41, 54, 46),
        AccentColor = Color3.fromRGB(134, 163, 148),
        AccentSoftColor = Color3.fromRGB(41, 55, 47),
        OutlineColor = Color3.fromRGB(56, 72, 63),
        FontColor = Color3.fromRGB(237, 242, 239),
        MutedFontColor = Color3.fromRGB(146, 159, 152),
        ShadowColor = Color3.fromRGB(5, 8, 6),
        WarningColor = Color3.fromRGB(205, 158, 86),
        DestructiveColor = Color3.fromRGB(192, 69, 80),
        RedColor = Color3.fromRGB(225, 88, 104),
        DarkColor = Color3.fromRGB(7, 10, 8),
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        WhiteColor = Color3.fromRGB(247, 250, 248),
        BackgroundImage = "",
        CornerRadius = 8,
        IsLight = false,
    },
    Ash = {
        BackgroundColor = Color3.fromRGB(18, 16, 14),
        MainColor = Color3.fromRGB(37, 33, 28),
        TopBarColor = Color3.fromRGB(31, 28, 24),
        SurfaceColor = Color3.fromRGB(25, 22, 19),
        RaisedColor = Color3.fromRGB(31, 28, 24),
        ElementColor = Color3.fromRGB(37, 33, 28),
        HoverColor = Color3.fromRGB(48, 43, 36),
        AccentColor = Color3.fromRGB(165, 151, 133),
        AccentSoftColor = Color3.fromRGB(46, 41, 34),
        OutlineColor = Color3.fromRGB(62, 55, 46),
        FontColor = Color3.fromRGB(241, 239, 235),
        MutedFontColor = Color3.fromRGB(151, 146, 139),
        ShadowColor = Color3.fromRGB(7, 6, 5),
        WarningColor = Color3.fromRGB(205, 158, 86),
        DestructiveColor = Color3.fromRGB(194, 67, 79),
        RedColor = Color3.fromRGB(227, 87, 103),
        DarkColor = Color3.fromRGB(9, 8, 7),
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        WhiteColor = Color3.fromRGB(249, 247, 243),
        BackgroundImage = "",
        CornerRadius = 8,
        IsLight = false,
    },
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.OriginalMinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.OriginalMinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)

    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local function GetViewportSize()
    local Camera = workspace.CurrentCamera
    local Success, ViewportSize = pcall(function()
        return Camera and Camera.ViewportSize
    end)
    if Success and typeof(ViewportSize) == "Vector2" and ViewportSize.X > 0 and ViewportSize.Y > 0 then
        return ViewportSize
    end

    return Vector2.new(1280, 720)
end

local Templates = {
    
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
        ClipsDescendants = true,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = "MutedFontColor",
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        BorderStrokePosition = Enum.BorderStrokePosition.Inner,
        LineJoinMode = Enum.LineJoinMode.Round,
    },

    
    Window = {
        Title = "No Title",
        Footer = "No Footer",

        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(780, 640),
        IconSize = UDim2.fromOffset(30, 30),

        AutoShow = true,
        Center = true,
        Resizable = true,
        AlwaysOnTop = false,

        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,

        CornerRadius = 8,
        NotifySide = "Right",
        ShowCustomCursor = true,

        Font = Enum.Font.GothamMedium,
        ToggleKeybind = Enum.KeyCode.RightControl,

        ShowCompactLauncher = true,
        CompactLauncherIcon = "maximize-2",
        CompactLauncherSize = 36,
        CompactLauncherWidth = 172,
        CompactLauncherTitle = nil,
        CompactLauncherPosition = UDim2.fromScale(0.5, 0.5),
        CompactLauncherAnchorPoint = Vector2.new(0.5, 0.5),
        CompactLauncherDraggable = true,

        ShowMobileButtons = true,
        MobileButtonsSide = "Left",

        UnlockMouseWhileOpen = true,

        EnableSidebarResize = false,
        EnableCompacting = true,
        DisableCompactingSnap = false,
        SidebarCompacted = false,
        MinContainerWidth = 256,
        ResponsiveLayout = true,
        SingleColumnWidth = 540,
        HideSearchAtWidth = 210,

        
        MinSidebarWidth = 128,
        SidebarCompactWidth = 48,
        SidebarCollapseThreshold = 0.5,

        
        CompactWidthActivation = 128,

        
        BackgroundImage = "",

        
        Animations = {
            ToggleWindow = true,
            TabSwitch = true,
            Groupbox = true,
            Dropdown = true,
            KeyPicker = true
        },

        TabTransitionTime = 0.085,
        TabSwipeOffset = 10,
        TabSwipeFrom = "auto"
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        FooterButtons = {}
    },
    Loading = {
        Title = "mspaint",
        Icon = 95816097006870,
        IconSize = UDim2.fromOffset(30, 30),

        LoadingIcon = CustomImageManager.GetAsset("LoadingIcon"),
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,

        CurrentStep = 0,
        TotalSteps = 10,

        ShowSidebar = false,
        AutoResizeHeight = false,
        AlwaysOnTop = true,

        WindowWidth = 450,
        WindowHeight = 275,

        ContentWidth = 450,
        SidebarWidth = 250,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        ConfirmDanger = true,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        ClearTextOnBlur = false,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "None",

        Callback = function() end,
        Changed = function() end,
        VerifyValue = nil,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,

        AllowRightClickInput = true
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        ValueImages = {},

        Multi = false,
        DragSelect = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        OutlineTransparency = 0.46,
        OutlineThickness = 1,
        CornerRadius = 4,
        Padding = 6,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        ImageSize = UDim2.fromScale(1, 1),
        ImagePosition = UDim2.fromScale(0.5, 0.5),
        ImageAnchorPoint = Vector2.new(0.5, 0.5),
        ImageScale = 1,
        TileSize = UDim2.fromOffset(64, 64),
        Rotation = 0,
        AspectRatio = 0,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    
    KeyPicker = {
        Text = "KeyPicker",

        Default = "None",
        DefaultModifiers = {},

        Blacklisted = {},
        BlacklistedModifiers = {},
        Whitelisted = {},
        WhitelistedModifiers = {},

        Mode = "Toggle",
        Modes = { "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Resizable = true,

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}


local SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark"
}

local SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(Index)
    if not Index then
        return nil
    end

    local ReplaceAliasIndex = SchemeReplaceAlias[Index]
    if ReplaceAliasIndex and Library.Scheme[Index] == nil and Library.Scheme[ReplaceAliasIndex] ~= nil then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil

        return Library.Scheme[Index]
    end

    local AliasIndex = SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        warn(string.format("Scheme Value %q is deprecated, please use %q instead.", Index, AliasIndex))
        return Library.Scheme[AliasIndex]
    end

    return Library.Scheme[Index]
end

local function CloneDesignValue(Value)
    if type(Value) ~= "table" then
        return Value
    end

    local Result = {}
    for Key, Child in Value do
        Result[Key] = CloneDesignValue(Child)
    end
    return Result
end

local function MergeDesign(Target, Source)
    if type(Source) ~= "table" then
        return Target
    end

    for Key, Value in Source do
        if type(Value) == "table" and type(Target[Key]) == "table" then
            MergeDesign(Target[Key], Value)
        else
            Target[Key] = CloneDesignValue(Value)
        end
    end
    return Target
end

function Library:GetDesignToken(Path: string, Fallback: any): any
    if type(Path) ~= "string" or Path == "" then
        return Fallback
    end

    local Value = Library.Design
    for Segment in string.gmatch(Path, "[^%.]+") do
        if type(Value) ~= "table" then
            return Fallback
        end
        Value = Value[Segment]
        if Value == nil then
            return Fallback
        end
    end
    return Value
end

function Library:Metric(Name: string, Fallback: number): number
    local Value = tonumber(Library:GetDesignToken("Grid." .. Name, Fallback)) or Fallback
    return math.max(0, math.round(Value))
end

function Library:Snap(Value: number): number
    return math.round(tonumber(Value) or 0)
end

function Library:CenterOffset(Outer: number, Inner: number): number
    return math.round((Outer - Inner) * 0.5)
end

function Library:MatchParity(Outer: number, Inner: number): number
    local Size = math.max(0, math.round(Inner))
    if (math.round(Outer) - Size) % 2 ~= 0 then
        Size += 1
    end
    return Size
end

function Library:GetMotion(Name: string): TweenInfo
    local Motion = Library.Design.Motion
    local Spec = type(Motion[Name]) == "table" and Motion[Name] or Motion.Control
    if type(Spec) ~= "table" then
        Spec = { 0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out }
    end
    local Duration = tonumber(Spec[1]) or 0.1
    local Scale = math.max(tonumber(Motion.Scale) or 1, 0)
    if Motion.Reduced == true then
        Duration = 0
    else
        Duration *= Scale
    end
    return TweenInfo.new(Duration, Spec[2] or Enum.EasingStyle.Quint, Spec[3] or Enum.EasingDirection.Out)
end

function Library:RefreshMotion()
    Library.HoverTweenInfo = Library:GetMotion("Hover")
    Library.TweenInfo = Library:GetMotion("Control")
    Library.KeybindMenuTweenInfo = Library:GetMotion("Fast")
    Library.KeybindRowTweenInfo = Library:GetMotion("Hover")
    Library.NotifyTweenInfo = Library:GetMotion("Notify")
    Library.NotifyCloseTweenInfo = Library:GetMotion("NotifyClose")
    Library.TabTransitionInfo = Library:GetMotion("TabEnter")
    Library.TabExitTransitionInfo = Library:GetMotion("TabExit")
    Library.WindowAnimationInfo = Library:GetMotion("Fast")
    Library.WindowOpenAnimationInfo = Library:GetMotion("WindowOpen")
    Library.WindowCloseAnimationInfo = Library:GetMotion("WindowClose")
    Library.DialogOverlayOpenAnimationInfo = Library:GetMotion("Control")
    Library.DialogOpenAnimationInfo = Library:GetMotion("Dialog")
    Library.DialogOverlayCloseAnimationInfo = Library:GetMotion("Hover")
    Library.DialogCloseAnimationInfo = Library:GetMotion("Control")
    Library.DropdownTransitionInfo = Library:GetMotion("Popup")
    Library.KeyPickerTransitionInfo = Library:GetMotion("Popup")
    Library.GroupboxTweenInfo = Library:GetMotion("Popup")
    Library.RotatingChevronTweenInfo = Library:GetMotion("Control")
end

function Library:SetDesign(Overrides)
    assert(type(Overrides) == "table", "Design overrides must be a table")
    MergeDesign(Library.Design, Overrides)
    Library.DesignRevision += 1
    Library:RefreshMotion()

    local Radius = tonumber(Library:GetDesignToken("Radius.Window", Library.CornerRadius))
    if Radius then
        Radius = math.clamp(Radius, 0, 20)
        Templates.Window.CornerRadius = Radius
        if Library.Window and type(Library.Window.SetCornerRadius) == "function" then
            Library.Window:SetCornerRadius(Radius)
        else
            Library.CornerRadius = Radius
        end
    end

    Library:UpdateColorsUsingRegistry()
    Library:RefreshThemeState()
    return Library
end

function Library:SetReducedMotion(Enabled: boolean)
    Library.Design.Motion.Reduced = Enabled == true
    Library:RefreshMotion()
    return Library
end

function Library:GetAddonStyle(Overrides)
    local Style = CloneDesignValue(Library.Design.Addon)
    Style._Overrides = Overrides and (Overrides._Overrides or Overrides) or {}
    Style.Spacing = CloneDesignValue(Library.Design.Spacing)
    Style.Radius = tonumber(Style.Radius) or Library:GetDesignToken("Radius.Card", 7)
    Style.ControlRadius = Library:GetDesignToken("Radius.Control", 4)
    Style.PopupRadius = Library:GetDesignToken("Radius.Popup", 6)
    Style.TextSize = Library:GetDesignToken("Size.Text", 14)
    Style.CaptionSize = Library:GetDesignToken("Size.Caption", 12)
    Style.StrokeThickness = Library:GetDesignToken("Stroke.Thickness", 1)
    MergeDesign(Style, Overrides)
    Style.HeaderHeight = math.clamp(tonumber(Style.HeaderHeight) or 38, 28, 56)
    Style.Padding = math.clamp(tonumber(Style.Padding) or 10, 0, 24)
    Style.Gap = math.clamp(tonumber(Style.Gap) or 8, 0, 20)
    Style.Radius = math.clamp(tonumber(Style.Radius) or 7, 0, 16)
    Style.ControlRadius = math.clamp(tonumber(Style.ControlRadius) or 4, 0, 12)
    Style.PopupRadius = math.clamp(tonumber(Style.PopupRadius) or 7, 0, 16)
    Style.OutlineTransparency = math.clamp(tonumber(Style.OutlineTransparency) or 0.5, 0, 1)
    Style.BackgroundTransparency = math.clamp(tonumber(Style.BackgroundTransparency) or 0, 0, 1)
    Style.ControlHeight = math.clamp(tonumber(Style.ControlHeight) or 28, 20, 40)
    Style.TextSize = math.clamp(tonumber(Style.TextSize) or 14, 10, 24)
    Style.CaptionSize = math.clamp(tonumber(Style.CaptionSize) or 12, 9, 20)
    Style.StrokeThickness = math.clamp(tonumber(Style.StrokeThickness) or 1, 0, 4)
    Style.WindowWidth = math.clamp(tonumber(Style.WindowWidth) or 420, 240, 1100)
    Style.WindowHeight = math.clamp(tonumber(Style.WindowHeight) or 480, 180, 900)
    Style.CellRadius = math.clamp(tonumber(Style.CellRadius) or Style.Radius, 0, 16)
    Style.CellPadding = math.clamp(tonumber(Style.CellPadding) or 6, 0, 20)
    Style.SelectionThickness = math.clamp(tonumber(Style.SelectionThickness) or 1, 0, 4)
    Style.PreviewRatio = math.clamp(tonumber(Style.PreviewRatio) or 0.58, 0.3, 0.8)
    Style.Motion = Style.Motion ~= false
    Style.Minimal = Style.Minimal == true
    Style.Highlight = Style.Highlight == true
    Style.ShowHeader = Style.ShowHeader ~= false
    Style.ShowBackground = Style.ShowBackground ~= false
    Style.ShowOutline = Style.ShowOutline ~= false
    Style.ShowShadow = Style.ShowShadow ~= false

    if Style.Minimal then
        Style.OutlineTransparency = 1
        Style.StrokeThickness = 0
        Style.ShowOutline = false
        Style.ShowShadow = false
        Style.Padding = math.max(0, Style.Padding - 2)
        Style.Gap = math.max(0, Style.Gap - 2)
        Style.Radius = math.max(0, Style.Radius - 2)
        Style.CellRadius = math.max(0, Style.CellRadius - 1)
    end

    if Style.Highlight then
        if Style._Overrides.ShowOutline ~= false then
            Style.ShowOutline = true
        end
        Style.OutlineTransparency = math.min(Style.OutlineTransparency, 0.12)
        Style.StrokeThickness = math.max(1, Style.StrokeThickness)
        Style.HighlightColor = function()
            return Library.Scheme.AccentColor
        end
    end

    for _, Key in {
        "HeaderHeight",
        "Padding",
        "Gap",
        "Radius",
        "ControlRadius",
        "PopupRadius",
        "ControlHeight",
        "TextSize",
        "CaptionSize",
        "WindowWidth",
        "WindowHeight",
        "CellRadius",
        "CellPadding",
    } do
        Style[Key] = math.round(Style[Key])
    end

    return Style
end

Library:RefreshMotion()


local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Finished = false
    local Connection = Event:Once(function(...)
        if Finished then
            return
        end

        Finished = true
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        if Finished then
            return
        end

        Finished = true
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Finished = true
    Connection:Disconnect()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end
local function IsMouseClickInput(Input: InputObject)
    return Input.UserInputType == Enum.UserInputType.MouseButton1 or 
        Input.UserInputType == Enum.UserInputType.MouseButton2 or 
        Input.UserInputType == Enum.UserInputType.MouseButton3
end
local function IsMovementInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function IsSequentialArray(Table: { [any]: any })
    for Key in Table do
        if typeof(Key) ~= "number" or Key < 1 or Key % 1 ~= 0 then
            return false
        end
    end

    return true
end

local function StopTween(Tween: TweenBase, Destroy: boolean?)
    if not Tween then
        return
    end

    pcall(function()
        if Tween.PlaybackState == Enum.PlaybackState.Playing then
            Tween:Cancel()
        end
    end)

    if Destroy == true then
        pcall(Tween.Destroy, Tween)
    end
end

local function AreTweenTargetsEqual(First, Second)
    for Property, Value in First do
        if Second[Property] ~= Value then
            return false
        end
    end

    for Property in Second do
        if First[Property] == nil then
            return false
        end
    end

    return true
end

function Library:PlayTween(Instance: Instance, Slot: string, TweenInfoValue: TweenInfo, Properties)
    if not Instance or not Instance.Parent or Library.Unloaded then
        return nil
    end

    local TweenSlots = Library.ActiveTweens[Instance]
    if not TweenSlots then
        TweenSlots = {}
        Library.ActiveTweens[Instance] = TweenSlots
    end

    local Existing = TweenSlots[Slot]
    if Existing and AreTweenTargetsEqual(Existing.Properties, Properties) then
        return Existing.Tween
    end

    if Existing then
        StopTween(Existing.Tween, true)
        TweenSlots[Slot] = nil
    end

    local Changed = false
    for Property, Value in Properties do
        if Instance[Property] ~= Value then
            Changed = true
            break
        end
    end

    if not Changed then
        return nil
    end

    local Tween = TweenService:Create(Instance, TweenInfoValue, Properties)
    TweenSlots[Slot] = {
        Tween = Tween,
        Properties = table.clone(Properties),
    }

    Tween.Completed:Once(function()
        if TweenSlots[Slot] and TweenSlots[Slot].Tween == Tween then
            TweenSlots[Slot] = nil
        end
    end)

    Tween:Play()
    return Tween
end

function Library:CancelTween(Instance: Instance, Slot: string)
    if not Instance then
        return
    end

    local TweenSlots = Library.ActiveTweens[Instance]
    if not TweenSlots or not TweenSlots[Slot] then
        return
    end

    StopTween(TweenSlots[Slot].Tween, true)
    TweenSlots[Slot] = nil
end

local RevealProperty = {
    TextLabel = "TextTransparency",
    TextButton = "TextTransparency",
    TextBox = "TextTransparency",
    ImageLabel = "ImageTransparency",
    ImageButton = "ImageTransparency",
}

local RevealTokens = {}
local RevealTargets = {}

local function CollectRevealTargets(Root: Instance, Out: { any })
    local Property = RevealProperty[Root.ClassName]
    if Property then
        table.insert(Out, { Object = Root, Property = Property })
    end

    for _, Child in Root:GetDescendants() do
        local ChildProperty = RevealProperty[Child.ClassName]
        if ChildProperty then
            table.insert(Out, { Object = Child, Property = ChildProperty })
        end
    end

    return Out
end

function Library:CancelReveal(Root: Instance, Restore: boolean?)
    if typeof(Root) ~= "Instance" then
        return
    end

    RevealTokens[Root] = (RevealTokens[Root] or 0) + 1

    local Targets = RevealTargets[Root]
    if not Targets then
        return
    end

    for _, Entry in Targets do
        Library:CancelTween(Entry.Object, "Reveal")
        if Restore ~= false and Entry.Object.Parent then
            pcall(function()
                Entry.Object[Entry.Property] = Entry.Target
            end)
        end
    end

    RevealTargets[Root] = nil
end

function Library:RevealText(Root: Instance, Info)
    if typeof(Root) ~= "Instance" then
        return
    end

    Info = Info or {}

    if Library.Design.Motion.Reduced or Info.Motion == false then
        Library:CancelReveal(Root, true)
        return
    end

    Library:CancelReveal(Root, true)

    local Targets = CollectRevealTargets(Root, {})
    if #Targets == 0 then
        return
    end

    local Stagger = math.clamp(tonumber(Info.Stagger) or 0.012, 0, 0.08)
    local Rise = math.clamp(tonumber(Info.Rise) or 0, 0, 12)
    local Motion = Library:GetMotion(Info.Motion or "TextReveal")

    RevealTokens[Root] = (RevealTokens[Root] or 0) + 1
    local Token = RevealTokens[Root]

    for Index, Entry in Targets do
        Entry.Target = Entry.Object[Entry.Property]
        Entry.Object[Entry.Property] = 1
    end

    RevealTargets[Root] = Targets

    local Span = math.min(#Targets * Stagger, 0.22)
    local Step = #Targets > 1 and (Span / (#Targets - 1)) or 0

    for Index, Entry in Targets do
        local Offset = Step * (Index - 1)

        local function Play()
            if RevealTokens[Root] ~= Token or not Entry.Object.Parent then
                return
            end
            Library:PlayTween(Entry.Object, "Reveal", Motion, {
                [Entry.Property] = Entry.Target,
            })
        end

        if Offset <= 0 then
            Play()
        else
            task.delay(Offset, Play)
        end
    end

    task.delay(Span + Motion.Time, function()
        if RevealTokens[Root] == Token then
            RevealTargets[Root] = nil
        end
    end)

    if Rise > 0 and Root:IsA("GuiObject") then
        local Resting = Root.Position
        Root.Position = Resting + UDim2.fromOffset(0, Rise)
        Library:PlayTween(Root, "RevealRise", Motion, { Position = Resting })
    end
end

local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local RoundingFactors = { [0] = 1 }
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    local Factor = RoundingFactors[Rounding]
    if not Factor then
        Factor = 10 ^ Rounding
        RoundingFactors[Rounding] = Factor
    end

    return math.round(Value * Factor) / Factor
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end

local DependencyUpdateQueued = false

function Library:UpdateDependencyBoxes()
    for _, Depbox in Library.DependencyBoxes do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

function Library:QueueDependencyUpdate()
    if DependencyUpdateQueued or Library.Unloaded then
        return
    end

    DependencyUpdateQueued = true
    task.defer(function()
        DependencyUpdateQueued = false
        if not Library.Unloaded then
            Library:UpdateDependencyBoxes()
        end
    end)
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            
            local Visible = false

            
            if ElementInfo.Text:lower():find(Search, 1, true) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if ElementInfo.SubButton.Text:lower():find(Search, 1, true) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        
        if ElementInfo.Text and ElementInfo.Text:lower():find(Search, 1, true) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search)
    end

    Box.Holder.Visible = VisibleElements > 0
    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = ElementInfo.Visible ~= false

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

local function ApplySearchToTab(Tab, Search)
    if not Tab then
        return
    end

    local HasVisible = false

    
    for _, Groupbox in Tab.Groupboxes do
        if Groupbox.Visible == false then
            continue
        end

        local VisibleElements = 0
        for _, ElementInfo in Groupbox.Elements do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                
                local Visible = false

                
                if ElementInfo.Text:lower():find(Search, 1, true) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end
                if ElementInfo.SubButton.Text:lower():find(Search, 1, true) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end
                ElementInfo.Holder.Visible = Visible

                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            
            if ElementInfo.Text and ElementInfo.Text:lower():find(Search, 1, true) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search)
        end

        
        if VisibleElements > 0 then
            Groupbox:Resize()
            HasVisible = true
        end
        Groupbox.BoxHolder.Visible = VisibleElements > 0
    end

    for _, Tabbox in Tab.Tabboxes do
        local VisibleTabs = 0
        local VisibleElements = {}

        for _, SubTab in Tabbox.Tabs do
            VisibleElements[SubTab] = 0

            for _, ElementInfo in SubTab.Elements do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    
                    local Visible = false

                    
                    if ElementInfo.Text:lower():find(Search, 1, true) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if ElementInfo.SubButton.Text:lower():find(Search, 1, true) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements[SubTab] += 1
                    end

                    continue
                end

                
                if ElementInfo.Text and ElementInfo.Text:lower():find(Search, 1, true) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements[SubTab] += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements[SubTab] += CheckDepbox(Depbox, Search)
            end
        end

        for SubTab, Visible in VisibleElements do
            SubTab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1
                HasVisible = true

                if Tabbox.ActiveTab == SubTab then
                    SubTab:Resize()
                elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                    SubTab:Show()
                end
            end
        end

        
        Tabbox.BoxHolder.Visible = VisibleTabs > 0
    end

    return HasVisible
end
local function ResetTab(Tab)
    if not Tab then
        return
    end

    for _, Groupbox in Tab.Groupboxes do
        for _, ElementInfo in Groupbox.Elements do
            ElementInfo.Holder.Visible = ElementInfo.Visible ~= false

            if ElementInfo.SubButton then
                ElementInfo.Base.Visible = ElementInfo.Visible
                ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            RestoreDepbox(Depbox)
        end

        Groupbox:Resize()
        Groupbox.BoxHolder.Visible = Groupbox.Visible ~= false
    end

    for _, Tabbox in Tab.Tabboxes do
        for _, SubTab in Tabbox.Tabs do
            for _, ElementInfo in SubTab.Elements do
                ElementInfo.Holder.Visible = ElementInfo.Visible ~= false

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            SubTab.ButtonHolder.Visible = true
        end

        if Tabbox.ActiveTab then
            Tabbox.ActiveTab:Resize()
        end
        Tabbox.BoxHolder.Visible = true
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.GlobalSearch then
        for _, Tab in Library.Tabs do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                table.insert(TabsToReset, Tab)
            end
        end
    elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    for _, Tab in ipairs(TabsToReset) do
        ResetTab(Tab)
    end

    local Search = SearchText:lower()
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    local TabsToSearch = {}

    if Library.GlobalSearch then
        TabsToSearch = TabsToReset
        if #TabsToSearch == 0 then
            for _, Tab in Library.Tabs do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabsToSearch, Tab)
                end
            end
        end
    elseif Library.ActiveTab then
        table.insert(TabsToSearch, Library.ActiveTab)
    end

    local FirstVisibleTab = nil
    local ActiveHasVisible = false

    for _, Tab in ipairs(TabsToSearch) do
        local HasVisible = ApplySearchToTab(Tab, Search)
        if HasVisible then
            if not FirstVisibleTab then
                FirstVisibleTab = Tab
            end
            if Tab == Library.ActiveTab then
                ActiveHasVisible = true
            end
        end
    end

    if Library.GlobalSearch then
        if ActiveHasVisible and Library.ActiveTab then
            Library.ActiveTab:RefreshSides()
        elseif FirstVisibleTab then
            local SearchMarker = SearchText
            task.defer(function()
                if Library.SearchText ~= SearchMarker then
                    return
                end

                if Library.ActiveTab ~= FirstVisibleTab then
                    FirstVisibleTab:Show()
                end
            end)
        end
        Library.LastSearchTab = nil
    else
        Library.LastSearchTab = Library.ActiveTab
    end
end

local SearchRequestId = 0
function Library:QueueSearch(SearchText: string)
    SearchRequestId += 1
    Library.SearchText = SearchText

    local RequestId = SearchRequestId
    local Delay = math.max(tonumber(Library.SearchDebounce) or 0, 0)
    if Delay == 0 then
        return Library:UpdateSearch(SearchText)
    end

    task.delay(Delay, function()
        if Library.Unloaded or RequestId ~= SearchRequestId or Library.SearchText ~= SearchText then
            return
        end

        Library:UpdateSearch(SearchText)
    end)
end

function Library:AddToRegistry(Instance, Properties)
    if Instance:IsA("ScrollingFrame") and Properties.ScrollBarImageColor3 == "AccentColor" then
        Properties = table.clone(Properties)
        Properties.ScrollBarImageColor3 = function()
            return Library:GetDesignToken("Effects.AccentScrollbars", false) and Library.Scheme.AccentColor or Library.Scheme.MutedFontColor
        end
        Instance.ScrollBarImageColor3 = Properties.ScrollBarImageColor3()
    end
    Library.Registry[Instance] = Properties
    if Instance:IsA("UIStroke") then
        Instance.BorderStrokePosition = Enum.BorderStrokePosition.Inner
        Instance.LineJoinMode = Enum.LineJoinMode.Round
    end
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:ReleaseRegistryTree(Object)
    if typeof(Object) ~= "Instance" then
        return
    end

    for _, Child in Object:GetDescendants() do
        Library.Registry[Child] = nil
    end
    Library.Registry[Object] = nil
end

function Library:BindTheme(Object, Properties)
    local Bindings = table.clone(Library.Registry[Object] or {})
    for Property, Value in Properties do
        Bindings[Property] = Value
        if type(Value) == "function" then
            Object[Property] = Value()
        else
            Object[Property] = GetSchemeValue(Value) or Value
        end
    end
    Library:AddToRegistry(Object, Bindings)
    return Object
end

function Library:BindAddonStyle(Root, Style, Info, BindSurface)
    Info = Info or {}
    local Overrides = table.clone(Style._Overrides or Info.Style or {})
    local State = {
        Destroyed = false,
        Overrides = Overrides,
        Style = Style,
    }
    local ManagedCorners = {}

    for _, Corner in Root:GetDescendants() do
        if Corner:IsA("UICorner") and Corner.CornerRadius.Scale == 0 then
            local Offset = Corner.CornerRadius.Offset
            local Role
            if Offset == Style.Radius or Offset == Style.CellRadius then
                if Overrides.Radius == nil and Overrides.CellRadius == nil then Role = "Card" end
            elseif Offset == Style.ControlRadius and Overrides.ControlRadius == nil then
                Role = "Control"
            end
            if Role then
                table.insert(ManagedCorners, { Corner = Corner, Role = Role, Fallback = Offset })
            end
        end
    end

    local RootCorner = Root:FindFirstChildOfClass("UICorner")
    local RootStroke = Root:FindFirstChildOfClass("UIStroke")

    local function Apply()
        local Current = State.Style
        for _, Entry in ManagedCorners do
            Library:BindTheme(Entry.Corner, {
                CornerRadius = function()
                    local Explicit = Entry.Role == "Control" and Current.ControlRadius or Current.Radius
                    local Radius = tonumber(Info.CornerRadius)
                    if Radius == nil then
                        Radius = Library:GetDesignToken("Radius." .. Entry.Role, Explicit or Entry.Fallback)
                    end
                    return UDim.new(0, math.max(0, math.floor(Radius)))
                end,
            })
        end

        if not BindSurface then
            return
        end

        if RootCorner then
            Library:BindTheme(RootCorner, {
                CornerRadius = function()
                    return UDim.new(0, math.max(0, math.floor(State.Style.Radius)))
                end,
            })
        end
        if RootStroke then
            Library:BindTheme(RootStroke, {
                Color = function()
                    return State.Style.Highlight and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
                end,
                Thickness = function()
                    return State.Style.ShowOutline and State.Style.StrokeThickness or 0
                end,
                Transparency = function()
                    return State.Style.ShowOutline and State.Style.OutlineTransparency or 1
                end,
            })
        end
        if Root:IsA("GuiObject") then
            Library:BindTheme(Root, {
                BackgroundTransparency = function()
                    return State.Style.ShowBackground and State.Style.BackgroundTransparency or 1
                end,
            })
        end
    end

    local Controller = {}

    function Controller:Set(NewOverrides)
        if State.Destroyed then
            return Controller
        end
        if type(NewOverrides) == "table" then
            for Key, Value in NewOverrides do
                State.Overrides[Key] = Value
            end
        end
        State.Style = Library:GetAddonStyle(State.Overrides)
        Apply()
        Controller.Style = State.Style
        return Controller
    end

    function Controller:SetMinimal(Enabled)
        return Controller:Set({ Minimal = Enabled == true })
    end

    function Controller:SetHighlighted(Enabled)
        return Controller:Set({ Highlight = Enabled == true })
    end

    function Controller:Get()
        return table.clone(State.Style)
    end

    function Controller:Destroy()
        State.Destroyed = true
    end

    Controller.Style = State.Style
    Apply()
    return Controller
end

local function CancelThemeTweens(Instance: Instance, Properties)
    local TweenSlots = Library.ActiveTweens[Instance]
    if not TweenSlots then
        return
    end

    local Slots = {}
    for Slot, ActiveTween in TweenSlots do
        for Property in Properties do
            if ActiveTween.Properties[Property] ~= nil then
                table.insert(Slots, Slot)
                break
            end
        end
    end

    for _, Slot in Slots do
        local ActiveTween = TweenSlots[Slot]
        if ActiveTween then
            StopTween(ActiveTween.Tween, true)
            TweenSlots[Slot] = nil
        end
    end
end

function Library:UpdateColorsUsingRegistry()
    Library.ColorRevision += 1
    Library.ThemeErrors = {}

    for Instance, Properties in Library.Registry do
        pcall(function()
            CancelThemeTweens(Instance, Properties)
        end)
        for Property, Index in Properties do
            local Success, Message = pcall(function()
                local SchemeValue = GetSchemeValue(Index)
                local Value = SchemeValue
                if typeof(Index) == "function" then
                    Value = Index()
                elseif Value == nil and typeof(Index) ~= "string" then
                    Value = Index
                elseif Value == nil then
                    error("Unknown theme token: " .. Index)
                end

                if Value ~= nil and Instance[Property] ~= Value then
                    Instance[Property] = Value
                end
            end)
            if not Success then
                table.insert(Library.ThemeErrors, { Object = Instance, Property = Property, Message = tostring(Message) })
            end
        end
    end
end

function Library:OnThemeChanged(Callback)
    assert(type(Callback) == "function", "OnThemeChanged expects a function")

    local Token = {}
    Library.ThemeListeners[Token] = Callback

    return function()
        Library.ThemeListeners[Token] = nil
    end
end

function Library:RefreshThemeState()
    local Refreshed = {}
    for _, Collection in { Library.Buttons, Library.Toggles, Library.Options } do
        for _, Control in Collection do
            if typeof(Control) == "table" and not Refreshed[Control] and typeof(Control.UpdateColors) == "function" then
                Refreshed[Control] = true
                pcall(Control.UpdateColors, Control)
                if type(Control.RefreshTypography) == "function" then pcall(Control.RefreshTypography, Control) end
            end
        end
    end

    for _, Control in Library.KeybindToggles do
        if typeof(Control) == "table" and typeof(Control.UpdateColors) == "function" then
            pcall(Control.UpdateColors, Control)
        end
    end

    local Window = Library.Window
    if Window and typeof(Window.RefreshTheme) == "function" then
        pcall(Window.RefreshTheme, Window)
    end

    for _, Callback in Library.ThemeListeners do
        pcall(Callback)
    end
end

function Library:ApplyTheme()
    Library:UpdateColorsUsingRegistry()
    Library:RefreshThemeState()
end

function Library:SetDPIScale(DPIScale: number)
    local Scale = math.max(tonumber(DPIScale) or 100, 1) / 100
    if Library.DPIScale == Scale then
        return
    end

    Library.DPIScale = Scale
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale

	for Index = #Library.Scales, 1, -1 do
        local UIScale = Library.Scales[Index]
        if not UIScale or not UIScale.Parent then
            if UIScale then
                Library.ScalesOffset[UIScale] = nil
                Library.ScaleMultipliers[UIScale] = nil
            end
            table.remove(Library.Scales, Index)
        else
            Library:CancelTween(UIScale, "WindowVisibilityScale")
            local BaseScale = Library.DPIScale - (tonumber(Library.ScalesOffset[UIScale]) or 0)
            UIScale.Scale = BaseScale * (tonumber(Library.ScaleMultipliers[UIScale]) or 1)
        end
    end

    for _, Option in Options do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
            Option:RefreshPool()
        end
    end

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end

    (Library :: any):UpdateNotificationPositions(true)

    if Library.Window and Library.Window.QueueFitToViewport then
        Library.Window:QueueFitToViewport()
    elseif Library.Window and Library.Window.FitToViewport then
        task.defer(Library.Window.FitToViewport, Library.Window)
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and ConnectionType == "RBXScriptConnection" then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string" and (Icon:match("^rbxasset://textures/") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

local function IsCustomAssetIcon(Icon: string, IncludeAssetId: boolean)
    return typeof(Icon) == "string" and (Icon:match("^content://") or (Icon:match("^rbxasset://%x+/") or Icon:match("^rbxasset://[^/]+/")) or (IncludeAssetId == true and Icon:match("^rbxassetid://")))
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons, Icons = pcall(function()
    local SourceURL = "https://raw.githubusercontent.com/mstudio45/lucide-roblox-direct/refs/heads/main/source.lua"
    local CachePath = "Obsidian/cache/lucide-2026-08-03.lua"
    local Source

    if readfile and isfile and isfile(CachePath) then
        local Success, CachedSource = pcall(readfile, CachePath)
        if Success and typeof(CachedSource) == "string" and #CachedSource > 0 then
            Source = CachedSource
        end
    end

    if not Source then
        local Downloaded, Result = RequestGet(SourceURL)
        if not Downloaded then
            error(Result)
        end
        Source = Result

        if writefile and isfolder and makefolder then
            pcall(function()
                if not isfolder("Obsidian") then
                    makefolder("Obsidian")
                end
                if not isfolder("Obsidian/cache") then
                    makefolder("Obsidian/cache")
                end
                writefile(CachePath, Source)
            end)
        end
    end

    
    
    if not NativeLoadString then
        error("loadstring is unavailable")
    end

    local FastSource = "local writefile, isfolder, makefolder, getcustomasset = nil, nil, nil, nil\n" .. Source
    return ((NativeLoadString(FastSource) :: () -> IconModule)())
end)

function Library:GetIcon(IconName: string)
    if not FetchIcons or not Icons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end
    
    return Icon
end

function Library:GetCustomIcon(IconName: string): any
    if not IconName then
        return nil
    end

    if tonumber(IconName) then
        IconName = string.format("rbxassetid://%s", tostring(IconName))
    end

    if IsCustomAssetIcon(IconName, true) then
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
        }
    elseif IsValidCustomIcon(IconName) then
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end

    local LucideIcon = Library:GetIcon(IconName)
    if LucideIcon then
        return LucideIcon
    end

    return nil
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in Template do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end


local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}

    for key, value in Table do
        if key ~= "Text" then
            local SchemeValue = GetSchemeValue(value)

            if SchemeValue or typeof(value) == "function" then
                ThemeProperties[key] = value
                value = SchemeValue or value()
            else
                ThemeProperties[key] = nil
            end
        end

        if string.find(key, "Radius", 1, true) and typeof(value) == "UDim" and value.Scale == 0 then
            value = UDim.new(0, math.max(0, math.floor(value.Offset + 0.5)))
        end
        Instance[key] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)
    if Instance:IsA("GuiObject") then
        Instance.BorderSizePixel = 0
    end

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if ClassName == "ScrollingFrame" then
        pcall(function()
            Instance.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
            Instance.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        end)
        local Bindings = Library.Registry[Instance] or {}
        if Properties.ScrollBarThickness and Properties.ScrollBarThickness > 0 then
            Bindings.ScrollBarThickness = function()
                return math.clamp(math.floor(Library:GetDesignToken("Shell.ScrollbarThickness", 2)), 0, 6)
            end
            Instance.ScrollBarThickness = Bindings.ScrollBarThickness()
        end
        Library:AddToRegistry(Instance, Bindings)
    end

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

function Library:CreateSurface(Parent: Instance, Info)
    Info = Info or {}
    local Role = tostring(Info.Role or "Surface")
    local ColorIndex = Info.Color or (Role == "Control" and "ElementColor" or Role == "Raised" and "RaisedColor" or "SurfaceColor")
    local RadiusRole = tostring(Info.RadiusRole or (Role == "Control" and "Control" or Role == "Popup" and "Popup" or "Card"))
    local Radius = math.max(0, tonumber(Info.Radius) or tonumber(Library:GetDesignToken("Radius." .. RadiusRole, 7)) or 7)
    local StrokeTransparency = math.clamp(
        tonumber(Info.OutlineTransparency) or tonumber(Library:GetDesignToken("Stroke.SoftTransparency", 0.46)) or 0.46,
        0,
        1
    )
    local Object = New(Info.ClassName or "Frame", {
        BackgroundColor3 = ColorIndex,
        BackgroundTransparency = math.clamp(tonumber(Info.BackgroundTransparency) or 0, 0, 1),
        ClipsDescendants = Info.ClipsDescendants ~= false,
        Name = Info.Name,
        Position = Info.Position,
        Size = Info.Size or UDim2.fromScale(1, 1),
        Visible = Info.Visible ~= false,
        ZIndex = Info.ZIndex,
        Parent = Parent,
    })
    local Corner = New("UICorner", {
        CornerRadius = UDim.new(0, Radius),
        Parent = Object,
    })
    local Stroke
    if Info.Outline ~= false then
        Stroke = New("UIStroke", {
            Color = Info.OutlineColor or "OutlineColor",
            Thickness = tonumber(Info.OutlineThickness) or Library:GetDesignToken("Stroke.Thickness", 1),
            Transparency = StrokeTransparency,
            Parent = Object,
        })
    end
    local Shadow
    if Info.Shadow == true then
        Shadow = Library:AddSoftShadow(
            Object,
            Info.ShadowBlur,
            Info.ShadowTransparency or Library:GetDesignToken("Opacity.Shadow", 0.48),
            Info.ShadowOffset
        )
    end
    return Object, Stroke, Corner, Shadow
end

function Library:CreateDivider(Parent: Instance, Info)
    Info = Info or {}
    return Library:MakeLine(Parent, {
        AnchorPoint = Info.AnchorPoint,
        Color = Info.Color or "OutlineColor",
        Position = Info.Position or UDim2.new(0, 0, 1, -1),
        Size = Info.Size or UDim2.new(1, 0, 0, 1),
        Transparency = Info.Transparency or Library:GetDesignToken("Opacity.Divider", 0.56),
        ZIndex = Info.ZIndex,
    })
end


local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local function SetAlwaysOnTop(Gui: ScreenGui, Enabled: boolean)
    if not Gui then
        return
    end

    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(Gui, "OnTopOfCoreBlur", Enabled)
        elseif setscriptable then
            setscriptable(Gui, "OnTopOfCoreBlur", true)
            Gui.OnTopOfCoreBlur = Enabled
            setscriptable(Gui, "OnTopOfCoreBlur", false)
        end
    end)
end

local ExistingLibrary = getgenv().Library
if typeof(ExistingLibrary) == "table" and ExistingLibrary ~= Library and IsFunction(ExistingLibrary.Unload) then
    local ExistingGui = ExistingLibrary.ScreenGui
    if typeof(ExistingGui) == "Instance" and ExistingGui.Name == "MonHub" then
        pcall(ExistingLibrary.Unload, ExistingLibrary)
    end
end

local ScreenGui = New("ScreenGui", {
    Name = "MonHub",
    DisplayOrder = 998,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})


local Cursor, CursorCustomImage
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 11000,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        ZIndex = 11000,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = CursorV,
    })

    CursorCustomImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 11000,
        Visible = false,
        Parent = Cursor
    })
end


local NotificationArea
local NotifyOrder = {}
do
    local Style = Library.NotificationStyle
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -Style.Margin, 0, Style.Margin),
        Size = UDim2.new(0, Style.Width, 1, -Style.Margin * 2),
        Parent = ScreenGui,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = NotificationArea,
        })
    )
end


function Library:ResetCursorIcon()
    CursorCustomImage.Visible = false
    CursorCustomImage.Size = UDim2.fromOffset(20, 20)
end

function Library:ChangeCursorIcon(ImageId: string)
    if not ImageId or ImageId == "" then
        Library:ResetCursorIcon()
        return
    end

    local Icon = Library:GetCustomIcon(ImageId)
    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

    CursorCustomImage.Visible = true
    CursorCustomImage.Image = Icon.Url
    CursorCustomImage.ImageRectOffset = Icon.ImageRectOffset
    CursorCustomImage.ImageRectSize = Icon.ImageRectSize
end

function Library:ChangeCursorIconSize(Size: UDim2)
    assert(typeof(Size) == "UDim2", "UDim2 expected.")
    CursorCustomImage.Size = Size
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetAccentSurfaceColor(Strength: number?): Color3
    local Weight = math.clamp(Strength or 0.1, 0, 1)
    local Base = Library.Scheme.AccentSoftColor or Library.Scheme.SurfaceColor or Library.Scheme.MainColor
    return Base:Lerp(Library.Scheme.AccentColor, Weight * 0.38)
end

local function GetTopBarSurfaceColor(Strength: number?): Color3
    local Weight = math.clamp(Strength or 0.08, 0, 1)
    local Base = Library.Scheme.ElementColor or Library.Scheme.TopBarColor
    return Base:Lerp(Library.Scheme.AccentColor, Weight * 0.28)
end

function Library:GetSurfaceColor(Level: string?): Color3
    if Level == "Raised" then
        return Library.Scheme.RaisedColor or Library.Scheme.TopBarColor
    end
    if Level == "Element" then
        return Library.Scheme.ElementColor or Library.Scheme.MainColor
    end
    if Level == "Hover" then
        return Library.Scheme.HoverColor or Library:GetBetterColor(Library.Scheme.MainColor, 4)
    end

    return Library.Scheme.SurfaceColor or Library.Scheme.BackgroundColor:Lerp(Library.Scheme.MainColor, 0.5)
end

function Library:GetMutedFontColor(): Color3
    return Library.Scheme.MutedFontColor or Library.Scheme.FontColor:Lerp(Library.Scheme.BackgroundColor, 0.42)
end

local ButtonVariantAliases = {
    Default = "Default",
    Secondary = "Default",
    Primary = "Primary",
    Ghost = "Ghost",
}

function Library:NormalizeButtonVariant(Variant: string?, _Risky: boolean?): string
    local Normalized = typeof(Variant) == "string" and ButtonVariantAliases[Variant] or nil
    if Normalized then
        return Normalized
    end

    return "Default"
end

function Library:GetButtonStyle(Variant: string?, Disabled: boolean?)
    local Scheme = Library.Scheme
    local Normalized = Library:NormalizeButtonVariant(Variant)
    local Style = {
        BackgroundColor = Library:GetSurfaceColor("Element"),
        BackgroundTransparency = 0,
        OutlineColor = Scheme.OutlineColor,
        OutlineTransparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
        TextColor = Scheme.FontColor,
        TextTransparency = 0.16,
        HoverBackgroundColor = Library:GetSurfaceColor("Hover"),
        HoverBackgroundTransparency = 0,
        HoverOutlineColor = Scheme.OutlineColor:Lerp(Scheme.AccentColor, 0.28),
        HoverOutlineTransparency = Library:GetDesignToken("Stroke.StrongTransparency", 0.18),
        HoverTextColor = Scheme.FontColor,
        HoverTextTransparency = 0,
    }

    if Normalized == "Primary" then
        Style.OutlineColor = Scheme.OutlineColor:Lerp(Scheme.AccentColor, 0.62)
        Style.HoverBackgroundColor = Library:GetSurfaceColor("Hover")
        Style.HoverOutlineColor = Scheme.AccentColor
    elseif Normalized == "Ghost" then
        Style.BackgroundColor = Scheme.BackgroundColor
        Style.BackgroundTransparency = 1
        Style.OutlineColor = Scheme.OutlineColor
        Style.OutlineTransparency = 1
        Style.TextTransparency = 0.24
        Style.HoverBackgroundColor = Library:GetSurfaceColor("Element")
        Style.HoverBackgroundTransparency = 0
        Style.HoverOutlineColor = Scheme.OutlineColor:Lerp(Scheme.AccentColor, 0.2)
        Style.HoverOutlineTransparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38)
    end

    if Disabled then
        Style.BackgroundColor = Scheme.BackgroundColor
        Style.BackgroundTransparency = 0.32
        Style.OutlineColor = Scheme.OutlineColor
        Style.OutlineTransparency = 0.58
        Style.TextColor = Scheme.FontColor
        Style.TextTransparency = 0.64
        Style.HoverBackgroundColor = Style.BackgroundColor
        Style.HoverBackgroundTransparency = Style.BackgroundTransparency
        Style.HoverOutlineColor = Style.OutlineColor
        Style.HoverOutlineTransparency = Style.OutlineTransparency
        Style.HoverTextColor = Style.TextColor
        Style.HoverTextTransparency = Style.TextTransparency
    end

    Style.Variant = Normalized
    return Style
end

local function GetCachedButtonStyle(Button)
    if Button.StyleCacheRevision ~= Library.ColorRevision
        or Button.StyleCacheVariant ~= Button.Variant
        or Button.StyleCacheDisabled ~= Button.Disabled
    then
        Button.StyleCache = Library:GetButtonStyle(Button.Variant, Button.Disabled)
        Button.StyleCacheRevision = Library.ColorRevision
        Button.StyleCacheVariant = Button.Variant
        Button.StyleCacheDisabled = Button.Disabled
    end

    return Button.StyleCache
end

local function NormalizeToggleVariant(Variant: string?, Risky: boolean?): string
    if typeof(Variant) == "string" then
        if Variant == "Warning" or Variant == "Caution" then
            return "Warning"
        end
        if Variant == "Danger" or Variant == "Destructive" then
            return "Danger"
        end
    end

    return Risky and "Danger" or "Default"
end

local function GetToggleAccentColor(Variant: string): Color3
    if Variant == "Warning" then
        return Library.Scheme.WarningColor or Library.Scheme.AccentColor
    end
    if Variant == "Danger" then
        return Library.Scheme.DestructiveColor or Library.Scheme.AccentColor
    end

    return Library.Scheme.AccentColor
end

local function GetToggleLabelColor(Variant: string, Active: boolean): Color3
    if Active and (Variant == "Warning" or Variant == "Danger") then
        return Library.Scheme.FontColor:Lerp(GetToggleAccentColor(Variant), 0.52)
    end

    return Library.Scheme.FontColor
end

local function GetToggleSurfaceColor(Toggle): Color3
    if Toggle.Value then
        local AccentWeight = Toggle.Variant == "Checkbox" and 0.82 or 0.56
        return Library:GetSurfaceColor("Element"):Lerp(GetToggleAccentColor(Toggle.StyleVariant), AccentWeight)
    end

    return Library:GetSurfaceColor("Element"):Lerp(Library.Scheme.OutlineColor, 0.12)
end

local function GetToggleStrokeColor(Toggle): Color3
    if Toggle.Value then
        return GetToggleSurfaceColor(Toggle)
    end

    return Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.08)
end

local function GetKeybindToggleSurfaceColor(Active: boolean): Color3
    if Active then
        return Library.Scheme.MainColor:Lerp(Library.Scheme.AccentColor, 0.78)
    end

    return Library.Scheme.MainColor:Lerp(Library.Scheme.OutlineColor, 0.16)
end

local function GetKeybindToggleStrokeColor(Active: boolean): Color3
    if Active then
        return GetKeybindToggleSurfaceColor(true)
    end

    return Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.08)
end

local function RegisterToggleTheme(Toggle, Surface: GuiObject, Stroke: UIStroke, Label: TextLabel)
    local SurfaceRegistry = Library.Registry[Surface] or {}
    SurfaceRegistry.BackgroundColor3 = function()
        return GetToggleSurfaceColor(Toggle)
    end
    Library.Registry[Surface] = SurfaceRegistry

    local StrokeRegistry = Library.Registry[Stroke] or {}
    StrokeRegistry.Color = function()
        return GetToggleStrokeColor(Toggle)
    end
    Library.Registry[Stroke] = StrokeRegistry

    local LabelRegistry = Library.Registry[Label] or {}
    LabelRegistry.TextColor3 = function()
        return GetToggleLabelColor(Toggle.StyleVariant, Toggle.Value)
    end
    Library.Registry[Label] = LabelRegistry
end

local function ResolveButtonIcon(Icon: string | number | boolean?)
    local RequestedIcon = Icon

    if RequestedIcon == false or RequestedIcon == nil or RequestedIcon == "" then
        return nil
    end

    if typeof(RequestedIcon) ~= "string" and typeof(RequestedIcon) ~= "number" then
        return nil
    end

    return Library:GetCustomIcon(RequestedIcon)
end

local function ApplyButtonVisual(
    Button: TextButton,
    Stroke: UIStroke?,
    TextObject: TextLabel | TextButton?,
    Variant: string?,
    Disabled: boolean?,
    Hovered: boolean?,
    Animate: boolean?,
    TweenKey: string?,
    StyleOverride
)
    local Style = StyleOverride or Library:GetButtonStyle(Variant, Disabled)
    local UseHover = Hovered == true and not Disabled
    local BackgroundColor = UseHover and Style.HoverBackgroundColor or Style.BackgroundColor
    local BackgroundTransparency = UseHover and Style.HoverBackgroundTransparency or Style.BackgroundTransparency
    local OutlineColor = UseHover and Style.HoverOutlineColor or Style.OutlineColor
    local OutlineTransparency = UseHover and Style.HoverOutlineTransparency or Style.OutlineTransparency
    local TextColor = UseHover and Style.HoverTextColor or Style.TextColor
    local TextTransparency = UseHover and Style.HoverTextTransparency or Style.TextTransparency
    local Key = TweenKey or "Button"
    local ButtonGoals = {
        BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = BackgroundTransparency,
    }

    if TextObject == Button then
        ButtonGoals.TextColor3 = TextColor
        ButtonGoals.TextTransparency = TextTransparency
    end

    if Animate then
        Library:PlayTween(Button, Key .. "Surface", Library.TweenInfo, ButtonGoals)
        if TextObject and TextObject ~= Button then
            Library:PlayTween(TextObject, Key .. "Text", Library.TweenInfo, {
                TextColor3 = TextColor,
                TextTransparency = TextTransparency,
            })
        end
        if Stroke then
            Library:PlayTween(Stroke, Key .. "Stroke", Library.TweenInfo, {
                Color = OutlineColor,
                Transparency = OutlineTransparency,
            })
        end
    else
        Library:CancelTween(Button, Key .. "Surface")
        Button.BackgroundColor3 = BackgroundColor
        Button.BackgroundTransparency = BackgroundTransparency
        if TextObject then
            Library:CancelTween(TextObject, Key .. "Text")
            TextObject.TextColor3 = TextColor
            TextObject.TextTransparency = TextTransparency
        end
        if Stroke then
            Library:CancelTween(Stroke, Key .. "Stroke")
            Stroke.Color = OutlineColor
            Stroke.Transparency = OutlineTransparency
        end
    end

    return Style
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

local TextBoundsCache = {}
local TextBoundsCacheSize = 0
local MaxTextBoundsCacheSize = 512

function Library:ClearTextBoundsCache()
    table.clear(TextBoundsCache)
    TextBoundsCacheSize = 0
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local FinalWidth = math.max(1, Width or GetViewportSize().X - 32)
    local FontCache = TextBoundsCache[Font]
    if not FontCache then
        FontCache = {}
        TextBoundsCache[Font] = FontCache
    end

    local SizeCache = FontCache[Size]
    if not SizeCache then
        SizeCache = {}
        FontCache[Size] = SizeCache
    end

    local WidthCache = SizeCache[FinalWidth]
    if not WidthCache then
        WidthCache = {}
        SizeCache[FinalWidth] = WidthCache
    end

    local Cached = WidthCache[Text]
    if Cached then
        return Cached.X, Cached.Y
    end

    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = FinalWidth

    local Bounds = TextService:GetTextBoundsAsync(Params)
    Params:Destroy()

    if TextBoundsCacheSize >= MaxTextBoundsCacheSize then
        Library:ClearTextBoundsCache()
        FontCache = {}
        SizeCache = {}
        WidthCache = {}
        TextBoundsCache[Font] = FontCache
        FontCache[Size] = SizeCache
        SizeCache[FinalWidth] = WidthCache
    end

    WidthCache[Text] = Bounds
    TextBoundsCacheSize += 1
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:IsInsideFrame(ParentFrame: GuiObject, Frame: GuiObject)
    local GuiPos = Frame.AbsolutePosition
	local GuiSize = Frame.AbsoluteSize

	local FramePos = ParentFrame.AbsolutePosition
	local FrameSize = ParentFrame.AbsoluteSize

	return GuiPos.X >= FramePos.X
		and GuiPos.X + GuiSize.X <= FramePos.X + FrameSize.X
		and GuiPos.Y >= FramePos.Y
		and GuiPos.Y + GuiSize.Y <= FramePos.Y + FrameSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        local Context = Library.ConfigLoadContext
        if Context and Context.Thread == coroutine.running() then
            table.insert(Context.Errors, tostring(Error))
            return Error
        end
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError and Library.Notify then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function GetOverlappingDraggable(UI: GuiObject, TargetPos: Vector2?)
    local Pos1 = TargetPos or UI.AbsolutePosition
    local Size1 = UI.AbsoluteSize
    
    for _, Other in ipairs(Library.DraggableElements) do
        if Other == UI or not Other.Visible or not Other.Parent then
            continue
        end

        local Pos2 = Other.AbsolutePosition
        local Size2 = Other.AbsoluteSize
        
        if Pos1.X < Pos2.X + Size2.X and
            Pos1.X + Size1.X > Pos2.X and
            Pos1.Y < Pos2.Y + Size2.Y and
            Pos1.Y + Size1.Y > Pos2.Y then
            return Other
        end
    end
    
    return nil
end

function GetNonOverlappingPosition(UI: GuiObject, StartPos: UDim2?)
    local ScreenSize = GetViewportSize() - Vector2.new(100, 100)
    local Start = StartPos and Vector2.new(StartPos.X.Offset, StartPos.Y.Offset) or Vector2.new(6, 6)
    local Padding = 6
    
    local CurrentX = Start.X
    local CurrentY = Start.Y
    
    local Size = UI.AbsoluteSize
    if Size.X == 0 and Size.Y == 0 then
        RunService.RenderStepped:Wait()
        Size = UI.AbsoluteSize
    end
    
    if Size.X == 0 then Size = Vector2.new(150, 40) end

    local MaxXInColumn = Size.X

    while true do
        local Obstacle = GetOverlappingDraggable(UI, Vector2.new(CurrentX, CurrentY))
        if not Obstacle then
            break
        end
        
        if Obstacle.AbsoluteSize.X > MaxXInColumn then
            MaxXInColumn = Obstacle.AbsoluteSize.X
        end
        
        local NextY = Obstacle.AbsolutePosition.Y + Obstacle.AbsoluteSize.Y + Padding
        if NextY + Size.Y > ScreenSize.Y - Padding then
            local NextX = CurrentX + MaxXInColumn + Padding
            
            if NextX + Size.X > ScreenSize.X - Padding then
                break
            end
            
            CurrentY = Start.Y
            CurrentX = NextX
            MaxXInColumn = Size.X
        else
            CurrentY = NextY
        end
    end
    
    return UDim2.fromOffset(CurrentX, CurrentY)
end

local ClampGuiToViewport

function PositionDraggable(UI: GuiObject, StartPos: UDim2?)
    UI.Position = GetNonOverlappingPosition(UI, StartPos)
    ClampGuiToViewport(UI, 6)
end

ClampGuiToViewport = function(UI: GuiObject, Margin: number?)
    if not UI.Parent then
        return
    end

    Margin = Margin or 8

    local ViewportSize = GetViewportSize()
    local AbsolutePosition = UI.AbsolutePosition
    local AbsoluteSize = UI.AbsoluteSize
    local MaxX = math.max(Margin, ViewportSize.X - AbsoluteSize.X - Margin)
    local MaxY = math.max(Margin, ViewportSize.Y - AbsoluteSize.Y - Margin)
    local ClampedX = math.clamp(AbsolutePosition.X, Margin, MaxX)
    local ClampedY = math.clamp(AbsolutePosition.Y, Margin, MaxY)
    local Correction = Vector2.new(ClampedX, ClampedY) - AbsolutePosition

    if Correction.Magnitude > 0 then
        UI.Position = UDim2.new(
            UI.Position.X.Scale,
            UI.Position.X.Offset + Correction.X,
            UI.Position.Y.Scale,
            UI.Position.Y.Offset + Correction.Y
        )
    end
end

local function ConfigureAutoScrollbar(ScrollFrame: ScrollingFrame, IdleTransparency: number?, HoverTransparency: number?)
    IdleTransparency = IdleTransparency or 0.62
    HoverTransparency = HoverTransparency or 0.18

    ScrollFrame.ClipsDescendants = true
    pcall(function()
        ScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        ScrollFrame.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    end)

    local Hovering = false
    local function Refresh(Animate: boolean?)
        if Library.Unloaded or not ScrollFrame.Parent then
            return
        end

        local IsScrollable = ScrollFrame.AbsoluteCanvasSize.Y > ScrollFrame.AbsoluteSize.Y + 1
        local Transparency = IsScrollable and (Hovering and HoverTransparency or IdleTransparency) or 1

        if Animate then
            Library:PlayTween(ScrollFrame, "ScrollbarHover", Library.HoverTweenInfo, {
                ScrollBarImageTransparency = Transparency,
            })
        else
            ScrollFrame.ScrollBarImageTransparency = Transparency
        end
    end

    Library:GiveSignal(ScrollFrame.MouseEnter:Connect(function()
        Hovering = true
        Refresh(true)
    end))
    Library:GiveSignal(ScrollFrame.MouseLeave:Connect(function()
        Hovering = false
        Refresh(true)
    end))
    Library:GiveSignal(ScrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
        Refresh(false)
    end))
    Library:GiveSignal(ScrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Refresh(false)
    end))

    task.defer(Refresh, false)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?, CanDrag: (() -> boolean)?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    local InputBegan
    local InputChanged

    local function DragAllowed()
        if not CanDrag then
            return true
        end

        local Success, Allowed = pcall(CanDrag)
        return Success and Allowed == true
    end

    InputBegan = DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or not DragAllowed() or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    InputChanged = UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and not DragAllowed() then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)

            ClampGuiToViewport(UI, IsMainWindow and 8 or 6)
        end
    end)

    Library:GiveSignal(InputChanged)
    Library:GiveSignal(InputBegan)
    
    UI.Destroying:Once(function()
        if InputChanged and InputChanged.Connected then
            InputChanged:Disconnect()
        end

        if InputBegan and InputBegan.Connected then
            InputBegan:Disconnect()
        end

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end

        local IdxChanged = table.find(Library.Signals, InputChanged)
        if IdxChanged then
            table.remove(Library.Signals, IdxChanged)
        end

        local IdxBegan = table.find(Library.Signals, InputBegan)
        if IdxBegan then
            table.remove(Library.Signals, IdxBegan)
        end
    end)
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: (() -> ())?, ResizeInfo: any?)
    ResizeInfo = ResizeInfo or {}
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed
    local InputBegan
    local InputChanged
    local CallbackQueued = false

    local function QueueCallback()
        if not Callback or CallbackQueued then
            return
        end

        CallbackQueued = true
        task.defer(function()
            CallbackQueued = false
            if not Library.Unloaded and UI.Parent then
                Library:SafeCallback(Callback)
            end
        end)
    end

    InputBegan = DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    InputChanged = UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            local ViewportSize = GetViewportSize()
            local Scale = math.max(tonumber(ResizeInfo.Scale) or Library.DPIScale or 1, 0.01)
            local MaxWidth = math.max(0, (ViewportSize.X - UI.AbsolutePosition.X - 8) / Scale)
            local MaxHeight = math.max(0, (ViewportSize.Y - UI.AbsolutePosition.Y - 8) / Scale)

            local Minimum = ResizeInfo.MinSize or Library.MinSize
            local Maximum = ResizeInfo.MaxSize or Vector2.new(math.huge, math.huge)
            MaxWidth = math.min(MaxWidth, Maximum.X)
            MaxHeight = math.min(MaxHeight, Maximum.Y)
            local OldSize = UI.Size
            local NewSize = UDim2.new(
                FrameSize.X.Scale,
                math.floor(math.clamp(FrameSize.X.Offset + Delta.X / Scale, math.min(Minimum.X, MaxWidth), MaxWidth)),
                FrameSize.Y.Scale,
                math.floor(math.clamp(FrameSize.Y.Offset + Delta.Y / Scale, math.min(Minimum.Y, MaxHeight), MaxHeight))
            )
            UI.Size = NewSize
            UI.Position += UDim2.fromOffset(
                (NewSize.X.Offset - OldSize.X.Offset) * UI.AnchorPoint.X,
                (NewSize.Y.Offset - OldSize.Y.Offset) * UI.AnchorPoint.Y
            )
            QueueCallback()
        end
    end)

    Library:GiveSignal(InputChanged)
    Library:GiveSignal(InputBegan)

    UI.Destroying:Once(function()
        if InputChanged and InputChanged.Connected then
            InputChanged:Disconnect()
        end

        if InputBegan and InputBegan.Connected then
            InputBegan:Disconnect()
        end

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end

        local IdxChanged = table.find(Library.Signals, InputChanged)
        if IdxChanged then
            table.remove(Library.Signals, IdxChanged)
        end

        local IdxBegan = table.find(Library.Signals, InputBegan)
        if IdxBegan then
            table.remove(Library.Signals, IdxBegan)
        end
    end)
end

function Library:CreateAddonWindow(Info)
    Info = Info or {}
    local Style = Library:GetAddonStyle(Info.Style)
    local Width = math.floor(math.clamp(tonumber(Info.Width) or Style.WindowWidth, 240, 1100))
    local Height = math.floor(math.clamp(tonumber(Info.Height) or Style.WindowHeight, 180, 900))
    local ShowHeader = Info.ShowHeader ~= false and Style.ShowHeader ~= false
    local HeaderHeight = ShowHeader and math.floor(math.clamp(tonumber(Info.HeaderHeight) or (Info.Subtitle and 54 or 44), 38, 68)) or 0
    local Position = typeof(Info.Position) == "UDim2" and Info.Position or UDim2.fromScale(0.5, 0.5)
    local AnchorPoint = typeof(Info.AnchorPoint) == "Vector2" and Info.AnchorPoint or Vector2.new(0.5, 0.5)
    local Connections = {}
    local Modules = {}
    local ModuleSequence = 0
    local function ReleaseRegistryTree(Object)
        for _, Child in Object:GetDescendants() do
            Library:RemoveFromRegistry(Child)
        end
        Library:RemoveFromRegistry(Object)
    end
    local RequestedVisible = Info.Visible ~= false
    local HideWithMenu = Info.HideWithMenu ~= false and Library.Window ~= nil
    local MenuSuppressed = HideWithMenu and not Library.Toggled
    local VisibilityToken = 0
    local Root = New("CanvasGroup", {
        Active = true,
        AnchorPoint = AnchorPoint,
        BackgroundColor3 = "BackgroundColor",
        BackgroundTransparency = Style.ShowBackground and Style.BackgroundTransparency or 1,
        ClipsDescendants = true,
        GroupTransparency = RequestedVisible and not MenuSuppressed and 0 or 1,
        Name = tostring(Info.Name or "AddonWindow"),
        Position = Position,
        Size = UDim2.fromOffset(Width, Height),
        Visible = RequestedVisible and not MenuSuppressed,
        ZIndex = tonumber(Info.ZIndex) or 24,
        Parent = Info.Parent or Library.ScreenGui,
    })
    local RootCorner = New("UICorner", {
        CornerRadius = UDim.new(0, Style.Radius),
        Parent = Root,
    })
    local RootStroke = New("UIStroke", {
        Color = Style.HighlightColor or "OutlineColor",
        Thickness = Style.ShowOutline and Style.StrokeThickness or 0,
        Transparency = Style.ShowOutline and Style.OutlineTransparency or 1,
        Parent = Root,
    })
    if Style.ShowShadow then
        Library:AddSoftShadow(Root, 22, Library:GetDesignToken("Opacity.Shadow", 0.44), UDim2.fromOffset(0, 5))
    end

    local Scale = New("UIScale", {
        Scale = 1,
        Parent = Root,
    })

    local Header = New("Frame", {
        BackgroundColor3 = "TopBarColor",
        Size = UDim2.new(1, 0, 0, HeaderHeight),
        Visible = ShowHeader,
        Parent = Root,
    })
    Library:CreateDivider(Header, {
        Position = UDim2.new(0, Style.Padding, 1, -1),
        Size = UDim2.new(1, -Style.Padding * 2, 0, 1),
    })

    local IconBadge = Library:MatchParity(HeaderHeight, 26)
    local IconGap = 10
    local HeaderControl = Library:MatchParity(HeaderHeight, 28)

    local IconHolder = New("Frame", {
        BackgroundColor3 = function()
            return Library:GetAccentSurfaceColor(0.18)
        end,
        Position = UDim2.fromOffset(Style.Padding, Library:CenterOffset(HeaderHeight, IconBadge)),
        Size = UDim2.fromOffset(IconBadge, IconBadge),
        Parent = Header,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Style.ControlRadius),
        Parent = IconHolder,
    })
    local IconData = Library:GetCustomIcon(Info.Icon or "layout-dashboard") or Library:GetIcon("layout-dashboard")
    local HeaderIcon = New("ImageLabel", {
        AnchorPoint = Vector2.zero,
        Image = IconData and IconData.Url or "",
        ImageColor3 = "AccentColor",
        ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
        ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
        Position = UDim2.fromOffset(math.floor((IconBadge - 16) / 2), math.floor((IconBadge - 16) / 2)),
        Size = UDim2.fromOffset(16, 16),
        Parent = IconHolder,
    })

    local HeaderTextInset = Style.Padding + IconBadge + IconGap
    local HeaderText = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(HeaderTextInset, 0),
        Size = UDim2.new(1, -(HeaderTextInset + Style.Padding + (Info.Closable ~= false and HeaderControl + IconGap or 0)), 1, 0),
        Parent = Header,
    })
    local HasSubtitle = Info.Subtitle ~= nil and tostring(Info.Subtitle) ~= ""
    local TitleRow = 20
    local SubtitleRow = 16
    local TitleTop = Library:CenterOffset(HeaderHeight, TitleRow + SubtitleRow)

    local Title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, HasSubtitle and TitleTop or 0),
        Size = UDim2.new(1, 0, 0, HasSubtitle and TitleRow or HeaderHeight),
        Text = tostring(Info.Title or "Module"),
        TextSize = Style.TextSize,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderText,
    })
    local Subtitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, TitleTop + TitleRow),
        Size = UDim2.new(1, 0, 0, SubtitleRow),
        Text = tostring(Info.Subtitle or ""),
        TextColor3 = "MutedFontColor",
        TextSize = Style.CaptionSize,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = HasSubtitle,
        Parent = HeaderText,
    })

    local CloseButton
    if ShowHeader and Info.Closable ~= false then
        CloseButton = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = "ElementColor",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -Style.Padding, 0, Library:CenterOffset(HeaderHeight, HeaderControl)),
            Size = UDim2.fromOffset(HeaderControl, HeaderControl),
            Text = "",
            Parent = Header,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Style.ControlRadius),
            Parent = CloseButton,
        })
        local CloseData = Library:GetIcon("x")
        local CloseIconSize = Library:MatchParity(HeaderControl, 16)
        local CloseIcon = New("ImageLabel", {
            Image = CloseData and CloseData.Url or "",
            ImageColor3 = "MutedFontColor",
            ImageRectOffset = CloseData and CloseData.ImageRectOffset or Vector2.zero,
            ImageRectSize = CloseData and CloseData.ImageRectSize or Vector2.zero,
            Position = UDim2.fromOffset(
                Library:CenterOffset(HeaderControl, CloseIconSize),
                Library:CenterOffset(HeaderControl, CloseIconSize)
            ),
            Size = UDim2.fromOffset(CloseIconSize, CloseIconSize),
            Parent = CloseButton,
        })
        table.insert(Connections, CloseButton.MouseEnter:Connect(function()
            Library:PlayTween(CloseButton, "AddonWindowHover", Library:GetMotion("Hover"), { BackgroundTransparency = 0 })
            Library:PlayTween(CloseIcon, "AddonWindowHover", Library:GetMotion("Hover"), { ImageColor3 = Library.Scheme.FontColor })
        end))
        table.insert(Connections, CloseButton.MouseLeave:Connect(function()
            Library:PlayTween(CloseButton, "AddonWindowHover", Library:GetMotion("Hover"), { BackgroundTransparency = 1 })
            Library:PlayTween(CloseIcon, "AddonWindowHover", Library:GetMotion("Hover"), { ImageColor3 = Library.Scheme.MutedFontColor })
        end))
    end

    local Content = New("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        CanvasSize = UDim2.fromScale(0, 0),
        Position = UDim2.fromOffset(0, HeaderHeight),
        ScrollBarImageColor3 = "AccentColor",
        ScrollBarImageTransparency = 0.42,
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Size = UDim2.new(1, 0, 1, -HeaderHeight),
        Parent = Root,
    })
    local ContentLayout = New("UIListLayout", {
        Padding = UDim.new(0, Style.Gap),
        Parent = Content,
    })
    local ContentPadding = New("UIPadding", {
        PaddingBottom = UDim.new(0, Style.Padding),
        PaddingLeft = UDim.new(0, Style.Padding),
        PaddingRight = UDim.new(0, Style.Padding),
        PaddingTop = UDim.new(0, Style.Padding),
        Parent = Content,
    })

    local Host = {
        Root = Root,
        Header = Header,
        Content = Content,
        ContentLayout = ContentLayout,
        Icon = HeaderIcon,
        TitleLabel = Title,
        SubtitleLabel = Subtitle,
        Stroke = RootStroke,
        Corner = RootCorner,
        Scale = Scale,
        Style = Style,
        Modules = Modules,
        Connections = Connections,
        Visible = RequestedVisible,
        Destroyed = false,
    }

    function Host:SetVisible(Visible, Instant)
        if Host.Destroyed then
            return Host
        end
        RequestedVisible = Visible == true
        Host.Visible = RequestedVisible
        Library:CancelTween(Root, "AddonWindowVisibility")
        Library:CancelTween(Scale, "AddonWindowVisibility")
        VisibilityToken += 1
        local Token = VisibilityToken
        if RequestedVisible and not MenuSuppressed then
            Root.Visible = true
            if Instant or not Style.Motion then
                Root.GroupTransparency = 0
                Scale.Scale = 1
                return Host
            end
            Root.GroupTransparency = 1
            Scale.Scale = 0.985
            Library:PlayTween(Root, "AddonWindowVisibility", Library:GetMotion("WindowOpen"), { GroupTransparency = 0 })
            Library:PlayTween(Scale, "AddonWindowVisibility", Library:GetMotion("WindowOpen"), { Scale = 1 })
            return Host
        end
        if Instant or not Style.Motion then
            Root.GroupTransparency = 1
            Root.Visible = false
            return Host
        end
        local Tween = Library:PlayTween(Root, "AddonWindowVisibility", Library:GetMotion("WindowClose"), { GroupTransparency = 1 })
        Library:PlayTween(Scale, "AddonWindowVisibility", Library:GetMotion("WindowClose"), { Scale = 0.99 })
        if Tween then
            Tween.Completed:Once(function()
                if not Host.Destroyed and VisibilityToken == Token and (not RequestedVisible or MenuSuppressed) then
                    Root.Visible = false
                end
            end)
        else
            Root.Visible = false
        end
        return Host
    end

    function Host:Toggle()
        return Host:SetVisible(not RequestedVisible)
    end

    function Host:SetTitle(Value)
        Title.Text = tostring(Value or "")
        return Host
    end

    function Host:SetSubtitle(Value)
        Subtitle.Text = tostring(Value or "")
        Subtitle.Visible = Subtitle.Text ~= ""
        HeaderHeight = ShowHeader and math.floor(math.clamp(tonumber(Info.HeaderHeight) or (Subtitle.Visible and 54 or 44), 38, 68)) or 0
        Header.Size = UDim2.new(1, 0, 0, HeaderHeight)
        Content.Position = UDim2.fromOffset(0, HeaderHeight)
        Content.Size = UDim2.new(1, 0, 1, -HeaderHeight)
        IconHolder.Position = UDim2.fromOffset(Style.Padding, Library:CenterOffset(HeaderHeight, IconBadge))
        if CloseButton then
            CloseButton.Position = UDim2.new(1, -Style.Padding, 0, Library:CenterOffset(HeaderHeight, HeaderControl))
        end
        if Subtitle.Visible then
            local TitleTop = Library:CenterOffset(HeaderHeight, TitleRow + SubtitleRow)
            Title.Position = UDim2.fromOffset(0, TitleTop)
            Title.Size = UDim2.new(1, 0, 0, TitleRow)
            Subtitle.Position = UDim2.fromOffset(0, TitleTop + TitleRow)
        else
            Title.Position = UDim2.fromOffset(0, 0)
            Title.Size = UDim2.new(1, 0, 0, HeaderHeight)
        end
        return Host
    end

    function Host:SetIcon(Value)
        local Data = Library:GetCustomIcon(Value)
        HeaderIcon.Image = Data and Data.Url or ""
        HeaderIcon.ImageRectOffset = Data and Data.ImageRectOffset or Vector2.zero
        HeaderIcon.ImageRectSize = Data and Data.ImageRectSize or Vector2.zero
        return Host
    end

    function Host:SetSize(NewWidth, NewHeight)
        Width = math.floor(math.clamp(tonumber(NewWidth) or Width, 240, 1100))
        Height = math.floor(math.clamp(tonumber(NewHeight) or Height, 180, 900))
        local Viewport = GetViewportSize()
        Root.Size = UDim2.fromOffset(math.min(Width, math.max(1, Viewport.X - 16)), math.min(Height, math.max(1, Viewport.Y - 16)))
        ClampGuiToViewport(Root, 8)
        Host:RefreshLayout()
        return Host
    end

    function Host:SetPosition(NewPosition)
        if typeof(NewPosition) == "UDim2" then
            Root.Position = NewPosition
            ClampGuiToViewport(Root, 8)
        end
        return Host
    end

    local function PrepareModule(Module, ModuleStyle)
        Module.StyleOverrides = table.clone(ModuleStyle or {})
        Module.FrameCorner = New("UICorner", {
            CornerRadius = UDim.new(0, 0),
            Parent = Module.Holder,
        })
        Module.HighlightStroke = New("UIStroke", {
            Color = "AccentColor",
            Thickness = 1,
            Transparency = 1,
            Parent = Module.Holder,
        })
        if Module.Root then
            Module.BaseBackgroundTransparency = Module.Root.BackgroundTransparency
            Module.BaseStroke = Module.Root:FindFirstChildOfClass("UIStroke")
            if Module.BaseStroke then
                Module.BaseStrokeThickness = Module.BaseStroke.Thickness
                Module.BaseStrokeTransparency = Module.BaseStroke.Transparency
            end
        end
    end

    local function ApplyModuleStyle(Module)
        local ModuleStyle = Library:GetAddonStyle(Module.StyleOverrides)
        Module.Style = ModuleStyle
        Module.FrameCorner.CornerRadius = UDim.new(0, ModuleStyle.Radius)
        local function ResolveHighlightColor()
            local Color = Module.Style.HighlightColor
            if type(Color) == "function" then
                Color = Color()
            end
            return typeof(Color) == "Color3" and Color or Library.Scheme.AccentColor
        end
        Module.HighlightStroke.Color = ResolveHighlightColor()
        Library:AddToRegistry(Module.HighlightStroke, { Color = ResolveHighlightColor })
        Module.HighlightStroke.Thickness = math.max(1, tonumber(ModuleStyle.SelectionThickness) or 1)
        local ControllerOwnsSurface = Module.Controller and type(Module.Controller.SetStyle) == "function"
        Module.HighlightStroke.Transparency = ModuleStyle.Highlight and not ControllerOwnsSurface and 0.08 or 1

        if ControllerOwnsSurface then
            Module.Controller:SetStyle(Module.StyleOverrides)
        elseif Module.Root then
            Module.Root.BackgroundTransparency = ModuleStyle.ShowBackground ~= false and Module.BaseBackgroundTransparency or 1
            if Module.BaseStroke then
                Module.BaseStroke.Thickness = ModuleStyle.ShowOutline ~= false and Module.BaseStrokeThickness or 0
                Module.BaseStroke.Transparency = ModuleStyle.ShowOutline ~= false and Module.BaseStrokeTransparency or 1
            end
        end
    end

    function Host:AddCustom(Idx, Object, ModuleHeight, Controller, ModuleStyle)
        assert(typeof(Object) == "Instance" and Object:IsA("GuiObject"), "Custom module must be a GuiObject")
        ModuleSequence += 1
        while Idx == nil and Modules[ModuleSequence] do
            ModuleSequence += 1
        end
        local Key = Idx or ModuleSequence
        if Modules[Key] then
            Host:Remove(Key)
        end
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            LayoutOrder = ModuleSequence,
            Size = UDim2.new(1, 0, 0, math.max(1, math.floor(tonumber(ModuleHeight) or Object.Size.Y.Offset))),
            Parent = Content,
        })
        Object.Parent = Holder
        Object.Position = UDim2.fromScale(0, 0)
        Object.Size = UDim2.fromScale(1, 1)
        Modules[Key] = {
            Holder = Holder,
            Root = Object,
            Controller = Controller,
            FitHeight = false,
            Visible = true,
        }
        PrepareModule(Modules[Key], ModuleStyle)
        ApplyModuleStyle(Modules[Key])
        Host:RefreshLayout()
        return Modules[Key]
    end

    function Host:AddAddon(Idx, Addon, AddonInfo)
        assert(type(Addon) == "table" and type(Addon.Create) == "function", "Window addons must expose Create")
        AddonInfo = table.clone(AddonInfo or {})
        ModuleSequence += 1
        while Idx == nil and Modules[ModuleSequence] do
            ModuleSequence += 1
        end
        local Key = Idx or ModuleSequence
        local ModuleHeight = math.max(1, math.floor(tonumber(AddonInfo.Height) or tonumber(AddonInfo.ModuleHeight) or 280))
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            LayoutOrder = ModuleSequence,
            Size = UDim2.new(1, 0, 0, ModuleHeight),
            Parent = Content,
        })
        AddonInfo.Parent = Holder
        AddonInfo.Height = ModuleHeight
        AddonInfo.Style = AddonInfo.Style or Style
        local Success, Controller = pcall(Addon.Create, Library, AddonInfo)
        if not Success then
            ReleaseRegistryTree(Holder)
            Holder:Destroy()
            error("Unable to create window addon: " .. tostring(Controller), 2)
        end
        if Modules[Key] then Host:Remove(Key) end
        Modules[Key] = {
            Holder = Holder,
            Controller = Controller,
            Root = type(Controller) == "table" and Controller.Root or nil,
            FitHeight = AddonInfo.FitHeight == true,
            Visible = true,
        }
        PrepareModule(Modules[Key], AddonInfo.Style)
        ApplyModuleStyle(Modules[Key])
        if not Modules[Key].FitHeight and type(Controller) == "table" and tonumber(Controller.Height) then
            Holder.Size = UDim2.new(1, 0, 0, Controller.Height)
        end
        Host:RefreshLayout()
        return Controller
    end

    function Host:Detach(Idx, Parent)
        local Module = Modules[Idx]
        if Host.Destroyed or not Module or not Module.Root then return nil end
        assert(typeof(Parent) == "Instance" and Parent:IsA("GuiBase2d"), "Detach requires a GUI parent")
        assert(Parent ~= Module.Holder and not Parent:IsDescendantOf(Module.Holder), "Cannot detach into the module itself")
        local Result = Module.Controller or Module.Root
        Module.Root.Parent = Parent
        Module.Root.Position = UDim2.fromOffset(0, 0)
        Module.Root.Size = UDim2.new(1, 0, 0, Module.Holder.Size.Y.Offset)
        if Module.Controller and Module.Controller.Host == Host then Module.Controller.Host = nil end
        Modules[Idx] = nil
        ReleaseRegistryTree(Module.Holder)
        Module.Holder:Destroy()
        Host:RefreshLayout()
        return Result
    end

    function Host:Remove(Idx)
        local Module = Modules[Idx]
        if not Module then
            return false
        end
        ReleaseRegistryTree(Module.Holder)
        if Module.Controller and type(Module.Controller.Destroy) == "function" then
            Module.Controller:Destroy()
        elseif Module.Root then
            Module.Root:Destroy()
        end
        if Module.Holder and Module.Holder.Parent then
            Module.Holder:Destroy()
        end
        Modules[Idx] = nil
        Host:RefreshLayout()
        return true
    end

    function Host:SetModuleHeight(Idx, ModuleHeight)
        local Module = Modules[Idx]
        if not Module then
            return false
        end
        local NewHeight = math.max(1, math.floor(tonumber(ModuleHeight) or Module.Holder.Size.Y.Offset))
        Module.Holder.Size = UDim2.new(1, 0, 0, NewHeight)
        if Module.Controller and type(Module.Controller.SetHeight) == "function" then
            Module.Controller:SetHeight(NewHeight)
            if tonumber(Module.Controller.Height) then
                Module.Holder.Size = UDim2.new(1, 0, 0, Module.Controller.Height)
            end
        elseif Module.Root then
            Module.Root.Size = UDim2.fromScale(1, 1)
        end
        return true
    end

    function Host:GetModule(Idx)
        local Module = Modules[Idx]
        return Module and (Module.Controller or Module.Root) or nil
    end

    function Host:GetModules()
        local Result = {}
        for Idx, Module in Modules do
            Result[Idx] = Module.Controller or Module.Root
        end
        return Result
    end

    function Host:SetModuleVisible(Idx, Visible)
        local Module = Modules[Idx]
        if not Module then return false end
        Module.Visible = Visible == true
        Module.Holder.Visible = Module.Visible
        if Module.Controller and type(Module.Controller.SetVisible) == "function" then
            Module.Controller:SetVisible(Module.Visible)
        elseif Module.Root then
            Module.Root.Visible = Module.Visible
        end
        Host:RefreshLayout()
        return true
    end

    function Host:SetModuleOrder(Idx, Order)
        local Module = Modules[Idx]
        if not Module then return false end
        Module.Holder.LayoutOrder = math.floor(tonumber(Order) or Module.Holder.LayoutOrder)
        return true
    end

    function Host:SetModuleFitHeight(Idx, Enabled)
        local Module = Modules[Idx]
        if not Module then return false end
        Module.FitHeight = Enabled == true
        Host:RefreshLayout()
        return true
    end

    function Host:SetModuleStyle(Idx, Overrides)
        local Module = Modules[Idx]
        if not Module or type(Overrides) ~= "table" then
            return false
        end
        for Key, Value in Overrides do
            Module.StyleOverrides[Key] = Value
        end
        ApplyModuleStyle(Module)
        return true
    end

    function Host:GetModuleStyle(Idx)
        local Module = Modules[Idx]
        return Module and table.clone(Module.Style) or nil
    end

    function Host:SetModuleHighlighted(Idx, Enabled, Color)
        local Overrides = { Highlight = Enabled == true }
        if typeof(Color) == "Color3" then
            Overrides.HighlightColor = Color
        end
        return Host:SetModuleStyle(Idx, Overrides)
    end

    function Host:SetModuleMinimal(Idx, Enabled)
        return Host:SetModuleStyle(Idx, { Minimal = Enabled == true })
    end

    function Host:SetContentSpacing(Padding, Gap)
        Style.Padding = math.clamp(math.floor(tonumber(Padding) or Style.Padding), 0, 32)
        Style.Gap = math.clamp(math.floor(tonumber(Gap) or Style.Gap), 0, 24)
        ContentPadding.PaddingBottom = UDim.new(0, Style.Padding)
        ContentPadding.PaddingLeft = UDim.new(0, Style.Padding)
        ContentPadding.PaddingRight = UDim.new(0, Style.Padding)
        ContentPadding.PaddingTop = UDim.new(0, Style.Padding)
        ContentLayout.Padding = UDim.new(0, Style.Gap)
        Host:RefreshLayout()
        return Host
    end

    function Host:RefreshLayout()
        if Host.Destroyed then return Host end
        local VisibleCount = 0
        local FitCount = 0
        local FixedHeight = 0
        for _, Module in Modules do
            if Module.Visible ~= false and Module.Holder.Visible then
                VisibleCount += 1
                if Module.FitHeight then
                    FitCount += 1
                else
                    FixedHeight += Module.Holder.Size.Y.Offset
                end
            end
        end
        if FitCount == 0 then return Host end
        local Available = math.max(
            1,
            math.floor(Content.AbsoluteSize.Y) - Style.Padding * 2 - FixedHeight - math.max(0, VisibleCount - 1) * Style.Gap
        )
        local FitHeight = math.max(1, math.floor(Available / FitCount))
        for Key, Module in Modules do
            if Module.FitHeight and Module.Visible ~= false and Module.Holder.Visible then
                Host:SetModuleHeight(Key, FitHeight)
            end
        end
        return Host
    end

    function Host:Destroy()
        if Host.Destroyed then
            return
        end
        Host.Destroyed = true
        for Idx in table.clone(Modules) do
            Host:Remove(Idx)
        end
        for _, Connection in Connections do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(Connections)
        Library:CancelTween(Root, "AddonWindowVisibility")
        Library:CancelTween(Scale, "AddonWindowVisibility")
        if Root then
            ReleaseRegistryTree(Root)
            Root:Destroy()
        end
    end

    if CloseButton then
        table.insert(Connections, CloseButton.Activated:Connect(function()
            Host:SetVisible(false)
        end))
    end
    table.insert(Connections, Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Host:RefreshLayout()
    end))
    if Info.Draggable ~= false then
        Library:MakeDraggable(Root, ShowHeader and Header or Root, true, false)
    end
    if Info.Resizable ~= false then
        local ResizeButton = New("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            ZIndex = Root.ZIndex + 2,
            Parent = Root,
        })
        local ResizeIcon = Library:GetIcon("grip")
        New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageColor3 = "MutedFontColor",
            ImageTransparency = 0.4,
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.fromOffset(12, 12),
            Parent = ResizeButton,
        })
        Library:MakeResizable(Root, ResizeButton, function()
            Width, Height = Root.Size.X.Offset, Root.Size.Y.Offset
        end, { MinSize = Vector2.new(240, 180), MaxSize = Vector2.new(1100, 900), Scale = 1 })
    end
    local CameraConnection
    local function BindViewport()
        if CameraConnection and CameraConnection.Connected then
            CameraConnection:Disconnect()
        end
        local OldConnectionIndex = table.find(Connections, CameraConnection)
        if OldConnectionIndex then
            table.remove(Connections, OldConnectionIndex)
        end
        local Camera = workspace.CurrentCamera
        if Camera then
            CameraConnection = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                if not Host.Destroyed then
                    Host:SetSize(Width, Height)
                end
            end)
            table.insert(Connections, CameraConnection)
        end
        task.defer(function()
            if not Host.Destroyed then
                Host:SetSize(Width, Height)
            end
        end)
    end
    table.insert(Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindViewport))
    BindViewport()
    if HideWithMenu and Library.Window.VisibilityChanged then
        table.insert(Connections, Library.Window.VisibilityChanged.Event:Connect(function(Visible)
            MenuSuppressed = not Visible
            if Visible then
                Host:SetVisible(RequestedVisible, true)
            else
                VisibilityToken += 1
                Library:CancelTween(Root, "AddonWindowVisibility")
                Library:CancelTween(Scale, "AddonWindowVisibility")
                Root.GroupTransparency = 1
                Scale.Scale = 1
                Root.Visible = false
            end
        end))
    end
    Library:OnUnload(function()
        Host:Destroy()
    end)
    return Host
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:GlyphSize(Box: number, Preferred: number?): number
    local Outer = math.max(1, math.round(Box))
    local Target = math.max(1, math.round(Preferred or (Outer - 4)))

    if Target > Outer then
        Target = Outer
    end

    if (Outer - Target) % 2 ~= 0 then
        Target -= 1
    end

    return math.max(1, Target)
end

function Library:GetLuminance(Color: Color3): number
    local function Channel(Value: number): number
        if Value <= 0.03928 then
            return Value / 12.92
        end
        return ((Value + 0.055) / 1.055) ^ 2.4
    end

    return 0.2126 * Channel(Color.R) + 0.7152 * Channel(Color.G) + 0.0722 * Channel(Color.B)
end

function Library:GetContrastColor(Background: Color3): Color3
    local Light = Library.Scheme.WhiteColor or Color3.new(1, 1, 1)
    local Dark = Library.Scheme.BackgroundColor or Color3.new(0, 0, 0)
    local Base = Library:GetLuminance(Background)

    local function Ratio(First: number, Second: number): number
        local High = math.max(First, Second)
        local Low = math.min(First, Second)
        return (High + 0.05) / (Low + 0.05)
    end

    if Ratio(Base, Library:GetLuminance(Light)) >= Ratio(Base, Library:GetLuminance(Dark)) then
        return Light
    end
    return Dark
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = Info.Color or "OutlineColor",
        BackgroundTransparency = Info.Transparency or 0,
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or Frame.ZIndex,
        Parent = Frame,
    })

    return Line
end

function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = "OutlineColor",
        Thickness = Library:GetDesignToken("Stroke.Thickness", 1),
        Transparency = Library:GetDesignToken("Stroke.SoftTransparency", 0.46),
        ZIndex = 2,
        Parent = Frame,
    })
    return OutlineStroke
end

function Library:AddSoftShadow(Frame: GuiObject, BlurRadius: number?, Transparency: number?, Offset: UDim2?)
    local Shadow
    local Success = pcall(function()
        Shadow = Instance.new("UIShadow")
        Shadow.BlurRadius = UDim.new(0, math.max(0, tonumber(BlurRadius) or 14))
        Shadow.Color = Library.Scheme.ShadowColor or Library.Scheme.DarkColor
        Shadow.Offset = Offset or UDim2.fromOffset(0, 3)
        Shadow.Spread = UDim2.fromOffset(1, 1)
        Shadow.Transparency = math.clamp(tonumber(Transparency) or Library:GetDesignToken("Opacity.Shadow", 0.48), 0, 1)
        Shadow.ZIndex = 0
        Shadow.Parent = Frame
    end)

    if not Success or not Shadow then
        if Shadow then
            Shadow:Destroy()
        end
        return nil
    end

    Library:AddToRegistry(Shadow, {
        Color = "ShadowColor",
        Transparency = function()
            return Library:GetDesignToken("Effects.Shadows", false)
                and math.clamp(tonumber(Transparency) or Library:GetDesignToken("Opacity.Shadow", 0.48), 0, 1)
                or 1
        end,
    })
    if not Library:GetDesignToken("Effects.Shadows", false) then
        Shadow.Transparency = 1
    end
    return Shadow
end

function Library:AddBlank(Frame: GuiObject, Size: UDim2)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = Size or UDim2.fromScale(0, 0),
        Parent = Frame,
    })
end


local ActiveTabTweens = setmetatable({}, { __mode = "k" })

function Library:PlayTabAnimation(TabCanvas: CanvasGroup, Showing: boolean, OnComplete: (() -> ())?)
    if not TabCanvas then
        if OnComplete then
            OnComplete()
        end

        return
    end

    local Existing = ActiveTabTweens[TabCanvas]
    if Existing then
        StopTween(Existing, true)
        ActiveTabTweens[TabCanvas] = nil
    end

    local BaseZIndex = TabCanvas.ZIndex
    if not (Library.Animations and Library.Animations.TabSwitch) then
        TabCanvas.Visible = Showing
        TabCanvas.GroupTransparency = Showing and 0 or 1
        TabCanvas.Position = UDim2.fromScale(0, 0)
        TabCanvas.ZIndex = BaseZIndex

        if OnComplete then
            OnComplete()
        end

        return
    end

    if Showing then
        local TweenInfo = Library.TabTransitionInfo or Library:GetMotion("TabEnter")
        local Offset = Library.TabSwipeOffset or 2
        local SwipeFrom = string.lower(Library.TabSwipeFrom or "bottom")

        if SwipeFrom == "auto" then
            local Direction = Library.TabSwipeDirection
            SwipeFrom = Direction == -1 and "top" or "bottom"
        end

        local StartPosition

        if SwipeFrom == "left" then
            StartPosition = UDim2.fromOffset(-Offset, 0)
        elseif SwipeFrom == "top" then
            StartPosition = UDim2.fromOffset(0, -Offset)
        elseif SwipeFrom == "right" then
            StartPosition = UDim2.fromOffset(Offset, 0)
        else
            StartPosition = UDim2.fromOffset(0, Offset)
        end

        TabCanvas.ZIndex = BaseZIndex + 1
        TabCanvas.GroupTransparency = 1
        TabCanvas.Position = StartPosition
        TabCanvas.Visible = true

        local Tween = TweenService:Create(TabCanvas, TweenInfo, {
            GroupTransparency = 0,
            Position = UDim2.fromScale(0, 0)
        })

        ActiveTabTweens[TabCanvas] = Tween
        Tween:Play()

        local Connection; Connection = Tween.Completed:Connect(function(PlaybackState)
            if Connection then
                Connection:Disconnect()
            end

            if ActiveTabTweens[TabCanvas] == Tween then
                ActiveTabTweens[TabCanvas] = nil
            end

            if PlaybackState == Enum.PlaybackState.Cancelled then
                return
            end

            TabCanvas.ZIndex = BaseZIndex
            if OnComplete then
                OnComplete()
            end
        end)
    else
        if not TabCanvas.Visible then
            TabCanvas.GroupTransparency = 1
            TabCanvas.Position = UDim2.fromScale(0, 0)
            TabCanvas.ZIndex = BaseZIndex
            if OnComplete then
                OnComplete()
            end
            return
        end

        local TweenInfo = Library.TabExitTransitionInfo or Library:GetMotion("TabExit")
        local Tween = TweenService:Create(TabCanvas, TweenInfo, {
            GroupTransparency = 1,
            Position = UDim2.fromOffset(0, -2),
        })

        ActiveTabTweens[TabCanvas] = Tween
        Tween:Play()

        local Connection; Connection = Tween.Completed:Connect(function(PlaybackState)
            if Connection then
                Connection:Disconnect()
            end

            if ActiveTabTweens[TabCanvas] ~= Tween then
                return
            end

            ActiveTabTweens[TabCanvas] = nil
            if PlaybackState == Enum.PlaybackState.Cancelled then
                return
            end

            TabCanvas.Visible = false
            TabCanvas.Position = UDim2.fromScale(0, 0)
            TabCanvas.ZIndex = BaseZIndex
            if OnComplete then
                OnComplete()
            end
        end)
    end
end

function Library:AnimateTabHover(Button: TextButton, Label: TextLabel, Icon: ImageLabel?, Hovering: boolean)
    Library:PlayTween(Button, "TabHover", Library.HoverTweenInfo, {
        BackgroundTransparency = Hovering and 0.52 or 1,
    })
    Library:PlayTween(Label, "TabHover", Library.TweenInfo, {
        TextTransparency = Hovering and 0.18 or 0.5,
    })

    if Icon then
        Library:PlayTween(Icon, "TabHover", Library.TweenInfo, {
            ImageTransparency = Hovering and 0.18 or 0.5,
        })
    end
end

function Library:AnimateTabSelection(Button: TextButton, Label: TextLabel, Icon: ImageLabel?, Selected: boolean)
    Library:CancelTween(Button, "TabHover")
    Library:CancelTween(Label, "TabHover")
    if Icon then
        Library:CancelTween(Icon, "TabHover")
    end
    Library:PlayTween(Button, "TabSelection", Library.TweenInfo, {
        BackgroundTransparency = Selected and 0.14 or 1,
    })
    Library:PlayTween(Label, "TabSelection", Library.TweenInfo, {
        TextTransparency = Selected and 0 or 0.5,
    })
    if Icon then
        Library:PlayTween(Icon, "TabSelection", Library.TweenInfo, {
            ImageTransparency = Selected and 0 or 0.5,
        })
    end

    local Indicator = Button:FindFirstChild("Indicator")
    if Indicator then
        Indicator.Visible = Library:GetDesignToken("Effects.NavigationIndicator", false)
        local Row = Button.AbsoluteSize.Y
        if Row <= 0 then
            Row = Library:GetDesignToken("Shell.NavigationHeight", 38)
        end
        local Height = Library:MatchParity(Row, math.round(Row * 0.44))
        Library:PlayTween(Indicator, "TabIndicator", Library.TweenInfo, {
            BackgroundTransparency = Selected and 0 or 1,
            Size = UDim2.fromOffset(2, Selected and Height or 0),
        })
    end
end


function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    warn("MonHub:MakeOutline is deprecated, please use MonHub:AddOutline instead.")
    local Holder = New("Frame", {
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder, Outline
end

function Library:AddDraggableLabel(...)
    local Params = select(1, ...)
    local Text
    local Icon
    local IconPosition = "left"
    local Position = UDim2.fromOffset(6, 6)
    local AnchorPoint = Vector2.zero
    local TextSize = 13
    local BackgroundColor = "BackgroundColor"
    local BackgroundTransparency = 0
    local Draggable = true

    if typeof(Params) == "table" then
        Text = Params.Text
        Icon = Params.Icon
        IconPosition = Params.IconPosition or "left"
        Position = Params.Position or Position
        AnchorPoint = Params.AnchorPoint or AnchorPoint
        TextSize = Params.TextSize or TextSize
        BackgroundColor = Params.BackgroundColor or BackgroundColor
        BackgroundTransparency = math.clamp(tonumber(Params.BackgroundTransparency) or 0, 0, 1)
        Draggable = Params.Draggable ~= false
    elseif typeof(Params) == "string" then
        Text = Params
        Icon = select(2, ...)
        IconPosition = select(3, ...) or "left"
    end

    if typeof(IconPosition) ~= "string" then
        IconPosition = "left"
    end

    IconPosition = string.lower(IconPosition)
    assert(IconPosition == "left" or IconPosition == "right", "Icon Position needs to be either 'left' or 'right'.")

    local DraggableLabel = {
        Connections = {},
        Destroyed = false
    }

    local IconImage
    local Label = New("TextLabel", {
        AnchorPoint = AnchorPoint,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = BackgroundTransparency,
        Size = UDim2.fromOffset(0, 0),
        Position = Position,
        Text = Text or "",
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextWrapped = false,
        TextSize = TextSize,
        ZIndex = 10,
        Parent = ScreenGui,
    })

    local LabelCorner = New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Label,
    })
    local Accent
    do
        Accent = New("Frame", {
            Visible = typeof(Params) == "table" and Params.Accent == true,
            AnchorPoint = Vector2.zero,
            BackgroundColor3 = "AccentColor",
            Position = UDim2.new(0, 7, 0.5, 0),
            Size = UDim2.fromOffset(2, 12),
            ZIndex = 11,
            Parent = Label,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Accent,
        })
    end

    local Spacing = 6
    local HorizontalPadding = 10
    local AccentWidth = 2
    local BasePadding = HorizontalPadding + (Accent.Visible and 6 or 0)

    local Padding = New("UIPadding", {
        PaddingBottom = UDim.new(0, Spacing),
        PaddingLeft = UDim.new(0, BasePadding),
        PaddingRight = UDim.new(0, HorizontalPadding),
        PaddingTop = UDim.new(0, Spacing),
        Parent = Label,
    })
    local LabelScale = New("UIScale", {
        Scale = Library.DPIScale,
        Parent = Label,
    })
    table.insert(Library.Scales, LabelScale)
    Library.ScaleMultipliers[LabelScale] = 1

    local LabelStroke = Library:AddOutline(Label)
    if Draggable then
        Library:MakeDraggable(Label, Label, true)
    end

    function DraggableLabel:SetText(Text: string)
        if DraggableLabel.Destroyed then return DraggableLabel end
        if Label.Text ~= Text then Label.Text = Text end
        return DraggableLabel
    end

    function DraggableLabel:SetIcon(NewIcon: string)
        Icon = NewIcon

        local IsNotEmpty = Icon and Trim(tostring(Icon)) ~= ""
        if IsNotEmpty then
            local CustomIcon = Library:GetCustomIcon(Icon)
            assert(CustomIcon, "Icon must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            IconImage = IconImage or New("ImageLabel", {
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                Size = UDim2.fromOffset(16, 16),
                ZIndex = 11,
                Parent = Label,
            })

            IconImage.Image = CustomIcon.Url
            IconImage.ImageRectOffset = CustomIcon.ImageRectOffset
            IconImage.ImageRectSize = CustomIcon.ImageRectSize
        end

        if IconImage then IconImage.Visible = IsNotEmpty end
        DraggableLabel:SetIconPosition(IconPosition)
    end

    function DraggableLabel:SetIconPosition(NewPosition: string)
        IconPosition = string.lower(NewPosition)
        assert(IconPosition == "left" or IconPosition == "right", "Icon Position needs to be either 'left' or 'right'.")

        local IsNotEmpty = Icon and Trim(tostring(Icon)) ~= ""
        local IconInset = BasePadding + 22
        Padding.PaddingLeft = UDim.new(0, (IsNotEmpty and IconPosition == "left") and IconInset or BasePadding)
        Padding.PaddingRight = UDim.new(0, (IsNotEmpty and IconPosition == "right") and HorizontalPadding + 22 or HorizontalPadding)

        if IconImage then
            IconImage.AnchorPoint = Vector2.new(IconPosition == "left" and 0 or 1, 0)
        end

        DraggableLabel:AlignIcon()
    end

    function DraggableLabel:AlignIcon()
        local Scale = math.max(LabelScale.Scale, 0.01)
        local Inner = math.round(Label.AbsoluteSize.Y / Scale) - Padding.PaddingTop.Offset - Padding.PaddingBottom.Offset

        if IconImage then
            local Offset = Library:CenterOffset(Inner, IconImage.Size.Y.Offset)
            IconImage.Position = IconPosition == "left" and UDim2.new(0, -22, 0, Offset)
                or UDim2.new(1, 22, 0, Offset)
        end

        if Accent then
            local Height = Library:MatchParity(Inner, math.max(10, Inner - 4))
            Accent.AnchorPoint = Vector2.zero
            Accent.Size = UDim2.fromOffset(AccentWidth, Height)
            Accent.Position = UDim2.new(
                0,
                5 - Padding.PaddingLeft.Offset,
                0,
                Library:CenterOffset(Inner, Height)
            )
        end
    end

    local WidthLimit = New("UISizeConstraint", { Parent = Label })
    local function FitWidth()
        if DraggableLabel.Destroyed then return end
        local Scale = math.max(LabelScale.Scale, 0.01)
        WidthLimit.MaxSize = Vector2.new(math.max(1, math.floor(GetViewportSize().X / Scale - 16)), math.huge)
        DraggableLabel:AlignIcon()
    end
    table.insert(DraggableLabel.Connections, Label:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitWidth))
    table.insert(DraggableLabel.Connections, LabelScale:GetPropertyChangedSignal("Scale"):Connect(FitWidth))
    table.insert(DraggableLabel.Connections, ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitWidth))

    function DraggableLabel:SetVisible(Visible: boolean)
        Label.Visible = Visible
    end

    function DraggableLabel:SetStyle(Style)
        if DraggableLabel.Destroyed then return DraggableLabel end
        Style = table.clone(Style or {})
        for _, Key in { "TextSize", "Padding", "HorizontalPadding", "CornerRadius", "Scale", "AccentWidth", "BackgroundTransparency", "OutlineTransparency" } do
            if Style[Key] ~= nil then
                local Number = tonumber(Style[Key])
                Style[Key] = Number and Number == Number and math.abs(Number) < math.huge and Number or nil
            end
        end
        if Style.TextSize ~= nil then
            Label.TextSize = math.clamp(math.floor(tonumber(Style.TextSize) or Label.TextSize), 9, 28)
        end
        if Style.BackgroundTransparency ~= nil then
            Label.BackgroundTransparency = math.clamp(tonumber(Style.BackgroundTransparency) or Label.BackgroundTransparency, 0, 1)
        end
        if Style.OutlineTransparency ~= nil then
            LabelStroke.Transparency = math.clamp(tonumber(Style.OutlineTransparency) or LabelStroke.Transparency, 0, 1)
        end
        if Style.CornerRadius ~= nil then
            LabelCorner.CornerRadius = UDim.new(0, math.clamp(math.floor(tonumber(Style.CornerRadius) or Library.CornerRadius), 0, 16))
        end
        if Style.Scale ~= nil then
            local Multiplier = math.clamp(tonumber(Style.Scale) or Library.ScaleMultipliers[LabelScale] or 1, 0.5, 2)
            Library.ScaleMultipliers[LabelScale] = Multiplier
            local BaseScale = Library.DPIScale - (tonumber(Library.ScalesOffset[LabelScale]) or 0)
            LabelScale.Scale = BaseScale * Multiplier
        end
        if Style.Padding ~= nil then
            Spacing = math.clamp(math.floor(tonumber(Style.Padding) or Spacing), 2, 20)
            Padding.PaddingBottom = UDim.new(0, Spacing)
            Padding.PaddingTop = UDim.new(0, Spacing)
        end
        if Style.Accent ~= nil and Accent then
            Accent.Visible = Style.Accent == true
        end
        if Style.AccentWidth ~= nil and Accent then
            AccentWidth = math.clamp(math.floor(tonumber(Style.AccentWidth) or AccentWidth), 1, 4)
        end
        if Style.HorizontalPadding ~= nil then
            HorizontalPadding = math.clamp(math.floor(tonumber(Style.HorizontalPadding) or HorizontalPadding), 4, 32)
        end
        if Style.TextColor ~= nil then Library:BindTheme(Label, { TextColor3 = Style.TextColor }) end
        if Style.BackgroundColor ~= nil then Library:BindTheme(Label, { BackgroundColor3 = Style.BackgroundColor }) end
        if Style.AccentColor ~= nil then Library:BindTheme(Accent, { BackgroundColor3 = Style.AccentColor }) end
        BasePadding = HorizontalPadding + (Accent.Visible and 6 or 0)
        DraggableLabel.HorizontalPadding = HorizontalPadding
        DraggableLabel:SetIconPosition(IconPosition)
        FitWidth()
        return DraggableLabel
    end

    function DraggableLabel:SetPosition(NewPosition: UDim2)
        if Draggable then
            PositionDraggable(Label, NewPosition)
            return
        end

        Label.Position = NewPosition
        ClampGuiToViewport(Label, 6)
    end
    
    DraggableLabel:SetIcon(Icon)
    DraggableLabel.Label = Label
    DraggableLabel.Accent = Accent
    DraggableLabel.Stroke = LabelStroke
    DraggableLabel.Padding = Padding
    DraggableLabel.Corner = LabelCorner
    DraggableLabel.Scale = LabelScale

    if Draggable and not table.find(Library.DraggableElements, Label) then
        table.insert(Library.DraggableElements, Label)
    end

    if Draggable then
        PositionDraggable(Label, Label.Position)
    else
        ClampGuiToViewport(Label, 6)
    end

    function DraggableLabel:Destroy()
        if DraggableLabel.Destroyed then
            return
        end

        DraggableLabel.Destroyed = true

        if DraggableLabel.Connections then
            for _, connection in DraggableLabel.Connections do
                connection:Disconnect()
            end
        end

        local ElemIdx = table.find(Library.DraggableElements, Label)
        if ElemIdx then
            table.remove(Library.DraggableElements, ElemIdx)
        end

        Library.ScaleMultipliers[LabelScale] = nil
        Library.ScalesOffset[LabelScale] = nil
        local ScaleIndex = table.find(Library.Scales, LabelScale)
        if ScaleIndex then table.remove(Library.Scales, ScaleIndex) end
        Library:ReleaseRegistryTree(Label)
        Label:Destroy()
    end

    DraggableLabel:SetStyle(typeof(Params) == "table" and Params or {})
    return DraggableLabel
end

function Library:AddDraggableButton(...)
    local Params = select(1, ...)

    local Text
    local Func
    local ExcludeScaling
    local ExcludeDragging

    if typeof(Params) == "table" then
        Text = Params.Text
        Func = Params.Callback or Params.Func
        ExcludeScaling = Params.ExcludeScaling
        ExcludeDragging = Params.ExcludeDragging
    elseif typeof(Params) == "string" then
        Text = Params
        Func = select(2, ...)
        ExcludeScaling = select(3, ...)
        ExcludeDragging = select(4, ...)
    end

    local DraggableButton = {
        Connections = {},
        Destroyed = false
    }

    local Button = New("TextButton", {
        BackgroundColor3 = "RaisedColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners, 
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = Button,
            })
        )
    end
    Library:AddOutline(Button)

    local DragThreshold = if ExcludeDragging then 0.25 else math.huge
    Button.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end
        
        local Start = tick()

        local Changed
        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            local IsLikelyDragging = tick() - Start > DragThreshold
            if IsLikelyDragging then
                return
            end

            Library:SafeCallback(Func, DraggableButton)

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    function DraggableButton:SetText(Text: string)
        local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

        Button.Text = Text
        Button.Size = UDim2.fromOffset(X * 2, Y * 2)
    end

    Library:MakeDraggable(Button, Button, true)
    DraggableButton:SetText(Text)
    DraggableButton.Button = Button

    if not table.find(Library.DraggableElements, Button) then
        table.insert(Library.DraggableElements, Button)
    end

    PositionDraggable(Button, Button.Position)

    function DraggableButton:Destroy()
        if DraggableButton.Destroyed then
            return
        end

        DraggableButton.Destroyed = true

        if DraggableButton.Connections then
            for _, connection in DraggableButton.Connections do
                connection:Disconnect()
            end
        end

        local ElemIdx = table.find(Library.DraggableElements, Button)
        if ElemIdx then
            table.remove(Library.DraggableElements, ElemIdx)
        end

        if Button then
            Button:Destroy()
        end
    end

    return DraggableButton
end

function Library:AddDraggableMenu(Name: string)
    local Holder = New("CanvasGroup", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "RaisedColor",
        GroupTransparency = 1,
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Holder,
        })
    )
    local AnimationScale = New("UIScale", {
        Scale = 1,
        Parent = Holder,
    })
    Library:AddOutline(Holder)
    Library:AddSoftShadow(Holder, 14, Library:GetDesignToken("Opacity.Shadow", 0.48), UDim2.fromOffset(0, 3))

    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
        Transparency = Library:GetDesignToken("Opacity.Divider", 0.56),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = Library:GetDesignToken("Size.Text", 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, Library:GetDesignToken("Spacing.Small", 6)),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, Library:GetDesignToken("Spacing.Small", 6)),
        PaddingLeft = UDim.new(0, Library:GetDesignToken("Spacing.Small", 6)),
        PaddingRight = UDim.new(0, Library:GetDesignToken("Spacing.Small", 6)),
        PaddingTop = UDim.new(0, Library:GetDesignToken("Spacing.Small", 6)),
        Parent = Container,
    })

    Library:MakeDraggable(Holder, Label, true)

    if not table.find(Library.DraggableElements, Holder) then
        table.insert(Library.DraggableElements, Holder)
    end

    PositionDraggable(Holder, Holder.Position)

    return Holder, Container, AnimationScale
end

function Library:HasVisibleKeybinds()
    for _, KeybindToggle in Library.KeybindToggles do
        if KeybindToggle.Loaded and KeybindToggle.Visible then
            return true
        end
    end

    return false
end

function Library:RefreshKeybindMenu()
    local Frame = Library.KeybindFrame
    local AnimationScale = Library.KeybindAnimationScale
    if not Frame or Library.Unloaded then
        return
    end

    local ShouldShow = Library.KeybindMenuRequested and Library:HasVisibleKeybinds()
    if Library.KeybindMenuVisible == ShouldShow and Frame.Visible == ShouldShow then
        return
    end

    Library.KeybindMenuVisible = ShouldShow

    if ShouldShow then
        Library.UpdatingKeybindMenuVisibility = true
        Frame.Visible = true
        Library.UpdatingKeybindMenuVisibility = false
        Frame.GroupTransparency = 1
        if AnimationScale then
            AnimationScale.Scale = 1
        end

        Library.KeybindMenuTween = Library:PlayTween(Frame, "KeybindMenuVisibility", Library.KeybindMenuTweenInfo, {
            GroupTransparency = 0,
        })
        return
    end

    if not Frame.Visible then
        Frame.GroupTransparency = 1
        if AnimationScale then
            AnimationScale.Scale = 1
        end
        return
    end

    Library.KeybindMenuTween = Library:PlayTween(Frame, "KeybindMenuVisibility", Library.KeybindMenuTweenInfo, {
        GroupTransparency = 1,
    })

    local Tween = Library.KeybindMenuTween
    if not Tween then
        Library.UpdatingKeybindMenuVisibility = true
        Frame.Visible = false
        Library.UpdatingKeybindMenuVisibility = false
        return
    end

    Tween.Completed:Connect(function(State)
        if State ~= Enum.PlaybackState.Completed or Library.KeybindMenuVisible or Library.KeybindMenuTween ~= Tween then
            return
        end

        Library.UpdatingKeybindMenuVisibility = true
        Frame.Visible = false
        Library.UpdatingKeybindMenuVisibility = false
    end)
end

function Library:SetKeybindMenuVisible(Visible: boolean)
    Library.KeybindMenuRequested = Visible == true
    Library:RefreshKeybindMenu()
end

function Library:AddDraggableImageButton(...)
    local Params = select(1, ...)

    local Icon
    local IconSize
    local Func
    local ExcludeScaling
    local ExcludeDragging

    if typeof(Params) == "table" then
        Icon = Params.Icon
        IconSize = Params.IconSize or 24
        Func = Params.Callback or Params.Func
        ExcludeScaling = Params.ExcludeScaling
        ExcludeDragging = Params.ExcludeDragging
    elseif typeof(Params) == "string" or typeof(Params) == "number" then
        Icon = Params
        IconSize = select(2, ...)
        Func = select(3, ...)
        ExcludeScaling = select(4, ...)
        ExcludeDragging = select(5, ...)
    end

    local DraggableImageButton = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "RaisedColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(IconSize + 12, IconSize + 12),
        Text = "",
        ZIndex = 10,
        Parent = ScreenGui,
    })
    
    local IconImage = New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(IconSize, IconSize),
        ImageColor3 = "FontColor",
        ZIndex = 11,
        Parent = Button,
    })

    table.insert(
        Library.Corners, 
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = Button,
            })
        )
    end
    Library:AddOutline(Button)

    local DragThreshold = if ExcludeDragging then 0.25 else math.huge
    Button.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end
        
        local Start = tick()

        local Changed
        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            local IsLikelyDragging = tick() - Start > DragThreshold
            if IsLikelyDragging then
                return
            end

            Library:SafeCallback(Func, DraggableImageButton)

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    function DraggableImageButton:SetIcon(NewIcon: string)
        Icon = NewIcon or Icon
        
        local CustomIcon = Library:GetCustomIcon(Icon)
        assert(CustomIcon, "Icon must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        IconImage.Image = CustomIcon.Url
        IconImage.ImageRectOffset = CustomIcon.ImageRectOffset
        IconImage.ImageRectSize = CustomIcon.ImageRectSize
    end

    function DraggableImageButton:SetIconSize(NewSize: number)
        IconSize = NewSize
        IconImage.Size = UDim2.fromOffset(IconSize, IconSize)
        Button.Size = UDim2.fromOffset(IconSize + 12, IconSize + 12)
    end

    Library:MakeDraggable(Button, Button, true)
    DraggableImageButton:SetIcon(Icon)
    DraggableImageButton.Button = Button

    if not table.find(Library.DraggableElements, Button) then
        table.insert(Library.DraggableElements, Button)
    end

    PositionDraggable(Button, Button.Position)

    return DraggableImageButton
end


do
    local WatermarkSide = "Left"
    local WatermarkDraggable = true
    local WatermarkStyle = {
        TextSize = 13,
        BackgroundTransparency = 0,
        OutlineTransparency = Library:GetDesignToken("Stroke.SoftTransparency", 0.46),
        CornerRadius = 5,
        Padding = 6,
        HorizontalPadding = 10,
        Margin = 8,
        Accent = false,
        AccentWidth = 2,
        Scale = 1,
    }
    local WatermarkLabel = Library:AddDraggableLabel({
        Text = "",
        Icon = "",
        Position = UDim2.new(0, 8, 0, 8),
        AnchorPoint = Vector2.zero,
        TextSize = 13,
        BackgroundColor = "MainColor",
        Draggable = false,
    })
    WatermarkLabel:SetVisible(false)
    WatermarkLabel:SetStyle(WatermarkStyle)
    Library.Watermark = WatermarkLabel
    Library.WatermarkStyle = WatermarkStyle
    Library.WatermarkSide = WatermarkSide
    Library.WatermarkDraggable = WatermarkDraggable
    WatermarkLabel.Label.Active = true
    Library:MakeDraggable(WatermarkLabel.Label, WatermarkLabel.Label, true, false, function()
        return WatermarkDraggable
    end)
    if not table.find(Library.DraggableElements, WatermarkLabel.Label) then
        table.insert(Library.DraggableElements, WatermarkLabel.Label)
    end
    local ClampQueued = false

    local function ApplyWatermarkSide()
        local Label = WatermarkLabel.Label
        if not Label or not Label.Parent then
            return
        end

        if WatermarkSide == "Left" then
            Label.AnchorPoint = Vector2.zero
            Label.Position = UDim2.new(0, WatermarkStyle.Margin, 0, WatermarkStyle.Margin)
        else
            Label.AnchorPoint = Vector2.new(1, 0)
            Label.Position = UDim2.new(1, -WatermarkStyle.Margin, 0, WatermarkStyle.Margin)
        end

        ClampGuiToViewport(Label, WatermarkStyle.Margin)
    end

    local function QueueWatermarkClamp()
        if ClampQueued then
            return
        end

        ClampQueued = true
        task.defer(function()
            RunService.Heartbeat:Wait()
            ClampQueued = false
            local Label = WatermarkLabel.Label
            if not Library.Unloaded and Label and Label.Parent and Label.Visible and Label.AbsoluteSize.X > 0 then
                ClampGuiToViewport(Label, WatermarkStyle.Margin)
            end
        end)
    end

    function Library:SetWatermark(Text: string)
        WatermarkLabel:SetText(tostring(Text or ""))
        QueueWatermarkClamp()
        return Library
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        WatermarkLabel:SetVisible(Visible)
        if Visible then
            QueueWatermarkClamp()
        end
        return Library
    end

    function Library:SetWatermarkSide(Side: "Left" | "Right")
        local Normalized = string.lower(tostring(Side))
        assert(Normalized == "left" or Normalized == "right", "Watermark side must be Left or Right.")
        WatermarkSide = Normalized == "left" and "Left" or "Right"
        Library.WatermarkSide = WatermarkSide
        ApplyWatermarkSide()
        return Library
    end

    function Library:SetWatermarkDraggable(Draggable: boolean)
        WatermarkDraggable = Draggable == true
        Library.WatermarkDraggable = WatermarkDraggable
        WatermarkLabel.Label.Active = WatermarkDraggable
        return Library
    end

    function Library:SetWatermarkOptions(Info)
        assert(typeof(Info) == "table", "Watermark options must be a table")
        for Key, Value in Info do
            if WatermarkStyle[Key] ~= nil then
                WatermarkStyle[Key] = Value
            end
        end
        local Margin = tonumber(WatermarkStyle.Margin)
        WatermarkStyle.Margin = Margin and Margin == Margin and math.clamp(math.floor(Margin), 0, 40) or 8
        WatermarkLabel:SetStyle(WatermarkStyle)
        WatermarkStyle.TextSize = WatermarkLabel.Label.TextSize
        WatermarkStyle.Padding = WatermarkLabel.Padding.PaddingTop.Offset
        WatermarkStyle.HorizontalPadding = WatermarkLabel.HorizontalPadding
        WatermarkStyle.Accent = WatermarkLabel.Accent.Visible
        WatermarkStyle.AccentWidth = WatermarkLabel.Accent.Size.X.Offset
        WatermarkStyle.CornerRadius = WatermarkLabel.Corner.CornerRadius.Offset
        WatermarkStyle.Scale = Library.ScaleMultipliers[WatermarkLabel.Scale]
        WatermarkStyle.BackgroundTransparency = WatermarkLabel.Label.BackgroundTransparency
        WatermarkStyle.OutlineTransparency = WatermarkLabel.Stroke.Transparency
        if Info.TextColor ~= nil or Info.BackgroundColor ~= nil or Info.AccentColor ~= nil then
            WatermarkLabel:SetStyle({ TextColor = Info.TextColor, BackgroundColor = Info.BackgroundColor, AccentColor = Info.AccentColor })
        end
        if Info.Margin ~= nil then ApplyWatermarkSide() end
        if Info.Text ~= nil then WatermarkLabel:SetText(tostring(Info.Text)) end
        if Info.Icon ~= nil then WatermarkLabel:SetIcon(Info.Icon) end
        if Info.IconPosition ~= nil then WatermarkLabel:SetIconPosition(Info.IconPosition) end
        if Info.Side ~= nil then Library:SetWatermarkSide(Info.Side) end
        if Info.Draggable ~= nil then Library:SetWatermarkDraggable(Info.Draggable) end
        if Info.Position ~= nil then WatermarkLabel:SetPosition(Info.Position) end
        if Info.Visible ~= nil then Library:SetWatermarkVisibility(Info.Visible) end
        QueueWatermarkClamp()
        return Library
    end

    Library.SetWatermarkStyle = Library.SetWatermarkOptions

    Library:GiveSignal(WatermarkLabel.Label:GetPropertyChangedSignal("AbsoluteSize"):Connect(QueueWatermarkClamp))
    Library:GiveSignal(WatermarkLabel.Label:GetPropertyChangedSignal("TextBounds"):Connect(QueueWatermarkClamp))
    Library:GiveSignal(WatermarkLabel.Label:GetPropertyChangedSignal("Visible"):Connect(QueueWatermarkClamp))
    Library:GiveSignal(WatermarkLabel.Label.InputEnded:Connect(function(Input)
        if IsMouseInput(Input) then
            QueueWatermarkClamp()
        end
    end))
    local WatermarkCameraConnection
    local function BindWatermarkCamera()
        if WatermarkCameraConnection and WatermarkCameraConnection.Connected then
            WatermarkCameraConnection:Disconnect()
        end

        local Camera = workspace.CurrentCamera
        if Camera then
            WatermarkCameraConnection = Library:GiveSignal(
                Camera:GetPropertyChangedSignal("ViewportSize"):Connect(QueueWatermarkClamp)
            )
        else
            WatermarkCameraConnection = nil
        end
    end

    BindWatermarkCamera()
    Library:GiveSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        BindWatermarkCamera()
        QueueWatermarkClamp()
    end))
end


local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?,
    IgnoreCornerRadius: boolean?,
    SpecificCornersOnly: ("top" | "bottom" | "no_left" | "no_top_left")?, 
    AnimationType: ("Dropdown" | "KeyPicker" | "none")?
)
    local Menu
    local ParentGui = Holder:FindFirstAncestorOfClass("ScreenGui")
    local MenuZIndex = math.max(10, Holder.ZIndex + 1)
    if ParentGui ~= ScreenGui and (Library.ActiveLoading and ParentGui ~= Library.ActiveLoading.ScreenGui) then
        ParentGui = ScreenGui
    end

    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "RaisedColor",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = MenuZIndex,
            Parent = ParentGui,
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "RaisedColor",
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = MenuZIndex,
            Parent = ParentGui,
        })
    end
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Menu,
        })
    )

    New("UIStroke", {
        Color = "OutlineColor",
        Thickness = Library:GetDesignToken("Stroke.Thickness", 1),
        Transparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
        Parent = Menu,
    })

    local Corner;
    if IgnoreCornerRadius ~= true then
        if SpecificCornersOnly == "top" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomRightRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, 0),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        elseif SpecificCornersOnly == "bottom" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, 0),
                BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        elseif SpecificCornersOnly == "no_left" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomLeftRadius = UDim.new(0, 0),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        elseif SpecificCornersOnly == "no_top_left" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        else
            Corner = New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            }); table.insert(Library.Corners, Corner)
        end
    end

    local Table = {
        Connections = {},
        Destroyed = false,

        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,

        AutoSizeY = List == 1,
        OpenCloseTween = nil,
        Animated = function()
            if not AnimationType or AnimationType == "none" then
                return false
            end

            if not (Library.Animations and Library.Animations[AnimationType] == true) then
                return false
            end
            
        return true, Library[string.format("%sTransitionInfo", AnimationType)] or Library:GetMotion("Popup")
        end
    }

    if List == 1 then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true

        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset[2])
            )
        end

        local TargetSize = typeof(Table.Size) == "function" and Table.Size() or Table.Size

        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        if Table.OpenCloseTween then
            StopTween(Table.OpenCloseTween, true)
            Table.OpenCloseTween = nil
        end

        local IsAnimated, TweenInfo = Table.Animated()
        if IsAnimated == true then
            local OpenSize = TargetSize
            if Table.AutoSizeY then
                local FullHeight = Menu.AbsoluteSize.Y

                Menu.AutomaticSize = Enum.AutomaticSize.None
                OpenSize = UDim2.new(TargetSize.X.Scale, TargetSize.X.Offset, 0, FullHeight)
            end

            Menu.Size = UDim2.new(OpenSize.X.Scale, OpenSize.X.Offset, 0, 0)
            Menu.Visible = true

            local Tween = TweenService:Create(Menu, TweenInfo, { Size = OpenSize })
            Table.OpenCloseTween = Tween

            local Connection; Connection = Library:GiveSignal(Tween.Completed:Once(function()
                if Connection then
                    Connection:Disconnect()
                end

                if Table.OpenCloseTween == Tween then
                    StopTween(Table.OpenCloseTween, true)
                    Table.OpenCloseTween = nil

                    if Table.AutoSizeY then
                        Menu.AutomaticSize = Enum.AutomaticSize.Y
                    end
                end
            end))

            Tween:Play()
        else
            Menu.Size = TargetSize
            Menu.Visible = true
        end

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset[2])
                )
            end

            if not Library:IsInsideFrame(Library.WindowContainer, Holder) and Table.Active then
                Table:Close()
            end
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end

        Table.Active = false
        CurrentMenu = nil

        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end

        if Table.OpenCloseTween then
            StopTween(Table.OpenCloseTween, true)
            Table.OpenCloseTween = nil
        end

        local IsAnimated, TweenInfo = Table.Animated()
        if IsAnimated == true then
            if Table.AutoSizeY then
                Menu.AutomaticSize = Enum.AutomaticSize.None
            end

            local CurrentSize = Menu.Size
            local CollapsedSize = UDim2.new(CurrentSize.X.Scale, CurrentSize.X.Offset, 0, 0)

            local Tween = TweenService:Create(Menu, TweenInfo, { Size = CollapsedSize })
            Table.OpenCloseTween = Tween

            local Connection; Connection = Library:GiveSignal(Tween.Completed:Once(function(PlaybackState)
                if Connection then
                    Connection:Disconnect()
                end

                if Table.OpenCloseTween == Tween then
                    StopTween(Table.OpenCloseTween, true)
                    Table.OpenCloseTween = nil

                    Menu.Visible = false
                    if Table.AutoSizeY then
                        Menu.AutomaticSize = Enum.AutomaticSize.Y
                    end
                end
            end))

            Tween:Play()
        else
            Menu.Visible = false
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    function Table:Destroy()
        if Table.Destroyed then
            return
        end

        Table.Destroyed = true

        if Table.Connections then
            for _, Connection in Table.Connections do
                Connection:Disconnect()
            end
        end

        if CurrentMenu == Table then
            Table:Close()
        end

        if Table.OpenCloseTween then
            StopTween(Table.OpenCloseTween, true)
            Table.OpenCloseTween = nil
        end

        if Menu then
            Menu:Destroy()
        end
    end

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))


local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "RaisedColor",
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
New("UIPadding", {
    PaddingBottom = UDim.new(0, 2),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 2),
    Parent = TooltipLabel,
})
table.insert(
    Library.Scales,
    New("UIScale", {
        Parent = TooltipLabel,
    })
)
New("UIStroke", {
    Color = "OutlineColor",
    Parent = TooltipLabel,
})
table.insert(
    Library.Corners,
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
        Parent = TooltipLabel,
    })
)
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, _ = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        math.max(1, (GetViewportSize().X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale)
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8, 0)
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    if Library.TooltipsEnabled ~= true then
        function TooltipTable:Destroy() end
        return TooltipTable
    end

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or Library.ActiveDialog
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        local ParentGui = HoverInstance:FindFirstAncestorOfClass("ScreenGui")
        if ParentGui ~= ScreenGui and (Library.ActiveLoading and ParentGui ~= Library.ActiveLoading.ScreenGui) then
            ParentGui = ScreenGui
        end
        TooltipLabel.Parent = ParentGui

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            (Library.Toggled or Library.ActiveLoading)
            and not Library.ActiveDialog
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        if TooltipTable.Destroyed then
            return
        end

        TooltipTable.Destroyed = true

        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                TooltipLabel.Visible = false
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipLabel)
    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
end

local BaseAddons = {}
do
    local Funcs = {}

    local function NormalizeFeatureKeyPickerModes(Modes)
        local Result = {}
        if typeof(Modes) == "table" then
            for _, Mode in Modes do
                if (Mode == "Toggle" or Mode == "Hold") and not table.find(Result, Mode) then
                    table.insert(Result, Mode)
                end
            end
        end

        if #Result == 0 then
            Result = { "Toggle", "Hold" }
        end

        return Result
    end

    function Funcs:AddKeyPicker(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel
        local IsForButton = ParentObj.Type == "Button" or ParentObj.Type == "SubButton"

        if IsForButton then
            Info.Mode = "Press"
            Info.Modes = { "Press" }
            ToggleLabel = ParentObj.Base
        elseif Info.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can only be applied on Labels and Buttons.")
            Info.Modes = { "Press" }
        else
            Info.Modes = NormalizeFeatureKeyPickerModes(Info.Modes)
            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = table.find(Info.Modes, "Toggle") and "Toggle" or Info.Modes[1]
            end
        end

        local KeyPicker = {
            Connections = {},

            Text = Info.Text,
            Value = Info.Default, 
            Modifiers = Info.DefaultModifiers, 
            DisplayValue = Info.Default, 

            Blacklisted = Info.Blacklisted,
            BlacklistedModifiers = Info.BlacklistedModifiers,
            Whitelisted = Info.Whitelisted,
            WhitelistedModifiers = Info.WhitelistedModifiers,

            Toggled = Info.SyncToggleState and ParentObj.Type == "Toggle" and ParentObj.Value == true or false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            KeyPicker.SyncToggleState = false
        end

        local Picking = false

        
        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers)

        local SlideOverflow = true
        local MaxPickerWidth = 75
        local SlidingLabel

        local LastPickerWidth = 0
        local SlideForwardTween
        local SlideBackTween
        local HandleForwardTween = function(State)
            if State ~= Enum.PlaybackState.Completed then
                return
            end

            task.wait(1.5)
            if SlideBackTween then
                SlideBackTween:Play()
            end
        end

        local HandleBackTween = function(State)
            if State ~= Enum.PlaybackState.Completed then
                return
            end

            task.wait(1.5)
            if SlideForwardTween then
                SlideForwardTween:Play()
            end
        end

        local CancelSlidingTweens = function()
            if SlideForwardTween then
                StopTween(SlideForwardTween, true)
                SlideForwardTween = nil
            end

            if SlideBackTween then
                StopTween(SlideBackTween, true)
                SlideBackTween = nil
            end
        end

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(18, 18),
            Text = (IsForButton and SlideOverflow) and "" or KeyPicker.Value,
            TextSize = 14,
            Parent = ToggleLabel,
        })

        if IsForButton and SlideOverflow then
            Picker.ClipsDescendants = true

            SlidingLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Text = KeyPicker.Value,
                TextSize = 14,
                FontFace = Picker.FontFace,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = Picker,
            })

            Library:AddToRegistry(SlidingLabel, {
                TextColor3 = "FontColor",
            })
        end

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Picker,
        })

        local PickerCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Picker,
        }); table.insert(Library.SpecificCorners, PickerCorner)

        if IsForButton then
            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Parent = ToggleLabel.Parent,
            })

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                Padding = UDim.new(0, 9),
                Parent = Holder,
            })

            ToggleLabel.Parent = Holder
            Picker.Parent = Holder

            Picker.Size = UDim2.new(0, 18, 1, 0)
        end

        local KeybindsToggle = {
            Normal = nil,
            Visible = false,
        }
        do
            local Holder = New("TextButton", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Size = UDim2.new(1, 0, 0, 18),
                Text = "",
                Visible = false,
                Parent = Library.KeybindContainer,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = Holder,
            })

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0, 1),
                LayoutOrder = 2,
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })

            local RowScale = New("UIScale", {
                Scale = 1,
                Parent = Holder,
            })

            local Switch = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(14, 14),
                LayoutOrder = 1,
                Parent = Holder,
            })
            local SwitchScale = New("UIScale", {
                Scale = 1,
                Parent = Switch,
            })
            local SwitchStroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = 0.18,
                Parent = Switch,
            })
            local CheckIcon = Library:GetCustomIcon("check")
            local Checkmark = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "WhiteColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                ResampleMode = Enum.ResamplerMode.Default,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromOffset(9, 9),
                Parent = Switch,
            })

            local SwitchRegistry = Library.Registry[Switch] or {}
            SwitchRegistry.BackgroundColor3 = function()
                return GetKeybindToggleSurfaceColor(KeybindsToggle.DisplayState == true)
            end
            Library.Registry[Switch] = SwitchRegistry

            local SwitchStrokeRegistry = Library.Registry[SwitchStroke] or {}
            SwitchStrokeRegistry.Color = function()
                return GetKeybindToggleStrokeColor(KeybindsToggle.DisplayState == true)
            end
            Library.Registry[SwitchStroke] = SwitchStrokeRegistry

            Library:AddToRegistry(Checkmark, {
                ImageColor3 = "WhiteColor",
            })

            function KeybindsToggle:Display(State)
                State = State == true
                if KeybindsToggle.DisplayState == State then
                    return
                end

                KeybindsToggle.DisplayState = State

                if KeybindsToggle.LabelTween then
                    StopTween(KeybindsToggle.LabelTween, true)
                end
                if KeybindsToggle.IndicatorTween then
                    StopTween(KeybindsToggle.IndicatorTween, true)
                end
                if KeybindsToggle.IndicatorStrokeTween then
                    StopTween(KeybindsToggle.IndicatorStrokeTween, true)
                end
                if KeybindsToggle.IndicatorCheckTween then
                    StopTween(KeybindsToggle.IndicatorCheckTween, true)
                end

                KeybindsToggle.LabelTween = TweenService:Create(Label, Library.KeybindRowTweenInfo, {
                    TextTransparency = State and 0 or 0.5,
                })
                KeybindsToggle.IndicatorTween = TweenService:Create(Switch, Library.KeybindRowTweenInfo, {
                    BackgroundColor3 = GetKeybindToggleSurfaceColor(State),
                })
                KeybindsToggle.IndicatorStrokeTween = TweenService:Create(SwitchStroke, Library.KeybindRowTweenInfo, {
                    Color = GetKeybindToggleStrokeColor(State),
                    Transparency = State and 0.04 or 0.18,
                })
                KeybindsToggle.IndicatorCheckTween = TweenService:Create(Checkmark, Library.KeybindRowTweenInfo, {
                    ImageTransparency = State and 0 or 1,
                })
                KeybindsToggle.LabelTween:Play()
                KeybindsToggle.IndicatorTween:Play()
                KeybindsToggle.IndicatorStrokeTween:Play()
                KeybindsToggle.IndicatorCheckTween:Play()

                if State then
                    KeybindsToggle:Pulse()
                end
            end

            function KeybindsToggle:Pulse()
                if Library.Design.Motion.Reduced then
                    return
                end

                Library:CancelTween(SwitchScale, "KeybindPulse")
                SwitchScale.Scale = 1.24
                Library:PlayTween(SwitchScale, "KeybindPulse", Library:GetMotion("Control"), {
                    Scale = 1,
                })
            end

            function KeybindsToggle:AnimateIn()
                if Library.Design.Motion.Reduced then
                    return
                end

                Library:CancelTween(Holder, "KeybindEnter")
                Library:CancelTween(RowScale, "KeybindEnter")

                Holder.BackgroundTransparency = 1
                RowScale.Scale = 0.94
                Library:PlayTween(RowScale, "KeybindEnter", Library:GetMotion("Popup"), { Scale = 1 })
                Library:RevealText(Holder, { Stagger = 0 })
            end

            function KeybindsToggle:UpdateColors()
                if KeybindsToggle.LabelTween then
                    StopTween(KeybindsToggle.LabelTween, true)
                    KeybindsToggle.LabelTween = nil
                end
                if KeybindsToggle.IndicatorTween then
                    StopTween(KeybindsToggle.IndicatorTween, true)
                    KeybindsToggle.IndicatorTween = nil
                end
                if KeybindsToggle.IndicatorStrokeTween then
                    StopTween(KeybindsToggle.IndicatorStrokeTween, true)
                    KeybindsToggle.IndicatorStrokeTween = nil
                end
                if KeybindsToggle.IndicatorCheckTween then
                    StopTween(KeybindsToggle.IndicatorCheckTween, true)
                    KeybindsToggle.IndicatorCheckTween = nil
                end

                local State = KeybindsToggle.DisplayState == true
                Label.TextTransparency = State and 0 or 0.5
                Switch.BackgroundColor3 = GetKeybindToggleSurfaceColor(State)
                SwitchStroke.Color = GetKeybindToggleStrokeColor(State)
                SwitchStroke.Transparency = State and 0.04 or 0.18
                Checkmark.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                Label.Text = Text
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Visibility = Visibility == true
                if KeybindsToggle.Visible == Visibility then
                    return
                end

                KeybindsToggle.Visible = Visibility

                if KeybindsToggle.VisibilityTween then
                    StopTween(KeybindsToggle.VisibilityTween, true)
                    KeybindsToggle.VisibilityTween = nil
                end

                if Visibility then
                    Holder.Visible = true
                    Holder.Size = UDim2.new(1, 0, 0, 0)
                    KeybindsToggle.VisibilityTween = TweenService:Create(Holder, Library.KeybindRowTweenInfo, {
                        Size = UDim2.new(1, 0, 0, 18),
                    })
                    KeybindsToggle.VisibilityTween:Play()
                    KeybindsToggle:AnimateIn()
                else
                    KeybindsToggle.VisibilityTween = TweenService:Create(Holder, Library.KeybindRowTweenInfo, {
                        Size = UDim2.new(1, 0, 0, 0),
                    })

                    local Tween = KeybindsToggle.VisibilityTween
                    Tween.Completed:Connect(function(State)
                        if State == Enum.PlaybackState.Completed and not KeybindsToggle.Visible and KeybindsToggle.VisibilityTween == Tween then
                            Holder.Visible = false
                        end
                    end)
                    KeybindsToggle.VisibilityTween:Play()
                end

                Library:RefreshKeybindMenu()
            end

            function KeybindsToggle:SetNormal(Normal)
                if KeybindsToggle.Normal == Normal and KeybindsToggle.NormalApplied then
                    return
                end

                KeybindsToggle.Normal = Normal
                KeybindsToggle.NormalApplied = true

                Holder.Active = not Normal
                Switch.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end 
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Switch
            KeybindsToggle.Switch = Switch
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local ModeButtons = {}
        local TotalModeButtons = GetTableSize(Info.Modes)
        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, function(Active: boolean)
            PickerCorner.TopRightRadius = Active and UDim.new(0, 0) or UDim.new(0, Library.CornerRadius / 2)
            PickerCorner.BottomRightRadius = Active and UDim.new(0, 0) or UDim.new(0, Library.CornerRadius / 2)
        end, false, if TotalModeButtons == 1 then "no_left" else "no_top_left", "KeyPicker")
        KeyPicker.Menu = MenuTable

        for Index, Mode in Info.Modes do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, IsForButton and 21 or (TotalModeButtons == 1 and 18 or 19)),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })
            
            if Index == 1 and TotalModeButtons == 1 then
                table.insert(Library.SpecificCorners, New("UICorner", {
                    TopLeftRadius = UDim.new(0, 0),
                    TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    BottomLeftRadius = UDim.new(0, 0),
                    BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                }))
            elseif Index == 1 then
                table.insert(Library.SpecificCorners, New("UICorner", {
                    TopLeftRadius = UDim.new(0, 0),
                    TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    BottomLeftRadius = UDim.new(0, 0),
                    BottomRightRadius = UDim.new(0, 0),
                    Parent = Button,
                }))
            elseif Index == TotalModeButtons then
                table.insert(Library.SpecificCorners, New("UICorner", {
                    TopLeftRadius = UDim.new(0, 0),
                    TopRightRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                    BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                }))
            end

            function ModeButton:Select()
                for _, Button in ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            Button.MouseEnter:Connect(function()
                if KeyPicker.Mode == Mode then
                    return
                end

                Library:PlayTween(Button, "KeyPickerModeHover", Library.HoverTweenInfo, {
                    BackgroundTransparency = 0.7,
                    TextTransparency = 0.1,
                })
            end)

            Button.MouseLeave:Connect(function()
                if KeyPicker.Mode == Mode then
                    return
                end

                Library:PlayTween(Button, "KeyPickerModeHover", Library.HoverTweenInfo, {
                    BackgroundTransparency = 1,
                    TextTransparency = 0.5,
                })
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local DisplayText = PickerText or KeyPicker.DisplayValue
            if IsForButton and SlideOverflow then
                if LastPickerWidth == Picker.AbsoluteSize.X then
                    return
                end

                local X, _Y = Library:GetTextBounds(
                    DisplayText,
                    Picker.FontFace,
                    Picker.TextSize,
                    10000
                )

                SlidingLabel.Text = DisplayText

                local OffsetScale = X + 9
                local PickerWidth = math.min(OffsetScale, MaxPickerWidth)
                Picker.Size = UDim2.new(0, PickerWidth, 1, 0)

                if OffsetScale > PickerWidth then
                    SlidingLabel.TextXAlignment = Enum.TextXAlignment.Left
                    SlidingLabel.Size = UDim2.new(0, OffsetScale, 1, 0)
                    SlidingLabel.Position = UDim2.fromOffset(4.5, 0)

                    RunService.RenderStepped:Wait()

                    local RealPickerWidth = Picker.AbsoluteSize.X
                    if RealPickerWidth <= 0 then RealPickerWidth = PickerWidth end

                    LastPickerWidth = RealPickerWidth

                    local OverflowDistance = OffsetScale - RealPickerWidth - 4.5
                    if OverflowDistance > 0 then
                        CancelSlidingTweens()

                        local Duration = OverflowDistance / 25
                        local TweenInfo = TweenInfo.new(
                            Duration,
                            Enum.EasingStyle.Linear, Enum.EasingDirection.InOut
                        )

                        SlideForwardTween = TweenService:Create(SlidingLabel, TweenInfo, {
                            Position = UDim2.fromOffset(-OverflowDistance, 0)
                        })

                        SlideBackTween = TweenService:Create(SlidingLabel, TweenInfo, {
                            Position = UDim2.fromOffset(4.5, 0)
                        })

                        SlideForwardTween:Play()

                        SlideForwardTween.Completed:Connect(HandleForwardTween)
                        SlideBackTween.Completed:Connect(HandleBackTween)
                    else
                        CancelSlidingTweens()

                        SlidingLabel.TextXAlignment = Enum.TextXAlignment.Center
                        SlidingLabel.Size = UDim2.new(1, 0, 1, 0)
                        SlidingLabel.Position = UDim2.new(0, 0, 0, 0)
                    end
                else
                    CancelSlidingTweens()

                    SlidingLabel.TextXAlignment = Enum.TextXAlignment.Center
                    SlidingLabel.Size = UDim2.new(1, 0, 1, 0)
                    SlidingLabel.Position = UDim2.new(0, 0, 0, 0)
                end
            else
                local X, Y = Library:GetTextBounds(
                    DisplayText,
                    Picker.FontFace,
                    Picker.TextSize,
                    ToggleLabel.AbsoluteSize.X
                )
                Picker.Text = DisplayText
                Picker.Size = IsForButton and UDim2.new(0, X + 9, 1, 0) or UDim2.fromOffset((X + 9), (Y + 4))
            end
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            if Info.NoUI or KeyPicker.Mode == "Press" then
                if KeybindsToggle.Loaded then
                    KeybindsToggle:SetVisibility(false)
                end
                return
            end

            if not KeyPicker:IsBound() then
                KeybindsToggle:SetVisibility(false)
                return
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end
        end

        function KeyPicker:IsBound()
            return KeyPicker.Value ~= "None" and KeyPicker.Value ~= "Unknown"
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if Picking then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    if Library.Toggled then
                        return false
                    end

                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key] :: any) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if Picking then
                return
            end

            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if IsForButton then
                Library:SafeCallback(ParentObj.Func, KeyPicker.Toggled)
			end
			
			if Library.ToggleKeybind == KeyPicker and Library.Toggle then
                Library:Toggle(nil, "Keybind")
            end

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:RunChanged(IsKeyValid, KeyCode)
            if IsKeyValid == nil or KeyCode == nil then
                IsKeyValid, KeyCode = pcall(function()
                    if KeyPicker.Value == "None" then
                        return nil
                    end

                    if SpecialKeys[KeyPicker.Value] == nil then
                        return Enum.KeyCode[KeyPicker.Value]
                    end

                    return SpecialKeys[KeyPicker.Value]
                end)
            end

            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, KeyCode, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, KeyCode, NewModifiers)
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, KeyCode = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers =
                VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                else KeyPicker.Value

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            KeyPicker:Update()
            KeyPicker:RunChanged(IsKeyValid, KeyCode)
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        local SetPickingState = function(State)
            Picking = State
            Library.IsPicking = State

            if ParentObj then
                ParentObj.AnyKeyPickerPicking = Picking
            end

            if IsForButton then
                ToggleLabel.Visible = not Picking
                RunService.RenderStepped:Wait()
            end

            KeyPicker:Update()
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking or Library.IsPicking then
                return
            end

            SetPickingState(true)

            if IsForButton and SlideOverflow then
                KeyPicker:Display("...")
            else
                Picker.Text = "..."
                Picker.Size = IsForButton and UDim2.new(0, 29, 1, 0) or UDim2.fromOffset(29, 18)
            end

            
            local ActiveModifiers = {}
            local CurrentInput = nil

            local IsValidInput = function(InputObj)
                if InputObj.KeyCode == Enum.KeyCode.Escape then
                    return true
                end

                local IsMod = IsModifierInput(InputObj)
                local KeyName
                if SpecialKeysInput[InputObj.UserInputType] ~= nil then
                    KeyName = SpecialKeysInput[InputObj.UserInputType]
                elseif InputObj.UserInputType == Enum.UserInputType.Keyboard then
                    if IsMod then
                        KeyName = ModifiersInput[InputObj.KeyCode]
                    else
                        KeyName = InputObj.KeyCode.Name
                    end
                end

                if KeyName then
                    if IsMod then
                        if KeyPicker.WhitelistedModifiers and #KeyPicker.WhitelistedModifiers > 0 and not table.find(KeyPicker.WhitelistedModifiers, KeyName) then
                            return false
                        end

                        if KeyPicker.BlacklistedModifiers and table.find(KeyPicker.BlacklistedModifiers, KeyName) then
                            return false
                        end
                    else
                        if KeyPicker.Whitelisted and #KeyPicker.Whitelisted > 0 and not table.find(KeyPicker.Whitelisted, KeyName) then
                            return false
                        end

                        if KeyPicker.Blacklisted and table.find(KeyPicker.Blacklisted, KeyName) then
                            return false
                        end
                    end
                end

                return true
            end

            
            while true do
                local InputObj = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() ~= nil then
                    SetPickingState(false)
                    return
                end

                if IsValidInput(InputObj) then
                    CurrentInput = InputObj
                    break
                end
            end

            
            while IsModifierInput(CurrentInput) do
                if CurrentInput.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                
                local ModName = ModifiersInput[CurrentInput.KeyCode]
                if ModName then
                    local text = if #ActiveModifiers > 0 then table.concat(ActiveModifiers, " + ") .. " + " .. ModName .. " + ..." else ModName .. " + ..."
                    KeyPicker:Display(text)
                end

                local NextInput = nil
                local Released = false

                local BeganConn
                local EndedConn

                BeganConn = UserInputService.InputBegan:Connect(function(InputObj)
                    if UserInputService:GetFocusedTextBox() ~= nil then
                        return
                    end
                    if IsValidInput(InputObj) then
                        NextInput = InputObj
                    end
                end)

                EndedConn = UserInputService.InputEnded:Connect(function(InputObj)
                    if InputObj.KeyCode == CurrentInput.KeyCode then
                        Released = true
                    end
                end)

                repeat
                    task.wait()
                until Released or NextInput or UserInputService:GetFocusedTextBox() ~= nil or Library.Unloaded

                if BeganConn then BeganConn:Disconnect() end
                if EndedConn then EndedConn:Disconnect() end

                if UserInputService:GetFocusedTextBox() ~= nil or Library.Unloaded then
                    SetPickingState(false)
                    return
                end

                if Released then
                    break 
                elseif NextInput then
                    
                    local OldModName = ModifiersInput[CurrentInput.KeyCode]
                    if OldModName and not table.find(ActiveModifiers, OldModName) then
                        ActiveModifiers[#ActiveModifiers + 1] = OldModName
                    end

                    CurrentInput = NextInput
                    if CurrentInput.KeyCode == Enum.KeyCode.Escape then
                        break
                    end
                end
            end

            local Key = "Unknown"
            if SpecialKeysInput[CurrentInput.UserInputType] ~= nil then
                Key = SpecialKeysInput[CurrentInput.UserInputType]
            elseif CurrentInput.UserInputType == Enum.UserInputType.Keyboard then
                Key = CurrentInput.KeyCode == Enum.KeyCode.Escape and "None" or CurrentInput.KeyCode.Name
            end

            ActiveModifiers = if CurrentInput.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

            KeyPicker.Toggled = if ParentObj.Type == "Toggle" then ParentObj.Value else false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            repeat
                task.wait()
            until not IsInputDown(CurrentInput) or UserInputService:GetFocusedTextBox()

            SetPickingState(false)
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        table.insert(KeyPicker.Connections, UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            local IsMouse = IsMouseClickInput(Input)
            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or Library.IsPicking
                or UserInputService:GetFocusedTextBox()
                or (IsMouse and Library.Toggled)
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and (
                    SpecialKeysInput[Input.UserInputType] == Key
                    or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                )
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        table.insert(KeyPicker.Connections, UserInputService.InputEnded:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            local IsMouse = IsMouseClickInput(Input)
            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or Library.IsPicking
                or UserInputService:GetFocusedTextBox()
                or (IsMouse and Library.Toggled)
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        function KeyPicker:Destroy()
            if KeyPicker.Destroyed then
                return
            end

            KeyPicker.Destroyed = true

            if KeyPicker.Connections then
                for _, Connection in KeyPicker.Connections do
                    Connection:Disconnect()
                end
                table.clear(KeyPicker.Connections)
            end

            if KeybindsToggle and KeybindsToggle.Loaded then
                if KeybindsToggle.Holder then 
                    KeybindsToggle.Holder:Destroy()
                end
                local KTIdx = table.find(Library.KeybindToggles, KeybindsToggle)
                if KTIdx then
                    table.remove(Library.KeybindToggles, KTIdx)
                end
            end

            if MenuTable then 
                MenuTable:Destroy() 
            end

            if IsForButton and SlideOverflow then
                if SlideForwardTween then 
                    SlideForwardTween:Destroy() 
                end

                if SlideBackTween then 
                    SlideBackTween:Destroy() 
                end
            end

            if Picker then
                Picker:Destroy()
            end

            if ParentObj and ParentObj.Addons then
                local AddonIdx = table.find(ParentObj.Addons, KeyPicker)
                
                if AddonIdx then 
                    table.remove(ParentObj.Addons, AddonIdx) 
                end
            end

            Options[Idx] = nil
        end

        Options[Idx] = KeyPicker

        return self
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Connections = {},
            Destroyed = false,

            Value = Info.Default,

            Transparency = math.clamp(tonumber(Info.Transparency) or 0, 0, 1),
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = "RaisedColor",
            ClipsDescendants = true,
            Size = UDim2.fromOffset(36, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        local HolderStroke = New("UIStroke", {
            Color = "OutlineColor",
            Transparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
            Parent = Holder,
        })

        local ColorPickerCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Holder,
        }); table.insert(Library.SpecificCorners, ColorPickerCorner)

        local HolderTransparency = New("ImageLabel", {
            Image = CustomImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Tile,
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.new(1, -6, 1, -6),
            TileSize = UDim2.fromOffset(6, 6),
            Parent = Holder,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, math.max(1, Library.CornerRadius / 2 - 1)),
                Parent = HolderTransparency,
            })
        )

        local HolderColor = New("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BackgroundTransparency = ColorPicker.Transparency,
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.new(1, -6, 1, -6),
            Parent = Holder,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, math.max(1, Library.CornerRadius / 2 - 1)),
                Parent = HolderColor,
            })
        )

        table.insert(ColorPicker.Connections, Holder.MouseEnter:Connect(function()
            Library:PlayTween(HolderStroke, "ColorPickerSwatchHover", Library:GetMotion("Hover"), {
                Color = Library.Scheme.AccentColor,
                Transparency = 0.08,
            })
        end))
        table.insert(ColorPicker.Connections, Holder.MouseLeave:Connect(function()
            Library:PlayTween(HolderStroke, "ColorPickerSwatchHover", Library:GetMotion("Hover"), {
                Color = Library.Scheme.OutlineColor,
                Transparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
            })
        end))

        
        local ColorMenu = Library:AddContextMenu(
            Holder,
            UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
            function()
                return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
            end,
            1, function(Active: boolean)
                ColorPickerCorner.BottomRightRadius = Active and UDim.new(0, 0) or UDim.new(0, Library.CornerRadius / 2)
                ColorPickerCorner.BottomLeftRadius = Active and UDim.new(0, 0) or UDim.new(0, Library.CornerRadius / 2)
            end, false, "no_top_left")
        ColorMenu.List.Padding = UDim.new(0, 0)
        ColorPicker.ColorMenu = ColorMenu

        
        local ContentHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            Parent = ContentHolder,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = ContentHolder,
        })

        
        local FooterHeight = Library.IsMobile and 30 or 22

        local FooterBackground = New("Frame", {
            BackgroundColor3 = "SurfaceColor",
            Size = UDim2.new(1, 0, 0, FooterHeight),
            Parent = ColorMenu.Menu,
        })
        table.insert(
            Library.SpecificCorners,
            New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = FooterBackground,
            })
        )
        Library:MakeLine(FooterBackground, {
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.new(1, 0, 0, 1),
        })

        local FooterBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = FooterBackground,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, Info.Resizable and (FooterHeight + 4) or 6),
            Parent = FooterBar,
        })

        local FooterInfoLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            TextTransparency = 0.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = FooterBar,
        })

        local function RefreshFooterInfo()
            FooterInfoLabel.Text = string.format(
                "#%s • %d, %d, %d",
                ColorPicker.Value:ToHex(),
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255)
            )
        end
        RefreshFooterInfo()

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 8),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ContentHolder,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = ContentHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        
        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = CustomImageManager.GetAsset("SaturationMap"),
            Size = UDim2.fromOffset(200, 200),
            Parent = ColorHolder,
        })

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "DarkColor",
            Parent = SatVibCursor,
        })

        
        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            BorderColor3 = "DarkColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                Image = CustomImageManager.GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                BorderColor3 = "DarkColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        
        local ResizeGrabber
        if Info.Resizable then
            local BaseMapSize = 200
            local BaseBarWidth = 16
            local BasePadding = 6
            local MinMapSize = 140

            ColorPicker.MapWidth = BaseMapSize
            ColorPicker.MapHeight = BaseMapSize

            local function GetBarWidth(MapWidth)
                return math.clamp(math.floor((MapWidth / BaseMapSize) * BaseBarWidth + 0.5), 12, 24)
            end

            local function GetContentWidth(MapWidth)
                local BarWidth = GetBarWidth(MapWidth)
                local Width = MapWidth + BarWidth + BasePadding
                if Info.Transparency then
                    Width += (BarWidth + BasePadding)
                end

                return Width + 12
            end

            local FixedVerticalOverhead = 6 + 6 + 8 + 20 + 8 + 20 + FooterHeight
            if typeof(ColorPicker.Title) == "string" then
                FixedVerticalOverhead += 8 + 8
            end

            local function ClampToViewport(NewWidth, NewHeight)
                local ViewportSize = GetViewportSize()
                local ScreenMargin = 12

                local MaxWidth = ViewportSize.X - ColorMenu.Menu.AbsolutePosition.X - ScreenMargin
                local MaxHeight = ViewportSize.Y - ColorMenu.Menu.AbsolutePosition.Y - ScreenMargin - FixedVerticalOverhead

                while NewWidth > MinMapSize and GetContentWidth(NewWidth) > MaxWidth do
                    NewWidth -= 4
                end

                if NewHeight > MaxHeight then
                    NewHeight = math.max(MinMapSize, math.floor(MaxHeight))
                end

                return NewWidth, NewHeight
            end

            local function UpdateColorMenuSize(NewWidth, NewHeight)
                NewWidth = math.max(MinMapSize, math.floor(NewWidth + 0.5))
                NewHeight = math.max(MinMapSize, math.floor(NewHeight + 0.5))
                NewWidth, NewHeight = ClampToViewport(NewWidth, NewHeight)

                if NewWidth == ColorPicker.MapWidth and NewHeight == ColorPicker.MapHeight then
                    return
                end

                local BarWidth = GetBarWidth(NewWidth)
                local CursorSize = math.clamp(math.floor((math.min(NewWidth, NewHeight) / BaseMapSize) * 6 + 0.5), 4, 10)

                ColorHolder.Size = UDim2.new(1, 0, 0, NewHeight)
                SatVipMap.Size = UDim2.fromOffset(NewWidth, NewHeight)
                SatVibCursor.Size = UDim2.fromOffset(CursorSize, CursorSize)
                HueSelector.Size = UDim2.new(0, BarWidth, 0, NewHeight)

                if TransparencySelector then
                    TransparencySelector.Size = UDim2.new(0, BarWidth, 0, NewHeight)
                end

                ColorPicker.MapWidth = NewWidth
                ColorPicker.MapHeight = NewHeight
                ColorMenu:SetSize(UDim2.new(0, GetContentWidth(NewWidth), 0, 0))
            end

            ResizeGrabber = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -Library.CornerRadius / 4, 0, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = FooterBackground,
            })
            New("ImageLabel", {
                Image = ResizeIcon and ResizeIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.5,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = ResizeGrabber,
            })

            table.insert(ColorPicker.Connections, ResizeGrabber.InputBegan:Connect(function(Input: InputObject)
                Library.CantDragForced = true
                local StartMouse = Vector2.new(Mouse.X, Mouse.Y)
                local StartWidth = ColorPicker.MapWidth
                local StartHeight = ColorPicker.MapHeight

                while IsDragInput(Input) and not ColorPicker.Destroyed do
                    local Delta = Vector2.new(Mouse.X, Mouse.Y) - StartMouse
                    UpdateColorMenuSize(StartWidth + Delta.X, StartHeight + Delta.Y)

                    RunService.RenderStepped:Wait()
                end

                Library.CantDragForced = false
            end))
        end

        local InfoHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ContentHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local HueBoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = HueBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HueBox,
            })
        )

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local RgbBoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = RgbBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = RgbBox,
            })
        )

        
        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, function(Active: boolean)
            ColorPickerCorner.TopRightRadius = Active and UDim.new(0, 0) or UDim.new(0, Library.CornerRadius / 2)
            ColorPickerCorner.BottomRightRadius = Active and UDim.new(0, 0) or UDim.new(0, Library.CornerRadius / 2)
        end, false, "no_top_left")
        ColorPicker.ContextMenu = ContextMenu
        ContextMenu.List.Padding = UDim.new(0, 6)
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)

                Button.MouseEnter:Connect(function()
                    Library:PlayTween(Button, "ColorContextHover", Library.HoverTweenInfo, {
                        BackgroundTransparency = 0.7,
                    })
                end)

                Button.MouseLeave:Connect(function()
                    Library:PlayTween(Button, "ColorContextHover", Library.HoverTweenInfo, {
                        BackgroundTransparency = 1,
                    })
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end 
            CreateButton("Paste color", function()
                if not Library.CopiedColor then
                    return
                end

                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)

                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        
        local ActionHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ContentHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = ActionHolder,
        })

        local CopyColorButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            Text = "Copy color",
            TextSize = 14,
            Parent = ActionHolder,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = CopyColorButton,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = CopyColorButton,
            })
        )

        local PasteColorButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            Text = "Paste color",
            TextSize = 14,
            Parent = ActionHolder,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = PasteColorButton,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = PasteColorButton,
            })
        )

        local CopyColorOriginalText = CopyColorButton.Text
        local PasteColorOriginalText = PasteColorButton.Text
        local CopyColorResetId = 0
        local PasteColorResetId = 0

        table.insert(ColorPicker.Connections, CopyColorButton.MouseEnter:Connect(function()
            Library:PlayTween(CopyColorButton, "CopyColorHover", Library.TweenInfo, {
                BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 10),
            })
        end))

        table.insert(ColorPicker.Connections, CopyColorButton.MouseLeave:Connect(function()
            Library:PlayTween(CopyColorButton, "CopyColorHover", Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.MainColor,
            })
        end))

        table.insert(ColorPicker.Connections, PasteColorButton.MouseEnter:Connect(function()
            Library:PlayTween(PasteColorButton, "PasteColorHover", Library.TweenInfo, {
                BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 10),
            })
        end))

        table.insert(ColorPicker.Connections, PasteColorButton.MouseLeave:Connect(function()
            Library:PlayTween(PasteColorButton, "PasteColorHover", Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.MainColor,
            })
        end))

        table.insert(ColorPicker.Connections, CopyColorButton.MouseButton1Click:Connect(function()
            Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }

            CopyColorResetId += 1
            local ThisResetId = CopyColorResetId
            CopyColorButton.Text = "Copied color"

            task.delay(1, function()
                if ColorPicker.Destroyed or ThisResetId ~= CopyColorResetId then
                    return
                end

                CopyColorButton.Text = CopyColorOriginalText
            end)
        end))

        table.insert(ColorPicker.Connections, PasteColorButton.MouseButton1Click:Connect(function()
            PasteColorResetId += 1
            local ThisResetId = PasteColorResetId

            if not Library.CopiedColor then
                PasteColorButton.Text = "Nothing to paste"
            else
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
                PasteColorButton.Text = "Pasted color"
            end

            task.delay(1, function()
                if ColorPicker.Destroyed or ThisResetId ~= PasteColorResetId then
                    return
                end

                PasteColorButton.Text = PasteColorOriginalText
            end)
        end))

        
        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            HolderColor.BackgroundColor3 = ColorPicker.Value
            HolderColor.BackgroundTransparency = ColorPicker.Transparency

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")

            RefreshFooterInfo()
        end

        function ColorPicker:RunChanged()
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value, ColorPicker.Transparency)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value, ColorPicker.Transparency)
        end

        function ColorPicker:Update()
            ColorPicker:Display()
            ColorPicker:RunChanged()
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency ~= nil and math.clamp(tonumber(Transparency) or ColorPicker.Transparency or 0, 0, 1) or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            assert(typeof(Color) == "Color3", "ColorPicker:SetValueRGB expects Color3")
            ColorPicker.Transparency = Info.Transparency ~= nil and math.clamp(tonumber(Transparency) or ColorPicker.Transparency or 0, 0, 1) or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        table.insert(ColorPicker.Connections, Holder.MouseButton1Click:Connect(ColorMenu.Toggle))
        table.insert(ColorPicker.Connections, Holder.MouseButton2Click:Connect(ContextMenu.Toggle))

        table.insert(ColorPicker.Connections, SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) and not ColorPicker.Destroyed do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end))

        table.insert(ColorPicker.Connections, HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) and not ColorPicker.Destroyed do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end))
        
        if TransparencySelector then
            table.insert(ColorPicker.Connections, TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) and not ColorPicker.Destroyed do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end))
        end

        table.insert(ColorPicker.Connections, HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end))

        table.insert(ColorPicker.Connections, RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end))

        for _, BoxPair in { 
            { HueBox, HueBoxStroke }, 
            { RgbBox, RgbBoxStroke } 
        } do
            local TextBoxInstance, Stroke = BoxPair[1], BoxPair[2]

            table.insert(ColorPicker.Connections, TextBoxInstance.Focused:Connect(function()
                Library.Registry[Stroke].Color = "AccentColor"
                Library:PlayTween(Stroke, "ColorPickerInputStroke", Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                })
            end))

            table.insert(ColorPicker.Connections, TextBoxInstance.FocusLost:Connect(function()
                Library.Registry[Stroke].Color = "OutlineColor"
                Library:PlayTween(Stroke, "ColorPickerInputStroke", Library.TweenInfo, {
                    Color = Library.Scheme.OutlineColor,
                })
            end))
        end

        ColorPicker:Display()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value
        ColorPicker.DefaultTransparency = ColorPicker.Transparency

        function ColorPicker:Destroy()
            if ColorPicker.Destroyed then
                return
            end

            ColorPicker.Destroyed = true

            if ColorPicker.Connections then
                for _, Connection in ColorPicker.Connections do
                    Connection:Disconnect()
                end
            end

            if ColorMenu then 
                ColorMenu:Destroy() 
            end

            if ResizeGrabber then
                ResizeGrabber:Destroy()
            end

            if ContextMenu then 
                ContextMenu:Destroy() 
            end

            if Holder then 
                Holder:Destroy() 
            end

            if ParentObj and ParentObj.Addons then
                local AddonIdx = table.find(ParentObj.Addons, ColorPicker)
                
                if AddonIdx then 
                    table.remove(ParentObj.Addons, AddonIdx) 
                end
            end

            Options[Idx] = nil
        end

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    local function CancelToggleConfirmation(Toggle)
        local Dialog = Toggle.ConfirmationDialog
        Toggle.ConfirmationPending = false
        Toggle.ConfirmationDialog = nil

        if Dialog and not Dialog.Destroyed then
            Dialog:Dismiss()
        end
    end

    local function RequestToggleValue(Toggle, Groupbox, Value)
        if Toggle.Disabled or Toggle.Destroyed then
            return
        end

        Value = Value == true
        if Toggle.Value == Value then
            return
        end

        local NeedsConfirmation = Value and Toggle.StyleVariant == "Danger" and Toggle.ConfirmDanger ~= false
        if not NeedsConfirmation then
            Toggle:SetValue(Value)
            return
        end

        local Window = Groupbox.Tab and Groupbox.Tab.Window
        if Toggle.ConfirmationPending or Library.ActiveDialog or not Window then
            return
        end

        Toggle.ConfirmationPending = true
        local Dialog = Window:AddDialog("DangerToggle:" .. tostring(Toggle), {
            Title = Toggle.ConfirmTitle or ("Enable " .. Toggle.Text .. "?"),
            Description = Toggle.ConfirmDescription or "This change may affect your session.",
            Icon = "triangle-alert",
            TitleColor = "DestructiveColor",
            AutoDismiss = true,
            OutsideClickDismiss = false,
            OnDismiss = function()
                Toggle.ConfirmationPending = false
                Toggle.ConfirmationDialog = nil
            end,
            FooterButtons = {
                Cancel = {
                    Title = "Cancel",
                    Variant = "Ghost",
                    Order = 1,
                },
                Continue = {
                    Title = "Continue",
                    Variant = "Primary",
                    Order = 2,
                    Callback = function()
                        Toggle.ConfirmationPending = false
                        Toggle.ConfirmationDialog = nil

                        if not Toggle.Destroyed and not Toggle.Disabled and Toggle.StyleVariant == "Danger" and not Toggle.Value then
                            Toggle:SetValue(true)
                        end
                    end,
                },
            },
        })

        Toggle.ConfirmationDialog = Dialog
        if not Dialog then
            Toggle.ConfirmationPending = false
        end
    end

    function Funcs:AddDivider(...)
        if self.Destroyed then return nil end

        local Params = select(1, ...)
        local Text
        local MarginTop = 0
        local MarginBottom = 0

        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 0
            MarginBottom = Params.MarginBottom or Params.Margin or 0
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, (Text and 20 or 6) + MarginTop + MarginBottom),
            Parent = Container,
        })

        local InnerHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingTop = UDim.new(0, MarginTop),
            PaddingBottom = UDim.new(0, MarginBottom),
            Parent = Holder,
        })

        local Lines = {}
        local DividerConnections = {}
        local TextLabel
        if Text then
            TextLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = Text,
                TextSize = Library:GetDesignToken("Size.Caption", 12),
                TextColor3 = "MutedFontColor",
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = InnerHolder,
            })
        end
        for Index = 1, Text and 2 or 1 do
            Lines[Index] = New("Frame", {
                BackgroundColor3 = "OutlineColor",
                BackgroundTransparency = function()
                    return Library:GetDesignToken("Effects.Dividers", false) and 0.6 or 1
                end,
                BorderSizePixel = 0,
                Parent = InnerHolder,
            })
        end
        local function LayoutLines()
            local Width = math.max(0, math.floor(InnerHolder.AbsoluteSize.X))
            local Top = math.floor(InnerHolder.AbsoluteSize.Y / 2)
            local Length = Width
            if TextLabel then
                local TextWidth = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, Width)
                Length = math.max(0, math.floor((Width - TextWidth) / 2) - 8)
            end
            Lines[1].Position = UDim2.fromOffset(0, Top)
            Lines[1].Size = UDim2.fromOffset(Length, 1)
            if Lines[2] then
                Lines[2].Position = UDim2.fromOffset(Width - Length, Top)
                Lines[2].Size = UDim2.fromOffset(Length, 1)
            end
        end
        table.insert(DividerConnections, InnerHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutLines))
        if TextLabel then
            table.insert(DividerConnections, TextLabel:GetPropertyChangedSignal("FontFace"):Connect(LayoutLines))
        end
        LayoutLines()
        Groupbox:Resize()

        local Divider = {
            Connections = DividerConnections,
            Destroyed = false,

            Holder = Holder,
            Text = Text,
            MarginTop = MarginTop,
            MarginBottom = MarginBottom,
            Type = "Divider",
        }

        function Divider:SetVisible(Value)
            Holder.Visible = Value == true
            Groupbox:Resize()
        end

        function Divider:Destroy()
            if Divider.Destroyed then
                return
            end

            Divider.Destroyed = true

            if Divider.Connections then
                for _, Connection in Divider.Connections do
                    Connection:Disconnect()
                end
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Divider)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
        end

        table.insert(Groupbox.Elements, Divider)
        return Divider
    end

    function Funcs:AddLabel(...)
        if self.Destroyed then return nil end

        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Label = {
            Connections = {},
            Destroyed = false,

            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Library:Metric("Row", 24)),
            Text = Label.Text,
            TextSize = Data.Size,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Container,
        })

        function Label:Display()
            if not Label.DoesWrap then
                return
            end

            local Width = TextLabel.AbsoluteSize.X
            if Width <= 0 then return end

            local _, Y = Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, Width)
            TextLabel.Size = UDim2.new(1, 0, 0, Library:Snap(Y) + 4)
        end

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Groupbox:Resize()
        end

        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text

            Label:Display()
            Groupbox:Resize()
        end

        if Label.DoesWrap then
            Label:Display()

            local Last = TextLabel.AbsoluteSize
            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                Label:Display()
                Last = TextLabel.AbsoluteSize

                Groupbox:Resize()
            end)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        Groupbox:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Label.Holder = TextLabel
        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        function Label:Destroy()
            if Label.Destroyed then
                return
            end

            Label.Destroyed = true

            if Label.Connections then
                for _, Connection in Label.Connections do
                    Connection:Disconnect()
                end
            end

            if Label.Addons then
                for Index = #Label.Addons, 1, -1 do
                    local Addon = table.remove(Label.Addons, Index)
                    if Addon and Addon.Destroy then
                        Addon:Destroy()
                    end
                end
            end

            if TextLabel then 
                TextLabel:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Label)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()

            if Data.Idx then
                Labels[Data.Idx] = nil
            else
                local LblIdx = table.find(Labels, Label)
                
                if LblIdx then 
                    table.remove(Labels, LblIdx) 
                end
            end
        end

        return Label
    end

    function Funcs:AddButton(...)
        if self.Destroyed then return nil end

        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick
                Info.Variant = Params.Variant
                Info.Icon = Params.Icon
                Info.IconColor = Params.IconColor

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible ~= false
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false
                Info.Variant = nil
                Info.Icon = nil
                Info.IconColor = nil

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Groupbox = self
        local Container = Groupbox.Container

        local Button = {
            Connections = {},
            Addons = {},
            Destroyed = false,

            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,
            Variant = Library:NormalizeButtonVariant(Info.Variant, Info.Risky),
            Icon = Info.Icon,
            IconColor = Info.IconColor,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Library:GetDesignToken("Size.Control", 25)),
            Parent = Container,
        })

        local ButtonGap = Library:GetDesignToken("Spacing.Medium", 8)

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, ButtonGap),
            Parent = Holder,
        })

        local ButtonBases = {}

        local function ResizeButtons()
            local Visible = {}
            for _, Base in ButtonBases do
                if Base.Visible then
                    table.insert(Visible, Base)
                end
            end

            local Count = #Visible
            if Count == 0 then
                return
            end

            local Total = math.floor(Holder.AbsoluteSize.X)
            if Total <= 0 then
                for _, Base in Visible do
                    Base.Size = UDim2.new(1 / Count, 0, 1, 0)
                end
                return
            end

            local Available = Total - ButtonGap * (Count - 1)
            local Share = math.max(1, math.floor(Available / Count))
            for Index, Base in Visible do
                local Width = Index == Count and (Available - Share * (Count - 1)) or Share
                Base.Size = UDim2.new(0, Width, 1, 0)
            end
        end

        Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeButtons)

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                ClipsDescendants = true,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Visible = Button.Visible,
                Parent = Holder,
            })
            table.insert(ButtonBases, Base)
            Base:GetPropertyChangedSignal("Visible"):Connect(ResizeButtons)
            task.defer(ResizeButtons)

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.68 or Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
                Parent = Base,
            })

            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Control", math.max(Library.CornerRadius / 2, 2))) end,
                    Parent = Base,
                })
            )

            local Content = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(0, 14),
                Parent = Base,
            })

            local function CenterButtonContent()
                Content.Position = UDim2.new(
                    0,
                    Library:CenterOffset(Base.AbsoluteSize.X, Content.AbsoluteSize.X),
                    0.5,
                    0
                )
            end

            Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(CenterButtonContent)
            Base:GetPropertyChangedSignal("AbsoluteSize"):Connect(CenterButtonContent)
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = Content,
            })
            local IconImage = New("ImageLabel", {
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.fromOffset(14, 14),
                Visible = false,
                Parent = Content,
            })
            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Size = UDim2.fromOffset(0, 14),
                Text = Button.Text,
                TextSize = Library:GetDesignToken("Size.Text", 14),
                TextTransparency = 0.12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Content,
            })

            return Base, Stroke, Label, IconImage
        end

        local function UpdateButtonIcon(Button)
            local IconData = ResolveButtonIcon(Button.Icon)
            if not IconData then
                Button.IconImage.Visible = false
                return
            end

            Button.IconImage.Image = IconData.Url
            Button.IconImage.ImageRectOffset = IconData.ImageRectOffset
            Button.IconImage.ImageRectSize = IconData.ImageRectSize
            Button.IconImage.Visible = true
        end

        local function ApplyButtonIconStyle(Button, Hovered: boolean?, Animate: boolean?)
            if not Button.IconImage.Visible then
                return
            end

            local Style = GetCachedButtonStyle(Button)
            local UseHover = Hovered == true and not Button.Disabled
            local Color = Button.Disabled and Style.TextColor or Button.IconColor or (UseHover and Style.HoverTextColor or Style.TextColor)
            local Transparency = UseHover and Style.HoverTextTransparency or Style.TextTransparency

            if Animate then
                Library:PlayTween(Button.IconImage, "ButtonIcon", Library.TweenInfo, {
                    ImageColor3 = Color,
                    ImageTransparency = Transparency,
                })
                return
            end

            Library:CancelTween(Button.IconImage, "ButtonIcon")
            Button.IconImage.ImageColor3 = Color
            Button.IconImage.ImageTransparency = Transparency
        end

        local function UpdateButtonStyleRegistry(Button)
            local BaseRegistry = Library.Registry[Button.Base] or {}
            BaseRegistry.BackgroundColor3 = function()
                return GetCachedButtonStyle(Button).BackgroundColor
            end
            BaseRegistry.BackgroundTransparency = function()
                return GetCachedButtonStyle(Button).BackgroundTransparency
            end
            Library.Registry[Button.Base] = BaseRegistry

            local LabelRegistry = Library.Registry[Button.Label] or {}
            LabelRegistry.TextColor3 = function()
                return GetCachedButtonStyle(Button).TextColor
            end
            LabelRegistry.TextTransparency = function()
                return GetCachedButtonStyle(Button).TextTransparency
            end
            Library.Registry[Button.Label] = LabelRegistry

            local IconRegistry = Library.Registry[Button.IconImage] or {}
            IconRegistry.ImageColor3 = function()
                local Style = GetCachedButtonStyle(Button)
                return Button.Disabled and Style.TextColor or Button.IconColor or Style.TextColor
            end
            IconRegistry.ImageTransparency = function()
                return GetCachedButtonStyle(Button).TextTransparency
            end
            Library.Registry[Button.IconImage] = IconRegistry

            local StrokeRegistry = Library.Registry[Button.Stroke] or {}
            StrokeRegistry.Color = function()
                return GetCachedButtonStyle(Button).OutlineColor
            end
            StrokeRegistry.Transparency = function()
                return GetCachedButtonStyle(Button).OutlineTransparency
            end
            Library.Registry[Button.Stroke] = StrokeRegistry
        end

        local function ApplyButtonStyle(Button, Hovered: boolean?, Animate: boolean?)
            local Style = GetCachedButtonStyle(Button)
            ApplyButtonVisual(
                Button.Base,
                Button.Stroke,
                Button.Label,
                Button.Variant,
                Button.Disabled,
                Hovered,
                Animate,
                "Button",
                Style
            )
            ApplyButtonIconStyle(Button, Hovered, Animate)
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                ApplyButtonStyle(Button, true, true)
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                ApplyButtonStyle(Button, false, true)
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Label.Text = "Are you sure?"
                    Button.Label.TextColor3 = Library.Scheme.AccentColor

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Label.Text = Button.Text
                    Button:UpdateColors()

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() 
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke, Button.Label, Button.IconImage = CreateButton(Button)
        UpdateButtonStyleRegistry(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Connections = {},
                Addons = {},
                Destroyed = false,

                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,
                Variant = Library:NormalizeButtonVariant(Info.Variant, Info.Risky),
                Icon = Info.Icon,
                IconColor = Info.IconColor,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke, SubButton.Label, SubButton.IconImage = CreateButton(SubButton)
            UpdateButtonStyleRegistry(SubButton)
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                ApplyButtonStyle(SubButton, false, false)
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVariant(Variant: string)
                SubButton.Variant = Library:NormalizeButtonVariant(Variant, SubButton.Risky)
                SubButton:UpdateIcon()
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Groupbox:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Label.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            function SubButton:UpdateIcon()
                UpdateButtonIcon(SubButton)
            end

            function SubButton:SetIcon(Icon: string | number | boolean?, IconColor: Color3?)
                SubButton.Icon = Icon
                if IconColor ~= nil then
                    SubButton.IconColor = IconColor
                end
                SubButton:UpdateIcon()
                SubButton:UpdateColors()
            end

            SubButton:UpdateIcon()
            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            SubButton.AddKeyPicker = BaseAddons.__index.AddKeyPicker

            function SubButton:Destroy()
                if SubButton.Destroyed then
                    return
                end

                SubButton.Destroyed = true

                for _, Addon in table.clone(SubButton.Addons) do
                    if Addon.Destroy then
                        Addon:Destroy()
                    end
                end
                table.clear(SubButton.Addons)

                if SubButton.TooltipTable then 
                    SubButton.TooltipTable:Destroy() 
                end

                if SubButton.Tween then 
                    SubButton.Tween:Destroy() 
                end

                if SubButton.Base then 
                    SubButton.Base:Destroy() 
                end

                if Info.Idx then
                    Buttons[Info.Idx] = nil
                else
                    local BIdx = table.find(Buttons, SubButton)
                    
                    if BIdx then 
                        table.remove(Buttons, BIdx) 
                    end
                end
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            ApplyButtonStyle(Button, false, false)
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVariant(Variant: string)
            Button.Variant = Library:NormalizeButtonVariant(Variant, Button.Risky)
            Button:UpdateIcon()
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Groupbox:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Label.Text = Text
        end

        function Button:UpdateIcon()
            UpdateButtonIcon(Button)
        end

        function Button:SetIcon(Icon: string | number | boolean?, IconColor: Color3?)
            Button.Icon = Icon
            if IconColor ~= nil then
                Button.IconColor = IconColor
            end
            Button:UpdateIcon()
            Button:UpdateColors()
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        Button:UpdateIcon()
        Button:UpdateColors()
        Groupbox:Resize()

        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        Button.AddKeyPicker = BaseAddons.__index.AddKeyPicker

        function Button:Destroy()
            if Button.Destroyed then
                return
            end

            Button.Destroyed = true

            for _, Addon in table.clone(Button.Addons) do
                if Addon.Destroy then
                    Addon:Destroy()
                end
            end
            table.clear(Button.Addons)

            if Button.TooltipTable then 
                Button.TooltipTable:Destroy() 
            end

            if Button.Tween then 
                Button.Tween:Destroy() 
            end

            if Button.SubButton then 
                Button.SubButton:Destroy() 
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Button)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()

            if Info.Idx then
                Buttons[Info.Idx] = nil
            else
                local BIdx = table.find(Buttons, Button)
                
                if BIdx then 
                    table.remove(Buttons, BIdx) 
                end
            end
        end

        return Button
    end

    function Funcs:AddCheckbox(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            ConfirmDanger = Info.ConfirmDanger,
            ConfirmTitle = Info.ConfirmTitle,
            ConfirmDescription = Info.ConfirmDescription,
            ConfirmationPending = false,
            ConfirmationDialog = nil,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            StyleVariant = NormalizeToggleVariant(Info.Variant, Info.Risky),

            Addons = {},
            AnyKeyPickerPicking = false,

            Variant = "Checkbox",
            Type = "Toggle",
        }

        local RowHeight = Library:Metric("Row", 24)
        local IndicatorSize = Library:MatchParity(RowHeight, Library:Metric("Indicator", 16))
        local LabelInset = IndicatorSize + Library:Metric("IndicatorGap", 9)

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, RowHeight),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(LabelInset, 0),
            Size = UDim2.new(1, -LabelInset, 1, 0),
            Text = Toggle.Text,
            TextSize = Library:GetDesignToken("Size.Text", 14),
            TextTransparency = Library:GetDesignToken("Opacity.MutedText", 0.42),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromOffset(0, Library:CenterOffset(RowHeight, IndicatorSize)),
            Size = UDim2.fromOffset(IndicatorSize, IndicatorSize),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Indicator", 3)) end,
            Parent = Checkbox,
        })
        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Transparency = Library:GetDesignToken("Stroke.StrongTransparency", 0.18),
            Parent = Checkbox,
        })

        local CheckIcon = Library:GetCustomIcon("check")
        local CheckSize = Library:GlyphSize(IndicatorSize, 14)
        local Checkmark = New("ImageLabel", {
            BackgroundTransparency = 1,
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = function()
                return Library:GetContrastColor(GetToggleSurfaceColor(Toggle))
            end,
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = Toggle.Value and 0 or 1,
            Position = UDim2.fromOffset(
                Library:CenterOffset(IndicatorSize, CheckSize),
                Library:CenterOffset(IndicatorSize, CheckSize)
            ),
            ResampleMode = Enum.ResamplerMode.Default,
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromOffset(CheckSize, CheckSize),
            Parent = Checkbox,
        })
        local CheckRestScale = math.max(1, CheckSize - 2) / CheckSize
        local CheckmarkScale = New("UIScale", {
            Scale = Toggle.Value and 1 or CheckRestScale,
            Parent = Checkmark,
        })

        local function SetCheckmarkTransparency(Value)
            Checkmark.ImageTransparency = Value
        end

        local function TweenCheckmarkTransparency(Value)
            Library:PlayTween(Checkmark, "CheckboxCheckmark", Library.TweenInfo, {
                ImageTransparency = Value,
            })
        end

        local function CancelCheckmarkTweens()
            Library:CancelTween(Checkmark, "CheckboxCheckmark")
        end

        RegisterToggleTheme(Toggle, Checkbox, CheckboxStroke, Label)
        Library:AddToRegistry(Checkmark, {
            ImageColor3 = function()
                return Library:GetContrastColor(GetToggleSurfaceColor(Toggle))
            end,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local BackgroundColor = GetToggleSurfaceColor(Toggle)
            local StrokeColor = GetToggleStrokeColor(Toggle)
            local LabelColor = GetToggleLabelColor(Toggle.StyleVariant, Toggle.Value)

            Checkmark.ImageColor3 = Library:GetContrastColor(BackgroundColor)

            if Toggle.Disabled then
                Library:CancelTween(Checkbox, "CheckboxColor")
                Library:CancelTween(CheckboxStroke, "CheckboxStroke")
                Library:CancelTween(Label, "CheckboxLabelColor")
                Library:CancelTween(Label, "CheckboxLabelTransparency")
                CancelCheckmarkTweens()
                Library:CancelTween(CheckmarkScale, "CheckboxCheckmarkScale")
                Label.TextColor3 = LabelColor
                Label.TextTransparency = 0.8
                Checkbox.BackgroundColor3 = BackgroundColor
                Checkbox.BackgroundTransparency = 0.35
                CheckboxStroke.Color = StrokeColor
                CheckboxStroke.Transparency = 0.65
                SetCheckmarkTransparency(Toggle.Value and 0.58 or 1)

                return
            end

            Checkbox.BackgroundTransparency = 0
            CheckboxStroke.Transparency = Toggle.Value and 0.04 or 0.18

            Library:PlayTween(Checkbox, "CheckboxColor", Library.TweenInfo, {
                BackgroundColor3 = BackgroundColor,
            })
            Library:PlayTween(CheckboxStroke, "CheckboxStroke", Library.TweenInfo, {
                Color = StrokeColor,
            })
            Library:PlayTween(Label, "CheckboxLabelColor", Library.TweenInfo, {
                TextColor3 = LabelColor,
            })
            Library:PlayTween(Label, "CheckboxLabelTransparency", Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or Library:GetDesignToken("Opacity.MutedText", 0.38),
            })
            TweenCheckmarkTransparency(Toggle.Value and 0 or 1)
            Library:PlayTween(CheckmarkScale, "CheckboxCheckmarkScale", Library.TweenInfo, {
                Scale = Toggle.Value and 1 or CheckRestScale,
            })
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:RunChanged()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Value = Value == true
            if Toggle.Value == Value then
                return
            end

            if Toggle.ConfirmationPending then
                CancelToggleConfirmation(Toggle)
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:QueueDependencyUpdate()

            if not Toggle.AnyKeyPickerPicking then
                Toggle:RunChanged()
            end
        end

        function Toggle:SetDisabled(Disabled: boolean)
            if Toggle.Disabled == Disabled then
                return
            end

            if Disabled then
                CancelToggleConfirmation(Toggle)
            end

            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVariant(Variant: string)
            CancelToggleConfirmation(Toggle)
            Toggle.StyleVariant = NormalizeToggleVariant(Variant, Toggle.Risky)
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            if Toggle.Visible == Visible then
                return
            end

            Toggle.Visible = Visible

            if not Toggle.Visible then
                CancelToggleConfirmation(Toggle)
            end

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        table.insert(Toggle.Connections, Button.Activated:Connect(function()
            if Toggle.Disabled then
                return
            end

            RequestToggleValue(Toggle, Groupbox, not Toggle.Value)
        end))

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Checkbox = Checkbox
        Toggle.Checkmark = Checkmark
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        function Toggle:Destroy()
            if Toggle.Destroyed then
                return
            end

            CancelToggleConfirmation(Toggle)
            Toggle.Destroyed = true

            Library:CancelTween(Checkbox, "CheckboxColor")
            Library:CancelTween(CheckboxStroke, "CheckboxStroke")
            Library:CancelTween(Label, "CheckboxLabelColor")
            Library:CancelTween(Label, "CheckboxLabelTransparency")
            CancelCheckmarkTweens()
            Library:CancelTween(CheckmarkScale, "CheckboxCheckmarkScale")

            if Toggle.Connections then
                for _, Connection in Toggle.Connections do
                    Connection:Disconnect()
                end
            end

            if Toggle.TooltipTable then 
                Toggle.TooltipTable:Destroy() 
            end

            if Button then 
                Button:Destroy() 
            end

            if Toggle.Addons then
                for Index = #Toggle.Addons, 1, -1 do
                    local Addon = table.remove(Toggle.Addons, Index)
                    if Addon and Addon.Destroy then
                        Addon:Destroy()
                    end
                end
            end

            local ElemIdx = table.find(Groupbox.Elements, Toggle)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Toggles[Idx] = nil
        end

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        if self.Destroyed then return nil end

        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            ConfirmDanger = Info.ConfirmDanger,
            ConfirmTitle = Info.ConfirmTitle,
            ConfirmDescription = Info.ConfirmDescription,
            ConfirmationPending = false,
            ConfirmationDialog = nil,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            StyleVariant = NormalizeToggleVariant(Info.Variant, Info.Risky),

            Addons = {},
            AnyKeyPickerPicking = false,

            Variant = "Switch",
            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Library:GetDesignToken("Size.Row", 24)),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -32, 1, 0),
            Text = Toggle.Text,
            TextSize = Library:GetDesignToken("Size.Text", 14),
            TextTransparency = Library:GetDesignToken("Opacity.MutedText", 0.38),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, Library:GetDesignToken("Spacing.Small", 6)),
            Parent = Label,
        })

        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = function()
                return GetToggleSurfaceColor(Toggle)
            end,
            ClipsDescendants = true,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(24, 14),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = function()
                return GetToggleStrokeColor(Toggle)
            end,
            Transparency = 0.18,
            Parent = Switch,
        })

        local Ball = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "FontColor",
            Position = UDim2.new(0, Toggle.Value and 12 or 2, 0.5, 0),
            Size = UDim2.fromOffset(10, 10),
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        RegisterToggleTheme(Toggle, Switch, SwitchStroke, Label)
        local BallRegistry = Library.Registry[Ball] or {}
        BallRegistry.BackgroundColor3 = function()
            return Toggle.Disabled and Library:GetDarkerColor(Library.Scheme.FontColor) or Library.Scheme.FontColor
        end
        BallRegistry.Position = function()
            return UDim2.new(0, Toggle.Value and 12 or 2, 0.5, 0)
        end
        Library.Registry[Ball] = BallRegistry

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local BallPosition = UDim2.new(0, Toggle.Value and 12 or 2, 0.5, 0)
            local SwitchColor = GetToggleSurfaceColor(Toggle)
            local StrokeColor = GetToggleStrokeColor(Toggle)
            local LabelColor = GetToggleLabelColor(Toggle.StyleVariant, Toggle.Value)

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or (Toggle.Value and 0.04 or 0.18)

            if Toggle.Disabled then
                Library:CancelTween(Switch, "SwitchColor")
                Library:CancelTween(SwitchStroke, "SwitchStroke")
                Library:CancelTween(Label, "SwitchLabelColor")
                Library:CancelTween(Label, "SwitchLabelTransparency")
                Library:CancelTween(Ball, "SwitchBallPosition")
                Library:CancelTween(Ball, "SwitchBallColor")
                Switch.BackgroundColor3 = SwitchColor
                SwitchStroke.Color = StrokeColor
                Label.TextColor3 = LabelColor
                Label.TextTransparency = 0.8
                Ball.Position = BallPosition

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)

                return
            end

            Library:PlayTween(Switch, "SwitchColor", Library.TweenInfo, {
                BackgroundColor3 = SwitchColor,
            })
            Library:PlayTween(SwitchStroke, "SwitchStroke", Library.TweenInfo, {
                Color = StrokeColor,
            })
            Library:PlayTween(Label, "SwitchLabelColor", Library.TweenInfo, {
                TextColor3 = LabelColor,
            })
            Library:PlayTween(Label, "SwitchLabelTransparency", Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or Library:GetDesignToken("Opacity.MutedText", 0.38),
            })
            Library:PlayTween(Ball, "SwitchBallPosition", Library.TweenInfo, {
                Position = BallPosition,
            })
            Library:PlayTween(Ball, "SwitchBallColor", Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.FontColor,
            })

        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:RunChanged()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Value = Value == true
            if Toggle.Value == Value then
                return
            end

            if Toggle.ConfirmationPending then
                CancelToggleConfirmation(Toggle)
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:QueueDependencyUpdate()

            if not Toggle.AnyKeyPickerPicking then
                Toggle:RunChanged()
            end
        end

        function Toggle:SetDisabled(Disabled: boolean)
            if Toggle.Disabled == Disabled then
                return
            end

            if Disabled then
                CancelToggleConfirmation(Toggle)
            end

            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVariant(Variant: string)
            CancelToggleConfirmation(Toggle)
            Toggle.StyleVariant = NormalizeToggleVariant(Variant, Toggle.Risky)
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            if Toggle.Visible == Visible then
                return
            end

            Toggle.Visible = Visible

            if not Toggle.Visible then
                CancelToggleConfirmation(Toggle)
            end

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        table.insert(Toggle.Connections, Button.Activated:Connect(function()
            if Toggle.Disabled then
                return
            end

            RequestToggleValue(Toggle, Groupbox, not Toggle.Value)
        end))

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        function Toggle:Destroy()
            if Toggle.Destroyed then
                return
            end

            CancelToggleConfirmation(Toggle)
            Toggle.Destroyed = true

            Library:CancelTween(Switch, "SwitchColor")
            Library:CancelTween(SwitchStroke, "SwitchStroke")
            Library:CancelTween(Label, "SwitchLabelColor")
            Library:CancelTween(Label, "SwitchLabelTransparency")
            Library:CancelTween(Ball, "SwitchBallPosition")
            Library:CancelTween(Ball, "SwitchBallColor")

            if Toggle.Connections then
                for _, Connection in Toggle.Connections do
                    Connection:Disconnect()
                end
            end

            if Toggle.TooltipTable then 
                Toggle.TooltipTable:Destroy() 
            end

            if Button then 
                Button:Destroy() 
            end

            if Toggle.Addons then
                for Index = #Toggle.Addons, 1, -1 do
                    local Addon = table.remove(Toggle.Addons, Index)
                    if Addon and Addon.Destroy then
                        Addon:Destroy()
                    end
                end
            end

            local ElemIdx = table.find(Groupbox.Elements, Toggle)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Toggles[Idx] = nil
        end

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        if self.Destroyed then return nil end

        if typeof(Info) == "table" and (typeof(Info.VerifyValue) == "function" and Info.Finished ~= true) then
            Info.Finished = true
        end

        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            ClearTextOnBlur = Info.ClearTextOnBlur,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,
            VerifyValue = Info.VerifyValue,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local InputControlHeight = Library:Snap(Library:GetDesignToken("Size.Control", 28))
        local InputLabelRow = Library:Metric("LabelRow", 18)

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, InputControlHeight + InputLabelRow),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, InputLabelRow),
            Text = Input.Text,
            TextSize = Library:GetDesignToken("Size.Text", 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromOffset(0, InputLabelRow),
            Size = UDim2.new(1, 0, 0, InputControlHeight),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextSize = Library:GetDesignToken("Size.Text", 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local BoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Transparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
            Parent = Box,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Control", math.max(Library.CornerRadius / 2, 2))) end,
                Parent = Box,
            })
        )

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:RunChanged()
            Library:SafeCallback(Input.Callback, Input.Value)
            Library:SafeCallback(Input.Changed, Input.Value)
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            if typeof(Info.VerifyValue) == "function" and (Text ~= Input.EmptyReset and Info.VerifyValue(Text) ~= true) then
                Text = Input.EmptyReset
            end

            if Input.Value == Text then
                return
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Input:RunChanged()
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            table.insert(Input.Connections, Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    if Input.ClearTextOnBlur then
                        Box.Text = Input.Value
                    end

                    return
                end

                Input:SetValue(Box.Text)
            end))
        else
            table.insert(Input.Connections, Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box.Text == Input.Value then return end
                
                Input:SetValue(Box.Text)
            end))
        end

        table.insert(Input.Connections, Box.Focused:Connect(function()
            if Input.Disabled then
                return
            end

            Library.Registry[BoxStroke].Color = "AccentColor"
            Library:PlayTween(BoxStroke, "InputFocus", Library.TweenInfo, {
                Color = Library.Scheme.AccentColor,
            })
        end))

        table.insert(Input.Connections, Box.FocusLost:Connect(function()
            Library.Registry[BoxStroke].Color = "OutlineColor"
            Library:PlayTween(BoxStroke, "InputFocus", Library.TweenInfo, {
                Color = Library.Scheme.OutlineColor,
            })
        end))

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Groupbox:Resize()

        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)

        Input.Default = Input.Value
        if typeof(Info.VerifyValue) == "function" and (Input.Default ~= Input.EmptyReset and Info.VerifyValue(Input.Default) ~= true) then
            Input:SetValue(Input.EmptyReset)
            Input.Default = Input.EmptyReset
        end
        
        Options[Idx] = Input

        function Input:Destroy()
            if Input.Destroyed then
                return
            end

            Input.Destroyed = true

            if Input.Connections then
                for _, Connection in Input.Connections do
                    Connection:Disconnect()
                end
            end

            if Input.TooltipTable then 
                Input.TooltipTable:Destroy() 
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Input)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Slider)

        local Groupbox = self
        local Container = Groupbox.Container

        local Slider = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            AllowRightClickInput = Info.AllowRightClickInput,

            Type = "Slider",
        }

        local LabelRow = Library:Metric("LabelRow", 18)
        local TrackRow = Library:Metric("TrackRow", 14)
        local TrackHeight = Library:MatchParity(TrackRow, Library:Metric("Track", 4))
        local ThumbSize = Library:MatchParity(TrackRow, Library:Metric("Thumb", 10))
        local ThumbHover = Library:MatchParity(TrackRow, Library:Metric("ThumbHover", 12))
        local TrackInset = math.round(ThumbHover * 0.5)
        local ValueWidth = 96

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, LabelRow + TrackRow),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        if not Info.Compact then
            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -ValueWidth, 0, LabelRow),
                Text = Slider.Text,
                TextSize = Library:GetDesignToken("Size.Text", 14),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, LabelRow),
            Size = UDim2.new(1, 0, 0, TrackRow),
            Text = "",
            Parent = Holder,
        })

        local Track = New("Frame", {
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromOffset(TrackInset, Library:CenterOffset(TrackRow, TrackHeight)),
            Size = UDim2.new(1, -TrackInset * 2, 0, TrackHeight),
            Parent = Bar,
        })
        New("UICorner", {
            CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Indicator", 3)) end,
            Parent = Track,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Transparency = Library:GetDesignToken("Stroke.SoftTransparency", 0.46),
            Parent = Track,
        })

        local DisplayLabel = New("TextLabel", {
            AnchorPoint = Info.Compact and Vector2.zero or Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = Info.Compact and UDim2.zero or UDim2.fromScale(1, 0),
            Size = Info.Compact and UDim2.new(1, 0, 0, LabelRow) or UDim2.fromOffset(ValueWidth - 6, LabelRow),
            Text = "",
            TextColor3 = "MutedFontColor",
            TextSize = Library:GetDesignToken("Size.Text", 14),
            TextXAlignment = Info.Compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right,
            ZIndex = Bar.ZIndex + 2,
            Parent = Holder,
        })

        local InputTextBox
        if Info.AllowRightClickInput then
            InputTextBox = New("TextBox", {
                AnchorPoint = Info.Compact and Vector2.zero or Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = Info.Compact and UDim2.zero or UDim2.fromScale(1, 0),
                Size = Info.Compact and UDim2.new(1, 0, 0, LabelRow) or UDim2.fromOffset(ValueWidth - 6, LabelRow),
                Text = "",
                TextSize = Library:GetDesignToken("Size.Text", 14),
                TextXAlignment = Info.Compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right,
                ZIndex = Bar.ZIndex + 3,
                Visible = false,
                ClearTextOnFocus = false,
                Parent = Holder,
            })
        end

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = Bar.ZIndex + 1,
            Parent = Track,
        })
        local FillGradient = New("UIGradient", {
            Color = function()
                return ColorSequence.new(
                    Library.Scheme.AccentColor:Lerp(Library.Scheme.FontColor, 0.12),
                    Library.Scheme.AccentColor
                )
            end,
            Enabled = not Slider.Disabled,
            Parent = Fill,
        })
        New("UICorner", {
            CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Indicator", 3)) end,
            Parent = Fill,
        })

        local Thumb = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "FontColor",
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(ThumbSize, ThumbSize),
            ZIndex = Bar.ZIndex + 2,
            Parent = Track,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Thumb,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Thickness = 1,
            Parent = Thumb,
        })

        table.insert(Slider.Connections, Bar.MouseEnter:Connect(function()
            if Slider.Disabled then
                return
            end
            Library:PlayTween(Thumb, "SliderHover", Library.TweenInfo, {
                Size = UDim2.fromOffset(ThumbHover, ThumbHover),
            })
        end))
        table.insert(Slider.Connections, Bar.MouseLeave:Connect(function()
            Library:PlayTween(Thumb, "SliderHover", Library.TweenInfo, {
                Size = UDim2.fromOffset(ThumbSize, ThumbSize),
            })
        end))

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            
            if Info.AllowRightClickInput then
                InputTextBox.TextTransparency = Slider.Disabled and 0.8 or 0
            end

            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
            FillGradient.Enabled = not Slider.Disabled
            Thumb.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.FontColor
            Library.Registry[Thumb].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "FontColor"
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text =
                        string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s%s/%s%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Suffix,
                        Slider.Prefix,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local Span = Slider.Max - Slider.Min
            local X = Span ~= 0 and (Slider.Value - Slider.Min) / Span or 0
            local TrackWidth = Track.AbsoluteSize.X
            if TrackWidth > 0 then
                local Offset = math.round(X * TrackWidth)
                Fill.Size = UDim2.new(0, Offset, 1, 0)
                Thumb.Position = UDim2.new(0, Offset, 0.5, 0)
            else
                Fill.Size = UDim2.new(X, 0, 1, 0)
                Thumb.Position = UDim2.new(X, 0, 0.5, 0)
            end
        end

        table.insert(Slider.Connections, Track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Slider:Display()
        end))

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:RunChanged()
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == Slider.Value then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Slider:RunChanged()
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            if Slider.Disabled then
                Thumb.Size = UDim2.fromOffset(10, 10)
            end
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        if Info.AllowRightClickInput then
            local LastValidText = ""
            table.insert(Slider.Connections, InputTextBox:GetPropertyChangedSignal("Text"):Connect(function()
                local Text = InputTextBox.Text
                local AsNum = tonumber(Text)

                if #tostring(Text) > 0 and not AsNum and Text ~= "-" then
                    InputTextBox.Text = LastValidText
                else
                    if Slider.Rounding == 0 and Text:find("%.") then
                        InputTextBox.Text = LastValidText
                        return
                    end

                    local DecimalPos = Text:find("%.")
                    if DecimalPos and Slider.Rounding > 0 then
                        local Decimals = #Text - DecimalPos
                        if Decimals > Slider.Rounding then
                            InputTextBox.Text = LastValidText
                            return
                        end
                    end

                    LastValidText = Text

                    if AsNum then
                        if AsNum > Slider.Max then
                            InputTextBox.Text = tostring(Slider.Max)
                        elseif AsNum < Slider.Min then
                            InputTextBox.Text = tostring(Slider.Min)
                        end
                    end
                end
            end))

            table.insert(Slider.Connections, InputTextBox.FocusLost:Connect(function()
                InputTextBox.Visible = false
                DisplayLabel.Visible = true

                local Num = tonumber(InputTextBox.Text)
                if not Num then
                    return
                end

                Num = Round(Num, Slider.Rounding)
                Slider:SetValue(Num)
            end))
        end

        local LastTap = 0
        table.insert(Slider.Connections, Bar.InputBegan:Connect(function(Input: InputObject)
            local ValidInput = IsClickInput(Input) or Input.UserInputType == Enum.UserInputType.MouseButton2
            if not ValidInput or Slider.Disabled then
                return
            end

            if Info.AllowRightClickInput then
                local IsRightClick = Input.UserInputType == Enum.UserInputType.MouseButton2
                local IsDoubleTap = false

                if Library.IsMobile and Input.UserInputType == Enum.UserInputType.Touch then
                    if tick() - LastTap < 0.3 then
                        IsDoubleTap = true
                    end
                    
                    LastTap = tick()
                end

                if IsRightClick or IsDoubleTap then
                    InputTextBox.Text = tostring(Slider.Value)
                    InputTextBox.Visible = true
                    DisplayLabel.Visible = false

                    task.spawn(InputTextBox.CaptureFocus, InputTextBox)
                    return
                end
            end

            if not IsClickInput(Input) then
                return
            end

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = false
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = false
            end

            while IsDragInput(Input) and not Slider.Destroyed do
                local Location = Input.UserInputType == Enum.UserInputType.Touch and Input.Position.X or Mouse.X
                local Scale = math.clamp((Location - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                Slider:Display()
                if Slider.Value ~= OldValue then
                    Slider:RunChanged()
                end

                RunService.RenderStepped:Wait()
            end

            if Library.ActiveTab then
                for _, Side in Library.ActiveTab.Sides do
                    Side.ScrollingEnabled = true
                end
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = true
            end
        end))

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Groupbox:Resize()

        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        function Slider:Destroy()
            if Slider.Destroyed then
                return
            end

            Slider.Destroyed = true

            if Slider.Connections then
                for _, Connection in Slider.Connections do
                    Connection:Disconnect()
                end
            end

            if Slider.TooltipTable then 
                Slider.TooltipTable:Destroy() 
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Slider)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Dropdown)

        local Groupbox = self
        local Container = Groupbox.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Connections = {},
            Destroyed = false,

            Text = typeof(Info.Text) == "string" and Info.Text or nil,

            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            ValueImages = Info.ValueImages,

            Multi = Info.Multi,
            DragSelect = Info.Multi and not Library.IsMobile and Info.DragSelect == true,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,
            EnablePlayerImages = Info.EnablePlayerImages,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
        }

        local ControlHeight = Library:Snap(Library:GetDesignToken("Size.Control", 28))
        local DropdownLabelRow = Library:Metric("LabelRow", 18)
        local HasLabel = not not Info.Text

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, HasLabel and ControlHeight + DropdownLabelRow or ControlHeight),
            Visible = Dropdown.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, DropdownLabelRow),
            Text = Dropdown.Text,
            TextSize = Library:GetDesignToken("Size.Text", 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = HasLabel,
            ZIndex = 3,
            Parent = Holder,
        })

        local DisplayContainer = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromOffset(0, HasLabel and DropdownLabelRow or 0),
            Size = UDim2.new(1, 0, 0, ControlHeight),
            Text = "",
            TextTransparency = 1,
            ZIndex = 2,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = DisplayContainer,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Transparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
            Parent = DisplayContainer,
        })

        local DropdownCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, Library:GetDesignToken("Radius.Control", math.max(Library.CornerRadius / 2, 2))),
            TopRightRadius = UDim.new(0, Library:GetDesignToken("Radius.Control", math.max(Library.CornerRadius / 2, 2))),
            BottomRightRadius = UDim.new(0, Library:GetDesignToken("Radius.Control", math.max(Library.CornerRadius / 2, 2))),
            BottomLeftRadius = UDim.new(0, Library:GetDesignToken("Radius.Control", math.max(Library.CornerRadius / 2, 2))),
            Parent = DisplayContainer,
        }); table.insert(Library.SpecificCorners, DropdownCorner)

        local DisplayImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, Library:CenterOffset(ControlHeight, 16)),
            Size = UDim2.fromOffset(16, 16),
            Image = "",
            ImageTransparency = 1,
            ZIndex = 2,
            Parent = DisplayContainer,
        })

        local DisplayButton = New("TextButton", {
            Active = not Dropdown.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 1, 0),
            Text = "None",
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextWrapped = false,
            TextSize = Library:GetDesignToken("Size.Text", 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            Parent = DisplayContainer,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.new(1, 0, 0, Library:CenterOffset(ControlHeight, 14)),
            Size = UDim2.fromOffset(14, 14),
            Parent = DisplayContainer,
        })

        local SearchBox
        if Info.Searchable then
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8, 0),
                Size = UDim2.new(1, -12, 1, 0),
                TextSize = Library:GetDesignToken("Size.Text", 14),
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = DisplayButton,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = SearchBox,
            })
        end

        local GetValueImage = function(Value, RawValue)
            if not Value then
                return nil
            end

            local ValueImage = nil
            if Dropdown.SpecialType == "Player" and Dropdown.EnablePlayerImages == true then
                local PlayerValue = Value
                if typeof(PlayerValue) ~= "Instance" and RawValue ~= nil then
                    PlayerValue = RawValue
                end

                if typeof(PlayerValue) == "Instance" and PlayerValue:IsA("Player") then
                    ValueImage = { Url = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=48&h=48", tostring(PlayerValue.UserId)) }
                end
            else
                if Dropdown.ValueImages then
                    local IconRef = Dropdown.ValueImages[Value]
                    if IconRef == nil and RawValue ~= nil then
                        IconRef = Dropdown.ValueImages[RawValue]
                    end

                    if IconRef then
                        ValueImage = Library:GetCustomIcon(IconRef)
                    end
                end
            end

            return ValueImage
        end

        local MenuTable = Library:AddContextMenu(
            DisplayContainer,
            function()
                return UDim2.fromOffset((DisplayContainer.AbsoluteSize.X / Library.DPIScale), 0)
            end,
            function()
                return { 0, DisplayContainer.AbsoluteSize.Y + 1 }
            end,
            2,
            function(Active: boolean)
                DisplayButton.TextTransparency = (Active and SearchBox) and 1 or 0

                ArrowImage.ImageTransparency = Active and 0 or 0.5
                ArrowImage.Rotation = Active and 180 or 0

                if SearchBox then
                    SearchBox.Text = ""
                    SearchBox.Visible = Active
                end

                local Radius = Library:GetDesignToken("Radius.Control", math.max(Library.CornerRadius / 2, 2))
                DropdownCorner.BottomRightRadius = Active and UDim.new(0, 0) or UDim.new(0, Radius)
                DropdownCorner.BottomLeftRadius = Active and UDim.new(0, 0) or UDim.new(0, Radius)
            end,
            false,
            "bottom",
            "Dropdown"
        )
        Dropdown.Menu = MenuTable

        local ItemHeight = math.max(24, Library:Snap(Library:GetDesignToken("Size.Control", 28)) - 4)
        local PoolSize = math.max(1, Info.MaxVisibleDropdownItems + 2)
        local Pool = {}
        local FilteredEntries = {}

        function Dropdown:RecalculateListSize(Count)
            local ItemCount = Count or #FilteredEntries
            local Y = math.clamp(ItemCount * ItemHeight, 0, Info.MaxVisibleDropdownItems * ItemHeight)

            MenuTable.Menu.CanvasSize = UDim2.fromOffset(0, ItemCount * ItemHeight)

            MenuTable:SetSize(function()
                return UDim2.fromOffset((DisplayContainer.AbsoluteSize.X / Library.DPIScale), Y)
            end)
        end

        function Dropdown:RefreshTypography()
            if Dropdown.Destroyed then return end
            local DesiredSize = math.max(8, math.floor(Library:GetDesignToken("Size.Text", 14)))
            local function Fit(Object, Height)
                local Success, _, MeasuredHeight = pcall(Library.GetTextBounds, Library, "Ag", Object.FontFace, DesiredSize, 10000)
                local Available = math.max(1, Height - 4)
                Object.TextSize = Success and MeasuredHeight > Available
                    and math.max(8, math.floor(DesiredSize * Available / MeasuredHeight)) or DesiredSize
                Object.TextYAlignment = Enum.TextYAlignment.Center
            end
            Fit(DisplayButton, ControlHeight)
            Fit(Label, DropdownLabelRow)
            if SearchBox then Fit(SearchBox, ControlHeight) end
            for _, Row in Pool do Fit(Row.Button, ItemHeight) end
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayButton.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayImage.ImageTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = ""
            local ValueImage = nil
            local IsDictionary = not IsSequentialArray(Dropdown.Values)

            if Info.Multi then
                for Key, RawValue in Dropdown.Values do
                    local Value = IsDictionary and Key or RawValue

                    if Dropdown.Value[Value] then
                        if not ValueImage then
                            ValueImage = GetValueImage(Value, RawValue)
                        end

                        Str = Str
                            .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(RawValue)) or tostring(RawValue))
                            .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                local DisplayValue = Dropdown.Value
                if IsDictionary and Dropdown.Value ~= nil then
                    DisplayValue = Dropdown.Values[Dropdown.Value]
                end

                ValueImage = GetValueImage(Dropdown.Value, DisplayValue)
                Str = DisplayValue and tostring(DisplayValue) or ""

                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end

            DisplayButton.Text = (Str == "" and "None" or Str)
            
            if ValueImage then
                DisplayImage.Image = ValueImage.Url
                DisplayImage.ImageRectOffset = ValueImage.ImageRectOffset or Vector2.zero
                DisplayImage.ImageRectSize = ValueImage.ImageRectSize or Vector2.zero
                DisplayImage.ImageTransparency = 0
            else
                DisplayImage.Image = ""
                DisplayImage.ImageTransparency = 1
            end

            local ImageInset = ValueImage and 22 or 0
            DisplayButton.Size = UDim2.new(1, -(ImageInset + 24), 1, 0)
            DisplayButton.Position = UDim2.fromOffset(ImageInset, 0)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:GetActiveValues(ReturnCount)
            local Table = {}

            if Info.Multi then
                for Value, _ in Dropdown.Value do
                    table.insert(Table, Value)
                end
            else
                if Dropdown.Value then
                    table.insert(Table, Dropdown.Value)
                end
            end

            return ReturnCount == true and GetTableSize(Table) or Table
        end

        local DragSelecting = false
        local DragStartIndex = nil
        local DragPrevMin = nil
        local DragPrevMax = nil
        local DragLastIndex = nil
        local DragChanged = false
        local DragInitialValues = {}
        local DragInputEndedConn = nil
        local DragInputChangedConn = nil

        local function RecomputeFilteredEntries()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues
            local IsDictionary = not IsSequentialArray(Values)

            local EnabledList, DisabledList = {}, {}
            local Pending = {}

            for Key, RawValue in Values do
                local Value = IsDictionary and Key or RawValue

                local FormattedValue = tostring(Info.FormatListValue and Info.FormatListValue(RawValue) or RawValue)
                if SearchBox and not FormattedValue:lower():find(SearchBox.Text:lower(), 1, true) then
                    continue
                end

                local IsDisabled = table.find(DisabledValues, Value) ~= nil
                    or (RawValue ~= nil and RawValue ~= Value and table.find(DisabledValues, RawValue) ~= nil)

                local Entry = {
                    Value = Value,
                    RawValue = RawValue,
                    FormattedValue = FormattedValue,
                    IsDisabled = IsDisabled,
                    ValueImage = GetValueImage(Value, RawValue),
                    SortKey = Key,
                }

                table.insert(Pending, Entry)
            end

            if not IsDictionary then
                table.sort(Pending, function(A, B)
                    return A.SortKey < B.SortKey
                end)
            end

            for _, Entry in Pending do
                if Entry.IsDisabled then
                    table.insert(DisabledList, Entry)
                else
                    table.insert(EnabledList, Entry)
                end
            end

            table.clear(FilteredEntries)
            for _, Entry in EnabledList do
                table.insert(FilteredEntries, Entry)
            end
            for _, Entry in DisabledList do
                table.insert(FilteredEntries, Entry)
            end
        end

        local function GetFirstVisibleIndex()
            local Total = #FilteredEntries
            if Total <= PoolSize then
                return 1
            end

            local MaxFirst = Total - PoolSize + 1
            local ScrollY = MenuTable.Menu.CanvasPosition.Y / Library.DPIScale
            local Index = math.floor(ScrollY / ItemHeight) + 1
            return math.clamp(Index, 1, MaxFirst)
        end

        function Dropdown:RefreshPool()
            local Total = #FilteredEntries
            local First = GetFirstVisibleIndex()

            for SlotIndex, Row in Pool do
                local DataIndex = First + SlotIndex - 1
                local Entry = FilteredEntries[DataIndex]

                Row.Entry = Entry
                Row.Index = Entry and DataIndex or nil

                if not Entry then
                    Row.Container.Visible = false
                    continue
                end

                Row.Container.Visible = true
                Row.Container.Position = UDim2.fromOffset(0, (DataIndex - 1) * ItemHeight)

                local IsLast = DataIndex == Total
                Row.Corner.BottomRightRadius = IsLast and UDim.new(0, Library.CornerRadius / 2) or UDim.new(0, 0)
                Row.Corner.BottomLeftRadius = IsLast and UDim.new(0, Library.CornerRadius / 2) or UDim.new(0, 0)

                Row.Button.Text = Entry.FormattedValue

                if Entry.ValueImage then
                    Row.Image.Visible = true
                    Row.Image.Image = Entry.ValueImage.Url
                    Row.Image.ImageRectOffset = Entry.ValueImage.ImageRectOffset or Vector2.zero
                    Row.Image.ImageRectSize = Entry.ValueImage.ImageRectSize or Vector2.zero
                    Row.Button.Size = UDim2.new(1, -18, 0, ItemHeight)
                    Row.Button.Position = UDim2.fromOffset(18, 0)
                else
                    Row.Image.Visible = false
                    Row.Button.Size = UDim2.new(1, 0, 0, ItemHeight)
                    Row.Button.Position = UDim2.fromOffset(0, 0)
                end

                Row:UpdateButton()
            end
        end

        function Dropdown:RunChanged()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end      

        local function StopDragSelect()
            DragSelecting = false
            DragStartIndex = nil
            DragPrevMin = nil
            DragPrevMax = nil
            DragLastIndex = nil
            DragChanged = false
            table.clear(DragInitialValues)

            if DragInputEndedConn then
                DragInputEndedConn:Disconnect()
                DragInputEndedConn = nil
            end

            if DragInputChangedConn then
                DragInputChangedConn:Disconnect()
                DragInputChangedConn = nil
            end
        end

        local DragActiveCount = 0

        local function ApplyDragIndex(Index, InRange)
            local Entry = FilteredEntries[Index]
            if not Entry or Entry.IsDisabled then
                return
            end

            local Try = DragInitialValues[Entry.Value]
            if InRange then
                Try = not Try
            end

            local WantActive = Try and true or false
            local IsActive = Dropdown.Value[Entry.Value] and true or false
            if WantActive == IsActive then
                return
            end

            if not WantActive and DragActiveCount == 1 and not Info.AllowNull then
                return
            end

            Dropdown.Value[Entry.Value] = WantActive and true or nil
            DragActiveCount += WantActive and 1 or -1
            DragChanged = true
        end

        local function ApplyDragRange(From, To, InRange)
            for Index = From, To do
                ApplyDragIndex(Index, InRange)
            end
        end

        local function UpdateDrag(CurrentIndex)
            if CurrentIndex == nil or CurrentIndex == DragLastIndex then
                return
            end

            DragLastIndex = CurrentIndex

            local Min = math.min(DragStartIndex, CurrentIndex)
            local Max = math.max(DragStartIndex, CurrentIndex)
            DragActiveCount = Dropdown:GetActiveValues(true)

            if DragPrevMin == nil then
                ApplyDragRange(Min, Max, true)
            else
                if DragPrevMin < Min then
                    ApplyDragRange(DragPrevMin, Min - 1, false)
                end
                if DragPrevMax > Max then
                    ApplyDragRange(Max + 1, DragPrevMax, false)
                end
                if Min < DragPrevMin then
                    ApplyDragRange(Min, DragPrevMin - 1, true)
                end
                if Max > DragPrevMax then
                    ApplyDragRange(DragPrevMax + 1, Max, true)
                end
            end

            DragPrevMin = Min
            DragPrevMax = Max

            for _, OtherRow in Pool do
                OtherRow:UpdateButton()
            end
        end

        local function CreatePoolRow()
            local Row = {
                Entry = nil,
                Index = nil
            }

            local Container = New("Frame", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Visible = false,
                Parent = MenuTable.Menu,
            })

            local Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, 0),
                BottomRightRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, 0),
                Parent = Container,
            }); table.insert(Library.SpecificCorners, Corner)

            local Image = New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "",
                ImageTransparency = 0.5,
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.fromOffset(4, Library:CenterOffset(ItemHeight, 16)),
                Visible = false,
                Parent = Container,
            })

            local Button = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Text = "",
                TextSize = Library:GetDesignToken("Size.Text", 14),
                TextYAlignment = Enum.TextYAlignment.Center,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextWrapped = false,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Container,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                Parent = Button,
            })

            Row.Container = Container
            Row.Corner = Corner
            Row.Image = Image
            Row.Button = Button

            function Row:UpdateButton()
                local Entry = Row.Entry
                if not Entry then
                    return
                end

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Entry.Value]
                else
                    Selected = Dropdown.Value == Entry.Value
                end

                Row.Selected = Selected and true or false

                local BackgroundTransparency = Selected and 0 or 1
                local TextTransparency = Entry.IsDisabled and 0.8 or Selected and 0 or 0.5
                if Container.BackgroundTransparency ~= BackgroundTransparency then
                    Container.BackgroundTransparency = BackgroundTransparency
                end
                if Button.TextTransparency ~= TextTransparency then
                    Button.TextTransparency = TextTransparency
                end

                if Entry.ValueImage then
                    local ImageTransparency = Entry.IsDisabled and 0.8 or Selected and 0 or 0.5
                    if Image.ImageTransparency ~= ImageTransparency then
                        Image.ImageTransparency = ImageTransparency
                    end
                end
            end

            Button.MouseButton1Click:Connect(function()
                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled or DragSelecting then
                    return
                end

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Entry.Value]
                else
                    Selected = Dropdown.Value == Entry.Value
                end

                local Try = not Selected
                local Changed = false
                if not (Dropdown:GetActiveValues(true) == 1 and not Try and not Info.AllowNull) then
                    Selected = Try
                    if Info.Multi then
                        Dropdown.Value[Entry.Value] = Selected and true or nil
                    else
                        Dropdown.Value = Selected and Entry.Value or nil
                    end
                    Changed = true

                    for _, OtherRow in Pool do
                        OtherRow:UpdateButton()
                    end
                end

                if not Changed then
                    return
                end

                Row:UpdateButton()
                Dropdown:Display()

                Library:QueueDependencyUpdate()
                Dropdown:RunChanged()
            end)

			Button.MouseEnter:Connect(function()
				if Row.Selected then
					return
				end

				Library:PlayTween(Container, "DropdownRowHover", Library.TweenInfo, {
					BackgroundTransparency = 0.85,
				})
				Library:PlayTween(Button, "DropdownRowHover", Library.TweenInfo, {
					TextTransparency = 0.25,
				})

				if Image then
					Library:PlayTween(Image, "DropdownRowHover", Library.TweenInfo, {
						ImageTransparency = 0.25,
					})
				end
			end)

			Button.MouseLeave:Connect(function()
				if Row.Selected then
					return
				end

				Library:PlayTween(Container, "DropdownRowHover", Library.TweenInfo, {
					BackgroundTransparency = 1,
				})
				Library:PlayTween(Button, "DropdownRowHover", Library.TweenInfo, {
					TextTransparency = 0.5,
				})

				if Image then
					Library:PlayTween(Image, "DropdownRowHover", Library.TweenInfo, {
						ImageTransparency = 0.5,
					})
				end
			end)

            Button.InputBegan:Connect(function(StartInput)
                if not (Info.Multi and Dropdown.DragSelect and not Library.IsMobile) then
                    return
                end

                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled then
                    return
                end

                if not IsMouseInput(StartInput) then
                    return
                end

                DragSelecting = true
                DragStartIndex = Row.Index
                DragChanged = false
                table.clear(DragInitialValues)

                for _, FilteredEntry in FilteredEntries do
                    DragInitialValues[FilteredEntry.Value] = Dropdown.Value[FilteredEntry.Value]
                end

                UpdateDrag(Row.Index)

                if DragInputEndedConn then DragInputEndedConn:Disconnect() end
                if DragInputChangedConn then DragInputChangedConn:Disconnect() end

                DragInputChangedConn = Library:GiveSignal(UserInputService.InputChanged:Connect(function(ChangeInput)
                    if not IsMovementInput(ChangeInput) and ChangeInput ~= StartInput then
                        return
                    end

                    local Pos = ChangeInput.Position
                    for _, OtherRow in Pool do
                        if OtherRow.Entry and Library:MouseIsOverFrame(OtherRow.Button, Pos) then
                            UpdateDrag(OtherRow.Index)
                            break
                        end
                    end
                end))

                DragInputEndedConn = Library:GiveSignal(UserInputService.InputEnded:Connect(function(EndInput)
                    if EndInput ~= StartInput and not (IsMouseInput(EndInput) and EndInput.UserInputType == StartInput.UserInputType) then
                        return
                    end

                    if DragChanged then
                        Dropdown:Display()
                        Library:QueueDependencyUpdate()
                        Dropdown:RunChanged()
                    end

                    StopDragSelect()
                end))

                table.insert(Dropdown.Connections, DragInputEndedConn)
                table.insert(Dropdown.Connections, DragInputChangedConn)
            end)

            return Row
        end

        function Dropdown:BuildDropdownList()
            StopDragSelect()

            RecomputeFilteredEntries()

            MenuTable.Menu.CanvasPosition = Vector2.new(0, 0)

            Dropdown:RefreshPool()
            Dropdown:RecalculateListSize(#FilteredEntries)
        end

        for _ = 1, PoolSize do
            table.insert(Pool, CreatePoolRow())
        end

        table.insert(Dropdown.Connections, MenuTable.Menu:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            Dropdown:RefreshPool()
        end))

        local function ValueExists(Val)
            if IsSequentialArray(Dropdown.Values) then
                for _, Existing in Dropdown.Values do
                    if Existing == Val then
                        return true
                    end
                end

                return false
            end

            return Dropdown.Values[Val] ~= nil
        end

        local function AreSelectedValuesEqual(First, Second)
            for Value in First do
                if not Second[Value] then
                    return false
                end
            end

            for Value in Second do
                if not First[Value] then
                    return false
                end
            end

            return true
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}
				
                for Val, Active in Value or {} do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and ValueExists(Val) then
                        Table[Val] = true
                    end
                end

                if AreSelectedValuesEqual(Dropdown.Value, Table) then
                    return
                end

                Dropdown.Value = Table
            else
                local NextValue = Dropdown.Value
                if ValueExists(Value) then
                    NextValue = Value
                elseif not Value then
                    NextValue = nil
                end

                if Dropdown.Value == NextValue then
                    return
                end

                Dropdown.Value = NextValue
            end

            Dropdown:Display()
            for _, Row in Pool do
                Row:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:QueueDependencyUpdate()
                Dropdown:RunChanged()
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values

            local Changed = false
            if Info.Multi then
                for Val in Dropdown.Value do
                    if not ValueExists(Val) then
                        Dropdown.Value[Val] = nil
                        Changed = true
                    end
                end

            elseif Dropdown.Value ~= nil and not ValueExists(Dropdown.Value) then
                Dropdown.Value = nil
                Changed = true
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()

            if Changed and not Dropdown.Disabled then
                Library:QueueDependencyUpdate()
                Dropdown:RunChanged()
            end
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) ~= "table" and typeof(Values) ~= "string" then
                return
            end

            local IsDictionary = not IsSequentialArray(Dropdown.Values)
            if IsDictionary then
                if typeof(Values) == "string" then
                    Dropdown.Values[Values] = Values

                elseif IsSequentialArray(Values) then
                    for _, Val in Values do
                        Dropdown.Values[Val] = Val
                    end

                else
                    for Key, Val in Values do
                        Dropdown.Values[Key] = Val
                    end
                end
            else
                if typeof(Values) == "table" then
                    for _, Val in Values do
                        table.insert(Dropdown.Values, Val)
                    end
                else
                    table.insert(Dropdown.Values, Values)
                end
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in DisabledValues do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end
            
            Dropdown.ValueImages = ValueImages
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end
            
            for key, val in ValueImages do
                Dropdown.ValueImages[key] = val
            end
            
            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            DisplayButton.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            Groupbox:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text ~= nil and tostring(Text) or nil
            HasLabel = Dropdown.Text ~= nil and Dropdown.Text ~= ""
            Holder.Size = UDim2.new(1, 0, 0, ControlHeight + (HasLabel and DropdownLabelRow or 0))
            DisplayContainer.Position = UDim2.fromOffset(0, HasLabel and DropdownLabelRow or 0)
            Label.Text = Dropdown.Text or ""
            Label.Visible = HasLabel
            Groupbox:Resize()
        end

        function Dropdown:SetDragSelect(Value: boolean)
            if not Info.Multi or Library.IsMobile then 
                Value = false
            end

            Dropdown.DragSelect = Value == true
            Dropdown:BuildDropdownList()
        end

        local ToggleDropdown = function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end

        table.insert(Dropdown.Connections, DisplayContainer.MouseButton1Click:Connect(ToggleDropdown))
        table.insert(Dropdown.Connections, DisplayButton.MouseButton1Click:Connect(ToggleDropdown))

        if SearchBox then
            table.insert(Dropdown.Connections, SearchBox:GetPropertyChangedSignal("Text"):Connect(Dropdown.BuildDropdownList))
        end

        local Defaults = (function()
            local Resolved = {}
            local Default = Info.Default
            if Default == nil then
                return Resolved
            end

            local IsDictionary = not IsSequentialArray(Dropdown.Values)
            local function ResolveOne(Candidate)
                if IsDictionary then
                    return Dropdown.Values[Candidate] ~= nil and Candidate or nil
                end

                for _, Existing in Dropdown.Values do
                    if Existing == Candidate then
                        return Existing
                    end
                end

                return nil
            end

            local DefaultType = typeof(Default)
            if DefaultType == "string" then
                local Value = ResolveOne(Default)
                if Value ~= nil then
                    table.insert(Resolved, Value)
                end

            elseif DefaultType == "table" then
                for _, Candidate in Default do
                    local Value = ResolveOne(Candidate)
                    if Value ~= nil then
                        table.insert(Resolved, Value)
                    end
                end

            elseif Dropdown.Values[Default] ~= nil then
                table.insert(Resolved, IsDictionary and Default or Dropdown.Values[Default])
            end

            return Resolved
        end)()

        for _, SelectValue in Defaults do
            if Info.Multi then
                Dropdown.Value[SelectValue] = true
            else
                Dropdown.Value = SelectValue
                break
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, DisplayContainer)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Groupbox:Resize()

        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Dropdown:RefreshTypography()
        Options[Idx] = Dropdown

        function Dropdown:Destroy()
            if Dropdown.Destroyed then
                return
            end

            Dropdown.Destroyed = true

            StopDragSelect()

            if Dropdown.Connections then
                for _, Connection in Dropdown.Connections do
                    Connection:Disconnect()
                end
            end

            if Dropdown.TooltipTable then 
                Dropdown.TooltipTable:Destroy() 
            end

            if MenuTable then 
                MenuTable:Destroy() 
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Dropdown)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Dropdown
    end

    function Funcs:AddViewport(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Viewport)

        local Groupbox = self
        local Container = Groupbox.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0
        local MinZoomDistance, MaxZoomDistance = 2, 100

        local function CloneViewportObject(Object: Instance)
            local Archivable = Object.Archivable
            if not Archivable then
                Object.Archivable = true
            end

            local Success, Clone = pcall(Object.Clone, Object)
            Object.Archivable = Archivable
            assert(Success and Clone, "Viewport object could not be cloned.")

            return Clone
        end

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            ViewportObject = CloneViewportObject(Info.Object)
        end

        local Viewport = {
            Connections = {},
            Destroyed = false,

            Object = ViewportObject :: PVInstance,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            OwnsCamera = not Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        local function SetTabScrollingEnabled(Enabled)
            for _, Side in Groupbox.Tab.Sides do
                Side.ScrollingEnabled = Enabled
            end
        end

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = math.max(MaxExtent * 1.75, 3)
            local ModelPosition = (Viewport.Object :: PVInstance):GetPivot().Position
            local FocusOffset = Vector3.new(0, MaxExtent * 0.08, 0)

            MinZoomDistance = math.max(MaxExtent * 0.8, 1.5)
            MaxZoomDistance = math.max(MaxExtent * 4, MinZoomDistance + 1)
            Viewport.Camera.CFrame = CFrame.lookAt(
                ModelPosition + FocusOffset + Vector3.new(0, 0, CameraDistance),
                ModelPosition + FocusOffset
            )
        end

        local function ZoomCamera(Amount)
            local ModelPosition = (Viewport.Object :: PVInstance):GetPivot().Position
            local Camera = Viewport.Camera
            local Offset = Camera.CFrame.Position - ModelPosition
            local Distance = Offset.Magnitude
            if Distance <= 0.001 then
                return
            end

            local TargetDistance = math.clamp(Distance - Amount, MinZoomDistance, MaxZoomDistance)
            Camera.CFrame = CFrame.lookAt(
                ModelPosition + Offset.Unit * TargetDistance,
                ModelPosition,
                Camera.CFrame.UpVector
            )
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            Ambient = Library.Scheme.MainColor:Lerp(Library.Scheme.FontColor, 0.58),
            BackgroundColor3 = Library.Scheme.BackgroundColor,
            BackgroundTransparency = 0.08,
            LightColor = Library.Scheme.FontColor,
            LightDirection = Vector3.new(-1, -0.7, -1),
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
        })

        Library:AddToRegistry(ViewportFrame, {
            Ambient = function()
                return Library.Scheme.MainColor:Lerp(Library.Scheme.FontColor, 0.58)
            end,
            BackgroundColor3 = "BackgroundColor",
            LightColor = "FontColor",
        })

        table.insert(Viewport.Connections, ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            SetTabScrollingEnabled(false)
        end))

        table.insert(Viewport.Connections, ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            SetTabScrollingEnabled(true)
        end))

        table.insert(Viewport.Connections, ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
            then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
                SetTabScrollingEnabled(false)
            end
        end))

        table.insert(Viewport.Connections, UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
            then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
                SetTabScrollingEnabled(true)
            end
        end))

        table.insert(Viewport.Connections, UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = (Viewport.Object :: PVInstance):GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        table.insert(Viewport.Connections, ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                ZoomCamera(input.Position.Z * 1.5)
            end
        end))

        table.insert(Viewport.Connections, UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
                SetTabScrollingEnabled(false)
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                ZoomCamera(delta)
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
                SetTabScrollingEnabled(true)
            end
        end))

        ;(Viewport.Object :: PVInstance).Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(
                typeof(Object) == "Instance" and (Object:IsA("BasePart") or Object:IsA("Model")),
                "Object must be a BasePart or Model."
            )

            if Object == Viewport.Object and Clone ~= true then
                return
            end

            if Clone then
                Object = CloneViewportObject(Object)
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            ;(Viewport.Object :: PVInstance).Parent = ViewportFrame

            if Viewport.AutoFocus then
                FocusCamera()
            end

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            if Viewport.OwnsCamera and Viewport.Camera and Viewport.Camera ~= Camera then
                Viewport.Camera:Destroy()
            end

            Viewport.Camera = Camera
            Viewport.OwnsCamera = false
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
            if not Interactive then
                Dragging = false
                Pinching = false
                SetTabScrollingEnabled(true)
            end
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Viewport.Holder = Holder
        Viewport.Box = Box
        Viewport.Frame = ViewportFrame
        table.insert(Groupbox.Elements, Viewport)

        Options[Idx] = Viewport

        function Viewport:Destroy()
            if Viewport.Destroyed then
                return
            end

            Viewport.Destroyed = true
            SetTabScrollingEnabled(true)

            if Viewport.Connections then
                for _, Connection in Viewport.Connections do
                    Connection:Disconnect()
                end
                table.clear(Viewport.Connections)
            end

            if Viewport.OwnsCamera and Viewport.Camera then
                Viewport.Camera:Destroy()
                Viewport.Camera = nil
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Viewport)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Image)

        local Groupbox = self
        local Container = Groupbox.Container

        local Image = {
            Connections = {},
            Destroyed = false,

            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = math.clamp(tonumber(Info.Transparency) or 0, 0, 1),
            BackgroundTransparency = math.clamp(tonumber(Info.BackgroundTransparency) or 0, 0, 1),
            BackgroundColor = typeof(Info.BackgroundColor) == "Color3" and Info.BackgroundColor or nil,
            OutlineColor = typeof(Info.OutlineColor) == "Color3" and Info.OutlineColor or nil,
            OutlineTransparency = math.clamp(tonumber(Info.OutlineTransparency) or 0.42, 0, 1),
            OutlineThickness = math.clamp(tonumber(Info.OutlineThickness) or 1, 0, 4),
            CornerRadius = math.clamp(tonumber(Info.CornerRadius) or 4, 0, 24),
            Padding = math.clamp(tonumber(Info.Padding) or 6, 0, math.max(0, math.min(48, math.floor((tonumber(Info.Height) or 200) * 0.5) - 1))),
            ImageSize = typeof(Info.ImageSize) == "UDim2" and Info.ImageSize or UDim2.fromScale(1, 1),
            ImagePosition = typeof(Info.ImagePosition) == "UDim2" and Info.ImagePosition or UDim2.fromScale(0.5, 0.5),
            ImageAnchorPoint = typeof(Info.ImageAnchorPoint) == "Vector2" and Info.ImageAnchorPoint or Vector2.new(0.5, 0.5),
            ImageScale = math.clamp(tonumber(Info.ImageScale) or 1, 0.1, 4),
            TileSize = typeof(Info.TileSize) == "UDim2" and Info.TileSize or UDim2.fromOffset(64, 64),
            Rotation = tonumber(Info.Rotation) or 0,
            AspectRatio = math.max(0, tonumber(Info.AspectRatio) or 0),

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            BackgroundColor3 = Image.BackgroundColor or Library.Scheme.MainColor,
            BorderSizePixel = 0,
            BackgroundTransparency = Image.BackgroundTransparency,
            ClipsDescendants = true,
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        local BoxCorner = New("UICorner", {
            CornerRadius = UDim.new(0, Image.CornerRadius),
            Parent = Box,
        })

        local BoxStroke = New("UIStroke", {
            Color = Image.OutlineColor or Library.Scheme.OutlineColor,
            Thickness = Image.OutlineThickness,
            Transparency = Image.OutlineTransparency,
            Parent = Box,
        })

        local BoxPadding = New("UIPadding", {
            PaddingBottom = UDim.new(0, Image.Padding),
            PaddingLeft = UDim.new(0, Image.Padding),
            PaddingRight = UDim.new(0, Image.Padding),
            PaddingTop = UDim.new(0, Image.Padding),
            Parent = Box,
        })

        Library:AddToRegistry(Box, {
            BackgroundColor3 = function()
                return Image.BackgroundColor or Library.Scheme.MainColor
            end,
        })
        Library:AddToRegistry(BoxStroke, {
            Color = function()
                return Image.OutlineColor or Library.Scheme.OutlineColor
            end,
        })

        local ImageProperties = {
            AnchorPoint = Image.ImageAnchorPoint,
            BackgroundTransparency = 1,
            Position = Image.ImagePosition,
            Size = Image.ImageSize,
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            TileSize = Image.TileSize,
            Rotation = Image.Rotation,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)
        local ImageScale = New("UIScale", {
            Scale = Image.ImageScale,
            Parent = ImageLabel,
        })
        local AspectConstraint

        local function ApplyAspectRatio()
            if Image.AspectRatio > 0 then
                if not AspectConstraint then
                    AspectConstraint = New("UIAspectRatioConstraint", {
                        AspectRatio = Image.AspectRatio,
                        AspectType = Enum.AspectType.ScaleWithParentSize,
                        DominantAxis = Enum.DominantAxis.Width,
                        Parent = ImageLabel,
                    })
                else
                    AspectConstraint.AspectRatio = Image.AspectRatio
                end
            elseif AspectConstraint then
                AspectConstraint:Destroy()
                AspectConstraint = nil
            end
        end

        ApplyAspectRatio()

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Image:SetPadding(Image.Padding)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            ImageLabel.ImageRectOffset = Image.RectOffset
            ImageLabel.ImageRectSize = Image.RectSize
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetImageSize(Size: UDim2)
            assert(typeof(Size) == "UDim2", "Image size must be a UDim2 value.")
            Image.ImageSize = Size
            ImageLabel.Size = Size
        end

        function Image:SetImageScale(Scale: number)
            assert(typeof(Scale) == "number", "Image scale must be a number.")
            Image.ImageScale = math.clamp(Scale, 0.1, 4)
            ImageScale.Scale = Image.ImageScale
        end

        function Image:SetImagePosition(Position: UDim2, AnchorPoint: Vector2?)
            assert(typeof(Position) == "UDim2", "Image position must be a UDim2 value.")
            if AnchorPoint ~= nil then
                assert(typeof(AnchorPoint) == "Vector2", "Image anchor point must be a Vector2 value.")
                Image.ImageAnchorPoint = AnchorPoint
                ImageLabel.AnchorPoint = AnchorPoint
            end
            Image.ImagePosition = Position
            ImageLabel.Position = Position
        end

        function Image:SetTileSize(Size: UDim2)
            assert(typeof(Size) == "UDim2", "Tile size must be a UDim2 value.")
            Image.TileSize = Size
            ImageLabel.TileSize = Size
        end

        function Image:SetRotation(Rotation: number)
            assert(typeof(Rotation) == "number", "Rotation must be a number.")
            Image.Rotation = Rotation
            ImageLabel.Rotation = Rotation
        end

        function Image:SetAspectRatio(Ratio: number)
            assert(typeof(Ratio) == "number" and Ratio >= 0, "Aspect ratio must be zero or greater.")
            Image.AspectRatio = Ratio
            ApplyAspectRatio()
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetBackgroundTransparency(Transparency: number)
            assert(typeof(Transparency) == "number" and Transparency >= 0 and Transparency <= 1, "Background transparency must be between 0 and 1.")
            Image.BackgroundTransparency = Transparency
            Box.BackgroundTransparency = Transparency
        end

        function Image:SetOutlineTransparency(Transparency: number)
            assert(typeof(Transparency) == "number" and Transparency >= 0 and Transparency <= 1, "Outline transparency must be between 0 and 1.")
            Image.OutlineTransparency = Transparency
            BoxStroke.Transparency = Transparency
        end

        function Image:SetBackgroundColor(Color: Color3?)
            assert(Color == nil or typeof(Color) == "Color3", "Background color must be a Color3 value or nil.")
            Image.BackgroundColor = Color
            Box.BackgroundColor3 = Color or Library.Scheme.MainColor
        end

        function Image:SetOutlineColor(Color: Color3?)
            assert(Color == nil or typeof(Color) == "Color3", "Outline color must be a Color3 value or nil.")
            Image.OutlineColor = Color
            BoxStroke.Color = Color or Library.Scheme.OutlineColor
        end

        function Image:SetPadding(Padding: number)
            assert(typeof(Padding) == "number" and Padding >= 0, "Padding must be zero or greater.")
            Image.Padding = math.clamp(Padding, 0, math.max(0, math.min(48, math.floor(Image.Height * 0.5) - 1)))
            local Value = UDim.new(0, Image.Padding)
            BoxPadding.PaddingBottom = Value
            BoxPadding.PaddingLeft = Value
            BoxPadding.PaddingRight = Value
            BoxPadding.PaddingTop = Value
        end

        function Image:SetCornerRadius(Radius: number)
            assert(typeof(Radius) == "number" and Radius >= 0, "Corner radius must be zero or greater.")
            Image.CornerRadius = math.clamp(Radius, 0, 24)
            BoxCorner.CornerRadius = UDim.new(0, Image.CornerRadius)
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Image.Holder = Holder
        Image.Box = Box
        Image.ImageLabel = ImageLabel
        Image.ImageScaleObject = ImageScale
        Image.Stroke = BoxStroke
        table.insert(Groupbox.Elements, Image)

        Options[Idx] = Image

        function Image:Destroy()
            if Image.Destroyed then
                return
            end

            Image.Destroyed = true

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Image)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Image
    end

    function Funcs:AddVideo(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Video)

        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Connections = {},
            Destroyed = false,

            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Groupbox.Elements, Video)

        Options[Idx] = Video

        function Video:Destroy()
            if Video.Destroyed then
                return
            end

            Video.Destroyed = true

            if Video.Connections then
                for _, Connection in Video.Connections do
                    Connection:Disconnect()
                end
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Video)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Connections = {},
            Destroyed = false,

            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder

        Groupbox:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Groupbox:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Groupbox.Elements, Passthrough)

        Options[Idx] = Passthrough

        function Passthrough:Destroy()
            if Passthrough.Destroyed then
                return
            end

            Passthrough.Destroyed = true

            if Passthrough.Connections then
                for _, Connection in Passthrough.Connections do
                    Connection:Disconnect()
                end
            end

            if Holder then 
                Holder:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.Elements, Passthrough)
            if ElemIdx then 
                table.remove(Groupbox.Elements, ElemIdx) 
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Passthrough
    end

    function Funcs:AddAddon(Idx, Addon, Info)
        if self.Destroyed then return nil end
        assert(type(Addon) == "table", "Addon module must be a table")

        local Mount = Addon.Mount
        if type(Mount) ~= "function" then
            Mount = Addon.CreateEmbedded
        end
        assert(type(Mount) == "function", "Addon module must expose Mount")

        local Success, Result = pcall(Mount, Library, self, Idx, Info or {})
        if not Success then
            error("Unable to mount addon: " .. tostring(Result), 2)
        end
        assert(type(Result) == "table", "Addon mount must return a controller table")
        return Result
    end

    function Funcs:AddDependencyBox()
        if self.Destroyed then return nil end

        local Groupbox = self
        local Container = Groupbox.Container

        local DepboxContainer
        local DepboxList

        do
            DepboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepboxContainer,
            })
        end

        local Depbox = {
            Connections = {},
            Destroyed = false,

            Visible = false,
            Dependencies = {},

            Holder = DepboxContainer,
            Container = DepboxContainer,

            Elements = {},
            DependencyBoxes = {}
        }

        function Depbox:Resize()
            if Depbox.Destroyed or not DepboxContainer.Parent then
                return
            end

            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y / Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Update(CancelSearch)
            for _, Dependency in Depbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepboxContainer.Visible = false
                    Depbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    end
                end
            end

            Depbox.Visible = true
            DepboxContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    Depbox:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not Depbox.Visible then
                return
            end

            Depbox:Resize()
        end)

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        function Depbox:Destroy()
            if Depbox.Destroyed then
                return
            end

            Depbox.Destroyed = true

            if Depbox.Connections then
                for _, Connection in Depbox.Connections do
                    Connection:Disconnect()
                end
                table.clear(Depbox.Connections)
            end

            for _, Element in table.clone(Depbox.Elements) do
                if Element.Destroy then
                    Element:Destroy()
                end
            end
            table.clear(Depbox.Elements)

            for _, SubDepbox in table.clone(Depbox.DependencyBoxes) do
                if SubDepbox.Destroy then
                    SubDepbox:Destroy()
                end
            end
            table.clear(Depbox.DependencyBoxes)

            if DepboxContainer then 
                DepboxContainer:Destroy() 
            end

            local ElemIdx = table.find(Groupbox.DependencyBoxes, Depbox)
            if ElemIdx then 
                table.remove(Groupbox.DependencyBoxes, ElemIdx)
            end

            local LibIdx = table.find(Library.DependencyBoxes, Depbox)
            if LibIdx then 
                table.remove(Library.DependencyBoxes, LibIdx) 
            end
        end

        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        if self.Destroyed then return nil end

        local Groupbox = self
        local Tab = Groupbox.Tab
        local BoxHolder = Groupbox.BoxHolder

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "SurfaceColor",
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = BoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = DepGroupboxContainer,
                })
            )
            Library:AddOutline(DepGroupboxContainer)

            DepGroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepGroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = DepGroupboxContainer,
            })
        end

        local DepGroupbox = {
            Connections = {},
            Destroyed = false,

            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = DepGroupboxContainer,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        function DepGroupbox:Resize()
            if DepGroupbox.Destroyed or not DepGroupboxContainer.Parent then
                return
            end

            DepGroupboxContainer.Size = UDim2.new(1, 0, 0, (DepGroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
        end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in DepGroupbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepGroupboxContainer.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                DepGroupboxContainer.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        setmetatable(DepGroupbox, BaseGroupbox)

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyBoxes, DepGroupbox :: any)

        function DepGroupbox:Destroy()
            if DepGroupbox.Destroyed then
                return
            end

            DepGroupbox.Destroyed = true

            if DepGroupbox.Connections then
                for _, Connection in DepGroupbox.Connections do
                    Connection:Disconnect()
                end
                table.clear(DepGroupbox.Connections)
            end

            for _, Element in table.clone(DepGroupbox.Elements) do
                if Element.Destroy then
                    Element:Destroy()
                end
            end
            table.clear(DepGroupbox.Elements)

            for _, SubDepbox in table.clone(DepGroupbox.DependencyBoxes) do
                if SubDepbox.Destroy then
                    SubDepbox:Destroy()
                end
            end
            table.clear(DepGroupbox.DependencyBoxes)

            if DepGroupboxContainer then 
                DepGroupboxContainer:Destroy() 
            end

            local ElemIdx = table.find(Tab.DependencyGroupboxes, DepGroupbox)
            if ElemIdx then 
                table.remove(Tab.DependencyGroupboxes, ElemIdx) 
            end

            local LibIdx = table.find(Library.DependencyBoxes, DepGroupbox)
            if LibIdx then 
                table.remove(Library.DependencyBoxes, LibIdx) 
            end
        end

        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local ThemeAliases = {
    default = "Default",
    graphite = "Default",
    gray = "Default",
    grey = "Default",
    metal = "Metal",
    material = "Metal",
    purple = "Metal",
    blackpurple = "Metal",
    amethyst = "Metal",
    midnight = "Midnight",
    night = "Midnight",
    dark = "Midnight",
    steel = "Steel",
    slate = "Steel",
    bluegray = "Steel",
    bluegrey = "Steel",
    sage = "Sage",
    forest = "Sage",
    green = "Sage",
    ash = "Ash",
    warmgray = "Ash",
    warmgrey = "Ash",
    taupe = "Ash",
}

function Library:ResolveThemeName(Theme): string
    if typeof(Theme) ~= "string" then
        return Library.DefaultTheme
    end

    if Library.Themes[Theme] then
        return Theme
    end
    local Normalized = string.lower(Theme):gsub("[%s_%-]", "")
    return ThemeAliases[Normalized] or Library.DefaultTheme
end

function Library:RegisterTheme(Name, Overrides, Base)
    assert(type(Name) == "string" and Name ~= "", "Theme name must be a non-empty string")
    assert(type(Overrides) == "table", "Theme overrides must be a table")
    local Theme = table.clone(Library.Themes[Library:ResolveThemeName(Base or Library.DefaultTheme)])
    for Key, Value in Overrides do
        assert(Theme[Key] ~= nil, "Unknown theme property: " .. tostring(Key))
        assert(typeof(Value) == typeof(Theme[Key]), "Invalid theme property: " .. tostring(Key))
        Theme[Key] = Value
    end
    Library.Themes[Name] = Theme
    if Library.ThemeManager and Library.ThemeManager.RefreshThemeList then
        Library.ThemeManager:RefreshThemeList()
    end
    return Library
end

function Library:SetPalette(Overrides)
    assert(type(Overrides) == "table", "Palette overrides must be a table")
    for Key, Value in Overrides do
        assert(typeof(Library.Scheme[Key]) == "Color3" and typeof(Value) == "Color3", "Invalid palette color: " .. tostring(Key))
    end
    for Key, Value in Overrides do
        Library.Scheme[Key] = Value
    end
    if Overrides.ElementColor and not Overrides.MainColor then
        Library.Scheme.MainColor = Overrides.ElementColor
    elseif Overrides.MainColor and not Overrides.ElementColor then
        Library.Scheme.ElementColor = Overrides.MainColor
    end
    if (Overrides.AccentColor or Overrides.ElementColor or Overrides.MainColor) and not Overrides.AccentSoftColor then
        Library.Scheme.AccentSoftColor = Library.Scheme.ElementColor:Lerp(Library.Scheme.AccentColor, 0.18)
    end
    Library:UpdateColorsUsingRegistry()
    Library:RefreshThemeState()
    if Library.ThemeManager and Library.ThemeManager.SyncFromLibrary then
        Library.ThemeManager:SyncFromLibrary(Library.CurrentTheme)
    end
    return Library
end

function Library:SetTheme(Theme)
    local ThemeName = Library:ResolveThemeName(Theme)
    local ThemeData = Library.Themes[ThemeName] or Library.Themes[Library.DefaultTheme]

    for _, Index in {
        "BackgroundColor",
        "MainColor",
        "TopBarColor",
        "SurfaceColor",
        "RaisedColor",
        "ElementColor",
        "HoverColor",
        "AccentColor",
        "AccentSoftColor",
        "OutlineColor",
        "FontColor",
        "MutedFontColor",
        "ShadowColor",
        "RedColor",
        "WarningColor",
        "DestructiveColor",
        "DarkColor",
        "WhiteColor",
    } do
        Library.Scheme[Index] = ThemeData[Index]
    end

    Library.Scheme.Red = nil
    Library.Scheme.Dark = nil
    Library.Scheme.White = nil
    Library.Scheme.BackgroundImage = ThemeData.BackgroundImage or ""
    Library.IsLightTheme = ThemeData.IsLight == true
    Library.CurrentTheme = ThemeName

    if Library:GetDesignToken("Effects.ThemeGeometry", false) then
        Library:SetDesign({
            Radius = {
                Window = ThemeData.CornerRadius,
                Card = math.max(0, ThemeData.CornerRadius - 1),
                Popup = ThemeData.CornerRadius,
                Control = math.max(0, ThemeData.CornerRadius - 2),
                Indicator = math.max(0, math.min(3, ThemeData.CornerRadius - 2)),
            },
        })
    end
    if Library.Window then
        Library.Window:SetBackgroundImage(Library.Scheme.BackgroundImage)
    end

    Library:SetFont(Library.ThemeFontOverride or ThemeData.Font, true)
    Library:UpdateColorsUsingRegistry()
    Library:RefreshThemeState()
    Library:UpdateColorsUsingRegistry()

    if Library.ThemeManager and Library.ThemeManager.SyncFromLibrary then
        Library.ThemeManager:SyncFromLibrary(ThemeName)
    end

    return Library
end

function Library:SetFont(FontFace, SkipRegistryUpdate: boolean?)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace :: any)
    end

    Library.Scheme.Font = FontFace
    Templates.Window.Font = FontFace
    Library:ClearTextBoundsCache()
    if not SkipRegistryUpdate then
        Library:UpdateColorsUsingRegistry()
        for _, Option in Options do
            if type(Option.RefreshTypography) == "function" then Option:RefreshTypography() end
        end
    end
end

function Library:SetBackgroundImage(Image: string | number)
    assert(typeof(Image) == "string" or typeof(Image) == "number", "Expected string/number got " .. typeof(Image))
    
    Library.Scheme.BackgroundImage = Image
    if Library.Window then
        Library.Window:SetBackgroundImage(Image)
    end

    Library:UpdateColorsUsingRegistry()
end

local function NotificationViewport()
    local Viewport = GetViewportSize()
    local Scale = math.max(Library.DPIScale, 0.01)
    local Margin = Library.NotificationStyle.Margin
    return math.max(1, math.floor(Viewport.X / Scale - Margin * 2)),
        math.max(1, math.floor(Viewport.Y / Scale - Margin * 2))
end

function Library:UpdateNotificationPositions(Snap: boolean?)
    if Library.PositioningNotifications then return end
    Library.PositioningNotifications = true
    local _, MaximumHeight = NotificationViewport()
    local Total = 0
    for _, Root in NotifyOrder do
        local Data = Library.Notifications[Root]
        if Data then Total += Data.Height + Library.NotificationStyle.Gap end
    end
    while #NotifyOrder > 1 and (Total - Library.NotificationStyle.Gap > MaximumHeight or #NotifyOrder > Library.NotificationStyle.MaxVisible) do
        local Oldest = Library.Notifications[NotifyOrder[1]]
        if Oldest then
            Total -= Oldest.Height + Library.NotificationStyle.Gap
            Oldest:Destroy(true)
        else
            table.remove(NotifyOrder, 1)
        end
    end
    local IsLeft = Library.NotifySide == "Left"
    local RunningY = 0
    for _, Root in NotifyOrder do
        local Data = Library.Notifications[Root]
        if not Data or Data.Destroyed then continue end
        Root.AnchorPoint = Vector2.new(IsLeft and 0 or 1, 0)
        local Target = UDim2.new(IsLeft and 0 or 1, 0, 0, RunningY)
        if Snap or not Data.PositionInitialized then
            Library:CancelTween(Root, "NotifyPosition")
            Root.Position = Target
        else
            Library:PlayTween(Root, "NotifyPosition", Library.NotifyTweenInfo, { Position = Target })
        end
        Data.PositionInitialized = true
        RunningY += Data.Height + Library.NotificationStyle.Gap
    end
    Library.PositioningNotifications = false
end

function Library:SetNotifySide(Side: string)
    local Normalized = string.lower(tostring(Side))
    assert(Normalized == "left" or Normalized == "right", "Notification side must be Left or Right")
    Library.NotifySide = Normalized == "left" and "Left" or "Right"
    local IsLeft = Library.NotifySide == "Left"
    local Margin = Library.NotificationStyle.Margin
    local Width = NotificationViewport()
    NotificationArea.AnchorPoint = Vector2.new(IsLeft and 0 or 1, 0)
    NotificationArea.Position = UDim2.new(IsLeft and 0 or 1, IsLeft and Margin or -Margin, 0, Margin)
    NotificationArea.Size = UDim2.fromOffset(math.min(Width, Library.NotificationStyle.Width), 0)
    Library:UpdateNotificationPositions(true)
    return Library
end

function Library:SetNotificationOptions(Info)
    assert(typeof(Info) == "table", "Notification options must be a table")
    if Info.Side ~= nil then
        local Side = string.lower(tostring(Info.Side))
        assert(Side == "left" or Side == "right", "Notification side must be Left or Right")
    end
    local Next = table.clone(Library.NotificationStyle)
    for Key, Limits in { Width = { 160, 520 }, Margin = { 0, 40 }, Gap = { 0, 24 }, Padding = { 4, 24 }, CornerRadius = { 0, 18 }, MaxVisible = { 1, 20 }, TextSize = { 9, 20 }, TitleTextSize = { 9, 20 }, DescriptionTextSize = { 9, 20 } } do
        local Value = tonumber(Info[Key])
        if Value and Value == Value and math.abs(Value) < math.huge then
            Next[Key] = math.clamp(math.floor(Value), Limits[1], Limits[2])
        end
    end
    if Info.TextSize ~= nil then
        Next.TitleTextSize = Next.TextSize
        Next.DescriptionTextSize = math.max(9, Next.TextSize - 1)
    end
    local Duration = tonumber(Info.DefaultDuration)
    if Duration and Duration == Duration and Duration < math.huge then Next.DefaultDuration = math.max(0, Duration) end
    for _, Key in { "Accent", "ShowProgress", "Dismissible" } do
        if Info[Key] ~= nil then Next[Key] = Info[Key] == true end
    end
    Library.NotificationStyle = Next
    for _, Root in table.clone(NotifyOrder) do
        local Data = Library.Notifications[Root]
        if Data then Data:Resize() end
    end
    Library:SetNotifySide(Info.Side or Library.NotifySide)
    return Library
end

Library.SetNotifyOptions = Library.SetNotificationOptions

function Library:ClearNotifications()
    for _, Data in table.clone(Library.Notifications) do Data:Destroy(true) end
    return Library
end

function Library:Notify(...)
    assert(not Library.Unloaded, "Cannot notify after unloading the library")
    local Value = select(1, ...)
    local Info = typeof(Value) == "table" and table.clone(Value) or {
        Description = tostring(Value or ""), Time = select(2, ...), SoundId = select(3, ...), Volume = select(4, ...),
    }
    local Data = { Destroyed = false, Connections = {}, Height = 0, Progress = 0 }
    Data.Title = tostring(Info.Title or "")
    Data.Description = tostring(Info.Description or "")
    Data.Time = Info.Time or Library.NotificationStyle.DefaultDuration
    if typeof(Data.Time) ~= "Instance" then
        local Duration = tonumber(Data.Time)
        Data.Time = Duration and Duration == Duration and Duration < math.huge and math.max(0, Duration) or Library.NotificationStyle.DefaultDuration
    end
    local Steps = tonumber(Info.Steps)
    Data.Steps = Steps and Steps == Steps and Steps > 0 and Steps < math.huge and Steps or nil
    Data.Persist = Info.Persist == true
    Data.Variant = string.lower(tostring(Info.Variant or "Default"))
    Data.UsesDefaultWidth = Info.Width == nil
    Data.SoundId, Data.Volume = Info.SoundId, Info.Volume
    Data.Icon, Data.BigIcon = Info.Icon, Info.BigIcon
    Data.IconColor, Data.AccentColor = Info.IconColor, Info.AccentColor
    Data.TitleColor, Data.DescriptionColor = Info.TitleColor, Info.DescriptionColor
    local AccentColor = Info.AccentColor or ((Data.Variant == "error" or Data.Variant == "danger") and "DestructiveColor"
        or Data.Variant == "warning" and "WarningColor" or Data.Variant == "success" and Color3.fromRGB(91, 194, 137) or "AccentColor")
    local Root = New("Frame", { BackgroundTransparency = 1, Parent = NotificationArea })
    local Holder = New("CanvasGroup", {
        BackgroundColor3 = "MainColor", ClipsDescendants = true, GroupTransparency = 1,
        Position = UDim2.fromOffset(0, -3), Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = Root,
    })
    local Corner = New("UICorner", { Parent = Holder })
    local Stroke = Library:AddOutline(Holder)
    Stroke.Transparency = 0.62
    local Accent = New("Frame", { BackgroundColor3 = AccentColor, Parent = Holder })
    local Title = New("TextLabel", {
        BackgroundTransparency = 1, FontFace = function() return Library.Scheme.Font end,
        RichText = false, Text = Data.Title, TextColor3 = Info.TitleColor or "FontColor",
        TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = Holder,
    })
    local Desc = New("TextLabel", {
        BackgroundTransparency = 1, FontFace = function() return Library.Scheme.Font end,
        RichText = false, Text = Data.Description, TextColor3 = Info.DescriptionColor or "MutedFontColor",
        TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = Holder,
    })
    local IconData = (Info.BigIcon or Info.Icon) and Library:GetCustomIcon(Info.BigIcon or Info.Icon)
    local Icon = New("ImageLabel", {
        BackgroundTransparency = 1, Image = IconData and IconData.Url or "",
        ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
        ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
        ImageColor3 = Info.IconColor or "MutedFontColor", Visible = IconData ~= nil and IconData ~= false, Parent = Holder,
    })
    local Close = New("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = Holder })
    local CloseData = Library:GetIcon("x")
    New("ImageLabel", {
        BackgroundTransparency = 1, Image = CloseData and CloseData.Url or "",
        ImageRectOffset = CloseData and CloseData.ImageRectOffset or Vector2.zero,
        ImageRectSize = CloseData and CloseData.ImageRectSize or Vector2.zero,
        ImageColor3 = "MutedFontColor", Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(12, 12), Parent = Close,
    })
    local Timer = New("Frame", { BackgroundColor3 = "OutlineColor", BackgroundTransparency = 0.6, ClipsDescendants = true, Parent = Holder })
    local Fill = New("Frame", { BackgroundColor3 = AccentColor, Size = UDim2.fromScale(Data.Steps and 0 or 1, 1), Parent = Timer })
    local Started = os.clock()
    local TimerTask, CleanupTask, TimerTween
    local Resizing = false
    local function Release()
        if Data.Released then return end
        Data.Released = true
        Library:CancelTween(Root, "NotifyPosition")
        Library:CancelTween(Holder, "NotifyEnterPosition")
        Library:CancelTween(Holder, "NotifyVisibility")
        Library.Notifications[Root] = nil
        Library:ReleaseRegistryTree(Root)
        Root:Destroy()
    end
    function Data:Resize()
        if Data.Destroyed then return Data end
        if Resizing then Data.ResizePending = true; return Data end
        Resizing = true
        for Key, Limits in { Width = { 160, 520 }, Padding = { 4, 24 }, CornerRadius = { 0, 18 } } do
            local Number = tonumber(Info[Key])
            if not Number or Number ~= Number or math.abs(Number) == math.huge then Number = Library.NotificationStyle[Key] end
            Data[Key] = math.clamp(math.floor(Number), Limits[1], Limits[2])
        end
        local LegacySize = tonumber(Info.TextSize)
        if not LegacySize or LegacySize ~= LegacySize or math.abs(LegacySize) == math.huge then LegacySize = nil end
        local TitleSize = tonumber(Info.TitleTextSize)
        if not TitleSize or TitleSize ~= TitleSize or math.abs(TitleSize) == math.huge then TitleSize = LegacySize or Library.NotificationStyle.TitleTextSize end
        local DescriptionSize = tonumber(Info.DescriptionTextSize)
        if not DescriptionSize or DescriptionSize ~= DescriptionSize or math.abs(DescriptionSize) == math.huge then
            DescriptionSize = LegacySize and LegacySize - 1 or Library.NotificationStyle.DescriptionTextSize
        end
        Data.TitleTextSize = math.clamp(math.floor(TitleSize), 9, 20)
        Data.DescriptionTextSize = math.clamp(math.floor(DescriptionSize), 9, 20)
        Data.TextSize = Data.TitleTextSize
        for _, Key in { "Accent", "ShowProgress", "Dismissible" } do
            Data[Key] = if Info[Key] ~= nil then Info[Key] == true else Library.NotificationStyle[Key]
        end
        local AvailableWidth, AvailableHeight = NotificationViewport()
        local Width = math.min(Data.Width, AvailableWidth)
        local Padding = math.min(Data.Padding, math.max(0, math.floor((Width - 1) / 2)))
        local IconSize = Info.BigIcon and 24 or 16
        local Left = Padding + (IconData and IconSize + 8 or 0) + (Data.Accent and 4 or 0)
        local TextWidth = math.max(1, Width - Left - Padding - (Data.Dismissible and 28 or 0))
        Title.FontFace, Desc.FontFace = Library.Scheme.Font, Library.Scheme.Font
        Title.TextSize, Desc.TextSize = Data.TitleTextSize, Data.DescriptionTextSize
        Title.Visible, Desc.Visible = Data.Title ~= "", Data.Description ~= ""
        local _, TitleHeight = Library:GetTextBounds(Data.Title, Library.Scheme.Font, Data.TitleTextSize, TextWidth)
        local _, DescHeight = Library:GetTextBounds(Data.Description, Library.Scheme.Font, Data.DescriptionTextSize, TextWidth)
        if Data.Destroyed then Resizing = false; return Data end
        TitleHeight = Title.Visible and math.ceil(TitleHeight) or 0
        DescHeight = Desc.Visible and math.ceil(DescHeight) or 0
        local Gap = Title.Visible and Desc.Visible and 2 or 0
        Timer.Visible = Data.ShowProgress and (Data.Steps ~= nil or (not Data.Persist and typeof(Data.Time) ~= "Instance"))
        if Timer.Visible and not Data.Steps and typeof(Data.Time) == "number" then
            if not TimerTween then
                local Remaining = math.max(0, Data.Time - (os.clock() - Started))
                Fill.Size = UDim2.fromScale(Data.Time > 0 and Remaining / Data.Time or 0, 1)
                TimerTween = TweenService:Create(Fill, TweenInfo.new(Remaining, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) })
                TimerTween:Play()
            end
        elseif TimerTween then
            TimerTween:Cancel()
            TimerTween = nil
        end
        local TimerHeight = Timer.Visible and 8 or 0
        local MaxTextHeight = math.max(1, AvailableHeight - Padding * 2 - TimerHeight)
        TitleHeight = math.min(TitleHeight, MaxTextHeight)
        DescHeight = math.min(DescHeight, math.max(0, MaxTextHeight - TitleHeight - Gap))
        local ContentHeight = math.max(TitleHeight + Gap + DescHeight, IconData and IconSize or 0, Data.Dismissible and 24 or 1)
        Data.Height = math.min(AvailableHeight, ContentHeight + Padding * 2 + TimerHeight)
        Root.Size = UDim2.fromOffset(Width, Data.Height)
        Corner.CornerRadius = UDim.new(0, Data.CornerRadius)
        Title.Position, Title.Size = UDim2.fromOffset(Left, Padding), UDim2.fromOffset(TextWidth, TitleHeight)
        Desc.Position, Desc.Size = UDim2.fromOffset(Left, Padding + TitleHeight + Gap), UDim2.fromOffset(TextWidth, DescHeight)
        Icon.Position, Icon.Size = UDim2.fromOffset(Padding, Padding), UDim2.fromOffset(IconSize, IconSize)
        Close.Visible = Data.Dismissible
        Close.Position, Close.Size = UDim2.fromOffset(math.max(0, Width - Padding - 24), math.max(0, Padding - 3)), UDim2.fromOffset(24, 24)
        Accent.Visible = Data.Accent
        Accent.Position, Accent.Size = UDim2.fromOffset(0, Padding), UDim2.fromOffset(2, math.max(1, Data.Height - Padding * 2))
        Timer.Position, Timer.Size = UDim2.fromOffset(Padding, Data.Height - Padding - 2), UDim2.fromOffset(math.max(1, Width - Padding * 2), 2)
        Resizing = false
        if Data.ResizePending then
            Data.ResizePending = false
            return Data:Resize()
        end
        if Library.Notifications[Root] then Library:UpdateNotificationPositions() end
        return Data
    end
    function Data:ChangeTitle(Text)
        if Data.Destroyed then return Data end
        Data.Title = tostring(Text or "")
        Title.Text = Data.Title
        return Data:Resize()
    end
    function Data:ChangeDescription(Text)
        if Data.Destroyed then return Data end
        Data.Description = tostring(Text or "")
        Desc.Text = Data.Description
        return Data:Resize()
    end
    function Data:ChangeStep(Step)
        if Data.Destroyed or not Data.Steps then return Data end
        local Number = tonumber(Step)
        if not Number or Number ~= Number then return Data end
        Data.Progress = math.clamp(Number, 0, Data.Steps)
        Fill.Size = UDim2.fromScale(Data.Progress / Data.Steps, 1)
        return Data
    end
    Data.SetProgress = Data.ChangeStep
    function Data:Destroy(Instant)
        if Data.Destroyed then
            if Instant then
                if CleanupTask then pcall(task.cancel, CleanupTask); CleanupTask = nil end
                Release()
            end
            return Data
        end
        Data.Destroyed = true
        if TimerTask then pcall(task.cancel, TimerTask); TimerTask = nil end
        if TimerTween then TimerTween:Cancel(); TimerTween = nil end
        for _, Connection in Data.Connections do Connection:Disconnect() end
        table.clear(Data.Connections)
        local Index = table.find(NotifyOrder, Root)
        if Index then table.remove(NotifyOrder, Index) end
        Library:UpdateNotificationPositions()
        if Instant or Library.Unloaded then Release(); return Data end
        Library:CancelTween(Holder, "NotifyEnterPosition")
        Library:PlayTween(Holder, "NotifyVisibility", Library.NotifyCloseTweenInfo, { GroupTransparency = 1 })
        CleanupTask = task.delay(Library.NotifyCloseTweenInfo.Time, function() CleanupTask = nil; Release() end)
        return Data
    end
    Data.Holder, Data.Root = Holder, Root
    Data:Resize()
    table.insert(Data.Connections, Close.Activated:Connect(function() Data:Destroy() end))
    table.insert(Data.Connections, Title:GetPropertyChangedSignal("FontFace"):Connect(function() Data:Resize() end))
    table.insert(Data.Connections, Desc:GetPropertyChangedSignal("FontFace"):Connect(function() Data:Resize() end))
    table.insert(NotifyOrder, Root)
    Library.Notifications[Root] = Data
    Library:UpdateNotificationPositions()
    Library:PlayTween(Holder, "NotifyEnterPosition", Library.NotifyTweenInfo, { Position = UDim2.fromOffset(0, 0) })
    Library:PlayTween(Holder, "NotifyVisibility", Library.NotifyTweenInfo, { GroupTransparency = 0 })
    if not Data.Persist then
        if typeof(Data.Time) == "Instance" then
            table.insert(Data.Connections, Data.Time.Destroying:Connect(function() Data:Destroy() end))
        else
            TimerTask = task.delay(math.max(0, Data.Time - (os.clock() - Started)), function()
                TimerTask = nil
                Data:Destroy()
            end)
        end
    end
    if Info.SoundId then
        local SoundId = typeof(Info.SoundId) == "number" and string.format("rbxassetid://%d", Info.SoundId) or Info.SoundId
        New("Sound", { SoundId = SoundId, Volume = math.clamp(tonumber(Info.Volume) or 1, 0, 10), PlayOnRemove = true, Parent = SoundService }):Destroy()
    end
    return Data
end

do
    local function RefreshNotifications()
        if Library.Unloaded then return end
        for _, Root in table.clone(NotifyOrder) do
            local Data = Library.Notifications[Root]
            if Data then Data:Resize() end
        end
        Library:SetNotifySide(Library.NotifySide)
    end
    Library:GiveSignal(NotificationArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshNotifications))
    Library:GiveSignal(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshNotifications))
end


function Library:CreateWindow(WindowInfo)
    assert(not Library.Unloaded, "Cannot create a window after unloading the library.")
    assert(not Library.Window, "Only one window can be created per library instance.")

    WindowInfo = Library:Validate(WindowInfo, Templates.Window)
    local ViewportSize: Vector2 = GetViewportSize()

    local MaxX = math.max(1, ViewportSize.X - 32)
    local MaxY = math.max(1, ViewportSize.Y - 32)

    Library.OriginalMinSize =
        Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    Library.MinSize = Vector2.new(math.min(WindowInfo.MinContainerWidth, MaxX), Library.OriginalMinSize.Y)

    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font :: any)
    end
    WindowInfo.CornerRadius = math.clamp(WindowInfo.CornerRadius, 0, 20)
    
    
    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end
    if WindowInfo.SidebarMinWidth ~= nil then
        WindowInfo.MinSidebarWidth = WindowInfo.SidebarMinWidth
    end
    WindowInfo.MinSidebarWidth = math.max(64, WindowInfo.MinSidebarWidth)
    WindowInfo.SidebarCompactWidth = math.max(48, WindowInfo.SidebarCompactWidth)
    WindowInfo.SidebarCollapseThreshold = math.clamp(WindowInfo.SidebarCollapseThreshold, 0.1, 0.9)
    WindowInfo.CompactWidthActivation = math.max(48, WindowInfo.CompactWidthActivation)
    WindowInfo.SingleColumnWidth = math.max(240, WindowInfo.SingleColumnWidth)
    WindowInfo.HideSearchAtWidth = math.max(120, WindowInfo.HideSearchAtWidth)
    WindowInfo.ShowCompactLauncher = WindowInfo.ShowCompactLauncher ~= false
    WindowInfo.CompactLauncherSize = math.clamp(math.floor(tonumber(WindowInfo.CompactLauncherSize) or 36), 30, 48)
    WindowInfo.CompactLauncherWidth = math.clamp(
        math.floor(tonumber(WindowInfo.CompactLauncherWidth) or 172),
        math.max(128, WindowInfo.CompactLauncherSize * 3),
        280
    )
    WindowInfo.CompactLauncherDraggable = WindowInfo.CompactLauncherDraggable ~= false
    if typeof(WindowInfo.CompactLauncherPosition) ~= "UDim2" then
        WindowInfo.CompactLauncherPosition = UDim2.fromScale(0.5, 0.5)
    end
    if typeof(WindowInfo.CompactLauncherAnchorPoint) ~= "Vector2" then
        WindowInfo.CompactLauncherAnchorPoint = Vector2.new(0.5, 0.5)
    end
    if typeof(WindowInfo.CompactLauncherIcon) ~= "string" and typeof(WindowInfo.CompactLauncherIcon) ~= "number" then
        WindowInfo.CompactLauncherIcon = "maximize-2"
    end
    if typeof(WindowInfo.CompactLauncherTitle) ~= "string" then
        WindowInfo.CompactLauncherTitle = nil
    end

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch
    
    Library.Animations = WindowInfo.Animations
    Library.TabTransitionInfo = TweenInfo.new(
        math.max(0, WindowInfo.TabTransitionTime or Library.Design.Motion.TabEnter[1]),
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )
    Library.TabSwipeOffset = math.max(1, WindowInfo.TabSwipeOffset or 2)
    Library.TabSwipeFrom = WindowInfo.TabSwipeFrom or "bottom"

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local WindowScale
    local DividerLine
    local TitleHolder
    local WindowTitle
    local WindowIcon
    local RightWrapper
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local BackgroundImage
    local BottomBackground
    local FooterLabel
    local TopBar
    local MinimizeButton
    local CompactLauncher
    local CompactLauncherIcon
    local CompactLauncherTitleLabel
    local CompactLauncherStroke
    local CompactLauncherMotionScale
    local TopBarHeight = Library:GetDesignToken("Size.TopBar", 48)
    local BottomBarHeight = Library:GetDesignToken("Size.Footer", 20)

    local SidebarRatio = Library:GetDesignToken("Shell.SidebarRatio", 0.255)
    local SidebarMin = Library:GetDesignToken("Shell.SidebarMin", 184)
    local SidebarMax = Library:GetDesignToken("Shell.SidebarMax", 214)
    local InitialLeftWidth = math.clamp(math.ceil(WindowInfo.Size.X.Offset * SidebarRatio), SidebarMin, SidebarMax)
    local IsCompact = WindowInfo.EnableCompacting and (WindowInfo.SidebarCompacted or Library.IsMobile)
    local LastExpandedWidth = InitialLeftWidth
    local LastCompactState = nil
    local NavigationIconSize = Library:GetDesignToken("Size.Icon", 16)
    local NavigationIconX = 12
    local NavigationLabelX = 40
    local HeaderIconSize = math.clamp(WindowInfo.IconSize.X.Offset > 0 and WindowInfo.IconSize.X.Offset or 24, 18, 28)
    local HeaderControlWidth = WindowInfo.ShowCompactLauncher and 84 or 50

    do
        Library.KeybindFrame, Library.KeybindContainer, Library.KeybindAnimationScale = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false

        local function SnapKeybindFrame()
            local Frame = Library.KeybindFrame
            if not Frame or Frame.Position.X.Scale ~= 0 or Frame.Position.Y.Scale ~= 0.5 then
                return
            end

            local Height = Frame.AbsoluteSize.Y
            local Viewport = GetViewportSize().Y
            local Centered = Viewport * 0.5 - Height * 0.5
            local Correction = math.round(Centered) - Centered
            if Frame.Position.Y.Offset ~= Correction then
                Frame.Position = UDim2.new(0, Frame.Position.X.Offset, 0.5, Correction)
            end
        end

        Library:GiveSignal(Library.KeybindFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(SnapKeybindFrame))
        SnapKeybindFrame()
        Library:GiveSignal(Library.KeybindFrame:GetPropertyChangedSignal("Visible"):Connect(function()
            if Library.UpdatingKeybindMenuVisibility then
                return
            end

            Library.KeybindMenuRequested = Library.KeybindFrame.Visible
            Library:RefreshKeybindMenu()
        end))

        MainFrame = New("CanvasGroup", {
            BackgroundColor3 = "BackgroundColor",
            ClipsDescendants = true,
            GroupTransparency = 1,
            Name = "Main",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Parent = ScreenGui,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = MainFrame,
            })
        )
        WindowScale = New("UIScale", {
            Parent = MainFrame,
        })
        table.insert(Library.Scales, WindowScale)
        local MainOutline = Library:AddOutline(MainFrame)
        MainOutline.Transparency = Library:GetDesignToken("Stroke.StrongTransparency", 0.18)
        Library:AddSoftShadow(MainFrame, 22, Library:GetDesignToken("Opacity.Shadow", 0.44), UDim2.fromOffset(0, 5))
        Library:MakeLine(MainFrame, {
            Color = function()
                return Library:GetAccentSurfaceColor(0.2)
            end,
            Position = UDim2.fromOffset(0, TopBarHeight),
            Size = UDim2.new(1, 0, 0, 1),
            Transparency = Library:GetDesignToken("Opacity.Divider", 0.56),
        })

        DividerLine = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = Library:GetDesignToken("Opacity.Divider", 0.56),
            Position = UDim2.fromOffset(InitialLeftWidth, 0),
            Size = UDim2.new(0, 1, 1, -(BottomBarHeight + 1)),
            Parent = MainFrame,
            ZIndex = 2
        })

        local BackgroundIcon = Library:GetCustomIcon(WindowInfo.BackgroundImage)
        BackgroundImage = New("ImageLabel", {
            Image = BackgroundIcon and BackgroundIcon.Url or "",
            ImageRectOffset = BackgroundIcon and BackgroundIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = BackgroundIcon and BackgroundIcon.ImageRectSize or Vector2.zero,
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromScale(1, 1),
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 999,
            BackgroundTransparency = 1,
            ImageTransparency = 0.75,
            Visible = BackgroundIcon ~= nil,
            Parent = MainFrame,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BackgroundImage,
            })
        )

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        
        TopBar = New("Frame", {
            BackgroundColor3 = "TopBarColor",
            BackgroundTransparency = 0,
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 0, TopBarHeight - 1),
            Parent = MainFrame,
        })

        
        TitleHolder = New("Frame", {
            BackgroundColor3 = "TopBarColor",
            BackgroundTransparency = 0,
            Size = UDim2.new(0, InitialLeftWidth, 1, 0),
            Parent = TopBar,
        })
        if WindowInfo.Icon then
            local Icon = Library:GetCustomIcon(WindowInfo.Icon)
            WindowIcon = New("ImageLabel", {
                AnchorPoint = Vector2.new(IsCompact and 0.5 or 0, 0.5),
                Image = Icon and Icon.Url or "",
                ImageRectOffset = Icon and Icon.ImageRectOffset or Vector2.zero,
                ImageRectSize = Icon and Icon.ImageRectSize or Vector2.zero,
                Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 14, 0.5, 0),
                Size = UDim2.fromOffset(HeaderIconSize, HeaderIconSize),
                Parent = TitleHolder,
            })
        else
            WindowIcon = New("TextLabel", {
                AnchorPoint = Vector2.new(IsCompact and 0.5 or 0, 0.5),
                BackgroundTransparency = 1,
                Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 14, 0.5, 0),
                Size = UDim2.fromOffset(HeaderIconSize, HeaderIconSize),
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Visible = IsCompact,
                Parent = TitleHolder,
            })
        end

        local TitleX = WindowInfo.Icon and 50 or 16
        WindowTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(TitleX, 0),
            Size = UDim2.new(1, -(TitleX + 12), 1, 0),
            Text = WindowInfo.Title,
            TextSize = Library:GetDesignToken("Typography.WindowTitle", 16),
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not IsCompact,
            Parent = TitleHolder,
        })

        
        RightWrapper = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -HeaderControlWidth, 0.5, 0),
            Size = UDim2.new(1, -InitialLeftWidth - HeaderControlWidth - 8, 1, -16),
            Parent = TopBar,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, Library:GetDesignToken("Shell.HeaderGap", 8)),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Grow,
            Parent = CurrentTabInfo,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextSize = Library:GetDesignToken("Typography.SectionTitle", 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextColor3 = "MutedFontColor",
            TextWrapped = true,
            TextSize = Library:GetDesignToken("Typography.Caption", 12),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.12,
            Parent = CurrentTabInfo,
        })

        SearchBox = New("TextBox", {
            BackgroundColor3 = "ElementColor",
            PlaceholderText = "Search",
            Size = WindowInfo.SearchbarSize,
            TextSize = Library:GetDesignToken("Typography.Body", 14),
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Shrink,
            Parent = SearchBox,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Control", 4)) end,
                Parent = SearchBox,
            })
        )
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 30),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = SearchBox,
        })
        local SearchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Transparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
            Parent = SearchBox,
        })
        SearchBox.Focused:Connect(function()
            Library.Registry[SearchStroke].Color = "AccentColor"
            Library:PlayTween(SearchStroke, "SearchFocus", Library.TweenInfo, {
                Color = Library.Scheme.AccentColor,
                Transparency = 0,
            })
        end)
        SearchBox.FocusLost:Connect(function()
            Library.Registry[SearchStroke].Color = "OutlineColor"
            Library:PlayTween(SearchStroke, "SearchFocus", Library.TweenInfo, {
                Color = Library.Scheme.OutlineColor,
                Transparency = Library:GetDesignToken("Stroke.ControlTransparency", 0.38),
            })
        end)

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            New("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Image = SearchIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchIcon.ImageRectOffset,
                ImageRectSize = SearchIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Parent = SearchBox,
            })
        end

        local MoveButton = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            AutoButtonColor = false,
            BackgroundColor3 = function()
                return GetTopBarSurfaceColor(0.06)
            end,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, WindowInfo.ShowCompactLauncher and -58 or -24, 0.5, 0),
            Size = UDim2.fromOffset(Library:GetDesignToken("Shell.HeaderControl", 32), Library:GetDesignToken("Shell.HeaderControl", 32)),
            Text = "",
            ZIndex = 4,
            Parent = TopBar,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library:GetDesignToken("Radius.Control", 3)),
                Parent = MoveButton,
            })
        )
        local MoveOutline = Library:AddOutline(MoveButton)
        MoveOutline.Transparency = 0.74

        local MoveIcon = Library:GetIcon("move")
        New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = MoveIcon and MoveIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = MoveIcon and MoveIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = MoveIcon and MoveIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.42,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16),
            ZIndex = 5,
            Parent = MoveButton,
        })
        MoveButton.MouseEnter:Connect(function()
            Library:PlayTween(MoveButton, "MoveButtonHover", Library.HoverTweenInfo, {
                BackgroundTransparency = 0.78,
            })
        end)
        MoveButton.MouseLeave:Connect(function()
            Library:PlayTween(MoveButton, "MoveButtonHover", Library.HoverTweenInfo, {
                BackgroundTransparency = 1,
            })
        end)
        Library:MakeDraggable(MainFrame, MoveButton, false, true)

        if WindowInfo.ShowCompactLauncher then
            MinimizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = function()
                    return GetTopBarSurfaceColor(0.06)
                end,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -24, 0.5, 0),
                Size = UDim2.fromOffset(Library:GetDesignToken("Shell.HeaderControl", 32), Library:GetDesignToken("Shell.HeaderControl", 32)),
                Text = "",
                ZIndex = 4,
                Parent = TopBar,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library:GetDesignToken("Radius.Control", 3)),
                    Parent = MinimizeButton,
                })
            )
            local MinimizeStroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = 0.74,
                Parent = MinimizeButton,
            })
            local MinimizeIcon = Library:GetIcon("minus")
            New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = MinimizeIcon and MinimizeIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = MinimizeIcon and MinimizeIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = MinimizeIcon and MinimizeIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.42,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(16, 16),
                ZIndex = 5,
                Parent = MinimizeButton,
            })
            MinimizeButton.MouseEnter:Connect(function()
                Library:PlayTween(MinimizeButton, "MinimizeButtonHover", Library.HoverTweenInfo, {
                    BackgroundTransparency = 0.78,
                })
                Library:PlayTween(MinimizeStroke, "MinimizeButtonHover", Library.HoverTweenInfo, {
                    Transparency = 0.48,
                })
            end)
            MinimizeButton.MouseLeave:Connect(function()
                Library:PlayTween(MinimizeButton, "MinimizeButtonHover", Library.HoverTweenInfo, {
                    BackgroundTransparency = 1,
                })
                Library:PlayTween(MinimizeStroke, "MinimizeButtonHover", Library.HoverTweenInfo, {
                    Transparency = 0.74,
                })
            end)
        end

        
        BottomBackground = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "SurfaceColor",
            Position = UDim2.new(0, 1, 1, -1),
            Size = UDim2.new(1, -2, 0, BottomBarHeight - 1),
            ZIndex = 3,
            Parent = MainFrame,
        })
        Library:MakeLine(MainFrame, {
            Color = function()
                return Library:GetAccentSurfaceColor(0.2)
            end,
            Position = UDim2.new(0, 0, 1, -BottomBarHeight),
            Size = UDim2.new(1, 0, 0, 1),
            Transparency = Library:GetDesignToken("Opacity.Divider", 0.56),
            ZIndex = 4,
        })

        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, BottomBarHeight),
            ZIndex = 4,
            Parent = MainFrame,
        })

        
        FooterLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(36, 0),
            Size = UDim2.new(1, -72, 1, 0),
            Text = WindowInfo.Footer,
            TextColor3 = "MutedFontColor",
            TextSize = 12,
            TextTransparency = 0.2,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
            Parent = BottomBar,
        })

        
        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(24, BottomBarHeight),
                Text = "",
                ZIndex = 6,
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                if Library.ActiveTab then
                    Library.ActiveTab:Resize(Library.ActiveTab.WarningBox and Library.ActiveTab.WarningBox.Visible)
                end
                if Library.Window and Library.Window.RefreshResponsiveLayout then
                    Library.Window:RefreshResponsiveLayout()
                end
            end)

            New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = ResizeIcon and ResizeIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.55,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(12, 12),
                ZIndex = 7,
                Parent = ResizeButton,
            })
        end

        
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "SurfaceColor",
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(1, TopBarHeight + 1),
            ScrollBarImageColor3 = "AccentColor",
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 2,
            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.new(0, InitialLeftWidth - 1, 1, -(TopBarHeight + 2 + BottomBarHeight)),
            Parent = MainFrame,
        })
        New("UIListLayout", {
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = UDim.new(0, Library:GetDesignToken("Shell.NavigationGap", 5)),
            Parent = Tabs,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, Library:GetDesignToken("Shell.NavigationPadding", 7)),
            PaddingLeft = UDim.new(0, Library:GetDesignToken("Shell.NavigationInset", 0)),
            PaddingRight = UDim.new(0, Library:GetDesignToken("Shell.NavigationInset", 0)),
            PaddingTop = UDim.new(0, Library:GetDesignToken("Shell.NavigationPadding", 7)),
            Parent = Tabs,
        })
        ConfigureAutoScrollbar(Tabs, 0.72, 0.28)

        
        Container = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = "BackgroundColor",
            ClipsDescendants = true,
            Name = "Container",
            Position = UDim2.new(1, 0, 0, TopBarHeight + 1),
            Size = UDim2.new(1, -InitialLeftWidth - 1, 1, -(TopBarHeight + 2 + BottomBarHeight)),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, Library:GetDesignToken("Shell.ContentPadding", 12)),
            PaddingRight = UDim.new(0, Library:GetDesignToken("Shell.ContentPadding", 12)),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })

        Library.WindowContainer = Container
    end

    
    local VisibilityChanged = New("BindableEvent", {
        Name = "VisibilityChanged",
        Parent = MainFrame,
    })
    local Window = {
        Frame = MainFrame,
        VisibilityChanged = VisibilityChanged,
        LastHideReason = nil,
    }
    local WindowTween
    local WindowAnimationSequence = 0
    local IsNarrowLayout = false
    local IsUltraNarrowLayout = false
    local TabInfoRequested = false
    local ResponsiveLayoutQueued = false
    local ViewportFitQueued = false
    local CompactLauncherHovered = false
    local CompactLauncherSequence = 0
    local CompactLauncherPressPosition
    local CompactLauncherMoved = false
    local CompactLauncherDragThreshold = 8
    local CompactLauncherHoverTweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local CompactLauncherVisibilityTweenInfo = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function SetCompactLauncherIcon(Icon: string | number)
        if not CompactLauncherIcon then
            return
        end

        local IconData = Library:GetCustomIcon(Icon) or Library:GetIcon("maximize-2")
        CompactLauncherIcon.Image = IconData and IconData.Url or ""
        CompactLauncherIcon.ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero
        CompactLauncherIcon.ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero
    end

    local function GetCompactLauncherTitle()
        return WindowInfo.CompactLauncherTitle or WindowInfo.Title
    end

    local function RefreshCompactLauncherTitle()
        if CompactLauncherTitleLabel then
            CompactLauncherTitleLabel.Text = GetCompactLauncherTitle()
        end
    end

    local function ApplyCompactLauncherStyle(Animate: boolean?)
        if not CompactLauncher or not CompactLauncherIcon or not CompactLauncherTitleLabel or not CompactLauncherStroke then
            return
        end

        local BackgroundColor = GetTopBarSurfaceColor(CompactLauncherHovered and 0.11 or 0.055)
        local BackgroundTransparency = CompactLauncherHovered and 0.02 or 0.08
        local IconTransparency = CompactLauncherHovered and 0.02 or 0.16
        local TitleTransparency = CompactLauncherHovered and 0.02 or 0.16
        local StrokeColor = CompactLauncherHovered and Library.Scheme.AccentColor or Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.1)
        local StrokeTransparency = CompactLauncherHovered and 0.2 or 0.38

        if Animate then
            Library:PlayTween(CompactLauncher, "CompactLauncherSurface", CompactLauncherHoverTweenInfo, {
                BackgroundColor3 = BackgroundColor,
                BackgroundTransparency = BackgroundTransparency,
            })
            Library:PlayTween(CompactLauncherIcon, "CompactLauncherIcon", CompactLauncherHoverTweenInfo, {
                ImageColor3 = Library.Scheme.FontColor,
                ImageTransparency = IconTransparency,
            })
            Library:PlayTween(CompactLauncherTitleLabel, "CompactLauncherTitle", CompactLauncherHoverTweenInfo, {
                TextTransparency = TitleTransparency,
            })
            Library:PlayTween(CompactLauncherStroke, "CompactLauncherStroke", CompactLauncherHoverTweenInfo, {
                Color = StrokeColor,
                Transparency = StrokeTransparency,
            })
            return
        end

        Library:CancelTween(CompactLauncher, "CompactLauncherSurface")
        Library:CancelTween(CompactLauncherIcon, "CompactLauncherIcon")
        Library:CancelTween(CompactLauncherTitleLabel, "CompactLauncherTitle")
        Library:CancelTween(CompactLauncherStroke, "CompactLauncherStroke")
        CompactLauncher.BackgroundColor3 = BackgroundColor
        CompactLauncher.BackgroundTransparency = BackgroundTransparency
        CompactLauncherIcon.ImageColor3 = Library.Scheme.FontColor
        CompactLauncherIcon.ImageTransparency = IconTransparency
        CompactLauncherTitleLabel.TextTransparency = TitleTransparency
        CompactLauncherStroke.Color = StrokeColor
        CompactLauncherStroke.Transparency = StrokeTransparency
    end

    local function BindCoreSurface(Instance, Property, Token)
        if not Instance or not Instance.Parent then
            return
        end

        local Properties = Library.Registry[Instance] or {}
        Properties[Property] = Token
        Library.Registry[Instance] = Properties

        local Value = Library.Scheme[Token]
        if Value ~= nil and Instance[Property] ~= Value then
            Library:CancelTween(Instance, "ThemeSurface")
            Instance[Property] = Value
        end
    end

    function Window:RefreshTheme()
        BindCoreSurface(MainFrame, "BackgroundColor3", "BackgroundColor")
        BindCoreSurface(TopBar, "BackgroundColor3", "TopBarColor")
        BindCoreSurface(TitleHolder, "BackgroundColor3", "TopBarColor")
        BindCoreSurface(Tabs, "BackgroundColor3", "SurfaceColor")
        BindCoreSurface(Container, "BackgroundColor3", "BackgroundColor")
        BindCoreSurface(BottomBackground, "BackgroundColor3", "SurfaceColor")
        ApplyCompactLauncherStyle(false)
    end

    if WindowInfo.ShowCompactLauncher then
        CompactLauncher = New("TextButton", {
            Active = true,
            AnchorPoint = WindowInfo.CompactLauncherAnchorPoint,
            AutoButtonColor = false,
            BackgroundColor3 = function()
                return GetTopBarSurfaceColor(CompactLauncherHovered and 0.11 or 0.055)
            end,
            BackgroundTransparency = 1,
            Position = WindowInfo.CompactLauncherPosition,
            Size = UDim2.fromOffset(WindowInfo.CompactLauncherWidth, WindowInfo.CompactLauncherSize),
            Text = "",
            Visible = false,
            ZIndex = 20,
            Parent = ScreenGui,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library:GetDesignToken("Radius.Card", 4)),
                Parent = CompactLauncher,
            })
        )
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = CompactLauncher,
            })
        )
        CompactLauncherMotionScale = New("UIScale", {
            Scale = 0.975,
            Parent = CompactLauncher,
        })
        CompactLauncherStroke = New("UIStroke", {
            Color = function()
                return CompactLauncherHovered and Library.Scheme.AccentColor or Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.1)
            end,
            Transparency = 1,
            Parent = CompactLauncher,
        })
        Library:AddSoftShadow(CompactLauncher, 14, 0.46, UDim2.fromOffset(0, 3))
        CompactLauncherIcon = New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = "FontColor",
            ImageTransparency = 1,
            Position = UDim2.fromOffset(11, WindowInfo.CompactLauncherSize / 2),
            Size = UDim2.fromOffset(16, 16),
            ZIndex = 21,
            Parent = CompactLauncher,
        })
        CompactLauncherTitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(37, 0),
            Size = UDim2.new(1, -47, 1, 0),
            Text = GetCompactLauncherTitle(),
            TextSize = 14,
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 21,
            Parent = CompactLauncher,
        })
        SetCompactLauncherIcon(WindowInfo.CompactLauncherIcon)
        Library:MakeDraggable(CompactLauncher, CompactLauncher, true, false, function()
            return WindowInfo.CompactLauncherDraggable
        end)
        Library:GiveSignal(CompactLauncher.MouseEnter:Connect(function()
            CompactLauncherHovered = true
            if CompactLauncher.Visible then
                ApplyCompactLauncherStyle(true)
            end
        end))
        Library:GiveSignal(CompactLauncher.MouseLeave:Connect(function()
            CompactLauncherHovered = false
            if CompactLauncher.Visible then
                ApplyCompactLauncherStyle(true)
            end
        end))
        Library:GiveSignal(CompactLauncher.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or not CompactLauncher.Visible then
                return
            end

            CompactLauncherPressPosition = Input.Position
            CompactLauncherMoved = false
        end))
        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if WindowInfo.CompactLauncherDraggable and CompactLauncherPressPosition and IsHoverInput(Input) and (Input.Position - CompactLauncherPressPosition).Magnitude > CompactLauncherDragThreshold then
                CompactLauncherMoved = true
            end
        end))
        Library:GiveSignal(UserInputService.InputEnded:Connect(function(Input: InputObject)
            if IsMouseInput(Input) then
                CompactLauncherPressPosition = nil
            end
        end))
        Library:GiveSignal(CompactLauncher.Activated:Connect(function()
            if CompactLauncherMoved or not CompactLauncher.Visible or Library.Toggled then
                return
            end

            Window:Toggle(true, "Launcher")
        end))
        task.defer(function()
            if CompactLauncher and CompactLauncher.Parent then
                ClampGuiToViewport(CompactLauncher, 8)
            end
        end)
    end

    function Window:RefreshCompactLauncher(Animate: boolean?)
        if not CompactLauncher then
            return
        end

        CompactLauncherSequence += 1
        local Sequence = CompactLauncherSequence
        local ShouldShow = WindowInfo.ShowCompactLauncher and not Library.Toggled and Window.LastHideReason ~= "Keybind"

        if ShouldShow then
            if not CompactLauncher.Visible then
                CompactLauncher.Visible = true
                CompactLauncher.BackgroundTransparency = 1
                CompactLauncherIcon.ImageTransparency = 1
                CompactLauncherTitleLabel.TextTransparency = 1
                CompactLauncherStroke.Transparency = 1
                CompactLauncherMotionScale.Scale = 0.965
            end
            ApplyCompactLauncherStyle(Animate == true)
            if Animate then
                Library:PlayTween(CompactLauncherMotionScale, "CompactLauncherVisibility", CompactLauncherVisibilityTweenInfo, {
                    Scale = 1,
                })
            else
                CompactLauncherMotionScale.Scale = 1
            end
            return
        end

        if not CompactLauncher.Visible then
            return
        end

        if Animate ~= true then
            CompactLauncher.Visible = false
            CompactLauncher.BackgroundTransparency = 1
            CompactLauncherIcon.ImageTransparency = 1
            CompactLauncherTitleLabel.TextTransparency = 1
            CompactLauncherStroke.Transparency = 1
            CompactLauncherMotionScale.Scale = 0.975
            return
        end

        Library:PlayTween(CompactLauncher, "CompactLauncherSurface", CompactLauncherVisibilityTweenInfo, {
            BackgroundTransparency = 1,
        })
        local IconTween = Library:PlayTween(CompactLauncherIcon, "CompactLauncherIcon", CompactLauncherVisibilityTweenInfo, {
            ImageTransparency = 1,
        })
        Library:PlayTween(CompactLauncherTitleLabel, "CompactLauncherTitle", CompactLauncherVisibilityTweenInfo, {
            TextTransparency = 1,
        })
        Library:PlayTween(CompactLauncherStroke, "CompactLauncherStroke", CompactLauncherVisibilityTweenInfo, {
            Transparency = 1,
        })
        Library:PlayTween(CompactLauncherMotionScale, "CompactLauncherVisibility", CompactLauncherVisibilityTweenInfo, {
            Scale = 0.975,
        })
        if not IconTween then
            CompactLauncher.Visible = false
            return
        end

        IconTween.Completed:Once(function(State)
            if State == Enum.PlaybackState.Completed and Sequence == CompactLauncherSequence and not ShouldShow and CompactLauncher.Parent then
                CompactLauncher.Visible = false
            end
        end)
    end

    function Window:SetCompactLauncherIcon(Icon: string | number)
        assert(typeof(Icon) == "string" or typeof(Icon) == "number", "Compact launcher icon must be a Lucide name, asset id, or asset URL.")
        WindowInfo.CompactLauncherIcon = Icon
        SetCompactLauncherIcon(Icon)
    end

    function Window:SetCompactLauncherPosition(Position: UDim2)
        assert(typeof(Position) == "UDim2", "UDim2 expected.")
        WindowInfo.CompactLauncherPosition = Position
        if CompactLauncher then
            CompactLauncher.Position = Position
            ClampGuiToViewport(CompactLauncher, 8)
        end
    end

    function Window:SetCompactLauncherTitle(Title: string?)
        assert(Title == nil or typeof(Title) == "string", "Compact launcher title must be a string or nil.")
        WindowInfo.CompactLauncherTitle = Title
        RefreshCompactLauncherTitle()
    end

    function Window:SetCompactLauncherWidth(Width: number)
        assert(typeof(Width) == "number", "Compact launcher width must be a number.")
        WindowInfo.CompactLauncherWidth = math.clamp(
            math.floor(Width),
            math.max(128, WindowInfo.CompactLauncherSize * 3),
            280
        )
        if CompactLauncher then
            CompactLauncher.Size = UDim2.fromOffset(WindowInfo.CompactLauncherWidth, WindowInfo.CompactLauncherSize)
            ClampGuiToViewport(CompactLauncher, 8)
        end
    end

    function Window:SetCompactLauncherDraggable(Draggable: boolean)
        WindowInfo.CompactLauncherDraggable = Draggable == true
    end

    Window.CompactLauncher = CompactLauncher

    local function GetContentWidth()
        local Scale = math.max(Library.DPIScale or 1, 0.01)
        local Width = Container.AbsoluteSize.X / Scale

        if Width <= 0 then
            Width = MainFrame.Size.X.Offset - Window:GetSidebarWidth() - 1
        end

        return math.max(0, Width)
    end

    function Window:IsSingleColumnLayout()
        return IsNarrowLayout
    end

    function Window:SetResponsiveLayoutEnabled(Enabled: boolean)
        WindowInfo.ResponsiveLayout = Enabled == true
        Window:RefreshResponsiveLayout()
    end

    function Window:RefreshResponsiveLayout()
        local ContentWidth = GetContentWidth()
        local PreviousNarrowLayout = IsNarrowLayout
        IsNarrowLayout = WindowInfo.ResponsiveLayout == true and ContentWidth <= WindowInfo.SingleColumnWidth
        IsUltraNarrowLayout = ContentWidth <= WindowInfo.HideSearchAtWidth

        local ShowSearch = WindowInfo.DisableSearch ~= true and not IsUltraNarrowLayout
        local ShowTabInfo = TabInfoRequested and not IsUltraNarrowLayout
        local TabInfoSize = UDim2.fromScale(ShowSearch and 0.5 or 1, 1)
        local SearchSize = UDim2.fromScale(ShowTabInfo and 0.5 or 1, 1)

        if SearchBox.Visible ~= ShowSearch then
            SearchBox.Visible = ShowSearch
        end
        if CurrentTabInfo.Visible ~= ShowTabInfo then
            CurrentTabInfo.Visible = ShowTabInfo
        end
        if CurrentTabInfo.Size ~= TabInfoSize then
            CurrentTabInfo.Size = TabInfoSize
        end

        if IsDefaultSearchbarSize and SearchBox.Size ~= SearchSize then
            SearchBox.Size = SearchSize
        end

        if PreviousNarrowLayout ~= IsNarrowLayout then
            for _, Tab in Library.Tabs do
                if not Tab.IsKeyTab and Tab.RefreshSides then
                    Tab:RefreshSides()
                end
            end
        end
    end

    local function QueueResponsiveLayout()
        if ResponsiveLayoutQueued then
            return
        end

        ResponsiveLayoutQueued = true
        task.defer(function()
            ResponsiveLayoutQueued = false

            if not Library.Unloaded and MainFrame.Parent then
                Window:RefreshResponsiveLayout()
            end
        end)
    end

    local function SetUICorner(UICorner, Corner, HalfCurrent, HalfValue, Value)
        local Current = UICorner[Corner]
        if Current.Offset == 0 and Current.Scale == 0 then
            return
        end

        UICorner[Corner] = Current.Offset == HalfCurrent and HalfValue or Value
    end

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

        WindowTitle.Text = title
        WindowInfo.Title = title
        if WindowInfo.CompactLauncherTitle == nil then
            RefreshCompactLauncherTitle()
        end
    end

    function Window:SetBackgroundImage(Image: string)
        local ValidIcon = false

        if typeof(Image) == "string" then
            local BackgroundIcon = Library:GetCustomIcon(Image)

            if BackgroundIcon then
                ValidIcon = true

                BackgroundImage.Image = BackgroundIcon.Url
                BackgroundImage.ImageRectOffset = BackgroundIcon.ImageRectOffset
                BackgroundImage.ImageRectSize = BackgroundIcon.ImageRectSize
                BackgroundImage.Visible = true
            elseif Image:match("http://") or Image:match("https://") then
                local RawFileName = Image:match("(.+)%..+$")
                local _, Domain = Image:match("^(https?://)([^/]+)"); 

                if RawFileName and Domain then
                    local Extention = string.sub(Image, #RawFileName + 1, #Image)
                    local FileNamePos = RawFileName:gsub("\\", "/"):find("/[^/]*$")
                    local FileName = FileNamePos and Image:sub(FileNamePos + 1) or nil

                    if FileName then
                        ValidIcon = true

                        local AssetName = Domain .. FileName
                        if #AssetName > 255 then
                            local NewLength = 255 - #Domain - #Extention
                            if NewLength < 0 then
                                AssetName = Domain .. Extention
                            else
                                AssetName = Domain .. string.sub(FileName:sub(1, #FileName - #Extention), 1, NewLength) .. Extention
                            end
                        end

                        if CustomImageManagerAssets[FileName] == nil then
                            CustomImageManager.AddAsset(FileName, 0, Image)
                        else
                            CustomImageManager.DownloadAsset(FileName, true)
                        end

                        BackgroundImage.Image = CustomImageManager.GetAsset(FileName)
                        BackgroundImage.ImageRectOffset = Vector2.zero
                        BackgroundImage.ImageRectSize = Vector2.zero
                        BackgroundImage.Visible = true
                    end
                end
            end
        end

        if not ValidIcon then
            BackgroundImage.Image = ""
            BackgroundImage.ImageRectOffset = Vector2.zero
            BackgroundImage.ImageRectSize = Vector2.zero
            BackgroundImage.Visible = false
        end
    
        WindowInfo.BackgroundImage = Image
    end

    function Window:SetFooter(Footer: string)
        assert(typeof(Footer) == "string", "Expected string for footer got: " .. typeof(Footer))

        FooterLabel.Text = Footer
        WindowInfo.Footer = Footer
    end

    function Window:SetAlwaysOnTop(Enabled: boolean)
        WindowInfo.AlwaysOnTop = Enabled == true
        SetAlwaysOnTop(Library.ScreenGui, WindowInfo.AlwaysOnTop)
    end

    local CornerRadiusRetry = false

    function Window:SetCornerRadius(Radius: number)
        assert(typeof(Radius) == "number", "Expected number for Radius got: " .. typeof(Radius))
        Radius = math.clamp(Radius, 0, 20)

        local Applied, Reason = pcall(function()
            Window:ApplyCornerRadius(Radius)
        end)

        if Applied then
            CornerRadiusRetry = false
            return
        end

        if CornerRadiusRetry then
            warn("MonHub: unable to apply corner radius (" .. tostring(Reason) .. ")")
            CornerRadiusRetry = false
            return
        end

        CornerRadiusRetry = true
        task.defer(function()
            if not Library.Unloaded then
                Window:SetCornerRadius(Radius)
            end
        end)
    end

    function Window:ApplyCornerRadius(Radius: number)
        local RadiusHalf = UDim.new(0, math.floor(Radius / 2))
        local RadiusUDim = UDim.new(0, Radius)
        local HalfCurrent = Library.CornerRadius / 2

        for Index = #Library.Corners, 1, -1 do
            local UICorner = Library.Corners[Index]
            if not UICorner or not UICorner.Parent then
                table.remove(Library.Corners, Index)
            elseif math.abs(UICorner.CornerRadius.Offset - HalfCurrent) <= 1 then
                UICorner.CornerRadius = RadiusHalf
            else
                UICorner.CornerRadius = RadiusUDim
            end
        end

        for Index = #Library.SpecificCorners, 1, -1 do
            local UICorner = Library.SpecificCorners[Index]
            if not UICorner or not UICorner.Parent then
                table.remove(Library.SpecificCorners, Index)
            else
                SetUICorner(UICorner, "TopRightRadius", HalfCurrent, RadiusHalf, RadiusUDim)
                SetUICorner(UICorner, "TopLeftRadius", HalfCurrent, RadiusHalf, RadiusUDim)
                SetUICorner(UICorner, "BottomRightRadius", HalfCurrent, RadiusHalf, RadiusUDim)
                SetUICorner(UICorner, "BottomLeftRadius", HalfCurrent, RadiusHalf, RadiusUDim)
            end
        end

        Library.CornerRadius = Radius
        WindowInfo.CornerRadius = Radius

        if ResizeButton then
            ResizeButton.Position = UDim2.new(1, -4, 0.5, 0)
        end
        BottomBackground.Position = UDim2.new(0, 1, 1, -1)
        BottomBackground.Size = UDim2.new(1, -2, 0, BottomBarHeight - 1)

        for _, Tab in Library.Tabs do
            if Tab.IsKeyTab then
                continue
            end

            for _, Tabbox in Tab.Tabboxes do
                Tabbox:UpdateCorners()
            end
        end
    end

    function Window:SetAnimations(Animations: { [string]: boolean }?, TabTransitionTime: number?, TabSwipeOffset: number?, TabSwipeFrom: ("left" | "right" | "top" | "bottom" | string)?)
        if typeof(Animations) == "table" then
            WindowInfo.Animations = Animations
            Library.Animations = Animations
        end

        if typeof(TabTransitionTime) == "number" then
            local TweenInfo = TweenInfo.new(
                math.max(0, TabTransitionTime or Library.Design.Motion.TabEnter[1]),
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            )

            WindowInfo.TabTransitionInfo = TweenInfo
            Library.TabTransitionInfo = TweenInfo
        end

        if typeof(TabSwipeOffset) == "number" then
            TabSwipeOffset = math.max(1, TabSwipeOffset)

            WindowInfo.TabSwipeOffset = TabSwipeOffset
            Library.TabSwipeOffset = TabSwipeOffset
        end

        if typeof(TabSwipeFrom) == "string" then
            TabSwipeFrom = string.lower(TabSwipeFrom)

            WindowInfo.TabSwipeFrom = TabSwipeFrom
            Library.TabSwipeFrom = TabSwipeFrom
        end
    end

    local function ApplyCompact()
        local Compact = Window:GetSidebarWidth() == WindowInfo.SidebarCompactWidth
        if WindowInfo.DisableCompactingSnap then
            Compact = Window:GetSidebarWidth() <= WindowInfo.CompactWidthActivation
        end
        IsCompact = Compact

        if LastCompactState == IsCompact then
            return
        end
        LastCompactState = IsCompact

        WindowTitle.Visible = not IsCompact
        WindowIcon.Visible = WindowInfo.Icon and true or IsCompact
        WindowIcon.AnchorPoint = Vector2.new(IsCompact and 0.5 or 0, 0.5)
        WindowIcon.Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 14, 0.5, 0)
        WindowIcon.Size = UDim2.fromOffset(HeaderIconSize, HeaderIconSize)

        for _, Button in Library.TabButtons do
            Button.Label.Visible = not IsCompact
            if not Button.Icon then
                continue
            end

            Button.Icon.AnchorPoint = Vector2.new(IsCompact and 0.5 or 0, 0.5)
            Button.Icon.Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, NavigationIconX, 0.5, 0)
            Button.Icon.Size = UDim2.fromOffset(NavigationIconSize, NavigationIconSize)
        end
    end

    function Window:IsSidebarCompacted()
        return IsCompact
    end

    function Window:SetCompact(State)
        Window:SetSidebarWidth(State and WindowInfo.SidebarCompactWidth or LastExpandedWidth)
    end

    function Window:GetSidebarWidth()
        return Tabs.Size.X.Offset + 1
    end

    function Window:SetSidebarWidth(Width)
        local MaxSidebarWidth = math.max(48, MainFrame.Size.X.Offset - WindowInfo.MinContainerWidth - 1)
        Width = math.floor(math.clamp(Width, 48, MaxSidebarWidth) + 0.5)

        if Width == Tabs.Size.X.Offset + 1 then
            return
        end

        DividerLine.Position = UDim2.fromOffset(Width, 0)

        TitleHolder.Size = UDim2.new(0, Width, 1, 0)
        RightWrapper.Size = UDim2.new(1, -Width - HeaderControlWidth - 8, 1, -16)
        Tabs.Size = UDim2.new(0, Width - 1, 1, -(TopBarHeight + 2 + BottomBarHeight))
        Container.Size = UDim2.new(1, -Width - 1, 1, -(TopBarHeight + 2 + BottomBarHeight))

        if WindowInfo.EnableCompacting then
            ApplyCompact()
        end
        if not IsCompact then
            LastExpandedWidth = Width
        end

        QueueResponsiveLayout()
    end

    function Window:FitToViewport(PostLayoutPass)
        local Camera = workspace.CurrentCamera
        if not Camera or not MainFrame.Parent then
            return
        end

        local Margin = 8
        local Scale = math.max(Library.DPIScale or 1, 0.01)
        local ViewportSize = GetViewportSize()
        local OverflowX = math.max(0, MainFrame.AbsoluteSize.X - (ViewportSize.X - Margin * 2))
        local OverflowY = math.max(0, MainFrame.AbsoluteSize.Y - (ViewportSize.Y - Margin * 2))
        local SizeChanged = false
        if OverflowX > 0 or OverflowY > 0 then
            local MinWidth = math.min(Library.MinSize.X, math.max(240, (ViewportSize.X - Margin * 2) / Scale))
            local MinHeight = math.min(Library.MinSize.Y, math.max(220, (ViewportSize.Y - Margin * 2) / Scale))

            local NewSize = UDim2.new(
                MainFrame.Size.X.Scale,
                math.max(MinWidth, MainFrame.Size.X.Offset - OverflowX / Scale),
                MainFrame.Size.Y.Scale,
                math.max(MinHeight, MainFrame.Size.Y.Offset - OverflowY / Scale)
            )
            SizeChanged = NewSize ~= MainFrame.Size
            MainFrame.Size = NewSize
        end

        Window:SetSidebarWidth(math.min(Window:GetSidebarWidth(), MainFrame.Size.X.Offset - WindowInfo.MinContainerWidth - 1))
        ClampGuiToViewport(MainFrame, Margin)

        Window:RefreshResponsiveLayout()

        if Library.ActiveTab then
            Library.ActiveTab:Resize(Library.ActiveTab.WarningBox and Library.ActiveTab.WarningBox.Visible)
        end

        if not PostLayoutPass then
            task.defer(function()
                RunService.Heartbeat:Wait()
                if Library.Unloaded or not MainFrame.Parent then
                    return
                end

                Window:FitToViewport(true)
            end)
        elseif SizeChanged then
            task.defer(function()
                RunService.Heartbeat:Wait()
                if Library.Unloaded or not MainFrame.Parent then
                    return
                end

                ClampGuiToViewport(MainFrame, Margin)
                Window:RefreshResponsiveLayout()
                if Library.ActiveTab then
                    Library.ActiveTab:Resize(Library.ActiveTab.WarningBox and Library.ActiveTab.WarningBox.Visible)
                end
            end)
        end
    end

    function Window:QueueFitToViewport()
        if ViewportFitQueued then
            return
        end

        ViewportFitQueued = true
        task.defer(function()
            ViewportFitQueued = false

            if not Library.Unloaded and MainFrame.Parent then
                Window:FitToViewport()
            end
        end)
    end

    function Window:ShowTabInfo(Name, Description)
        CurrentTabLabel.Text = Name
        CurrentTabDescription.Text = Description
        TabInfoRequested = true
        Window:RefreshResponsiveLayout()
    end

    function Window:HideTabInfo()
        TabInfoRequested = false
        Window:RefreshResponsiveLayout()
    end
    local TabSequence = 0

    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil
        local Order = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
            Order = Info.Order
        else
            Name = select(1, ...)
            Icon = select(2, ...)
            Description = select(3, ...)
            Order = select(4, ...)
        end

        TabSequence += 1
        Order = tonumber(Order) or TabSequence

        local TabButton: TextButton
        local TabLabel
        local TabIcon
        local TabContainer
        local TabCanvas
        local TabLeft
        local TabRight
        local ColumnGap = Library:GetDesignToken("Spacing.Section", 10)
        local ColumnOffset = ColumnGap / 2

        Icon = Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = function()
                    return Library:GetAccentSurfaceColor(0.12)
                end,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, Library:GetDesignToken("Shell.NavigationHeight", 38)),
                Text = "",
                LayoutOrder = Order,
                Parent = Tabs,
            })
            New("UICorner", {
                CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Card", 4)) end,
                Parent = TabButton,
            })
            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 1,
                Name = "Indicator",
                Visible = function() return Library:GetDesignToken("Effects.NavigationIndicator", false) end,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(2, 0),
                Parent = TabButton,
            })
            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(NavigationLabelX, 0),
                Size = UDim2.new(1, -(NavigationLabelX + 8), 1, 0),
                Text = Name,
                TextSize = Library:GetDesignToken("Typography.Navigation", 14),
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(IsCompact and 0.5 or 0, 0.5),
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, NavigationIconX, 0.5, 0),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(NavigationIconSize, NavigationIconSize),
                    Parent = TabButton,
                })
            end

            table.insert(Library.TabButtons, {
                Button = TabButton,
                Label = TabLabel,
                Icon = TabIcon,
            })

            
            TabCanvas = New("CanvasGroup", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                GroupTransparency = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                Visible = true,
                Parent = TabCanvas,
            })

            TabLeft = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
                ScrollBarImageColor3 = "AccentColor",
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(0.5, -ColumnOffset, 1, 0),
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                Parent = TabLeft,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, Library:GetDesignToken("Spacing.Large", 12)),
                PaddingLeft = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                PaddingRight = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                PaddingTop = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                Parent = TabLeft,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabLeft,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabLeft,
                })
            end

            TabRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
                Position = UDim2.fromScale(1, 0),
                ScrollBarImageColor3 = "AccentColor",
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = UDim2.new(0.5, -ColumnOffset, 1, 0),
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                Parent = TabRight,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, Library:GetDesignToken("Spacing.Large", 12)),
                PaddingLeft = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                PaddingRight = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                PaddingTop = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                Parent = TabRight,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabRight,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabRight,
                })
            end

            ConfigureAutoScrollbar(TabLeft)
            ConfigureAutoScrollbar(TabRight)
        end

        
        local WarningBoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            Parent = TabContainer,
        })

        local WarningBox
        local WarningBoxOutline
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningStroke
        local WarningText
        do
            WarningBox = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 0),
                Size = UDim2.new(1, -5, 0, 0),
                Parent = WarningBoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = WarningBox,
                })
            )
            WarningBoxOutline = Library:AddOutline(WarningBox)

            WarningBoxScrollingFrame = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = WarningBox,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4),
                Parent = WarningBoxScrollingFrame,
            })

            WarningTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 14),
                Text = "",
                TextColor3 = "DestructiveColor",
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = WarningBoxScrollingFrame,
            })

            WarningStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = function()
                    local DestructiveColor = Library.Scheme.DestructiveColor or Library.Scheme.RedColor
                    return DestructiveColor:Lerp(Library.Scheme.DarkColor, 0.42)
                end,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningTitle,
            })

            WarningText = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, -4, 0, 0),
                Text = "",
                TextSize = 14,
                TextWrapped = true,
                Parent = WarningBoxScrollingFrame,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            })

            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        local function GetWarningBoxDestructiveColor()
            return Library.Scheme.DestructiveColor or Library.Scheme.RedColor
        end

        local function GetWarningBoxSurfaceColor()
            return Library.Scheme.BackgroundColor:Lerp(GetWarningBoxDestructiveColor(), 0.34)
        end

        local function GetWarningBoxStrokeColor()
            return GetWarningBoxDestructiveColor():Lerp(Library.Scheme.DarkColor, 0.42)
        end

        
        local Tab = {
            Description = Description,
            Order = Order,

            Connections = {},
            Destroyed = false,

            Window = Window,
            Canvas = TabCanvas,
            Sides = {
                TabLeft,
                TabRight,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },

            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},
        }

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.IsNormal) == "boolean" then
                Tab.WarningBox.IsNormal = Info.IsNormal
            end
            if typeof(Info.LockSize) == "boolean" then
                Tab.WarningBox.LockSize = Info.LockSize
            end
            if typeof(Info.Visible) == "boolean" then
                Tab.WarningBox.Visible = Info.Visible
            end
            if typeof(Info.Title) == "string" then
                Tab.WarningBox.Title = Info.Title
            end
            if typeof(Info.Text) == "string" then
                Tab.WarningBox.Text = Info.Text
            end

            WarningBoxHolder.Visible = Tab.WarningBox.Visible
            WarningTitle.Text = Tab.WarningBox.Title
            WarningText.Text = Tab.WarningBox.Text
            Tab:Resize(true)

            WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor
                or GetWarningBoxSurfaceColor()

            WarningBoxOutline.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or GetWarningBoxDestructiveColor()

            WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor
                or GetWarningBoxDestructiveColor()
            WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor
                or GetWarningBoxStrokeColor()

            if not Library.Registry[WarningBox] then
                Library:AddToRegistry(WarningBox, {})
            end
            if not Library.Registry[WarningBoxOutline] then
                Library:AddToRegistry(WarningBoxOutline, {})
            end
            if not Library.Registry[WarningTitle] then
                Library:AddToRegistry(WarningTitle, {})
            end
            if not Library.Registry[WarningStroke] then
                Library:AddToRegistry(WarningStroke, {})
            end

            Library.Registry[WarningBox].BackgroundColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or GetWarningBoxSurfaceColor()
            end

            Library.Registry[WarningBoxOutline].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or GetWarningBoxDestructiveColor()
            end

            Library.Registry[WarningTitle].TextColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or GetWarningBoxDestructiveColor()
            end

            Library.Registry[WarningStroke].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or GetWarningBoxStrokeColor()
            end
        end

        function Tab:RefreshSides()
            if Tab.Destroyed or not TabCanvas.Parent then
                return
            end

            local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
            if Tab.FullWidth then
                local FullPosition = UDim2.fromOffset(0, Offset)
                local FullSize = UDim2.new(1, 0, 1, -Offset)
                if TabLeft.AnchorPoint ~= Vector2.zero then
                    TabLeft.AnchorPoint = Vector2.zero
                end
                if TabLeft.Position ~= FullPosition then
                    TabLeft.Position = FullPosition
                end
                if TabLeft.Size ~= FullSize then
                    TabLeft.Size = FullSize
                end
                if TabRight.Visible then
                    TabRight.Visible = false
                end
                return
            end
            if not TabRight.Visible then
                TabRight.Visible = true
            end
            if IsNarrowLayout then
                local HalfOffset = math.floor(Offset / 2)
                local Gap = 6
                local LeftPosition = UDim2.fromOffset(0, Offset)
                local LeftSize = UDim2.new(1, 0, 0.5, -(HalfOffset + Gap))
                local RightPosition = UDim2.new(0, 0, 0.5, HalfOffset + Gap)
                local RightSize = UDim2.new(1, 0, 0.5, -(HalfOffset + Gap))
                if TabLeft.AnchorPoint ~= Vector2.zero then
                    TabLeft.AnchorPoint = Vector2.zero
                end

                if TabLeft.Position ~= LeftPosition then
                    TabLeft.Position = LeftPosition
                end
                if TabLeft.Size ~= LeftSize then
                    TabLeft.Size = LeftSize
                end
                if TabRight.AnchorPoint ~= Vector2.new(0, 0) then
                    TabRight.AnchorPoint = Vector2.new(0, 0)
                end
                if TabRight.Position ~= RightPosition then
                    TabRight.Position = RightPosition
                end
                if TabRight.Size ~= RightSize then
                    TabRight.Size = RightSize
                end
            else
                local Total = math.floor(TabContainer.AbsoluteSize.X)
                local LeftPosition = UDim2.fromOffset(0, Offset)
                local RightPosition = UDim2.new(1, 0, 0, Offset)
                local LeftSize, RightSize
                if Total > ColumnGap then
                    local LeftWidth = math.floor((Total - ColumnGap) / 2)
                    LeftSize = UDim2.new(0, LeftWidth, 1, -Offset)
                    RightSize = UDim2.new(0, Total - ColumnGap - LeftWidth, 1, -Offset)
                else
                    LeftSize = UDim2.new(0.5, -ColumnOffset, 1, -Offset)
                    RightSize = UDim2.new(0.5, -ColumnOffset, 1, -Offset)
                end

                if TabLeft.AnchorPoint ~= Vector2.zero then
                    TabLeft.AnchorPoint = Vector2.zero
                end
                if TabLeft.Position ~= LeftPosition then
                    TabLeft.Position = LeftPosition
                end
                if TabLeft.Size ~= LeftSize then
                    TabLeft.Size = LeftSize
                end
                if TabRight.AnchorPoint ~= Vector2.new(1, 0) then
                    TabRight.AnchorPoint = Vector2.new(1, 0)
                end
                if TabRight.Position ~= RightPosition then
                    TabRight.Position = RightPosition
                end
                if TabRight.Size ~= RightSize then
                    TabRight.Size = RightSize
                end
            end
        end

        table.insert(Tab.Connections, TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if Library.ActiveTab ~= nil and Library.ActiveTab ~= Tab then
                return
            end
            Tab:RefreshSides()
        end))

        function Tab:Resize(ResizeWarningBox: boolean?)
            if Tab.Destroyed or not TabContainer.Parent then
                return
            end

            if ResizeWarningBox then
                local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                local _, YText = Library:GetTextBounds(
                    WarningText.Text,
                    Library.Scheme.Font,
                    WarningText.TextSize,
                    WarningText.AbsoluteSize.X
                )

                local YBox = 24 + YText
                if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                    YBox = MaximumSize
                else
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                end

                WarningText.Size = UDim2.new(1, -4, 0, YText)
                WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
            end

            Tab:RefreshSides()
        end

        local function AddTabbox(self, Info)
            local ParentObj = self

            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = if ParentObj.Type == "Groupbox" then ParentObj.Container else (Info.Side == 1 and TabLeft or TabRight),
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local TabboxHolder
            local TabboxButtons

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "SurfaceColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = TabboxHolder,
                    })
                )
                Library:AddOutline(TabboxHolder)

                TabboxButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = TabboxHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Parent = TabboxButtons,
                })
            end

            local function ResizeTabboxButtons()
                if not TabboxButtons then
                    return
                end

                local Buttons = {}
                for _, Child in TabboxButtons:GetChildren() do
                    if Child:IsA("GuiObject") and Child.Visible then
                        table.insert(Buttons, Child)
                    end
                end

                local Count = #Buttons
                if Count == 0 then
                    return
                end

                local Total = math.floor(TabboxButtons.AbsoluteSize.X)
                if Total <= 0 then
                    for _, Child in Buttons do
                        Child.Size = UDim2.new(1 / Count, 0, 1, 0)
                    end
                    return
                end

                local Share = math.max(1, math.floor(Total / Count))
                for Index, Child in Buttons do
                    local Width = Index == Count and (Total - Share * (Count - 1)) or Share
                    Child.Size = UDim2.new(0, Width, 1, 0)
                end
            end

            if TabboxButtons then
                TabboxButtons:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResizeTabboxButtons)
                TabboxButtons.ChildAdded:Connect(function()
                    task.defer(ResizeTabboxButtons)
                end)
            end

            local TotalTabs = 0
            local FirstTab
            local LastTab

            local Tabbox = {
                Connections = {},
                Destroyed = false,

                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = TabboxHolder,
                Tabs = {}
            }

            function Tabbox:UpdateCorners()
                for _, Tab in Tabbox.Tabs do
                    Tab:UpdateCorners()
                end
            end

            function Tabbox:AddTab(Name, IconName)
                TotalTabs = TotalTabs + 1
                local TabIndex = TotalTabs

                LastTab = TabIndex
                if not FirstTab then
                    FirstTab = TabIndex
                end

                local IsNameEmpty = Name == nil or Trim(tostring(Name)) == ""
                local TabStoringIndex = IsNameEmpty and tostring(TabIndex) or Name

                local Button = New("TextButton", {
                    BackgroundColor3 = function()
                        return Library:GetAccentSurfaceColor(0.14)
                    end,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 34),
                    Text = "",
                    Parent = TabboxButtons,
                })

                local ButtonCorner = New("UICorner", {
                    TopLeftRadius = UDim.new(0, WindowInfo.CornerRadius),
                    TopRightRadius = UDim.new(0, WindowInfo.CornerRadius),
                    BottomRightRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, 0),
                    Parent = Button,
                }); table.insert(Library.SpecificCorners, ButtonCorner)

                local ButtonContent = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(0, 16),
                    Parent = Button,
                })

                local function CenterTabboxContent()
                    ButtonContent.Position = UDim2.new(
                        0,
                        Library:CenterOffset(Button.AbsoluteSize.X, ButtonContent.AbsoluteSize.X),
                        0.5,
                        0
                    )
                end

                ButtonContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(CenterTabboxContent)
                Button:GetPropertyChangedSignal("AbsoluteSize"):Connect(CenterTabboxContent)
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = ButtonContent,
                })

                local ButtonIcon                
                local BoxIcon = Library:GetCustomIcon(IconName)
                if BoxIcon then
                    ButtonIcon = New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = IsNameEmpty and UDim2.fromOffset(16, 16) or UDim2.fromOffset(18, 18),
                        Parent = ButtonContent,
                    })
                end

                local ButtonLabel
                if not IsNameEmpty then
                    ButtonLabel = New("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(0, 16),
                        Text = Name,
                        TextSize = 15,
                        TextTransparency = 0.5,
                        Parent = ButtonContent,
                    })
                end

                local Line = Library:MakeLine(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Color = "OutlineColor",
                    Position = UDim2.new(0, 0, 1, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                    Transparency = 0.68,
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = TabboxHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = Container,
                })

                local Tab = {
                    Connections = {},
                    Destroyed = false,

                    ButtonHolder = Button,
                    Container = Container,
                    ButtonCorner = ButtonCorner,

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                local function ApplyTabboxVisual(Selected: boolean, Animate: boolean)
                    local BackgroundTransparency = Selected and 0 or 1
                    local TextTransparency = Selected and 0.04 or 0.5

                    if Animate then
                        Library:PlayTween(Button, "TabboxSelection", Library.HoverTweenInfo, {
                            BackgroundTransparency = BackgroundTransparency,
                        })
                        if ButtonLabel then
                            Library:PlayTween(ButtonLabel, "TabboxSelection", Library.HoverTweenInfo, {
                                TextTransparency = TextTransparency,
                            })
                        end
                        if ButtonIcon then
                            Library:PlayTween(ButtonIcon, "TabboxSelection", Library.HoverTweenInfo, {
                                ImageTransparency = TextTransparency,
                            })
                        end
                    else
                        Library:CancelTween(Button, "TabboxSelection")
                        Button.BackgroundTransparency = BackgroundTransparency
                        if ButtonLabel then
                            Library:CancelTween(ButtonLabel, "TabboxSelection")
                            ButtonLabel.TextTransparency = TextTransparency
                        end
                        if ButtonIcon then
                            Library:CancelTween(ButtonIcon, "TabboxSelection")
                            ButtonIcon.ImageTransparency = TextTransparency
                        end
                    end

                    Line.Visible = not Selected
                end

                function Tab:Show()
                    local Animate = Tabbox.ActiveTab ~= nil
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end

                    ApplyTabboxVisual(true, Animate)

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()
                end

                function Tab:Hide()
                    ApplyTabboxVisual(false, true)
                    Container.Visible = false

                    Tabbox.ActiveTab = nil
                end

                function Tab:Resize()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end

                    TabboxHolder.Size = UDim2.new(1, 0, 0, (List.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                    if ParentObj.Type == "Groupbox" then
                        ParentObj:Resize()
                    end
                end

                function Tab:UpdateCorners()
                    local Radius = WindowInfo.CornerRadius

                    ButtonCorner.TopLeftRadius = UDim.new(0, TabIndex == FirstTab and Radius or 0)
                    ButtonCorner.TopRightRadius = UDim.new(0, TabIndex == LastTab and Radius or 0)
                end

                function Tab:Destroy()
                    if Tab.Destroyed then
                        return
                    end

                    Tab.Destroyed = true

                    if Tab.Connections then
                        for _, Connection in Tab.Connections do
                            Connection:Disconnect()
                        end
                        table.clear(Tab.Connections)
                    end

                    for _, Element in table.clone(Tab.Elements) do
                        if Element.Destroy then
                            Element:Destroy()
                        end
                    end
                    table.clear(Tab.Elements)

                    for _, SubDepbox in table.clone(Tab.DependencyBoxes) do
                        if SubDepbox.Destroy then
                            SubDepbox:Destroy()
                        end
                    end
                    table.clear(Tab.DependencyBoxes)

                    if Container then
                        Container:Destroy()
                    end

                    if Button then
                        Button:Destroy()
                    end
                end

                
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[TabStoringIndex] = Tab
                Tabbox:UpdateCorners()

                return Tab, TabStoringIndex
            end

            function Tabbox:Destroy()
                if Tabbox.Destroyed then
                    return
                end

                Tabbox.Destroyed = true

                if Tabbox.Connections then
                    for _, Connection in Tabbox.Connections do
                        Connection:Disconnect()
                    end
                    table.clear(Tabbox.Connections)
                end

                for _, Tab in table.clone(Tabbox.Tabs) do
                    if Tab.Destroy then
                        Tab:Destroy()
                    end
                end
                table.clear(Tabbox.Tabs)

                if TabboxHolder then
                    TabboxHolder:Destroy()
                end

                if BoxHolder then
                    BoxHolder:Destroy()
                end
            end

            if Info.Name then
                Tab.Tabboxes[Info.Name] = Tabbox
            else
                table.insert(Tab.Tabboxes, Tabbox)
            end

            return Tabbox
        end

        Tab.AddTabbox = AddTabbox

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Side = 2, Name = Name })
        end

        function Tab:AddGroupbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = (Tab.FullWidth or Info.Side == 1) and TabLeft or TabRight,
            })

            local GroupboxHolder
            local GroupboxLabel

            local GroupboxContainer
            local GroupboxList

            local GroupboxCollapseArrow
            local GroupboxLine
            local GroupboxHeader
            local GroupboxHeaderHeight = Library:GetDesignToken("Size.GroupHeader", 35)
            local GroupboxTopPadding = Library:GetDesignToken("Spacing.Medium", 8)
            local GroupboxBottomPadding = Library:GetDesignToken("Spacing.Large", 12)
            local GroupboxHorizontalPadding = Library:GetDesignToken("Spacing.Medium", 8)

            do
                GroupboxHolder = New("Frame", {
                    BackgroundColor3 = "SurfaceColor",
                    ClipsDescendants = true,
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = function() return UDim.new(0, Library:GetDesignToken("Radius.Card", math.max(WindowInfo.CornerRadius - 1, 2))) end,
                        Parent = GroupboxHolder,
                    })
                )
                local GroupboxOutline = Library:AddOutline(GroupboxHolder)
                GroupboxOutline.Transparency = Library:GetDesignToken("Stroke.SoftTransparency", 0.46)

                GroupboxHeader = New("Frame", {
                    BackgroundColor3 = "SurfaceColor",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, GroupboxHeaderHeight),
                    Parent = GroupboxHolder,
                })

                GroupboxLine = Library:MakeLine(GroupboxHolder, {
                    Color = "OutlineColor",
                    Position = UDim2.fromOffset(GroupboxHorizontalPadding, GroupboxHeaderHeight - 1),
                    Size = UDim2.new(1, -GroupboxHorizontalPadding * 2, 0, 1),
                    Transparency = Library:GetDesignToken("Opacity.Divider", 0.56),
                    ZIndex = 2,
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    New("ImageLabel", {
                        Image = BoxIcon.Url,
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = BoxIcon.ImageRectOffset,
                        ImageRectSize = BoxIcon.ImageRectSize,
                        Position = UDim2.fromOffset(8, math.floor((GroupboxHeaderHeight - 18) * 0.5)),
                        Size = UDim2.fromOffset(18, 18),
                        ZIndex = 3,
                        Parent = GroupboxHolder,
                    })
                end

                GroupboxLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                    Size = UDim2.new(1, -(BoxIcon and 24 or 0), 0, GroupboxHeaderHeight - 1),
                    Text = Info.Name,
                    TextSize = Library:GetDesignToken("Size.Text", 14),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 3,
                    Parent = GroupboxHolder,
                })
                New("UIPadding", {
                        PaddingLeft = UDim.new(0, Library:GetDesignToken("Spacing.Large", 12)),
                        PaddingRight = UDim.new(0, Info.DisableCollapsing == true and 12 or 36),
                    Parent = GroupboxLabel,
                })

                if Info.DisableCollapsing ~= true then
                    GroupboxCollapseArrow = New("ImageButton", {
                        Image = ArrowIcon and ArrowIcon.Url or "",
                        ImageColor3 = "WhiteColor",
                        ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
                        ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
                        BackgroundTransparency = 1,
                        Rotation = 180,
                        Position = UDim2.new(1, -30, 0, math.floor((GroupboxHeaderHeight - 18) * 0.5)),
                        Size = UDim2.fromOffset(18, 18),
                        ImageTransparency = 0.22,
                        ZIndex = 3,
                        Parent = GroupboxHolder,
                    })
                end

                GroupboxContainer = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, GroupboxHeaderHeight),
                    Size = UDim2.new(1, 0, 1, -GroupboxHeaderHeight),
                    Parent = GroupboxHolder,
                })

                GroupboxList = New("UIListLayout", {
                    Padding = UDim.new(0, Library:GetDesignToken("Spacing.Medium", 8)),
                    Parent = GroupboxContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, GroupboxBottomPadding),
                    PaddingLeft = UDim.new(0, GroupboxHorizontalPadding),
                    PaddingRight = UDim.new(0, GroupboxHorizontalPadding),
                    PaddingTop = UDim.new(0, GroupboxTopPadding),
                    Parent = GroupboxContainer,
                })
            end

            local Groupbox = {
                Type = "Groupbox",

                Connections = {},
                Destroyed = false,

                Visible = true,
                Collapsed = false,

                BoxHolder = BoxHolder,
                Holder = GroupboxHolder,
                Container = GroupboxContainer,

                Tab = Tab,
                DependencyBoxes = {},
                Elements = {}
            }

            local ResizeQueued = false

            function Groupbox:Resize()
                if Groupbox.Destroyed or not GroupboxHolder.Parent then
                    return
                end

                local DPIScale = math.max(Library.DPIScale or 1, 0.01)
                local ContentBottom = (GroupboxList.AbsoluteContentSize.Y / DPIScale) + GroupboxTopPadding
                local ContainerY = GroupboxContainer.AbsolutePosition.Y

                for _, Child in GroupboxContainer:GetChildren() do
                    if Child:IsA("GuiObject") and Child.Visible then
                        local ChildBottom = (Child.AbsolutePosition.Y - ContainerY + Child.AbsoluteSize.Y) / DPIScale
                        ContentBottom = math.max(ContentBottom, ChildBottom)
                    end
                end

                local ExpandedHeight = GroupboxHeaderHeight + ContentBottom + GroupboxBottomPadding
                local TargetSize = UDim2.new(1, 0, 0, Groupbox.Collapsed and GroupboxHeaderHeight or math.ceil(ExpandedHeight))

                GroupboxLine.Visible = not Groupbox.Collapsed
                local AnimateResize = Library.Animations
                    and Library.Animations.Groupbox
                    and TabCanvas.Visible
                    and GroupboxHolder.Visible
                    and GroupboxHolder.AbsoluteSize.Y > 0

                if AnimateResize then
                    local TweenInfo = Library.GroupboxTweenInfo or Library:GetMotion("Popup")
                    Library:PlayTween(GroupboxHolder, "GroupboxSize", TweenInfo, { Size = TargetSize })
                else
                    Library:CancelTween(GroupboxHolder, "GroupboxSize")
                    GroupboxHolder.Size = TargetSize
                end
            end

            function Groupbox:QueueResize()
                if ResizeQueued or Groupbox.Destroyed then
                    return
                end

                ResizeQueued = true
                task.defer(function()
                    ResizeQueued = false

                    if Groupbox.Destroyed or not GroupboxHolder.Parent then
                        return
                    end

                    Groupbox:Resize()
                end)
            end

            table.insert(Groupbox.Connections, GroupboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Groupbox:QueueResize()
            end))

            function Groupbox:SetCollapsed(Collapsed: boolean)
                if Info.DisableCollapsing == true then return end
                if Groupbox.Collapsed == Collapsed then
                    return
                end

                Groupbox.Collapsed = Collapsed

                local TargetRotation = if Collapsed then 0 else 180

                GroupboxContainer.Visible = not Collapsed
                if Library.Animations and Library.Animations.Groupbox then
                    local TweenInfo = Library.RotatingChevronTweenInfo or Library:GetMotion("Control")
                    Library:PlayTween(GroupboxCollapseArrow, "GroupboxChevron", TweenInfo, { Rotation = TargetRotation })
                else
                    Library:CancelTween(GroupboxCollapseArrow, "GroupboxChevron")
                    GroupboxCollapseArrow.Rotation = TargetRotation
                end

                Groupbox:Resize()
            end

            function Groupbox:ToggleCollapsed()
                if Info.DisableCollapsing == true then return end
                Groupbox:SetCollapsed(not Groupbox.Collapsed)
            end

            function Groupbox:Destroy()
                if Groupbox.Destroyed then
                    return
                end

                Groupbox.Destroyed = true

                Library:CancelTween(GroupboxHolder, "GroupboxSize")
                if GroupboxCollapseArrow then
                    Library:CancelTween(GroupboxCollapseArrow, "GroupboxChevron")
                end

                if Groupbox.Connections then
                    for _, Connection in Groupbox.Connections do
                        Connection:Disconnect()
                    end
                    table.clear(Groupbox.Connections)
                end

                for _, Element in table.clone(Groupbox.Elements) do
                    if Element.Destroy then
                        Element:Destroy()
                    end
                end
                table.clear(Groupbox.Elements)

                for _, SubDepbox in table.clone(Groupbox.DependencyBoxes) do
                    if SubDepbox.Destroy then
                        SubDepbox:Destroy()
                    end
                end
                table.clear(Groupbox.DependencyBoxes)

                if GroupboxHolder then 
                    GroupboxHolder:Destroy() 
                end

                if BoxHolder then
                    BoxHolder:Destroy()
                end
            end

            function Groupbox:SetVisible(Visible: boolean)
                if Groupbox.Visible == Visible then
                    return
                end

                Groupbox.Visible = Visible
                BoxHolder.Visible = Visible

                if Visible == true and Library.Searching then
                    Library:UpdateSearch(Library.SearchText)
                end
            end

            function Groupbox:SetOrder(Order: number)
                assert(typeof(Order) == "number", "Groupbox order must be a number.")
                BoxHolder.LayoutOrder = Order
            end

            function Groupbox:Show()
                Groupbox:SetVisible(true) 
            end

            function Groupbox:Hide()
                Groupbox:SetVisible(false) 
            end

            if Info.DisableCollapsing ~= true then
                GroupboxCollapseArrow.MouseButton1Click:Connect(function()
                    Groupbox:ToggleCollapsed()
                end)
            end

            Groupbox.AddTabbox = AddTabbox
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox

            if Info.Visible == false then
                Groupbox:Hide()
            end

            if Info.DisableCollapsing ~= true and Info.Collapsed == true then
                Groupbox:SetCollapsed(true)
            end

            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name, IconName, Visible, Collapsed, DisableCollapsing)
            return Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName, Visible = Visible, Collapsed = Collapsed, DisableCollapsing = DisableCollapsing })
        end

        function Tab:AddRightGroupbox(Name, IconName, Visible, Collapsed, DisableCollapsing)
            return Tab:AddGroupbox({ Side = 2, Name = Name, IconName = IconName, Visible = Visible, Collapsed = Collapsed, DisableCollapsing = DisableCollapsing })
        end

        local function AbsorbRightColumn()
            local Moved = {}
            for _, Child in TabRight:GetChildren() do
                if Child:IsA("GuiObject") then
                    table.insert(Moved, Child)
                end
            end

            table.sort(Moved, function(First, Second)
                return First.LayoutOrder < Second.LayoutOrder
            end)

            for _, Child in Moved do
                Child.Parent = TabLeft
            end
        end

        function Tab:SetFullWidth(Enabled)
            local Wanted = Enabled ~= false
            if Tab.FullWidth == Wanted then
                return Tab
            end

            Tab.FullWidth = Wanted
            if Wanted then
                AbsorbRightColumn()
            end

            Tab:RefreshSides()
            Tab:Resize()
            return Tab
        end

        function Tab:AddFullGroupbox(Name, IconName, Visible, Collapsed, DisableCollapsing)
            if not Tab.FullWidth then
                Tab.FullWidth = true
                AbsorbRightColumn()
            end

            local Groupbox = Tab:AddGroupbox({ Side = 1, Name = Name, IconName = IconName, Visible = Visible, Collapsed = Collapsed, DisableCollapsing = DisableCollapsing })
            Tab:RefreshSides()
            return Groupbox
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            Library:AnimateTabHover(TabButton, TabLabel, TabIcon, Hovering)
        end

        function Tab:Show()
            if Tab.Destroyed then
                return
            end

            if Library.ActiveTab == Tab then
                return
            end

            if Library.ActiveTab then
                local From = tonumber(Library.ActiveTab.Order) or 0
                local To = tonumber(Tab.Order) or 0
                Library.TabSwipeDirection = To < From and -1 or 1
                Library.ActiveTab:Hide()
            else
                Library.TabSwipeDirection = 1
            end

            Library:AnimateTabSelection(TabButton, TabLabel, TabIcon, true)

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            Library:PlayTabAnimation(TabCanvas, true)
            Tab:Resize(Tab.WarningBox.Visible)

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            if Tab.Destroyed then
                return
            end

            Library:AnimateTabSelection(TabButton, TabLabel, TabIcon, false)

            Library:PlayTabAnimation(TabCanvas, false)
            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            if Tab.Destroyed then
                return
            end

            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        function Tab:SetOrder(Order: number)
            TabButton.LayoutOrder = Order
        end

        function Tab:Destroy()
            if Tab.Destroyed then
                return
            end

            Tab.Destroyed = true

            if Tab.Connections then
                for _, Connection in Tab.Connections do
                    Connection:Disconnect()
                end
                table.clear(Tab.Connections)
            end

            for _, Groupbox in table.clone(Tab.Groupboxes) do
                if Groupbox.Destroy then
                    Groupbox:Destroy()
                end
            end
            table.clear(Tab.Groupboxes)

            for _, Tabbox in table.clone(Tab.Tabboxes) do
                if Tabbox.Destroy then
                    Tabbox:Destroy()
                end
            end
            table.clear(Tab.Tabboxes)

            for _, DepGroupbox in table.clone(Tab.DependencyGroupboxes) do
                if DepGroupbox.Destroy then
                    DepGroupbox:Destroy()
                end
            end
            table.clear(Tab.DependencyGroupboxes)

            if TabCanvas then
                TabCanvas:Destroy()
            elseif TabContainer then
                TabContainer:Destroy()
            end

            if TabButton then
                for Index, Entry in Library.TabButtons do
                    if typeof(Entry) == "table" and Entry.Button == TabButton then
                        table.remove(Library.TabButtons, Index)
                        break
                    end
                end
                
                TabButton:Destroy()
            end

            if Library.ActiveTab == Tab then
                Library.ActiveTab = nil
            end
            if Library.LastSearchTab == Tab then
                Library.LastSearchTab = nil
            end

            Library.Tabs[Name] = nil
        end

        
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        Icon = Icon or "key"

        local TabButton: TextButton
        local TabLabel
        local TabIcon
        local TabCanvas
        local TabContainer

        Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = function()
                    return Library:GetAccentSurfaceColor(0.12)
                end,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, Library:GetDesignToken("Shell.NavigationHeight", 38)),
                Text = "",
                Parent = Tabs,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library:GetDesignToken("Radius.Card", 4)),
                Parent = TabButton,
            })
            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(NavigationLabelX, 0),
                Size = UDim2.new(1, -(NavigationLabelX + 8), 1, 0),
                Text = Name,
                TextSize = 15,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(IsCompact and 0.5 or 0, 0.5),
                    Image = Icon.Url,
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Position = IsCompact and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, NavigationIconX, 0.5, 0),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(NavigationIconSize, NavigationIconSize),
                    Parent = TabButton,
                })
            end

            table.insert(Library.TabButtons, {
                Button = TabButton,
                Label = TabLabel,
                Icon = TabIcon,
            })

            
            TabCanvas = New("CanvasGroup", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                GroupTransparency = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageColor3 = "AccentColor",
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                Visible = true,
                Parent = TabCanvas,
            })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 10),
                Parent = TabContainer,
            })
            ConfigureAutoScrollbar(TabContainer)
        end

        
        local Tab = {
            Description = Description,
            IsKeyTab = true,
            Destroyed = false,

            Elements = {},

            Window = Window,
            Canvas = TabCanvas
        }

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 22),
                Parent = TabContainer,
            })

            local function SnapKeyBoxWidth()
                local Available = math.floor(TabContainer.AbsoluteSize.X)
                if Available <= 0 then
                    return
                end

                local Width = math.floor(Available * 0.75)
                if (Available - Width) % 2 ~= 0 then
                    Width -= 1
                end
                Holder.Size = UDim2.new(0, math.max(1, Width), 0, 22)
            end

            SnapKeyBoxWidth()
            TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(SnapKeyBoxWidth)

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Box,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Box,
                })
            )

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Button,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
            )

            Button.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                if not Library:MouseIsOverFrame(Button, Input.Position) then
                    return
                end

                Library:SafeCallback(Callback, Box.Text)
            end)
        end
        
        function Tab:Destroy()
            if Tab.Destroyed then
                return
            end

            Tab.Destroyed = true

            if TabCanvas then
                TabCanvas:Destroy()
            elseif TabContainer then
                TabContainer:Destroy()
            end

            if TabButton then
                for Index, Entry in Library.TabButtons do
                    if typeof(Entry) == "table" and Entry.Button == TabButton then
                        table.remove(Library.TabButtons, Index)
                        break
                    end
                end
                
                TabButton:Destroy()
            end

            if Library.ActiveTab == Tab then
                Library.ActiveTab = nil
            end
            if Library.LastSearchTab == Tab then
                Library.LastSearchTab = nil
            end

            Library.Tabs[Name] = nil
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end
        function Tab:UpdateCorners() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            Library:AnimateTabHover(TabButton, TabLabel, TabIcon, Hovering)
        end

        function Tab:Show()
            if Tab.Destroyed then
                return
            end

            if Library.ActiveTab == Tab then
                return
            end

            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            Library:AnimateTabSelection(TabButton, TabLabel, TabIcon, true)

            Library:PlayTabAnimation(TabCanvas, true)

            if Description then
                Window:ShowTabInfo(Name, Description)
            end

            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            if Tab.Destroyed then
                return
            end

            Library:AnimateTabSelection(TabButton, TabLabel, TabIcon, false)

            Library:PlayTabAnimation(TabCanvas, false)
            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            if Tab.Destroyed then
                return
            end

            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseGroupbox)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddDialog(Idx, Info)
        Info = Library:Validate(Info, Templates.Dialog)

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Active = false,
            ZIndex = 9000,
            Visible = true,
            Parent = MainFrame,
        })
        Library:PlayTween(DialogOverlay, "DialogOverlayFade", Library.DialogOverlayOpenAnimationInfo, {
            BackgroundTransparency = 0.58,
        })

        DialogFrame = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "RaisedColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 9001,
            Parent = DialogOverlay,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = DialogFrame,
            })
        )
        local DialogOutline = Library:AddOutline(DialogFrame)
        Library:AddSoftShadow(DialogFrame, 18, 0.4, UDim2.fromOffset(0, 4))
        DialogOutline.Transparency = 0.16

        local InnerContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9002,
            Parent = DialogFrame,
        })
        local DialogScale = New("UIScale", {
            Scale = 0.975,
            Parent = DialogFrame,
        })
        Library:PlayTween(DialogScale, "DialogScale", Library.DialogOpenAnimationInfo, {
            Scale = 1,
        })
        local _InnerPadding = New("UIPadding", {
            PaddingBottom = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            Parent = InnerContainer,
        })
        local _InnerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = HeaderContainer,
        })

        local TitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9002,
            Parent = HeaderContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        if Info.Icon then
            local ParsedIcon = Library:GetCustomIcon(Info.Icon)
            if ParsedIcon then
                local _IconImg = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 16),
                    Image = ParsedIcon.Url,
                    ImageColor3 = Info.TitleColor or "FontColor",
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    LayoutOrder = 1,
                    ZIndex = 9002,
                    Parent = TitleRow,
                })
            end
        end

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title,
            TextSize = 18,
            TextColor3 = Info.TitleColor or "FontColor",
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = TitleRow,
        })

        local DescriptionLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description,
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Info.DescriptionColor or "FontColor",
            TextWrapped = true,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = HeaderContainer,
        })

        DialogContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        local _DialogContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = DialogContainer,
        })
        
        local _Sep2 = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 9002,
            Parent = InnerContainer,
        })

        ButtonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Destroyed = false,
            Elements = {},
            Container = DialogContainer,
        }

        function Dialog:Resize()
            if Dialog.Destroyed or not MainFrame.Parent then
                return
            end

            local MaxWidth = math.max(220, MainFrame.AbsoluteSize.X - 24)
            local MinWidth = math.min(400, MaxWidth)

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in FooterButtonsList do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8) + 30
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)

            local _DescX, DescY = Library:GetTextBounds(DescriptionLabel.Text, Library.Scheme.Font, 14, TargetWidth - 30)
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in DialogContainer:GetChildren() do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end
            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons
        end

        function Dialog:SetTitle(Title)
            if Dialog.Destroyed then
                return
            end

            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            if Dialog.Destroyed then
                return
            end

            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:Dismiss()
            if Dialog.Destroyed then
                return
            end

            Dialog.Destroyed = true

            if Library.ActiveDialog == Dialog then
                Library.ActiveDialog = nil
            end

            Library:SafeCallback(Info.OnDismiss, Dialog)

            for Index = #Dialog.Elements, 1, -1 do
                local Element = Dialog.Elements[Index]
                if Element and Element.Destroy then
                    Element:Destroy()
                end
            end
            table.clear(Dialog.Elements)

            Library:PlayTween(DialogOverlay, "DialogOverlayFade", Library.DialogOverlayCloseAnimationInfo, {
                BackgroundTransparency = 1,
            })
            Library:PlayTween(DialogScale, "DialogScale", Library.DialogCloseAnimationInfo, {
                Scale = 0.985,
            })
            
            task.delay(Library.DialogCloseAnimationInfo.Time, function()
                if DialogOverlay and DialogOverlay.Parent then
                    DialogOverlay:Destroy()
                end
            end)
            Library.Dialogues[Idx] = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if Dialog.Destroyed then
                return
            end

            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
                Dialog:Resize()
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if Dialog.Destroyed then
                return
            end

            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if Dialog.Destroyed then
                return
            end

            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            if Dialog.Destroyed then
                return
            end

            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = math.max(tonumber(ButtonInfo.WaitTime) or 0, 0)

            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = 9002,
                Parent = ButtonsHolder,
            })
            
            local Variant = Library:NormalizeButtonVariant(ButtonInfo.Variant)
            local InitialStyle = Library:GetButtonStyle(Variant, WaitTime > 0)

            local TextBtn = New("TextButton", {
                BackgroundColor3 = InitialStyle.BackgroundColor,
                BorderColor3 = InitialStyle.OutlineColor,
                BackgroundTransparency = InitialStyle.BackgroundTransparency,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9002,
                Parent = ButtonContainer,
            })
            local OutlineStroke = Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", { 
                    CornerRadius = UDim.new(0, Library.CornerRadius), 
                    Parent = TextBtn 
                })
            )

            local _BtnPadding = New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = InitialStyle.TextColor,
                TextTransparency = InitialStyle.TextTransparency,
                TextSize = 14,
                ZIndex = 9002,
                Parent = TextBtn,
            })
            
            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ProgressBar
            if WaitTime > 0 then
                ProgressBar = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 2,
                    Parent = TextBtn,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", { 
                        CornerRadius = UDim.new(0, Library.CornerRadius), 
                        Parent = ProgressBar 
                    })
                )
            end

            local IsActive = WaitTime <= 0

            local function UpdateFooterButtonStyleRegistry()
                local BaseRegistry = Library.Registry[TextBtn] or {}
                BaseRegistry.BackgroundColor3 = function()
                    return Library:GetButtonStyle(Variant, not IsActive).BackgroundColor
                end
                BaseRegistry.BackgroundTransparency = function()
                    return Library:GetButtonStyle(Variant, not IsActive).BackgroundTransparency
                end
                Library.Registry[TextBtn] = BaseRegistry

                local LabelRegistry = Library.Registry[BtnLabel] or {}
                LabelRegistry.TextColor3 = function()
                    return Library:GetButtonStyle(Variant, not IsActive).TextColor
                end
                LabelRegistry.TextTransparency = function()
                    return Library:GetButtonStyle(Variant, not IsActive).TextTransparency
                end
                Library.Registry[BtnLabel] = LabelRegistry

                local StrokeRegistry = Library.Registry[OutlineStroke] or {}
                StrokeRegistry.Color = function()
                    return Library:GetButtonStyle(Variant, not IsActive).OutlineColor
                end
                StrokeRegistry.Transparency = function()
                    return Library:GetButtonStyle(Variant, not IsActive).OutlineTransparency
                end
                Library.Registry[OutlineStroke] = StrokeRegistry
            end

            local function ApplyFooterButtonStyle(Hovered: boolean?, Disabled: boolean?, Animate: boolean?)
                UpdateFooterButtonStyleRegistry()
                ApplyButtonVisual(
                    TextBtn,
                    OutlineStroke,
                    BtnLabel,
                    Variant,
                    Disabled,
                    Hovered,
                    Animate,
                    "DialogFooter"
                )
            end

            ApplyFooterButtonStyle(false, not IsActive, false)

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    if Dialog.Destroyed or not TextBtn.Parent then
                        return
                    end

                    IsActive = not Disabled
                    ApplyFooterButtonStyle(false, Disabled, true)
                end
            }

            TextBtn.MouseEnter:Connect(function()
                if not IsActive then return end
                ApplyFooterButtonStyle(true, false, true)
            end)
            TextBtn.MouseLeave:Connect(function()
                if not IsActive then return end
                ApplyFooterButtonStyle(false, false, true)
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end
                if ButtonInfo.Callback then
                    Library:SafeCallback(ButtonInfo.Callback, Dialog)
                end
                if Info.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 0, 2)
                }):Play()
                
                task.delay(WaitTime, function()
                    if Dialog.Destroyed or not TextBtn.Parent then
                        return
                    end

                    ButtonWrap:SetDisabled(false)
                    if ProgressBar and ProgressBar.Parent then
                        Library:PlayTween(ProgressBar, "DialogFooterProgress", Library.TweenInfo, {
                            BackgroundTransparency = 1
                        })
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
            Dialog:Resize()
        end

        for BIdx, BInfo in Info.FooterButtons do
            if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
            Dialog:AddFooterButton(BIdx, BInfo)
        end

        setmetatable(Dialog, BaseGroupbox)
        Library.Dialogues[Idx] = Dialog

        Dialog:Resize()
        
        Library.ActiveDialog = Dialog
        return Dialog
    end

    function Window:Toggle(Value: boolean?, Source: string?)
        if typeof(Value) == "boolean" and Value == Library.Toggled then
            return
        end

        if Library.ActiveLoading then
            if Value == true then
                return
            end

            if not Library.Toggled then
                return
            end
        end

        local TargetState = typeof(Value) == "boolean" and Value or not Library.Toggled
        Library.Toggled = TargetState
        if TargetState then
            Window.LastHideReason = nil
        else
            Window.LastHideReason = Source
        end
        VisibilityChanged:Fire(Library.Toggled)
        Window:RefreshCompactLauncher(Library.Animations and Library.Animations.ToggleWindow == true)

        WindowAnimationSequence += 1
        local AnimationSequence = WindowAnimationSequence

        if WindowTween then
            StopTween(WindowTween, true)
            WindowTween = nil
        end
        Library:CancelTween(WindowScale, "WindowVisibilityScale")

        if Library.Animations and Library.Animations.ToggleWindow == true then
            local TargetScale = math.max(Library.DPIScale or 1, 0.01)
            local AnimationInfo = Library.Toggled
                and (Library.WindowOpenAnimationInfo or Library.WindowAnimationInfo)
                or (Library.WindowCloseAnimationInfo or Library.WindowAnimationInfo)

            WindowScale.Scale = TargetScale

            if Library.Toggled then
                local WasVisible = MainFrame.Visible
                MainFrame.Visible = true

                if not WasVisible then
                    MainFrame.GroupTransparency = 1
                end
            end

            WindowTween = TweenService:Create(MainFrame, AnimationInfo, {
                GroupTransparency = Library.Toggled and 0 or 1,
            })

            local ActiveWindowTween = WindowTween

            WindowTween.Completed:Once(function(PlaybackState)
                if PlaybackState ~= Enum.PlaybackState.Completed or AnimationSequence ~= WindowAnimationSequence then
                    return
                end

                if not Library.Unloaded and MainFrame.Parent and not Library.Toggled then
                    MainFrame.Visible = false
                end

                if WindowTween == ActiveWindowTween then
                    WindowTween = nil
                end
            end)
            WindowTween:Play()
        else
            MainFrame.GroupTransparency = Library.Toggled and 0 or 1
            MainFrame.Visible = Library.Toggled
            WindowScale.Scale = math.max(Library.DPIScale or 1, 0.01)
        end

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            local OldMouseIconEnabled = UserInputService.MouseIconEnabled
            local ShowCursorBinding = Library.ShowCursorBinding
            pcall(function()
                RunService:UnbindFromRenderStep(ShowCursorBinding)
            end)
            local LastCursorX, LastCursorY = -1, -1

            RunService:BindToRenderStep(ShowCursorBinding, Enum.RenderPriority.Last.Value, function()
                local WantIcon = not Library.ShowCustomCursor
                if UserInputService.MouseIconEnabled ~= WantIcon then
                    UserInputService.MouseIconEnabled = WantIcon
                end

                local X, Y = Mouse.X, Mouse.Y
                if X ~= LastCursorX or Y ~= LastCursorY then
                    LastCursorX, LastCursorY = X, Y
                    Cursor.Position = UDim2.fromOffset(X, Y)
                end

                if Cursor.Visible ~= Library.ShowCustomCursor then
                    Cursor.Visible = Library.ShowCustomCursor
                end

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = OldMouseIconEnabled
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep(ShowCursorBinding)
                end
            end)
        elseif not Library.Toggled then
            TooltipLabel.Visible = false

            for _, Option in Library.Options do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    function Library:Toggle(Value: boolean?, Source: string?)
        return Window:Toggle(Value, Source)
    end

    if MinimizeButton then
        Library:GiveSignal(MinimizeButton.MouseButton1Click:Connect(function()
            if Library.Toggled then
                Window:Toggle(false, "Minimize")
            end
        end))
    end

    if WindowInfo.EnableSidebarResize then
        local Threshold = (WindowInfo.MinSidebarWidth + WindowInfo.SidebarCompactWidth) * WindowInfo.SidebarCollapseThreshold
        local StartPos, StartWidth
        local Dragging = false
        local Changed

        local SidebarGrabber = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, 8, 1, 0),
            Text = "",
            Parent = DividerLine,
        })
        SidebarGrabber.MouseEnter:Connect(function()
            Library:PlayTween(DividerLine, "SidebarResizeHover", Library.TweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.OutlineColor),
            })
        end)
        SidebarGrabber.MouseLeave:Connect(function()
            if Dragging then
                return
            end
            Library:PlayTween(DividerLine, "SidebarResizeHover", Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.OutlineColor,
            })
        end)

        SidebarGrabber.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) then
                return
            end

            Library.CantDragForced = true

            StartPos = Input.Position
            StartWidth = Window:GetSidebarWidth()
            Dragging = true

            Changed = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Library.CantDragForced = false
                Library:PlayTween(DividerLine, "SidebarResizeHover", Library.TweenInfo, {
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                })

                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end
            end)
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if not Library.Toggled or not (ScreenGui and ScreenGui.Parent) then
                Dragging = false
                Library.CantDragForced = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end

                return
            end

            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - StartPos
                local Width = StartWidth + Delta.X

                if WindowInfo.DisableCompactingSnap then
                    Window:SetSidebarWidth(Width)
                    return
                end

                if Width > Threshold then
                    Window:SetSidebarWidth(math.max(Width, WindowInfo.MinSidebarWidth))
                else
                    Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth)
                end
            end
        end))
    end

    local WindowCameraConnection
    local function HandleViewportChanged()
        if Library.Unloaded then
            return
        end

        Window:QueueFitToViewport()
        if CompactLauncher and CompactLauncher.Parent then
            ClampGuiToViewport(CompactLauncher, 8)
        end
    end
    local function BindWindowCamera()
        if WindowCameraConnection and WindowCameraConnection.Connected then
            WindowCameraConnection:Disconnect()
        end

        local Camera = workspace.CurrentCamera
        if Camera then
            WindowCameraConnection = Library:GiveSignal(
                Camera:GetPropertyChangedSignal("ViewportSize"):Connect(HandleViewportChanged)
            )
        else
            WindowCameraConnection = nil
        end
    end

    BindWindowCamera()
    Library:GiveSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        BindWindowCamera()
        HandleViewportChanged()
    end))

    Window:SetAlwaysOnTop(WindowInfo.AlwaysOnTop)
    Window:FitToViewport()
    if WindowInfo.EnableCompacting and (WindowInfo.SidebarCompacted or Library.IsMobile) then
        Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth)
    end
    if not WindowInfo.AutoShow or Library.ActiveLoading then
        Window:RefreshCompactLauncher(false)
    end
    if WindowInfo.AutoShow and not Library.ActiveLoading then
        task.spawn(Library.Toggle)
    end

    if Library.IsMobile and not WindowInfo.ShowCompactLauncher then
        local ToggleButton = Library:AddDraggableButton("Toggle", function()
            Library:Toggle()
        end, true, true)

        local LockButton = Library:AddDraggableButton("Lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetText(Library.CantDragForced and "Unlock" or "Lock")
        end, true, true)

        if WindowInfo.MobileButtonsSide == "Right" then
            ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)
            ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)

            LockButton.Button.AnchorPoint = Vector2.new(1, 0)
            LockButton.Button.Position = UDim2.new(1, -(ToggleButton.Button.Size.X.Offset + 12), 0, 6)
        else
            ToggleButton.Button.AnchorPoint = Vector2.new(0, 0)
            ToggleButton.Button.Position = UDim2.fromOffset(6, 6)

            LockButton.Button.AnchorPoint = Vector2.new(0, 0)
            LockButton.Button.Position = UDim2.fromOffset(ToggleButton.Button.Size.X.Offset + 12, 6)
        end

        if WindowInfo.ShowMobileButtons == false then
            ToggleButton.Button.Visible = false
            LockButton.Button.Visible = false
        end
    end

    
    Library:GiveSignal(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:QueueSearch(SearchBox.Text)
    end))

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if Input.KeyCode == Library.ToggleKeybind then
            Library:Toggle(nil, "Keybind")
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    Library.Window = Window
    return Window
end

function Library:CreateLoading(LoadingInfo)
    if Library.ActiveLoading then
        warn("Loading GUI already exists, you cannot create multiple Loading GUIs.")
        return Library.ActiveLoading
    end

    LoadingInfo = Library:Validate(LoadingInfo, Templates.Loading)

    local Loading = {
        CurrentStep = LoadingInfo.CurrentStep,
        TotalSteps = LoadingInfo.TotalSteps,

        ShowSidebar = LoadingInfo.ShowSidebar,
        AutoResizeHeight = LoadingInfo.AutoResizeHeight,
        AlwaysOnTop = LoadingInfo.AlwaysOnTop,

        IsError = false,
        Destroyed = false,

        WindowWidth = LoadingInfo.WindowWidth,
        WindowHeight = LoadingInfo.WindowHeight,
        BaseWindowHeight = LoadingInfo.WindowHeight,
        WindowErrorHeight = LoadingInfo.WindowHeight,

        ContentWidth = LoadingInfo.ContentWidth,
        SidebarWidth = LoadingInfo.SidebarWidth,
    }

    
    local ScreenGui = New("ScreenGui", {
        Name = "MonHubLoading",
        DisplayOrder = 999,
        ResetOnSpawn = false
    })
    ParentUI(ScreenGui)
    Loading.ScreenGui = ScreenGui
    SetAlwaysOnTop(ScreenGui, LoadingInfo.AlwaysOnTop)

    ScreenGui.DescendantRemoving:Connect(function(Instance)
        Library:RemoveFromRegistry(Instance)
    end)

    
    local MainFrame = New("TextButton", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Loading.ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth, Loading.WindowHeight),
        ClipsDescendants = true,
        Text = "",
        AutoButtonColor = false,
        Parent = ScreenGui,
    })
    Library:AddOutline(MainFrame)
    Library:AddSoftShadow(MainFrame, 18, 0.42, UDim2.fromOffset(0, 4))
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = MainFrame }))
    
	local MainScale = New("UIScale", {
		Scale = Library.IsMobile and 0.8 or 1,
		Parent = MainFrame
	})
	table.insert(Library.Scales, MainScale)
	Library.ScalesOffset[MainScale] = Library.IsMobile and 0.2 or 0

    
    local Container = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, Loading.ContentWidth, 1, 0),
        Parent = MainFrame,
    })

    local SideBar = New("Frame", {
        Name = "SideBar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Loading.ContentWidth, 0),
        Size = UDim2.new(0, Loading.ShowSidebar and Loading.SidebarWidth or 0, 1, 0),
        ClipsDescendants = true,
        Visible = Loading.ShowSidebar,
        Parent = MainFrame,
    })
    local SidebarCorner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = SideBar })
    table.insert(Library.Corners, SidebarCorner)
    
    Library:AddOutline(SideBar)
    
    local SidebarDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Visible = Loading.ShowSidebar,
        Parent = SideBar,
    })

    
    local TopBar = New("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 2,
        Parent = Container,
    })
    local TitleHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = TopBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = TitleHolder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        Parent = TitleHolder,
    })

    if LoadingInfo.Icon then
        local Icon = Library:GetCustomIcon(LoadingInfo.Icon)
        local _WindowIcon = New("ImageLabel", {
            Image = Icon and Icon.Url or "",
            ImageRectOffset = Icon and Icon.ImageRectOffset or Vector2.zero,
            ImageRectSize = Icon and Icon.ImageRectSize or Vector2.zero,
            Size = LoadingInfo.IconSize,
            Parent = TitleHolder,
        })
    else
        local _WindowIcon = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = LoadingInfo.IconSize,
            Text = LoadingInfo.Title:sub(1, 1),
            TextScaled = true,
            Visible = false,
            Parent = TitleHolder,
        })
    end

    local TitleX = Library:GetTextBounds(
        LoadingInfo.Title,
        Library.Scheme.Font,
        20,
        TitleHolder.AbsoluteSize.X - (LoadingInfo.Icon and (LoadingInfo.IconSize.X.Offset + 6) or 0) - 12
    )
    local _WindowTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, TitleX, 1, 0),
        Text = LoadingInfo.Title,
        TextSize = 20,
        Parent = TitleHolder,
    })

    Library:MakeLine(Container, {
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 0, 1),
    })

    
    local InnerContent = New("Frame", {
        Name = "InnerContent",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        Parent = Container,
    })

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
        Parent = InnerContent,
    })

    local IconHolder = New("Frame", {
        Name = "IconHolder",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(64, 64),
        Parent = InnerContent,
    })

    local LoaderIcon = Library:GetCustomIcon(LoadingInfo.LoadingIcon)
    local LoadingIcon = New("ImageLabel", {
        Name = "LoaderIcon",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        Image = LoaderIcon and LoaderIcon.Url or "",
        ImageRectOffset = LoaderIcon and LoaderIcon.ImageRectOffset or Vector2.zero,
        ImageRectSize = LoaderIcon and LoaderIcon.ImageRectSize or Vector2.zero,
        ImageColor3 = LoadingInfo.LoadingIconColor or ((LoadingInfo.LoadingIcon == Templates.Loading.LoadingIcon) and "AccentColor" or "WhiteColor"),
        Parent = IconHolder,
    })

    local RotationTween
    if LoadingInfo.LoadingIconTweenTime > 0 then
        RotationTween = TweenService:Create(
            LoadingIcon,
            TweenInfo.new(LoadingInfo.LoadingIconTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            { Rotation = 360 }
        )
        RotationTween:Play()
    end

    local MessageLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 18,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    local DescriptionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 14,
        TextTransparency = 0.5,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    
    local SliderBar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0.7, 0, 0, 15),
        Parent = InnerContent,
    })
    Library:AddOutline(SliderBar)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderBar }))

    local SliderFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = SliderBar,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderFill }))

    local ProgressLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextSize = 14,
        ZIndex = 2,
        Parent = SliderBar,
    })
    New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Color = "DarkColor",
        LineJoinMode = Enum.LineJoinMode.Miter,
        Thickness = 0.5,
        Transparency = 0.7,
        Parent = ProgressLabel,
    })

    
    local SidebarScrolling = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = "OutlineColor",
        Parent = SideBar,
    })
    local SidebarList = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SidebarScrolling,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        Parent = SidebarScrolling,
    })

    local SidebarObject = {
        Elements = {},
        DependencyBoxes = {},
        Tabboxes = {},
        
        BoxHolder = SidebarScrolling,
        Container = SidebarScrolling,
        
        Resize = function(self)
            SidebarScrolling.CanvasSize = UDim2.fromOffset(0, SidebarList.AbsoluteContentSize.Y + 24)
        end,
        Tab = {
            Elements = {},
            DependencyBoxes = {},
            DependencyGroupboxes = {},
            Tabboxes = {},
        },
    }

    SidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SidebarObject:Resize()
    end)

    setmetatable(SidebarObject, BaseGroupbox)
    Loading.Sidebar = SidebarObject

    
    local ErrorFrame = New("Frame", {
        Name = "Error",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        ClipsDescendants = true,
        Visible = false,
        Parent = Container,
    })

    local _ErrorTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 15),
        Size = UDim2.new(1, -30, 0, 18),
        Text = "Error",
        TextColor3 = "RedColor",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ErrorFrame,
    })

    local ErrorLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 39),
        Size = UDim2.new(1, -30, 1, -90),
        Text = "Error Message",
        TextSize = 14,
        TextTransparency = 0.2,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = ErrorFrame,
    })

    local ErrorButtonsDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, -48),
        Size = UDim2.new(1, -30, 0, 1),
        Visible = false,
        Parent = ErrorFrame,
    })

    local ErrorButtonsHolder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 42),
        Visible = false,
        Parent = ErrorFrame,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ErrorButtonsHolder,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = ErrorButtonsHolder,
    })

    function Loading:UpdateLayout()
        if Loading.IsError then
            Loading:RecalculateErrorHeight()
        end

        local ShowSidebar = Loading.ShowSidebar
        local FinalWidth = ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth
        local FinalHeight = Loading.IsError and Loading.WindowErrorHeight or Loading.WindowHeight
        
        if ShowSidebar then
            SideBar.Visible = true
            SidebarDivider.Visible = true
        end

        TweenService:Create(MainFrame, Library.TweenInfo, { Size = UDim2.fromOffset(FinalWidth, FinalHeight) }):Play()
        TweenService:Create(SideBar, Library.TweenInfo, { Position = UDim2.fromOffset(Loading.ContentWidth, 0), Size = UDim2.new(0, ShowSidebar and Loading.SidebarWidth or 0, 1, 0) }):Play()
        TweenService:Create(Container, Library.TweenInfo, { Size = UDim2.new(0, ShowSidebar and Loading.ContentWidth or Loading.WindowWidth, 1, 0) }):Play()

        if not ShowSidebar then
            task.delay(Library.TweenInfo.Time, function()
                if not Loading.ShowSidebar then
                    SideBar.Visible = false
                    SidebarDivider.Visible = false
                end
            end)
        end
    end

    
    function Loading:RecalculateLoadingHeight()
        if not Loading.AutoResizeHeight then
            return
        end

        local RequiredHeight = 
              49 
            + 48 
            + InnerContent.UIListLayout.AbsoluteContentSize.Y

        Loading.WindowHeight = math.max(Loading.BaseWindowHeight, RequiredHeight)
    end

    function Loading:SetMessage(Text)
        MessageLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetDescription(Text)
        DescriptionLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetLoadingIcon(Icon)
        local IconData = Library:GetCustomIcon(Icon)
        assert(IconData, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        LoadingIcon.Image = IconData.Url
        LoadingIcon.ImageRectOffset = IconData.ImageRectOffset
        LoadingIcon.ImageRectSize = IconData.ImageRectSize
    end

    function Loading:SetLoadingIconTweenTime(TweenTime)
        if RotationTween then
            StopTween(RotationTween, true)
            RotationTween = nil
        end

        if TweenTime > 0 then
            RotationTween = TweenService:Create(
                LoadingIcon,
                TweenInfo.new(TweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
                { Rotation = 360 }
            )
            RotationTween:Play()
        else
            LoadingIcon.Rotation = 0
        end
    end

    function Loading:SetLoadingIconColor(Color)
        LoadingIcon.ImageColor3 = Color
    end

    function Loading:SetCurrentStep(Step)
        Loading.CurrentStep = math.clamp(Step, 0, Loading.TotalSteps)

        local Progress = Loading.CurrentStep / Loading.TotalSteps
        TweenService:Create(SliderFill, Library.TweenInfo, { Size = UDim2.fromScale(Progress, 1) }):Play()

        ProgressLabel.Text = string.format("%d/%d", Loading.CurrentStep, Loading.TotalSteps)
    end

    function Loading:SetTotalSteps(Steps)
        Loading.TotalSteps = Steps
        Loading:SetCurrentStep(Loading.CurrentStep)
    end

    
    function Loading:SetWindowHeight(Height)
        Loading.WindowHeight = Height
        Loading:UpdateLayout()
    end

    function Loading:SetWindowWidth(Width)
        Loading.WindowWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetContentWidth(Width)
        Loading.ContentWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetSidebarWidth(Width)
        Loading.SidebarWidth = Width
        Loading:UpdateLayout()
    end

    
    function Loading:ShowSidebarPage(Bool)
        Loading.ShowSidebar = Bool
        Loading:UpdateLayout()
    end

    
    function Loading:ShowErrorPage(Enabled)
        Loading.IsError = Enabled
        InnerContent.Visible = not Enabled
        ErrorFrame.Visible = Enabled

        if Loading.ShowSidebar then
            Loading:ShowSidebarPage(not Enabled)
        else
            Loading:UpdateLayout()
        end
    end

    function Loading:RecalculateErrorHeight()
        local TargetWidth = (Loading.ShowSidebar and Loading.ContentWidth or Loading.WindowWidth) - 30
        local _, ErrorY = Library:GetTextBounds(ErrorLabel.Text, Library.Scheme.Font, 14, TargetWidth)

        ErrorLabel.Size = UDim2.new(1, -30, 0, ErrorY)

        local HasButtons = ErrorButtonsHolder.Visible
        local RequiredHeight =
              49                        
            + 15                        
            + 18                        
            + 6                         
            + ErrorY                    
            + 15                        
            + (HasButtons and 48 or 0)  

        Loading.WindowErrorHeight = RequiredHeight 
    end

    function Loading:SetErrorMessage(Text)
        ErrorLabel.Text = Text
        Loading:UpdateLayout()
    end

    function Loading:SetErrorButtons(Buttons)
        assert(typeof(Buttons) == "table", "Buttons must be a table")

        for _, button in ErrorButtonsHolder:GetChildren() do
            if button:IsA("Frame") then 
                button:Destroy() 
            end
        end

        local HasButtons = GetTableSize(Buttons) > 0
        ErrorButtonsHolder.Visible = HasButtons
        ErrorButtonsDivider.Visible = HasButtons

        for Idx, ButtonInfo in Buttons do
            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                Parent = ErrorButtonsHolder,
            })
            
            local Variant = Library:NormalizeButtonVariant(ButtonInfo.Variant)
            local InitialStyle = Library:GetButtonStyle(Variant)

            local TextBtn = New("TextButton", {
                BackgroundColor3 = InitialStyle.BackgroundColor,
                BorderColor3 = InitialStyle.OutlineColor,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                Parent = ButtonContainer,
            })
            local OutlineStroke = Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", { 
                    CornerRadius = UDim.new(0, Library.CornerRadius), 
                    Parent = TextBtn 
                })
            )

            New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or Idx,
                TextColor3 = InitialStyle.TextColor,
                TextTransparency = InitialStyle.TextTransparency,
                TextSize = 14,
                Parent = TextBtn,
            })
            
            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local function UpdateErrorButtonStyleRegistry()
                local BaseRegistry = Library.Registry[TextBtn] or {}
                BaseRegistry.BackgroundColor3 = function()
                    return Library:GetButtonStyle(Variant).BackgroundColor
                end
                BaseRegistry.BackgroundTransparency = function()
                    return Library:GetButtonStyle(Variant).BackgroundTransparency
                end
                Library.Registry[TextBtn] = BaseRegistry

                local LabelRegistry = Library.Registry[BtnLabel] or {}
                LabelRegistry.TextColor3 = function()
                    return Library:GetButtonStyle(Variant).TextColor
                end
                LabelRegistry.TextTransparency = function()
                    return Library:GetButtonStyle(Variant).TextTransparency
                end
                Library.Registry[BtnLabel] = LabelRegistry

                local StrokeRegistry = Library.Registry[OutlineStroke] or {}
                StrokeRegistry.Color = function()
                    return Library:GetButtonStyle(Variant).OutlineColor
                end
                StrokeRegistry.Transparency = function()
                    return Library:GetButtonStyle(Variant).OutlineTransparency
                end
                Library.Registry[OutlineStroke] = StrokeRegistry
            end

            local function ApplyErrorButtonStyle(Hovered: boolean?, Animate: boolean?)
                UpdateErrorButtonStyleRegistry()
                ApplyButtonVisual(
                    TextBtn,
                    OutlineStroke,
                    BtnLabel,
                    Variant,
                    false,
                    Hovered,
                    Animate,
                    "LoadingError"
                )
            end

            ApplyErrorButtonStyle(false, false)

            TextBtn.MouseEnter:Connect(function()
                ApplyErrorButtonStyle(true, true)
            end)
            TextBtn.MouseLeave:Connect(function()
                ApplyErrorButtonStyle(false, true)
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if ButtonInfo.Callback then
                    Library:SafeCallback(ButtonInfo.Callback, Loading)
                end
            end)
        end

        Loading:UpdateLayout()
    end

    
    function Loading:Destroy()
        if Loading.Destroyed then
            return
        end

        if RotationTween then
            StopTween(RotationTween, true)
            RotationTween = nil
        end

        ScreenGui:Destroy()
        Loading.Destroyed = true
        Library.ActiveLoading = nil

        if Library.Toggle and Library.Toggled == false and Library.Unloaded ~= true then
            Library:Toggle(true)
        end
    end

    Loading.Continue = Loading.Destroy;

    if Library.Toggle and Library.Toggled and Library.Unloaded ~= true then
        Library:Toggle(false)
    end

    Loading:SetCurrentStep(Loading.CurrentStep)

    Library.ActiveLoading = Loading
    return Loading
end

local DeclarativeElementMethods = {
    button = "AddButton",
    checkbox = "AddCheckbox",
    divider = "AddDivider",
    dropdown = "AddDropdown",
    image = "AddImage",
    input = "AddInput",
    label = "AddLabel",
    slider = "AddSlider",
    toggle = "AddToggle",
    uipassthrough = "AddUIPassthrough",
    video = "AddVideo",
    viewport = "AddViewport",
}

local DeclarativeTypeAliases = {
    action = "button",
    check = "checkbox",
    select = "dropdown",
    separator = "divider",
    text = "label",
    textbox = "input",
    ui = "uipassthrough",
}

local function CloneDefinition(Definition)
    if typeof(Definition) ~= "table" then
        return Definition
    end

    return table.clone(Definition)
end

local function ForEachDefinition(Definitions, Callback)
    if Definitions == nil then
        return
    end

    assert(typeof(Definitions) == "table", "Declarative collections must be tables")

    local SequentialCount = #Definitions
    for Index = 1, SequentialCount do
        Callback(Index, Definitions[Index])
    end

    for Key, Definition in Definitions do
        local IsSequentialKey = typeof(Key) == "number" and Key % 1 == 0 and Key >= 1 and Key <= SequentialCount
        if not IsSequentialKey then
            Callback(Key, Definition)
        end
    end
end

local function NormalizeElementType(ElementType)
    assert(typeof(ElementType) == "string", "Every element needs a Type or Kind")

    local Normalized = ElementType:lower():gsub("[%s_%-]", "")
    return DeclarativeTypeAliases[Normalized] or Normalized
end

function Library:Create(AppInfo)
    assert(typeof(AppInfo) == "table", "Library:Create expects a configuration table")

    local WindowInfo = CloneDefinition(AppInfo.Window or AppInfo)
    local Theme = AppInfo.Theme or WindowInfo.Theme

    WindowInfo.Window = nil
    WindowInfo.Theme = nil
    WindowInfo.Tabs = nil
    WindowInfo.Pages = nil
    WindowInfo.OnReady = nil

    if Theme ~= nil then
        Library:SetTheme(Theme)
    end

    WindowInfo.Title = WindowInfo.Title or "MonHub"
    WindowInfo.Footer = WindowInfo.Footer or ""
    WindowInfo.Font = WindowInfo.Font or Library.Scheme.Font
    WindowInfo.CornerRadius = WindowInfo.CornerRadius or Library.CornerRadius
    if WindowInfo.EnableSidebarResize == nil then
        WindowInfo.EnableSidebarResize = true
    end

    local App = {
        Destroyed = false,
        Library = Library,
        Window = nil,
        Tabs = {},
        Pages = nil,
        Groups = {},
        Sections = nil,
        Refs = {},
        All = {},
        AllTabs = {},
        AllGroups = {},
    }
    App.Pages = App.Tabs
    App.Sections = App.Groups

    local AutoId = 0
    local function NextId(Prefix)
        AutoId += 1
        return string.format("__obsidian_%s_%d", Prefix, AutoId)
    end

    local function RegisterRef(Id, Value)
        if Id == nil then
            return
        end

        assert(App.Refs[Id] == nil, string.format("Duplicate declarative Id %q", tostring(Id)))
        App.Refs[Id] = Value
    end

    local function RegisterElement(Element, ExplicitId)
        table.insert(App.All, Element)
        RegisterRef(ExplicitId, Element)
    end

    function App:Get(Id)
        return App.Refs[Id]
    end

    function App:Toggle(Value)
        return App.Window:Toggle(Value)
    end

    function App:Notify(...)
        return Library:Notify(...)
    end

    function App:Destroy()
        if App.Destroyed then
            return
        end

        App.Destroyed = true
        Library:Unload()
    end

    local Window = Library:CreateWindow(WindowInfo)
    App.Window = Window
    Window.AddPage = Window.AddTab

    local function BuildAddons(Element, Addons, ParentType)
        ForEachDefinition(Addons, function(Key, RawAddon)
            assert(typeof(RawAddon) == "table", "Addon definitions must be tables")

            local AddonInfo = CloneDefinition(RawAddon)
            local AddonType = NormalizeElementType(AddonInfo.Type or AddonInfo.Kind)
            local ExplicitId = AddonInfo.Id or AddonInfo.ID or AddonInfo.Idx or AddonInfo.Key
            local InternalId = ExplicitId or NextId(AddonType)

            AddonInfo.Type = nil
            AddonInfo.Kind = nil
            AddonInfo.Id = nil
            AddonInfo.ID = nil
            AddonInfo.Idx = nil
            AddonInfo.Key = nil
            AddonInfo.Callback = AddonInfo.Callback or AddonInfo.OnChanged

            if AddonType == "keypicker" then
                AddonInfo.Clicked = AddonInfo.Clicked or AddonInfo.OnClick
                if ParentType == "button" and AddonInfo.Mode == nil then
                    AddonInfo.Mode = "Press"
                end
                assert(Element.AddKeyPicker, "This element does not support KeyPicker addons")
                Element:AddKeyPicker(InternalId, AddonInfo)
            elseif AddonType == "colorpicker" then
                assert(Element.AddColorPicker, "This element does not support ColorPicker addons")
                Element:AddColorPicker(InternalId, AddonInfo)
            else
                error(string.format("Unknown addon type %q", tostring(AddonType)))
            end

            local Addon = Options[InternalId]
            if Addon then
                RegisterElement(Addon, ExplicitId or (typeof(Key) == "string" and Key or nil))
            end
        end)
    end

    local function BuildElement(Group, Key, RawElement)
        local ElementInfo
        if typeof(RawElement) == "string" then
            ElementInfo = { Type = "Label", Text = RawElement }
        else
            assert(typeof(RawElement) == "table", "Element definitions must be tables or label strings")
            ElementInfo = CloneDefinition(RawElement)
        end

        local ElementType = NormalizeElementType(ElementInfo.Type or ElementInfo.Kind)
        local MethodName = DeclarativeElementMethods[ElementType]
        assert(MethodName, string.format("Unknown element type %q", tostring(ElementType)))

        local ExplicitId = ElementInfo.Id or ElementInfo.ID or ElementInfo.Idx or ElementInfo.Key
        if ExplicitId == nil and typeof(Key) == "string" then
            ExplicitId = Key
        end
        local InternalId = ExplicitId or NextId(ElementType)
        local Addons = ElementInfo.Addons

        ElementInfo.Type = nil
        ElementInfo.Kind = nil
        ElementInfo.Id = nil
        ElementInfo.ID = nil
        ElementInfo.Idx = nil
        ElementInfo.Key = nil
        ElementInfo.Addons = nil
        ElementInfo.Text = ElementInfo.Text or ElementInfo.Label or ElementInfo.Name
        if ElementInfo.Default == nil and ElementInfo.Value ~= nil then
            ElementInfo.Default = ElementInfo.Value
        end

        if ElementType == "button" then
            ElementInfo.Func = ElementInfo.Func or ElementInfo.OnClick or ElementInfo.Callback
        else
            ElementInfo.Callback = ElementInfo.Callback or ElementInfo.OnChanged
        end

        local Element
        if ElementType == "divider" then
            Element = Group:AddDivider(ElementInfo)
        else
            Element = Group[MethodName](Group, InternalId, ElementInfo)
        end

        if Element then
            RegisterElement(Element, ExplicitId)
            BuildAddons(Element, Addons, ElementType)
        end
    end

    local Tabs = AppInfo.Tabs or AppInfo.Pages or WindowInfo.Tabs or WindowInfo.Pages
    ForEachDefinition(Tabs, function(TabKey, RawTab)
        local TabInfo = if typeof(RawTab) == "string" then { Name = RawTab } else CloneDefinition(RawTab)
        assert(typeof(TabInfo) == "table", "Tab definitions must be tables or strings")

        local TabName = TabInfo.Name or TabInfo.Title or (typeof(TabKey) == "string" and TabKey) or "Tab"
        local TabId = TabInfo.Id or TabInfo.ID or (typeof(TabKey) == "string" and TabKey) or TabName
        local Tab = Window:AddTab({
            Name = TabName,
            Icon = TabInfo.Icon,
            Description = TabInfo.Description,
            Order = TabInfo.Order,
        })

        App.Tabs[TabId] = Tab
        table.insert(App.AllTabs, Tab)

        local Groups = TabInfo.Groups or TabInfo.Sections
        ForEachDefinition(Groups, function(GroupKey, RawGroup)
            local GroupInfo = if typeof(RawGroup) == "string" then { Name = RawGroup } else CloneDefinition(RawGroup)
            assert(typeof(GroupInfo) == "table", "Group definitions must be tables or strings")

            local GroupName = GroupInfo.Name or GroupInfo.Title or (typeof(GroupKey) == "string" and GroupKey) or "Section"
            local Side = GroupInfo.Side
            local SideIndex = if Side == 2 or (typeof(Side) == "string" and Side:lower() == "right") then 2 else 1
            local Group = Tab:AddGroupbox({
                Side = SideIndex,
                Name = GroupName,
                IconName = GroupInfo.Icon or GroupInfo.IconName,
                Visible = GroupInfo.Visible,
                Collapsed = GroupInfo.Collapsed,
                DisableCollapsing = GroupInfo.DisableCollapsing,
            })

            local GroupId = GroupInfo.Id or GroupInfo.ID or (typeof(GroupKey) == "string" and GroupKey)
            local GroupPath = GroupId or string.format("%s/%s", tostring(TabId), GroupName)
            App.Groups[GroupPath] = Group
            table.insert(App.AllGroups, Group)

            local Elements = GroupInfo.Elements or GroupInfo.Controls or GroupInfo.Items
            ForEachDefinition(Elements, function(ElementKey, ElementInfo)
                BuildElement(Group, ElementKey, ElementInfo)
            end)
        end)
    end)

    if AppInfo.OnReady then
        Library:SafeCallback(AppInfo.OnReady, App)
    end

    return App
end

function Library:Mount(AppInfo)
    return Library:Create(AppInfo)
end

function Library.create(First, Second)
    return Library:Create(if First == Library then Second else First)
end

Library.mount = Library.create

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList = GetPlayers()
    local ExcludedPlayerList = table.clone(PlayerList)
    local LocalPlayerIndex = table.find(ExcludedPlayerList, LocalPlayer)
    if LocalPlayerIndex then
        table.remove(ExcludedPlayerList, LocalPlayerIndex)
    end
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

function Library:Unload()
    if Library.Unloaded then
        return
    end

    Library.Unloaded = true
    SearchRequestId += 1
    Library:ClearNotifications()
    if Library.Watermark then Library.Watermark:Destroy() end

    for _, TweenSlots in Library.ActiveTweens do
        for _, Entry in TweenSlots do
            StopTween(Entry.Tween, true)
        end
    end
    table.clear(Library.ActiveTweens)
    table.clear(Library.Registry)
    table.clear(Library.ThemeListeners)
    table.clear(RevealTokens)
    table.clear(RevealTargets)


    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)

        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    
    local UnloadCallbacks = table.clone(Library.UnloadSignals)
    table.clear(Library.UnloadSignals)
    for _, Callback in UnloadCallbacks do

        if Callback then
            Library:SafeCallback(Callback)
        end
    end

    
    for _, Tab in table.clone(Library.Tabs) do
        if Tab and Tab.Destroy then
            Library:SafeCallback(Tab.Destroy, Tab)
        end
    end

    for Index = #Tooltips, 1, -1 do
        local Tooltip = table.remove(Tooltips, Index)

        if Tooltip and Tooltip.Destroy then
            Library:SafeCallback(Tooltip.Destroy, Tooltip)
        end
    end

    if Library.ActiveLoading then
        Library.ActiveLoading:Destroy()
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    
    table.clear(Library.Registry)
    Library.ThemeErrors = {}

    table.clear(Options)
    table.clear(Toggles)
    table.clear(Buttons)
    table.clear(Labels)
    table.clear(Tooltips)

    table.clear(Library.Tabs)
    table.clear(Library.TabButtons)

    table.clear(Library.Scales)
    table.clear(Library.ScalesOffset)
    table.clear(Library.ScaleMultipliers)

    table.clear(Library.Corners)
    table.clear(Library.SpecificCorners)

    table.clear(Library.Notifications)
    table.clear(Library.Dialogues)
    table.clear(Library.DraggableElements)
    table.clear(Library.KeybindToggles)
    table.clear(Library.DependencyBoxes)

    table.clear(ActiveTabTweens)
    Library:ClearTextBoundsCache()
    
    Library.Toggle = function(...) end
    Library.Window = nil
    Library.ScreenGui = nil
    Library.WindowContainer = nil
    Library.KeybindFrame = nil
    Library.KeybindContainer = nil
    Library.ActiveTab = nil
    Library.LastSearchTab = nil
    Library.ActiveDialog = nil
    Library.ActiveLoading = nil
    Library.CantDragForced = false

    if getgenv().Library == Library then
        getgenv().Library = nil
    end
end

local DefaultFont, DefaultFontError = Library:LoadCustomFont(
    Library.DefaultFontName,
    Library.DefaultFontURL,
    Library.DefaultFontWeight
)
Library.DefaultFont = DefaultFont or Font.fromEnum(Enum.Font.GothamMedium)
Library.DefaultFontError = DefaultFontError
Library.CurrentFontName = DefaultFontError and "Gotham" or "Inter"
Library:SetThemeFont(Library.DefaultFont)

getgenv().Library = Library
return Library
