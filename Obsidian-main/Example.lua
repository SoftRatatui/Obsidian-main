












assert(type(loadstring) == "function", "This example requires an executor with loadstring support.")

local PRIMARY_REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local RELEASE_VERSION = "0.0.1-release-3"
local SOURCE_CACHE_KEY = RELEASE_VERSION .. "-ui-1"
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
	local Url = BaseUrl .. Path .. "?monhub=" .. SOURCE_CACHE_KEY
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
local AssetCatalog = LoadModule("addons/AssetCatalog.lua", false, ActiveRepository)
local CollectionModel = LoadModule("addons/CollectionModel.lua", false, ActiveRepository)
local CharacterTrail = LoadModule("addons/CharacterTrail.lua", false, ActiveRepository)
local DashboardWindow = LoadModule("addons/DashboardWindow.lua", false, ActiveRepository)
local UniversalESP = LoadModule("addons/esp/ESP.lua", false, ActiveRepository)
local UniversalESPUI = LoadModule("addons/esp/MonHubUI.lua", false, ActiveRepository)
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = true
Library.ShowToggleFrameInKeybinds = true

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
	Font = Library.Scheme.Font,
	CornerRadius = 8,
	ShowCompactLauncher = true,
	CompactLauncherIcon = "maximize-2",
	CompactLauncherSize = 36,
	CompactLauncherWidth = 172,
	CompactLauncherPosition = UDim2.fromScale(0.5, 0.5),
	CompactLauncherAnchorPoint = Vector2.new(0.5, 0.5),
	CompactLauncherDraggable = true,
	TabTransitionTime = 0.085,
	TabSwipeOffset = 10,
	TabSwipeFrom = "auto",
	Size = Library.IsMobile and UDim2.fromOffset(520, 480) or UDim2.fromOffset(880, 664),
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
	Preview = Window:AddTab("Preview", "sparkles"),
	Controls = Window:AddTab("Controls", "sliders-horizontal"),
	Media = Window:AddTab("Media", "gallery-horizontal-end"),
	Visuals = Window:AddTab("Visuals", "eye"),
	ESP = Window:AddTab("ESP", "scan-eye"),
	Addons = Window:AddTab("Addons", "package-plus"),
	Gallery = Window:AddTab("Gallery", "layout-grid"),
	Advanced = Window:AddTab("Advanced", "wand-sparkles"),
	KeySystem = Window:AddKeyTab("Key System"),
	Settings = Window:AddTab("UI Settings", "settings-2"),
}

local UniversalESPController
local UniversalESPPanel
local UniversalESPPreviewRenderer
if UniversalESP and UniversalESPUI then
	local Created, Result = pcall(function()
		local Controller = UniversalESP.new({
			AutoStart = true,
			WrapPlayers = true,
		})
		local Panel = UniversalESPUI.Mount(Library, Tabs.ESP, Controller, {
			Prefix = "ExampleESP_",
			AutoNPCs = false,
		})
		return {
			Controller = Controller,
			Panel = Panel,
			PreviewRenderer = Controller:CreatePreviewAdapter({ UseContext = true }),
		}
	end)
	if Created then
		UniversalESPController = Result.Controller
		UniversalESPPanel = Result.Panel
		UniversalESPPreviewRenderer = Result.PreviewRenderer
		Library:OnUnload(function()
			UniversalESPController:Destroy()
		end)
	else
		warn("[MonHub Example] Universal ESP disabled: " .. tostring(Result))
	end
end


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
local ShowcaseImage = MediaLeft:AddImage("ShowcaseImage", {
	Image = "sparkles",
	Color = Color3.fromRGB(184, 189, 201),
	BackgroundTransparency = 0.12,
	OutlineTransparency = 0.48,
	CornerRadius = 5,
	Padding = 10,
	ScaleType = Enum.ScaleType.Fit,
	Height = 82,
})

MediaLeft:AddSlider("ShowcaseImageTransparency", {
	Text = "Image transparency",
	Default = 0,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		ShowcaseImage:SetTransparency(Value / 100)
	end,
})

MediaLeft:AddSlider("ShowcaseImageBackgroundTransparency", {
	Text = "Image background transparency",
	Default = 12,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		ShowcaseImage:SetBackgroundTransparency(Value / 100)
	end,
})

MediaLeft:AddSlider("ShowcaseImagePadding", {
	Text = "Image padding",
	Default = 10,
	Min = 0,
	Max = 28,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		ShowcaseImage:SetPadding(Value)
	end,
})

