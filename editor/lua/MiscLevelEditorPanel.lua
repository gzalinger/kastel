--panel for editing various fields in Level

MiscLevelEditorPanel = {}
MiscLevelEditorPanel.__index = MiscLevelEditorPanel


function MiscLevelEditorPanel.create(x, y, w, h, level)
	local temp = {}
	setmetatable(temp, MiscLevelEditorPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.level = level
	temp.labels = {}
	temp.hasUnsavedChanges = false
	--level id:
	temp.levelIDTextField = TextField.create(x + 80, y + 40, 50, 25, "font16", true)
	temp.levelIDTextField.text = "" .. level.id
	table.insert(temp.labels, {x = temp.levelIDTextField.x - 64, y = temp.levelIDTextField.y + 3, text = "Level ID:", font = fonts["font14"]})
	--wall type:
	table.insert(temp.labels, {x = x + 15, y = y + 90, text = "Initial Wall Type", font = fonts["font16"]})
	temp.wallTypeChooser = ChooserWidget.create(x + 15, y + 115, 130, 25, "font16", EditorUtil.getTableOfNames(EditorUtil.getBuildable(wallTypes)))
	temp.wallTypeChooser:setSelection(wallTypes[level.initialWallType].name)
	--wall gap orientation
	temp.wallGapTextField = TextField.create(x + 185, y + 200, 50, 25, "font16", true)
	temp.wallGapTextField.text = "" .. level.wallGapOrientation
	table.insert(temp.labels, {x = x + 15, y = temp.wallGapTextField.y + 2, text = "Wall Gap Orientation:", font = fonts["font16"]})
	--initial resources:
	table.insert(temp.labels, {x = x + 400, y = y + 40, text = "Initial Resources:", font = fonts["font16"]})
	table.insert(temp.labels, {x  = x + 435, y = y + 70, text = "Gold:", font = fonts["font16"]})
	temp.goldTextField = TextField.create(x + 480, y + 70, 60, 25, "font16", true)
	temp.goldTextField.text = "" .. level.initialResources.gold
	table.insert(temp.labels, {x  = x + 415, y = y + 100, text = "Timber:", font = fonts["font16"]})
	temp.timberTextField = TextField.create(x + 480, y + 100, 60, 25, "font16", true)
	temp.timberTextField.text = "" .. level.initialResources.timber
	table.insert(temp.labels, {x  = x + 425, y = y + 130, text = "Stone:", font = fonts["font16"]})
	temp.stoneTextField = TextField.create(x + 480, y + 130, 60, 25, "font16", true)
	temp.stoneTextField.text = "" .. level.initialResources.stone
	--initial peasant population:
	table.insert(temp.labels, {x = x + 380, y = y + 170, text = "Peasant Population:", font = fonts["font16"]})
	temp.peasantPopulationTextField = TextField.create(x + 540, y + 170, 60, 25, "font16", true)
	temp.peasantPopulationTextField.text = "" .. level.initialPeasantPopulation
	--description:
	table.insert(temp.labels, {x = x + 20, y = y + 300, text = "Description:", font = fonts["font16"]})
	temp.descriptionTextField = TextField.create(x + 130, y + 300, 450, 25, "font16", false)
	temp.descriptionTextField.text = level.description
	--is tutorial:
	table.insert(temp.labels, {x = x + 20, y = y + 350, text= "Tutorial:", font = fonts["font16"]})
	temp.tutorialCheckBox = CheckBox.create(x + 100, y + 350, 25)
	temp.tutorialCheckBox.isChecked = level.isTutorial
	return temp
end

-- ====================================================

function MiscLevelEditorPanel:draw()
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	--all labels:
	love.graphics.setColor(colors["black"])
	for key, label in pairs(self.labels) do
		love.graphics.setFont(label.font)
		love.graphics.print(label.text, label.x, label.y)
	end
	
	--other elements:
	self.levelIDTextField:draw()
	self.wallTypeChooser:draw()
	self.wallGapTextField:draw()
	self.goldTextField:draw()
	self.timberTextField:draw()
	self.stoneTextField:draw()
	self.peasantPopulationTextField:draw()
	self.descriptionTextField:draw()
	self.tutorialCheckBox:draw()
end

-- ====================================================

function MiscLevelEditorPanel:checkForUnsavedChanges()
	if tonumber(self.levelIDTextField.text) ~= self.level.id then
		self.hasUnsavedChanges = true
		return
	elseif wallTypes[self.level.initialWallType].name ~= self.wallTypeChooser:getSelected() then
		self.hasUnsavedChanges = true
		return
	elseif tonumber(self.wallGapTextField.text) ~= self.level.wallGapOrientation then
		self.hasUnsavedChanges = true
		return
	elseif tonumber(self.goldTextField.text) ~= self.level.initialResources.gold then
		self.hasUnsavedChanges = true
		return
	elseif tonumber(self.timberTextField.text) ~= self.level.initialResources.timber then
		self.hasUnsavedChanges = true
		return
	elseif tonumber(self.stoneTextField.text) ~= self.level.initialResources.stone then
		self.hasUnsavedChanges = true
		return
	elseif tonumber(self.peasantPopulationTextField.text) ~= self.level.initialPeasantPopulation then
		self.hasUnsavedChanges = true
		return
	elseif self.descriptionTextField.text ~= self.level.description then
		self.hasUnsavedChanges = true
		return
	elseif self.tutorialCheckBox.isChecked ~= self.level.isTutorial then
		self.hasUnsavedChanges = true
		return
	else
		self.hasUnsavedChanges = false
	end
end

-- ====================================================

function MiscLevelEditorPanel:saveChanges()
	self.level.id = tonumber(self.levelIDTextField.text)
	for key, wallType in pairs(wallTypes) do
		if wallType.name == self.wallTypeChooser:getSelected() then
			self.level.initialWallType = key
		end
	end
	self.level.wallGapOrientation = tonumber(self.wallGapTextField.text)
	self.level.initialResources.gold = tonumber(self.goldTextField.text)
	self.level.initialResources.timber = tonumber(self.timberTextField.text)
	self.level.initialResources.stone = tonumber(self.stoneTextField.text)
	self.level.initialPeasantPopulation = tonumber(self.peasantPopulationTextField.text)
	self.level.description = self.descriptionTextField.text
	self.level.isTutorial = self.tutorialCheckBox.isChecked

	self.hasUnsavedChanges = false
end

-- ====================================================

function MiscLevelEditorPanel:update(dt)
	self.levelIDTextField:update(dt)
	self.wallGapTextField:update(dt)
	self.goldTextField:update(dt)
	self.timberTextField:update(dt)
	self.stoneTextField:update(dt)
	self.peasantPopulationTextField:update(dt)
	self.descriptionTextField:update(dt)
end

-- ====================================================

function MiscLevelEditorPanel:mousepressed(x, y, button)
	self.levelIDTextField:mousepressed(x, y, button)
	self.wallTypeChooser:mousepressed(x, y, button)
	self.wallGapTextField:mousepressed(x, y, button)
	self.goldTextField:mousepressed(x, y, button)
	self.timberTextField:mousepressed(x, y, button)
	self.stoneTextField:mousepressed(x, y, button)
	self.peasantPopulationTextField:mousepressed(x, y, button)
	self.descriptionTextField:mousepressed(x, y, button)
	self.tutorialCheckBox:mousepressed(x, y, button)
	self:checkForUnsavedChanges()
end

-- ====================================================

function MiscLevelEditorPanel:keypressed(key)
	self.levelIDTextField:keypressed(key)
	self.wallGapTextField:keypressed(key)
	self.goldTextField:keypressed(key)
	self.timberTextField:keypressed(key)
	self.stoneTextField:keypressed(key)
	self.peasantPopulationTextField:keypressed(key)
	self.descriptionTextField:keypressed(key)
	self:checkForUnsavedChanges()
end

-- ====================================================