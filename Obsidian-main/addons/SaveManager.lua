local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local HttpService: HttpService = cloneref(game:GetService("HttpService"))

local NativeIsFolder, NativeIsFile, NativeListFiles = isfolder, isfile, listfiles
local FileSystemAvailable = type(NativeIsFolder) == "function" and type(NativeIsFile) == "function" and type(makefolder) == "function" and type(readfile) == "function" and type(writefile) == "function"

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
    ReleaseVersion = "0.0.1-release-3",
    Library = nil,
    FileSystemAvailable = FileSystemAvailable,

    Folder = "ObsidianLibSettings",
    SubFolder = "",

    Ignore = {},
    LoadingOrder = {},
    UseLoadingOrder = false,
    Adapters = {},
    Migrations = {},
    SchemaVersion = 2,

    ApplyMode = "Batched",
    BackupCount = 0,

    AutoloadConfig = nil
}

local ConfigSchemaVersion = 2

local function ObjectKey(Option)
    local function Part(Value)
        local Text = tostring(Value)
        return typeof(Value) .. ":" .. #Text .. ":" .. Text
    end
    return Part(Option.type) .. (Option.type == "Groupbox" and Part(Option.tabIdx) or "") .. Part(Option.idx)
end

function SaveManager:Notify(Message, Title, Variant)
    if not SaveManager.Library or type(SaveManager.Library.Notify) ~= "function" then return end
    Message = tostring(Message)
    local IsError = Variant == "Error" or Message:match("^Failed") or Message:match("^Invalid")
    SaveManager.Library:Notify({
        Title = Title or (IsError and "Config error" or "Configuration"),
        Description = Message,
        Variant = Variant or (IsError and "Error" or "Default"),
        Time = IsError and 6 or 3,
    })
end

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

local function DeepEqual(First, Second)
    if type(First) ~= type(Second) then return false end
    if type(First) ~= "table" then return First == Second end
    for Key, Value in First do if not DeepEqual(Value, Second[Key]) then return false end end
    for Key in Second do if First[Key] == nil then return false end end
    return true
end

local KindParser = {
    value = {
        Save = function(Control) return { value = Control.Value } end,
        Load = function(Control, Data)
            if not DeepEqual(Control.Value, Data.value) then Control:SetValue(Data.value) end
        end,
        Validate = function(Option)
            local ValueType = typeof(Option.value)
            if ValueType ~= "string" and ValueType ~= "number" and ValueType ~= "boolean" then
                return false, "expected a scalar value"
            end
            return true
        end,
    },
    boolean = {
        Save = function(Control) return { value = Control.Value == true } end,
        Load = function(Control, Data)
            if Control.Value ~= (Data.value == true) then Control:SetValue(Data.value == true) end
        end,
        Validate = function(Option)
            if typeof(Option.value) ~= "boolean" then return false, "expected a boolean value" end
            return true
        end,
    },
    list = {
        Save = function(Control) return { value = Control.Value } end,
        Load = function(Control, Data)
            if not DeepEqual(Control.Value, Data.value) then Control:SetValue(Data.value) end
        end,
        Validate = function(Option)
            if typeof(Option.value) ~= "table" then return false, "expected a list value" end
            return true
        end,
    },
}

