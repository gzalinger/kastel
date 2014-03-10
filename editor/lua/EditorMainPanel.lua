--top level UI class for main level-editing UI

EditorMainPanel = {}
EditorMainPanel.__index = EditorMainPanel


function EditorMainPanel.create(level)
	local temp = {}
	setmetatable(temp, EditorMainPanel)
	temp.width = love.graphics:getWidth()
	temp.height = love.graphics:getHeight()
	temp.x = 0
	temp.y = 0
	temp.level = level
	temp.tabButtons = {}
	temp.tabButtons["map"] = TextButton.create("Map", 28, 38, "font16")
	temp.tabButtons["restrictions"] = TextButton.create("Restrictions", 80, 38, "font16")
	temp.tabButtons["misc"] = TextButton.create("Misc", 195, 38, "font16")
	
	local paneX = temp.x + 20
	local paneY = temp.y + 70
	local paneWidth = temp.width - 40
	local paneHeight = temp.height - 120
	temp.contentPanes = {}
	temp.contentPanes["map"] = MapEditorPanel.create(paneX, paneY, paneWidth, paneHeight, level)
	temp.contentPanes["restrictions"] = LevelRestrictionsEditorPanel.create(paneX, paneY, paneWidth, paneHeight)
	temp.contentPanes["misc"] = MiscLevelEditorPanel.create(paneX, paneY, paneWidth, paneHeight, level)
	
	temp:selectTab("map")
	temp.saveButton = TextButton.create("Save", 0, 0, "font20")
	temp.saveButton.x = (temp.width - temp.saveButton.width)/2
	temp.saveButton.y = temp.height - temp.saveButton.height - 6
	return temp
end

-- ====================================================

function EditorMainPanel:selectTab(tab)
	if self.currentTab == tab then
		return
	end
	self.currentTab = tab
	self.contentPane = self.contentPanes[tab]
end

-- ====================================================

function EditorMainPanel:draw()
	--'currently editing' label
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font16"])
	love.graphics.print("Currently Editing:  '" .. self.level.name .. "'", self.x + 8, self.y + 3)

	--highlight selected tab button:
	for key, b in pairs(self.tabButtons) do
		if key == self.currentTab then
			love.graphics.setColor(colors["white"])
			love.graphics.rectangle("fill", b.x - 6, b.y - 4, b.width + 12, self.contentPane.y - b.y + 4)
			love.graphics.setColor(colors["black"])
			love.graphics.setLineWidth(1)
			love.graphics.rectangle("line", b.x - 6, b.y - 4, b.width + 12, self.contentPane.y - b.y + 4)
		end
	end
	
	self.contentPane:draw()
	
	for key, b in pairs(self.tabButtons) do
		b:draw()
		--unsaved changes:
		if self.contentPanes[key].hasUnsavedChanges then
			love.graphics.setColor(colors["black"])
			love.graphics.setFont(fonts["font24"])
			love.graphics.print("*", b.x + b.width - 11, b.y - 4)
		end
	end
	self.saveButton:draw()
end

-- ====================================================

function EditorMainPanel:update(dt)
	for key, b in pairs(self.tabButtons) do
		b:update(dt)
	end
	self.contentPane:update(dt)
	self.saveButton:update(dt)
end

-- ====================================================

function EditorMainPanel:mousepressed(x, y, button)
	if button ~= "l" then
		return
	end
	for key, b in pairs(self.tabButtons) do
		if b:mousepressed(x, y, button) then
			self:selectTab(key)
			return
		end
	end
	if self.saveButton:mousepressed(x, y, button) then
		--save changes made so far:
		for key, pane in pairs(self.contentPanes) do
			if pane.hasUnsavedChanges then
				pane:saveChanges()
			end
		end
		--output new levels:
		EditorSaveUtil.save()
		return
	end
	
	self.contentPane:mousepressed(x, y, button)
end

-- ====================================================

function EditorMainPanel:mousereleased(x, y, button)
	--nothing
end

-- ====================================================

function EditorMainPanel:keypressed(key)
	self.contentPane:keypressed(key)
end

-- ====================================================

function EditorMainPanel:keyreleased(key)
	--nothing
end

-- ====================================================