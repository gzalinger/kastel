--top level UI for in-game screen

GamePanel = {}
GamePanel.__index = GamePanel


function GamePanel.create()
	local temp = {}
	setmetatable(temp, GamePanel)
	local w = love.graphics:getWidth()
	local h = love.graphics:getHeight()
	temp.x = 0
	temp.y = 0
	temp.width = w
	temp.height = h
	local bottom = 120
	temp.mapPanel = MapPanel.create(24, 24, w - 48, h - 48 - bottom)
	temp.bottomPanel = BottomPanel.create(24, h - 24 -  bottom, w - 48, bottom)
	--temp.critinfoPanel = CritinfoPanel.create(12, 12)
	temp.topPanel = TopPanel.create(12, 12, w - 24)
	--temp.marketPanel = MarketPanel.create(12, 12 + temp.critinfoPanel.height)
	temp.endBuildPhaseButton = TextButton.create("End Build Phase", 36, h - 24 - bottom - 40, "font20")
	temp.cancelRelocationButton = TextButton.create("Get Refund Instead", 36, h - 24 - bottom - 40, "font20")
	temp.endAutumnButton = TextButton.create("End Autumn", 36, h - 24 - bottom - 40, "font20")
	temp.cancelButton = TextButton.create("Cancel", 36, h - 24 - bottom - 40, "font20") -- generic button to return to default ui mode
	temp.buildPanel = BuildPanel.create(w - 24 - 64, 24, 64, h - 48 - bottom)
	temp.spellButtonPanel = SpellButtonPanel.create(32, 48, h - bottom - 16 - 64)
	temp.cheatManager = CheatManager.create(40, h - bottom - 90)
	temp.inCheatMode = false
	temp.tutorialPanel = TutorialPanel.create((w - 320)/2, h - bottom - 170, 320, 130)
	temp.rebuildWallsButton = TextButton.create("Rebuild Walls", 0, h - bottom - 65, "font20")
	temp.rebuildWallsButton.x = w - temp.rebuildWallsButton.width - 40
	return temp
end

-- ====================================================

function GamePanel:draw()
	self.mapPanel:draw() --draw this first so other parts will go over its "spillover"
	
	local w = love.graphics:getWidth()
	local h = love.graphics:getHeight()
	love.graphics.setColor(unpack(colors["white"]))
	love.graphics.setLineWidth(24)
	love.graphics.rectangle("line", 0, 0, w, h)
	love.graphics.setColor(unpack(colors["black"]))
	love.graphics.setLineWidth(3)
	love.graphics.rectangle("line", 12, 12, w - 24, h - 24)
	love.graphics.setColor(unpack(colors["white"]))
	love.graphics.setLineWidth(9)
	love.graphics.rectangle("line", 18, 18, w - 36, h - 36)
	
	self.bottomPanel:draw()
	--self.critinfoPanel:draw()
	self.topPanel:draw()
	
	if ui.mode == "relocateVillageStruct" then
		self.cancelRelocationButton:draw()
	end
	--if #currentGame.destroyedWalls > 0 then
		--self.rebuildWallsButton:draw()
	--end

	self.buildPanel:draw()
	self.spellButtonPanel:draw()

	if ui.mode == "pickMilitiaCallup" then
		self.cancelButton:draw()
	end
	if self.inCheatMode then
		self.cheatManager:draw()
	end
	if currentGame.tutorial ~= nil then
		self.tutorialPanel:draw()
	end
	
	--text messages:
	love.graphics.setColor(colors["yellow"])
	love.graphics.setFont(fonts["font16"])
	local msgY = self.mapPanel.y + self.mapPanel.height - 30
	for key, msg in pairs(ui.textMessages) do
		love.graphics.print(msg.text, self.x + 45, msgY)
		msgY = msgY - 20
	end
	
	--hax directions for rotating
	if ui.mode == "newWall" then
		local txt = "Press 'r' to rotate"
		love.graphics.setColor(colors["yellow"])
		love.graphics.setFont(fonts["font20"])
		love.graphics.print(txt, (love.graphics:getWidth() - fonts["font20"]:getWidth(txt))/2, 60)
	end
	--hax directions for spring stage:
	if currentGame.phase == "spring" then
		local txt = "Place all stored village structures"
		love.graphics.setColor(colors["yellow"])
		love.graphics.setFont(fonts["font20"])
		love.graphics.print(txt, (love.graphics:getWidth() - fonts["font20"]:getWidth(txt))/2, 60)
	end
	--hax directions for relocating village structs:
	if ui.mode == "relocateVillageStruct" then
		local txt = "Pick a location to relocate " .. ui.selectionData.structType.name .. " to."
		love.graphics.setColor(colors["yellow"])
		love.graphics.setFont(fonts["font20"])
		love.graphics.print(txt, (love.graphics:getWidth() - fonts["font20"]:getWidth(txt))/2, 60)
	end
	--hax directions for calling up militias:
	if ui.mode == "pickMilitiaCallup" then
		local txt = "Pick where you want to call up militia."
		love.graphics.setColor(colors["yellow"])
		love.graphics.setFont(fonts["font20"])
		love.graphics.print(txt, (love.graphics:getWidth() - fonts["font20"]:getWidth(txt))/2, 60)
	end
	
	
	--popup and bg
	if ui.popup ~= nil then
		local popupX = self.mapPanel.x + (self.mapPanel.width - ui.popup.width)/2
		local popupY = self.mapPanel.y + (self.mapPanel.height - ui.popup.height)/2
		--grey bg over map panel:
		local bgColor = {100, 100, 100, 100}
		love.graphics.setColor(bgColor)
		love.graphics.rectangle("fill", self.mapPanel.x, self.mapPanel.y, self.mapPanel.width, self.mapPanel.height)
		--center popup over map panel:
		ui.popup:draw(popupX, popupY)
	end