local ElementParser = {}; do
    local function Equal(First, Second)
        if type(First) ~= type(Second) then return false end
        if type(First) ~= "table" then return First == Second end
        for Key, Value in First do if not Equal(Value, Second[Key]) then return false end end
        for Key in Second do if First[Key] == nil then return false end end
        return true
    end

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
                Data.version = Element.ConfigVersion

                return Data
            end, 

            Load = function(Index: string?, Data: any)
                if CustomElementFetcher == true then
                    return Load(nil, Data)
                end

                local Elements = SaveManager.Library and SaveManager.Library[LibaryIndex]
                local Element = Elements and Elements[Index]
                if not Element then return end
                local Current = Save(Index, Element)
                local Same = true
                for Key, Value in Current do
                    local Incoming = Data[Key]
                    if ElementType == "Slider" and Key == "value" then Incoming = tonumber(Incoming) end
                    if ElementType == "Dropdown" and Element.Multi and Key == "value" then
                        local A, B = {}, {}
                        for _, Item in Value do A[Item] = true end
                        for Id, Item in Incoming or {} do
                            if type(Item) == "boolean" then if Item then B[Id] = true end else B[Item] = true end
                        end
                        if not Equal(A, B) then Same = false; break end
                    elseif not Equal(Value, Incoming) then Same = false; break end
                end
                for Key in Data do
                    if Key ~= "type" and Key ~= "idx" and Key ~= "version" and Current[Key] == nil then Same = false end
                end
                if Same then return false end
                local WasDisabled = Element.Disabled
                Element.Disabled = false
                local Success, ErrorMessage = pcall(Load, Element, Data)
                Element.Disabled = WasDisabled
                if not Success then error(ErrorMessage, 0) end
                return true
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
                return
            end
            
            Element:SetValue(Data.value)
        end
    )

    CreateParser(
        "Slider", "Options",
        function(Index: string, Slider: any)
            return { value = Slider.Value }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == tonumber(Data.value) then
                return
            end

            Element:SetValue(Data.value)
        end
    )

    CreateParser("Hidden", "Options", function(_, Element)
        return { value = Element.Value }
    end, function(Element, Data)
        Element:SetValue(Data.value)
    end)

    CreateParser(
        "Dropdown", "Options",
        function(Index: string, Dropdown: any)
            if Dropdown.Multi then
                local Selected = {}
                for Value, Active in Dropdown.Value do
                    if Active then table.insert(Selected, Value) end
                end
                table.sort(Selected, function(a, b)
                    return typeof(a) .. ":" .. tostring(a) < typeof(b) .. ":" .. tostring(b)
                end)
                return { value = Selected, multi = true }
            end
            return { value = Dropdown.Value, multi = Dropdown.Multi }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
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
                return
            end

            Element:SetValue(Data.text)
        end
    )

    CreateParser(
        "Segmented", "Options",
        function(Index: string, Segmented: any)
            return { value = Segmented.Value }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
                return
            end

            Element:SetValue(Data.value)
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
    if not IsValidLeafName(Name) then return false end
    local Lower = string.lower(Name)
    return Lower ~= "autoload" and not Lower:match("%.pending$") and not Lower:match("%.backup$")
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

local function GetBackupFolderPath(): false | string
    local CurrentSettingsPath = GetCurrentSettingsPath()
    return if CurrentSettingsPath == false then false else string.format("%s/backups", CurrentSettingsPath)
end

local function GetRecoveryPath(): false | string
    local CurrentSettingsPath = GetCurrentSettingsPath()
    return if CurrentSettingsPath == false then false else string.format("%s/recovery.json", CurrentSettingsPath)
end

local function WriteVerified(Path: string, Content: string): (boolean, string?)
    local Base, Extension = Path:match("^(.*)%.([^./]+)$")
    Base, Extension = Base or Path, Extension or "txt"
    local TemporaryPath = Base .. ".pending." .. Extension
    local BackupPath = Base .. ".backup." .. Extension
    local HadPrevious = isfile(Path)
    local PreviousContent = nil
    if HadPrevious then
        local ReadOld, OldContent = pcall(readfile, Path)
        if ReadOld and typeof(OldContent) == "string" then
            PreviousContent = OldContent
        else
            return false, "Cannot read the existing file; it has not been overwritten"
        end
    end

    local function RestorePrevious()
        if PreviousContent ~= nil then
            local Restored = pcall(writefile, Path, PreviousContent)
            local ReadBack, RestoredContent = pcall(readfile, Path)
            if not Restored or not ReadBack or RestoredContent ~= PreviousContent then
                return "; could not restore the previous file (backup: " .. BackupPath .. ")"
            end
        elseif isfile(Path) then
            pcall(delfile, Path)
        end
        return ""
    end

    local WroteTemporary, TemporaryError = pcall(writefile, TemporaryPath, Content)
    if not WroteTemporary then
        return false, "Failed to write temporary file " .. TemporaryPath .. ": " .. tostring(TemporaryError)
    end

    local ReadTemporary, TemporaryContent = pcall(readfile, TemporaryPath)
    if not ReadTemporary or TemporaryContent ~= Content then
        pcall(delfile, TemporaryPath)
        return false, "Temporary file verification failed"
    end

    if PreviousContent ~= nil then
        local WroteBackup = pcall(writefile, BackupPath, PreviousContent)
        local ReadBackup, BackupContent = pcall(readfile, BackupPath)
        if not WroteBackup or not ReadBackup or BackupContent ~= PreviousContent then
            pcall(delfile, TemporaryPath)
            return false, "Cannot verify backup; the existing file has not been overwritten"
        end
    end

    local WroteFinal, FinalError = pcall(writefile, Path, Content)
    if not WroteFinal then
        local Recovery = RestorePrevious()
        pcall(delfile, TemporaryPath)
        return false, "Failed to write file: " .. tostring(FinalError) .. Recovery
    end

    local ReadFinal, FinalContent = pcall(readfile, Path)
    if not ReadFinal or FinalContent ~= Content then
        local Recovery = RestorePrevious()
        pcall(delfile, TemporaryPath)
        return false, "File verification failed" .. Recovery
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


function SaveManager:GetConfigs()
    return self:RefreshConfigList()
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

function SaveManager:SetBackupCount(Count: number)
    assert(type(Count) == "number" and Count >= 0 and Count % 1 == 0, "Backup count must be a non-negative integer")
    SaveManager.BackupCount = Count
    return SaveManager
end

local function BackupSlot(Folder: string, ConfigName: string, Index: number): string
    return string.format("%s/%s.%d.json", Folder, ConfigName, Index)
end

function SaveManager:ListBackups(ConfigName: string)
    local Result = {}
    if not IsValidConfigName(ConfigName) then return Result end
    local Folder = GetBackupFolderPath()
    if Folder == false or not isfolder(Folder) then return Result end
    for Index = 1, math.max(SaveManager.BackupCount, 1) do
        local Path = BackupSlot(Folder, ConfigName, Index)
        if isfile(Path) then table.insert(Result, { Index = Index, Path = Path }) end
    end
    return Result
end

function SaveManager:RotateBackup(ConfigName: string): (boolean, string?)
    if SaveManager.BackupCount <= 0 then return true end
    if not IsValidConfigName(ConfigName) then return false, "Invalid config name provided" end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false or not isfile(ConfigPath) then return true end

    local Folder = GetBackupFolderPath()
    if Folder == false then return false, "Invalid path provided" end
    if not isfolder(Folder) then
        local Made = pcall(makefolder, Folder)
        if not Made and not isfolder(Folder) then return false, "Failed to create backup folder" end
    end

    for Index = SaveManager.BackupCount, 2, -1 do
        local Older, Newer = BackupSlot(Folder, ConfigName, Index), BackupSlot(Folder, ConfigName, Index - 1)
        if isfile(Newer) then
            local ReadOK, Content = pcall(readfile, Newer)
            if ReadOK then pcall(writefile, Older, Content) end
        elseif isfile(Older) then
            pcall(delfile, Older)
        end
    end

    local ReadOK, Content = pcall(readfile, ConfigPath)
    if not ReadOK then return false, tostring(Content) end
    local WroteOK, WriteError = pcall(writefile, BackupSlot(Folder, ConfigName, 1), Content)
    if not WroteOK then return false, tostring(WriteError) end
    return true
end

function SaveManager:RestoreBackup(ConfigName: string, Index: number): (boolean, string?)
    if not IsValidConfigName(ConfigName) then return false, "Invalid config name provided" end
    local Folder = GetBackupFolderPath()
    if Folder == false then return false, "Invalid path provided" end

    local Path = BackupSlot(Folder, ConfigName, Index or 1)
    if not isfile(Path) then return false, "Backup does not exist" end

    local ReadOK, Content = pcall(readfile, Path)
    if not ReadOK then return false, tostring(Content) end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false then return false, "Invalid config name provided" end

    local FolderReady, FolderError = SaveManager:CheckFolderTree()
    if not FolderReady then return false, FolderError or "Failed to prepare config folder" end

    return WriteVerified(ConfigPath, Content)
end

function SaveManager:SaveJSON(ConfigName)
    if self.Library and self.Library.BuildLazyTabs then
        local Built, Message = self.Library:BuildLazyTabs()
        if not Built then return "", false, Message end
    end
    local Library = SaveManager.Library
    if not Library then
        return "", false, "Library is not set"
    end

    local IgnoreIndexes = SaveManager.Ignore
    local CurrentData = {
        schema = SaveManager.SchemaVersion,
        libraryVersion = tostring(Library.ReleaseVersion or "unknown"),
        timestamp = os.date("%d.%m.%Y %H:%M:%S"),
        name = ConfigName or "",

        objects = {},
        keybindMenu = if Library.KeybindFrame then {
            visible = if Library.KeybindMenuRequested ~= nil then Library.KeybindMenuRequested else Library.KeybindFrame.Visible,
            position = SpecialValueParser.UDim2.Encode(Library.KeybindFrame.Position)
        } else nil
    }

    local SaveReport = { Skipped = {} }

    local function Append(Parser, Index, Value, ...)
        local Success, Data = pcall(Parser.Save, Index, Value, ...)
        if not Success then
            return false, string.format("Failed to save %q: %s", tostring(Index), tostring(Data))
        end
        table.insert(CurrentData.objects, Data)
        return true
    end

    local function AppendControl(Index, Control, ...)
        local Parser = ElementParser[Control.Type]
        if Parser then
            return Append(Parser, Index, Control, ...)
        end

        local Kind = typeof(Control.SaveKind) == "string" and KindParser[Control.SaveKind] or nil
        if Kind then
            local Success, Data = pcall(Kind.Save, Control)
            if not Success then
                return false, string.format("Failed to save %q: %s", tostring(Index), tostring(Data))
            end
            Data.type = Control.Type
            Data.idx = Index
            Data.kind = Control.SaveKind
            Data.version = Control.ConfigVersion
            table.insert(CurrentData.objects, Data)
            return true
        end

        if Control.Save ~= true then
            return true
        end

        local Reason = string.format("no parser or SaveKind for control type %q", tostring(Control.Type))
        table.insert(CurrentData.objects, { type = Control.Type, idx = Index, unsaveable = true, reason = Reason })
        table.insert(SaveReport.Skipped, { Id = tostring(Index), Reason = Reason })
        return true
    end

    for Index, Toggle in Library.Toggles do
        if not Toggle.Type or Toggle.Save == false or Toggle.Secret or Toggle.NoSave then continue end
        if IgnoreIndexes[Index] then continue end

        local Success, ErrorMessage = AppendControl(Index, Toggle)
        if not Success then return "", false, ErrorMessage end
    end


    for Index, Option in Library.Options do
        if not Option.Type or Option.Save == false or Option.Secret or Option.NoSave then continue end
        if IgnoreIndexes[Index] then continue end

        local Success, ErrorMessage = AppendControl(Index, Option)
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
        return ObjectKey(First) < ObjectKey(Second)
    end)

    SaveManager.LastSaveReport = SaveReport

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

    SaveManager:RotateBackup(ConfigName)

    return WriteVerified(ConfigPath, EncodedData)
