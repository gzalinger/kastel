-- a multi-purpose UI elt that gets "popped" up over map panel

Popup = {}
Popup.__index = Popup


function Popup.create(topic, data)
	local temp = {}
	setmetatable(temp, Popup)
	temp.topic = topic
	temp.data = data
	temp.buttons = {}
	temp:init()
	return temp
end

-- ====================================================

function Popup:init()
	--sets width and height depending on topic
	if self.topic == "PeasantShelterResults" then
		self.width = 230
		self.height = 180
		local button = TextButton.create("OK", 0, 0, "font14")
		button.x = (self.width - button.width)/2
		button.y = self.height - button.height - 8
		self.buttons["ok"] = button
	elseif self.topic == "BuildOverVillageStruct" then
		self.width = 250
		self.height = 130
		local button = TextButton.create("Cancel", 0, 0, "font14")
		button.x = 16
		button.y = self.height - button.height - 8
		self.buttons["ok"] = button
		button = TextButton.create("Refund", 0, 0, "font14")
		button.x = self.width/2  - button.width/2
		button.y = self.height - button.height - 8
		self.buttons["buildOverRefund"] = button
		button = TextButton.create("Relocate", 0, 0, "font14")
		button.x = self.width - button.width - 8
		button.y = self.height - button.height - 8
		self.buttons["buildOverRelocate"] = button
	elseif self.topic == "noSpringPhase" then
		self.width = 250
		self.height = 130
		local button = TextButton.create("OK", 0, 0, "font14")
		button.x = (self.width - button.width)/2
		button.y = self.height - button.height - 16
		self.buttons["ok"] = button
	else
		print("WARNING: unknown popup topic in 'init()':  " .. self.topic)
	end
end

-- ====================================================

function Popup:update(dt, myX, myY)
	for key, b in pairs(self.buttons) do
		local oldX = b.x
		local oldY = b.y
		b.x = b.x + myX
		b.y = b.y + myY
		b:update(dt)
		b.x = oldX
		b.y = oldY
	end
end

-- ====================================================

function Popup:mousepressed(x, y, button, myX, myY)
	--"myX" and "myY" are x and y values of this popup
	for key, b in pairs(self.buttons) do
		local oldX = b.x
		local oldY = b.y
		b.x = b.x + myX
		b.y = b.y + myY
		if b:mousepressed(x, y, button) then
			self:onButtonPressed(key)
		end
		b.x = oldX
		b.y = oldY
	end
	
	return x >= myX and x <= myX + self.width and y >= myY and y <= myY + self.height
end

-- ====================================================

function Popup:onButtonPressed(buttonKey)
	if buttonKey == "ok" then
		ui:setPopup(nil)
	elseif buttonKey == "buildOverRefund" then
		if self.topic == "BuildOverVillageStruct" then
			currentGame:buildOverVillageStruct(self.data.villageStruct, self.data.newStructType, false)
			ui:setPopup(nil)
		end
	elseif buttonKey == "buildOverRelocate" then
		if self.topic == "BuildOverVillageStruct" then
			currentGame:buildOverVillageStruct(self.data.villageStruct, self.data.newStructType, true)
			ui:setPopup(nil)
		end
	end
end

-- ====================================================

function Popup:draw(x, y)
	--border and bg:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", x, y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, self.width, self.height)
	--buttons:
	for key, b in pairs(self.buttons) do
		local oldX = b.x
		local oldY = b.y
		b.x = b.x + x
		b.y = b.y + y
		b:draw()
		b.x = oldX
		b.y = oldY
	end
	
	if self.topic == "PeasantShelterResults" then
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font16"])
		love.graphics.print("Peasant Sheltering", x + 4, y + 4)
		love.graphics.setFont(fonts["font12"])
		local col1 = x + 8
		local col2 = x + 130
		local printY = y + 36
		love.graphics.print("Initial Peasants:", col1, printY)
		love.graphics.print(self.data.startingPeasants, col2, printY)
		printY = printY + 20
		love.graphics.print("Wheat:", col1, printY)
		love.graphics.print(self.data.wheat, col2, printY)
		printY = printY + 20
		love.graphics.print("Shelter Space:", col1, printY)
		love.graphics.print(self.data.shelter, col2, printY)
		printY = printY + 25
		love.graphics.line(col1, printY - 5, col2 + 10, printY - 5)
		love.graphics.print("Deaths:", col1, printY)
		love.graphics.print(self.data.peasantsLost, col2, printY)
	
	elseif self.topic == "BuildOverVillageStruct" then
		love.graphics.setColor(colors["black"])
		local font = fonts["font14"]
		love.graphics.setFont(font)
		local txt = "Are you sure you want to build"
		love.graphics.print(txt, x + (self.width - font:getWidth(txt))/2, y + 16)
		local txt = "over that " .. self.data.villageStruct.structType.name .. "?"
		love.graphics.print(txt, x + (self.width - font:getWidth(txt))/2, y + 40)
		local txt = "(you will get a partial refund)"
		love.graphics.print(txt, x + (self.width - font:getWidth(txt))/2, y + 64)
	
	elseif self.topic == "noSpringPhase" then
		love.graphics.setColor(colors["black"])
		local font = fonts["font14"]
		love.graphics.setFont(font)
		local txt = "Spring has passed."
		love.graphics.print(txt, x + (self.width - font:getWidth(txt))/2, y + 16)
		txt = "(you had no structures in storage)"
		love.graphics.print(txt, x + (self.width - font:getWidth(txt))/2, y + 40)
	end
end

-- ====================================================

function Popup:keypressed(key)
	--do nothing
end

-- ====================================================