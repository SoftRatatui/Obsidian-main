-- MonHub beta loader, written by tools/build.py --beta as beta/Library.lua.
--
-- The library itself is beta/Library.<version>.lua. Every client on a PC shares one
-- copy of it in the workspace: the first client that needs a version downloads it while
-- the others wait for that file, so twenty accounts started together fetch it once. A
-- copy is used only when its size is exactly the size of this build, so a file another
-- client is still writing, or a cut off download, is never run.
--
-- A hub runs this file and gets the library back, as it did with the full bundle. A table
-- passed as the first argument can replace Get (a function from url to body) and Cache.
local Version = "__VERSION__"
local Size = __SIZE__
local Repo = "SoftRatatui/Obsidian-main"
local Branch = "MonHub-Rewrite-Project"
local Folder = "Obsidian-main/beta/"

local Options = ...
if type(Options) ~= "table" then
    Options = {}
end

local Genv = (getgenv and getgenv()) or shared
local Cache = Options.Cache or "MonHub/cache_rewrite/core/"
local Name = "Library." .. Version .. ".lua"
local Path = Cache .. Name
local LockPath = Cache .. "Library." .. Version .. ".lock"
local Files = readfile and writefile and isfile and isfolder and makefolder
local Request = Genv.MonHub_Req or request or http_request or (syn and syn.request) or (http and http.request)
-- A download nobody has refreshed for this long belongs to a client that is gone.
local Stale = 30
local Me = game:GetService("HttpService"):GenerateGUID(false)

-- A hub that watches its own heartbeat (MonHub_YBA_Beat) would take a long wait for a
-- dead start and run a second copy, so the beat goes on while this loader waits.
local function KeepAlive()
    if type(Genv.MonHub_YBA_Beat) == "number" then
        Genv.MonHub_YBA_Beat = os.clock()
    end
end

local function Read(File)
    if not Files then
        return nil
    end
    local Ok, Text = pcall(function()
        if isfile(File) then
            return readfile(File)
        end
        return nil
    end)
    if Ok and type(Text) == "string" then
        return Text
    end
    return nil
end

local function Write(File, Text)
    if not Files then
        return false
    end
    return (pcall(function()
        local Built = ""
        for Part in string.gmatch(string.match(File, "^(.*)/[^/]*$") or "", "[^/]+") do
            Built = if Built == "" then Part else Built .. "/" .. Part
            if not isfolder(Built) then
                makefolder(Built)
            end
        end
        writefile(File, Text)
    end))
end

local function Remove(File)
    if delfile then
        pcall(function()
            if isfile(File) then
                delfile(File)
            end
        end)
    end
end

local function Fetch(Url)
    if Options.Get then
        local Ok, Body = pcall(Options.Get, Url)
        return if Ok and type(Body) == "string" then Body else nil
    end
    if Request then
        local Ok, Response = pcall(Request, { Url = Url, Method = "GET" })
        if Ok and type(Response) == "table" then
            local Code = tonumber(Response.StatusCode)
            if type(Response.Body) == "string" and (Code == nil or (Code >= 200 and Code < 300)) then
                return Response.Body
            end
        end
    end
    local Get = Genv.MonHub_Get or function(Address)
        return game:HttpGet(Address)
    end
    local Ok, Body = pcall(Get, Url)
    return if Ok and type(Body) == "string" then Body else nil
end

-- One GET, given up after Limit seconds so a mirror that never answers does not hold the
-- start; the request itself finishes in the background.
local function Get(Url, Limit)
    local Done, Body = false, nil
    task.spawn(function()
        Body = Fetch(Url)
        Done = true
    end)
    local Deadline = os.clock() + Limit
    while not Done and os.clock() < Deadline do
        KeepAlive()
        task.wait(0.05)
    end
    return Body
end

