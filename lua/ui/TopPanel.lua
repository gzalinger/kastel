-- UI elt that strtetches top of screen during game, contains various sub-elts

TopPanel = {}
TopPanel.__index = TopPanel


function TopPanel.create(x, y, w)
	local temp = {}
	setmetatable(temp, TopPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	local cornerWidth = 240
	local cornerHeight = 92
	temp.topRightPanel = TopRightPanel.create(x + w - cornerWidth, y, cornerWidth, cornerHeight)
	temp.topLeftPanel = TopLeftPanel.create(x, y, cornerWidth, cornerHeight)
	temp.marketPanel = MarketPanel.create(x + cornerWidth, y)
	temp.clockWidget = ClockWidget.create(x + temp.marketPanel.x + temp.marketPanel.width, y, w - 2*cornerWidth - temp.marketPanel.width, cornerHeight)
	--temp.waveMap = WaveMap.create(x + cornerWidth, y, w - 2*cornerWidth, 40)
	temp.autumnPanel = AutumnPanel.create(x, y + cornerHeight + temp.marketPanel.height, cornerWidth, 200)
	return temp
end

-- ====================================================

function TopPanel:draw()
	self.topRightPanel:draw()
	self.topLeftPanel:draw()
	--self.waveMap:draw()
	self.marketPanel:draw()
	self.clockWidget:draw()

	if currentGame.phase == "autumn" then
		self.autumnPanel:draw()
	end
end

-- ====================================================

function TopPanel:catchEvent(event)
	self.marketPanel:catchEvent(event)
end

-- ====================================================

function TopPanel:update(dt)
	self.marketPanel:update(dt)
end

-- ====================================================

function TopPanel:mousepressed(x, y, button)
	return self.topRightPanel:mousepressed(x, y, button) or
		self.topLeftPanel:mousepressed(x, y, button) or
		--self.waveMap:mousepressed(x, y, button) or
		(currentGame.phase == "autumn" and self.autumnPanel:mousepressed(x, y, button)) or
		self.marketPanel:mousepressed(x, y, button) or
		self.clockWidget:mousepressed(x, y, button)
end

-- ====================================================
-- ====================================================
-- ====================================================
-- shows current level and season

TopRightPanel = {}
TopRightPanel.__index = TopRightPanel


function TopRightPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, TopRightPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	return temp
end

-- ====================================================

function TopRightPanel:draw()
	--border and bg:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	--print level and season:
	local font = fonts["font20"]
	love.graphics.setFont(font)
	local txt = "Level " .. currentGame.level.id
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y + self.height/2 - font:getHeight(txt) - 8)
	txt = "Day " .. currentGame:getDay() .. ", "
	if currentGame:isNight() then
		txt = txt .. "Night"
	else
		txt = txt .. "Day"
	end
	love.graphics.print(txt, self.x + (self.width - font:getWidth(txt))/2, self.y + self.height/2 + 8)
end

-- ====================================================

function TopRightPanel:mousepressed(x, y, button)
	return x >= self.x and x <= (self.x+self.width) and y >= self.y and y <= (self.y+self.height)
end

-- ====================================================
-- ====================================================
-- ====================================================
-- shows "critical info" (resources, etc)

TopLeftPanel = {}
TopLeftPanel.__index = TopLeftPanel


function TopLeftPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, TopLeftPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	return temp
end

-- ====================================================

