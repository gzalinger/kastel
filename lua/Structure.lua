-- instance of a player building

Structure = {}
Structure.__index = Structure


function Structure.create(structType)
	local temp = {}
	setmetatable(temp, Structure)
	temp.structType = structType
	temp.hp = structType.hp
	temp.isVillageStruct = tableContains(villageStructureTypes, structType)
	--special cases for extra info:
	if structType.spell ~= nil then
		temp.spell = Spell.create(structType.spell, temp)
	end
	if structType.maxPopulation ~= nil then
		temp.peasantResidents = {}
		temp.breadIncome = 0.0 --how much bread they're getting provided (per second)
		temp.newPeasant = 0.0 --progress towards a new peasant
	end
	if structType.employees ~= nil then
		temp.employeeSlots = {}
		for i = 1, structType.employees do
			temp.employeeSlots[i] = {idx = i, peasant = nil}
		end
	end
	if structType.production ~= nil then
		temp.resourcesBanked = 0
		if structType.production.resourceType == "wheat" then
			temp.isProducingWheat = true
		end
	end
	
	return temp
end

-- ====================================================

function Structure:takeDamage(dmg, dmgType)
	dmg = calculateDamageAfterDefense(dmg, dmgType, self.structType.defenseType, self.structType.defenseLevel)
	self.hp = self.hp - dmg
	if self.hp <= 0 then
		currentGame:removeStructure(self)
	end
end

-- ====================================================

function Structure:repairGate()
	local cost = wallTypes["gate"].repairCost
	if self.gate.hp > 0 or not currentGame:canAfford(cost) then
		return
	end
	currentGame:spend(cost)
	self.gate.hp = self.gate.wallType.hp
end

-- ====================================================

function Structure:upgrade()
	--already been vetted in Game, just do internal stuff here
	local upgradeType
	if self.isVillageStruct then
		upgradeType = villageStructureTypes[self.structType.upgrade]
	else
		upgradeType = structureTypes[self.structType.upgrade]
	end
	self.structType = upgradeType
	self.hp = self.structType.hp
end

-- ====================================================

function Structure:onEndDefendPhase()
	self:emptyResourceBank()	
	--woodlot:
	--if self.structType == structureTypes["woodlot"] then
	--	local wood = WOODLOT_TIMBER_PER_WAVE
	--	if self.hp < self.structType.hp then
	--		wood = math.ceil(wood/2)
	--	end
	--	currentGame.timber = currentGame.timber + wood
	--	local anim = AnimFloatingNumber.create("+" .. wood, colors["dark_green"], {tile = self.location, offset = {x = 0, y = 0}})
	--	table.insert(currentGame.animations, anim)
	--quarry:
	--elseif self.structType == structureTypes["quarry"] then
	--	local stone = QUARRY_STONE_PER_WAVE
	--	if self.hp < self.structType.hp then
	--		stone = math.ceil(stone/2)
	--	end
	--	currentGame.stone = currentGame.stone + stone
	--	local anim = AnimFloatingNumber.create("+" .. stone, colors["dark_gray"], {tile = self.location, offset = {x = 0, y = 0}})
	--	table.insert(currentGame.animations, anim)
	--end
	
	--build projects:
	if self.buildProject ~= nil then
		self.buildProject.wavesRemaining = self.buildProject.wavesRemaining - 1
		if self.buildProject.wavesRemaining == 0 then
			currentGame:finishBuildProject(self.buildProject)
		end
	end
end

-- ====================================================

function Structure:getAvailableUpgrades()
	--find all upgrades that haven't been purchased and whose prereqs have been met
	if self.structType.upgrades == nil then
		return {}
	end
	local list = {}
	for key, up in pairs(self.structType.upgrades) do
		local upgrade = upgrades[up]
		if not upgrade.purchased and currentGame:isPrereqMet({prereqs = upgrade.structPrereqs}) and Upgrade.isPrereqMet(upgrade.upgradePrereqs) and not currentGame:isUpgradeRestricted(upgrade) then
			list[up] = upgrade
		end
	end
	return list
end

function Structure:getInProgressUpgrades()
	if self.structType.upgrades == nil then
		return {}
	end
	local list = {}
	for key, up in pairs(self.structType.upgrades) do
		local upgrade = upgrades[up]
		if upgrade.purchased and upgrade.timeRemaining >= 0 and upgrade.structPurchasedAt == self then
			table.insert(list, upgrade)
		end
	end
	return list
end

-- ====================================================

function Structure:countEmployees()
	if self.employeeSlots == nil then
		return 0
	end
	local count = 0
	for key, slot in pairs(self.employeeSlots) do
		if slot.peasant ~= nil then
			count = count + 1
		end
	end
	return count
end

-- ====================================================

function Structure:addEmployee(peasant)
	if self.employeeSlots == nil then
		return false
	end
	for key, slot in pairs(self.employeeSlots) do
		if slot.peasant == nil then
			slot.peasant = peasant
			peasant.employer = self
			if self.structType.production.resourceType == "wheat" and not self.isProducingWheat then
				currentGame:calculateBreadProduction()
			end
			return true
		end
	end
	return false
end

-- ====================================================

