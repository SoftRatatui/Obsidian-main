export type BoxSettings = {
    Enabled: boolean,
    Style: "Corner" | "Full" | "3D",
    Dynamic: boolean,
    Scale: number,
    Thickness: number,
    Transparency: number,
    Outline: boolean,
    OutlineThickness: number,
    Fill: boolean,
    FillTransparency: number,
    Gradient: boolean,
    Rainbow: boolean,
    RainbowSpeed: number,
}

export type TextSettings = {
    Name: boolean,
    DisplayName: boolean,
    Team: boolean,
    Distance: boolean,
    Tool: boolean,
    Health: boolean,
    Category: boolean,
    Flags: boolean,
    Size: number,
    RelativeSize: boolean,
    Outline: boolean,
    Font: "Plex" | "UI" | "System" | "Monospace",
    Separator: string,
}

export type HealthBarSettings = {
    Enabled: boolean,
    Position: "Left" | "Right" | "Top" | "Bottom",
    Width: number,
    Offset: number,
    Outline: boolean,
    Text: boolean,
}

export type TracerSettings = {
    Enabled: boolean,
    Origin: "Bottom" | "Center" | "Mouse" | "Top",
    Target: "Bottom" | "Center" | "Top",
    Thickness: number,
    Transparency: number,
    Outline: boolean,
}

export type SkeletonSettings = {
    Enabled: boolean,
    Thickness: number,
    Transparency: number,
    Outline: boolean,
    MaxJoints: number,
}

export type HeadDotSettings = {
    Enabled: boolean,
    Filled: boolean,
    Radius: number,
    Sides: number,
    Thickness: number,
    Transparency: number,
    Outline: boolean,
}

export type OffscreenArrowSettings = {
    Enabled: boolean,
    Radius: number,
    Size: number,
    Filled: boolean,
    Transparency: number,
    Outline: boolean,
}

export type HighlightSettings = {
    Enabled: boolean,
    FillTransparency: number,
    OutlineTransparency: number,
    DepthMode: "AlwaysOnTop" | "Occluded",
    HealthColor: boolean,
}

export type ColorSettings = {
    Enemy: Color3,
    Gradient: Color3,
    Tracer: Color3,
    Skeleton: Color3,
    HeadDot: Color3,
    Arrow: Color3,
    Team: Color3,
    NPC: Color3,
    Part: Color3,
    Visible: Color3,
    Occluded: Color3,
    Outline: Color3,
    Text: Color3,
    HealthLow: Color3,
    HealthHigh: Color3,
    HighlightFill: Color3,
    HighlightOutline: Color3,
}

export type Settings = {
    Enabled: boolean,
    Players: boolean,
    NPCs: boolean,
    Parts: boolean,
    IncludeLocalPlayer: boolean,
    AliveCheck: boolean,
    TeamCheck: boolean,
    TeamColors: boolean,
    VisibilityCheck: boolean,
    VisibilityInterval: number,
    MaxDistance: number,
    TextDistance: number,
    UpdateRate: number,
    TextUpdateRate: number,
    Box: BoxSettings,
    Text: TextSettings,
    HealthBar: HealthBarSettings,
    Tracer: TracerSettings,
    Skeleton: SkeletonSettings,
    HeadDot: HeadDotSettings,
    OffscreenArrow: OffscreenArrowSettings,
    Highlight: HighlightSettings,
    Colors: ColorSettings,
}

export type EntryInfo = {
    Id: string?,
    Kind: "Player" | "NPC" | "Part"?,
    Name: string | ((Instance, Instance, Player?) -> any)?,
    Team: string | ((Player?) -> any)?,
    Tool: string | ((Instance, Instance, Player?) -> any)?,
    Category: string?,
    Flags: string | { any } | ((Instance, Instance, Player?) -> any)?,
    Predicate: ((Instance, Instance?, Player?, number?) -> boolean)?,
    Color: Color3?,
    GradientColor: Color3?,
    MaxDistance: number?,
    TextDistance: number?,
    AllowedVisuals: { [string]: boolean }?,
}

export type Stats = {
    Total: number,
    Players: number,
    NPCs: number,
    Parts: number,
    Running: boolean,
    Enabled: boolean,
    Available: boolean,
    LastError: string?,
}

export type Watcher = {
    Container: Instance,
    Info: EntryInfo,
    Destroyed: boolean,
    Scan: (self: Watcher) -> number,
    Destroy: (self: Watcher) -> (),
}

export type PreviewAdapter = {
    Continuous: boolean,
    UseContext: boolean,
    AttachPreview: (self: PreviewAdapter, Preview: any, Context: { [string]: any }) -> any,
    UpdatePreview: (self: PreviewAdapter, Preview: any, Context: { [string]: any }) -> (),
    SetPreviewVisible: (self: PreviewAdapter, Preview: any, Visible: boolean) -> (),
    DetachPreview: (self: PreviewAdapter, Preview: any) -> (),
    Destroy: (self: PreviewAdapter) -> (),
}

export type Controller = {
    Available: boolean,
    Settings: Settings,
    Entries: { [string]: any },
    Running: boolean,
    Destroyed: boolean,
    LastError: string?,
    Get: (self: Controller, Path: string) -> any,
    Set: (self: Controller, Path: string, Value: any) -> any,
    ApplySettings: (self: Controller, Settings: { [string]: any }) -> Settings,
    ApplyPreset: (self: Controller, Name: "Performance" | "Balanced" | "Quality") -> Settings,
    SetEnabled: (self: Controller, Enabled: boolean) -> (),
    Start: (self: Controller) -> Controller,
    Stop: (self: Controller) -> Controller,
    WrapObject: (self: Controller, Object: Instance, Info: EntryInfo?) -> string,
    Wrap: (self: Controller, Object: Instance, Info: EntryInfo?) -> string,
    UnwrapObject: (self: Controller, ObjectOrId: Instance | string) -> boolean,
    Unwrap: (self: Controller, ObjectOrId: Instance | string) -> boolean,
    GetEntry: (self: Controller, ObjectOrId: Instance | string) -> any,
    WrapPlayers: (self: Controller, Info: EntryInfo?) -> Controller,
    UnwrapPlayers: (self: Controller) -> Controller,
    ScanNPCs: (self: Controller, Container: Instance?, Info: EntryInfo?) -> number,
    WatchNPCs: (self: Controller, Container: Instance?, Info: EntryInfo?) -> Watcher,
    TrackNPCs: (self: Controller, Container: Instance?, Info: EntryInfo?) -> Watcher,
    SetAutomaticNPCs: (self: Controller, Enabled: boolean, Container: Instance?, Info: EntryInfo?) -> Watcher?,
    CreatePreviewAdapter: (self: Controller, Info: { UseContext: boolean? }?) -> PreviewAdapter,
    GetStats: (self: Controller) -> Stats,
    Restart: (self: Controller, Rebuild: boolean?) -> Controller,
    HideAll: (self: Controller) -> (),
    Destroy: (self: Controller) -> (),
    Exit: (self: Controller) -> (),
}

export type Module = {
    Version: string,
    Available: boolean,
    Defaults: Settings,
    new: (Info: { AutoStart: boolean?, WrapPlayers: boolean?, Settings: { [string]: any }? }?) -> Controller,
}

return nil :: Module?
