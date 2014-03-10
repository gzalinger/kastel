--instance of a place and task that needs engineer regiments to work on it

EngineerJob = {}
EngineerJob.__index = EngineerJob


function EngineerJob.create(jobType, location)
	--NOTE: location can be tile OR vertice
	local temp = {}
	setmetatable(temp, EngineerJob)
	temp.jobType = jobType
	temp.location = location
	return temp
end

-- ====================================================

function EngineerJob:getDistanceTo(tile)
	if self.jobType == "build_structure" or self.jobType == "repair_structure" then
		return countSteps(self.location, tile)
	elseif self.jobType == "build_tower" or self.jobType == "repair_tower" then
		local closest = nil
		for key, adj in pairs(self.location.adjacent) do
			local dist = countSteps(adj.tile, tile)
			if closest == nil or dist < closest then
				closest = nil
			end
		end
		return closest
	else
		return nil
	end
end

-- ====================================================

function EngineerJob:isRegimentAt(reg)
	--is the regiment at this job site? 
	if reg:isMoving() then
		return false
	end
	if self.jobType == "build_structure" or self.jobType == "repair_structure" then
		return reg.bannerman.location == self.location:getSubtile(0, 0)
	elseif self.jobType == "build_tower" or self.jobType == "repair_tower" then
		--TODO: UPDATE FOR SUBTILES
		--hax:
		return false
	else
		return nil
	end
end

-- ====================================================

function EngineerJob:doWork(reg, dt)
	--special case: tower workers that need to go to right postions:
	--[[
	if self.jobType == "build_tower" or self.jobType == "repair_tower" then
		--give inital position assignments:
		if reg:getRandomUnit().fightPosition == nil then
			self:assignEngineersToTowerPositions(reg)
			return
		else
			local done = true
			for key, unit in pairs(reg.units) do
				if not unit:updateMove(dt) then
					done = false
				end
			end
			if not done then
				return --units aren't in position yet; don't build yet
			end
		end
	end
	--]]
	
	local numUnits
	if not self:isTower() then
		numUnits = #reg.units
	else
		--count units who are in position
		numUnits = 0
		for key, unit in pairs(reg.units) do
			if unit.locationOffset.x == 0 and unit.locationOffset.y == 0 and unit.location:isAdjacentTo(self.location:getSubtile()) then
				numUnits = numUnits + 1
			end
		end
	end
	
	--have regiment do work at the job
	local work = numUnits * reg.regimentType.workRate * dt
	local finished = false
	
	--build projects:
	if self.jobType == "build_structure" or self.jobType == "build_tower" then
		local buildProject 
		local buildTime
		if self.jobType == "build_structure" then
			buildProject = self.location.structure.buildProject
			buildTime = buildProject.structTypeOnCompletion.buildTime
		elseif self.jobType == "build_tower" then
			buildProject = self.location.tower.buildProject
			buildTime = buildProject.towerTypeOnCompletion.buildTime
		end
				
		buildProject.age = buildProject.age + work
		if buildProject.age >= buildTime then
			--done with project:
			if self.jobType == "build_structure" then
				currentGame:finishBuildProject(buildProject)
			elseif self.jobType == "build_tower" then
				currentGame:finishTowerBuildProject(buildProject)
			end
			finished = true
		end
	--repairing:
	elseif self.jobType == "repair_structure" or self.jobType == "repair_tower" then
		local hp = work * ENGINEER_WORK_TO_REPAIRED_HP
		if self.jobType == "repair_structure" then
			local newHP = hp + self.location.structure.hp
			if newHP >= self.location.structure.structType.hp then
				self.location.structure.hp = self.location.structure.structType.hp
				finished = true
			else
				self.location.structure.hp = newHP
			end
		elseif self.jobType == "repair_tower" then
			local newHP = hp + self.location.tower.hp
			if newHP >= self.location.tower.towerType.hp then
				self.location.tower.hp = self.location.tower.towerType.hp
				finished = true
			else
				self.location.tower.hp = newHP
			end
		end
	end	
		
	if finished then
		--clear positions in case the were working on tower:
		for key, u in pairs(reg.units) do
			u.fightPosition = nil
		end
		
		reg.jobAssignment = currentGame.engineerJobQueue:popFirst()
	end
end

-- ====================================================

function EngineerJob:moveRegimentTowards(reg)
	local tileSet --list of all possible end states for pathfinding
	if self.jobType == "build_structure" or self.jobType == "repair_structure" then
		local dest = self.location:getSubtile(0, 0)
		if reg.bannerman.location.parent == self.location then
			reg:moveWithinTile(dest)
		else
			reg:moveBetweenTiles(dest)
		end
	elseif self.jobType == "build_tower" or self.jobType == "repair_tower" then
		--TODO: UPDATE FOR SUBTILES
		tileSet = {}
		reg:moveToTower(self.location.tower)
	end
	--[[
	local path = IDAStar.findPath(reg.location, tileSet, reg.regimentType.moveType, false)
	if path ~= nil then
		path:popFirst()
	end
	reg:followPath(path) --if path is nil, reg will just freeze for a couple seconds
	--]]
end

-- ====================================================

function EngineerJob:assignEngineersToTowerPositions(reg)
	local orient = reg.location:getOrientationOfVertice(self.location)
	local front = true
	local idx = 1
	for key, unit in pairs(reg.units) do
		if front then
			unit.fightPosition = towerFrontFightPositions[orient][idx]
			if idx == NUM_FORWARD_FIGHT_POSITIONS then
				idx = 1
				front = false
			else
				idx = idx + 1
			end
		else	--rear
			unit.fightPosition = towerRearFightPositions[orient][idx]
			idx = idx + 1
		end
	end
end

-- ====================================================

function EngineerJob:isTower()
	return self.jobType == "build_tower" or self.jobType == "repair_tower" 
end

-- ====================================================