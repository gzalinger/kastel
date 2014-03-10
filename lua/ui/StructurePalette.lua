-- UI elt that lets player select new structure to build

BuildPanel = {}
BuildPanel.__index = BuildPanel


function BuildPanel.create(x, y, w, h)
	--NOTE: 'height' is total height in which this elt should be centered vertically
	local temp = {}
	setmetatable(temp, BuildPanel)
	temp.x = x
	temp.width = w
	--temp.height = w * 5
	--temp.y = y + (h - temp.height)/2
	temp.originalHeight = h
	temp.originalY = y
	
	temp.buttons = {}
	temp.buttons["structures"] = {x = x, idx = 1, width = w, height = w, category = "structures"}
	temp.buttons["towers"] = {x = x, idx = 2, width = w, height = w, category = "towers"}
	temp.buttons["villageStructs"] = {x = x, idx = 3, width = w, height = w, category = "villageStructs"}
	temp.buttons["villageTowers"] = {x = x, idx = 4, width = w, height = w, category = "villageTowers"}
	for key, b in pairs(temp.buttons) do
		b.isMouseOver = false
	end
	temp.category = "none"
	temp.palette = nil
	return temp 
end

-- ====================================================

function BuildPanel:getHeight()
	return self.width * 4
end

-- ====================================================

function BuildPanel:getY()
	return self.originalY + (self.originalHeight - self:getHeight()) / 2
end

-- ====================================================

function BuildPanel:setCategory(newCategory)
	if newCategory == self.category or newCategory == "none" then
		self.category = "none"
		self.palette = nil
	else
		self.category = newCategory
		self.palette = StructurePalette.create(self.x - self.width, self.originalY, self.width, self.originalHeight, newCategory, self)
	end
end

-- ====================================================

function BuildPanel:draw()
	local h = self:getHeight()
	local y = self:getY()
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, y, self.width, h)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, y, self.width, h)
	for key, button in pairs(self.buttons) do
		self:drawButton(button)
	end
	if self.palette ~= nil then
		self.palette:draw()
	end
end

-- ====================================================

function BuildPanel:drawButton(button)
	local buttonY = self:getY() + (button.idx - 1)*button.width
	--mouse over:
	if button.isMouseOver then
		love.graphics.setColor(colors["light_gray"])
		love.graphics.rectangle("fill", button.x + 1, buttonY + 1, button.width - 2, button.height - 2)
	end
	--selection highlight
	if button.category == self.category then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(3)
		love.graphics.rectangle("line", button.x, buttonY, button.width, button.height)
	else
		--draw 'divider' at bottom of button
		love.graphics.setColor(colors["black"])
		love.graphics.rectangle("fill", button.x, buttonY + button.height, button.width, 2)
	end
	--center image:
	love.graphics.setColor(colors["white"])
	if button.category == "structures" then
		local img = images["structureBuildButton"]
		love.graphics.draw(img, button.x + 4, buttonY + 4, 0, (button.width - 8)/img:getWidth(), (button.height - 8)/img:getHeight())
	elseif button.category == "villageStructs" then
		local img = images["villageStructureBuildButton"]
		love.graphics.draw(img, button.x + 4, buttonY + 4, 0, (button.width - 8)/img:getWidth(), (button.height - 8)/img:getHeight())
	elseif button.category == "towers" then
		local img = images["towerBuildButton"]
		love.graphics.draw(img, button.x + 4, buttonY + 4, 0, (button.width - 8)/img:getWidth(), (button.height - 8)/img:getHeight())
	elseif button.category == "villageTowers" then
		local img = images["villageTowerBuildButton"]
		love.graphics.draw(img, button.x + 4, buttonY + 4, 0, (button.width - 8)/img:getWidth(), (button.height - 8)/img:getHeight())
	elseif button.category == "walls" then
		--hax until image exists:
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font14"])
		love.graphics.print("Walls", button.x + 5, buttonY + button.height/2)
	end
end

-- ====================================================

function BuildPanel:mousepressed(x, y, button)
	if button == "l" then
		for key, button in pairs(self.buttons) do
			if not (button.hideInWinter and currentGame.wave.isWinter) then
				local buttonY = self:getY() + (button.idx - 1)*button.width
				if x >= button.x and x <= (button.x+button.width) and y >= buttonY and y <= (buttonY+button.height) then
					self:setCategory(button.category)
					return true
				end
			end
		end
	end
	if self.palette ~= nil then
		return self.palette:mousepressed(x, y, button)
	else
		return false
	end
end

-- ====================================================

