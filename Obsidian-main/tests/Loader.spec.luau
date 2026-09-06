return function(CreateLoader)
    local Responses, Requests = {}, {}
    local function Request(Info)
        table.insert(Requests, Info.Url)
        return { StatusCode = 200, Body = Responses.Body }
    end
    local Fallbacks = 0
    local function HttpGet(_, Url, Cached)
        Fallbacks += 1
        assert(Cached == false and Url:find("configs-2-", 1, true))
        if Responses.FallbackError then error("HTTP unavailable") end
        return Responses.Fallback
    end
    local TryModule = CreateLoader(Request, HttpGet)
    Responses.Body = "return { Ready = true }"
    local Module, ErrorMessage = TryModule("https://example.invalid/", "Library.lua")
    assert(Module and Module.Ready and not ErrorMessage and Fallbacks == 0)
    Responses.Body = "return 'not a module'"
    local Invalid, InvalidError = TryModule("https://example.invalid/", "Library.lua")
    assert(not Invalid and InvalidError:find("expected a module table", 1, true))
    Responses.Body = "<html>unexpected response</html>"
    local HTML, HTMLError = TryModule("https://example.invalid/", "Library.lua")
    assert(not HTML and HTMLError:find("not valid Lua", 1, true))
    Responses.Body = "error('module startup failed')"
    local Broken, RuntimeError = TryModule("https://example.invalid/", "Library.lua")
    assert(not Broken and RuntimeError:find("module execution failed", 1, true))
    Responses.Body = ""
    Responses.Fallback = "return { Fallback = true }"
    local Fallback = TryModule("https://example.invalid/", "Library.lua")
    assert(Fallback and Fallback.Fallback and Fallbacks == 1)
    Responses.FallbackError = true
    local Offline, OfflineError = TryModule("https://example.invalid/", "Library.lua")
    assert(not Offline and OfflineError:find("download failed", 1, true))
    print("PASS loader module validation, compilation errors, runtime errors and HTTP fallback")
end
