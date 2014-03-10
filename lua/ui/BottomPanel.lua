-- highly dynamic ui elt that (predictably) goes below map

BottomPanel = {}
BottomPanel.__index = BottomPanel


function BottomPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, BottomPanel)
	temp.x = x
	temp.y =y 
	temp.width = w
	temp.height = h
	temp.selectionPanel = SelectionPanel.create(x, y, w/2, h)
	temp.controlPanel = nil
	return temp
end

-- ====================================================

function BottomPanel:draw()	
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(3)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	self.selectionPanel:draw()
	if self.controlPanel ~= nil then
		self.controlPanel:draw()
	end
	
	--middle vertical line
	love.graphics.setColor(colors["black"])
	love.graphics.rectangle("fill", self.x + self.width/2 - 1, self.y, 3, self.height)
end

-- ====================================================

function BottomPanel:update(dt)
	if self.controlPanel ~= nil then
		self.controlPanel:update(dt)
	end
end

-- ====================================================

function BottomPanel:mousepressed(x, y, button)
	if self.controlPanel ~= nil then
		self.controlPanel:mousepressed(x, y, button)
	end
end

function BottomPanel:mousereleased(x, y, button)
	--nothing
end

-- ====================================================

function BottomPanel:initControlPanel()
	--if ui.selectedTile == nil and ui.selectedTower == nil then
	--	self.controlPanel = nil
	--else
	self.controlPanel = ControlPanel.create(self.x + self.width/2, self.y, self.width/2, self.height, self)
	--end
end

-- ====================================================

function BottomPanel:catchEvent(event)
	if event == "endBuildPhase" or event == "endDefendPhase" or event == "resetControlPanel" or event == "changeSelection" then
		self:initControlPanel()
	end
	
	self.selectionPanel:catchEvent(event)
end

-- ====================================================
-- ====================================================
-- ====================================================
-- UI elt that displays info about selected tile

SelectionPanel = {}
SelectionPanel.__index = SelectionPanel


function SelectionPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, SelectionPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	--temp.wheatWidget = ProjectedWheatWidget.create(x + 70, y + h - 38, 140)
	return temp
end

-- ====================================================

