




export type Scheme = {
    BackgroundColor: Color3,
    MainColor: Color3,
    TopBarColor: Color3,
    SurfaceColor: Color3,
    RaisedColor: Color3,
    ElementColor: Color3,
    HoverColor: Color3,
    AccentColor: Color3,
    AccentSoftColor: Color3,
    OutlineColor: Color3,
    FontColor: Color3,
    MutedFontColor: Color3,
    ShadowColor: Color3,
    Font: Font,
    RedColor: Color3,
    WarningColor: Color3,
    DestructiveColor: Color3,
    DarkColor: Color3,
    WhiteColor: Color3,
    BackgroundImage: string | number,
}

export type Icon = {
    Url: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
    Custom: boolean?,
}

export type ContextMenu = {
    Active: boolean,
    Holder: GuiObject,
    Menu: GuiObject,
    List: UIListLayout?,
    Signal: RBXScriptConnection?,
    Size: UDim2 | () -> UDim2,

    Open: (self: ContextMenu) -> (),
    Close: (self: ContextMenu) -> (),
    Toggle: (self: ContextMenu) -> (),
    SetSize: (self: ContextMenu, Size: UDim2 | () -> UDim2) -> (),
}

export type Tooltip = {
    Disabled: boolean,
    Hovering: boolean,
    Signals: { [number]: RBXScriptConnection },
    Destroy: (self: Tooltip) -> (),
}

export type Notification = {
    Title: string?,
    Description: string,
    Time: number | Instance,
    SoundId: string | number?,
    Volume: number?,
    Steps: number?,
    Persist: boolean?,
    Icon: string?,
    BigIcon: string?,
    IconColor: Color3 | string?,
    TitleColor: Color3?,
    DescriptionColor: Color3?,
    Destroyed: boolean,
    PositionInitialized: boolean?,

    Resize: (self: Notification) -> (),
    ChangeTitle: (self: Notification, Text: string) -> (),
    ChangeDescription: (self: Notification, Text: string) -> (),
    ChangeStep: (self: Notification, NewStep: number) -> (),
    Destroy: (self: Notification) -> (),
}

export type KeybindToggle = {
    Normal: boolean,
    Visible: boolean,
    Holder: TextButton,
    Label: TextLabel,
    Checkbox: Frame,
    Loaded: boolean,

    Display: (self: KeybindToggle, State: boolean) -> (),
    SetText: (self: KeybindToggle, Text: string) -> (),
    SetVisibility: (self: KeybindToggle, Visibility: boolean) -> (),
    SetNormal: (self: KeybindToggle, Normal: boolean) -> (),
}

export type DraggableLabel = {
    Label: TextLabel,
    SetText: (self: DraggableLabel, Text: string) -> (),
    SetVisible: (self: DraggableLabel, Visible: boolean) -> (),
    SetPosition: (self: DraggableLabel, Position: UDim2) -> (),
    SetIcon: (self: DraggableLabel, Icon: string) -> (),
    SetIconPosition: (self: DraggableLabel, Position: string) -> (),
}

export type DraggableButton = {
    Button: TextButton,
    SetText: (self: DraggableButton, Text: string) -> (),
    SetIcon: (self: DraggableButton, Icon: string) -> (),
    SetIconPosition: (self: DraggableButton, Position: string) -> (),
}

export type DraggableImageButton = {
    Button: TextButton,
    SetIcon: (self: DraggableImageButton, Icon: string) -> (),
    SetIconSize: (self: DraggableImageButton, Size: number) -> (),
}


export type ButtonVariant = "Default" | "Primary" | "Ghost" | "Secondary"
export type ToggleVariant = "Default" | "Warning" | "Danger" | "Caution" | "Destructive"

export type ButtonInfo = {
    Text: string,
    Func: (FromKeyPicker: boolean?) -> (),
    DoubleClick: boolean?,
    Variant: ButtonVariant?,
    Icon: string | number | boolean?,
    IconColor: Color3?,
    Tooltip: string?,
    DisabledTooltip: string?,
    Risky: boolean?,
    Disabled: boolean?,
    Visible: boolean?,
}

export type ToggleInfo = {
    Text: string,
    Default: boolean?,
    Variant: ToggleVariant?,
    Callback: ((boolean) -> ())?,
    Changed: ((boolean) -> ())?,
    Tooltip: string?,
    DisabledTooltip: string?,
    Risky: boolean?,
    ConfirmDanger: boolean?,
    ConfirmTitle: string?,
    ConfirmDescription: string?,
    Disabled: boolean?,
    Visible: boolean?,
}

export type InputInfo = {
    Text: string,
    Default: string?,
    Finished: boolean?,
    Numeric: boolean?,
    ClearTextOnFocus: boolean?,
    Placeholder: string?,
    AllowEmpty: boolean?,
    EmptyReset: string?,
    MaxLength: number?,
    Tooltip: string?,
    DisabledTooltip: string?,
    Callback: ((string) -> ())?,
    Changed: ((string) -> ())?,
    Disabled: boolean?,
    Visible: boolean?,
}

export type SliderInfo = {
    Text: string,
    Default: number?,
    Min: number?,
    Max: number?,
    Rounding: number?,
    Prefix: string?,
    Suffix: string?,
    Compact: boolean?,
    HideMax: boolean?,
    FormatDisplayValue: ((Slider, number) -> string)?,
    Tooltip: string?,
    DisabledTooltip: string?,
    Callback: ((number) -> ())?,
    Changed: ((number) -> ())?,
    Disabled: boolean?,
    Visible: boolean?,
    AllowRightClickInput: boolean?,
}

export type DropdownInfo = {
    Text: string?,
    Values: { [any]: any },
    Default: any,
    DisabledValues: { any }?,
    ValueImages: { [any]: string }?,
    Multi: boolean?,
    DragSelect: boolean?,
    MaxVisibleDropdownItems: number?,
    SpecialType: "Player" | "Team"?,
    ExcludeLocalPlayer: boolean?,
    EnablePlayerImages: boolean?,
    AllowNull: boolean?,
    Searchable: boolean?,
    FormatDisplayValue: ((any) -> string)?,
    FormatListValue: ((any) -> string)?,
    Tooltip: string?,
    DisabledTooltip: string?,
    Callback: ((any) -> ())?,
    Changed: ((any) -> ())?,
    Disabled: boolean?,
    Visible: boolean?,
}

export type ViewportInfo = {
    Object: BasePart | Model,
    Camera: Camera?,
    Clone: boolean?,
    AutoFocus: boolean?,
    Interactive: boolean?,
    Height: number?,
    Visible: boolean?,
}

