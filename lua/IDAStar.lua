-- file for holding everything pathfinding-related


--[[
	MODES (brainstorm)
1. "tiles" by tile, whole formations
	- only consider terrain and walls, not other regiments
	- don't consider shape of formation
2. "formation" subtiles, formations
	- subtile-level
	- consider other formations
	- look at shape of formation to make sure subtiles can be moved to by bannerman
3. "unit" subtiles, single unit (location)
	- single unit from within regiment
	- is blocked by fellow regiment-members
	- must stay in regiment (adjacent), but formation doesn't matter
4. "melee" single unit, combat
	- isn't navigating to location, instead is trying to get in combat with an enemy
	- otherwise the same as sigle unit (location)	
5. "tower" single unit, move towards subtile while ignoring some units

--]]

IDAStar = {}
IDAStar.__index = IDAStar


function IDAStar.findPath(params)
	--calculates path of moves from 'from' to 'to'
	local MAX_SEARCH_RANGE --will not search longer (deeper) than this
	if params.mode == "tile" then
		MAX_SEARCH_RANGE = 8
	else
		MAX_SEARCH_RANGE = 12
	end
		
	local startState = {g = 0, parent = nil} --universal part shared by all modes
	if params.mode == "tile" then
		startState.location = {x = params.from.x, y = params.from.y}
	else
		startState.subtile = params.from
	end
	
	local min = IDAStar.h(startState, params)
	--local closeEnough = math.max(min - MAX_SEARCH_RANGE, 0)
	local max = 30
	for depth = min, max do
		local queue = OrderedList.create()
		local trash = {}
		queue:add(startState, IDAStar.f(startState, params))
		
		local bestFinish = nil
		local bestFinishValue
		while queue.size > 0 do
			local state = queue:popLast()
			
			--case: found finish state:
			if IDAStar.isFinishState(state, params--[[, closeEnough--]]) then
				local stateF = IDAStar.f(state, params)
				if bestFinish == nil or stateF < bestFinishValue then
					bestFinish = state
					bestFinishValue = stateF
				end
			--case: not a finish state, add children to queue
			else
				for key, child in pairs(IDAStar.makeChildren(state, params)) do
					local childF = IDAStar.f(child, params)
					if not IDAStar.isStateInTrash(state, trash, params) and ((bestFinish == nil and childF <= depth) or (bestFinish ~= nil and childF <= bestFinishValue)) then
						queue:add(child, childF)
					end
				end
			end
			table.insert(trash, state)
		end
		
		if bestFinish ~= nil then
			local list = LinkedList.create()
			local temp = bestFinish
			while true do
				list:addFirst(temp)
				temp = temp.parent
				if temp == nil then
					break
				end
			end
			return list
		end
	end
end

-- ====================================================

function IDAStar.f(state, params)
	return state.g + IDAStar.h(state, params)
end

-- ====================================================

function IDAStar.h(state, params)
	if params.mode == "tile" then
		local min = nil
		for key, dest in pairs(params.destinations) do
			local temp = countSteps(state.location, dest)
			if min == nil or temp < min then
				min = temp
			end
		end
		return min
	elseif params.mode == "formation" or params.mode == "unit" or params.mode == "tower" then
		local dist = state.subtile:distanceTo(params.destination)
		local h = (math.abs(dist.x) + math.abs(dist.y)) / 2
		if params.mode == "tower" then
			h = h - 1 --b/c you only need to get adjacent to it
		end
		return h
	elseif params.mode == "melee" then
		--todo
		return nil
	end
	return nil --shouldn't happen
end

-- ====================================================

function IDAStar.isStateInTrash(state, trash, params)
	for key, trashState in pairs(trash) do
		if IDAStar.f(state, params) >= IDAStar.f(trashState, params) 
			and ((params.mode == "tile" and state.location.x == trashState.location.x and state.location.y == trashState.location.y) or (params.mode ~= "tile" and state.subtile == trashState.subtile)) 
			then
			
			return true
		end
	end
	return false
end

-- ====================================================

function IDAStar.makeChildren(state, params)
	local children = {}
	if params.mode == "tile" then
		for key, trans in pairs(currentGame.map:getTile(state.location.x, state.location.y).transitions) do
			local other = trans:getDest(state.location)
			if other.terrainType.passable and trans:isPassable() then --(params.isMonster or (trans:isPassable() and other.regiment == nil)) then
				local newState = {parent = state, g = state.g + 1/other.terrainType.moveRates[params.moveType], location = {x = other.x, y = other.y}}
				table.insert(children, newState)
			end
		end
	else --all subtile modes
		for key, adj in pairs(state.subtile:getAdjacent()) do
			local valid = true
			if params.mode == "unit" or params.mode == "tower" then
				local trans = state.subtile.parent:getTransitionTo(adj.parent)
				local vert = adj:getVertice()
				--make sure they can move to that subtile:
				if not adj.parent.terrainType.passable or (trans ~= nil and trans.wall ~= nil and not trans.wall:isPassable()) or (vert ~= nil and vert.tower ~= nil) then
					valid = false
				end
				if adj.unit ~= nil then
					--if params.mode == "formation" and adj.unit.parent ~= params.regiment then
					--	valid = false
					if params.mode == "unit" then
						valid = false
					elseif params.mode == "tower" and not tableContains(params.ignoreUnits, adj.unit) then
						valid = false
					end
				end
			elseif params.mode == "formation" then
				valid = IDAStar.formationCanMoveTo(state, adj, params)
			end
			
			if valid then
				local newState = {parent = state, g = state.g + 1/adj.parent.terrainType.moveRates[params.unit.regimentType.moveType], subtile = adj}
				table.insert(children, newState)
			end
		end
	end
	
	return children
end

-- ====================================================

function IDAStar.isFinishState(state, params)
	if params.mode == "tile" then
		for key, dest in pairs(params.destinations) do
			if state.location.x == dest.x and state.location.y == dest.y then
				return true
			elseif dest.regiment ~= nil and dest:isAdjacent(currentGame.map:getTile(state.location.x, state.location.y)) then
				return true
			end
		end
	elseif params.mode == "formation" or params.mode == "unit" then
		return state.subtile == params.destination
	elseif params.mode == "tower" then
		return params.destination:isAdjacentTo(state.subtile)
	elseif params.mode == "melee" then
		--todo
	end
	
	return false
end

-- ====================================================

function IDAStar.formationCanMoveTo(state, subtile, params)
	--validate that the entire formation can move here
	local dir = state.subtile:distanceTo(subtile)
	
	for key, unit in pairs(params.regiment.units) do
		local relToBannerman = params.regiment.bannerman.location:distanceTo(unit.location)
		local dest = state.subtile:getRelativeSubtile({x = dir.x + relToBannerman.x, y = dir.y + relToBannerman.y})
		local trans = unit.location.parent:getTransitionTo(dest)
		local vert = dest:getVertice()
		if not dest.parent.terrainType.passable or (trans ~= nil and not trans:isPassable()) or (dest.unit ~= nil and dest.unit.parent ~= params.regiment) or (vert ~= nil and vert.tower ~= nil) then
			return false
		end
	end
	return true
end

-- ====================================================