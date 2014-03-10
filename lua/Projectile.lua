--instance of a tower's attack moving across the map

Projectile = {}
Projectile.__index = Projectile


function Projectile.create(from, victim, attack)
	local temp = {}
	setmetatable(temp, Projectile)
	temp.victim = victim
	temp.attack = attack
	local adj = from:getAdjacent()
	temp.source = adj.tile
	temp.position = {x = MapVertice.getOffset(adj.orient).x, y = MapVertice.getOffset(adj.orient).y} --hex units from center of source
	return temp
end

-- ====================================================

function Projectile:update(dt)
	local dest
	if self.victim == nil then
		dest = {x = self.finalDest.x, y = self.finalDest.y}
	else
		local hexDist = getRealHexDistance(self.source, self.victim.location.parent) --goes to center of victim tile, doesn't account for subtiles
		hexDist.x = hexDist.x + (self.victim.location.x + self.victim.locationOffset.x) * MapSubtile.X_OFFSET_PER_SUBTILE
		hexDist.y = hexDist.y + (self.victim.location.y + self.victim.locationOffset.y) * MapSubtile.Y_OFFSET_PER_SUBTILE
		dest = {x = hexDist.x, y = hexDist.y}
	end
	
	--edge case: victim has died:
	if self.victim ~= nil and self.victim.hp <= 0 then
		self.finalDest = dest
		self.victim = nil
	end

	--check to see if it hit
	if self.attack.speed*dt >= distance(self.position, dest) then
		if self.victim ~= nil then
			--DO DAMAGE
			if self.victim:takeDamage(self.attack.damage, self.attack.damageType) and self.victim.parent.fight ~= nil then
				self.victim.parent.fight:unitKilledByTower(self.victim)
			end
			if self.attack.splashDamage ~= nil then
				self.victim.parent:takeSplashDamage(self.attack.splashDamage, self.attack.damageType, self.victim)
			end
		end
		currentGame:removeProjectile(self)
		return
	end
	local angle = angleTo(self.position, dest)
	local dX = self.attack.speed * dt * math.cos(angle)
	local dY = self.attack.speed * dt * math.sin(angle)
	self.position.x = self.position.x + dX
	self.position.y = self.position.y + dY
end

-- ====================================================