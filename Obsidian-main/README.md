# MonHub

Библиотека интерфейса для Roblox Luau: контролы, темы, конфиги, галереи, отдельные
окна и необязательные аддоны. Полный API и настройки описаны в [GUIDE.md](GUIDE.md).
История изменений: [UPDATE_LOG.md](UPDATE_LOG.md) и старые заметки в
[UPDATE_LOG.txt](UPDATE_LOG.txt).

> Номер версии сейчас спорный: `Library.lua` содержит `ReleaseVersion =
> "0.0.1-release-3"`, а changelog в `GUIDE.md` и владелец называют другие значения.
> Точности ради смотрите раздел про версии в начале [UPDATE_LOG.md](UPDATE_LOG.md);
> одинаковый номер релиза не гарантирует одинаковый набор исправлений. Обновляйте
> `Library.lua`, `Library.d.luau` и используемые аддоны вместе и полностью
> перезапускайте скрипт после обновления.

## Что это

- Окно с вкладками, боковой навигацией, сворачиваемыми под-вкладками (`Tab:AddSubTab`)
  и группами.
- Контролы: тумблеры, слайдеры, дропдауны с чипами, поля ввода с маской, префиксом,
  суффиксом, многострочным режимом и валидацией, кнопки с состоянием
  (`Idle`/`Loading`/`Success`/`Error`), сегменты, бейджи, шаги, скелетоны, карточки
  настроек, прогресс-бары и другое. Опции `VisibleWhen` и `EnabledWhen` управляют
  видимостью и доступностью.
- Мобильные устройства: пресеты плотности (`Comfortable`, `Compact`, `Touch`),
  реальный свайп между вкладками, перехват ввода, чтобы тап в меню не срабатывал в
  игре, вибрация, учёт выреза экрана, автоскрытие скроллбаров и обрезка текста с учётом
  UTF-8.
- Реактивность и сборка: `Library:State`, `Library:Observe`, пулы объектов,
  виртуальные списки, бюджет сборки, история изменений с `Undo`/`Redo`, палитра команд
  и декларативный сборщик `Library:Create` / `Library:Mount`.
- Темы, конфиги с автолоадом и постранично устойчивой загрузкой, галереи изображений и
  текстур.

Подробности и сигнатуры смотрите в [GUIDE.md](GUIDE.md).

## Аддоны

Все аддоны опциональны и подключаются отдельно.

- `SaveManager` - конфиги, автолоад, резервные копии и восстановление.
- `ThemeManager` - галерея тем, предпросмотр, проверка контраста, палитры доступности.
- `AssetCatalog` - каталог карточек с выбором и пагинацией.
- `DashboardWindow` - встроенные и отдельные панели-дашборды.
- `ImageGallery`, `TextureGallery` - виртуализированные галереи с ленивой загрузкой.
- `ImagePreview`, `VisualPreview` - предпросмотр изображений и визуальных эффектов.
- `CollectionModel` - модель коллекции без привязки к UI.
- `CharacterTrail`, `DrawingESPPreview`, `FixedR6Preview`, `TracerPreview` - визуальные
  превью-аддоны.
- `MetricsPanel` - панель метрик с графиками и скользящими выборками (новый).
- `Onboarding` - пошаговый онбординг, встроенный или отдельный (новый).

## Загрузка

```luau
local BASE = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local CACHE = "0.0.1-release-3-configs-2-" .. tostring(os.time())
local Library = loadstring(game:HttpGet(BASE .. "Library.lua?monhub=" .. CACHE, false))()
local SaveManager = loadstring(game:HttpGet(BASE .. "addons/SaveManager.lua?monhub=" .. CACHE, false))()

local Window = Library:CreateWindow({
    Title = "My interface",
    Center = true,
    AutoShow = true,
})
local Main = Window:AddTab("Main", "house")
local Controls = Main:AddLeftGroupbox("General")

Controls:AddToggle("FeatureEnabled", { Text = "Enabled", Default = false })
Controls:AddSlider("FeatureStrength", { Text = "Strength", Default = 50, Min = 0, Max = 100, Rounding = 0 })

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyInterface")
SaveManager:SetSubFolder(tostring(game.PlaceId))
SaveManager:BuildConfigSection(Window:AddTab("Settings", "settings"))
SaveManager:LoadAutoloadConfig()
```

Сначала создайте все контролы и зарегистрируйте адаптеры аддонов, затем постройте блок
конфигурации и вызовите автолоад последним. Используйте постоянные ID контролов и не
меняйте папку между сохранением и загрузкой. Строка `CACHE` включает `os.time()`, чтобы
всегда получать свежий файл; если нужен кеш по версии, читайте раздел про версии и
устаревший кеш в [UPDATE_LOG.md](UPDATE_LOG.md).

Готовые примеры: [Example.lua](Example.lua) и [QuickStart.luau](QuickStart.luau).

## Тесты

```powershell
./tests/check.ps1 -Compiler luau-compile -Runtime luau
```

Локальные тесты покрывают конфиги, раскладку, рантайм, аддоны и типографику. Отображение,
загрузку ассетов и касания дополнительно проверяйте на реальном устройстве Roblox.
