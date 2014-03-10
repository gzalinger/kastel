-- global abilities for player to use during defend phase

Spell = {}
Spell.__index = Spell


function Spell.setStatics()
	spellTypes = {
		lightningBolt = {name = "Lightning Bolt", cooldown = 30, needsTarget = true}
	}
end

-- ====================================================

function Spell.create(spellType, struct)
	local temp = {}
	setmetatable(temp, Spell)
	temp.spellType = spellTypes[spellType]
	temp.cooldown = 0
	temp.structure = struct --the structure supporting this spell
	return temp
end

-- ====================================================

function Spell:needsTarget()
	--does spell need to target a specific tile?
	return self.spellType.needsTarget
end

-- ====================================================

function Spell:cast(tile)
	--NOTE: 'tile' will be nil if spell doesn't target specific tile
	if self.cooldown > 0 or self.structure.hp < self.structure.structType.hp then
		return
	end
	
	--LIGHTNING BOLT:
	if self.spellType == spellTypes["lightningBolt"] then
		if tile.regiment == nil or tile.regiment:isFriendly() then
			return
		end
		--damage a random unit:
		local reg = tile.regiment
		local victim = reg:getRandomUnit()
		if victim:takeDamage(100, "magic") and reg.fight ~= nil then
			reg.fight:unitKilledByTower(victim)
		end
		victim.parent:takeSplashDamage(15, "magic", victim)
	else
		print("cast spell with unknown spell type")
	end
	self.cooldown = self.spellType.cooldown
end

-- ====================================================

function Spell:update(dt)
	if self.cooldown > 0 then
		self.cooldown = self.cooldown - dt
	end
end

-- ====================================================

function Spell:isAvailable()
	--i.e. can it be cast right now
	return self.cooldown <= 0 and self.structure.hp == self.structure.structType.hp
end

-- ====================================================