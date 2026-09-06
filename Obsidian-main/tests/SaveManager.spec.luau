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
    assert(Environment.files["MonHub/Tests/settings/place-1/zeta.json.tmp"] == nil)

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
    assert(Report.Applied >= 7 and Report.Skipped == 0)

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
    local FailedLoad, FailedError = SaveManager:Load("zeta")
    assert(not FailedLoad)
    assert(Accent.Value:ToHex() == "ABCDEF", "rollback color: " .. tostring(Accent.Value:ToHex()) .. "; " .. tostring(FailedError))
    assert(Accent.Transparency == 0.4, "rollback transparency: " .. tostring(Accent.Transparency))
    assert(Profile.Value == "stable", "rollback input: " .. tostring(Profile.Value))

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
        assert(Environment.files["MonHub/Tests/settings/place-1/groups.json.bak"] == OriginalContent)
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
    local CallbackOK, CallbackError = Restarted:Load("groups")
    assert(not CallbackOK and CallbackError:find("real SafeCallback failure", 1, true))
    assert(Strength.Value == 31 and Library.ConfigLoadContext == nil, "Callback failure did not roll back or clear context")
    Strength.SetValue = OriginalSliderSetter

    local Invalid = Environment.storedJson[OriginalContent]
    for _, Object in Invalid.objects do
        if Object.type == "Slider" then Object.value = "not a number" end
    end
    assert(not Restarted:Load("groups"))
    assert(Strength.Value == 31)

    print("PASS config round-trip, cross-tab groups, disabled controls, failed-write recovery, restart autoload and real callback rollback")
end
