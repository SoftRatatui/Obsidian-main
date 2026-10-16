# MonHub

Библиотека интерфейса для Roblox Luau: контролы, темы, конфиги, отдельные окна и
необязательные аддоны. Полный API и настройки описаны в [GUIDE.md](GUIDE.md).
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
- Темы, конфиги с автолоадом и постранично устойчивой загрузкой.

Подробности и сигнатуры смотрите в [GUIDE.md](GUIDE.md).

## Аддоны

Все аддоны опциональны и подключаются отдельно.

- `SaveManager` - конфиги, автолоад, резервные копии и восстановление.
- `ThemeManager` - галерея тем, предпросмотр, проверка контраста, палитры доступности.
- `DashboardWindow` - встроенные и отдельные панели-дашборды.
- `CharacterTrail` - след за персонажем с пресетами, текстурами и градиентом.
- `MetricsPanel` - панель метрик с графиками и скользящими выборками (новый).
- `Onboarding` - пошаговый онбординг, встроенный или отдельный (новый).

## Загрузка

### Одна строка, всегда свежая сборка

```luau
local function Get(Url)
    local Ok, Body = pcall(game.HttpGet, game, Url)
    return Ok and Body or nil
end
local Load = Get("https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/dist/Load.lua?t=" .. os.time())
    or Get("https://cdn.jsdelivr.net/gh/SoftRatatui/Obsidian-main@main/Obsidian-main/dist/Load.lua")
local Library = loadstring(Load)()
local ThemeManager = Library.Addons.ThemeManager
local SaveManager = Library.Addons.SaveManager
```

`Load.lua` это тот же загрузчик, только он сразу возвращает библиотеку. Версию он
всегда спрашивает у GitHub с антикешем, поэтому после пуша хаб получает новую
сборку при следующем запуске, а не через 5 минут или 12 часов. Если GitHub закрыт,
строка берёт загрузчик с jsDelivr, а дальше всё идёт через зеркала и кеш.

Старая строка `game:HttpGet(BASE .. "Library.lua?monhub=" .. RELEASE)` грузит
несжатый исходник, а постоянный `?monhub=` CDN кеширует до 5 минут, отсюда «старая
версия» сразу после пуша. Если не хочется менять хаб, достаточно заменить хвост на
`"Library.lua?t=" .. os.time()`.

После каждого пуша запускайте `python tools/purge.py`, чтобы jsDelivr сразу отдавал
новые файлы игрокам, у которых GitHub не открывается.

### Через вставленный загрузчик

Для хабов берите сборку `dist/Library.lua`: в одном файле библиотека, все аддоны и
иконки, сжато darklua. Рядом лежит `dist/version.txt` (номер сборки, несколько
байт). Вставьте в начало хаба блок из `Loader.lua` и загружайте так:

```luau
local Library = MonHubLoad()
local ThemeManager = Library.Addons.ThemeManager
local SaveManager = Library.Addons.SaveManager
```

Порядок работы загрузчика, на сетевую часть всего 5 секунд:

1. Читает `version.txt`. Если версия совпала с сохранённой копией, запускает её,
   больше ничего не качая. Это обычный запуск: по сети идут единицы байт.
2. Иначе качает `Library.lua`. Файл принимается, только если размер совпал с
   `version.txt` и он компилируется, поэтому обрезанный файл или страница блокировки
   не запустятся. Копия сохраняется в `MonHub/cache/`.
3. Не вышло или не успел за 5 секунд: запускает последнюю сохранённую копию.
4. Сохранённой нет: запускает копию, встроенную в сам скрипт.

После отката загрузка продолжается в фоне до двух минут, и копия обновляется к
следующему запуску. Меню при этом не ждёт.

Если сохранённой копии и встроенной нет (первый запуск не встроенного хаба), 5 секунд
не действуют: загрузке даётся до 60 секунд, зеркала стартуют с шагом 3 секунды, чтобы
медленный мобильный интернет не делился между копиями файла, а на экране показывается
уведомление Roblox о первой загрузке и об ошибке: у телефона нет консоли.

Зеркала: GitHub raw, затем jsDelivr (Gcore, Fastly, CDN, Cloudflare). raw.githack
убран: он перенаправляет на тот же GitHub raw, а statically.io не отдаёт файл в
950 КБ. Следующее зеркало стартует параллельно, если предыдущее не ответило за
секунду. Сработавшее зеркало запоминается и в следующий раз пробуется первым, так что
игроку из России с закрытым GitHub задержка нужна только в первый раз. Свои зеркала
добавляются в `MonHubConfig.Extra`.

Библиотека сама при запуске по сети ничего не качает: иконки внутри сборки, шрифт
Inter подгружается в фоне, меню открывается сразу на Gotham и переключается на Inter.

### WindUI

Рядом лежит отдельная библиотека WindUI 1.6.66 (MIT, автор Footages, исходники в
`windui/`) со своим API: `Window:Tab`, `Tab:Section`, `Section:Toggle({ ... })`.
Хабы MonHub на ней не запускаются. Загрузка тем же загрузчиком:

```luau
local WindUI = MonHubLoad("WindUI")
```

Отличия от оригинала: иконки Lucide внутри файла вместо шести наборов, которые
оригинал качает с GitHub при каждом запуске (старт 45 мс вместо 950 мс, и без
ошибки там, где GitHub закрыт), 320 КБ вместо 1.35 МБ, и сборка окна больше не
тормозит квадратично от числа надписей (180 элементов за 0.54 с вместо 1.9 с).

Встроить библиотеку в хаб как последнюю страховку:
`python tools/embed_hub.py hub.lua`. Рядом появится копия хаба, больше на ~950 КБ,
оригинал не меняется.

После правок в исходниках пересоберите и запушьте: `python tools/build.py` (нужен
darklua).

Старый способ ниже по-прежнему работает, но качает несжатые файлы только с GitHub.

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
