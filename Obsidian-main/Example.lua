












assert(type(loadstring) == "function", "This example requires an executor with loadstring support.")

local PRIMARY_REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local RELEASE_VERSION = "0.0.1-release-3"
-- Fallback used only when the manifest cannot be read; the manifest revision replaces it below.
local SOURCE_CACHE_KEY = RELEASE_VERSION .. "-configs-2-" .. tostring(os.time())
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

	local Success, Response = pcall(game.HttpGet, game, Url, false)
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

	if type(Module) ~= "table" then
		return nil, string.format("%s: expected a module table, received %s. Update Library, Example and addons together.", Url, typeof(Module))
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

-- Publishing a new revision:
--   1. Edit the library or addon files that changed.
--   2. In Library.lua raise Library.Revision to a value that sorts above the current one.
--      The shipped format is "YYYY-MM-DD.N": use today's date with N = 1, or raise N for a
--      second publish in one day. Leave ReleaseVersion alone.
--   3. Set manifest.json "revision" to that same value, and update "modules" if a file was
--      added or removed.
--   4. Set manifest.json "release" to the marketing version clients should report. That field
--      is the single source of truth for the release string; the loader never derives logic
--      from it, so the differing release-3 / release-12 / release-15 mentions elsewhere are
--      harmless. Pick one and reconcile the docs when ready.
--   5. Commit and push. Clients bust their cache automatically because the query string is
--      built from the revision, and a client still holding an older build is warned by name.
local function RevisionParts(Revision)
	if type(Revision) ~= "string" then
		return nil
	end
	local Parts = {}
	for Number in string.gmatch(Revision, "%d+") do
		table.insert(Parts, tonumber(Number))
	end
	return #Parts > 0 and Parts or nil
end

