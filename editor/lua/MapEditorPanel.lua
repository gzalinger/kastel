--panel for editing map (includes terrain and initial structures)

MapEditorPanel = {}
MapEditorPanel.__index = MapEditorPanel


function MapEditorPanel.create(x, y, w, h, level)
	local temp = {}
	setmetatable(temp, MapEditorPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.hasUnsavedChanges = false
	temp.mapPanel = MapPanel.create(x + 20, y + 20, 500, 500, level)
	
	temp.buttons = {}
	local idx = 1
	for key, terr in pairs(terrainTypes) do
		local b = MapEditButton.create(x + 515 + 57*idx, y + 75, 50, "terrain", key, temp)
		table.insert(temp.buttons, b)
		idx = idx + 1
	end
	--spawn points:
	table.insert(temp.buttons, MapEditButton.create(x + 572, y + 155, 50, "spawnPoint", nil, temp))
	temp.spawnPointTextField = TextField.create(x + 790, y + 160, 100, 25, "font16", false)
	--structures & towers:
	local buttonsPerRow = 7
	local buttonY = y + 240
	idx = 1
	for key, structType in pairs(structureTypes) do
		if key ~= "manor" and key ~= "rubble" then
			local b = MapEditButton.create(x + 515 + 57*idx, buttonY, 50, "structure", key, temp)
			table.insert(temp.buttons, b)
			idx = idx + 1
			if idx > buttonsPerRow then
				idx = 1
				buttonY = buttonY + 60
			end
		end
	end
	buttonY = buttonY + 80
	idx = 1
	for key, structType in pairs(villageStructureTypes) do
		local b = MapEditButton.create(x + 515 + 57*idx, buttonY, 50, "villageStructure", key, temp)
		table.insert(temp.buttons, b)
		idx = idx + 1
	end
	buttonY = buttonY + 80
	idx = 1
	for key, towerType in pairs(towerTypes) do
		if key ~= "gateTower" then
			local b = MapEditButton.create(x + 515 + 57*idx, buttonY, 50, "tower", key, temp)
			table.insert(temp.buttons, b)
			idx = idx + 1
		end
	end
	
	temp.selectedButton = nil
	return temp
end

-- ====================================================

function MapEditorPanel:saveChanges()
	--todo
end

-- ====================================================

function MapEditorPanel:draw()
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	self.mapPanel:draw()
	for key, b in pairs(self.buttons) do
		b:draw()
	end
	
	self.spawnPointTextField:draw()
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font16"])
	love.graphics.print("Spawn Point Name:", self.x + 632, self.y + 163)
	
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font18"])
	love.graphics.print("Terrain:", self.x + 570, self.y + 45)
end

-- ====================================================

function MapEditorPanel:update(dt)
	self.mapPanel:update(dt)
	self.spawnPointTextField:update(dt)
end

-- ====================================================

function MapEditorPanel:mousepressed(x, y, button)
	if button ~= "l" then
		return
	end
	for key, b in pairs(self.buttons) do
		if b:mousepressed(x, y, button) then
			self.editType = b.editType
			self.editSelection = b.editSelection
			self.selectedButton = b
			return
		end
	end
	
	self.spawnPointTextField:mousepressed(x, y, button)
end

-- ====================================================

function MapEditorPanel:keypressed(key)
	self.mapPanel:keypressed(key)
	self.spawnPointTextField:keypressed(key)
end

-- ====================================================
-- ====================================================
-- ====================================================
-- multi-purpose button for anything that can be placed on the map

MapEditButton = {}
MapEditButton.__index = MapEditButton


function MapEditButton.create(x, y, size, editType, editSelection, parent)
	local temp = {}
	setmetatable(temp, MapEditButton)
	temp.x = x
	temp.y = y
	temp.size = size
	temp.editType = editType
	temp.editSelection = editSelection
	temp.parent = parent
	return temp
end

-- ====================================================

function MapEditButton:draw()
	--terrain buttons:
	if self.editType == "terrain" then
		local color = terrainTypes[self.editSelection].color
		love.graphics.setColor({color.r, color.g, color.b})
		love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
	--spawn point
	elseif self.editType == "spawnPoint" then
		local img = images["rallyPoint"]
		love.graphics.setColor(colors["red"])
		love.graphics.draw(img, self.x + 4, self.y + 4, 0, (self.size - 8)/img:getWidth(), (self.size - 8)/img:getHeight())
	--city structures
	elseif self.editType == "structure" then
		local img = structureTypes[self.editSelection].img
		if img ~= nil then
			love.graphics.setColor(colors["white"])
			love.graphics.draw(img, self.x + 4, self.y + 4, 0, (self.size - 8)/img:getWidth(), (self.size - 8)/img:getHeight())
		end
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font10"])
		love.graphics.print(self.editSelection, self.x + (self.size - fonts["font10"]:getWidth(self.editSelection))/2, self.y)
	--village structs:
	elseif self.editType == "villageStructure" then
		local img = villageStructureTypes[self.editSelection].img
		if img ~= nil then
			love.graphics.setColor(colors["white"])
			love.graphics.draw(img, self.x + 4, self.y + 4, 0, (self.size - 8)/img:getWidth(), (self.size - 8)/img:getHeight())
		end
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font10"])
		love.graphics.print(self.editSelection, self.x + (self.size - fonts["font10"]:getWidth(self.editSelection))/2, self.y)
	--towers
	elseif self.editType == "tower" then
		local img = towerTypes[self.editSelection].paletteImg
		if img ~= nil then
			love.graphics.setColor(colors["white"])
			love.graphics.draw(img, self.x + 4, self.y + 4, 0, (self.size - 8)/img:getWidth(), (self.size - 8)/img:getHeight())
		end
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font10"])
		love.graphics.print(self.editSelection, self.x + (self.size - fonts["font10"]:getWidth(self.editSelection))/2, self.y)
	end
	
	--border:
	if self == self.parent.selectedButton then
		love.graphics.setColor(colors["yellow"])
	else
		love.graphics.setColor(colors["black"])
	end
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.size, self.size)
end

-- ====================================================

function MapEditButton:mousepressed(x, y, button)
	return x >= self.x and x <= self.x + self.size and y >= self.y and y <= self.y + self.size
end

-- ====================================================