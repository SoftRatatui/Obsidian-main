local VisualPreview = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local function IsClass(Object, ClassName)
    if typeof(Object) ~= "Instance" then
        return false
    end

    local Success, Result = pcall(function()
        return Object:IsA(ClassName)
    end)
    return Success and Result
end

local function SetVisible(Object, Visible)
    if IsClass(Object, "GuiObject") then
        pcall(function()
            Object.Visible = Visible == true
        end)
    end
end

local function IsLiveInstance(Object)
    if typeof(Object) ~= "Instance" then
        return false
    end

    local Success, Parent = pcall(function()
        return Object.Parent
    end)
    return Success and Parent ~= nil
end

local function ResolveCharacter(Source, Seen, Depth)
    Depth = Depth or 0
    if Depth >= 8 then
        return nil
    end

    if type(Source) == "function" then
        Seen = Seen or {}
        if Seen[Source] then
            return nil
        end
        Seen[Source] = true
        local Success, Result = pcall(Source)
        if Success then
            return ResolveCharacter(Result, Seen, Depth + 1)
        end
        return nil
    end

    if typeof(Source) ~= "Instance" then
        return nil
    end

    if Source:IsA("Player") then
        local Character = Source.Character
        if Character and IsLiveInstance(Character) then
            return Character
        end
        return nil
    end

    if Source:IsA("Model") and IsLiveInstance(Source) then
        return Source
    end

    return nil
end

local function CloneCharacter(Source)
    local Character = ResolveCharacter(Source)
    if not Character or not IsLiveInstance(Character) then
        return nil
    end

    local PreviousArchivable
    local Success, Clone = pcall(function()
        PreviousArchivable = Character.Archivable
        Character.Archivable = true
        return Character:Clone()
    end)
    if PreviousArchivable ~= nil then
        pcall(function()
            Character.Archivable = PreviousArchivable
        end)
    end

    if not Success or not Clone then
        return nil
    end

    for _, Object in Clone:GetDescendants() do
        if Object:IsA("Script") or Object:IsA("LocalScript") or Object:IsA("ModuleScript") then
            Object:Destroy()
        elseif Object:IsA("BasePart") then
            Object.Anchored = true
            Object.CanCollide = false
            Object.CastShadow = false
        elseif Object:IsA("Humanoid") then
            Object.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            Object.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        end
    end

    return Clone
end

local function FocusCamera(Object, Camera, Yaw, Pitch, Zoom)
    if not IsLiveInstance(Object) or not IsLiveInstance(Camera) then
        return false
    end

    return pcall(function()
        local _, Size = Object:GetBoundingBox()
        local Extent = math.max(Size.X, Size.Y, Size.Z)
        local Position = Object:GetPivot().Position + Vector3.new(0, Extent * 0.06, 0)
        local Rotation = CFrame.fromOrientation(Pitch or 0, Yaw or 0, 0)
        local Distance = math.max(Extent * (Zoom or 1.9), 5)
        Camera.CFrame = CFrame.lookAt(Position - Rotation.LookVector * Distance, Position)
    end)
end

local function CreateText(Parent, Position, Size, ZIndex)
    local Label = Instance.new("TextLabel")
    Label.AnchorPoint = Vector2.new(0.5, 0.5)
    Label.BackgroundTransparency = 1
    Label.FontFace = Font.fromEnum(Enum.Font.Gotham)
    Label.Position = Position
    Label.Size = Size
    Label.TextColor3 = Color3.fromRGB(245, 247, 250)
    Label.TextSize = 12
    Label.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
    Label.TextStrokeTransparency = 0.2
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.ZIndex = ZIndex
    Label.Parent = Parent
    return Label
end

