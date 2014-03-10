-- backend data structure for game map

Map = {}
Map.__index = Map


function Map.create(level)
	local temp = {}
	setmetatable(temp, Map)
	temp.width = level.mapBlueprint.width
	temp.height = level.mapBlueprint.height
	temp:initTiles(level.mapBlueprint)
	temp:initTransitions()
	temp:initVertices()
	temp.center = temp:getTile(level.mapBlueprint.townHallLoc.x, level.mapBlueprint.townHallLoc.y)
	for key, sp in pairs(level.spawnPoints) do
		temp:getTile(sp.x, sp.y).isSpawnPoint = true
	end
	return temp	
end

-- ====================================================

function Map:initTiles(blueprint)
	self.tiles = {}
	local idx = 0
	for i = 0, self.height - 1 do
		local j = 0
		--local j = i % 2 --if in odd row, start at 1
		while j < self.width do
			local temp = MapTile.create(j, i, terrainTypes[blueprint.defaultTerrainType], self)
			self.tiles[idx] = temp
			idx = idx + 1
			j = j + 1
		end
	end
	--set terrain from blueprint:
	for key, terr in pairs(blueprint.terrain) do
		self:getTile(terr.x, terr.y):setTerrainType(terrainTypes[terr.terrain])
	end
	for key, road in pairs(blueprint.roads) do
		self:getTile(road.x, road.y):setTerrainType(terrainTypes["road"])
	end
end

-- ====================================================

function Map:initTransitions()
	--transitions are stored in both master list and map tiles they include
	self.transitions = {}
	for key, tile in pairs(self.tiles) do
		--make three new transitions, link up with tiles they connect to
		-- 1) transition to the right:
		local dest = self:getTile(tile.x + 1, tile.y - ((tile.x+1)%2))
		if dest ~= nil then
			local temp = TileTransition.create(tile, dest, self)
			table.insert(self.transitions, temp)
			table.insert(tile.transitions, temp)
			table.insert(dest.transitions, temp)
		end
		-- 2) down and right
		dest = self:getTile(tile.x + 1, tile.y + (tile.x%2))
		if dest ~= nil then
			local temp = TileTransition.create(tile, dest, self)
			table.insert(self.transitions, temp)
			table.insert(tile.transitions, temp)
			table.insert(dest.transitions, temp)
		end
		-- 3) down and left
		dest = self:getTile(tile.x, tile.y + 1)
		if dest ~= nil then
			local temp = TileTransition.create(tile, dest, self)
			table.insert(self.transitions, temp)
			table.insert(tile.transitions, temp)
			table.insert(dest.transitions, temp)
		end
	end
end

-- ====================================================

function Map:initVertices()
	self.vertices = {}
	for key, tile in pairs(self.tiles) do
		for i =0, 5 do
			--for each iteration of this loop, make a vertice
			if tile.vertices[i] == nil then
				--vertice doesn't already exist
				local vert = MapVertice.create()
				vert:addAdjacentTile(tile, i)
				tile.vertices[i] = vert
				table.insert(self.vertices, vert)
				--add to other tiles:
				local trans = tile:getTransitionAtOrientation(i)
				if trans ~= nil then
					local other = trans:getDest(tile)
					other.vertices[(i + 4)%6] = vert
					vert:addAdjacentTile(other, (i+4)%6)
				end
				local j = (i - 1)%6
				trans = tile:getTransitionAtOrientation(j)
				if trans ~= nil then
					local other = trans:getDest(tile)
					other.vertices[(j + 3)%6] = vert
					vert:addAdjacentTile(other, (j+3)%6)
				end
			end
		end
	end
end

-- ====================================================

function Map:getTile(x, y)
	if x < 0 or x >= self.width or y < 0 or y >= self.height then
		return nil
	end
	return self.tiles[y*self.height + math.floor(x)]
end

-- ====================================================

