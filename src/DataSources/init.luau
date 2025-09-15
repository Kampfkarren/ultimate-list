local DataSources = {}

export type DataSource<T> = {
	type: "immutableArray",
	array: { T },
}

function DataSources.immutableArray<T>(array: { T }): DataSource<T>
	return {
		type = "immutableArray",
		array = array,
	}
end

return DataSources