export type ImageInfo = {
    Image: string,
    Transparency: number?,
    Color: Color3?,
    RectOffset: Vector2?,
    RectSize: Vector2?,
    ScaleType: Enum.ScaleType?,
    Height: number?,
    Visible: boolean?,
}

export type VideoInfo = {
    Video: string,
    Looped: boolean?,
    Playing: boolean?,
    Volume: number?,
    Height: number?,
    Visible: boolean?,
}

export type UIPassthroughInfo = {
    Instance: GuiBase2d,
    Height: number?,
    Visible: boolean?,
}

export type KeyPickerInfo = {
    Text: string,
    Default: string?,
    Mode: "Toggle" | "Hold" | "Press"?,
    Modes: { "Toggle" | "Hold" | "Press" }?,
    SyncToggleState: boolean?,
    NoUI: boolean?,
    WaitForCallback: boolean?,
    Callback: ((boolean) -> ())?,
    ChangedCallback: ((Enum.KeyCode | Enum.UserInputType) -> ())?,
    Changed: ((Enum.KeyCode | Enum.UserInputType) -> ())?,
    Clicked: (() -> ())?,
}

export type ColorPickerInfo = {
    Default: Color3?,
    Transparency: number?,
    Title: string?,
    Resizable: boolean?,
    Callback: ((Color3) -> ())?,
    Changed: ((Color3) -> ())?,
}

export type LoadingInfo = {
    Title: string?,
    Icon: string | number?,
    IconSize: UDim2?,
    LoadingIcon: string | number?,
    LoadingIconColor: Color3?,
    LoadingIconTweenTime: number?,
    CurrentStep: number?,
    TotalSteps: number?,
    ShowSidebar: boolean?,
    AutoResizeHeight: boolean?,
    AlwaysOnTop: boolean?,
    WindowWidth: number?,
    WindowHeight: number?,
    ContentWidth: number?,
    SidebarWidth: number?,
}

export type ThemePreset = {
    BackgroundColor: Color3?,
    MainColor: Color3?,
    TopBarColor: Color3?,
    SurfaceColor: Color3?,
    RaisedColor: Color3?,
    ElementColor: Color3?,
    HoverColor: Color3?,
    AccentColor: Color3?,
    AccentSoftColor: Color3?,
    OutlineColor: Color3?,
    FontColor: Color3?,
    MutedFontColor: Color3?,
    ShadowColor: Color3?,
    Font: Font | Enum.Font?,
    RedColor: Color3?,
    WarningColor: Color3?,
    DestructiveColor: Color3?,
    DarkColor: Color3?,
    WhiteColor: Color3?,
    BackgroundImage: string | number?,
    CornerRadius: number?,
    IsLight: boolean?,
}

export type DeclarativeAddon = {
    Type: "KeyPicker" | "ColorPicker" | string,
    Id: (string | number)?,
    Kind: string?,
    OnChanged: ((any) -> ())?,
    OnClick: (() -> ())?,
    [string]: any,
}

export type DeclarativeElement = {
    Type: string,
    Id: (string | number)?,
    Kind: string?,
    Text: string?,
    Label: string?,
    Value: any?,
    Default: any?,
    OnChanged: ((any) -> ())?,
    OnClick: (() -> ())?,
    Addons: { DeclarativeAddon }?,
    [string]: any,
}

export type DeclarativeGroup = {
    Name: string,
    Id: (string | number)?,
    Side: ("Left" | "Right" | number)?,
    Icon: string?,
    Visible: boolean?,
    Collapsed: boolean?,
    DisableCollapsing: boolean?,
    Elements: { DeclarativeElement | string }?,
    Controls: { DeclarativeElement | string }?,
}

export type DeclarativeTab = {
    Name: string,
    Id: (string | number)?,
    Icon: string?,
    Description: string?,
    Order: number?,
    Groups: { DeclarativeGroup | string }?,
    Sections: { DeclarativeGroup | string }?,
}

export type AppInfo = {
    Title: string?,
    Footer: string?,
    Theme: (string | ThemePreset)?,
    Window: { [string]: any }?,
    Tabs: { DeclarativeTab | string }?,
    Pages: { DeclarativeTab | string }?,
    OnReady: ((any) -> ())?,
    [string]: any,
}


export type KeyPicker = {
    Text: string,
    Value: string,
    Toggled: boolean,
    Mode: "Toggle" | "Hold" | "Press",
    SyncToggleState: boolean,
    Callback: (Toggled: boolean) -> (),
    ChangedCallback: (Key: Enum.KeyCode | Enum.UserInputType) -> (),
    Changed: (Key: Enum.KeyCode | Enum.UserInputType) -> (),
    Clicked: () -> (),
    Type: "KeyPicker",
    Menu: ContextMenu,

    Display: (self: KeyPicker) -> (),
    Update: (self: KeyPicker) -> (),
    IsBound: (self: KeyPicker) -> boolean,
    GetState: (self: KeyPicker) -> boolean,
    OnChanged: (self: KeyPicker, Func: (Key: Enum.KeyCode | Enum.UserInputType) -> ()) -> (),
    OnClick: (self: KeyPicker, Func: () -> ()) -> (),
    DoClick: (self: KeyPicker) -> (),
    SetValue: (self: KeyPicker, Data: { string }) -> (),
    SetText: (self: KeyPicker, Text: string) -> (),
    Destroy: (self: KeyPicker) -> (),
}

export type ColorPicker = {
    Value: Color3,
    Transparency: number,
    Title: string?,
    Callback: (Value: Color3) -> (),
    Changed: (Value: Color3) -> (),
    Type: "ColorPicker",
    Hue: number,
    Sat: number,
    Vib: number,
    ColorMenu: ContextMenu,
    ContextMenu: ContextMenu,

    SetHSVFromRGB: (self: ColorPicker, Color: Color3) -> (),
    Display: (self: ColorPicker) -> (),
    Update: (self: ColorPicker) -> (),
    OnChanged: (self: ColorPicker, Func: (Value: Color3) -> ()) -> (),
    SetValue: (self: ColorPicker, HSV: { number }, Transparency: number?) -> (),
    SetValueRGB: (self: ColorPicker, Color: Color3, Transparency: number?) -> (),
    Destroy: (self: ColorPicker) -> (),
}

export type Addon = KeyPicker | ColorPicker


export type Label = {
    Text: string,
    DoesWrap: boolean,
    Addons: { [number]: Addon },
    Visible: boolean,
    Type: "Label",
    TextLabel: TextLabel,
    Container: GuiObject,
    Holder: TextLabel,

    SetVisible: (self: Label, Visible: boolean) -> (),
    SetText: (self: Label, Text: string) -> (),

    
    AddKeyPicker: (self: Label, Idx: string, Info: KeyPickerInfo) -> Label,
    AddColorPicker: (self: Label, Idx: string, Info: ColorPickerInfo) -> Label,
    Destroy: (self: Label) -> (),
}

