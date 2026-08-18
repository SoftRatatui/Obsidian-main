--[[
	Obsidian — full showcase / smoke test

	The example loads the library from:
	https://github.com/SoftRatatui/Obsidian-main

	RightShift opens and closes the window.
	ThemeManager and SaveManager are optional: the UI still starts if an addon
	has not been uploaded to the repository yet or the executor has no file API.
]]

local REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"

local function LoadRemote(Path, Required)
	local Url = REPOSITORY .. Path
	local Downloaded, Source = pcall(game.HttpGet, game, Url)

	if not Downloaded then
		local Message = string.format("Не удалось загрузить %s\n%s", Url, tostring(Source))
		if Required then
			error(Message, 0)
		end

		warn("[Obsidian Example] " .. Message)
		return nil
	end

	local Chunk, CompileError = loadstring(Source)
	if not Chunk then
		local Message = string.format("Ошибка компиляции %s\n%s", Path, tostring(CompileError))
		if Required then
			error(Message, 0)
		end

		warn("[Obsidian Example] " .. Message)
		return nil
	end

	local Executed, Module = pcall(Chunk)
	if not Executed then
		local Message = string.format("Ошибка запуска %s\n%s", Path, tostring(Module))
		if Required then
			error(Message, 0)
		end

		warn("[Obsidian Example] " .. Message)
		return nil
	end

	return Module
end

local Library = LoadRemote("Library.lua", true)
local ThemeManager = LoadRemote("addons/ThemeManager.lua", false)
local SaveManager = LoadRemote("addons/SaveManager.lua", false)

assert(type(Library.Create) == "function", "Для Example.lua нужна новая версия Library.lua с Library:Create().")

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- A small model for the Viewport test. The library clones it before rendering.
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

local PreviewRing = Instance.new("Part")
PreviewRing.Name = "Ring"
PreviewRing.Anchored = true
PreviewRing.CanCollide = false
PreviewRing.Material = Enum.Material.Neon
PreviewRing.Color = Color3.fromRGB(178, 142, 231)
PreviewRing.Shape = Enum.PartType.Cylinder
PreviewRing.Size = Vector3.new(0.25, 4.1, 4.1)
PreviewRing.CFrame = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90))
PreviewRing.Parent = PreviewModel

PreviewModel.PrimaryPart = PreviewCore

-- A custom GuiObject for AddUIPassthrough.
local CustomCard = Instance.new("Frame")
CustomCard.Name = "CustomPassthroughCard"
CustomCard.BackgroundColor3 = Color3.fromRGB(25, 21, 35)
CustomCard.BorderSizePixel = 0
CustomCard.Size = UDim2.fromScale(1, 1)

local CustomCardCorner = Instance.new("UICorner")
CustomCardCorner.CornerRadius = UDim.new(0, 8)
CustomCardCorner.Parent = CustomCard

local CustomCardStroke = Instance.new("UIStroke")
CustomCardStroke.Color = Color3.fromRGB(75, 57, 105)
CustomCardStroke.Transparency = 0.2
CustomCardStroke.Parent = CustomCard

local CustomCardGradient = Instance.new("UIGradient")
CustomCardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 20, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 34, 68)),
})
CustomCardGradient.Rotation = 12
CustomCardGradient.Parent = CustomCard

local CustomCardTitle = Instance.new("TextLabel")
CustomCardTitle.BackgroundTransparency = 1
CustomCardTitle.Position = UDim2.fromOffset(14, 8)
CustomCardTitle.Size = UDim2.new(1, -28, 0, 22)
CustomCardTitle.Font = Enum.Font.GothamMedium
CustomCardTitle.Text = "Custom UI passthrough"
CustomCardTitle.TextColor3 = Color3.fromRGB(238, 232, 248)
CustomCardTitle.TextSize = 15
CustomCardTitle.TextXAlignment = Enum.TextXAlignment.Left
CustomCardTitle.Parent = CustomCard

