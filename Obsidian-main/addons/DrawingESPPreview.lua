local Environment = getfenv()
local DrawingAPI = if type(Environment) == "table" then rawget(Environment, "Drawing") else nil
if type(DrawingAPI) ~= "table" then
    DrawingAPI = rawget(_G, "Drawing")
end

local DrawingESPPreview = {}

local function Set(Object, Property, Value)
    if Object then
        pcall(function()
            Object[Property] = Value
        end)
    end
end

local function Remove(Object)
    if not Object then
        return
    end
    pcall(function()
        if type(Object.Remove) == "function" then
            Object:Remove()
        elseif type(Object.Destroy) == "function" then
            Object:Destroy()
        end
    end)
end

local function NewDrawing(Type)
    if type(DrawingAPI) ~= "table" or type(DrawingAPI.new) ~= "function" then
        return nil
    end
    local Success, Object = pcall(DrawingAPI.new, Type)
    return Success and Object or nil
end

local function SetLine(Line, From, To, Color, Thickness, Transparency, Visible)
    if not Line then
        return
    end
    pcall(function()
        Line.From = From
        Line.To = To
        Line.Color = Color
        Line.Thickness = Thickness
        Line.Transparency = Transparency
        Line.Visible = Visible
    end)
end

local function SetText(Text, Value, Position, Color, Size, Visible)
    if not Text then
        return
    end
    pcall(function()
        Text.Text = Value
        Text.Position = Position
        Text.Color = Color
        Text.Size = Size
        Text.Center = true
        Text.Outline = true
        Text.OutlineColor = Color3.fromRGB(7, 9, 12)
        Text.Transparency = 1
        Text.Visible = Visible
    end)
end

local function ResolveText(State)
    local Top = ""
    if State.NameVisible and State.TeamVisible and State.Team ~= "" then
        Top = string.format("%s [%s]", State.Name or "", State.Team)
    elseif State.NameVisible then
        Top = State.Name or ""
    elseif State.TeamVisible and State.Team ~= "" then
        Top = string.format("[%s]", State.Team)
    end

    local Distance = State.Distance and string.format("%dm", math.max(0, math.floor(State.Distance + 0.5))) or ""
    local Bottom = ""
    if State.WeaponVisible and State.DistanceVisible and State.Weapon ~= "" and Distance ~= "" then
        Bottom = string.format("%s | %s", State.Weapon, Distance)
    elseif State.WeaponVisible then
        Bottom = State.Weapon or ""
    elseif State.DistanceVisible then
        Bottom = Distance
    end
    return Top, Bottom
end

