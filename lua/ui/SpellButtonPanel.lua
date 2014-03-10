-- UI for spells; a dynamic list of player's current spells

SpellButtonPanel = {}
SpellButtonPanel.__index = SpellButtonPanel


function SpellButtonPanel.create(h, x, y)
	local temp = {}
	setmetatable(temp, SpellButtonPanel)
	temp.x = x
	temp.y = y
	temp.height = h
	temp.gap = 8 --horiz gap between buttons
	temp:init()
	return temp
end

-- ====================================================

function SpellButtonPanel:init()
	--should get called upon creation and whenever a spell is added or removed
	self.buttons = {}
	local w = 0
	for key, sp in pairs(currentGame.spells) do
		local b = SpellButton.create(self.height, self.x + w + self.height/2, self.y + self.height/2, sp)
		table.insert(self.buttons, b)
		w = w + self.height + self.gap
	end
	if w ~= 0 then
		w = w - self.gap --take off gap after last button
	end
	self.width = w
end

-- ====================================================

function SpellButtonPanel:draw()
	for key, b in pairs(self.buttons) do
		b:draw()
	end
end

-- ====================================================

function SpellButtonPanel:mousepressed(x, y, button)
	for key, b in pairs(self.buttons) do
		if b:mousepressed(x, y, button) then
			return true
		end
	end
	return false
end

-- ====================================================

function SpellButtonPanel:update(dt)
	for key, b in pairs(self.buttons) do
		b:updateMouseOver(love.mouse.getX(), love.mouse.getY())
	end
end

-- ====================================================
-- ====================================================
-- ====================================================
-- button to activate individual spell

SpellButton = {}
SpellButton.__index = SpellButton


function SpellButton.create(size, x, y, spell)
	--NOTE: x,y are center, NOT top-left
	local temp = {}
	setmetatable(temp, SpellButton)
	temp.size = size
	temp.x = x
	temp.y = y
	temp.spell = spell
	temp.isMouseOver = false
	return temp
end

-- ====================================================

function SpellButton:draw()
	--background & border
	love.graphics.setColor(colors["white"])
	love.graphics.circle("fill", self.x, self.y, self.size)
	if ui.mode == "targetSpell" and ui.selectionData == self.spell then
		love.graphics.setColor(colors["yellow"])
	elseif self.isMouseOver then
		love.graphics.setColor(colors["gray"])
	else
		love.graphics.setColor(colors["black"])
	end
	love.graphics.setLineWidth(2)
	love.graphics.circle("line", self.x, self.y, self.size)
	
	--todo: image, name, etc
	
	--show cooldown:
	if self.spell.cooldown > 0 then
		love.graphics.setColor(0, 0, 0, 100)
		local portion = self.spell.cooldown/self.spell.spellType.cooldown
		love.graphics.arc("fill", self.x, self.y, self.size, math.pi*(2*portion - 0.5), -0.5*math.pi)
	end
	--'disbaled'
	if self.spell.structure.hp < self.spell.structure.structType.hp then
		love.graphics.setColor(0, 0, 0, 200)
		love.graphics.circle("fill", self.x, self.y, self.size)
	end
end

-- ====================================================

function SpellButton:updateMouseOver(mouseX, mouseY)
	local dist = distance({x = self.x, y= self.y}, {x = mouseX, y = mouseY})
	self.isMouseOver = dist <= self.size
end

-- ====================================================

function SpellButton:mousepressed(x, y, button)
	if button ~= "l" or ui.mode ~= "default" then
		return false
	end
	local dist = distance({x = self.x, y= self.y}, {x = x, y = y})
	if dist <= self.size then
		if self.spell:isAvailable() then
			if self.spell:needsTarget() then
				ui:setMode("targetSpell")
				ui.selectionData = self.spell
			else
				self.spell:cast()
			end
		end
		return true
	end
	return false
end

-- ====================================================