local CollectionModel = require("../addons/CollectionModel")
local Passed = 0

local function Test(Name, Callback)
    local Success, Message = pcall(Callback)
    assert(Success, Name .. ": " .. tostring(Message))
    Passed += 1
    print("PASS " .. Name)
end

local function Create()
    return CollectionModel.Create({
        Items = {
            { Id = "a", Name = "Neptune", Category = "Rifles", Tags = { "blue" } },
            { Id = "b", Name = "Arctic", Category = "Pistols", Favorite = true },
            { Id = "c", Name = "Locked", Locked = true },
            { Id = "d", Name = "Disabled", Disabled = true },
        },
    })
end

local function View()
    local Result = { Page = 3, Destroyed = false, SetItemsCount = 0 }
    function Result:SetItems(Items)
        Result.Items = Items
        Result.Page = 1
        Result.SetItemsCount += 1
    end
    function Result:SetPage(Page)
        Result.Page = Page
    end
    function Result:Select(Id, Silent)
        Result.SelectedId = Id
        if not Silent and Result.OnSelected then
            Result.OnSelected(Id and { Id = Id } or nil, Id and { Id = Id } or nil)
        end
    end
    function Result:Destroy()
        Result.Destroyed = true
    end
    return Result
end

Test("stable IDs after removal and insertion", function()
    local Model = CollectionModel.Create({ Items = { "first", "second" } })
    local Items = Model:GetItems()
    Model:RemoveItem(Items[1].Id)
    local Added = Model:AddItem("third")
    assert(Added.Id ~= Items[1].Id and Added.Id ~= Items[2].Id)
end)

Test("replacement is atomic on duplicate IDs", function()
    local Model = Create()
    Model:Select("a")
    assert(not pcall(function()
        Model:SetItems({ { Id = "x" }, { Id = "x" } })
    end))
    assert(#Model:GetItems() == 4 and Model:GetSelected().Id == "a")
end)

Test("automatic IDs avoid explicit IDs", function()
    local Model = CollectionModel.Create({ Items = { "auto", { Id = "collection-1" } } })
    assert(Model:GetItems()[1].Id ~= "collection-1")
end)

Test("selection rejects unavailable items and clears after removal", function()
    local Model = Create()
    assert(Model:Select("a"))
    assert(not Model:Select("d") and not Model:Select("missing"))
    assert(Model:GetSelected().Id == "a")
    assert(Model:Select("c"))
    Model:RemoveItem("c")
    assert(Model:GetSelected() == nil)
end)

Test("query filters and sorting leave source order intact", function()
    local Model = Create()
    assert(Model:Query({ Search = "BLUE", Category = "Rifles" })[1].Id == "a")
    assert(#Model:Query({ Search = "[" }) == 0)
    assert(Model:Query({ FavoritesOnly = true })[1].Id == "b")
    assert(Model:Query({ Sort = "Name" })[1].Id == "b")
    assert(Model:GetItems()[1].Id == "a")
end)

Test("returned records do not mutate collection data", function()
    local Model = Create()
    local Item = Model:GetItem("a")
    Item.Name = "changed"
    Item.Tags[1] = "changed"
    assert(Model:GetItem("a").Name == "Neptune" and Model:GetItem("a").Tags[1] == "blue")
end)

Test("updates preserve IDs and invalidate disabled selection", function()
    local Model = Create()
    Model:Select("a")
    assert(not pcall(function()
        Model:UpdateItem("a", { Id = "b" })
    end))
    Model:UpdateItem("a", { Disabled = true })
    assert(Model:GetSelected() == nil)
    Model:SetFavorite("a", true)
    assert(#Model:Query({ FavoritesOnly = true }) == 2)
end)

Test("multiple views synchronize without rebuilding on selection", function()
    local Model, A, B = Create(), View(), View()
    Model:Bind(A)
    Model:Bind(B)
    A:Select("b")
    assert(Model:GetSelected().Id == "b" and B.SelectedId == "b")
    assert(A.SetItemsCount == 1 and B.SetItemsCount == 1)
    Model:UpdateItem("b", { Name = "Updated" })
    assert(B.Items[2].Name == "Updated" and A.Page == 3 and B.Page == 3)
end)

Test("view destruction disconnects only its own binding", function()
    local Model, A, B = Create(), View(), View()
    local Binding = Model:Bind(A)
    Model:Bind(B)
    A:Destroy()
    Model:Select("b")
    assert(not Binding.Connected and A.Destroyed and B.SelectedId == "b")
end)

Test("rebinding a view replaces the previous owner", function()
    local A, B, Widget = Create(), Create(), View()
    local Binding = A:Bind(Widget)
    B:Bind(Widget)
    A:Select("a")
    assert(not Binding.Connected and Widget.SelectedId == nil)
    Widget:Select("b")
    assert(A:GetSelected().Id == "a" and B:GetSelected().Id == "b")
end)

Test("collection destruction restores original callbacks", function()
    local Model, Widget = Create(), View()
    local Callback = function() end
    Widget.OnSelected = Callback
    local OriginalDestroy = Widget.Destroy
    Model:Bind(Widget)
    Model:Destroy()
    Model:Destroy()
    assert(Widget.OnSelected == Callback and Widget.Destroy == OriginalDestroy)
    assert(not pcall(function()
        Model:AddItem("later")
    end))
end)

Test("reentrant updates are delivered after the current notification", function()
    local Model = Create()
    local Calls = 0
    local Listener = Model:Subscribe(function()
        Calls += 1
        if Calls == 1 then
            Model:Select("b")
        end
    end)
    Model:Select("a")
    assert(Calls == 2 and Model:GetSelected().Id == "b")
    Listener:Disconnect()
    Model:Select(nil)
    assert(Calls == 2)
end)

print(string.format("%d collection regression tests passed", Passed))
