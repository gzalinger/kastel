--object holding everything about a single game/mission

Game = {}
Game.__index = Game


function Game.create(level)
	local temp = {}
	setmetatable(temp, Game)
	temp.level = level
	temp.map = Map.create(level)
	temp:initResources()
	temp.regimentCap = 0
	--temp:initStructures()
	temp.structures = {}
	temp.phase = "defend" --with switch to real time, it's essentially always defend phase
	temp.animations = {}
	temp.buildProjects = {}
	temp.playerRegiments = {}
	temp.hostileRegiments = {}
	temp.fights = {}
	temp.projectiles = {}
	temp.towers = {}
	temp.spells = {}
	temp.storedVillageStructs = {}
	temp.traps = {}
	temp.peasants = {}
	temp.unemployed = {}
	temp.engineerJobQueue = LinkedList.create()
	--temp:setWave(1)
	temp.levelAge = 0
	temp:makeInitialCity(level)
	temp:initPeasantPopulation()
	temp:assignEmployees()
	temp:initTownhallEngineers() --hax that's necessary b/c structures must be made before peasants, but peasants are needed for this regiment
	temp.destroyedWalls = {}
	AttackGenerator.onLevelBegin()
	temp.paused = true
	if level.isTutorial then
		temp.tutorial = Tutorial.create()
	end
	return temp
end

-- ====================================================
--[[
function Game:setWave(id)
	--load new wave (NOTE: this does *not* happen at start of defend phase)
	self.wave = nil
	for key, wave in pairs(self.level.waves) do
		if wave.id == id then
			self.wave = wave
			break
		end
	end
	if self.wave == nil then
		endLevel()
		return	
	end
	
	self.remainingSpawns = {}
	for key, sp in pairs(self.wave.spawns) do
		table.insert(self.remainingSpawns, sp)
	end
end
--]]
-- ====================================================

function Game:update(dt)
	if self.paused then
		return
	end

	self.levelAge = self.levelAge + dt
	self:spawnMonsters()
	for key, sp in pairs(self.spells) do
		sp:update(dt)
	end
	
	--structures:
	for key, s in pairs(self.structures) do
		s:update(dt)
	end

	--towers:
	for key, tower in pairs(self.towers) do
		tower:update(dt)
	end
	--monsters (AI):
	for key, reg in pairs(self.hostileRegiments) do
		if not reg:isMoving() and reg.fight == nil then
			MonsterAI.act(reg, dt)
		end
		--damage structure:
		--[[
		if reg.fight == nil and reg.location.structure ~= nil and reg.location.structure.structType.name ~= "Rubble" then
			self:attackStructure(reg, dt)
		end
		--]]
	end
	--animations:
	for key, anim in pairs(self.animations) do
		if anim:update(dt) then
			table.remove(self.animations, key)
		end
	end
	--fights:
	for key, f in pairs(self.fights) do
		f:update(dt)
	end
	--projectiles:
	for key, proj in pairs(self.projectiles) do
		proj:update(dt)
	end
	--traps:
	for key, trap in pairs(self.traps) do
		trap:update(dt)
	end
	--regiments:
	for key, reg in pairs(self.playerRegiments) do
		reg:update(dt)
	end
	for key, reg in pairs(self.hostileRegiments) do
		reg:update(dt)
	end
	
	ui:update(dt)
	Upgrade.update(dt)
	--procedural monster generation:
	if self.level == levels["sandbox"] then
		AttackGenerator.update(dt)
	end
end

-- ====================================================
--[[
function Game:initStructures()
	self.structures = {}
	--create town hall:
	local townHall = Structure.create(structureTypes["townhall"])
	table.insert(self.structures, townHall)
	local tile = self.map.center
	tile.structure = townHall
	townHall.location = tile
	self.pop = self.pop + townHall.structType.popAdded
	self.regimentCap = self.regimentCap + townHall.structType.regimentCapIncrease
	--set up initial 'edge-of-base' around town hall:
	self.map:updateEdgeOfBase(tile, self)
end
--]]
-- ====================================================

function Game:makeInitialCity(level)
	--create initial structs, walls, and towers specified by the level
	self.cityWallType = wallTypes[level.initialWallType]
	self.wallGapLocation = {tile = self.map.center, trans = self.map.center:getTransitionAtOrientation(level.wallGapOrientation), isFilled = false}
	--town hall:
	self:buildNewStruct(structureTypes["townhall"], self.map.center, true)
	--structures:
	for key, s in pairs(level.initialStructures) do
		self:buildNewStruct(structureTypes[s.structType], self.map:getTile(s.x, s.y), true)
	end
	--village structures:
	for key, vs in pairs(level.initialVillageStructures) do
		self:buildNewVillageStruct(villageStructureTypes[vs.structType], self.map:getTile(vs.x, vs.y), true)
	end
	--walls?
	--towers:
	for key, t in pairs(level.initialTowers) do
		local tile = self.map:getTile(t.x, t.y)
		self:buildNewTower(towerTypes[t.towerType], tile.vertices[t.orientation], true)
	end
end

-- ====================================================

function Game:initResources()
	--create initial values for player's resources
	self.gold = self.level.initialResources.gold
	self.timber = self.level.initialResources.timber
	self.stone = self.level.initialResources.stone
	self.pop = 0
	self.wheat = 0
end

-- ====================================================

function Game:initPeasantPopulation()
	local pop = self.level.initialPeasantPopulation
	--compile list of hamlets:
	local hamlets = {}
	for key, s in pairs(self.structures) do
		if s.peasantResidents ~= nil then
			table.insert(hamlets, s)
		end
	end
	
	--init peasants and place them into hamlets:
	while #hamlets > 0 and pop > 0 do
		for key, h in pairs(hamlets) do
			if pop <= 0 then
				break
			end
			--make sure it has more room:
			if h.structType.maxPopulation == #h.peasantResidents then
				removeFromTable(hamlets, h)
			else
				--make a peasant, add to village:
				local peasant = Peasant.create(h)
				table.insert(h.peasantResidents, peasant)
				table.insert(self.peasants, peasant)
				pop = pop - 1
			end
		end
	end
	--assertion: placed all peasants that we could
	if pop > 0 then
		print("WARNING: could not place all initial peasants")
	end
end

-- ====================================================

function Game:assignEmployees()
	--distributes all employees to work places
	--first, add them all to unemployed list:
	self.unemployed = {}
	for key, p in pairs(self.peasants) do
		p.employer = nil
		table.insert(self.unemployed, p)
	end
	--place unemployed into structures
	local idx = #self.unemployed
	while idx >0 do
		local found = false
		for key, struct in pairs(self.structures) do
			if struct.employeeSlots ~= nil and struct:countEmployees() < struct.structType.employees then
				found = true
				--add worker:
				local p = self.unemployed[idx]
				struct:addEmployee(p)
				self.unemployed[idx] = nil
				idx = idx - 1
				if idx == 0 then
					break
				end
			end
		end
		if not found then
			break
		end
	end
end

-- ====================================================

function Game:endBuildPhase()
	self.levelAge = 0
	self:completeBuildingProjects()
	self.phase = "defend"
	self:spawnFriendlyRegiments()
	self.traps = {}
	for key, tower in pairs(self.towers) do
		tower:onEndBuildPhase()
	end
	
	--hax: create one monster regiment:
	--local tile = self.map:getTile(0, 0) 
	--if tile.regiment == nil then
	--	local reg = Regiment.create(regimentTypes["orcs"])
	--	reg:placeAt(tile)
	--	tile.regiment = reg
	--	table.insert(self.hostileRegiments, reg)
	--end --end hax block
	
	currentPanel:catchEvent("endBuildPhase")
end

-- ====================================================

function Game:completeBuildingProjects()
	for key, proj in pairs(self.buildProjects) do
		if proj.projectType == "newStruct" then
			local struct = Structure.create(proj.structType)
			struct.location = proj.location
			proj.location.structure = struct
			proj.location.buildProject = nil
			table.insert(self.structures, struct)
			if struct.structType.name == "Gatehouse" then
				struct.gate = self:buildNewWall(wallTypes["gate"], proj.orientation, proj.location)
			elseif struct.structType.name == "Barracks" then
				struct.rallyPoint = struct.location
				struct.location.rallyPoint = struct
			end
			--create friendly regiment instances:
			if struct.structType.regimentType ~= nil then
				local reg = Regiment.create(regimentTypes[struct.structType.regimentType], struct)
				struct.regiment = reg
				table.insert(self.playerRegiments, reg)
			end
		end
	end
	self.buildProjects = {}
