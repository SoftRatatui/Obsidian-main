return function(SaveManager, Environment)
    local function Control(Type, Value)
        local Item = { Type = Type, Value = Value, ChangedRuns = 0 }
        function Item:SetValue(NewValue)
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

    print("PASS config round-trip, rollback, verified writes, adapters, compatibility and autoload")
end
