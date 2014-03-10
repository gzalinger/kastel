-- proceudral monster generation for sandbox mode

AttackGenerator = {}
AttackGenerator.__index = AttackGenerator


function AttackGenerator.onLevelBegin()
	AttackGenerator.MAX_DAY = 5
	AttackGenerator.counter = 0
	AttackGenerator.nextSpawnAt = -1
end

-- ====================================================

function AttackGenerator.scheduleNextSpawn()
	local day = currentGame:getDay()
	if day > AttackGenerator.MAX_DAY then
		day = AttackGenerator.MAX_DAY
	end
	local isNight = currentGame:isNight()
	--special case for 1st day:
	if day == 1 and not isNight then
		AttackGenerator.nextSpawnAt = currentGame.level.dayDuration - currentGame:getTimeToday() + 1
		return
	end
	
	local min = 2
	local max = 8
	AttackGenerator.nextSpawnAt = math.random(min, max)
	if not isNight then
		AttackGenerator.nextSpawnAt = AttackGenerator.nextSpawnAt * 2
	end
end

-- ====================================================

function AttackGenerator.update(dt)
	if AttackGenerator.nextSpawnAt == -1 then
		AttackGenerator.scheduleNextSpawn()
	end
	
	AttackGenerator.counter = AttackGenerator.counter + dt
	if AttackGenerator.counter >= AttackGenerator.nextSpawnAt then
		AttackGenerator.counter = 0
		AttackGenerator.scheduleNextSpawn()
		AttackGenerator.makeSpawn()
	end
end

-- ====================================================

function AttackGenerator.makeSpawn()
	local day = currentGame:getDay()
	if day > AttackGenerator.MAX_DAY then
		day = AttackGenerator.MAX_DAY
	end
	local isNight = currentGame:isNight()
	--pick spawn point:
	local spawnPoint = AttackGenerator.getRandomSpawnPoint()
	
	local numMonsters = day
	if not isNight then
		numMonsters = math.ceil(numMonsters / 2)
	end
	
	--hax:
	local reg = Regiment.create(regimentTypes["goblins"], nil, numMonsters)
	currentGame:doSpawn(reg, spawnPoint)
end

-- ====================================================

function AttackGenerator.getRandomSpawnPoint()
	local points = {}
	for key, sp in pairs(currentGame.level.spawnPoints) do
		table.insert(points, sp)
	end
	local r = math.random(1, #points)
	return points[r]
end

-- ====================================================