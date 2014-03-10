--displays actual game map
-- THIS IS MODIFIED VERSION FOR EDITOR

MapPanel = {}
MapPanel.__index = MapPanel


function MapPanel.create(x, y, w, h, level)
	local temp = {}
	setmetatable(temp, MapPanel)
	temp.level = level
	temp.map = Map.create(level)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.tileHeight = 80
	temp.tileWidth = temp.tileHeight * TILE_ASPECT_RATIO
	temp.zoom = 1.0
	temp.parent = parent
	--center:
	local left = math.floor(round(level.mapBlueprint.width/2) - (temp.width/2) / temp.tileWidth)
	local top = math.floor(round(level.mapBlueprint.height/2) - (temp.height/2) / temp.tileHeight)
	temp.topLeft = {x = left, y = top} --map coord that the top left of UI shows
	
	temp:adjustZoom(0.5)
	return temp
end

-- ====================================================

function MapPanel:draw()
	--background:
	love.graphics.setColor(unpack(colors["gray"]))
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	--tiles:
	--draw each tile independently:
	for key, tile in pairs(self.map.tiles) do
		self:drawMapTile(tile)
	end
	
	--transitions:
	for key, trans in pairs(self.map.transitions) do
		self:drawTransition(trans)
	end
	
	--towers:
	--for key, tower in pairs(currentGame.towers) do
	--	self:drawTower(tower.towerType, tower.location, tower.hp/tower.towerType.hp, nil, tower == ui.selectedTower)
	--end
	
	--initial structures:
	self:drawStructureGhost(structureTypes["townhall"], self.level.mapBlueprint.townHallLoc, colors["white"])
	for key, struct in pairs(self.level.initialStructures) do
		self:drawStructureGhost(struct.structType, struct, colors["white"])
	end
	for key, struct in pairs(self.level.initialVillageStructures) do
		self:drawStructureGhost(struct.structType, struct, colors["white"])
	end
	for key, tower in pairs(self.level.initialTowers) do
		self:drawTower(tower.towerType, tower, tower.orientation, colors["white"])
	end
	--todo: initial village structs
	--todo: initial towers (city and village)
	
	--ghost tower (mouse over for 'new tower' mode:
	--if (ui.mode == "newTower" or ui.mode == "newVillageTower") and ui.mouseOverVertice ~= nil then
	--	self:drawTower(ui.selectionData, ui.mouseOverVertice, 1, nil, false)
	--end
	
	--border:
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(3)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

-- ====================================================

function MapPanel:drawMapTile(tile)
	local x = self.x + (tile.x - self.topLeft.x) * self.tileWidth
	local y = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2)
	
	local vertices = {
		x + HEX_RATIO*self.tileWidth, y,
		x + (1-HEX_RATIO)*self.tileWidth, y,
		x + (1+HEX_RATIO)*self.tileWidth, y + self.tileHeight/2,
		x + (1-HEX_RATIO)*self.tileWidth, y + self.tileHeight,
		x + HEX_RATIO*self.tileWidth, y + self.tileHeight,
		x - self.tileWidth*HEX_RATIO, y + self.tileHeight/2
	}
	
	--don't draw tiles that are off screen:
	if x > self.x + self.width or (x + self.tileWidth) < self.x or y > self.y + self.height or (y + self.tileHeight) < self.y then
		return
	end
	
	love.graphics.setColor(tile.bgColor)
	love.graphics.polygon("fill", vertices)
	
	--draw structure:
	--if tile.structure ~= nil then
	--	self:drawStructure(tile.structure, x, y)
	--end
	
	--mouse over stuff:
	if self.mouseOverTile == tile then
		--[[
		if (ui.mode == "newStruct" or ui.mode == "springPlaceStruct" or ui.mode == "relocateVillageStruct" or ui.mode == "newVillageStruct") and (tile.structure == nil or (tile.structure.isVillageStruct and not tableContains(villageStructureTypes, ui.selectionData))) then
			local structType = ui.selectionData
			if ui.mode == "relocateVillageStruct" then
				structType = ui.selectionData.structType
			end
			self:drawStructureGhost(structType, x, y, colors["white"])
		end
		--]]
	end
	
	--spawn point
	if tile.isSpawnPoint then
		love.graphics.setColor(colors["red"])
		local img = images["rallyPoint"]
		love.graphics.draw(img, x + self.tileWidth/8, y + self.tileHeight*0.375, 0, (self.tileWidth/2)/img:getWidth(), (self.tileHeight/2)/img:getHeight())
	end	
