local MonHubConfig = {
    Repo = "SoftRatatui/Obsidian-main",
    Branch = "main",
    Folder = "Obsidian-main/dist/",
    Cache = "MonHub/cache/",
    Timeout = 5,
    Stagger = 1,
    PatientTimeout = 60,
    Extra = {},
    Embedded = nil,
    Get = nil,
}

local function MonHubLoad(Config)
    Config = Config or MonHubConfig
    local Started = os.clock()
    local Timeout = Config.Timeout or 5
    local Stagger = Config.Stagger or 1
    local Patient = Config.PatientTimeout or 60
    local Cache = Config.Cache or "MonHub/cache/"
    local Request = (syn and syn.request) or http_request or request
    local Notes = {}

    local function Get(Url)
        if Config.Get then
            local Ok, Body = pcall(Config.Get, Url)
            return Ok and type(Body) == "string" and #Body > 0 and Body or nil
        end
        if Request then
            local Ok, Response = pcall(Request, { Url = Url, Method = "GET" })
            if Ok and type(Response) == "table" then
                local Body, Status = Response.Body, Response.StatusCode
                if type(Body) == "string" and #Body > 0 and (Status == nil or (Status >= 200 and Status < 300)) then
                    return Body
                end
            end
        end
        local Ok, Body = pcall(game.HttpGet, game, Url)
        if Ok and type(Body) == "string" and #Body > 0 then
            return Body
        end
        return nil
    end

    local Preferred

    local function Urls(Name, Fresh)
        local Repo, Branch = Config.Repo, Config.Branch
        local Path = Config.Folder .. Name
        local List = {
            "https://raw.githubusercontent.com/" .. Repo .. "/" .. Branch .. "/" .. Path .. (Fresh and ("?monhub=" .. os.time()) or ""),
            "https://gcore.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. Path,
            "https://fastly.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. Path,
            "https://cdn.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. Path,
            "https://testingcf.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. Path,
            "https://raw.githack.com/" .. Repo .. "/" .. Branch .. "/" .. Path,
            "https://cdn.statically.io/gh/" .. Repo .. "/" .. Branch .. "/" .. Path,
        }
        for _, Base in Config.Extra or {} do
            table.insert(List, Base .. Name)
        end
        if Preferred then
            for Index, Url in List do
                if string.match(Url, "//([^/]+)") == Preferred then
                    table.remove(List, Index)
                    table.insert(List, 1, Url)
                    break
                end
            end
        end
        return List
    end

    local function Race(Name, Accept, Budget, Spacing)
        Spacing = Spacing or Stagger
        local State = { Running = 0 }
        local Deadline = os.clock() + Budget
        for _, Url in Urls(Name, true) do
            State.Running += 1
            task.spawn(function()
                local Raw = Get(Url)
                State.Running -= 1
                if Raw and not State.Body then
                    local Body, Chunk = Accept(Raw)
                    if Body and not State.Body then
                        State.Body, State.Chunk = Body, Chunk
                        Preferred = string.match(Url, "//([^/]+)")
                    end
                end
            end)
            local Next = os.clock() + Spacing
            while not State.Body and State.Running > 0 and os.clock() < Next and os.clock() < Deadline do
                task.wait()
            end
            if State.Body or os.clock() >= Deadline then
                break
            end
        end
        while not State.Body and State.Running > 0 and os.clock() < Deadline do
            task.wait()
        end
        return State.Body, State.Chunk
    end

    local function ReadFile(Path)
        if not (isfile and readfile) then
            return nil
        end
        local Ok, Data = pcall(function()
            if isfile(Path) then
                return readfile(Path)
            end
        end)
        return Ok and type(Data) == "string" and #Data > 0 and Data or nil
    end

    local function WriteFile(Path, Data)
        if not (writefile and isfolder and makefolder) then
            return false
        end
        return (pcall(function()
            local Folder = ""
            for Segment in string.gmatch(string.match(Path, "^(.*)/[^/]*$") or "", "[^/]+") do
                Folder = Folder == "" and Segment or Folder .. "/" .. Segment
                if not isfolder(Folder) then
                    makefolder(Folder)
                end
            end
            writefile(Path, Data)
        end))
    end

    local function VersionCheck(Raw)
        local Clean = string.gsub(Raw, "%s+", "")
        if string.match(Clean, "^%x+%-%d+$") then
            return Clean
        end
        return nil
    end

    local function SizeMatches(Length, Bytes)
        return Bytes == nil or math.abs(Length - Bytes) <= 16
    end

    local function LibraryCheck(Bytes)
        return function(Raw)
            local Body = string.gsub(Raw, "\r\n", "\n")
            if #Body < 4096 or not SizeMatches(#Body, Bytes) then
                return nil
            end
            local Chunk = loadstring(Body)
            if Chunk then
                return Body, Chunk
            end
            return nil
        end
    end

    local function Run(Chunk, Source)
        local Ok, Result = pcall(Chunk)
        if Ok and type(Result) == "table" then
            return Result
        end
        table.insert(Notes, Source .. ": " .. (Ok and "did not return the library" or tostring(Result)))
        return nil
    end

    local function Store(Body, Version)
        WriteFile(Cache .. "Library.lua", Body)
        WriteFile(Cache .. "Library.version", Version or "")
    end

    local function RememberMirror()
        if Preferred and Preferred ~= ReadFile(Cache .. "Library.mirror") then
            WriteFile(Cache .. "Library.mirror", Preferred)
        end
    end

    local function Refresh()
        task.spawn(function()
            local Version = Race("version.txt", VersionCheck, 20)
            if not Version or Version == ReadFile(Cache .. "Library.version") then
                return
            end
            local Bytes = tonumber(string.match(Version, "%-(%d+)$"))
            local Body = Race("Library.lua", LibraryCheck(Bytes), 120)
            if Body then
                Store(Body, Version)
            end
        end)
    end

    local function Toast(Text, Duration)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "MonHub",
                Text = Text,
                Duration = Duration,
            })
        end)
    end

    local function Remaining()
        return math.max(0, Timeout - (os.clock() - Started))
    end

    Preferred = ReadFile(Cache .. "Library.mirror")

    local Remote = Race("version.txt", VersionCheck, math.min(3, Timeout))
    RememberMirror()
    local Bytes = Remote and tonumber(string.match(Remote, "%-(%d+)$"))
    local Cached = ReadFile(Cache .. "Library.version")

    if Remote and Cached == Remote then
        local Body = ReadFile(Cache .. "Library.lua")
        local Chunk = Body and SizeMatches(#Body, Bytes) and loadstring(Body)
        local Library = Chunk and Run(Chunk, "cached copy")
        if Library then
            return Library
        end
    end

    local Saved = ReadFile(Cache .. "Library.lua")
    local HasFallback = Saved ~= nil or Config.Embedded ~= nil
    if not HasFallback then
        Toast("Downloading the interface for the first time. On a slow connection this can take a minute.", 8)
    end
    local Body, Chunk = Race("Library.lua", LibraryCheck(Bytes), HasFallback and Remaining() or Patient, 3)
    if Body then
        local Library = Run(Chunk, "download")
        if Library then
            Store(Body, Remote)
            RememberMirror()
            return Library
        end
    end

    local SavedChunk = Saved and loadstring(Saved)
    local Library = SavedChunk and Run(SavedChunk, "cached copy")
    if Library then
        Refresh()
        return Library
    end

    local Embedded = Config.Embedded and loadstring(Config.Embedded)
    Library = Embedded and Run(Embedded, "embedded copy")
    if Library then
        Refresh()
        return Library
    end

    local Message = "MonHub could not be loaded: " .. (#Notes > 0 and table.concat(Notes, "; ") or "no mirror answered and no copy is stored")
    Toast("Could not download the interface. Check the connection and run the script again.", 12)
    error(Message, 0)
end
