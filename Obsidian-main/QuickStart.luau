local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua"
))()

Library:SetTheme("Graphite")
Library:SetClickSound(92679954573730, 0.3)

local App
App = Library:Create({
    Title = "MonHub",
    Footer = "Ready",

    Tabs = {
        {
            Name = "Dashboard",
            Icon = "house",
            Description = "Main controls",

            Sections = {
                {
                    Name = "General",
                    Icon = "settings-2",
                    Side = "Left",

                    Controls = {
                        {
                            Type = "Toggle",
                            Id = "active",
                            Text = "Active",
                            Default = true,
                            OnChanged = function(Value)
                                print("Active:", Value)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "intensity",
                            Text = "Intensity",
                            Min = 0,
                            Max = 100,
                            Default = 40,
                            Suffix = "%",
                        },
                        {
                            Type = "Dropdown",
                            Id = "mode",
                            Text = "Mode",
                            Values = { "Balanced", "Fast", "Quality" },
                            Default = "Balanced",
                        },
                    },
                },
                {
                    Name = "Actions",
                    Icon = "sparkles",
                    Side = "Right",

                    Controls = {
                        "The declarative API also accepts strings as labels.",
                        {
                            Type = "Button",
                            Text = "Show notification",
                            OnClick = function()
                                App:Notify({
                                    Title = "MonHub",
                                    Description = "The new interface is ready.",
                                    Time = 3,
                                })
                            end,
                        },
                    },
                },
            },
        },
    },
})

return App
