return function(CreateDropdown, Mock)
    local Dropdown, View = CreateDropdown({})
    Dropdown.Value = "Head"
    Dropdown:Display()
    assert(View.Button.Size.Y.Scale == 1 and View.Button.Size.Y.Offset == 0, "Dropdown value is shorter than its field")
    assert(View.Button.Position.Y.Offset == 0 and View.Button.Size.X.Offset == -24)
    local Long = "Очень длинное название выбранного элемента"
    Dropdown.Value = Long
    Dropdown:Display()
    assert(View.Button.Text == Long, "Dropdown truncates UTF-8 by bytes instead of rendered width")
    Dropdown.ValueImages = { [Long] = "image" }
    Dropdown:Display()
    assert(View.Button.Position.X.Offset == 22 and View.Button.Size.X.Offset == -46, "Value icon overlaps text or the arrow")
    for _, Height in { 12, 14, 18, 24, 32 } do
        View.FontHeight = Height
        Dropdown:RefreshTypography()
        assert(View.Button.TextSize >= 8 and View.Button.TextSize <= 14)
        assert(View.Button.TextYAlignment == Mock.Enum.TextYAlignment.Center)
        assert(View.Row.TextSize >= 8 and View.Row.TextSize <= 14)
        assert(View.Button.Size.Y.Scale == 1, "Font metrics alter control geometry")
    end
    Dropdown:SetText(nil)
    assert(View.Holder.Size.Y.Offset == 28 and View.Display.Position.Y.Offset == 0 and not View.Label.Visible)
    Dropdown:SetText("Hitbox")
    assert(View.Holder.Size.Y.Offset == 46 and View.Display.Position.Y.Offset == 18 and View.Label.Visible)
    print("PASS dropdown centering, UTF-8 labels, icons and varied font metrics")
end
