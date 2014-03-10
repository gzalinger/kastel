--represents an instance of a regiment (friendly or hostile)

Regiment = {}
Regiment.__index = Regiment


function Regiment.create(regimentType, home, numUnits)
	local temp = {}
	setmetatable(temp, Regiment)
	temp.regimentType = regimentType
	temp.homeStructure = home --will be nil if this is a hostile regiment
	temp:init(numUnits)
	temp.bannerman = nil --unit "elected" to represent center of regiment
	--temp.location = nil --tile regiment is currently at (defense phase only)
	--temp.moveAnim = nil
	temp.isMilitia = false
	temp.fights = {}
	--temp.travelDestination = nil --hax for new subtile system; subtile where they want to get
	temp.moveManager = RegimentMoveManager.create(temp)
	temp.isGoingToRest = false
	if home == nil then
		temp.spawnSickness = 0.5 --to keep it from acting just after getting created
	else
		temp.spawnSickness = 0
	end
	return temp
end

-- ====================================================

function Regiment:init(numUnits)
	if numUnits == nil then
		numUnits = self.regimentType.defaultUnitsPerRegiment
	end
	self.maxUnits = numUnits --stores original umber of units this reg has in case of casualties
	self.units = {}
	for i = 1, numUnits do
		self.units[i] = Unit.create(self.regimentType, self, i)
	end
end

-- ====================================================

function Regiment:getLocation()
	--returns a map TILE
	if self.bannerman == nil then
		return nil
	end
	return self.bannerman.location.parent
end

-- ====================================================
--[[
function Regiment:placeAt(tile)
	local place = tile
	if tile.regiment ~= nil then
		for key, adj in pairs(tile:getAdjacent()) do
			if adj.regiment == nil and adj.terrainType.passable then
				place = adj
				break
			end
		end
	end

	self.location = place
	for key, u in pairs(self.units) do
		u:resetLocation()
	end
	place.regiment = self
end
--]]

-- ====================================================

