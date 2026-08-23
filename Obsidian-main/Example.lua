












assert(type(loadstring) == "function", "This example requires an executor with loadstring support.")

local PRIMARY_REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local RELEASE_VERSION = "0.0.1-final-theme-5"
local ExecutorEnvironment = getfenv()
local SynEnvironment = if type(ExecutorEnvironment) == "table" then rawget(ExecutorEnvironment, "syn") else nil
local SynRequest = if type(SynEnvironment) == "table" then rawget(SynEnvironment, "request") else nil
local ExecutorRequest = if type(ExecutorEnvironment) == "table" then rawget(ExecutorEnvironment, "request") or rawget(ExecutorEnvironment, "http_request") or SynRequest else SynRequest

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
	local Url = BaseUrl .. Path .. "?monhub=" .. RELEASE_VERSION
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
if Library.ReleaseVersion ~= RELEASE_VERSION then
	warn(string.format("MonHub version notice: expected %s, received %s", RELEASE_VERSION, tostring(Library.ReleaseVersion)))
end
local SaveManager = LoadModule("addons/SaveManager.lua", false, ActiveRepository)
local ThemeManager = LoadModule("addons/ThemeManager.lua", false, ActiveRepository)
local VisualPreview = LoadModule("addons/VisualPreview.lua", false, ActiveRepository)
local DrawingESPPreview = LoadModule("addons/DrawingESPPreview.lua", false, ActiveRepository)
local ImageGallery = LoadModule("addons/ImageGallery.lua", false, ActiveRepository)
local ImagePreview = LoadModule("addons/ImagePreview.lua", false, ActiveRepository)
local TracerPreview = LoadModule("addons/TracerPreview.lua", false, ActiveRepository)
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = true
Library.ShowToggleFrameInKeybinds = true


Library:SetClickSound(92679954573730, 0.3)

