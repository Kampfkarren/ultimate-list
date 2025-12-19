local Src = script:FindFirstAncestor("ultimate-list")

local Dimensions = require(Src.Dimensions)

local function binarySearchAccumulatingSizeSections<T>(
	sections: { Dimensions.AccumulatingSizeSection },

	scrollAxis: number,
	windowAxis: number
): Vector3
	local low, high = 1, #sections

	while low <= high do
		local mid = (low + high) // 2

		local section = sections[mid]

		local sectionStart = section.box.X
		local sectionFinish = section.box.Y
		assert(sectionFinish > sectionStart, "Section box is not valid")

		if sectionFinish < scrollAxis then
			low = mid + 1
		elseif sectionStart > scrollAxis + windowAxis then
			high = mid - 1
		else
			local min, max = mid, mid

			while min > 1 do
				local nextBox = sections[min - 1].box
				if nextBox.X < scrollAxis or nextBox.Y > scrollAxis + windowAxis then
					break
				end
				min -= 1
			end

			while max < #sections do
				local nextBox = sections[max + 1].box
				if nextBox.X < scrollAxis or nextBox.Y > scrollAxis + windowAxis then
					break
				end
				max += 1
			end

			return Vector3.new(min, max)
		end
	end

	return Vector3.zero
end

return binarySearchAccumulatingSizeSections
