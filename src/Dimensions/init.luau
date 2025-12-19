local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataSources = require(ReplicatedStorage.Packages["ultimate-list"].DataSources)
local Dimensions = {}

export type Dimensions<T> =
	| {
		type: "getter",
		callback: (value: T, index: number) -> UDimRect,
	}
	| {
		type: "accumulatingSize",
		callback: (value: T, index: number) -> UDim2,
	}
	| {
		type: "consistentSize",
		size: number,
	}
	| {
		type: "consistentUDim2",
		udim2: UDim2,
	}
	| {
		type: "spaced",
		spacing: number,
		inner: Dimensions<T>,
	}

export type DimensionsState<T> =
	{
		type: "accumulatingSize",

		-- Will include spacing
		udimRects: { UDimRect },

		-- Sorted list of the height of rows if direction == y, and width of columns if direction == x.
		-- This exists so that if you have multiple items of different sizes in the same section, the binary
		-- search behaves as it should.
		dominantSections: { AccumulatingSizeSection },

		dataSource: DataSources.DataSource<T>,
		windowSize: Vector2,

		latestNonDominantSizeOffset: number,
		latestNonDominantSizeScale: number,

		-- If you use scale for the non-dominant axis, we don't need to recalculate anything.
		-- If you use offset, then the rows/columns can wrap differently.
		sizeRecalculationStrategy: {
			needsRecalculation: true,
			lastWindowSize: Vector2,
		} | {
			needsRecalculation: false,
		},
	}
	| {
		type: "none",
	}

export type AccumulatingSizeSection = {
	-- [start index, end index]
	indexRange: Vector3,

	-- [starting point, end point]
	box: Vector3,
}

export type UDimRect = {
	size: UDim2,
	position: UDim2,
}

function Dimensions.getter<T>(callback: (value: T, index: number) -> UDimRect): Dimensions<T>
	return {
		type = "getter",
		callback = callback,
	}
end

function Dimensions.consistentSize<T>(size: number): Dimensions<T>
	return {
		type = "consistentSize",
		size = size,
	}
end

function Dimensions.consistentUDim2<T>(udim2: UDim2): Dimensions<T>
	return {
		type = "consistentUDim2",
		udim2 = udim2,
	}
end

function Dimensions.withSpacing<T>(inner: Dimensions<T>, spacing: number): Dimensions<T>
	assert(
		inner.type ~= "getter",
		"withSpacing does not support getter. Instead, include your padding as part of your returned position."
	)

	if inner.type == "spaced" then
		return Dimensions.withSpacing(inner.inner, spacing)
	end

	return {
		type = "spaced",
		spacing = spacing,
		inner = inner,
	}
end

return Dimensions
