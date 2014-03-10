-- instance of a melee between two units

Fight = {}
Fight.__index = Fight


function Fight.create(attacker, defender, trans, tower)
	--NOTE: is 'defender' is nil, this is a fight against a wall or tower
	local temp = {}
	setmetatable(temp, Fight)
	temp.attacker = attacker
	temp.defender = defender
	if trans ~= nil and trans.wall ~= nil then
		temp.wall = trans.wall
	end
	temp.tower = tower --will be nil unless this is a fight against a tower
	temp:init()
	return temp
end

-- ====================================================
--[[
function Fight:isAgainstWall()
	return self.defender == nil
end
--]]
-- ====================================================

function Fight:init()
	if self.wall ~= nil then
		self.fightType = "wall"
	elseif self.tower ~= nil then
		self.fightType = "tower"
	elseif self.defender ~= nil then
		self.fightType = "melee" --i.e. regiment on regiment
	else
		self.fightType = "???"
	end
	
	--copy units and store with fight-rleated data
	self.attackerUnits = {}
	for key, unit in pairs(self.attacker.units) do
		table.insert(self.attackerUnits, {unit = unit, victim = nil})
	end
	if self.defender ~= nil then
		self.defenderUnits = {}
		for key, unit in pairs(self.defender.units) do
			table.insert(self.attackerUnits, {unit = unit, victim = nil})
		end
	end
end

-- ====================================================

function Fight:update(dt)
	local damages = {} --list of little damage objects, to be assessed at end
	local attackerMoves = {} --units that have to move
	local defenderMoves = {}
	
	for key, obj in pairs(self.attackerUnits) do
		self:updateForUnit(obj, damages, attackerMoves, dt)
	end
	if self.defender ~= nil then
		for key, obj in pairs(self.defenderUnits) do
			self:updateForUnit(obj, damages, defenderMoves, dt)
		end
	end
	
	--decisions made, now take effects:
	self.attacker:doMovesForFight(self, attackerMoves)
	if self.defender ~= nil then
		self.defender:doMovesForFight(self, defenderMoves)
	end
	--deal damages:
	if self.fightType == "tower" then
		local totalDamage = 0
		for key, dmg in pairs(damages) do
			totalDamage = totalDamage + dmg.damage
		end
		self.tower:takeDamage(totalDamage, self.attacker.regimentType.damageType)
		
	elseif self.fightType == "wall" then
		--todo
	elseif self.fightType == "melee" then
		--todo
	end
end

-- ====================================================

function Fight:updateForUnit(obj, damages, moves, dt)
	--'damages' and 'moves' are pre-built lists to which results should be added
	--NOTE: obj has unit field; is not unit itself
	if obj.unit.locationOffset.x ~= 0 or obj.unit.locationOffset.y ~= 0 then
		--unit is still moving
		return
	end
	
	if self.fightType == "tower" then
		if obj.unit.location:isAdjacentTo(self.tower.location:getSubtile()) then
			--next to tower; attack!
			table.insert(damages, {attacker = obj.unit, damage = obj.unit.regimentType.dps * dt})
		else
			--move towards tower:
			table.insert(moves, obj.unit)
		end
		
	elseif self.fightType == "wall" then
		--todo
	elseif self.fightType == "melee" then
		--todo
	end
end

-- ====================================================
--[[
function Fight:dealDamage(unitIDX, attackerIsDealingDamage, dt)
	if self.defender == nil then
		--fight against wall
		return self.attacker.regimentType.dps * dt
	end
	
	--figure out which specific unit is getting hit:
	local victimIDX = unitIDX
	while (attackerIsDealingDamage and self.defenderFrontPositions[victimIDX] == nil) or ((not attackerIsDealingDamage) and self.attackerFrontPositions[victimIDX] == nil) do
		victimIDX = victimIDX - 1
		if victimIDX <= 0 then
			print("ERROR: could not find victim for damage!")
			return
		end
	end
	local victim
	local damage
	local damageType
	if attackerIsDealingDamage then
		victim = self.defenderFrontPositions[victimIDX]
		damage = self.attacker.regimentType.dps * dt
		damageType = self.attacker.regimentType.damageType
	else
		victim = self.attackerFrontPositions[victimIDX]	
		damage = self.defender.regimentType.dps * dt
		damageType = self.defender.regimentType.damageType
	end
	
	if victim:takeDamage(damage, damageType) then
		local front, back, orient
		if attackerIsDealingDamage then
			front = self.defenderFrontPositions
			rear = self.defenderRearPositions
			orient = self.defenderOrient
		else
			front = self.attackerFrontPositions
			rear = self.attackerRearPositions
			orient = self.attackerOrient
		end
		self:removeDeadUnit(victimIDX, front, rear, orient)
	end
	return 0
end
--]]
-- ====================================================

function Fight:unitKilledByTower(unit)
	self:removeDeadUnit(unit)
end

-- ====================================================