end

-- ====================================================

function GamePanel:update(dt)
	if ui.popup ~= nil then
		local popupX = self.mapPanel.x + (self.mapPanel.width - ui.popup.width)/2
		local popupY = self.mapPanel.y + (self.mapPanel.height - ui.popup.height)/2
		ui.popup:update(dt, popupX, popupY)
		return
	end

	self.mapPanel:update(dt)
	self.bottomPanel:update(dt)
	self.topPanel:update(dt)
	if ui.mode ~= "relocateVillageStruct" then
		self.cancelRelocationButton:update(dt)
	end

	self.buildPanel:update(dt)
	self.spellButtonPanel:update(dt)
	
	if ui.mode == "pickMilitiaCallup" then
		self.cancelButton:update(dt)
	end
	if currentGame.tutorial ~= nil then
		self.tutorialPanel:update(dt)
	end
	
	if ui.popop ~= nil then
		ui.popup:update(dt)
	end
end

-- ====================================================

function GamePanel:mousepressed(x, y, button)
	--remember to 'return' is mouse hits UI so it doesn't also get sent to map panel
	
	--when a popup is up, nothing else can get activated:
	if ui.popup ~= nil then
		local popupX = self.mapPanel.x + (self.mapPanel.width - ui.popup.width)/2
		local popupY = self.mapPanel.y + (self.mapPanel.height - ui.popup.height)/2
		ui.popup:mousepressed(x, y, button, popupX, popupY)
		return
	end
	
	self.bottomPanel:mousepressed(x, y, button)
	if self.topPanel:mousepressed(x, y, button) then
		return
	end

	 if self.buildPanel:mousepressed(x, y, button) then
	 	return
	 end
	 if ui.mode == "relocateVillageStruct" and self.cancelRelocationButton:mousepressed(x, y, button) then
		currentGame:giveRecycleCost(ui.selectionData.structType, ui.selectionData.location)
		ui.selectionData:freeAllEmployees()
		ui:setMode("default")
		return
	end
	if self.spellButtonPanel:mousepressed(x, y, button) then
		return
	end
	if ui.mode == "pickMilitiaCallup" and self.cancelButton:mousepressed(x, y, button) then
		ui:setMode("default")
		return
	end
	if currentGame.tutorial ~= nil and self.tutorialPanel:mousepressed(x, y, button) then
		return
	end
	
	self.mapPanel:mousepressed(x, y, button)
end

-- ====================================================

function GamePanel:mousereleased(x, y, button)
	self.mapPanel:mousereleased(x, y, button)
	self.bottomPanel:mousereleased(x, y, button)
end

-- ====================================================

