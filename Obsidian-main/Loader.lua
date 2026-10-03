local MonHubSource = {
    Repo = "SoftRatatui/Obsidian-main",
    Branch = "main",
    Folder = "Obsidian-main/dist/",
}

local function MonHubLoad(Path)
    local Repo, Branch, File = MonHubSource.Repo, MonHubSource.Branch, MonHubSource.Folder .. Path
    local Mirrors = {
        "https://raw.githubusercontent.com/" .. Repo .. "/" .. Branch .. "/" .. File,
        "https://gcore.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. File,
        "https://fastly.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. File,
        "https://cdn.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. File,
        "https://testingcf.jsdelivr.net/gh/" .. Repo .. "@" .. Branch .. "/" .. File,
        "https://raw.githack.com/" .. Repo .. "/" .. Branch .. "/" .. File,
        "https://cdn.statically.io/gh/" .. Repo .. "/" .. Branch .. "/" .. File,
    }
    local CachePath = "MonHub/cache/" .. string.gsub(Path, "[/\\]", "_")
    local Request = (syn and syn.request) or http_request or request

    local function Get(Url)
        if Request then
            local Ok, Response = pcall(Request, { Url = Url, Method = "GET" })
            if Ok and type(Response) == "table" and type(Response.Body) == "string"
                and (Response.StatusCode == nil or (Response.StatusCode >= 200 and Response.StatusCode < 300)) then
                return Response.Body
            end
        end
        local Ok, Body = pcall(game.HttpGet, game, Url)
        return Ok and Body or nil
    end

    local State = { Running = 0 }
    local function Try(Url)
        State.Running += 1
        task.spawn(function()
            local Body = Get(Url)
            State.Running -= 1
            if not State.Chunk and type(Body) == "string" and #Body > 512 then
                local Chunk = loadstring(Body)
                if Chunk and not State.Chunk then
                    State.Chunk, State.Body = Chunk, Body
                end
            end
        end)
    end

    local Deadline = os.clock() + 30
    for Index, Url in Mirrors do
        Try(Url)
        local Next = os.clock() + 2
        while not State.Chunk and State.Running > 0 and os.clock() < Next do
            task.wait()
        end
        if State.Chunk or os.clock() > Deadline then
            break
        end
    end
    while not State.Chunk and State.Running > 0 and os.clock() < Deadline do
        task.wait()
    end

    if State.Chunk then
        if writefile and isfolder and makefolder then
            pcall(function()
                if not isfolder("MonHub") then makefolder("MonHub") end
                if not isfolder("MonHub/cache") then makefolder("MonHub/cache") end
                writefile(CachePath, State.Body)
            end)
        end
        return State.Chunk()
    end

    if readfile and isfile then
        local Ok, Cached = pcall(function()
            return isfile(CachePath) and readfile(CachePath) or nil
        end)
        local Chunk = Ok and type(Cached) == "string" and loadstring(Cached)
        if Chunk then
            return Chunk()
        end
    end

    error("MonHub: " .. Path .. " could not be downloaded from any mirror", 0)
end

local Library = MonHubLoad("Library.lua")
local ThemeManager = Library.Addons.ThemeManager
local SaveManager = Library.Addons.SaveManager