export type Button = {
    Text: string,
    Func: (FromKeyPicker: boolean?) -> (),
    DoubleClick: boolean?,
    Variant: ButtonVariant,
    Icon: string | number | boolean?,
    IconColor: Color3?,
    Tooltip: string?,
    DisabledTooltip: string?,
    TooltipTable: Tooltip?,
    Risky: boolean,
    Disabled: boolean,
    Visible: boolean,
    Tween: Tween?,
    Type: "Button",
    Base: TextButton,
    Stroke: UIStroke,
    Label: TextLabel,
    IconImage: ImageLabel,
    Holder: Frame,
    SubButton: SubButton?,

    AddButton: (self: Button, Info: ButtonInfo | string, Func: (() -> ())?, Idx: string?) -> SubButton,
    UpdateColors: (self: Button) -> (),
    UpdateIcon: (self: Button) -> (),
    SetDisabled: (self: Button, Disabled: boolean) -> (),
    SetVariant: (self: Button, Variant: ButtonVariant) -> (),
    SetIcon: (self: Button, Icon: string | number | boolean?, IconColor: Color3?) -> (),
    SetVisible: (self: Button, Visible: boolean) -> (),
    SetText: (self: Button, Text: string) -> (),
    Destroy: (self: Button) -> (),
}

export type SubButton = {
    Text: string,
    Func: (FromKeyPicker: boolean?) -> (),
    DoubleClick: boolean?,
    Variant: ButtonVariant,
    Icon: string | number | boolean?,
    IconColor: Color3?,
    Tooltip: string?,
    DisabledTooltip: string?,
    TooltipTable: Tooltip?,
    Risky: boolean,
    Disabled: boolean,
    Visible: boolean,
    Tween: Tween?,
    Type: "SubButton",
    Base: TextButton,
    Stroke: UIStroke,
    Label: TextLabel,
    IconImage: ImageLabel,

    UpdateColors: (self: SubButton) -> (),
    UpdateIcon: (self: SubButton) -> (),
    SetDisabled: (self: SubButton, Disabled: boolean) -> (),
    SetVariant: (self: SubButton, Variant: ButtonVariant) -> (),
    SetIcon: (self: SubButton, Icon: string | number | boolean?, IconColor: Color3?) -> (),
    SetVisible: (self: SubButton, Visible: boolean) -> (),
    SetText: (self: SubButton, Text: string) -> (),
    Destroy: (self: SubButton) -> (),
}

export type Toggle = {
    Text: string,
    Value: boolean,
    Tooltip: string?,
    DisabledTooltip: string?,
    TooltipTable: Tooltip?,
    Callback: (Value: boolean) -> (),
    Changed: (Value: boolean) -> (),
    Risky: boolean,
    ConfirmDanger: boolean,
    ConfirmTitle: string?,
    ConfirmDescription: string?,
    ConfirmationPending: boolean,
    Disabled: boolean,
    Visible: boolean,
    Variant: "Checkbox" | "Switch",
    StyleVariant: ToggleVariant,
    Addons: { [number]: Addon },
    Type: "Toggle",
    TextLabel: TextLabel,
    Checkbox: Frame?,
    Checkmark: ImageLabel?,
    Container: GuiObject,
    Holder: TextButton,

    UpdateColors: (self: Toggle) -> (),
    Display: (self: Toggle) -> (),
    OnChanged: (self: Toggle, Func: (Value: boolean) -> ()) -> (),
    SetValue: (self: Toggle, Value: boolean) -> (),
    SetDisabled: (self: Toggle, Disabled: boolean) -> (),
    SetVariant: (self: Toggle, Variant: ToggleVariant) -> (),
    SetVisible: (self: Toggle, Visible: boolean) -> (),
    SetText: (self: Toggle, Text: string) -> (),

    
    AddKeyPicker: (self: Toggle, Idx: string, Info: KeyPickerInfo) -> Toggle,
    AddColorPicker: (self: Toggle, Idx: string, Info: ColorPickerInfo) -> Toggle,
    Destroy: (self: Toggle) -> (),
}

export type Input = {
    Text: string,
    Value: string,
    Finished: boolean,
    Numeric: boolean,
    ClearTextOnFocus: boolean,
    Placeholder: string,
    AllowEmpty: boolean,
    EmptyReset: string,
    Tooltip: string?,
    DisabledTooltip: string?,
    TooltipTable: Tooltip?,
    Callback: (Value: string) -> (),
    Changed: (Value: string) -> (),
    Disabled: boolean,
    Visible: boolean,
    Type: "Input",
    Holder: Frame,

    UpdateColors: (self: Input) -> (),
    OnChanged: (self: Input, Func: (Value: string) -> ()) -> (),
    SetValue: (self: Input, Text: string) -> (),
    SetDisabled: (self: Input, Disabled: boolean) -> (),
    SetVisible: (self: Input, Visible: boolean) -> (),
    SetText: (self: Input, Text: string) -> (),
    Destroy: (self: Input) -> (),
}

export type Slider = {
    Text: string,
    Value: number,
    Min: number,
    Max: number,
    Prefix: string,
    Suffix: string,
    Compact: boolean?,
    Rounding: number,
    Tooltip: string?,
    DisabledTooltip: string?,
    TooltipTable: Tooltip?,
    Callback: (Value: number) -> (),
    Changed: (Value: number) -> (),
    Disabled: boolean,
    Visible: boolean,
    AllowRightClickInput: boolean,
    Type: "Slider",
    Holder: Frame,

    UpdateColors: (self: Slider) -> (),
    Display: (self: Slider) -> (),
    OnChanged: (self: Slider, Func: (Value: number) -> ()) -> (),
    SetMax: (self: Slider, Value: number) -> (),
    SetMin: (self: Slider, Value: number) -> (),
    SetValue: (self: Slider, Value: number | string) -> (),
    SetDisabled: (self: Slider, Disabled: boolean) -> (),
    SetVisible: (self: Slider, Visible: boolean) -> (),
    SetAllowRightClickInput: (self: Slider, Allow: boolean) -> (),
    SetText: (self: Slider, Text: string) -> (),
    SetPrefix: (self: Slider, Prefix: string) -> (),
    SetSuffix: (self: Slider, Suffix: string) -> (),
    Destroy: (self: Slider) -> (),
}

