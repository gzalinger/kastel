-- widget for inputing boolean values

CheckBox = {}
CheckBox.__index = CheckBox


function CheckBox.create(x, y, size)
	local temp = {}
	setmetatable(temp, CheckBox)
	temp.x = x
	temp.y = y
	temp.size = size
	temp.isChecked = false
	return temp
end

-- ====================================================

function CheckBox:draw()
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.size, self.size)
	
	if self.isChecked then
		love.graphics.line(self.x + 3, self.y + 3, self.x + self.size - 3, self.y + self.size - 3)
		love.graphics.line(self.x + 3, self.y + self.size - 3, self.x + self.size - 3, self.y + 3)
	end
end

-- ====================================================

function CheckBox:mousepressed(x, y, button)
	if button ~= "l" then
		return
	end
	if x >= self.x and x <= self.x + self.size and y >= self.y and y <= self.y + self.size then
		self.isChecked = not self.isChecked
	end
end

-- ====================================================