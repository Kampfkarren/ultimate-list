local Src = script:FindFirstAncestor("UltimateList")

local DataSources = require(script.Parent)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)

local DataSourceMethods = {}

export type DataSourceCursor<T> = {
	before: () -> DataSourceCursor<T>?,
	value: T,
	after: () -> DataSourceCursor<T>?,
}

local function get<T>(dataSource: DataSources.DataSource<T>): DataSourceCursor<T>? end

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
