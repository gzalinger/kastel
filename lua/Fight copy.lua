-- instance of a melee between two units

Fight = {}
Fight.__index = Fight


function Fight.create(attacker, defender, trans, tower)
	--NOTE: is 'defender' is nil, this is a fight against a wall or tower
	local temp = {}
	setmetatable(temp, Fight)
	temp.attacker = attacker
	temp.defender = defender
	temp.transition = trans
	temp.tower = tower --will be nil unless this is a fight against a tower
	temp:init()
	return temp
end

-- ====================================================

function Fight:isAgainstWall()
	return self.defender == nil
end

-- ====================================================

function Fight:init()
	--set up stuff (e.g. fight positions)
	if self.tower == nil then
		self.attackerOrient = self.attacker.location:getOrientationOfTransition(self.transition)
	else
		self.attackerOrient = self.attacker.location:getOrientationOfVertice(self.tower.location)
	end
	self.defenderOrient = (self.attackerOrient + 3) % 6
	--init fight position tables:
	self.attackerFrontPositions = {}
	self.attackerRearPositions = {}
	if self.defender ~= nil then
		self.defenderFrontPositions = {}
		self.defenderRearPositions = {}
	end
	
	local masterFrontPositions
	local masterRearPositions
	if self.tower == nil then
		masterFrontPositions = forwardFightPositions
		masterRearPositions = rearFightPositions
	else
		masterFrontPositions = towerFrontFightPositions
		masterRearPositions = towerRearFightPositions
	end
	
	--initialize list of available units for each combatant
	local attackerUnits = self.attacker:getUnitsForFight()
	local defenderUnits
	if self.defender ~= nil then
		defenderUnits = self.defender:getUnitsForFight()
	end
	
	--assign units:
	local idx = 1
	local isFront = true
	for key, u in pairs(attackerUnits) do
		if isFront then
			self.attackerFrontPositions[idx] = u
			u.fightPosition = masterFrontPositions[self.attackerOrient][idx]
			idx = idx + 1
			if idx > NUM_FORWARD_FIGHT_POSITIONS then
				idx = 1
				isFront = false
			end
		else
			self.attackerRearPositions[idx] = u
			u.fightPosition = masterRearPositions[self.attackerOrient][idx]
			idx = idx + 1
		end
	end
	if self.defender ~= nil then
		idx = 1
		isFront = true
		for key, u in pairs(defenderUnits) do
			if isFront then
				self.defenderFrontPositions[idx] = u
				u.fightPosition = masterFrontPositions[self.defenderOrient][idx]
				idx = idx + 1
				if idx > NUM_FORWARD_FIGHT_POSITIONS then
					idx = 1
					isFront = false
				end
			else
				self.defenderRearPositions[idx] = u
				u.fightPosition = masterRearPositions[self.defenderOrient][idx]
				idx = idx + 1
			end
		end
	end
end

-- ====================================================

function Fight:update(dt)
	local wallDmg = 0
	for key, unit in pairs(self.attackerFrontPositions) do
		if unit:updateMove(dt) then
			wallDmg = wallDmg + self:dealDamage(key, true, dt)
		end
	end
	for key, unit in pairs(self.attackerRearPositions) do
		unit:updateMove(dt)
	end
	if self.defender ~= nil then
		for key, unit in pairs(self.defenderFrontPositions) do
			if unit:updateMove(dt) then
				self:dealDamage(key, false, dt)
			end
		end
		for key, unit in pairs(self.defenderRearPositions) do
			unit:updateMove(dt)
		end
	else
		--CASE: fight is against wall or tower
		if self.tower ~= nil then
			--TOWER
			self.tower:takeDamage(wallDmg, self.attacker.regimentType.damageType)
			--NOTE: tower will call 'endFight' itself
		else
			--WALL
			if self.transition.wall:takeDamage(wallDmg, self.attacker.regimentType.damageType) then
				--wall has been destroyed:
				self:endFight(true)
			end
		end
	end
end

