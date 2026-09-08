param(
    [string]$Compiler = 'luau-compile',
    [string]$Runtime = 'luau'
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskFiles = Get-ChildItem -LiteralPath $taskRoot -Recurse -File | Where-Object { $_.Extension -in '.lua', '.luau' -and $_.FullName -notlike '*\.vscode\*' }
foreach ($taskFile in $taskFiles) {
    & $Compiler --null $taskFile.FullName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed: $($taskFile.FullName)"
    }
}
& $Runtime (Join-Path $PSScriptRoot 'CollectionModel.spec.luau')
if ($LASTEXITCODE -ne 0) {
    throw 'Collection regression tests failed'
}
$taskMock = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'RobloxMock.luau'))
$taskSource = "local Mock = (function()`n$taskMock`nend)()`n"
foreach ($taskGlobal in @('game', 'Instance', 'Enum', 'UDim', 'UDim2', 'Vector2', 'Color3', 'Font', 'TweenInfo', 'ColorSequence', 'ColorSequenceKeypoint', 'NumberSequence', 'NumberSequenceKeypoint', 'typeof', 'task')) {
    $taskSource += "local $taskGlobal = Mock.$taskGlobal`n"
}
$taskSource += "local Modules = {}`nlocal getgenv = function() return {} end`n"
foreach ($taskModule in @('AssetCatalog', 'ImageGallery', 'ImagePreview', 'TextureGallery', 'CollectionModel', 'DashboardWindow', 'ThemeManager')) {
    $taskModuleSource = [IO.File]::ReadAllText((Join-Path $taskRoot "addons/$taskModule.lua"))
    $taskSource += "Modules.$taskModule = (function()`n$taskModuleSource`nend)()`n"
}
$taskLibrarySource = [IO.File]::ReadAllText((Join-Path $taskRoot 'Library.lua'))
$taskBoundsStart = $taskLibrarySource.IndexOf('local TextBoundsCache = {}')
$taskBoundsEnd = $taskLibrarySource.IndexOf('function Library:MouseIsOverFrame', $taskBoundsStart)
$taskBoundsSource = $taskLibrarySource.Substring($taskBoundsStart, $taskBoundsEnd - $taskBoundsStart)
$taskSource += @'
local function CreateTextBounds()
    local State = { Calls = 0, Destroyed = 0, Time = 0 }
    local Library = { Scheme = { Font = {} } }
    local os = { clock = function() return State.Time end }
    local function GetViewportSize() return Vector2.new(400, 800) end
    local Instance = { new = function()
        if State.FailCreate then error("params unavailable") end
        return { Destroy = function() State.Destroyed += 1 end }
    end }
    local TextService = {}
    function TextService:GetTextBoundsAsync(Params)
        State.Calls += 1
        if State.Fail then error("Temp read failed.") end
        return Vector2.new(40, 18)
    end
    function TextService:GetTextSize(Text)
        State.PlainText = Text
        if State.FailFallback then error("text service unavailable") end
        return Vector2.new(55, 20)
    end
'@
$taskSource += "`n$taskBoundsSource`nreturn Library, State`nend`n"
$taskBoundsSpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'TextBounds.spec.luau'))
$taskFontStart = $taskLibrarySource.IndexOf('local function EnsureFontFolder(')
$taskFontEnd = $taskLibrarySource.IndexOf('function Library:SetThemeFont(', $taskFontStart)
$taskFontSource = $taskLibrarySource.Substring($taskFontStart, $taskFontEnd - $taskFontStart)
$taskSource += @'
local function CreateFontLoader()
    local State = { Destroyed = 0 }
    local Library = {}
    local function IsFunction(Value) return type(Value) == "function" end
    local function NativeIsFolder()
        if State.FolderError then error("filesystem denied") end
        return true
    end
    local function NativeMakeFolder() end
    local function NativeIsFile()
        if State.FileError then error("file access denied") end
        return false
    end
    local function NativeWriteFile() end
    local function NativeGetCustomAsset(Path) return Path end
    local function IsFontData() return true end
    local function RequestGet() return true, "font binary" end
    local function ResolveFontWeight() return 500, Enum.FontWeight.Medium end
    local HttpService = { JSONEncode = function()
        if State.JSONError then error("cannot encode") end
        return "metadata"
    end }
    local Font = { new = function() return { _type = "Font" } end }
    local Instance = { new = function() return { Destroy = function() State.Destroyed += 1 end } end }
    local TextService = { GetTextBoundsAsync = function()
        if State.FontError then error("Temp read failed.") end
        return Vector2.new(18, 16)
    end }
