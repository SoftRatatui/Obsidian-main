return function(Install, Mock, Modules)
    local Library = Mock.Library()
    Library.Options, Library.Toggles, Library.Tabs = {}, {}, {}
    function Library:SafeCallback(Func, ...)
        if Func then
            local OK, Result = pcall(Func, ...)
            if not OK then self:ReportError(Result) else return Result end
        end
    end
    local Frame = Install(Library)
    local Created = 0
    local Pool = Library:CreatePool(nil, function()
        Created += 1
        return Mock.Instance.new("Frame")
    end)
    local A = Pool:Acquire()
    assert(Pool:Release(A) and not Pool:Release(A))
    assert(Pool:Acquire() == A and Created == 1)
    Pool:Release(A); Pool:Trim(0)
    assert(A.Destroyed)
    Pool:Destroy()
    local Scroll = Mock.Instance.new("ScrollingFrame")
    Scroll.AbsoluteSize = Mock.Vector2.new(300, 280)
    Scroll.CanvasPosition = Mock.Vector2.zero
    local View = Library:CreateVirtualList(Scroll, {
        Count = 5000, RowHeight = 28, Overscan = 2,
        CreateRow = function() return Mock.Instance.new("TextLabel") end,
        RenderRow = function(Row, Index) Row.Text = tostring(Index) end,
    })
    assert(View.Pool.Created <= 14 and View.Rows[1].Text == "1")
    View:ScrollTo(4999)
    assert(View.Rows[5000] and View.Pool.Created <= 28)
    View:SetCount(2)
    assert(View.Rows[1] and View.Rows[2] and not View.Rows[5000])
    View:Destroy()
    assert(Library:Diagnose().ActiveRows == 0)
    local Items = {}
    for Index = 1, 5000 do Items[Index] = { Id = Index, Name = "Asset " .. Index, Image = 123 } end
    local Catalog = Modules.AssetCatalog.Create(Library, { Items = Items, Columns = 3 })
    assert(Catalog.Virtualized and Catalog.VirtualView.Pool.Created < 40)
    Catalog.VirtualView:ScrollTo(4999)
    assert(Catalog.VirtualView.Last == 5000 and Catalog.VirtualView.Pool.Created < 80)
    Catalog:SetItemState(5000, { Status = "Ready" })
    Catalog:Destroy()
    assert(Library:Diagnose().ActiveRows == 0)
    local State, Seen = Library:State(false), {}
    local Observer = Library:Observe(function() table.insert(Seen, State:Get()) end)
    State:Set(true); State:Set(true); State:Set(false)
    assert(#Seen == 3 and Seen[1] == false and Seen[2] == true and Seen[3] == false)
    Observer:Destroy(); State:Set(true); assert(#Seen == 3)
    local Resizes = 0
    local Target = { Resize = function() Resizes += 1 end }
    for _ = 1, 100 do Library:RequestLayout(Target) end
    assert(Resizes == 0)
    Frame:Fire(); assert(Resizes == 1)
    local Work = 0
    local First = Library:QueueBuild(function() Work += 1 end, "first")
    local Cancelled = Library:QueueBuild(function() Work += 100 end, "cancelled")
    Cancelled:Cancel(); Frame:Fire()
    assert(Work == 1 and First.Status == "Completed" and Cancelled.Status == "Cancelled")
    local Errors = 0
    Library:OnError(function(Entry) Errors += 1; assert(Entry.Id == "broken") end)
    Library:QueueBuild(function() error("broken builder") end, "broken")
    Frame:Fire(); assert(Errors == 1)
    Library:DestroyRuntime()
    local Report = Library:Diagnose()
    assert(next(Report.Resources) == nil and Report.Connections == 0 and Report.PendingBuilds == 0)
    print("PASS pooled 5000-item viewport, state observers, coalesced layout, build cancellation and runtime cleanup")
end

