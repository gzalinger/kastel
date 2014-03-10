-- UI for setting up initial values of blueprint (done for new levels before going to normal editor)

MapBlueprintEditorPanel = {}
MapBlueprintEditorPanel.__index = MapBlueprintEditorPanel


function MapBlueprintEditorPanel.create(level)
	local temp = {}
	setmetatable(temp, MapBlueprintEditorPanel)
	temp.width = love.graphics:getWidth()
	temp.height = love.graphics:getHeight()
	temp.x = 0
	temp.y = 0
	temp.level = level
	temp.mapWidthTextField = TextField.create(130, 220, 60, 30, "font14", true)
	temp.mapHeightTextField = TextField.create(280, 220, 60, 30, "font14", true)
	local terrainTypeNames = {}
	for key, terrain in pairs(terrainTypes) do
		table.insert(terrainTypeNames, key)
	end
	temp.terrainTypeChooser = ChooserWidget.create(100, 390, 100, 25, "font14", terrainTypeNames)
	temp.doneButton = TextButton.create("Done", 40, temp.height - 80, "font20")
	temp.alert = ""
	return temp
end

-- ====================================================

function MapBlueprintEditorPanel:makeBlueprint(mapWidth, mapHeight, defaultTerrainType)
	--done with this panel; make blueprint for level and more on
	local blueprint = {
		width = mapWidth, height = mapHeight, defaultTerrainType = defaultTerrainType,
		terrain = {}, roads = {},
		townHallLoc = {x = math.floor(mapWidth/2), y = math.floor(mapHeight/2)}
	}
	self.level.mapBlueprint = blueprint
	currentPanel = EditorMainPanel.create(self.level)
end

-- ====================================================

function MapBlueprintEditorPanel:draw()
	--title:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font20"])
	love.graphics.print("First step: define some basics about the map", self.x + 40, self.y + 40)
	
	--alert:
	love.graphics.setColor(colors["red"])
	love.graphics.setFont(fonts["font14"])
	love.graphics.print(self.alert, self.doneButton.x, self.doneButton.y + self.doneButton.height + 8)
	
	--dimensions control labels:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font18"])
	love.graphics.print("Map Dimensions:", self.x + 80, self.y + 170)
	local tempFont = fonts["font14"]
	love.graphics.setFont(tempFont)
	love.graphics.print("Width", self.mapWidthTextField.x - tempFont:getWidth("Width") - 8, self.mapWidthTextField.y + 4)
	love.graphics.print("Height", self.mapHeightTextField.x - tempFont:getWidth("Height") - 8, self.mapHeightTextField.y + 4)
	
	--terrain type label:
	love.graphics.setFont(fonts["font18"])
	love.graphics.print("Choose default terrain type:", self.x + 80, self.y + 350)
	
	self.doneButton:draw()
	self.mapWidthTextField:draw()
	self.mapHeightTextField:draw()
	self.terrainTypeChooser:draw()
end

-- ====================================================

function MapBlueprintEditorPanel:update(dt)
	self.doneButton:update(dt)
	self.mapWidthTextField:update(dt)
	self.mapHeightTextField:update(dt)
end

-- ====================================================

function MapBlueprintEditorPanel:mousepressed(x, y, button)
	self.mapWidthTextField:mousepressed(x, y, button)
	self.mapHeightTextField:mousepressed(x, y, button)
	self.terrainTypeChooser:mousepressed(x, y, button)
	
	if button == "l" and self.doneButton:mousepressed(x, y, button) then
		local width = tonumber(self.mapWidthTextField.text)
		local height = tonumber(self.mapHeightTextField.text)
		if width == nil then
			self.alert = "Invalid map width"
			return
		end
		if height == nil then
			self.alert = "Invalid map height"
			return
		end
		if self.terrainTypeChooser:getSelected() == nil then
			self.alert = "Choose a default terrain type"
			return
		end
		self:makeBlueprint(width, height, self.terrainTypeChooser:getSelected())
	end
end

-- ====================================================

function MapBlueprintEditorPanel:mousereleased(x, y, button)
	--nothing
end

-- ====================================================

function MapBlueprintEditorPanel:keypressed(key)
	self.mapWidthTextField:keypressed(key)
	self.mapHeightTextField:keypressed(key)
end

-- ====================================================

function MapBlueprintEditorPanel:keyreleased(key)
	--nothing
end

-- ====================================================