'@
$taskSource += "`n$taskFontSource`nreturn Library, State`nend`n"
$taskSource += "local RunBounds = (function()`n$taskBoundsSpec`nend)()`nRunBounds(CreateTextBounds, CreateFontLoader)`n"
$taskHostStart = $taskLibrarySource.IndexOf('function Library:CreateAddonWindow(Info)')
$taskHostEnd = $taskLibrarySource.IndexOf('function Library:MakeCover', $taskHostStart)
$taskHostSource = $taskLibrarySource.Substring($taskHostStart, $taskHostEnd - $taskHostStart)
$taskSource += "Modules.HostLibrary = Mock.HostLibrary()`nlocal Library = Modules.HostLibrary`nlocal workspace = Mock.Workspace`nlocal function New(Class, Properties) return Mock.New(Library, Class, Properties) end`nlocal function GetViewportSize() return workspace.CurrentCamera.ViewportSize end`nlocal function ClampGuiToViewport() end`n$taskHostSource`n"
$taskRegistryStart = $taskLibrarySource.IndexOf('function Library:AddToRegistry(')
$taskRegistryEnd = $taskLibrarySource.IndexOf('function Library:RefreshThemeState()', $taskRegistryStart)
$taskRegistrySource = $taskLibrarySource.Substring($taskRegistryStart, $taskRegistryEnd - $taskRegistryStart)
$taskThemeStart = $taskLibrarySource.IndexOf('function Library:ResolveThemeName(')
$taskThemeEnd = $taskLibrarySource.IndexOf('function Library:SetFont(', $taskThemeStart)
$taskThemeSource = $taskLibrarySource.Substring($taskThemeStart, $taskThemeEnd - $taskThemeStart)
$taskSource += "local function GetSchemeValue(Key) return Library.Scheme[Key] end`nlocal function StopTween(Tween) Tween:Cancel() end`nLibrary.ActiveTweens = {}`nLibrary.ColorRevision = 0`n$taskRegistrySource`nlocal ThemeAliases = {}`n$taskThemeSource`n"
$taskOverlayStart = $taskLibrarySource.IndexOf('local function NotificationViewport()')
$taskOverlayEnd = $taskLibrarySource.IndexOf('function Library:CreateWindow(', $taskOverlayStart)
$taskOverlaySource = $taskLibrarySource.Substring($taskOverlayStart, $taskOverlayEnd - $taskOverlayStart)
$taskLabelStart = $taskLibrarySource.IndexOf('function Library:AddDraggableLabel(')
$taskLabelEnd = $taskLibrarySource.IndexOf('function Library:AddDraggableButton(', $taskLabelStart)
$taskLabelSource = $taskLibrarySource.Substring($taskLabelStart, $taskLabelEnd - $taskLabelStart)
$taskOverlayStyle = [regex]::Match($taskLibrarySource, '(?s)NotificationStyle = (\{.*?\n    \}),').Groups[1].Value
$taskSource += @'
local function CreateOverlayLibrary()
    local Library = Mock.HostLibrary()
    local ScreenGui = Library.ScreenGui
    local NotificationArea = Mock.Instance.new("Frame")
    local NotifyOrder, Scheduled = {}, {}
    local SoundService = Mock.Instance.new("SoundService")
    local TweenService = Mock.game:GetService("TweenService")
    local task = table.clone(Mock.task)
    function task.delay(_, Callback)
        local Job = { Callback = Callback }
        table.insert(Scheduled, Job)
        return Job
    end
    function task.cancel(Job) Job.Cancelled = true end
    Library.Notifications = {}
    Library.NotifySide = "Right"
    Library.DPIScale = 1
    Library.CornerRadius = 5
    Library.Scales, Library.ScaleMultipliers, Library.ScalesOffset, Library.DraggableElements = {}, {}, {}, {}
    Library.NotifyTweenInfo = Mock.TweenInfo.new(0.1)
    Library.NotifyCloseTweenInfo = Mock.TweenInfo.new(0.1)
    function Library:GetTextBounds(Text, _, Size, Width)
        local Lines = math.max(1, math.ceil(#Text * Size / 2 / Width))
        return math.min(Width, #Text * Size / 2), Lines * (Size + 2)
    end
    function Library:GiveSignal(Connection) return Connection end
    function Library:ReleaseRegistryTree(Root)
        self:RemoveFromRegistry(Root)
        for _, Child in Root:GetDescendants() do self:RemoveFromRegistry(Child) end
    end
    local function New(Class, Properties)
        local Object = Mock.New(Library, Class, Properties)
        if Class == "UIScale" then Object.Scale = Properties.Scale or 1 end
        return Object
    end
    function Library:AddOutline(Root) return New("UIStroke", { Parent = Root }) end
    local function Trim(Text) return Text:match("^%s*(.-)%s*$") end
    local function PositionDraggable(Root, Position) Root.Position = Position end
'@
$taskSource += "`nLibrary.NotificationStyle = $taskOverlayStyle`n$taskLabelSource`n$taskOverlaySource`nreturn Library, Scheduled`nend`n"
$taskOverlaySpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Overlays.spec.luau'))
$taskSource += "local RunOverlays = (function()`n$taskOverlaySpec`nend)()`nRunOverlays(CreateOverlayLibrary, Mock)`n"
$taskDropdownStart = $taskLibrarySource.IndexOf('    function Funcs:AddDropdown(')
$taskDropdownMethods = ''
foreach ($taskRange in @(@('        function Dropdown:Display()', '        function Dropdown:OnChanged'), @('        function Dropdown:RefreshTypography()', '        function Dropdown:UpdateColors'), @('        function Dropdown:SetText(', '        function Dropdown:SetDragSelect'))) {
    $taskStart = $taskLibrarySource.IndexOf($taskRange[0], $taskDropdownStart)
    $taskEnd = $taskLibrarySource.IndexOf($taskRange[1], $taskStart)
    $taskDropdownMethods += $taskLibrarySource.Substring($taskStart, $taskEnd - $taskStart)
}
$taskSource += @'
local function CreateDropdown(Info)
    local Library = Mock.HostLibrary()
    local ControlHeight, DropdownLabelRow, ItemHeight = 28, 18, 24
    local HasLabel = false
    local Holder = Mock.Instance.new("Frame")
    local DisplayContainer = Mock.Instance.new("Frame")
    local DisplayButton = Mock.Instance.new("TextButton")
    local DisplayImage = Mock.Instance.new("ImageLabel")
    local Label = Mock.Instance.new("TextLabel")
    local SearchBox = Mock.Instance.new("TextBox")
    local Pool = { { Button = Mock.Instance.new("TextButton") } }
    local Groupbox = { Resize = function() end }
    local View = { Button = DisplayButton, Row = Pool[1].Button, Holder = Holder, Display = DisplayContainer, Label = Label, FontHeight = 14 }
    function Library:GetTextBounds() return 20, View.FontHeight end
    local Dropdown = { Values = { "Head" }, ValueImages = {} }
    local function IsSequentialArray(Values) return #Values > 0 end
    local function GetValueImage(Value)
        return Dropdown.ValueImages[Value] and { Url = Dropdown.ValueImages[Value] } or nil
    end
'@
$taskSource += "`n$taskDropdownMethods`nreturn Dropdown, View`nend`n"
$taskTypographySpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Typography.spec.luau'))
$taskSource += "local RunTypography = (function()`n$taskTypographySpec`nend)()`nRunTypography(CreateDropdown, Mock)`n"
$taskEditorStart = $taskLibrarySource.IndexOf('    function Funcs:AddImageGrid(')
$taskDragStart = $taskLibrarySource.IndexOf('function Library:RegisterImageGrid(')
$taskDragEnd = $taskLibrarySource.IndexOf('local function CopyOptionValue(', $taskDragStart)
$taskDragMethods = $taskLibrarySource.Substring($taskDragStart, $taskDragEnd - $taskDragStart)
$taskEditorEnd = $taskLibrarySource.IndexOf('    function Funcs:AddDependencyBox()', $taskEditorStart)
$taskEditorMethods = $taskLibrarySource.Substring($taskEditorStart, $taskEditorEnd - $taskEditorStart)
$taskHiddenStart = $taskLibrarySource.IndexOf('local function CopyOptionValue(')
$taskHiddenEnd = $taskLibrarySource.IndexOf('local BaseGroupbox = {}', $taskHiddenStart)
$taskHiddenMethods = $taskLibrarySource.Substring($taskHiddenStart, $taskHiddenEnd - $taskHiddenStart)
$taskPopupStart = $taskLibrarySource.IndexOf('    function Window:AddDialog(')
$taskPopupEnd = $taskLibrarySource.IndexOf('    function Window:Toggle(', $taskPopupStart)
$taskPopupMethods = $taskLibrarySource.Substring($taskPopupStart, $taskPopupEnd - $taskPopupStart)
$taskSource += @'
local function CreateEditor()
    local Vector2 = {}
    function Vector2.new(X, Y)
        return setmetatable({ X = X, Y = Y, Magnitude = math.sqrt(X * X + Y * Y) }, {
            __sub = function(A, B) return Vector2.new(A.X - B.X, A.Y - B.Y) end,
        })
    end
    local Library = Mock.HostLibrary()
    local ScreenGui = Library.ScreenGui
    local Options, Toggles = {}, {}
    Library.Options, Library.Toggles = Options, Toggles
    Library.DPIScale, Library.Corners, Library.Dialogues = 1, {}, {}
    local function New(Class, Properties)
        local Object = Mock.New(Library, Class, Properties)
        if Class == "UIListLayout" then Object.AbsoluteContentSize = Vector2.new(300, 100) end
        return Object
    end
    function Library:SafeCallback(Callback, ...) if Callback then return Callback(...) end end
    function Library:AddOutline(Root) return New("UIStroke", { Parent = Root }) end
    function Library:GiveSignal(Connection) return Connection end
    function Library:GetTextBounds() return 100, 16 end
    function Library:ReleaseRegistryTree(Root)
        self:RemoveFromRegistry(Root)
        for _, Child in Root:GetDescendants() do self:RemoveFromRegistry(Child) end
    end
    local Funcs = {}
    local BaseGroupbox = { __index = Funcs }
    function Funcs:AddAddon(Id, Addon, Info) return Addon.CreateEmbedded(Library, self, Id, Info) end
    function Funcs:AddUIPassthrough(Id, Info)
        Info.Instance.Parent = self.Container
        local Element = {}
        function Element:Destroy() Info.Instance:Destroy(); Options[Id] = nil end
        function Element:SetVisible(Value) Info.Instance.Visible = Value end
        function Element:SetHeight() end
        Options[Id] = Element
        return Element
    end
    function Funcs:AddSlider(Id, Info)
        local Slider = { Value = Info.Default, Disabled = false }
        function Slider:SetValue(Value) self.Value = math.clamp(Value, Info.Min, Info.Max); Info.Callback(self.Value) end
        function Slider:SetDisabled(Value) self.Disabled = Value end
        function Slider:Destroy() Options[Id] = nil end
        Options[Id] = Slider
        return Slider
    end
    local Window, WindowInfo = {}, { CornerRadius = 4 }
    local MainFrame = New("Frame", { Parent = Library.ScreenGui })
    local UserInputService = { InputBegan = Mock.Signal(), InputChanged = Mock.Signal(), InputEnded = Mock.Signal(), WindowFocusReleased = Mock.Signal() }
    function Library:MouseIsOverFrame(Object, Point)
        local Pos, Size = Object.AbsolutePosition, Object.AbsoluteSize
        return Point.X >= Pos.X and Point.Y >= Pos.Y and Point.X <= Pos.X + Size.X and Point.Y <= Pos.Y + Size.Y
    end
    local Templates = { Dialog = { Title = "Dialog", Description = "", FooterButtons = {} } }
    function Library:Validate(Info, Template)
        local Result = table.clone(Template)
        for Key, Value in Info or {} do Result[Key] = Value end
        return Result
    end
    Library.DialogOpenAnimationInfo, Library.DialogCloseAnimationInfo = TweenInfo.new(0.1), TweenInfo.new(0.1)
    Library.DialogOverlayOpenAnimationInfo, Library.DialogOverlayCloseAnimationInfo = TweenInfo.new(0.1), TweenInfo.new(0.1)
'@
$taskSource += "`n$taskDragMethods`n$taskHiddenMethods`n$taskEditorMethods`n$taskPopupMethods`n"
$taskSource += @'
    local Groupbox = setmetatable({ Elements = {}, Container = New("Frame", { Parent = MainFrame }), Resize = function() end }, BaseGroupbox)
    return Library, Groupbox, Window, UserInputService
end
'@
$taskEditorSpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'EditorControls.spec.luau'))
$taskSource += "`nlocal RunEditor = (function()`n$taskEditorSpec`nend)()`nRunEditor(CreateEditor, Mock, Modules)`n"
$taskSpecs = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Addons.spec.luau'))
$taskSource += "local Run = (function()`n$taskSpecs`nend)()`nRun(Modules, Mock)`n"
$taskGenerated = Join-Path ([IO.Path]::GetTempPath()) ("monhub-addons-" + [guid]::NewGuid().ToString() + '.luau')
try {
    [IO.File]::WriteAllText($taskGenerated, $taskSource)
    & $Runtime $taskGenerated
    if ($LASTEXITCODE -ne 0) {
        throw 'Addon contract tests failed'
    }
} finally {
    Remove-Item -LiteralPath $taskGenerated -ErrorAction SilentlyContinue
}
$taskSaveManagerSource = [IO.File]::ReadAllText((Join-Path $taskRoot 'addons/SaveManager.lua'))
$taskSaveManagerSpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'SaveManager.spec.luau'))
$taskSaveSource = @'
local storedJson = {}
local jsonSequence = 0
local files = {}
local folders = {}
local faults = {}
local function typeof(Value)
    return type(Value) == "table" and Value._type or type(Value)
