-- ui elt that shows contents of all warehouses graphically

WarehouseViewer = {}
WarehouseViewer.__index = WarehouseViewer


function WarehouseViewer.create()
	local temp = {}
	setmetatable(temp, WarehouseViewer)
	temp.marginSize = 12
	temp.titleHeight = 16
	temp.iconSize = 50
	temp.iconsPerRow = 5
	
	temp.width = temp.iconSize * temp.iconsPerRow + temp.marginSize * (temp.iconsPerRow + 1)
	temp.height = temp.titleHeight + (temp.iconSize + temp.marginSize) * math.ceil(#currentGame.storedVillageStructs / temp.iconsPerRow) + 2*temp.marginSize
	
	temp.closeButton = TextButton.create("Close", 0, 0, "font14")
	temp.closeButton.x = (temp.width - temp.closeButton.width)/2
	temp.closeButton.y = temp.height - temp.closeButton.height - 8
	return temp
end

-- ====================================================

function WarehouseViewer:draw(x, y)
	--bg and border
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", x, y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, self.width, self.height)
	
	--title:
	love.graphics.setFont(fonts["font14"])
	love.graphics.print("Village Structures in Storage:", x + 8, y + 4)
	
	--icons:
	love.graphics.setLineWidth(1)
	local i = 1
	for key, structType in pairs(currentGame.storedVillageStructs) do
		local iconX = x + self.marginSize*(i % self.iconsPerRow) + self.iconSize*(i%self.iconsPerRow - 1)
		local iconY = y + 2*self.marginSize + self.titleHeight + (self.iconSize+self.marginSize)*math.floor(i / self.iconsPerRow)
		love.graphics.setColor(colors["black"])
		love.graphics.rectangle("line", iconX, iconY, self.iconSize, self.iconSize)
		--image of structType:
		love.graphics.setColor(colors["white"])
		local img = structType.img
		if img == nil then
			img = images["defaultVillageStruct"]
		end
		love.graphics.draw(img, iconX, iconY, 0, self.iconSize/img:getWidth(), self.iconSize/img:getHeight())
		i = i + 1
	end
	
	self.closeButton:draw()
end

-- ====================================================

function WarehouseViewer:update(dt, myX, myY)
	local oldX = self.closeButton.x
	local oldY = self.closeButton.y
	self.closeButton.x = oldX + myX
	self.closeButton.y = oldY + myY
	self.closeButton:update(dt)
	self.closeButton.x = oldX
	self.closeButton.y = oldY
end

-- ====================================================

function WarehouseViewer:mousepressed(x, y, button, myX, myY)
	local oldX = self.closeButton.x
	local oldY = self.closeButton.y
	self.closeButton.x = oldX + myX
	self.closeButton.y = oldY + myY
	if self.closeButton:mousepressed(x, y, button) then
		ui:setPopup(nil)
	end
	self.closeButton.x = oldX
	self.closeButton.y = oldY
end

-- ====================================================

function WarehouseViewer:keypressed(key)
	if key == "escape" then
		ui:setPopup(nil)
	end
end

-- ====================================================