--flexible UI widget that lets user choose an element from a list

ChooserWidget = {}
ChooserWidget.__index = ChooserWidget


function ChooserWidget.create(x, y, w, rowHeight, fontName, options)
	local temp = {}
	setmetatable(temp, ChooserWidget)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.rowHeight = rowHeight
	temp.font = fonts[fontName]
	temp.options = options
	temp.selected = -1
	return temp
end

-- ====================================================

function ChooserWidget:getHeight()
	local height = #self.options * self.rowHeight
	if height == 0 then
		height = 10
	end
	return height
end

-- ====================================================

function ChooserWidget:draw()
	local height = self:getHeight()
	--bg:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, height)
	
	--draw rows:
	love.graphics.setFont(self.font)
	local i = 1
	for key, option in pairs(self.options) do
		local rowY = self.y + self.rowHeight*(i-1)
		if i == self.selected then
			love.graphics.setColor(colors["light_gray"])
			love.graphics.rectangle("fill", self.x, rowY, self.width, self.rowHeight)
		end
		love.graphics.setColor(colors["black"])
		love.graphics.print(option, self.x + 4, rowY + (self.rowHeight - self.font:getHeight(option))/2)
		i = i + 1
	end
	
	--border:
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, height)
end

-- ====================================================

function ChooserWidget:mousepressed(x, y, button)
	if button ~= "l" or #self.options == 0 then
		return
	end
	local height = self:getHeight()
	--make sure click was on widget:
	if x < self.x or x > self.x + self.width or y < self.y or y > self.y + height then
		return
	end
	
	--determine which row was clicked:
	local row = math.ceil((y - self.y) / self.rowHeight)
	self.selected = row
end

-- ====================================================

function ChooserWidget:getSelected()
	if self.selected == -1 then
		return nil
	else
		return self.options[self.selected]
	end
end

-- ====================================================

function ChooserWidget:setSelection(optionName)
	for key, opt in pairs(self.options) do
		if opt == optionName then
			self.selected = key
			return
		end
	end
	self.selected = -1
end

-- ====================================================