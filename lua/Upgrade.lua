-- 'class' for defining and tracking intra-level upgrades

Upgrade = {}
Upgrade.__index = Upgrade


function Upgrade.setStatics()
	upgrades = {
		footmenRegimentSize6 = {name = "Increase Regiment Size (6)", goldCost = 50, timberCost = 0, stoneCost = 0, researchTime = 20, structPrereqs = {}, upgradePrereqs = {}},
		footmenRegimentSize8 = {name = "Increase Regiment Size (8)", goldCost = 75, timberCost = 0, stoneCost = 0, researchTime = 20, structPrereqs = {}, upgradePrereqs = {"footmenRegimentSize6"}},
		footmenRegimentSize10 = {name = "Increase Regiment Size (10)", goldCost = 100, timberCost = 0, stoneCost = 0, researchTime = 20, structPrereqs = {"manor"}, upgradePrereqs = {"footmenRegimentSize8"}},
		footmenArmor = {name = "Footmen Armor", goldCost = 75, timberCost = 0, stoneCost = 0, researchTime = 30, structPrereqs = {}, upgradePrereqs = {}},
		wallsStockade = {name = "Upgrade Walls (Stockades)", goldCost = 100, timberCost = 200, stoneCost = 0, researchTime = 10, structPrereqs = {}, upgradePrereqs = {}},
		wallsStone = {name = "Upgrade Walls (Stone)", goldCost = 250, timberCost = 0, stoneCost = 100, researchTime = 30, structPrereqs = {"manor"}, upgradePrereqs = {"wallsStockade"}}
	}
	--set all to 'not purchased'
	for key, u in pairs(upgrades) do
		u.purchased = false
		u.timeRemaining = u.researchTime --waves remaining until purchased upgrades takes effect
	end
end

-- ====================================================
--[[
function Upgrade.onBuildPhaseBegin()
	--update time for all purchased but unfinished upgrades:
	for key, u in pairs(upgrades) do
		if u.purchased and u.wavesRemaining > 0 then
			u.wavesRemaining = u.wavesRemaining - 1
			if u.wavesRemaining <= 0 then
				u.wavesRemaining = -1 --mark it as complete
				Upgrade.onUpgradeCompleted(u, u.structPurchasedAt)
			end
		end
	end
end
--]]
-- ====================================================

function Upgrade.update(dt)
	for key, u in pairs(upgrades) do
		if u.purchased and u.timeRemaining > -1 then
			u.timeRemaining = u.timeRemaining - dt
			if u.timeRemaining <= 0 then
				u.timeRemaining = -1
				Upgrade.onUpgradeCompleted(u, u.structPurchasedAt)
			end
		end
	end
end

-- ====================================================

function Upgrade.isPurchased(up)
	--NOTE: always use this, don't look at 'purchased' field b/c it doesn't take research time into account
	local upgrade = upgrades[up]
	return upgrade.purchased and upgrade.timeRemaining  == -1
end

-- ====================================================

function Upgrade.isPrereqMet(prereqs)
	--checks upgrade prereqs (not struct ones)
	for key, req in pairs(prereqs) do
		if not upgrades[req].purchased  or upgrades[req].timeRemaining >= 0 then
			return false
		end
	end
	return true
end

-- ====================================================

function Upgrade.purchase(upgrade, struct)
	--make sure player can afford it:
	if not currentGame:canAfford(upgrade) then
		ui:addTextMessage("You can't afford that")
		return
	end
	upgrade.purchased = true
	currentGame:spend(upgrade)
	upgrade.structPurchasedAt = struct
	if upgrade.researchTime == 0 then
		Upgrade.onUpgradeCompleted(upgrade, struct)
		upgrade.timeRemaining = -1
	end
	currentPanel:catchEvent("resetControlPanel")
end

-- ====================================================

function Upgrade.onUpgradeCompleted(upgrade, struct)
	--do any immediate effects from this uograde
	print("Research completed: " .. upgrade.name)
	for key, up in pairs(upgrades) do
		if up == upgrade then
			if key == "footmenRegimentSize6" or key == "footmenRegimentSize8" or key == "footmenRegimentSize10" then
				struct.regiment:increaseMaxUnits(2)
				currentPanel:catchEvent("resetControlPanel")
			elseif key == "wallsStockade" then
				currentGame.cityWallType = wallTypes["stockade"]
				--upgrade all walls:
				for key, trans in pairs(currentGame.map.transitions) do
					if trans.wall ~= nil then
						trans.wall:upgrade(wallTypes["stockade"])
					end
				end
			elseif key == "wallsStone" then
				currentGame.cityWallType = wallTypes["stonewall"]
				--upgrade all walls:
				for key, trans in pairs(currentGame.map.transitions) do
					if trans.wall ~= nil then
						trans.wall:upgrade(wallTypes["stonewall"])
					end
				end
			end
		end
	end
end

-- ====================================================

function Upgrade.cancel(upgrade)
	upgrade.purchased = false
	upgrade.timeRemaining = upgrade.researchTime
end

-- ====================================================