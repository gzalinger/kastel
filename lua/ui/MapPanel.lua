--displays actual game map

MapPanel = {}
MapPanel.__index = MapPanel


function MapPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, MapPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.tileHeight = 80
	temp.tileWidth = temp.tileHeight * TILE_ASPECT_RATIO
	temp.zoom = 1.0
	temp.parent = parent
	temp.isPreview = false
	--center:
	local left = math.floor(round(currentGame.map.width/2) - (temp.width/2) / temp.tileWidth)
	local top = math.floor(round(currentGame.map.height/2) - (temp.height/2) / temp.tileHeight)
	temp.topLeft = {x = left, y = top} --map coord that the top left of UI shows
	
	temp:adjustZoom(0.5)
	return temp
end

-- ====================================================

function initMapPreview(h)
	--height is defined, width is adjusted to be proportional to actual map
	local w = h * ((currentGame.map.width * TILE_ASPECT_RATIO) / (currentGame.map.height + 0.5))
	local mapPanel = MapPanel.create(0, 0, w, h)
	mapPanel.isPreview = true
	--adjust zoom to make map tiles fit:
	local tileWidth = mapPanel.tileWidth * (currentGame.map.width + 2*HEX_RATIO)
	mapPanel:adjustZoom(mapPanel.width / tileWidth)
	mapPanel.topLeft.x = mapPanel.topLeft.x - HEX_RATIO
	mapPanel.topLeft.y = mapPanel.topLeft.y - 0.125
	return mapPanel
end

-- ====================================================

