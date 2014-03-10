-- object that holds meta-data about interactions to keep them separate from individual ui elts

UI = {}
UI.__index = UI


function UI.create() 
	local temp = {}
	setmetatable(temp, UI)
	temp.selectedTile = nil
	temp.selectedTower = nil
	temp.selectedRegiment = nil
	temp.mouseOverTile = nil
	temp.mouseOverVertice = nil
	temp.mode = "default"
	temp.selectionData = nil --very general pointer for various kinds of info pertaining to what's selected
	temp.selectionOrientation = 0
	temp.showExtraInfo = false
	temp.popup = nil
	temp.textMessages = {}
	temp.TEXT_MESSAGE_DURATION = 5.0
	return temp
end

-- ====================================================

function UI:reset()
	self.selectedTile = nil
	self.mouseOverTile = nil
	self.mode = "default"
	self.selectionData = nil
	self.selectionOrientation = 0
	self.showExtraInfo = false
	self.popup = nil
end

-- ====================================================

function UI:update(dt)
	for key, msg in pairs(self.textMessages) do
		msg.age = msg.age + dt
		if msg.age >= self.TEXT_MESSAGE_DURATION then
			removeFromTable(self.textMessages, msg)
		end
	end
end

-- ====================================================

function UI:selectTile(tile)
	if tile ~= nil then
		self.selectedTower = nil
		self.selectedRegiment = nil
	end
	self.selectedTile = tile
	currentPanel:catchEvent("changeSelection")
end

-- ====================================================

function UI:selectTower(tower)
	if tower ~= nil then
		self.selectedTile = nil
		self.selectedRegiment = nil
	end
	self.selectedTower = tower
	currentPanel:catchEvent("changeSelection")
end

-- ====================================================

function UI:selectRegiment(reg)
	if reg ~= nil then
		self.selectedTile = nil
		self.selectedTower = nil
	end
	self.selectedRegiment = reg
	currentPanel:catchEvent("changeSelection")
end

-- ====================================================

function UI:setMode(newMode)
	self.mode = newMode
	self.selectionData = nil
	currentGame.map:clearAllHighlights()
end

-- ====================================================

function UI:setMouseOverTile(tile)
	self.mouseOverTile = tile
end

-- ====================================================

function UI:setMouseOverVertice(vert)
	self.mouseOverVertice = vert
end

-- ====================================================

function UI:setPopup(popup)
	self.popup = popup
end

-- ====================================================

function UI:addTextMessage(text)
	table.insert(self.textMessages, {text = text, age = 0})
end

-- ====================================================