end

-- ====================================================
--[[
function Game:spawnFriendlyRegiments()
	for key, struct in pairs(self.structures) do
		if struct.regiment ~= nil and struct:isFinished() then
			struct.regiment:placeAt(struct.rallyPoint)
			struct.rallyPoint.regiment = struct.regiment
		end
	end
end
--]]
-- ====================================================

function Game:endDefendPhase()
	self.phase = "build"
	currentPanel:catchEvent("endDefendPhase")
	for key, reg in pairs(self.playerRegiments) do
		if reg.location ~= nil then
			reg.location.regiment = nil
		end
	end
	for key, tower in pairs(self.towers) do
		tower:onEndDefendPhase()
	end
	for key, struct in pairs(self.structures) do
		struct:onEndDefendPhase()
	end
	for key, sp in pairs(self.spells) do
		sp.cooldown = 0
	end
	self:disbandRemainingMilitias()
	Upgrade.onBuildPhaseBegin()
	local prevWave = self.wave
	self:setWave(self.wave.id + 1) 
	self:regeneratePlayerRegiments()
	self:regenerateWallsAndTowers()
	self.projectiles = {}
	--check to see if you're going into winter or summer:
	if self.wave ~= nil then --if it is nil, the level is over
		if not prevWave.isWinter and self.wave.isWinter then
			--AUTUMN
			self.phase = "autumn"
			ui:setMode("autumn")
			ui:selectTile(nil)
			self.autumnTempData = {selectedStructs = {}, goldCost = 0, timberCost = 0, stoneCost = 0, spaceUsed = 0}
			--remove village towers:
			for key, tower in pairs(self.towers) do
				if tower.isVillageTower then
					self:removeTower(tower)
				end
			end
		elseif prevWave.isWinter and not self.wave.isWinter then
			--SPRING
			self.phase = "spring"
			ui:setMode("spring")
			ui:selectTile(nil)
			currentPanel:catchEvent("onSpringBegin")
			--case where there aren't any structs to place:
			if #self.storedVillageStructs == 0 then
				self.phase = "build"
				ui:setMode("default")
				currentPanel:catchEvent("onSpringEnd")
				local popup = Popup.create("noSpringPhase", {})
				ui:setPopup(popup)
			end
		end
	end
end

-- ====================================================

function Game:regeneratePlayerRegiments()
	--after defend phase, all player units regain health and regiments get back some units
	for key, reg in pairs(self.playerRegiments) do
		reg:regenerate()
	end
end

-- ====================================================

function Game:regenerateWallsAndTowers()
	--heal all walls
	for key, trans in pairs(self.map.transitions) do
		if trans.wall ~= nil and trans.wall.hp > 0 then
			trans.wall.hp = trans.wall.wallType.hp
		end
	end
	for key, tower in pairs(self.towers) do
		tower.hp = tower.towerType.hp
	end
end

-- ====================================================

