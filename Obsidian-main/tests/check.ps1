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
function HttpService:JSONEncode(Value)
    jsonSequence += 1
    local Key = "json:" .. tostring(jsonSequence)
    storedJson[Key] = Value
    return Key
end
function HttpService:JSONDecode(Value)
    assert(storedJson[Value], "invalid json")
    return storedJson[Value]
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
local function writefile(Path, Content) files[Path] = Content end
local function delfile(Path) assert(files[Path] ~= nil, "missing file"); files[Path] = nil end
local globalEnvironment = {}
local function getgenv() return globalEnvironment end
'@
$taskSaveSource += "`nlocal SaveManager = (function()`n$taskSaveManagerSource`nend)()`n"
$taskSaveSource += "local Run = (function()`n$taskSaveManagerSpec`nend)()`nRun(SaveManager, { files = files, folders = folders, storedJson = storedJson, UDim2 = UDim2, Color3 = Color3 })`n"
$taskThemeManagerSource = [IO.File]::ReadAllText((Join-Path $taskRoot 'addons/ThemeManager.lua'))
$taskThemeManagerSpec = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ThemeManagerPersistence.spec.luau'))
$taskSaveSource += "local ThemeManager = (function()`n$taskThemeManagerSource`nend)()`n"
$taskSaveSource += "local RunThemes = (function()`n$taskThemeManagerSpec`nend)()`nRunThemes(ThemeManager, { files = files, folders = folders, Color3 = Color3 })`n"
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