function Map.getDXDYForOrientation(tile, orient)
	if orient  == 0 then
		return {dX = 0, dY = -1}
	elseif orient == 1 then
		return {dX = 1, dY = -1*((tile.x + 1)%2)}
	elseif orient == 2 then
		return {dX = 1, dY = tile.x%2}
	elseif orient == 3 then
		return {dX = 0, dY = 1}
	elseif orient == 4 then
		return {dX = -1, dY = (tile.x)%2}
	elseif orient == 5 then
		return {dX = -1, dY = -1*((tile.x + 1)%2)}
	else
		return {dX = 0, dY = 0}
	end
end

-- ====================================================

function Map:updateEdgeOfBase(tile, game)
	--new struct has been built on this tile, update edge around it
	local wallsToMove = {}
	local newEdgeOfBase = {} --trans that are newly edge of base and will need a wall
	for key, trans in pairs(tile.transitions) do
		if (trans.a.structure == nil or trans.a.structure.isVillageStruct) or (trans.b.structure == nil or trans.b.structure.isVillageStruct) then
			trans.isEdgeOfBase = true
			table.insert(newEdgeOfBase, trans)
			--game:buildNewWall(game.cityWallType, trans.a:getOrientationOfTransition(trans), trans.a)
		else
			trans.isEdgeOfBase = false
			if trans.wall ~= nil then
				table.insert(wallsToMove, trans.wall)
			end
			trans.wall = nil
		end
	end
	--TOWERS:
	local towersToMove = {}
	for key, vert in pairs(tile.vertices) do
		--see if vert has at least one adjacent tile withOUT a struct
		local isEdge = false
		for key, adj in pairs(vert.adjacent) do
			if adj.tile.structure == nil or adj.tile.structure.isVillageStruct then
				isEdge = true
			end
		end
		vert.isEdgeOfBase = isEdge
		if not isEdge and vert.tower ~= nil then
			table.insert(towersToMove, vert)
		end
	end
	
	--update wall gap (if applicable):
	while not game.wallGapLocation.trans.isEdgeOfBase do
		local newTile = game.wallGapLocation.trans:getDest(game.wallGapLocation.tile)
		game.wallGapLocation = {tile = newTile, trans = newTile:getTransitionAtOrientation(game.level.wallGapOrientation), isFilled = game.wallGapLocation.isFilled}
	end
	
	--move elements that are no longer along egde of base
	for key, wall in pairs(wallsToMove) do
		self:moveWallToEdgeOfBase(tile, wall)
	end
	for key, vert in pairs(towersToMove) do
		local oldLoc = vert
		local tower = vert.tower
		self:moveTowerToEdgeOfBase(tile, vert)
		currentGame:moveEngineerJobForTower(vert, tower.location)
	end
	--build new walls as needed:
	for key, trans in pairs(newEdgeOfBase) do
		if trans.wall == nil then --may have already gotten a wall moved there
			game:buildNewWall(game.cityWallType, trans.a:getOrientationOfTransition(trans), trans.a)
		end
	end
	
	--update wall gap 'isFilled':
	local foundGap = false
	for key, trans in pairs(self.transitions) do
		if trans.isEdgeOfBase and ((trans.wall == nil and trans ~= game.wallGapLocation.trans) or (trans.wall ~= nil and trans.wall.wallType == wallTypes["gate"])) then
			foundGap = true
			break
		end
	end
	game.wallGapLocation.isFilled = foundGap
	if foundGap and game.wallGapLocation.trans.wall == nil then
		game:buildNewWall(game.cityWallType, game.level.wallGapOrientation, game.wallGapLocation.tile)
	elseif not foundGap and game.wallGapLocation.wall ~= nil then
		game:removeWall(game.wallGapLocation.trans.wall)
	end
end

-- ====================================================