end

function SaveManager:SetCallbackMode(Mode)
    assert(Mode == "Sync" or Mode == "Background", "Callback mode must be Sync or Background")
    self.CallbackMode = Mode
    return self
end

function SaveManager:GetSlowCallbacks(Threshold)
    local Result = {}
    local Report = self.LastLoadReport
    if not Report then return Result end
    Threshold = tonumber(Threshold) or 0.05
    for _, Entries in { Report.CallbackTimings or {}, Report.BackgroundCallbacks or {} } do
        for _, Entry in Entries do
            if Entry.Seconds and Entry.Seconds >= Threshold then table.insert(Result, table.clone(Entry)) end
        end
    end
    table.sort(Result, function(A, B) return A.Seconds > B.Seconds end)
    return Result
end

function SaveManager:OnConfigLoaded(Callback)
    assert(type(Callback) == "function", "Expected a callback")
    self.LoadListeners = self.LoadListeners or {}
    local Connection = { Callback = Callback, Connected = true }
    table.insert(self.LoadListeners, Connection)
    return function()
        Connection.Connected = false
        local Index = table.find(self.LoadListeners, Connection)
        if Index then table.remove(self.LoadListeners, Index) end
    end
end

function SaveManager:EmitConfigLoaded(Report)
    Report.ListenerErrors = {}
    for _, Connection in table.clone(self.LoadListeners or {}) do
        if Connection.Connected then
            local Success, Message = pcall(Connection.Callback, Report)
            if not Success then table.insert(Report.ListenerErrors, tostring(Message)) end
        end
    end
end

function SaveManager:SetSchemaVersion(Version)
    assert(type(Version) == "number" and Version >= ConfigSchemaVersion and Version < math.huge and Version % 1 == 0, "Invalid schema version")
    self.SchemaVersion = Version
    return self
end

function SaveManager:RegisterMigration(FromVersion, Callback)
    assert(type(FromVersion) == "number" and FromVersion >= 1 and FromVersion % 1 == 0 and type(Callback) == "function", "Invalid migration")
    self.Migrations[FromVersion] = Callback
    return self
end

function SaveManager:Migrate(Decoded)
    local Version = Decoded.schema or 1
    if type(Version) ~= "number" or Version < 1 or Version % 1 ~= 0 or Version > self.SchemaVersion then return nil, "Unsupported config schema" end
    while Version < self.SchemaVersion do
        local Migration = self.Migrations[Version]
        if Migration then
            local Success, Result = pcall(Migration, Decoded)
            if not Success then return nil, "Migration " .. Version .. ": " .. tostring(Result) end
            if Result ~= nil and type(Result) ~= "table" then return nil, "Migration must return a table or nil" end
            if type(Result) == "table" then Decoded = Result end
        elseif Version >= ConfigSchemaVersion then return nil, "Missing migration from schema " .. Version end
        Version += 1; Decoded.schema = Version
    end
    if type(Decoded.objects) ~= "table" then return nil, "Migration must preserve an objects array" end
    return Decoded
end

function SaveManager:PreviewJSON(Content)
    local Success, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if not Success or type(Decoded) ~= "table" then return nil, "Invalid config JSON" end
    local Migrated, Message = self:Migrate(Decoded)
    if not Migrated then return nil, Message end
    local CurrentJSON, OK, Error = self:SaveJSON()
    if not OK then return nil, Error end
    local Current = HttpService:JSONDecode(CurrentJSON)
    local ById = {}; for _, Option in Current.objects do ById[ObjectKey(Option)] = Option end
    local function Equal(A, B)
        if type(A) ~= type(B) then return false end
        if type(A) ~= "table" then return A == B end
        for Key, Value in A do if not Equal(Value, B[Key]) then return false end end
        for Key in B do if A[Key] == nil then return false end end
        return true
    end
    local Changes = {}
    for _, Option in Migrated.objects do
        if type(Option) ~= "table" then return nil, "Invalid config object" end
        local Existing = ById[ObjectKey(Option)]
        if not Equal(Existing, Option) then table.insert(Changes, { Id = Option.idx, Before = Existing, After = Option, Missing = Existing == nil }) end
    end
    return Changes
end

function SaveManager:PreviewConfig(ConfigName)
    if not IsValidConfigName(ConfigName) then return nil, "Invalid config name provided" end
    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false or not isfile(ConfigPath) then return nil, "Config file does not exist" end
    local ReadOK, Content = pcall(readfile, ConfigPath)
    if not ReadOK then return nil, "Failed to read config file" end
    return self:PreviewJSON(Content)