end -- end drawMapTile()

-- ====================================================
--[[
function MapPanel:drawStructure(struct, tile)
	local x = self:getTileCenter(tile).x - self.tileWidth/2
	local y = self.getTileCenter(tile).y - self.tileHeight/2
	love.graphics.setColor(colors["white"])
	local structSize = self.tileHeight/2
	local img = struct.structType.img
	if img == nil then
		img = images["defaultStructure"]
	end
	love.graphics.draw(img, x + (self.tileWidth-structSize)/2, y + (self.tileHeight-structSize)/2, 0, structSize/img:getWidth(), structSize/img:getHeight())
end
--]]
-- ====================================================

function MapPanel:drawStructureGhost(struct, tile, color)
	--for structure types, not actual instances (e.g. when placing new structures
	local structSize = self.tileHeight/2
	local x = self:getTileCenter(tile).x - self.tileWidth/2 + (self.tileWidth-structSize)/2
	local y = self:getTileCenter(tile).y - self.tileHeight/2 + (self.tileHeight-structSize)/2
	love.graphics.setColor(color)
	
	--don't draw if off the screen:
	if x > (self.x + self.width) or (x + structSize) < self.x or y > (self.y + self.height) or (y + structSize) < self.y then
		return
	end
	
	local img = struct.img
	if img == nil then
		img = images["defaultStructure"]
	end
	love.graphics.draw(img, x, y, 0, structSize/img:getWidth(), structSize/img:getHeight())
end

-- ====================================================

function MapPanel:getWallEndPoints(x, y, orient)
	local a 
	local b 
	if orient == 0 then
		a = {x = x + HEX_RATIO*self.tileWidth, y = y}
		b = {x = x + (1-HEX_RATIO)*self.tileWidth, y = y}
	elseif orient == 1 then
		a = {x = x + (1-HEX_RATIO)*self.tileWidth, y = y}
		b = {x = x + (1+HEX_RATIO)*self.tileWidth, y = y + self.tileHeight/2}
	elseif orient == 2 then
		a = {x = x + (1+HEX_RATIO)*self.tileWidth, y = y + self.tileHeight/2}
		b = {x = x + (1-HEX_RATIO)*self.tileWidth, y = y + self.tileHeight}
	elseif orient == 3 then
		a = {x = x + (1-HEX_RATIO)*self.tileWidth, y = y + self.tileHeight}
		b = {x = x + HEX_RATIO*self.tileWidth, y = y + self.tileHeight}
	elseif orient == 4 then
		a = {x = x + HEX_RATIO*self.tileWidth, y = y + self.tileHeight}
		b = {x = x - self.tileWidth*HEX_RATIO, y = y + self.tileHeight/2}
	elseif orient == 5 then
		a = {x = x - self.tileWidth*HEX_RATIO, y = y + self.tileHeight/2}
		b = {x = x + HEX_RATIO*self.tileWidth, y = y}
	end
	
	return {a = a, b = b}
end

-- ====================================================

function MapPanel:drawWall(wallType, orient, x, y, color, hp, percentOpen)
	love.graphics.setColor(color)
	love.graphics.setLineWidth(wallType.HAXLINEWIDTH * self.zoom)
	local endPoints = self:getWallEndPoints(x, y, orient)
	local a = endPoints.a
	local b = endPoints.b
	if percentOpen == nil or percentOpen == 0 then
		--this is the default:
		love.graphics.line(a.x, a.y, b.x, b.y)
	else
		local angle = angleTo(a, b)
		local wallLength = distance(a, b)
		local factor = 0.2 + 0.3 * (1-percentOpen)
		local temp = {x = a.x + wallLength*factor*math.cos(angle), y = a.y + wallLength*factor*math.sin(angle)}
		love.graphics.line(a.x, a.y, temp.x, temp.y)
		temp = {x = b.x - wallLength*factor*math.cos(angle), y = b.y - wallLength*factor*math.sin(angle)}
		love.graphics.line(temp.x, temp.y, b.x, b.y)
	end
end

-- ====================================================

function MapPanel:drawTransition(trans)
	--if trans.wall == nil and not trans.isEdgeOfBase then
	--	return
	--end
	local tile = trans.a
	local orient = trans.a:getOrientationOfTransition(trans)
	if orient == -1 then
		orient = trans.b:getOrientationOfTransition(trans)
		tile = trans.b
	end
	local x = self.x + (tile.x - self.topLeft.x) * self.tileWidth
	local y = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2)
	local coords = self:getWallEndPoints(x, y, orient)
	
	--don't draw if off the screen:
	if math.min(coords.a.x, coords.b.x) > (self.x + self.width) or math.max(coords.a.x, coords.b.x) < self.x or math.min(coords.a.y, coords.b.y) > (self.y + self.height) or math.max(coords.a.y, coords.b.y) < self.y then
		return
	end
	
	--basic outline:
	love.graphics.setColor(unpack(colors["gray"]))
	love.graphics.setLineWidth(1)
	love.graphics.line(coords.a.x, coords.a.y, coords.b.x, coords.b.y)
	--selection/highlighting:
	if trans.a.isHighlighted or trans.b.isHighlighted then
		love.graphics.setColor({255, 255, 0, 140})
		love.graphics.setLineWidth(8 * self.zoom)
		love.graphics.line(coords.a.x, coords.a.y, coords.b.x, coords.b.y)
	end
	--walls:
	if trans.wall ~= nil then
		local col = colors["blue"]
		if trans.wall.wallType.name == "Gate" then
			if trans.wall:isBroken() then
				col = colors["black"]
			else
				col = colors["brown"]
			end
		end
		self:drawWall(trans.wall.wallType, orient, x, y, col, trans.wall.hp / trans.wall.wallType.hp, trans.wall:getPercentOpen())
	end