local CustomCardText = Instance.new("TextLabel")
CustomCardText.BackgroundTransparency = 1
CustomCardText.Position = UDim2.fromOffset(14, 31)
CustomCardText.Size = UDim2.new(1, -28, 0, 34)
CustomCardText.Font = Enum.Font.Gotham
CustomCardText.Text = "Любой GuiBase2d можно встроить внутрь groupbox."
CustomCardText.TextColor3 = Color3.fromRGB(178, 170, 193)
CustomCardText.TextSize = 12
CustomCardText.TextWrapped = true
CustomCardText.TextXAlignment = Enum.TextXAlignment.Left
CustomCardText.TextYAlignment = Enum.TextYAlignment.Top
CustomCardText.Parent = CustomCard

local App
local DraggableStatus
local DraggableButton

local function Notify(Title, Description, Duration)
	return Library:Notify({
		Title = Title,
		Description = Description,
		Time = Duration or 4,
	})
end

local function OpenDialog()
	local Dialog = App.Window:AddDialog("ShowcaseDialog", {
		Title = "Проверка диалога",
		Description = "Диалог поддерживает собственные элементы, варианты кнопок и плавное закрытие.",
		Icon = "message-square-more",
		AutoDismiss = false,
		OutsideClickDismiss = true,
		FooterButtons = {
			Cancel = {
				Title = "Отмена",
				Variant = "Secondary",
				Order = 1,
				Callback = function(CurrentDialog)
					CurrentDialog:Dismiss()
				end,
			},
			Confirm = {
				Title = "Подтвердить",
				Variant = "Primary",
				Order = 2,
				Callback = function(CurrentDialog)
					local Text = Options.DialogInput and Options.DialogInput.Value or ""
					Notify("Диалог подтвержден", Text ~= "" and Text or "Поле оставлено пустым")
					CurrentDialog:Dismiss()
				end,
			},
		},
	})

	Dialog:AddInput("DialogInput", {
		Text = "Сообщение",
		Default = "Привет из Obsidian",
		Placeholder = "Введите текст...",
		ClearTextOnFocus = false,
	})
	Dialog:AddToggle("DialogToggle", {
		Text = "Дополнительный параметр",
		Default = true,
	})
	Dialog:Resize()
end

