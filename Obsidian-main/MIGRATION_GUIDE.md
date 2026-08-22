# Переход с Obsidian на MonHub UI

Актуальная полная документация находится в [GUIDE.md](GUIDE.md). Этот файл посвящён именно переносу существующего проекта с Obsidian.

Этот документ описывает безопасный перенос существующего интерфейса с оригинального Obsidian на MonHub UI без переписывания всей логики. Legacy API сохранён: `CreateWindow`, `AddTab`, groupboxes, controls, `ThemeManager`, `SaveManager`, `Library.Options` и `Library.Toggles` продолжают работать.

MonHub добавляет Graphite-тему, Gotham, адаптивный sidebar, улучшенные slider и checkbox, плавные анимации, click sound, draggable Watermark с viewport clamp, R6 ESP preview, оптимизированный search и декларативный API.

## Полезные ссылки

- [Репозиторий MonHub UI](https://github.com/SoftRatatui/Obsidian-main)
- [Library.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Library.lua)
- [Raw Library.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua)
- [Полный Example.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Example.lua)
- [Raw Example.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Example.lua)
- [QuickStart.luau](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/QuickStart.luau)
- [ThemeManager.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/ThemeManager.lua)
- [SaveManager.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/SaveManager.lua)
- [VisualPreview.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/VisualPreview.lua)
- [Raw VisualPreview.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua)
- [Library.d.luau с актуальными типами](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Library.d.luau)
- [История изменений](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/CHANGELOG.md)
- [Оригинальный Obsidian](https://github.com/deividcomsono/Obsidian)
- [Документация legacy API](https://docs.mspaint.cc/obsidian)
- [Каталог Lucide icons](https://lucide.dev/icons/)
- [Лицензия MIT](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/LICENSE)

## Короткий маршрут миграции

Для большинства проектов достаточно выполнить пять действий:

1. Сохранить резервную копию рабочего скрипта и папки configs.
2. Заменить URL оригинального `Library.lua` на MonHub raw URL.
3. Оставить существующие IDs controls без изменений.
4. Подключить новые версии `ThemeManager.lua` и `SaveManager.lua` из того же репозитория.
5. Запустить smoke test и проверить callbacks, configs, keybinds, mobile layout и unload.

## Шаг 1. Замените loader

Старый loader обычно выглядит так:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"
))()
```

Замените его на MonHub:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua"
))()
```

Используйте `raw.githubusercontent.com`, а не ссылку вида `github.com/.../blob/...`. Blob-страница возвращает HTML, из-за чего Luau сообщает `Expected ident` на первой строке.

## Шаг 2. Оставьте legacy API

Не нужно сразу переходить на декларативный API. Существующий код можно сохранить:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua"
))()

local Window = Library:CreateWindow({
    Title = "My Hub",
    Footer = "Ready",
    Center = true,
    AutoShow = true,
    Resizable = true,
    GlobalSearch = true,
    EnableSidebarResize = true,
    Font = Enum.Font.Gotham,
    CornerRadius = 4,
    Size = Library.IsMobile and UDim2.fromOffset(520, 480) or UDim2.fromOffset(720, 680),
})

local MainTab = Window:AddTab("Main", "house")
local GeneralGroup = MainTab:AddLeftGroupbox("General", "settings-2")

