local Workspace = game:GetService("Workspace")

local MonHubUI = {}

local function Value(Controller, Path, Fallback)
    local Current = Controller:Get(Path)
    if Current == nil then
        return Fallback
    end
    return Current
end

local function Toggle(Group, Prefix, Id, Text, Controller, Path)
    return Group:AddToggle(Prefix .. Id, {
        Text = Text,
        Default = Value(Controller, Path, false) == true,
        Callback = function(State)
            Controller:Set(Path, State)
        end,
    })
end

local function Slider(Group, Prefix, Id, Text, Controller, Path, Minimum, Maximum, Rounding, Suffix, Scale)
    Scale = Scale or 1
    return Group:AddSlider(Prefix .. Id, {
        Text = Text,
        Default = Value(Controller, Path, Minimum) * Scale,
        Min = Minimum * Scale,
        Max = Maximum * Scale,
        Rounding = Rounding,
        Suffix = Suffix,
        Callback = function(Number)
            Controller:Set(Path, Number / Scale)
        end,
    })
end

local function Dropdown(Group, Prefix, Id, Text, Controller, Path, Values)
    return Group:AddDropdown(Prefix .. Id, {
        Text = Text,
        Values = Values,
        Default = Value(Controller, Path, Values[1]),
        Callback = function(Selection)
            Controller:Set(Path, Selection)
        end,
    })
end

local function Color(ToggleObject, Prefix, Id, Title, Controller, Path)
    return ToggleObject:AddColorPicker(Prefix .. Id, {
        Title = Title,
        Default = Value(Controller, Path, Color3.new(1, 1, 1)),
        Callback = function(Selection)
            Controller:Set(Path, Selection)
        end,
    })
end

