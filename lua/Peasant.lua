-- class for instances of village residents/workers
-- NOTE: these also function like pseudo-units

Peasant = {}
Peasant.__index = Peasant


function Peasant.create(home)
	local temp = {}
	setmetatable(temp, Peasant)
	temp.home = home
	return temp
end

-- ====================================================

function Peasant:kill()
	if self.employer ~= nil then
		self.employer:getSlotForEmployee(self).peasant = nil
	end
	removeFromTable(self.home.peasantResidents, self)
	removeFromTable(currentGame.peasants, self)
end

-- ====================================================