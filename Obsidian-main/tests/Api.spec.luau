-- API regression suite. Runs entirely by scanning the source text of Library.lua
-- and Library.d.luau, so it keeps working as other agents add controls and methods
-- rather than hardcoding a control list. check.ps1 passes both sources as strings.
return function(LibrarySource, TypeSource)
    local function SortedList(Set)
        local Names = {}
        for Name in Set do
            table.insert(Names, Name)
        end
        table.sort(Names)
        return table.concat(Names, ", ")
    end

    local function CollectNames(Pattern)
        local Set = {}
        for Name in LibrarySource:gmatch(Pattern) do
            Set[Name] = true
        end
        return Set
    end

    -- A method is declared in the type file when its name is followed by a colon and
    -- a function type opener: "Name: (" for a plain method or "Name: <T>(" for a
    -- generic one. Matching the opener avoids counting a same-named record field.
    local function DeclaredInTypes(Name)
        return TypeSource:find("[^%w_]" .. Name .. "%s*:%s*[(<]") ~= nil
    end

    -- Library methods that are deliberately implementation-only and are not part of
    -- the published type surface. Anything not listed here MUST appear in
    -- Library.d.luau, which is what makes the d.luau audit self-enforcing.
    local InternalMethods = {
        BindControl = true,
        BindItemDragSource = true,
        ClosePopupsUnder = true,
        EmitConfigChanged = true,
        GetButtonStyle = true,
        GetControlValue = true,
        IsDropTargetVisible = true,
        NormalizeButtonVariant = true,
        PlayTabAnimation = true,
        RecordChange = true,
        RegisterConfigOption = true,
        ResetScope = true,
        TrackResource = true,
    }

    do
        local LibraryMethods = CollectNames("function Library:([%a_][%w_]*)")
        local FuncMethods = CollectNames("function Funcs:(Add[%w_]*)")
        assert(next(LibraryMethods), "No Library methods were discovered; the scan pattern is broken")
        assert(next(FuncMethods), "No Funcs:AddXxx controls were discovered; the scan pattern is broken")

        local Missing = {}
        for Name in LibraryMethods do
            if not InternalMethods[Name] and not DeclaredInTypes(Name) then
                Missing[Name] = true
            end
        end
        for Name in FuncMethods do
            if not DeclaredInTypes(Name) then
                Missing[Name] = true
            end
        end
        assert(not next(Missing), "Library.d.luau is missing entries for: " .. SortedList(Missing))
        print("PASS every public Library method and Funcs:AddXxx control is declared in Library.d.luau")
    end

    do
        -- Split the type file into per-type chunks so a control's declared contract can
        -- be inspected without brace matching. Chunks run from one export type to the
        -- next, which is exactly that type's body.
        local Starts = {}
        local Index = 1
        while true do
            local Begin, Stop, Name = TypeSource:find("export type (%w+)%s*=%s*{", Index)
            if not Begin then
                break
            end
            table.insert(Starts, { Name = Name, Begin = Begin })
            Index = Stop + 1
        end
        assert(#Starts > 0, "No export type blocks were discovered; the scan pattern is broken")

        local ValueTypes, Incomplete, DisabledControls, DisabledWithoutBase = {}, {}, {}, {}
        for Position, Entry in Starts do
            local ChunkEnd = Position < #Starts and Starts[Position + 1].Begin - 1 or #TypeSource
            local Chunk = TypeSource:sub(Entry.Begin, ChunkEnd)
            local HasAccessor = Chunk:find("[^%w_]SetValue%s*:")
                or Chunk:find("[^%w_]GetValue%s*:")
                or Chunk:find("[^%w_]GetNumber%s*:")
            local HasVisible = Chunk:find("[^%w_]SetVisible%s*:") ~= nil
            local HasDestroy = Chunk:find("[^%w_]Destroy%s*:") ~= nil
            if HasAccessor then
                ValueTypes[Entry.Name] = true
                if not (HasVisible and HasDestroy) then
                    Incomplete[Entry.Name] = true
                end
            end
            -- A control the dependency system can disable must carry the visibility and
            -- cleanup lifecycle it is driven through. Action controls have no value, so a
            -- value accessor is not required here, only for the value controls above.
            if Chunk:find("[^%w_]SetDisabled%s*:") then
                DisabledControls[Entry.Name] = true
                if not (HasVisible and HasDestroy) then
                    DisabledWithoutBase[Entry.Name] = true
                end
            end
        end
        assert(next(ValueTypes), "No value controls were discovered in Library.d.luau")
        assert(
            not next(Incomplete),
            "These value controls expose a value accessor but not the full SetVisible/Destroy contract: "
                .. SortedList(Incomplete)
        )
        print("PASS every value control declares the shared controller contract (accessor, visibility, cleanup)")

        assert(next(DisabledControls), "No disableable controls were discovered; the disabled-state contract is unenforced")
        assert(
            not next(DisabledWithoutBase),
            "These controls expose SetDisabled but not the SetVisible/Destroy lifecycle it relies on: "
                .. SortedList(DisabledWithoutBase)
        )
        -- Reset is a library-level contract rather than a per-control method, so config
        -- and dependency reset flow through Library:ResetDefaults (roadmap 107).
        assert(DeclaredInTypes("ResetDefaults"), "Library.d.luau no longer declares Library:ResetDefaults, the reset contract")
        print("PASS disableable controls carry the full controller contract and the reset entry point is declared")
    end

    do
        local Block = LibrarySource:match("DeclarativeElementMethods%s*=%s*{(.-)}")
        assert(Block, "Could not locate the DeclarativeElementMethods table")
        local Mapped = {}
        for Method in Block:gmatch('"(Add%w+)"') do
            Mapped[Method] = true
        end
        assert(next(Mapped), "DeclarativeElementMethods parsed to an empty map")

        local FuncMethods = CollectNames("function Funcs:(Add[%w_]*)")

        -- Every method the declarative map points at must be a real control.
        local Dangling = {}
        for Method in Mapped do
            if not FuncMethods[Method] then
                Dangling[Method] = true
            end
        end
        assert(not next(Dangling), "DeclarativeElementMethods points at controls that do not exist: " .. SortedList(Dangling))

        -- Controls that are structural, config-only, or reached through the addon path
        -- rather than as a declarative element type.
        local NonDeclarative = {
            AddKeyPicker = true,
            AddColorPicker = true,
            AddHidden = true,
            AddSection = true,
            AddAddon = true,
            AddDependencyBox = true,
            AddDependencyGroupbox = true,
        }
        local Unmapped = {}
        for Method in FuncMethods do
            if not Mapped[Method] and not NonDeclarative[Method] then
                Unmapped[Method] = true
            end
        end
        assert(
            not next(Unmapped),
            "These controls are not covered by the declarative element map: " .. SortedList(Unmapped)
        )
        print("PASS the declarative element map covers every declarative Funcs:AddXxx control")
    end

    do
        -- Static teardown guard for roadmap 107. The full runtime cannot be
        -- instantiated in this offline harness (Runtime.spec covers the executed
        -- DestroyRuntime -> Diagnose path), so assert Unload still performs each
        -- teardown step and Diagnose still reports each leak category. Removing a
        -- step here would let a leak ship silently.
        local UnloadStart = LibrarySource:find("function Library:Unload%(%)")
        assert(UnloadStart, "Could not locate Library:Unload")
        local UnloadBody = LibrarySource:sub(UnloadStart)

        local Steps = {
            ["runtime teardown"] = "DestroyRuntime",
            ["registry clear"] = "table%.clear%(Library%.Registry%)",
            ["signal disconnect"] = "Library%.Signals",
            ["tween clear"] = "table%.clear%(Library%.ActiveTweens%)",
        }
        local MissingSteps = {}
        for Label, Pattern in Steps do
            if not UnloadBody:find(Pattern) then
                MissingSteps[Label] = true
            end
        end
        assert(not UnloadBody:find("Library%.Signals") or UnloadBody:find(":Disconnect%(%)"), "Unload no longer disconnects signals")
        assert(not next(MissingSteps), "Library:Unload no longer performs: " .. SortedList(MissingSteps))

        local Categories = {
            Connections = "Report%.Connections",
            Tweens = "Report%.Tweens",
            Instances = "Report%.Instances",
            Resources = "Report%.Resources",
        }
        local MissingCategories = {}
        for Label, Pattern in Categories do
            if not LibrarySource:find(Pattern) then
                MissingCategories[Label] = true
            end
        end
        assert(
            not next(MissingCategories),
            "Library:Diagnose no longer reports leak categories: " .. SortedList(MissingCategories)
        )
        print("PASS Library:Unload performs every teardown step and Library:Diagnose reports every leak category")
    end
end
