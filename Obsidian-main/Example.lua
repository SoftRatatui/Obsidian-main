--[[
	Obsidian full showcase and smoke test.

	The loader tries this repository first:
	https://github.com/SoftRatatui/Obsidian-main

	If the repository is private, unavailable, or returns a non-Lua response,
	the example falls back to the stable upstream repository. This prevents
	"Expected identifier" errors caused by passing a GitHub 404 page to loadstring.

	Press RightShift to show or hide the window.
]]

assert(type(loadstring) == "function", "This example requires an executor with loadstring support.")

local PRIMARY_REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local FALLBACK_REPOSITORY = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local function CleanPreview(Source)
	local Preview = tostring(Source):sub(1, 120)
	return Preview:gsub("[%c]+", " ")
end

local function TryModule(BaseUrl, Path)
	local Url = BaseUrl .. Path
	local Downloaded, Source = pcall(game.HttpGet, game, Url)

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
	AddBase(FALLBACK_REPOSITORY)

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

	warn("[Obsidian Example] " .. Message)
	return nil
end

local Library, ActiveRepository = LoadModule("Library.lua", true)
local ThemeManager = LoadModule("addons/ThemeManager.lua", false, ActiveRepository)
local SaveManager = LoadModule("addons/SaveManager.lua", false, ActiveRepository)

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- Apply the black and purple appearance before any UI objects are created.
Library.Scheme.BackgroundColor = Color3.fromRGB(9, 9, 13)
Library.Scheme.MainColor = Color3.fromRGB(18, 17, 24)
Library.Scheme.AccentColor = Color3.fromRGB(116, 82, 178)
Library.Scheme.OutlineColor = Color3.fromRGB(43, 38, 53)
Library.Scheme.FontColor = Color3.fromRGB(232, 229, 238)
Library.Scheme.WhiteColor = Color3.fromRGB(232, 229, 238)
Library.Scheme.Font = Font.fromEnum(Enum.Font.Gotham)
Library.CornerRadius = 9
Library.IsLightTheme = false