function MonHubUI.Mount(Library, Tab, Controller, Info)
    assert(type(Library) == "table", "Library is required.")
    assert(type(Tab) == "table", "A MonHub tab is required.")
    assert(type(Controller) == "table", "An ESP controller is required.")
    Info = Info or {}

    local Prefix = tostring(Info.Prefix or "UniversalESP_")
    local Handle = {
        Controller = Controller,
        Groups = {},
        Destroyed = false,
        OwnController = Info.OwnController == true,
        NPCContainer = Info.NPCContainer or Workspace,
        NPCInfo = Info.NPCInfo or {},
    }

    local General = Tab:AddLeftGroupbox(Info.GeneralTitle or "ESP", "scan-eye")
    local Filters = Tab:AddRightGroupbox("Filters", "list-filter")
    local Boxes = Tab:AddLeftGroupbox("Boxes", "box-select")
    local Text = Tab:AddRightGroupbox("Text", "type")
    local Health = Tab:AddLeftGroupbox("Health", "heart-pulse")
    local Tracers = Tab:AddRightGroupbox("Tracers", "git-branch")
    local Models = Tab:AddLeftGroupbox("Model visuals", "scan-line")
    local Colors = Tab:AddRightGroupbox("Colors", "palette")
    local Runtime = Tab:AddLeftGroupbox("Runtime", "gauge")
    local NPC = Tab:AddRightGroupbox("NPC tracking", "bot")

    Handle.Groups = {
        General = General,
        Filters = Filters,
        Boxes = Boxes,
        Text = Text,
        Health = Health,
        Tracers = Tracers,
        Models = Models,
        Colors = Colors,
        Runtime = Runtime,
        NPC = NPC,
    }

    local Master = Toggle(General, Prefix, "Enabled", "Enabled", Controller, "Enabled")
    Master:AddKeyPicker(Prefix .. "Keybind", {
        Text = "ESP",
        Default = Info.Keybind or "None",
        Mode = "Toggle",
        SyncToggleState = true,
    })
    local PlayersToggle = Toggle(General, Prefix, "Players", "Players", Controller, "Players")
    local NPCToggle = Toggle(General, Prefix, "NPCs", "NPCs", Controller, "NPCs")
    local PartsToggle = Toggle(General, Prefix, "Parts", "Wrapped parts", Controller, "Parts")
    Toggle(General, Prefix, "AliveCheck", "Alive check", Controller, "AliveCheck")
    Slider(General, Prefix, "MaxDistance", "Render distance", Controller, "MaxDistance", 100, 10000, 0, "m")
    Slider(General, Prefix, "TextDistance", "Text distance", Controller, "TextDistance", 50, 3000, 0, "m")

    Toggle(Filters, Prefix, "TeamCheck", "Team check", Controller, "TeamCheck")
    local TeamColorsToggle = Toggle(Filters, Prefix, "TeamColors", "Use team colors", Controller, "TeamColors")
    local VisibilityToggle = Toggle(Filters, Prefix, "VisibilityCheck", "Visibility check", Controller, "VisibilityCheck")
    Slider(Filters, Prefix, "VisibilityInterval", "Visibility interval", Controller, "VisibilityInterval", 0.02, 1, 2, "s")
    Toggle(Filters, Prefix, "IncludeLocalPlayer", "Include local player", Controller, "IncludeLocalPlayer")

    local BoxToggle = Toggle(Boxes, Prefix, "BoxEnabled", "Box", Controller, "Box.Enabled")
    Color(BoxToggle, Prefix, "EnemyColor", "Primary color", Controller, "Colors.Enemy")
    Color(BoxToggle, Prefix, "GradientColor", "Gradient color", Controller, "Colors.Gradient")
    Dropdown(Boxes, Prefix, "BoxStyle", "Style", Controller, "Box.Style", { "Corner", "Full", "3D" })
    Toggle(Boxes, Prefix, "DynamicBox", "Dynamic bounds", Controller, "Box.Dynamic")
    Toggle(Boxes, Prefix, "BoxGradient", "Gradient", Controller, "Box.Gradient")
    Toggle(Boxes, Prefix, "BoxRainbow", "Rainbow", Controller, "Box.Rainbow")
    Toggle(Boxes, Prefix, "BoxOutline", "Outline", Controller, "Box.Outline")
    Toggle(Boxes, Prefix, "BoxFill", "Fill", Controller, "Box.Fill")
    Slider(Boxes, Prefix, "BoxScale", "Scale", Controller, "Box.Scale", 0.6, 1.5, 2, "x")
    Slider(Boxes, Prefix, "BoxThickness", "Thickness", Controller, "Box.Thickness", 0.5, 4, 1, "px")
    Slider(Boxes, Prefix, "BoxTransparency", "Line opacity", Controller, "Box.Transparency", 0, 1, 0, "%", 100)
    Slider(Boxes, Prefix, "FillTransparency", "Fill opacity", Controller, "Box.FillTransparency", 0, 0.8, 0, "%", 100)
    Slider(Boxes, Prefix, "RainbowSpeed", "Rainbow speed", Controller, "Box.RainbowSpeed", 0.02, 1, 2, "x")

    local NameToggle = Toggle(Text, Prefix, "Name", "Name", Controller, "Text.Name")
    Toggle(Text, Prefix, "DisplayName", "Display name", Controller, "Text.DisplayName")
    Toggle(Text, Prefix, "TeamText", "Team", Controller, "Text.Team")
    Toggle(Text, Prefix, "Distance", "Distance", Controller, "Text.Distance")
    Toggle(Text, Prefix, "Tool", "Tool", Controller, "Text.Tool")
    Toggle(Text, Prefix, "HealthText", "Health text", Controller, "Text.Health")
    Toggle(Text, Prefix, "Category", "Category", Controller, "Text.Category")
    Toggle(Text, Prefix, "Flags", "Custom flags", Controller, "Text.Flags")
    Toggle(Text, Prefix, "RelativeSize", "Distance scaling", Controller, "Text.RelativeSize")
    Toggle(Text, Prefix, "TextOutline", "Outline", Controller, "Text.Outline")
    Slider(Text, Prefix, "TextSize", "Size", Controller, "Text.Size", 8, 24, 0, "px")
    Dropdown(Text, Prefix, "TextFont", "Font", Controller, "Text.Font", { "Plex", "UI", "System", "Monospace" })

    local HealthToggle = Toggle(Health, Prefix, "HealthBar", "Health bar", Controller, "HealthBar.Enabled")
    Color(HealthToggle, Prefix, "HealthLow", "Low health", Controller, "Colors.HealthLow")
    Color(HealthToggle, Prefix, "HealthHigh", "High health", Controller, "Colors.HealthHigh")
    Dropdown(Health, Prefix, "HealthPosition", "Position", Controller, "HealthBar.Position", { "Left", "Right", "Top", "Bottom" })
    Toggle(Health, Prefix, "HealthOutline", "Outline", Controller, "HealthBar.Outline")
    Toggle(Health, Prefix, "HealthValue", "Value label", Controller, "HealthBar.Text")
    Slider(Health, Prefix, "HealthWidth", "Width", Controller, "HealthBar.Width", 1, 6, 0, "px")
    Slider(Health, Prefix, "HealthOffset", "Offset", Controller, "HealthBar.Offset", 2, 16, 0, "px")

    local TracerToggle = Toggle(Tracers, Prefix, "Tracer", "Tracer", Controller, "Tracer.Enabled")
    Color(TracerToggle, Prefix, "TracerColor", "Tracer color", Controller, "Colors.Tracer")
    Dropdown(Tracers, Prefix, "TracerOrigin", "Origin", Controller, "Tracer.Origin", { "Bottom", "Center", "Mouse", "Top" })
    Dropdown(Tracers, Prefix, "TracerTarget", "Target", Controller, "Tracer.Target", { "Bottom", "Center", "Top" })
    Toggle(Tracers, Prefix, "TracerOutline", "Outline", Controller, "Tracer.Outline")
    Slider(Tracers, Prefix, "TracerThickness", "Thickness", Controller, "Tracer.Thickness", 0.5, 4, 1, "px")
    Slider(Tracers, Prefix, "TracerTransparency", "Opacity", Controller, "Tracer.Transparency", 0, 1, 0, "%", 100)

    local SkeletonToggle = Toggle(Models, Prefix, "Skeleton", "Skeleton", Controller, "Skeleton.Enabled")
    Color(SkeletonToggle, Prefix, "SkeletonColor", "Skeleton color", Controller, "Colors.Skeleton")
    Toggle(Models, Prefix, "SkeletonOutline", "Skeleton outline", Controller, "Skeleton.Outline")
    Slider(Models, Prefix, "SkeletonThickness", "Skeleton thickness", Controller, "Skeleton.Thickness", 0.5, 4, 1, "px")
    local HeadToggle = Toggle(Models, Prefix, "HeadDot", "Head dot", Controller, "HeadDot.Enabled")
    Color(HeadToggle, Prefix, "HeadDotColor", "Head dot color", Controller, "Colors.HeadDot")
    Toggle(Models, Prefix, "HeadFilled", "Filled head dot", Controller, "HeadDot.Filled")
    Slider(Models, Prefix, "HeadRadius", "Head dot radius", Controller, "HeadDot.Radius", 1, 12, 0, "px")
    local ArrowToggle = Toggle(Models, Prefix, "OffscreenArrow", "Offscreen arrow", Controller, "OffscreenArrow.Enabled")
    Color(ArrowToggle, Prefix, "ArrowColor", "Arrow color", Controller, "Colors.Arrow")
    Slider(Models, Prefix, "ArrowRadius", "Arrow radius", Controller, "OffscreenArrow.Radius", 40, 500, 0, "px")
    Slider(Models, Prefix, "ArrowSize", "Arrow size", Controller, "OffscreenArrow.Size", 4, 30, 0, "px")

    local HighlightToggle = Toggle(Colors, Prefix, "Highlight", "Highlight", Controller, "Highlight.Enabled")
    Color(HighlightToggle, Prefix, "HighlightFill", "Highlight fill", Controller, "Colors.HighlightFill")
    Color(HighlightToggle, Prefix, "HighlightOutline", "Highlight outline", Controller, "Colors.HighlightOutline")
    Toggle(Colors, Prefix, "HighlightHealth", "Health color", Controller, "Highlight.HealthColor")
    Dropdown(Colors, Prefix, "HighlightDepth", "Depth mode", Controller, "Highlight.DepthMode", { "AlwaysOnTop", "Occluded" })
    Slider(Colors, Prefix, "HighlightFillTransparency", "Fill transparency", Controller, "Highlight.FillTransparency", 0, 1, 0, "%", 100)
    Slider(Colors, Prefix, "HighlightOutlineTransparency", "Outline transparency", Controller, "Highlight.OutlineTransparency", 0, 1, 0, "%", 100)
    Color(TeamColorsToggle, Prefix, "TeamColor", "Team color", Controller, "Colors.Team")
    Color(NPCToggle, Prefix, "NPCColor", "NPC color", Controller, "Colors.NPC")
    Color(PartsToggle, Prefix, "PartColor", "Part color", Controller, "Colors.Part")
    Color(VisibilityToggle, Prefix, "VisibleColor", "Visible color", Controller, "Colors.Visible")
    Color(VisibilityToggle, Prefix, "OccludedColor", "Occluded color", Controller, "Colors.Occluded")
    Color(BoxToggle, Prefix, "OutlineColor", "Outline color", Controller, "Colors.Outline")
    Color(NameToggle, Prefix, "TextColor", "Text color", Controller, "Colors.Text")
    Color(PlayersToggle, Prefix, "PlayerColor", "Player color", Controller, "Colors.Enemy")

    Runtime:AddDropdown(Prefix .. "Preset", {
        Text = "Quality preset",
        Values = { "Balanced", "Performance", "Quality" },
        Default = "Balanced",
        Callback = function(Selection)
            Controller:ApplyPreset(Selection)
        end,
    })
    Slider(Runtime, Prefix, "UpdateRate", "Render rate", Controller, "UpdateRate", 10, 240, 0, " fps")
    Slider(Runtime, Prefix, "TextUpdateRate", "Text refresh", Controller, "TextUpdateRate", 1, 30, 0, " Hz")
    Runtime:AddButton("Restart renderer", function()
        Controller:Restart(false)
    end)
    Runtime:AddButton("Rebuild entries", function()
        Controller:Restart(true)
    end)
    Runtime:AddButton("Print statistics", function()
        local Stats = Controller:GetStats()
        print(string.format("[MonHub ESP] %d entries (%d players, %d NPCs, %d parts)", Stats.Total, Stats.Players, Stats.NPCs, Stats.Parts))
    end)

    NPC:AddLabel("NPC tracking is opt-in and can target the entire Workspace or a dedicated folder.", true)
    local AutoNPC = NPC:AddToggle(Prefix .. "AutoNPC", {
        Text = "Watch NPC container",
        Default = Info.AutoNPCs == true,
        Callback = function(State)
            Controller:SetAutomaticNPCs(State, Handle.NPCContainer, Handle.NPCInfo)
        end,
    })
    AutoNPC:AddKeyPicker(Prefix .. "AutoNPCKey", {
        Text = "NPC watcher",
        Default = "None",
        Mode = "Toggle",
        SyncToggleState = true,
    })
    NPC:AddButton("Scan NPCs now", function()
        local Count = Controller:ScanNPCs(Handle.NPCContainer, Handle.NPCInfo)
        if type(Library.Notify) == "function" then
            Library:Notify({
                Title = "ESP",
                Description = string.format("Added %d NPC entries.", Count),
                Time = 3,
            })
        end
    end)
    NPC:AddButton("Remove NPC entries", function()
        local Pending = {}
        for Id, Entry in Controller.Entries do
            if Entry.Kind == "NPC" then
                table.insert(Pending, Id)
            end
        end
        for _, Id in Pending do
            Controller:UnwrapObject(Id)
        end
    end)

    if Info.AutoNPCs == true then
        Controller:SetAutomaticNPCs(true, Handle.NPCContainer, Handle.NPCInfo)
    end

    function Handle:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self.Controller:SetAutomaticNPCs(false)
        if self.OwnController then
            self.Controller:Destroy()
        end
    end

    if type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Handle:Destroy()
        end)
    end

    return Handle
end

return MonHubUI