-- The pinned file first; Library.core.lua is always the newest build, and matches this
-- one until a newer build is pushed.
local function Mirrors()
    local Pinned = Folder .. Name
    local Raw = "https://raw.githubusercontent.com/" .. Repo .. "/" .. Branch .. "/"
    return {
        Raw .. Pinned,
        Raw .. Folder .. "Library.core.lua?v=" .. Version,
        "https://cdn.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. Pinned,
        "https://fastly.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. Pinned,
        "https://raw.githack.com/" .. Repo .. "/" .. Branch .. "/" .. Pinned,
    }
end

-- When this build is gone from every mirror (newer builds replaced it), the newest build
-- is run instead. It is not kept: the next start gets a loader for that build.
local function Newest()
    local Body = Get("https://raw.githubusercontent.com/" .. Repo .. "/" .. Branch .. "/" .. Folder .. "Library.core.lua?t=" .. os.time(), 20)
    if type(Body) ~= "string" or #Body < 100000 then
        return nil
    end
    local Text = string.gsub(Body, "\r\n", "\n")
    return loadstring(Text, "=MonHub")
end

-- The mirrors one after another, never all at once. Before each one the lock is stamped
-- again, so clients waiting on this download know it is still going.
local function Download(Stamp)
    for _, Url in Mirrors() do
        if Stamp then
            Stamp()
        end
        local Body = Get(Url, 20)
        if Body then
            Body = string.gsub(Body, "\r\n", "\n")
            if #Body == Size then
                return Body
            end
        end
    end
    return nil
end

local function Compile(Text)
    if type(Text) ~= "string" or #Text ~= Size then
        return nil
    end
    return loadstring(Text, "=MonHub")
end

local function Holder()
    local Text = Read(LockPath)
    if not Text then
        return nil
    end
    local Id, Stamp = string.match(Text, "^(%S+) (%d+)")
    Stamp = tonumber(Stamp)
    if Id and Stamp and math.abs(os.time() - Stamp) < Stale then
        return Id
    end
    return nil
end

local function StampLock()
    Write(LockPath, Me .. " " .. os.time())
end

-- Takes the download for this client unless a live one holds it. Two clients that write
-- the lock at the same moment both read it back after a short wait; the last write wins.
local function Claim()
    local Current = Holder()
    if Current and Current ~= Me then
        return false
    end
    StampLock()
    task.wait(0.15)
    return Holder() == Me
end

-- Copies of older versions go once a newer one is in place, along with their dead locks.
local function Tidy()
    if not (listfiles and delfile) then
        return
    end
    pcall(function()
        for _, File in listfiles(Cache) do
            local Base = string.match(File, "([^/\\]+)$") or ""
            if Base ~= Name and string.match(Base, "^Library%.%x+%.lua$") then
                delfile(File)
            elseif string.match(Base, "^Library%.%x+%.lock$") and Base ~= "Library." .. Version .. ".lock" then
                local Text = readfile(File)
                local Stamp = tonumber(string.match(Text or "", "^%S+ (%d+)"))
                if not Stamp or math.abs(os.time() - Stamp) >= Stale then
                    delfile(File)
                end
            end
        end
    end)
end

local function Obtain()
    local Chunk = Compile(Read(Path))
    if Chunk then
        return Chunk
    end
    if not Files then
        return Compile(Download(nil)) or Newest()
    end
    local Deadline = os.clock() + 90
    while os.clock() < Deadline do
        Chunk = Compile(Read(Path))
        if Chunk then
            return Chunk
        end
        if Claim() then
            local Body = Download(StampLock)
            Chunk = Compile(Body)
            if Chunk then
                Write(Path, Body)
            end
            Remove(LockPath)
            if Chunk then
                Tidy()
                return Chunk
            end
            return Newest()
        end
        KeepAlive()
        task.wait(0.25)
    end
    -- The client that took the download never finished it: this one gets its own copy.
    return Compile(Download(nil)) or Newest()
end

local Chunk = Obtain()
if not Chunk then
    error("MonHub could not download its library (" .. Name .. "). Check the connection and run the script again.", 0)
end
return Chunk()