export type Dropdown = {
    Connections: { RBXScriptConnection },
    Destroyed: boolean,

    Text: string?,
    Value: { [any]: boolean } | any,
    Values: { [any]: any },
    DisabledValues: { any },
    ValueImages: { [any]: string }?,
    Multi: boolean,
    DragSelect: boolean,
    SpecialType: "Player" | "Team"?,
    ExcludeLocalPlayer: boolean?,
    EnablePlayerImages: boolean?,
    Tooltip: string?,
    DisabledTooltip: string?,
    TooltipTable: Tooltip?,
    Callback: (Value: any) -> (),
    Changed: (Value: any) -> (),
    Disabled: boolean,
    Visible: boolean,
    Type: "Dropdown",
    Menu: ContextMenu,
    Holder: Frame,
    Default: { any },
    DefaultValues: { [any]: any },

    RecalculateListSize: (self: Dropdown, Count: number?) -> (),
    UpdateColors: (self: Dropdown) -> (),
    Display: (self: Dropdown) -> (),
    OnChanged: (self: Dropdown, Func: (Value: any) -> ()) -> (),
    GetActiveValues: (self: Dropdown, ReturnCount: boolean?) -> { any } | number,
    RefreshPool: (self: Dropdown) -> (),
    BuildDropdownList: (self: Dropdown) -> (),
    RunChanged: (self: Dropdown) -> (),
    SetValue: (self: Dropdown, Value: any) -> (),
    SetValues: (self: Dropdown, Values: { [any]: any }) -> (),
    AddValues: (self: Dropdown, Values: { [any]: any } | string) -> (),
    SetDisabledValues: (self: Dropdown, DisabledValues: { any }) -> (),
    AddDisabledValues: (self: Dropdown, DisabledValues: { any } | string) -> (),
    SetValueImages: (self: Dropdown, ValueImages: { [any]: string }) -> (),
    AddValueImages: (self: Dropdown, ValueImages: { [any]: string }) -> (),
    SetDisabled: (self: Dropdown, Disabled: boolean) -> (),
    SetVisible: (self: Dropdown, Visible: boolean) -> (),
    SetText: (self: Dropdown, Text: string) -> (),
    SetDragSelect: (self: Dropdown, Value: boolean) -> (),
    Destroy: (self: Dropdown) -> (),
}

export type Viewport = {
    Object: BasePart | Model,
    Camera: Camera,
    Interactive: boolean,
    AutoFocus: boolean,
    Visible: boolean,
    Type: "Viewport",
    Holder: Frame,
    Box: Frame,
    Frame: ViewportFrame,
    Holder: Frame,

    SetObject: (self: Viewport, Object: Instance, Clone: boolean?) -> (),
    SetHeight: (self: Viewport, Height: number) -> (),
    Focus: (self: Viewport) -> (),
    SetCamera: (self: Viewport, Camera: Camera) -> (),
    SetInteractive: (self: Viewport, Interactive: boolean) -> (),
    SetVisible: (self: Viewport, Visible: boolean) -> (),
    Destroy: (self: Viewport) -> (),
}

export type Image = {
    Image: string,
    Color: Color3,
    RectOffset: Vector2,
    RectSize: Vector2,
    Height: number,
    ScaleType: Enum.ScaleType,
    Transparency: number,
    Visible: boolean,
    Type: "Image",
    Holder: Frame,

    SetHeight: (self: Image, Height: number) -> (),
    SetImage: (self: Image, NewImage: string) -> (),
    SetColor: (self: Image, Color: Color3) -> (),
    SetRectOffset: (self: Image, RectOffset: Vector2) -> (),
    SetRectSize: (self: Image, RectSize: Vector2) -> (),
    SetScaleType: (self: Image, ScaleType: Enum.ScaleType) -> (),
    SetTransparency: (self: Image, Transparency: number) -> (),
    SetVisible: (self: Image, Visible: boolean) -> (),
    Destroy: (self: Image) -> (),
}

export type Video = {
    Video: string,
    Looped: boolean,
    Playing: boolean,
    Volume: number,
    Height: number,
    Visible: boolean,
    Type: "Video",
    Holder: Frame,
    VideoFrame: VideoFrame,

    SetHeight: (self: Video, Height: number) -> (),
    SetVideo: (self: Video, NewVideo: string) -> (),
    SetLooped: (self: Video, Looped: boolean) -> (),
    SetVolume: (self: Video, Volume: number) -> (),
    SetPlaying: (self: Video, Playing: boolean) -> (),
    Play: (self: Video) -> (),
    Pause: (self: Video) -> (),
    SetVisible: (self: Video, Visible: boolean) -> (),
    Destroy: (self: Video) -> (),
}

export type UIPassthrough = {
    Instance: GuiBase2d,
    Height: number,
    Visible: boolean,
    Type: "UIPassthrough",
    Holder: Frame,

    SetHeight: (self: UIPassthrough, Height: number) -> (),
    SetInstance: (self: UIPassthrough, Instance: GuiBase2d) -> (),
    SetVisible: (self: UIPassthrough, Visible: boolean) -> (),
    Destroy: (self: UIPassthrough) -> (),
}

export type Divider = {
    Type: "Divider",
    Holder: Frame,
    Destroy: (self: Divider) -> (),
}

export type Element =
    Label
    | Button
    | Toggle
    | Input
    | Slider
    | Dropdown
    | Viewport
    | Image
    | Video
    | UIPassthrough
    | Divider
export type Option =
    Toggle
    | Input
    | Slider
    | Dropdown
    | Viewport
    | Image
    | Video
    | UIPassthrough
    | KeyPicker
    | ColorPicker


export type BaseGroupbox = {
    AddDivider: (self: Groupbox, MarginTop: number?, MarginBottom: number?) -> (),
    AddLabel: (
        self: Groupbox,
        Info: { Text: string, DoesWrap: boolean?, Size: number?, Visible: boolean?, Idx: string? } | string,
        DoesWrap: boolean?,
        Idx: string?
    ) -> Label,
    AddButton: (self: Groupbox, Info: ButtonInfo | string, Func: (() -> ())?, Idx: string?) -> Button,
    AddCheckbox: (self: Groupbox, Idx: string, Info: ToggleInfo) -> Toggle,
    AddToggle: (self: Groupbox, Idx: string, Info: ToggleInfo) -> Toggle,
    AddInput: (self: Groupbox, Idx: string, Info: InputInfo) -> Input,
    AddSlider: (self: Groupbox, Idx: string, Info: SliderInfo) -> Slider,
    AddDropdown: (self: Groupbox, Idx: string, Info: DropdownInfo) -> Dropdown,
    AddViewport: (self: Groupbox, Idx: string, Info: ViewportInfo) -> Viewport,
    AddImage: (self: Groupbox, Idx: string, Info: ImageInfo) -> Image,
    AddVideo: (self: Groupbox, Idx: string, Info: VideoInfo) -> Video,
    AddUIPassthrough: (self: Groupbox, Idx: string, Info: UIPassthroughInfo) -> UIPassthrough,
    AddDependencyBox: (self: Groupbox) -> DependencyBox,
    AddDependencyGroupbox: (self: Groupbox) -> DependencyGroupbox,
    AddTabbox: (self: Groupbox, Info: { Name: string?, IconName: string? } | string) -> Tabbox,
    SetVisible: (self: Groupbox, Visible: boolean) -> (),
    Show: (self: Groupbox) -> (),
    Hide: (self: Groupbox) -> (),
}

