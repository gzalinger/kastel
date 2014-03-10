--partly UI-object that handles everything about cheat codes

CheatManager = {}
CheatManager.__index = CheatManager


function CheatManager.create(x, y)
	local temp = {}
	setmetatable(temp, CheatManager)
	temp.x = x
	temp.y = y
	temp.buffer = ""
	return temp
end

-- ====================================================

function CheatManager:draw()
	love.graphics.setColor(colors["dark_blue"])
	love.graphics.setFont(fonts["font20"])
	love.graphics.print("#" .. self.buffer, self.x, self.y)
end

-- ====================================================

function CheatManager:clear()
	self.buffer = ""
end

-- ====================================================

function CheatManager:keypressed(key)
	if key == "return" then
		self:executeCheat(self.buffer)
		self.buffer = ""
		return true
	else
		self.buffer = self.buffer .. key
		return false
	end
end

-- ====================================================

function CheatManager:executeCheat(code)
	--NOTE: no guarantee code is valid
	if code == "unitethetribes" then
		endLevel()
	elseif code == "thisdoesglitter" then
		currentGame.gold = currentGame.gold + 500
	elseif code == "whoneedsaheart" then
		currentGame.timber = currentGame.timber + 500
	elseif code == "walljackson" then
		currentGame.stone = currentGame.stone + 500
	elseif code == "everyseventh" then
		currentGame:setWave(currentGame.wave.id + 1)
	elseif code == "hurryup" then
		--finish all build projects:
		for key, struct in pairs(currentGame.structures) do
			if struct.buildProject ~= nil then
				currentGame:finishBuildProject(struct.buildProject)
			end
		end
	end	
end

-- ====================================================