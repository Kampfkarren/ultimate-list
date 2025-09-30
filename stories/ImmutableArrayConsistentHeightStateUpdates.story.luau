local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

local function Demo()
	local numbers: { number }, setNumbers = React.useState({ 1, 2, 3 } :: { number })

	React.useEffect(function()
		local thread = task.spawn(function()
			while true do
				setNumbers(function(newNumbers)
					newNumbers = table.clone(newNumbers)
					table.insert(newNumbers, #newNumbers + 1)
					return newNumbers
				end)

				task.wait(0.5)
			end
		end)

		return function()
			task.cancel(thread)
		end
	end, {})

	return e("Frame", {
		Size = UDim2.fromOffset(300, 300),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(numbers),
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