end

function SaveManager:SaveSubsetJSON(Ids)
    local Content, Success, Message = self:SaveJSON()
    if not Success then return Content, Success, Message end
    local Decoded = HttpService:JSONDecode(Content)
    local Wanted = {}; for _, Id in Ids do Wanted[Id] = true end
    local Objects = {}; for _, Option in Decoded.objects do if Wanted[Option.idx] then table.insert(Objects, Option) end end
    Decoded.objects, Decoded.keybindMenu = Objects, nil
    local Encoded, Result = pcall(HttpService.JSONEncode, HttpService, Decoded)
    return Encoded and Result or "", Encoded, not Encoded and tostring(Result) or nil
end

function SaveManager:Duplicate(From, To)
    if not IsValidConfigName(From) or not IsValidConfigName(To) then return false, "Invalid profile name" end
    local Source, Target = GetConfigPath(From), GetConfigPath(To)
    if not Source or not Target or not isfile(Source) then return false, "Source profile does not exist" end
    if isfile(Target) then return false, "Target profile already exists" end
    local Success, Content = pcall(readfile, Source)
    if not Success then return false, tostring(Content) end
    return WriteVerified(Target, Content)
end

function SaveManager:Rename(From, To)
    local Success, Message = self:Duplicate(From, To)
    if not Success then return false, Message end
    local Autoload = self:GetAutoloadConfig()
    if Autoload == From then
        local Changed, Error = self:SaveAutoloadConfig(To)
        if not Changed then return false, "Profile copied, but autoload was not changed: " .. tostring(Error) end
    end
    local Deleted, Error = self:Delete(From)
    if not Deleted then return false, "Profile copied, but original could not be removed: " .. tostring(Error) end
    if self.ActiveProfile == From then self.ActiveProfile = To end
    return true
end

function SaveManager:WriteRecoverySnapshot(Name)
    local RecoveryPath = GetRecoveryPath()
    if RecoveryPath == false then return false, "Invalid path provided" end
    local Encoded, Success, Message = self:SaveJSON(Name)
    if not Success then return false, Message end
    return pcall(writefile, RecoveryPath, Encoded)
end

function SaveManager:MarkSessionOpen(Name)
    local RecoveryPath = GetRecoveryPath()
    if RecoveryPath == false then return false end
    local MarkerPath = RecoveryPath:gsub("%.json$", ".txt")
    return pcall(writefile, MarkerPath, tostring(Name or ""))
end

function SaveManager:ClearRecovery()
    local RecoveryPath = GetRecoveryPath()
    if RecoveryPath == false then return false end
    local MarkerPath = RecoveryPath:gsub("%.json$", ".txt")
    if isfile(RecoveryPath) then pcall(delfile, RecoveryPath) end
    if isfile(MarkerPath) then pcall(delfile, MarkerPath) end
    return true
end

function SaveManager:CheckRecovery()
    local RecoveryPath = GetRecoveryPath()
    if RecoveryPath == false then return nil end
    local MarkerPath = RecoveryPath:gsub("%.json$", ".txt")
    if not isfile(MarkerPath) or not isfile(RecoveryPath) then return nil end

    local ReadName, Name = pcall(readfile, MarkerPath)
    local ReadContent, Content = pcall(readfile, RecoveryPath)
    if not ReadContent then return nil end

    return { Name = ReadName and Trim(Name) or "", Content = Content }
end

function SaveManager:RestoreRecovery()
    local Recovery = self:CheckRecovery()
    if not Recovery then return false, "No recovery snapshot found" end
    local Success, Message, Report = self:LoadJSON(Recovery.Content, { Source = "Recovery" })
    if Success then self:ClearRecovery() end
    return Success, Message, Report
end

function SaveManager:StartAutosave(Name, Delay)
    assert(IsValidConfigName(Name), "Invalid autosave profile")
    assert(self.Library and self.Library.OnConfigChanged, "SetLibrary before autosave")
    self:StopAutosave()
    self:MarkSessionOpen(Name)
    local Active, Generation, Timer = true, 0, nil
    local Disconnect = self.Library:OnConfigChanged(function(Event)
        if Event.Source == "Config" then return end
        Generation += 1; local Token = Generation
        if Timer and type(task.cancel) == "function" then pcall(task.cancel, Timer) end
        Timer = task.delay(math.max(0.1, tonumber(Delay) or 1), function()
            if not Active or Token ~= Generation or self.Library.Unloaded then return end
            Timer = nil
            local Success, Message = self:Save(Name)
            if not Success then self:Notify(Message, "Autosave failed", "Error") end
            self:WriteRecoverySnapshot(Name)
        end)
    end)
    self.AutosaveStop = function()
        Active = false; Generation += 1; Disconnect()
        if Timer and type(task.cancel) == "function" then pcall(task.cancel, Timer) end
        Timer = nil
    end
    if self.Library.OnUnload then self.Library:OnUnload(function() self:StopAutosave(true) end) end
    return self
end

function SaveManager:StopAutosave(Clean)
    if self.AutosaveStop then self.AutosaveStop(); self.AutosaveStop = nil end
    if Clean then self:ClearRecovery() end
    return self
end