function BuildPanel:keypressed(key)
	--keyboard shortcuts
	if ui.mode ~= "default" then
		return
	end
	
	if self.category == "structures" then
		for tableKey, struct in pairs(structureTypes) do
			if struct.shortcut ~= nil and struct.shortcut == key then
				--make sure it's buildable:
				if currentGame:canAfford(struct) and currentGame:isPrereqMet(struct) and not currentGame:isStructureRestricted(struct) then
					ui:setMode("newStruct")
					ui.selectionData = struct
					ui.selectionOrientation = 0
					self:setCategory("none")
				end
			end
		end
	end
end

-- ====================================================

function BuildPanel:catchEvent(event)
	if event == "changeSelection" or event == "endBuildPhase" then
		self:setCategory("none")
	end
end

-- ====================================================

function BuildPanel:update(dt)
	--for mouse-over stuff:
	local mouseX = love.mouse.getX()
	local mouseY = love.mouse.getY()
	for key, b in pairs(self.buttons) do
		local buttonY = self:getY() + (b.idx - 1)*b.width
		b.isMouseOver = mouseX >= b.x and mouseX <= b.x + b.width and mouseY >= buttonY and mouseY <= buttonY + b.height
	end
	
	if self.palette ~= nil then
		self.palette:update(dt)
	end
end

-- ====================================================
-- ====================================================
-- ====================================================
-- 'palette' of buttons to build specific structs, walls, or towers

StructurePalette = {}
StructurePalette.__index = StructurePalette