local function CreateOverlay(Parent, AccentColor, BaseZIndex, Renderer)
    if type(Renderer) == "function" then
        local Success, Result = pcall(Renderer, Parent)
        local Container = Success and type(Result) == "table" and Result.Container or nil
        if IsClass(Container, "GuiObject") then
            Container.AnchorPoint = Vector2.new(0.5, 0.5)
            Container.BackgroundTransparency = 1
            Container.Position = UDim2.new(0.5, 0, 0.56, 0)
            Container.Size = UDim2.new(0.42, 0, 0.43, 0)
            Container.ZIndex = BaseZIndex + 2

            for _, Object in Container:GetDescendants() do
                if Object:IsA("GuiObject") then
                    Object.ZIndex = BaseZIndex + 3
                end
            end

            return {
                Overlay = Container,
                Container = Container,
                Box = IsClass(Result.BoxFrame, "GuiObject") and Result.BoxFrame or nil,
                BoxStroke = IsClass(Result.BoxStroke, "UIStroke") and Result.BoxStroke or nil,
                BoxGradient = IsClass(Result.BoxGradient, "UIGradient") and Result.BoxGradient or nil,
                InfoTop = IsClass(Result.InfoTop, "TextLabel") and Result.InfoTop or nil,
                InfoBottom = IsClass(Result.InfoBottom, "TextLabel") and Result.InfoBottom or nil,
                HealthBack = IsClass(Result.HealthBack, "GuiObject") and Result.HealthBack or nil,
                HealthFill = IsClass(Result.HealthFill, "GuiObject") and Result.HealthFill or nil,
            }
        end
    end

    local Overlay = Instance.new("Frame")
    Overlay.Name = "VisualPreviewOverlay"
    Overlay.BackgroundTransparency = 1
    Overlay.Size = UDim2.fromScale(1, 1)
    Overlay.ZIndex = BaseZIndex
    Overlay.Parent = Parent

    local Box = Instance.new("Frame")
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.BackgroundTransparency = 1
    Box.Position = UDim2.new(0.5, 0, 0.56, 0)
    Box.Size = UDim2.new(0.46, 0, 0.42, 0)
    Box.ZIndex = BaseZIndex + 2
    Box.Parent = Overlay

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BoxStroke.Color = AccentColor
    BoxStroke.Thickness = 1
    BoxStroke.Transparency = 0.04
    BoxStroke.Parent = Box

    local BoxGradient = Instance.new("UIGradient")
    BoxGradient.Enabled = false
    BoxGradient.Rotation = 90
    BoxGradient.Color = ColorSequence.new(AccentColor, AccentColor)
    BoxGradient.Parent = BoxStroke

    local InfoTop = CreateText(Box, UDim2.new(0.5, 0, 0, -4), UDim2.new(1.7, 0, 0, 16), BaseZIndex + 3)
    InfoTop.AnchorPoint = Vector2.new(0.5, 1)

    local InfoBottom = CreateText(Box, UDim2.new(0.5, 0, 1, 4), UDim2.new(1.7, 0, 0, 16), BaseZIndex + 3)
    InfoBottom.AnchorPoint = Vector2.new(0.5, 0)
    InfoBottom.TextColor3 = Color3.fromRGB(205, 225, 255)
    InfoBottom.TextSize = 11

    local HealthBack = Instance.new("Frame")
    HealthBack.AnchorPoint = Vector2.new(1, 0.5)
    HealthBack.BackgroundColor3 = Color3.fromRGB(8, 11, 15)
    HealthBack.BackgroundTransparency = 0.16
    HealthBack.BorderSizePixel = 0
    HealthBack.Position = UDim2.new(0, -5, 0.5, 0)
    HealthBack.Size = UDim2.new(0, 3, 1, 0)
    HealthBack.ZIndex = BaseZIndex + 2
    HealthBack.Parent = Box

    local Health = Instance.new("Frame")
    Health.AnchorPoint = Vector2.new(0, 1)
    Health.BackgroundColor3 = Color3.fromRGB(109, 214, 151)
    Health.BorderSizePixel = 0
    Health.Position = UDim2.new(0, 0, 1, 0)
    Health.Size = UDim2.new(1, 0, 0.72, 0)
    Health.ZIndex = BaseZIndex + 3
    Health.Parent = HealthBack

    local Tracer = Instance.new("Frame")
    Tracer.AnchorPoint = Vector2.new(0.5, 1)
    Tracer.BackgroundColor3 = AccentColor
    Tracer.BorderSizePixel = 0
    Tracer.Position = UDim2.new(0.5, 0, 0.98, 0)
    Tracer.Size = UDim2.new(0, 1, 0.28, 0)
    Tracer.ZIndex = BaseZIndex + 2
    Tracer.Parent = Overlay

    local TracerGradient = Instance.new("UIGradient")
    TracerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.35, 0.34),
        NumberSequenceKeypoint.new(1, 0.12),
    })
    TracerGradient.Parent = Tracer

    return {
        Overlay = Overlay,
        Box = Box,
        BoxStroke = BoxStroke,
        BoxGradient = BoxGradient,
        InfoTop = InfoTop,
        InfoBottom = InfoBottom,
        HealthBack = HealthBack,
        HealthFill = Health,
        Tracer = Tracer,
    }
end

