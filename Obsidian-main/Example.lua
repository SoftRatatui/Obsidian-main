












assert(type(loadstring) == "function", "This example requires an executor with loadstring support.")

local PRIMARY_REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local ExecutorRequest = request or http_request or (syn and syn.request)

local function DownloadSource(Url)
	local RequestError

	if type(ExecutorRequest) == "function" then
		local Success, Response = pcall(ExecutorRequest, {
			Url = Url,
			Method = "GET",
		})

		if Success then
			local Body = typeof(Response) == "table" and (Response.Body or Response.body) or Response
			local StatusCode = typeof(Response) == "table" and (Response.StatusCode or Response.Status) or nil

			if type(Body) == "string" and #Body > 0 and (type(StatusCode) ~= "number" or (StatusCode >= 200 and StatusCode < 300)) then
				return true, Body
			end

			RequestError = string.format("request returned status %s", tostring(StatusCode or "unknown"))
		else
			RequestError = tostring(Response)
		end
	end

	local Success, Response = pcall(game.HttpGet, game, Url)
	if Success and type(Response) == "string" and #Response > 0 then
		return true, Response
	end

	return false, RequestError or tostring(Response)
end

local function CleanPreview(Source)
	local Preview = tostring(Source):sub(1, 120)
	return Preview:gsub("[%c]+", " ")
end

local function TryModule(BaseUrl, Path)
	local Url = BaseUrl .. Path
	local Downloaded, Source = DownloadSource(Url)

	if not Downloaded then
		return nil, string.format("%s: download failed (%s)", Url, tostring(Source))
	end

	if type(Source) ~= "string" or #Source < 16 then
		return nil, string.format("%s: empty or invalid response", Url)
	end

	local Chunk, CompileError = loadstring(Source)
	if not Chunk then
		return nil, string.format(
			"%s: response is not valid Lua (%s). Response starts with: %s",
			Url,
			tostring(CompileError),
			CleanPreview(Source)
		)
	end

	local Executed, Module = pcall(Chunk)
	if not Executed then
		return nil, string.format("%s: module execution failed (%s)", Url, tostring(Module))
	end

	return Module, nil, BaseUrl
end

local function LoadModule(Path, Required, PreferredBase)
	local Bases = {}
	local Added = {}

	local function AddBase(BaseUrl)
		if BaseUrl and not Added[BaseUrl] then
			Added[BaseUrl] = true
			table.insert(Bases, BaseUrl)
		end
	end

	AddBase(PreferredBase)
	AddBase(PRIMARY_REPOSITORY)

	local Errors = {}
	for _, BaseUrl in Bases do
		local Module, ModuleError, UsedBase = TryModule(BaseUrl, Path)
		if Module then
			return Module, UsedBase
		end

		table.insert(Errors, ModuleError)
	end

	local Message = string.format("Could not load %s:\n- %s", Path, table.concat(Errors, "\n- "))
	if Required then
		error(Message, 0)
	end

	warn("[MonHub Example] " .. Message)
	return nil
end

local Library, ActiveRepository = LoadModule("Library.lua", true)
local ThemeManager = LoadModule("addons/ThemeManager.lua", false, ActiveRepository)
local SaveManager = LoadModule("addons/SaveManager.lua", false, ActiveRepository)
local VisualPreview = LoadModule("addons/VisualPreview.lua", false, ActiveRepository)
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true


Library:SetTheme("Graphite")
Library:SetClickSound(92679954573730, 0.3)

local Window = Library:CreateWindow({
	Title = "MonHub Private",
	Footer = "Beta v0.0.1",
	NotifySide = "Right",
	Center = true,
	AutoShow = true,
	Resizable = false,
	GlobalSearch = true,
	EnableSidebarResize = false,
	ResponsiveLayout = true,
	SingleColumnWidth = 540,
	HideSearchAtWidth = 210,
	ShowCustomCursor = true,
	Font = Enum.Font.Gotham,
	CornerRadius = 6,
	ShowCompactLauncher = true,
	CompactLauncherIcon = "maximize-2",
	CompactLauncherSize = 36,
	CompactLauncherWidth = 172,
	CompactLauncherPosition = UDim2.fromScale(0.5, 0.5),
	CompactLauncherAnchorPoint = Vector2.new(0.5, 0.5),
	CompactLauncherDraggable = true,
	TabTransitionTime = 0.2,
	TabSwipeOffset = 8,
	TabSwipeFrom = "bottom",
	Size = Library.IsMobile and UDim2.fromOffset(520, 480) or UDim2.fromOffset(760, 660),
	Animations = {
		ToggleWindow = true,
		TabSwitch = true,
		Groupbox = true,
		Dropdown = true,
		KeyPicker = true,
	},
})