end

-- ====================================================

function MapPanel:drawTower(towerType, tile, orient, color)
	local tileX = self.x + (tile.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
	local tileY = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2) + self.tileHeight/2
	local x = tileX + MapVertice.getOffset(orient).x*self.tileWidth
	local y = tileY + MapVertice.getOffset(orient).y*self.tileHeight
	if color == nil then
		if tableContains(villageTowerTypes, towerType) then
			love.graphics.setColor(colors["brown"])
		else
			love.graphics.setColor(colors["blue"])
		end
	else
		love.graphics.setColor(color)
	end
	local size = 10*self.zoom
	
	--don't draw if off the screen:
	if (x - size/2) > (self.x + self.width) or (x + size/2) < self.x or (y - size/2) > (self.y + self.height) or (y + size/2) < self.y then
		return
	end
	
	love.graphics.circle("fill", x, y, size)
	
	--img
	if towerType.mapImg ~= nil then
		love.graphics.draw(towerType.mapImg, x - size/2, y - size/2, 0, size/towerType.mapImg:getWidth(), size/towerType.mapImg:getHeight())
	end
end

-- ====================================================

function MapPanel:update(dt)
	local mouseX = love.mouse.getX()
	local mouseY = love.mouse.getY()
	--make sure mouse is in bounds:
	if mouseX < self.x or mouseX > self.x + self.width or mouseY < self.y or mouseY > self.y + self.height then
		self.mouseOverTile = nil
		return
	end
	local over = self:getTileForMouseCoords(mouseX, mouseY)
	self.mouseOverTile = over
	self.mouseOverVertice = self:getClosestVertice(over, mouseX, mouseY)
end

-- ====================================================