function GamePanel:keypressed(key)
	--print("'" .. key .. "'")
	
	if ui.popup ~= nil then
		ui.popup:keypressed(key)
		return
	end
	
	if self.inCheatMode then
		if key == "`" then
			self.inCheatMode = false
			self.cheatManager:clear()
		else
			self.inCheatMode = not self.cheatManager:keypressed(key)
		end
		return
	end
	
	if key == "escape" then
		if ui.mode == "newStruct" or ui.mode == "newVillageStruct" or ui.mode == "newWall" or ui.mode == "newTower" or ui.mode == "newVillageTower" or ui.mode == "changeRally" or ui.mode == "moveRegiment" or ui.mode == "attackWithRegiment" or ui.mode == "targetSpell" or ui.mode == "pickMilitiaCallup" then
			ui:setMode("default")
		elseif ui.mode == "default" then
			self.buildPanel:setCategory("none")
		end
	elseif key == "r" then
		if ui.mode == "newWall" or ui.mode == "newStruct" then
			ui.selectionOrientation = (ui.selectionOrientation + 1) % 6
		end
	elseif key == "tab" then
		ui.showExtraInfo = true
	elseif key == "return" and currentGame.phase == "build" then
		currentGame:endBuildPhase()
	elseif key == " " then
		--gate controls
		if currentGame.phase == "defend" and ui.selectedTile ~= nil and ui.selectedTile.structure ~= nil and ui.selectedTile.structure.gate ~= nil then
			local gate = ui.selectedTile.structure.gate
			if gate.isOpen or (gate.gateAnim ~= nil and gate.gateAnim.isOpening) then
				gate:close()
			else
				gate:open()
			end
		end
	elseif key == "`" then
		self.inCheatMode = true
	end
	--shortcuts for build panel:
	--[[
	elseif key == "s" then
		if currentGame.phase == "build" and self.buildPanel.category == "none" then
			self.buildPanel:setCategory("structures")
		end
	elseif key == "w" then
		if currentGame.phase == "build" and self.buildPanel.category == "none" then
			self.buildPanel:setCategory("walls")
		end
	elseif key == "t" then
		if currentGame.phase == "build" and self.buildPanel.category == "none" then
			self.buildPanel:setCategory("towers")
		end
	end
	--]]

	--propagate call to other elts:
	if currentGame.phase == "build" and ui.mode ~= "relocateVillageStruct" then
		self.buildPanel:keypressed(key)
	end
	self.mapPanel:keypressed(key)
end

function GamePanel:keyreleased(key)
	if key == "tab" then
		ui.showExtraInfo = false
	end

	self.mapPanel:keyreleased(key)
end

-- ====================================================

function GamePanel:catchEvent(event)
	if event == "onSpringBegin" or event == "resetSpringBuildPanel" then
		self.springBuildPanel = SpringBuildPanel.create(self.mapPanel.x + self.mapPanel.width, self.mapPanel.y + self.mapPanel.height/2)
	elseif event == "onSpringEnd" then
		self.springBuildPanel = nil
	elseif event == "resetSpellPanel" then
		self.spellButtonPanel:init()
	end

	self.bottomPanel:catchEvent(event)
	self.mapPanel:catchEvent(event)
	--self.critinfoPanel:catchEvent(event)
	self.topPanel:catchEvent(event)
	self.buildPanel:catchEvent(event)
end

-- ====================================================
-- ====================================================
-- ====================================================
--"critical info" panel displays basic facts between both phases
-- NOTE: NO LONGER BEING USED!!

CritinfoPanel = {}
CritinfoPanel.__index = CritinfoPanel

function CritinfoPanel.create(x, y)
	local temp = {}
	setmetatable(temp, CritinfoPanel)
	temp.x = x
	temp.y = y
	temp.width = 940
	temp.height = 20
	return temp
end

-- ====================================================

function CritinfoPanel:draw()
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setLineWidth(2)
	love.graphics.setColor(colors["black"])
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	love.graphics.setFont(fonts["font14"])
	local x = 10
	love.graphics.print("Level:  " .. currentGame.level.id, self.x + x, self.y)
	x = x + 70
	love.graphics.print("Wave:  " .. currentGame.wave.id .. " / " .. #currentGame.level.waves, self.x + x, self.y)
	x = x + 85
	love.graphics.print("|", self.x + x, self.y)
	x = x + 15
	love.graphics.print("Gold:  " .. currentGame.gold, self.x + x, self.y)
	x = x + 95
	love.graphics.print("Timber:  " .. currentGame.timber, self.x + x, self.y)
	x = x + 105
	love.graphics.print("Stone:  " .. currentGame.stone, self.x + x, self.y)
	x = x + 105
	love.graphics.print("Wheat:  " .. currentGame.wheat .. "/" .. currentGame:getTotalWheatStorage(), self.x + x, self.y)
	x = x + 105
	love.graphics.print("CityPop:  " ..currentGame.pop, self.x + x, self.y)
	x = x + 110
	love.graphics.print("Peasant:  " .. #currentGame.peasants, self.x + x, self.y)
	x = x + 110
	love.graphics.print("Regiments:  " .. (#currentGame.playerRegiments) .. " / " .. currentGame.regimentCap, self.x + x, self.y)
end

-- ====================================================

function CritinfoPanel:catchEvent(event)
	--do nothing
end

-- ====================================================