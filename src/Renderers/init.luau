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
	renderers: { (React.Binding<T?>) -> React.Node? },
	primaryRendererIndex: number?,
}

export type StateRendererConfig = {
	freezeViewWhileScrolling: boolean?,
}

export type TypedBindingRendererConfig<T> = {
	renderers: { (React.Binding<T?>) -> React.Node? },
	primaryRendererIndex: number?,
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
	if #config.renderers == 0 then
		error(`Renderers.byTypedBinding: renderers must be a non-empty array.`)
	end

	if config.primaryRendererIndex ~= nil then
		if config.primaryRendererIndex < 1 or config.primaryRendererIndex > #config.renderers then
			error(
				`Renderers.byTypedBinding: primaryRendererIndex {config.primaryRendererIndex} is out of range `
					.. `for renderers array of length {#config.renderers}.`
			)
		end
	end

	return {
		type = "byTypedBinding",
		renderers = config.renderers,
		primaryRendererIndex = config.primaryRendererIndex,
	}
end

return Renderers
