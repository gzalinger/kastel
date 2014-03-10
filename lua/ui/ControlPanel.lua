-- UI elt that holds controls for structures (e.g. upgrade buttons)

ControlPanel = {}
ControlPanel.__index = ControlPanel


function ControlPanel.create(x, y, w, h, parent)
	--this panel is (for it's whole lifespan) associated with the given tile
	local temp = {}
	setmetatable(temp, ControlPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.parent = parent
	temp.buttons = {}
	temp.messages = {}
	if ui.selectedTile ~= nil then
		temp:initWithTile(ui.selectedTile)
	elseif ui.selectedTower ~= nil then
		temp:initWithTower(ui.selectedTower)
	elseif ui.selectedRegiment ~= nil then
		temp:initWithRegiment(ui.selectedRegiment)
	end
	--set 'y' of each button:
	local buttonY = y + 10
	for key, b in pairs(temp.buttons) do
		b.y = buttonY
		buttonY = buttonY + 30
	end
	return temp
end

-- ====================================================

function ControlPanel:initWithTile(tile)
	--create all buttons, etc for controlling whatever's on this tile
	self.tile = tile
	if tile.structure ~= nil then
		--ALL damaged structures:
		if tile.structure.hp < tile.structure.structType.hp then
			self.buttons["repair"] = TextButton.create("Repair", self.x + 10, 0, "font14")
		--STRUCTS WITH BUILD PROJECTS
		elseif tile.structure.buildProject ~= nil then
			if tile.structure.buildProject.structTypeOnCompletion == tile.structure.structType then
				table.insert(self.messages, "Under construction...")
			else
				table.insert(self.messages, "Upgrading...")
			end
		else --UNDAMAGED (i.e. normal) STRUCTURE CONTROLS
			--upgrade:
			if tile.structure.structType.upgrade ~= nil then
				local upgrade 
				local txt
				if tile.structure.isVillageStruct then
					upgrade = villageStructureTypes[tile.structure.structType.upgrade]
					txt = "Upgrade (" .. upgrade.goldCost .. "/" .. upgrade.timberCost .. "/" .. upgrade.stoneCost .. ")"
				else
					upgrade = structureTypes[tile.structure.structType.upgrade]						txt = "Upgrade (" .. upgrade.goldCost .. "/" .. upgrade.timberCost .. "/" .. upgrade.stoneCost .. "/" ..upgrade.popCost .. ")"
				end
				self.buttons["upgrade"] = TextButton.create(txt, self.x + 10, 0, "font14")
			end
			--barracks (etc:
			if tile.structure.regiment ~= nil and not tile.structure.regiment:isEngineer() then
				--self.buttons["changeRally"] = TextButton.create("Set Rally Point", self.x + 10, self.y + y + 15, "font14")
				--y = y + 35
				if tile.structure.regiment:isDead() then
					self.buttons["resurrectRegiment"] = TextButton.create("Resurrect", self.x + 10, 0, "font14")
				elseif not tile.structure.regiment:isDeployed() then
					self.buttons["deployRegiment"] = TextButton.create("Deploy Regiment", self.x + 10, 0, "font14")
				end
			--gatehouse
			elseif tile.structure.structType == structureTypes["gatehouse"] then
				if tile.structure.gate.hp <= 0 then
					self.buttons["repairGate"] = TextButton.create("Repair Gate", self.x + 10, 0, "font14")
				end
			--warehouse
			elseif tile.structure.structType == structureTypes["warehouse"] then
				if currentGame.wave.isWinter then
					self.buttons["viewWarehouse"] = TextButton.create("View Stored Structures", self.x + 10, 0, "font14")
				end
			--farm
			elseif tile.structure.structType.production ~= nil and tile.structure.structType.production.resourceType == "wheat" then
				if tile.structure.isProducingWheat then
					self.buttons["switchToBread"] = TextButton.create("Switch to Bread", self.x + 10, 0, "font14")
				else
					self.buttons["switchToWheat"] = TextButton.create("Switch to Wheat", self.x + 10, 0, "font14")
				end
			end
			--upgrades
			for key, up in pairs(tile.structure:getAvailableUpgrades()) do
				self.buttons[key] = TextButton.create(up.name, self.x + 10, 0, "font14")
			end
			--in-progress upgrades:
			--[[
			for key, up in pairs(tile.structure:getInProgressUpgrades()) do
				table.insert(self.messages, "Upgrading...")
			end
			--]]
		end
	--new structs:
	--elseif tile.buildProject ~= nil and tile.buildProject.projectType == "newStruct" then
	--	self.buttons["cancelNewStruct"] = TextButton.create("Cancel", self.x + 10, self.y + y + 15, "font14")
	end
	--regiment controls:
	if tile.regiment ~= nil and tile.regiment:isFriendly() and not tile.regiment:isEngineer() then
		self.buttons["move"] = TextButton.create("Move", self.x + 10, 0, "font14")
		self.buttons["attack"] = TextButton.create("Attack", self.x + 10, 0, "font14")
		if tile.regiment.isMilitia then
			self.buttons["goHome"] = TextButton.create("Go Home", self.x + 10, 0, "font14")
			self.buttons["disbandMilitia"] = TextButton.create("Disband", self.x + 115, 0, "font14")
		else
			self.buttons["restRegiment"] = TextButton.create("Rest Regiment", self.x + 10, 0, "font14")
		end
	end
	--gate controls:
	if tile.structure ~= nil and tile.structure.gate ~= nil and tile.structure:isFinished() then
		if tile.structure.gate.isOpen or (tile.structure.gate.gateAnim ~= nil and tile.structure.gate.gateAnim.isOpening) then
			self.buttons["closeGate"] = TextButton.create("Close Gate", self.x + 10, 0, "font14")
		else
			self.buttons["openGate"] = TextButton.create("Open Gate", self.x + 10, 0, "font14")
		end
	--farm production
	elseif tile.structure ~= nil and tile.structure.structType.production ~= nil and tile.structure.structType.production.resourceType == "wheat" then
		if tile.structure.isProducingWheat then
			self.buttons["switchToBread"] = TextButton.create("Switch to Bread", self.x + 10, 0, "font14")
		else
			self.buttons["switchToWheat"] = TextButton.create("Switch to Wheat", self.x + 10, 0, "font14")
		end
	end
	--employee control panel:
	--[[
	if tile.structure~= nil and tile.structure.employeeSlots ~= nil then
		self.employeeControlPanel = EmployeeControlPanel.create(tile.structure, self.x, self.y + self.height- 80, self.width, 70)
	end
	--]]
end

-- ====================================================

function ControlPanel:initWithTower(tower)
	--create all buttons, etc for controlling this tower
	self.tower = tower
	--damaged:
	if tower.hp < tower.towerType.hp then
		self.buttons["repairTower"] = TextButton.create("Repair", self.x + 10, 0, "font14")
	--undamaged:
	else
		if tower.buildProject == nil and tower.towerType.upgrade ~= nil and currentGame:isPrereqMet(towerTypes[tower.towerType.upgrade]) then
			self.buttons["upgradeTower"] = TextButton.create("Upgrade", self.x + 10, 0, "font14")
		end
		if tower.towerType == villageTowerTypes["militiaHQ"] and tower.buildProject == nil then
			self.buttons["callupMilitia"] = TextButton.create("Callup Militia", self.x + 10, 0, "font14")
		end
		if tower.buildProject ~= nil then
			table.insert(self.messages, "Building...")
		end
	end
end

-- ====================================================

function ControlPanel:initWithRegiment(regiment)
	self.regiment = regiment
	if regiment:isFriendly() and not regiment:isEngineer() then
		self.buttons["move"] = TextButton.create("Move", self.x + 10, 0, "font14")
		self.buttons["attack"] = TextButton.create("Attack", self.x + 10, 0, "font14")
		self.buttons["halt"] = TextButton.create("Halt", self.x + 10, 0, "font14")
		if regiment.isMilitia then
			self.buttons["goHome"] = TextButton.create("Go Home", self.x + 10, 0, "font14")
			self.buttons["disbandMilitia"] = TextButton.create("Disband", self.x + 115, 0, "font14")
		else
			self.buttons["restRegiment"] = TextButton.create("Rest Regiment", self.x + 10, 0, "font14")
		end
	end
end

-- ====================================================

function ControlPanel:update(dt)
	for key, b in pairs(self.buttons) do
		b:update(dt)
	end
	if self.employeeControlPanel ~= nil then
		self.employeeControlPanel:update(dt)
	end
end

-- ====================================================

function ControlPanel:draw()
	local maxY = self.y - 30
	for key, b in pairs(self.buttons) do
		b:draw()
		if b.y > maxY then
			maxY = b.y
		end
	end
	if self.employeeControlPanel ~= nil then
		self.employeeControlPanel:draw()
	end
	--messages:
	local msgY = maxY + 40
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font12"])
	for key, msg in pairs(self.messages) do
		love.graphics.print(msg, self.x + 10, msgY)
		msgY = msgY + 20
	end
	
	--progress bar:
	if (self.tile ~= nil and self.tile.structure ~= nil and self.tile.structure.militiaCallup ~= nil) or (self.tower ~= nil and self.tower.militiaCallup ~= nil) then
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font12"])
		love.graphics.print("Militia Callup:", self.x + self.width - 110, self.y + 15)
		local callup
		if self.tile ~= nil then
			callup = self.tile.structure.militiaCallup
		else
			callup = self.tower.militiaCallup
		end
		local barWidth = 90
		local barHeight = 8
		love.graphics.setColor(colors["blue"])
		love.graphics.rectangle("fill", self.x + self.width - 110, self.y + 30, barWidth * (callup.progress / MILITIA_CALLUP_TIME), barHeight)
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", self.x + self.width - 110, self.y + 30, barWidth, barHeight)
	elseif self.tile ~= nil and self.tile.structure ~= nil and self.tile.structure.militiaDisbandment ~= nil then
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font12"])
		love.graphics.print("Militia Disbanding:", self.x + self.width - 120, self.y + 15)
		local callup = self.tile.structure.militiaDisbandment
		local barWidth = 90
		local barHeight = 8
		love.graphics.setColor(colors["blue"])
		love.graphics.rectangle("fill", self.x + self.width - 110, self.y + 30, barWidth * (callup.progress / MILITIA_DISBAND_TIME), barHeight)
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", self.x + self.width - 110, self.y + 30, barWidth, barHeight)
	--researcj:
	elseif self.tile ~= nil and self.tile.structure ~= nil then
		local y = self.y + 15
		for key, up in pairs(self.tile.structure:getInProgressUpgrades()) do
			love.graphics.setColor(colors["black"])
			love.graphics.setFont(fonts["font12"])
			love.graphics.print("Researching:", self.x + self.width - 120, y)
			local progress = 1 - up.timeRemaining/up.researchTime
			local barWidth = 90
			local barHeight = 8
			love.graphics.setColor(colors["purple"])
			love.graphics.rectangle("fill", self.x + self.width - 110, y + 15, barWidth * progress, barHeight)
			love.graphics.setColor(colors["black"])
			love.graphics.setLineWidth(1)
			love.graphics.rectangle("line", self.x + self.width - 110, y + 15, barWidth, barHeight)
			y = y + 30
		end
	end
end

-- ====================================================

function ControlPanel:mousepressed(x, y, button)
	--this might be too sweeping...
	if ui.mode ~= "default" then
		return
	end
	
	for key, b in pairs(self.buttons) do
		if b:mousepressed(x, y, button) then
			if key == "changeRally" then
				ui:setMode("changeRally")
			elseif key == "cancelNewStruct" then
				currentGame:cancelBuildProject(ui.selectedTile)
				self.parent.controlPanel = nil
			elseif key == "move" then
				ui:setMode("moveRegiment")
			elseif key == "attack" then
				ui:setMode("attackWithRegiment")
			elseif key == "resurrectRegiment" then
				currentGame:resurrectRegiment(ui.selectedTile.structure.regiment)
			elseif key == "repair" then
				currentGame:repairStructure(ui.selectedTile.structure)
			elseif key == "repairTower" then
				currentGame:repairTower(ui.selectedTower)
			elseif key == "openGate" then
				ui.selectedTile.structure.gate:open()
			elseif key == "closeGate" then
				ui.selectedTile.structure.gate:close()
			elseif key == "repairGate" then
				ui.selectedTile.structure:repairGate()
			elseif key == "upgrade" then
				currentGame:upgradeStructure(ui.selectedTile.structure)
			elseif key == "upgradeTower" then
				currentGame:upgradeTower(ui.selectedTower)
			elseif key == "viewWarehouse" then
				ui:setPopup(WarehouseViewer.create())
			elseif key == "switchToWheat" or key == "switchToBread" then
				ui.selectedTile.structure:switchFarmProductionType(key == "switchToWheat")
			elseif key == "callupMilitia" then
				if ui.selectedTower.militiaCallup == nil then
					ui:setMode("pickMilitiaCallup")
					for key, adj in pairs(ui.selectedTower.location.adjacent) do
						adj.tile.isHighlighted = true
					end
				end
			elseif key == "goHome" then
				currentGame:movePlayerRegiment(ui.selectedTile.regiment, ui.selectedTile.regiment.homeStructure.location)
			elseif key == "disbandMilitia" then
				currentGame:disbandMilitia(ui.selectedTile.regiment, false)
			elseif key == "deployRegiment" then
				ui.selectedTile.structure.regiment:placeAt(ui.selectedTile)
				ui:selectRegiment(ui.selectedTile.structure.regiment)
				currentPanel:catchEvent("resetControlPanel")
			elseif key == "restRegiment" then
				if not ui.selectedRegiment:isMoving() and ui.selectedRegiment.fight == nil then
					ui.selectedRegiment:rest()
				end
			elseif key == "halt" then
				ui.selectedRegiment:halt()
			else
				--upgrades
				for upKey, up in pairs(upgrades) do
					if key == upKey then
						Upgrade.purchase(up, ui.selectedTile.structure)
					end
				end
			end
		end
	end
	
	if self.employeeControlPanel ~= nil then
		self.employeeControlPanel:mousepressed(x, y, button)
	end
end

-- ====================================================