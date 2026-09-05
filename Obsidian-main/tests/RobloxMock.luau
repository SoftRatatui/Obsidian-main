local Mock = { Objects = {}, Deferred = {} }

function Mock.Signal()
    local Signal = { Listeners = {} }
    function Signal:Connect(Callback)
        local Connection = { Connected = true }
        function Connection:Disconnect()
            Connection.Connected = false
        end
        Connection.Callback = Callback
        table.insert(Signal.Listeners, Connection)
        return Connection
    end
    function Signal:Once(Callback)
        local Connection
        Connection = Signal:Connect(function(...)
            Connection:Disconnect()
            Callback(...)
        end)
        return Connection
    end
    function Signal:Fire(...)
        for _, Connection in table.clone(Signal.Listeners) do
            if Connection.Connected then
                Connection.Callback(...)
            end
        end
    end
    return Signal
end

Mock.UDim = {
    new = function(Scale, Offset)
        return { Scale = Scale, Offset = Offset }
    end,
}
Mock.UDim2 = {}
function Mock.UDim2.new(XScale, XOffset, YScale, YOffset)
    return { _type = "UDim2", X = Mock.UDim.new(XScale, XOffset), Y = Mock.UDim.new(YScale, YOffset) }
end
function Mock.UDim2.fromOffset(X, Y)
    return Mock.UDim2.new(0, X, 0, Y)
end
function Mock.UDim2.fromScale(X, Y)
    return Mock.UDim2.new(X, 0, Y, 0)
end
Mock.Vector2 = {
    new = function(X, Y)
        return { _type = "Vector2", X = X, Y = Y }
    end,
}
Mock.Vector2.zero = Mock.Vector2.new(0, 0)
Mock.Color3 = {}
function Mock.Color3.new(R, G, B)
    local Color = { _type = "Color3", R = R, G = G, B = B }
    function Color:Lerp(Other, Alpha)
        return Mock.Color3.new(R + (Other.R - R) * Alpha, G + (Other.G - G) * Alpha, B + (Other.B - B) * Alpha)
    end
    return Color
end
function Mock.Color3.fromRGB(R, G, B)
    return Mock.Color3.new(R / 255, G / 255, B / 255)
end
Mock.Enum = setmetatable({}, {
    __index = function(Self, Key)
        local Group = setmetatable({}, {
            __index = function(GroupSelf, Name)
                local Item = { _type = "EnumItem", EnumType = GroupSelf, Name = Name }
                rawset(GroupSelf, Name, Item)
                return Item
            end,
        })
        rawset(Self, Key, Group)
        return Group
    end,
})
Mock.Font = {
    fromEnum = function()
        return {}
    end,
}
Mock.TweenInfo = {
    new = function(Time)
        return { Time = Time }
    end,
}
Mock.ColorSequence = {
    new = function(...)
        return { ... }
    end,
}
Mock.NumberSequence = {
    new = function(...)
        return { ... }
    end,
}
Mock.ColorSequenceKeypoint = {
    new = function(...)
        return { ... }
    end,
}
Mock.NumberSequenceKeypoint = {
    new = function(...)
        return { ... }
    end,
}
Mock.typeof = function(Value)
    return type(Value) == "table" and Value._type or type(Value)
end
Mock.task = {
    spawn = function(Callback, ...)
        return Callback(...)
    end,
    defer = function(Callback)
        table.insert(Mock.Deferred, Callback)
    end,
    delay = function(_, Callback)
        table.insert(Mock.Deferred, Callback)
    end,
}

Mock.Instance = {}
function Mock.Instance.new(ClassName)
    local Properties = {
        _type = "Instance",
        ClassName = ClassName,
        Name = ClassName,
        Size = Mock.UDim2.fromOffset(0, 0),
        Position = Mock.UDim2.fromOffset(0, 0),
        AbsoluteSize = Mock.Vector2.new(600, 400),
        AbsolutePosition = Mock.Vector2.zero,
        Visible = true,
        Active = true,
        ZIndex = 1,
        Text = "",
        Image = "",
    }
    local Object, Methods, Signals = {}, {}, {}
    function Methods:IsA(Name)
        return Name == ClassName or Name == "GuiObject" or Name == "GuiBase2d"
    end
    function Methods:GetPropertyChangedSignal(Name)
        Signals[Name] = Signals[Name] or Mock.Signal()
        return Signals[Name]
    end
    function Methods:IsDescendantOf(Ancestor)
        local Parent = Properties.Parent
        while Parent do
            if Parent == Ancestor then
                return true
            end
            Parent = Parent.Parent
        end
        return false
    end
    function Methods:GetDescendants()
        local Children = {}
        for _, Child in Mock.Objects do
            if Child:IsDescendantOf(Object) then
                table.insert(Children, Child)
            end
        end
        return Children
    end
    function Methods:FindFirstChildOfClass(Name)
        for _, Child in Mock.Objects do
            if Child.Parent == Object and Child.ClassName == Name then
                return Child
            end
        end
        return nil
    end
    function Methods:Destroy()
        if Properties.Destroyed then
            return
        end
        Object.Destroying:Fire()
        for _, Child in Methods:GetDescendants() do
            Child:Destroy()
        end
        Properties.Destroyed = true
        Properties.Parent = nil
        for _, Signal in Signals do
            for _, Connection in Signal.Listeners do
                Connection:Disconnect()
            end
        end
    end
    setmetatable(Object, {
        __index = function(_, Key)
            if Methods[Key] then
                return Methods[Key]
            end
            if
                Key == "Activated"
                or Key == "MouseEnter"
                or Key == "MouseLeave"
                or Key == "Destroying"
                or Key == "InputBegan"
                or Key == "InputChanged"
            then
                return Methods:GetPropertyChangedSignal(Key)
            end
            return Properties[Key]
        end,
        __newindex = function(_, Key, Value)
            Properties[Key] = Value
        end,
    })
    table.insert(Mock.Objects, Object)
    return Object
