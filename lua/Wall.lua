-- instance of one section of wall

Wall = {}
Wall.__index = Wall


function Wall.create(wallType, trans)
	local temp = {}
	setmetatable(temp, Wall)
	temp.wallType = wallType
	temp.location = trans
	temp.hp = wallType.hp
	temp.isOpen = false
	return temp
end

-- ====================================================

function Wall:takeDamage(dmg, dmgType, fight)
	dmg = calculateDamageAfterDefense(dmg, dmgType, self.wallType.defenseType, self.wallType.defenseLevel)
	self.hp = self.hp - dmg
	if self.hp <= 0 then
		--if self.wallType ~= wallTypes["gate"] then
		--	currentGame:removeWall(self)
		--end
		table.insert(currentGame.destroyedWalls, self)
		return true
	else
		return false
	end
end

-- ====================================================

function Wall:isPassable()
	return (self.wallType == wallTypes["gate"] and self.isOpen) or self.hp <= 0
end

-- ====================================================

function Wall:open()
	--for gates only
	if self.wallType ~= wallTypes["gate"] then
		return
	end
	--self.isOpen = true WAIT UNTIL ANIM IS FINISHED
	
	if self.gateAnim == nil then
		self.gateAnim = AnimOpenGate.create(self, true)
		table.insert(currentGame.animations, self.gateAnim)
	elseif not self.gateAnim.isOpening then
		self.gateAnim.isOpening = true
	end --last case if animation exists but it's already opening, in which case nothing has to be done
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Wall:close()
	--for gates only
	if self.wallType ~= wallTypes["gate"] then
		return
	end
	--make sure there isn't a fight there:
	for key, fight in pairs(currentGame.fights) do
		if fight.transition == self.location then
			return
		end
	end
	
	self.isOpen = false
	if self.gateAnim == nil then
		self.gateAnim = AnimOpenGate.create(self, false)
		table.insert(currentGame.animations, self.gateAnim)
	elseif self.gateAnim.isOpening then
		self.gateAnim.isOpening = false
	end --last case if animation exists but it's already closing, in which case nothing has to be done
	
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Wall:isBroken()
	return self.wallType == wallTypes["gate"] and self.hp <= 0
end

-- ====================================================

function Wall:getPercentOpen()
	if self.wallType ~= wallTypes["gate"] then
		--case for normal (non-gate) walls:
		if self.hp <= 0 then
			return 1.0
		else
			return 0.0
		end
	elseif self.gateAnim ~= nil then
		return self.gateAnim.percentOpen
	elseif self.isOpen or self:isBroken() then
		return 1.0
	else
		return 0.0 --gate is closed
	end
end

-- ====================================================

function Wall:upgrade(newWallType)
	local hpDiff = newWallType.hp - self.wallType.hp
	self.wallType = newWallType
	self.hp = self.hp + hpDiff
end

-- ====================================================