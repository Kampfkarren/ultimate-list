local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages.UltimateList)

local e = React.createElement

return function(target)
	local root = ReactRoblox.createRoot(target)

	local letters = {}
	for offset = 0, 25 do
		table.insert(letters, string.char(string.byte("A") + offset))
	end

	root:render(e("Frame", {
		Size = UDim2.fromOffset(300, 300),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(letters),
			dimensions = UltimateList.Dimensions.consistentSize(48),
			renderer = UltimateList.Renderers.byBinding(function(valueBinding)
				return e("TextLabel", {
					-- Visually see efficient ordering
					BackgroundColor3 = Color3.fromHSV(math.random(), 0.5, 0.5),
					Font = Enum.Font.BuilderSansBold,
					Text = valueBinding:map(function(value: string?)
						return value or ""
					end),
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
