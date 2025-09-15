local Dimensions = {}

export type Dimensions<T> =
	{
		type: "getter",
		callback: (value: T, index: number) -> UDimRect,
	}
	| {
		type: "consistentSize",
		size: number,
	}
	| {
		type: "consistentUDim2",
		udim2: UDim2,
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

return Dimensions
