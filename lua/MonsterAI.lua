--code for making enemies act

MonsterAI = {}
MonsterAI.__index = MonsterAI


function MonsterAI.act(regiment, dt)
	--NOTE: assumes they aren't already moving or fighting
	if regiment.spawnSickness > 0 then
		regiment.spawnSickness = regiment.spawnSickness - dt
		return
	end
	
	--CASE 1: already at an enemy structure
	if regiment.bannerman.location.parent.structure ~= nil and regiment.bannerman.location.parent.structure.structType.name ~= "Rubble" then
		return
	end
	
	--CASE 2: adjacent to friendly regiment
	--[[
	for key, tile in pairs(regiment.location:getAdjacent()) do
		if tile.regiment ~= nil and tile.regiment:isFriendly() then
			if currentGame:initMelee(regiment, tile.regiment) then
				return
			end
		end
	end
	--]]
	
	--CASE 3: near a tower tower
	--if they're already next to one, start fight:
	local tower = MonsterAI.getAdjacentTower(regiment)
	if tower ~= nil and tower.towerType ~= towerTypes["gatetower"] then
		--start fight:
		currentGame:initTowerAttack(regiment, tower)
		return
	end
	--if they'e near one, go to it
	if not regiment:isMurdering() then
		for key, vert in pairs(regiment:getLocation().vertices) do
			if vert.tower ~= nil and vert.tower.towerType ~= towerTypes["gatetower"] then
				regiment:moveToTower(vert.tower)
				return
			end
		end
	end
	
	
	--CASE 4: adjacent to a structure
	--[[
	for key, tile in pairs(regiment.location:getAdjacent()) do
		local trans = regiment.location:getTransitionTo(tile)
		if tile.structure ~= nil and tile.structure.structType.name ~= "Rubble" and trans:isPassable() then
			--found adjacent structure, now move to it
			if tile.regiment == nil then
				currentGame:moveRegiment(regiment, tile)
				return
			elseif tile.regiment:isFriendly() and tile.regiment.fight == nil then
				currentGame:initMelee(regiment, tile.regiment)
				return
			end
		end
	end
	--]]
	
	--CASE 5: adjacent to wall
	--[[
	if not regiment:isMurdering() then
		for key, trans in pairs(regiment.location.transitions) do
			if trans.wall ~= nil and (not trans.wall.isOpen) and (not trans.wall:isBroken()) then
				currentGame:initWallAttack(regiment, trans.wall)
				return
			end
		end
	end
	--]]
	
	--CASE 6: move 1 step towards town hall
	if regiment.moveManager.tileMovePath ~= nil or regiment.moveManager.subtileMovePath ~= nil then
		regiment:takeNextMoveStep()
	else
		--move towards center:
		if regiment.bannerman.location.parent == currentGame.map.center then
			regiment:moveWithinTile(currentGame.map.center:getSubtile(0, 0))
		else
			regiment:moveBetweenTiles(currentGame.map.center:getSubtile(0, 0))
		end
	end
end

-- ====================================================

function MonsterAI.getAdjacentTower(regiment)
	--return any tower adjacent to this regiment (or nil if there is none)
	for key, unit in pairs(regiment.units) do
		for key, subtile in pairs(unit.location:getAdjacent()) do
			local vert = subtile:getVertice()
			if vert ~= nil and vert.tower ~= nil then
				return vert.tower
			end
		end
	end
	return nil
end

-- ====================================================