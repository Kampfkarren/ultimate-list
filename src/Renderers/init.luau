local Src = script:FindFirstAncestor("ultimate-list")

local React = require(Src.Parent.React)

local Renderers = {}

export type Renderer<T> = {
	type: "byState",
	callback: (T) -> React.Node,
	config: StateRendererConfig,
} | {
	type: "byBinding",
	callback: (React.Binding<T?>) -> React.Node,
} | {
	type: "byTypedBinding",
	getItemType: (value: T) -> string,
	renderers: { [string]: (React.Binding<T?>) -> React.Node },
	primaryType: string,
}

export type StateRendererConfig = {
	freezeViewWhileScrolling: boolean?,
}

export type TypedBindingRendererConfig<T> = {
	getItemType: (value: T) -> string,
	renderers: { [string]: (React.Binding<T?>) -> React.Node },
	primaryType: string,
}

function Renderers.byState<T>(callback: (T) -> React.Node, config: StateRendererConfig?): Renderer<T>
	return {
		type = "byState",
		callback = callback,
		config = config or {},
	}
end

function Renderers.byBinding<T>(callback: (React.Binding<T?>) -> React.Node): Renderer<T>
	return {
		type = "byBinding",
		callback = callback,
	}
end

function Renderers.byTypedBinding<T>(config: TypedBindingRendererConfig<T>): Renderer<T>
	return {
		type = "byTypedBinding",
		getItemType = config.getItemType,
		renderers = config.renderers,
		primaryType = config.primaryType,
	}
end

return Renderers