function Game:canAfford(purchase)
	return self.gold >= purchase.goldCost and self.timber >= purchase.timberCost and self.stone >= purchase.stoneCost and (purchase.popCost == nil or purchase.popCost <= self.pop) and (purchase.peasantPopCost == nil or purchase.peasantPopCost <= #self.unemployed)
end

-- ====================================================

function Game:spend(purchase)
	self.gold = self.gold - purchase.goldCost
	self.timber = self.timber - purchase.timberCost
	self.stone = self.stone - purchase.stoneCost
	if purchase.popCost ~= nil then
		self.pop = self.pop - purchase.popCost
	end
end

-- ====================================================

function Game:refund(purchase)
	self.gold = self.gold + purchase.goldCost
	self.timber = self.timber + purchase.timberCost
	self.stone = self.stone + purchase.stoneCost
	if purchase.popCost ~= nil then
		self.pop = self.pop + purchase.popCost
	end
end

-- ====================================================

function Game:buildNewStruct(structType, tile, isFree)
	--for building over village structs:
	if isFree == nil then
		isFree = false
	end
	if structType == structureTypes["gatehouse"] then
		self:buildGatehouse(tile, isFree)
		return
	end
	
	if (tile.structure ~= nil and not tile.structure.isVillageStruct) then
		ui:addTextMessage("There's already a structure there")
		return
	elseif tile.terrainType ~= terrainTypes["plains"] then
		ui:addTextMessage("Strucutres must be placed on Plains")
		return
	elseif tile:isBorder() then
		ui:addTextMessage("Structures cannot be placed along the edge of the map")
		return
	elseif tile.isSpawnPoint then
		ui:addTextMessage("Strucutres cannot be placed on spawn points")
		return
	elseif ((not tile:isEdgeOfBase()) and (not (structType == structureTypes["townhall"]))) then
		ui:addTextMessage("City structures must be adjacent to other city structures")
		return
	 elseif not self:isPrereqMet(structType) then
	 	ui:addTextMessage("Prereqs haven't been met")
	 	return
	 elseif self:isStructureRestricted(structType) then
		ui:addTextMessage("That structure type isn't allowed on this level")
		return
	end
	--make sure tile does not border a gate:
	for key, trans in pairs(tile.transitions) do
		if trans.wall ~= nil and trans.wall.wallType == wallTypes["gate"] then
			ui:addTextMessage("Structures cannot be placed across from gates")
			return
		end
	end
	--check regiment cap:
	if structType.regimentType ~= nil and self:getRegimentCapSpaceUsed() + regimentTypes[structType.regimentType].capSpace > self.regimentCap then
		ui:addTextMessage("Regiment cap is full")
		return
	end
	
	--building over village structs
	if tableContains(structureTypes, structType) and tile.structure ~= nil and tile.structure.isVillageStruct then
		ui:setPopup(Popup.create("BuildOverVillageStruct", {villageStruct = tile.structure, newStructType = structType}))
		return
	end
	
	if not isFree then
		self:spend(structType)
	end
	local struct = Structure.create(structType)
	struct.location = tile
	tile.structure = struct
	table.insert(self.structures, struct)
	self.map:updateEdgeOfBase(tile, self)
	
	--create friendly regiment instances:
	if structType.regimentType ~= nil and structType ~= structureTypes["townhall"] then
		local reg = Regiment.create(regimentTypes[structType.regimentType], struct, structType.regimentSize)
		struct.regiment = reg
		table.insert(self.playerRegiments, reg)
		--associate with peasants (engineers only):
		if reg:isEngineer() then
			for key, unit in pairs(reg.units) do
				local peasant = self.unemployed[#self.unemployed]
				unit.militiaPeasant = peasant
				peasant.employer = struct
				removeFromTable(self.unemployed, peasant)
			end
		end
	end	
	
	--instantiate build project:
	if not struct.isVillageStruct then 
		local buildProject = {structure= struct, structTypeOnCompletion = structType, age = 0}
		if structType.buildTime == 0 or isFree then -- using 'free' flag to exempt initial structures is a bit of hax
			self:finishBuildProject(buildProject)
		else
			struct.buildProject = buildProject
			--add to job queue:
			self:addEngineerJob(EngineerJob.create("build_structure", tile))
		end
	end
end

-- ====================================================

function Game:buildGatehouse(tile, isFree)
	--such a special case, it gets it's own function
	local structType = structureTypes["gatehouse"]
	--MAKE SURE TILE IS VALID:
	--special build conditions for gatehouse:
	if (tile.structure ~= nil and not tile.structure.isVillageStruct) then
		ui:addTextMessage("There's already a structure there")
		return
	 elseif (tile.terrainType.name ~= "Plains" and tile.terrainType.name ~= "Road") then
	 	ui:addTextMessage("Gatehouses must be placed on Plains or Road")
	 	return
	 elseif tile.isSpawnPoint then
	 	ui:addTextMessage("Gatehouses can't be placed on spawn points")
	 	return
	 elseif tile:isBorder() then
	 	ui:addTextMessage("Gatehouses cannot be placed along the edge of the map")
	 	return
	 elseif not tile:hasAdjacentStructure() then
	 	ui:addTextMessage("Gatehouses must be adjacent to other city structures")
	 	return
	 elseif not self:canAfford(structType) then
	 	ui:addTextMessage("You can't afford that")
	 	return
	elseif self:isStructureRestricted(structType) then
		ui:addTextMessage("That structure type isn't allowed on this level")
		return
	end
	--make sure no adjacent structs are also gatehouses:
	for key, adj in pairs(tile:getAdjacent()) do
		if adj.structure ~= nil and adj.structure.structType == structType then
			ui:addTextMessage("Gatehouses can't be adjacent to other gatehouses")
			return
		end
	end
	--conditions for gate itself
	local trans = tile:getTransitionAtOrientation(ui.selectionOrientation)
	if trans.wall ~= nil or trans:getDest(tile).structure ~= nil then
		ui:addTextMessage("Invalid gate position")
		return
	end
	for key, vert in pairs(trans:getVertices()) do
		if vert.tower ~= nil then
			ui:addTextMessage("No room for gatehouse towers")
			return
		end
	end
	
	if tile.structure ~= nil and tile.structure.isVillageStruct then
		ui:setPopup(Popup.create("BuildOverVillageStruct", {villageStruct = tile.structure, newStructType = structType}))
		return
	end
	
	if not isFree then
		self:spend(structType)
	end
	local struct = Structure.create(structType)
	struct.location = tile
	tile.structure = struct
	table.insert(self.structures, struct)
	
	--delete wall that might be in way of gate:
	--[[local gateTrans = tile:getTransitionAtOrientation(ui.selectionOrientation)
	if gateTrans.wall ~= nil then
		self:removeWall(gateTrans.wall)
	end--]]
	local gate = self:buildNewWall(wallTypes["gate"], ui.selectionOrientation, tile)
	gate.isOpen = true
	struct.gate = gate
	
	self.map:updateEdgeOfBase(tile, self)
	
	struct.towers = {}
	for key, vert in pairs(gate.location:getVertices()) do
		local tower = self:buildNewTower(towerTypes["gatetower"], vert, true)
		table.insert(struct.towers, tower)
	end
	
	--instantiate build project:
	if not free then -- using 'free' flag to exempt initial structures is a bit of hax
		local buildProject = {structure= struct, structTypeOnCompletion = structType, age = 0}
		if structType.buildTime == 0 then
			self:finishBuildProject(buildProject)
		else
			struct.buildProject = buildProject
			--add to job queue:
			self:addEngineerJob(EngineerJob.create("build_structure", tile))
		end
	end
end

-- ====================================================

function Game:buildNewVillageStruct(vstructType, tile, isFree)
	if isFree == nil then
		isFree = false
	end
	if tile.structure ~= nil then
		ui:addTextMessage("Village structures can't be built over other structures")
		return false
	elseif tile.terrainType.name ~= "Plains" then
		ui:addTextMessage("Village structures must be built on Plains")
		return false
	elseif tile:isBorder() then
		ui:addTextMessage("Village structures can't be built along the edge of the map")
		return false
	elseif tile.isSpawnPoint then
		ui:addTextMessage("Village structures can't be built over spawn points")
		return false
	elseif not tile:hasAdjacentStructure() then
		ui:addTextMessage("Village strucutres must be built next to other structures")
		return false
	elseif not self:isPrereqMet(vstructType) then
		ui:addTextMessage("Prereqs haven't been met")
		return false
	elseif self:isVillageStructureRestricted(vstructType) then
		ui:addTextMessage("That village structure type isn't allowed on this level")
		return false
	elseif (not isFree and not self:canAfford(vstructType)) then
		ui:addTextMessage("You can't afford that")
		return false
	end
	--make sure tile does not border a gate:
	for key, trans in pairs(tile.transitions) do
		if trans.wall ~= nil and trans.wall.wallType == wallTypes["gate"] then
			ui:addTextMessage("Village structures can't be built next to gates")
			return false
		end
	end
	--make sure farms are adjacent to hamlets:
	if vstructType.production ~= nil and vstructType.production.resourceType == "wheat" then
		local foundHamlet = false
		for key, adj in pairs(tile:getAdjacent()) do
			if adj.structure ~= nil and adj.structure.structType.maxPopulation ~= nil then
				foundHamlet = true
				break
			end
		end
		if not foundHamlet then
			ui:addTextMessage("Farms must be built adjacent to hamlets")
			return false
		end
	end
	--make sure there are enough workers:
	if vstructType.employees ~= nil and vstructType.employees > #self.unemployed then
		ui:addTextMessage("Not enough unemployed peasants")
		return false
	end
	
	local vstruct = Structure.create(vstructType)
	vstruct.location = tile
	tile.structure = vstruct
	table.insert(self.structures, vstruct)
	if not isFree then
		self:spend(vstructType)
	end

	--if able and applicable, fill with unemployed peasants:
	if vstruct.employeeSlots ~= nil and self.unemployed ~= nil then
		local n = 0
		while n < vstructType.employees and #self.unemployed > 0 do
			vstruct:addEmployee(self.unemployed[#self.unemployed])
			self.unemployed[#self.unemployed] = nil
			n = n + 1
		end
	end

	--update bread production (if applicable):
	if vstruct.peasantResidents ~= nil or (vstructType.production ~= nil and vstructType.resourceType == "wheat" and not vstruct.isProducingWheat) then
		self:calculateBreadProduction()
	end
	
	--instantiate build project: 
	local buildProject = {structure= vstruct, structTypeOnCompletion = vstructType, age = 0}
	if vstructType.buildTime == 0 or isFree then -- using 'free' flag to exempt initial structures is a bit of hax
		self:finishBuildProject(buildProject)
	else
		vstruct.buildProject = buildProject
		--add to job queue:
		self:addEngineerJob(EngineerJob.create("build_structure", tile))
	end
	
	return true
end

-- ====================================================

function Game:buildNewWall(wallType, orient, tile, isFree)
	if isFree == nil then isFree = false end
	local trans = tile:getTransitionAtOrientation(orient)
	if trans == nil or trans.wall ~= nil or trans:isBorder() --[[or (not trans.isEdgeOfBase)--]] then
		return
	end
	if trans == self.wallGapLocation.trans and not self.wallGapLocation.isFilled then
		return
	end
	--make sure it's not adjacent to road (unless it's a gate):
	if wallType ~= wallTypes["gate"] and (trans.a.terrainType == terrainTypes["road"] or trans.b.terrainType == terrainTypes["road"]) then
		return
	end
	
	local wall = Wall.create(wallType, trans)
	trans.wall = wall
	--if not isFree then
	--	self:spend(wallType)
	--end
	return wall --special case used for gatehouses
end

-- ====================================================

function Game:cancelBuildProject(tile)
	removeFromTable(self.buildProjects, tile.buildProject)
	self:refund(tile.buildProject.structType)
	tile.buildProject = nil
end

-- ====================================================
--[[
function Game:movePlayerRegiment(reg, dest)
	--check to make sure it's valid:
	if self.phase ~= "defend" or (not reg:isFriendly()) or reg.fight ~= nil then --or dest.regiment ~= nil
		return
	end

	local path = IDAStar.findPath(reg.location, {dest}, reg.regimentType.moveType, false)
	if path ~= nil then
		path:popFirst() -- this one is the tile they're already at
	end
	reg:followPath(path)
end
--]]
-- ====================================================

function Game:movePlayerRegiment(reg, subtile)
	if not reg:isFriendly() or reg:isEngineer() or reg.fight ~= nil then
		return
	end
	if subtile.parent == reg.bannerman.location.parent then
		reg:moveWithinTile(subtile)
	else
		reg:moveBetweenTiles(subtile)
	end
end

-- ====================================================

function Game:moveRegiment(reg, dest)
	--an atomic move between one tile and another; not the same as issuing order to move across map	that will require pathfinding
	if self.phase ~= "defend" or dest.regiment ~= nil or reg:isMoving() or reg.fight ~= nil then
		return false
	end
	local trans = reg.location:getTransitionTo(dest)
	if not trans:isPassable() then
		return false
	end
	
	local oldLocation = reg.location
	reg.location.regiment = nil
	dest.regiment = reg
	reg.location = dest
	reg:doMoveAnimation(oldLocation)
	if reg:isFriendly() and ui.selectedTile == oldLocation then
		ui:selectTile(dest)
	end
	--traps:
	if not reg:isFriendly() then
		Trap.trigger(reg, oldLocation, dest)
	end
	--cancel militia callups:
	if dest.structure ~= nil and dest.structure.militiaCallup ~= nil then
		dest.structure.militiaCallup.tower:cancelMilitiaCallup()
	end
	return true
end

-- ====================================================

function Game:initMelee(attacker, defender)
	if defender == nil or (not attacker.location:isAdjacent(defender.location)) or attacker:isFriendly() == defender:isFriendly() or attacker:isMoving() then
		return false
	end
	
	local trans = attacker.location:getTransitionTo(defender.location)
	--make sure trans isn't a wall that they can't fight through:
	if not trans:isPassable() then
		return false
	end
	--interrupt wallfights:
	for key, f in pairs(attacker.fights) do
		if f:isAgainstWall() then
			f:endFight(false)
		end
	end
	for key, f in pairs(defender.fights) do
		if f:isAgainstWall() then
			f:endFight(false)
		end
	end	
	--if attacker.fight ~= nil and attacker.fight:isAgainstWall() then
	--	removeFromTable(self.fights, attacker.fight)
	--elseif defender.fight ~= nil and defender.fight:isAgainstWall() then
	--	removeFromTable(self.fights, defender.fight)
	--end
	
	local fight = Fight.create(attacker, defender, trans)
	table.insert(self.fights, fight)
	attacker:enterFight(fight)
	defender:enterFight(fight)
	return true
end

-- ====================================================

function Game:initWallAttack(reg, wall)
	if reg:isFriendly() or reg:isMoving() or reg.fight ~= nil or wall.isOpen or (wall.location.a ~= reg.location and wall.location.b ~= reg.location) then
		return
	end
	local fight = Fight.create(reg, nil, wall.location)
	table.insert(self.fights, fight)
	reg:enterFight(fight)
end

-- ====================================================

function Game:initTowerAttack(reg, tower)
	if reg:isFriendly() or reg:isMoving() or reg.fight ~= nil or --[[(trans.a ~= reg.location and trans.b ~= reg.location) or--]] tower.towerType == towerTypes["gatetower"] then
		return
	end
	local fight = Fight.create(reg, nil, nil, tower)
	table.insert(self.fights, fight)
	reg:enterFight(fight)
	tower:enterFight(fight)
end

-- ====================================================

function Game:removeRegiment(reg)
	if not reg:isFriendly() then
		removeFromTable(self.hostileRegiments, reg)
		--[[
		if #self.hostileRegiments == 0 and #self.remainingSpawns == 0 then
			local a = AnimEndDefendPhase.create()
			table.insert(self.animations, a)
			--wave's gold bonus:
			self.gold = self.gold + self.wave.goldBonus
			local anim = AnimFloatingNumber.create("+" .. self.wave.goldBonus, colors["gold"], {tile = self.map.center, offset = {x = 0, y = 0}})
			table.insert(self.animations, anim)
		end
		--]]
	end
end

-- ====================================================

function Game:resurrectRegiment(reg)
	if (not reg:isDead()) or (not self:canAfford(reg.regimentType)) then
		return
	end
	reg:resurrect()
	self:spend(reg.regimentType)
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Game:attackStructure(regiment, dt)
	--this hostile reg is at a structure; do damage to it
	if regiment:isMurdering() and regiment.location.structure:countEmployees() > 0 then
		self:doMurderAttack(regiment, dt)
		return
	end
	local dmg = 0
	for key, u in pairs(regiment.units) do
		if regiment.moveAnim == nil or u:updateMove(0) then
			dmg = dmg + regiment.regimentType.dps * dt
		end
	end
	regiment.location.structure:takeDamage(dmg, regiment.regimentType.damageType)
end

-- ====================================================

function Game:doMurderAttack(regiment, dt)
	local totalDPS = 0
	for key, u in pairs(regiment.units) do
		if regiment.moveAnim == nil or u:updateMove(0) then
			totalDPS = totalDPS + regiment.regimentType.murderDPS
		end
	end
	if totalDPS == 0 then
		return
	end
	
	if regiment.murderAttack == nil then
		regiment.murderAttack = {progress = 0.0}
	end
	regiment.murderAttack.progress = regiment.murderAttack.progress + dt * totalDPS
	
	if regiment.murderAttack.progress > 1 then
		regiment.murderAttack.progress = regiment.murderAttack.progress - 1
		local victim = regiment.location.structure:getEmployee()
		local victimSlot = victim.employer:getSlotForEmployee(victim)
		victim:kill()
		victimSlot.open = false
		local anim = AnimFloatingNumber.create("-1 peasant", colors["red"], {tile = regiment.location, offset = {x = 0, y = 0}})
		table.insert(self.animations, anim)
		if regiment.location.structure:countEmployees() == 0 then
			regiment.murderAttack = nil
		end
	end
end

-- ====================================================

function Game:removeStructure(struct)
	removeFromTable(self.structures, struct)
	struct.location.structure = nil
	struct:freeAllEmployees()
	if struct.peasantResidents ~= nil and self.phase ~= "autumn" then
		self:redistributeResidents(struct.peasantResidents, struct)
	end
	--remove population:
	if struct.structType.popAdded ~= nil then
		self.pop = self.pop - struct.structType.popAdded
	end
	if struct.structType.regimentCapIncrease ~= nil then
		self.regimentCap = self.regimentCap - struct.structType.regimentCapIncrease
	end
	--remove spell:
	if struct.spell ~= nil then
		removeFromTable(self.spells, struct.spell)
		currentPanel:catchEvent("resetSpellPanel")
	end
	--granaries:
	if struct.structType.wheatStorage ~= nil then
		self:addWheat(0) --this will remove any above the new storage limit
	end
	--check if it was town hall:
	if struct.structType == structureTypes["townhall"] or struct.structType == structureTypes["manor"] then
		endGame()
	elseif struct.structType == structureTypes["gatehouse"] then
		self:onGatehouseRemoved(struct)
	end
	--cancel in-progress upgrades:
	for key, up in pairs(struct:getInProgressUpgrades()) do
		Upgrade.cancel(up)
	end
	--update bread production (if applicable)
	if struct.peasantResidents ~= nil or (struct.structType.production ~= nil and struct.structType.production.resourceType == "wheat" and not struct.isProducingWheat) then
		self:calculateBreadProduction()
	end
	--cancel militia callups:
	if struct.militiaCallup ~= nil then
		struct.militiaCallup.tower:cancelMilitiaCallup()
	end
	
	--add rubble:
	if not struct.isVillageStruct then
		local rubble = Structure.create(structureTypes["rubble"])
		struct.location.structure = rubble
		table.insert(self.structures, rubble)
	end
end

-- ====================================================

function Game:onGatehouseRemoved(struct)
	--remove towers and wall
	for key, tower in pairs(struct.towers) do
		self:removeTower(tower)
	end
	--see if gate was in any fights:
	for key, f in pairs(self.fights) do
		if f:isAgainstWall() and f.transition == struct.gate.location then
			f:endFight(true)
		end
	end
	self:removeWall(struct.gate)
end

-- ====================================================
--[[
function Game:repairStructure(struct)
	local percent = 1 - struct.hp/struct.structType.hp
	local cost = {goldCost = round(struct.structType.goldCost*percent*0.75), timberCost = round(struct.structType.timberCost*percent*0.75), stoneCost = round(struct.structType.stoneCost*percent*0.75)}
	if not self:canAfford(cost) then
		return
	end
	self:spend(cost)
	struct.hp = struct.structType.hp
	currentPanel:catchEvent("resetControlPanel")
end
--]]
-- ====================================================

function Game:repairStructure(struct)
	--i.e. create and engineer job for it
	self:addEngineerJob(EngineerJob.create("repair_structure", struct.location))
end

-- ====================================================

function Game:repairTower(tower)
	self:addEngineerJob(EngineerJob.create("repair_tower", tower.location))
end

-- ====================================================

function Game:removeWall(wall)
	wall.location.wall = nil
end

-- ====================================================

function Game:addProjectile(proj)
	table.insert(self.projectiles, proj)
end

function Game:removeProjectile(proj)
	removeFromTable(self.projectiles, proj)
end

-- ====================================================

function Game:spawnMonsters()
	--spawn new monsters from current wave if applicable
	--[[
	for key, spawn in pairs(self.remainingSpawns) do
		if spawn.delay <= self.levelAge then
			--actually do spawn:
			local reg = Regiment.create(regimentTypes[spawn.unitType], nil, spawn.numUnits)
			self:doSpawn(reg, self.level.spawnPoints[spawn.spawnPoint])
			removeFromTable(self.remainingSpawns, spawn)
		end
	end
	--]]
	
	--todo: spawn using new, real-time system
end

-- ====================================================

function Game:doSpawn(reg, point)
	local tile = self.map:getTile(point.x, point.y)	
	--check for case where spawn is blocked:
	if tile.regiment ~= nil then
		for key, t in pairs(tile:getAdjacent()) do
			if t.regiment == nil and t.terrainType.passable then
				tile = t
				break
			end
		end
	end
	
	reg:placeAt(tile)
	--tile.regiment = reg
	table.insert(self.hostileRegiments, reg)
end

-- ====================================================

function Game:buildNewTower(towerType, vertice, isFree)
	if isFree == nil then isFree = false end
	if vertice.tower ~= nil then
		ui:addTextMessage("There's already a tower there")
		return nil
	elseif (not self:canAfford(towerType) and not isFree) then
		ui:addTextMessage("You can't afford that")
		return nil
	elseif not vertice.isEdgeOfBase then
		ui:addTextMessage("Towers can't be built along the edge of the map")
		return nil
	elseif not self:isPrereqMet(towerType) then
		ui:addTextMessage("Prereqs haven't been met")
		return nil
	elseif self:isTowerRestricted(towerType) then
		ui:addTextMessage("That tower type isn't allowed on this level")
		return nil
	end
	local tower = Tower.create(towerType, vertice)
	vertice.tower = tower
	table.insert(self.towers, tower)
	if not isFree then
		self:spend(towerType)
	end
	
	--build project:
	local buildProject = {tower = tower, towerTypeOnCompletion = towerType, age = 0}
	if isFree or towerType.buildTime == 0 then
		self:finishTowerBuildProject(buildProject)
	else
		tower.buildProject = buildProject
		self:addEngineerJob(EngineerJob.create("build_tower", vertice))
	end
	
	return tower
end

-- ====================================================

function Game:buildNewVillageTower(vtowerType, vertice)
	if vertice.tower ~= nil or (not self:canAfford(vtowerType)) or (not self:isPrereqMet(vtowerType)) or (self:isVillageTowerRestricted(vtowerType)) then
		return
	end
	--vertice must not be edge-of-base and must border at least one village structure
	if vertice.isEdgeOfBase then
		return
	end
	local borders = false
	for key, adj in pairs(vertice.adjacent) do
		if adj.tile.structure ~= nil and adj.tile.structure.isVillageStruct then
			borders = true
			break
		end
	end
	if not borders then
		return
	end
	
	self:spend(vtowerType)
	local tower = Tower.create(vtowerType, vertice)
	vertice.tower = tower
	table.insert(self.towers, tower)
	
	local buildProject = {tower = tower, towerTypeOnCompletion = vtowerType, age = 0}
	if vtowerType.buildTime == 0 then
		self:finishTowerBuildProject(buildProject)
	else
		tower.buildProject = buildProject
		self:addEngineerJob(EngineerJob.create("build_tower", vertice))
	end
end

-- ====================================================

function Game:removeTower(tower)
	tower.location.tower = nil
	removeFromTable(self.towers, tower)
	--cancel militia callups:
	if tower.militiaCallup ~= nil then
		tower:cancelMilitiaCallup()
	end
end

-- ====================================================

function Game:giveRecycleCost(purchase, animTile)
	--if 'animTile' is not nil, make some floating nubmers there
	local anims = {}
	local n = round(purchase.goldCost * RECYCLE_RATE)
	self.gold = self.gold + n
	if animTile ~= nil and n > 0 then
		table.insert(anims, AnimFloatingNumber.create("+" .. n, colors["gold"], {tile = animTile, offset = {x = 0, y = 0}}))
	end
	
	n = round(purchase.timberCost * RECYCLE_RATE)
	self.timber = self.timber + n
	if animTile ~= nil and n > 0 then
		table.insert(anims, AnimFloatingNumber.create("+" .. n, colors["dark_green"], {tile = animTile, offset = {x = 0, y = -0.5*#anims}}))
	end
	
	n = round(purchase.stoneCost * RECYCLE_RATE)
	self.stone = self.stone + n
	if animTile ~= nil and n > 0 then
		table.insert(anims, AnimFloatingNumber.create("+" .. n, colors["dark_gray"], {tile = animTile, offset = {x = 0, y = -0.5*#anims}}))
	end
	
	for key, a in pairs(anims) do
		table.insert(self.animations, a)
	end
end

-- ====================================================
--[[
function Game:isSpawnPointActive(tile)
	--i.e. will this tile spawn units next wave
	for key, spawn in pairs(self.wave.spawns) do
		if tile:equals(self.level.spawnPoints[spawn.spawnPoint]) then
			return true
		end
	end
	return false
end
--]]
-- ====================================================

function Game:upgradeStructure(struct)
	--NOTE: this is the player buying an upgrade, the upgrade actually finishing is separate
	if struct.hp < struct.structType.hp then
		ui:addTextMessage("Damaged structures can't be upgraded")
		return
	elseif struct.structType.upgrade == nil then
		ui:addTextMessage("This structure is at it's max level")
		return
	end
	local upgradeType 
	if struct.isVillageStruct then
		upgradeType = villageStructureTypes[struct.structType.upgrade]
	else
		upgradeType = structureTypes[struct.structType.upgrade]
	end
	if upgradeType == nil or (not self:canAfford(upgradeType)) then
		ui:addTextMessage("You can't afford that")
		return
	end
	
	self:spend(upgradeType)
	--instantiate build project (unless it's instant):
	local buildProject = {structure = struct, structTypeOnCompletion = upgradeType, age = 0}
	if struct.isVillageStruct or upgradeType.buildTime == 0 then
		self:finishBuildProject(buildProject)
	else
		struct.buildProject = buildProject
	end
	
	--update bread production (if applicable)
	if struct.structType.production ~= nil and struct.structType.production.resourceType == "wheat" and not struct.isProductingWheat then
		self:calculateBreadProduction()
	end
	
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Game:finishBuildProject(buildProject)
	--new structures finishing:
	if buildProject.structTypeOnCompletion == buildProject.structure.structType then
		--rally point
		if buildProject.structure.structType == structureTypes["barracks"] then
			buildProject.structure.rallyPoint = buildProject.structure.location
			buildProject.structure.location.rallyPoint = buildProject.structure
		end
		--add city pop:
		if buildProject.structure.structType.popAdded ~= nil then
			self.pop = self.pop + buildProject.structure.structType.popAdded
		end
		--regiment cap:
		if buildProject.structure.structType.regimentCapIncrease ~= nil then
			self.regimentCap = self.regimentCap + buildProject.structure.structType.regimentCapIncrease
		end	
		--spells:
		if buildProject.structure.spell ~= nil then
			table.insert(self.spells, buildProject.structure.spell)
			currentPanel:catchEvent("resetSpellPanel")
		end
		--close gate:
		if buildProject.structure.structType == structureTypes["gatehouse"] then
			buildProject.structure.gate.isOpen = false
		end
		
		--if able and applicable, fill with unemployed peasants:
		--[[
		if buildProject.structure.employeeSlots ~= nil and self.unemployed ~= nil then
			local n = 0
			while n < buildProject.structure.structType.employees and #self.unemployed > 0 do
				buildProject.structure:addEmployee(self.unemployed[#self.unemployed])
				self.unemployed[#self.unemployed] = nil
				n = n + 1
			end
		end
		--]]
		--place regiment:
		--[[
		if buildProject.structure.regiment ~= nil then
			buildProject.structure.regiment:placeAt(buildProject.structure.location)
			buildProject.structure.location.regiment = buildProject.structure.regiment
		end
		--]]
	
	--UPGRADE FINISHING:
	else
		if buildProject.structTypeOnCompletion.popAdded ~= nil then
			self.pop = self.pop + buildProject.structTypeOnCompletion.popAdded
		end
		if buildProject.structTypeOnCompletion.regimentCapIncrease ~= nil then
			self.regimentCap = self.regimentCap + buildProject.structTypeOnCompletion.regimentCapIncrease
		end
		--upgrading regiment:
		if buildProject.structure.regiment ~= nil then
			local reg = buildProject.structure.regiment
			if reg.regimentType ~= buildProject.structTypeOnCompletion.regimentType then
				--todo: upgrade reg to new type
			end
			if buildProject.structTypeOnCompletion.regimentSize ~= nil then
				reg:increaseMaxUnits(buildProject.structTypeOnCompletion.regimentSize - reg.maxUnits)
			end
		end
		
		buildProject.structure:upgrade()
	end
	
	buildProject.structure.buildProject = nil
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Game:finishTowerBuildProject(buildProject)
	--new structure finishing:
	if buildProject.towerTypeOnCompletion == buildProject.tower.towerType then
		--do nothing?
	--upgrading:
	else
		buildProject.tower:upgrade()
	end
	buildProject.tower.buildProject = nil
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Game:upgradeTower(tower)
	if tower.hp < tower.towerType.hp then
		ui:addTextMessage("Damaged towers can't be upgraded")
		return
	elseif tower.towerType.upgrade == nil then
		ui:addTextMessage("That tower is at it's max level")
		return
	end
	local upgradeType = towerTypes[tower.towerType.upgrade]
	if not self:canAfford(upgradeType) then
		ui:addTextMessage("You can't afford that")
		return
	elseif not self:isPrereqMet(upgradeType) then
		ui:addTextMessage("Prereqs haven't been met")
		return
	end
	self:spend(upgradeType)
	--tower:upgrade()
	
	--build project:
	local buildProject = {tower = tower, towerTypeOnCompletion = upgradeType, age = 0}
	if tower.towerType.upgrade.buildTime == 0 then
		self:finishTowerBuildProject(buildProject)
	else
		tower.buildProject = buildProject
	end
	
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Game:isPrereqMet(structType)
	--NOTE: structType can be a tower type as well
	if structType.prereqs == nil then
		return true
	end
	for key, p in pairs(structType.prereqs) do
		local prereq = structureTypes[p]
		local found = false
		for key, s in pairs(self.structures) do
			if s.structType == prereq and (s.buildProject == nil or s.buildProject.structTypeOnCompletion ~= s.structType) then
				found = true
			end
		end
		if not found then
			return false
		end
	end
	return true
end

-- ====================================================

function Game:giveKillReward(unit)
	--give player reward for killing a bad guy
	self.gold = self.gold + unit.regimentType.goldReward
	local loc = {tile = unit.location.parent, offset = {x = (unit.location.x + unit.locationOffset.x)*MapSubtile.X_OFFSET_PER_SUBTILE, y = (unit.location.y + unit.locationOffset.y) * MapSubtile.Y_OFFSET_PER_SUBTILE}}
	local anim = AnimFloatingNumber.create("+" .. unit.regimentType.goldReward, colors["gold"], loc)
	table.insert(self.animations, anim)
end

-- ====================================================

function Game:buyTimber()
	local goldCost = BUY_TIMBER_AMOUNT * TIMBER_BUY_COST
	if self.gold < goldCost then
		return
	end
	self.gold = self.gold - goldCost
	self.timber = self.timber + BUY_TIMBER_AMOUNT
	local anim = AnimFloatingNumber.create("+" .. BUY_TIMBER_AMOUNT, colors["dark_green"], {tile = self.map.center, offset = {x = 0, y = 0}})
	table.insert(self.animations, anim)
	anim = AnimFloatingNumber.create("-" .. goldCost, colors["gold"], {tile = self.map.center, offset = {x = 0, y = -0.3}})
	table.insert(self.animations, anim)
end

function Game:sellTimber()
	if self.timber < SELL_TIMBER_AMOUNT then
		return
	end
	local profit = SELL_TIMBER_AMOUNT * TIMBER_SELL_RATE
	self.timber = self.timber - SELL_TIMBER_AMOUNT
	self.gold = self.gold + profit
	local anim = AnimFloatingNumber.create("-" .. SELL_TIMBER_AMOUNT, colors["dark_green"], {tile = self.map.center, offset = {x = 0, y = -0.3}})
	table.insert(self.animations, anim)
	anim = AnimFloatingNumber.create("+" .. profit, colors["gold"], {tile = self.map.center, offset = {x = 0, y = 0}})
	table.insert(self.animations, anim)
end

function Game:buyStone()
	local goldCost = BUY_STONE_AMOUNT * STONE_BUY_COST
	if self.gold < goldCost then
		return
	end
	self.gold = self.gold - goldCost
	self.stone = self.stone + BUY_STONE_AMOUNT
	local anim = AnimFloatingNumber.create("+" .. BUY_STONE_AMOUNT, colors["dark_gray"], {tile = self.map.center, offset = {x = 0, y = 0}})
	table.insert(self.animations, anim)
	anim = AnimFloatingNumber.create("-" .. goldCost, colors["gold"], {tile = self.map.center, offset = {x = 0, y = -0.3}})
	table.insert(self.animations, anim)
end

function Game:sellStone()
	if self.stone < SELL_STONE_AMOUNT then
		return
	end
	local profit = SELL_STONE_AMOUNT * STONE_SELL_RATE
	self.stone = self.stone - SELL_STONE_AMOUNT
	self.gold = self.gold + profit
	local anim = AnimFloatingNumber.create("-" .. SELL_STONE_AMOUNT, colors["dark_gray"], {tile = self.map.center, offset = {x = 0, y = -0.3}})
	table.insert(self.animations, anim)
	anim = AnimFloatingNumber.create("+" .. profit, colors["gold"], {tile = self.map.center, offset = {x = 0, y = 0}})
	table.insert(self.animations, anim)
end

-- ====================================================

function Game:isStructureRestricted(structType)
	--i.e. does level not allow this to be built yet
	for key, restrict in pairs(self.level.restrictions.structures) do
		if structureTypes[restrict] == structType then
			return true
		end
	end
	return false
end

function Game:isVillageStructureRestricted(vstructType)
	for key, restrict in pairs(self.level.restrictions.villageStructs) do
		if villageStructureTypes[restrict] == vstructType then
			return true
		end
	end
	return false
end

function Game:isTowerRestricted(towerType)
	for key, restrict in pairs(self.level.restrictions.towers) do
		if towerTypes[restrict] == towerType then
			return true
		end
	end
	return false
end

function Game:isVillageTowerRestricted(towerType)
	for key, restrict in pairs(self.level.restrictions.villageTowers) do
		if villageTowerTypes[restrict] == towerType then
			return true
		end
	end
	return false
end

function Game:isUpgradeRestricted(upgrade)
	for key, restrict in pairs(self.level.restrictions.upgrades) do
		if upgrades[restrict] == upgrade then
			return true
		end
	end
	return false
end

-- ====================================================

function Game:assignSingleWorker(peasant)
	--assigns newly created or freed peasant to a structure
	peasant.employer = nil
	for key, s in pairs(self.structures) do
		if s:addEmployee(peasant) then
			return
		end
	end	
	--no struct would take him:
	table.insert(self.unemployed, peasant)
end

-- ====================================================

function Game:fillEmployeeSlot(slot, forceFill, struct)
	--if 'forceFill', then pull from filled slots
	--'struct' is where they're going to work
	if #self.unemployed > 0 then
		slot.peasant = self.unemployed[#self.unemployed]
		self.unemployed[#self.unemployed] = nil
		slot.peasant.employer = struct
		if struct.structType.production ~= nil and struct.structType.production.resourceType == "wheat" and not struct.isProductingWheat then
			self:calculateBreadProduction()
		end
		return
	end
	--forcefill:
	if forceFill then
		--take employee from first possible struct
		for key, s in pairs(self.structures) do
			if s ~= struct then
				local peasant = s:removeUnlockedEmployee()
				if peasant ~= nil then
					slot.peasant = peasant
					peasant.employer = struct
					return
				end
			end
		end
	end
end

-- ====================================================

function Game:getTotalWheatStorage()
	local total = 0
	for key, s in pairs(self.structures) do
		if s.structType.wheatStorage ~= nil and s:isFinished() then
			total = total + s.structType.wheatStorage
		end
	end
	return total
end

-- ====================================================

function Game:addWheat(n)
	local storage = self:getTotalWheatStorage()
	self.wheat = math.min(storage, self.wheat + n)
end

-- ====================================================
--[[
function Game:getProjectedWheatProduction()
	--calculate how much wheat will probably in inventory at end of wave
	--NOTE: assumes level will end immediately after last spawn, which is not entirely true
	local remainingTime = getLastSpawn(self.wave).delay - self.levelAge
	local prodRate = 0 --per second
	for key, s in pairs(self.structures) do
		if s.structType.production ~= nil and s.structType.production.resourceType == "wheat" and s.isProducingWheat then
			 prodRate = prodRate + s:getCurrentProductionRate()
		end
	end
	return math.min(self.wheat + prodRate * remainingTime, self:getTotalWheatStorage())
end
--]]
-- ====================================================

function Game:endAutumn()
	self.map:clearAllHighlights()
	--store selected structures:
	self.storedVillageStructs = {}
	for key, selected in pairs(self.autumnTempData.selectedStructs) do
		table.insert(self.storedVillageStructs, selected.structType)
	end
	--remove all village structs:
	local villageStructs = {}
	--compile list first, then remove all (to avoid 'concurrent modification' issues)
	for key, s in pairs(self.structures) do
		if s.isVillageStruct then
			table.insert(villageStructs, s)
		end
	end
	for key, s in pairs(villageStructs) do
		self:removeStructure(s)
	end
	
	--cull peasants depending on shelter space and wheat:
	local popupData = {wheat = self.wheat, peasantsLost = 0}
	local totalShelter = self:getTotalShelterSpace()
	popupData.shelter = totalShelter
	popupData.startingPeasants = #self.peasants
	local max = math.min(self.wheat, totalShelter)
	if #self.peasants > max then
		local toCull = #self.peasants - max
		popupData.peasantsLost = toCull
		local start = #self.peasants
		for i = 1, toCull do
			self.peasants[start - i + 1] = nil
		end
	end
	local popup = Popup.create("PeasantShelterResults", popupData)
	ui:setPopup(popup)
	
	self.phase = "build"
	ui:setMode("default")
end

-- ====================================================

function Game:getTotalStorageSpace()
	local total = 0
	for key, s in pairs(self.structures) do
		if s.structType.storageSpace ~= nil and s:isFinished() then
			total = total + s.structType.storageSpace
		end
	end
	return total
end

-- ====================================================

function Game:getTotalShelterSpace()
	local total = 0
	for key, s in pairs(self.structures) do
		if s.structType.shelterSpace ~= nil and s:isFinished() then
			total = total + s.structType.shelterSpace
		end
	end
	return total
end

-- ====================================================

function Game:selectTileForAutumn(tile)
	--attempt to select structure for storage (done during 'autumn' phase)
	if tile == nil or tile.structure == nil or not tile.structure.isVillageStruct or tile.structure.structType.storageCost == nil then
		return
	end
	--if already selected, then deselect it:
	if tableContains(self.autumnTempData.selectedStructs, tile.structure) then
		removeFromTable(self.autumnTempData.selectedStructs, tile.structure)
		self.autumnTempData.goldCost = self.autumnTempData.goldCost - tile.structure.structType.storageCost.gold
		self.autumnTempData.timberCost = self.autumnTempData.timberCost - tile.structure.structType.storageCost.timber
		self.autumnTempData.stoneCost = self.autumnTempData.stoneCost - tile.structure.structType.storageCost.stone
		self.autumnTempData.spaceUsed = self.autumnTempData.spaceUsed - tile.structure.structType.storageCost.space
		tile.isHighlighted = false
	else
		--try to select this struct:
		local newGoldCost = self.autumnTempData.goldCost + tile.structure.structType.storageCost.gold
		local newTimberCost = self.autumnTempData.timberCost + tile.structure.structType.storageCost.timber
		local newStoneCost = self.autumnTempData.stoneCost + tile.structure.structType.storageCost.stone
		local newSpaceUsed = self.autumnTempData.spaceUsed + tile.structure.structType.storageCost.space
		if newGoldCost > self.gold or newTimberCost > self.timber or newStoneCost > self.stone or newSpaceUsed > self:getTotalStorageSpace() then
			return
		end
		--successfully select it:
		table.insert(self.autumnTempData.selectedStructs, tile.structure)
		self.autumnTempData.goldCost = newGoldCost
		self.autumnTempData.TimberCost = newTimberCost
		self.autumnTempData.stoneCost = newStoneCost
		self.autumnTempData.spaceUsed = newSpaceUsed
		tile.isHighlighted = true
	end
end

-- ====================================================

function Game:buildOverVillageStruct(villageStruct, structType, relocate)
	--replace village struct and give refund or relocate struct
	--make sure they can afford relocating:
	if relocate then
		if self.gold < RELOCATION_GOLD_COST or self.timber < RELOCATION_TIMBER_COST then
			return false
		end
	end
	local tile = villageStruct.location
	tile.structure = nil
	self:buildNewStruct(structType, tile)
	if relocate then
		ui:setMode("relocateVillageStruct")
		ui.selectionData = villageStruct
		ui:selectTile(nil)
	else
		self:removeStructure(villageStruct)
		self:giveRecycleCost(villageStruct.structType, tile)
		villageStruct:freeAllEmployees()
	end
	return true
end

-- ====================================================

function Game:relocateVillageStructTo(struct, tile)
	--places already-instantiated structure at required location:
	if tile.structure ~= nil or tile.terrainType.name ~= "Plains" or tile:isBorder() or tile.isSpawnPoint or (not tile:hasAdjacentStructure()) then
		return false
	end
	--make sure tile does not border a gate:
	for key, trans in pairs(tile.transitions) do
		if trans.wall ~= nil and trans.wall.wallType == wallTypes["gate"] then
			return false
		end
	end
	--make sure farms are adjacent to hamlets:
	if struct.structType.production ~= nil and struct.structType.production.resourceType == "wheat" then
		local foundHamlet = false
		for key, adj in pairs(tile:getAdjacent()) do
			if adj.structure ~= nil and adj.structure.structType.maxPopulation ~= nil then
				foundHamlet = true
				break
			end
		end
		if not foundHamlet then
			return false
		end
	end
	--NOTE: above code was copied from 'buildNewVillageStruct'
	 
	tile.structure = struct
	struct.location = tile
	ui:setMode("default")
	--charge relocation fee:
	self.gold = self.gold - RELOCATION_GOLD_COST
	self.timber = self.timber - RELOCATION_TIMBER_COST
	table.insert(self.animations, AnimFloatingNumber.create("-" .. RELOCATION_GOLD_COST, colors["gold"], {tile = tile, offset = {x = 0, y = 0}}))
	table.insert(self.animations, AnimFloatingNumber.create("-" .. RELOCATION_GOLD_COST, colors["dark_green"], {tile = tile, offset = {x = 0, y = -0.25}}))
end

-- ====================================================

function Game:reconstituteVillageStruct(structType, tile)
	--take it out of storage and rebuild
	if not self:buildNewVillageStruct(structType, tile, true) then
		--placing struct was not successful
		return
	end
	removeFromTable(self.storedVillageStructs, structType)
	currentPanel:catchEvent("resetSpringBuildPanel")
	--check to see if spring is done:
	if #self.storedVillageStructs == 0 then
		self.phase = "build"
		ui:setMode("default")
		currentPanel:catchEvent("onSpringEnd")
	else
		ui:setMode("spring")
	end
end

-- ====================================================

function Game:redistributeResidents(residents, homeStruct)
	--take peasants living at destroyed hamlet and send to other hamlets
	--DON'T let them go back to 'homeStruct'
	local idx = #residents
	for key, s in pairs(self.structures) do
		if s.peasantResidents ~= nil and s ~= homeStruct then
			--add as many peasants as possible to this hamlet:
			while #s.peasantResidents < s.structType.maxPopulation do
				s.peasantResidents[#s.peasantResidents + 1] = residents[idx]
				idx = idx - 1
				if idx == 0 then
					return
				end
			end
		end
	end
	--if this point has been reached, not all residents could be found a home
	while idx > 0 do
		local peasant = residents[idx]
		removeFromTable(self.peasants, peasant)
		if peasant.employer ~= nil then
			local slot = peasant.employer:getSlotForEmployee(peasant)
			slot.peasant = nil
			self:fillEmployeeSlot(slot, false, peasant.employer)
			peasant.employer = nil
		end
		idx = idx - 1
	end
end

-- ====================================================

function Game:calculateBreadProduction()
	--determine how much bread is getting produced at each hamlet
	--first, clear bread income at each hamlet:
	for key, s in pairs(self.structures) do
		if s.peasantResidents ~= nil then
			s.breadIncome = 0
		end
	end
	--look for farms:
	for key, farm in pairs(self.structures) do
		if farm.structType.production ~= nil and farm.structType.production.resourceType == "wheat" and not farm.isProducingWheat then
			--this actually is a farm
			local production = farm:getCurrentProductionRate()
			local hamlets = {}
			--find all adjacent hamlets:
			for key, adj in pairs(farm.location:getAdjacent()) do
				if adj.structure ~= nil and adj.structure.peasantResidents ~= nil then
					table.insert(hamlets, adj.structure)
				end
			end
			--distribute this farm's bread between hamlets:
			for key, ham in pairs(hamlets) do
				ham.breadIncome = ham.breadIncome + production/#hamlets
			end
		end
	end
end

-- ====================================================

function Game:callupMilitia(tile, tower)
	--start process to call up militia regiment at tile, initiated by HQ at tower
	local callup = {homeStructure = tile.structure, tower = tower, progress = 0, peasants= {}}
	--close all employee slots and add peasants to callup object:
	for key, slot in pairs(tile.structure.employeeSlots) do
		if slot.peasant ~= nil then
			table.insert(callup.peasants, slot.peasant)
			slot.peasant.employer = nil
			slot.peasant = nil
		end
		slot.open = false
	end
	tower.militiaCallup = callup
	tile.structure.militiaCallup = callup
	
	ui:setMode("default")
end

-- ====================================================

function Game:instantiateMilitiaRegiment(structure, tower)
	--finish calling up militia at structure, called originally from tower
	local reg = Regiment.create(regimentTypes["militia"], structure, #tower.militiaCallup.peasants)
	reg.isMilitia = true
	table.insert(self.playerRegiments, reg)
	reg:placeAt(structure.location)
	--structure.location.regiment = reg
	--associate peasants with units:
	local idx = 1
	for key, unit in pairs(reg.units) do
		unit.militiaPeasant = tower.militiaCallup.peasants[idx]
		idx = idx + 1
	end
	structure.militiaCallup = nil
	tower.militiaCallup = nil
	structure.militiaRegiment = reg
	if ui.selectedTile == structure.location then
		currentPanel:catchEvent("resetControlPanel")
	end
end

-- ====================================================

function Game:disbandMilitia(regiment, isEndOfPhase)
	--if 'endOfPhase', ignore all robustness conditions:
	if not isEndOfPhase and (not regiment.isMilitia or regiment:isMoving() or regiment.fight ~= nil or regiment.location.structure ~= regiment.homeStructure) then
		return
	end
	removeFromTable(self.playerRegiments, regiment)
	regiment.location.regiment = nil
	regiment.homeStructure.militiaRegiment = nil
	--return peasants to employee slots:
	local idx = 1
	for key, peasant in pairs(regiment.units) do
		local slot = regiment.homeStructure.employeeSlots[idx]
		slot.open = true
		slot.peasant = peasant
		idx = idx + 1
	end
	local disbandment = {structure = regiment.homeStructure, progress = 0}
	regiment.homeStructure.militiaDisbandment = disbandment
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Game:disbandRemainingMilitias()
	--called at end of defend phase, instantly disband all surviving militia regiments and finish any ongoing disbandments/callups
	for key, reg in pairs(self.playerRegiments) do
		if reg.isMilitia then
			self:disbandMilitia(reg, true)
		end
	end
	for key, struct in pairs(self.structures) do
		if struct.militiaDisbandment ~= nil then
			struct.militiaDisbandment = nil
		end
		if struct.militiaCallup ~= nil then
			struct.militiaCallup.tower:cancelMilitiaCallup()
		end
	end
end

-- ====================================================

function Game:rebuildDestroyedWalls()
	local cost = {}
	cost.goldCost = #self.destroyedWalls * self.cityWallType.goldCost
	cost.timberCost = #self.destroyedWalls * self.cityWallType.timberCost
	cost.stoneCost = #self.destroyedWalls * self.cityWallType.stoneCost
	if not self:canAfford(cost) then
		return
	end
	self:spend(cost)
	for key, wall in pairs(self.destroyedWalls) do
		wall.hp = wall.wallType.hp
	end
	self.destroyedWalls = {}
end

-- ====================================================

function Game:isNight()
	local timeToday = self.levelAge % (self.level.dayDuration + self.level.nightDuration)
	return timeToday > self.level.dayDuration
end

-- ====================================================

function Game:getDay()
	--'number' of current day within current level
	return math.ceil(self.levelAge / (self.level.dayDuration + self.level.nightDuration))
end

-- ====================================================

function Game:getTimeToday()
	--time within current day
	return self.levelAge % (self.level.dayDuration + self.level.nightDuration)
end

-- ====================================================

function Game:getRegimentCapSpaceUsed()
	local total = 0
	for key, reg in pairs(self.playerRegiments) do
		total = total + reg.regimentType.capSpace
	end
	return total
end

-- ====================================================

function Game:initTownhallEngineers()
	--total HAX to make town hall's regiment of engineers
	local structType = structureTypes["townhall"]
	local struct = self.map.center.structure
	
	local reg = Regiment.create(regimentTypes[structType.regimentType], struct, structType.regimentSize)
	struct.regiment = reg
	table.insert(self.playerRegiments, reg)
	--associate with peasants:
	for key, unit in pairs(reg.units) do
		local peasant = self.peasants[#self.unemployed]
		unit.militiaPeasant = peasant
		peasant.employer = struct
		removeFromTable(self.unemployed, peasant)
	end	
	--don't place on map b/c engineers aren't deployed by default
end
	
-- ====================================================

function Game:addEngineerJob(job)
	--look for free engineers, otherwise add to queue	
	local closest = nil
	local dist = -1
	for key, reg in pairs(self.playerRegiments) do
		if reg.regimentType == regimentTypes["engineer"] and reg.jobAssignment == nil and reg.homeStructure:isFinished() then
			--engineers found:
			local d
			if reg.location == nil then
				d = job:getDistanceTo(reg.homeStructure.location)
			else
				d = job:getDistanceTo(reg.location)
			end
			if closest == nil or d < dist then
				closest = reg
				dist = d
			end
		end
	end
	if closest ~= nil then
		closest.jobAssignment = job
		if not closest:isDeployed() then
			closest:placeAt(closest.homeStructure.location)
		else
			closest:halt() --in case they were on their way home
		end
		return
	end
	
	--there weren't any engineers available:
	self.engineerJobQueue:add(job)
end

-- ====================================================

function Game:moveEngineerJobForTower(oldLoc, newLoc)
	--tower has moved; find engineer job for it and move that too
	--first, search queue:
	for key, job in pairs(self.engineerJobQueue:values()) do
		if job.location == oldLoc then
			job.location = newLoc
		end
	end
	--search engineer regiments:
	for key, reg in pairs(self.playerRegiments) do
		if reg.jobAssignment ~= nil and reg.jobAssignment.location == oldLoc then
			reg.jobAssignment.location = newLoc
		end
	end
end

-- ====================================================

function Game:translateFormation(regiment, direction)
	--try to translate entire formation in direction by one subtile
	--first, copy old locations in case they're not allowed to move (also, clear current location)	
	local oldLocs = {}
	for key, unit in pairs(regiment.units) do
		table.insert(oldLocs, {unit = unit, loc = unit.location})
		unit.location.unit = nil
	end
	
	local failed = false
	--move units:
	for key, unit in pairs(regiment.units) do
		local dest = unit.location:getRelativeSubtile(direction)
		local trans = unit.location.parent:getTransitionTo(dest.parent) --used for checking for walls
		local vert = dest:getVertice()
		if dest.unit ~= nil or not dest.parent.terrainType.passable or (trans ~= nil and trans.wall ~= nil and not trans.wall:isPassable()) or (vert ~= nil and vert.tower ~= nil) then
			failed = true
			break
		else
			unit.location = dest
			dest.unit = unit
			unit.locationOffset = {x = -direction.x * MapSubtile.X_OFFSET_PER_SUBTILE, y = -direction.y * MapSubtile.Y_OFFSET_PER_SUBTILE}
		end
	end
	
	if failed then
		--revert to old locations
		for key, old in pairs(oldLocs) do	
			old.unit.location = old.loc
			old.loc.unit = old.unit
			old.unit.locationOffset = {x = 0, y = 0}
		end
	else
		--successful, do anim
		local anim = AnimMoveRegiment.create(regiment)
		regiment.moveManager.moveAnim = anim
		--table.insert(self.animations, anim)
	end
	
	return not failed
end

-- ====================================================

function Game:moveUnitTo(unit, dest)
	--move single unit independent of regiment
	if dest.unit ~= nil or not unit.location:isAdjacentTo(dest) or not dest.parent.terrainType.passable then
		return false
	end
	--check for moving through wall:
	if unit.location.parent ~= dest.parent and not unit.location.parent:getTransitionTo(dest.parent):isPassable() then
		return false
	end
	--check for tower:
	local vert = dest:getVertice()
	if vert ~= nil and vert.tower ~= nil then
		return false
	end
	
	--successful move
	local dist = unit.location:distanceTo(dest)
	unit.location.unit = nil
	dest.unit = unit
	unit.location = dest
	unit.locationOffset = {x = -dist.x * MapSubtile.X_OFFSET_PER_SUBTILE, y = -dist.y * MapSubtile.Y_OFFSET_PER_SUBTILE}
	return true
end

-- ====================================================