local Window = Library:CreateWindow({
	Title = "Obsidian",
	Footer = ActiveRepository == PRIMARY_REPOSITORY and "Full showcase | custom repository" or "Full showcase | upstream fallback",
	Icon = "gem",
	NotifySide = "Right",
	Center = true,
	AutoShow = true,
	Resizable = true,
	GlobalSearch = true,
	EnableSidebarResize = true,
	ShowCustomCursor = true,
	Font = Enum.Font.Gotham,
	CornerRadius = 9,
	Size = Library.IsMobile and UDim2.fromOffset(560, 430) or UDim2.fromOffset(860, 620),
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
	Advanced = Window:AddTab("Advanced", "wand-sparkles"),
	KeySystem = Window:AddKeyTab("Key System"),
	Settings = Window:AddTab("UI Settings", "settings-2"),
}

-- Controls tab.
local BasicGroup = Tabs.Controls:AddLeftGroupbox("Basic controls", "component")
BasicGroup:AddLabel("All common controls are included in this smoke test.", true)
BasicGroup:AddDivider()

local FeatureToggle = BasicGroup:AddToggle("FeatureEnabled", {
	Text = "Main feature",
	Default = true,
	Tooltip = "A toggle with color and keybind addons",
	Callback = function(Value)
		print("[Obsidian] FeatureEnabled:", Value)
	end,
})

FeatureToggle:AddColorPicker("FeatureColor", {
	Title = "Feature color",
	Default = Color3.fromRGB(116, 82, 178),
	Transparency = 0,
})

FeatureToggle:AddKeyPicker("FeatureKeybind", {
	Text = "Main feature",
	Default = "G",
	Mode = "Toggle",
	SyncToggleState = true,
})

BasicGroup:AddCheckbox("CheckboxMode", {
	Text = "Checkbox mode",
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

-- Media tab: Image, Viewport, Video, and UIPassthrough.
local PreviewModel = Instance.new("Model")
PreviewModel.Name = "ObsidianPreviewModel"

local PreviewBase = Instance.new("Part")
PreviewBase.Name = "Base"
PreviewBase.Anchored = true
PreviewBase.CanCollide = false
PreviewBase.Material = Enum.Material.SmoothPlastic
PreviewBase.Color = Color3.fromRGB(43, 34, 62)
PreviewBase.Size = Vector3.new(4.8, 0.6, 4.8)
PreviewBase.CFrame = CFrame.new(0, -1.6, 0)
PreviewBase.Parent = PreviewModel

local PreviewCore = Instance.new("Part")
PreviewCore.Name = "Core"
PreviewCore.Anchored = true
PreviewCore.CanCollide = false
PreviewCore.Material = Enum.Material.Neon
PreviewCore.Color = Color3.fromRGB(116, 82, 178)
PreviewCore.Shape = Enum.PartType.Ball
PreviewCore.Size = Vector3.new(2.5, 2.5, 2.5)
PreviewCore.CFrame = CFrame.new(0, 0.1, 0)
PreviewCore.Parent = PreviewModel
PreviewModel.PrimaryPart = PreviewCore

local MediaLeft = Tabs.Media:AddLeftGroupbox("Image and viewport", "image")
MediaLeft:AddImage("ShowcaseImage", {
	Image = "sparkles",
	Color = Color3.fromRGB(178, 142, 231),
	BackgroundTransparency = 0.15,
	ScaleType = Enum.ScaleType.Fit,
	Height = 120,
})

MediaLeft:AddViewport("ShowcaseViewport", {
	Object = PreviewModel,
	Clone = true,
	AutoFocus = true,
	Interactive = true,
	Height = 220,
})
MediaLeft:AddLabel("Drag to rotate the viewport. Use the mouse wheel to zoom.", true)

local CustomCard = Instance.new("Frame")
CustomCard.Name = "CustomPassthroughCard"
CustomCard.BackgroundColor3 = Color3.fromRGB(28, 23, 39)
CustomCard.BorderSizePixel = 0
CustomCard.Size = UDim2.fromScale(1, 1)

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 8)
CardCorner.Parent = CustomCard

local CardStroke = Instance.new("UIStroke")
CardStroke.Color = Color3.fromRGB(75, 57, 105)
CardStroke.Parent = CustomCard

local CardText = Instance.new("TextLabel")
CardText.BackgroundTransparency = 1
CardText.Position = UDim2.fromOffset(12, 8)
CardText.Size = UDim2.new(1, -24, 1, -16)
CardText.Font = Enum.Font.Gotham
CardText.Text = "Custom GuiBase2d embedded through UIPassthrough"
CardText.TextColor3 = Color3.fromRGB(232, 229, 238)
CardText.TextSize = 14
CardText.TextWrapped = true
CardText.Parent = CustomCard

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

-- Advanced tab: dialogs, loading, draggable UI, dependency boxes, and tabboxes.
local AdvancedActions = Tabs.Advanced:AddLeftGroupbox("System actions", "blocks")

AdvancedActions:AddButton("Show notification", function()
	Notify("Obsidian is ready", "Notifications support a title, description, and duration.")
end)

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
		Default = "Hello from Obsidian",
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
			Title = "Obsidian Showcase",
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

local DraggableLabel
AdvancedActions:AddButton("Create draggable label", function()
	if not DraggableLabel or DraggableLabel.Destroyed then
		DraggableLabel = Library:AddDraggableLabel({
			Text = "Obsidian | draggable label",
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
StyleTab:AddLabel("The default palette is black and muted purple.", true)
StyleTab:AddButton("Reapply black purple", function()
	Library.Scheme.BackgroundColor = Color3.fromRGB(9, 9, 13)
	Library.Scheme.MainColor = Color3.fromRGB(18, 17, 24)
	Library.Scheme.AccentColor = Color3.fromRGB(116, 82, 178)
	Library.Scheme.OutlineColor = Color3.fromRGB(43, 38, 53)
	Library.Scheme.FontColor = Color3.fromRGB(232, 229, 238)
	Library.Scheme.WhiteColor = Color3.fromRGB(232, 229, 238)
	Library:UpdateColorsUsingRegistry()
	Window:SetCornerRadius(9)
end)

-- Key system tab.
Tabs.KeySystem:AddLabel({
	Text = "Test key: <b>OBSIDIAN</b>",
	DoesWrap = true,
	Size = 16,
})

Tabs.KeySystem:AddKeyBox(function(ReceivedKey)
	local Success = ReceivedKey == "OBSIDIAN"
	Notify(
		Success and "Key accepted" or "Invalid key",
		string.format("Received: %s\nSuccess: %s", tostring(ReceivedKey), tostring(Success))
	)
end)

-- UI settings.
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Interface", "panel-left")
SetGroupOrder(MenuGroup, 10)
MenuGroup:AddToggle("KeybindMenuOpen", {
	Text = "Show keybind menu",
	Default = Library.KeybindFrame.Visible,
	Callback = function(Value)
		Library.KeybindFrame.Visible = Value
	end,
})

MenuGroup:AddToggle("CustomCursor", {
	Text = "Custom cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
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
	Risky = true,
	DoubleClick = true,
	Func = function()
		Library:Unload()
	end,
})

-- Optional addons. The active library repository is tried first.
if ThemeManager then
	local ThemeReady, ThemeError = pcall(function()
		ThemeManager:SetLibrary(Library)
		ThemeManager:SetFolder("ObsidianShowcase")
		local ThemeBox = ThemeManager:ApplyToTab(Tabs.Settings)
		SetGroupOrder(ThemeBox, -10)
	end)

	if not ThemeReady then
		warn("[Obsidian Example] ThemeManager disabled: " .. tostring(ThemeError))
	end
end

if SaveManager then
	local SaveReady, SaveError = pcall(function()
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
		SaveManager:SetFolder("ObsidianShowcase")
		SaveManager:SetSubFolder(tostring(game.PlaceId))
		local ConfigurationBox = SaveManager:BuildConfigSection(Tabs.Settings)
		SetGroupOrder(ConfigurationBox, -10)
		SaveManager:LoadAutoloadConfig()
	end)

	if not SaveReady then
		warn("[Obsidian Example] SaveManager disabled: " .. tostring(SaveError))
	end
end

Library:OnUnload(function()
	if PreviewModel then
		PreviewModel:Destroy()
	end

	print("[Obsidian Example] Interface unloaded and connections cleaned up.")
end)

Notify(
	"Obsidian started",
	ActiveRepository == PRIMARY_REPOSITORY
		and "Loaded from the custom repository. Press RightShift to toggle the interface."
		or "The custom repository was unavailable, so the verified upstream fallback was used.",
	6
)

return {
	Library = Library,
	Window = Window,
	Tabs = Tabs,
	ThemeManager = ThemeManager,
	SaveManager = SaveManager,
	Repository = ActiveRepository,
}