GeneralGroup:AddToggle("Enabled", {
    Text = "Enabled",
    Default = true,
    Callback = function(Value)
        print("Enabled:", Value)
    end,
})
```

## Совместимость API

| Оригинальный Obsidian | MonHub UI | Действие |
|---|---|---|
| `Library:CreateWindow` | Поддерживается | Оставить |
| `Window:AddTab` | Поддерживается | Оставить |
| `Window:AddKeyTab` | Поддерживается | Оставить |
| `Tab:AddLeftGroupbox` | Поддерживается | Оставить |
| `Tab:AddRightGroupbox` | Поддерживается | Оставить |
| `AddToggle` | Поддерживается | Оставить |
| `AddCheckbox` | Поддерживается | Оставить |
| `AddInput` | Поддерживается | Оставить |
| `AddSlider` | Поддерживается | Оставить |
| `AddDropdown` | Поддерживается | Оставить |
| `AddButton` | Поддерживается | Оставить |
| `AddLabel` и `AddDivider` | Поддерживаются | Оставить |
| `AddColorPicker` | Поддерживается | Оставить |
| `AddKeyPicker` | Поддерживается | Оставить |
| `Library.Options` | Поддерживается | Не менять IDs |
| `Library.Toggles` | Поддерживается | Не менять IDs |
| `ThemeManager` | Поддерживается | Обновить файл |
| `SaveManager` | Поддерживается | Обновить файл |
| `Library:SetWatermark` | Поддерживается | Можно использовать |
| `Library:SetWatermarkVisibility` | Поддерживается | Можно использовать |
| `Library:SetWatermarkSide` | Поддерживается | `"Left"` или `"Right"` |
| `Library:SetWatermarkDraggable` | Поддерживается | Включает или отключает drag |

Изменился внешний вид controls, но их основные методы сохранены. `SetValue` больше не вызывает callback повторно, если значение не изменилось: это убирает лишние зависимости, tweens и вычисления.

## Настройка окна

Рекомендуемый набор параметров:

```luau
local Window = Library:CreateWindow({
    Title = "MonHub",
    Footer = "Beta",
    NotifySide = "Right",
    Center = true,
    AutoShow = true,
    Resizable = true,
    GlobalSearch = true,
    EnableSidebarResize = true,
    EnableCompacting = true,
    ShowCustomCursor = true,
    Font = Enum.Font.Gotham,
    CornerRadius = 4,
    TabTransitionTime = 0.18,
    TabSwipeOffset = 10,
    TabSwipeFrom = "bottom",
    Size = Library.IsMobile and UDim2.fromOffset(520, 480) or UDim2.fromOffset(720, 680),
    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
    },
})
```

Основные параметры:

| Параметр | Назначение |
|---|---|
| `Title` | Заголовок окна |
| `Footer` | Текст нижней панели |
| `Size` | Размер desktop/mobile |
| `Center` | Центрирование при создании |
| `Resizable` | Изменение размера |
| `GlobalSearch` | Поиск по controls |
| `EnableSidebarResize` | Перетаскивание ширины sidebar |
| `EnableCompacting` | Compact sidebar |
| `CornerRadius` | Радиус от 0 до 20 |
| `Font` | `Enum.Font` или `Font` |
| `TabTransitionTime` | Длительность tab transition |
| `TabSwipeOffset` | Дистанция появления tab content |
| `TabSwipeFrom` | `left`, `right`, `top`, `bottom` |

После изменения viewport или нестандартного размера можно вызвать:

```luau
Window:FitToViewport()
```

## Tabs и groupboxes

```luau
local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Settings = Window:AddTab("UI Settings", "settings-2"),
}

local MainLeft = Tabs.Main:AddLeftGroupbox("Player", "user")
local MainRight = Tabs.Main:AddRightGroupbox("World", "globe")

MainLeft:SetOrder(0)
MainRight:SetOrder(0)
```

Используйте `SetOrder`, если ThemeManager, SaveManager или динамические groupboxes должны находиться в предсказуемом порядке.

## Перенос controls

### Toggle и Checkbox

```luau
local FeatureToggle = MainLeft:AddToggle("FeatureEnabled", {
    Text = "Feature enabled",
    Default = false,
    Tooltip = "Enables the feature",
    Callback = function(Value)
        print(Value)
    end,
})

