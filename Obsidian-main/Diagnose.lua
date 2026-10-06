local Repo, Branch, Folder = "SoftRatatui/Obsidian-main", "main", "Obsidian-main/dist/"
local Lines = {}
local Gui, Box

local function Show()
    local Text = table.concat(Lines, "\n")
    pcall(function()
        if writefile then
            writefile("MonHub_diagnose.txt", Text)
        end
    end)
    pcall(function()
        if not Gui then
            Gui = Instance.new("ScreenGui")
            Gui.Name = "MonHubDiagnose"
            Gui.DisplayOrder = 10000
            Gui.ResetOnSpawn = false
            local Holder = (gethui and gethui()) or game:GetService("CoreGui")
            local Ok = pcall(function() Gui.Parent = Holder end)
            if not Ok or not Gui.Parent then
                Gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            end
            local Frame = Instance.new("Frame")
            Frame.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
            Frame.BackgroundTransparency = 0.05
            Frame.Position = UDim2.fromOffset(12, 12)
            Frame.Size = UDim2.new(1, -24, 1, -24)
            Frame.Parent = Gui
            Box = Instance.new("TextBox")
            Box.BackgroundTransparency = 1
            Box.ClearTextOnFocus = false
            Box.MultiLine = true
            Box.TextEditable = false
            Box.TextWrapped = true
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.TextYAlignment = Enum.TextYAlignment.Top
            Box.TextColor3 = Color3.fromRGB(235, 236, 242)
            Box.TextSize = 14
            Box.Font = Enum.Font.Code
            Box.Position = UDim2.fromOffset(8, 8)
            Box.Size = UDim2.new(1, -16, 1, -56)
            Box.Parent = Frame
            local Close = Instance.new("TextButton")
            Close.AnchorPoint = Vector2.new(1, 1)
            Close.BackgroundColor3 = Color3.fromRGB(40, 43, 54)
            Close.Position = UDim2.new(1, -8, 1, -8)
            Close.Size = UDim2.fromOffset(110, 36)
            Close.Text = "Close"
            Close.TextColor3 = Color3.fromRGB(235, 236, 242)
            Close.Parent = Frame
            Close.Activated:Connect(function() Gui:Destroy() end)
        end
        Box.Text = Text
    end)
end

local function Log(Text)
    table.insert(Lines, Text)
    Show()
end

local function Yes(Value)
    return Value and "yes" or "NO"
end

Log("MonHub diagnostic")
local Name, Version = "unknown", ""
pcall(function()
    if identifyexecutor then
        Name, Version = identifyexecutor()
    end
end)
local Platform = "?"
pcall(function() Platform = tostring(game:GetService("UserInputService"):GetPlatform()) end)
Log(("executor: %s %s | platform: %s"):format(tostring(Name), tostring(Version), Platform))
Log(("request=%s http_request=%s syn.request=%s HttpGet=%s loadstring=%s"):format(
    Yes(request), Yes(http_request), Yes(syn and syn.request), Yes(pcall(function() return game.HttpGet end)), Yes(loadstring)))
Log(("getgenv=%s getfenv=%s setfenv=%s gethui=%s cloneref=%s protectgui=%s"):format(
    Yes(getgenv), Yes(getfenv), Yes(setfenv), Yes(gethui), Yes(cloneref), Yes(protectgui)))
Log(("isfile=%s readfile=%s writefile=%s makefolder=%s getcustomasset=%s setclipboard=%s"):format(
    Yes(isfile), Yes(readfile), Yes(writefile), Yes(makefolder), Yes(getcustomasset), Yes(setclipboard)))

local Get = request or http_request or (syn and syn.request)
local function Fetch(Url)
    local Started = os.clock()
    local Result = { Ms = 0 }
    if Get then
        local Ok, Response = pcall(Get, { Url = Url, Method = "GET" })
        if Ok and type(Response) == "table" then
            Result.Status, Result.Body = Response.StatusCode, Response.Body
        else
            Result.Error = "request: " .. tostring(Response)
        end
    end
    if not Result.Body then
        local Ok, Body = pcall(game.HttpGet, game, Url)
        if Ok then
            Result.Body = Body
            Result.Via = "HttpGet"
        else
            Result.Error = (Result.Error and Result.Error .. " | " or "") .. "HttpGet: " .. tostring(Body)
        end
    end
    Result.Ms = math.floor((os.clock() - Started) * 1000)
    return Result
end

