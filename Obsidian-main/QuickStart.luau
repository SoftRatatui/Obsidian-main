local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"
))()

local App
App = Library:Create({
    Title = "Black Purple",
    Footer = "Fast, smooth, simple",

    Tabs = {
        {
            Name = "Dashboard",
            Icon = "layout-dashboard",
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
                                    Title = "Obsidian",
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
