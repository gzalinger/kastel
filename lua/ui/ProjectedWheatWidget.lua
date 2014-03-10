-- UI elt that shows projected wheat need and production

ProjectedWheatWidget = {}
ProjectedWheatWidget.__index = ProjectedWheatWidget


function ProjectedWheatWidget.create(x, y, w)
	--NOTE: labels will be left of 'x'
	local temp = {}
	setmetatable(temp, ProjectedWheatWidget)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = 24
	return temp
end

-- ====================================================

function ProjectedWheatWidget:draw()
	--labels:
	local labelFont = fonts["font10"]
	love.graphics.setColor(colors["black"])
	love.graphics.setFont(labelFont)
	local txt = "Wheat Prod"
	love.graphics.print(txt, self.x - labelFont:getWidth(txt) - 4, self.y - 2)
	txt = "Population"
	love.graphics.print(txt, self.x - labelFont:getWidth(txt) - 4, self.y + 10)
	
	local prod = currentGame:getProjectedWheatProduction()
	local need = #currentGame.peasants
	local graphSize = math.ceil(math.max(prod, need))
	
	--actual values:
	local barHeight = 6
	--need/population
	love.graphics.setColor(colors["blue"])
	local w = self.width * (need / graphSize)
	love.graphics.rectangle("fill", self.x, self.y + self.height/2 + 1, w, barHeight)
	--production:
	love.graphics.setColor(colors["burleywood"])
	w = self.width * (prod / graphSize)
	love.graphics.rectangle("fill", self.x, self.y + 1, w, barHeight)
	
	--draw axes:
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(1)
	--vertical:
	love.graphics.line(self.x, self.y, self.x, self.y + self.height)
	--horiz:
	love.graphics.line(self.x, self.y + self.height, self.x + self.width, self.y + self.height)
	
	--hash marks:
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(1)
	love.graphics.setFont(labelFont)
	local hashInterval = self.width / graphSize
	for i = 0, graphSize do
		local hashX = self.x + i * hashInterval
		love.graphics.line(hashX, self.y + self.height, hashX, self.y + self.height + 2)
		--label every fifth and last one
		if i == graphSize or (i % 5) == 0 then
			love.graphics.print(i, hashX - labelFont:getWidth(i)/2, self.y + self.height + 2)
		end
	end
	
	
end

-- ====================================================