export type DependencyBox = BaseGroupbox & {
    Visible: boolean,
    Dependencies: { [number]: { Element } },
    Holder: Frame,
    Container: Frame,
    Elements: { [number]: Element },
    DependencyBoxes: { [number]: DependencyBox },

    Resize: (self: DependencyBox) -> (),
    Update: (self: DependencyBox, CancelSearch: boolean?) -> (),
    SetupDependencies: (self: DependencyBox, Dependencies: { { Element } }) -> (),
}

export type DependencyGroupbox = BaseGroupbox & {
    Visible: boolean,
    Dependencies: { [number]: { Element } },
    BoxHolder: Frame,
    Holder: Frame,
    Container: Frame,
    Tab: Tab,
    Elements: { [number]: Element },
    DependencyBoxes: { [number]: DependencyBox },

    Resize: (self: DependencyGroupbox) -> (),
    Update: (self: DependencyGroupbox, CancelSearch: boolean?) -> (),
    SetupDependencies: (self: DependencyGroupbox, Dependencies: { { Element } }) -> (),
}

export type Groupbox = BaseGroupbox & {
    BoxHolder: Frame,
    Holder: Frame,
    Container: Frame,
    Tab: Tab,
    DependencyBoxes: { [number]: DependencyBox },
    Elements: { [number]: Element },

    Resize: (self: Groupbox) -> (),
    SetOrder: (self: Groupbox, Order: number) -> (),
    SetCollapsed: (self: Groupbox, Collapsed: boolean) -> (),
    ToggleCollapsed: (self: Groupbox) -> (),
}

export type SubTab = BaseGroupbox & {
    ButtonHolder: TextButton,
    Container: Frame,
    Tab: Tab,
    Elements: { [number]: Element },
    DependencyBoxes: { [number]: DependencyBox },

    Show: (self: SubTab) -> (),
    Hide: (self: SubTab) -> (),
    Resize: (self: SubTab) -> (),
}

export type Tabbox = {
    ActiveTab: SubTab?,
    BoxHolder: Frame,
    Holder: Frame,
    Tabs: { [string]: SubTab },

    AddTab: (self: Tabbox, Name: string, IconName: string?) -> (SubTab, number),
}

export type Tab = {
    Window: Window,
    Groupboxes: { [string]: Groupbox },
    Tabboxes: { [string]: Tabbox },
    DependencyGroupboxes: { [number]: DependencyGroupbox },
    Sides: { ScrollingFrame },
    WarningBox: { IsNormal: boolean, LockSize: boolean, Visible: boolean, Title: string, Text: string },

    UpdateWarningBox: (
        self: Tab,
        Info: { IsNormal: boolean?, LockSize: boolean?, Visible: boolean?, Title: string?, Text: string? }
    ) -> (),
    Resize: (self: Tab, ResizeWarningBox: boolean?) -> (),
    AddGroupbox: (
        self: Tab,
        Info: {
            Side: number,
            Name: string,
            IconName: string?,
            Visible: boolean?,
            Collapsed: boolean?,
            DisableCollapsing: boolean?,
        }
    ) -> Groupbox,
    AddLeftGroupbox: (
        self: Tab,
        Name: string,
        IconName: string?,
        Visible: boolean?,
        Collapsed: boolean?,
        DisableCollapsing: boolean?
    ) -> Groupbox,
    AddRightGroupbox: (
        self: Tab,
        Name: string,
        IconName: string?,
        Visible: boolean?,
        Collapsed: boolean?,
        DisableCollapsing: boolean?
    ) -> Groupbox,
    AddTabbox: (self: Tab, Info: { Side: number, Name: string? }) -> Tabbox,
    AddLeftTabbox: (self: Tab, Name: string?) -> Tabbox,
    AddRightTabbox: (self: Tab, Name: string?) -> Tabbox,
    Hover: (self: Tab, Hovering: boolean) -> (),
    Show: (self: Tab) -> (),
    Hide: (self: Tab) -> (),
    SetVisible: (self: Tab, Visible: boolean) -> (),
    SetOrder: (self: Tab, Order: number) -> (),
}

export type KeyTab = BaseGroupbox & {
    Elements: { [any]: any },
    IsKeyTab: true,
    Window: Window,
    Container: ScrollingFrame,

    AddKeyBox: (self: KeyTab, ExpectedKey: string?, Callback: (Success: boolean, Key: string) -> ()) -> (),
    Resize: (self: KeyTab) -> (),
    Hover: (self: KeyTab, Hovering: boolean) -> (),
    Show: (self: KeyTab) -> (),
    Hide: (self: KeyTab) -> (),
    SetVisible: (self: KeyTab, Visible: boolean) -> (),
}

export type LoadingErrorButtonInfo = {
    Title: string?,
    Variant: ButtonVariant?,
    Callback: ((Loading) -> ())?,
}

export type LoadingSidebar = BaseGroupbox & {
    Elements: { [number]: Element },
    DependencyBoxes: { [number]: DependencyBox },
    Tabboxes: { [string]: Tabbox },
    BoxHolder: ScrollingFrame,
    Container: ScrollingFrame,
    Tab: {
        Elements: { [number]: Element },
        DependencyBoxes: { [number]: DependencyBox },
        DependencyGroupboxes: { [number]: DependencyGroupbox },
        Tabboxes: { [string]: Tabbox },
    },

    Resize: (self: LoadingSidebar) -> (),
}