function VisualPreview.Create(Library, Tab, Info)
    assert(Library and Library.AddToRegistry and Library.ScreenGui, "VisualPreview requires an active MonHub library")
    assert(Tab, "VisualPreview requires a regular tab")

    Info = Info or {}
    local MainWindow = Info.Window or Library.Window
    assert(MainWindow and MainWindow.Frame, "VisualPreview requires a window with a frame")
    local MainFrame = MainWindow.Frame
    assert(IsClass(MainFrame, "GuiObject"), "VisualPreview requires a GuiObject window frame")
    local TabCanvas = Tab.Canvas
    local PanelWidth = math.clamp(tonumber(Info.Width) or 300, 180, 720)
    local PanelHeight = math.clamp(tonumber(Info.Height) or 420, 220, 900)

    local Holder = Instance.new("Frame")
    Holder.Name = "MonHubVisualPreview"
    Holder.AnchorPoint = Vector2.new(0, 0.5)
    Holder.BackgroundColor3 = Library.Scheme.BackgroundColor
    Holder.BorderSizePixel = 0
    Holder.ClipsDescendants = true
    Holder.Position = UDim2.fromOffset(8, 8)
    Holder.Size = UDim2.fromOffset(PanelWidth, PanelHeight)
    Holder.Visible = false
    Holder.ZIndex = 10
    Holder.Parent = Library.ScreenGui
    Library:AddToRegistry(Holder, {
        BackgroundColor3 = "BackgroundColor",
    })

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, Library.CornerRadius)
    Corner.Parent = Holder

    local Outline = Instance.new("UIStroke")
    Outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Outline.Color = Library.Scheme.OutlineColor
    Outline.Thickness = 1
    Outline.Parent = Holder
    Library:AddToRegistry(Outline, {
        Color = "OutlineColor",
    })

    local AnimationScale = Instance.new("UIScale")
    AnimationScale.Scale = 0.98
    AnimationScale.Parent = Holder

    local Header = Instance.new("TextLabel")
    Header.BackgroundTransparency = 1
    Header.FontFace = Library.Scheme.Font
    Header.Position = UDim2.fromOffset(12, 0)
    Header.Size = UDim2.new(1, -24, 0, 34)
    Header.Text = tostring(Info.Name or "ESP preview")
    Header.TextColor3 = Library.Scheme.FontColor
    Header.TextSize = 14
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.ZIndex = 12
    Header.Parent = Holder
    Library:AddToRegistry(Header, {
        FontFace = "Font",
        TextColor3 = "FontColor",
    })

    local HeaderLine = Instance.new("Frame")
    HeaderLine.BackgroundColor3 = Library.Scheme.OutlineColor
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Position = UDim2.fromOffset(0, 34)
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.ZIndex = 12
    HeaderLine.Parent = Holder
    Library:AddToRegistry(HeaderLine, {
        BackgroundColor3 = "OutlineColor",
    })

    local Content = Instance.new("Frame")
    Content.BackgroundColor3 = Library:GetBetterColor(Library.Scheme.BackgroundColor, 2)
    Content.BorderSizePixel = 0
    Content.Position = UDim2.fromOffset(0, 35)
    Content.Size = UDim2.new(1, 0, 1, -35)
    Content.ZIndex = 11
    Content.Parent = Holder
    Library:AddToRegistry(Content, {
        BackgroundColor3 = function()
            return Library:GetBetterColor(Library.Scheme.BackgroundColor, 2)
        end,
    })

    local ViewportFrame = Instance.new("ViewportFrame")
    ViewportFrame.Ambient = Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.42)
    ViewportFrame.Active = true
    ViewportFrame.BackgroundTransparency = 1
    ViewportFrame.LightColor = Library.Scheme.FontColor
    ViewportFrame.LightDirection = Vector3.new(-1, -0.65, -1)
    ViewportFrame.Size = UDim2.fromScale(1, 1)
    ViewportFrame.ZIndex = 11
    ViewportFrame.Parent = Content
    Library:AddToRegistry(ViewportFrame, {
        Ambient = function()
            return Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.42)
        end,
        LightColor = "FontColor",
    })

    local Camera = Instance.new("Camera")
    Camera.Parent = ViewportFrame
    ViewportFrame.CurrentCamera = Camera

    local Model

    local Chams = Instance.new("Highlight")
    Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Chams.Enabled = false
    Chams.FillColor = Color3.fromRGB(119, 182, 255)
    Chams.FillTransparency = 0.25
    Chams.OutlineColor = Color3.fromRGB(235, 241, 248)
    Chams.OutlineTransparency = 0
    Chams.Parent = ViewportFrame

    local AccentColor = typeof(Info.Color) == "Color3" and Info.Color or Library.Scheme.AccentColor
    local Overlay = CreateOverlay(Content, AccentColor, 12, Info.Renderer)
    local Preview = {
        Holder = Holder,
        Frame = ViewportFrame,
        Camera = Camera,
        Model = Model,
        Overlay = Overlay,
        Chams = Chams,
        Side = Info.Side or "Auto",
        Alignment = Info.Alignment or "Center",
        Gap = math.clamp(tonumber(Info.Gap) or 12, 6, 32),
        Color = AccentColor,
        GradientColor = typeof(Info.GradientColor) == "Color3" and Info.GradientColor or AccentColor,
        Enabled = false,
        Destroyed = false,
        NameVisible = Info.NameVisible ~= false,
        TeamVisible = Info.Team == true,
        DistanceVisible = Info.Distance ~= false,
        WeaponVisible = Info.Weapon == true,
        Distance = nil,
        TargetName = "",
        TeamName = "",
        WeaponName = "",
        Target = nil,
        SourceCharacter = nil,
        TargetConnection = nil,
        CameraViewportConnection = nil,
        CameraChangedConnection = nil,
        ChamsEnabled = false,
        BoxScale = math.clamp(tonumber(Info.BoxScale) or 92, 70, 115),
        DynamicBoxes = Info.DynamicBoxes == true,
        Yaw = 0,
        Pitch = 0,
        Zoom = 1.9,
        Connections = {},
    }

    if Overlay.InfoTop then
        Library:AddToRegistry(Overlay.InfoTop, {
            FontFace = "Font",
            TextColor3 = "FontColor",
            TextStrokeColor3 = "DarkColor",
        })
    end
    if Overlay.InfoBottom then
        Library:AddToRegistry(Overlay.InfoBottom, {
            FontFace = "Font",
            TextColor3 = function()
                return Library.Scheme.FontColor:Lerp(Library.Scheme.AccentColor, 0.16)
            end,
            TextStrokeColor3 = "DarkColor",
        })
    end
    if Overlay.HealthBack then
        Library:AddToRegistry(Overlay.HealthBack, {
            BackgroundColor3 = function()
                return Library.Scheme.DarkColor:Lerp(Library.Scheme.BackgroundColor, 0.2)
            end,
        })
    end
    local VisibilitySequence = 0
    local Rotating = false
    local LastPointerPosition

    local function GetOverlayBox()
        local TargetBox = Overlay.Container or Overlay.Box
        if IsClass(TargetBox, "GuiObject") then
            return TargetBox
        end
        return nil
    end

    local function ApplyGradientColor()
        if IsClass(Overlay.BoxGradient, "UIGradient") then
            pcall(function()
                Overlay.BoxGradient.Color = ColorSequence.new(Preview.Color, Preview.GradientColor)
            end)
        end
    end

    local function UpdateInfoLabels()
        if Preview.Destroyed then
            return
        end

        local Top = ""
        if Preview.NameVisible and Preview.TeamVisible then
            Top = string.format("%s [%s]", Preview.TargetName, Preview.TeamName)
        elseif Preview.NameVisible then
            Top = Preview.TargetName
        elseif Preview.TeamVisible then
            Top = Preview.TeamName ~= "" and string.format("[%s]", Preview.TeamName) or ""
        end

        local Bottom = ""
        local DistanceText = Preview.Distance and string.format("%dm", Preview.Distance) or ""
        if Preview.WeaponVisible and Preview.DistanceVisible and Preview.WeaponName ~= "" and DistanceText ~= "" then
            Bottom = string.format("%s | %s", Preview.WeaponName, DistanceText)
        elseif Preview.WeaponVisible then
            Bottom = Preview.WeaponName
        elseif Preview.DistanceVisible then
            Bottom = DistanceText
        end

        if IsClass(Overlay.InfoTop, "TextLabel") then
            pcall(function()
                Overlay.InfoTop.Text = Top
                Overlay.InfoTop.Visible = Top ~= ""
            end)
        end
        if IsClass(Overlay.InfoBottom, "TextLabel") then
            pcall(function()
                Overlay.InfoBottom.Text = Bottom
                Overlay.InfoBottom.Visible = Bottom ~= ""
            end)
        end
    end

    local function UpdateTargetInfo(Character)
        if Preview.Destroyed then
            return
        end

        if not IsClass(Character, "Model") or not IsLiveInstance(Character) then
            Character = nil
        end

        local Player = Character and Players:GetPlayerFromCharacter(Character)
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local CameraObject = workspace.CurrentCamera
        Preview.TargetName = Player and Player.DisplayName or Character and Character.Name or ""
        Preview.TeamName = Player and Player.Team and Player.Team.Name or ""
        local Tool = Character and Character:FindFirstChildOfClass("Tool")
        Preview.WeaponName = Tool and Tool.Name or ""
        Preview.Distance = nil
        if IsClass(Root, "BasePart") and IsClass(CameraObject, "Camera") and IsLiveInstance(CameraObject) then
            local Success, Distance = pcall(function()
                return (Root.Position - CameraObject.CFrame.Position).Magnitude
            end)
            if Success then
                Preview.Distance = math.max(0, math.floor(Distance + 0.5))
            end
        end
        if IsClass(Overlay.HealthFill, "GuiObject") and IsClass(Humanoid, "Humanoid") then
            local Success, Health = pcall(function()
                return math.clamp(Humanoid.Health / math.max(Humanoid.MaxHealth, 100), 0, 1)
            end)
            if Success then
                pcall(function()
                    Overlay.HealthFill.Size = UDim2.new(1, 0, Health, 0)
                    Overlay.HealthFill.BackgroundColor3 = Color3.fromHSV(Health * 0.33, 0.9, 1)
                end)
            end
        end
        UpdateInfoLabels()
    end

    local function IsR6(ModelObject)
        if not IsClass(ModelObject, "Model") then
            return false
        end

        local Success, Humanoid = pcall(function()
            return ModelObject:FindFirstChildOfClass("Humanoid")
        end)
        return Success and IsClass(Humanoid, "Humanoid") and Humanoid.RigType == Enum.HumanoidRigType.R6
    end

    local function ProjectPoint(Point, ContentSize)
        if Preview.Destroyed or typeof(Point) ~= "Vector3" or typeof(ContentSize) ~= "Vector2" or not IsLiveInstance(Camera) then
            return nil
        end

        local Success, CameraPoint, FieldOfView = pcall(function()
            return Camera.CFrame:PointToObjectSpace(Point), Camera.FieldOfView
        end)
        if not Success then
            return nil
        end

        local Depth = -CameraPoint.Z
        if Depth <= 0.1 then
            return nil
        end

        local TanFov = math.tan(math.rad(math.clamp(FieldOfView, 1, 120) * 0.5))
        if TanFov <= 0 then
            return nil
        end

        local PixelScale = ContentSize.Y / (2 * Depth * TanFov)
        return ContentSize.X * 0.5 + CameraPoint.X * PixelScale, ContentSize.Y * 0.5 - CameraPoint.Y * PixelScale, Depth
    end

    local function UpdateOverlayBounds()
        if Preview.Destroyed or not IsClass(Model, "Model") or not IsLiveInstance(Model) then
            return
        end

        local Root = Model:FindFirstChild("HumanoidRootPart") or Model.PrimaryPart
        local ContentSize = Content.AbsoluteSize
        if not IsClass(Root, "BasePart") or ContentSize.X <= 0 or ContentSize.Y <= 0 then
            return
        end

        local CenterX, CenterY, Depth = ProjectPoint(Root.Position, ContentSize)
        if not CenterX then
            return
        end

        local Success, FieldOfView = pcall(function()
            return Camera.FieldOfView
        end)
        if not Success then
            return
        end

        local TanFov = math.tan(math.rad(math.clamp(FieldOfView, 1, 120) * 0.5)) * 2
        if TanFov <= 0 then
            return
        end
        local RawHeight = (5 * (Preview.BoxScale / 100) * ContentSize.Y) / (Depth * TanFov)
        local Height = math.clamp(RawHeight, 4, ContentSize.Y * 1.15)
        local Width = math.max(Height * 0.58, 4)

        if Preview.DynamicBoxes then
            local BoundsSuccess, BoundsFrame, BoundsSize = pcall(function()
                return Model:GetBoundingBox()
            end)
            if BoundsSuccess then
                local HalfX = BoundsSize.X * 0.5
                local HalfY = BoundsSize.Y * 0.5
                local HalfZ = BoundsSize.Z * 0.5
                local MinimumX, MinimumY = math.huge, math.huge
                local MaximumX, MaximumY = -math.huge, -math.huge
                local Count = 0

                for X = -1, 1, 2 do
                    for Y = -1, 1, 2 do
                        for Z = -1, 1, 2 do
                            local Point = BoundsFrame:PointToWorldSpace(Vector3.new(HalfX * X, HalfY * Y, HalfZ * Z))
                            local ScreenX, ScreenY = ProjectPoint(Point, ContentSize)
                            if ScreenX then
                                MinimumX = math.min(MinimumX, ScreenX)
                                MinimumY = math.min(MinimumY, ScreenY)
                                MaximumX = math.max(MaximumX, ScreenX)
                                MaximumY = math.max(MaximumY, ScreenY)
                                Count += 1
                            end
                        end
                    end
                end

                local DynamicWidth = MaximumX - MinimumX
                local DynamicHeight = MaximumY - MinimumY
                if Count >= 4 and DynamicWidth >= 3 and DynamicHeight >= 3 then
                    local SafeHeight = math.clamp(DynamicHeight, RawHeight * 0.64, RawHeight * 1.14)
                    local SafeWidth = math.clamp(DynamicWidth, SafeHeight * 0.32, SafeHeight * 0.72)
                    CenterX = MinimumX + DynamicWidth * 0.5
                    CenterY = MinimumY + DynamicHeight * 0.5
                    Width = math.max(4, SafeWidth)
                    Height = math.max(4, SafeHeight)
                end
            end
        end

        local TargetBox = GetOverlayBox()
        if not TargetBox then
            return
        end

        pcall(function()
            TargetBox.Position = UDim2.fromOffset(math.floor(CenterX + 0.5), math.floor(CenterY + 0.5))
            TargetBox.Size = UDim2.fromOffset(math.floor(Width + 0.5), math.floor(Height + 0.5))
        end)
    end

    local function UpdateCamera()
        if not Preview.Destroyed and IsClass(Model, "Model") and IsLiveInstance(Model) then
            FocusCamera(Model, Camera, Preview.Yaw, Preview.Pitch, Preview.Zoom)
            UpdateOverlayBounds()
        end
    end

    function Preview:SetTarget(Source)
        if Preview.Destroyed then
            return false
        end

        if Preview.TargetConnection then
            pcall(function()
                Preview.TargetConnection:Disconnect()
            end)
            Preview.TargetConnection = nil
        end

        if Model then
            pcall(function()
                Model:Destroy()
            end)
            Model = nil
        end
        Preview.Model = nil
        if IsClass(Chams, "Highlight") then
            pcall(function()
                Chams.Adornee = nil
                Chams.Enabled = false
            end)
        end

        local Character = ResolveCharacter(Source)
        local Clone = CloneCharacter(Character)
        Preview.Target = Source
        Preview.SourceCharacter = Character
        Preview.Model = Clone
        Model = Clone
        if IsClass(Chams, "Highlight") then
            pcall(function()
                Chams.Adornee = Clone
                Chams.Enabled = Preview.ChamsEnabled and IsR6(Clone)
            end)
        end

        if Clone then
            local Success = pcall(function()
                Clone.Parent = ViewportFrame
            end)
            if Success then
                UpdateCamera()
            else
                Clone:Destroy()
                Model = nil
                Preview.Model = nil
                if IsClass(Chams, "Highlight") then
                    pcall(function()
                        Chams.Adornee = nil
                        Chams.Enabled = false
                    end)
                end
            end
        end

        UpdateTargetInfo(Character)

        if IsClass(Source, "Player") and IsLiveInstance(Source) then
            local Success, Connection = pcall(function()
                return Source.CharacterAdded:Connect(function()
                    Preview:SetTarget(Source)
                end)
            end)
            if Success then
                Preview.TargetConnection = Connection
            end
        end

        return Model ~= nil
    end

    local function RefreshTarget()
        if Preview.Destroyed then
            return
        end

        local Character = ResolveCharacter(Preview.Target)
        if Character ~= Preview.SourceCharacter or (Model and not IsLiveInstance(Model)) then
            Preview:SetTarget(Preview.Target)
            return
        end

        UpdateTargetInfo(Character)
    end

    function Preview:Rotate(DeltaX, DeltaY)
        if Preview.Destroyed then
            return
        end

        Preview.Yaw -= (tonumber(DeltaX) or 0) * 0.012
        Preview.Pitch = math.clamp(Preview.Pitch - (tonumber(DeltaY) or 0) * 0.012, -1.15, 1.15)
        UpdateCamera()
    end

    function Preview:SetZoom(Zoom)
        if Preview.Destroyed then
            return
        end

        Preview.Zoom = math.clamp(tonumber(Zoom) or Preview.Zoom, 1.2, 3.2)
        UpdateCamera()
    end

    function Preview:ResetView()
        if Preview.Destroyed then
            return
        end

        Preview.Yaw = 0
        Preview.Pitch = 0
        Preview.Zoom = 1.9
        UpdateCamera()
    end

    local function PositionPanel()
        if Preview.Destroyed or not Holder.Parent then
            return
        end

        local CameraObject = workspace.CurrentCamera
        if not IsClass(CameraObject, "Camera") or not IsLiveInstance(CameraObject) or not IsLiveInstance(MainFrame) then
            return
        end

        local Success, MainPosition, MainSize, ScreenSize = pcall(function()
            return MainFrame.AbsolutePosition, MainFrame.AbsoluteSize, CameraObject.ViewportSize
        end)
        if not Success or ScreenSize.X <= 0 or ScreenSize.Y <= 0 then
            return
        end

        local CurrentPanelWidth = math.max(Holder.AbsoluteSize.X, PanelWidth)
        local CurrentPanelHeight = math.max(Holder.AbsoluteSize.Y, PanelHeight)
        local Gap = Preview.Gap
        local Side = string.lower(tostring(Preview.Side))
        local Alignment = string.lower(tostring(Preview.Alignment))
        local UseLeft = Side == "left"

        if Side == "auto" then
            UseLeft = MainPosition.X + MainSize.X + Gap + CurrentPanelWidth > ScreenSize.X - 8
        elseif Side == "right" and MainPosition.X + MainSize.X + Gap + CurrentPanelWidth > ScreenSize.X - 8 then
            UseLeft = MainPosition.X - Gap - CurrentPanelWidth >= 8
        end

        local AnchorX = UseLeft and 1 or 0
        local X = UseLeft and MainPosition.X - Gap or MainPosition.X + MainSize.X + Gap
        local AnchorY = 0.5
        local Y = MainPosition.Y + MainSize.Y * 0.5

        if Alignment == "top" then
            AnchorY = 0
            Y = MainPosition.Y
        elseif Alignment == "bottom" then
            AnchorY = 1
            Y = MainPosition.Y + MainSize.Y
        end

        local MinimumX = 8 + CurrentPanelWidth * AnchorX
        local MaximumX = ScreenSize.X - 8 - CurrentPanelWidth * (1 - AnchorX)
        local MinimumY = 8 + CurrentPanelHeight * AnchorY
        local MaximumY = ScreenSize.Y - 8 - CurrentPanelHeight * (1 - AnchorY)
        X = math.clamp(X, math.min(MinimumX, MaximumX), math.max(MinimumX, MaximumX))
        Y = math.clamp(Y, math.min(MinimumY, MaximumY), math.max(MinimumY, MaximumY))

        pcall(function()
            Holder.AnchorPoint = Vector2.new(AnchorX, AnchorY)
            Holder.Position = UDim2.fromOffset(math.floor(X + 0.5), math.floor(Y + 0.5))
        end)
    end

    local function IsTabVisible()
        if not IsClass(TabCanvas, "GuiObject") then
            return true
        end

        local Success, Visible = pcall(function()
            return TabCanvas.Visible
        end)
        return Success and Visible
    end

    local function IsMainVisible()
        if not IsClass(MainFrame, "GuiObject") or not IsLiveInstance(MainFrame) then
            return false
        end

        local Success, Visible = pcall(function()
            return MainFrame.Visible
        end)
        return Success and Visible
    end

    local function IsDisplayable()
        return Preview.Enabled and Library.Toggled and Library.ActiveTab == Tab and IsTabVisible() and IsMainVisible()
    end

    local function UpdateVisibility()
        if Preview.Destroyed or not Holder.Parent then
            return
        end

        VisibilitySequence += 1
        local Sequence = VisibilitySequence
        local Visible = IsDisplayable()

        if Visible then
            RefreshTarget()
            PositionPanel()
            UpdateCamera()
            if not Holder.Visible then
                AnimationScale.Scale = 0.98
                Holder.Visible = true
            end
            Library:PlayTween(AnimationScale, "VisualPreviewVisibility", TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Scale = 1,
            })
            return
        end

        if not Holder.Visible then
            return
        end

        Rotating = false
        LastPointerPosition = nil

        local Tween = Library:PlayTween(AnimationScale, "VisualPreviewVisibility", TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0.98,
        })

        if not Tween then
            Holder.Visible = false
            return
        end

        Tween.Completed:Once(function(State)
            if State == Enum.PlaybackState.Completed and Sequence == VisibilitySequence and not IsDisplayable() then
                Holder.Visible = false
            end
        end)
    end

    local VisibilityUpdateQueued = false
    local function QueueVisibilityUpdate()
        if VisibilityUpdateQueued then
            return
        end

        VisibilityUpdateQueued = true
        task.defer(function()
            VisibilityUpdateQueued = false
            UpdateVisibility()
        end)
    end

    local function AddConnection(Connection)
        if Connection then
            table.insert(Preview.Connections, Connection)
        end
        return Connection
    end

    local function DisconnectConnection(Connection)
        if not Connection then
            return
        end

        pcall(function()
            Connection:Disconnect()
        end)
        for Index = #Preview.Connections, 1, -1 do
            if Preview.Connections[Index] == Connection then
                table.remove(Preview.Connections, Index)
            end
        end
    end

    local function ConnectProperty(Object, Property, Callback)
        if not IsLiveInstance(Object) then
            return nil
        end

        local Success, Signal = pcall(function()
            return Object:GetPropertyChangedSignal(Property)
        end)
        if Success and Signal then
            local Connected, Connection = pcall(function()
                return Signal:Connect(function()
                    if not Preview.Destroyed then
                        Callback()
                    end
                end)
            end)
            if Connected then
                return AddConnection(Connection)
            end
        end
        return nil
    end

    local function BindCurrentCamera()
        DisconnectConnection(Preview.CameraViewportConnection)
        Preview.CameraViewportConnection = nil

        local CameraObject = workspace.CurrentCamera
        if not IsClass(CameraObject, "Camera") or not IsLiveInstance(CameraObject) then
            return
        end

        Preview.CameraViewportConnection = ConnectProperty(CameraObject, "ViewportSize", function()
            PositionPanel()
            RefreshTarget()
        end)
    end

    ConnectProperty(MainFrame, "AbsolutePosition", PositionPanel)
    ConnectProperty(MainFrame, "AbsoluteSize", PositionPanel)
    ConnectProperty(MainFrame, "Visible", QueueVisibilityUpdate)
    ConnectProperty(MainFrame, "GroupTransparency", QueueVisibilityUpdate)
    ConnectProperty(TabCanvas, "Visible", QueueVisibilityUpdate)
    ConnectProperty(Content, "AbsoluteSize", UpdateCamera)
    local VisibilityChanged = MainWindow.VisibilityChanged
    if typeof(VisibilityChanged) == "Instance" then
        local Success, Signal = pcall(function()
            return VisibilityChanged.Event
        end)
        if Success and Signal then
            local Connected, Connection = pcall(function()
                return Signal:Connect(function()
                    if not Preview.Destroyed then
                        UpdateVisibility()
                    end
                end)
            end)
            if Connected then
                AddConnection(Connection)
            end
        end
    end
    Preview.CameraChangedConnection = ConnectProperty(workspace, "CurrentCamera", function()
        BindCurrentCamera()
        RefreshTarget()
        PositionPanel()
    end)
    BindCurrentCamera()

    AddConnection(ViewportFrame.InputBegan:Connect(function(Input)
        if Preview.Destroyed or not Holder.Visible then
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Rotating = true
            LastPointerPosition = Input.Position
        end
    end))
    AddConnection(ViewportFrame.InputChanged:Connect(function(Input)
        if not Preview.Destroyed and Input.UserInputType == Enum.UserInputType.MouseWheel and Holder.Visible then
            Preview:SetZoom(Preview.Zoom - Input.Position.Z * 0.12)
        end
    end))
    AddConnection(UserInputService.InputChanged:Connect(function(Input)
        if Preview.Destroyed or not Rotating or not Holder.Visible then
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            local Position = Input.Position
            if LastPointerPosition then
                Preview:Rotate(Position.X - LastPointerPosition.X, Position.Y - LastPointerPosition.Y)
            end
            LastPointerPosition = Position
        end
    end))
    AddConnection(UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Rotating = false
            LastPointerPosition = nil
        end
    end))
    local NextTargetUpdate = 0
    AddConnection(RunService.Heartbeat:Connect(function()
        if Preview.Destroyed or not Holder.Visible or not Preview.Enabled then
            return
        end

        local Now = os.clock()
        if Now >= NextTargetUpdate then
            NextTargetUpdate = Now + 0.25
            RefreshTarget()
        end
    end))

    function Preview:SetEnabled(Enabled)
        if Preview.Destroyed then
            return
        end

        Preview.Enabled = Enabled == true
        SetVisible(Overlay.Overlay, Preview.Enabled)
        UpdateVisibility()
    end

    function Preview:SetColor(Color)
        if Preview.Destroyed or typeof(Color) ~= "Color3" then
            return
        end

        Preview.Color = Color
        if IsClass(Overlay.BoxStroke, "UIStroke") then
            pcall(function()
                Overlay.BoxStroke.Color = Color
            end)
        end
        ApplyGradientColor()
        if IsClass(Overlay.Tracer, "GuiObject") then
            pcall(function()
                Overlay.Tracer.BackgroundColor3 = Color
            end)
        end
    end

    function Preview:SetBoxScale(Scale)
        if Preview.Destroyed then
            return
        end

        Preview.BoxScale = math.clamp(tonumber(Scale) or Preview.BoxScale, 70, 115)
        UpdateOverlayBounds()
    end

    function Preview:SetDynamicBoxes(Enabled)
        if Preview.Destroyed then
            return
        end

        Preview.DynamicBoxes = Enabled == true
        UpdateOverlayBounds()
    end

    function Preview:SetBoxStyle()
        if Preview.Destroyed then
            return
        end

        SetVisible(Overlay.Box or Overlay.Container, true)
    end

    function Preview:SetGradientEnabled(Enabled)
        if Preview.Destroyed or not IsClass(Overlay.BoxGradient, "UIGradient") then
            return
        end

        pcall(function()
            Overlay.BoxGradient.Enabled = Enabled == true
        end)
    end

    function Preview:SetGradientColor(Color)
        if Preview.Destroyed or typeof(Color) ~= "Color3" then
            return
        end

        Preview.GradientColor = Color
        ApplyGradientColor()
    end

    function Preview:SetOpacity()
        if Preview.Destroyed then
            return
        end
    end

    function Preview:SetPosition(Side, Alignment)
        if Preview.Destroyed then
            return
        end

        local NormalizedSide = string.lower(tostring(Side or Preview.Side))
        local NormalizedAlignment = string.lower(tostring(Alignment or Preview.Alignment))
        Preview.Side = NormalizedSide == "left" and "Left" or NormalizedSide == "right" and "Right" or "Auto"
        Preview.Alignment = NormalizedAlignment == "top" and "Top" or NormalizedAlignment == "bottom" and "Bottom" or "Center"
        PositionPanel()
    end

    function Preview:SetPanelGap(Gap)
        if Preview.Destroyed then
            return
        end

        Preview.Gap = math.clamp(tonumber(Gap) or Preview.Gap, 6, 32)
        PositionPanel()
    end

    function Preview:SetBoxVisible(Visible)
        if Preview.Destroyed then
            return
        end

        SetVisible(Overlay.Box or Overlay.Container, Visible)
    end

    function Preview:SetNameVisible(Visible)
        if Preview.Destroyed then
            return
        end

        Preview.NameVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetDistanceVisible(Visible)
        if Preview.Destroyed then
            return
        end

        Preview.DistanceVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetTeamVisible(Visible)
        if Preview.Destroyed then
            return
        end

        Preview.TeamVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetWeaponVisible(Visible)
        if Preview.Destroyed then
            return
        end

        Preview.WeaponVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetTracerVisible(Visible)
        if Preview.Destroyed then
            return
        end

        SetVisible(Overlay.Tracer, Visible)
    end

    function Preview:SetHealthVisible(Visible)
        if Preview.Destroyed then
            return
        end

        SetVisible(Overlay.HealthBack, Visible)
    end

    function Preview:SetHighlightVisible(Visible)
        if Preview.Destroyed or not IsClass(Chams, "Highlight") then
            return
        end

        Preview.ChamsEnabled = Visible == true
        pcall(function()
            Chams.Enabled = Preview.ChamsEnabled and IsR6(Model)
        end)
    end

    function Preview:SetChams(Enabled, FillColor, OutlineColor, FillTransparency, OutlineTransparency)
        if Preview.Destroyed or not IsClass(Chams, "Highlight") then
            return
        end

        if typeof(FillColor) == "Color3" then
            pcall(function()
                Chams.FillColor = FillColor
            end)
        end
        if typeof(OutlineColor) == "Color3" then
            pcall(function()
                Chams.OutlineColor = OutlineColor
            end)
        end
        pcall(function()
            Chams.FillTransparency = math.clamp(tonumber(FillTransparency) or Chams.FillTransparency, 0, 1)
            Chams.OutlineTransparency = math.clamp(tonumber(OutlineTransparency) or Chams.OutlineTransparency, 0, 1)
        end)
        Preview.ChamsEnabled = Enabled == true
        pcall(function()
            Chams.Enabled = Preview.ChamsEnabled and IsR6(Model)
        end)
    end

    function Preview:SetDistance(Value)
        if Preview.Destroyed then
            return
        end

        local NumericValue = tonumber(Value)
        if NumericValue then
            Preview.Distance = math.max(0, math.floor(NumericValue + 0.5))
            UpdateInfoLabels()
        end
    end

    function Preview:Destroy()
        if Preview.Destroyed then
            return
        end

        Preview.Destroyed = true
        Rotating = false
        LastPointerPosition = nil
        if Preview.TargetConnection then
            pcall(function()
                Preview.TargetConnection:Disconnect()
            end)
            Preview.TargetConnection = nil
        end
        for Index = #Preview.Connections, 1, -1 do
            local Connection = Preview.Connections[Index]
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(Preview.Connections)
        Preview.CameraViewportConnection = nil
        Preview.CameraChangedConnection = nil
        if IsClass(Chams, "Highlight") then
            pcall(function()
                Chams.Enabled = false
                Chams.Adornee = nil
            end)
        end
        if Model then
            pcall(function()
                Model:Destroy()
            end)
            Model = nil
            Preview.Model = nil
        end
        Preview.Target = nil
        Preview.SourceCharacter = nil
        if Holder then
            pcall(function()
                Holder:Destroy()
            end)
        end
    end

    Library:OnUnload(function()
        Preview:Destroy()
    end)

    Preview:SetTarget(Info.Target or Info.Player or Players.LocalPlayer)
    Preview:SetBoxVisible(Info.Box ~= false)
    Preview:SetNameVisible(Preview.NameVisible)
    Preview:SetDistanceVisible(Preview.DistanceVisible)
    Preview:SetTeamVisible(Preview.TeamVisible)
    Preview:SetWeaponVisible(Preview.WeaponVisible)
    Preview:SetTracerVisible(Info.Tracer == true)
    Preview:SetHealthVisible(Info.Health ~= false)
    Preview:SetChams(Info.Highlight == true, Info.ChamsFillColor, Info.ChamsOutlineColor, Info.ChamsFillTransparency, Info.ChamsOutlineTransparency)
    Preview:SetGradientColor(Preview.GradientColor)
    Preview:SetGradientEnabled(Info.Gradient == true)
    Preview:SetPosition(Preview.Side, Preview.Alignment)
    Preview:SetEnabled(Info.Enabled == true)

    return Preview
end

return VisualPreview
