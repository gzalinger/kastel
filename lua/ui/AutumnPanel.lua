-- panel with autumn-related controls and information

AutumnPanel = {}
AutumnPanel.__index = AutumnPanel


function AutumnPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, AutumnPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	return temp
end

-- ====================================================

function AutumnPanel:draw()
	--border and bg:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	--title:
	love.graphics.setFont(fonts["font16"])
	love.graphics.print("Autumn", self.x + 4, self.y + 4)
	love.graphics.setFont(fonts["font10"])
	love.graphics.print("Select structures to store for winter.", self.x + 4, self.y + 20)
	
	--'currently selected' data:
	love.graphics.setFont(fonts["font12"])
	love.graphics.print("Currently storing " .. #currentGame.autumnTempData.selectedStructs .. " structures", self.x + 4, self.y + 42)
	local txt = "Cost:  " .. currentGame.autumnTempData.goldCost .. " gold"
	if currentGame.autumnTempData.timberCost > 0 then
		txt = txt .. ", " .. currentGame.autumnTempData.timberCost .. " timber"
	end
	if currentGame.autumnTempData.stoneCost > 0 then
		txt = txt .. ", " .. currentGame.autumnTempData.stoneCost .. " stone"
	end
	love.graphics.print(txt, self.x + 12, self.y + 59)
	love.graphics.print("Space used:  " .. currentGame.autumnTempData.spaceUsed .. " / " .. currentGame:getTotalStorageSpace(), self.x + 12, self.y + 76)

	--mouse over cost:
	if ui.mouseOverTile ~= nil and ui.mouseOverTile.structure ~= nil and ui.mouseOverTile.structure.isVillageStruct then
		local struct = ui.mouseOverTile.structure
		love.graphics.print(struct.structType.name, self.x + 4, self.y + 110)
		if tableContains(currentGame.autumnTempData.selectedStructs, struct) then
			love.graphics.print("Already stored!", self.x + 12, self.y + 129)
		elseif struct.structType.storageCost == nil then
			love.graphics.print("Cannot be stored!", self.x + 12, self.y + 129)
		else
			--print cost of storing it:
			local cost = struct.structType.storageCost
			local txt = "Costs " .. cost.gold .. " gold"
			if cost.timber > 0 then
				txt = txt .. ", " .. cost.timber .. " timber"
			end
			if cost.stone > 0 then
				txt = txt .. ", " .. cost.stone .. " stone"
			end
			love.graphics.print(txt, self.x + 12, self.y + 129)
			love.graphics.print("Takes up " .. cost.space .. " space", self.x + 12, self.y + 148)
		end
	end
end

-- ====================================================

function AutumnPanel:mousepressed(x, y, button)
	return x >= self.x and x <= (self.x+self.width) and y >= self.y and y <= (self.y+self.height)
end

-- ====================================================