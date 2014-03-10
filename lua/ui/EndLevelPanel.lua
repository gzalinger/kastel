-- ui that appears between levels (and at end of game)

EndLevelPanel = {}
EndLevelPanel.__index = EndLevelPanel


function EndLevelPanel.create(nextLevel)
	local temp = {}
	setmetatable(temp, EndLevelPanel)
	temp.width = love.graphics:getWidth()
	temp.height = love.graphics:getHeight()
	temp.nextLevel = nextLevel
	if nextLevel ~= nil then
		temp.nextLevelButton = TextButton.create("Next Level", 0, temp.height - 100, "font16")
		temp.nextLevelButton.x = (temp.width - temp.nextLevelButton.width)/2
	end
	return temp
end

-- ====================================================

function EndLevelPanel:draw()
	--background:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", 0, 0, self.width, self.height)
	--title:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font30"])
	local title = "Level Complete!"
	love.graphics.print(title, (self.width-fonts["font30"]:getWidth(title))/2, 50)
	--"all levels" subtitle:
	if self.nextLevel == nil then
		title = "You've completed all the levels"
		love.graphics.setFont(fonts["font20"])
		love.graphics.print(title, (self.width-fonts["font20"]:getWidth(title))/2, 125)
	end
	
	if self.nextLevelButton ~= nil then
		self.nextLevelButton:draw()
	end
end

-- ====================================================

function EndLevelPanel:update(dt)
	if self.nextLevelButton ~= nil then
		self.nextLevelButton:update(dt)
	end
end

-- ====================================================

function EndLevelPanel:mousepressed(x, y, button)
	if self.nextLevelButton ~= nil and self.nextLevelButton:mousepressed(x, y, button) then
		nextLevel(self.nextLevel)
	end
end

function EndLevelPanel:mousereleased(x, y, button)
	--do nothing
end

-- ====================================================

function EndLevelPanel:keypressed(key)
	if key == "return" then
		nextLevel(self.nextLevel)
	end
end

function EndLevelPanel:keyreleased(key)
	--do nothing
end

-- ====================================================