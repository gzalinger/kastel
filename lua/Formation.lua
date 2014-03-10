-- formations of units for regiments in new 'sub-tile'system

Formation = {}
Formation.__index = Formation


function Formation.setStatics()
	formations = {} --master list of formations
	formations["marching"] = { --the following is a list of offsets, in order, of where units will be in this formation
		{x = 0, y = 0},  
		{x = 1, y = -1},
		{x = 1, y = 1},
		{x = -1, y = 1},
		{x = -1, y = -1}
	} --todo: expand for regiments with more than 5 units
end

-- ====================================================

function Formation.create(numPositions, formationType)
	local temp = {}
	setmetatable(temp, Formation)
	temp.positions = {}
	for n = 1, numPositions do
		temp.positions[n] = formations[formationType][n]
	end
	temp:initDimensions()
	temp.formationType = formationType
	return temp
end

-- ====================================================

function Formation:initDimensions()
	local minX = nil
	local maxX = nil
	local minY = nil
	local maxY = nil
	for key, pos in pairs(self.positions) do
		if minX == nil or pos.x < minX then
			minX = pos.x
		end
		if maxX == nil or pos.x > maxX then
			maxX = pos.x
		end
		if minY == nil or pos.y < minY then
			minY = pos.y
		end
		if maxY == nil or pos.y > maxY then
			maxY = pos.y
		end
	end
	self.width = math.abs(maxX - minX) + 1
	self.height = math.abs(maxY - minY) + 1
end

-- ====================================================