function SaveManager:LoadSummary(Report)
    Report = Report or self.LastLoadReport or {}
    local Loaded = (Report.Applied or 0) + (Report.Unchanged or 0)
    local Extra = {}
    if (Report.Skipped or 0) > 0 then table.insert(Extra, string.format("%d skipped", Report.Skipped)) end
    if (Report.Failed or 0) > 0 then table.insert(Extra, string.format("%d failed", Report.Failed)) end
    if (Report.Invalid or 0) > 0 then table.insert(Extra, string.format("%d invalid", Report.Invalid)) end
    return string.format("Loaded %d of %d settings%s", Loaded, Report.Total or Loaded,
        #Extra > 0 and (", " .. table.concat(Extra, ", ")) or "")
end

function SaveManager:FormatLoadReport(Report)
    Report = Report or self.LastLoadReport or {}
    local Lines = { self:LoadSummary(Report) }
    if (Report.Unchanged or 0) > 0 then
        table.insert(Lines, string.format("%d already current", Report.Unchanged))
    end
    if (Report.Missing or 0) > 0 then
        table.insert(Lines, string.format("%d control(s) not found: %s", Report.Missing, table.concat(Report.MissingIds or {}, ", ")))
    end
    for _, Entry in Report.Entries or {} do
        if Entry.Reason then
            table.insert(Lines, string.format("- %s (%s): %s", tostring(Entry.Id), tostring(Entry.Status), tostring(Entry.Reason)))
        end
    end
    return table.concat(Lines, "\n")
end

function SaveManager:SetApplyMode(Mode)
    assert(Mode == "Batched" or Mode == "Immediate", "Apply mode must be Batched or Immediate")
    self.ApplyMode = Mode
    return self
end

function SaveManager:RunApplyBatch(Batch, Report)
    for _, Job in Batch do
        local Run = Job.Run
        Job.Run = nil
        if Run then Run() end
        if Report then
            if Job.Seconds then
                table.insert(Report.CallbackTimings, { Id = Job.Id, Seconds = Job.Seconds, Success = Job.Status == "Completed" })
            end
            if Job.Status == "Failed" then
                Report.Failed += 1
                table.insert(Report.FailedIds, tostring(Job.Id))
                table.insert(Report.Errors, string.format("%s: %s", tostring(Job.Id), tostring(Job.Error)))
                table.insert(Report.Entries, { Id = tostring(Job.Id), Status = "Failed", Reason = tostring(Job.Error) })
            end
        end
    end
end

function SaveManager:Apply()
    local Pending = self.PendingApply
    if not Pending then return self.LastLoadReport end
    self.PendingApply = nil
    Pending.Finish()
    return Pending.Report
end

function SaveManager:LoadJSON(Content: string, Options: any?)
    Options = typeof(Options) == "table" and Options or {}
    local ApplyMode = Options.ApplyMode or SaveManager.ApplyMode
    local Batched = ApplyMode ~= "Immediate"
    local AutoApply = Options.AutoApply ~= false
    local LoadContext = Options

    if self.Library and self.Library.BuildLazyTabs then
        local Built, Message = self.Library:BuildLazyTabs()
        if not Built then return false, Message end
    end
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

    local Migrated, MigrationError = self:Migrate(Decoded)
    if not Migrated then return false, MigrationError end
    Decoded = Migrated

    local function ValidateObject(ObjectIndex: any, Option: any): (boolean, string?)
        if typeof(Option) ~= "table" then
            return false, string.format("object %s: expected table", tostring(ObjectIndex))
        end

        if Option.version ~= nil and (type(Option.version) ~= "number" or Option.version < 1
            or Option.version >= math.huge or Option.version % 1 ~= 0) then
            return false, "Invalid option version"
        end

        if Option.type == nil then
            return true
        end

        if typeof(Option.type) ~= "string" then
            return false, string.format("object %s: expected string type", tostring(ObjectIndex))
        end

        local Parser = ElementParser[Option.type]
        if not Parser then
            if Option.unsaveable then
                return true
            end

            local Kind = typeof(Option.kind) == "string" and KindParser[Option.kind] or nil
            if Kind then
                if typeof(Option.idx) ~= "string" and typeof(Option.idx) ~= "number" then
                    return false, string.format("%s object %s: expected string or number index", Option.type, tostring(ObjectIndex))
                end
                local ShapeOK, ShapeError = Kind.Validate(Option)
                if not ShapeOK then
                    return false, string.format("%s %q: %s", Option.type, tostring(Option.idx), tostring(ShapeError))
                end
            end
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
            local Value = (typeof(Option.value) == "string" or typeof(Option.value) == "number") and tonumber(Option.value) or nil
            if not Value or Value ~= Value or math.abs(Value) == math.huge then
                return false, string.format("Slider %q: expected a finite numeric value", tostring(Option.idx))
            end
            Option.value = Value
        elseif Option.type == "Dropdown" then
            if Option.multi ~= nil and typeof(Option.multi) ~= "boolean" then
                return false, string.format("Dropdown %q: expected boolean multi value", tostring(Option.idx))
            end
            if Option.multi == true and typeof(Option.value) ~= "table" then
                return false, string.format("Dropdown %q: expected selected values", tostring(Option.idx))
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
        elseif Option.type == "Segmented" then
            local ValueType = typeof(Option.value)
            if ValueType ~= "string" and ValueType ~= "number" and ValueType ~= "boolean" then
                return false, string.format("Segmented %q: expected a scalar value", tostring(Option.idx))
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

    local LoadReport = {
        Total = 0, Applied = 0, Unchanged = 0, Skipped = 0, Failed = 0, Missing = 0, Invalid = 0,
        MissingIds = {}, SkippedIds = {}, FailedIds = {}, InvalidIds = {}, Entries = {}, Errors = {},
        CallbackTimings = {}, BackgroundCallbacks = {},
    }
    local function RecordSkip(Id, Reason)
        LoadReport.Skipped += 1
        table.insert(LoadReport.SkippedIds, tostring(Id))
        if Reason then
            table.insert(LoadReport.Entries, { Id = tostring(Id), Status = "Skipped", Reason = Reason })
        end
    end

    local Objects = {}
    local ObjectKeys = {}
    for ObjectIndex, Option in Decoded.objects do
        local Valid, ValidationError = ValidateObject(ObjectIndex, Option)
        if not Valid then
            RecordSkip(typeof(Option) == "table" and Option.idx or ObjectIndex, ValidationError)
            continue
        end

        if Option.type ~= nil then
            local Key = ObjectKey(Option)
            if not ObjectKeys[Key] then
                ObjectKeys[Key] = true
                table.insert(Objects, Option)
            end
        end
    end

    local KeybindMenuData = Decoded.keybindMenu
    local KeybindMenuPosition = nil
    if KeybindMenuData ~= nil then
        local KeybindInvalid = nil
        if typeof(KeybindMenuData) ~= "table" then
            KeybindInvalid = "invalid keybind menu data"
        elseif KeybindMenuData.visible ~= nil and typeof(KeybindMenuData.visible) ~= "boolean" then
            KeybindInvalid = "invalid keybind menu visibility"
        elseif KeybindMenuData.position ~= nil then
            KeybindMenuPosition = SpecialValueParser.UDim2.Decode(KeybindMenuData.position)
            if not KeybindMenuPosition then
                KeybindInvalid = "invalid keybind menu position"
            end
        end

        if KeybindInvalid then
            KeybindMenuData = nil
            RecordSkip("KeybindMenu", KeybindInvalid)
        end
    end

    local Library = SaveManager.Library
    local LoadingOrder = SaveManager.LoadingOrder
    local IgnoreIndexes = SaveManager.Ignore
    local LoadErrors = LoadReport.Errors
    local Batch = {}
    local ValidationTargets = {}

    local function ResolveControl(Index)
        return (Library.Options and Library.Options[Index]) or (Library.Toggles and Library.Toggles[Index])
    end

    local function KindFallbackParser(Kind, Type)
        local Def = KindParser[Kind]
        return {
            Save = function(Index, Control)
                local Data = Def.Save(Control)
                Data.type = Type
                Data.idx = Index
                Data.kind = Kind
                Data.version = Control.ConfigVersion
                return Data
            end,
            Load = function(Index, Data)
                local Target = ResolveControl(Index)
                if not Target then return end
                local Current = Def.Save(Target)
                if DeepEqual(Current.value, Data.value) then return false end
                local WasDisabled = Target.Disabled
                Target.Disabled = false
                local Success, ErrorMessage = pcall(Def.Load, Target, Data)
                Target.Disabled = WasDisabled
                if not Success then error(ErrorMessage, 0) end
                return true
            end,
        }
    end

    local DefaultOrder = { Input = 1, Dropdown = 2, Slider = 3, ColorPicker = 4, Toggle = 5, KeyPicker = 6, Groupbox = 7, Custom = 8 }
    local function Priority(Option)
        if SaveManager.UseLoadingOrder and typeof(LoadingOrder) == "table" then
            local Index = table.find(LoadingOrder, Option.idx) or table.find(LoadingOrder, Option.type)
            if Index then return Index end
        end
        return #LoadingOrder + (DefaultOrder[Option.type] or 9)
    end
    table.sort(Objects, function(a, b)
        local First, Second = Priority(a), Priority(b)
        return First < Second or First == Second and ObjectKey(a) < ObjectKey(b)
    end)

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
            if Option.unsaveable then
                RecordSkip(Option.idx, tostring(Option.reason or "control has no save strategy"))
                continue
            end

            local Kind = typeof(Option.kind) == "string" and KindParser[Option.kind] or nil
            if Kind then
                Parser = KindFallbackParser(Option.kind, Option.type)
            else
                RecordSkip(Option.idx, string.format("no parser or SaveKind for control type %q", tostring(Option.type)))
                continue
            end
        end

        local TargetExists = false
        if Option.type == "Toggle" then
            local Target = Library.Toggles and Library.Toggles[Option.idx]
            TargetExists = Target ~= nil and Target.Type == "Toggle"
        elseif Option.type == "Groupbox" then
            local Tab = Library.Tabs and Library.Tabs[Option.tabIdx]
            TargetExists = Tab and Tab.Groupboxes and Tab.Groupboxes[Option.idx] ~= nil
        elseif Option.type == "Custom" then
            TargetExists = SaveManager.Adapters[Option.idx] ~= nil
        else
            local Target = Library.Options and Library.Options[Option.idx]
            TargetExists = Target ~= nil and Target.Type == Option.type
            if TargetExists and Option.type == "Dropdown" and Option.multi ~= nil then
                TargetExists = (Target.Multi == true) == Option.multi
            end
        end
        if not TargetExists then
            LoadReport.Skipped += 1
            LoadReport.Missing += 1
            table.insert(LoadReport.MissingIds, tostring(Option.idx))
            table.insert(LoadReport.Entries, { Id = tostring(Option.idx), Status = "Missing", Reason = "control not found" })
            continue
        end

        local Target = (Option.type == "Toggle" and Library.Toggles or Library.Options)[Option.idx]
        if Target and Target.Save == false then LoadReport.Skipped += 1; continue end
        if Option.type ~= "Custom" and Option.type ~= "Groupbox" and Target and Target.ConfigVersion and Target.ConfigDefault
            and Target.ConfigVersion > (Option.version or 0) then
            local SuccessDefault, DefaultData = pcall(Parser.Save, Option.idx, Target.ConfigDefault)
            if not SuccessDefault then
                table.insert(LoadErrors, tostring(DefaultData))
                continue
            end
            Option = DefaultData
            LoadReport.ResetIds = LoadReport.ResetIds or {}
            table.insert(LoadReport.ResetIds, Option.idx)
        end



        if Option.type == "Dropdown" and Target and type(Target.Values) == "table" then
            local function Exists(Value)
                if #Target.Values > 0 then return table.find(Target.Values, Value) ~= nil end
                return Value ~= nil and Target.Values[Value] ~= nil
            end
            local Invalid = false
            if Target.Multi then
                for Key, Value in Option.value or {} do
                    local Selected = type(Value) == "boolean" and Key or Value
                    if Value ~= false and not Exists(Selected) then Invalid = true; break end
                end
            else
                Invalid = Option.value ~= nil and not Exists(Option.value)
            end
            if Invalid then
                local Default = Target.ConfigDefault and Target.ConfigDefault.Value or Target.Default
                local Replacement
                if Target.Multi then
                    Replacement = {}
                    for Key, Value in Default or {} do
                        local Selected = type(Value) == "boolean" and Key or Value
                        if Value ~= false and Exists(Selected) then table.insert(Replacement, Selected) end
                    end
                elseif Exists(Default) then Replacement = Default
                elseif not Target.AllowNull then
                    if #Target.Values > 0 then Replacement = Target.Values[1]
                    else
                        local Keys = {}
                        for Key in Target.Values do table.insert(Keys, Key) end
                        table.sort(Keys, function(A, B) return tostring(A) < tostring(B) end)
                        Replacement = Keys[1]
                    end
                end
                Option = table.clone(Option)
                Option.value = Replacement
                LoadReport.Adjusted = (LoadReport.Adjusted or 0) + 1
                LoadReport.AdjustedIds = LoadReport.AdjustedIds or {}
                table.insert(LoadReport.AdjustedIds, Option.idx)
            end
        end

        local IsTheme = IsThemeManagerOption(Option.idx)
        local PreviousContext = Library.ConfigLoadContext
        local Context = { Thread = coroutine.running(), Errors = {}, Timings = LoadReport.CallbackTimings, Id = Option.idx }
        if not IsTheme and (Target and Target.ConfigCallbackMode or SaveManager.CallbackMode) == "Background" then
            Context.BackgroundJobs = LoadReport.BackgroundCallbacks
        elseif Batched and not IsTheme then
            Context.BackgroundJobs = Batch
        end
        Library.ConfigLoadContext = Context
        local SuccessLoad, LoadError = pcall(Parser.Load, Option.idx, Option)
        Library.ConfigLoadContext = PreviousContext
        if #Context.Errors > 0 then
            SuccessLoad = false
            LoadError = table.concat(Context.Errors, "; ")
        end
        if not SuccessLoad then
            LoadReport.Failed += 1
            table.insert(LoadReport.FailedIds, tostring(Option.idx))
            table.insert(LoadErrors, string.format("%s %q: %s", tostring(Option.type), tostring(Option.idx), tostring(LoadError)))
            table.insert(LoadReport.Entries, { Id = tostring(Option.idx), Status = "Failed", Reason = tostring(LoadError) })
            continue
        end
        if LoadError == false then LoadReport.Unchanged += 1 else LoadReport.Applied += 1 end

        if Target and Option.type ~= "Groupbox" and Option.type ~= "Custom" and typeof(Target.Validate) == "function" then
            table.insert(ValidationTargets, { Id = Option.idx, Control = Target })
        end

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

    for _, Item in ValidationTargets do
        local Control = Item.Control
        local Success, Result = pcall(Control.Validate, Control.Value)
        local ErrorText = if Success then (typeof(Result) == "string" and Result ~= "" and Result or nil) else tostring(Result)
        if ErrorText then
            LoadReport.Invalid += 1
            table.insert(LoadReport.InvalidIds, tostring(Item.Id))
            table.insert(LoadReport.Entries, { Id = tostring(Item.Id), Status = "Invalid", Reason = ErrorText })
            if typeof(Control.SetError) == "function" then pcall(Control.SetError, Control, ErrorText) end
        elseif typeof(Control.ClearError) == "function" then
            pcall(Control.ClearError, Control)
        end
    end

    LoadReport.Total = LoadReport.Applied + LoadReport.Unchanged + LoadReport.Skipped + LoadReport.Failed

    if LoadReport.Applied == 0 and LoadReport.Unchanged == 0 and LoadReport.Missing > 0 then
        table.insert(LoadErrors, "No matching controls or adapters. Create them before loading and keep their IDs stable")
        for _, Job in LoadReport.BackgroundCallbacks do Job.Status = "Cancelled"; Job.Run = nil end
        for _, Job in Batch do Job.Status = "Cancelled"; Job.Run = nil end
        LoadReport.Status = "Failed"
        SaveManager.LastLoadReport = LoadReport
        return false, "Failed to load config data: " .. table.concat(LoadErrors, "; "), LoadReport
    end

    LoadReport.ConfigName = LoadContext.ConfigName or Decoded.name
    LoadReport.Source = LoadContext.Source or "JSON"
    SaveManager.LastLoadReport = LoadReport

    local function Finish()
        SaveManager:RunApplyBatch(Batch, LoadReport)
        for _, Job in LoadReport.BackgroundCallbacks do
            local Run = Job.Run
            Job.Run = nil
            task.defer(Run)
        end
        table.sort(LoadReport.CallbackTimings, function(A, B) return A.Seconds > B.Seconds end)
        LoadReport.Status = (LoadReport.Missing > 0 or LoadReport.Failed > 0) and "Partial" or "Loaded"
        SaveManager.ActiveProfile = LoadReport.ConfigName
        SaveManager:EmitConfigLoaded(LoadReport)
    end

    if AutoApply then
        Finish()
    else
        LoadReport.Status = LoadReport.Missing > 0 and "Partial" or "Loaded"
        SaveManager.PendingApply = { Report = LoadReport, Finish = Finish }
    end

    return true, nil, LoadReport
end

function SaveManager:Load(ConfigName: string, Source: string?, Options: any?): (boolean, string?, { [string]: any }?)
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

    local LoadOptions = { ConfigName = ConfigName, Source = Source or "Load" }
    for Key, Value in typeof(Options) == "table" and Options or {} do
        LoadOptions[Key] = Value
    end
    return SaveManager:LoadJSON(Content, LoadOptions)
end

function SaveManager:Delete(ConfigName: string): (boolean, string?)
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
    if not SuccessDelete or isfile(ConfigPath) then
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

    AutoloadConfigName = Trim(AutoloadConfigName:gsub("^\239\187\191", ""))
    if AutoloadConfigName == "" then
        return "none", false, "Autoload config is not set"
    end
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
    local ConfigName, Success, FetchErrorMessage = SaveManager:GetAutoloadConfig()
    if not Success or FetchErrorMessage then
        if FetchErrorMessage == "Autoload config is not set" then
            return true, nil, { Status = "NotConfigured", Applied = 0, Skipped = 0, Missing = 0 }
        end
        SaveManager:Notify(tostring(FetchErrorMessage) .. ". Check the config folder and select Set as autoload again.", "Autoload failed", "Error")
        return false, FetchErrorMessage
    end

    local SuccessLoad, LoadErrorMessage, Report = SaveManager:Load(ConfigName, "Autoload")
    if not SuccessLoad then
        SaveManager:Notify(string.format("%s: %s", ConfigName, tostring(LoadErrorMessage)), "Autoload failed", "Error")
        return false, LoadErrorMessage, Report
    end

    Report.ConfigName = ConfigName
    local Incomplete = (Report.Missing or 0) > 0 or (Report.Failed or 0) > 0
    SaveManager:Notify(string.format("%s: %s.%s", ConfigName, SaveManager:LoadSummary(Report),
        Incomplete and " Some controls did not load. Update Library and addons together, then check their IDs." or ""),
        Incomplete and "Autoload incomplete" or "Config loaded", Incomplete and "Warning" or "Success")
    return true, nil, Report
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

    local SuccessDelete = pcall(delfile, AutoloadPath)
    if not SuccessDelete or isfile(AutoloadPath) then
        local Cleared, ClearError = WriteVerified(AutoloadPath, "")
        if not Cleared then return false, ClearError end
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
    local function RefreshList(Selected)
        local Previous = Selected or ConfigList.Value
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
            SaveManager:Notify("Configuration name cannot be empty.")
            return
        end

        if string.lower(ConfigName) == "autoload" then
            SaveManager:Notify("Invalid config name provided.")
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
                    SaveManager:Notify(string.format("Failed to create config %q: %s", ConfigName, ErrorMessage))
                    return
                end

                SaveManager:Notify(string.format("Successfully created config %q", ConfigName))
                RefreshList(ConfigName)
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
                SaveManager:Notify("Please select a config first.")
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
                    local Success, ErrorMessage, Report = SaveManager:Load(ConfigName)
                    if not Success then
                        SaveManager:Notify(string.format("Failed to load config %q: %s", ConfigName, ErrorMessage))
                        return
                    end

                    local Incomplete = (Report.Missing or 0) > 0 or (Report.Failed or 0) > 0
                    SaveManager:Notify(string.format("%s: %s.%s", ConfigName, SaveManager:LoadSummary(Report),
                        Incomplete and " Check control IDs and update Library and addons together." or ""),
                        Incomplete and "Config loaded partially" or "Config loaded", Incomplete and "Warning" or "Success")
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
                SaveManager:Notify("Please select a config first.")
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
                        SaveManager:Notify(string.format("Failed to overwrite config %q: %s", ConfigName, ErrorMessage))
                        return
                    end

                    SaveManager:Notify(string.format("Successfully overwrote config %q", ConfigName))
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
                SaveManager:Notify("Please select a config first.")
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
                        SaveManager:Notify(string.format("Failed to delete config %q: %s", ConfigName, ErrorMessage))
                        return
                    end

                    SaveManager:Notify(string.format("Successfully deleted config %q", ConfigName))
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
                SaveManager:Notify("Please select a config first.")
                return
            end

            local Success, ErrorMessage = SaveManager:SaveAutoloadConfig(ConfigName)
            if not Success then
                SaveManager:Notify(string.format("Failed to set autoload config %q: %s", ConfigName, ErrorMessage))
                return
            end

            SaveManager:Notify(string.format("Successfully set autoload config to %q", ConfigName))
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
                        SaveManager:Notify(string.format("Failed to reset autoload config: %s", ErrorMessage))
                        return
                    end

                    SaveManager:Notify("Successfully reset autoload config.")
                    RefreshAutoloadConfigLabel()
                end
            )
        end
    })

    ConfigurationBox:AddButton({
        Text = "Duplicate config",
        DoubleClick = false,

        Func = function()
            local Source = ConfigList.Value
            if IsStringEmpty(Source) then
                SaveManager:Notify("Please select a config first.")
                return
            end

            local Target = Trim(ConfigNameInput.Value)
            if IsStringEmpty(Target) then
                SaveManager:Notify("Type a name for the copy in the config name field.")
                return
            end

            local Success, ErrorMessage = SaveManager:Duplicate(Source, Target)
            if not Success then
                SaveManager:Notify(string.format("Failed to duplicate %q: %s", Source, ErrorMessage))
                return
            end

            SaveManager:Notify(string.format("Duplicated %q to %q", Source, Target))
            RefreshList(Target)
        end
    })

    ConfigurationBox:AddButton({
        Text = "Rename config",
        DoubleClick = false,

        Func = function()
            local Source = ConfigList.Value
            if IsStringEmpty(Source) then
                SaveManager:Notify("Please select a config first.")
                return
            end

            local Target = Trim(ConfigNameInput.Value)
            if IsStringEmpty(Target) then
                SaveManager:Notify("Type the new name in the config name field.")
                return
            end

            local Success, ErrorMessage = SaveManager:Rename(Source, Target)
            if not Success then
                SaveManager:Notify(string.format("Failed to rename %q: %s", Source, ErrorMessage))
                return
            end

            SaveManager:Notify(string.format("Renamed %q to %q", Source, Target))
            RefreshAutoloadConfigLabel()
            RefreshList(Target)
        end
    })

    ConfigurationBox:AddButton({
        Text = "Preview changes",
        DoubleClick = false,

        Func = function()
            local ConfigName = ConfigList.Value
            if IsStringEmpty(ConfigName) then
                SaveManager:Notify("Please select a config first.")
                return
            end

            local Changes, ErrorMessage = SaveManager:PreviewConfig(ConfigName)
            if not Changes then
                SaveManager:Notify(string.format("Failed to preview %q: %s", ConfigName, ErrorMessage))
                return
            end

            if #Changes == 0 then
                SaveManager:Notify(string.format("%q matches your current settings. Nothing would change.", ConfigName))
                return
            end

            ShowDialog(
                function(): boolean
                    return true
                end,

                "SaveManager_PreviewConfig",
                "Load config",
                string.format("Loading %q will change %d setting(s). Continue?", ConfigName, #Changes),

                "Load",
                function()
                    local Success, LoadErrorMessage, Report = SaveManager:Load(ConfigName)
                    if not Success then
                        SaveManager:Notify(string.format("Failed to load config %q: %s", ConfigName, LoadErrorMessage))
                        return
                    end

                    SaveManager:Notify(string.format("%s: %s", ConfigName, SaveManager:LoadSummary(Report)),
                        "Config loaded", "Success")
                end
            )
        end
    })

    ConfigurationBox:AddButton({
        Text = "Restore backup",
        DoubleClick = false,

        Func = function()
            local ConfigName = ConfigList.Value
            if IsStringEmpty(ConfigName) then
                SaveManager:Notify("Please select a config first.")
                return
            end

            local Backups = SaveManager:ListBackups(ConfigName)
            if #Backups == 0 then
                SaveManager:Notify(string.format("No backups are stored for %q yet.", ConfigName))
                return
            end

            ShowDialog(
                function(): boolean
                    return true
                end,

                "SaveManager_RestoreBackup",
                "Restore backup",
                string.format("Restore %q from its most recent backup? Your current saved config will be replaced.", ConfigName),

                "Restore",
                function()
                    local Success, ErrorMessage = SaveManager:RestoreBackup(ConfigName, Backups[1].Index)
                    if not Success then
                        SaveManager:Notify(string.format("Failed to restore backup for %q: %s", ConfigName, ErrorMessage))
                        return
                    end

                    SaveManager:Notify(string.format("Restored %q from backup. Load it to apply.", ConfigName))
                    RefreshList(ConfigName)
                end
            )
        end
    })

    AutoloadConfigLabel = ConfigurationBox:AddLabel("Current autoload config: ...", true);

    ConfigurationBox:AddDivider()

    
    ConfigurationBox:AddInput("SaveManager_JSON", {
        Text = "Paste or export config JSON"
    })

    ConfigurationBox:AddButton("Import config", function()
        local ConfigJSON = ConfigJSONInput.Value
        if IsStringEmpty(ConfigJSON) then
            SaveManager:Notify("Paste a config into the field above first.")
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
                    SaveManager:Notify(string.format("Failed to import config: %s", ErrorMessage))
                    return
                end

                SaveManager:Notify("Successfully imported config")
            end
        )
    end)

    ConfigurationBox:AddButton("Export current config", function()
        local EncodedData, Success, ErrorMessage = SaveManager:SaveJSON()
        if not Success  then
            SaveManager:Notify(ErrorMessage)
            return
        end

        ConfigJSONInput:SetValue(EncodedData)

        local Env = SaveManager.Library.Env
        local SetClipboard = (Env and Env.setclipboard) or setclipboard
        if type(SetClipboard) == "function" and pcall(SetClipboard, EncodedData) then
            SaveManager:Notify("Copied config to your clipboard. Paste it anywhere to share.")
        else
            SaveManager:Notify("Clipboard is unavailable. Select the JSON in the field above and copy it manually.")
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
