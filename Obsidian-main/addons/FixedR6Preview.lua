local Players = game:GetService("Players")

local FixedR6Preview = {
    ReleaseVersion = "0.0.1-release-6",
}

local function ResolvePlayer(Target)
    if typeof(Target) == "Instance" and Target:IsA("Player") then
        return Target
    end
    if typeof(Target) == "Instance" and Target:IsA("Model") then
        return Players:GetPlayerFromCharacter(Target)
    end
    if typeof(Target) == "number" then
        return Players:GetPlayerByUserId(Target)
    end
    return Players.LocalPlayer
end

local function GetDescription(Player)
    if Player and Player.Character then
        local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            local Success, Description = pcall(Humanoid.GetAppliedDescription, Humanoid)
            if Success and typeof(Description) == "Instance" and Description:IsA("HumanoidDescription") then
                return Description
            end
        end
    end
    if Player then
        local AsyncMethod = Players.GetHumanoidDescriptionFromUserIdAsync
        if type(AsyncMethod) == "function" then
            local Success, Description = pcall(AsyncMethod, Players, Player.UserId)
            if Success and typeof(Description) == "Instance" and Description:IsA("HumanoidDescription") then
                return Description
            end
        end
        local LegacyMethod = Players.GetHumanoidDescriptionFromUserId
        if type(LegacyMethod) == "function" then
            local Success, Description = pcall(LegacyMethod, Players, Player.UserId)
            if Success and typeof(Description) == "Instance" and Description:IsA("HumanoidDescription") then
                return Description
            end
        end
    end
    return Instance.new("HumanoidDescription")
end

local function CreateR6Model(Description)
    local AsyncMethod = Players.CreateHumanoidModelFromDescriptionAsync
    if type(AsyncMethod) == "function" then
        local Success, Model = pcall(AsyncMethod, Players, Description, Enum.HumanoidRigType.R6)
        if Success and typeof(Model) == "Instance" and Model:IsA("Model") then
            return Model
        end
    end
    local LegacyMethod = Players.CreateHumanoidModelFromDescription
    if type(LegacyMethod) == "function" then
        local Success, Model = pcall(LegacyMethod, Players, Description, Enum.HumanoidRigType.R6)
        if Success and typeof(Model) == "Instance" and Model:IsA("Model") then
            return Model
        end
    end
    return nil
end

