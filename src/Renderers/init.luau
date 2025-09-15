local Src = script:FindFirstAncestor("UltimateList")

local React = require(Src.Parent.React)

local Renderers = {}

export type Renderer<T> = {
	type: "byState",
	callback: (T) -> React.Node,
} | {
	-- todo soon: with this, track maximum number of items seen
	-- with `getter`, and allow a pre-warm value in here
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
