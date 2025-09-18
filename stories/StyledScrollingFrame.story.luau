local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StylingService = game:GetService("StylingService")

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

	local styleSheet = Instance.new("StyleSheet")

	local styleRule = Instance.new("StyleRule")
	styleRule.Selector = ".MyScrollingFrame"
	styleRule:SetProperty("BackgroundColor3", Color3.new(1, 0, 0))
	styleRule.Parent = styleSheet

	styleSheet.Parent = StylingService

	root:render(e("Frame", {
		Size = UDim2.fromOffset(300, 300),
	}, {
		StyleLink = e("StyleLink", {
			StyleSheet = styleSheet,
		}),

		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(letters),
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

			tag = "MyScrollingFrame",
		}),
	}))

	return function()
		root:unmount()
		styleSheet:Destroy()
	end
end