function FixedR6Preview.Create(Library, VisualPreview, DrawingESPPreview, Tab, Info)
    assert(Library and Library.ScreenGui and Library.Window, "FixedR6Preview requires an active MonHub window")
    assert(type(VisualPreview) == "table" and type(VisualPreview.Create) == "function", "FixedR6Preview requires VisualPreview")
    assert(type(Tab) == "table" and Tab.Canvas, "FixedR6Preview requires a regular tab")
    Info = Info or {}

    local Controller = {
        Destroyed = false,
        Player = ResolvePlayer(Info.Target or Info.Player),
        Preview = nil,
        Renderer = Info.Renderer,
        OwnsRenderer = false,
        SourceModel = nil,
        Connections = {},
        Refreshing = false,
    }

    local SourceFolder = Instance.new("Folder")
    SourceFolder.Name = "MonHubR6PreviewSource"
    SourceFolder.Parent = Library.ScreenGui

    if not Controller.Renderer and type(DrawingESPPreview) == "table" and type(DrawingESPPreview.Create) == "function" then
        Controller.Renderer = DrawingESPPreview.Create({
            Color = typeof(Info.Color) == "Color3" and Info.Color or Color3.fromRGB(128, 169, 207),
            GradientColor = typeof(Info.GradientColor) == "Color3" and Info.GradientColor or Color3.fromRGB(198, 170, 224),
            Gradient = Info.Gradient ~= false,
        })
        Controller.OwnsRenderer = true
    end

    local function BuildModel()
        local Description = GetDescription(Controller.Player)
        local Model = CreateR6Model(Description)
        if Description and Description.Parent == nil then
            Description:Destroy()
        end
        if not Model then
            return nil
        end
        Model.Name = "MonHubRealR6Preview"
        Model.Parent = SourceFolder
        for _, Object in Model:GetDescendants() do
            if Object:IsA("BasePart") then
                Object.Anchored = true
                Object.CanCollide = false
                Object.CanQuery = false
                Object.CanTouch = false
                Object.CastShadow = false
            elseif Object:IsA("Script") or Object:IsA("LocalScript") or Object:IsA("ModuleScript") then
                Object:Destroy()
            end
        end
        return Model
    end

    Controller.SourceModel = BuildModel()
    assert(Controller.SourceModel, "Unable to create the R6 preview model")

    Controller.Preview = VisualPreview.Create(Library, Tab, {
        Name = tostring(Info.Name or "Visual preview"),
        Target = Controller.SourceModel,
        Renderer = Controller.Renderer,
        Width = math.clamp(tonumber(Info.Width) or 292, 220, 420),
        Height = math.clamp(tonumber(Info.Height) or 440, 300, 680),
        Side = Info.Side or "Right",
        Alignment = Info.Alignment or "Center",
        Gap = math.clamp(tonumber(Info.Gap) or 10, 6, 24),
        Enabled = Info.Enabled ~= false,
        Box = Info.Box ~= false,
        NameVisible = Info.NameVisible == true,
        Distance = Info.Distance == true,
        Health = Info.Health ~= false,
        Gradient = Info.Gradient ~= false,
        DynamicBoxes = Info.DynamicBoxes ~= false,
        Color = typeof(Info.Color) == "Color3" and Info.Color or Color3.fromRGB(128, 169, 207),
        GradientColor = typeof(Info.GradientColor) == "Color3" and Info.GradientColor or Color3.fromRGB(198, 170, 224),
        Highlight = Info.Highlight == true,
        ShowHeader = Info.ShowHeader ~= false,
    })

    function Controller:SetEnabled(Value)
        if not Controller.Destroyed then
            Controller.Preview:SetEnabled(Value)
        end
        return Controller
    end

    function Controller:SetColors(ColorA, ColorB)
        if Controller.Destroyed then
            return Controller
        end
        Controller.Preview:SetColor(ColorA)
        Controller.Preview:SetGradientColor(ColorB)
        return Controller
    end

    function Controller:SetGradientEnabled(Value)
        if not Controller.Destroyed then
            Controller.Preview:SetGradientEnabled(Value)
        end
        return Controller
    end

    function Controller:SetPosition(Side, Alignment)
        if not Controller.Destroyed then
            Controller.Preview:SetPosition(Side, Alignment)
        end
        return Controller
    end

    function Controller:Rotate(X, Y)
        if not Controller.Destroyed then
            Controller.Preview:Rotate(X, Y)
        end
        return Controller
    end

    function Controller:SetZoom(Value)
        if not Controller.Destroyed then
            Controller.Preview:SetZoom(Value)
        end
        return Controller
    end

    function Controller:RefreshCharacter()
        if Controller.Destroyed or Controller.Refreshing then
            return false
        end
        Controller.Refreshing = true
        local Model = BuildModel()
        Controller.Refreshing = false
        if not Model then
            return false
        end
        if Controller.Destroyed then
            Model:Destroy()
            return false
        end
        local Previous = Controller.SourceModel
        Controller.SourceModel = Model
        Controller.Preview:SetTarget(Model)
        if Previous then
            Previous:Destroy()
        end
        return true
    end

    function Controller:Destroy()
        if Controller.Destroyed then
            return
        end
        Controller.Destroyed = true
        for _, Connection in Controller.Connections do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(Controller.Connections)
        if Controller.Preview then
            Controller.Preview:Destroy()
            Controller.Preview = nil
        end
        if Controller.OwnsRenderer and Controller.Renderer and Controller.Renderer.Destroy then
            Controller.Renderer:Destroy()
        end
        Controller.Renderer = nil
        if SourceFolder then
            SourceFolder:Destroy()
        end
        Controller.SourceModel = nil
    end

    if Controller.Player and Info.AutoRefresh ~= false then
        table.insert(Controller.Connections, Controller.Player.CharacterAppearanceLoaded:Connect(function()
            if not Controller.Destroyed then
                task.defer(Controller.RefreshCharacter, Controller)
            end
        end))
    end

    Library:OnUnload(function()
        Controller:Destroy()
    end)

    return Controller
end

return FixedR6Preview
