export type Item = {
    Id: string | number?,
    Name: string?,
    Category: string?,
    Image: string | number?,
    Tags: { string }?,
    Badges: { string }?,
    Disabled: boolean?,
    Locked: boolean?,
    Favorite: boolean?,
    [string]: any,
}

export type Connection = {
    Connected: boolean,
    Disconnect: (self: Connection) -> (),
}

export type Query = {
    Search: string?,
    Category: string?,
    FavoritesOnly: boolean?,
    Sort: "Name" | "Original"?,
}

export type Model = {
    Destroyed: boolean,
    Revision: number,
    ItemsRevision: number,
    GetItems: (self: Model) -> { Item },
    GetItem: (self: Model, Id: string | number) -> Item?,
    GetSelected: (self: Model) -> Item?,
    SetItems: (self: Model, Items: { Item | string | number }) -> Model,
    AddItem: (self: Model, Item: Item | string | number) -> Item,
    UpdateItem: (self: Model, Id: string | number, Changes: Item) -> boolean,
    RemoveItem: (self: Model, Id: string | number) -> boolean,
    Select: (self: Model, Id: string | number?) -> boolean,
    SetFavorite: (self: Model, Id: string | number, Value: boolean) -> boolean,
    Query: (self: Model, Options: Query?) -> { Item },
    Subscribe: (self: Model, Callback: (Model) -> ()) -> Connection,
    Bind: (self: Model, View: any) -> Connection,
    Destroy: (self: Model) -> (),
}

export type Module = {
    ReleaseVersion: string,
    Create: (Info: { Items: { Item | string | number }?, Selected: string | number? }?) -> Model,
}

return {}
