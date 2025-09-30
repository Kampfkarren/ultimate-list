local Src = script:FindFirstAncestor("ultimate-list")

local React = require(Src.Parent.React)

local Renderers = {}

export type Renderer<T> = {
	type: "byState",
	callback: (T) -> React.Node,
} | {
	type: "byBinding",
	callback: (React.Binding<T?>) -> React.Node,
}

function Renderers.byState<T>(callback: (T) -> React.Node): Renderer<T>
	return {
		type = "byState",
		callback = callback,
	}
end

function Renderers.byBinding<T>(callback: (React.Binding<T?>) -> React.Node): Renderer<T>
	return {
		type = "byBinding",
		callback = callback,
	}
end

return Renderers