function StructurePalette.create(x, y, w, h, category, parent)
	--NOTE: 'height' is total height in which this elt should be centered vertically
	local temp = {}
	setmetatable(temp, StructurePalette)
	temp.x = x
	temp.width = w
	temp.height = 0
	temp.parent = parent
	
	temp.widgets = {}
	temp.selected = nil
	local total = 0
	local widgetHeight = temp.width + 30
	if category == "structures" then
		for key, struct in pairs(structureTypes) do
			if struct.buildable and currentGame:isPrereqMet(struct) and not currentGame:isStructureRestricted(struct) then
				local wid = StructurePaletteWidget.create(temp, struct, temp.width, widgetHeight)
				table.insert(temp.widgets, wid)
				total = total + 1
			end
		end
	elseif category == "villageStructs" then
		for key, vstruct in pairs(villageStructureTypes) do
			if vstruct.buildable and currentGame:isPrereqMet(vstruct) and not currentGame:isVillageStructureRestricted(vstruct) then
				local wid = VillageStructPaletteWidget.create(temp, vstruct, temp.width, widgetHeight)
				table.insert(temp.widgets, wid)
				total = total + 1
			end
		end
	elseif category == "towers" then
		for key, tower in pairs(towerTypes) do
			if tower.buildable and currentGame:isPrereqMet(tower) and not currentGame:isTowerRestricted(tower) then
				local wid = TowerPaletteWidget.create(temp, tower, temp.width, widgetHeight)
				table.insert(temp.widgets, wid)
				total = total + 1
			end
		end
	elseif category == "walls" then
		for key, wall in pairs(wallTypes) do
			if wall.name ~= "Gate" and not currentGame:isWallRestricted(wall) then
				local wid = WallPaletteWidget.create(temp, wall, temp.width, widgetHeight)
				table.insert(temp.widgets, wid)
				total = total + 1
			end
		end
	elseif category == "villageTowers" then
		for key, vt in pairs(villageTowerTypes) do
			if vt.buildable and currentGame:isPrereqMet(vt) and not currentGame:isVillageTowerRestricted(vt) then
				local wid = VillageTowerPaletteWidget.create(temp, vt, temp.width, widgetHeight)
				table.insert(temp.widgets, wid)
				total = total + 1
			end
		end
	elseif category == "spring" then
		for key, stored in pairs(currentGame.storedVillageStructs) do
			local wid = SpringBuildPaletteWidget.create(temp, stored, temp.width, widgetHeight)
			table.insert(temp.widgets, wid)
			total = total + 1
		end
	end
	
	--set elt's width and height
	temp.widgetsPerColumn = 5
	temp.columns = math.ceil(total / temp.widgetsPerColumn)
	temp.height = math.min(temp.widgetsPerColumn*widgetHeight, total*widgetHeight)
	temp.y = y + (h - temp.height)/2
	
	--set widgets' x and y
	local i = 0
	--local widsPerColumn = math.ceil(#temp.widgets/temp.columns)
	for key, wid in pairs(temp.widgets) do
		local widX = temp.x
		if i >= temp.widgetsPerColumn then
			widX = widX - wid.width
		end
		wid.x = widX
		wid.y = temp.y + (i % temp.widgetsPerColumn) * wid.height
		i = i + 1
	end
	
	return temp
end

-- ====================================================

function StructurePalette:draw()
	--bg and border:    NOTE: this has been moved to individual widgets!
	--love.graphics.setColor(colors["white"])
	--love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	--love.graphics.setColor(colors["black"])
	--love.graphics.setLineWidth(2)
	--love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	for key, wid in pairs(self.widgets) do
		wid:draw()
	end
end

-- ====================================================

function StructurePalette:update(dt)
	local mouseX = love.mouse.getX()
	local mouseY = love.mouse.getY()
	for key, wid in pairs(self.widgets) do
		wid.isMouseOver = mouseX >= wid.x and mouseX <= wid.x + wid.width and mouseY >= wid.y and mouseY <= wid.y + wid.height
	end
end

-- ====================================================

function StructurePalette:mousepressed(x, y, button)
	for key, wid in pairs(self.widgets) do
		if wid:mousepressed(x, y, button) then
			return true
		end
	end
	return false
end

-- ====================================================
-- ====================================================
-- ====================================================

StructurePaletteWidget = {}
StructurePaletteWidget.__index = StructurePaletteWidget


function StructurePaletteWidget.create(parent, structType, w, h)
	local temp = {}
	setmetatable(temp, StructurePaletteWidget)
	temp.width = w
	temp.height = h
	temp.structType = structType
	temp.parent = parent
	temp.isMouseOver = false
	return temp
end

-- ====================================================

function StructurePaletteWidget:draw()
	--bg and border:
	if self.isMouseOver then
		love.graphics.setColor(colors["light_gray"])
	else
		love.graphics.setColor(colors["white"])
	end
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	if self == self.parent.selected and ui.mode == "newStruct" then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(3)
	else
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(2)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	if currentGame:canAfford(self.structType) and currentGame:isPrereqMet(self.structType) then
		love.graphics.setColor(colors["white"])
	else
		love.graphics.setColor(colors["dark_gray"])
	end
	local offset = 4
	local img = self.structType.img
	if img == nil then
		img = images["defaultStructure"]
	end
	love.graphics.draw(img, self.x + offset, self.y + offset + (self.height - self.width)/2, 0 , (self.width-2*offset)/img:getWidth(), (self.width-2*offset)/img:getHeight())
	
	--name and cost text:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font10"])
	local txt = self.structType.name
	love.graphics.print(txt, self.x + (self.width - fonts["font10"]:getWidth(txt))/2, self.y)
	txt = self.structType.goldCost .. "/" .. self.structType.timberCost .. "/" .. self.structType.stoneCost .. "/" .. self.structType.popCost
	love.graphics.print(txt, self.x + (self.width - fonts["font10"]:getWidth(txt))/2, self.y + self.height - 12)
end

-- ====================================================

function StructurePaletteWidget:mousepressed(x, y, button)
	--determine if click is w/in bound of this widget:
	if x < self.x or x > self.x+self.width or y < self.y or y > self.y + self.height then
		return false
	end
	if not currentGame:canAfford(self.structType) then
		ui:addTextMessage("You can't afford that.")
		return true
	elseif not currentGame:isPrereqMet(self.structType) then
		ui:addTextMessage("Prereqs haven't been met")
		return true
	end
	
	if self.parent.selected == self and ui.mode == "newStruct" then
		self.parent.selected = nil
		ui:setMode("default")
	else
		self.parent.selected = self
		ui:setMode("newStruct")
		ui.selectionData = self.structType
		ui.selectionOrientation = 0
		self.parent.parent:setCategory("none")
	end
	return true
end

-- ====================================================
-- ====================================================
-- ====================================================
-- another widget, but this one is for building walls

WallPaletteWidget = {}
WallPaletteWidget.__index = WallPaletteWidget


function WallPaletteWidget.create(parent, wallType, w, h)
	local temp = {}
	setmetatable(temp, WallPaletteWidget)
	temp.parent = parent
	temp.wallType = wallType
	temp.width = w
	temp.height = h
	temp.isMouseOver = false
	return temp
end

-- ====================================================

function WallPaletteWidget:draw()
	--bg and border:
	if self.isMouseOver then
		love.graphics.setColor(colors["light_gray"])
	else
		love.graphics.setColor(colors["white"])
	end
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	if self == self.parent.selected and ui.mode == "newWall" then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(3)
	else
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(2)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	if currentGame:canAfford(self.wallType) then
		love.graphics.setColor(colors["white"])
	else
		love.graphics.setColor(colors["dark_gray"])
	end
	
	local img = self.wallType.paletteImage
	local offset = 4
	love.graphics.draw(img, self.x + offset, self.y + offset + (self.height - self.width)/2, 0 , (self.width-2*offset)/img:getWidth(), (self.width-2*offset)/img:getHeight())
	
	--name and cost labels:
	love.graphics.setColor(colors["black"])
	local font = fonts["font10"]
	love.graphics.setFont(font)
	local txt = self.wallType.name
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y)
	txt = self.wallType.goldCost .. "/" .. self.wallType.timberCost .. "/" .. self.wallType.stoneCost
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y + self.height - 12)
end