export type Loading = {
    CurrentStep: number,
    TotalSteps: number,
    ShowSidebar: boolean,
    AutoResizeHeight: boolean,
    AlwaysOnTop: boolean,
    IsError: boolean,
    Destroyed: boolean,
    WindowWidth: number,
    WindowHeight: number,
    BaseWindowHeight: number,
    WindowErrorHeight: number,
    ContentWidth: number,
    SidebarWidth: number,
    ScreenGui: ScreenGui,
    Sidebar: LoadingSidebar,

    UpdateLayout: (self: Loading) -> (),
    RecalculateLoadingHeight: (self: Loading) -> (),
    SetMessage: (self: Loading, Text: string) -> (),
    SetDescription: (self: Loading, Text: string) -> (),
    SetLoadingIcon: (self: Loading, Icon: string | number) -> (),
    SetLoadingIconTweenTime: (self: Loading, TweenTime: number) -> (),
    SetLoadingIconColor: (self: Loading, Color: Color3) -> (),
    SetCurrentStep: (self: Loading, Step: number) -> (),
    SetTotalSteps: (self: Loading, Steps: number) -> (),
    SetWindowHeight: (self: Loading, Height: number) -> (),
    SetWindowWidth: (self: Loading, Width: number) -> (),
    SetContentWidth: (self: Loading, Width: number) -> (),
    SetSidebarWidth: (self: Loading, Width: number) -> (),
    ShowSidebarPage: (self: Loading, Bool: boolean) -> (),
    ShowErrorPage: (self: Loading, Enabled: boolean) -> (),
    RecalculateErrorHeight: (self: Loading) -> (),
    SetErrorMessage: (self: Loading, Text: string) -> (),
    SetErrorButtons: (self: Loading, Buttons: { [string]: LoadingErrorButtonInfo }) -> (),
    Destroy: (self: Loading) -> (),
    Continue: (self: Loading) -> (),
}

export type DialogButtonInfo = {
    Title: string,
    Variant: ButtonVariant?,
    WaitTime: number?,
    Order: number?,
    Callback: ((Dialog) -> ())?,
}

export type Dialog = {
    SetTitle: (self: Dialog, Title: string) -> (),
    SetDescription: (self: Dialog, Description: string) -> (),
    AddFooterButton: (self: Dialog, ButtonIdx: string, ButtonInfo: DialogButtonInfo) -> (),
    RemoveFooterButton: (self: Dialog, ButtonIdx: string) -> (),
    SetButtonDisabled: (self: Dialog, ButtonIdx: string, Disabled: boolean) -> (),
    SetButtonOrder: (self: Dialog, ButtonIdx: string, Order: number) -> (),
    Dismiss: (self: Dialog) -> (),
}


export type Window = {
    AlwaysOnTop: boolean,
    Frame: CanvasGroup,
    CompactLauncher: TextButton?,
    VisibilityChanged: BindableEvent,
    IsSidebarCompacted: (self: Window) -> boolean,
    GetSidebarWidth: (self: Window) -> number,
    SetSidebarWidth: (self: Window, Width: number) -> (),
    FitToViewport: (self: Window) -> (),
    QueueFitToViewport: (self: Window) -> (),
    SetCompact: (self: Window, State: boolean) -> (),
    IsSingleColumnLayout: (self: Window) -> boolean,
    SetResponsiveLayoutEnabled: (self: Window, Enabled: boolean) -> (),
    RefreshResponsiveLayout: (self: Window) -> (),
    ShowTabInfo: (self: Window, Name: string, Description: string) -> (),
    HideTabInfo: (self: Window) -> (),
    AddTab: (
        self: Window,
        Info: { Name: string, Icon: string?, Description: string?, Order: number? } | string,
        Icon: string?,
        Description: string?,
        Order: number?
    ) -> Tab,
    AddKeyTab: (
        self: Window,
        Info: { Name: string, Icon: string?, Description: string? } | string,
        Icon: string?,
        Description: string?
    ) -> KeyTab,
    AddDialog: (
        self: Window,
        Idx: string,
        Info: {
            Title: string,
            Description: string?,
            Icon: string?,
            TitleColor: Color3 | string?,
            DescriptionColor: Color3 | string?,
            AutoDismiss: boolean?,
            OutsideClickDismiss: boolean?,
            OnDismiss: ((Dialog) -> ())?,
            FooterButtons: { [string]: DialogButtonInfo }?,
        }
    ) -> Dialog,
    ChangeTitle: (self: Window, Title: string) -> (),
    SetBackgroundImage: (self: Window, Image: string) -> (),
    SetFooter: (self: Window, Footer: string) -> (),
    SetAlwaysOnTop: (self: Window, Enabled: boolean) -> (),
    SetCornerRadius: (self: Window, Radius: number) -> (),
    SetAnimations: (
        self: Window,
        Animations: { [string]: boolean }?,
        TabTransitionTime: number?,
        TabSwipeOffset: number?,
        TabSwipeFrom: ("left" | "right" | "top" | "bottom" | string)?
    ) -> (),
    RefreshCompactLauncher: (self: Window, Animate: boolean?) -> (),
    SetCompactLauncherIcon: (self: Window, Icon: string | number) -> (),
    SetCompactLauncherPosition: (self: Window, Position: UDim2) -> (),
    SetCompactLauncherTitle: (self: Window, Title: string?) -> (),
    SetCompactLauncherWidth: (self: Window, Width: number) -> (),
    SetCompactLauncherDraggable: (self: Window, Draggable: boolean) -> (),
    Toggle: (self: Window, Value: boolean?, Source: string?) -> (),
}

export type App = {
    Destroyed: boolean,
    Library: any,
    Window: Window,
    Tabs: { [string | number]: Tab },
    Pages: { [string | number]: Tab },
    Groups: { [string | number]: Groupbox },
    Sections: { [string | number]: Groupbox },
    Refs: { [string | number]: Element | Addon },
    All: { Element | Addon },
    Get: (self: App, Id: string | number) -> (Element | Addon)?,
    Toggle: (self: App, Value: boolean?) -> (),
    Notify: (self: App, ...any) -> Notification,
    Destroy: (self: App) -> (),
}