-- ====================================================

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

-- ====================================================

function Fight:unitKilledByTower(unit)
	--a unit involved in this fight was killed by something external to the fight
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
	local idx = -1
	for key, u in pairs(front) do
		if u == unit then
			idx = key
			break
		end
	end
	--case: unit was in front:
	if idx ~= -1 then
		self:removeDeadUnit(idx, front, rear, orient)
	else
		--case: unit was in rear
		for key, u in pairs(rear) do
			if u == unit then
				idx = key
			end
		end
		self:repositionRear(idx, rear, orient)
	end
end

-- ====================================================

function Fight:removeDeadUnit(unitIDX, frontPos, rearPos, orient)
	--remove dead guy:
	frontPos[unitIDX] = nil
	
	local masterFrontPositions
	if self.tower == nil then
		masterFrontPositions = forwardFightPositions
	else
		masterFrontPositions = towerFrontFightPositions
	end
	
	--try to fill from back:
	local i = #rearPos
	while i > 0 do
		if rearPos[i] ~= nil then
			frontPos[unitIDX] = rearPos[i]
			rearPos[i] = nil
			frontPos[unitIDX].fightPosition = masterFrontPositions[orient][unitIDX]
			return
		end
		i = i - 1
	end
	
	--try to fill from another fight:
	local u
	if orient == self.attackerOrient then
		u = self.attacker:getSingleFightReplacement(self, self:countUnits(self.attacker) == 0)
	else
		u = self.defender:getSingleFightReplacement(self, self:countUnits(self.defender) == 0)
	end
	if u ~= nil then
		frontPos[unitIDX] = u
		u.fightPosition = masterFrontPositions[orient][unitIDX]
		return
	end
	
	--reposition units along front:
	i = NUM_FORWARD_FIGHT_POSITIONS
	while i > unitIDX do
		if frontPos[i] ~= nil and i ~= unitIDX then
			frontPos[unitIDX] = frontPos[i]
			frontPos[i] = nil
			frontPos[unitIDX].fightPosition = masterFrontPositions[orient][unitIDX]
			return
		end
		i = i - 1
	end
	--check to see if this combat is over:
	if #frontPos == 0 then
		self:endFight(orient == self.defenderOrient)
	end
end

-- ====================================================

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

-- ====================================================

function Fight:endFight(attackerWon)
	local oldLoc
	if attackerWon then
		--move them into defender's tile:
		oldLoc = self.attacker.location
		if self.defender ~= nil then
			if self.defender:countFights() == 1 then
				self.attacker.location.regiment = nil
				self.attacker.location = self.defender.location
				self.defender.location.regiment = self.attacker
			end
		elseif self.tower == nil then
			local newLoc = self.transition:getDest(self.attacker.location)
			if newLoc.terrainType.passable and newLoc.regiment == nil then
				self.attacker.location.regiment = nil
				self.attacker.location = newLoc
				newLoc.regiment = self.attacker
			end
		--else was against tower; don't move regiment
		end
		--move anim will be called from exitFight()
	end
	
	self:redistributeSurvivors() --sends survivors to other fights
	
	self.attacker:exitFight(self, oldLoc)
	if self.defender ~= nil then
		self.defender:exitFight(self)
	end
	removeFromTable(currentGame.fights, self)
	
	if self.tower ~= nil then
		self.tower:exitFight(self)
	end
end

-- ====================================================

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

-- ====================================================

function Fight:countUnits(reg)
	local front
	local rear
	if reg== self.attacker then
		front = self.attackerFrontPositions
		rear = self.attackerRearPositions
	else
		front = self.defenderFrontPositions
		rear = self.defenderRearPositions
	end
	--count manually in case there are whole in arrays (sometimes this gets called mid casaulty-replacement):
	local count = 0
	for key, u in pairs(front) do count = count + 1 end
	for key, u in pairs(rear) do count = count + 1 end
	return count
end

-- ====================================================

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

-- ====================================================

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

-- ====================================================

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

-- ====================================================