local function Notify(Title, Description, Duration)
	return Library:Notify({
		Title = Title,
		Description = Description,
		Time = Duration or 4,
	})
end

local function SetGroupOrder(Group, Order)
	if Group.SetOrder then
		Group:SetOrder(Order)
	elseif Group.BoxHolder then
		Group.BoxHolder.LayoutOrder = Order
	end
end

local Tabs = {
	Controls = Window:AddTab("Controls", "sliders-horizontal"),
	Media = Window:AddTab("Media", "gallery-horizontal-end"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Advanced = Window:AddTab("Advanced", "wand-sparkles"),
	KeySystem = Window:AddKeyTab("Key System"),
	Settings = Window:AddTab("UI Settings", "settings-2"),
}


local BasicGroup = Tabs.Controls:AddLeftGroupbox("Basic controls", "component")
BasicGroup:AddLabel("All common controls are included in this smoke test.", true)
BasicGroup:AddDivider()

local FeatureToggle = BasicGroup:AddToggle("FeatureEnabled", {
	Text = "Main feature",
	Default = true,
	Tooltip = "A toggle with color and keybind addons",
	Callback = function(Value)
		print("[MonHub] FeatureEnabled:", Value)
	end,
})

FeatureToggle:AddColorPicker("FeatureColor", {
	Title = "Feature color",
	Default = Color3.fromRGB(121, 126, 139),
	Transparency = 0,
})

FeatureToggle:AddKeyPicker("FeatureKeybind", {
	Text = "Main feature",
	Default = "G",
	Mode = "Toggle",
	SyncToggleState = true,
})

BasicGroup:AddToggle("SecondaryToggle", {
	Text = "Secondary toggle",
	Default = false,
})

BasicGroup:AddInput("ProfileName", {
	Text = "Profile name",
	Default = "Default profile",
	Placeholder = "Enter a profile name...",
	ClearTextOnFocus = false,
})

BasicGroup:AddSlider("PowerLevel", {
	Text = "Power level",
	Default = 65,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
})

BasicGroup:AddButton("Read current values", function()
	Notify(
		"Current values",
		string.format(
			"Feature: %s\nPower: %s%%\nProfile: %s",
			tostring(Toggles.FeatureEnabled.Value),
			tostring(Options.PowerLevel.Value),
			tostring(Options.ProfileName.Value)
		)
	)
end)

local DropdownGroup = Tabs.Controls:AddRightGroupbox("Dropdowns", "list-filter")
DropdownGroup:AddDropdown("Quality", {
	Text = "Quality",
	Values = { "Low", "Balanced", "High", "Ultra" },
	Default = "Balanced",
})

DropdownGroup:AddDropdown("Modules", {
	Text = "Enabled modules",
	Values = { "Combat", "Visuals", "Movement", "Utility" },
	Default = { "Visuals", "Utility" },
	Multi = true,
	DragSelect = true,
})

DropdownGroup:AddDropdown("SearchableCommand", {
	Text = "Search command",
	Values = {
		"Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta",
		"Eta", "Theta", "Iota", "Kappa", "Lambda", "Omega",
	},
	Default = "Alpha",
	Searchable = true,
	MaxVisibleDropdownItems = 7,
})

DropdownGroup:AddDropdown("SelectedPlayer", {
	Text = "Player",
	SpecialType = "Player",
	ExcludeLocalPlayer = false,
})

DropdownGroup:AddDropdown("SelectedTeam", {
	Text = "Team",
	SpecialType = "Team",
})

DropdownGroup:AddLabel("Standalone color picker"):AddColorPicker("StandaloneColor", {
	Title = "Standalone color",
	Default = Color3.fromRGB(178, 142, 231),
	Transparency = 0,
})

DropdownGroup:AddLabel("Press keybind"):AddKeyPicker("PressKeybind", {
	Text = "Show notification",
	Default = "H",
	Mode = "Press",
	Callback = function()
		Notify("Keybind pressed", "The H keybind callback was executed.")
	end,
})


local function CreateR6Preview()
	local Model = Instance.new("Model")
	Model.Name = "MonHubR6Preview"

	local function CreatePart(Name, Size, Position, Color, Material, Transparency)
		local Part = Instance.new("Part")
		Part.Name = Name
		Part.Anchored = true
		Part.CanCollide = false
		Part.CastShadow = false
		Part.Color = Color
		Part.Material = Material or Enum.Material.SmoothPlastic
		Part.Size = Size
		Part.CFrame = CFrame.new(Position)
		Part.Transparency = Transparency or 0
		Part.TopSurface = Enum.SurfaceType.Smooth
		Part.BottomSurface = Enum.SurfaceType.Smooth
		Part.Parent = Model
		return Part
	end

	local Skin = Color3.fromRGB(239, 196, 156)
	local Shirt = Color3.fromRGB(86, 91, 105)
	local Pants = Color3.fromRGB(39, 41, 47)
	local Torso = CreatePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), Shirt)
	local Head = CreatePart("Head", Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0), Skin)
	local RightArm = CreatePart("Right Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), Skin)
	local LeftArm = CreatePart("Left Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), Skin)
	local RightLeg = CreatePart("Right Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), Pants)
	local LeftLeg = CreatePart("Left Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), Pants)

	local HeadMesh = Instance.new("SpecialMesh")
	HeadMesh.MeshType = Enum.MeshType.Head
	HeadMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	HeadMesh.Parent = Head

	local Face = Instance.new("Decal")
	Face.Face = Enum.NormalId.Back
	Face.Texture = "rbxasset://textures/face.png"
	Face.Parent = Head

	Model.PrimaryPart = Torso
	return Model
end

local MediaLeft = Tabs.Media:AddLeftGroupbox("R6 character preview", "user-round")
MediaLeft:AddImage("ShowcaseImage", {
	Image = "sparkles",
	Color = Color3.fromRGB(184, 189, 201),
	BackgroundTransparency = 0.08,
	ScaleType = Enum.ScaleType.Fit,
	Height = 82,
})

MediaLeft:AddViewport("ShowcaseViewport", {
	Object = CreateR6Preview(),
	Clone = false,
	AutoFocus = true,
	Interactive = true,
	Height = 260,
})
MediaLeft:AddLabel("Left or right drag to rotate. Use the mouse wheel or pinch to zoom.", true)

local CustomCard = Instance.new("Frame")
CustomCard.Name = "CustomPassthroughCard"
CustomCard.BackgroundColor3 = Library:GetAccentSurfaceColor(0.06)
CustomCard.BorderSizePixel = 0
CustomCard.Size = UDim2.fromScale(1, 1)

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 6)
CardCorner.Parent = CustomCard

local CardStroke = Instance.new("UIStroke")
CardStroke.Color = Library.Scheme.OutlineColor
CardStroke.Transparency = 0.25
CardStroke.Parent = CustomCard

local CardText = Instance.new("TextLabel")
CardText.BackgroundTransparency = 1
CardText.Position = UDim2.fromOffset(12, 8)
CardText.Size = UDim2.new(1, -24, 1, -16)
CardText.Font = Enum.Font.Gotham
CardText.Text = "Custom GuiBase2d embedded through UIPassthrough"
CardText.TextColor3 = Library.Scheme.FontColor
CardText.TextSize = 14
CardText.TextWrapped = true
CardText.Parent = CustomCard

Library:AddToRegistry(CustomCard, {
	BackgroundColor3 = function()
		return Library:GetAccentSurfaceColor(0.06)
	end,
})
Library:AddToRegistry(CardStroke, {
	Color = "OutlineColor",
})
Library:AddToRegistry(CardText, {
	TextColor3 = "FontColor",
})

local MediaRight = Tabs.Media:AddRightGroupbox("Video and custom UI", "video")
local ShowcaseVideo = MediaRight:AddVideo("ShowcaseVideo", {
	Video = "rbxassetid://5608324215",
	Looped = true,
	Playing = true,
	Volume = 0,
	Height = 175,
})

MediaRight:AddToggle("VideoPlaying", {
	Text = "Play video",
	Default = true,
	Callback = function(Value)
		ShowcaseVideo:SetPlaying(Value)
	end,
})

MediaRight:AddUIPassthrough("CustomUI", {
	Instance = CustomCard,
	Height = 76,
})


local ESPPreview
if VisualPreview then
	local Created, PreviewOrError = pcall(VisualPreview.Create, Library, Tabs.Visuals, {
		Name = "ESP preview",
		Width = 300,
		Height = 420,
		Color = Color3.fromRGB(119, 166, 209),
	})

	if Created then
		ESPPreview = PreviewOrError
	else
		warn("[MonHub Example] VisualPreview disabled: " .. tostring(PreviewOrError))
	end
end

local VisualControls = Tabs.Visuals:AddLeftGroupbox("ESP controls", "eye")
VisualControls:AddLabel("This local R6 preview is isolated from players and shows the selected ESP appearance.", true)

local ESPEnabled = VisualControls:AddToggle("ESPEnabled", {
	Text = "Enable ESP preview",
	Default = false,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetEnabled(Value)
		end
	end,
})

ESPEnabled:AddColorPicker("ESPPreviewColor", {
	Title = "ESP color",
	Default = Color3.fromRGB(119, 166, 209),
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetColor(Value)
		end
	end,
})

VisualControls:AddToggle("ESPBox", {
	Text = "Box",
	Default = true,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetBoxVisible(Value)
		end
	end,
})

VisualControls:AddToggle("ESPName", {
	Text = "Name",
	Default = true,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetNameVisible(Value)
		end
	end,
})

VisualControls:AddToggle("ESPDistance", {
	Text = "Distance",
	Default = true,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetDistanceVisible(Value)
		end
	end,
})

VisualControls:AddSlider("ESPPreviewDistance", {
	Text = "Preview distance",
	Default = 86,
	Min = 5,
	Max = 500,
	Rounding = 0,
	Suffix = "m",
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetDistance(Value)
		end
	end,
})

VisualControls:AddToggle("ESPHealth", {
	Text = "Health bar",
	Default = true,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetHealthVisible(Value)
		end
	end,
})

VisualControls:AddToggle("ESPTracer", {
	Text = "Tracer",
	Default = false,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetTracerVisible(Value)
		end
	end,
})

VisualControls:AddToggle("ESPHighlight", {
	Text = "Highlight",
	Default = false,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetHighlightVisible(Value)
		end
	end,
})

if ESPPreview then
	ESPPreview:SetEnabled(ESPEnabled.Value)
	ESPPreview:SetBoxVisible(Toggles.ESPBox.Value)
	ESPPreview:SetNameVisible(Toggles.ESPName.Value)
	ESPPreview:SetDistanceVisible(Toggles.ESPDistance.Value)
	ESPPreview:SetDistance(Options.ESPPreviewDistance.Value)
	ESPPreview:SetHealthVisible(Toggles.ESPHealth.Value)
	ESPPreview:SetTracerVisible(Toggles.ESPTracer.Value)
	ESPPreview:SetHighlightVisible(Toggles.ESPHighlight.Value)
end


local AdvancedActions = Tabs.Advanced:AddLeftGroupbox("System actions", "blocks")

AdvancedActions:AddButton({
	Text = "Show notification",
	Variant = "Primary",
	Func = function()
		Notify("MonHub is ready", "Notifications support a title, description, and duration.")
	end,
})

AdvancedActions:AddButton("Open dialog", function()
	local Dialog = Window:AddDialog("ShowcaseDialog", {
		Title = "Dialog test",
		Description = "This dialog contains controls and multiple footer button styles.",
		Icon = "message-square-more",
		AutoDismiss = false,
		OutsideClickDismiss = true,
		FooterButtons = {
			Cancel = {
				Title = "Cancel",
				Variant = "Secondary",
				Order = 1,
				Callback = function(CurrentDialog)
					CurrentDialog:Dismiss()
				end,
			},
			Confirm = {
				Title = "Confirm",
				Variant = "Primary",
				Order = 2,
				Callback = function(CurrentDialog)
					local Value = Options.DialogInput and Options.DialogInput.Value or "No input"
					Notify("Dialog confirmed", tostring(Value))
					CurrentDialog:Dismiss()
				end,
			},
		},
	})

	Dialog:AddInput("DialogInput", {
		Text = "Message",
		Default = "Hello from MonHub",
		ClearTextOnFocus = false,
	})
	Dialog:AddToggle("DialogOption", {
		Text = "Additional option",
		Default = true,
	})
	Dialog:Resize()
end)

AdvancedActions:AddButton("Run loading test", function()
	if Library.ActiveLoading then
		Notify("Loading is active", "Wait for the current loading test to finish.")
		return
	end

	task.spawn(function()
		local Steps = {
			{ "Preparing interface", "Checking the active theme and controls" },
			{ "Loading settings", "Reading demonstration values" },
			{ "Optimizing", "Updating only the required objects" },
			{ "Final check", "The test is almost complete" },
			{ "Complete", "All loading steps passed" },
		}

		local Loading = Library:CreateLoading({
			Title = "MonHub Beta",
			Icon = "orbit",
			LoadingIcon = "loader-circle",
			CurrentStep = 0,
			TotalSteps = #Steps,
			AutoResizeHeight = true,
			AlwaysOnTop = true,
			WindowWidth = 470,
			WindowHeight = 270,
		})

		for Index, Step in Steps do
			if Loading.Destroyed or Library.Unloaded then
				return
			end

			Loading:SetMessage(Step[1])
			Loading:SetDescription(Step[2])
			Loading:SetCurrentStep(Index)
			task.wait(0.4)
		end

		task.wait(0.25)
		if not Loading.Destroyed then
			Loading:Continue()
		end
		Notify("Loading complete", "The loading screen passed the smoke test.")
	end)
end)

local ButtonStyles = Tabs.Advanced:AddRightGroupbox("Button styles", "mouse-pointer-click")

ButtonStyles:AddButton({
	Text = "Default action",
	Variant = "Default",
	Func = function()
		Notify("Default action", "Neutral actions use the standard surface.")
	end,
})

ButtonStyles:AddButton({
	Text = "Primary action",
	Variant = "Primary",
	Func = function()
		Notify("Primary action", "Primary actions use a restrained accent surface.")
	end,
})

ButtonStyles:AddButton({
	Text = "Ghost action",
	Variant = "Ghost",
	Func = function()
		Notify("Ghost action", "Secondary actions stay visually quiet.")
	end,
})

ButtonStyles:AddButton({
	Text = "Warning action",
	Variant = "Warning",
	Icon = "triangle-alert",
	Func = function()
		Notify("Warning action", "Warning actions use a separate semantic icon.")
	end,
})

ButtonStyles:AddButton({
    Text = "Danger action",
	Variant = "Danger",
	Icon = "octagon-x",
	DoubleClick = true,
	Func = function()
		Notify("Danger action", "The confirmation was accepted.")
    end,
})

ButtonStyles:AddDivider()

ButtonStyles:AddToggle("WarningToggleStyle", {
    Text = "Warning toggle",
    Default = true,
    Variant = "Warning",
})

ButtonStyles:AddToggle("DangerToggleStyle", {
    Text = "Danger toggle",
    Default = false,
    Variant = "Danger",
    ConfirmTitle = "Enable danger toggle?",
    ConfirmDescription = "This change may affect your session.",
})

local DraggableLabel
AdvancedActions:AddButton("Create draggable label", function()
	if not DraggableLabel or DraggableLabel.Destroyed then
		DraggableLabel = Library:AddDraggableLabel({
			Text = "MonHub | draggable label",
			Icon = "grip",
		})
	else
		DraggableLabel:SetVisible(true)
	end
end)

local DraggableButton
AdvancedActions:AddButton("Create draggable button", function()
	if not DraggableButton or DraggableButton.Destroyed then
		DraggableButton = Library:AddDraggableButton("Quick toggle", function()
			Library:Toggle()
		end)
	end
end)

local DependencyGroup = Tabs.Advanced:AddRightGroupbox("Dependencies", "workflow")
DependencyGroup:AddToggle("AdvancedMode", {
	Text = "Advanced mode",
	Default = true,
})
DependencyGroup:AddLabel("The controls below are visible only while Advanced mode is enabled.", true)

local DependencyBox = DependencyGroup:AddDependencyBox()
DependencyBox:AddSlider("DependencyValue", {
	Text = "Dependent value",
	Default = 25,
	Min = 0,
	Max = 50,
	Rounding = 0,
})
DependencyBox:AddButton("Read dependent value", function()
	Notify("Dependency box", "Value: " .. tostring(Options.DependencyValue.Value))
end)
DependencyBox:SetupDependencies({ { Toggles.AdvancedMode, true } })

local AdvancedTabbox = Tabs.Advanced:AddRightTabbox("Tabbox showcase")
local RuntimeTab = AdvancedTabbox:AddTab("Runtime")
RuntimeTab:AddLabel("A compact tab container inside a normal page.", true)
RuntimeTab:AddToggle("RuntimeEnabled", { Text = "Runtime enabled", Default = true })

local StyleTab = AdvancedTabbox:AddTab("Style")
StyleTab:AddLabel("Graphite uses layered neutral-gray surfaces, a muted slate accent, and compact geometry.", true)
StyleTab:AddButton("Reapply Graphite", function()
	if ThemeManager and ThemeManager.ApplyTheme then
		ThemeManager:ApplyTheme(ThemeManager.FallbackThemeName or "Default")
	else
		Library:SetTheme("Graphite")
	end
end)


Tabs.KeySystem:AddLabel({
	Text = "Test key: <b>MONHUB</b>",
	DoesWrap = true,
	Size = 16,
})

Tabs.KeySystem:AddKeyBox(function(ReceivedKey)
	local Success = ReceivedKey == "MONHUB"
	Notify(
		Success and "Key accepted" or "Invalid key",
		string.format("Received: %s\nSuccess: %s", tostring(ReceivedKey), tostring(Success))
	)
end)


local MenuGroup = Tabs.Settings:AddLeftGroupbox("Interface", "panel-left")
SetGroupOrder(MenuGroup, -100)

local WatermarkEnabled = true
local WatermarkShowFPS = true
local WatermarkShowPing = true
local WatermarkFPS = 0
local WatermarkPing = 0
local WatermarkFrames = 0
local WatermarkElapsed = 0

local function RefreshWatermark()
	local Sections = { "MonHub" }
	if WatermarkShowFPS then
		table.insert(Sections, string.format("%d FPS", WatermarkFPS))
	end
	if WatermarkShowPing then
		table.insert(Sections, string.format("%d ms", WatermarkPing))
	end
	Library:SetWatermark(table.concat(Sections, "  |  "))
	Library:SetWatermarkVisibility(WatermarkEnabled)
end

local function ReadPing()
	local Success, Value = pcall(function()
		return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if not Success then
		return 0
	end
	return math.max(0, math.floor((tonumber(Value) or 0) + 0.5))
end

local WatermarkToggle = MenuGroup:AddToggle("WatermarkEnabled", {
	Text = "Watermark",
	Default = true,
	Callback = function(Value)
		WatermarkEnabled = Value
		WatermarkFrames = 0
		WatermarkElapsed = 0
		RefreshWatermark()
	end,
})

local WatermarkSettings = MenuGroup:AddDependencyBox()
WatermarkSettings:AddToggle("WatermarkFPS", {
	Text = "Show FPS",
	Default = true,
	Callback = function(Value)
		WatermarkShowFPS = Value
		WatermarkFrames = 0
		WatermarkElapsed = 0
		RefreshWatermark()
	end,
})
WatermarkSettings:AddToggle("WatermarkPing", {
	Text = "Show ping",
	Default = true,
	Callback = function(Value)
		WatermarkShowPing = Value
		WatermarkElapsed = 0
		RefreshWatermark()
	end,
})
WatermarkSettings:AddDropdown("WatermarkSide", {
	Text = "Watermark side",
	Values = { "Left", "Right" },
	Default = "Left",
	Callback = function(Value)
		Library:SetWatermarkSide(Value)
	end,
})
WatermarkSettings:AddToggle("WatermarkDraggable", {
	Text = "Draggable watermark",
	Default = true,
	Callback = function(Value)
		Library:SetWatermarkDraggable(Value)
	end,
})
WatermarkSettings:SetupDependencies({ { WatermarkToggle, true } })

Library:GiveSignal(RunService.RenderStepped:Connect(function(DeltaTime)
	if not WatermarkEnabled or not (WatermarkShowFPS or WatermarkShowPing) then
		return
	end

	WatermarkElapsed += DeltaTime
	if WatermarkShowFPS then
		WatermarkFrames += 1
	end
	if WatermarkElapsed < 0.5 then
		return
	end

	if WatermarkShowFPS then
		WatermarkFPS = math.floor(WatermarkFrames / WatermarkElapsed + 0.5)
	end
	if WatermarkShowPing then
		WatermarkPing = ReadPing()
	end
	WatermarkFrames = 0
	WatermarkElapsed = 0
	RefreshWatermark()
end))

RefreshWatermark()
MenuGroup:AddToggle("KeybindMenuOpen", {
	Text = "Show keybind menu",
	Default = Library.KeybindFrame.Visible,
	Callback = function(Value)
		Library:SetKeybindMenuVisible(Value)
	end,
})

MenuGroup:AddToggle("CustomCursor", {
	Text = "Custom cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddToggle("ResponsiveLayout", {
	Text = "Responsive layout",
	Default = true,
	Callback = function(Value)
		Window:SetResponsiveLayoutEnabled(Value)
	end,
})

MenuGroup:AddToggle("AlwaysOnTop", {
	Text = "Always on top",
	Default = Window.AlwaysOnTop,
	Callback = function(Value)
		Window:SetAlwaysOnTop(Value)
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Text = "Notification side",
	Values = { "Left", "Right" },
	Default = "Right",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIScale", {
	Text = "DPI scale",
	Values = { "75%", "100%", "125%", "150%" },
	Default = "100%",
	Callback = function(Value)
		Library:SetDPIScale(tonumber(Value:gsub("%%", "")))
	end,
})

MenuGroup:AddSlider("CornerRadius", {
	Text = "Corner radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 16,
	Rounding = 0,
	Callback = function(Value)
		Window:SetCornerRadius(Value)
	end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Show or hide the menu",
})
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddButton({
	Text = "Unload interface",
	Variant = "Danger",
	Func = function()
		Library:Unload()
	end,
})


if ThemeManager then
	local ThemeReady, ThemeError = pcall(function()
		ThemeManager:SetLibrary(Library)
		ThemeManager:SetFolder("MonHub")
		local ThemeBox = ThemeManager:ApplyToTab(Tabs.Settings)
		SetGroupOrder(ThemeBox, 0)
	end)

	if not ThemeReady then
		warn("[MonHub Example] ThemeManager disabled: " .. tostring(ThemeError))
	end
end

if SaveManager then
	local SaveReady, SaveError = pcall(function()
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetFolder("MonHub")
		SaveManager:SetSubFolder(tostring(game.PlaceId))
		local ConfigurationBox = SaveManager:BuildConfigSection(Tabs.Settings)
		SetGroupOrder(ConfigurationBox, -100)
		SaveManager:LoadAutoloadConfig()
	end)

	if not SaveReady then
		warn("[MonHub Example] SaveManager disabled: " .. tostring(SaveError))
	end
end

Notify(
	"MonHub started",
	"Loaded from the custom repository. Press RightShift to toggle the interface.",
	6
)

return {
	Library = Library,
	Window = Window,
	Tabs = Tabs,
	ThemeManager = ThemeManager,
	SaveManager = SaveManager,
	ESPPreview = ESPPreview,
	Repository = ActiveRepository,
}
