-----------------------
-- NO: A game of numbers
-- Created: 23.08.08 by Michael Enger
-- Version: 0.2
-- Website: http://www.facemeandscream.com
-- Licence: ZLIB
-----------------------
-- Handles buttons and such.
-----------------------

TextButton = {}
TextButton.__index = TextButton

function TextButton.create(text, x, y, fontName)
	
	local temp = {}
	setmetatable(temp, TextButton)
	temp.hover = false -- whether the mouse is hovering over the button
	temp.click = false -- whether the mouse has been clicked on the button
	temp.text = text -- the text in the button
	temp.width = fonts[fontName]:getWidth(text) + 8
	temp.height = fonts[fontName]:getHeight() + 6
	temp.x = x
	temp.fontName = fontName
	temp.y = y
	return temp
	
end


function TextButton:draw()	
	--background:
	love.graphics.setColor(unpack(colors["light_gray"]))
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	--border:	
	love.graphics.setColor(unpack(colors["dark_gray"]))
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	--text:
	love.graphics.setFont(fonts[self.fontName])
	if self.hover then 
		love.graphics.setColor(unpack(colors["black"]))
	else 
		love.graphics.setColor(unpack(colors["dark_gray"])) 
	end
	love.graphics.print(self.text, self.x + 4, self.y + 3)
	
end


function TextButton:update(dt)
	self.hover = false
	
	local x = love.mouse.getX()
	local y = love.mouse.getY()
	
	if x > self.x
		and x < self.x + self.width
		and y < self.y + self.height
		and y > self.y then
		self.hover = true
	end
end


function TextButton:mousepressed(x, y, button)
	if self.hover then
		return true
	end
	return false
end