end
local UDim2 = {}
function UDim2.new(XScale, XOffset, YScale, YOffset)
    return { _type = "UDim2", X = { Scale = XScale, Offset = XOffset }, Y = { Scale = YScale, Offset = YOffset } }
end
local Color3 = {}
function Color3.fromHex(Hex)
    Hex = tostring(Hex):gsub("#", "")
    assert(Hex:match("^[%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F]$"), "invalid hex")
    local Color = { _type = "Color3", Hex = string.upper(Hex) }
    function Color:ToHex() return self.Hex end
    return Color
end
local HttpService = {}
local function CopyJSON(Value)
    if type(Value) ~= "table" then return Value end
    assert(Value._type == nil, "unsupported JSON value")
    local Copy = {}
    for Key, Item in Value do Copy[Key] = CopyJSON(Item) end
    return Copy
end
function HttpService:JSONEncode(Value)
    jsonSequence += 1
    local Key = "json:" .. tostring(jsonSequence)
    storedJson[Key] = CopyJSON(Value)
    return Key
end
function HttpService:JSONDecode(Value)
    assert(storedJson[Value], "invalid json")
    return CopyJSON(storedJson[Value])
end
local game = { GetService = function(_, Name) assert(Name == "HttpService"); return HttpService end }
local function cloneref(Value) return Value end
local function isfolder(Path) return folders[Path] == true end
local function isfile(Path) return files[Path] ~= nil end
local function listfiles(Path)
    local Result = {}
    local Prefix = Path .. "/"
    for FilePath in files do
        if string.sub(FilePath, 1, #Prefix) == Prefix and not string.find(string.sub(FilePath, #Prefix + 1), "/", 1, true) then
            table.insert(Result, FilePath)
        end
    end
    return Result
end
local function makefolder(Path) folders[Path] = true end
local function readfile(Path) assert(files[Path] ~= nil, "missing file"); return files[Path] end
local function writefile(Path, Content)
    assert(Path:match("%.json$") or Path:match("%.txt$"), "invalid argument #1 to 'writefile' (illegal path)")
    if faults.WritePath == Path then
        local Mode = faults.Mode
        faults.WritePath = nil
        files[Path] = "partial write"
        if Mode == "throw" then error("disk write failed after truncation") end
        return
    end
    files[Path] = Content
end
local function delfile(Path) assert(files[Path] ~= nil, "missing file"); files[Path] = nil end
local globalEnvironment = {}
local function getgenv() return globalEnvironment end
'@
$taskSaveSource += "`nlocal function CreateSaveManager()`n$taskSaveManagerSource`nend`nlocal SaveManager = CreateSaveManager()`n"
$taskCallbackStart = $taskLibrarySource.IndexOf('function Library:SafeCallback(')
$taskCallbackEnd = $taskLibrarySource.IndexOf('function GetOverlappingDraggable', $taskCallbackStart)
$taskCallbackSource = $taskLibrarySource.Substring($taskCallbackStart, $taskCallbackEnd - $taskCallbackStart)
$taskSaveSource += "local function BindCallbacks(Library)`n$taskCallbackSource`nend`n"
$taskSaveSource += "local Run = (function()`n$taskSaveManagerSpec`nend)()`nRun(SaveManager, { files = files, folders = folders, storedJson = storedJson, UDim2 = UDim2, Color3 = Color3, faults = faults, CreateSaveManager = CreateSaveManager, BindCallbacks = BindCallbacks })`n"
$taskThemeManagerSource = [IO.File]::ReadAllText((Join-Path $taskRoot 'addons/ThemeManager.lua'))
$taskThemeManagerSpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ThemeManagerPersistence.spec.luau'))
$taskSaveSource += "local ThemeManager = (function()`n$taskThemeManagerSource`nend)()`n"
$taskSaveSource += "local RunThemes = (function()`n$taskThemeManagerSpec`nend)()`nRunThemes(ThemeManager, { files = files, folders = folders, Color3 = Color3 })`n"
$taskExampleSource = [IO.File]::ReadAllText((Join-Path $taskRoot 'Example.lua'))
$taskLoaderStart = $taskExampleSource.IndexOf('local PRIMARY_REPOSITORY')
$taskLoaderEnd = $taskExampleSource.IndexOf('local Library, ActiveRepository', $taskLoaderStart)
$taskLoaderSource = $taskExampleSource.Substring($taskLoaderStart, $taskLoaderEnd - $taskLoaderStart)
$taskLoaderSpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Loader.spec.luau'))
$taskSaveSource += "local function CreateLoader(Request, HttpGet)`nlocal function getfenv() return { request = Request } end`nlocal game = { HttpGet = HttpGet }`n$taskLoaderSource`nreturn TryModule`nend`nlocal TestLoader = (function()`n$taskLoaderSpec`nend)()`nTestLoader(CreateLoader)`n"
$taskSaveGenerated = Join-Path ([IO.Path]::GetTempPath()) ("monhub-save-manager-" + [guid]::NewGuid().ToString() + '.luau')
try {
    [IO.File]::WriteAllText($taskSaveGenerated, $taskSaveSource)
    & $Runtime $taskSaveGenerated
    if ($LASTEXITCODE -ne 0) {
        throw 'SaveManager regression tests failed'
    }
} finally {
    Remove-Item -LiteralPath $taskSaveGenerated -ErrorAction SilentlyContinue
}
Write-Output "Compiled $($taskFiles.Count) Luau files"
