-- class for all things related to traps (peasant defense that immbolizes enemies)

Trap = {}
Trap.__index = Trap


function Trap.create(homeTower, victim)
	local temp = {}
	setmetatable(temp, Trap)
	temp.parentTower = homeTower
	temp.victim = victim
	temp.duration = homeTower.towerType.trapDuration
	return temp
end

-- ====================================================

function Trap.trigger(regiment, from, to)
	--see if there are any traps to trigger on them:
	for key, tower in pairs(currentGame.towers) do
		if tower.traps ~= nil and tower.traps > 0 and tower.buildProject == nil and tableContains(from:getTransitionTo(to):getVertices(), tower.location) then
			--trigger trap!
			local numTraps = math.min(tower.traps, #regiment.units)
			for i = 1, numTraps do
				Trap.initTrap(tower, regiment, i)
			end
			tower.traps = tower.traps - numTraps
			--floating text:
			local adjTile = tower.location:getAdjacent()
			local anim = AnimFloatingNumber.create("Trap x" .. numTraps, colors["black"], {tile = adjTile.tile, offset = MapVertice.getOffset(adjTile.orient)})
			table.insert(currentGame.animations, anim)
		end
	end
end

-- ====================================================

function Trap.initTrap(tower, victimRegiment, idx)
	--create a trap from that tower targeting victim
	--NOTE: traps trigger on but don't affect mechanical units:
	if victimRegiment.regimentType.moveType == "vehicle" then
		return
	end
	local victim = victimRegiment.units[idx]
	local trap = Trap.create(tower, victim)
	victim.trap = trap
	table.insert(currentGame.traps, trap)
end

-- ====================================================

function Trap:update(dt)
	self.duration = self.duration - dt
	if self.duration <= 0 then
		self.victim.trap = nil
		removeFromTable(currentGame.traps, self)
	end
end

-- ====================================================