end

local TweenService = {}
function TweenService:Create(Object, _, Values)
    local Tween = { Completed = Mock.Signal() }
    function Tween:Play()
        for Key, Value in Values do
            Object[Key] = Value
        end
    end
    function Tween:Cancel()
        Tween.Completed:Fire()
    end
    function Tween:Destroy()
        Tween.Destroyed = true
    end
    return Tween
end
Mock.game = {
    GetService = function(_, Name)
        if Name == "TweenService" then
            return TweenService
        end
        if Name == "Workspace" then
            return Mock.Workspace
        end
        error("Unexpected service " .. Name)
    end,
}

function Mock.Library()
    local Library = { Registry = {}, Unloads = {} }
    Library.Scheme = setmetatable({ Font = {} }, {
        __index = function()
            return Mock.Color3.fromRGB(30, 32, 38)
        end,
    })
    function Library:AddToRegistry(Object, Properties)
        Library.Registry[Object] = Properties
    end
    function Library:RemoveFromRegistry(Object)
        Library.Registry[Object] = nil
    end
    function Library:OnUnload(Callback)
        table.insert(Library.Unloads, Callback)
    end
    function Library:SafeCallback(Callback, ...)
        return Callback(...)
    end
    return Library
end

Mock.Workspace = Mock.Instance.new("Workspace")
Mock.Workspace.CurrentCamera = Mock.Instance.new("Camera")
Mock.Workspace.CurrentCamera.ViewportSize = Mock.Vector2.new(1280, 720)

function Mock.HostLibrary()
    local Library = Mock.Library()
    Library.ScreenGui = Mock.Instance.new("ScreenGui")
    Library.Toggled = true
    Library.Window = { VisibilityChanged = { Event = Mock.Signal() } }
    function Library:GetAddonStyle()
        return {
            WindowWidth = 420,
            HeaderHeight = 38,
            ControlHeight = 28,
            WindowHeight = 480,
            Padding = 10,
            Gap = 8,
            Radius = 4,
            ControlRadius = 3,
            StrokeThickness = 1,
            OutlineTransparency = 0.5,
            TextSize = 14,
            CaptionSize = 12,
            Motion = true,
        }
    end
    function Library:GetDesignToken(_, Fallback)
        return Fallback
    end
    function Library:AddSoftShadow() end
    function Library:CreateDivider() end
    function Library:MatchParity(Height, Size)
        return Size + (Height - Size) % 2
    end
    function Library:CenterOffset(Height, Size)
        return math.floor((Height - Size) / 2)
    end
    function Library:GetCustomIcon()
        return {}
    end
    Library.GetIcon = Library.GetCustomIcon
    function Library:GetMotion()
        return Mock.TweenInfo.new(0.1)
    end
    function Library:GetAccentSurfaceColor()
        return Library.Scheme.AccentColor
    end
    function Library:MakeDraggable() end
    function Library:MakeResizable() end
    Library.Tweens = {}
    function Library:CancelTween(Object)
        local Tween = Library.Tweens[Object]
        Library.Tweens[Object] = nil
        if Tween then
            Tween:Cancel()
        end
    end
    function Library:PlayTween(Object, _, Info, Properties)
        Library:CancelTween(Object)
        local Tween = TweenService:Create(Object, Info, Properties)
        Library.Tweens[Object] = Tween
        Tween:Play()
        return Tween
    end
    return Library
end

function Mock.New(Library, Class, Properties)
    local Object = Mock.Instance.new(Class)
    for Key, Value in Properties do
        Object[Key] = Value
    end
    Library:AddToRegistry(Object, {})
    return Object
end

return Mock
