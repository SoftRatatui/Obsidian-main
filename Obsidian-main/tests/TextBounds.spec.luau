return function(CreateTextBounds, CreateFontLoader)
    local Library, State = CreateTextBounds()
    local Face = Library.Scheme.Font
    local X, Y = Library:GetTextBounds("Test", Face, 14, 200)
    assert(X == 40 and Y == 18 and State.Calls == 1 and State.Destroyed == 1)
    Library:GetTextBounds("Test", Face, 14, 200)
    assert(State.Calls == 1, "Successful measurement was not cached")

    Library:ClearTextBoundsCache()
    State.Fail = true
    X, Y = Library:GetTextBounds("<b>Текст</b><br/>😀", Face, 14, 200)
    assert(X == 55 and Y == 20 and State.Destroyed == 2)
    assert(State.PlainText == "Текст\n😀")
    Library:GetTextBounds("Another label", Face, 14, 200)
    assert(State.Calls == 2, "Failed font retried immediately for another label")
    State.Fail = false
    State.Time = 6
    X, Y = Library:GetTextBounds("<b>Текст</b><br/>😀", Face, 14, 200)
    assert(X == 40 and Y == 18 and State.Calls == 3, "Fallback cache prevented recovery")

    Library:ClearTextBoundsCache()
    State.Fail, State.FailFallback = true, true
    X, Y = Library:GetTextBounds("😀\nЯ", Face, 10, 200)
    assert(X == 10 and Y == 28, "Emergency layout counts UTF-8 bytes instead of characters")
    X, Y = Library:GetTextBounds("Text", nil, 0 / 0, -10)
    assert(X >= 0 and Y > 0 and Y < math.huge)
    Library:ClearTextBoundsCache()
    State.FailCreate = true
    X, Y = Library:GetTextBounds("No params", Face, 14, 200)
    assert(X > 0 and Y > 0, "Unavailable params API interrupted layout")
    print("PASS mobile text measurement failure, cleanup, fallback, cooldown, recovery and UTF-8 layout")

    local Fonts, Files = CreateFontLoader()
    local Face, ErrorMessage = Fonts:LoadCustomFont("Inter", "https://example.invalid/font.ttf")
    assert(Face and not ErrorMessage and Files.Destroyed == 1)
    Files.FontError = true
    Face, ErrorMessage = Fonts:LoadCustomFont("Inter", "https://example.invalid/font.ttf")
    assert(not Face and ErrorMessage and Files.Destroyed == 2, "Unreadable font was accepted or leaked params")
    Files.FontError = false
    for _, Failure in { "FolderError", "FileError", "JSONError" } do
        Files[Failure] = true
        local OK, Result, Reason = pcall(Fonts.LoadCustomFont, Fonts, "Inter", "https://example.invalid/font.ttf")
        assert(OK and Result == nil and Reason, "Font bootstrap propagated " .. Failure)
        Files[Failure] = false
    end
    print("PASS custom font readability and filesystem/metadata bootstrap failures")
end