function TopLeftPanel:draw()
	--border and bg:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	local printInterval = 17
	--print resources:
	local printY = self.y + 8
	local col1X = self.x + 4
	local col2X = self.x + 65
	love.graphics.setFont(fonts["font12"])
	love.graphics.print("Gold:", col1X, printY)
	love.graphics.print(currentGame.gold, col2X, printY)
	printY = printY + printInterval
	love.graphics.print("Timber:", col1X, printY)
	love.graphics.print(currentGame.timber, col2X, printY)
	printY = printY + printInterval
	love.graphics.print("Stone:", col1X, printY)
	love.graphics.print(currentGame.stone, col2X, printY)
	printY = printY + printInterval
	love.graphics.print("Wheat:", col1X, printY)
	love.graphics.print(currentGame.wheat .. "/" .. currentGame:getTotalWheatStorage(), col2X, printY)
	printY = printY + printInterval
	love.graphics.print("Current Wall Type:  " .. currentGame.cityWallType.name, col1X, printY)
	--print other stuff:
	printY = self.y + 8
	col1X = self.x + 125
	col2X = self.x + 205
	love.graphics.print("CityPop:", col1X, printY)
	love.graphics.print(currentGame.pop, col2X, printY)
	printY = printY + printInterval
	love.graphics.print("Peasants:", col1X, printY)
	love.graphics.print(#currentGame.peasants, col2X, printY)
	printY = printY + printInterval
	love.graphics.print("Regiments:", col1X, printY)
	love.graphics.print((currentGame:getRegimentCapSpaceUsed()) .. " / " .. currentGame.regimentCap, col2X, printY)
	printY = printY + printInterval
	love.graphics.print("Peasants:", col1X, printY)
	love.graphics.print(#currentGame.unemployed, col2X, printY)
end

-- ====================================================

function TopLeftPanel:mousepressed(x, y, button)
	return x >= self.x and x <= (self.x+self.width) and y >= self.y and y <= (self.y+self.height)
end

-- ====================================================
-- ====================================================
-- ====================================================
-- visually shows number of waves and where seasons line up

WaveMap = {}
WaveMap.__index = WaveMap


function WaveMap.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, WaveMap)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	return temp
end

-- ====================================================

function WaveMap:draw()
	--border and bg:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	local waveWidth = self.width / #currentGame.level.waves
	local waveHeight = self.height - 18
	
	--"halfway" line:
	love.graphics.line(self.x, self.y + waveHeight, self.x + self.width, self.y + waveHeight)

	--actual colored wave boxes
	local font = fonts["font12"]
	love.graphics.setFont(font)
	for key, wave in pairs(currentGame.level.waves) do
		--fill, depending on season:
		if wave.isWinter then
			love.graphics.setColor(colors["ice"])
		else
			love.graphics.setColor(colors["burleywood"])
		end
		love.graphics.rectangle("fill", self.x + waveWidth*(wave.id - 1), self.y, waveWidth, waveHeight)
		--border:
		love.graphics.setColor(colors["black"])
		love.graphics.rectangle("line", self.x + waveWidth*(wave.id - 1), self.y, waveWidth, waveHeight)
		local centerX = self.x + waveWidth*(wave.id - 0.5)
		--label:
		love.graphics.print(wave.id, centerX - font:getWidth(wave.id)/2, self.y + waveHeight + 4)
		--arrow indicating current wave:
		if wave == currentGame.wave then
			if currentGame.phase == "autumn" or currentGame.phase == "spring" then
				centerX = centerX - waveWidth/2
			end
			local width = math.min(50, waveWidth)
			love.graphics.setColor(colors["black"])
			love.graphics.triangle("fill", centerX - width/2, self.y + waveHeight, centerX, self.y + waveHeight/2, centerX + width/2, self.y + waveHeight)
		end
	end
end

-- ====================================================

function WaveMap:mousepressed(x, y, button)
	return x >= self.x and x <= (self.x+self.width) and y >= self.y and y <= (self.y+self.height)
end

-- ====================================================
-- ====================================================
-- ====================================================
-- graphically shows how far into night or day it is

ClockWidget = {}
ClockWidget.__index = ClockWidget


function ClockWidget.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, ClockWidget)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	return temp
end

-- ====================================================

function ClockWidget:draw()
	--bg:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	
	--semi circle:
	if currentGame:isNight() then
		love.graphics.setColor(colors["dark_blue"])
	else
		love.graphics.setColor(colors["yellow"])
	end
	love.graphics.arc("fill", self.x+ self.width/2, self.y + self.height, self.height*0.75, 0, -math.pi)
	
	--clock arm:
	local ageToday = currentGame.levelAge - (currentGame:getDay()-1)*(currentGame.level.dayDuration+currentGame.level.nightDuration)
	local percent
	if currentGame:isNight() then
		percent = (ageToday - currentGame.level.dayDuration) / currentGame.level.nightDuration
	else
		percent = ageToday / currentGame.level.dayDuration
	end
	local angle = math.pi * (1 - percent)
	local armWidth = 0.1 --in radians
	love.graphics.setColor(colors["black"])
	love.graphics.arc("fill", self.x+ self.width/2, self.y + self.height, self.height*0.75, -(angle + armWidth), -(angle - armWidth))
	
	--border:
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

-- ====================================================

function ClockWidget:mousepressed(x, y, button)
	return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

-- ====================================================