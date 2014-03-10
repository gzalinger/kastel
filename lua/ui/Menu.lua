-- GUI that exists when not in the middle of a game

Menu = {}
Menu.__index = Menu


function Menu.create()
	local temp = {}
	setmetatable(temp, Menu)
	local w = love.graphics:getWidth()
	local h = love.graphics:getHeight()
	temp.playCampaignButton = TextButton.create("Play Campaign", 0, h - 210, "font20")
	temp.playCampaignButton.x = (w - temp.playCampaignButton.width)/2
	temp.playSandboxButton = TextButton.create("Play Sandbox Mode", 0, h - 120, "font20")
	temp.playSandboxButton.x = (w - temp.playSandboxButton.width)/2
	return temp
end

-- ====================================================

function Menu:draw()
	--title:
	love.graphics.setColor(unpack(colors["black"]))
	love.graphics.setFont(fonts["font30"])
	local title = "Kastel"
	love.graphics.print(title, (love.graphics:getWidth() - fonts["font30"]:getWidth(title))/2, 35)
	--love.graphics.setFont(fonts["font20"])
	--local subtitle = "Version " .. version
	--love.graphics.print(subtitle, (love.graphics:getWidth() - fonts["font20"]:getWidth(subtitle))/2, 80)
	
	self.playCampaignButton:draw()
	self.playSandboxButton:draw()
end
-- ====================================================

function Menu:mousepressed(x, y, button)
	if button == "l" then
		if self.playCampaignButton:mousepressed(x, y, button) then
			nextLevel(levels[1])
		elseif self.playSandboxButton:mousepressed(x, y, button) then
			nextLevel(levels["sandbox"])
		end
	end
end

-- ====================================================

function Menu:mousereleased(x, y, button)
	--nothing
end

-- ====================================================

function Menu:update(dt)
	self.playCampaignButton:update(dt)
	self.playSandboxButton:update(dt)
end

-- ====================================================

function Menu:keypressed(key)
	--if key == "return"  then
	--	nextLevel(levels["sandbox"])
	--end
end

function Menu:keyreleased(key)
	--nothing
end

-- ====================================================

function Menu:catchEvent(event)
	--do nothing
end

-- ====================================================