local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

return function(target)
	local root = ReactRoblox.createRoot(target)

	local letters = {}
	for offset = 0, 25 do
		table.insert(letters, string.char(string.byte("A") + offset))
	end

	root:render(e("Frame", {
		Size = UDim2.new(0.5, 0, 0, 300),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(letters),
			dimensions = UltimateList.Dimensions.withSpacing(
				UltimateList.Dimensions.consistentUDim2(UDim2.fromOffset(100, 72)),
				8
			),
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
		}),
	}))

	return function()
		root:unmount()
	end
end