function Map:moveWallToEdgeOfBase(tile, wall)
	local orient = tile:getOrientationOfTransition(wall.location)
	for i = 1, 3 do
		--try transitions in 'i' to either direction
		local temp = tile:getTransitionAtOrientation((orient - i)%6)
		if temp.wall == nil and temp.isEdgeOfBase and not temp:isBorder() then
			temp.wall = wall
			wall.location.wall = nil
			temp.wall.location = temp
			return
		end
		temp = tile:getTransitionAtOrientation((orient + i)%6)
		if temp.wall == nil and temp.isEdgeOfBase and not temp:isBorder() then
			temp.wall = wall
			wall.location.wall = nil
			temp.wall.location = temp
			return
		end
	end
	print("could not move wall " .. trans.wall.hp)
	--could not find a place for it; recycle
	--currentGame:giveRecycleCost(trans.wall.wallType)
end

-- ====================================================

function Map:moveTowerToEdgeOfBase(tile, vert)
	local orient = tile:getOrientationOfVertice(vert)
	for i = 1, 3 do
		local temp = tile.vertices[(orient - i)%6]
		if temp.tower == nil and temp.isEdgeOfBase then
			temp.tower = vert.tower
			vert.tower = nil
			temp.tower.location = temp
			return
		end
		temp = tile.vertices[(orient + i)%6]
		if temp.tower == nil and temp.isEdgeOfBase then
			temp.tower = vert.tower
			vert.tower = nil
			temp.tower.location = temp
			return
		end
	end
	--could not find a place to move it; recycle it
	currentGame:giveRecycleCost(vert.tower.towerType)
	vert.tower = nil
end

-- ====================================================

function Map:clearAllHighlights()
	for key, t in pairs(self.tiles) do
		t.isHighlighted = false
	end
end

-- ====================================================
-- ====================================================
-- ====================================================


MapTile = {}
MapTile.__index = MapTile


function MapTile.create(x, y, terrainType, map)
 	local temp = {}
 	setmetatable(temp, MapTile)
 	temp.transitions = {}
 	temp.x = x
 	temp.y = y
 	temp.parent = map
 	temp.structure = nil
 	temp.buildProject = nil
 	temp:setTerrainType(terrainType)
 	temp.isSpawnPoint = false
 	temp.vertices = {}
 	temp.isHighlighted = false
 	temp:initSubtiles()
 	return temp
end

-- ====================================================

function MapTile:setTerrainType(tt)
	self.terrainType = tt
	self.bgColor = {math.min(tt.color.r + math.random(0, 20), 255), math.min(tt.color.g + math.random(0, 20), 255), math.min(tt.color.b + math.random(0, 20), 255)} 
end

-- ====================================================

function MapTile:equals(loc)
	return loc.x == self.x and loc.y == self.y
end

-- ====================================================

function MapTile:getTransitionAtOrientation(orient)
	local delta = Map.getDXDYForOrientation(self, orient)
	return self:getTransition(delta.dX, delta.dY)
end

-- ====================================================

function MapTile:getTransition(dX, dY)
	for key, trans in pairs(self.transitions) do
		if dX == trans:getDX(self) and dY == trans:getDY(self) then
			return trans
		end
	end
	return nil
end

-- ====================================================

function MapTile:getTransitionTo(dest)
	for key, trans in pairs(self.transitions) do
		if (trans.a == self and trans.b == dest) or (trans.a == dest and trans.b == self) then
			return trans
		end
	end
	return nil
end

-- ====================================================

function MapTile:getCenter()
	--calculates (in pseudo-map coords) the center of this tile
	local x = self.x + 0.5
	local y = self.y + 0.5 + (x%2)*0.5
	return {x=x, y=y}
end

-- ====================================================

function MapTile:getOrientationOfTransition(trans)
	for i = 0, 5 do
		if trans == self:getTransitionAtOrientation(i) then
			return i
		end
	end
	return -1
end

-- ====================================================

function MapTile:isAdjacent(other)
	for key, trans in pairs(self.transitions) do
		if trans.a == other or trans.b == other then
			return true
		end
	end
	return false
end

-- ====================================================

function MapTile:getAdjacent()
	local adj = {}
	for key, trans in pairs(self.transitions) do
		table.insert(adj, trans:getDest(self))
	end
	return adj
end

-- ====================================================