local function RevisionOlder(Loaded, Published)
	local Left, Right = RevisionParts(Loaded), RevisionParts(Published)
	if not Left or not Right then
		return false
	end
	for Index = 1, math.max(#Left, #Right) do
		local A, B = Left[Index] or 0, Right[Index] or 0
		if A ~= B then
			return A < B
		end
	end
	return false
end

local function LoadManifest(BaseUrl)
	-- The manifest is tiny and must never be served stale, so it always busts on os.time().
	local Downloaded, Source = DownloadSource(BaseUrl .. "manifest.json?monhub=" .. tostring(os.time()))
	if not Downloaded or type(Source) ~= "string" then
		return nil
	end
	local Ok, Decoded = pcall(function()
		return game:GetService("HttpService"):JSONDecode(Source)
	end)
	return Ok and type(Decoded) == "table" and Decoded or nil
end

local Manifest = LoadManifest(PRIMARY_REPOSITORY)
if Manifest and type(Manifest.revision) == "string" then
	SOURCE_CACHE_KEY = Manifest.revision .. "-configs-2"
end

local Library, ActiveRepository = LoadModule("Library.lua", true)
if Library.ReleaseVersion ~= RELEASE_VERSION then
	warn(string.format("MonHub version notice: expected %s, received %s", RELEASE_VERSION, tostring(Library.ReleaseVersion)))
end
if Manifest and type(Manifest.revision) == "string" then
	local Loaded = Library.Revision
	if type(Loaded) == "string" and RevisionOlder(Loaded, Manifest.revision) then
		warn(string.format(
			"MonHub cache warning: loaded revision %s is older than published revision %s. Your client served a cached copy of the library; clear its HTTP cache or relaunch to pick up the current build.",
			Loaded,
			Manifest.revision
		))
	end
end
local SaveManager = LoadModule("addons/SaveManager.lua", false, ActiveRepository)
local ThemeManager = LoadModule("addons/ThemeManager.lua", false, ActiveRepository)
local VisualPreview = LoadModule("addons/VisualPreview.lua", false, ActiveRepository)
local DrawingESPPreview = LoadModule("addons/DrawingESPPreview.lua", false, ActiveRepository)
local ImageGallery = LoadModule("addons/ImageGallery.lua", false, ActiveRepository)
if ImageGallery then Library:RegisterImageGrid(ImageGallery) end
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
local PreviewModulesMinimal = false
local PreviewModuleHighlighted = false
do
	local PreviewControls = Tabs.Preview:AddLeftGroupbox("Library controls", "component")
	PreviewControls:AddSection("Controls and presets")    local WatermarkPresetIndex = 1
    PreviewControls:AddButton("Next watermark style", function()
        local Presets = { "Compact", "Minimal", "Classic" }
        WatermarkPresetIndex = WatermarkPresetIndex % #Presets + 1
        Library:SetWatermarkPreset(Presets[WatermarkPresetIndex])
    end)
    PreviewControls:AddButton("Compact spectator list", function()
        if not DashboardWindow then return end
        local List = DashboardWindow.CreateStandalone(Library, {
            Title = "Spectators", WindowWidth = 240, AutoHeight = true,
            Compact = true, Closable = true, Resizable = false,
        })
        List:AddMetric({ Label = "player_one", Value = "spectating" })
        List:AddMetric({ Label = "player_two", Value = "spectating" })
    end)
    local ChangeLabel = PreviewControls:AddLabel("Options unchanged")
    local DisconnectChanges = Library:OnConfigChanged(function(Event)
        ChangeLabel:SetText("Last change: " .. (Event.Id and tostring(Event.Id) or Event.Source))
    end)
    Library:OnUnload(DisconnectChanges)
    PreviewControls:AddButton("Apply compact preset", function()
        Library:SetValues({ PreviewStrength = 40, PreviewMode = "Smooth", PreviewFeatureToggle = true })
    end)
    PreviewControls:AddSlider("PreviewReleaseOnly", {
        Text = "Commit on release", Min = 0, Max = 100, Default = 50, Rounding = 0,
        CallbackOnRelease = true, Save = false,
        Tooltip = "Hold on mobile to read this tooltip. This value is not saved.",
        Callback = function(Value) ChangeLabel:SetText("Committed: " .. tostring(Value)) end,
    })
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

	local BindProfiles = Library:AddKeybindProfile("PreviewProfiles", {
        Profiles = {
            Primary = { PreviewAccentKey = { "P", "Toggle", {} } },
            Secondary = { PreviewAccentKey = { "O", "Hold", {} } },
        },
    })
    PreviewControls:AddButton("Next keybind profile", function() BindProfiles:Next() end)
    local LazyPreview = Window:AddLazyTab("Deferred example", {
        Icon = "clock",
        Build = function(Tab)
            local Group = Tab:AddLeftGroupbox("Created on demand")
            Group:AddSection("Lazy content")
            Group:AddLabel("This page builds once, when shown or before config persistence.", true)
        end,
    })
    PreviewControls:AddButton("Open deferred page", function() LazyPreview:Show() end)

    local ProgressDemo = PreviewControls:AddProgressBar("PreviewProgress", { Text = "Completed", Max = 100, Value = 25 })
    local StatDemo = PreviewControls:AddStatRow("PreviewStat", { Text = "Processed", Value = "25 items" })
    PreviewControls:AddButton("Advance progress", function()
        local Value = (ProgressDemo.Value + 25) % 125
        ProgressDemo:SetValue(Value)
        StatDemo:SetValue(tostring(Value) .. " items")
    end)
    PreviewControls:AddInput("PreviewAmount", {
        Text = "Amount", Default = "12000", Numeric = true, Min = 0, Max = 1000000,
        ThousandsSeparator = true, Save = false,
    })
    PreviewControls:AddDropdown("PreviewPlayerName", {
        Text = "Player username", SpecialType = "Player", PlayerValue = "Name", Save = false,
    })
    PreviewControls:AddButton("Toggle deferred tab visibility", function()
        LazyPreview:SetVisible(LazyPreview.Visible == false)
    end)
    if AssetCatalog then
        local MultiBox = Tabs.Preview:AddFullGroupbox("Multiple selection", "images")
        local MultiCatalog = MultiBox:AddAddon("PreviewMultiCatalog", AssetCatalog, {
            Items = GalleryItems, MultiSelect = true, ShowPager = false, Layout = "Grid", Height = 280,
            OnSelected = function(Items) StatDemo:SetValue(tostring(#Items) .. " selected") end,
        })
        MultiBox:AddButton("Mark first card ready", function()
            local Item = MultiCatalog.Items[1]
            if Item then MultiCatalog:SetItemState(Item.Id, { Status = "Ready" }) end
        end)
    end

    PreviewControls:AddButton("Open command palette", function() Library:OpenCommandPalette() end)
    PreviewControls:AddButton("Favorite strength", function()
        Library:SetFavorite("PreviewStrength", true)
        Library:OpenCommandPalette(true)
    end)
    Library:EnableHistory(100)
    Library:EnableCommandKeys()
    PreviewControls:AddButton("Undo last edit", function() Library:Undo() end)
    PreviewControls:AddButton("Redo last edit", function() Library:Redo() end)
    local DetailsState = Library:State(false)
    PreviewControls:AddToggle("PreviewStateToggle", { Text = "Reactive details", State = DetailsState, Save = false })
    PreviewControls:AddInput("PreviewConditional", {
        Text = "Conditional input", Default = "Visible through State:Get()", Save = false,
        VisibleWhen = function() return DetailsState:Get() end,
    })
    local DataDemo = Tabs.Preview:AddFullGroupbox("Data and runtime", "chart-no-axes-combined")
    local TableDemo = DataDemo:AddTable("PreviewDataTable", {
        Height = 180, Columns = { { Key = "Name", Width = 3 }, { Key = "Value", Width = 1, Align = "Right" } },
        Rows = { { Id = 1, Name = "First", Value = 20 }, { Id = 2, Name = "Second", Value = 10 } },
    })
    DataDemo:AddButton("Load 5,000 rows", function()
        local Rows = {}
        for Index = 1, 5000 do Rows[Index] = { Id = Index, Name = "Item " .. Index, Value = 5001 - Index } end
        TableDemo:SetRows(Rows)
    end)
    local ChartDemo = DataDemo:AddChart("PreviewChart", { Height = 80, Capacity = 30, Values = { 2, 4, 3, 8, 6, 10 } })
    DataDemo:AddButton("Append chart sample", function() ChartDemo:Push(math.random(1, 12)) end)
    local LogDemo = DataDemo:AddLog("PreviewLog", { Height = 130, Capacity = 100 })
    DataDemo:AddButton("Inspect runtime", function()
        local Report = Library:Diagnose()
        LogDemo:Append("Info", string.format("%d active rows, %d pooled rows, %d tracked connections", Report.ActiveRows, Report.PooledRows, Report.Connections))
    end)

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
	PreviewAddons:AddButton("Toggle minimal modules", function()
		PreviewModulesMinimal = not PreviewModulesMinimal
		if PreviewImage and PreviewImage.SetMinimal then
			PreviewImage:SetMinimal(PreviewModulesMinimal)
		end
		if PreviewGallery and PreviewGallery.SetMinimal then
			PreviewGallery:SetMinimal(PreviewModulesMinimal)
		end
	end)
	PreviewAddons:AddButton("Highlight gallery module", function()
		PreviewModuleHighlighted = not PreviewModuleHighlighted
		if PreviewGallery and PreviewGallery.SetHighlighted then
			PreviewGallery:SetHighlighted(PreviewModuleHighlighted)
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
			return PreviewGalleryBox:AddImageGrid("PreviewGallery", {
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

	local EditorDemo = Tabs.Preview:AddFullGroupbox("Item editor", "layers")
    local ActiveSlot = "Sticker1"
    local SelectedItem
    local DemoSlots = EditorDemo:AddItemSlots("PreviewStickerSlots", {
        Items = GalleryItems,
        DragType = "Sticker",
        OnSelect = function(Id)
            ActiveSlot = Id
            if SelectedItem then Options.PreviewStickerSlots:Assign(Id, SelectedItem) end
        end,
    })
    EditorDemo:AddItemSlots("PreviewCharmSlots", {
        Slots = { "Charm1", "Charm2", "Charm3", "Charm4" },
        Items = GalleryItems,
        DragType = "Sticker",
    })
    EditorDemo:AddSliderGroup("PreviewStickerTransform", {
        Callback = function(Values)
            if Options.PreviewEditorViewport then
                local Object = Options.PreviewEditorViewport.Object
                Object:PivotTo(CFrame.Angles(0, math.rad(Values.Rotation), 0))
            end
        end,
    })
    if ImageGallery then
        EditorDemo:AddImageGrid("PreviewStickerGrid", {
            Items = GalleryItems, Height = 230, PageSize = 9,
            DraggableItems = true, DragType = "Sticker",
            Callback = function(_, Item) SelectedItem = Item end,
        })
    end
    EditorDemo:AddButton("Open nested editor", function()
        local CatalogPopup = Window:AddPopup("PreviewCatalogPopup", {
            Title = "Catalog", Description = "Open an editor above this catalog.", Width = 580,
        })
        if ImageGallery then
            CatalogPopup:AddImageGrid("PreviewPopupGrid", { Items = GalleryItems, Height = 220 })
        end
        CatalogPopup:AddButton("Edit selected slot", function()
            local EditorPopup = CatalogPopup:AddPopup("PreviewStickerPopup", {
                Title = ActiveSlot, Description = "Drag to rotate. Scroll or pinch to zoom.", Width = 580,
                FooterButtons = { { Text = "Close", Callback = function(Dialog) Dialog:Dismiss() end } },
            })
            local Sample = Instance.new("Part")
            Sample.Name = "Preview block"
            Sample.Size = Vector3.new(4, 2, 1)
            Sample.Anchored = true
            Sample.Color = Color3.fromRGB(100, 105, 115)
            local Point = Instance.new("Attachment")
            Point.Name = "Charm1"
            Point.Position = Vector3.new(1.5, 0.5, 0.5)
            Point.Parent = Sample
            EditorPopup:AddViewport("PreviewEditorViewport", { Model = Sample, Clone = false, Interactive = true, Height = 180, ShowAttachments = true })
            EditorPopup:AddSliderGroup("PreviewPopupTransform", {
                Callback = function(Value)
                    Sample:PivotTo(CFrame.new(Value.X, Value.Y, 0) * CFrame.Angles(0, 0, math.rad(Value.Rotation)))
                    Sample.Size = Vector3.new(4, 2, 1) * Value.Scale
                    Sample.Transparency = Value.Wear
                    Options.PreviewEditorViewport:RefreshAttachmentPoints()
                end,
            })
        end)
    end)
    EditorDemo:AddButton("Clear selected slot", function() DemoSlots:Assign(ActiveSlot, nil) end)

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
		local Loaded, AutoloadError = SaveManager:LoadAutoloadConfig()
		if not Loaded then
			warn("[MonHub Example] Autoload failed: " .. tostring(AutoloadError))
		end
	end)

	if not SaveReady then
		warn("[MonHub Example] SaveManager disabled: " .. tostring(SaveError))
	end
end

-- ===========================================================================
-- Living all-controls demo and layout test (roadmap 127 and 128)
--
-- Everything below this line is the smoke test. It builds one tab per topic so
-- a reader can jump straight to the thing they want to copy:
--   New Controls  the controls that were missing from the old example
--   Runtime       Library:State, VisibleWhen, undo, favourites, declarative build
--   Layout        window width and density switches for eyeballing breakpoints
--   Recipes       four small hubs (farm, combat, visuals, settings) as sub-tabs
--
-- Each section is wrapped in pcall so one broken demo warns instead of stopping
-- the whole file from loading. Library.lua grows while this runs, so anything
-- that was not present at build time is skipped rather than called blindly.
-- ===========================================================================

local DemoTabs = {}

-- Undo and Redo record control changes once history is on. Turn it on before
-- any demo control is built so the buttons further down have something to walk.
pcall(function()
	if Library.EnableHistory then
		Library:EnableHistory(100)
	end
	if Library.EnableCommandKeys then
		Library:EnableCommandKeys()
	end
end)

-- ---------------------------------------------------------------------------
-- New Controls: one live example of every control the audit flagged as absent.
-- ---------------------------------------------------------------------------
local NewControlsOk, NewControlsError = pcall(function()
	local Tab = Window:AddTab("New Controls", "shapes")
	DemoTabs.NewControls = Tab

	local FormGroup = Tab:AddLeftGroupbox("Form controls", "text-cursor-input")

	FormGroup:AddCheckbox("Demo_Checkbox", {
		Text = "Standalone checkbox",
		Default = true,
		Tooltip = "AddCheckbox is a toggle pinned to the checkbox layout.",
		Callback = function(Value)
			print("[MonHub] Demo checkbox:", Value)
		end,
	})

	FormGroup:AddInput("Demo_ValidatedInput", {
		Text = "Server slot",
		Placeholder = "1 to 100",
		Numeric = true,
		Finished = true,
		Clearable = true,
		Copyable = true,
		Prefix = "#",
		Validate = function(Text)
			local Number = tonumber(Text)
			if not Number then
				return "Enter a number"
			end
			if Number < 1 or Number > 100 then
				return "Use 1 to 100"
			end
			-- Return nothing to clear the error and accept the value.
		end,
		Callback = function(Value)
			print("[MonHub] Server slot:", Value)
		end,
	})

	FormGroup:AddInput("Demo_MultilineInput", {
		Text = "Notes",
		Placeholder = "Multiline, grows as you type",
		Multiline = true,
		Finished = true,
	})

	FormGroup:AddSegmented("Demo_Segmented", {
		Text = "Fire mode",
		Values = { "Off", "Single", "Auto" },
		Default = "Single",
		Callback = function(Value)
			print("[MonHub] Fire mode:", Value)
		end,
	})

	FormGroup:AddDropdown("Demo_ChipDropdown", {
		Text = "Targets",
		Values = { "Head", "Torso", "Legs", "Arms" },
		Default = { Head = true, Torso = true },
		Multi = true,
		Chips = true,
		Tooltip = "Multi dropdown with removable chips.",
	})

	FormGroup:AddSplitButton("Demo_SplitButton", {
		Text = "Teleport to spawn",
		Callback = function()
			Notify("Teleport", "Primary split action fired.", 3)
		end,
		Options = {
			{
				Text = "Teleport to safe zone",
				Icon = "shield",
				Callback = function()
					Notify("Teleport", "Safe zone option fired.", 3)
				end,
			},
			{
				Text = "Teleport to last death",
				Icon = "skull",
				Callback = function()
					Notify("Teleport", "Last death option fired.", 3)
				end,
			},
		},
	})

	-- Button:SetState walks Idle, Loading, then Success or Error.
	local StatefulButton
	StatefulButton = FormGroup:AddButton({
		Text = "Save profile",
		Func = function()
			if not StatefulButton then
				return
			end
			StatefulButton:SetState("Loading", "Saving...")
			task.delay(1, function()
				if StatefulButton and not StatefulButton.Destroyed then
					StatefulButton:SetState("Success", "Saved")
				end
			end)
		end,
	})

	local PresentationGroup = Tab:AddRightGroupbox("Presentation", "layout-panel-top")

	PresentationGroup:AddBadge("Demo_Badge", {
		Label = "Session status",
		Text = "Live",
		Variant = "Success",
	})

	local StepsControl = PresentationGroup:AddSteps("Demo_Steps", {
		Steps = {
			{ Title = "Connect", Text = "Join the server" },
			{ Title = "Configure", Text = "Pick your options" },
			{ Title = "Run", Text = "Start the hub" },
		},
	})
	if StepsControl and StepsControl.SetCurrent then
		StepsControl:SetCurrent(1)
	end

	local StepIndex = 1
	PresentationGroup:AddButton({
		Text = "Advance step",
		Func = function()
			StepIndex = StepIndex % 3 + 1
			if StepsControl and StepsControl.SetCurrent then
				StepsControl:SetCurrent(StepIndex)
			end
		end,
	})

	PresentationGroup:AddDetailList("Demo_DetailList", {
		Items = {
			{ Icon = "user", Title = "Owner", Text = "SoftRatatui" },
			{ Icon = "clock", Title = "Uptime", Text = "12 minutes" },
			{ Icon = "activity", Title = "State", Text = "Running" },
		},
	})

	PresentationGroup:AddSettingsCard("Demo_SettingsCard", {
		Title = "Auto rejoin",
		Text = "Rejoin the server after a disconnect.",
		Control = {
			Type = "Toggle",
			Text = "Enabled",
			Default = false,
		},
	})

	-- A skeleton stands in while data loads; toggle it to compare states.
	local SkeletonControl = PresentationGroup:AddSkeleton("Demo_Skeleton", {
		Rows = 3,
	})
	local SkeletonRunning = true
	if SkeletonControl and SkeletonControl.Start then
		SkeletonControl:Start()
	end
	PresentationGroup:AddButton({
		Text = "Toggle skeleton",
		Func = function()
			if not SkeletonControl then
				return
			end
			SkeletonRunning = not SkeletonRunning
			SkeletonControl:SetVisible(SkeletonRunning)
		end,
	})

	PresentationGroup:AddEmptyState("Demo_EmptyState", {
		Icon = "inbox",
		Title = "No saved configs",
		Text = "Create one to see it listed here.",
		ActionText = "Create config",
		Callback = function()
			Notify("Empty state", "Action button fired.", 3)
		end,
	})

	-- AddDependencyGroupbox is a full card that only shows while its master is on.
	local DepMasterGroup = Tab:AddLeftGroupbox("Dependency card", "workflow")
	local DepMaster = DepMasterGroup:AddToggle("Demo_DepMaster", {
		Text = "Show extra options",
		Default = false,
	})
	local DepBox = DepMasterGroup:AddDependencyGroupbox()
	DepBox:AddToggle("Demo_DepChild", {
		Text = "Extra option",
		Default = true,
	})
	DepBox:AddSlider("Demo_DepSlider", {
		Text = "Extra amount",
		Min = 0,
		Max = 100,
		Default = 50,
		Rounding = 0,
	})
	DepBox:SetupDependencies({ { DepMaster, true } })
end)
if not NewControlsOk then
	warn("[MonHub Example] New Controls tab skipped: " .. tostring(NewControlsError))
end

-- ---------------------------------------------------------------------------
-- Runtime: the reactive and control-management API, none of which had a demo.
-- ---------------------------------------------------------------------------
local RuntimeOk, RuntimeError = pcall(function()
	local Tab = Window:AddTab("Runtime", "cpu")
	DemoTabs.Runtime = Tab

	-- One Library:State bound to two toggles. Flip either and the other follows.
	local StateGroup = Tab:AddLeftGroupbox("Shared state", "share-2")
	StateGroup:AddLabel("Both toggles share a single Library:State. Flip one.", true)
	local SyncState = Library:State(true)
	StateGroup:AddToggle("Demo_SyncA", {
		Text = "Mirror A",
		Default = true,
		State = SyncState,
	})
	StateGroup:AddToggle("Demo_SyncB", {
		Text = "Mirror B",
		Default = true,
		State = SyncState,
	})

	-- VisibleWhen and EnabledWhen react to a state instead of a dependency box.
	local ReactiveGroup = Tab:AddRightGroupbox("Conditional controls", "eye")
	local AdvancedState = Library:State(false)
	ReactiveGroup:AddToggle("Demo_ShowAdvanced", {
		Text = "Show advanced",
		Default = false,
		Callback = function(Value)
			AdvancedState:Set(Value)
		end,
	})
	ReactiveGroup:AddSlider("Demo_AdvancedSlider", {
		Text = "Advanced power",
		Min = 0,
		Max = 100,
		Default = 25,
		Rounding = 0,
		VisibleWhen = function()
			return AdvancedState:Get()
		end,
	})
	ReactiveGroup:AddToggle("Demo_GatedToggle", {
		Text = "Only usable while advanced is on",
		Default = false,
		EnabledWhen = function()
			return AdvancedState:Get()
		end,
	})

	-- GetControl reads one control by id, ForEach walks every control.
	local BulkGroup = Tab:AddLeftGroupbox("Bulk operations", "list-checks")
	BulkGroup:AddButton({
		Text = "Count controls with ForEach",
		Func = function()
			local Total, Toggles = 0, 0
			Library:ForEach(function(Control)
				Total += 1
				if Control.Type == "Toggle" then
					Toggles += 1
				end
			end)
			Notify("ForEach", string.format("%d controls, %d of them toggles.", Total, Toggles), 4)
		end,
	})
	BulkGroup:AddButton({
		Text = "Flip Mirror A with GetControl",
		Func = function()
			local Control = Library:GetControl("Demo_SyncA")
			if Control and Control.SetValue then
				Control:SetValue(not Control.Value)
			end
		end,
	})

	-- ResetScope on a groupbox returns just that group's controls to default.
	local ResetGroup = Tab:AddRightGroupbox("Reset a scope", "rotate-ccw")
	ResetGroup:AddSlider("Demo_ResetSlider", {
		Text = "Sensitivity",
		Min = 0,
		Max = 100,
		Default = 30,
		Rounding = 0,
	})
	ResetGroup:AddToggle("Demo_ResetToggle", {
		Text = "Snap lines",
		Default = false,
	})
	ResetGroup:AddButton({
		Text = "Reset this group",
		Func = function()
			-- Confirm false skips the dialog and resets straight away.
			ResetGroup:Reset(false)
		end,
	})

	-- Undo and Redo replay the recorded change history.
	local HistoryGroup = Tab:AddLeftGroupbox("Undo and redo", "history")
	HistoryGroup:AddLabel("Change a control above, then step the history.", true)
	HistoryGroup:AddButton({
		Text = "Undo",
		Func = function()
			Library:Undo()
		end,
	})
	HistoryGroup:AddButton({
		Text = "Redo",
		Func = function()
			Library:Redo()
		end,
	})

	-- The command palette needs an on-screen entry because Ctrl+K is not on a phone.
	local CommandGroup = Tab:AddRightGroupbox("Command palette", "command")
	if Library.RegisterCommand then
		Library:RegisterCommand("demo_notify", "Say hello", function()
			Notify("Command", "Ran the demo command.", 3)
		end)
		Library:RegisterCommand("demo_advanced", "Toggle advanced", function()
			AdvancedState:Set(not AdvancedState:Get())
		end)
	end
	CommandGroup:AddButton({
		Text = "Open command palette",
		Func = function()
			Library:OpenCommandPalette()
		end,
	})
	-- Favourites feed the favourites-only view of the same palette.
	pcall(function()
		Library:SetFavorite("Demo_SyncA", true)
		Library:SetFavorite("Demo_ResetSlider", true)
	end)
	CommandGroup:AddButton({
		Text = "Open favourites",
		Func = function()
			Library:OpenCommandPalette(true)
		end,
	})

	-- The same three controls built two ways: by hand, then from a table.
	local ImperativeGroup = Tab:AddLeftGroupbox("Built imperatively", "wrench")
	ImperativeGroup:AddToggle("Demo_ImpToggle", { Text = "Enabled", Default = true })
	ImperativeGroup:AddSlider("Demo_ImpSlider", {
		Text = "Amount",
		Min = 0,
		Max = 100,
		Default = 40,
		Rounding = 0,
	})
	ImperativeGroup:AddDropdown("Demo_ImpDropdown", {
		Text = "Target",
		Values = { "Nearest", "Farthest", "Random" },
		Default = "Nearest",
	})

	local DeclarativeGroup = Tab:AddRightGroupbox("Built from a table", "code")
	DeclarativeGroup:AddLabel("Same controls, described as data and built by Library:BuildElementInto.", true)
	if Library.BuildElementInto then
		local Spec = {
			{ Id = "Demo_DeclToggle", Type = "Toggle", Text = "Enabled", Default = true },
			{ Id = "Demo_DeclSlider", Type = "Slider", Text = "Amount", Min = 0, Max = 100, Default = 40, Rounding = 0 },
			{ Id = "Demo_DeclDropdown", Type = "Dropdown", Text = "Target", Values = { "Nearest", "Farthest", "Random" }, Default = "Nearest" },
		}
		for _, Element in Spec do
			local Id = Element.Id
			Element.Id = nil
			Library:BuildElementInto(DeclarativeGroup, Id, Element)
		end
	end
end)
if not RuntimeOk then
	warn("[MonHub Example] Runtime tab skipped: " .. tostring(RuntimeError))
end

-- ---------------------------------------------------------------------------
-- Layout: switches for watching the responsive breakpoints and density presets.
-- ---------------------------------------------------------------------------
local LayoutOk, LayoutError = pcall(function()
	local Tab = Window:AddTab("Layout", "layout-template")
	DemoTabs.Layout = Tab

	local WidthGroup = Tab:AddLeftGroupbox("Window width", "move-horizontal")
	WidthGroup:AddLabel("Resize the window through the breakpoints. Below the single column width the two columns stack and the sidebar compacts.", true)

	local function SetWindowWidth(Width)
		if not Window.Frame then
			return
		end
		local Height = Window.Frame.Size.Y.Offset
		Window.Frame.Size = UDim2.fromOffset(Width, Height)
		Window.Frame.Position = UDim2.new(
			0.5,
			-math.floor(Width / 2),
			Window.Frame.Position.Y.Scale,
			Window.Frame.Position.Y.Offset
		)
		if Window.RefreshResponsiveLayout then
			Window:RefreshResponsiveLayout()
		end
	end

	WidthGroup:AddSegmented("Demo_WidthPreset", {
		Text = "Preset",
		Values = { "Phone", "Tablet", "Desktop" },
		Default = "Desktop",
		Callback = function(Value)
			local Width = 900
			if Value == "Phone" then
				Width = 500
			elseif Value == "Tablet" then
				Width = 700
			end
			SetWindowWidth(Width)
		end,
	})

	local DensityGroup = Tab:AddRightGroupbox("Density", "rows-3")
	DensityGroup:AddLabel("Compare the spacing presets live. Touch is picked for you on mobile.", true)
	DensityGroup:AddSegmented("Demo_DensityPreset", {
		Text = "Preset",
		Values = { "Comfortable", "Compact", "Touch" },
		Default = "Comfortable",
		Callback = function(Value)
			Library:SetDensity(Value)
		end,
	})

	-- A progress pair so density and width changes have something to reflow.
	local SampleGroup = Tab:AddLeftGroupbox("Sample content", "gauge")
	local Determinate = SampleGroup:AddProgressBar("Demo_Progress", {
		Text = "Download",
		Value = 0,
		Segments = 10,
	})
	if Determinate and Determinate.SetValue then
		local Progress = 0
		Library:GiveSignal(RunService.Heartbeat:Connect(function(Delta)
			Progress = (Progress + Delta * 12) % 100
			Determinate:SetValue(math.floor(Progress))
		end))
	end
	local Busy = SampleGroup:AddProgressBar("Demo_ProgressBusy", {
		Text = "Working",
		Value = 0,
	})
	if Busy and Busy.SetIndeterminate then
		Busy:SetIndeterminate(true)
	end
end)
if not LayoutOk then
	warn("[MonHub Example] Layout tab skipped: " .. tostring(LayoutError))
end

-- ---------------------------------------------------------------------------
-- Recipes: four small hubs as sub-tabs under one parent. The parent is
-- collapsed by default, shows a chevron, and auto-expands when a child opens.
-- Copy any one of these as a starting point for a real menu.
-- ---------------------------------------------------------------------------
local RecipesOk, RecipesError = pcall(function()
	local Parent = Window:AddTab("Recipes", "book-open")
	DemoTabs.Recipes = Parent
	Parent:AddLeftGroupbox("Recipes", "book-open")
		:AddLabel("Expand this tab in the sidebar to open a ready-made hub layout.", true)

	-- Farm recipe.
	local Farm = Parent:AddSubTab("Farm", "sprout")
	local FarmBox = Farm:AddLeftGroupbox("Auto farm", "sprout")
	FarmBox:AddToggle("Recipe_FarmEnabled", { Text = "Enable auto farm", Default = false })
	FarmBox:AddDropdown("Recipe_FarmTarget", {
		Text = "Target",
		Values = { "Nearest mob", "Boss", "Ore" },
		Default = "Nearest mob",
	})
	FarmBox:AddSlider("Recipe_FarmRange", {
		Text = "Range",
		Min = 10,
		Max = 500,
		Default = 120,
		Suffix = " studs",
		Rounding = 0,
	})
	FarmBox:AddToggle("Recipe_FarmAutoSell", { Text = "Auto sell when full", Default = true })

	-- Combat recipe. Tab:SetBadge tags the sidebar entry.
	local Combat = Parent:AddSubTab("Combat", "swords")
	if Combat.SetBadge then
		Combat:SetBadge("PVP")
	end
	local CombatBox = Combat:AddLeftGroupbox("Aim assist", "swords")
	CombatBox:AddToggle("Recipe_CombatEnabled", { Text = "Enable aim assist", Default = false })
	CombatBox:AddSlider("Recipe_CombatSmoothing", {
		Text = "Smoothing",
		Min = 0,
		Max = 100,
		Default = 35,
		Rounding = 0,
	})
	CombatBox:AddSegmented("Recipe_CombatBone", {
		Text = "Target bone",
		Values = { "Head", "Torso", "Random" },
		Default = "Head",
	})
	-- KeyPicker attaches to a control, so hang it off a label.
	CombatBox:AddLabel("Hold to aim"):AddKeyPicker("Recipe_CombatKey", {
		Text = "Hold to aim",
		Default = "E",
		Mode = "Hold",
	})

	-- Visuals recipe.
	local Visuals = Parent:AddSubTab("Visuals", "eye")
	local VisualsBox = Visuals:AddLeftGroupbox("ESP", "eye")
	VisualsBox:AddToggle("Recipe_VisualBoxes", { Text = "Boxes", Default = true })
	VisualsBox:AddToggle("Recipe_VisualNames", { Text = "Names", Default = true })
	VisualsBox:AddToggle("Recipe_VisualTracers", { Text = "Tracers", Default = false })
	-- ColorPicker attaches to a control, so hang it off a label.
	VisualsBox:AddLabel("ESP colour"):AddColorPicker("Recipe_VisualColor", {
		Title = "ESP colour",
		Default = Color3.fromRGB(80, 200, 255),
		Transparency = 0,
	})

	-- Settings recipe.
	local SettingsRecipe = Parent:AddSubTab("Settings", "settings")
	local SettingsBox = SettingsRecipe:AddLeftGroupbox("Preferences", "settings")
	SettingsBox:AddToggle("Recipe_SettingNotify", { Text = "Show notifications", Default = true })
	SettingsBox:AddSlider("Recipe_SettingUiScale", {
		Text = "UI scale",
		Min = 80,
		Max = 130,
		Default = 100,
		Suffix = "%",
		Rounding = 0,
	})
	SettingsBox:AddInput("Recipe_SettingConfigName", {
		Text = "Config name",
		Placeholder = "default",
		Finished = true,
	})
	SettingsBox:AddButton({
		Text = "Save",
		Func = function()
			Notify("Settings", "Recipe settings saved.", 3)
		end,
	})
end)
if not RecipesOk then
	warn("[MonHub Example] Recipes tab skipped: " .. tostring(RecipesError))
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
	DemoTabs = DemoTabs,
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
