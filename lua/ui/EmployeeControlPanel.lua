--UI elt for controlling the peasant employees at a structure
-- (sub-panel of ControlPanel)

EmployeeControlPanel = {}
EmployeeControlPanel.__index = EmployeeControlPanel


function EmployeeControlPanel.create(struct, x, y, w, h)
	--NOTE: elt is horizontally centered within this box
	local temp = {}
	setmetatable(temp, EmployeeControlPanel)
	temp.y = y
	temp.height = h
	temp.structure = struct
	local widgetWidth = h - 24
	local widgetHeight = h - 24
	local gap = 12
	temp.width = widgetHeight*struct.structType.employees + gap*(struct.structType.employees + 1)
	temp.x = x + (w - temp.width)/2
	temp.widgets = {}
	temp.buttons = {}
	for i = 1, struct.structType.employees do
		--local widget = {idx = i, x = gap + (gap+widgetWidth)*(i-1) + widgetWidth/2, y = temp.height/2 + 4, size = widgetWidth/2}
		local widX = temp.x + gap + (gap+widgetWidth)*(i-1) + widgetWidth/2
		local widget = EmployeeWidget.create(i, widX, temp.y + temp.height/2 - 6, widgetWidth/2 - 8, temp)
		temp.widgets[i] = widget
		local fillButton = TextButton.create("fill", widX - 22, temp.y + temp.height - 22, "font10")
		fillButton.employeeSlot = struct.employeeSlots[i]
		table.insert(temp.buttons, fillButton)
		local lockButton = TextButton.create("lock", widX, temp.y + temp.height - 22, "font10")
		lockButton.employeeSlot = struct.employeeSlots[i]
		table.insert(temp.buttons, lockButton)
	end
	return temp
end

-- ====================================================

function EmployeeControlPanel:update(dt)
	--disable when there's a militia active:
	if self.structure.militiaCallup ~= nil or self.structure.militiaRegiment ~= nil or self.structure.militiaDisbandment ~= nil then
		return
	end
	for key, but in pairs(self.buttons) do
		but:update(dt)
	end
end

-- ====================================================

function EmployeeControlPanel:draw()
	--bg and border
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	--title:
	love.graphics.setFont(fonts["font10"])
	love.graphics.print("Employees:", self.x + 4, self.y)
	
	--draw widgets:
	for key, wid in pairs(self.widgets) do
		wid:draw()
	end
	--draw buttons:
	for key, but in pairs(self.buttons) do
		but:draw()
	end
	
	--indicate it's under murder attack:
	if self.structure.location.regiment ~= nil and self.structure.location.regiment.murderAttack ~= nil then
		love.graphics.setColor(colors["red"])
		love.graphics.setFont(fonts["font20"])
		local txt = "UNDER ATTACK!"
		love.graphics.print(txt, self.x + (self.width - fonts["font20"]:getWidth(txt))/2,self.y + (self.height - fonts["font20"]:getHeight(txt))/2)
	end
	--indicate there's a militia something
	if self.structure.militiaCallup ~= nil or self.structure.militiaRegiment ~= nil or self.structure.militiaDisbandment ~= nil then
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font20"])
		local txt = "MILITIA ACTIVATED"
		love.graphics.print(txt, self.x + (self.width - fonts["font20"]:getWidth(txt))/2,self.y + (self.height - fonts["font20"]:getHeight(txt))/2)
	end
end

-- ====================================================

function EmployeeControlPanel:mousepressed(x, y, button)
	--disable when under murder-attack:
	if self.structure.location.regiment ~= nil and self.structure.location.regiment.murderAttack ~= nil then
		return
	end
	--disable when there's a militia active:
	if self.structure.militiaCallup ~= nil or self.structure.militiaRegiment ~= nil or self.structure.militiaDisbandment ~= nil then
		return
	end
	
	for key, wid in pairs(self.widgets) do
		wid:mousepressed(x, y, button)
	end
	--lock and fill buttons
	for key, b in pairs(self.buttons) do
		if b:mousepressed(x, y, button) then
			if b.text == "lock" and b.employeeSlot.peasant ~= nil then
				b.employeeSlot.locked = true
			elseif b.text == "fill" and b.employeeSlot.open and b.employeeSlot.peasant == nil then
				currentGame:fillEmployeeSlot(b.employeeSlot, true, self.structure)
			end
		end
	end
end

-- ====================================================
-- ====================================================
-- ====================================================
-- a small UI elt for showing the status of a single employee slot

EmployeeWidget = {}
EmployeeWidget.__index = EmployeeWidget


function EmployeeWidget.create(idx, x, y, r, parent)
	--NOTE: x and y are for center
	local temp = {}
	setmetatable(temp, EmployeeWidget)
	temp.idx = idx
	temp.x = x
	temp.y = y
	temp.radius = r
	temp.parent = parent
	temp.employeeSlot = parent.structure.employeeSlots[idx]
	return temp
end

-- ====================================================

function EmployeeWidget:draw()
	EmployeeWidget.drawWidget(self.x, self.y, self.radius, self.employeeSlot)
end

-- ====================================================

function EmployeeWidget.drawWidget(x, y, radius, slot)
	--center color:
	if slot.peasant ~= nil then
		love.graphics.setColor(colors["blue"])
	else
		love.graphics.setColor(colors["light_gray"])
	end
	love.graphics.circle("fill", x, y, radius)
	--border:
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(1)
	love.graphics.circle("line", x, y, radius)
	
	--'x' for closed slots
	if not slot.open then
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(4)
		love.graphics.line(x - radius/2, y - radius/2, x + radius/2, y + radius/2)
		love.graphics.line(x - radius/2, y + radius/2, x + radius/2, y - radius/2)
	end
	--lock icon
	if slot.locked then
		local img = images["lock"]
		local imgSize = 1.25*radius/img:getWidth()
		love.graphics.draw(img, x - radius*0.7, y - radius*0.7, 0, 1.25*radius/img:getWidth(), 1.25*radius/img:getHeight())
	end
end

-- ====================================================

function EmployeeWidget:mousepressed(x, y, button)
	if button ~= "l" then
		return
	end
	local dist = distance({x = x, y = y}, {x = self.x, y = self.y})
	if dist > self.radius then
		return
	end
	--assertion: this element got clicked with left mouse button
	if self.employeeSlot.open then
		--UNLOCKING:
		if self.employeeSlot.locked then
			self.employeeSlot.locked = false
		--CLOSING:
		else
			self.employeeSlot.open = false
			if self.employeeSlot.peasant ~= nil then
				local peasant = self.employeeSlot.peasant
				self.employeeSlot.peasant = nil
				if self.parent.structure.structType.production ~= nil and self.parent.structure.structType.production.resourceType == "wheat" and not self.parent.structure.isProducingWheat then
					currentGame:calculateBreadProduction()
				end
				currentGame:assignSingleWorker(peasant)
			end
		end
	--OPENING:
	else
		self.employeeSlot.open = true
		currentGame:fillEmployeeSlot(self.employeeSlot, false, self.parent.structure)
	end
end

-- ====================================================