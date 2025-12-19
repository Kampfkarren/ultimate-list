local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local controls = {
	elements = 2,
	vertical = true,

	dominantSize = 50,
	width = 150,
	nonDominantSizeScale = 0,
	nonDominantSizeOffset = 45,
}

return {
	react = React,
	reactRoblox = ReactRoblox,

	controls = controls,

	story = function(props: {
		controls: typeof(controls),
	})
		-- todo soon
	end,
}
