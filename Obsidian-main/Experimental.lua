assert(type(loadstring) == "function", "Experimental.lua requires loadstring support.")

local REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local RELEASE_VERSION = "0.0.1-release-6"
local EXPERIMENTAL_BUILD = "0.0.1-experimental-2"
local Environment = getfenv()
local NativeReadFile = type(Environment) == "table" and rawget(Environment, "readfile") or nil
local NativeIsFile = type(Environment) == "table" and rawget(Environment, "isfile") or nil
local Syn = type(Environment) == "table" and rawget(Environment, "syn") or nil
local NativeRequest = type(Environment) == "table" and (rawget(Environment, "request") or rawget(Environment, "http_request")) or nil
if type(NativeRequest) ~= "function" and type(Syn) == "table" then
    NativeRequest = rawget(Syn, "request")
end

local function NormalizeSource(Source)
    if type(Source) ~= "string" then
        return nil, "response is not text"
    end
    if string.sub(Source, 1, 3) == "\239\187\191" then
        Source = string.sub(Source, 4)
    end
    if not string.find(Source, "%S") then
        return nil, "response is empty"
    end
    local Head = string.lower(string.sub(Source, 1, 192)):match("^%s*(.*)") or ""
    if string.sub(Head, 1, 1) == "<"
        or string.sub(Head, 1, 1) == "{"
        or string.find(Head, "404", 1, true) == 1
        or string.find(Head, "not found", 1, true) == 1
        or string.find(Head, "bad gateway", 1, true)
        or string.find(Head, "access denied", 1, true)
        or string.find(Head, "rate limit", 1, true)
    then
        return nil, "server returned a non-Luau response"
    end
    return Source
end

local function Compile(Path, Source, Origin)
    local Normalized, ValidationError = NormalizeSource(Source)
    if not Normalized then
        return nil, Origin .. ": " .. ValidationError
    end
    local Chunk, CompileError = loadstring(Normalized)
    if not Chunk then
        return nil, Origin .. ": " .. tostring(CompileError)
    end
    return Chunk
end

local function Execute(Path, Chunk)
    local Success, Result = pcall(Chunk)
    if not Success then
        error("Failed to execute " .. Path .. ": " .. tostring(Result), 2)
    end
    return Result
end

local function Load(Path)
    local Attempts = {}
    if type(NativeReadFile) == "function" and type(NativeIsFile) == "function" then
        local ExistsSuccess, Exists = pcall(NativeIsFile, Path)
        if ExistsSuccess and Exists then
            local ReadSuccess, Source = pcall(NativeReadFile, Path)
            if ReadSuccess then
                local Chunk, CompileError = Compile(Path, Source, "local file")
                if Chunk then
                    return Execute(Path, Chunk)
                end
                table.insert(Attempts, CompileError)
            else
                table.insert(Attempts, "local file: " .. tostring(Source))
            end
        end
    end

    local URL = REPOSITORY .. Path .. "?monhub=" .. EXPERIMENTAL_BUILD
    local HttpSuccess, HttpSource = pcall(game.HttpGet, game, URL)
    if HttpSuccess then
        local Chunk, CompileError = Compile(Path, HttpSource, "game.HttpGet")
        if Chunk then
            return Execute(Path, Chunk)
        end
        table.insert(Attempts, CompileError)
    else
        table.insert(Attempts, "game.HttpGet: " .. tostring(HttpSource))
    end

    if type(NativeRequest) == "function" then
        local RequestSuccess, Response = pcall(NativeRequest, {
            Url = URL,
            Method = "GET",
        })
        if RequestSuccess then
            local Body = typeof(Response) == "table" and (Response.Body or Response.body) or Response
            local Status = typeof(Response) == "table" and (Response.StatusCode or Response.Status) or nil
            if type(Status) == "number" and (Status < 200 or Status >= 300) then
                table.insert(Attempts, "request: HTTP " .. tostring(Status))
            else
                local Chunk, CompileError = Compile(Path, Body, "request")
                if Chunk then
                    return Execute(Path, Chunk)
                end
                table.insert(Attempts, CompileError)
            end
        else
            table.insert(Attempts, "request: " .. tostring(Response))
        end
    end

    error("Failed to load " .. Path .. " | " .. table.concat(Attempts, " | "), 2)
end

local Library = Load("ExperimentalLibrary.lua")
local CharacterTrail = Load("addons/CharacterTrail.lua")
local TextureGallery = Load("addons/TextureGallery.lua")
local VisualPreview = Load("addons/VisualPreview.lua")
local DrawingESPPreview = Load("addons/DrawingESPPreview.lua")
local FixedR6Preview = Load("addons/FixedR6Preview.lua")
local InterBold, FontError = Library:LoadCustomFont(
    "MonHubInterBold",
    REPOSITORY .. "assets/Inter-Bold.ttf?monhub=" .. RELEASE_VERSION,
    700
)

if InterBold then
    Library:SetThemeFont(InterBold)
end

Library.ExperimentalMode = true
Library.Experimental = {
    ReleaseVersion = RELEASE_VERSION,
    Build = EXPERIMENTAL_BUILD,
    FullCoreAPI = true,
    CharacterTrail = CharacterTrail,
    TextureGallery = TextureGallery,
    VisualPreview = VisualPreview,
    DrawingESPPreview = DrawingESPPreview,
    FixedR6Preview = FixedR6Preview,
    InterBold = InterBold,
    FontError = FontError,
}

function Library:CreateCharacterTrail(Info)
    return CharacterTrail.Create(Info)
end

function Library:CreateTextureGallery(Groupbox, Idx, Info)
    if type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function" then
        return TextureGallery.CreateEmbedded(Library, Groupbox, Idx, Info)
    end
    return TextureGallery.Create(Library, Info or Idx or Groupbox)
end

function Library:CreateFixedR6Preview(Tab, Info)
    return FixedR6Preview.Create(Library, VisualPreview, DrawingESPPreview, Tab, Info)
end

function Library:CreateVisualPreview(Tab, Info)
    return VisualPreview.Create(Library, Tab, Info)
end

function Library:CreateEmbeddedVisualPreview(Groupbox, Idx, Info)
    if type(Idx) == "table" and Info == nil then
        Info = Idx
        Idx = nil
    end
    local Options = table.clone(Info or {})
    Options.Idx = Idx or Options.Idx
    return VisualPreview.CreateEmbedded(Library, Groupbox, Options)
end

function Library:CreateDrawingESPPreview(Info)
    return DrawingESPPreview.Create(Info)
end

return Library
