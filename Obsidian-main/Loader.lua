local MonHubConfig = {
    Name = "Library",
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
    if type(Config) == "string" then
        Config = { Name = Config }
    end
    if Config and Config ~= MonHubConfig then
        setmetatable(Config, { __index = MonHubConfig })
    end
    Config = Config or MonHubConfig
    local Name = Config.Name or "Library"
    local VersionFile = Name == "Library" and "version.txt" or Name .. ".version.txt"
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

    local OriginHost = "raw.githubusercontent.com"

    local function Race(Name, Accept, Budget, Spacing, PreferOrigin)
        Spacing = Spacing or Stagger
        local State = { Running = 0 }
        local Deadline = os.clock() + Budget
        local OriginRunning = false
        local SettleAt = 0

        local function Done()
            if State.Final then
                return true
            end
            return State.Body ~= nil and (not OriginRunning or os.clock() >= SettleAt)
        end

        local function Launch(Url)
            local Host = string.match(Url, "//([^/]+)")
            local IsOrigin = Host == OriginHost
            State.Running += 1
            if IsOrigin then
                OriginRunning = true
            end
            task.spawn(function()
                local Raw = Get(Url)
                State.Running -= 1
                if IsOrigin then
                    OriginRunning = false
                end
                if not Raw or State.Final then
                    return
                end
                local Body, Chunk = Accept(Raw)
                if not Body then
                    return
                end
                if IsOrigin or not PreferOrigin then
                    State.Final = true
                    State.Body, State.Chunk, State.Host = Body, Chunk, Host
                elseif not State.Body then
                    State.Body, State.Chunk, State.Host = Body, Chunk, Host
                    SettleAt = os.clock() + 0.5
                end
            end)
        end

        local List = Urls(Name, true)
        if PreferOrigin then
            for Index, Url in List do
                if string.match(Url, "//([^/]+)") == OriginHost then
                    table.remove(List, Index)
                    Launch(Url)
                    break
                end
            end
        end
        for _, Url in List do
            Launch(Url)
            local Next = os.clock() + Spacing
            while not Done() and State.Running > 0 and os.clock() < Next and os.clock() < Deadline do
                task.wait()
            end
            if Done() or os.clock() >= Deadline then
                break
            end
        end
        while not Done() and State.Running > 0 and os.clock() < Deadline do
            task.wait()
        end
        if State.Host then
            Preferred = State.Host
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

    local function Run(Chunk, Source, Version)
        local Ok, Result = pcall(Chunk)
        if Ok and type(Result) == "table" then
            pcall(function()
                Result.BuildVersion = Version or Source
            end)
            return Result
        end
        table.insert(Notes, Source .. ": " .. (Ok and "did not return the library" or tostring(Result)))
        return nil
    end

    local function Store(Body, Version)
        WriteFile(Cache .. Name .. ".lua", Body)
        WriteFile(Cache .. Name .. ".version", Version or "")
    end

    local function RememberMirror()
        if Preferred and Preferred ~= ReadFile(Cache .. Name .. ".mirror") then
            WriteFile(Cache .. Name .. ".mirror", Preferred)
        end
    end

    local function Download(Version, Budget)
        local Hash, Bytes = string.match(Version or "", "^(%x+)%-(%d+)$")
        Bytes = tonumber(Bytes)
        local Body, Chunk
        if Hash then
            Body, Chunk = Race(Name .. "." .. Hash .. ".lua", LibraryCheck(Bytes), Budget, 3)
        end
        if not Body then
            Body, Chunk = Race(Name .. ".lua", LibraryCheck(Bytes), Budget, 3)
        end
        return Body, Chunk
    end

    local function Refresh()
        task.spawn(function()
            local Version = Race(VersionFile, VersionCheck, 20, nil, true)
            if not Version or Version == ReadFile(Cache .. Name .. ".version") then
                return
            end
            local Body = Download(Version, 120)
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

    Preferred = ReadFile(Cache .. Name .. ".mirror")

    local Remote = Race(VersionFile, VersionCheck, math.min(3, Timeout), nil, true)
    RememberMirror()
    local Bytes = Remote and tonumber(string.match(Remote, "%-(%d+)$"))
    local Cached = ReadFile(Cache .. Name .. ".version")

    if Remote and Cached == Remote then
        local Body = ReadFile(Cache .. Name .. ".lua")
        local Chunk = Body and SizeMatches(#Body, Bytes) and loadstring(Body)
        local Library = Chunk and Run(Chunk, "cached copy", Remote)
        if Library then
            return Library
        end
    end

    local Saved = ReadFile(Cache .. Name .. ".lua")
    local HasFallback = Saved ~= nil or Config.Embedded ~= nil
    if not HasFallback then
        Toast("Downloading the interface for the first time. On a slow connection this can take a minute.", 8)
    end
    local Body, Chunk = Download(Remote, HasFallback and Remaining() or Patient)
    if Body then
        local Library = Run(Chunk, "download", Remote)
        if Library then
            Store(Body, Remote)
            RememberMirror()
            return Library
        end
    end

    local SavedChunk = Saved and loadstring(Saved)
    local Library = SavedChunk and Run(SavedChunk, "cached copy", ReadFile(Cache .. Name .. ".version"))
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

    local Message = Name .. " could not be loaded: " .. (#Notes > 0 and table.concat(Notes, "; ") or "no mirror answered and no copy is stored")
    Toast("Could not download the interface. Check the connection and run the script again.", 12)
    error(Message, 0)
end
