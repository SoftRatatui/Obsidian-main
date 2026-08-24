assert(type(loadstring) == "function", "Experimental.lua requires loadstring support.")

local REPOSITORY = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"
local RELEASE_VERSION = "0.0.1-release-6"
local Environment = getfenv()
local NativeReadFile = type(Environment) == "table" and rawget(Environment, "readfile") or nil
local NativeIsFile = type(Environment) == "table" and rawget(Environment, "isfile") or nil
local Syn = type(Environment) == "table" and rawget(Environment, "syn") or nil
local NativeRequest = type(Environment) == "table" and (rawget(Environment, "request") or rawget(Environment, "http_request")) or nil
if type(NativeRequest) ~= "function" and type(Syn) == "table" then
    NativeRequest = rawget(Syn, "request")
end

local function Fetch(Path)
    if type(NativeReadFile) == "function" and type(NativeIsFile) == "function" and NativeIsFile(Path) then
        local Success, Source = pcall(NativeReadFile, Path)
        if Success and type(Source) == "string" and #Source > 0 then
            return Source
        end
    end

    local URL = REPOSITORY .. Path .. "?monhub=" .. RELEASE_VERSION
    if type(NativeRequest) == "function" then
        local Success, Response = pcall(NativeRequest, {
            Url = URL,
            Method = "GET",
        })
        if Success then
            local Body = typeof(Response) == "table" and (Response.Body or Response.body) or Response
            local Status = typeof(Response) == "table" and (Response.StatusCode or Response.Status) or nil
            if type(Body) == "string" and #Body > 0 and (type(Status) ~= "number" or Status >= 200 and Status < 300) then
                return Body
            end
        end
    end

    local Success, Source = pcall(game.HttpGet, game, URL)
    assert(Success and type(Source) == "string" and #Source > 0, "Failed to load " .. Path)
    return Source
end

local function Load(Path)
    local Chunk, CompileError = loadstring(Fetch(Path))
    assert(Chunk, tostring(CompileError))
    return Chunk()
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
    Build = Library.ExperimentalBuild,
    CharacterTrail = CharacterTrail,
    TextureGallery = TextureGallery,
    VisualPreview = VisualPreview,
    DrawingESPPreview = DrawingESPPreview,
    FixedR6Preview = FixedR6Preview,
    InterBold = InterBold,
    FontError = FontError,
}

function Library:CreateTextureGallery(Groupbox, Idx, Info)
    if type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function" then
        return TextureGallery.CreateEmbedded(Library, Groupbox, Idx, Info)
    end
    return TextureGallery.Create(Library, Info or Idx or Groupbox)
end

function Library:CreateFixedR6Preview(Tab, Info)
    return FixedR6Preview.Create(Library, VisualPreview, DrawingESPPreview, Tab, Info)
end

return Library
