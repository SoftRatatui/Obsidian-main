return function(SaveManager, Environment)
    local function Control(Type, Value)
        local Item = { Type = Type, Value = Value, ChangedRuns = 0 }
        function Item:SetValue(NewValue)
            if self.Disabled then return end
            if self.Value == NewValue then return end
            if Type == "Slider" then
                self.Value = tonumber(NewValue)
            elseif Type == "KeyPicker" then
                self.Value = NewValue[1]
                self.Mode = NewValue[2]
                self.Modifiers = NewValue[3]
            else
                self.Value = NewValue
            end
            self.ChangedRuns += 1
        end
        function Item:SetValueRGB(NewValue, Transparency)
            self.Value = NewValue
            self.Transparency = Transparency
            self.ChangedRuns += 1
        end
        function Item:RunChanged()
            self.ChangedRuns += 1
        end
        function Item:Update() end
        return Item
    end

    local Feature = Control("Toggle", true)
    local KeybindMenu = Control("Toggle", true)
    local Strength = Control("Slider", 72)
    local Accent = Control("ColorPicker", Environment.Color3.fromHex("786FD4"))
    Accent.Transparency = 0.25
    local Keybind = Control("KeyPicker", "K")
    Keybind.Mode = "Toggle"
    Keybind.Modifiers = { "LeftControl" }
    Keybind.Toggled = true
    local Profile = Control("Input", "alpha")
    local Library = {
        ReleaseVersion = "test",
        Toggles = { Feature = Feature, KeybindMenuOpen = KeybindMenu },
        Options = { Strength = Strength, Accent = Accent, Keybind = Keybind, Profile = Profile },
        Tabs = {},
        KeybindFrame = { Visible = true, Position = Environment.UDim2.new(0, 20, 0, 30) },
        KeybindMenuRequested = true,
        Notifications = {},
    }
    Environment.BindCallbacks(Library)
    function Library:SetKeybindMenuVisible(Value)
        self.KeybindMenuRequested = Value
        self.KeybindFrame.Visible = Value
    end
    function Library:Notify(Message)
        table.insert(self.Notifications, Message)
    end

    local ModuleState = { Layout = "Split", Visible = true }
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    assert(SaveManager.Ignore.ThemeManager_ThemeList == true)
    SaveManager:SetFolder("MonHub\\Tests")
    SaveManager:SetSubFolder("place-1")
    SaveManager:RegisterAdapter("CatalogState", {
        Save = function()
            return { Layout = ModuleState.Layout, Visible = ModuleState.Visible }
        end,
        Validate = function(Value)
            return type(Value) == "table" and type(Value.Layout) == "string", "invalid catalog state"
        end,
        Load = function(Value)
            ModuleState.Layout = Value.Layout
            ModuleState.Visible = Value.Visible == true
        end,
    })

    local Saved, SaveError = SaveManager:Save("zeta")
    assert(Saved, SaveError)
    assert(Environment.files["MonHub/Tests/settings/place-1/zeta.json"] ~= nil)
    assert(Environment.files["MonHub/Tests/settings/place-1/zeta.pending.json"] == nil)

    Feature.Value = false
    Strength.Value = 4
    Accent.Value = Environment.Color3.fromHex("FFFFFF")
    Accent.Transparency = 1
    Profile.Value = "changed"
    ModuleState.Layout = "Grid"
    ModuleState.Visible = false
    Library.KeybindFrame.Visible = false
    Library.KeybindMenuRequested = false

    local Loaded, LoadError, Report = SaveManager:Load("zeta")
    assert(Loaded, LoadError)
    assert(Feature.Value == true and Strength.Value == 72 and Profile.Value == "alpha")
    assert(Accent.Value:ToHex() == "786FD4" and Accent.Transparency == 0.25)
    assert(ModuleState.Layout == "Split" and ModuleState.Visible == true)
    assert(Library.KeybindFrame.Visible == true and KeybindMenu.Value == true)
    assert(Report.Applied + Report.Unchanged >= 7 and Report.Skipped == 0)

    local Runs = Feature.ChangedRuns + Strength.ChangedRuns + Accent.ChangedRuns + Keybind.ChangedRuns + Profile.ChangedRuns
    local SameOK, SameError, SameReport = SaveManager:Load("zeta")
    assert(SameOK, SameError)
    assert(SameReport.Unchanged >= 6)
    assert(Feature.ChangedRuns + Strength.ChangedRuns + Accent.ChangedRuns + Keybind.ChangedRuns + Profile.ChangedRuns == Runs, "Unchanged controls ran callbacks")
    Keybind.Modifiers = nil
    assert(SaveManager:Load("zeta"))
    assert(Keybind.Modifiers[1] == "LeftControl", "Missing current fields incorrectly count as unchanged")

    SaveManager:Save("Alpha")
    Environment.files["MonHub/Tests/settings/place-1/notes.txt"] = "ignore"
    local Names = SaveManager:RefreshConfigList()
    assert(#Names == 2 and Names[1] == "Alpha" and Names[2] == "zeta")

    local Autoloaded, AutoloadError = SaveManager:SaveAutoloadConfig("zeta")
    assert(Autoloaded, AutoloadError)
    Feature.Value = false
    assert(SaveManager:LoadAutoloadConfig())
    assert(Feature.Value == true)
    assert(SaveManager:DeleteAutoLoadConfig())
    assert(SaveManager:DeleteAutoLoadConfig())

    local LegacyColor = Environment.storedJson[Environment.files["MonHub/Tests/settings/place-1/zeta.json"]]
    for _, Object in LegacyColor.objects do
        if Object.type == "ColorPicker" then
            Object.transparency = nil
        end
    end
    Accent.Transparency = 0.8
    assert(SaveManager:Load("zeta"))
    assert(Accent.Transparency == 0)

    SaveManager:UnregisterAdapter("CatalogState")
    ModuleState.Layout = "Detached"
    local Compatible, CompatibleError, CompatibleReport = SaveManager:Load("zeta")
    assert(Compatible, CompatibleError)
    assert(ModuleState.Layout == "Detached" and CompatibleReport.Skipped == 1)

    Accent.Value = Environment.Color3.fromHex("ABCDEF")
    Accent.Transparency = 0.4
    Profile.Value = "stable"
    local OriginalSetValue = Profile.SetValue
    function Profile:SetValue(Value)
        if Value == "explode" then error("simulated callback failure") end
        OriginalSetValue(self, Value)
    end
    for _, Object in LegacyColor.objects do
        if Object.type == "Input" and Object.idx == "Profile" then Object.text = "explode" end
    end
    local PartialLoad, PartialError, PartialReport = SaveManager:Load("zeta")
    assert(PartialLoad, "Resilient load should keep working entries: " .. tostring(PartialError))
    assert(PartialReport.Failed == 1 and PartialReport.FailedIds[1] == "Profile", "Throwing entry was not recorded as failed")
    assert(Accent.Value:ToHex() == "786FD4", "A good entry must still apply when another throws: " .. tostring(Accent.Value:ToHex()))
    assert(Profile.Value == "stable", "Throwing entry must be skipped, not applied: " .. tostring(Profile.Value))
    assert(PartialReport.Missing == 1 and PartialReport.MissingIds[1] == "CatalogState", "Missing adapter was not reported")

    Profile.SetValue = OriginalSetValue
    local A = { Collapsed = true, SetCollapsed = function(self, Value) self.Collapsed = Value end }
    local B = { Collapsed = false, SetCollapsed = A.SetCollapsed }
    Library.Tabs = { First = { Groupboxes = { Settings = A } }, Second = { Groupboxes = { Settings = B } } }
    assert(SaveManager:Save("groups"))
    A.Collapsed, B.Collapsed = false, true
    assert(SaveManager:Load("groups"), "Same groupbox name in different tabs must load")
    assert(A.Collapsed and not B.Collapsed)

    Feature.Disabled, Strength.Disabled = true, true
    Feature.Value, Strength.Value = false, 0
    assert(SaveManager:Load("groups"))
    assert(Feature.Value and Strength.Value == 72, "Disabled controls were not restored")
    assert(Feature.Disabled and Strength.Disabled, "Loading changed disabled state")
    Feature.Disabled, Strength.Disabled = false, false

    local OriginalContent = Environment.files["MonHub/Tests/settings/place-1/groups.json"]
    for _, Mode in { "throw", "corrupt" } do
        Environment.faults.WritePath = "MonHub/Tests/settings/place-1/groups.json"
        Environment.faults.Mode = Mode
        local Wrote, ErrorMessage = SaveManager:Save("groups")
        assert(not Wrote and ErrorMessage)
        assert(Environment.files["MonHub/Tests/settings/place-1/groups.json"] == OriginalContent, "Failed write destroyed the previous config")
        assert(Environment.files["MonHub/Tests/settings/place-1/groups.backup.json"] == OriginalContent)
    end

    assert(SaveManager:SaveAutoloadConfig("groups"))
    local Restarted = Environment.CreateSaveManager()
    Restarted:SetLibrary(Library):SetFolder("MonHub/Tests"):SetSubFolder("place-1")
    Feature.Value = false
    local RestartOK, RestartError, RestartReport = Restarted:LoadAutoloadConfig()
    assert(RestartOK, RestartError)
    assert(Feature.Value and RestartReport.Status == "Loaded" and RestartReport.ConfigName == "groups")
    assert(type(Library.Notifications[#Library.Notifications]) == "table")
    assert(Restarted:DeleteAutoLoadConfig())
    local CountBefore = #Library.Notifications
    local EmptyOK, _, EmptyReport = Restarted:LoadAutoloadConfig()
    assert(EmptyOK and EmptyReport.Status == "NotConfigured" and #Library.Notifications == CountBefore)

    local EmptyLibrary = { Options = {}, Toggles = {}, Tabs = {} }
    Restarted:SetLibrary(EmptyLibrary)
    local EarlyOK, _, EarlyReport = Restarted:Load("groups")
    assert(not EarlyOK and EarlyReport.Missing > 0, "Loading before controls exist reported success")
    Restarted:SetLibrary(Library)

    Strength.Value = 31
    local OriginalSliderSetter = Strength.SetValue
    function Strength:SetValue(Value)
        OriginalSliderSetter(self, Value)
        Library:SafeCallback(function()
            if tonumber(Value) == 72 then error("real SafeCallback failure") end
        end)
    end
    local CallbackOK, CallbackError, CallbackReport = Restarted:Load("groups")
    assert(CallbackOK, "A failing callback must not fail the whole load: " .. tostring(CallbackError))
    assert(CallbackReport.Failed >= 1 and CallbackReport.FailedIds[1] == "Strength")
    local SawCallbackError = false
    for _, Message in CallbackReport.Errors do
        if string.find(Message, "real SafeCallback failure", 1, true) then SawCallbackError = true end
    end
    assert(SawCallbackError, "Callback failure was not recorded in the report")
    assert(Strength.Value == 72 and Library.ConfigLoadContext == nil, "Applied value must survive a failing callback and context must clear")
    Strength.SetValue = OriginalSliderSetter

    local BackgroundCalls = 0
    function Strength:SetValue(Value)
        OriginalSliderSetter(self, Value)
        Library:SafeCallback(function() BackgroundCalls += 1 end)
    end
    Strength.ConfigCallbackMode = "Background"
    Strength.Value = 10
    local BackgroundOK, BackgroundError, BackgroundReport = Restarted:Load("groups")
    assert(BackgroundOK, BackgroundError)
    assert(Strength.Value == 72 and BackgroundCalls == 0 and #BackgroundReport.BackgroundCallbacks == 1)
    Environment.FlushCallbacks()
    assert(BackgroundCalls == 1 and BackgroundReport.BackgroundCallbacks[1].Status == "Completed")
    assert(Restarted:GetSlowCallbacks(0)[1].Id == "Strength")
    assert(Restarted:Load("groups"))
    Environment.FlushCallbacks()
    assert(BackgroundCalls == 1, "Unchanged background callback was queued")
    Strength.Value = 12
    function Strength:SetValue(Value)
        OriginalSliderSetter(self, Value)
        Library:SafeCallback(function() error("background failure") end)
    end
    assert(Restarted:Load("groups"))
    local FailedJob = Restarted.LastLoadReport.BackgroundCallbacks[1]
    Environment.FlushCallbacks()
    assert(FailedJob.Status == "Failed" and FailedJob.Error:find("background failure", 1, true))
    assert(Strength.Value == 72, "Background failure rolled back committed values")
    function Strength:SetValue(Value)
        OriginalSliderSetter(self, Value)
        Library:SafeCallback(function() BackgroundCalls += 1 end)
    end
    Strength.ConfigCallbackMode = nil
    Strength.Value = 20
    assert(Restarted:Load("groups"))
    assert(BackgroundCalls == 2 and #Restarted.LastLoadReport.CallbackTimings == 1)
    Strength.SetValue = OriginalSliderSetter

    local ApplyCalls = 0
    Strength.Value = 5
    function Strength:SetValue(Value)
        OriginalSliderSetter(self, Value)
        Library:SafeCallback(function() ApplyCalls += 1 end)
    end
    local BatchedOK = Restarted:Load("groups", "Manual", { AutoApply = false })
    assert(BatchedOK, "Batched load with deferred apply failed")
    assert(Strength.Value == 72 and ApplyCalls == 0, "Batched load must set values before running callbacks")
    Restarted:Apply()
    assert(ApplyCalls == 1, "Apply did not run the deferred callback exactly once")
    Strength.SetValue = OriginalSliderSetter
    print("PASS resilient partial load, batched apply and per-entry reporting")

    local Multi = Control("Dropdown", { [2] = true, [17] = true })
    Multi.Multi = true
    function Multi:SetValue(Values)
        self.Value = {}
        for Key, Value in Values do
            self.Value[type(Value) == "boolean" and Key or Value] = true
        end
    end
    Library.Options.Multi = Multi
    assert(Restarted:Save("multi"))
    local MultiJSON = Environment.storedJson[Environment.files["MonHub/Tests/settings/place-1/multi.json"]]
    for _, Object in MultiJSON.objects do
        if Object.idx == "Multi" then assert(#Object.value == 2 and Object.value[1] ~= true) end
    end
    Multi.Value = {}
    assert(Restarted:Load("multi") and Multi.Value[2] and Multi.Value[17])

    local Buttons = {}
    local Box = {}
    function Box:AddInput(Id, Info)
        local Input = Control("Input", "")
        Library.Options[Id] = Input
        return Input
    end
    function Box:AddDropdown(Id, Info)
        local Dropdown = Control("Dropdown", nil)
        Dropdown.Values = Info.Values
        function Dropdown:SetValues(Values) self.Values = Values end
        Library.Options[Id] = Dropdown
        return Dropdown
    end
    function Box:AddButton(Info, Callback)
        Buttons[type(Info) == "string" and Info or Info.Text] = Callback or Info.Func
    end
    function Box:AddDivider() end
    function Box:AddLabel()
        return { SetText = function(self, Text) self.Text = Text end }
    end
    Library.Window = { AddDialog = function(_, _, Info)
        Info.FooterButtons.DestructiveAction.Callback({ Dismiss = function() end })
    end }
    Restarted:BuildConfigSection({ AddRightGroupbox = function() return Box end })
    Library.Options.SaveManager_ConfigName:SetValue(" from-ui ")
    Buttons["Create config"]()
    assert(Library.Options.SaveManager_ConfigList.Value == "from-ui", "New config was not selected")
    Buttons["Set as autoload"]()
    assert(Restarted:GetAutoloadConfig() == "from-ui")
    Feature.Value = false
    Buttons["Load config"]()
    assert(Feature.Value)
    Buttons["Reset autoload"]()
    assert(select(2, Restarted:GetAutoloadConfig()) == false)
    Buttons["Delete config"]()
    assert(Environment.files["MonHub/Tests/settings/place-1/from-ui.json"] == nil)

    local Hidden = Control("Hidden", "knife-default")
    Library.Options.HiddenSkin = Hidden
    assert(Restarted:Save("hidden-state"))
    Hidden.Value = "changed"
    local Calls = 0
    local Disconnect = Restarted:OnConfigLoaded(function(Report)
        Calls += 1
        assert(Hidden.Value == "knife-default", "Listener ran before hidden state was applied")
        assert(Report.ConfigName == "hidden-state" and Report.Status == "Loaded")
    end)
    assert(Restarted:Load("hidden-state"))
    assert(Calls == 1)
    Disconnect()
    assert(Restarted:Load("hidden-state"))
    assert(Calls == 1)
    Hidden.ConfigVersion = 2
    Hidden.ConfigDefault = { Value = "new-default" }
    assert(Restarted:Load("hidden-state"))
    assert(Hidden.Value == "new-default", "Older unversioned option did not reset")
    Hidden.Value = "user-choice"
    assert(Restarted:Save("hidden-state"))
    Hidden.Value = "other"
    assert(Restarted:Load("hidden-state"))
    assert(Hidden.Value == "user-choice", "Same-version user choice was overwritten")
    local StopFailure = Restarted:OnConfigLoaded(function() error("consumer failed") end)
    local Loaded, _, Report = Restarted:Load("hidden-state")
    assert(Loaded and #Report.ListenerErrors == 1)
    StopFailure()
    print("PASS hidden config values, option versions and completion listeners")

    local Catalog = Control("Dropdown", "retired")
    Catalog.Values = { "default", "other" }
    Catalog.ConfigDefault = { Value = "default" }
    Catalog.Multi = false
    Library.Options.Catalog = Catalog
    assert(Restarted:Save("stale-dropdown"))
    Catalog.Value = "other"
    local Restored, _, ReplacementReport = Restarted:Load("stale-dropdown")
    assert(Restored and Catalog.Value == "default" and ReplacementReport.Adjusted == 1)
    assert(ReplacementReport.AdjustedIds[1] == "Catalog")
    Catalog.Save = false
    assert(Restarted:Save("ignored-control"))
    for _, Object in Environment.storedJson[Environment.files["MonHub/Tests/settings/place-1/ignored-control.json"]].objects do
        assert(Object.idx ~= "Catalog")
    end
    assert(table.find(Restarted:GetConfigs(), "ignored-control"))
    print("PASS stale dropdown fallback reporting and per-control persistence")

    assert(Restarted:Duplicate("groups", "copy-profile"))
    assert(not Restarted:Duplicate("groups", "copy-profile"))
    assert(Restarted:Rename("copy-profile", "renamed-profile"))
    assert(Environment.files["MonHub/Tests/settings/place-1/renamed-profile.json"])
    assert(not Environment.files["MonHub/Tests/settings/place-1/copy-profile.json"])
    Profile.Value = "round-trip"
    assert(Restarted:Save("profile-a"))
    assert(Restarted:Duplicate("profile-a", "profile-b"))
    Profile.Value = "changed-after"
    assert(Restarted:Rename("profile-b", "profile-c"))
    assert(Environment.files["MonHub/Tests/settings/place-1/profile-c.json"])
    assert(not Environment.files["MonHub/Tests/settings/place-1/profile-b.json"])
    Profile.Value = "scratch"
    assert(Restarted:Load("profile-c"))
    assert(Profile.Value == "round-trip", "Duplicated then renamed profile lost its settings")
    local Subset, SubsetOK = Restarted:SaveSubsetJSON({ "Strength" })
    assert(SubsetOK)
    local SubsetData = Environment.storedJson[Subset]
    assert(#SubsetData.objects == 1 and SubsetData.objects[1].idx == "Strength" and not SubsetData.keybindMenu)
    Profile.Value = "before migration"
    assert(Restarted:Save("migration"))
    Restarted:SetSchemaVersion(3)
    Restarted:RegisterMigration(2, function(Data)
        for _, Object in Data.objects do if Object.idx == "Profile" then Object.text = "migrated" end end
    end)
    local Preview = Restarted:PreviewJSON(Environment.files["MonHub/Tests/settings/place-1/migration.json"])
    assert(#Preview >= 1 and Profile.Value == "before migration")
    assert(Restarted:Load("migration"))
    assert(Profile.Value == "migrated")
    Restarted:SetSchemaVersion(4)
    local MissingMigration, MigrationError = Restarted:Load("migration")
    assert(not MissingMigration and MigrationError:find("Missing migration", 1, true))
    Restarted:SetSchemaVersion(2)
    print("PASS profile duplication/rename, partial exports, preview and sequential schema migrations")

    local Invalid = Environment.storedJson[OriginalContent]
    for _, Object in Invalid.objects do
        if Object.type == "Slider" then Object.value = "not a number" end
    end
    local BeforeInvalid = Strength.Value
    local Resilient, ResilientError, InvalidReport = Restarted:Load("groups")
    assert(Resilient, "A malformed entry must not abort the whole file: " .. tostring(ResilientError))
    assert(Strength.Value == BeforeInvalid, "Malformed slider must be skipped, not applied")
    assert(InvalidReport.Skipped >= 1)
    local SawSkip = false
    for _, Entry in InvalidReport.Entries do
        if Entry.Id == "Strength" and Entry.Status == "Skipped" then SawSkip = true end
    end
    assert(SawSkip, "Malformed slider was not reported as skipped with a reason")

    Restarted:SetBackupCount(2)
    Profile.Value = "v1"
    assert(Restarted:Save("rotate"))
    Profile.Value = "v2"
    assert(Restarted:Save("rotate"))
    Profile.Value = "v3"
    assert(Restarted:Save("rotate"))
    local Backups = Restarted:ListBackups("rotate")
    assert(#Backups == 2, "Expected two rotated backups")
    assert(Restarted:RestoreBackup("rotate", 1))
    Profile.Value = "scratch"
    assert(Restarted:Load("rotate"))
    assert(Profile.Value == "v2", "Restoring backup 1 should recover the previous version")
    Restarted:SetBackupCount(0)
    print("PASS malformed-entry skip, resilient reporting and backup rotation restore")

    local Segment = Control("Segmented", "A")
    Segment.Values = { "A", "B", "C" }
    function Segment:SetValue(Value)
        if self.Disabled then return end
        local Found = false
        for _, Existing in self.Values do
            if Existing == Value then Found = true break end
        end
        if not Found or self.Value == Value then return end
        self.Value = Value
        self.ChangedRuns += 1
    end
    Library.Options.SegmentedMode = Segment
    Segment.Value = "B"
    assert(Restarted:Save("segmented"))
    local SegmentedJson = Environment.storedJson[Environment.files["MonHub/Tests/settings/place-1/segmented.json"]]
    local SavedSegment = false
    for _, Object in SegmentedJson.objects do
        if Object.idx == "SegmentedMode" then
            assert(Object.type == "Segmented" and Object.value == "B", "Segmented was not serialized")
            SavedSegment = true
        end
    end
    assert(SavedSegment, "Segmented control never reached the config")
    Segment.Value = "A"
    assert(Restarted:Load("segmented"))
    assert(Segment.Value == "B", "Segmented value did not round-trip")

    local Stepper = Control("Stepper", 3)
    Stepper.SaveKind = "value"
    Library.Options.Stepper = Stepper
    Stepper.Value = 7
    assert(Restarted:Save("kind"))
    local KindJson = Environment.storedJson[Environment.files["MonHub/Tests/settings/place-1/kind.json"]]
    local SavedKind = false
    for _, Object in KindJson.objects do
        if Object.idx == "Stepper" then
            assert(Object.kind == "value" and Object.value == 7 and Object.type == "Stepper", "Declared SaveKind was not honoured")
            SavedKind = true
        end
    end
    assert(SavedKind, "Control with a declared SaveKind was not saved")
    Stepper.Value = 1
    assert(Restarted:Load("kind"))
    assert(Stepper.Value == 7, "SaveKind fallback did not restore the value")

    local Ranked = Control("Slider", 20)
    function Ranked.Validate(Value)
        if tonumber(Value) > 100 then return "too high" end
        return nil
    end
    Ranked.Valid = true
    function Ranked:SetError(Text)
        self.Valid = false
        self.ErrorText = Text
    end
    function Ranked:ClearError()
        self.Valid = true
        self.ErrorText = nil
    end
    Library.Options.Ranked = Ranked
    Ranked.Value = 150
    assert(Restarted:Save("validate"))
    Ranked.Value = 20
    Ranked.Valid = true
    local ValidateOK, ValidateError, ValidateReport = Restarted:Load("validate")
    assert(ValidateOK, "A restored invalid value must not fail the load: " .. tostring(ValidateError))
    assert(Ranked.Value == 150, "Restored value was not applied before validation")
    assert(ValidateReport.Invalid == 1 and ValidateReport.InvalidIds[1] == "Ranked", "Restored invalid value was not reported")
    assert(Ranked.Valid == false and Ranked.ErrorText == "too high", "Restored invalid value was not flagged in the UI")
    local SawInvalid = false
    for _, Entry in ValidateReport.Entries do
        if Entry.Id == "Ranked" and Entry.Status == "Invalid" then SawInvalid = true end
    end
    assert(SawInvalid, "Invalid restored value missing from the report entries")
    Ranked.Value = 20
    assert(Restarted:Load("validate"))

    local Widget = Control("Widget", "opaque")
    Widget.Save = true
    Library.Options.Widget = Widget
    assert(Restarted:Save("unsaveable"))
    local SawSaveSkip = false
    for _, Entry in Restarted.LastSaveReport.Skipped do
        if Entry.Id == "Widget" and Entry.Reason then SawSaveSkip = true end
    end
    assert(SawSaveSkip, "Unsaveable control was dropped silently at save time")
    local UnsaveableJson = Environment.storedJson[Environment.files["MonHub/Tests/settings/place-1/unsaveable.json"]]
    local SawMarker = false
    for _, Object in UnsaveableJson.objects do
        if Object.idx == "Widget" then
            assert(Object.unsaveable == true and type(Object.reason) == "string", "Unsaveable marker was malformed")
            SawMarker = true
        end
    end
    assert(SawMarker, "Unsaveable control left no record in the config")
    local UnsaveableOK, UnsaveableError, UnsaveableReport = Restarted:Load("unsaveable")
    assert(UnsaveableOK, UnsaveableError)
    local SawLoadSkip = false
    for _, Entry in UnsaveableReport.Entries do
        if Entry.Id == "Widget" and Entry.Status == "Skipped" and Entry.Reason then SawLoadSkip = true end
    end
    assert(SawLoadSkip, "Unsaveable control was not reported as skipped on load")
    print("PASS segmented round-trip, declared SaveKind fallback, unsaveable reporting and load-time validation")

    print("PASS config round-trip, cross-tab groups, disabled controls, failed-write recovery, restart autoload and resilient partial loads")
end
