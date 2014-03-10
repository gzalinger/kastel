-- version of build panel for spring when player is reconstituting village

SpringBuildPanel = {}
SpringBuildPanel.__index = SpringBuildPanel


function SpringBuildPanel.create(centerX, middleY)
	local temp = {}
	setmetatable(temp, SpringBuildPanel)
	--hax: cetner palette vertically within 1000 (doesn't really matter)
	temp.palette = StructurePalette.create(centerX - 64, middleY - 500, 64, 1000, "spring", temp)
	return temp
end

-- ====================================================

function SpringBuildPanel:draw()
	self.palette:draw()
end

-- ====================================================

function SpringBuildPanel:mousepressed(x, y, button)
	return self.palette:mousepressed(x, y, button)
end

-- ====================================================
-- ====================================================
-- ====================================================

SpringBuildPaletteWidget = {}
SpringBuildPaletteWidget.__index = SpringBuildPaletteWidget


function SpringBuildPaletteWidget.create(parent, structType, w, h)
	local temp = {}
	setmetatable(temp, SpringBuildPaletteWidget)
	temp.width = w
	temp.height = h
	temp.structType = structType
	temp.parent = parent
	return temp
end

-- ====================================================

function SpringBuildPaletteWidget:draw()
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	if self == self.parent.selected and ui.mode == "springPlaceStruct" then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(3)
	else
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(2)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	--image/icon
	love.graphics.setColor(colors["white"])
	local offset = 4
	local img = self.structType.img
	if img == nil then
		img = images["defaultStructure"]
	end
	love.graphics.draw(img, self.x + offset, self.y + offset + (self.height - self.width)/2, 0 , (self.width-2*offset)/img:getWidth(), (self.width-2*offset)/img:getHeight())
	
	--name:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(fonts["font10"])
	local txt = self.structType.name
	love.graphics.print(txt, self.x + (self.width - fonts["font10"]:getWidth(txt))/2, self.y)
end

-- ====================================================

function SpringBuildPaletteWidget:mousepressed(x, y, button)
	if x < self.x or x > self.x+self.width or y < self.y or y > self.y + self.height then
		return false
	end
	
	--deselecting:
	if self.parent.selected == self and ui.mode == "springPlaceStruct" then
		self.parent.selected = nil
		ui:setMode("spring")
	else
		--actual function:
		self.parent.selected = self
		ui:setMode("springPlaceStruct")
		ui.selectionData = self.structType
	end
	return true
end

-- ====================================================