local function RunLoadingTest()
	if Library.ActiveLoading then
		Notify("Loading уже запущен", "Дождитесь завершения текущего теста.")
		return
	end

	task.spawn(function()
		local Steps = {
			{ "Подготовка интерфейса", "Проверяем тему и компоненты" },
			{ "Загрузка настроек", "Читаем демонстрационные значения" },
			{ "Оптимизация", "Обновляем только нужные элементы" },
			{ "Финальная проверка", "Почти готово" },
			{ "Готово", "Все тесты завершены" },
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
			task.wait(0.38)
		end

		task.wait(0.25)
		if not Loading.Destroyed then
			Loading:Continue()
		end
		Notify("Loading завершен", "Окно и прогресс-бар работают корректно.")
	end)
end

App = Library:Create({
	Theme = "BlackPurple",
	Title = "Obsidian",
	Footer = "Full showcase • black purple edition",
	Icon = "gem",
	NotifySide = "Right",
	GlobalSearch = true,
	Resizable = true,
	EnableSidebarResize = true,
	ShowCustomCursor = true,
	Size = Library.IsMobile and UDim2.fromOffset(560, 430) or UDim2.fromOffset(860, 620),
	Animations = {
		ToggleWindow = true,
		TabSwitch = true,
		Groupbox = true,
		Dropdown = true,
		KeyPicker = true,
	},

	Tabs = {
		{
			Id = "controls",
			Name = "Controls",
			Icon = "sliders-horizontal",
			Description = "Базовые элементы и выбор значений",
			Groups = {
				{
					Id = "basic_controls",
					Name = "Основные элементы",
					Icon = "component",
					Side = "Left",
					Elements = {
						{
							Type = "Label",
							Text = "<b>Декларативный API</b> создает весь интерфейс из одной таблицы.",
							DoesWrap = true,
						},
						{ Type = "Divider" },
						{
							Type = "Toggle",
							Id = "master_toggle",
							Text = "Главная функция",
							Default = true,
							Tooltip = "Toggle с ColorPicker и KeyPicker",
							OnChanged = function(Value)
								print("[Obsidian] master_toggle:", Value)
							end,
							Addons = {
								{
									Type = "ColorPicker",
									Id = "accent_picker",
									Title = "Цвет функции",
									Default = Color3.fromRGB(116, 82, 178),
									Transparency = 0,
								},
								{
									Type = "KeyPicker",
									Id = "feature_keybind",
									Text = "Главная функция",
									Default = "G",
									Mode = "Toggle",
									SyncToggleState = true,
								},
							},
						},
						{
							Type = "Checkbox",
							Id = "compact_checkbox",
							Text = "Checkbox-режим",
							Default = false,
						},
						{
							Type = "Input",
							Id = "profile_name",
							Text = "Название профиля",
							Value = "Default profile",
							Placeholder = "Введите название...",
							ClearTextOnFocus = false,
						},
						{
							Type = "Slider",
							Id = "power_slider",
							Text = "Мощность",
							Default = 65,
							Min = 0,
							Max = 100,
							Rounding = 0,
							Suffix = "%",
						},
						{
							Type = "Button",
							Id = "basic_button",
							Text = "Проверить значения",
							OnClick = function()
								Notify(
									"Текущие значения",
									string.format(
										"Toggle: %s\nPower: %s%%\nProfile: %s",
										tostring(Toggles.master_toggle.Value),
										tostring(Options.power_slider.Value),
										tostring(Options.profile_name.Value)
									)
								)
							end,
						},
					},
				},
				{
					Id = "dropdown_controls",
					Name = "Dropdown и списки",
					Icon = "list-filter",
					Side = "Right",
					Elements = {
						{
							Type = "Dropdown",
							Id = "quality_dropdown",
							Text = "Качество",
							Values = { "Low", "Balanced", "High", "Ultra" },
							Default = "Balanced",
						},
						{
							Type = "Dropdown",
							Id = "multi_dropdown",
							Text = "Модули",
							Values = { "Combat", "Visuals", "Movement", "Utility" },
							Default = { "Visuals", "Utility" },
							Multi = true,
							DragSelect = true,
						},
						{
							Type = "Dropdown",
							Id = "searchable_dropdown",
							Text = "Поиск команды",
							Values = {
								"Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta",
								"Eta", "Theta", "Iota", "Kappa", "Lambda", "Omega",
							},
							Default = "Alpha",
							Searchable = true,
							MaxVisibleDropdownItems = 7,
						},
						{
							Type = "Dropdown",
							Id = "player_dropdown",
							Text = "Игрок",
							SpecialType = "Player",
							ExcludeLocalPlayer = false,
						},
						{
							Type = "Dropdown",
							Id = "team_dropdown",
							Text = "Команда",
							SpecialType = "Team",
						},
					},
				},
			},
		},
		{
			Id = "media",
			Name = "Media",
			Icon = "gallery-horizontal-end",
			Description = "Изображения, видео, viewport и собственный UI",
			Groups = {
				{
					Id = "media_left",
					Name = "Image и Viewport",
					Icon = "image",
					Side = "Left",
					Elements = {
						{
							Type = "Image",
							Id = "showcase_image",
							Image = "sparkles",
							Color = Color3.fromRGB(178, 142, 231),
							BackgroundTransparency = 0.15,
							ScaleType = Enum.ScaleType.Fit,
							Height = 125,
						},
						{
							Type = "Viewport",
							Id = "showcase_viewport",
							Object = PreviewModel,
							Clone = true,
							AutoFocus = true,
							Interactive = true,
							Height = 220,
						},
						"Viewport: ПКМ/drag — вращение, колесо — zoom.",
					},
				},
				{
					Id = "media_right",
					Name = "Video и Custom UI",
					Icon = "video",
					Side = "Right",
					Elements = {
						{
							Type = "Video",
							Id = "showcase_video",
							Video = "rbxassetid://5608324215",
							Looped = true,
							Playing = true,
							Volume = 0,
							Height = 175,
						},
						{
							Type = "Toggle",
							Id = "video_playing",
							Text = "Проигрывать видео",
							Default = true,
							OnChanged = function(Value)
								local Video = App and App:Get("showcase_video")
								if Video then
									Video:SetPlaying(Value)
								end
							end,
						},
						{
							Type = "UIPassthrough",
							Id = "custom_ui",
							Instance = CustomCard,
							Height = 78,
						},
					},
				},
			},
		},
		{
			Id = "advanced",
			Name = "Advanced",
			Icon = "wand-sparkles",
			Description = "Системные окна и продвинутые контейнеры",
			Groups = {
				{
					Id = "advanced_actions",
					Name = "Системные действия",
					Icon = "blocks",
					Side = "Left",
					Elements = {
						{
							Type = "Button",
							Text = "Показать notification",
							OnClick = function()
								Notify("Obsidian готов", "Notification поддерживает заголовок, описание и таймер.")
							end,
						},
						{ Type = "Button", Text = "Открыть dialog", OnClick = OpenDialog },
						{ Type = "Button", Text = "Запустить loading", OnClick = RunLoadingTest },
						{
							Type = "Button",
							Text = "Создать draggable label",
							OnClick = function()
								if not DraggableStatus or DraggableStatus.Destroyed then
									DraggableStatus = Library:AddDraggableLabel({
										Text = "Obsidian • draggable",
										Icon = "grip",
									})
								else
									DraggableStatus:SetVisible(true)
								end
							end,
						},
						{
							Type = "Button",
							Text = "Создать draggable button",
							OnClick = function()
								if not DraggableButton or DraggableButton.Destroyed then
									DraggableButton = Library:AddDraggableButton("Quick toggle", function()
										App:Toggle()
									end)
								end
							end,
						},
					},
				},
				{
					Id = "advanced_dependency",
					Name = "Dependencies",
					Icon = "workflow",
					Side = "Right",
					Elements = {
						{
							Type = "Toggle",
							Id = "advanced_mode",
							Text = "Расширенный режим",
							Default = true,
						},
						"Нижние элементы видны только когда режим включен.",
					},
				},
			},
		},
		{
			Id = "settings",
			Name = "UI Settings",
			Icon = "settings-2",
			Description = "Оформление, поведение и конфигурации",
			Groups = {
				{
					Id = "menu_settings",
					Name = "Интерфейс",
					Icon = "panel-left",
					Side = "Left",
					Elements = {
						{
							Type = "Toggle",
							Id = "keybind_menu_open",
							Text = "Показывать Keybind Menu",
							Default = Library.KeybindFrame.Visible,
							OnChanged = function(Value)
								Library.KeybindFrame.Visible = Value
							end,
						},
						{
							Type = "Toggle",
							Id = "custom_cursor",
							Text = "Кастомный курсор",
							Default = Library.ShowCustomCursor,
							OnChanged = function(Value)
								Library.ShowCustomCursor = Value
							end,
						},
						{
							Type = "Dropdown",
							Id = "notification_side",
							Text = "Сторона уведомлений",
							Values = { "Left", "Right" },
							Default = "Right",
							OnChanged = function(Value)
								Library:SetNotifySide(Value)
							end,
						},
						{
							Type = "Dropdown",
							Id = "dpi_scale",
							Text = "DPI scale",
							Values = { "75%", "100%", "125%", "150%" },
							Default = "100%",
							OnChanged = function(Value)
								Library:SetDPIScale(tonumber(Value:gsub("%%", "")))
							end,
						},
						{
							Type = "Slider",
							Id = "corner_radius",
							Text = "Скругление",
							Default = Library.CornerRadius,
							Min = 0,
							Max = 16,
							Rounding = 0,
							OnChanged = function(Value)
								App.Window:SetCornerRadius(Value)
							end,
						},
					},
				},
			},
		},
	},
})

-- DependencyBox uses existing UI elements as conditions.
local DependencyBox = App.Groups.advanced_dependency:AddDependencyBox()
DependencyBox:AddLabel("DependencyBox активен", true)
DependencyBox:AddSlider("dependency_value", {
	Text = "Зависимое значение",
	Default = 25,
	Min = 0,
	Max = 50,
	Rounding = 0,
})
DependencyBox:AddButton("Проверить dependency", function()
	Notify("DependencyBox", "Значение: " .. tostring(Options.dependency_value.Value))
end)
DependencyBox:SetupDependencies({ { Toggles.advanced_mode, true } })

-- Tabbox tests the compact tab container API.
local AdvancedTabbox = App.Tabs.advanced:AddRightTabbox("Tabbox showcase")
local RuntimeTab = AdvancedTabbox:AddTab("Runtime")
RuntimeTab:AddLabel("Компактные вкладки внутри обычной страницы.", true)
RuntimeTab:AddToggle("runtime_enabled", { Text = "Runtime enabled", Default = true })

local ThemeTab = AdvancedTabbox:AddTab("Themes")
ThemeTab:AddButton("Black Purple", function()
	Library:SetTheme("BlackPurple")
end)
ThemeTab:AddButton("Classic", function()
	Library:SetTheme("Classic")
end)

-- Key System uses a special tab and a callback chosen by the script author.
local KeyTab = App.Window:AddKeyTab("Key System")
KeyTab:AddLabel({
	Text = "Тестовый ключ: <b>OBSIDIAN</b>",
	DoesWrap = true,
	Size = 16,
})
KeyTab:AddKeyBox(function(ReceivedKey)
	local Success = ReceivedKey == "OBSIDIAN"
	Notify(
		Success and "Ключ принят" or "Неверный ключ",
		string.format("Получено: %s\nРезультат: %s", tostring(ReceivedKey), tostring(Success)),
		4
	)
end)

-- Settings that are easier to express through the classic chainable API.
local MenuSettings = App.Groups.menu_settings
MenuSettings:AddDivider()
MenuSettings:AddLabel("Клавиша меню"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Открыть/закрыть меню",
})
Library.ToggleKeybind = Options.MenuKeybind