function Regiment:placeAt(tile)
	local formation = Formation.create(#self.units, "marching")
	self:setFormation(formation, tile:getSubtile(0, 0)) --NOTE: this function assumes reg will be placed at center of tile
end

-- ====================================================

function Regiment:setFormation(formation, centerSubtile)
	self.formation = formation
	self.bannerman = nil
	local idx = 1
	for key, unit in pairs(self.units) do
		if self.bannerman == nil then
			self.bannerman = unit
		end
		local loc = centerSubtile:getRelativeSubtile(formation.positions[idx])
		unit:setLocation(loc)
		loc.unit = unit
		idx = idx + 1
	end
end

-- ====================================================
--[[
function Regiment:doMoveAnimation(oldLoc)
	local anim = AnimMoveRegiment.create(self)
	self.moveAnim = anim
	table.insert(currentGame.animations, anim)
	for key, u in pairs(self.units) do
		u:move(oldLoc)
	end
end
--]]
-- ====================================================

function Regiment:isMoving()
	return self.moveManager:isMoving()
end

-- ====================================================

function Regiment:isFriendly()
	return self.regimentType.isFriendly
end

-- ====================================================

function Regiment:enterFight(fight)
	table.insert(self.fights, fight)
	self.fight = fight --NOTE: 'fight' field no longer used; this is kept b/c old system checked if it was nil to determine if reg was in ANY fights
	if self.murderAttack ~= nil then
		self.murderAttack = nil
	end
end

-- ====================================================

function Regiment:exitFight(fight, oldLoc)
	removeFromTable(self.fights, fight)
	--NOTE: 'fight' field no longer used; this is kept b/c old system checked if it was nil to determine if reg was in ANY fights:
	if self.fight == fight then
		self.fight = nil
		for key, f in pairs(self.fights) do
			if f ~= fight then
				self.fight = f
			end
		end
	end
		
	--todo: return to formation
end

-- ====================================================

function Regiment:removeDeadUnit(u)
	u.location.unit = nil
	for i = u.idx, self.maxUnits do
		if i == self.maxUnits then
			self.units[i] = nil
		else
			--no gaps
			self.units[i] = self.units[i + 1]
			if self.units[i] ~= nil then
				self.units[i].idx = i
			end
		end
	end
	--enemies give gold:
	if not self:isFriendly() then
		currentGame:giveKillReward(u)
	end
	--peasant militia case:
	if u.militiaPeasant ~= nil then
		u.militiaPeasant:kill()
	end
	--regiment dead case:
	if #self.units == 0 then
		--self.location.regiment = nil
		currentGame:removeRegiment(self)
		if self.isMilitia then
			self.homeStructure.militiaRegiment = nil
		end
		if self.jobAssignment ~= nil then
			currentGame:addEngineerJob(self.jobAssignment)
		end
	end
end

-- ====================================================

function Regiment:regenerate()
	--recover at end of phase
	for key, u in pairs(self.units) do
		u.hp = u:maxHP()
	end
	if #self.units == 0 then
		return --wiped out regiments don't replenish
	end
	--replenish new units:
	if self.homeStructure.hp == self.homeStructure.structType.hp then
		local newUnits = math.min(self.maxUnits - #self.units, self.regimentType.replenishRate)
		local start = #self.units
		for i = 1, newUnits do
			self.units[start + i] = Unit.create(self.regimentType, self, start + i)
		end
	end
end

-- ====================================================

function Regiment:isDead()
	return #self.units == 0
end

-- ====================================================

function Regiment:resurrect()
	--come back from the dead (i.e. get one turn of replenishment)
	local newUnits = math.min(self.maxUnits, self.regimentType.replenishRate)
	for i = 1, newUnits do
		self.units[i] = Unit.create(self.regimentType, self, i)
	end
end

-- ====================================================

function Regiment:followPath(path)
	self.moveManager:followPath(path)
end

-- ====================================================
--[[
function Regiment:takeNextMoveStep()
	if self.movePath == nil or not self:isFriendly() then
		--monster regiments must 'check in' with AI before taking next step
		return 
	else
		self:followPath(self.movePath)
	end
end
--]]
-- ====================================================

function Regiment:takeNextMoveStep()
	self.moveManager:takeNextMoveStep()
end

-- ====================================================

function Regiment:getRandomUnit()
	local r = math.random(1, #self.units)
	return self.units[r]
end

-- ====================================================

function Regiment:getUnitsForFight()
	--make list of units available for a new melee
	local a = {}
	local numFights = self:countFights()
	if numFights == 0 then
		--everyone is available
		for key, u in pairs(self.units) do
			table.insert(a, u)
		end
		return a
	end
	--draw units from each existing fight:
	local percent = 1.0 / (numFights + 1) --percent of units in each fight which should be given
	for key, fight in pairs(self.fights) do
		fight:giveUnitsForNewFight(self, a, percent)
	end
	return a
end

-- ====================================================

function Regiment:countFights()
	local count = 0
	for key, f in pairs(self.fights) do count = count + 1 end
	return count
end

-- ====================================================

function Regiment:getSingleFightReplacement(fight, pullFromFront)
	--a fight needs a replacement unit; see if it can draw from another fight
	--NOTE: 'pullFromFront' will be true if fight lost last unit and NEEDS a replacement
	local biggestFight = nil
	for key, f in pairs(self.fights) do
		if f ~= fight and (biggestFight == nil or f:countUnits(self) > biggestFight:countUnits(self)) then
			biggestFight = f
		end
	end
	if biggestFight ~= nil then
		return biggestFight:giveSingleReplacementUnit(self, pullFromFront)
	else
		return nil
	end
end

-- ====================================================


function Regiment:giveUnitToExistingFight(oldFight, unit)
	--this unit has been released by their old fight; send to another one
	local smallestFight = nil
	for key, f in pairs(self.fights) do
		if f~= oldFight and (smallestFight == nil or f:countUnits(self) < smallestFight:countUnits(self)) then
			smallestFight = f
		end
	end
	if smallestfight ~= nil then
		smallestFight:addUnit(unit)
	end
end

-- ====================================================

function Regiment:takeSplashDamage(damage, damageType, exemption)
	--do damage to everyone but exemption
	for key, u in pairs(self.units) do
		if u ~= exemption and u:takeDamage(damage, damageType) then
			--remove from fights
			for key, f in pairs(self.fights) do
				f:unitKilledByTower(u)
			end
		end
	end
end

-- ====================================================

function Regiment:increaseMaxUnits(n)
	--increase cap and add units
	self.maxUnits = self.maxUnits + n
	local start = #self.units
	for i = 1, n do
		self.units[i + start] = Unit.create(self.regimentType, self, i + start)
	end
end

-- ====================================================

function Regiment:getDefenseLevel()
	local defLevel = self.regimentType.defenseLevel
	if self.regimentType == regimentTypes["footmen"] and Upgrade.isPurchased("footmenArmor") then --upgrades["footmenArmor"].purchased then
		defLevel = defLevel + 1
	end
	return defLevel
end

-- ====================================================

function Regiment:isMurdering()
	return self.regimentType.murderDPS ~= nil
end

-- ====================================================

function Regiment:update(dt)
	--NOTE: some functions (fighting) are handled elsewhere
	--moving
	if self.moveManager.moveAnim ~= nil then
		self.moveManager.moveAnim:update(dt)
	end
	
	--freezing 'AI'
	if self.freezeTime ~= nil and self.freezeTime > 0 then
		self.freezeTime = self.freezeTime - dt
		return
	end
	
	--engineers:
	if self.regimentType == regimentTypes["engineer"] and not self:isMoving() and self.fight == nil and self:isDeployed() then
		--go to or work at job:
		if self.jobAssignment ~= nil then
			local isThere = self.jobAssignment:isRegimentAt(self)
			if not isThere then
				--move towards job
				self.jobAssignment:moveRegimentTowards(self)
			end
			if isThere or self.jobAssignment:isTower() then
				--always try to work at tower jobs b/c some units can be there while others aren't yet
				self.jobAssignment:doWork(self, dt)
			end
		--no assignment; go home
		else
			self:rest()
		end
	end
end

-- ====================================================

function Regiment:isEngineer()
	return self.regimentType == regimentTypes["engineer"]
end

-- ====================================================

function Regiment:isDeployed()
	return (not self:isDead()) and self.bannerman ~= nil and self.bannerman.location ~= nil
end

-- ====================================================
--[[
function Regiment:setTravelDestination(dest)
	self.moveManager:setTravelDestination(dest)
end
--]]
-- ====================================================

function Regiment:translateFormationTowards(dest)
	self.moveManager:translateFormationTowards(dest)
end

-- ====================================================

function Regiment:halt()
	--finish current move, but clear longer-term pathing/destination
	self.moveManager:halt()
end

-- ====================================================

function Regiment:moveWithinTile(dest)
	self.moveManager:moveWithinTile(dest)
end

-- ====================================================

function Regiment:moveBetweenTiles(dest)
	self.moveManager:moveBetweenTiles(dest)
end

-- ====================================================

function Regiment:moveToTower(tower)
	self.moveManager:moveToTower(tower)
end

-- ====================================================

function Regiment:rest()
	--go to home structure and un-deploy
	if self:isMoving() or self.fight ~= nil then
		return
	end
	--already there:
	if self:isAtHomeStructure() then
		self:undeploy()
	else
		--move to home structure, rest when you get there
		local loc = self.homeStructure.location:getSubtile(0, 0)
		if self.bannerman.location.parent == loc.parent then
			self:moveWithinTile(loc)
		else
			self:moveBetweenTiles(loc)
		end
		self.isGoingToRest = true
	end
end

-- ====================================================

function Regiment:isAtHomeStructure()
	return not self:isMoving() and self.bannerman.location ~= nil and self.bannerman.location == self.homeStructure.location:getSubtile(0, 0)
end

-- ====================================================

function Regiment:undeploy()
	--clear locations
	for key, u in pairs(self.units) do
		u.location.unit = nil
		u.location = nil
	end
	if ui.selectedRegiment == self then
		ui:selectRegiment(nil)
	end
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Regiment:doMovesForFight(fight, units)
	self.moveManager:doMovesForFight(fight, units)
end

-- ====================================================
-- ====================================================
-- ====================================================
-- an individual character within a regiment

Unit = {}
Unit.__index = Unit


function Unit.create(regimentType, parent, idx)
	local temp = {}
	setmetatable(temp, Unit)
	temp.regimentType = regimentType
	temp.parent = parent --the regiment they belong to
	temp.idx = idx --index within parent regiment (determines where they stand)
	temp.hp = temp:maxHP()
	temp.location = nil --subtile where it's standing
	temp.locationOffset = {x = 0, y = 0} --offset from actual positions (i.e. unit is mid-move), in units of tiles
	--temp.fightPosition = nil --where (in x,y offsets) this unit stands during melee; should be set by Fight object
	return temp
end

-- ====================================================

function Unit:setLocation(subtile)
	self.location = subtile
	self.locationOffset = {x = 0, y = 0}
end

-- ====================================================
--[[
function Unit:resetLocation()
	local loc = unitLocations[self.idx]
	self.location = {x = loc.x, y = loc.y}
end
--]]
-- ====================================================
--[[
function Unit:move(oldTileLoc)
	--signals the unit that it's parent regiment is moving
	self.location.x = self.location.x + oldTileLoc.x - self.parent.location.x
	self.location.y = self.location.y + (oldTileLoc:getCenter().y - self.parent.location:getCenter().y)
end
--]]
-- ====================================================
--[[
function Unit:updateMove(dt)
	local target --where they're moving to
	target = self.fightPosition
	if target == nil then
		target = unitLocations[self.idx]
	end
	local moveRate = self.parent.location.terrainType.moveRates[self.regimentType.moveType]
	--trap:
	if self.trap ~= nil then
		moveRate = 0
	end
	--move towards correct position
	if (self.regimentType.speed*dt*moveRate) >= distance(self.location, target) then
		self.location.x = target.x
		self.location.y = target.y
		return true
	end
	local dir = angleTo(self.location, target)
	local dX = self.regimentType.speed * dt * math.cos(dir) * moveRate
	local dY = self.regimentType.speed * dt * math.sin(dir) * moveRate
	self.location.x = self.location.x + dX
	self.location.y = self.location.y + dY
	return false
end
--]]
-- ====================================================

function Unit:updateMove(dt)
	--move unit so that locationOffset approaches zero
	local moveRate = self.parent.bannerman.location.parent.terrainType.moveRates[self.regimentType.moveType]
	--trap:
	if self.trap ~= nil then
		moveRate = 0
	end
	local move = self.regimentType.speed * dt * moveRate
	
	--end case:
	if move >= distance(self.locationOffset, {x = 0, y = 0}) then
		self.locationOffset = {x = 0, y = 0}
		return true
	end
	--non-end case movement:
	local angle = angleTo(self.locationOffset, {x = 0, y = 0})
	local dX = move * math.cos(angle)
	local dY = move * math.sin(angle)
	self.locationOffset.x = self.locationOffset.x + dX
	self.locationOffset.y = self.locationOffset.y + dY
	return false --not yet at final position
end

-- ====================================================

function Unit:maxHP()
	return self.regimentType.unitHP
end

-- ====================================================

function Unit:takeDamage(dmg, dmgType)
	--failsafe:
	if self.hp <= 0 then
		return false --already dead; cannot be killed again
	end
	
	dmg = calculateDamageAfterDefense(dmg, dmgType, self.regimentType.defenseType, self.parent:getDefenseLevel())
	self.hp = self.hp - dmg
	if self.hp <= 0 then
		self.parent:removeDeadUnit(self)
		return true
	else
		return false
	end
end

-- ====================================================