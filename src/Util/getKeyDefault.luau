local function getKeyDefault<T>(_value: T, index: number): string
	return tostring(index)
end

return getKeyDefault