-- ====================================================

function WallPaletteWidget:mousepressed(x, y, button)
	--determine if click is w/in bound of this widget:
	if x < self.x or x > self.x+self.width or y < self.y or y > self.y + self.height then
		return false
	end
	if not currentGame:canAfford(self.wallType) then
		ui:addTextMessage("You can't afford that")
		return true
	end
	
	if self.parent.selected == self and ui.mode == "newWall" then
		self.parent.selected = nil
		ui:setMode("default")
	else
		self.parent.selected = self
		ui:setMode("newWall")
		ui.selectionData = self.wallType
		ui.selectionOrientation = 0
		self.parent.parent:setCategory("none")
	end
	return true
end

-- ====================================================
-- ====================================================
-- ====================================================

TowerPaletteWidget = {}
TowerPaletteWidget.__index = TowerPaletteWidget


function TowerPaletteWidget.create(parent, towerType, w ,h)
	local temp = {}
	setmetatable(temp, TowerPaletteWidget)
	temp.parent = parent
	temp.towerType = towerType
	temp.width = w
	temp.height = h
	temp.isMouseOver = false
	return temp
end

-- ====================================================

function TowerPaletteWidget:draw()
	--bg and border:
	if self.isMouseOver then
		love.graphics.setColor(colors["light_gray"])
	else
		love.graphics.setColor(colors["white"])
	end
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	if self == self.parent.selected and ui.mode == "newTower" then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(3)
	else
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(2)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	if currentGame:canAfford(self.towerType) and currentGame:isPrereqMet(self.towerType) then
		love.graphics.setColor(colors["white"])
	else
		love.graphics.setColor(colors["dark_gray"])
	end
	local offset = 4
	love.graphics.draw(self.towerType.paletteImg, self.x + offset, self.y + offset + (self.height - self.width)/2, 0 , (self.width-2*offset)/self.towerType.paletteImg:getWidth(), (self.width-2*offset)/self.towerType.paletteImg:getHeight())
	
	--name and cost text:
	love.graphics.setColor(colors["black"])
	local font = fonts["font10"]
	love.graphics.setFont(font)
	local txt = self.towerType.name
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y)
	txt = self.towerType.goldCost .. "/" .. self.towerType.timberCost .. "/" .. self.towerType.stoneCost .."/" .. self.towerType.popCost
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y + self.height - 12)
end

-- ====================================================

function TowerPaletteWidget:mousepressed(x, y, button)
	--determine if click is w/in bound of this widget:
	if x < self.x or x > self.x+self.width or y < self.y or y > self.y + self.height then
		return false
	end
	if not currentGame:canAfford(self.towerType) then
		ui:addTextMessage("You can't afford that")
		return true
	elseif not currentGame:isPrereqMet(self.towerType) then
		ui:addTextMessage("Prereqs haven't been met")
		return true
	end
	
	if self.parent.selected == self and ui.mode == "newTower" then
		self.parent.selected = nil
		ui:setMode("default")
	else
		self.parent.selected = self
		ui:setMode("newTower")
		ui.selectionData = self.towerType
		ui.selectionOrientation = 0
		self.parent.parent:setCategory("none")
	end
	return true
end

-- ====================================================
-- ====================================================
-- ====================================================

VillageStructPaletteWidget = {}
VillageStructPaletteWidget.__index = VillageStructPaletteWidget


function VillageStructPaletteWidget.create(parent, vstructType, w, h)
	local temp = {}
	setmetatable(temp, VillageStructPaletteWidget)
	temp.parent = parent
	temp.vstructType = vstructType
	temp.width = w
	temp.height = h
	temp.isMouseOver = false
	return temp
end

-- ====================================================