local Window = Library:CreateWindow({
	Title = "MonHub Private",
	Footer = "MonHub v0.0.1",
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
	TabTransitionTime = 0.075,
	TabSwipeOffset = 2,
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
	Addons = Window:AddTab("Addons", "package-plus"),
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


local AddonGalleryGroup = Tabs.Addons:AddLeftGroupbox("Asset gallery", "layout-grid")
local AddonImageGroup = Tabs.Addons:AddRightGroupbox("Image preview", "image")
local AddonTracerGroup = Tabs.Addons:AddRightGroupbox("Tracer preview", "sparkles")

local GalleryItems = {
	{
		Id = "neptune",
		Name = "Neptune",
		Category = "Space",
		Subtitle = "Deep blue skybox",
		Image = "rbxassetid://218954524",
	},
	{
		Id = "nebula",
		Name = "Nebula",
		Category = "Space",
		Subtitle = "Classic nebula skybox",
		Image = "rbxassetid://159454293",
	},
	{
		Id = "vaporwave",
		Name = "Vaporwave",
		Category = "Space",
		Subtitle = "Purple horizon skybox",
		Image = "rbxassetid://1417494253",
	},
	{
		Id = "clouds",
		Name = "Clouds",
		Category = "Atmosphere",
		Subtitle = "Soft daytime clouds",
		Image = "rbxassetid://570557559",
	},
	{
		Id = "twilight",
		Name = "Twilight",
		Category = "Atmosphere",
		Subtitle = "Muted evening skybox",
		Image = "rbxassetid://264909420",
	},
	{
		Id = "blue-aurora",
		Name = "Blue Aurora",
		Category = "Atmosphere",
		Subtitle = "Cold aurora skybox",
		Image = "rbxassetid://12064152",
	},
	{
		Id = "minecraft",
		Name = "Minecraft",
		Category = "Worlds",
		Subtitle = "Block world skybox",
		Image = "rbxassetid://1876542941",
	},
	{
		Id = "jungle",
		Name = "Jungle",
		Category = "Worlds",
		Subtitle = "Dense green skybox",
		Image = "rbxassetid://214399894",
	},
	{
		Id = "winter-mountain",
		Name = "Winter Mountain",
		Category = "Worlds",
		Subtitle = "Snow mountain skybox",
		Image = "rbxassetid://402229293",
	},
}

local AddonImagePreview
if ImagePreview then
	local Created, Result = pcall(ImagePreview.CreateEmbedded, Library, AddonImageGroup, "AddonImagePreview", {
		Height = 220,
		ScaleType = "Fit",
		Title = "Select an asset",
		Subtitle = "Gallery selection appears here",
		Motion = true,
	})
	if Created then
		AddonImagePreview = Result
	else
		warn("[MonHub Example] ImagePreview disabled: " .. tostring(Result))
	end
end

local AddonGallery
if ImageGallery then
	local Created, Result = pcall(ImageGallery.CreateEmbedded, Library, AddonGalleryGroup, "AddonImageGallery", {
		Height = 330,
		Columns = 3,
		PageSize = 9,
		CellHeight = 78,
		ScaleType = "Fit",
		Preview = AddonImagePreview,
		Items = GalleryItems,
		OnSelected = function(Item)
			if Item then
				Notify("Gallery selection", Item.Name)
			end
		end,
	})
	if Created then
		AddonGallery = Result
		AddonGallery:Select("neptune", true)
	else
		warn("[MonHub Example] ImageGallery disabled: " .. tostring(Result))
	end
end

AddonGalleryGroup:AddInput("AddonGallerySearch", {
	Text = "Gallery search",
	Default = "",
	ClearTextOnFocus = false,
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetSearch(Value)
		end
	end,
})

AddonGalleryGroup:AddDropdown("AddonGalleryCategory", {
	Text = "Gallery category",
	Values = { "All", "Space", "Atmosphere", "Worlds" },
	Default = "All",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetCategory(Value)
		end
	end,
})

AddonGalleryGroup:AddDropdown("AddonGalleryColumns", {
	Text = "Gallery columns",
	Values = { "1", "2", "3", "4", "5" },
	Default = "3",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetColumns(tonumber(Value))
		end
	end,
})

AddonGalleryGroup:AddToggle("AddonGalleryVisible", {
	Text = "Gallery visible",
	Default = true,
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetVisible(Value)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryHeight", {
	Text = "Gallery height",
	Default = 330,
	Min = 220,
	Max = 500,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetHeight(Value)
		end
	end,
})

AddonGalleryGroup:AddButton("Previous gallery page", function()
	if AddonGallery then
		AddonGallery:PreviousPage()
	end
end)

AddonGalleryGroup:AddButton("Next gallery page", function()
	if AddonGallery then
		AddonGallery:NextPage()
	end
end)

local AddedGalleryItems = 0
AddonGalleryGroup:AddButton("Add gallery item", function()
	if not AddonGallery then
		return
	end
	AddedGalleryItems += 1
	local SourceItem = GalleryItems[((AddedGalleryItems - 1) % #GalleryItems) + 1]
	AddonGallery:AddItem({
		Id = "custom-" .. tostring(AddedGalleryItems),
		Name = "Custom " .. tostring(AddedGalleryItems),
		Category = "Worlds",
		Subtitle = "Runtime copy of " .. SourceItem.Name,
		Image = SourceItem.Image,
	})
end)

AddonGalleryGroup:AddButton("Remove selected item", function()
	if not AddonGallery then
		return
	end
	local _, Item = AddonGallery:GetSelected()
	if Item then
		AddonGallery:RemoveItem(Item.Id)
	end
end)

AddonGalleryGroup:AddButton("Reset gallery items", function()
	if AddonGallery then
		AddonGallery:SetItems(GalleryItems)
		AddonGallery:Select("neptune", true)
	end
end)

AddonGalleryGroup:AddButton("Select first gallery item", function()
	if AddonGallery then
		AddonGallery:Select("neptune")
	end
end)

AddonImageGroup:AddDropdown("AddonImageScaleType", {
	Text = "Preview scale type",
	Values = { "Fit", "Crop", "Stretch" },
	Default = "Fit",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetScaleType(Value)
		end
	end,
})

AddonImageGroup:AddToggle("AddonImageMotion", {
	Text = "Preview motion",
	Default = true,
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetMotion(Value)
		end
	end,
})

AddonImageGroup:AddSlider("AddonImageTransparency", {
	Text = "Image transparency",
	Default = 0,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetImageTransparency(Value / 100)
		end
	end,
})

AddonImageGroup:AddSlider("AddonImageHeight", {
	Text = "Preview height",
	Default = 220,
	Min = 140,
	Max = 360,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetHeight(Value)
		end
	end,
})

AddonImageGroup:AddToggle("AddonImageVisible", {
	Text = "Image preview visible",
	Default = true,
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetVisible(Value)
		end
	end,
})

AddonImageGroup:AddButton("Clear image preview", function()
	if AddonImagePreview then
		AddonImagePreview:SetImage("")
		AddonImagePreview:SetTitle("Select an asset")
		AddonImagePreview:SetSubtitle("")
	end
end)

local AddonTracer
local TracerAssetPresets = {
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
if TracerPreview then
	local Created, Result = pcall(TracerPreview.CreateEmbedded, Library, AddonTracerGroup, "AddonTracerPreview", {
		Name = "Tracer preview",
		AssetId = TracerAssetPresets.Beam,
		Height = 92,
		ColorA = Color3.fromRGB(255, 213, 58),
		ColorB = Color3.fromRGB(255, 246, 166),
		Glow = 0.82,
		Speed = 1.25,
	})
	if Created then
		AddonTracer = Result
	else
		warn("[MonHub Example] TracerPreview disabled: " .. tostring(Result))
	end
end

AddonTracerGroup:AddInput("AddonTracerAsset", {
	Text = "Tracer asset ID",
	Default = TracerAssetPresets.Beam,
	ClearTextOnFocus = false,
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetAssetId(Value)
		end
	end,
})

AddonTracerGroup:AddDropdown("AddonTracerPreset", {
	Text = "Tracer preset",
	Values = { "Beam", "Lightning", "Heartrate", "Chain", "Glitch", "Swirl", "Neon", "Plasma", "Laser" },
	Default = "Beam",
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetAssetId(TracerAssetPresets[Value])
		end
	end,
})

AddonTracerGroup:AddInput("AddonTracerName", {
	Text = "Tracer name",
	Default = "Tracer preview",
	ClearTextOnFocus = false,
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetName(Value)
		end
	end,
})

AddonTracerGroup:AddToggle("AddonTracerEnabled", {
	Text = "Tracer enabled",
	Default = true,
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetEnabled(Value)
		end
	end,
})

AddonTracerGroup:AddToggle("AddonTracerVisible", {
	Text = "Tracer visible",
	Default = true,
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetVisible(Value)
		end
	end,
})

AddonTracerGroup:AddSlider("AddonTracerGlow", {
	Text = "Tracer glow",
	Default = 82,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetGlow(Value / 100)
		end
	end,
})

AddonTracerGroup:AddSlider("AddonTracerSpeed", {
	Text = "Tracer speed",
	Default = 125,
	Min = 0,
	Max = 400,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetSpeed(Value / 100)
		end
	end,
})

AddonTracerGroup:AddSlider("AddonTracerHeight", {
	Text = "Tracer height",
	Default = 92,
	Min = 56,
	Max = 180,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		if AddonTracer then
			AddonTracer:SetHeight(Value)
		end
	end,
})

local AddonTracerColorA = Color3.fromRGB(255, 213, 58)
local AddonTracerColorB = Color3.fromRGB(255, 246, 166)
local AddonTracerColors = AddonTracerGroup:AddLabel("Tracer colors")
AddonTracerColors:AddColorPicker("AddonTracerColorA", {
	Title = "Tracer start",
	Default = AddonTracerColorA,
	Callback = function(Value)
		AddonTracerColorA = Value
		if AddonTracer then
			AddonTracer:SetColors(AddonTracerColorA, AddonTracerColorB)
		end
	end,
})
AddonTracerColors:AddColorPicker("AddonTracerColorB", {
	Title = "Tracer end",
	Default = AddonTracerColorB,
	Callback = function(Value)
		AddonTracerColorB = Value
		if AddonTracer then
			AddonTracer:SetColors(AddonTracerColorA, AddonTracerColorB)
		end
	end,
})


local VisualControls = Tabs.Visuals:AddLeftGroupbox("ESP controls", "eye")
local VisualPreviewBox = Tabs.Visuals:AddRightGroupbox("Live previews", "scan-eye")
VisualControls:AddLabel("The preview uses the same renderer contract that can draw live player ESP.", true)

local ESPPreview
local SharedESPRenderer = DrawingESPPreview and DrawingESPPreview.Create({
    Color = Color3.fromRGB(119, 166, 209),
    GradientColor = Color3.fromRGB(202, 220, 239),
}) or nil
if SharedESPRenderer then
	Library:OnUnload(function()
		SharedESPRenderer:Destroy()
	end)
end
if VisualPreview then
    local Created, PreviewOrError = pcall(VisualPreview.CreateEmbedded, Library, VisualPreviewBox, {
        Id = "EmbeddedESPPreview",
        Name = "ESP preview",
        Height = 320,
        Color = Color3.fromRGB(119, 166, 209),
        GradientColor = Color3.fromRGB(202, 220, 239),
        Gradient = true,
        DynamicBoxes = true,
        Renderer = SharedESPRenderer,
    })

    if Created then
        ESPPreview = PreviewOrError
    else
        warn("[MonHub Example] VisualPreview disabled: " .. tostring(PreviewOrError))
    end
end

local ESPEnabled = VisualControls:AddToggle("ESPEnabled", {
	Text = "Enable ESP preview",
	Default = false,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetEnabled(Value)
		end
	end,
})

local ESPPreviewColor = Color3.fromRGB(119, 166, 209)
local ESPPreviewGradientColor = Color3.fromRGB(202, 220, 239)
ESPEnabled:AddColorPicker("ESPPreviewColor", {
	Title = "ESP color",
	Default = ESPPreviewColor,
	Callback = function(Value)
		ESPPreviewColor = Value
		if ESPPreview then
			ESPPreview:SetColor(Value)
		end
	end,
})
ESPEnabled:AddColorPicker("ESPPreviewGradientColor", {
	Title = "ESP gradient color",
	Default = ESPPreviewGradientColor,
	Callback = function(Value)
		ESPPreviewGradientColor = Value
		if ESPPreview then
			ESPPreview:SetGradientColor(Value)
		end
	end,
})

VisualControls:AddToggle("ESPGradient", {
	Text = "Gradient box",
	Default = true,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetGradientEnabled(Value)
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

VisualControls:AddToggle("ESPTeam", {
	Text = "Team",
	Default = false,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetTeamVisible(Value)
		end
	end,
})

VisualControls:AddToggle("ESPWeapon", {
	Text = "Weapon",
	Default = false,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetWeaponVisible(Value)
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

VisualControls:AddToggle("ESPDynamicBoxes", {
	Text = "Dynamic boxes",
	Default = true,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetDynamicBoxes(Value)
		end
	end,
})

VisualControls:AddSlider("ESPBoxScale", {
	Text = "Box scale",
	Default = 92,
	Min = 70,
	Max = 115,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetBoxScale(Value)
		end
	end,
})

VisualControls:AddSlider("ESPPreviewZoom", {
	Text = "Preview zoom",
	Default = 190,
	Min = 120,
	Max = 320,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetZoom(Value / 100)
		end
	end,
})

local ESPChamsFill = Color3.fromRGB(119, 166, 209)
local ESPChamsOutline = Color3.fromRGB(235, 241, 248)
local ESPChamsTransparency = 25
local ESPHighlightToggle = VisualControls:AddToggle("ESPHighlight", {
	Text = "Highlight",
	Default = false,
	Callback = function(Value)
		if ESPPreview then
			ESPPreview:SetChams(Value, ESPChamsFill, ESPChamsOutline, ESPChamsTransparency / 100, 0)
		end
	end,
})
ESPHighlightToggle:AddColorPicker("ESPChamsFill", {
	Title = "Highlight fill",
	Default = ESPChamsFill,
	Callback = function(Value)
		ESPChamsFill = Value
		if ESPPreview then
			ESPPreview:SetChams(Toggles.ESPHighlight.Value, ESPChamsFill, ESPChamsOutline, ESPChamsTransparency / 100, 0)
		end
	end,
})
ESPHighlightToggle:AddColorPicker("ESPChamsOutline", {
	Title = "Highlight outline",
	Default = ESPChamsOutline,
	Callback = function(Value)
		ESPChamsOutline = Value
		if ESPPreview then
			ESPPreview:SetChams(Toggles.ESPHighlight.Value, ESPChamsFill, ESPChamsOutline, ESPChamsTransparency / 100, 0)
		end
	end,
})

VisualControls:AddSlider("ESPChamsTransparency", {
	Text = "Highlight transparency",
	Default = ESPChamsTransparency,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		ESPChamsTransparency = Value
		if ESPPreview then
			ESPPreview:SetChams(Toggles.ESPHighlight.Value, ESPChamsFill, ESPChamsOutline, ESPChamsTransparency / 100, 0)
		end
	end,
})

VisualControls:AddButton("Rotate preview left", function()
	if ESPPreview then
		ESPPreview:Rotate(-24, 0)
	end
end)

VisualControls:AddButton("Rotate preview right", function()
	if ESPPreview then
		ESPPreview:Rotate(24, 0)
	end
end)

VisualControls:AddButton("Reset preview camera", function()
	if ESPPreview then
		ESPPreview:ResetView()
	end
end)

if ESPPreview then
	ESPPreview:SetEnabled(ESPEnabled.Value)
	ESPPreview:SetBoxVisible(Toggles.ESPBox.Value)
	ESPPreview:SetNameVisible(Toggles.ESPName.Value)
	ESPPreview:SetDistanceVisible(Toggles.ESPDistance.Value)
	ESPPreview:SetTeamVisible(Toggles.ESPTeam.Value)
	ESPPreview:SetWeaponVisible(Toggles.ESPWeapon.Value)
	ESPPreview:SetDistance(Options.ESPPreviewDistance.Value)
	ESPPreview:SetHealthVisible(Toggles.ESPHealth.Value)
	ESPPreview:SetDynamicBoxes(Toggles.ESPDynamicBoxes.Value)
	ESPPreview:SetBoxScale(Options.ESPBoxScale.Value)
	ESPPreview:SetZoom(Options.ESPPreviewZoom.Value / 100)
	ESPPreview:SetGradientEnabled(Toggles.ESPGradient.Value)
	ESPPreview:SetGradientColor(ESPPreviewGradientColor)
	ESPPreview:SetChams(Toggles.ESPHighlight.Value, ESPChamsFill, ESPChamsOutline, ESPChamsTransparency / 100, 0)
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
StyleTab:AddLabel("Default, Metal, Midnight, Steel, Sage, and Ash use separate surfaces for cards, controls, hover states, overlays, and the top bar.", true)


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

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Show or hide the menu",
})
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddButton({
	Text = "Unload interface",
	Func = function()
		Library:Unload()
	end,
})

if ThemeManager then
	local ThemeReady, ThemeError = pcall(function()
		ThemeManager:SetLibrary(Library)
		local AppearanceBox = ThemeManager:ApplyToTab(Tabs.Settings)
		SetGroupOrder(AppearanceBox, -90)
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
	SaveManager = SaveManager,
	ThemeManager = ThemeManager,
	ESPPreview = ESPPreview,
	ESPRenderer = SharedESPRenderer,
	AddonModules = {
		ImageGallery = ImageGallery,
		ImagePreview = ImagePreview,
		TracerPreview = TracerPreview,
		VisualPreview = VisualPreview,
		DrawingESPPreview = DrawingESPPreview,
		SaveManager = SaveManager,
		ThemeManager = ThemeManager,
	},
	AddonExamples = {
		ImageGallery = AddonGallery,
		ImagePreview = AddonImagePreview,
		TracerPreview = AddonTracer,
	},
	Repository = ActiveRepository,
}