function SelectionPanel:draw()
	--if ui.selectedTile == nil and ui.selectedTower == nil then
	--	return
	--end
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font14"])
	local y = self.y + 30
	--TILE STUFF
	if ui.selectedTile ~= nil then
		love.graphics.print("(" .. ui.selectedTile.x .. ", " .. ui.selectedTile.y .. ")   " .. ui.selectedTile.terrainType.name, self.x + 10, self.y + 10)
		--structure:
		if ui.selectedTile.structure ~= nil then
			love.graphics.print(ui.selectedTile.structure.structType.name .. "  (" .. math.ceil(ui.selectedTile.structure.hp) .. " / " .. ui.selectedTile.structure.structType.hp .. ")", self.x + 20, y)
			y = y + 15
			if ui.selectedTile.structure.gate ~= nil and ui.selectedTile.structure.gate:isBroken() then
				love.graphics.print("GATE HAS BEEN BROKEN!", self.x + 20, y)
				y = y + 15
			end
			if ui.selectedTile.structure.spell ~= nil then
				love.graphics.print("Spell:  " .. ui.selectedTile.structure.spell.spellType.name, self.x + 20, y)
				y = y + 15
			end
			if ui.selectedTile.structure.regiment ~= nil then
				love.graphics.print("Home to a regiment of " .. ui.selectedTile.structure.regiment.regimentType.name .. " (size " .. ui.selectedTile.structure.regiment.maxUnits .. ")", self.x + 20, y)
				y = y + 15
			end
			if ui.selectedTile.structure.structType.wheatStorage ~= nil then
				love.graphics.print("Wheat storage space:  " .. ui.selectedTile.structure.structType.wheatStorage, self.x + 20, y)
				y = y + 15
			end
			--peasant population stuff
			if ui.selectedTile.structure.peasantResidents ~= nil then
				love.graphics.print("Peasant Population:  " .. #ui.selectedTile.structure.peasantResidents .. " / " .. ui.selectedTile.structure.structType.maxPopulation, self.x + 20, y)
				love.graphics.print("Unemployed peasants:  " .. ui.selectedTile.structure:countUnemployedResidents() .. " (" .. #currentGame.unemployed .. " total)", self.x + 20, y + 15)
				y = y + 30
				--bread stuff:
				love.graphics.print("Bread Income:  " .. ui.selectedTile.structure.breadIncome .. " (" .. math.floor(100 * ui.selectedTile.structure.breadIncome/ui.selectedTile.structure.structType.maxBread) .. "%)", self.x + 20, y)
				y = y + 15
				love.graphics.print("New Peasant:", self.x + 20, y)
				self:drawPeasantProgressBar(self.x + 120, y + 4, ui.selectedTile.structure.newPeasant)
				love.graphics.setColor(colors["black"])
				y = y + 15
			end
			if ui.selectedTile.structure.structType.storageSpace ~= nil then
				love.graphics.print("Storage Space:  " .. ui.selectedTile.structure.structType.storageSpace, self.x + 20, y)
				love.graphics.print("Total:  " .. currentGame:getTotalStorageSpace(), self.x + 30, y + 15)
				y = y + 30
			end
			if ui.selectedTile.structure.structType.shelterSpace ~= nil then
				love.graphics.print("Shelter Space:  " .. ui.selectedTile.structure.structType.shelterSpace, self.x + 20, y)
				love.graphics.print("Total:  " .. currentGame:getTotalShelterSpace(), self.x + 30, y + 15)
				y = y + 30
			end
			if ui.selectedTile.structure.structType.production ~= nil and ui.selectedTile.structure.structType.production.resourceType == "wheat" then
				if ui.selectedTile.structure.isProducingWheat then
					love.graphics.print("Producing:  Wheat", self.x + 20, y)
				else
					love.graphics.print("Producing:  Bread", self.x + 20, y)
				end
				y = y + 15
			end
			--num employees:
			if ui.selectedTile.structure.employeeSlots ~= nil then
				love.graphics.print("Employees:  " .. ui.selectedTile.structure:countEmployees() .. " / " .. #ui.selectedTile.structure.employeeSlots, self.x + 20, y)
				y = y + 15
			end
			--wheat widget:
			if ui.selectedTile.structure.structType.wheatStorage ~= nil or (ui.selectedTile.structure.structType.production ~= nil and ui.selectedTile.structure.structType.production.resourceType == "wheat") then
				--self.wheatWidget:draw()
				love.graphics.setColor(colors["black"]) --gotta reset these b/c wheat widget will change them
				love.graphics.setFont(fonts["font14"])
			end
		end
		--build project
		if ui.selectedTile.buildProject ~= nil and ui.selectedTile.buildProject.projectType == "newStruct" then
			love.graphics.print("BUILDING: " ..  ui.selectedTile.buildProject.structType.name, self.x + 20, y)
			y = y + 15
		end
		--regiment:
		--[[
		if ui.selectedTile.regiment ~= nil then --and (not ui.selectedTile.regiment:isMoving()) then
			love.graphics.print("Regiment of " .. ui.selectedTile.regiment.regimentType.name .. "  (" .. #ui.selectedTile.regiment.units .. "/" .. ui.selectedTile.regiment.maxUnits .. ")", self.x + 20, y + 15)
			y = y + 30
		end
		--]]
	--TOWER STUFF
	elseif ui.selectedTower ~= nil then
		love.graphics.print(ui.selectedTower.towerType.name .. "  (" .. math.ceil(ui.selectedTower.hp) .. " / " .. ui.selectedTower.towerType.hp .. ")", self.x + 20, y)
		y = y + 15
		if ui.selectedTower.traps ~= nil then
			love.graphics.print("Traps:  " .. ui.selectedTower.traps .. " / " .. ui.selectedTower.towerType.numTraps, self.x + 20, y)
			y = y + 15
		end
	--REGIMENT STUFF
	elseif ui.selectedRegiment ~= nil then
		love.graphics.print("Regiment of " .. ui.selectedRegiment.regimentType.name .. "  (" .. #ui.selectedRegiment.units .. "/" .. ui.selectedRegiment.maxUnits .. ")", self.x + 20, y)
		y = y + 15
	end
end

-- ====================================================

function SelectionPanel:drawPeasantProgressBar(x, y, progress)
	local w = 60
	local h = 10
	love.graphics.setColor(colors["burleywood"])
	love.graphics.rectangle("fill", x, y, w * progress, h)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", x, y, w, h)
end

-- ====================================================

function SelectionPanel:catchEvent(event)
	--do nothing
end

-- ====================================================