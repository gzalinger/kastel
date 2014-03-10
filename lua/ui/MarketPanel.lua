-- UI for buying and selling timber and stone

MarketPanel = {}
MarketPanel.__index = MarketPanel


function MarketPanel.create(x, y)
	local temp = {}
	setmetatable(temp, MarketPanel)
	temp.x = x
	temp.y = y
	temp.width = 300
	temp.height = 72
	temp.buyTimberButton = TextButton.create("Buy " .. BUY_TIMBER_AMOUNT .. " Timber (" .. (BUY_TIMBER_AMOUNT*TIMBER_BUY_COST) .. ")", x + 8, y + 8, "font14")
	temp.sellTimberButton = TextButton.create("Sell " .. SELL_TIMBER_AMOUNT .. " Timber (" .. (SELL_TIMBER_AMOUNT*TIMBER_SELL_RATE) .. ")", x + 8 + temp.width/2, y + 8, "font14")
	temp.buyStoneButton = TextButton.create("Buy " .. BUY_STONE_AMOUNT .. " Stone (" .. (BUY_STONE_AMOUNT*STONE_BUY_COST) .. ")", x + 8, y + 8 + temp.height/2, "font14")
	temp.sellStoneButton = TextButton.create("Sell " .. SELL_STONE_AMOUNT .. " Stone (" .. (SELL_STONE_AMOUNT*STONE_SELL_RATE) .. ")", x + 8 + temp.width/2, y + 8 + temp.height/2, "font14")
	return temp
end

-- ====================================================

function MarketPanel:draw()
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	
	self.buyTimberButton:draw()
	self.sellTimberButton:draw()
	self.buyStoneButton:draw()
	self.sellStoneButton:draw()
end

-- ====================================================

function MarketPanel:update(dt)
	self.buyTimberButton:update(dt)
	self.sellTimberButton:update(dt)
	self.buyStoneButton:update(dt)
	self.sellStoneButton:update(dt)
end

-- ====================================================

function MarketPanel:mousepressed(x, y, button)
	if button ~= "l" then
		return
	end
	if self.buyTimberButton:mousepressed(x, y, button) then
		currentGame:buyTimber()
		return true
	elseif self.sellTimberButton:mousepressed(x, y, button) then
		currentGame:sellTimber()
		return true
	elseif self.buyStoneButton:mousepressed(x, y, button) then
		currentGame:buyStone()
		return true
	elseif self.sellStoneButton:mousepressed(x, y, button) then
		currentGame:sellStone()
		return true
	end
	return false
end

-- ====================================================

function MarketPanel:catchEvent(event)
	--do nothing
end

-- ====================================================