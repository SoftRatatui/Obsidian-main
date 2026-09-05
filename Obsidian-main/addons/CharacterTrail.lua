local Players = game:GetService("Players")

local CharacterTrail = {
    ReleaseVersion = "0.0.1-release-3",
}

CharacterTrail.TexturePresets = {
    None = "",
    Beam = "rbxassetid://12781852245",
    Lightning = "rbxassetid://446111271",
    Heartrate = "rbxassetid://5830549480",
    Chain = "rbxassetid://9632168658",
    Glitch = "rbxassetid://8089467613",
    Swirl = "rbxassetid://5638168605",
    Neon = "rbxassetid://6361963422",
    Plasma = "rbxassetid://8993645509",
    Laser = "rbxassetid://14549123968",
}

CharacterTrail.Presets = {
    Soft = {
        ColorStart = Color3.fromRGB(146, 178, 214),
        ColorEnd = Color3.fromRGB(196, 168, 232),
        TransparencyStart = 0.04,
        TransparencyEnd = 0.18,
        WidthStart = 1,
        WidthEnd = 0.08,
        Lifetime = 0.42,
        AttachmentWidth = 1.7,
        Texture = "",
        LightEmission = 0.28,
    },
    Energy = {
        ColorStart = Color3.fromRGB(112, 178, 238),
        ColorEnd = Color3.fromRGB(183, 137, 235),
        TransparencyStart = 0.02,
        TransparencyEnd = 0.12,
        WidthStart = 1,
        WidthEnd = 0.04,
        Lifetime = 0.5,
        AttachmentWidth = 1.9,
        Texture = "rbxassetid://12781852245",
        LightEmission = 0.72,
    },
    Plasma = {
        ColorStart = Color3.fromRGB(139, 195, 255),
        ColorEnd = Color3.fromRGB(215, 151, 255),
        TransparencyStart = 0.03,
        TransparencyEnd = 0.15,
        WidthStart = 0.9,
        WidthEnd = 0.02,
        Lifetime = 0.56,
        AttachmentWidth = 2,
        Texture = "rbxassetid://8993645509",
        LightEmission = 0.82,
    },
    Minimal = {
        ColorStart = Color3.fromRGB(226, 232, 240),
        ColorEnd = Color3.fromRGB(151, 160, 176),
        TransparencyStart = 0.08,
        TransparencyEnd = 0.3,
        WidthStart = 0.72,
        WidthEnd = 0,
        Lifetime = 0.3,
        AttachmentWidth = 1.35,
        Texture = "",
        LightEmission = 0.08,
    },
}

local function NormalizeAsset(Value)
    if typeof(Value) == "number" then
        return string.format("rbxassetid://%d", Value)
    end
    if typeof(Value) ~= "string" or Value == "" then
        return ""
    end
    local Preset = CharacterTrail.TexturePresets[Value]
    if Preset ~= nil then
        return Preset
    end
    local LowerValue = string.lower(Value)
    for Name, Asset in CharacterTrail.TexturePresets do
        if string.lower(Name) == LowerValue then
            return Asset
        end
    end
    local Numeric = tonumber(Value)
    if Numeric then
        return string.format("rbxassetid://%d", Numeric)
    end
    return Value
end

local function ResolveTextureMode(Value)
    if typeof(Value) == "EnumItem" and Value.EnumType == Enum.TextureMode then
        return Value
    end
    local Name = string.lower(tostring(Value or "Wrap"))
    if Name == "stretch" then
        return Enum.TextureMode.Stretch
    elseif Name == "static" then
        return Enum.TextureMode.Static
    end
    return Enum.TextureMode.Wrap
end

local function ResolveCharacter(Source)
    if type(Source) == "function" then
        local Success, Result = pcall(Source)
        if Success then
            return ResolveCharacter(Result)
        end
        return nil
    end
    if typeof(Source) ~= "Instance" then
        return nil
    end
    if Source:IsA("Player") then
        return Source.Character
    end
    if Source:IsA("Model") then
        return Source
    end
    return Source:FindFirstAncestorOfClass("Model")
end

local function FindAttachmentPart(Character, Name)
    if typeof(Character) ~= "Instance" or not Character:IsA("Model") then
        return nil
    end
    local Part = Character:FindFirstChild(Name, true)
    if Part and Part:IsA("BasePart") then
        return Part
    end
    local Primary = Character.PrimaryPart
    if Primary and Primary:IsA("BasePart") then
        return Primary
    end
    return Character:FindFirstChildWhichIsA("BasePart", true)
end

local function SetProperty(Object, Property, Value)
    if not Object then
        return
    end
    pcall(function()
        Object[Property] = Value
    end)
end