function MapTile:isBorder()
	--is this tile along edge of map
	return self.x == 0 or self.x == self.parent.width-1 or self.y == 0 or self.y == self.parent.height-1
end

-- ====================================================

function MapTile:hasAdjacentStructure()
	for key, adj in pairs(self:getAdjacent()) do
		if adj.structure ~= nil then
			return true
		end
	end
	return false
end

-- ====================================================

function MapTile:getOrientationOfVertice(vert)
	for key, v in pairs(self.vertices) do
		if v == vert then
			return key
		end
	end
	return -1
end

-- ====================================================

function MapTile:isEdgeOfBase()
	--is it adjacent to a city structure but doesn't contain one
	if self.structure ~= nil and not self.structure.isVillageStruct then
		return false --is IN base b/c it has city struct here
	end
	for key, adj in pairs(self:getAdjacent()) do
		if adj.structure ~= nil and not adj.structure.isVillageStruct then
			return true
		end
	end
	return false
end

-- ====================================================

function MapTile:initSubtiles()
	self.subtiles = {}
	table.insert(self.subtiles, MapSubtile.create(0, 0, self))
	table.insert(self.subtiles, MapSubtile.create(-1, -1, self))
	table.insert(self.subtiles, MapSubtile.create(-1, 1, self))
	table.insert(self.subtiles, MapSubtile.create(1, -1, self))
	table.insert(self.subtiles, MapSubtile.create(1, 1, self))
	table.insert(self.subtiles, MapSubtile.create(-2, 0, self))
	table.insert(self.subtiles, MapSubtile.create(2, 0, self))
	table.insert(self.subtiles, MapSubtile.create(-3, -1, self))
	table.insert(self.subtiles, MapSubtile.create(-3, 1, self))
	table.insert(self.subtiles, MapSubtile.create(3, -1, self))
	table.insert(self.subtiles, MapSubtile.create(3, 1, self))
	table.insert(self.subtiles, MapSubtile.create(0, -2, self))
	table.insert(self.subtiles, MapSubtile.create(0, 2, self))
	table.insert(self.subtiles, MapSubtile.create(-2, -2, self))
	table.insert(self.subtiles, MapSubtile.create(-2, 2, self))
	table.insert(self.subtiles, MapSubtile.create(2, -2, self))
	table.insert(self.subtiles, MapSubtile.create(2, 2, self))
	table.insert(self.subtiles, MapSubtile.create(-1, -3, self))
	table.insert(self.subtiles, MapSubtile.create(-1, 3, self))
	table.insert(self.subtiles, MapSubtile.create(1, -3, self))	
	table.insert(self.subtiles, MapSubtile.create(1, 3, self))
	table.insert(self.subtiles, MapSubtile.create(0, -4, self))
	table.insert(self.subtiles, MapSubtile.create(0, 4, self))
	table.insert(self.subtiles, MapSubtile.create(-2, -4, self))
	table.insert(self.subtiles, MapSubtile.create(-2, 4, self))
	table.insert(self.subtiles, MapSubtile.create(2, -4, self))
	table.insert(self.subtiles, MapSubtile.create(2, 4, self))
	table.insert(self.subtiles, MapSubtile.create(-1, -5, self))
	table.insert(self.subtiles, MapSubtile.create(-1, 5, self))
	table.insert(self.subtiles, MapSubtile.create(1, -5, self))
	table.insert(self.subtiles, MapSubtile.create(1, 5, self))
	table.insert(self.subtiles, MapSubtile.create(0, -6, self))
	table.insert(self.subtiles, MapSubtile.create(-2, -6, self))
	table.insert(self.subtiles, MapSubtile.create(2, -6, self))
	table.insert(self.subtiles, MapSubtile.create(-3, -3, self))
	table.insert(self.subtiles, MapSubtile.create(3, -3, self))
end

-- ====================================================

function MapTile:getSubtile(x, y)
	for key, sub in pairs(self.subtiles) do
		if sub.x == x and sub.y == y then
			return sub
		end
	end
	return nil
end

