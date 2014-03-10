-- ui that previews the next level

LevelPreviewPanel = {}
LevelPreviewPanel.__index = LevelPreviewPanel


function LevelPreviewPanel.create()
	local temp = {}
	setmetatable(temp, LevelPreviewPanel)
	temp.width = love.graphics:getWidth()
	temp.height = love.graphics:getHeight()
	temp.playButton = TextButton.create("Play!", 0, temp.height - 80, "font20")
	temp.playButton.x = (temp.width - temp.playButton.width)/2
	temp.mapPreview = initMapPreview(temp.height/2)
	temp.mapPreview.x = (temp.width - temp.mapPreview.width)/2
	temp.mapPreview.y = (temp.height - temp.mapPreview.height)/2
	return temp
end

-- ====================================================

function LevelPreviewPanel:draw()
	--level title:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font30"])
	local txt
	if currentGame.level == levels["sandbox"] then
		txt = "Sandbox Mode"
	else
		txt = "Level " .. currentGame.level.id
	end
	love.graphics.print(txt, (self.width - fonts["font30"]:getWidth(txt))/2, 30)
	
	--subtitle
	--love.graphics.setFont(fonts["font16"])
	--txt = currentGame.level.numDays .. " Days"
	--love.graphics.print(txt, (self.width - fonts["font16"]:getWidth(txt))/2, 70)
	--long-form description:
	
	love.graphics.setFont(fonts["font12"])
	local txt = currentGame.level.description
	love.graphics.print(txt, (self.width - fonts["font12"]:getWidth(txt))/2, self.mapPreview.y + self.mapPreview.height + 30)
	
	self.mapPreview:draw()
	self.playButton:draw()
end

-- ====================================================

function LevelPreviewPanel:update(dt)
	self.playButton:update(dt)
end

-- ====================================================

function LevelPreviewPanel:mousepressed(x, y, button)
	if self.playButton:mousepressed(x, y, button) then
		--nextLevel(ui.selectionData)
		currentPanel = GamePanel.create()
		currentGame.paused = false
	end
end

-- ====================================================

function LevelPreviewPanel:mousereleased(x, y, button)
	--do nothing
end

-- ====================================================

function LevelPreviewPanel:keypressed(key)
	if key == "return" then
		--nextLevel(ui.selectionData)
		currentPanel = GamePanel.create()
		currentGame.paused = false
	end
end

-- ====================================================

function LevelPreviewPanel:keyreleased(key)
	--do nothing
end

-- ====================================================

function LevelPreviewPanel:catchEvent(event)
	--do nothing
end

-- ====================================================