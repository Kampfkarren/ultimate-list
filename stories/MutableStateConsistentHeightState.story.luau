local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

return function(target)
	local root = ReactRoblox.createRoot(target)

	local strings: { string } = {}
	local changedCallbacks: { [() -> ()]: true? } = {}

	local mutableSource = UltimateList.DataSources.mutableSource({
		get = UltimateList.DataSources.utilities.createGetSimpleCursor(function(index: number): string
			return strings[index]
		end, function()
			return #strings
		end),

		length = function()
			return #strings
		end,

		bindToChanged = function(callback)
			changedCallbacks[callback] = true
			return function()
				changedCallbacks[callback] = nil
			end
		end,
	})

	local thread = task.spawn(function()
		while true do
			table.insert(strings, HttpService:GenerateGUID())

			for callback in changedCallbacks do
				callback()
			end

			task.wait(0.5)
		end
	end)

	root:render(e("Frame", {
		Size = UDim2.fromOffset(300, 300),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = mutableSource,
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
	}))

	return function()
		task.cancel(thread)
		root:unmount()
	end
end