-- ====================================================
-- ====================================================
-- ====================================================

--connection between two tiles

TileTransition = {}
TileTransition.__index = TileTransition


function TileTransition.create(tileA, tileB, map)
	local temp = {}
	setmetatable(temp, TileTransition)
	temp.a = tileA
	temp.b = tileB
	temp.isHighlighted = false
	temp.wall = nil
	temp.isEdgeOfBase = false
	return temp
end

-- ====================================================

function TileTransition:getDest(src)
	--passed one of two ends, returns the other
	if self.a.x == src.x and self.a.y == src.y then
		return self.b
	else
		return self.a
	end
end

-- ====================================================

function TileTransition:getLineSegment()
	--converts this into a line segment in map coords
	local x1
	local y1
	local x2
	local y2
	--case 1 (side by side):
	if self.a.y == self.b.y then
		y1 = self.a.y
		y2 = y1 + 1
		x1 = math.max(self.a.x, self.b.x)
		x2 = x1
	--case 2 (stairs):
	else
		x1 = math.max(self.a.x, self.b.x)
		x2 = x1 + 1
		y1 = math.max(self.a.y, self.b.y)
		y2 = y1
	end
	
	return {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

-- ====================================================

function TileTransition:getDX(source)
	if source == self.a then
		return self.b.x - self.a.x
	else
		return self.a.x - self.b.x
	end
end

-- ====================================================

function TileTransition:getDY(source)
	if source == self.a then
		return self.b.y - self.a.y
	else
		return self.a.y - self.b.y
	end
end

-- ====================================================

function TileTransition:isBorder()
	--is it along border of map where walls aren't allowed to be
	return self.a:isBorder() and self.b.isBorder()
end

-- ====================================================

function TileTransition:getVertices()
	local vertices = {}
	local orient = self.a:getOrientationOfTransition(self)
	table.insert(vertices, self.a.vertices[orient])
	table.insert(vertices, self.a.vertices[(orient + 1)%6])
	return vertices
end

-- ====================================================

function TileTransition:isPassable()
	--NOTE: does not consider if one side's tile terrain is impassable
	return self.wall == nil or self.wall:isPassable()
end

-- ====================================================
-- ====================================================
-- ====================================================
-- a 'corner' between three tiles (used for towers)

MapVertice = {}
MapVertice.__index = MapVertice


function MapVertice.create()
	local temp = {}
	setmetatable(temp, MapVertice)
	temp.adjacent = {}
	temp.isEdgeOfBase = false
	temp.tower = nil
	return temp
end

-- ====================================================

function MapVertice:addAdjacentTile(tile, orient)
	local temp = {tile = tile, orient = orient}
	table.insert(self.adjacent, temp)
end

-- ====================================================

function MapVertice:getAdjacent()
	--doesn't really matter which one
	for key, adj in pairs(self.adjacent) do
		return adj
	end
end

-- ====================================================

function MapVertice:distanceToTile(tile)
	local adj = self:getAdjacent()
	local offset = MapVertice.getOffset(adj.orient)
	local loc = {x = adj.tile.x + offset.x, y = adj.tile.y + offset.y + 0.5*(adj.tile.x%2)}
	local otherLoc = {x = tile.x, y = tile.y + 0.5*(tile.x%2)}
	return distance(loc, otherLoc)
end

-- ====================================================

function MapVertice.getOffset(orient)
	--static method that gives offset from center for a vertice at this orientation
	if orient == 0 then
		return {x = -0.5 + HEX_RATIO, y = -0.5}
	elseif orient == 1 then
		return {x = 0.5 - HEX_RATIO, y = -0.5}
	elseif orient == 2 then
		return {x = 0.5 + HEX_RATIO, y = 0}
	elseif orient == 3 then
		return {x = 0.5 - HEX_RATIO, y = 0.5}
	elseif orient == 4 then
		return {x = -0.5 + HEX_RATIO, y = 0.5}
	elseif orient == 5 then
		return {x = -0.5 - HEX_RATIO, y = 0}
	else
		return nil
	end
end

-- ====================================================

function MapVertice:getSubtile()
	--vertices basically lie on top of subtiles, this returns closest one
	local tile = self:getAdjacent().tile
	local orient = tile:getOrientationOfVertice(self)
	if orient == 0 then
		return tile:getSubtile(-2, -6)
	elseif orient == 1 then
		return tile:getSubtile(2, -6)
	elseif orient == 2 then
		return tile:getSubtile(2, 0):getRelativeSubtile({x = 2, y = 0})
	elseif orient == 3 then
		return tile:getSubtile(2, 4):getRelativeSubtile({x = 0, y = 2})
	elseif orient == 4 then
		return tile:getSubtile(-2, 4):getRelativeSubtile({x = 0, y = 2})
	elseif orient == 5 then
		return tile:getSubtile(-2, 0):getRelativeSubtile({x = -2, y = 0})
	else
		return nil
	end
end

-- ====================================================
-- ====================================================
-- ====================================================
-- part of a map tile; units occupy exactly one of these

MapSubtile = {}
MapSubtile.__index = MapSubtile
MapSubtile.X_OFFSET_PER_SUBTILE = 0.17
MapSubtile.Y_OFFSET_PER_SUBTILE = 0.08


function MapSubtile.create(x, y, parent)
	local temp = {}
	setmetatable(temp, MapSubtile)
	temp.x = x
	temp.y = y
	temp.parent = parent
	return temp
end

-- ====================================================

function MapSubtile:getXOffset()
	--from center of parent
	return self.x * MapSubtile.X_OFFSET_PER_SUBTILE
end

-- ====================================================

function MapSubtile:getYOffset()
	return self.y * MapSubtile.Y_OFFSET_PER_SUBTILE
end

-- ====================================================

function MapSubtile:getRelativeSubtile(pos)
	--NOTE: won't work if it's not in this tile or adjacent tile
	
	--check own tile first:
	local x = self.x + pos.x
	local y = self.y + pos.y
	local subtile = self.parent:getSubtile(x, y)
	if subtile ~= nil then
		return subtile
	end
	
	--check adjacent tiles:
	for key, tile in pairs(self.parent:getAdjacent()) do
		--NOTE: not confident this is correct...
		local adjX = x - 6 * (tile:getCenter().x - self.parent:getCenter().x)
		local adjY = y - 12 * (tile:getCenter().y - self.parent:getCenter().y)
		subtile = tile:getSubtile(adjX, adjY)
		if subtile ~= nil then
			--print("success!")
			return subtile
		end 
	end
	return nil
end

-- ====================================================

function MapSubtile:distanceTo(other)
	--distance to other subtile in units of subtiles
	local relX = other.x + (other.parent:getCenter().x - self.parent:getCenter().x) * 6
	local relY = other.y + (other.parent:getCenter().y - self.parent:getCenter().y) * 12

	return {x = relX - self.x, y = relY - self.y}
end

-- ====================================================

function MapSubtile:getAdjacent()
	--NOTE: first time this is called subtile will store results
	if self.adjacent ~= nil then
		return self.adjacent
	end
	self.adjacent = {
		self:getRelativeSubtile({x = 0, y = -2}),
		self:getRelativeSubtile({x = 0, y = 2}),
		self:getRelativeSubtile({x = -1, y = -1}),
		self:getRelativeSubtile({x = -1, y = 1}),
		self:getRelativeSubtile({x = 1, y = -1}),
		self:getRelativeSubtile({x = 1, y = 1})
	}
	return self.adjacent
end

-- ====================================================

function MapSubtile:isAdjacentTo(other)
	local adj = self:getAdjacent()
	return tableContains(adj, other)
end

-- ====================================================

function MapSubtile:getVertice()
	--return MapVertice that's basically in the same place:
	if self.x == -2 and self.y == -6 then
		return self.parent.vertices[0]
	elseif self.x == 2 and self.y == -6 then
		return self.parent.vertices[1]
	else
		return nil
	end
end

-- ====================================================