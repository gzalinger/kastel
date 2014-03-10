-- 'utility object' to help organize movement and pathing-related logic

RegimentMoveManager = {}
RegimentMoveManager.__index = RegimentMoveManager


function RegimentMoveManager.create(parent)
	local temp = {}
	setmetatable(temp, RegimentMoveManager)
	temp.parent = parent --regiment it belongs to
	temp.moveAnim = nil --also used to identify when regiment is mid-move
	
	temp.finalTravelDestination = nil --subtile it's ultimately heading for
	temp.intermediateTravelDestination = nil --subtile
	temp.towerDestination = nil --used when heading to a tower, not a subtile
	temp.tileMovePath = nil --linkedlist of tiles to get to destination
	temp.subtileMovePath = nil --list of subtiles for nearby moves
	return temp
end

-- ====================================================

function RegimentMoveManager:isMoving()
	return self.moveAnim ~= nil
end

-- ====================================================

function RegimentMoveManager:moveWithinTile(destination)
	--move in formation to a location w/in same tile
	self.parent.isGoingToRest = false
	local path = IDAStar.findPath({mode = "formation", from = self.parent.bannerman.location, unit = self.parent.bannerman, destination = destination, regiment = self.parent})
	if path == nil or path.size == 0 then
		self:clearTravelData()
		self.parent.freezeTime = 2.0
		return
	end	
	path:popFirst()
	self.subtileMovePath = path
	self.finalTravelDestination = destination
	self.intermediateTravelDestination = destination
	self.tileMovePath = nil
	
	if not self:isMoving() then
		self:takeNextMoveStep()
	end	
end

-- ====================================================

function RegimentMoveManager:moveBetweenTiles(destination)
	--NOTE: destination is a subtile
	self.parent.isGoingToRest = false
	local path = IDAStar.findPath({mode = "tile", from = self.parent.bannerman.location.parent, destinations = {destination.parent}, moveType = self.parent.regimentType.moveType, isMonster = (not self.parent:isFriendly())})
	if path == nil or path.size == 0 then
		self:clearTravelData()
		self.parent.freezeTime = 2.0
		return
	end
	path:popFirst()
	self.tileMovePath = path
	self.subtileMovePath = nil
	self.finalTravelDestination = destination
	self.intermediateTravelDestination = nil
	
	if not self:isMoving() then
		self:takeNextMoveStep()
	end
end

-- ====================================================

function RegimentMoveManager:moveToTower(tower)
	self.parent.isGoingToRest = false
	self.tileMovePath = nil
	self.subtileMovePath = nil
	self.finalTravelDestination = nil
	self.intermediateTravelDestination = nil
	
	self.towerDestination = tower
	--case: tower is in same tile
	if self.parent.bannerman.location.parent:getOrientationOfVertice(tower.location) ~= -1 then
		--act as if they just got here from longer path
		self.intermediateTravelDestination = self.parent.bannerman.location
		self.tileMovePath = nil
		if not self:isMoving() then
			self:takeNextMoveStep()
		end
	else
		--navigate to any tile adjacent to tower
		local destSet = {}
		for key, adj in pairs(tower.location.adjacent) do
			table.insert(destSet, adj.tile)
		end
		local path = IDAStar.findPath({mode = "tile", from = self.parent.bannerman.location.parent, destinations = destSet, moveType = self.parent.regimentType.moveType, isMonster = (not self.parent:isFriendly())})
		if path == nil or path.size == 0 then
			self.towerDestinaton = nil
			self.parent.freezeTime = 2.0
			return
		end
		path:popFirst()
		self.tileMovePath = path
		if not self:isMoving() then
			self:takeNextMoveStep()
		end
	end
end

-- ====================================================
--[[
function RegimentMoveManager:followPath(path)
	--follow multi-step path of moves between tiles
	if path == nil or path.size == 0 then
		self.parent.freezeTime = 2.0
		return
	end
	
	local dest = nil
	if not self:isMoving() then --if reg is mid-move, they will pick up this new path once they finish current move
		dest = path:popFirst().location
	end
	if path.size > 0 then
		self.movePath = path
	else
		self.movePath = nil
	end
	
	if not self:isMoving() then 
		if not currentGame:moveRegiment(self.parent, currentGame.map:getTile(dest.x, dest.y)) then
			self.movePath = nil --couldn't move that step, will have to recalculate
		end
	end
end
--]]
-- ====================================================
--[[
function RegimentMoveManager:takeNextMoveStep()
	--next subtile step towards travelDestination
	--HAX no-pathing system with subtiles
	if self.travelDestination == nil then
		return
	end
	if self:translateFormationTowards(self.travelDestination) then
		--reached destination
		self.travelDestination = nil
	end
end
--]]
-- ====================================================

