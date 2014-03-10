--pseudo-structure that sits on a map vertice

Tower = {}
Tower.__index = Tower


function Tower.create(towerType, vert)
	local temp = {}
	setmetatable(temp, Tower)
	temp.towerType = towerType
	temp.location = vert
	temp.hp = towerType.hp
	temp.cooldown = 0
	temp.fights = {}
	temp.isVillageTower = tableContains(villageTowerTypes, towerType)
	if towerType.numTraps ~= nil then
		temp.traps = towerType.numTraps
	end
	return temp
end

-- ====================================================

function Tower:update(dt)
	--build projects (UPGRADES ONLY):
	if self.buildProject ~= nil and self.buildProject.towerTypeOnCompletion ~= self.towerType then
		self.buildProject.age = self.buildProject.age + dt
		if self.buildProject.age >= self.buildProject.towerTypeOnCompletion.buildTime then
			currentGame:finishTowerBuildProject(self.buildProject)
		end
		return
	end

	--attack stuff:
	if self.towerType.attack ~= nil and self.buildProject == nil then
		self.cooldown = self.cooldown - dt
		if self.cooldown <= 0 then
			self.cooldown = self.cooldown + self.towerType.attack.cooldown
			self:fireProjectile()
		end
	end
	--update militia callups:
	if self.militiaCallup ~= nil then
		self.militiaCallup.progress = self.militiaCallup.progress + dt
		if self.militiaCallup.progress >= MILITIA_CALLUP_TIME then
			currentGame:instantiateMilitiaRegiment(self.militiaCallup.homeStructure, self)
			--self.militiaCallup.homeStructure.militiaCallup = nil
			--self.militiaCallup = nil
		end
	end
end

-- ====================================================

function Tower:fireProjectile()
	--find closest enemy unit:
	local target = nil
	local dist = -1
	local ownSubtile = self.location:getSubtile()
	for key, reg in pairs(currentGame.hostileRegiments) do
		for key, unit in pairs(reg.units) do
			local rawDist = ownSubtile:distanceTo(unit.location)
			--NOTE: 'd' must in units of tile in order to match range
			local d = math.abs(rawDist.x)*MapSubtile.X_OFFSET_PER_SUBTILE + math.abs(rawDist.y)*MapSubtile.Y_OFFSET_PER_SUBTILE
			if d <= self.towerType.attack.range and (target == nil or d < dist) then
				target = unit
				dist = d
			end
		end
	end
	--instantiate projectile:
	if target ~= nil then
		local proj = Projectile.create(self.location, target, self.towerType.attack)
		currentGame:addProjectile(proj)
	end
end

-- ====================================================

function Tower:onEndDefendPhase()
	self.cooldown = 0
end

-- ====================================================

function Tower:onEndBuildPhase()
	if self.towerType.numTraps ~= nil then
		self.traps = self.towerType.numTraps
	end
end

-- ====================================================

function Tower:takeDamage(dmg, dmgType)
	if self.towerType == towerTypes["gatetower"] then
		print("WARNING: damage done to gate-tower")
		return
	end
	
	dmg = calculateDamageAfterDefense(dmg, dmgType, self.towerType.defenseType, self.towerType.defenseLevel)
	self.hp = self.hp - dmg
	if self.hp <= 0 then
		for key, f in pairs(self.fights) do
			f:endFight(true)
		end
		currentGame:removeTower(self)
		return true
	else
		return false
	end
end

-- ====================================================

function Tower:enterFight(fight)
	table.insert(self.fights, fight)
end

function Tower:exitFight(fight)
	removeFromTable(self.fights, fight)
end

-- ====================================================

function Tower:upgrade()
	--already been vetted in Game, just do internal stuff here
	self.towerType = towerTypes[self.towerType.upgrade]
	self.hp = self.towerType.hp
end

-- ====================================================

function Tower:cancelMilitiaCallup()
	--return peasants to their workplace:
	local idx = 1
	for key, peasant in pairs(self.militiaCallup.peasants) do
		local slot = self.militiaCallup.homeStructure.employeeSlots[idx]
		slot.isClosed = false
		slot.peasant = peasant
		idx = idx + 1
	end
	self.militiaCallup.homeStructure.militiaCallup = nil
	self.militiaCallup = nil
end

-- ====================================================