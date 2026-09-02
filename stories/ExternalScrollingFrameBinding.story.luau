local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

type Card = {
	id: string,
	width: number,
	xOffset: number,
}

local function createCards(): { Card }
	local cards = {}
	local xOffset = 0

	for index = 1, 60 do
		local width = 70 + (index % 4) * 24
		table.insert(cards, {
			id = `card-{index}`,
			width = width,
			xOffset = xOffset,
		})
		xOffset += width
	end

	return cards
end

local function Demo()
	local cards = React.useMemo(createCards, {})
	local viewportWidth, setViewportWidth = React.useState(420)
	local scrollingFrameRef = React.useRef(nil :: ScrollingFrame?)

	local resizeViewport = React.useCallback(function()
		setViewportWidth(function(currentWidth)
			return if currentWidth == 420 then 280 else 420
		end)
	end, {})

	local toggleScrollPosition = React.useCallback(function()
		local scrollingFrame = scrollingFrameRef.current
		if scrollingFrame ~= nil then
			scrollingFrame.CanvasPosition =
				Vector2.new(if scrollingFrame.CanvasPosition.X < 500 then 1_200 else 0, 0)
		end
	end, {})

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(440, 210),
	}, {
		Resize = e("TextButton", {
			BackgroundColor3 = Color3.fromRGB(45, 45, 50),
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(135, 32),
			Text = "Resize viewport",
			TextColor3 = Color3.new(1, 1, 1),
			[React.Event.Activated] = resizeViewport,
		}),
		Scroll = e("TextButton", {
			BackgroundColor3 = Color3.fromRGB(45, 45, 50),
			Position = UDim2.fromOffset(150, 0),
			Size = UDim2.fromOffset(135, 32),
			Text = "Toggle scroll",
			TextColor3 = Color3.new(1, 1, 1),
			[React.Event.Activated] = toggleScrollPosition,
		}),

		ExternalScrollingFrame = e("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.fromRGB(25, 25, 30),
			CanvasSize = UDim2.new(),
			Position = UDim2.fromOffset(0, 48),
			ScrollBarThickness = 8,
			ScrollingDirection = Enum.ScrollingDirection.X,
			Size = UDim2.fromOffset(viewportWidth, 150),
			ref = scrollingFrameRef,
		}, {
			Content = e(UltimateList.Components.ScrollingFrameContent, {
				dataSource = UltimateList.DataSources.array(cards),
				dimensions = UltimateList.Dimensions.getter(function(card: Card)
					return {
						position = UDim2.fromOffset(card.xOffset, 0),
						size = UDim2.new(0, card.width, 1, 0),
					}
				end),
				renderer = UltimateList.Renderers.byBinding(function(cardBinding: React.Binding<Card?>)
					return e("TextLabel", {
						BackgroundColor3 = cardBinding:map(function(card: Card?)
							if card == nil then
								return Color3.new()
							end
							return if card.width > 110
								then Color3.fromRGB(105, 70, 100)
								else Color3.fromRGB(70, 85, 110)
						end),
						Font = Enum.Font.BuilderSans,
						Size = UDim2.fromScale(1, 1),
						Text = cardBinding:map(function(card: Card?)
							return if card == nil then "" else `{card.id}\n{card.width}px`
						end),
						TextColor3 = Color3.new(1, 1, 1),
						TextSize = 16,
						TextWrapped = true,
					})
				end),
				getKey = function(card: Card)
					return card.id
				end,
				direction = "x",
				scrollingFrameRef = scrollingFrameRef,
			}),
		}),
	})
end

return function(target)
	local root = ReactRoblox.createRoot(target)

	root:render(e(Demo))

	return function()
		root:unmount()
	end
end
