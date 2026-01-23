local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local controls = {
	elements = 100,
	vertical = true,

	dominantSize = 50,
	width = 150,
	nonDominantSizeScale = 0,
	nonDominantSizeOffset = 45,

	-- todo soon: spacing
}

local function Item(props: {
	controls: typeof(controls),
	number: number,
})
	return React.createElement("TextLabel", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.BuilderSans,
		Size = UDim2.fromScale(1, 1),
		Text = tostring(props.number),
		TextSize = 24,
	})
end

local function Story(props: {
	controls: typeof(controls),
})
	local getSize = React.useCallback(
		function(value: number)
			return if props.controls.vertical
				then UDim2.new(
					props.controls.nonDominantSizeScale,
					props.controls.nonDominantSizeOffset,
					0,
					props.controls.dominantSize * (value / 3)
				)
				else UDim2.new(
					0,
					props.controls.dominantSize * (value / 3),
					props.controls.nonDominantSizeScale,
					props.controls.nonDominantSizeOffset
				)
		end,
		{
			props.controls.dominantSize,
			props.controls.nonDominantSizeOffset,
			props.controls.nonDominantSizeScale,
			props.controls.vertical,
		} :: { unknown }
	)

	local renderItem = React.useCallback(function(item: number)
		return React.createElement(Item, {
			controls = props.controls,
			number = item,
		})
	end, { props.controls })

	local items = React.useMemo(function()
		local total = {}

		for i = 1, props.controls.elements do
			table.insert(total, i)
		end

		return total
	end, { props.controls.elements })

	return React.createElement(
		"Frame",
		{
			Size = UDim2.fromOffset(props.controls.width, 500),
		},
		React.createElement(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(items),
			dimensions = UltimateList.Dimensions.accumulatingSize(getSize),
			renderer = UltimateList.Renderers.byState(renderItem),
			direction = if props.controls.vertical then "y" else "x",
		})
	)
end

return {
	packages = {
		React = React,
		ReactRoblox = ReactRoblox,
	},

	controls = controls,

	story = function(props: {
		controls: typeof(controls),
	})
		return React.createElement(Story, {
			controls = props.controls,
		})
	end,
}