MainLeft:AddCheckbox("SafeMode", {
    Text = "Safe mode",
    Default = true,
    Callback = function(Value)
        print(Value)
    end,
})
```

Checkbox остаётся отдельным квадратным контролом. `AddToggle` по умолчанию использует компактный мягкий switch с анимированным thumb и сохраняет прежний boolean API.

### Input

```luau
MainLeft:AddInput("ProfileName", {
    Text = "Profile name",
    Default = "Default",
    Placeholder = "Enter a profile name",
    Finished = true,
    ClearTextOnFocus = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

### Slider

```luau
MainLeft:AddSlider("PowerLevel", {
    Text = "Power level",
    Default = 65,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    AllowRightClickInput = true,
    Callback = function(Value)
        print(Value)
    end,
})
```

Slider API не изменился. Новый slider использует отдельные label/value, тонкий track, thumb, mouse drag, touch drag и right-click numeric input.

### Dropdown

```luau
MainRight:AddDropdown("Quality", {
    Text = "Quality",
    Values = { "Low", "Balanced", "High" },
    Default = "Balanced",
    AllowNull = false,
    Callback = function(Value)
        print(Value)
    end,
})

MainRight:AddDropdown("Modules", {
    Text = "Enabled modules",
    Values = { "Visuals", "Utility", "Movement" },
    Default = { "Visuals", "Utility" },
    Multi = true,
})

MainRight:AddDropdown("Command", {
    Text = "Search command",
    Values = { "Alpha", "Bravo", "Charlie", "Delta" },
    Default = "Alpha",
    Searchable = true,
})
```

Большие dropdown lists виртуализируются. Старые arrays, dictionaries, multi-select, player/team dropdowns поддерживаются.

### Button, Label и Divider

```luau
MainLeft:AddLabel("Status: ready", true)
MainLeft:AddDivider()

MainLeft:AddButton({
    Text = "Run action",
    DoubleClick = false,
    Variant = "Primary",
    Func = function()
        print("Action executed")
    end,
})
```

Короткая форма button также поддерживается:

```luau
MainLeft:AddButton("Run action", function()
    print("Action executed")
end)
```

Доступны варианты `Default`, `Primary`, `Warning`, `Danger` и `Ghost`. У `Warning` и `Danger` есть отдельные иконки по умолчанию; `Icon = "triangle-alert"` или `Icon = "octagon-x"` заменяет иконку, а `Icon = false` отключает её. `Library:SetButtonVariantIcon("Danger", "trash-2")` задаёт общий icon для semantic danger-кнопок. Старый `Risky = true` сохраняет совместимость и использует `Danger`, если `Variant` не задан. `Secondary`, `Caution` и `Destructive` остаются алиасами для `Default`, `Warning` и `Danger`.

Toggle также принимает `Variant = "Warning"` или `Variant = "Danger"`. В активном состоянии меняются только track и outline, поэтому строки с key picker не сдвигаются и остаются ровными. При включении `Danger` toggle появляется короткий dialog с `Cancel` и `Continue`; выключение остаётся мгновенным, чтобы функцию можно было быстро остановить. `ConfirmDanger = false` отключает это подтверждение, а `ConfirmTitle` и `ConfirmDescription` меняют его текст. Для compatibility `Caution` и `Destructive` работают как алиасы, а `Risky = true` без явного `Variant` становится `Danger`.

У окна есть mouse-first compact launcher: кнопка `−` в верхней панели сворачивает UI, а центральная draggable-панель с названием скрипта возвращает его. При скрытии через keybind launcher не появляется: UI возвращается тем же биндом и не перекрывает игру. Настройки `ShowCompactLauncher`, `CompactLauncherIcon`, `CompactLauncherSize`, `CompactLauncherWidth`, `CompactLauncherTitle`, `CompactLauncherPosition` и `CompactLauncherDraggable` передаются в `CreateWindow`.

## ColorPicker и KeyPicker addons

```luau
FeatureToggle:AddColorPicker("FeatureColor", {
    Title = "Feature color",
    Default = Color3.fromRGB(121, 126, 139),
    Transparency = 0,
    Resizable = true,
    Callback = function(Color)
        print(Color)
    end,
})

FeatureToggle:AddKeyPicker("FeatureKeybind", {
    Text = "Feature keybind",
    Default = "H",
    Mode = "Toggle",
    SyncToggleState = true,
    Callback = function(State)
        print(State)
    end,
})
```

Для feature keybind доступны `Toggle` и `Hold`. `Press` остаётся режимом action-bind для label/button и не попадает в state-панель keybinds.

Панель keybinds теперь автоматически скрывает строки без назначенной клавиши (`None` или некорректный bind) и не показывает пустое окно. Для её плавного отображения используйте публичный метод:

```luau
Library:SetKeybindMenuVisible(true)
```

Если позднее назначить первую клавишу, панель появится сама, пока эта настройка включена.

## Доступ к значениям

Не меняйте IDs при переносе configs.

```luau
local Options = Library.Options
local Toggles = Library.Toggles

print(Toggles.FeatureEnabled.Value)
print(Options.PowerLevel.Value)
print(Options.Quality.Value)

Toggles.FeatureEnabled:SetValue(true)
Options.PowerLevel:SetValue(80)
Options.Quality:SetValue("High")
```

`Toggles` содержит toggle/checkbox. `Options` содержит input, slider, dropdown, key picker, color picker и другие option controls.

## Graphite-тема

Graphite используется по умолчанию:

```luau
Library:SetTheme("Graphite")
```

Верхняя панель имеет отдельный цвет `TopBarColor`. Он доступен в ThemeManager как `Top bar color`:

```luau
Library:SetTheme({
    MainColor = Color3.fromRGB(33, 36, 43),
    TopBarColor = Color3.fromRGB(39, 42, 50),
})
```

Старые темы без `TopBarColor` продолжают работать: верхняя панель автоматически наследует `MainColor`.

Старая чёрно-фиолетовая тема сохранена:

```luau
Library:SetTheme("BlackPurple")
```

Классическая тема:

```luau
Library:SetTheme("Classic")
```

Собственная тема:

```luau
Library:SetTheme({
    BackgroundColor = Color3.fromRGB(22, 24, 29),
    MainColor = Color3.fromRGB(33, 36, 43),
    AccentColor = Color3.fromRGB(133, 141, 160),
    OutlineColor = Color3.fromRGB(65, 69, 80),
    FontColor = Color3.fromRGB(239, 241, 246),
    WhiteColor = Color3.fromRGB(248, 249, 252),
    Font = Font.fromEnum(Enum.Font.Gotham),
    CornerRadius = 4,
    IsLight = false,
})
```

## Click sound

MonHub использует один общий audio object для всех `GuiButton`:

```luau
Library:SetClickSound(92679954573730, 0.3)
```

Отключение:

```luau
Library:SetClickSound(false)
```

Если звук не воспроизводится, проверьте доступность asset для текущего experience и ограничения Roblox audio permissions.

## Watermark, FPS и ping

Базовый API:

```luau
Library:SetWatermark("My Hub  |  Ready")
Library:SetWatermarkVisibility(true)
Library:SetWatermarkSide("Left")
Library:SetWatermarkDraggable(true)
```

Watermark по умолчанию находится слева сверху. Его можно перетащить мышью или touch, либо явно установить через `SetWatermarkSide("Left")` и `SetWatermarkSide("Right")`. Даже после drag, изменения текста и смены размера экрана он остаётся внутри viewport.

Готовая реализация настроек `Watermark`, `Show FPS` и `Show ping` находится в [Example.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Example.lua). Она обновляет текст раз в 0.5 секунды, считает FPS лёгким `RenderStepped` counter и безопасно читает `Data Ping` через `Stats`.

## Интерактивный R6 Viewport

```luau
local PreviewGroup = Tabs.Visuals:AddLeftGroupbox("Character preview", "user-round")

PreviewGroup:AddViewport("CharacterViewport", {
    Object = CharacterModel,
    Clone = true,
    AutoFocus = true,
    Interactive = true,
    Height = 260,
})
```

Управление:

- ЛКМ или ПКМ: вращение.
- Mouse wheel: zoom.
- Touch drag: вращение.
- Pinch: zoom.

Zoom ограничен относительно размера модели. `Object` должен быть `BasePart` или `Model`.

Рабочий R6 builder без внешней модели находится в полном [Example.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Example.lua).

## ESP preview addon

`addons/VisualPreview.lua` предназначен для вкладки с ESP-настройками. Он клонирует реального персонажа из `Target` в отдельную фиксированную панель рядом с окном: внешность, rig и аксессуары остаются настоящими, а оригинальный character не изменяется. Если `Target` не задан, используется `Players.LocalPlayer`. Панель скрывается вместе с UI, не изменяет layout вкладки и показывает только элементы, включённые в ESP controls.

Загружайте addon из того же commit, что и `Library.lua`:

```luau
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua"
))()
local Players = game:GetService("Players")

local Preview = VisualPreview.Create(Library, VisualsTab, {
    Name = "ESP preview",
    Window = Window,
    Target = Players.LocalPlayer,
    Width = 300,
    Height = 420,
    Enabled = false,
    Side = "Auto",
    Alignment = "Center",
    Gap = 12,
})
```

`Window` обязателен для legacy API: передавайте результат `Library:CreateWindow`. `VisualsTab` должен быть обычным tab, созданным через `Window:AddTab`.

Свяжите preview с теми же callbacks, которые меняют настоящий ESP:

```luau
local function SyncPreview()
    Preview:SetEnabled(Config.ESPEnabled == true)
    Preview:SetBoxVisible(Config.ESPBoxes == true)
    Preview:SetNameVisible(Config.ESPNames == true)
    Preview:SetTeamVisible(Config.ESPTeamText == true)
    Preview:SetWeaponVisible(Config.ESPWeapons == true)
    Preview:SetDistanceVisible(Config.ESPDistance == true)
    Preview:SetHealthVisible(Config.ESPHealth == true)
    Preview:SetTracerVisible(Config.TracersEnabled == true)
    Preview:SetColor(Config.ESPGradient and Config.ESPGradientStart or Config.BoxColor)
    Preview:SetGradientEnabled(Config.ESPGradient == true)
    Preview:SetGradientColor(Config.ESPGradientEnd)
    Preview:SetChams(
        Config.ChamsEnabled == true,
        Config.ChamsFillColor,
        Config.ChamsOutlineColor,
        Config.ChamsFillTrans,
        Config.ChamsOutlineTrans
    )
end
```

`Renderer` необязателен: передавайте его только если ваш собственный скрипт предоставляет функцию, которая строит те же объекты, что и live ESP. Без него addon сам клонирует реального персонажа и строит preview. `Box Scale` и `Dynamic Boxes` используют тот же FOV/depth calculation, что и live renderer. `Preview:SetTarget(PlayerOrModel)` переключает preview на другого реального персонажа и автоматически обновляет clone после `CharacterAdded`, если передан `Player`. `SetPosition("Auto" | "Right" | "Left", "Center" | "Top" | "Bottom")` и `SetPanelGap(number)` отвечают только за размещение панели. Верхняя строка preview показывает реальные name/team, нижняя — текущий tool и реальную distance до камеры, а R6-only chams использует fill, outline и transparency из тех же controls.

Перетаскивайте character левой кнопкой мыши или touch-drag, чтобы вращать модель; mouse wheel меняет zoom. Для собственных controls доступны `Preview:Rotate(deltaX, deltaY)`, `Preview:SetZoom(value)` и `Preview:ResetView()`.

## Image, Video и UIPassthrough

```luau
local MediaGroup = Tabs.Visuals:AddRightGroupbox("Media", "image")

MediaGroup:AddImage("PreviewImage", {
    Image = "sparkles",
    Color = Color3.fromRGB(184, 189, 201),
    ScaleType = Enum.ScaleType.Fit,
    Height = 82,
})

MediaGroup:AddVideo("PreviewVideo", {
    Video = "rbxassetid://5608324215",
    Looped = true,
    Playing = false,
    Volume = 0,
    Height = 175,
})
```

`AddUIPassthrough` принимает готовый `GuiBase2d` и помещает его внутрь groupbox.

## ThemeManager

Загружайте addon из того же commit/repository, что и Library:

```luau
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ThemeManager.lua"
))()

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MonHub")
local ThemeGroup = ThemeManager:ApplyToTab(Tabs.Settings)
ThemeGroup:SetOrder(0)
```

Новая версия корректно определяет Gotham и не сбрасывает font dropdown на Code.

Опции ThemeManager теперь имеют префикс `ThemeManager_`, например `ThemeManager_BackgroundColor`. Это исключает конфликты с ID ваших элементов.

ThemeManager использует versioned default marker `default-v5.txt`. Устаревшие palette names и theme data больше не применяются автоматически, поэтому не могут вернуть старый font, отдельные цвета или предыдущую палитру. Выберите тему и сохраните её как default, если хотите заменить Graphite при следующем запуске.

## SaveManager

```luau
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/SaveManager.lua"
))()

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MonHub")
SaveManager:SetSubFolder(tostring(game.PlaceId))
local ConfigGroup = SaveManager:BuildConfigSection(Tabs.Settings)
ConfigGroup:SetOrder(-100)
SaveManager:LoadAutoloadConfig()
```

Правила переноса configs:

1. Сохраняйте прежние IDs controls.
2. Чтобы использовать старую папку configs, оставьте прежнее значение `SetFolder`.
3. Чтобы начать с чистой конфигурации, используйте новую папку `MonHub`.
4. Не вызывайте `LoadAutoloadConfig` до создания всех controls.
5. ThemeManager подключайте до загрузки autoload config.
6. Menu KeyPicker сохраняется вместе с конфигом по умолчанию. Добавляйте его в `SetIgnoreIndexes()` только если bind должен быть общим для всех configs.

## UI Settings

Рекомендуемый порядок:

```text
Left column
1. Interface
2. Themes

Right column
1. Configuration
```

Используйте `Groupbox:SetOrder`:

```luau
local InterfaceGroup = Tabs.Settings:AddLeftGroupbox("Interface", "panel-left")
InterfaceGroup:SetOrder(-100)

local ThemeGroup = ThemeManager:ApplyToTab(Tabs.Settings)
ThemeGroup:SetOrder(0)

local ConfigGroup = SaveManager:BuildConfigSection(Tabs.Settings)
ConfigGroup:SetOrder(-100)
```

## Mobile и desktop

MonHub автоматически compact-ит sidebar на touch devices. При узкой рабочей области контентные колонки перестраиваются вертикально: сначала левая, затем правая. Это сохраняет ширину controls и не сжимает slider, dropdown или input до нечитаемого размера.

```luau
local WindowSize = Library.IsMobile
    and UDim2.fromOffset(520, 460)
    or UDim2.fromOffset(760, 660)
```

Responsive layout включён по умолчанию. Его порог можно настроить под конкретный интерфейс:

```luau
local Window = Library:CreateWindow({
    ResponsiveLayout = true,
    SingleColumnWidth = 540,
    HideSearchAtWidth = 210,
})
```

`SingleColumnWidth` — рабочая ширина контента, при которой две колонки становятся вертикальными. `HideSearchAtWidth` — крайний порог: если места почти нет, search временно скрывается вместо наложения на заголовок. Используйте `Window:SetResponsiveLayoutEnabled(false)`, только если ваш интерфейс гарантированно рассчитан на desktop.

Рекомендации:

- Не уменьшайте desktop window ниже `480x360` без проверки controls.
- Используйте короткие tab names.
- Для длинного текста включайте wrapping в labels.
- Проверяйте обе колонки при DPI `75%`, `100%`, `125%`, `150%`.
- Проверяйте viewport в landscape mobile mode.
- После ручного изменения размеров вызывайте `Window:FitToViewport()`.
- В `Example.lua` настройка находится в `UI Settings → Responsive layout`.

## Анимации

Все основные transitions включены по умолчанию. Они завершаются после tween и не создают постоянную нагрузку.

```luau
Window:SetAnimations({
    ToggleWindow = true,
    TabSwitch = true,
    Groupbox = true,
    Dropdown = true,
    KeyPicker = true,
}, 0.18, 10, "bottom")
```

Для мгновенного UI отключите конкретную animation, а не все transitions сразу. Повторный hover или повторная установка того же состояния не создаёт новый tween: библиотека переиспользует активную цель анимации.

Для пользовательских controls, которые меняют несколько значений в одном callback, используйте `Library:QueueDependencyUpdate()`. Библиотека выполнит одну общую проверку зависимостей в конце текущего task cycle.

## Notifications

Legacy форма:

```luau
Library:Notify({
    Title = "Saved",
    Description = "Configuration saved successfully.",
    Time = 4,
    Icon = "check",
})
```

Notification sound:

```luau
Library:Notify({
    Title = "Ready",
    Description = "The interface is ready.",
    Time = 3,
    SoundId = 92679954573730,
    Volume = 0.3,
})
```

## Dependency controls

```luau
local AdvancedToggle = MainRight:AddToggle("AdvancedMode", {
    Text = "Advanced mode",
    Default = false,
})

local DependencyBox = MainRight:AddDependencyBox()
DependencyBox:AddSlider("AdvancedValue", {
    Text = "Advanced value",
    Default = 25,
    Min = 0,
    Max = 50,
})
DependencyBox:SetupDependencies({ { AdvancedToggle, true } })
```

## Unload и cleanup

```luau
Library:OnUnload(function()
    print("Interface unloaded")
end)

Library:Unload()
```

MonHub отключает зарегистрированные signals, удаляет UI, draggable elements, active animations, options и cached measurements. Собственные connections регистрируйте через `Library:GiveSignal` или отключайте в `OnUnload`.

## Декларативный API

Переход на декларативный API необязателен. Выполняйте его после успешной legacy migration.

```luau
local App = Library:Create({
    Title = "My Interface",
    Footer = "Ready",
    Theme = "Graphite",
    Tabs = {
        {
            Name = "Main",
            Icon = "house",
            Sections = {
                {
                    Name = "General",
                    Side = "Left",
                    Controls = {
                        {
                            Type = "Toggle",
                            Id = "enabled",
                            Text = "Enabled",
                            Default = true,
                            OnChanged = function(Value)
                                print(Value)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "power",
                            Text = "Power",
                            Min = 0,
                            Max = 100,
                            Default = 50,
                        },
                    },
                },
            },
        },
    },
})

App:Get("power"):SetValue(75)
App:Toggle(true)
```

Иерархия:

```text
App
└── Tabs / Pages
    └── Sections / Groups
        └── Controls / Elements
```

`Id` нужен только для элементов, к которым обращается код. `App:Get(Id)` возвращает созданный control.

## Установка через Wally или Studio

`wally.toml` в текущем repository сохраняет upstream package metadata. Установка `deividcomsono/obsidian` из публичного Wally registry может вернуть оригинальный Obsidian, а не эту MonHub-сборку.

Для точного поведения MonHub используйте один из вариантов:

1. Raw loader для executor environment.
2. Vendor copy текущих `Library.lua`, `Library.d.luau` и `addons` в собственный проект.
3. Собственный Wally package или Git submodule, зафиксированный на commit MonHub repository.

Не смешивайте `Library.lua` MonHub с addons другой версии.

## Частые ошибки

### `Expected ident` на строке 1

Причина: loader получил HTML, страницу ошибки или страницу private repository.

Проверка:

- Используется raw URL.
- Repository и branch доступны.
- Путь содержит `Obsidian-main/Library.lua`.
- Ответ GitHub не пустой.
- Executor поддерживает `game:HttpGet` и `loadstring`.

### UI запускается, но выглядит как старый Obsidian

Причина: загружен upstream URL, Wally upstream package или старый cached file.

Решение: проверьте URL и перезапустите session.

### Font Face становится Code

Обновите `ThemeManager.lua`. Текущая версия определяет активный Gotham font. Старый сохранённый theme также может явно содержать Code.

### Config не загружается

Проверьте:

- Все controls созданы до `LoadAutoloadConfig`.
- IDs не изменены.
- `SetFolder` и `SetSubFolder` совпадают со старым проектом.
- Executor поддерживает file APIs.

### Click sound не работает

Проверьте Roblox audio permissions и доступность asset `92679954573730` для текущего experience.

### Watermark показывает `0 ms`

`Stats.Network.ServerStatsItem["Data Ping"]` может быть недоступен сразу после подключения. Подождите следующий update interval.

### UI выходит за экран

Используйте responsive size и вызовите:

```luau
Window:FitToViewport()
```

### Viewport вращается, но модель не видна

Проверьте `Object`, `Clone`, `PrimaryPart`, bounding box и `AutoFocus`. Для `Model` желательно назначить `PrimaryPart`.

## Финальный checklist

- [ ] Raw URL заменён на MonHub.
- [ ] Library и addons взяты из одной версии.
- [ ] Старые control IDs сохранены.
- [ ] Graphite применяется по умолчанию.
- [ ] Gotham не заменяется на Code.
- [ ] Window помещается в desktop viewport.
- [ ] Sidebar compact работает на mobile.
- [ ] Toggle и checkbox callbacks работают.
- [ ] Slider работает мышью и touch.
- [ ] Dropdown single/multi values сохраняются.
- [ ] KeyPicker и ColorPicker работают.
- [ ] ThemeManager создаётся до SaveManager autoload.
- [ ] Старые configs загружаются либо осознанно перенесены в новую папку.
- [ ] Click sound доступен.
- [ ] Watermark, FPS и ping переключаются.
- [ ] Search работает без задержек.
- [ ] Unload отключает UI и custom connections.
- [ ] Скрипт проверен на desktop и mobile.

## Рекомендуемый порядок реального переноса

1. Перенесите loader и запустите окно без addons.
2. Проверьте tabs и controls.
3. Проверьте `Library.Options` и `Library.Toggles`.
4. Подключите ThemeManager.
5. Подключите SaveManager без autoload.
6. Создайте test config и загрузите его.
7. Включите autoload.
8. Добавьте Watermark и click sound.
9. Проверьте desktop, mobile, DPI и resizing.
10. Только после этого переходите на декларативный API.

Этот порядок локализует ошибки и позволяет откатить каждый этап отдельно.
