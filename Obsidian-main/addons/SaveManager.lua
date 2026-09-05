local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local HttpService: HttpService = cloneref(game:GetService("HttpService"))

local NativeIsFolder, NativeIsFile, NativeListFiles = isfolder, isfile, listfiles
local FileSystemAvailable = type(NativeIsFolder) == "function" and type(NativeIsFile) == "function" and type(NativeListFiles) == "function" and type(makefolder) == "function" and type(readfile) == "function" and type(writefile) == "function" and type(delfile) == "function"

local function isfolder(Folder)
    local Success, Result = pcall(NativeIsFolder, Folder)
    return Success and Result == true
end

local function isfile(File)
    local Success, Result = pcall(NativeIsFile, File)
    return Success and Result == true
end

local function listfiles(Folder)
    local Success, Result = pcall(NativeListFiles, Folder)
    return if Success and typeof(Result) == "table" then Result else {}
end


local SaveManager = {
    ReleaseVersion = "0.0.1-release-13",
    Library = nil,
    FileSystemAvailable = FileSystemAvailable,

    Folder = "ObsidianLibSettings",
    SubFolder = "",

    Ignore = {},
    LoadingOrder = {},
    UseLoadingOrder = false,
    Adapters = {},

    AutoloadConfig = nil
}

local ConfigSchemaVersion = 2

local ThemeOptionPrefix = "ThemeManager_"