function RegimentMoveManager:takeNextMoveStep()
	--update paths and move towards next subtile
	self.moveAnim = nil
	
	--case:tower endgame:
	if self.towerDestination ~= nil and self.tileMovePath == nil then
		if not self:takeStepTowardsTower() then
			self:clearMoveData()
		end
		return
	--case: done with travel:
	elseif self.parent.bannerman.location == self.finalTravelDestination then
		--resting:
		if self.parent.isGoingToRest and self.parent:isAtHomeStructure() then
			self.parent.isGoingToRest = false
			self.parent:undeploy()
		end
		self:clearMoveData()
		return
	--case: done with current leg of journey
	elseif self.intermediateTravelDestination == nil or self.parent.bannerman.location == self.intermediateTravelDestination then
		if self.tileMovePath == nil then
			--this can happen as a result of halting
			self:clearMoveData()
			return
		end
		local loc = self.tileMovePath:popFirst().location
		local nextDest --subtile
		if self.tileMovePath.size == 0 then
			--this is last step: go to final dest:
			if self.towerDestination ~= nil then
				if not self:takeStepTowardsTower() then
					self:clearMoveData()
				end
				self.tileMovePath = nil
				return
			else
				--moving to subtile:
				nextDest = self.finalTravelDestination
			end
		else
			--still in middle of journey, go to center or next tile
			nextDest = currentGame.map:getTile(loc.x, loc.y):getSubtile(0, 0)
		end
		local path = IDAStar.findPath({mode = "formation", from = self.parent.bannerman.location, unit = self.parent.bannerman, destination = nextDest, regiment = self.parent})
		if path == nil or path.size == 0 then
			self:clearMoveData()
			return
		end
		path:popFirst()
		self.subtileMovePath = path
		self.intermediateTravelDestination = nextDest
	end
	--take next step towards intermediate destination:
	local nextDest = self.subtileMovePath:popFirst()
	if nextDest ~= nil then
		self:translateFormationTowards(nextDest.subtile)
	else
		self:clearMoveData()
	end
end

-- ====================================================

function RegimentMoveManager:takeStepTowardsTower(units)
	--give each unit next step towards destination tower and init move anim	
	--copy units:
	if units == nil then
		units = {}
		for key, u in pairs(self.parent.units) do
			table.insert(units, u)
		end
	end
	
	--move all units
	local atLeastOne = false
	for n = 1, 3 do --do three iterations, then give up
		for key, unit in pairs(units) do
			--see if they're already there:
			if unit.location:isAdjacentTo(self.towerDestination.location:getSubtile()) then
				removeFromTable(units, unit)
			else
				local path = IDAStar.findPath({mode = "tower", unit = unit, from = unit.location, destination = self.towerDestination.location:getSubtile(), moveType = unit.regimentType.moveType, ignoreUnits = units})
				if path ~= nil or path.size > 1 then
					path:popFirst()
					local dest = path:popFirst().subtile
					if currentGame:moveUnitTo(unit, dest) then
						--successful move!
						removeFromTable(units, unit)
						atLeastOne = true
					end
				end
			end
		end
	end
	if atLeastOne then
		self.moveAnim = AnimMoveRegiment.create(self.parent)
	end
	return atLeastOne
end

-- ====================================================

function RegimentMoveManager:halt()
	--finish current move, but clear longer-term pathing/destination
	self:clearMoveData()
end

-- ====================================================

function RegimentMoveManager:clearMoveData()
	self.tileMovePath = nil
	self.subtileMovePath = nil
	self.finalTravelDestination = nil
	self.intermediateTravelDestination = nil
	self.parent.isGoingToRest = false
	self.towerDestination = nil
end

-- ====================================================

function RegimentMoveManager:translateFormationTowards(dest)
	--simple move of entire static formation in the direction of destination
	local dist = self.parent.bannerman.location:distanceTo(dest)
	if dist.x == 0 and dist.y == 0 then
		return true
	end
	
	local dir --direction of travel
	if dist.x >= 2 then
		dir = {x = 2, y = 0}
	elseif dist.x <= -2 then
		dir = {x = -2, y = 0}
	elseif dist.y >= 2 then
		dir = {x = 0, y = 2}
	elseif dist.y <= -2 then
		dir = {x = 0, y = -2}
	elseif dist.x > 0 and dist.y > 0 then
		dir = {x = 1, y = 1}
	elseif dist.x > 0 and dist.y < 0 then
		dir = {x = 1, y = -1}
	elseif dist.x < 0 and dist.y > 0 then
		dir = {x = -1, y = 1}
	elseif dist.x < 0 and dist.y < 0 then
		dir = {x = -1, y = -1}
	end
	
	if dir == nil then --shouldn't ever happen
		return true
	end
	
	return not currentGame:translateFormation(self.parent, dir) --if move failed, treat it like reaching destination
end

-- ====================================================
--[[
function RegimentMoveManager:setTravelDestination(dest)
	self.travelDestination = dest
	if not self:isMoving() then
		if self:translateFormationTowards(dest) then
			self.travelDestination = nil
		end
	end
end
--]]
-- ====================================================

function RegimentMoveManager:moveTowardsHome()
	local dest = self.parent.homeStructure.location:getSubtile(0, 0)
	if self.parent.bannerman.location.parent == dest.parent then
		self:moveWithinTile(dest)
	else
		self:moveBetweenTiles(dest)
	end
end

-- ====================================================

function RegimentMoveManager:doMovesForFight(fight, units)
	--move given set of units one space to get them closer to fight
	if fight.fightType == "tower" then
		self:takeStepTowardsTower(units)
	elseif fight.fightType == "wall" then
		--todo
	elseif fight.fightType == "melee" then
		--todo
	end
end

-- ====================================================