local CollectionModel = {
    ReleaseVersion = "0.0.1-release-16",
}

local function Copy(Value)
    if type(Value) ~= "table" then
        return Value
    end
    local Result = table.clone(Value)
    for _, Key in { "Tags", "Badges" } do
        if type(Result[Key]) == "table" then
            Result[Key] = table.clone(Result[Key])
        end
    end
    return Result
end

function CollectionModel.Create(Info)
    Info = Info or {}
    local Items, ById, Listeners = {}, {}, {}
    local SelectedId, NextId = nil, 0
    local Model = { Destroyed = false, Revision = 0, ItemsRevision = 0 }
    local Notifying, Pending = false, false

    local function Check()
        assert(not Model.Destroyed, "Collection has been destroyed")
    end

    local function Emit(ItemsChanged)
        Model.Revision += 1
        if ItemsChanged then
            Model.ItemsRevision += 1
        end
        Pending = true
        if Notifying then
            return
        end
        Notifying = true
        while Pending and not Model.Destroyed do
            Pending = false
            for _, Listener in table.clone(Listeners) do
                if Listener.Connected then
                    local Success, Message = pcall(Listener.Callback, Model)
                    if not Success then
                        print("Collection listener failed: " .. tostring(Message))
                    end
                end
            end
        end
        Notifying = false
    end

    local function Normalize(Item, Used)
        if type(Item) ~= "table" then
            Item = { Name = tostring(Item), Image = Item }
        end
        local Result = Copy(Item)
        if Result.Id == nil then
            repeat
                NextId += 1
                Result.Id = "collection-" .. NextId
            until not Used[Result.Id]
        end
        assert(type(Result.Id) == "string" or type(Result.Id) == "number", "Item Id must be a string or number")
        assert(Result.Id == Result.Id, "Item Id cannot be NaN")
        assert(not Used[Result.Id], "Duplicate item Id: " .. tostring(Result.Id))
        Result.Name = tostring(Result.Name or Result.Title or Result.Id)
        Result.Category = tostring(Result.Category or Result.Group or "All")
        return Result
    end

    function Model:GetItems()
        local Result = {}
        for _, Item in Items do
            table.insert(Result, Copy(Item))
        end
        return Result
    end

    function Model:GetItem(Id)
        return Copy(ById[Id])
    end

    function Model:GetSelected()
        return Copy(ById[SelectedId])
    end

    function Model:SetItems(Values)
        Check()
        assert(type(Values) == "table", "Items must be an array")
        local NewItems, NewById, Reserved = {}, {}, {}
        for _, Item in ipairs(Values) do
            if type(Item) == "table" and Item.Id ~= nil then
                Reserved[Item.Id] = true
            end
        end
        for _, Item in ipairs(Values) do
            local Value = Normalize(Item, type(Item) == "table" and Item.Id ~= nil and NewById or Reserved)
            assert(not NewById[Value.Id], "Duplicate item Id: " .. tostring(Value.Id))
            Reserved[Value.Id] = true
            NewById[Value.Id] = Value
            table.insert(NewItems, Value)
        end
        Items, ById = NewItems, NewById
        if SelectedId ~= nil and (not ById[SelectedId] or ById[SelectedId].Disabled) then
            SelectedId = nil
        end
        Emit(true)
        return Model
    end

    function Model:AddItem(Item)
        Check()
        local Value = Normalize(Item, ById)
        ById[Value.Id] = Value
        table.insert(Items, Value)
        Emit(true)
        return Copy(Value)
    end

    function Model:UpdateItem(Id, Changes)
        Check()
        assert(type(Changes) == "table", "Changes must be a table")
        local Item = ById[Id]
        if not Item then
            return false
        end
        assert(Changes.Id == nil or Changes.Id == Id, "Item Id cannot be changed")
        local Value = Copy(Item)
        for Key, Child in Changes do
            Value[Key] = Child
        end
        Value = Normalize(Value, {})
        ById[Id] = Value
        Items[table.find(Items, Item)] = Value
        if SelectedId == Id and Value.Disabled then
            SelectedId = nil
        end
        Emit(true)
        return true
    end

    function Model:RemoveItem(Id)
        Check()
        local Item = ById[Id]
        if not Item then
            return false
        end
        table.remove(Items, table.find(Items, Item))
        ById[Id] = nil
        if SelectedId == Id then
            SelectedId = nil
        end
        Emit(true)
        return true
    end

    function Model:Select(Id)
        Check()
        if Id ~= nil and (not ById[Id] or ById[Id].Disabled) then
            return false
        end
        if SelectedId ~= Id then
            SelectedId = Id
            Emit()
        end
        return true
    end

    function Model:SetFavorite(Id, Value)
        return Model:UpdateItem(Id, { Favorite = Value == true })
    end

    function Model:Query(Options)
        Options = Options or {}
        local Query = string.lower(tostring(Options.Search or ""))
        local Result = {}
        for _, Item in Items do
            local Tags = type(Item.Tags) == "table" and table.concat(Item.Tags, " ") or tostring(Item.Tags or "")
            local SearchText = string.lower(Item.Name .. " " .. Item.Category .. " " .. Tags)
            if
                (Options.Category == nil or Options.Category == "All" or Item.Category == Options.Category)
                and (not Options.FavoritesOnly or Item.Favorite)
                and (Query == "" or string.find(SearchText, Query, 1, true))
            then
                table.insert(Result, Copy(Item))
            end
        end
        if Options.Sort == "Name" then
            table.sort(Result, function(A, B)
                if A.Name == B.Name then
                    return tostring(A.Id) < tostring(B.Id)
                end
                return A.Name < B.Name
            end)
        end
        return Result
    end

    function Model:Subscribe(Callback)
        Check()
        assert(type(Callback) == "function", "Listener must be a function")
        local Listener = { Connected = true, Callback = Callback }
        table.insert(Listeners, Listener)
        function Listener:Disconnect()
            if not Listener.Connected then
                return
            end
            Listener.Connected = false
            local Index = table.find(Listeners, Listener)
            if Index then
                table.remove(Listeners, Index)
            end
        end
        return Listener
    end

    function Model:Bind(View)
        Check()
        assert(
            type(View) == "table" and type(View.SetItems) == "function" and type(View.Select) == "function",
            "View must support SetItems and Select"
        )
        if View.CollectionBinding then
            View.CollectionBinding:Disconnect()
        end
        local OriginalSelected, OriginalDestroy = View.OnSelected, View.Destroy
        local Syncing = false
        local ItemsRevision = -1
        local function Sync()
            if View.Destroyed then
                return
            end
            Syncing = true
            if ItemsRevision ~= Model.ItemsRevision then
                local Page = View.Page
                View:SetItems(Model:GetItems())
                if Page and type(View.SetPage) == "function" then
                    View:SetPage(Page)
                end
                ItemsRevision = Model.ItemsRevision
            end
            View:Select(SelectedId, true)
            Syncing = false
        end
        local Binding = Model:Subscribe(Sync)
        local function OnSelected(Source, Item)
            if not Syncing and not Model.Destroyed then
                Model:Select(Item and Item.Id or (Source and Source.Id))
            end
            if type(OriginalSelected) == "function" then
                OriginalSelected(Source, Item)
            end
        end
        local Disconnect = Binding.Disconnect
        local DestroyView
        function Binding:Disconnect()
            Disconnect(Binding)
            if View.CollectionBinding == Binding then
                View.CollectionBinding = nil
            end
            if View.OnSelected == OnSelected then
                View.OnSelected = OriginalSelected
            end
            if View.Destroy == DestroyView then
                View.Destroy = OriginalDestroy
            end
        end
        DestroyView = function(Self, ...)
            Binding:Disconnect()
            if OriginalDestroy then
                return OriginalDestroy(Self, ...)
            end
            return nil
        end
        View.OnSelected = OnSelected
        View.Destroy = DestroyView
        View.CollectionBinding = Binding
        Sync()
        return Binding
    end

    function Model:Destroy()
        if Model.Destroyed then
            return
        end
        Model.Destroyed = true
        for _, Listener in table.clone(Listeners) do
            Listener:Disconnect()
        end
        table.clear(Items)
        table.clear(ById)
        SelectedId = nil
    end

    Model:SetItems(Info.Items or {})
    if Info.Selected ~= nil then
        Model:Select(Info.Selected)
    end
    return Model
end

return CollectionModel