function DrawingESPPreview.Create(Info)
    Info = Info or {}
    local Renderer = {
        Available = type(DrawingAPI) == "table" and type(DrawingAPI.new) == "function",
        Continuous = Info.Continuous == true,
        Entities = {},
        Previews = setmetatable({}, { __mode = "k" }),
        Color = typeof(Info.Color) == "Color3" and Info.Color or Color3.fromRGB(130, 164, 204),
        GradientColor = typeof(Info.GradientColor) == "Color3" and Info.GradientColor or Color3.fromRGB(204, 218, 235),
        Thickness = math.clamp(tonumber(Info.Thickness) or 1, 1, 4),
        OutlineThickness = math.clamp(tonumber(Info.OutlineThickness) or 3, 2, 6),
        TextSize = math.clamp(tonumber(Info.TextSize) or 13, 10, 24),
        TracerThickness = math.clamp(tonumber(Info.TracerThickness) or 1, 1, 4),
    }

    function Renderer:CreateEntity()
        local Entity = {
            Box = {},
            BoxOutline = {},
            Name = NewDrawing("Text"),
            Distance = NewDrawing("Text"),
            HealthBack = NewDrawing("Line"),
            HealthFill = NewDrawing("Line"),
            TracerOutline = NewDrawing("Line"),
            Tracer = NewDrawing("Line"),
            Visible = false,
        }
        for Index = 1, 4 do
            Entity.Box[Index] = NewDrawing("Line")
            Entity.BoxOutline[Index] = NewDrawing("Line")
        end
        table.insert(Renderer.Entities, Entity)
        return Entity
    end

    function Renderer:SetEntityVisible(Entity, Visible)
        if not Entity then
            return
        end
        Entity.Visible = Visible == true
        if Entity.Visible then
            return
        end
        for _, Object in Entity.Box do
            Set(Object, "Visible", false)
        end
        for _, Object in Entity.BoxOutline do
            Set(Object, "Visible", false)
        end
        for _, Key in { "Name", "Distance", "HealthBack", "HealthFill", "TracerOutline", "Tracer" } do
            Set(Entity[Key], "Visible", false)
        end
    end

    function Renderer:UpdateEntity(Entity, State)
        if not Entity or type(State) ~= "table" or type(State.Bounds) ~= "table" or State.Visible ~= true then
            Renderer:SetEntityVisible(Entity, false)
            return
        end

        local Bounds = State.Bounds
        local X = tonumber(Bounds.AbsoluteX or Bounds.X)
        local Y = tonumber(Bounds.AbsoluteY or Bounds.Y)
        local Width = tonumber(Bounds.Width)
        local Height = tonumber(Bounds.Height)
        if not X or not Y or not Width or not Height or Width <= 0 or Height <= 0 then
            Renderer:SetEntityVisible(Entity, false)
            return
        end

        Renderer:SetEntityVisible(Entity, true)
        local ColorA = typeof(State.Color) == "Color3" and State.Color or Renderer.Color
        local ColorB = typeof(State.GradientColor) == "Color3" and State.GradientColor or Renderer.GradientColor
        local TopLeft = Vector2.new(X, Y)
        local TopRight = Vector2.new(X + Width, Y)
        local BottomLeft = Vector2.new(X, Y + Height)
        local BottomRight = Vector2.new(X + Width, Y + Height)
        local From = { TopLeft, TopRight, BottomRight, BottomLeft }
        local To = { TopRight, BottomRight, BottomLeft, TopLeft }
        local Colors
        if State.GradientEnabled == false then
            Colors = { ColorA, ColorA, ColorA, ColorA }
        else
            Colors = { ColorA, ColorA:Lerp(ColorB, 0.34), ColorB, ColorA:Lerp(ColorB, 0.68) }
        end
        local BoxVisible = State.BoxVisible == true

        for Index = 1, 4 do
            SetLine(Entity.BoxOutline[Index], From[Index], To[Index], Color3.fromRGB(5, 7, 10), Renderer.OutlineThickness, 0.9, BoxVisible)
            SetLine(Entity.Box[Index], From[Index], To[Index], Colors[Index], Renderer.Thickness, 1, BoxVisible)
        end

        local TopText, BottomText = ResolveText(State)
        SetText(Entity.Name, TopText, Vector2.new(X + Width * 0.5, Y - Renderer.TextSize - 2), ColorA, Renderer.TextSize, TopText ~= "")
        SetText(Entity.Distance, BottomText, Vector2.new(X + Width * 0.5, Y + Height + 2), ColorB, math.max(10, Renderer.TextSize - 1), BottomText ~= "")

        local Health = math.clamp(tonumber(State.Health) or 1, 0, 1)
        local HealthX = X - 5
        local HealthBottom = Y + Height
        local HealthTop = Y
        local HealthFillTop = HealthBottom - Height * Health
        SetLine(Entity.HealthBack, Vector2.new(HealthX, HealthBottom), Vector2.new(HealthX, HealthTop), Color3.fromRGB(5, 7, 10), 4, 0.92, State.HealthVisible == true)
        SetLine(Entity.HealthFill, Vector2.new(HealthX, HealthBottom), Vector2.new(HealthX, HealthFillTop), Color3.fromHSV(Health * 0.33, 0.82, 1), 2, 1, State.HealthVisible == true)

        local ContentPosition = State.ContentPosition or Vector2.zero
        local ContentSize = State.ContentSize or Vector2.zero
        local TracerStart = Vector2.new(ContentPosition.X + ContentSize.X * 0.5, ContentPosition.Y + ContentSize.Y - 2)
        local TracerEnd = Vector2.new(X + Width * 0.5, Y + Height)
        SetLine(Entity.TracerOutline, TracerStart, TracerEnd, Color3.fromRGB(5, 7, 10), Renderer.TracerThickness + 2, 0.82, State.TracerVisible == true)
        SetLine(Entity.Tracer, TracerStart, TracerEnd, ColorB, Renderer.TracerThickness, 1, State.TracerVisible == true)
    end

    function Renderer:RemoveEntity(Entity)
        if not Entity then
            return
        end
        for _, Object in Entity.Box do
            Remove(Object)
        end
        for _, Object in Entity.BoxOutline do
            Remove(Object)
        end
        for _, Key in { "Name", "Distance", "HealthBack", "HealthFill", "TracerOutline", "Tracer" } do
            Remove(Entity[Key])
        end
        local Index = table.find(Renderer.Entities, Entity)
        if Index then
            table.remove(Renderer.Entities, Index)
        end
    end

    function Renderer:AttachPreview(Preview, Context)
        local Entity = Renderer.Previews[Preview]
        if not Entity then
            Entity = Renderer:CreateEntity()
            Renderer.Previews[Preview] = Entity
        end
        Renderer:UpdatePreview(Preview, Context)
        return Entity
    end

    function Renderer:UpdatePreview(Preview, Context)
        local Entity = Renderer.Previews[Preview]
        if not Entity then
            return
        end
        Renderer:UpdateEntity(Entity, Context)
    end

    function Renderer:SetPreviewVisible(Preview, Visible)
        Renderer:SetEntityVisible(Renderer.Previews[Preview], Visible)
    end

    function Renderer:DetachPreview(Preview)
        local Entity = Renderer.Previews[Preview]
        Renderer.Previews[Preview] = nil
        Renderer:RemoveEntity(Entity)
    end

    function Renderer:SetColors(Color, GradientColor)
        if typeof(Color) == "Color3" then
            Renderer.Color = Color
        end
        if typeof(GradientColor) == "Color3" then
            Renderer.GradientColor = GradientColor
        end
    end

    function Renderer:Destroy()
        for Index = #Renderer.Entities, 1, -1 do
            Renderer:RemoveEntity(Renderer.Entities[Index])
        end
        table.clear(Renderer.Previews)
    end

    return Renderer
end

return DrawingESPPreview
