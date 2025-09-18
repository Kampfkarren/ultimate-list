local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages.UltimateList)

local e = React.createElement

local function Demo()
	local items = {}
	for index = 1, 100_000 do
		table.insert(items, tostring(index))
	end

	local bindingsRef = React.useRef(nil :: ScrollingFrame?)

	local onStateScrollAxisChanged = React.useCallback(function(scrollAxis: number)
		if bindingsRef.current ~= nil then
			bindingsRef.current.CanvasPosition = Vector2.new(0, scrollAxis)
		end
	end, {})

	return e("Frame", {}, {
		State = e("Frame", {
			Size = UDim2.fromOffset(300, 300),
		}, {
			ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
				dataSource = UltimateList.DataSources.array(items),
				dimensions = UltimateList.Dimensions.consistentSize(48),
				renderer = UltimateList.Renderers.byState(function(value)
					return e("TextLabel", {
						BackgroundColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.BuilderSansBold,
						Text = value,
						TextColor3 = Color3.new(0, 0, 0),
						TextSize = 36,
						Size = UDim2.fromScale(1, 1),
					})
				end),

				direction = "y",

				onScrollAxisChanged = onStateScrollAxisChanged,
			}),
		}),

		Bindings = e("Frame", {
			Size = UDim2.fromOffset(300, 300),
			Position = UDim2.fromOffset(350, 0),
		}, {
			ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
				dataSource = UltimateList.DataSources.array(items),
				dimensions = UltimateList.Dimensions.consistentSize(48),
				renderer = UltimateList.Renderers.byBinding(function(value)
					return e("TextLabel", {
						BackgroundColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.BuilderSansBold,
						Text = value,
						TextColor3 = Color3.new(0, 0, 0),
						TextSize = 36,
						Size = UDim2.fromScale(1, 1),
					})
				end),

				direction = "y",

				scrollingFrameRef = bindingsRef,
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
