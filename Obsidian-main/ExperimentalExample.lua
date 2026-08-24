assert(type(loadstring) == "function", "ExperimentalExample.lua requires loadstring support.")

local REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local RELEASE_VERSION = "0.0.1-release-6"
local Environment = getfenv()
local NativeReadFile = type(Environment) == "table" and rawget(Environment, "readfile") or nil
local NativeIsFile = type(Environment) == "table" and rawget(Environment, "isfile") or nil

local function Load(Path)
    local Source
    if type(NativeReadFile) == "function" and type(NativeIsFile) == "function" and NativeIsFile(Path) then
        local Success, Result = pcall(NativeReadFile, Path)
        if Success and type(Result) == "string" and #Result > 0 then
            Source = Result
        end
    end
    if not Source then
        Source = game:HttpGet(REPOSITORY .. Path .. "?monhub=" .. RELEASE_VERSION)
    end
    local Chunk, CompileError = loadstring(Source)
    assert(Chunk, tostring(CompileError))
    return Chunk()
end

local Library = Load("Experimental.lua")
local Modules = Library.Experimental
local Players = game:GetService("Players")

Library.ForceCheckbox = true
Library.ShowToggleFrameInKeybinds = true
Library:SetClickSound(92679954573730, 0.24)

local Window = Library:CreateWindow({
    Title = "MonHub Experimental",
    Footer = "Experimental v0.0.1",
    Icon = "sparkles",
    Size = UDim2.fromOffset(900, 700),
    Center = true,
    AutoShow = true,
    IconOnlySidebar = true,
    SidebarCompactWidth = 68,
    NavigationButtonHeight = 46,
    NavigationIconSize = 22,
    ResponsiveLayout = true,
    SingleColumnWidth = 620,
    ToggleKeybind = Enum.KeyCode.RightControl,
})

local Tabs = {
    Home = Window:AddTab({ Name = "Home", Icon = "house", Order = 1 }),
    Visuals = Window:AddTab({ Name = "Visuals", Icon = "scan-eye", Order = 2 }),
    Effects = Window:AddTab({ Name = "Effects", Icon = "sparkles", Order = 3 }),
    Settings = Window:AddTab({ Name = "Settings", Icon = "settings", Order = 4 }),
}

local HomePrimary = Tabs.Home:AddLeftGroupbox("Experimental build", "layers")
HomePrimary:AddLabel("A separate icon-rail build for testing the next MonHub layout.", true)
HomePrimary:AddButton({
    Text = "Show notification",
    Variant = "Primary",
    Icon = "bell",
    Func = function()
        Library:Notify({
            Title = "Experimental UI",
            Description = "The icon rail and visual addons are active.",
            Time = 3,
            Icon = "sparkles",
        })
    end,
})

local HomeStatus = Tabs.Home:AddRightGroupbox("Runtime", "activity")
HomeStatus:AddLabel("Build: " .. tostring(Modules.Build), true)
HomeStatus:AddLabel("Renderer: native viewport and shared ESP backend", true)
HomeStatus:AddLabel("Optional addons stay unloaded outside this entry point.", true)

local VisualControls = Tabs.Visuals:AddLeftGroupbox("R6 visual controls", "scan-eye")
local PreviewController
local PreviewSuccess, PreviewResult = pcall(function()
    return Library:CreateFixedR6Preview(Tabs.Visuals, {
        Name = "R6 visual preview",
        Target = Players.LocalPlayer,
        Enabled = true,
        Width = 292,
        Height = 446,
        Side = "Right",
        Alignment = "Center",
        Gap = 10,
        Box = true,
        Health = true,
        Gradient = true,
        DynamicBoxes = true,
        AutoRefresh = true,
    })
end)
if PreviewSuccess then
    PreviewController = PreviewResult
else
    warn("[MonHub Experimental] R6 preview unavailable: " .. tostring(PreviewResult))
end

VisualControls:AddToggle("ExperimentalPreviewEnabled", {
    Text = "R6 preview",
    Default = PreviewController ~= nil,
    Callback = function(Value)
        if PreviewController then
            PreviewController:SetEnabled(Value)
        end
    end,
})

VisualControls:AddToggle("ExperimentalPreviewBox", {
    Text = "Box",
    Default = true,
    Callback = function(Value)
        if PreviewController then
            PreviewController.Preview:SetBoxVisible(Value)
        end
    end,
})

VisualControls:AddToggle("ExperimentalPreviewDynamic", {
    Text = "Dynamic box",
    Default = true,
    Callback = function(Value)
        if PreviewController then
            PreviewController.Preview:SetDynamicBoxes(Value)
        end
    end,
})

VisualControls:AddToggle("ExperimentalPreviewName", {
    Text = "Name",
    Default = false,
    Callback = function(Value)
        if PreviewController then
            PreviewController.Preview:SetNameVisible(Value)
        end
    end,
})

VisualControls:AddToggle("ExperimentalPreviewDistance", {
    Text = "Distance",
    Default = false,
    Callback = function(Value)
        if PreviewController then
            PreviewController.Preview:SetDistanceVisible(Value)
        end
    end,
})

VisualControls:AddToggle("ExperimentalPreviewHealth", {
    Text = "Health bar",
    Default = true,
    Callback = function(Value)
        if PreviewController then
            PreviewController.Preview:SetHealthVisible(Value)
        end
    end,
})

VisualControls:AddToggle("ExperimentalPreviewGradient", {
    Text = "Two-color box",
    Default = true,
    Callback = function(Value)
        if PreviewController then
            PreviewController:SetGradientEnabled(Value)
        end
    end,
})