function Structure:update(dt)
	--NOTE: only called during defend phase
	--village resource production:
	if self.structType.production ~= nil and not (self.structType.production.resourceType == "wheat" and not self.isProductingWheat) and self.militiaDisbandment == nil and self.buildProject == nil then
		local produced = self.structType.production.rate * dt --* self:countEmployees()
		self.resourcesBanked = self.resourcesBanked + produced
		local threshold = 5
		if self.structType.production.resourceType == "wheat" then
			threshold = 1
		end
		if self.resourcesBanked >= threshold then
			self:cashResources(threshold)
		end
	end
	--peasant production:
	if self.structType.peasanProductionRate ~= nil and #self.peasantResidents < self.structType.maxPopulation then
		--local bread = self.breadIncome / self.structType.maxBread
		--if bread > 1 then
		--	bread = 1
		--end
		local prod = --[[bread *--]] self.structType.peasanProductionRate * dt
		self.newPeasant = self.newPeasant + prod
		if self.newPeasant >= 1 then
			self.newPeasant =self.newPeasant - 1
			--create new peasant:
			if #self.peasantResidents < self.structType.maxPopulation then
				self:createNewPeasant()
			end
		end
	end
	--militia disbanding (NOTE: militia callups are handled by Tower)
	if self.militiaDisbandment ~= nil then
		self.militiaDisbandment.progress = self.militiaDisbandment.progress + dt
		if self.militiaDisbandment.progress >= MILITIA_DISBAND_TIME then
			self.militiaDisbandment = nil
		end
	end
	
	--build projects (UPGRADES ONLY):
	if self.buildProject ~= nil and self.buildProject.structTypeOnCompletion ~= self.structType then
		self.buildProject.age = self.buildProject.age + dt
		if self.buildProject.age >= self.buildProject.structTypeOnCompletion.buildTime then
			currentGame:finishBuildProject(self.buildProject)
		end
	end
end

-- ====================================================

function Structure:createNewPeasant()
	local peasant = Peasant.create(self)
	table.insert(self.peasantResidents, peasant)
	table.insert(currentGame.peasants, peasant)
	currentGame:assignSingleWorker(peasant)
	--floating text
	local anim = AnimFloatingNumber.create("+peasant", colors["black"], {tile = self.location, offset = {x = 0, y = 0}})
	table.insert(currentGame.animations, anim)
end
		
-- ====================================================

function Structure:cashResources(n)
	--give resources from bank to player and show visually
	local color
	if self.structType.production.resourceType == "timber" then
		currentGame.timber = currentGame.timber + n
		color = colors["dark_green"]
	elseif self.structType.production.resourceType == "stone" then
		currentGame.stone = currentGame.stone + n
		color = colors["dark_gray"]
	elseif self.structType.production.resourceType == "wheat" then
		currentGame:addWheat(n)
		color = colors["burleywood"]
	end
	local anim = AnimFloatingNumber.create("+" .. n, color, {tile = self.location, offset = {x = 0, y = 0}})
	table.insert(currentGame.animations, anim)
	self.resourcesBanked = self.resourcesBanked - n
end

-- ====================================================

function Structure:emptyResourceBank()
	if self.resourcesBanked == nil then
		return
	end
	local n = math.floor(self.resourcesBanked)
	if n ~= 0 then
		self:cashResources(n)
	end
	self.resourcesBanked = 0
end

-- ====================================================

function Structure:removeUnlockedEmployee()
	--find and return employee who isn't locked into their slot
	if self.employeeSlots == nil then
		return nil
	end
	local i = #self.employeeSlots
	while i > 0 do
		local slot = self.employeeSlots[i]
		if slot.peasant ~= nil and not slot.locked then
			local temp = slot.peasant
			slot.peasant = nil
			temp.employer = nil
			if self.structType.production.resourceType == "wheat" and not self.isProducingWheat then
				currentGame:calculateBreadProduction()
			end
			return temp
		end
		i = i - 1
	end
	return nil
end

-- ====================================================

function Structure:getCurrentProductionRate()
	return self.structType.production.rate * self:countEmployees()
end

-- ====================================================

function Structure:freeAllEmployees()
	if self.employeeSlots == nil then
		return
	end
	for key, slot in pairs(self.employeeSlots) do
		if slot.peasant ~= nil then
			slot.peasant.employer = nil
			currentGame:assignSingleWorker(slot.peasant)
		end
	end
	if self.structType.production.resourceType == "wheat" and not self.isProducingWheat then
		currentGame:calculateBreadProduction()
	end
end

-- ====================================================

function Structure:countUnemployedResidents()
	if self.peasantResidents == nil then
		return 0
	end
	local total = 0
	for key, p in pairs(self.peasantResidents) do
		if p.employer == nil then
			total = total + 1
		end
	end
	return total
end

-- ====================================================

function Structure:getSlotForEmployee(peasant)
	--return the slot this employee works in
	if self.employeeSlots == nil then
		return nil
	end
	for key, slot in pairs(self.employeeSlots) do
		if slot.peasant == peasant then
			return slot
		end
	end
	return nil
end

-- ====================================================

function Structure:isFinished()
	--is it a ne structure that's build project hasn't finished yet?
	return self.buildProject == nil or self.buildProject.structTypeOnCompletion ~= self.structType
end

-- ====================================================

function Structure:switchFarmProductionType(switchToWheat)
	--switches between wheat and bread
	if self.isProducingWheat == nil then
		print("WARNING: tried to switch wheat/bread at non-farming structure")
		return
	end
	self.isProducingWheat = switchToWheat
	currentGame:calculateBreadProduction()
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Structure:getEmployee()
	if self.employeeSlots == nil then
		return nil
	end
	local idx = #self.employeeSlots
	while idx > 0 do
		if self.employeeSlots[idx].peasant ~= nil then
			return self.employeeSlots[idx].peasant
		end
		idx = idx - 1
	end
	return nil
end

-- ====================================================