export type Library = {
    ReleaseVersion: "0.0.1-release-6",
    
    LocalPlayer: Player,
    DevicePlatform: Enum.Platform?,
    IsMobile: boolean,
    IsRobloxFocused: boolean,
    ScreenGui: ScreenGui?,
    Window: Window?,
    SearchText: string,
    SearchDebounce: number,
    Searching: boolean,
    GlobalSearch: boolean,
    LastSearchTab: Tab?,
    ActiveTab: Tab?,
    ActiveLoading: Loading?,
    Tabs: { [string]: Tab | KeyTab },
    DependencyBoxes: { [number]: DependencyBox | DependencyGroupbox },
    KeybindFrame: CanvasGroup?,
    KeybindContainer: Frame?,
    KeybindAnimationScale: UIScale?,
    KeybindToggles: { [number]: KeybindToggle },
    KeybindMenuRequested: boolean,
    KeybindMenuVisible: boolean,
    Notifications: { [GuiObject]: Notification },
    Watermark: DraggableLabel?,
    WatermarkSide: "Left" | "Right",
    WatermarkDraggable: boolean,
    ClickSound: Sound?,
    ClickSounds: boolean,
    ClickSoundId: string,
    ClickSoundVolume: number,
    LastClickSoundAt: number,
    ToggleKeybind: Enum.KeyCode,
    TweenInfo: TweenInfo,
    NotifyTweenInfo: TweenInfo,
    TabTransitionInfo: TweenInfo,
    TabExitTransitionInfo: TweenInfo,
    KeybindMenuTweenInfo: TweenInfo,
    KeybindRowTweenInfo: TweenInfo,
    TabSwipeOffset: number,
    TabSwipeFrom: string,
    Animations: {
        ToggleWindow: boolean,
        TabSwitch: boolean,
        Groupbox: boolean,
        Dropdown: boolean,
        KeyPicker: boolean,
    },
    Toggled: boolean,
    Unloaded: boolean,
    Labels: { [string | number]: Label },
    Buttons: { [string | number]: Button | SubButton },
    Toggles: { [string | number]: Toggle },
    Options: { [string | number]: Option },
    NotifySide: "Right" | "Left",
    ShowCustomCursor: boolean,
    ForceCheckbox: boolean,
    TooltipsEnabled: boolean,
    AppearanceLocked: boolean,
    ThemeFontOverride: Font?,
    ShowToggleFrameInKeybinds: boolean,
    NotifyOnError: boolean,
    CantDragForced: boolean,
    DraggableElements: { GuiObject },
    Signals: { [number]: RBXScriptConnection },
    UnloadSignals: { [number]: () -> () },
    MinSize: Vector2,
    DPIScale: number,
    CornerRadius: number,
    IsLightTheme: boolean,
    Scheme: Scheme,
    DefaultTheme: "Default",
    CurrentTheme: "Default" | "Metal" | "Midnight" | "Steel" | "Sage" | "Ash",
    Themes: {
        Default: ThemePreset,
        Metal: ThemePreset,
        Midnight: ThemePreset,
        Steel: ThemePreset,
        Sage: ThemePreset,
        Ash: ThemePreset,
    },
    Registry: { [Instance]: { [string]: string | () -> any } },
    ColorRevision: number,
    Scales: { [GuiObject]: { [string]: any } },
    ScalesOffset: { [GuiObject]: { [string]: any } },
    CopiedColor: { Color3 | number }?,
    ImageManager: {
        AddAsset: (AssetName: string, RobloxAssetId: number, URL: string, ForceRedownload: boolean?) -> nil,
        GetAsset: (AssetName: string) -> string?,
        DownloadAsset: (AssetName: string, ForceRedownload: boolean?) -> nil,
        PreloadAssets: () -> (),
    },

    Fetch: (self: Library, URL: string) -> (boolean, string),
    
    UpdateDependencyBoxes: (self: Library) -> (),
    QueueDependencyUpdate: (self: Library) -> (),
    UpdateSearch: (self: Library, SearchText: string) -> (),
    QueueSearch: (self: Library, SearchText: string) -> (),
    AddToRegistry: (self: Library, Instance: Instance, Properties: { [string]: string | () -> any }) -> (),
    RemoveFromRegistry: (self: Library, Instance: Instance) -> (),
    UpdateColorsUsingRegistry: (self: Library) -> (),
    RefreshThemeState: (self: Library) -> (),
    SetDPIScale: (self: Library, DPIScale: number) -> (),
    PlayTween: (self: Library, Instance: Instance, Slot: string, TweenInfoValue: TweenInfo, Properties: { [string]: any }) -> Tween?,
    CancelTween: (self: Library, Instance: Instance, Slot: string) -> (),
    SetClickSound: (self: Library, SoundId: string | number | boolean, Volume: number?) -> (),
    PlayClickSound: (self: Library) -> (),
    GiveSignal: (self: Library, Connection: RBXScriptConnection) -> RBXScriptConnection,
    GetIcon: (self: Library, IconName: string) -> Icon?,
    GetCustomIcon: (self: Library, IconName: string) -> Icon?,
    Validate: (self: Library, Table: { [string]: any }, Template: { [string]: any }) -> { [string]: any },
    ResetCursorIcon: (self: Library) -> (),
    ChangeCursorIcon: (self: Library, ImageId: string) -> (),
    ChangeCursorIconSize: (self: Library, Size: UDim2) -> (),
    GetBetterColor: (self: Library, Color: Color3, Add: number) -> Color3,
    GetAccentSurfaceColor: (self: Library, Strength: number?) -> Color3,
    GetSurfaceColor: (self: Library, Level: ("Surface" | "Raised" | "Element" | "Hover" | string)?) -> Color3,
    GetMutedFontColor: (self: Library) -> Color3,
    GetLighterColor: (self: Library, Color: Color3) -> Color3,
    GetDarkerColor: (self: Library, Color: Color3) -> Color3,
    GetKeyString: (self: Library, KeyCode: Enum.KeyCode) -> string,
    GetTextBounds: (self: Library, Text: string, Font: Font, Size: number, Width: number?) -> (number, number),
    ClearTextBoundsCache: (self: Library) -> (),
    MouseIsOverFrame: (self: Library, Frame: GuiObject, Mouse: Vector2) -> boolean,
    IsInsideFrame: (self: Library, ParentFrame: GuiObject, Frame: GuiObject) -> boolean,
    SafeCallback: (self: Library, Func: (...any) -> ...any, ...any) -> ...any,
    MakeDraggable: (
        self: Library,
        UI: GuiObject,
        DragFrame: GuiObject,
        IgnoreToggled: boolean?,
        IsMainWindow: boolean?,
        CanDrag: (() -> boolean)?
    ) -> (),
    MakeResizable: (self: Library, UI: GuiObject, DragFrame: GuiObject, Callback: (() -> ())?) -> (),
    MakeCover: (self: Library, Holder: GuiObject, Place: string) -> Frame,
    MakeLine: (
        self: Library,
        Frame: GuiObject,
        Info: { AnchorPoint: Vector2?, Position: UDim2, Size: UDim2, Color: (string | Color3 | () -> Color3)? }
    ) -> Frame,
    AddOutline: (self: Library, Frame: GuiObject) -> Frame,
    AddSoftShadow: (self: Library, Frame: GuiObject, BlurRadius: number?, Transparency: number?, Offset: UDim2?) -> UIShadow?,
    AddBlank: (self: Library, Frame: GuiObject, Size: UDim2) -> (),
    MakeOutline: (self: Library, Frame: GuiObject, Corner: number?, ZIndex: number?) -> Frame,
    AddDraggableLabel: (
        self: Library,
        Text: string
            | {
                Text: string,
                Icon: string?,
                IconPosition: string?,
                Position: UDim2?,
                AnchorPoint: Vector2?,
                TextSize: number?,
                BackgroundColor: string | Color3?,
                Draggable: boolean?,
            },
        Icon: string?,
        IconPosition: string?
    ) -> DraggableLabel,
    AddDraggableButton: (
        self: Library,
        Text: string
            | {
                Text: string,
                Callback: (() -> ())?,
                Func: (() -> ())?,
                ExcludeScaling: boolean?,
                ExcludeDragging: boolean?,
                Icon: string?,
                IconPosition: string?,
            },
        Func: ((DraggableButton) -> ())?,
        ExcludeScaling: boolean?,
        ExcludeDragging: boolean?,
        Icon: string?,
        IconPosition: string?
    ) -> DraggableButton,
    AddDraggableImageButton: (
        self: Library,
        Icon: string
            | {
                Icon: string,
                IconSize: number?,
                Callback: (() -> ())?,
                Func: (() -> ())?,
                ExcludeScaling: boolean?,
                ExcludeDragging: boolean?,
            },
        IconSize: number?,
        Func: ((DraggableImageButton) -> ())?,
        ExcludeScaling: boolean?,
        ExcludeDragging: boolean?
    ) -> DraggableImageButton,
    AddDraggableMenu: (self: Library, Name: string) -> (CanvasGroup, Frame, UIScale),
    HasVisibleKeybinds: (self: Library) -> boolean,
    RefreshKeybindMenu: (self: Library) -> (),
    SetKeybindMenuVisible: (self: Library, Visible: boolean) -> (),
    AnimateTabHover: (self: Library, Button: TextButton, Label: TextLabel, Icon: ImageLabel?, Hovering: boolean) -> (),
    AnimateTabSelection: (self: Library, Button: TextButton, Label: TextLabel, Indicator: Frame, Icon: ImageLabel?, Selected: boolean) -> (),
    SetWatermarkVisibility: (self: Library, Visible: boolean) -> (),
    SetWatermark: (self: Library, Text: string) -> (),
    SetWatermarkSide: (self: Library, Side: "Left" | "Right") -> (),
    SetWatermarkDraggable: (self: Library, Draggable: boolean) -> (),
    AddContextMenu: (
        self: Library,
        Holder: GuiObject,
        Size: UDim2 | () -> UDim2,
        Offset: { [number]: number } | () -> { [number]: number },
        List: number?,
        ActiveCallback: ((boolean) -> ())?
    ) -> ContextMenu,
    AddTooltip: (self: Library, InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject) -> Tooltip,
    OnUnload: (self: Library, Callback: () -> ()) -> (),
    Unload: (self: Library) -> (),
    SetIconModule: (self: Library, module: any) -> (),
    ResolveThemeName: (self: Library, Theme: any) -> ("Default" | "Metal" | "Midnight" | "Steel" | "Sage" | "Ash"),
    SetTheme: (self: Library, Theme: string | ThemePreset) -> Library,
    LoadCustomFont: (self: Library, Name: string, URL: string, Weight: number?) -> (Font?, string?),
    SetThemeFont: (self: Library, FontFace: Font | Enum.Font) -> Library,
    SetFont: (self: Library, FontFace: Font | Enum.Font, SkipRegistryUpdate: boolean?) -> (),
    SetNotifySide: (self: Library, Side: "Left" | "Right") -> (),
    UpdateNotificationPositions: (self: Library, Snap: boolean?) -> (),
    Notify: (
        self: Library,
        Info: {
            Title: string?,
            Description: string,
            Time: number?,
            SoundId: string | number?,
            Volume: number?,
            Steps: number?,
            Persist: boolean?,
            TitleColor: Color3?,
            DescriptionColor: Color3?,
            Icon: string | number?,
            IconColor: Color3 | string?,
            BigIcon: string?,
        } | string,
        Time: number?,
        SoundId: string | number?
    ) -> Notification,
    CreateLoading: (self: Library, LoadingInfo: LoadingInfo) -> Loading,
    CreateWindow: (
        self: Library,
        WindowInfo: {
            Title: string?,
            Footer: string?,
            Position: UDim2?,
            Size: UDim2?,
            Icon: string?,
            IconSize: UDim2?,
            BackgroundImage: string?,
            AutoShow: boolean?,
            Center: boolean?,
            Resizable: boolean?,
            DisableSearch: boolean?,
            SearchbarSize: UDim2?,
            GlobalSearch: boolean?,
            CornerRadius: number?,
            NotifySide: "Left" | "Right"?,
            ShowCustomCursor: boolean?,
            AlwaysOnTop: boolean?,
            Font: Font | Enum.Font?,
            ToggleKeybind: Enum.KeyCode?,
            ShowCompactLauncher: boolean?,
            CompactLauncherIcon: string | number?,
            CompactLauncherSize: number?,
            CompactLauncherWidth: number?,
            CompactLauncherTitle: string?,
            CompactLauncherPosition: UDim2?,
            CompactLauncherAnchorPoint: Vector2?,
            CompactLauncherDraggable: boolean?,
            ShowMobileButtons: boolean?,
            MobileButtonsSide: "Left" | "Right"?,
            UnlockMouseWhileOpen: boolean?,
            EnableSidebarResize: boolean?,
            EnableCompacting: boolean?,
            DisableCompactingSnap: boolean?,
            SidebarCompacted: boolean?,
            MinContainerWidth: number?,
            ResponsiveLayout: boolean?,
            SingleColumnWidth: number?,
            HideSearchAtWidth: number?,
            MinSidebarWidth: number?,
            SidebarCompactWidth: number?,
            SidebarCollapseThreshold: number?,
            CompactWidthActivation: number?,
            Animations: {
                ToggleWindow: boolean?,
                TabSwitch: boolean?,
                Groupbox: boolean?,
                Dropdown: boolean?,
                KeyPicker: boolean?,
            }?,
            TabTransitionTime: number?,
            TabSwipeOffset: number?,
            TabSwipeFrom: ("left" | "right" | "top" | "bottom" | string)?,
        }
    ) -> Window,
    Create: (self: Library, AppInfo: AppInfo) -> App,
    Mount: (self: Library, AppInfo: AppInfo) -> App,
    create: (AppInfo: AppInfo) -> App,
    mount: (AppInfo: AppInfo) -> App,
    Toggle: (self: Library, Value: boolean?, Source: string?) -> (),
}

return nil
