-- Layout regression suite. Encodes the geometry defects the owner has repeatedly
-- rejected builds over: fractional pixels, double-rounded corners, touch rows under
-- 44px and responsive columns that do not collapse. The real geometry, density and
-- two-column code is sliced out of Library.lua by check.ps1 and executed here; the
-- structural rules that cannot be instantiated in the offline mock are locked by
-- scanning the source. Everything discovers its inputs rather than hardcoding a
-- control list so new controls stay covered.
return function(BuildGeometry, BuildTabSides, Mock, Source)
    local function IsWhole(Value)
        return type(Value) == "number" and Value == math.floor(Value)
    end

    do
        local Library = BuildGeometry()

        -- Every size that reaches an instance flows through one of these primitives,
        -- so if any stops rounding, half-pixel geometry ships. Sweep fractional inputs
        -- and assert whole-pixel results and correct parity.
        for Outer = 0, 64 do
            for Inner = 0, 64 do
                local Center = Library:CenterOffset(Outer, Inner)
                assert(IsWhole(Center), "CenterOffset returned a fractional value")
                if (Outer - Inner) % 2 == 0 then
                    assert(Center * 2 + Inner == Outer, "CenterOffset does not center exactly on matched parity")
                end

                local Matched = Library:MatchParity(Outer, Inner)
                assert(IsWhole(Matched), "MatchParity returned a fractional value")
                assert((Outer - Matched) % 2 == 0, "MatchParity result cannot center on whole pixels")
                assert(Matched >= 0, "MatchParity returned a negative size")
            end
        end

        for _, Sample in { 0, 0.4, 0.5, 1.5, 12.49, 23.5, 44.5, -3.5 } do
            assert(IsWhole(Library:Snap(Sample)), "Snap returned a fractional value")
        end

        -- Icon glyphs must land on a clean divisor of the box so they center without a
        -- half-pixel, which is the sprite-sizing rule the owner enforces.
        for _, Box in { 24, 16, 12, 28, 32 } do
            local Glyph = Library:GlyphSize(Box)
            assert(IsWhole(Glyph), "GlyphSize returned a fractional value")
            assert(Glyph >= 1 and Glyph <= Box, "GlyphSize escaped its box")
            assert((Box - Glyph) % 2 == 0, "GlyphSize cannot center inside its box")
        end
        assert(Library:GlyphSize(24) == 20, "GlyphSize(24) drifted off the 24px sprite divisor")
        assert(Library:GlyphSize(16) == 12, "GlyphSize(16) drifted off the 16px sprite divisor")
        print("PASS geometry primitives round to whole pixels and centre on matched parity")
    end

    do
        -- Touch density is the mobile safety net: sized from the Grid tokens, every
        -- control inherits a >=44px row. Drive the real SetDensity/ApplyDensity path
        -- both explicitly and through Auto-on-mobile and read the numbers back through
        -- Metric, exactly as a control does.
        local function AssertTouch(Library)
            assert(Library:Metric("Row", 0) >= 44, "Touch density row is under 44px")
            assert(Library:Metric("Indicator", 0) >= 24, "Touch indicator is under 24px")
            assert(Library:Metric("Swatch", 0) >= 24, "Touch swatch is under 24px")
            assert(Library:Metric("Thumb", 0) >= 18, "Touch slider thumb is under 18px")
            assert(Library:Metric("TrackRow", 0) >= 20, "Touch track row is under 20px")
            assert(Library.Design.Shell.NavigationHeight >= 44, "Touch navigation height is under 44px")
            for Name, Value in Library.Design.Grid do
                assert(IsWhole(Value), "Touch grid token " .. Name .. " is fractional")
            end
        end

        local Explicit = BuildGeometry()
        Explicit.IsMobile = false
        Explicit:SetDensity("Touch")
        assert(Explicit:ResolveDensity() == "Touch", "SetDensity('Touch') did not resolve to the Touch preset")
        AssertTouch(Explicit)

        local Auto = BuildGeometry()
        Auto.IsMobile = true
        Auto:SetDensity("Auto")
        assert(Auto:ResolveDensity() == "Touch", "Auto density on mobile did not resolve to Touch")
        AssertTouch(Auto)

        -- A phone can never be forced below Touch even when a smaller preset is asked
        -- for, or hit areas would drop under 44px on the smallest screens.
        local Forced = BuildGeometry()
        Forced.IsMobile = true
        Forced:SetDensity("Compact")
        AssertTouch(Forced)

        local Desktop = BuildGeometry()
        Desktop.IsMobile = false
        Desktop:SetDensity("Comfortable")
        for Name, Value in Desktop.Design.Grid do
            assert(IsWhole(Value), "Comfortable grid token " .. Name .. " is fractional")
        end
        print("PASS Touch density keeps every interactive row at 44px or larger on whole pixels")
    end

    do
        -- The real Tab:RefreshSides two-column splitter, driven at three widths. It must
        -- split into whole pixels with no overflow when wide and collapse to a single
        -- stacked column when narrow.
        local function Widths(Size)
            return { Left = Size.X.Offset, LeftScale = Size.X.Scale, Top = Size.Y.Scale }
        end

        local function AssertNoOverflow(Sides, Total, Gap)
            local Left = Sides.Left.Size.X.Offset
            local Right = Sides.Right.Size.X.Offset
            assert(IsWhole(Left) and IsWhole(Right), "Column widths are fractional")
            assert(Left + Gap + Right == Total, "Columns overflow or underflow their container")
            assert(Right >= Left, "Remainder pixel was not handed to a column")
        end

        local Gap = 12

        local Even = BuildTabSides()
        Even.Container.AbsoluteSize = Mock.Vector2.new(600, 400)
        Even.SetNarrow(false)
        Even.Tab:RefreshSides()
        AssertNoOverflow(Even, 600, Gap)
        assert(Even.Left.Size.X.Offset == 294 and Even.Right.Size.X.Offset == 294, "Even split is wrong")

        local Odd = BuildTabSides()
        Odd.Container.AbsoluteSize = Mock.Vector2.new(601, 400)
        Odd.SetNarrow(false)
        Odd.Tab:RefreshSides()
        AssertNoOverflow(Odd, 601, Gap)

        local Narrow = BuildTabSides()
        Narrow.Container.AbsoluteSize = Mock.Vector2.new(360, 640)
        Narrow.SetNarrow(true)
        Narrow.Tab:RefreshSides()
        local Left = Widths(Narrow.Left.Size)
        local Right = Widths(Narrow.Right.Size)
        assert(Left.LeftScale == 1 and Right.LeftScale == 1, "Narrow layout did not collapse both columns to full width")
        assert(Left.Top == 0.5 and Right.Top == 0.5, "Narrow columns are not stacked into a single column")
        print("PASS two columns split on whole pixels when wide and stack into one when narrow")
    end

    local function IsCursor(Node)
        return Node.Name == "Cursor" or Node.IsCursorTracker == true
    end

    local function IsAspectViewport(Node)
        if Node.ClassName ~= "ViewportFrame" then
            return false
        end
        for _, Child in Node:GetChildren() do
            if Child.ClassName == "UIAspectRatioConstraint" then
                return true
            end
        end
        return false
    end

    local function CollectFractional(Root)
        local Bad = {}
        local function Visit(Node)
            if not (IsCursor(Node) or IsAspectViewport(Node)) then
                local Position, Size = Node.AbsolutePosition, Node.AbsoluteSize
                if Position and not (IsWhole(Position.X) and IsWhole(Position.Y)) then
                    table.insert(Bad, Node.Name .. ".AbsolutePosition")
                end
                if Size and not (IsWhole(Size.X) and IsWhole(Size.Y)) then
                    table.insert(Bad, Node.Name .. ".AbsoluteSize")
                end
            end
            for _, Child in Node:GetChildren() do
                Visit(Child)
            end
        end
        Visit(Root)
        return Bad
    end

    local function HasOwnCorner(Node)
        for _, Child in Node:GetChildren() do
            if Child.ClassName == "UICorner" then
                return true
            end
        end
        return false
    end

    local function IsMaskingClip(Node)
        if not HasOwnCorner(Node) then
            return false
        end
        return Node.ClassName == "CanvasGroup" or Node.ClipsDescendants == true
    end

    local function IsFlushToCorner(Node)
        local Position = Node.Position
        if not Position then
            return false
        end
        return Position.X.Scale == 0 and Position.X.Offset == 0 and Position.Y.Scale == 0 and Position.Y.Offset == 0
    end

    local function CollectDoubleCorner(Root)
        local Bad = {}
        local function Visit(Node, Masked)
            if Masked and IsFlushToCorner(Node) and HasOwnCorner(Node) then
                table.insert(Bad, Node.Name)
            end
            local NextMasked = Masked or IsMaskingClip(Node)
            for _, Child in Node:GetChildren() do
                Visit(Child, NextMasked)
            end
        end
        Visit(Root, false)
        return Bad
    end

    do
        -- Walk a representative window tree and assert the fractional-pixel and
        -- double-corner detectors behave: the documented exceptions (an aspect-ratio
        -- ViewportFrame and the pointer cursor) are allowed to carry sub-pixel geometry,
        -- a planted defect on any other node is caught, and a child flush against a
        -- masked corner may not carry its own UICorner. The full CreateWindow cannot be
        -- instantiated in this offline mock, so the source scans below lock the real
        -- code paths while these prove the walkers.
        local Root = Mock.Instance.new("Frame")
        Root.Name = "Window"
        Root.AbsolutePosition = Mock.Vector2.new(0, 0)
        Root.AbsoluteSize = Mock.Vector2.new(600, 400)

        local Card = Mock.Instance.new("Frame")
        Card.Name = "Card"
        Card.Parent = Root
        Card.AbsolutePosition = Mock.Vector2.new(12, 12)
        Card.AbsoluteSize = Mock.Vector2.new(576, 300)

        local Preview = Mock.Instance.new("ViewportFrame")
        Preview.Name = "Preview"
        Preview.Parent = Card
        Preview.AbsolutePosition = Mock.Vector2.new(4, 4)
        Preview.AbsoluteSize = Mock.Vector2.new(120.5, 90.5)
        local Ratio = Mock.Instance.new("UIAspectRatioConstraint")
        Ratio.Parent = Preview

        local Cursor = Mock.Instance.new("Frame")
        Cursor.Name = "Cursor"
        Cursor.Parent = Root
        Cursor.AbsolutePosition = Mock.Vector2.new(133.5, 42.25)
        Cursor.AbsoluteSize = Mock.Vector2.new(6, 6)

        assert(#CollectFractional(Root) == 0, "documented sub-pixel exceptions were not honoured")

        local Row = Mock.Instance.new("Frame")
        Row.Name = "Row"
        Row.Parent = Card
        Row.AbsolutePosition = Mock.Vector2.new(0, 0)
        Row.AbsoluteSize = Mock.Vector2.new(100.5, 24)
        local Found = CollectFractional(Root)
        assert(#Found == 1 and Found[1] == "Row.AbsoluteSize", "fractional geometry on a normal node was missed")

        local Shell = Mock.Instance.new("Frame")
        Shell.Name = "Shell"
        local Masked = Mock.Instance.new("CanvasGroup")
        Masked.Name = "MaskedCard"
        Masked.Parent = Shell
        local MaskedCorner = Mock.Instance.new("UICorner")
        MaskedCorner.Parent = Masked
        local Content = Mock.Instance.new("Frame")
        Content.Name = "Content"
        Content.Parent = Masked
        Content.Position = Mock.UDim2.new(0, 0, 0, 0)

        assert(#CollectDoubleCorner(Shell) == 0, "a clean flush child was flagged as double-rounded")
        local Notch = Mock.Instance.new("UICorner")
        Notch.Parent = Content
        local Notches = CollectDoubleCorner(Shell)
        assert(#Notches == 1 and Notches[1] == "Content", "double-rounded corner under a mask was missed")
        print("PASS fractional-pixel and double-corner walkers honour exceptions and catch planted defects")
    end

    do
        -- Structural rules that cannot execute offline, locked against the live source.
        local RadiusBlock = Source:match("Radius = {(.-)}")
        assert(RadiusBlock, "Could not locate the Radius token block")
        local function Token(Name)
            return tonumber(RadiusBlock:match(Name .. "%s*=%s*(%d+)"))
        end
        assert(
            Token("Window") == 8
                and Token("Card") == 6
                and Token("Control") == 5
                and Token("Popup") == 6
                and Token("Indicator") == 3,
            "Radius tokens drifted from Window=8, Card=6, Control=5, Popup=6, Indicator=3"
        )

        assert(
            Source:find("IsNarrowLayout%s*=%s*WindowInfo%.ResponsiveLayout%s*==%s*true%s*and%s*ContentWidth%s*<=%s*WindowInfo%.SingleColumnWidth"),
            "The single-column collapse gate below the breakpoint changed or was removed"
        )
        assert(
            Source:find("PreviousNarrowLayout%s*~=%s*IsNarrowLayout"),
            "Responsive layout no longer refreshes tab sides when the breakpoint is crossed"
        )
        assert(
            Source:find("Container%.AbsoluteSize%.X%s*/%s*Scale"),
            "Content width is no longer normalised by DPI scale, which can overflow the container"
        )

        -- Discover every responsive cell formula that divides a container width across
        -- columns and assert each floors to whole pixels rather than dividing raw. New
        -- controls that follow the same pattern are covered automatically.
        local FloorCount = 0
        for _ in Source:gmatch("math%.floor%(%(Width") do
            FloorCount += 1
        end
        assert(FloorCount >= 2, "Responsive cell formulas no longer floor their column widths")
        assert(
            not Source:find("CellWidth%s*=%s*[^\n]-Width%s*/%s*Columns"),
            "A responsive cell width divides by columns without flooring, which yields half pixels"
        )
        print("PASS radius tokens, the responsive collapse gate and whole-pixel cell math are intact")
    end
end
