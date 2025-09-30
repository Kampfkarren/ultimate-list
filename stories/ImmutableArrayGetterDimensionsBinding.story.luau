local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

type Letter = {
	text: string,
	dimensions: UltimateList.UDimRect,
}

return function(target)
	local root = ReactRoblox.createRoot(target)

	local letters: { Letter } = {}
	local positionOffset = 0

	for offset = 0, 25 do
		local row = offset // 2
		if offset % 2 == 0 and row > 0 then
			positionOffset += row * 16
		end

		table.insert(letters, {
			text = string.char(string.byte("A") + offset),
			dimensions = {
				size = UDim2.new(0.5, 0, 0, (row + 1) * 16),
				position = UDim2.new((offset % 2) * 0.5, 0, 0, positionOffset),
			},
		})
	end

	root:render(e("Frame", {
		Size = UDim2.fromOffset(300, 300),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(letters),
			dimensions = UltimateList.Dimensions.getter(function(value: Letter, _index: number)
				return value.dimensions
			end),
			renderer = UltimateList.Renderers.byBinding(function(valueBinding: React.Binding<Letter?>)
				return e("TextLabel", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.BuilderSansBold,
					Text = valueBinding:map(function(value: Letter?)
						return if value then value.text else ""
					end),
					TextColor3 = Color3.new(0, 0, 0),
					TextSize = 12,
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