local Bases = {
    { "raw", "https://raw.githubusercontent.com/%s/%s/%s" },
    { "gcore", "https://gcore.jsdelivr.net/gh/%s@%s/%s" },
    { "fastly", "https://fastly.jsdelivr.net/gh/%s@%s/%s" },
    { "jsdelivr", "https://cdn.jsdelivr.net/gh/%s@%s/%s" },
    { "testingcf", "https://testingcf.jsdelivr.net/gh/%s@%s/%s" },
}

local Remote, Reachable
for _, Entry in Bases do
    local Url = Entry[2]:format(Repo, Branch, Folder .. "version.txt")
    local Result = Fetch(Url)
    local Body = Result.Body and Result.Body:gsub("%s+", "")
    Log(("%-9s version.txt: %s %s ms %s"):format(Entry[1], Body and Body or "FAILED", Result.Ms, Result.Error and ("(" .. Result.Error:sub(1, 90) .. ")") or ""))
    if Body and Body:match("^%x+%-%d+$") and not Remote then
        Remote, Reachable = Body, Entry
    end
end

if not Remote then
    Log("RESULT: no mirror answered. The device has no route to GitHub or the CDNs.")
    return
end

local Hash, Bytes = Remote:match("^(%x+)%-(%d+)$")
Log(("loading Library.%s.lua from %s (%s bytes expected)"):format(Hash, Reachable[1], Bytes))
local Download = Fetch(Reachable[2]:format(Repo, Branch, Folder .. "Library." .. Hash .. ".lua"))
if not Download.Body or (Download.Status and Download.Status >= 400) then
    Log(("pinned file unavailable (status %s), trying Library.lua"):format(tostring(Download.Status)))
    Download = Fetch(Reachable[2]:format(Repo, Branch, Folder .. "Library.lua"))
end
if not Download.Body or (Download.Status and Download.Status >= 400) then
    Log("RESULT: download failed " .. tostring(Download.Error) .. " status " .. tostring(Download.Status))
    return
end
local Source = Download.Body:gsub("\r\n", "\n")
Log(("downloaded %d bytes in %d ms (status %s)"):format(#Source, Download.Ms, tostring(Download.Status)))
if math.abs(#Source - tonumber(Bytes)) > 16 then
    Log("WARNING: size differs from version.txt, the response was changed on the way")
end

local Compile = os.clock()
local Chunk, CompileError = loadstring(Source)
Log(("compile: %s in %d ms %s"):format(Chunk and "ok" or "FAILED", (os.clock() - Compile) * 1000, CompileError and tostring(CompileError):sub(1, 200) or ""))
if not Chunk then
    return
end

local Env = getgenv and getgenv() or _G
local Previous = Env.Library
Env.Library = nil
local Run = os.clock()
local Ok, Library = xpcall(Chunk, function(Err) return tostring(Err) .. "\n" .. debug.traceback() end)
Log(("run: %s in %d ms"):format(Ok and "ok" or "FAILED", (os.clock() - Run) * 1000))
if not Ok then
    Log(tostring(Library):sub(1, 900))
    Env.Library = Previous
    return
end

local Steps = {}
local function Step(Label, Callback)
    local Passed, Err = xpcall(Callback, function(Message) return tostring(Message) .. "\n" .. debug.traceback() end)
    Log(("%s: %s"):format(Label, Passed and "ok" or ("FAILED " .. tostring(Err):sub(1, 500))))
    return Passed
end

local Window
Step("create window", function()
    Window = Library:CreateWindow({ Title = "Diagnostic", Size = UDim2.fromOffset(420, 280), Center = true, AutoShow = true })
end)
Step("tabs and controls", function()
    local Tab = Window:AddTab("Main", "house")
    local Sub = Tab:AddSubTab("Sub", "cog")
    local Box = Sub:AddLeftGroupbox("Box", "house")
    Box:AddToggle("d_t", { Text = "Toggle" })
    Box:AddSlider("d_s", { Text = "Slider", Min = 0, Max = 10, Default = 3, Rounding = 0 })
    Box:AddDropdown("d_d", { Text = "Drop", Values = { "a", "b" }, Default = 1 })
    Box:AddInput("d_i", { Text = "Input" })
end)
Step("notification", function() Library:Notify({ Title = "MonHub", Description = "Diagnostic notification", Time = 3 }) end)
Step("addons", function()
    assert(Library.Addons.ThemeManager and Library.Addons.SaveManager, "bundled addons missing")
end)
Log(("font: %s | mobile: %s | density: %s"):format(tostring(Library.CurrentFontName), tostring(Library.IsMobile), tostring(Library.ActiveDensity)))
task.wait(2)
pcall(function() Library:Unload() end)
Env.Library = Previous
Log("RESULT: finished. Send a screenshot of this panel, or the file MonHub_diagnose.txt from the executor workspace.")