MediaLeft:AddSlider("ShowcaseImageScale", {
	Text = "Image zoom",
	Default = 100,
	Min = 25,
	Max = 300,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		ShowcaseImage:SetImageScale(Value / 100)
	end,
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
CardText.FontFace = Library.Scheme.Font
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
	FontFace = "Font",
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
local CharacterTrailGroup = Tabs.Addons:AddRightGroupbox("Character trail", "sparkles")
local Dashboard
if DashboardWindow then
	local DashboardGroup = Tabs.Addons:AddLeftGroupbox("Dashboard window", "layout-dashboard")
	Dashboard = DashboardWindow.Create(Library, {
		Title = "MonHub dashboard",
		Icon = "layout-dashboard",
		Width = 304,
		Height = 320,
		Position = "Right",
		Visible = false,
		Draggable = true,
	})

	local DashboardRuntime = Dashboard:AddSection({ Title = "Runtime", Icon = "activity" })
	DashboardRuntime:AddText("Compact script information and actions in a separate window.")
	DashboardRuntime:AddMetric({
		Label = "Player",
		Value = function()
			return Library.LocalPlayer.DisplayName
		end,
		Interval = 1,
	})
	DashboardRuntime:AddMetric({
		Label = "Menu",
		Value = function()
			return Library.Toggled and "Open" or "Hidden"
		end,
		Interval = 0.2,
	})

	local DashboardActions = Dashboard:AddSection({ Title = "Actions", Icon = "mouse-pointer-click" })
	DashboardActions:AddButton({
		Text = "Show notification",
		Callback = function()
			Notify("Dashboard", "The standalone dashboard action is working.", 3)
		end,
	})

	DashboardGroup:AddLabel("A compact theme-aware window for values, actions, and custom GUI content.", true)
	DashboardGroup:AddButton("Toggle dashboard", function()
		Dashboard:Toggle()
	end)
	DashboardGroup:AddButton("Refresh dashboard", function()
		Dashboard:Refresh()
	end)
end

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

local SkinCollection = CollectionModel and CollectionModel.Create({ Items = GalleryItems, Selected = "neptune" })
if SkinCollection then
	Library:OnUnload(function()
		SkinCollection:Destroy()
	end)
end

local CatalogModule
local CatalogHost
if AssetCatalog then
	local CatalogGroup = Tabs.Addons:AddRightGroupbox("Asset catalog", "panels-top-left")
	CatalogModule, CatalogHost = AssetCatalog.CreateStandalone(Library, {
		Model = SkinCollection,
		WindowTitle = "Skin collection",
		WindowSubtitle = "Search, inspect, and apply",
		WindowIcon = "layout-grid",
		WindowWidth = 760,
		WindowHeight = 560,
		Height = 482,
		Layout = "Split",
		PreviewSide = "Right",
		Columns = 3,
		Rows = 3,
		Items = GalleryItems,
		Selected = "neptune",
		Visible = true,
		HideWithMenu = true,
		ActionText = "Apply",
		OnAction = function(Item)
			if Item then
				Notify("Catalog action", tostring(Item.Name) .. " selected")
			end
		end,
	})
	CatalogHost:SetVisible(false, true)

	CatalogGroup:AddLabel("A complete skin changer surface with compact and standalone layouts.", true)
	CatalogGroup:AddButton("Toggle catalog window", function()
		CatalogHost:Toggle()
	end)
	CatalogGroup:AddDropdown("CatalogLayout", {
		Text = "Catalog layout",
		Values = { "Split", "Stack", "Grid" },
		Default = "Split",
		Callback = function(Value)
			CatalogModule:SetLayout(Value)
		end,
	})
	CatalogGroup:AddSlider("CatalogPreviewRatio", {
		Text = "Preview width",
		Default = 58,
		Min = 35,
		Max = 72,
		Rounding = 0,
		Suffix = "%",
		Callback = function(Value)
			CatalogModule:SetPreviewRatio(Value / 100)
		end,
	})
end

local GalleryCatalog
if AssetCatalog then
	local GalleryGroup = Tabs.Gallery:AddFullGroupbox("Skin gallery", "layout-grid")

	local Created, Result = pcall(function()
		return AssetCatalog.CreateEmbedded(Library, GalleryGroup, "GalleryCatalog", {
			Model = SkinCollection,
			Items = GalleryItems,
			Height = 430,
			MinCellWidth = 116,
			Layout = "Split",
			PreviewSide = "Right",
			PreviewRatio = 0.42,
			ActionText = "Apply",
			SecondaryActionText = "Inspect",
			OnAction = function(Item)
				if Item then
					Notify("Gallery", tostring(Item.Name) .. " applied")
				end
			end,
		})
	end)

	if Created then
		GalleryCatalog = Result
	else
		GalleryGroup:AddLabel("Gallery unavailable: " .. tostring(Result), true)
	end

	local GalleryOptions = Tabs.Gallery:AddFullGroupbox("Gallery layout", "sliders-horizontal")
	GalleryOptions:AddLabel(
		"A full width groupbox gives the grid the room a half width column cannot. Columns are fitted to the available space in whole pixels.",
		true
	)
	GalleryOptions:AddDropdown("GalleryLayoutMode", {
		Text = "Layout",
		Values = { "Split", "Stack", "Grid" },
		Default = "Split",
		Callback = function(Value)
			if GalleryCatalog then
				GalleryCatalog:SetLayout(Value)
			end
		end,
	})
	GalleryOptions:AddSlider("GalleryCellWidth", {
		Text = "Minimum card width",
		Default = 124,
		Min = 90,
		Max = 220,
		Rounding = 0,
		Suffix = "px",
		Callback = function(Value)
			if GalleryCatalog then
				GalleryCatalog:SetMinCellWidth(Value)
			end
		end,
	})
	GalleryOptions:AddSlider("GalleryCellHeight", {
		Text = "Card height",
		Default = 104,
		Min = 78,
		Max = 180,
		Rounding = 0,
		Suffix = "px",
		Callback = function(Value)
			if GalleryCatalog then
				GalleryCatalog:SetCellHeight(Value)
			end
		end,
	})
	GalleryOptions:AddButton("Open the same gallery as a window", function()
		local Ok, Err = pcall(function()
			AssetCatalog.CreateStandalone(Library, {
				Model = SkinCollection,
				Items = GalleryItems,
				WindowTitle = "Skin gallery",
				WindowSubtitle = "Standalone module",
				WindowWidth = 820,
				WindowHeight = 560,
				MinCellWidth = 124,
			})
		end)
		if not Ok then
			Notify("Gallery", "Standalone failed: " .. tostring(Err))
		end
	end)
	GalleryOptions:AddSlider("GalleryPanelHeight", {
		Text = "Gallery height",
		Default = 430,
		Min = 340,
		Max = 800,
		Rounding = 0,
		Suffix = "px",
		Callback = function(Value)
			if GalleryCatalog then
				GalleryCatalog:SetHeight(Value)
			end
		end,
	})
	GalleryOptions:AddButton("Save or unsave selected skin", function()
		local Item = SkinCollection and SkinCollection:GetSelected()
		if Item then
			SkinCollection:SetFavorite(Item.Id, not Item.Favorite)
		end
	end)
end

local AddonImagePreview
if ImagePreview then
	local Created, Result = pcall(function()
		return AddonImageGroup:AddAddon("AddonImagePreview", ImagePreview, {
			Height = 220,
			ScaleType = "Fit",
			ImagePadding = 12,
			BackgroundTransparency = 0.04,
			CanvasTransparency = 0.18,
			CaptionTransparency = 0.08,
			OutlineTransparency = 0.48,
			ShadeTransparency = 0.62,
			Title = "Select an asset",
			Subtitle = "Gallery selection appears here",
			Motion = true,
		})
	end)
	if Created then
		AddonImagePreview = Result
	else
		warn("[MonHub Example] ImagePreview disabled: " .. tostring(Result))
	end
end

local AddonGallery
if ImageGallery then
	local Created, Result = pcall(function()
		return AddonGalleryGroup:AddAddon("AddonImageGallery", ImageGallery, {
			Height = 330,
			Columns = 3,
			PageSize = 9,
			CellHeight = 78,
			ScaleType = "Fit",
			CellTransparency = 0.06,
			OutlineTransparency = 0.48,
			ImageBackgroundTransparency = 0.22,
			ImagePadding = 5,
			Preview = AddonImagePreview,
			Items = GalleryItems,
			OnSelected = function(Item)
				if Item then
					Notify("Gallery selection", Item.Name)
				end
			end,
		})
	end)
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

AddonGalleryGroup:AddDropdown("AddonGalleryScaleType", {
	Text = "Gallery image scale",
	Values = { "Fit", "Crop", "Stretch" },
	Default = "Fit",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetScaleType(Value)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryImageTransparency", {
	Text = "Gallery image transparency",
	Default = 0,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetImageTransparency(Value / 100)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryImageBackgroundTransparency", {
	Text = "Image area transparency",
	Default = 22,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetImageBackgroundTransparency(Value / 100)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryCellTransparency", {
	Text = "Card transparency",
	Default = 6,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetCellTransparency(Value / 100)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryOutlineTransparency", {
	Text = "Card outline transparency",
	Default = 48,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetOutlineTransparency(Value / 100)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryImagePadding", {
	Text = "Gallery image padding",
	Default = 5,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetImagePadding(Value)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryImageScale", {
	Text = "Gallery image zoom",
	Default = 100,
	Min = 25,
	Max = 300,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetImageScale(Value / 100)
		end
	end,
})

AddonGalleryGroup:AddSlider("AddonGalleryCellHeight", {
	Text = "Gallery card height",
	Default = 78,
	Min = 52,
	Max = 140,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		if AddonGallery then
			AddonGallery:SetCellHeight(Value)
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

AddonImageGroup:AddSlider("AddonImageCanvasTransparency", {
	Text = "Canvas transparency",
	Default = 18,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetCanvasTransparency(Value / 100)
		end
	end,
})

AddonImageGroup:AddSlider("AddonImageCaptionTransparency", {
	Text = "Caption transparency",
	Default = 8,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetCaptionTransparency(Value / 100)
		end
	end,
})

AddonImageGroup:AddSlider("AddonImageOutlineTransparency", {
	Text = "Preview outline transparency",
	Default = 48,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetOutlineTransparency(Value / 100)
		end
	end,
})

AddonImageGroup:AddSlider("AddonImagePadding", {
	Text = "Preview image padding",
	Default = 12,
	Min = 0,
	Max = 48,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetImagePadding(Value)
		end
	end,
})

AddonImageGroup:AddSlider("AddonImageScale", {
	Text = "Preview image zoom",
	Default = 100,
	Min = 25,
	Max = 300,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetImageScale(Value / 100)
		end
	end,
})

AddonImageGroup:AddSlider("AddonImageRotation", {
	Text = "Preview rotation",
	Default = 0,
	Min = -180,
	Max = 180,
	Rounding = 0,
	Suffix = "°",
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetRotation(Value)
		end
	end,
})

AddonImageGroup:AddToggle("AddonImageShade", {
	Text = "Preview shade",
	Default = true,
	Callback = function(Value)
		if AddonImagePreview then
			AddonImagePreview:SetShade(Value, 0.62)
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

local TrailController = CharacterTrail and CharacterTrail.Create({
	Target = game:GetService("Players").LocalPlayer,
	Enabled = false,
	TransparencyStart = 0.04,
	TransparencyEnd = 0.18,
	WidthStart = 1,
	WidthEnd = 0.08,
	Lifetime = 0.42,
	AttachmentWidth = 1.7,
}) or nil

if TrailController then
	Library:OnUnload(function()
		TrailController:Destroy()
	end)
end

local TrailColorStart = Color3.fromRGB(146, 178, 214)
local TrailColorEnd = Color3.fromRGB(196, 168, 232)
local TrailTransparencyStart = 4
local TrailTransparencyEnd = 18
local TrailWidthStart = 100
local TrailWidthEnd = 8
local SyncTrailControls

local TrailToggle = CharacterTrailGroup:AddToggle("CharacterTrailEnabled", {
	Text = "Character trail",
	Default = false,
	Callback = function(Value)
		if TrailController then
			TrailController:SetEnabled(Value)
		end
	end,
})

TrailToggle:AddColorPicker("CharacterTrailColorStart", {
	Title = "Gradient start",
	Default = TrailColorStart,
	Callback = function(Value)
		TrailColorStart = Value
		if TrailController then
			TrailController:SetColors(TrailColorStart, TrailColorEnd)
		end
	end,
})

TrailToggle:AddColorPicker("CharacterTrailColorEnd", {
	Title = "Gradient end",
	Default = TrailColorEnd,
	Callback = function(Value)
		TrailColorEnd = Value
		if TrailController then
			TrailController:SetColors(TrailColorStart, TrailColorEnd)
		end
	end,
})

CharacterTrailGroup:AddDropdown("CharacterTrailPreset", {
	Text = "Trail preset",
	Values = { "Soft", "Energy", "Plasma", "Minimal" },
	Default = "Soft",
	Callback = function(Value)
		if TrailController and TrailController:ApplyPreset(Value) then
			task.defer(function()
				if SyncTrailControls then
					SyncTrailControls(TrailController:GetState())
				end
			end)
		end
	end,
})

CharacterTrailGroup:AddDropdown("CharacterTrailTexturePreset", {
	Text = "Texture preset",
	Values = { "None", "Beam", "Lightning", "Heartrate", "Chain", "Glitch", "Swirl", "Neon", "Plasma", "Laser" },
	Default = "None",
	Callback = function(Value)
		if TrailController and CharacterTrail then
			TrailController:SetTexture(CharacterTrail.TexturePresets[Value])
		end
	end,
})

CharacterTrailGroup:AddInput("CharacterTrailTexture", {
	Text = "Custom texture",
	Default = "",
	ClearTextOnFocus = false,
	Callback = function(Value)
		if TrailController then
			TrailController:SetTexture(Value)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailTransparencyStart", {
	Text = "Minimum transparency",
	Default = TrailTransparencyStart,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		TrailTransparencyStart = Value
		if TrailController then
			TrailController:SetTransparency(TrailTransparencyStart / 100, TrailTransparencyEnd / 100)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailTransparencyEnd", {
	Text = "Maximum transparency",
	Default = TrailTransparencyEnd,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		TrailTransparencyEnd = Value
		if TrailController then
			TrailController:SetTransparency(TrailTransparencyStart / 100, TrailTransparencyEnd / 100)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailWidthStart", {
	Text = "Start width scale",
	Default = TrailWidthStart,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		TrailWidthStart = Value
		if TrailController then
			TrailController:SetWidthScale(TrailWidthStart / 100, TrailWidthEnd / 100)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailWidthEnd", {
	Text = "End width scale",
	Default = TrailWidthEnd,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		TrailWidthEnd = Value
		if TrailController then
			TrailController:SetWidthScale(TrailWidthStart / 100, TrailWidthEnd / 100)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailAttachmentWidth", {
	Text = "Ribbon width",
	Default = 1.7,
	Min = 0.1,
	Max = 6,
	Rounding = 2,
	Suffix = " studs",
	Callback = function(Value)
		if TrailController then
			TrailController:SetAttachmentWidth(Value)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailLifetime", {
	Text = "Lifetime",
	Default = 0.42,
	Min = 0.05,
	Max = 3,
	Rounding = 2,
	Suffix = "s",
	Callback = function(Value)
		if TrailController then
			TrailController:SetLifetime(Value)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailVerticalOffset", {
	Text = "Vertical offset",
	Default = 0,
	Min = -4,
	Max = 4,
	Rounding = 2,
	Suffix = " studs",
	Callback = function(Value)
		if TrailController then
			TrailController:SetVerticalOffset(Value)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailMinLength", {
	Text = "Minimum segment",
	Default = 0.05,
	Min = 0,
	Max = 3,
	Rounding = 2,
	Suffix = " studs",
	Callback = function(Value)
		if TrailController then
			TrailController:SetMinLength(Value)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailMaxLength", {
	Text = "Maximum length",
	Default = 0,
	Min = 0,
	Max = 50,
	Rounding = 1,
	Suffix = " studs",
	Callback = function(Value)
		if TrailController then
			TrailController:SetMaxLength(Value)
		end
	end,
})

CharacterTrailGroup:AddDropdown("CharacterTrailTextureMode", {
	Text = "Texture mode",
	Values = { "Wrap", "Stretch", "Static" },
	Default = "Wrap",
	Callback = function(Value)
		if TrailController then
			TrailController:SetTextureMode(Value)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailTextureLength", {
	Text = "Texture length",
	Default = 1.25,
	Min = 0.1,
	Max = 10,
	Rounding = 2,
	Callback = function(Value)
		if TrailController then
			TrailController:SetTextureLength(Value)
		end
	end,
})

CharacterTrailGroup:AddToggle("CharacterTrailFaceCamera", {
	Text = "Face camera",
	Default = true,
	Callback = function(Value)
		if TrailController then
			TrailController:SetFaceCamera(Value)
		end
	end,
})

local TrailLightEmission = 28
local TrailLightInfluence = 0
CharacterTrailGroup:AddSlider("CharacterTrailLightEmission", {
	Text = "Light emission",
	Default = TrailLightEmission,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		TrailLightEmission = Value
		if TrailController then
			TrailController:SetLight(TrailLightEmission / 100, TrailLightInfluence / 100)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailLightInfluence", {
	Text = "Light influence",
	Default = TrailLightInfluence,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		TrailLightInfluence = Value
		if TrailController then
			TrailController:SetLight(TrailLightEmission / 100, TrailLightInfluence / 100)
		end
	end,
})

CharacterTrailGroup:AddSlider("CharacterTrailBrightness", {
	Text = "Brightness",
	Default = 1,
	Min = 0,
	Max = 3,
	Rounding = 2,
	Callback = function(Value)
		if TrailController then
			TrailController:SetBrightness(Value)
		end
	end,
})

CharacterTrailGroup:AddInput("CharacterTrailPart", {
	Text = "Attachment part",
	Default = "HumanoidRootPart",
	ClearTextOnFocus = false,
	Callback = function(Value)
		if TrailController then
			TrailController:SetAttachmentPart(Value)
		end
	end,
})

SyncTrailControls = function(State)
	TrailColorStart = State.ColorStart
	TrailColorEnd = State.ColorEnd
	TrailTransparencyStart = math.round(State.TransparencyStart * 100)
	TrailTransparencyEnd = math.round(State.TransparencyEnd * 100)
	TrailWidthStart = math.round(State.WidthStart * 100)
	TrailWidthEnd = math.round(State.WidthEnd * 100)
	TrailLightEmission = math.round(State.LightEmission * 100)
	TrailLightInfluence = math.round(State.LightInfluence * 100)
	Options.CharacterTrailColorStart:SetValueRGB(State.ColorStart)
	Options.CharacterTrailColorEnd:SetValueRGB(State.ColorEnd)
	Options.CharacterTrailTransparencyStart:SetValue(TrailTransparencyStart)
	Options.CharacterTrailTransparencyEnd:SetValue(TrailTransparencyEnd)
	Options.CharacterTrailWidthStart:SetValue(TrailWidthStart)
	Options.CharacterTrailWidthEnd:SetValue(TrailWidthEnd)
	Options.CharacterTrailAttachmentWidth:SetValue(State.AttachmentWidth)
	Options.CharacterTrailLifetime:SetValue(State.Lifetime)
	Options.CharacterTrailVerticalOffset:SetValue(State.VerticalOffset)
	Options.CharacterTrailMinLength:SetValue(State.MinLength)
	Options.CharacterTrailMaxLength:SetValue(State.MaxLength)
	Options.CharacterTrailTextureLength:SetValue(State.TextureLength)
	Options.CharacterTrailLightEmission:SetValue(TrailLightEmission)
	Options.CharacterTrailLightInfluence:SetValue(TrailLightInfluence)
	Options.CharacterTrailBrightness:SetValue(State.Brightness)
	Options.CharacterTrailPart:SetValue(State.AttachmentPart)
	Options.CharacterTrailTexture:SetValue(State.Texture)
	Options.CharacterTrailTextureMode:SetValue(State.TextureMode.Name)
	Toggles.CharacterTrailFaceCamera:SetValue(State.FaceCamera)
	for Name, Asset in CharacterTrail.TexturePresets do
		if Asset == State.Texture then
			Options.CharacterTrailTexturePreset:SetValue(Name)
			break
		end
	end
end

CharacterTrailGroup:AddButton("Rebind character trail", function()
	if TrailController then
		TrailController:Refresh()
	end
end)


local VisualControls = Tabs.Visuals:AddLeftGroupbox("ESP controls", "eye")
local VisualPreviewBox = Tabs.Visuals:AddRightGroupbox("Live previews", "scan-eye")
VisualControls:AddLabel("The preview uses the same renderer contract that can draw live player ESP.", true)

local ESPPreview
local SharedESPRenderer = UniversalESPPreviewRenderer or DrawingESPPreview and DrawingESPPreview.Create({
    Color = Color3.fromRGB(119, 166, 209),
    GradientColor = Color3.fromRGB(202, 220, 239),
}) or nil
if SharedESPRenderer then
	Library:OnUnload(function()
		SharedESPRenderer:Destroy()
	end)
end
if VisualPreview then
    local Created, PreviewOrError = pcall(function()
        return VisualPreviewBox:AddAddon("EmbeddedESPPreview", VisualPreview, {
            Id = "EmbeddedESPPreview",
            Name = "ESP preview",
            Height = 320,
            Color = Color3.fromRGB(119, 166, 209),
            GradientColor = Color3.fromRGB(202, 220, 239),
            Gradient = true,
            DynamicBoxes = true,
            Renderer = SharedESPRenderer,
            Style = {
                Motion = true,
                OutlineTransparency = 0.48,
            },
        })
    end)

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


local PreviewImage
local PreviewGallery
do
	local PreviewControls = Tabs.Preview:AddLeftGroupbox("Library controls", "component")
	PreviewControls:AddLabel("A compact interactive index of the library.", true)
	PreviewControls:AddButton("Show notification", function()
		Notify("Saved", "Your changes are ready.", 3)
	end)
    PreviewControls:AddButton("Show progress notification", function()
        local Notice = Library:Notify({ Title = "Loading assets", Description = "0 / 3", Steps = 3, Persist = true, ShowProgress = true })
        for Step = 1, 3 do
            task.delay(Step * 0.7, function()
                if Library.Unloaded or Notice.Destroyed then return end
                Notice:SetProgress(Step)
                Notice:ChangeDescription(tostring(Step) .. " / 3")
                if Step == 3 then
                    Notice:ChangeTitle("Assets loaded")
                    task.delay(1, function() Notice:Destroy() end)
                end
            end)
        end
    end)
    PreviewControls:AddButton("Toggle watermark", function()
        if Toggles.WatermarkEnabled then
            Toggles.WatermarkEnabled:SetValue(not Toggles.WatermarkEnabled.Value)
        end
    end)
    PreviewControls:AddToggle("PreviewFeatureToggle", {
		Text = "Example toggle",
		Default = true,
	})
	PreviewControls:AddSlider("PreviewStrength", {
		Text = "Example slider",
		Default = 65,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Suffix = "%",
	})
	PreviewControls:AddDropdown("PreviewMode", {
		Text = "Example dropdown",
		Values = { "Balanced", "Smooth", "Fast" },
		Default = "Balanced",
	})
	PreviewControls:AddInput("PreviewText", {
		Text = "Example input",
		Default = "MonHub",
		ClearTextOnFocus = false,
	})
	local PreviewAccent = PreviewControls:AddToggle("PreviewAccentEnabled", {
		Text = "Color and key addons",
		Default = true,
	})
	PreviewAccent:AddColorPicker("PreviewAccentColor", {
		Title = "Preview color",
		Default = Color3.fromRGB(139, 131, 214),
	})
	PreviewAccent:AddKeyPicker("PreviewAccentKey", {
		Default = "P",
		Text = "Preview action",
	})

	local PreviewAddons = Tabs.Preview:AddRightGroupbox("Addon modules", "package-plus")
	PreviewAddons:AddLabel("Open or trigger every large module from one place.", true)
	PreviewAddons:AddButton("Toggle skin catalog", function()
		if CatalogHost then
			CatalogHost:Toggle()
		end
	end)
	PreviewAddons:AddButton("Toggle dashboard", function()
		if Dashboard then
			Dashboard:Toggle()
		end
	end)
	PreviewAddons:AddButton("Next gallery image", function()
		if AddonGallery then
			AddonGallery:NextPage()
			local Current = AddonGallery:GetSelected()
			local CurrentIndex = 0
			for Index, Item in GalleryItems do
				if Current and Item.Id == Current.Id then
					CurrentIndex = Index
					break
				end
			end
			AddonGallery:Select(GalleryItems[(CurrentIndex % #GalleryItems) + 1].Id)
		end
	end)
	PreviewAddons:AddToggle("PreviewESPEnabled", {
		Text = "Live ESP preview",
		Default = false,
		Callback = function(Value)
			if Toggles.ESPEnabled then
				Toggles.ESPEnabled:SetValue(Value)
			elseif ESPPreview then
				ESPPreview:SetEnabled(Value)
			end
		end,
	})
	PreviewAddons:AddToggle("PreviewTrailEnabled", {
		Text = "Character trail",
		Default = false,
		Callback = function(Value)
			if Toggles.CharacterTrailEnabled then
				Toggles.CharacterTrailEnabled:SetValue(Value)
			elseif TrailController then
				TrailController:SetEnabled(Value)
			end
		end,
	})

	if ImagePreview then
		local PreviewImageBox = Tabs.Preview:AddRightGroupbox("Selected asset", "image")
		local Created, Result = pcall(function()
			return PreviewImageBox:AddAddon("PreviewImage", ImagePreview, {
				Height = 178,
				ImagePadding = 10,
				Title = "Neptune",
				Subtitle = "Interactive addon preview",
				Motion = true,
			})
		end)
		if Created then
			PreviewImage = Result
		end
	end

	if ImageGallery then
		local PreviewGalleryBox = Tabs.Preview:AddFullGroupbox("Gallery preview", "layout-grid")
		local Created, Result = pcall(function()
			return PreviewGalleryBox:AddAddon("PreviewGallery", ImageGallery, {
				Height = 250,
				MinCellWidth = 108,
				PageSize = 9,
				CellHeight = 82,
				ImagePadding = 5,
				Preview = PreviewImage,
				Items = GalleryItems,
			})
		end)
		if Created then
			PreviewGallery = Result
			PreviewGallery:Select("neptune", true)
		end
	end

	local PreviewPages = Tabs.Preview:AddFullGroupbox("Complete examples", "panels-top-left")
	PreviewPages:AddLabel("Each page contains the full API example for that area.", true)
	for _, Entry in {
		{ "Controls", Tabs.Controls },
		{ "Media", Tabs.Media },
		{ "Visuals", Tabs.Visuals },
		{ "ESP", Tabs.ESP },
		{ "Addons", Tabs.Addons },
		{ "Gallery", Tabs.Gallery },
		{ "Advanced", Tabs.Advanced },
		{ "UI settings", Tabs.Settings },
	} do
		PreviewPages:AddButton(Entry[1], function()
			Entry[2]:Show()
		end)
	end
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

local FontNames = Library:GetFontNames()
if #FontNames > 0 then
	MenuGroup:AddDropdown("InterfaceFont", {
		Text = "Font",
		Values = FontNames,
		Default = table.find(FontNames, Library.CurrentFontName) and Library.CurrentFontName or FontNames[1],
		Tooltip = "Typeface used by every label, control, and addon",
		Callback = function(Value)
			if not Library:SetFontByName(Value) then
				Notify("Font", tostring(Value) .. " is unavailable on this client")
			end
		end,
	})
end

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
	Library:SetWatermark(table.concat(Sections, "   ·   "))
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
WatermarkSettings:AddToggle("WatermarkAccent", {
	Text = "Accent marker",
	Default = false,
	Callback = function(Value)
		Library:SetWatermarkOptions({ Accent = Value })
	end,
})
WatermarkSettings:AddSlider("WatermarkOpacity", {
	Text = "Background transparency",
	Default = 0,
	Min = 0,
	Max = 90,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		Library:SetWatermarkOptions({ BackgroundTransparency = Value / 100 })
	end,
})
WatermarkSettings:AddSlider("WatermarkTextSize", {
	Text = "Text size",
	Default = 13,
	Min = 10,
	Max = 20,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		Library:SetWatermarkOptions({ TextSize = Value })
	end,
})
WatermarkSettings:AddSlider("WatermarkOutline", {
	Text = "Outline transparency",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		Library:SetWatermarkOptions({ OutlineTransparency = Value / 100 })
	end,
})
WatermarkSettings:AddSlider("WatermarkRadius", {
	Text = "Corner radius",
	Default = 5,
	Min = 0,
	Max = 16,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		Library:SetWatermarkOptions({ CornerRadius = Value })
	end,
})
WatermarkSettings:AddSlider("WatermarkPadding", {
	Text = "Vertical padding",
	Default = 6,
	Min = 2,
	Max = 16,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		Library:SetWatermarkOptions({ Padding = Value })
	end,
})
WatermarkSettings:AddSlider("WatermarkHorizontalPadding", {
    Text = "Horizontal padding",
    Default = 10,
    Min = 4,
    Max = 32,
    Rounding = 0,
    Suffix = "px",
    Callback = function(Value)
        Library:SetWatermarkOptions({ HorizontalPadding = Value })
    end,
})
WatermarkSettings:AddSlider("WatermarkMargin", {
    Text = "Screen margin",
    Default = 8,
    Min = 0,
    Max = 40,
    Rounding = 0,
    Suffix = "px",
    Callback = function(Value)
        Library:SetWatermarkOptions({ Margin = Value })
    end,
})
WatermarkSettings:AddSlider("WatermarkScale", {
	Text = "Scale",
	Default = 100,
	Min = 60,
	Max = 160,
	Rounding = 0,
	Suffix = "%",
	Callback = function(Value)
		Library:SetWatermarkOptions({ Scale = Value / 100 })
	end,
})
WatermarkSettings:AddSlider("WatermarkAccentWidth", {
	Text = "Accent width",
	Default = 2,
	Min = 1,
	Max = 4,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		Library:SetWatermarkOptions({ AccentWidth = Value })
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

local NotificationGroup = Tabs.Settings:AddGroupbox({
	Name = "Notifications",
	IconName = "bell",
	Side = 2,
	Collapsed = true,
})
SetGroupOrder(NotificationGroup, -70)
local NotificationWidth = Library.NotificationStyle.Width
local NotificationMargin = Library.NotificationStyle.Margin
local NotificationGap = Library.NotificationStyle.Gap
local NotificationPadding = Library.NotificationStyle.Padding
local NotificationRadius = Library.NotificationStyle.CornerRadius
local NotificationMaxVisible = Library.NotificationStyle.MaxVisible
local NotificationDuration = Library.NotificationStyle.DefaultDuration
local NotificationProgress = Library.NotificationStyle.ShowProgress
local NotificationAccent = Library.NotificationStyle.Accent
local NotificationDismissible = Library.NotificationStyle.Dismissible
local NotificationTitleSize = Library.NotificationStyle.TitleTextSize
local NotificationDescriptionSize = Library.NotificationStyle.DescriptionTextSize
local function ApplyNotificationStyle()
	Library:SetNotificationOptions({
		Width = NotificationWidth,
		Margin = NotificationMargin,
		Gap = NotificationGap,
		Padding = NotificationPadding,
		TitleTextSize = NotificationTitleSize,
		DescriptionTextSize = NotificationDescriptionSize,
		CornerRadius = NotificationRadius,
		MaxVisible = NotificationMaxVisible,
		DefaultDuration = NotificationDuration,
		ShowProgress = NotificationProgress,
		Accent = NotificationAccent,
		Dismissible = NotificationDismissible,
	})
end
NotificationGroup:AddSlider("NotificationTitleSize", {
	Text = "Title size",
	Default = NotificationTitleSize,
	Min = 9,
	Max = 20,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		NotificationTitleSize = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationDescriptionSize", {
	Text = "Description size",
	Default = NotificationDescriptionSize,
	Min = 9,
	Max = 20,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		NotificationDescriptionSize = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationWidth", {
	Text = "Width",
	Default = NotificationWidth,
	Min = 160,
	Max = 420,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		NotificationWidth = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationGap", {
	Text = "Stack gap",
	Default = NotificationGap,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		NotificationGap = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationMargin", {
	Text = "Screen margin",
	Default = NotificationMargin,
	Min = 0,
	Max = 32,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		NotificationMargin = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationPadding", {
	Text = "Card padding",
	Default = NotificationPadding,
	Min = 4,
	Max = 20,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		NotificationPadding = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationRadius", {
	Text = "Corner radius",
	Default = NotificationRadius,
	Min = 0,
	Max = 18,
	Rounding = 0,
	Suffix = "px",
	Callback = function(Value)
		NotificationRadius = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationMaxVisible", {
	Text = "Visible cards",
	Default = NotificationMaxVisible,
	Min = 1,
	Max = 12,
	Rounding = 0,
	Callback = function(Value)
		NotificationMaxVisible = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddSlider("NotificationDuration", {
	Text = "Default duration",
	Default = NotificationDuration,
	Min = 1,
	Max = 12,
	Rounding = 1,
	Suffix = "s",
	Callback = function(Value)
		NotificationDuration = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddToggle("NotificationProgress", {
	Text = "Progress bar",
	Default = NotificationProgress,
	Callback = function(Value)
		NotificationProgress = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddToggle("NotificationAccent", {
	Text = "Accent marker",
	Default = NotificationAccent,
	Callback = function(Value)
		NotificationAccent = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddToggle("NotificationDismissible", {
	Text = "Close button",
	Default = NotificationDismissible,
	Callback = function(Value)
		NotificationDismissible = Value
		ApplyNotificationStyle()
	end,
})
NotificationGroup:AddButton("Preview notification styles", function()
	for Index, Variant in { "Default", "Success", "Warning", "Error" } do
		Library:Notify({
			Title = Variant,
			Description = Index == 2 and "Settings saved." or Index == 3 and "Select an item first." or Index == 4 and "Could not load the image." or "Library is ready.",
			Variant = Variant,
			Icon = Index == 2 and "circle-check" or Index == 3 and "triangle-alert" or Index == 4 and "circle-x" or "info",
			Time = 3,
		})
	end
end)

if ThemeManager then
	local ThemeReady, ThemeError = pcall(function()
		ThemeManager:SetFolder("MonHub")
		ThemeManager:SetLibrary(Library)
		local AppearanceBox = ThemeManager:ApplyToTab(Tabs.Settings)
		SetGroupOrder(AppearanceBox, -90)
		if ThemeManager.CreateAppearanceManager then
			local Details = Tabs.Settings:AddGroupbox({
				Name = "Appearance",
				IconName = "sliders-horizontal",
				Side = 1,
				Collapsed = true,
			})
			ThemeManager:CreateAppearanceManager(Details)
			SetGroupOrder(Details, -80)
		end
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
		SaveManager:RegisterAdapter("ExampleModuleState", {
			Save = function()
				local Selected = SkinCollection and SkinCollection:GetSelected()
				return {
					Selected = Selected and Selected.Id or nil,
					CatalogVisible = CatalogHost and CatalogHost.Visible or false,
					CatalogLayout = CatalogModule and CatalogModule.Layout or nil,
					DashboardVisible = Dashboard and Dashboard.Visible or false,
				}
			end,
			Validate = function(Value)
				if type(Value) ~= "table" then return false, "expected module state table" end
				if Value.Selected ~= nil and type(Value.Selected) ~= "string" then return false, "invalid selection" end
				if Value.CatalogLayout ~= nil and type(Value.CatalogLayout) ~= "string" then return false, "invalid layout" end
				if Value.CatalogVisible ~= nil and type(Value.CatalogVisible) ~= "boolean" then return false, "invalid catalog visibility" end
				if Value.DashboardVisible ~= nil and type(Value.DashboardVisible) ~= "boolean" then return false, "invalid dashboard visibility" end
				return true
			end,
			Load = function(Value)
				if SkinCollection then SkinCollection:Select(Value.Selected) end
				if CatalogModule and Value.CatalogLayout then CatalogModule:SetLayout(Value.CatalogLayout) end
				if CatalogHost then CatalogHost:SetVisible(Value.CatalogVisible == true) end
				if Dashboard then Dashboard:SetVisible(Value.DashboardVisible == true) end
			end,
		})
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
		AssetCatalog = AssetCatalog,
		CollectionModel = CollectionModel,
		CharacterTrail = CharacterTrail,
		DashboardWindow = DashboardWindow,
		VisualPreview = VisualPreview,
		DrawingESPPreview = DrawingESPPreview,
		UniversalESP = UniversalESP,
		UniversalESPUI = UniversalESPUI,
		SaveManager = SaveManager,
		ThemeManager = ThemeManager,
	},
	AddonExamples = {
		PreviewGallery = PreviewGallery,
		PreviewImage = PreviewImage,
		ImageGallery = AddonGallery,
		ImagePreview = AddonImagePreview,
		AssetCatalog = CatalogModule,
		SkinCollection = SkinCollection,
		AssetCatalogWindow = CatalogHost,
		CharacterTrail = TrailController,
		DashboardWindow = Dashboard,
		UniversalESP = UniversalESPController,
		UniversalESPPanel = UniversalESPPanel,
	},
	Repository = ActiveRepository,
}
