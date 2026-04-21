--[[
	Stress test for Renderers.byTypedBinding with heterogeneous item types.

	Generates 100k items across four types (category, text, image, divider)
	with varying densities so each type's recycling pool gets exercised as
	the user scrolls. Each type has a distinct height to force
	Dimensions.getter paths, and a distinct visual treatment so recycling
	correctness is visible at a glance.
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
	| {
		type: "image",
		label: string,
	}
	| {
		type: "divider",
	}

type ItemWithUDimRect = {
	item: Item,
	udimRect: UltimateList.UDimRect,
}

-- Height per type. Mixed to force Dimensions.getter and to visually distinguish
-- recycling pools while scrolling.
local HEIGHT_BY_TYPE: { [string]: number } = {
	category = 48,
	text = 24,
	image = 64,
	divider = 8,
}

-- Uneven type weights. Primary ("text") dominates; other types appear
-- irregularly so each pool sees varying churn as the user scrolls.
local TYPE_WEIGHTS: { { type: string, weight: number } } = {
	{ type = "text", weight = 70 },
	{ type = "category", weight = 10 },
	{ type = "image", weight = 15 },
	{ type = "divider", weight = 5 },
}

local TOTAL_WEIGHT = 0
for _, entry in TYPE_WEIGHTS do
	TOTAL_WEIGHT += entry.weight
end

local ITEM_COUNT = 100_000

-- Seeded RNG so repeated runs see the same distribution, which makes
-- perf comparisons meaningful.
local rng = Random.new(1337)

local function pickType(): string
	local roll = rng:NextInteger(1, TOTAL_WEIGHT)
	local cumulative = 0
	for _, entry in TYPE_WEIGHTS do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.type
		end
	end
	return TYPE_WEIGHTS[1].type
end

local function makeItem(index: number): Item
	local itemType = pickType()
	if itemType == "category" then
		return {
			type = "category",
			name = string.format("Section %d", index),
		}
	elseif itemType == "text" then
		return {
			type = "text",
			text = string.format("Row %d", index),
		}
	elseif itemType == "image" then
		return {
			type = "image",
			label = string.format("Image %d", index),
		}
	else
		return { type = "divider" }
	end
end

local itemsWithUDimRects: { ItemWithUDimRect } = table.create(ITEM_COUNT)
local nextPosition = UDim2.new()

for index = 1, ITEM_COUNT do
	local item = makeItem(index)
	local height = HEIGHT_BY_TYPE[item.type]

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
		Size = UDim2.fromOffset(300, 500),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(itemsWithUDimRects),

			dimensions = UltimateList.Dimensions.getter(function(itemWithUDimRect: ItemWithUDimRect)
				return itemWithUDimRect.udimRect
			end),

			getKey = function(_value: ItemWithUDimRect, index: number)
				return tostring(index)
			end,

		renderer = UltimateList.Renderers.byTypedBinding({
			-- Renderers are tried in order; the first to return a non-nil
			-- node claims the slot. Text is the most common type (~70% of
			-- items) and the primary (pre-allocated) renderer.
			primaryRendererIndex = 1,

			renderers = {
				function(binding: React.Binding<ItemWithUDimRect?>): React.Node?
					local current = binding:getValue()
					if current ~= nil and current.item.type ~= "text" then
						return nil
					end

					return e("TextLabel", {
						BackgroundColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.BuilderSans,
						Size = UDim2.fromScale(1, 1),
						TextColor3 = Color3.new(0, 0, 0),
						TextSize = 18,

						Text = binding:map(function(itemWithUDimRect: ItemWithUDimRect?)
							local item = if itemWithUDimRect then itemWithUDimRect.item else nil
							return if item and item.type == "text" then item.text else ""
						end),
					})
				end,

				function(binding: React.Binding<ItemWithUDimRect?>): React.Node?
					local current = binding:getValue()
					if current ~= nil and current.item.type ~= "category" then
						return nil
					end

					return e("TextLabel", {
						BackgroundColor3 = Color3.new(0.9, 0.9, 0.95),
						Font = Enum.Font.BuilderSansBold,
						Size = UDim2.fromScale(1, 1),
						TextColor3 = Color3.new(0, 0, 0),
						TextSize = 30,

						Text = binding:map(function(itemWithUDimRect: ItemWithUDimRect?)
							local item = if itemWithUDimRect then itemWithUDimRect.item else nil
							return if item and item.type == "category" then item.name else ""
						end),
					})
				end,

				function(binding: React.Binding<ItemWithUDimRect?>): React.Node?
					local current = binding:getValue()
					if current ~= nil and current.item.type ~= "image" then
						return nil
					end

					return e("Frame", {
						BackgroundColor3 = Color3.new(0.85, 0.95, 0.85),
						Size = UDim2.fromScale(1, 1),
					}, {
						Label = e("TextLabel", {
							BackgroundTransparency = 1,
							Font = Enum.Font.BuilderSansBold,
							Size = UDim2.fromScale(1, 1),
							TextColor3 = Color3.new(0, 0.2, 0),
							TextSize = 22,

							Text = binding:map(function(itemWithUDimRect: ItemWithUDimRect?)
								local item = if itemWithUDimRect then itemWithUDimRect.item else nil
								return if item and item.type == "image" then item.label else ""
							end),
						}),
					})
				end,

				function(binding: React.Binding<ItemWithUDimRect?>): React.Node?
					local current = binding:getValue()
					if current ~= nil and current.item.type ~= "divider" then
						return nil
					end

					return e("Frame", {
						BackgroundColor3 = Color3.new(0.6, 0.6, 0.6),
						Size = UDim2.fromScale(1, 1),
					})
				end,
			},
		}),

			direction = "y",
		}),
	}))

	return function()
		root:unmount()
	end
end