function MapPanel:draw()
	--background:
	love.graphics.setColor(unpack(colors["gray"]))
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	--tiles:
	--local tileWidth = self.width / (currentGame.map.width / 2 + 0.5)
	--local tileHeight = self.height / currentGame.map.height
	--draw each tile independently:
	for key, tile in pairs(currentGame.map.tiles) do
		if tile ~= ui.selectedTile and tile ~= ui.mouseOverTile then
			self:drawMapTile(tile)
		end
	end

	--draw this one last b/c it should be "on top":
	if ui.mouseOverTile ~= nil then
		self:drawMapTile(ui.mouseOverTile)
	end
	if ui.selectedTile ~= nil then
		self:drawMapTile(ui.selectedTile)
	end
	
	--transitions:
	for key, trans in pairs(currentGame.map.transitions) do
		self:drawTransition(trans)
	end
	
	--towers:
	for key, tower in pairs(currentGame.towers) do
		self:drawTower(tower.towerType, tower.location, tower.hp/tower.towerType.hp, nil, tower == ui.selectedTower, tower.buildProject)
	end
	
	--ghost tower (mouse over for 'new tower' mode:
	if (ui.mode == "newTower" or ui.mode == "newVillageTower") and ui.mouseOverVertice ~= nil then
		self:drawTower(ui.selectionData, ui.mouseOverVertice, 1, nil, false)
	end
	
	--regiments:
	for key, reg in pairs(currentGame.playerRegiments) do
		if reg:isDeployed() then
			self:drawRegiment(reg)
		end
	end
	for key, reg in pairs(currentGame.hostileRegiments) do
		self:drawRegiment(reg)
	end
	
	--projectiles:
	if currentGame.phase == "defend" then
		for key, proj in pairs(currentGame.projectiles) do
			self:drawProjectile(proj)
		end
	end
	
	--various & sundry animations:
	for key, anim in pairs(currentGame.animations) do
		anim:draw(self)
	end
	
	--HAX for edge-of-base
	--for key, vert in pairs(currentGame.map.vertices) do
	--	if vert.isEdgeOfBase then
	--		self:drawTower(nil, vert, 1.0, colors["purple"])
	--	end
	--end
	
	--border for preview:
	if self.isPreview then
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	end
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
	--love.graphics.rectangle("fill", x, y, self.tileWidth, self.tileHeight)
	love.graphics.polygon("fill", vertices)
	
	--if tile == ui.selectedTile or tile.isHighlighted then
	--	love.graphics.setColor(unpack(colors["yellow"]))
	--	love.graphics.setLineWidth(2)
	--else
		--not selected; thickness and colors still depends on phase
	--	if currentGame.phase == "build" or currentGame.phase == "autumn" then
	--		love.graphics.setColor(unpack(colors["dark_gray"]))
	--		love.graphics.setLineWidth(2)
	--	else
	--		love.graphics.setColor(unpack(colors["gray"]))
	--		love.graphics.setLineWidth(1)
	--	end
	--end
	--love.graphics.polygon("line", vertices)
	
	--draw structure:
	if tile.structure ~= nil then
		self:drawStructure(tile.structure, x, y)
	
		--employee slots:
		--[[
		if self.zoom >= 1 and tile.structure.employeeSlots ~= nil then
			local widgetSize = 5 * self.zoom
			local numWidgets = #tile.structure.employeeSlots
			local idx = 1
			for key, slot in pairs(tile.structure.employeeSlots) do
				local widX = x + self.tileWidth/2 + (idx - numWidgets/2 - 0.5)*2*(widgetSize + 2)
				local widY = y + self.tileHeight - widgetSize - 4*self.zoom
				EmployeeWidget.drawWidget(widX, widY, widgetSize, slot)
				idx = idx + 1
			end
		end
		--]]
		
		--build projects:
		if tile.structure.buildProject ~= nil then
			local img = images["construction_icon"]
			love.graphics.setColor(colors["white"])
			local iconSize = self.tileWidth * 0.6
			love.graphics.draw(img, x + self.tileWidth/2 - iconSize/2, y + self.tileHeight/2 - iconSize/2, 0, iconSize/img:getWidth(), iconSize/img:getHeight())
		end
	end
	--if tile.buildProject ~= nil then
	--	self:drawBuildProject(tile, x, y)
	--end
	
	--mouse over stuff:
	if ui.mouseOverTile == tile then
		if (ui.mode == "newStruct" or ui.mode == "springPlaceStruct" or ui.mode == "relocateVillageStruct" or ui.mode == "newVillageStruct") and (tile.structure == nil or (tile.structure.isVillageStruct and not tableContains(villageStructureTypes, ui.selectionData))) then
			local structType = ui.selectionData
			if ui.mode == "relocateVillageStruct" then
				structType = ui.selectionData.structType
			end
			self:drawStructureGhost(structType, x, y, colors["white"])
			--special case for gatehouse:
			if ui.selectionData.name == "Gatehouse" then
				self:drawWall(wallTypes["gate"], ui.selectionOrientation, x, y, colors["brown"])
			end
		--elseif ui.mode == "newVillageStruct" then
		--	self:drawStructureGhost(ui.selectionData, x, y, colors["white"])
		elseif ui.mode == "newWall" then
			self:drawWall(ui.selectionData, ui.selectionOrientation, x, y, colors["blue"])
		elseif (ui.mode == "moveRegiment" and tile.terrainType.passable) or (ui.mode == "attackWithRegiment" and tile.regiment ~= nil and not tile.regiment:isFriendly()) then
			love.graphics.setColor({255, 255, 255, 150})
			love.graphics.setLineWidth(8 * self.zoom)
			love.graphics.polygon("line", vertices)
		end
	end
	
	--rallypoint (show during build phase if rallypoint's home structure is selected):
	--[[
	if (tile.rallyPoint ~= nil and currentGame.phase == "build" and ui.selectedTile ~= nil and ui.selectedTile.structure == tile.rallyPoint)
		or (ui.mode == "changeRally" and (ui.mouseOverTile == tile or tile.rallyPoint ~= nil)) then
		love.graphics.setColor(colors["blue"])
		local img = images["rallyPoint"]
		love.graphics.draw(img, x + self.tileWidth/8, y + self.tileHeight*0.375, 0, (self.tileWidth/2)/img:getWidth(), (self.tileHeight/2)/img:getHeight())
	end
	--]]
	--spawn point
	if tile.isSpawnPoint then
		love.graphics.setColor(colors["red"])
		local img = images["rallyPoint"]
		love.graphics.draw(img, x + self.tileWidth/8, y + self.tileHeight*0.375, 0, (self.tileWidth/2)/img:getWidth(), (self.tileHeight/2)/img:getHeight())
	end
	--murder attack bar:
	if tile.regiment ~= nil and tile.regiment.murderAttack ~= nil then
		local barWidth = self.tileWidth/2
		local barHeight = 5*self.zoom
		local barX = x + (self.tileWidth - barWidth)/2
		local barY = y + 6*self.zoom
		love.graphics.setColor(colors["red"])
		love.graphics.rectangle("fill", barX, barY, barWidth * tile.regiment.murderAttack.progress, barHeight)
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
	end
	
	--subtiles:
	if self.zoom >= 2 then
		self:drawSubtiles(tile, x + self.tileWidth/2, y + self.tileHeight/2)
	end
end -- end drawMapTile()

-- ====================================================

function MapPanel:drawStructure(struct, x, y)
	love.graphics.setColor(colors["white"])
	local structSize = self.tileHeight/2
	local img = struct.structType.img
	if img == nil then
		img = images["defaultStructure"]
	end
	love.graphics.draw(img, x + (self.tileWidth-structSize)/2, y + (self.tileHeight-structSize)/2, 0, structSize/img:getWidth(), structSize/img:getHeight())
	--health bar:
	if struct.hp < struct.structType.hp or ui.showExtraInfo then
		self:drawHealthBar(x + self.tileWidth/2, y + self.tileWidth*0.75, self.tileWidth/2, 4*self.zoom, struct.hp/struct.structType.hp)
	end
	--indicate dead regiments/gates:
	if ((struct.regiment ~= nil and struct.regiment:isDead()) or (struct.gate ~= nil and struct.gate:isBroken())) and currentGame.phase == "build" then
		love.graphics.setColor(colors["red"])
		love.graphics.setLineWidth(2)
		love.graphics.line(x + self.tileWidth*0.4, y + self.tileHeight*0.4, x + self.tileWidth*0.6, y + self.tileHeight*0.6)
		love.graphics.line(x + self.tileWidth*0.6, y + self.tileHeight*0.4, x + self.tileWidth*0.4, y + self.tileHeight*0.6)
	end
	--progress bar:
	if struct.militiaCallup ~= nil or struct.militiaDisbandment ~= nil or struct.buildProject ~= nil or #struct:getInProgressUpgrades() > 0 then
		local barX = x + self.tileWidth/4
		local barY = y + 3 * self.zoom
		local barWidth = self.tileWidth/2
		local barHeight = 4 * self.zoom
		local progress
		if struct.militiaCallup ~= nil then
			progress = struct.militiaCallup.progress / MILITIA_CALLUP_TIME
			love.graphics.setColor(colors["blue"])
		elseif struct.militiaDisbandment ~= nil then
			progress = struct.militiaDisbandment.progress / MILITIA_DISBAND_TIME
			love.graphics.setColor(colors["blue"])
		elseif struct.buildProject ~= nil then
			progress = struct.buildProject.age / struct.buildProject.structTypeOnCompletion.buildTime
			love.graphics.setColor(colors["brown"])
		elseif #struct:getInProgressUpgrades() > 0 then
			local up = struct:getInProgressUpgrades()[1]
			progress = 1 - up.timeRemaining / up.researchTime
			love.graphics.setColor(colors["purple"])
		end
		
		love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight)
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
	end
end

-- ====================================================

function MapPanel:drawStructureGhost(struct, x, y, color)
	--for structure types, not actual instances (e.g. when placing new structures
	love.graphics.setColor(color)
	local structSize = self.tileHeight/2
	local img = struct.img
	if img == nil then
		img = images["defaultStructure"]
	end
	love.graphics.draw(img, x + (self.tileWidth-structSize)/2, y + (self.tileHeight-structSize)/2, 0, structSize/img:getWidth(), structSize/img:getHeight())
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
	
	--health bar:
	if ui.showExtraInfo and ui.mode ~= "newStruct" and ui.mode ~= "newWall" then
		local centerX = math.min(a.x, b.x) + math.abs((a.x - b.x)/2)
		local centerY = math.min(a.y, b.y) + math.abs((a.y - b.y)/2)
		self:drawHealthBar(centerX, centerY, 18*self.zoom, 4*self.zoom, hp)
	end
end

-- ====================================================

function MapPanel:drawBuildProject(tile, x, y)
	if tile.buildProject.projectType == "newStruct" then
		self:drawStructureGhost(tile.buildProject.structType, x, y, colors["white"])
		--special case for gatehouse:
		if tile.buildProject.structType.name == "Gatehouse" then
			self:drawWall(wallTypes["gate"], tile.buildProject.orientation, x, y, colors["brown"])
		end
	end
	--hax: brown rectangle below structure
	love.graphics.setColor(colors["brown"])
	love.graphics.rectangle("fill", x + self.tileWidth/4, y + self.tileHeight*0.75, self.tileWidth/2, 4)
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
	
	--basic outline:
	if currentGame.phase == "build" or currentGame.phase == "autumn" then
		love.graphics.setColor(unpack(colors["dark_gray"]))
		love.graphics.setLineWidth(2)
	else
		love.graphics.setColor(unpack(colors["gray"]))
		love.graphics.setLineWidth(1)
	end
	love.graphics.line(coords.a.x, coords.a.y, coords.b.x, coords.b.y)
	--selection/highlighting:
	if ui.selectedTile == trans.a or ui.selectedTile == trans.b or trans.a.isHighlighted or trans.b.isHighlighted then
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
	--edge of base:
	--[[
	if trans.isEdgeOfBase then
		--love.graphics.setColor(colors["green"])
		love.graphics.setColor({0, 0, 255, 40})
		love.graphics.setLineWidth(10 * self.zoom)
		love.graphics.line(coords.a.x, coords.a.y, coords.b.x, coords.b.y)
		--drawDottedLine(coords.a.x, coords.a.y, coords.b.x, coords.b.y, 7)
	end
	--]]
	
	--special case: trappers:
	--if ui.selectedVertice ~= nil and ui.selectedVertice.tower ~= nil and ui.selectedVertice.tower.towerType == vilageTowerTypes["trapper"] and tableContains(trans:getVertices(), ui.selectedVertice) then
	if ui.selectedTower ~= nil and ui.selectedTower.towerType == villageTowerTypes["trapper"] and tableContains(trans:getVertices(), ui.selectedTower.location) then
		love.graphics.setColor(colors["brown"])
		love.graphics.setLineWidth(4 * self.zoom)
		drawDottedLine(coords.a.x, coords.a.y, coords.b.x, coords.b.y, 7)
	end
end

-- ====================================================

function MapPanel:drawRegiment(regiment)
	--hax for not having images for units:
	love.graphics.setLineWidth(1)
	for key, u in pairs(regiment.units) do
		local tile = u.location.parent
		local x = self.x + (tile.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
		local y = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2) + self.tileHeight/2
		local ux = x + (u.location:getXOffset() + u.locationOffset.x) * self.tileWidth
		local uy = y + (u.location:getYOffset() + u.locationOffset.y) * self.tileHeight
		local size = 13 * self.zoom
		--circle (default for units w/out images):
		if regiment.regimentType.img == nil then
			if regiment:isFriendly() then
				love.graphics.setColor(colors["blue"])
			else
				love.graphics.setColor(colors["red"])
			end
			love.graphics.circle("fill", ux, uy, 6*self.zoom)
			love.graphics.setColor(colors["black"])
			love.graphics.circle("line", ux, uy, 6*self.zoom)
		else
			--use image for unit
			love.graphics.setColor(colors["white"])
			love.graphics.draw(regiment.regimentType.img, ux - size/2, uy - size/2, 0, size/regiment.regimentType.img:getWidth(), size/regiment.regimentType.img:getHeight())
		end
		--trap:
		if u.trap ~= nil then
			local img = images["trap_icon"]
			love.graphics.setColor(colors["white"])
			love.graphics.draw(img, ux - size/2, uy - size/2, 0, size/img:getWidth(), size/img:getHeight())
		end
		--health bar:
		if ui.showExtraInfo and self.zoom >= 1.0 then
			local barLength = 10*self.zoom
			local hp = u.hp / u:maxHP()
			self:drawHealthBar(ux, uy - barLength/2 - 2*self.zoom, barLength, 2*self.zoom, hp)
		end
		--selection highlight:
		if regiment == ui.selectedRegiment then
			love.graphics.setColor(colors["yellow"])
			love.graphics.setLineWidth(1)
			love.graphics.circle("line", ux, uy, 6*self.zoom)
		end
	end
	--represent bannerman:
	local tile = regiment.bannerman.location.parent
	local x = self.x + (tile.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
	local y = self.y + (tile.y - self.topLeft.y) * self.tileHeight + (tile.x % 2)*(self.tileHeight/2) + self.tileHeight/2
	local ux = x + (regiment.bannerman.location:getXOffset() + regiment.bannerman.locationOffset.x) * self.tileWidth
	local uy = y + (regiment.bannerman.location:getYOffset() + regiment.bannerman.locationOffset.y) * self.tileHeight
	if regiment:isFriendly() then
		love.graphics.setColor(colors["blue"])
	else
		love.graphics.setColor(colors["red"])
	end
	local img = images["rallyPoint"]
	local size = 18 * self.zoom
	love.graphics.draw(img, ux, uy - size*0.75, 0, size/img:getWidth(), size/img:getHeight())
end
		
-- ====================================================

function MapPanel:drawHealthBar(x, y, w, h, hp)
	--NOTE: x and y are for center of bar
	if hp <= 0.25 then
		love.graphics.setColor(colors["red"])
	elseif hp <= 0.5 then
		love.graphics.setColor(colors["yellow"])
	else
		love.graphics.setColor(colors["green"])
	end
	love.graphics.rectangle("fill", x - w/2, y - h/2, w*hp, h)
end

-- ====================================================

function MapPanel:drawProjectile(proj)
	--find ui coords of center of proj's source
	local srcX = self.x + (proj.source.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
	local srcY = self.y + (proj.source.y - self.topLeft.y) * self.tileHeight + (proj.source.x % 2)*(self.tileHeight/2) + self.tileHeight/2
	
	local x = srcX + proj.position.x*self.tileWidth
	local y = srcY + proj.position.y*self.tileHeight
	
	--hax: small circle
	love.graphics.setColor(colors[proj.attack.projectileColor])
	love.graphics.circle("fill", x, y, proj.attack.projectileSize*self.zoom)
end

-- ====================================================

function MapPanel:drawTower(towerType, vertice, hp, color, isSelected, buildProject)
	local adj = vertice:getAdjacent()
	local tileX = self.x + (adj.tile.x - self.topLeft.x) * self.tileWidth + self.tileWidth/2
	local tileY = self.y + (adj.tile.y - self.topLeft.y) * self.tileHeight + (adj.tile.x % 2)*(self.tileHeight/2) + self.tileHeight/2
	local x = tileX + MapVertice.getOffset(adj.orient).x*self.tileWidth
	local y = tileY + MapVertice.getOffset(adj.orient).y*self.tileHeight
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
	love.graphics.circle("fill", x, y, size)
	
	--selection highlight:
	if isSelected then
		love.graphics.setColor(colors["yellow"])
		love.graphics.setLineWidth(1)
		love.graphics.circle("line", x, y, size + 1)
	end
	
	--img
	if towerType.mapImg ~= nil then
		love.graphics.draw(towerType.mapImg, x - size/2, y - size/2, 0, size/towerType.mapImg:getWidth(), size/towerType.mapImg:getHeight())
	end
	
	--health bar:
	if hp ~= nil and hp < 1.0 or ui.showExtraInfo then
		self:drawHealthBar(x, y + 8*self.zoom + 3, 10*self.zoom, 3*self.zoom, hp)
	end
	
	--buildProject:
	if buildProject ~= nil then
		local img = images["construction_icon"]
		love.graphics.setColor(colors["white"])
		love.graphics.draw(img, x - size, y - size, 0, 2*size/img:getWidth(), 2*size/img:getHeight())
		--progress bar:
		local barWidth = 2*size + 2*self.zoom
		local barHeight = 3 * self.zoom
		local progress = buildProject.age / buildProject.towerTypeOnCompletion.buildTime
		love.graphics.setColor(colors["brown"])
		love.graphics.rectangle("fill", x - barWidth/2, y - size - 2 - barHeight, barWidth * progress, barHeight)
		love.graphics.setColor(colors["black"])
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", x - barWidth/2, y - size - 2 - barHeight, barWidth, barHeight)
	end
end

-- ====================================================

function MapPanel:drawSubtiles(tile, centerX, centerY)
	--draw all subtiles of this MapTile
	love.graphics.setColor(0, 0, 0, 20)
	local size = 6 * self.zoom
	for key, sub in pairs(tile.subtiles) do
		love.graphics.circle("fill", centerX + sub:getXOffset()*self.tileWidth, centerY + sub:getYOffset()*self.tileHeight, size)
		--draw coords of each subtile:
		--[[
		love.graphics.setColor(colors["black"])
		love.graphics.setFont(fonts["font10"])
		local txt = sub.x .. "," .. sub.y
		love.graphics.print(txt, centerX + sub:getXOffset()*self.tileWidth - fonts["font10"]:getWidth(txt)/2, centerY + sub:getYOffset()*self.tileHeight)
		love.graphics.setColor(0, 0, 0, 20)
		--]]
	end
end

-- ====================================================

function MapPanel:update(dt)
	local mouseX = love.mouse.getX()
	local mouseY = love.mouse.getY()
	--make sure mouse is in bounds:
	if mouseX < self.x or mouseX > self.x + self.width or mouseY < self.y or mouseY > self.y + self.height then
		ui:setMouseOverTile(nil)
		return
	end
	local over = self:getTileForMouseCoords(mouseX, mouseY)
	ui:setMouseOverTile(over)
	ui:setMouseOverVertice(self:getClosestVertice(over, mouseX, mouseY))
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
	
	--clicking on units:
	local selectedRegiment
	local subtile = self:getSubtileForMouseCoords(x, y)
	if subtile.unit ~= nil then
		selectedRegiment = subtile.unit.parent
	end	
	
	if ui.mode == "default" then
		if button == "l" then
			if selectedTower ~= nil then
				ui:selectTower(selectedTower)
			elseif selectedRegiment ~= nil then
				ui:selectRegiment(selectedRegiment)
			else
				ui:selectTile(tile)
			end
		elseif button == "r" then
			--cancel new structs:
			if tile.buildProject ~= nil and tile.buildProject.projectType == "newStruct" then
				currentGame:cancelBuildProject(tile)
			--move friendly regiments:
			elseif ui.selectedRegiment ~= nil and ui.selectedRegiment:isFriendly() and not ui.selectedRegiment:isEngineer() then
				if subtile.unit == nil then
					currentGame:movePlayerRegiment(ui.selectedRegiment, subtile)
				else
					--todo: order regiment to attack
				end
			--set rally point
			elseif currentGame.phase == "build" and ui.selectedTile.structure.rallyPoint ~= nil then
				ui.selectedTile.structure.rallyPoint.rallyPoint = nil
				ui.selectedTile.structure.rallyPoint = tile
				tile.rallyPoint = ui.selectedTile.structure
			end
		end
	elseif ui.mode == "newStruct" then
		if button == "l" then
			currentGame:buildNewStruct(ui.selectionData, tile)
			ui:setMode("default")
			--update control panel:
			if tile == ui.selectedTile then
				currentPanel:catchEvent("resetControlPanel")
			end
		elseif button == "r" then
			ui:setMode("default")
		end
	elseif ui.mode == "newVillageStruct" then
		if button == "l" then
			currentGame:buildNewVillageStruct(ui.selectionData, tile)
			ui:setMode("default")
		elseif button == "r" then
			ui:setMode("default")
		end
	elseif ui.mode == "newWall" then
		if button == "l" then
			currentGame:buildNewWall(ui.selectionData, ui.selectionOrientation, tile)
			ui:setMode("default")
		end
	elseif ui.mode == "newTower" then
		if button == "l" then
			currentGame:buildNewTower(ui.selectionData, ui.mouseOverVertice)
			ui:setMode("default")
		end
	elseif ui.mode == "newVillageTower" then
		if button == "l" then
			currentGame:buildNewVillageTower(ui.selectionData, ui.mouseOverVertice)
			ui:setMode("default")
		end
	elseif ui.mode == "changeRally" then
		if button == "l" then
			if tile.rallyPoint == nil then
				ui.selectedTile.structure.rallyPoint.rallyPoint = nil
				ui.selectedTile.structure.rallyPoint = tile
				tile.rallyPoint = ui.selectedTile.structure
			end
			ui:setMode("default")
		end
	elseif ui.mode == "moveRegiment" then
		--currentGame:movePlayerRegiment(ui.selectedTile.regiment, tile)
		currentGame:movePlayerRegiment(ui.selectedRegiment, subtile)
		ui:setMode("default")
	elseif ui.mode == "attackWithRegiment" then
		currentGame:initMelee(ui.selectedTile.regiment, tile.regiment)
		ui:setMode("default")
	elseif ui.mode == "targetSpell" then
		ui.selectionData:cast(tile)
		ui:setMode("default")
	elseif ui.mode == "autumn" then
		if button == "l" then
			currentGame:selectTileForAutumn(tile)
		end
	elseif ui.mode == "springPlaceStruct" then
		if button == "l" then
			currentGame:reconstituteVillageStruct(ui.selectionData, tile)
		else
			ui:setMode("spring")
		end
	elseif ui.mode == "relocateVillageStruct" then
		if button == "l" then
			currentGame:relocateVillageStructTo(ui.selectionData, tile)
		end
	elseif ui.mode == "pickMilitiaCallup" then
		if button == "l" then 
			--make sure tile is valid:
			if tile:getOrientationOfVertice(ui.selectedTower.location) ~= -1 and tile.structure ~= nil and tile.structure:countEmployees() > 0 and tile.regiment == nil and tile.structure.militiaDisbandment == nil then
				currentGame:callupMilitia(tile, ui.selectedTower)
			end
		end
	end
end

function MapPanel:mousereleased(x, y, button)
	--todo
end

-- ====================================================

function MapPanel:getTileForMouseCoords(x, y)
	--tile clicked on is one whose center is closest to click area
	local rawX = (x - self.x) / self.tileWidth + self.topLeft.x
	local rawY = (y - self.y) / self.tileHeight + self.topLeft.y 
	local closest = nil
	local dist = -1
	for key, tile in pairs(currentGame.map.tiles) do
		local d = distance(tile:getCenter(), {x=rawX, y=rawY})
		if closest == nil or d < dist then
			closest = tile
			dist  =d
		end
	end
	return closest
end

-- ====================================================

function MapPanel:getSubtileForMouseCoords(x, y)
	local tile = self:getTileForMouseCoords(x, y)
	local tileCenter = self:getTileCenter(tile)
	local closest = nil
	local dist
	for key, subtile in pairs(tile.subtiles) do
		local d = distance({x = x, y = y}, {x = tileCenter.x + subtile:getXOffset()*self.tileWidth, y = tileCenter.y + subtile:getYOffset()*self.tileHeight})
		if closest == nil or d < dist then
			closest = subtile
			dist = d
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

function MapPanel:keyreleased(key)
	--if key == "tab" then
	--	self.showExtraData = false
	--end
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

function MapPanel:catchEvent(event)
	--do nothing
end

-- ====================================================