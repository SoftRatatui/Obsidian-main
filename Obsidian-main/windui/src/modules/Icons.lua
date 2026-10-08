-- Icon lookup for the MonHub build of WindUI.
-- Lucide ships inside the bundle, so nothing is downloaded at startup.
-- Extra packs can still be registered with AddIcons.

local Lucide = require("./Lucide")

local IconModule = {
	IconsType = "lucide",

	New = nil,
	IconThemeTag = nil,

	Icons = {},
}

local Aliases = {
	["sfsymbols:checkmark"] = "check",
	["sfsymbols:sunMinFill"] = "sun-dim",
	["sfsymbols:sunMaxFill"] = "sun",
}

local LucideCache = {}

local function ParseIconString(IconString)
	if type(IconString) == "string" then
		local SplitIndex = IconString:find(":")
		if SplitIndex then
			return IconString:sub(1, SplitIndex - 1), IconString:sub(SplitIndex + 1)
		end
	end
	return nil, IconString
end

local function GetLucide(Name)
	local Cached = LucideCache[Name]
	if Cached ~= nil then
		return Cached or nil
	end

	local Asset = Lucide.GetAsset(Name)
	local Result = Asset
			and {
				Asset.Url,
				{
					ImageRectSize = Asset.ImageRectSize,
					ImageRectPosition = Asset.ImageRectOffset,
				},
			}
		or false
	LucideCache[Name] = Result
	return Result or nil
end

function IconModule.AddIcons(PackName, IconsData)
	if type(PackName) ~= "string" or type(IconsData) ~= "table" then
		error("AddIcons: packName must be string, iconsData must be table")
	end

	local Pack = IconModule.Icons[PackName]
	if not Pack then
		Pack = { Icons = {}, Spritesheets = {} }
		IconModule.Icons[PackName] = Pack
	end

	for IconName, IconValue in pairs(IconsData) do
		if type(IconValue) == "number" or (type(IconValue) == "string" and IconValue:match("^rbxassetid://")) then
			local ImageId = type(IconValue) == "number" and "rbxassetid://" .. tostring(IconValue) or IconValue

			Pack.Icons[IconName] = {
				Image = ImageId,
				ImageRectSize = Vector2.new(0, 0),
				ImageRectPosition = Vector2.new(0, 0),
			}
			Pack.Spritesheets[ImageId] = ImageId
		elseif type(IconValue) == "table" and IconValue.Image and IconValue.ImageRectSize and IconValue.ImageRectPosition then
			local ImageId = type(IconValue.Image) == "number" and "rbxassetid://" .. tostring(IconValue.Image)
				or IconValue.Image

			Pack.Icons[IconName] = {
				Image = ImageId,
				ImageRectSize = IconValue.ImageRectSize,
				ImageRectPosition = IconValue.ImageRectPosition,
				Parts = IconValue.Parts,
			}
			Pack.Spritesheets[ImageId] = ImageId
		else
			warn("AddIcons: unsupported data for icon '" .. tostring(IconName) .. "'")
		end
	end
end

function IconModule.SetIconsType(IconsType)
	IconModule.IconsType = IconsType
end

function IconModule.Init(New, IconThemeTag)
	IconModule.New = New
	IconModule.IconThemeTag = IconThemeTag

	return IconModule
end

function IconModule.Icon(IconString, IconsType)
	if type(IconString) ~= "string" or IconString == "" then
		return nil
	end

	IconString = Aliases[IconString] or IconString
	local PackName, IconName = ParseIconString(IconString)
	PackName = PackName or IconsType or IconModule.IconsType

	local Pack = IconModule.Icons[PackName]
	if Pack and Pack.Icons[IconName] then
		local Data = Pack.Icons[IconName]
		return { Pack.Spritesheets[tostring(Data.Image)], Data }
	end

	if PackName == "lucide" then
		return GetLucide(IconName)
	end

	return nil
end

function IconModule.GetIcon(IconString, IconsType)
	return IconModule.Icon(IconString, IconsType)
end

function IconModule.Icon2(IconString, IconsType)
	return IconModule.Icon(IconString, IconsType)
end

function IconModule.Image(Config)
	local Image = {
		Icon = Config.Icon,
		Type = Config.Type,
		Colors = Config.Colors or { IconModule.IconThemeTag or Color3.new(1, 1, 1), Color3.new(1, 1, 1) },
		Size = Config.Size or UDim2.new(0, 24, 0, 24),

		IconFrame = nil,
	}

	local Colors = {}
	for Index, Value in next, Image.Colors do
		Colors[Index] = {
			ThemeTag = typeof(Value) == "string" and Value,
			Color = typeof(Value) == "Color3" and Value,
		}
	end

	local Data = IconModule.Icon(Image.Icon, Image.Type) or { "", { ImageRectSize = Vector2.zero, ImageRectPosition = Vector2.zero } }
	local New = IconModule.New

	local Label = New("ImageLabel", {
		Size = Image.Size,
		BackgroundTransparency = 1,
		ImageColor3 = Colors[1].Color or nil,
		ThemeTag = Colors[1].ThemeTag and {
			ImageColor3 = Colors[1].ThemeTag,
		},
		Image = Data[1],
		ImageRectSize = Data[2].ImageRectSize,
		ImageRectOffset = Data[2].ImageRectPosition,
	})

	if Data[2].Parts then
		for Index, Part in next, Data[2].Parts do
			local PartData = IconModule.Icon(Part, Image.Type)
			if PartData then
				local Tint = Colors[1 + Index] or {}
				New("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					ImageColor3 = Tint.Color or nil,
					ThemeTag = Tint.ThemeTag and {
						ImageColor3 = Tint.ThemeTag,
					},
					Image = PartData[1],
					ImageRectSize = PartData[2].ImageRectSize,
					ImageRectOffset = PartData[2].ImageRectPosition,
					Parent = Label,
				})
			end
		end
	end

	Image.IconFrame = Label
	return Image
end

return IconModule
