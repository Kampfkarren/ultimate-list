local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

type Row = {
	id: string,
	index: number,
	height: number,
	yOffset: number,
}

local function appendMeasuredRows(rows: { Row }, count: number): { Row }
	local newRows = table.clone(rows)
	local yOffset = if #newRows == 0 then 0 else newRows[#newRows].yOffset + newRows[#newRows].height

	for _ = 1, count do
		local index = #newRows + 1
		local height = 36 + (index % 5) * 12
		table.insert(newRows, {
			id = `row-{index}`,
			index = index,
			height = height,
			yOffset = yOffset,
		})
		yOffset += height
	end

	return newRows
end

local function button(text: string, position: UDim2, onActivated: () -> ())
	return e("TextButton", {
		BackgroundColor3 = Color3.fromRGB(45, 45, 50),
		Position = position,
		Size = UDim2.fromOffset(125, 32),
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		[React.Event.Activated] = onActivated,
	})
end

local function Demo()
	local rows, setRows = React.useState(function()
		return appendMeasuredRows({}, 40)
	end)
	local viewportHeight, setViewportHeight = React.useState(260)
	local scrollingFrameRef = React.useRef(nil :: ScrollingFrame?)

	local appendRows = React.useCallback(function()
		setRows(function(currentRows)
			return appendMeasuredRows(currentRows, 10)
		end)
	end, {})

	local resizeViewport = React.useCallback(function()
		setViewportHeight(function(currentHeight)
			return if currentHeight == 260 then 160 else 260
		end)
	end, {})

	local toggleScrollPosition = React.useCallback(function()
		local scrollingFrame = scrollingFrameRef.current
		if scrollingFrame ~= nil then
			scrollingFrame.CanvasPosition =
				Vector2.new(0, if scrollingFrame.CanvasPosition.Y < 400 then 800 else 0)
		end
	end, {})

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(420, 340),
	}, {
		Append = button("Append measured", UDim2.fromOffset(0, 0), appendRows),
		Resize = button("Resize viewport", UDim2.fromOffset(140, 0), resizeViewport),
		Scroll = button("Toggle scroll", UDim2.fromOffset(280, 0), toggleScrollPosition),

		ExternalScrollingFrame = e("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(25, 25, 30),
			CanvasSize = UDim2.new(),
			Position = UDim2.fromOffset(0, 48),
			ScrollBarThickness = 8,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.fromOffset(420, viewportHeight),
			ref = scrollingFrameRef,
		}, {
			Content = e(UltimateList.Components.VirtualizedContent, {
				dataSource = UltimateList.DataSources.array(rows),
				dimensions = UltimateList.Dimensions.getter(function(row: Row)
					return {
						position = UDim2.fromOffset(0, row.yOffset),
						size = UDim2.new(1, 0, 0, row.height),
					}
				end),
				renderer = UltimateList.Renderers.byState(function(row: Row)
					return e("TextLabel", {
						BackgroundColor3 = if row.index % 2 == 0
							then Color3.fromRGB(68, 85, 110)
							else Color3.fromRGB(55, 70, 92),
						Font = Enum.Font.BuilderSans,
						Size = UDim2.fromScale(1, 1),
						Text = `{row.id} — pre-measured height {row.height}`,
						TextColor3 = Color3.new(1, 1, 1),
						TextSize = 16,
					})
				end, {
					freezeViewWhileScrolling = true,
				}),
				getKey = function(row: Row)
					return row.id
				end,
				direction = "y",
				scrollingFrameRef = scrollingFrameRef,
				overscan = 240,
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
