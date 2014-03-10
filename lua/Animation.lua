-- very general family of objects that exist temporarily
-- key function is 'update' that returns 'true when animation is done


AnimEndDefendPhase = {}
AnimEndDefendPhase.__index = AnimEndDefendPhase


function AnimEndDefendPhase.create()
	local temp = {}
	setmetatable(temp, AnimEndDefendPhase)
	temp.timeRemaining = 3.0
	return temp
end

-- ====================================================

function AnimEndDefendPhase:update(dt)
	self.timeRemaining = self.timeRemaining - dt
	if self.timeRemaining < 0 then
		currentGame:endDefendPhase()
		return true
	else
		return false
	end
end

-- ====================================================

function AnimEndDefendPhase:draw(mapPanel)
	--do nothing
end

-- ====================================================
-- ====================================================
-- ====================================================
--prompts individual units to move; regiment is still moving until every unit is done

AnimMoveRegiment = {}
AnimMoveRegiment.__index = AnimMoveRegiment


function AnimMoveRegiment.create(regiment)
	local temp = {}
	setmetatable(temp, AnimMoveRegiment)
	temp.regiment = regiment
	--copy units into table:
	temp.units = {}
	for key, u in pairs(regiment.units) do
		temp.units[key] = u
	end
	return temp
end

-- ====================================================

function AnimMoveRegiment:update(dt)
	local done = true
	for key, u in pairs(self.units) do
		if u:updateMove(dt) then
			--this unit is done
			self.units[key] = nil
		else
			--unit isn't done therefore reg isn't
			done = false
		end
	end
	if done then
		self.regiment.moveManager.moveAnim = nil
		if self.regiment:isFriendly() then --monsters reconsider after each step
			self.regiment:takeNextMoveStep()
		end
	end
	return done
end

-- ====================================================

function AnimMoveRegiment:draw(mapPanel)
	--do nothing
end

-- ====================================================
-- ====================================================
-- ====================================================

AnimOpenGate = {}
AnimOpenGate.__index = AnimOpenGate


function AnimOpenGate.create(gate, isOpening)
	local temp = {}
	setmetatable(temp, AnimOpenGate)
	temp.gate = gate
	temp.isOpening = isOpening
	if isOpening then
		temp.percentOpen = 0.0
	else
		temp.percentOpen = 1.0
	end
	return temp
end

-- ====================================================

function AnimOpenGate:update(dt)
	if self.isOpening then
		self.percentOpen = self.percentOpen + dt * 0.5--1.2
	else
		self.percentOpen = self.percentOpen - dt * 0.5--1.2
	end
	if (self.isOpening and self.percentOpen >= 1.0) or (not self.isOpening and self.percentOpen <= 0) then
		self.gate.gateAnim = nil
		if self.isOpening then 
			self.gate.isOpen = true
			--end any fight gate is involved in
			for key, fight in pairs(currentGame.fights) do
				if fight:isAgainstWall() and fight.transition == self.gate.location then
					fight:endFight(false)
				end
			end
		end
		return true
	else
		return false
	end
end

-- ====================================================

function AnimOpenGate:draw(mapPanel)
	--do nothing
end

-- ====================================================
-- ====================================================
-- ====================================================
-- animates a bit of text that slowly rises then disappears (used for resource awards)

AnimFloatingNumber = {}
AnimFloatingNumber.__index = AnimFloatingNumber


function AnimFloatingNumber.create(text, color, loc)
	local temp = {}
	setmetatable(temp, AnimFloatingNumber)
	temp.text = text
	temp.color = color
	temp.location = loc
	temp.age = 0
	return temp
end

-- ====================================================

function AnimFloatingNumber:update(dt)
	local MAX_AGE = 1.0
	local TOTAL_RISE = 0.4
	self.location.offset.y = self.location.offset.y - (dt/MAX_AGE)*TOTAL_RISE
	self.age = self.age + dt
	return self.age >= MAX_AGE
end

-- ====================================================

function AnimFloatingNumber:draw(mapPanel)
	local tile = mapPanel:getTileCenter(self.location.tile)
	local x = tile.x + self.location.offset.x * mapPanel.tileWidth
	local y = tile.y + self.location.offset.y * mapPanel.tileHeight
	local font = fonts["font14"]
	love.graphics.setFont(font)
	love.graphics.setColor(self.color)
	love.graphics.print(self.text, x - font:getWidth(self.text)/2, y - font:getHeight(self.text)/2)
end

-- ====================================================