MenuSettings:AddToggle("always_on_top", {
	Text = "Always on top",
	Default = App.Window.AlwaysOnTop,
	Callback = function(Value)
		App.Window:SetAlwaysOnTop(Value)
	end,
})

MenuSettings:AddButton({
	Text = "Выгрузить интерфейс",
	Risky = true,
	DoubleClick = true,
	Func = function()
		Library:Unload()
	end,
})

-- Optional addons. Upload both files to /Obsidian-main/addons/ for these sections.
if ThemeManager then
	local ThemeReady, ThemeError = pcall(function()
		ThemeManager:SetLibrary(Library)
		ThemeManager:SetFolder("ObsidianShowcase")
		ThemeManager:ApplyToTab(App.Tabs.settings)
	end)

	if not ThemeReady then
		warn("[Obsidian Example] ThemeManager отключен: " .. tostring(ThemeError))
	end
end

if SaveManager then
	local SaveReady, SaveError = pcall(function()
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
		SaveManager:SetFolder("ObsidianShowcase")
		SaveManager:SetSubFolder(tostring(game.PlaceId))
		SaveManager:BuildConfigSection(App.Tabs.settings)
		SaveManager:LoadAutoloadConfig()
	end)

	if not SaveReady then
		warn("[Obsidian Example] SaveManager отключен: " .. tostring(SaveError))
	end
end

Library:OnUnload(function()
	if PreviewModel then
		PreviewModel:Destroy()
	end

	print("[Obsidian Example] Интерфейс выгружен, подключения очищены.")
end)

Notify(
	"Obsidian запущен",
	"Используйте поиск сверху или переключайтесь между вкладками. RightShift скрывает интерфейс.",
	6
)

return {
	Library = Library,
	App = App,
	ThemeManager = ThemeManager,
	SaveManager = SaveManager,
}