function Fight:removeDeadUnit(unit)
	--NOTE: unit will be removed from regiment in another function
	local isAttacker = unit.parent == self.attacker
	--remove from lists:
	if isAttacker then
		for key, obj in pairs(self.attackerUnits) do
			if obj.unit == unit then
				table.remove(self.attackerUnits, key)
				break
			end
		end
		--check to see if this combat is over:
		if #self.attackerUnits == 0 then
			self:endFight(false)
		end
	else
		for key, obj in pairs(self.defenderUnits) do
			if obj.unit == unit then
				table.remove(self.defenderUnits, key)
				break
			end
		end
		--check to see if this combat is over:
		if #self.defenderUnits == 0 then
			self:endFight(true)
		end
	end
end

-- ====================================================
--[[
function Fight:repositionRear(victimIdx, rearPositions, orient)
	--unit was killed in rear, reposition units to make sure there aren't gaps there
	local masterRearPositions
	if self.tower == nil then
		masterRearPositions = rearFightPositions
	else
		masterRearPositions = towerRearFightPositions
	end
	
	local idx = victimIdx + 1
	--while idx <= #rearFightPositions do
	while idx <= #masterRearPositions[orient] do
		local temp = rearPositions[idx]
		rearPositions[idx-1] = temp
		rearPositions[idx] = nil
		if temp ~= nil then
			temp.fightPosition = masterRearPositions[orient][idx - 1]
		end
		idx = idx + 1
	end
end
--]]
-- ====================================================

function Fight:endFight(attackerWon)
	--NOTE: "attackerWon" is not currently being used here
	self.attacker:exitFight(self)
	if self.defender ~= nil then
		self.defender:exitFight(self)
	end
	removeFromTable(currentGame.fights, self)
	
	if self.tower ~= nil then
		self.tower:exitFight(self)
	end
end

-- ====================================================
--[[
function Fight:giveUnitsForNewFight(regiment, unitList, percent)
	--one combatant has entered new fights and some units from this fight must go to it
	local front
	local rear
	if regiment == self.attacker then
		front = self.attackerFrontPositions
		rear = self.attackerRearPositions
	else
		front = self.defenderFrontPositions
		rear = self.defenderRearPositions
	end
	
	local count = self:countUnits(regiment)
	if count <= 1 then
		return --can't give last unit
	end
	local toGive = math.max(1, math.floor(count * percent))
	for key, u in pairs(rear) do
		table.insert(unitList, u)
		self:unitKilledByTower(u)
		toGive = toGive - 1
		if toGive == 0 then
			return
		end
	end
	for key, u in pairs(front) do
		table.insert(unitList, u)
		self:unitKilledByTower(u)
		toGive = toGive - 1
		if toGive == 0 then
			return
		end
	end
end
--]]
-- ====================================================
--[[
function Fight:giveSingleReplacementUnit(reg, pullFromFront)
	local front
	local rear
	if reg== self.attacker then
		front = self.attackerFrontPositions
		rear = self.attackerRearPositions
	else
		front = self.defenderFrontPositions
		rear = self.defenderRearPositions
	end
	
	--try from back:
	local i = #rear
	while i > 0 do
		if rear[i] ~= nil then
			local temp = rear[i]
			rear[i] = nil
			return temp
		end
		i = i - 1
	end
	--from front
	if not pullFromFront or self:countUnits() == 1 then
		return nil
	end
	i = #front
	while i > 0 do
		if front[i] ~= nil then
			local temp = front[i]
			front[i] = nil
			return temp
		end
	end
	return nil
end
--]]
-- ====================================================
--[[
function Fight:redistributeSurvivors()
	--all remaining units are sent to other fights their regiment might be in
	for key, u in pairs(self.attackerFrontPositions) do
		u.parent:giveUnitToExistingFight(self, u)
	end
	for key, u in pairs(self.attackerRearPositions) do
		u.parent:giveUnitToExistingFight(self, u)
	end
	if self.defender ~= nil then
		for key, u in pairs(self.defenderFrontPositions) do
			u.parent:giveUnitToExistingFight(self, u)
		end
		for key, u in pairs(self.defenderRearPositions) do
			u.parent:giveUnitToExistingFight(self, u)
		end
	end
end
--]]
-- ====================================================
--[[
function Fight:addUnit(unit)
	--a new unit has joined fight; put in correct position
	local front
	local rear
	local orient
	if unit.parent == self.attacker then
		front = self.attackerFrontPositions
		rear = self.attackerRearPositions
		orient = self.attackerOrient
	else
		front = self.defenderFrontPositions
		rear = self.defenderRearPositions
		orient = self.defenderOrient
	end
	--try to fill front first:
	for i = 0, NUM_FORWARD_FIGHT_POSITIONS do
		if front[i] == nil then
			front[i] = unit
			unit.fightPosition = frontFightPositions[orient][i]
			return
		end
	end
	--put in rear:
	local idx = #rear + 1
	rear[idx] = unit
	unit.fightPosition = rearFightPositions[orient][idx]
end
--]]
-- ====================================================