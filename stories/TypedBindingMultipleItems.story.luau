--[[
	Demonstrates byTypedBinding with heterogeneous item types.

	Categories and text entries each get their own recycling pool.
	Category slots are never reused for text entries (and vice versa),
	so each type can use different hooks without violating React rules.

	Compare with Demos/MultipleItems.story.luau which uses byState.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

type Item =
	{
		type: "category",
		name: string,
	}
	| {
		type: "text",
		text: string,
	}

type ItemWithUDimRect = {
	item: Item,
	udimRect: UltimateList.UDimRect,
}

local function category(name: string): Item
	return {
		type = "category",
		name = name,
	}
end

local function text(value: string): Item
	return {
		type = "text",
		text = value,
	}
end

local ITEMS: { Item } = {
	category("North America"),
	text("Canada"),
	text("Mexico"),
	text("United States"),
	text("Panama"),
	text("Jamaica"),

	category("South America"),
	text("Brazil"),
	text("Argentina"),
	text("Bolivia"),
	text("Paraguay"),
	text("Venezuela"),

	category("Europe"),
	text("United Kingdom"),
	text("The Netherlands"),
	text("France"),
	text("Germany"),
	text("Ukraine"),
}

local itemsWithUDimRects: { ItemWithUDimRect } = {}
local nextPosition = UDim2.new()

for _, item in ITEMS do
	local height = if item.type == "category" then 32 else 24

	table.insert(itemsWithUDimRects, {
		item = item,
		udimRect = {
			size = UDim2.new(1, 0, 0, height),
			position = nextPosition,
		},
	})

	nextPosition += UDim2.fromOffset(0, height)
end

return function(target)
	local root = ReactRoblox.createRoot(target)

	root:render(e("Frame", {
		Size = UDim2.fromOffset(300, 300),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(itemsWithUDimRects),

			dimensions = UltimateList.Dimensions.getter(function(itemWithUDimRect: ItemWithUDimRect)
				return itemWithUDimRect.udimRect
			end),

			renderer = UltimateList.Renderers.byTypedBinding({
				primaryType = "text",

				getItemType = function(itemWithUDimRect: ItemWithUDimRect)
					return itemWithUDimRect.item.type
				end,

				renderers = {
					category = function(binding: React.Binding<ItemWithUDimRect?>)
						return e("TextLabel", {
							BackgroundColor3 = Color3.new(0.9, 0.9, 0.95),
							Font = Enum.Font.BuilderSansBold,
							Size = UDim2.fromScale(1, 1),
							TextColor3 = Color3.new(0, 0, 0),
							TextSize = 30,

							Text = binding:map(function(itemWithUDimRect: ItemWithUDimRect?)
								return if itemWithUDimRect then itemWithUDimRect.item.name else ""
							end),
						})
					end,

					text = function(binding: React.Binding<ItemWithUDimRect?>)
						return e("TextLabel", {
							BackgroundColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.BuilderSans,
							Size = UDim2.fromScale(1, 1),
							TextColor3 = Color3.new(0, 0, 0),
							TextSize = 20,

							Text = binding:map(function(itemWithUDimRect: ItemWithUDimRect?)
								return if itemWithUDimRect then itemWithUDimRect.item.text else ""
							end),
						})
					end,
				},
			}),

			direction = "y",
		}),
	}))
end