local function ClonePreset(Preset)
    local Result = {}
    for Key, Value in Preset do
        Result[Key] = Value
    end
    return Result
end

function CharacterTrail.Create(Info)
    Info = Info or {}
    local Controller = {
        Enabled = Info.Enabled == true,
        Target = Info.Target or Players.LocalPlayer,
        AttachmentPart = tostring(Info.AttachmentPart or "HumanoidRootPart"),
        AttachmentWidth = math.clamp(tonumber(Info.AttachmentWidth) or 1.7, 0.05, 12),
        VerticalOffset = math.clamp(tonumber(Info.VerticalOffset) or 0, -12, 12),
        ColorStart = typeof(Info.ColorStart) == "Color3" and Info.ColorStart or typeof(Info.ColorA) == "Color3" and Info.ColorA or Color3.fromRGB(146, 178, 214),
        ColorEnd = typeof(Info.ColorEnd) == "Color3" and Info.ColorEnd or typeof(Info.ColorB) == "Color3" and Info.ColorB or Color3.fromRGB(196, 168, 232),
        TransparencyStart = math.clamp(tonumber(Info.TransparencyStart) or tonumber(Info.TransparencyMin) or 0.04, 0, 1),
        TransparencyEnd = math.clamp(tonumber(Info.TransparencyEnd) or tonumber(Info.TransparencyMax) or 0.18, 0, 1),
        WidthStart = math.clamp(tonumber(Info.WidthStart) or 1, 0, 1),
        WidthEnd = math.clamp(tonumber(Info.WidthEnd) or 0.08, 0, 1),
        Lifetime = math.clamp(tonumber(Info.Lifetime) or 0.42, 0.01, 10),
        MinLength = math.clamp(tonumber(Info.MinLength) or 0.05, 0, 100),
        MaxLength = math.clamp(tonumber(Info.MaxLength) or 0, 0, 1000),
        Texture = NormalizeAsset(Info.Texture),
        TextureLength = math.clamp(tonumber(Info.TextureLength) or 1.25, 0.05, 100),
        TextureMode = ResolveTextureMode(Info.TextureMode),
        FaceCamera = Info.FaceCamera ~= false,
        LightEmission = math.clamp(tonumber(Info.LightEmission) or 0.28, 0, 1),
        LightInfluence = math.clamp(tonumber(Info.LightInfluence) or 0, 0, 1),
        Brightness = math.clamp(tonumber(Info.Brightness) or 1, 0, 10),
        Destroyed = false,
        Trail = nil,
        Attachment0 = nil,
        Attachment1 = nil,
        Character = nil,
        CharacterAddedConnection = nil,
        CharacterRemovingConnection = nil,
        Revision = 0,
    }

    local ChangedEvent = Instance.new("BindableEvent")
    Controller.Changed = ChangedEvent.Event

    local function FireChanged(...)
        if not Controller.Destroyed then
            ChangedEvent:Fire(...)
        end
    end

    local function DisconnectCharacterSignals()
        if Controller.CharacterAddedConnection then
            Controller.CharacterAddedConnection:Disconnect()
            Controller.CharacterAddedConnection = nil
        end
        if Controller.CharacterRemovingConnection then
            Controller.CharacterRemovingConnection:Disconnect()
            Controller.CharacterRemovingConnection = nil
        end
    end

    local function ClearInstances()
        if Controller.Trail then
            Controller.Trail:Destroy()
            Controller.Trail = nil
        end
        if Controller.Attachment0 then
            Controller.Attachment0:Destroy()
            Controller.Attachment0 = nil
        end
        if Controller.Attachment1 then
            Controller.Attachment1:Destroy()
            Controller.Attachment1 = nil
        end
        Controller.Character = nil
    end

    local function ApplyProperties()
        local Trail = Controller.Trail
        if not Trail then
            return
        end

        Trail.Enabled = Controller.Enabled
        Trail.Color = ColorSequence.new(Controller.ColorStart, Controller.ColorEnd)
        Trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, Controller.TransparencyStart),
            NumberSequenceKeypoint.new(1, Controller.TransparencyEnd),
        })
        Trail.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, Controller.WidthStart),
            NumberSequenceKeypoint.new(1, Controller.WidthEnd),
        })
        Trail.Lifetime = Controller.Lifetime
        Trail.MinLength = Controller.MinLength
        Trail.Texture = Controller.Texture
        Trail.TextureLength = Controller.TextureLength
        Trail.TextureMode = Controller.TextureMode
        Trail.FaceCamera = Controller.FaceCamera
        Trail.LightEmission = Controller.LightEmission
        Trail.LightInfluence = Controller.LightInfluence
        SetProperty(Trail, "MaxLength", Controller.MaxLength)
        SetProperty(Trail, "Brightness", Controller.Brightness)

        if Controller.Attachment0 then
            Controller.Attachment0.Position = Vector3.new(-Controller.AttachmentWidth * 0.5, Controller.VerticalOffset, 0)
        end
        if Controller.Attachment1 then
            Controller.Attachment1.Position = Vector3.new(Controller.AttachmentWidth * 0.5, Controller.VerticalOffset, 0)
        end
    end

    local function Build(Character, Revision)
        if Controller.Destroyed or not Controller.Enabled or Revision ~= Controller.Revision then
            return
        end

        local Part = FindAttachmentPart(Character, Controller.AttachmentPart)
        if not Part then
            task.spawn(function()
                local Candidate = Character and Character:WaitForChild(Controller.AttachmentPart, 5)
                if Controller.Destroyed or not Controller.Enabled or Revision ~= Controller.Revision then
                    return
                end
                if Candidate and Candidate:IsA("BasePart") then
                    Build(Character, Revision)
                end
            end)
            return
        end

        ClearInstances()
        if Controller.Destroyed or not Controller.Enabled or Revision ~= Controller.Revision then
            return
        end

        local Attachment0 = Instance.new("Attachment")
        Attachment0.Name = "MonHubTrailLeft"
        Attachment0.Parent = Part

        local Attachment1 = Instance.new("Attachment")
        Attachment1.Name = "MonHubTrailRight"
        Attachment1.Parent = Part

        local Trail = Instance.new("Trail")
        Trail.Name = "MonHubCharacterTrail"
        Trail.Attachment0 = Attachment0
        Trail.Attachment1 = Attachment1
        Trail.Parent = Part

        Controller.Character = Character
        Controller.Attachment0 = Attachment0
        Controller.Attachment1 = Attachment1
        Controller.Trail = Trail
        ApplyProperties()
        FireChanged("Character", Character)
    end

    local function BindTarget()
        DisconnectCharacterSignals()
        ClearInstances()
        Controller.Revision += 1
        local Revision = Controller.Revision

        if Controller.Destroyed or not Controller.Enabled then
            return
        end

        local Target = Controller.Target
        if typeof(Target) == "Instance" and Target:IsA("Player") then
            Controller.CharacterAddedConnection = Target.CharacterAdded:Connect(function(Character)
                Controller.Revision += 1
                Build(Character, Controller.Revision)
            end)
            Controller.CharacterRemovingConnection = Target.CharacterRemoving:Connect(function(Character)
                if Controller.Character == Character then
                    Controller.Revision += 1
                    ClearInstances()
                end
            end)
        end

        local Character = ResolveCharacter(Target)
        if Character then
            Build(Character, Revision)
        end
    end

    local function Commit(Property, Value, Rebuild)
        if Controller.Destroyed then
            return Controller
        end
        Controller[Property] = Value
        if Rebuild and Controller.Enabled then
            BindTarget()
        else
            ApplyProperties()
        end
        FireChanged(Property, Value)
        return Controller
    end

    function Controller:SetEnabled(Value)
        if Controller.Destroyed then
            return Controller
        end
        Value = Value == true
        if Controller.Enabled == Value then
            return Controller
        end
        Controller.Enabled = Value
        BindTarget()
        FireChanged("Enabled", Value)
        return Controller
    end

    function Controller:SetTarget(Target)
        if Controller.Destroyed then
            return Controller
        end
        Controller.Target = Target or Players.LocalPlayer
        BindTarget()
        FireChanged("Target", Controller.Target)
        return Controller
    end

    function Controller:SetColors(First, Second)
        if Controller.Destroyed then
            return Controller
        end
        if typeof(First) == "Color3" then
            Controller.ColorStart = First
        end
        if typeof(Second) == "Color3" then
            Controller.ColorEnd = Second
        end
        ApplyProperties()
        FireChanged("Colors", Controller.ColorStart, Controller.ColorEnd)
        return Controller
    end

    function Controller:SetTransparency(First, Second)
        if Controller.Destroyed then
            return Controller
        end
        Controller.TransparencyStart = math.clamp(tonumber(First) or Controller.TransparencyStart, 0, 1)
        Controller.TransparencyEnd = math.clamp(tonumber(Second) or Controller.TransparencyEnd, 0, 1)
        ApplyProperties()
        FireChanged("Transparency", Controller.TransparencyStart, Controller.TransparencyEnd)
        return Controller
    end

    function Controller:SetWidthScale(First, Second)
        if Controller.Destroyed then
            return Controller
        end
        Controller.WidthStart = math.clamp(tonumber(First) or Controller.WidthStart, 0, 1)
        Controller.WidthEnd = math.clamp(tonumber(Second) or Controller.WidthEnd, 0, 1)
        ApplyProperties()
        FireChanged("WidthScale", Controller.WidthStart, Controller.WidthEnd)
        return Controller
    end

    function Controller:SetAttachmentWidth(Value)
        return Commit("AttachmentWidth", math.clamp(tonumber(Value) or Controller.AttachmentWidth, 0.05, 12), false)
    end

    function Controller:SetVerticalOffset(Value)
        return Commit("VerticalOffset", math.clamp(tonumber(Value) or Controller.VerticalOffset, -12, 12), false)
    end

    function Controller:SetAttachmentPart(Value)
        local Name = tostring(Value or "HumanoidRootPart")
        if Name == "" then
            Name = "HumanoidRootPart"
        end
        return Commit("AttachmentPart", Name, true)
    end

    function Controller:SetLifetime(Value)
        return Commit("Lifetime", math.clamp(tonumber(Value) or Controller.Lifetime, 0.01, 10), false)
    end

    function Controller:SetMinLength(Value)
        return Commit("MinLength", math.clamp(tonumber(Value) or Controller.MinLength, 0, 100), false)
    end

    function Controller:SetMaxLength(Value)
        return Commit("MaxLength", math.clamp(tonumber(Value) or Controller.MaxLength, 0, 1000), false)
    end

    function Controller:SetTexture(Value)
        return Commit("Texture", NormalizeAsset(Value), false)
    end

    function Controller:SetTextureMode(Value)
        return Commit("TextureMode", ResolveTextureMode(Value), false)
    end

    function Controller:SetTextureLength(Value)
        return Commit("TextureLength", math.clamp(tonumber(Value) or Controller.TextureLength, 0.05, 100), false)
    end

    function Controller:SetFaceCamera(Value)
        return Commit("FaceCamera", Value == true, false)
    end

    function Controller:SetLight(Emission, Influence)
        if Controller.Destroyed then
            return Controller
        end
        Controller.LightEmission = math.clamp(tonumber(Emission) or Controller.LightEmission, 0, 1)
        Controller.LightInfluence = math.clamp(tonumber(Influence) or Controller.LightInfluence, 0, 1)
        ApplyProperties()
        FireChanged("Light", Controller.LightEmission, Controller.LightInfluence)
        return Controller
    end

    function Controller:SetBrightness(Value)
        return Commit("Brightness", math.clamp(tonumber(Value) or Controller.Brightness, 0, 10), false)
    end

    function Controller:ApplyPreset(Name)
        if Controller.Destroyed then
            return false
        end
        local Preset = CharacterTrail.Presets[tostring(Name)]
        if not Preset then
            return false
        end
        local Values = ClonePreset(Preset)
        for Key, Value in Values do
            Controller[Key] = Value
        end
        if Controller.Enabled then
            ApplyProperties()
        end
        FireChanged("Preset", Name)
        return true
    end

    function Controller:Refresh()
        if Controller.Destroyed then
            return Controller
        end
        if Controller.Enabled then
            BindTarget()
        end
        return Controller
    end

    function Controller:GetTrail()
        return Controller.Trail
    end

    function Controller:GetState()
        return {
            Enabled = Controller.Enabled,
            Target = Controller.Target,
            AttachmentPart = Controller.AttachmentPart,
            AttachmentWidth = Controller.AttachmentWidth,
            VerticalOffset = Controller.VerticalOffset,
            ColorStart = Controller.ColorStart,
            ColorEnd = Controller.ColorEnd,
            ColorA = Controller.ColorStart,
            ColorB = Controller.ColorEnd,
            TransparencyStart = Controller.TransparencyStart,
            TransparencyEnd = Controller.TransparencyEnd,
            TransparencyMin = Controller.TransparencyStart,
            TransparencyMax = Controller.TransparencyEnd,
            WidthStart = Controller.WidthStart,
            WidthEnd = Controller.WidthEnd,
            Lifetime = Controller.Lifetime,
            MinLength = Controller.MinLength,
            MaxLength = Controller.MaxLength,
            Texture = Controller.Texture,
            TextureLength = Controller.TextureLength,
            TextureMode = Controller.TextureMode,
            FaceCamera = Controller.FaceCamera,
            LightEmission = Controller.LightEmission,
            LightInfluence = Controller.LightInfluence,
            Brightness = Controller.Brightness,
        }
    end

    function Controller:Destroy()
        if Controller.Destroyed then
            return
        end
        Controller.Destroyed = true
        Controller.Revision += 1
        DisconnectCharacterSignals()
        ClearInstances()
        ChangedEvent:Destroy()
    end

    if Controller.Enabled then
        BindTarget()
    end

    return Controller
end

return CharacterTrail