function MapPanel:mousepressed(x, y, button)
	--make sure click is in bounds:
	if x < self.x or x > self.x + self.width or y < self.y or y > self.y + self.height then
		return
	end
	
	--mouse wheel zooming
	if button == "wd" then
		self:adjustZoom(0.5)
		return
	elseif button == "wu" then
		self:adjustZoom(2.0)
		return
	end
	
	local tile = self:getTileForMouseCoords(x, y)
	
	--hax to print offsets of click
	--local tileX = self.x + (tile.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
	--local tileY = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2) + self.tileHeight/2
	--print(((x - tileX)/self.tileWidth) .. ", " .. ((y - tileY)/self.tileHeight))
	--end hax
	
	--clicking on towers:
	local selectedTower = nil
	local distanceHolder = {}
	local TOWER_SELECT_RANGE = 12
	local vert = self:getClosestVertice(tile, x, y, distanceHolder)
	if vert.tower ~= nil and distanceHolder.distance <= TOWER_SELECT_RANGE*self.zoom then
		selectedTower = vert.tower
	end
		
	--todo: do something based on UI mode
end

-- ====================================================

function MapPanel:getTileForMouseCoords(x, y)
	--tile clicked on is one whose center is closest to click area
	local rawX = (x - self.x) / self.tileWidth + self.topLeft.x
	local rawY = (y - self.y) / self.tileHeight + self.topLeft.y 
	local closest = nil
	local dist = -1
	for key, tile in pairs(self.map.tiles) do
		local d = distance(tile:getCenter(), {x=rawX, y=rawY})
		if closest == nil or d < dist then
			closest = tile
			dist  =d
		end
	end
	return closest
end

-- ====================================================

function MapPanel:getClosestVertice(tile, mouseX, mouseY, distanceHolder)
	--look at this tile's vertices, pick one closest to mouse coords
	local tileX = self.x + (tile.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
	local tileY = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2) + self.tileHeight/2
	local closest = nil
	local dist
	for key, vert in pairs(tile.vertices) do
		local vertX = tileX + MapVertice.getOffset(key).x * self.tileWidth
		local vertY = tileY + MapVertice.getOffset(key).y * self.tileHeight
		local d = distance({x = mouseX, y = mouseY}, {x = vertX, y = vertY})
		if closest == nil or d < dist then
			closest = vert
			dist = d
		end
	end
	if distanceHolder ~= nil then
		distanceHolder.distance = dist
	end
	return closest
end

-- ====================================================

function MapPanel:keypressed(key)
	--if key == "tab" then
	--	self.showExtraData = true
	--end
	--zoom controls:
	if key == "-" then
		self:adjustZoom(0.5)
	elseif key == "=" then
		self:adjustZoom(2.0)
	end
	--scroll controls:
	local scrollAmount = math.max(1, 1/self.zoom)
	if key == "right" then
		self.topLeft.x = self.topLeft.x + scrollAmount
	elseif key == "left" then
		self.topLeft.x = self.topLeft.x - scrollAmount
	elseif key == "down" then
		self.topLeft.y = self.topLeft.y + scrollAmount
	elseif key == "up" then
		self.topLeft.y = self.topLeft.y - scrollAmount
	end
end

-- ====================================================

function MapPanel:adjustZoom(factor)
	if (factor > 1 and (self.zoom*factor) > MAX_ZOOM) or (factor < 1 and (self.zoom*factor) < MIN_ZOOM) then
		return
	end
	
	--map coords at center of screen
	local centerX = self.topLeft.x + (self.width/2) / (self.tileWidth)
	local centerY = self.topLeft.y + (self.height/2) / self.tileHeight
	
	self.zoom = self.zoom * factor
	self.tileWidth = self.tileWidth * factor
	self.tileHeight = self.tileHeight * factor
	
	--reset top left based on center
	self.topLeft.x = round(centerX - (self.width/2) / self.tileWidth)
	self.topLeft.y = round(centerY - (self.height/2) / self.tileHeight)
end

-- ====================================================

function MapPanel:getTileCenter(tile)
	--return center of tile in x,y on screen
	local tileX = self.x + (tile.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
	local tileY = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2) + self.tileHeight/2
	return {x = tileX, y = tileY}
end

-- ====================================================