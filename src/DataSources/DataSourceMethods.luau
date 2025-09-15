local Src = script:FindFirstAncestor("UltimateList")

local DataSources = require(script.Parent)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)

local DataSourceMethods = {}

export type DataSourceCursor<T> = {
	before: () -> DataSourceCursor<T>?,
	value: T,
	after: () -> DataSourceCursor<T>?,
}

function DataSourceMethods.get<T>(dataSource: DataSources.DataSource<T>, startIndex: number): DataSourceCursor<T>?
	assert(startIndex >= 1, "index < 1")

	if dataSource.type == "immutableArray" then
		local function get(index: number): DataSourceCursor<T>?
			if index < 1 or index > #dataSource.array then
				return nil
			end

			return {
				before = function()
					return get(index - 1)
				end,

				value = dataSource.array[index],

				after = function()
					return get(index + 1)
				end,
			}
		end

		return get(startIndex)
	else
		return exhaustiveMatch(dataSource.type)
	end
end

function DataSourceMethods.getByRange<T>(dataSource: DataSources.DataSource<T>, range: Vector3): { T }
	if dataSource.type == "immutableArray" then
		return table.move(dataSource.array, range.X, range.Y, 1, {})
	else
		return exhaustiveMatch(dataSource.type)
	end
end

function DataSourceMethods.back<T>(dataSource: DataSources.DataSource<T>): T?
	if dataSource.type == "immutableArray" then
		return dataSource.array[#dataSource.array]
	else
		return exhaustiveMatch(dataSource.type)
	end
end

function DataSourceMethods.length<T>(dataSource: DataSources.DataSource<T>): number
	if dataSource.type == "immutableArray" then
		return #dataSource.array
	else
		return exhaustiveMatch(dataSource.type)
	end
end

return DataSourceMethods