local PreviewColorA = Color3.fromRGB(128, 169, 207)
local PreviewColorB = Color3.fromRGB(198, 170, 224)
local PreviewColors = VisualControls:AddLabel("Preview colors")
PreviewColors:AddColorPicker("ExperimentalPreviewColorA", {
    Title = "First color",
    Default = PreviewColorA,
    Callback = function(Value)
        PreviewColorA = Value
        if PreviewController then
            PreviewController:SetColors(PreviewColorA, PreviewColorB)
        end
    end,
})
PreviewColors:AddColorPicker("ExperimentalPreviewColorB", {
    Title = "Second color",
    Default = PreviewColorB,
    Callback = function(Value)
        PreviewColorB = Value
        if PreviewController then
            PreviewController:SetColors(PreviewColorA, PreviewColorB)
        end
    end,
})

VisualControls:AddDropdown("ExperimentalPreviewSide", {
    Text = "Preview side",
    Values = { "Right", "Left", "Auto" },
    Default = "Right",
    Callback = function(Value)
        if PreviewController then
            PreviewController:SetPosition(Value, "Center")
        end
    end,
})

VisualControls:AddButton("Refresh R6 character", function()
    if PreviewController then
        PreviewController:RefreshCharacter()
    end
end)

local PreviewHelp = Tabs.Visuals:AddRightGroupbox("Preview behavior", "mouse-pointer-2")
PreviewHelp:AddLabel("Drag the R6 model to rotate it. Use the mouse wheel to zoom.", true)
PreviewHelp:AddLabel("Pass your live renderer as Renderer to use the exact production ESP path.", true)

local TrailController = Modules.CharacterTrail.Create({
    Target = Players.LocalPlayer,
    Enabled = false,
    TransparencyMin = 0.04,
    TransparencyMax = 0.18,
    AttachmentWidth = 1.6,
    Lifetime = 0.42,
    FaceCamera = true,
})
Library:OnUnload(function()
    TrailController:Destroy()
end)

local TextureGroup = Tabs.Effects:AddLeftGroupbox("Trail textures", "gallery-horizontal")
local TextureGallery = Library:CreateTextureGallery(TextureGroup, "ExperimentalTrailTextures", {
    Height = 302,
    Columns = 2,
    Items = Modules.TextureGallery.DefaultItems,
    Selected = "beam",
    OnSelected = function(Item)
        TrailController:SetTexture(Item.Texture)
        TrailController:SetColors(Item.ColorA, Item.ColorB)
    end,
})

local TrailControls = Tabs.Effects:AddRightGroupbox("Character trail", "sparkles")
TrailControls:AddToggle("ExperimentalTrailEnabled", {
    Text = "Trail enabled",
    Default = false,
    Callback = function(Value)
        TrailController:SetEnabled(Value)
    end,
})

TrailControls:AddDropdown("ExperimentalTrailPreset", {
    Text = "Style",
    Values = { "Soft", "Energy", "Plasma", "Minimal" },
    Default = "Soft",
    Callback = function(Value)
        TrailController:ApplyPreset(Value)
    end,
})

local TrailTransparencyA = 4
local TrailTransparencyB = 18
TrailControls:AddSlider("ExperimentalTrailTransparencyA", {
    Text = "Start transparency",
    Default = TrailTransparencyA,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(Value)
        TrailTransparencyA = Value
        TrailController:SetTransparency(TrailTransparencyA / 100, TrailTransparencyB / 100)
    end,
})
TrailControls:AddSlider("ExperimentalTrailTransparencyB", {
    Text = "End transparency",
    Default = TrailTransparencyB,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(Value)
        TrailTransparencyB = Value
        TrailController:SetTransparency(TrailTransparencyA / 100, TrailTransparencyB / 100)
    end,
})
TrailControls:AddSlider("ExperimentalTrailWidth", {
    Text = "Ribbon width",
    Default = 1.6,
    Min = 0.2,
    Max = 4,
    Rounding = 1,
    Suffix = " studs",
    Callback = function(Value)
        TrailController:SetAttachmentWidth(Value)
    end,
})
TrailControls:AddSlider("ExperimentalTrailLifetime", {
    Text = "Lifetime",
    Default = 0.42,
    Min = 0.08,
    Max = 1.5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(Value)
        TrailController:SetLifetime(Value)
    end,
})
TrailControls:AddToggle("ExperimentalTrailFaceCamera", {
    Text = "Face camera",
    Default = true,
    Callback = function(Value)
        TrailController:SetFaceCamera(Value)
    end,
})
TrailControls:AddButton("Clear trail segments", function()
    local Trail = TrailController:GetTrail()
    if Trail then
        Trail:Clear()
    end
end)

local InterfaceSettings = Tabs.Settings:AddLeftGroupbox("Interface", "panel-left")
InterfaceSettings:AddDropdown("ExperimentalTheme", {
    Text = "Theme",
    Values = { "Default", "Metal", "Midnight", "Steel", "Sage", "Ash" },
    Default = "Default",
    Callback = function(Value)
        Library:SetTheme(Value)
    end,
})
InterfaceSettings:AddDropdown("ExperimentalScale", {
    Text = "DPI scale",
    Values = { "85%", "90%", "100%", "110%" },
    Default = "100%",
    Callback = function(Value)
        Library:SetDPIScale(tonumber(Value:match("%d+")) / 100)
    end,
})
InterfaceSettings:AddButton({
    Text = "Unload",
    Variant = "Ghost",
    Icon = "x",
    Func = function()
        Library:Unload()
    end,
})

return {
    Library = Library,
    Window = Window,
    Tabs = Tabs,
    Trail = TrailController,
    TextureGallery = TextureGallery,
    R6Preview = PreviewController,
}