function VillageStructPaletteWidget:draw()
	--bg and border:
	if self.isMouseOver then
		love.graphics.setColor(colors["light_gray"])
	else
		love.graphics.setColor(colors["white"])
	end
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	if self == self.parent.selected and ui.mode == "newVillageStruct" then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(3)
	else
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(2)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	if currentGame:canAfford(self.vstructType) and currentGame:isPrereqMet(self.vstructType) then
		love.graphics.setColor(colors["white"])
	else
		love.graphics.setColor(colors["dark_gray"])
	end
	local offset = 4
	local img = self.vstructType.img
	love.graphics.draw(img, self.x + offset, self.y + offset + (self.height - self.width)/2, 0 , (self.width-2*offset)/img:getWidth(), (self.width-2*offset)/img:getHeight())
	
	--name and cost text:
	love.graphics.setColor(colors["black"])
	local font = fonts["font10"]
	love.graphics.setFont(font)
	local txt = self.vstructType.name
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y)
	txt = self.vstructType.goldCost .. "/" .. self.vstructType.timberCost .. "/" .. self.vstructType.stoneCost
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y + self.height - 12)
end

-- ====================================================

function VillageStructPaletteWidget:mousepressed(x, y, button)
	--determine if click is w/in bound of this widget:
	if x < self.x or x > self.x+self.width or y < self.y or y > self.y + self.height then
		return false
	end
	if not currentGame:canAfford(self.vstructType) then
		ui:addTextMessage("You can't afford that")
		return true
	elseif not currentGame:isPrereqMet(self.vstructType) then
		ui:addTextMessage("Prereqs haven't been met")
		return true
	end
	
	if self.parent.selected == self and ui.mode == "newVillageStruct" then
		self.parent.selected = nil
		ui:setMode("default")
	else
		self.parent.selected = self
		ui:setMode("newVillageStruct")
		ui.selectionData = self.vstructType
		ui.selectionOrientation = 0
		self.parent.parent:setCategory("none")
	end
	return true
end

-- ====================================================
-- ====================================================
-- ====================================================

VillageTowerPaletteWidget = {}
VillageTowerPaletteWidget.__index = VillageTowerPaletteWidget


function VillageTowerPaletteWidget.create(parent, vtowerType, w, h)
	local temp = {}
	setmetatable(temp, VillageTowerPaletteWidget)
	temp.parent = parent
	temp.vtowerType = vtowerType
	temp.width = w
	temp.height = h
	temp.isMouseOver = false
	return temp
end

-- ====================================================

function VillageTowerPaletteWidget:draw()
	--bg and border:
	if self.isMouseOver then
		love.graphics.setColor(colors["light_gray"])
	else
		love.graphics.setColor(colors["white"])
	end
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	if self == self.parent.selected and ui.mode == "newVillageTower" then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(3)
	else
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(2)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	if currentGame:canAfford(self.vtowerType) and currentGame:isPrereqMet(self.vtowerType) then
		love.graphics.setColor(colors["white"])
	else
		love.graphics.setColor(colors["dark_gray"])
	end
	local offset = 4
	local img = self.vtowerType.img
	if img == nil then
		img = images["defaultVillageStruct"]
	end
	love.graphics.draw(img, self.x + offset, self.y + offset + (self.height - self.width)/2, 0 , (self.width-2*offset)/img:getWidth(), (self.width-2*offset)/img:getHeight())
	
	--name and cost text:
	love.graphics.setColor(colors["black"])
	local font = fonts["font10"]
	love.graphics.setFont(font)
	local txt = self.vtowerType.name
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y)
	txt = self.vtowerType.goldCost .. "/" .. self.vtowerType.timberCost .. "/" .. self.vtowerType.stoneCost
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y + self.height - 12)
end

-- ====================================================

function VillageTowerPaletteWidget:mousepressed(x, y, buttton)
	--determine if click is w/in bound of this widget:
	if x < self.x or x > self.x+self.width or y < self.y or y > self.y + self.height then
		return false
	end
	if not currentGame:canAfford(self.vtowerType) then
		ui:addTextMessage("You can't afford that")
		return true
	elseif not currentGame:isPrereqMet(self.vtowerType) then
		ui:addTextMessage("Prereqs haven't been met")
		return true
	end
	
	if self.parent.selected == self and ui.mode == "newVillageTower" then
		self.parent.selected = nil
		ui:setMode("default")
	else
		self.parent.selected = self
		ui:setMode("newVillageTower")
		ui.selectionData = self.vtowerType
		ui.selectionOrientation = 0
		self.parent.parent:setCategory("none")
	end
	return true
end

-- ====================================================