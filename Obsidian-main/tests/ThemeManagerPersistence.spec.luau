return function(ThemeManager, Environment)
    local ColorKeys = {
        "BackgroundColor", "MainColor", "TopBarColor", "SurfaceColor", "RaisedColor", "ElementColor", "HoverColor",
        "AccentColor", "AccentSoftColor", "OutlineColor", "FontColor", "MutedFontColor", "ShadowColor", "WarningColor",
        "DestructiveColor", "RedColor", "DarkColor", "WhiteColor",
    }
    local Base = { BackgroundImage = "", CornerRadius = 8, IsLight = false, Font = {} }
    local Scheme = { BackgroundImage = "" }
    for Index, Key in ColorKeys do
        local Hex = string.format("%06X", Index * 1000)
        Base[Key] = Environment.Color3.fromHex(Hex)
        Scheme[Key] = Base[Key]
    end
    local Library = {
        Themes = { Default = Base },
        Scheme = Scheme,
        DefaultTheme = "Default",
        CurrentTheme = "Default",
        CurrentFontName = "GothamMedium",
        CornerRadius = 8,
        IsLightTheme = false,
    }
    function Library:ResolveThemeName(Name)
        return self.Themes[Name] and Name or "Default"
    end
    function Library:RegisterTheme(Name, Overrides, BaseName)
        local Theme = table.clone(self.Themes[BaseName] or self.Themes.Default)
        for Key, Value in Overrides do Theme[Key] = Value end
        self.Themes[Name] = Theme
        return self
    end
    function Library:SetTheme(Name)
        self.CurrentTheme = self:ResolveThemeName(Name)
        local Theme = self.Themes[self.CurrentTheme]
        for Key, Value in Theme do
            if Scheme[Key] ~= nil then Scheme[Key] = Value end
        end
        return self
    end
    function Library:GetDesignToken(_, Fallback) return Fallback end
    function Library:GetFontPreset() return nil end

    ThemeManager:SetFolder("MonHub/ThemeTests")
    local Initialized, InitError = ThemeManager:SetLibrary(Library)
    assert(Initialized, InitError)
    assert(not ThemeManager:SaveCustomTheme("default"))
    local Saved, SaveError = ThemeManager:SaveCustomTheme("Ocean")
    assert(Saved, SaveError)
    assert(Environment.files["MonHub/ThemeTests/themes/Ocean.json"] ~= nil)
    assert(Library.Themes.Ocean ~= nil)
    assert(not ThemeManager:SaveCustomTheme("ocean"))
    assert(ThemeManager:SetDefaultTheme("ocean"))
    assert(Library.CurrentTheme == "Ocean")
    assert(ThemeManager:ApplyTheme("Ocean"))
    assert(Library.CurrentTheme == "Ocean")
    assert(ThemeManager:SaveDefault("Ocean"))
    assert(Environment.files["MonHub/ThemeTests/themes/default-v8.txt"] == "Ocean")

    Library.Themes.Ocean = nil
    table.clear(ThemeManager.CustomThemes)
    local Names, ReloadError = ThemeManager:ReloadCustomThemes()
    assert(not ReloadError and #Names == 1 and Names[1] == "Ocean")
    assert(Library.Themes.Ocean ~= nil)
    local DefaultName, DefaultReady = ThemeManager:GetDefaultTheme()
    assert(DefaultReady and DefaultName == "Ocean")

    assert(ThemeManager:Delete("Ocean"))
    assert(Library.Themes.Ocean == nil and Environment.files["MonHub/ThemeTests/themes/Ocean.json"] == nil)
    assert(ThemeManager:DeleteDefaultTheme())
    assert(Environment.files["MonHub/ThemeTests/themes/default-v8.txt"] == nil)
    print("PASS custom theme persistence, reload, startup selection and deletion")
end