local function IsThemeManagerOption(OptionId: any): boolean
    return typeof(OptionId) == "string" and string.sub(OptionId, 1, #ThemeOptionPrefix) == ThemeOptionPrefix
end

function SaveManager:SetLibrary(Library)
    assert(typeof(Library) == "table", "SaveManager requires a library table")
    SaveManager.Library = Library
    return SaveManager
end


local SpecialValueParser = {
    UDim2 = {
        Encode = function(Value: UDim2)
            return {
                X = { Scale = Value.X.Scale, Offset = Value.X.Offset },
                Y = { Scale = Value.Y.Scale, Offset = Value.Y.Offset }
            }
        end,

        Decode = function(Data: any)
            local DataType = typeof(Data)
            if DataType == "table" then
                local X = Data.X
                local Y = Data.Y
                if typeof(X) ~= "table" or typeof(Y) ~= "table" then
                    return nil
                end

                local XScale = X.Scale
                local XOffset = X.Offset
                local YScale = Y.Scale
                local YOffset = Y.Offset
                if typeof(XScale) ~= "number" or typeof(XOffset) ~= "number" or typeof(YScale) ~= "number" or typeof(YOffset) ~= "number" then
                    return nil
                end

                return UDim2.new(XScale, XOffset, YScale, YOffset)
            elseif DataType == "UDim2" then
                return Data
            end

            return nil
        end
    }
}

local ElementParser = {}; do
    local function CreateParser(
        ElementType: string, 
        LibaryIndex: string, 
        
        Save: (string, any, ...any) -> any, 
        Load: (any?, any) -> any,
        CustomElementFetcher: boolean?
    )
        ElementParser[ElementType] = { 
            Save = function(Index: string, Element: any, ...)
                local Data = Save(Index, Element, ...)
                Data.type = ElementType
                Data.idx = Index

                return Data
            end, 

            Load = function(Index: string?, Data: any)
                if CustomElementFetcher == true then
                    return Load(nil, Data)
                end

                local Elements = SaveManager.Library and SaveManager.Library[LibaryIndex]
                local Element = Elements and Elements[Index]
                return Load(Element, Data)
            end
        }
    end

    CreateParser(
        "Toggle", "Toggles",
        function(Index: string, Toggle: any)
            return { value = Toggle.Value }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
                Element:RunChanged()
                return
            end
            
            Element:SetValue(Data.value)
        end
    )

    CreateParser(
        "Slider", "Options",
        function(Index: string, Slider: any)
            return { value = tostring(Slider.Value) }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
                Element:RunChanged()
                return
            end

            Element:SetValue(Data.value)
        end
    )

    CreateParser(
        "Dropdown", "Options",
        function(Index: string, Dropdown: any)
            return { value = Dropdown.Value, multi = Dropdown.Multi }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
                Element:RunChanged()
                return
            end
            
            Element:SetValue(Data.value)
        end
    )

    CreateParser(
        "ColorPicker", "Options",
        function(Index: string, ColorPicker: any)
            return { value = ColorPicker.Value:ToHex(), transparency = ColorPicker.Transparency }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            
            Element:SetValueRGB(Color3.fromHex(Data.value), Data.transparency)
        end
    )

    CreateParser(
        "KeyPicker", "Options",
        function(Index: string, KeyPicker: any)
            return { mode = KeyPicker.Mode, key = KeyPicker.Value, modifiers = KeyPicker.Modifiers, toggled = KeyPicker.Toggled }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            
            Element:SetValue({ Data.key, Data.mode, Data.modifiers })
            if Data.mode == "Toggle" and Data.toggled ~= nil then
                Element.Toggled = Data.toggled
                Element:Update()
            end
        end
    )

    CreateParser(
        "Input", "Options",
        function(Index: string, Input: any)
            return { text = Input.Value }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if typeof(Data.text) ~= "string" then return end

            if Element.Value == Data.text then
                Element:RunChanged()
                return
            end

            Element:SetValue(Data.text)
        end
    )

    CreateParser(
        "Groupbox", "Tabs",
        function(Index: string, Groupbox: any, TabIndex: string)
            return { collapsed = Groupbox.Collapsed, tabIdx = TabIndex }
        end,
        function(_, Data: any)
            local TabIndex, Index = Data.tabIdx, Data.idx
            if typeof(TabIndex) ~= "string" or typeof(Index) ~= "string" then return end

            local Tabs = SaveManager.Library and SaveManager.Library.Tabs
            local Tab = Tabs and Tabs[TabIndex]
            if not Tab then return end

            local Groupbox = Tab.Groupboxes[Index]
            if not Groupbox or Groupbox.Collapsed == Data.collapsed then return end

            Groupbox:SetCollapsed(Data.collapsed == true)
        end,
        true
    )

    CreateParser(
        "Custom", "Adapters",
        function(Index: string, Adapter: any)
            return { value = Adapter.Save() }
        end,
        function(_, Data: any)
            local Adapter = SaveManager.Adapters[Data.idx]
            if not Adapter then return end
            if Adapter.Validate then
                local Valid, ErrorMessage = Adapter.Validate(Data.value)
                if Valid == false then
                    error(ErrorMessage or "custom value was rejected")
                end
            end
            Adapter.Load(Data.value)
        end,
        true
    )
end


local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

local function IsStringEmpty(String: string): boolean
    return if typeof(String) == "string" then Trim(String) == "" else true
end

local function IsValidLeafName(Name: any): boolean
    if typeof(Name) ~= "string" or Name ~= Trim(Name) or Name == "" or #Name > 96 then
        return false
    end

    return Name ~= "." and Name ~= ".." and not Name:find('[\\/%z<>:"|%?%*]')
end

local function IsValidConfigName(Name: any): boolean
    return IsValidLeafName(Name) and string.lower(Name) ~= "autoload"
end

local function IsValidFolderPath(Name: string): boolean
    if typeof(Name) ~= "string" then
        return false
    end
    local Normalized = Trim(Name):gsub("\\", "/"):gsub("/+", "/"):gsub("^/", ""):gsub("/$", "")
    if Normalized == "" or Normalized:find('[<>:"|%?%*%z]') then
        return false
    end
    for Segment in string.gmatch(Normalized, "[^/]+") do
        if Segment == "." or Segment == ".." or not IsValidLeafName(Segment) then
            return false
        end
    end
    return true
end

local function NormalizeFolderPath(Name: string): string
    return Trim(Name):gsub("\\", "/"):gsub("/+", "/"):gsub("^/", ""):gsub("/$", "")
end


local function SplitPath(Path: string): {string}
    local Result = {}
    local Current = ""

    for Part in string.gmatch(Path, "[^/]+") do
        Current = if Current == "" then Part else (Current .. "/" .. Part)
        table.insert(Result, Current)
    end

    return Result
end

local function GetFolderPath(): false | string
    if IsStringEmpty(SaveManager.Folder) then
        return false
    end

    return string.format("%s/settings", SaveManager.Folder)
end

local function GetSubFolderPath(): false | string
    if IsStringEmpty(SaveManager.Folder) or IsStringEmpty(SaveManager.SubFolder) then
        return false
    end

    return string.format("%s/settings/%s", SaveManager.Folder, SaveManager.SubFolder)
end

local function GetCurrentSettingsPath(): false | string
    local SubFolderPath = GetSubFolderPath()
    return if SubFolderPath == false then GetFolderPath() else SubFolderPath
end


local function GetConfigPath(ConfigName: string): false | string
    if not IsValidConfigName(ConfigName) then
        return false
    end

    local CurrentSettingsPath = GetCurrentSettingsPath()
    return if CurrentSettingsPath == false then false else string.format("%s/%s.json", CurrentSettingsPath, ConfigName)
end

local function DoesConfigExist(ConfigName: string): boolean
    local ConfigPath = GetConfigPath(ConfigName)
    return if ConfigPath == false then false else isfile(ConfigPath)
end

local function GetAutoloadPath(): false | string
    local CurrentSettingsPath = GetCurrentSettingsPath()
    return if CurrentSettingsPath == false then false else string.format("%s/autoload.txt", CurrentSettingsPath)
end

local function WriteVerified(Path: string, Content: string): (boolean, string?)
    local TemporaryPath = Path .. ".tmp"
    local HadPrevious = isfile(Path)
    local PreviousContent = nil
    if HadPrevious then
        local ReadOld, OldContent = pcall(readfile, Path)
        if ReadOld and typeof(OldContent) == "string" then
            PreviousContent = OldContent
        end
    end

    local WroteTemporary, TemporaryError = pcall(writefile, TemporaryPath, Content)
    if not WroteTemporary then
        return false, "Failed to write temporary file: " .. tostring(TemporaryError)
    end

    local ReadTemporary, TemporaryContent = pcall(readfile, TemporaryPath)
    if not ReadTemporary or TemporaryContent ~= Content then
        pcall(delfile, TemporaryPath)
        return false, "Temporary file verification failed"
    end

    local WroteFinal, FinalError = pcall(writefile, Path, Content)
    if not WroteFinal then
        pcall(delfile, TemporaryPath)
        return false, "Failed to write file: " .. tostring(FinalError)
    end

    local ReadFinal, FinalContent = pcall(readfile, Path)
    if not ReadFinal or FinalContent ~= Content then
        if PreviousContent ~= nil then
            pcall(writefile, Path, PreviousContent)
        elseif not HadPrevious and isfile(Path) then
            pcall(delfile, Path)
        end
        pcall(delfile, TemporaryPath)
        return false, "File verification failed"
    end

    pcall(delfile, TemporaryPath)
    return true
end


function SaveManager:SetLoadingOrder(Enabled: boolean, Order: {string}?)
    SaveManager.UseLoadingOrder = Enabled == true
    SaveManager.LoadingOrder = typeof(Order) == "table" and Order or SaveManager.LoadingOrder
    return SaveManager
end

function SaveManager:SetIgnoreIndexes(Indexes: {string}?, Replace: boolean?)
    assert(typeof(Indexes) == "table", "Expected table, got " .. typeof(Indexes))

    if Replace == true then
        table.clear(SaveManager.Ignore)
    end

    for _, Index in Indexes do
        if typeof(Index) == "string" or typeof(Index) == "number" then
            SaveManager.Ignore[Index] = true
        end
    end

    return SaveManager
end

function SaveManager:RegisterAdapter(Index: string, Adapter: any)
    assert(typeof(Index) == "string" and Index ~= "", "Adapter index must be a non-empty string")
    assert(typeof(Adapter) == "table", "Adapter must be a table")
    assert(typeof(Adapter.Save) == "function", "Adapter.Save must be a function")
    assert(typeof(Adapter.Load) == "function", "Adapter.Load must be a function")
    SaveManager.Adapters[Index] = Adapter
    return SaveManager
end

function SaveManager:UnregisterAdapter(Index: string)
    SaveManager.Adapters[Index] = nil
    return SaveManager
end

function SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({
        "BackgroundColor", "MainColor", "TopBarColor", "SurfaceColor", "RaisedColor", "ElementColor", "HoverColor", "AccentColor", "AccentSoftColor", "OutlineColor", "FontColor", "MutedFontColor", "ShadowColor", "WarningColor", "DestructiveColor", "FontFace", "BackgroundImage",
        "ThemeManager_BackgroundColor", "ThemeManager_MainColor", "ThemeManager_TopBarColor", "ThemeManager_SurfaceColor", "ThemeManager_RaisedColor", "ThemeManager_ElementColor", "ThemeManager_HoverColor", "ThemeManager_AccentColor", "ThemeManager_AccentSoftColor", "ThemeManager_OutlineColor", "ThemeManager_FontColor", "ThemeManager_MutedFontColor", "ThemeManager_ShadowColor", "ThemeManager_WarningColor", "ThemeManager_DestructiveColor", "ThemeManager_FontFace", "ThemeManager_BackgroundImage",
        "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
        "ThemeManager_Radius_Window", "ThemeManager_Radius_Card", "ThemeManager_Radius_Control", "ThemeManager_Radius_Indicator",
        "ThemeManager_ScrollbarThickness", "ThemeManager_Effect_Shadows", "ThemeManager_Effect_Dividers", "ThemeManager_Effect_NavigationIndicator", "ThemeManager_Effect_AccentScrollbars", "ThemeManager_ReducedMotion"
    })
    return SaveManager
end


function SaveManager:GetPaths(): {string}
    local SubFolderPath = GetSubFolderPath()
    if SubFolderPath == false then
        local FolderPath = GetFolderPath()
        return if FolderPath == false then {} else SplitPath(FolderPath)
    end

    return SplitPath(SubFolderPath)
end

function SaveManager:BuildFolderTree(SkipWhenCreated: boolean?)
    if not SaveManager.FileSystemAvailable then
        return false, "Filesystem API is unavailable"
    end

    local Paths = SaveManager:GetPaths()
    if #Paths == 0 then
        return false, "Invalid folder path"
    end

    if SkipWhenCreated == true then
        if isfolder(Paths[#Paths]) then
            return true
        end
    end

    for _, Path in Paths do
        if isfolder(Path) then continue end

        local Success, ErrorMessage = pcall(makefolder, Path)
        if not Success and not isfolder(Path) then
            return false, "Failed to create folder: " .. tostring(ErrorMessage)
        end
    end

    if not isfolder(Paths[#Paths]) then
        return false, "Failed to create folder"
    end

    return true
end

function SaveManager:CheckFolderTree()
    return SaveManager:BuildFolderTree(true)
end

function SaveManager:CheckSubFolder(CreateFolder: boolean)
    if not SaveManager.FileSystemAvailable then
        return false
    end

    local SubFolderPath = GetSubFolderPath()
    if SubFolderPath == false then
        return false
    end

    local FolderExists = isfolder(SubFolderPath)
    if not CreateFolder then
        return FolderExists
    end

    if FolderExists then
        return true
    end

    local FolderReady = SaveManager:BuildFolderTree()
    return FolderReady == true and isfolder(SubFolderPath)
end

function SaveManager:SetFolder(Folder: string)
    assert(IsValidFolderPath(Folder), "Invalid path provided")

    SaveManager.Folder = NormalizeFolderPath(Folder)
    SaveManager.AutoloadConfig = nil
    SaveManager:BuildFolderTree()
    return SaveManager
end

function SaveManager:SetSubFolder(SubFolder: string)
    if IsStringEmpty(SubFolder) then
        SaveManager.SubFolder = ""
        SaveManager.AutoloadConfig = nil
        SaveManager:BuildFolderTree()
        return SaveManager
    end
    assert(IsValidFolderPath(SubFolder), "Invalid path provided")

    SaveManager.SubFolder = NormalizeFolderPath(SubFolder)
    SaveManager.AutoloadConfig = nil
    SaveManager:BuildFolderTree()
    return SaveManager
end


function SaveManager:RefreshConfigList()
    if not SaveManager.FileSystemAvailable then
        return {}
    end

    local SettingsPath = GetCurrentSettingsPath()
    if SettingsPath == false then
        return {}
    end

    local FolderReady = SaveManager:CheckFolderTree()
    if not FolderReady then
        return {}
    end

    local SuccessList, Files = pcall(listfiles, SettingsPath)
    if not (SuccessList and typeof(Files) == "table") then
        if SaveManager.Library and SaveManager.Library.Notify then
            SaveManager.Library:Notify(string.format("Failed to load config list: %s", tostring(Files)))
        end
        return {}
    end

    local FileNames = {}
    for _, FilePath in Files do
        local Normalized = tostring(FilePath):gsub("\\", "/")
        local FileName = Normalized:match("([^/]+)%.json$")
        if not IsValidConfigName(FileName) then continue end

        table.insert(FileNames, FileName)
    end

    table.sort(FileNames, function(First, Second)
        return string.lower(First) < string.lower(Second)
    end)

    return FileNames
end

function SaveManager:SaveJSON(ConfigName)
    local Library = SaveManager.Library
    if not Library then
        return "", false, "Library is not set"
    end

    local IgnoreIndexes = SaveManager.Ignore
    local CurrentData = {
        schema = ConfigSchemaVersion,
        libraryVersion = tostring(Library.ReleaseVersion or "unknown"),
        timestamp = os.date("%d.%m.%Y %H:%M:%S"),
        name = ConfigName or "",

        objects = {},
        keybindMenu = if Library.KeybindFrame then {
            visible = if Library.KeybindMenuRequested ~= nil then Library.KeybindMenuRequested else Library.KeybindFrame.Visible,
            position = SpecialValueParser.UDim2.Encode(Library.KeybindFrame.Position)
        } else nil
    }

    local function Append(Parser, Index, Value, ...)
        local Success, Data = pcall(Parser.Save, Index, Value, ...)
        if not Success then
            return false, string.format("Failed to save %q: %s", tostring(Index), tostring(Data))
        end
        table.insert(CurrentData.objects, Data)
        return true
    end

    for Index, Toggle in Library.Toggles do
        if not Toggle.Type then continue end
        if IgnoreIndexes[Index] then continue end

        local Parser = ElementParser[Toggle.Type]
        if not Parser then continue end

        local Success, ErrorMessage = Append(Parser, Index, Toggle)
        if not Success then return "", false, ErrorMessage end
    end

    
    for Index, Option in Library.Options do
        if not Option.Type then continue end
        if IgnoreIndexes[Index] then continue end

        local Parser = ElementParser[Option.Type]
        if not Parser then continue end

        local Success, ErrorMessage = Append(Parser, Index, Option)
        if not Success then return "", false, ErrorMessage end
    end

    
    for TabIndex, Tab in Library.Tabs do
        if not Tab.Groupboxes then continue end

        for Index, Groupbox in Tab.Groupboxes do
            if IgnoreIndexes[Index] then continue end

            local Parser = ElementParser.Groupbox
            if not Parser then continue end

            local Success, ErrorMessage = Append(Parser, Index, Groupbox, TabIndex)
            if not Success then return "", false, ErrorMessage end
        end
    end

    for Index, Adapter in SaveManager.Adapters do
        if IgnoreIndexes[Index] then continue end
        local Success, ErrorMessage = Append(ElementParser.Custom, Index, Adapter)
        if not Success then return "", false, ErrorMessage end
    end

    table.sort(CurrentData.objects, function(First, Second)
        local FirstKey = string.format("%s:%s", tostring(First.type), tostring(First.idx))
        local SecondKey = string.format("%s:%s", tostring(Second.type), tostring(Second.idx))
        return FirstKey < SecondKey
    end)

    local SuccessEncode, EncodedData = pcall(HttpService.JSONEncode, HttpService, CurrentData)
    if not SuccessEncode then
        return "", false, "Failed to encode data: " .. tostring(EncodedData)
    end

    return EncodedData, true
end

function SaveManager:Save(ConfigName: string): (boolean, string?)
    if not IsValidConfigName(ConfigName) then
        return false, "Invalid config name provided"
    end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false then
        return false, "Invalid config name provided"
    end

    local FolderReady, FolderError = SaveManager:CheckFolderTree()
    if not FolderReady then
        return false, FolderError or "Failed to prepare config folder"
    end

    local EncodedData, SuccessEncode, EncodeErrorMessage = SaveManager:SaveJSON(ConfigName)
    if not SuccessEncode then
        return false, EncodeErrorMessage
    end

    return WriteVerified(ConfigPath, EncodedData)
end

function SaveManager:LoadJSON(Content: string, SkipRollback: boolean?)
    if not SaveManager.Library then
        return false, "Library is not set"
    end

    if IsStringEmpty(Content) then
        return false, "No JSON provided"
    end

    local SuccessDecode, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if not SuccessDecode or typeof(Decoded) ~= "table" or typeof(Decoded.objects) ~= "table" then
        return false, "Failed to decode config data"
    end

    if Decoded.schema ~= nil and (typeof(Decoded.schema) ~= "number" or Decoded.schema < 1 or Decoded.schema > ConfigSchemaVersion) then
        return false, "Unsupported config schema"
    end

    local function ValidateObject(ObjectIndex: any, Option: any): (boolean, string?)
        if typeof(Option) ~= "table" then
            return false, string.format("object %s: expected table", tostring(ObjectIndex))
        end

        if Option.type == nil then
            return true
        end

        if typeof(Option.type) ~= "string" then
            return false, string.format("object %s: expected string type", tostring(ObjectIndex))
        end

        local Parser = ElementParser[Option.type]
        if not Parser then
            return true
        end

        if typeof(Option.idx) ~= "string" and typeof(Option.idx) ~= "number" then
            return false, string.format("%s object %s: expected string or number index", Option.type, tostring(ObjectIndex))
        end

        if Option.type == "Toggle" then
            if typeof(Option.value) ~= "boolean" then
                return false, string.format("Toggle %q: expected boolean value", tostring(Option.idx))
            end
        elseif Option.type == "Slider" then
            if typeof(Option.value) ~= "string" and typeof(Option.value) ~= "number" then
                return false, string.format("Slider %q: expected string or number value", tostring(Option.idx))
            end
        elseif Option.type == "Dropdown" then
            if Option.multi ~= nil and typeof(Option.multi) ~= "boolean" then
                return false, string.format("Dropdown %q: expected boolean multi value", tostring(Option.idx))
            end
        elseif Option.type == "ColorPicker" then
            local IsColorValid = typeof(Option.value) == "string" and pcall(Color3.fromHex, Option.value)
            if not IsColorValid or Option.transparency ~= nil and typeof(Option.transparency) ~= "number" then
                return false, string.format("ColorPicker %q: invalid color data", tostring(Option.idx))
            end
            Option.transparency = math.clamp(tonumber(Option.transparency) or 0, 0, 1)
        elseif Option.type == "KeyPicker" then
            if Option.key ~= nil and typeof(Option.key) ~= "string" or Option.mode ~= nil and typeof(Option.mode) ~= "string" or Option.modifiers ~= nil and typeof(Option.modifiers) ~= "table" or Option.toggled ~= nil and typeof(Option.toggled) ~= "boolean" then
                return false, string.format("KeyPicker %q: invalid keybind data", tostring(Option.idx))
            end
        elseif Option.type == "Input" then
            if typeof(Option.text) ~= "string" then
                return false, string.format("Input %q: expected string text", tostring(Option.idx))
            end
        elseif Option.type == "Groupbox" then
            if typeof(Option.idx) ~= "string" or typeof(Option.tabIdx) ~= "string" or Option.collapsed ~= nil and typeof(Option.collapsed) ~= "boolean" then
                return false, string.format("Groupbox %q: invalid groupbox data", tostring(Option.idx))
            end
        elseif Option.type == "Custom" then
            local Adapter = SaveManager.Adapters[Option.idx]
            if Adapter and Adapter.Validate then
                local SuccessValidate, Valid, ErrorMessage = pcall(Adapter.Validate, Option.value)
                if not SuccessValidate or Valid == false then
                    return false, string.format("Custom %q: %s", tostring(Option.idx), tostring(if SuccessValidate then ErrorMessage or "invalid value" else Valid))
                end
            end
        end

        return true
    end

    local Objects = {}
    local ObjectKeys = {}
    for ObjectIndex, Option in Decoded.objects do
        local Valid, ValidationError = ValidateObject(ObjectIndex, Option)
        if not Valid then
            return false, "Failed to load config data: " .. tostring(ValidationError)
        end

        if Option.type ~= nil then
            local ObjectKey = string.format("%s:%s", tostring(Option.type), tostring(Option.idx))
            if ObjectKeys[ObjectKey] then
                return false, "Failed to load config data: duplicate object " .. ObjectKey
            end
            ObjectKeys[ObjectKey] = true
            table.insert(Objects, Option)
        end
    end

    local KeybindMenuData = Decoded.keybindMenu
    local KeybindMenuPosition = nil
    if KeybindMenuData ~= nil then
        if typeof(KeybindMenuData) ~= "table" then
            return false, "Failed to load config data: invalid keybind menu data"
        end

        if KeybindMenuData.visible ~= nil and typeof(KeybindMenuData.visible) ~= "boolean" then
            return false, "Failed to load config data: invalid keybind menu visibility"
        end

        if KeybindMenuData.position ~= nil then
            KeybindMenuPosition = SpecialValueParser.UDim2.Decode(KeybindMenuData.position)
            if not KeybindMenuPosition then
                return false, "Failed to load config data: invalid keybind menu position"
            end
        end
    end

    local Library = SaveManager.Library
    local LoadingOrder = SaveManager.LoadingOrder
    local IgnoreIndexes = SaveManager.Ignore
    local LoadErrors = {}
    local LoadReport = { Applied = 0, Skipped = 0, Total = #Objects }
    local RollbackJSON = nil
    if not SkipRollback then
        local Snapshot, SnapshotReady = SaveManager:SaveJSON("rollback")
        if SnapshotReady then
            RollbackJSON = Snapshot
        end
    end

    if SaveManager.UseLoadingOrder == true and typeof(LoadingOrder) == "table" then
        table.sort(Objects, function(a, b)
            local aIndex = table.find(LoadingOrder, a.idx) or table.find(LoadingOrder, a.type) or math.huge
            local bIndex = table.find(LoadingOrder, b.idx) or table.find(LoadingOrder, b.type) or math.huge
            if aIndex == bIndex then
                return string.format("%s:%s", tostring(a.type), tostring(a.idx)) < string.format("%s:%s", tostring(b.type), tostring(b.idx))
            end
            return aIndex < bIndex
        end)
    end

    if Library.KeybindFrame and KeybindMenuData then
        local KeybindFrameData = KeybindMenuData
        local IsVisible = KeybindFrameData.visible == true

        if Library.SetKeybindMenuVisible then
            Library:SetKeybindMenuVisible(IsVisible)
        else
            Library.KeybindFrame.Visible = IsVisible
        end
        Library.KeybindFrame.Position = KeybindMenuPosition or Library.KeybindFrame.Position
        
        local KeybindMenuToggle = Library.Toggles and Library.Toggles.KeybindMenuOpen
        if KeybindMenuToggle then
            KeybindMenuToggle:SetValue(IsVisible)
        end
    end

    local ThemeManager = Library and Library.ThemeManager
    local ThemeLoadStarted = false
    local SkipThemeOptions = false
    if ThemeManager then
        local HasThemeOptions = false
        for _, Option in Objects do
            if typeof(Option) == "table" and IsThemeManagerOption(Option.idx) and not IgnoreIndexes[Option.idx] and ElementParser[Option.type] then
                HasThemeOptions = true
                break
            end
        end

        if HasThemeOptions then
            if typeof(ThemeManager.BeginConfigLoad) == "function" and typeof(ThemeManager.MarkConfigOptionLoaded) == "function" and typeof(ThemeManager.EndConfigLoad) == "function" then
                local SuccessBegin, BeginResult, BeginError = pcall(ThemeManager.BeginConfigLoad, ThemeManager)
                if SuccessBegin and BeginResult ~= false then
                    ThemeLoadStarted = true
                else
                    SkipThemeOptions = true
                    table.insert(LoadErrors, "theme transaction: " .. tostring(if SuccessBegin then BeginError else BeginResult))
                end
            else
                SkipThemeOptions = true
            end
        end
    end

    
    for _ObjectIndex, Option in Objects do
        if not Option.type then continue end
        if IgnoreIndexes[Option.idx] then
            LoadReport.Skipped += 1
            continue
        end
        if SkipThemeOptions and IsThemeManagerOption(Option.idx) then
            LoadReport.Skipped += 1
            continue
        end

        local Parser = ElementParser[Option.type]
        if not Parser then
            LoadReport.Skipped += 1
            continue
        end

        local TargetExists = false
        if Option.type == "Toggle" then
            TargetExists = Library.Toggles and Library.Toggles[Option.idx] ~= nil
        elseif Option.type == "Groupbox" then
            local Tab = Library.Tabs and Library.Tabs[Option.tabIdx]
            TargetExists = Tab and Tab.Groupboxes and Tab.Groupboxes[Option.idx] ~= nil
        elseif Option.type == "Custom" then
            TargetExists = SaveManager.Adapters[Option.idx] ~= nil
        else
            TargetExists = Library.Options and Library.Options[Option.idx] ~= nil
        end
        if not TargetExists then
            LoadReport.Skipped += 1
            continue
        end

        local SuccessLoad, LoadError = pcall(Parser.Load, Option.idx, Option)
        if not SuccessLoad then
            table.insert(LoadErrors, string.format("%s %q: %s", tostring(Option.type), tostring(Option.idx), tostring(LoadError)))
            continue
        end
        LoadReport.Applied += 1

        if ThemeLoadStarted and IsThemeManagerOption(Option.idx) then
            local SuccessMark, MarkError = pcall(ThemeManager.MarkConfigOptionLoaded, ThemeManager, Option.idx)
            if not SuccessMark then
                table.insert(LoadErrors, string.format("theme option %q: %s", tostring(Option.idx), tostring(MarkError)))
            end
        end
    end

    if ThemeLoadStarted then
        local SuccessEnd, EndResult, EndError = pcall(ThemeManager.EndConfigLoad, ThemeManager)
        if not SuccessEnd then
            table.insert(LoadErrors, "theme transaction: " .. tostring(EndResult))
        elseif EndResult == false then
            table.insert(LoadErrors, "theme transaction: " .. tostring(EndError))
        end
    end

    if #LoadErrors > 0 then
        if RollbackJSON then
            local RolledBack, RollbackError = SaveManager:LoadJSON(RollbackJSON, true)
            if not RolledBack then
                table.insert(LoadErrors, "rollback: " .. tostring(RollbackError))
            end
        end
        return false, "Failed to load config data: " .. table.concat(LoadErrors, "; "), LoadReport
    end

    return true, nil, LoadReport
end

function SaveManager:Load(ConfigName: string): (boolean, string?)
    if IsStringEmpty(ConfigName) then
        return false, "No config is selected"
    end

    if not IsValidConfigName(ConfigName) then
        return false, "Invalid config name provided"
    end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false or not isfile(ConfigPath) then
        return false, "Config file does not exist"
    end

    local SuccessRead, Content = pcall(readfile, ConfigPath)
    if not SuccessRead then
        return false, "Failed to read config file"
    end

    return SaveManager:LoadJSON(Content)
end

function SaveManager:Delete(ConfigName: string): (boolean | string?)
    if IsStringEmpty(ConfigName) then
        return false, "No config is selected"
    end

    if not IsValidConfigName(ConfigName) then
        return false, "Invalid config name provided"
    end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false or not isfile(ConfigPath) then
        return false, "Config file does not exist"
    end

    local AutoloadConfig = SaveManager.AutoloadConfig
    if not AutoloadConfig then
        local SavedAutoload, HasAutoload = SaveManager:GetAutoloadConfig()
        if HasAutoload then AutoloadConfig = SavedAutoload end
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, ConfigPath)
    if not SuccessDelete then
        return false, "Failed to delete config file: " .. tostring(ErrorMessage)
    end

    if ConfigName == AutoloadConfig then
        local Cleared, ClearError = SaveManager:DeleteAutoLoadConfig()
        if not Cleared then return false, "Config deleted, but autoload cleanup failed: " .. tostring(ClearError) end
    end

    return true
end


function SaveManager:GetAutoloadConfig(): (string, boolean, string?)
    SaveManager.AutoloadConfig = nil
    local FolderReady, FolderError = SaveManager:CheckFolderTree()
    if not FolderReady then
        return "none", false, FolderError or "Failed to prepare config folder"
    end

    local AutoloadPath = GetAutoloadPath()
    if AutoloadPath == false then
        return "none", false, "Invalid path provided"
    end

    if not isfile(AutoloadPath) then
        return "none", false, "Autoload config is not set"
    end

    local SuccessRead, AutoloadConfigName = pcall(readfile, AutoloadPath)
    if not (SuccessRead and typeof(AutoloadConfigName) == "string") then
        return "none", false, AutoloadConfigName
    end

    AutoloadConfigName = Trim(AutoloadConfigName)
    if not IsValidConfigName(AutoloadConfigName) then
        return "none", false, "Invalid autoload config name"
    end

    local ConfigExists = DoesConfigExist(AutoloadConfigName)
    if not ConfigExists then
        return "none", false, "Config file not found"
    end

    SaveManager.AutoloadConfig = AutoloadConfigName
    return AutoloadConfigName, true
end

function SaveManager:SaveAutoloadConfig(ConfigName: string): (boolean, string?)
    if IsStringEmpty(ConfigName) then
        return false, "No config is selected"
    end

    if not IsValidConfigName(ConfigName) then
        return false, "Invalid config name provided"
    end

    local FolderReady, FolderError = SaveManager:CheckFolderTree()
    if not FolderReady then
        return false, FolderError or "Failed to prepare config folder"
    end

    local AutoloadPath = GetAutoloadPath()
    if AutoloadPath == false then
        return false, "Invalid path provided"
    end

    if not DoesConfigExist(ConfigName) then
        return false, "Config does not exist"
    end

    local SuccessWrite, ErrorMessage = WriteVerified(AutoloadPath, ConfigName)
    if not SuccessWrite then return false, ErrorMessage end

    SaveManager.AutoloadConfig = ConfigName
    return true
end

function SaveManager:LoadAutoloadConfig()
    if not SaveManager.Library then return false, "Library is not set" end
    local function Notify(Message)
        if typeof(SaveManager.Library.Notify) == "function" then SaveManager.Library:Notify(Message) end
    end
    local ConfigName, Success, FetchErrorMessage = SaveManager:GetAutoloadConfig()
    if not Success or FetchErrorMessage then
        if FetchErrorMessage == "Autoload config is not set" then
            return true
        end
        Notify(string.format("Failed to load autoload config: %s", FetchErrorMessage))
        return false, FetchErrorMessage
    end

    local SuccessLoad, LoadErrorMessage = SaveManager:Load(ConfigName)
    if not SuccessLoad then
        Notify(string.format("Failed to load autoload config: %s", LoadErrorMessage))
        return false, LoadErrorMessage
    end

    Notify(string.format("Successfully loaded autoload config %q", ConfigName))
    return true
end

function SaveManager:DeleteAutoLoadConfig(): (boolean, string?)
    local FolderReady, FolderError = SaveManager:CheckFolderTree()
    if not FolderReady then
        return false, FolderError or "Failed to prepare config folder"
    end

    local AutoloadPath = GetAutoloadPath()
    if AutoloadPath == false then
        return false, "Invalid path provided"
    end

    if not isfile(AutoloadPath) then
        SaveManager.AutoloadConfig = nil
        return true
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, AutoloadPath)
    if not SuccessDelete then
        return false, ErrorMessage
    end

    SaveManager.AutoloadConfig = nil
    return true
end


local function ShowDialog(
    Condition: () -> boolean,

    Index: string, 
    Title: string, 
    Description: string,

    DestructiveText: string,
    DestructiveAction: () -> nil
)
    if Condition() == false then
        return DestructiveAction()
    end

    return SaveManager.Library.Window:AddDialog(Index, {
        Title = Title,
        Description = Description,
        AutoDismiss = false,

        FooterButtons = {
            Cancel = {
                Title = "Cancel",
                Variant = "Ghost",
                Order = 1,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                end
            },

            DestructiveAction = {
                Title = DestructiveText,
                Variant = "Default",
                Order = 2,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                    DestructiveAction()
                end
            }
        }
    })
end

function SaveManager:BuildConfigSection(Tab: any, IconName: string)
    assert(SaveManager.Library, "Library is not set, call SaveManager:SetLibrary(Library) first.")
    local ConfigurationBox = Tab:AddRightGroupbox("Configuration", IconName or "folder-cog")
    
    local ConfigNameInput, ConfigList, ConfigJSONInput, AutoloadConfigLabel
    local function RefreshList()
        local Previous = ConfigList.Value
        local Values = SaveManager:RefreshConfigList()
        ConfigList:SetValues(Values)
        ConfigList:SetValue(table.find(Values, Previous) and Previous or nil)
    end

    local function RefreshAutoloadConfigLabel()
        local AutoloadConfigName, _Success, _ErrorMessage = SaveManager:GetAutoloadConfig()

        AutoloadConfigLabel:SetText(string.format("Current autoload config: %s", AutoloadConfigName))
        if ConfigList then RefreshList() end
    end

    
    ConfigurationBox:AddInput("SaveManager_ConfigName", {
        Text = "Config name"
    })

    ConfigurationBox:AddButton("Create config", function()
        local ConfigName = Trim(ConfigNameInput.Value)
        if IsStringEmpty(ConfigName) then
            SaveManager.Library:Notify("Configuration name cannot be empty.")
            return
        end

        if string.lower(ConfigName) == "autoload" then
            SaveManager.Library:Notify("Invalid config name provided.")
            return
        end
        
        ShowDialog(
            function(): boolean
                return DoesConfigExist(ConfigName)
            end,

            "SaveManager_CreateConfig",
            "Config already exists",
            string.format("A config named %q already exists. Overwriting will replace it with your current settings.", ConfigName),

            "Overwrite",
            function()
                local Success, ErrorMessage = SaveManager:Save(ConfigName)
                if not Success then
                    SaveManager.Library:Notify(string.format("Failed to create config %q: %s", ConfigName, ErrorMessage))
                    return
                end

                SaveManager.Library:Notify(string.format("Successfully created config %q", ConfigName))
                RefreshList()
            end
        )
    end)

    ConfigurationBox:AddDivider()

    
    ConfigurationBox:AddDropdown("SaveManager_ConfigList", {
        Text = "Config list",

        Values = SaveManager:RefreshConfigList(),
        AllowNull = true,
        Multi = false,

        FormatDisplayValue = function(Value: any)
            if Value == SaveManager.AutoloadConfig then
                return string.format("%s (autoload)", Value)
            end

            return Value
        end,
        FormatListValue = function(Value: any)
            if Value == SaveManager.AutoloadConfig then
                return string.format("%s (autoload)", Value)
            end

            return Value
        end
    })

    ConfigurationBox:AddButton({
        Text = "Load config",
        DoubleClick = false,

        Func = function()
            local ConfigName = ConfigList.Value
            if IsStringEmpty(ConfigName) then
                SaveManager.Library:Notify("Please select a config first.")
                return
            end

            ShowDialog(
                function(): boolean
                    return true 
                end,

                "SaveManager_LoadConfig",
                "Load config",
                string.format("Are you sure you want to load %q? Your current settings will be overwritten.", ConfigName),

                "Load",
                function()
                    local Success, ErrorMessage = SaveManager:Load(ConfigName)
                    if not Success then
                        SaveManager.Library:Notify(string.format("Failed to load config %q: %s", ConfigName, ErrorMessage))
                        return
                    end

                    SaveManager.Library:Notify(string.format("Successfully loaded config %q", ConfigName))
                end
            )
        end
    })
    
    ConfigurationBox:AddButton({
        Text = "Overwrite config",
        DoubleClick = false,

        Func = function()
            local ConfigName = ConfigList.Value
            if IsStringEmpty(ConfigName) then
                SaveManager.Library:Notify("Please select a config first.")
                return
            end

            ShowDialog(
                function(): boolean
                    return true 
                end,

                "SaveManager_OverwriteConfig",
                "Overwrite config",
                string.format("Are you sure you want to overwrite %q with your current settings? This cannot be undone.", ConfigName),

                "Overwrite",
                function()
                    local Success, ErrorMessage = SaveManager:Save(ConfigName)
                    if not Success then
                        SaveManager.Library:Notify(string.format("Failed to overwrite config %q: %s", ConfigName, ErrorMessage))
                        return
                    end

                    SaveManager.Library:Notify(string.format("Successfully overwrote config %q", ConfigName))
                end
            )
        end
    })

    ConfigurationBox:AddButton({
        Text = "Delete config",
        DoubleClick = false,

        Func = function()
            local ConfigName = ConfigList.Value
            if IsStringEmpty(ConfigName) then
                SaveManager.Library:Notify("Please select a config first.")
                return
            end

            ShowDialog(
                function(): boolean
                    return true 
                end,

                "SaveManager_DeleteConfig",
                "Delete config",
                string.format("Are you sure you want to delete %q? This cannot be undone.", ConfigName),
                
                "Delete",
                function()
                    local Success, ErrorMessage = SaveManager:Delete(ConfigName)
                    if not Success then
                        SaveManager.Library:Notify(string.format("Failed to delete config %q: %s", ConfigName, ErrorMessage))
                        return
                    end

                    SaveManager.Library:Notify(string.format("Successfully deleted config %q", ConfigName))
                    RefreshAutoloadConfigLabel()
                end
            )
        end
    })

    ConfigurationBox:AddButton("Refresh list", RefreshList)

    
    ConfigurationBox:AddButton({
        Text = "Set as autoload",
        DoubleClick = false,

        Func = function()
            local ConfigName = ConfigList.Value
            if IsStringEmpty(ConfigName) then
                SaveManager.Library:Notify("Please select a config first.")
                return
            end

            local Success, ErrorMessage = SaveManager:SaveAutoloadConfig(ConfigName)
            if not Success then
                SaveManager.Library:Notify(string.format("Failed to set autoload config %q: %s", ConfigName, ErrorMessage))
                return
            end

            SaveManager.Library:Notify(string.format("Successfully set autoload config to %q", ConfigName))
            RefreshAutoloadConfigLabel()
        end
    })

    ConfigurationBox:AddButton({
        Text = "Reset autoload",
        DoubleClick = false,

        Func = function()
            ShowDialog(
                function(): boolean
                    return true 
                end,

                "SaveManager_ResetAutoload",
                "Reset autoload config",
                "Are you sure you want to clear the autoload config? No config will be loaded automatically on next launch.",
                
                "Reset",
                function()
                    local Success, ErrorMessage = SaveManager:DeleteAutoLoadConfig()
                    if not Success then
                        SaveManager.Library:Notify(string.format("Failed to reset autoload config: %s", ErrorMessage))
                        return
                    end

                    SaveManager.Library:Notify("Successfully reset autoload config.")
                    RefreshAutoloadConfigLabel()
                end
            )
        end
    })

    AutoloadConfigLabel = ConfigurationBox:AddLabel("Current autoload config: ...", true);

    ConfigurationBox:AddDivider()

    
    ConfigurationBox:AddInput("SaveManager_JSON", {
        Text = "Config JSON"
    })

    ConfigurationBox:AddButton("Import config", function()
        local ConfigJSON = ConfigJSONInput.Value
        if IsStringEmpty(ConfigJSON) then
            SaveManager.Library:Notify("Configuration JSON cannot be empty")
            return
        end

        ShowDialog(
            function(): boolean
                return true 
            end,

            "SaveManager_ImportConfig",
            "Import config",
            "Are you sure you want to import this configuration? Your current settings will be overwritten.",

            "Import",
            function()
                local Success, ErrorMessage = SaveManager:LoadJSON(ConfigJSON)
                if not Success then
                    SaveManager.Library:Notify(string.format("Failed to import config: %s", ErrorMessage))
                    return
                end

                SaveManager.Library:Notify("Successfully imported config")
            end
        )
    end)

    ConfigurationBox:AddButton("Export current config", function()
        local EncodedData, Success, ErrorMessage = SaveManager:SaveJSON()
        if not Success  then
            SaveManager.Library:Notify(ErrorMessage)
            return
        end

        ConfigJSONInput:SetValue(EncodedData)
        if setclipboard then
            setclipboard(EncodedData)
            SaveManager.Library:Notify("Copied config to your clipboard")
        else
            SaveManager.Library:Notify("Config JSON is ready to copy")
        end
    end)

    
    ConfigNameInput, ConfigList, ConfigJSONInput =
        SaveManager.Library.Options.SaveManager_ConfigName, 
        SaveManager.Library.Options.SaveManager_ConfigList,
        SaveManager.Library.Options.SaveManager_JSON;

    
    RefreshAutoloadConfigLabel()
    SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName", "SaveManager_JSON" })

    return ConfigurationBox
end

SaveManager:BuildFolderTree()
return SaveManager
