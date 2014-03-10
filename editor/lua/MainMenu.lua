--opening menu for level editor

MainMenu = {}
MainMenu.__index = MainMenu


function MainMenu.create()
	local temp = {}
	setmetatable(temp, MainMenu)
	temp.width = love.graphics:getWidth()
	temp.height = love.graphics:getHeight()
	temp.x = 0
	temp.y = 0
	temp.newLevelWidget = NewLevelWidget.create(50, 200)
	temp.loadLevelWidget = LoadLevelWidget.create(50, 400)
	return temp
end

-- ====================================================

function MainMenu:draw()
	--title:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font24"])
	love.graphics.print("Welcome to the Kastel Map Editor", self.x + 100, self.y + 60)
	
	self.newLevelWidget:draw()
	self.loadLevelWidget:draw()
end

-- ====================================================

function MainMenu:update(dt)
	self.newLevelWidget:update(dt)
	self.loadLevelWidget:update(dt)
end

-- ====================================================

function MainMenu:mousepressed(x, y, button)
	self.newLevelWidget:mousepressed(x, y, button)
	self.loadLevelWidget:mousepressed(x, y, button)
end

-- ====================================================

function MainMenu:mousereleased(x, y, button)
	--nothing
end

-- ====================================================

function MainMenu:keypressed(key)
	self.newLevelWidget:keypressed(key)
end

-- ====================================================

function MainMenu:keyreleased(key)
	--nothing
end

-- ====================================================
-- ====================================================
-- ====================================================
--controls to make new level and get name for it

NewLevelWidget = {}
NewLevelWidget.__index = NewLevelWidget


function NewLevelWidget.create(x, y)
	local temp = {}
	setmetatable(temp, NewLevelWidget)
	temp.x = x
	temp.y = y
	temp.alert = ""
	temp.textField = TextField.create(x, y + 25, 150, 30, "font14", false)
	temp.makeLevelButton = TextButton.create("Create", x + temp.textField.width + 15, y + 25, "font16")
	return temp
end

-- ====================================================

function NewLevelWidget:draw()
	--title:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font16"])
	love.graphics.print("Make a new level:", self.x, self.y)
	
	--alert:
	love.graphics.setColor(colors["red"])
	love.graphics.setFont(fonts["font14"])
	love.graphics.print(self.alert, self.x, self.y + 70)
	
	self.textField:draw()
	self.makeLevelButton:draw()
end

-- ====================================================

function NewLevelWidget:update(dt)
	self.textField:update(dt)
	self.makeLevelButton:update(dt)
end

-- ====================================================

function NewLevelWidget:mousepressed(x, y, button)
	self.textField:mousepressed(x, y, button)
	if button == "l" and self.makeLevelButton:mousepressed(x, y, button) then
		if self.textField.text:len() == 0 then
			self.alert = "You need to name the level first."
		elseif EditorUtil.findLevelWithName(self.textField.text) ~= nil then
			self.alert = "There's already a level with that name."
		else
			--make a new level:
			local newLevel = EditorUtil.initLevel(self.textField.text)
			table.insert(levels, newLevel)
			currentPanel = MapBlueprintEditorPanel.create(newLevel)
		end
	end
end

-- ====================================================

function NewLevelWidget:keypressed(key)
	self.textField:keypressed(key)
end

-- ====================================================
-- ====================================================
-- ====================================================

LoadLevelWidget = {}
LoadLevelWidget.__index = LoadLevelWidget


function LoadLevelWidget.create(x, y)
	local temp = {}
	setmetatable(temp, LoadLevelWidget)
	temp.x = x
	temp.y = y
	temp.chooser = ChooserWidget.create(x, y + 30, 150, 25, "font14", EditorUtil:getAllLevelNames())
	temp.loadButton = TextButton.create("Load", x, temp.chooser.y + temp.chooser:getHeight() + 12, "font16")
	return temp
end

-- ====================================================

function LoadLevelWidget:draw()
	--title:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font16"])
	love.graphics.print("Load a level:", self.x, self.y)
	
	self.chooser:draw()
	self.loadButton:draw()
end

-- ====================================================

function LoadLevelWidget:update(dt)
	self.loadButton:update(dt)
end

-- ====================================================

function LoadLevelWidget:mousepressed(x, y, button)
	if button ~= "l" then
		return
	end
	
	self.chooser:mousepressed(x, y, button)
	if self.loadButton:mousepressed(x, y, button) and self.chooser:getSelected() ~= nil then
		currentPanel = EditorMainPanel.create(EditorUtil.findLevelWithName(self.chooser:getSelected()))
	end
end

-- ====================================================

function LoadLevelWidget:keypressed(key)
	--nothing
end

-- ====================================================