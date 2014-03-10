--ui elt that shows tutorial instructions

TutorialPanel = {}
TutorialPanel.__index = TutorialPanel


function TutorialPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, TutorialPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.currentlyDisplaying = 1
	--buttons:
	temp.backButton = TextButton.create("<", x + 8, 0, "font14")
	temp.backButton.y = y + h - 18 - temp.backButton.height
	temp.forwardButton = TextButton.create(">", x + w - 8 - temp.backButton.width, temp.backButton.y, "font14")
	temp.manualButton = TextButton.create(" Proceed ", 0, 0, "font14")
	temp.manualButton.x = x + (w - temp.manualButton.width)/2
	temp.manualButton.y = y + h - 18 - temp.manualButton.height
	return temp
end

-- ====================================================

function TutorialPanel:draw()
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	--text
	love.graphics.setFont(fonts["font12"])
	love.graphics.printf(currentGame.tutorial.steps[self.currentlyDisplaying].text, self.x + 8, self.y + 3, self.width - 16, "left")
	--progress text:
	love.graphics.setFont(fonts["font10"])
	local txt = self.currentlyDisplaying .. " of " .. #currentGame.tutorial.steps
	love.graphics.print(txt, self.x + (self.width - fonts["font10"]:getWidth(txt))/2, self.y + self.height - 14)
	
	--buttons
	if self.currentlyDisplaying > 1 then
		self.backButton:draw()
	end
	if self.currentlyDisplaying < currentGame.tutorial.currentStep then
		self.forwardButton:draw()
	end
	if self.currentlyDisplaying == currentGame.tutorial.currentStep and currentGame.tutorial:getCurrentStep().triggerType == "manual" then
		self.manualButton:draw()
	end
end

-- ====================================================

function TutorialPanel:update(dt)
	if self.currentlyDisplaying > 1 then
		self.backButton:update(dt)
	end
	if self.currentlyDisplaying < currentGame.tutorial.currentStep then
		self.forwardButton:update(dt)
	end
	if self.currentlyDisplaying == currentGame.tutorial.currentStep and currentGame.tutorial:getCurrentStep().triggerType == "manual" then
		self.manualButton:update(dt)
	end
end

-- ====================================================

function TutorialPanel:mousepressed(x, y, button)
	if button ~= "l" then
		return
	end
	if self.currentlyDisplaying > 1 and self.backButton:mousepressed(x, y, button) then
		self.currentlyDisplaying = self.currentlyDisplaying - 1
		return true
	end
	if self.currentlyDisplaying < currentGame.tutorial.currentStep and self.forwardButton:mousepressed(x, y, button) then
		self.currentlyDisplaying = self.currentlyDisplaying + 1
		return true
	end
	if self.currentlyDisplaying == currentGame.tutorial.currentStep and currentGame.tutorial:getCurrentStep().triggerType == "manual" and self.manualButton:mousepressed(x, y, button) then
		if currentGame.tutorial:trigger("manual") then
			self.currentlyDisplaying = self.currentlyDisplaying + 1
		end	
		return true
	end
	return false
end

-- ====================================================