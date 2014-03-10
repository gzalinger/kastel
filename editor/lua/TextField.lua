-- UI widget for entering text

TextField = {}
TextField.__index = TextField


function TextField.create(x, y, w, h, fontName, isInteger)
	local temp = {}
	setmetatable(temp, TextField)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.font = fonts[fontName]
	temp.text = ""
	temp.isSelected = false --whether or not it has mouse focus and is accepting input
	temp.showCursor = false
	temp.cursorCounter = 0
	temp.cursorBlinkInterval = 0.6
	temp.isInteger = isInteger
	return temp
end

-- ====================================================

function TextField:draw()
	--bg and border
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	if self.isSelected then
		love.graphics.setColor(colors["black"])
	else	
		love.graphics.setColor(colors["dark_gray"])
	end
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	--text:
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(self.font)
	love.graphics.print(self.text, self.x + 4, self.y + (self.height - self.font:getHeight(self.text))/2)
	
	--cursors:
	if self.isSelected and self.showCursor then
		local cursorX = self.x + 6 + self.font:getWidth(self.text)
		love.graphics.line(cursorX, self.y + 4, cursorX, self.y + self.height - 8)
	end
end

-- ====================================================

function TextField:update(dt)
	--cursor blink stuff
	self.cursorCounter = self.cursorCounter + dt
	if self.cursorCounter >= self.cursorBlinkInterval then
		self.cursorCounter = self.cursorCounter - self.cursorBlinkInterval
		self.showCursor = not self.showCursor
	end
end

-- ====================================================

function TextField:mousepressed(x, y, button)
	self.isSelected =  x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

-- ====================================================

function TextField:keypressed(key)
	if not self.isSelected then
		return
	end
	if key == "backspace" then
		if self.text:len() > 0 then
			self.text = self.text:sub(1, self.text:len() - 1)
		end
	else
		if self.isInteger then
			self:addTextToInteger(key)
		else
			self.text = self.text .. key
		end
	end	
end

-- ====================================================

function TextField:addTextToInteger(newText)
	--typing when in 'integer mode'
	if not self:isDigit(newText) then
		return
	end
	--if newText == "0" and self.text:len() == 0 then
	--	return
	--end
	if self.text == "0" then
		self.text = newText
	else
		self.text = self.text .. newText
	end
end

-- ====================================================

function TextField:isDigit(text)
	return (text == "0" or text == "1" or text == "2" or text == "3" or text == "4" or text == "5" or text == "6" or text == "7" or text == "8" or text == "9")
end

-- ====================================================