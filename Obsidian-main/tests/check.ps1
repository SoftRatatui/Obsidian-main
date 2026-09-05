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
Write-Output "Compiled $($taskFiles.Count) Luau files"
