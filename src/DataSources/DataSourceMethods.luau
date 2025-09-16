local Src = script:FindFirstAncestor("UltimateList")

local DataSources = require(script.Parent)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)

local DataSourceMethods = {}

function DataSourceMethods.get<T>(
	dataSource: DataSources.DataSource<T>,
	startIndex: number
): DataSources.DataSourceCursor<T>?
	assert(startIndex >= 1, "index < 1")

	if dataSource.type == "immutableArray" then
		local function get(index: number): DataSources.DataSourceCursor<T>?
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
	elseif dataSource.type == "mutableSource" then
		return dataSource.methods.get(startIndex)
	else
		return exhaustiveMatch(dataSource.type)
	end
end

function DataSourceMethods.getByRange<T>(dataSource: DataSources.DataSource<T>, range: Vector3): { T }
	if dataSource.type == "immutableArray" then
		return table.move(dataSource.array, range.X, range.Y, 1, {})
	elseif dataSource.type == "mutableSource" then
		if dataSource.methods.getByRange == nil then
			local items = {}

			local cursor = dataSource.methods.get(range.X)
			for _ = 0, range.Y - range.X do
				if cursor == nil then
					break
				end

				table.insert(items, cursor.value)
				cursor = cursor.after()
			end

			return items
		end

		return dataSource.methods.getByRange(range.X, range.Y)
	else
		return exhaustiveMatch(dataSource.type)
	end
end

function DataSourceMethods.back<T>(dataSource: DataSources.DataSource<T>): T?
	if dataSource.type == "immutableArray" then
		return dataSource.array[#dataSource.array]
	elseif dataSource.type == "mutableSource" then
		if dataSource.methods.back == nil then
			local cursor = dataSource.methods.get(dataSource.methods.length())
			return cursor and cursor.value
		end

		return dataSource.methods.back()
	else
		return exhaustiveMatch(dataSource.type)
	end
end

function DataSourceMethods.length<T>(dataSource: DataSources.DataSource<T>): number
	if dataSource.type == "immutableArray" then
		return #dataSource.array
	elseif dataSource.type == "mutableSource" then
		return dataSource.methods.length()
	else
		return exhaustiveMatch(dataSource.type)
	end
end

return DataSourceMethods
