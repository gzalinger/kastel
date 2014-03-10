--

function setStatics(isEditor)
	-- CONSTANTS --
	TILE_ASPECT_RATIO = 1.05 --width to height
	HEX_RATIO = 0.15
	MAX_ZOOM = 4
	MIN_ZOOM = 0.25
	
	RECYCLE_RATE = 0.75 --for resource (in general for any purchase)
	WOODLOT_TIMBER_PER_WAVE = 50
	QUARRY_STONE_PER_WAVE = 40
	
	BUY_TIMBER_AMOUNT = 25
	TIMBER_BUY_COST = 2.0 --gold per timber
	SELL_TIMBER_AMOUNT = 25
	TIMBER_SELL_RATE = 1.0 -- gold per timber sold
	BUY_STONE_AMOUNT = 25
	STONE_BUY_COST = 4.0
	SELL_STONE_AMOUNT = 25
	STONE_SELL_RATE = 0.4
	
	RELOCATION_GOLD_COST = 15
	RELOCATION_TIMBER_COST = 15
	
	MILITIA_CALLUP_TIME = 4.0
	MILITIA_DISBAND_TIME = 8.0
	
	DEFAULT_DAY_DURATION = 30.0
	DEFAULT_NIGHT_DURATION = 30.0
	
	ENGINEER_WORK_TO_REPAIRED_HP = 2.5
	
	local path = "images/"
	
	-- CONTENT --
	terrainTypes = {
		plains = {name = "Plains", passable = true, color = {r = 143, g = 188, b = 143}, moveRates = {foot = 1.0, horse = 1.0, vehicle = 1.0}},
		deepWater = {name = "Deep Water", passable = false, color = {r = 0, g = 0, b = 128}, moveRates = {foot = 0, horse = 0, vehicle = 0}},
		road = {name = "Road", passable = true, color = {r = 255, g = 211, b = 155}, moveRates = {foot = 1.5, horse = 1.5, vehicle = 2.0}}
	}
	structureTypes = {
		townhall = {name = "Town Hall", buildable = false, goldCost = 0, timberCost = 0, stoneCost = 0, popCost = 0, hp = 500, wheatStorage = 4, defenseType = "woodStructure", defenseLevel = 2, popAdded = 1, regimentCapIncrease = 1, upgrade = "manor", upgrades = {"wallsStockade"}, regimentType = "engineer", regimentSize = 2, img = love.graphics.newImage(path .. "townhall.png")},
		manor = {name = "Manor Hall", buildable = false, goldCost = 150, timberCost = 50, stoneCost = 25, popCost = 2, buildTime = 15, hp = 700, wheatStorage = 6, defenseType = "woodStructure", defenseLevel = 2, regimentCapIncrease = 1, upgrades = {"wallsStone"}, regimentType = "engineer", regimentSize = 3, img = love.graphics.newImage(path .. "manor.png")},
		--woodlot = {name = "Woodlot", shortcut = "w", buildable = true, goldCost = 25, timberCost = 0, stoneCost = 0, popCost = 2, hp = 250, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage("images/woodlot.png")},
		--quarry = {name = "Quarry", shortcut = "u", buildable = true, goldCost = 25, timberCost = 50, stoneCost = 0, popCost = 3, hp = 250, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage("images/quarry.png")},
		barracks = {name = "Barracks", shortcut = "b", buildable = true, goldCost = 50, timberCost = 25, stoneCost = 25, popCost = 3, buildTime = 20, hp = 400, defenseType = "stoneStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "barracks.png"), regimentType = "footmen", upgrades = {"footmenRegimentSize6", "footmenRegimentSize8", "footmenRegimentSize10"} },
		house = {name = "House", shortcut = "h", buildable = true, goldCost = 20, timberCost = 50, stoneCost = 0, popCost = 0, hp = 200, buildTime = 8, defenseType = "woodStructure", defenseLevel = 1, popAdded = 3, img = love.graphics.newImage(path .. "house.png")},
		gatehouse = {name = "Gatehouse", shortcut = "g", buildable = true, goldCost = 75, timberCost = 25, stoneCost= 50, popCost = 2, buildTime = 10, hp = 450, defenseType = "stoneStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "gatehouse.png")},
		cannoneer = {name = "Cannoneer", shortcut = "c", buildable = true, goldCost = 75, timberCost = 50, stoneCost = 0, popCost = 3, buildTime = 20, hp = 300, defenseType = "woodStructure", defenseLevel = 2, prereqs = {"manor"}, img = love.graphics.newImage(path .. "cannoneer.png")},
		fletcher = {name = "Fletcher", shortcut = "f", buildable = true, goldCost = 50, timberCost = 75, stoneCost = 0, popCost = 2, buildTime = 12, hp = 300, defenseType = "woodStructure", defenseLevel = 2, prereqs = {"manor"}, img = love.graphics.newImage(path .. "fletcher.png")},
		armory = {name = "Armory", shortcut = "a", buildable = true, goldCost = 75, timberCost = 25, stoneCost = 0, popCost = 2, buildTime = 12, hp = 350, defenseType="woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "armory.png"), upgrades = {"footmenArmor"}},
		wizardTower = {name = "Wizard Tower", shortcut = "z", buildable = true, goldCost= 125, timberCost = 50, stoneCost = 25, popCost = 1, buildTime = 15, hp = 300, defenseType = "woodStructure", defenseLevel = 2, prereqs = {"manor"}, spell = "lightningBolt", img = love.graphics.newImage(path .. "wizard_tower.png")},
		granary = {name = "Granary", shortcut = "r", buildable = true, goldCost = 50, timberCost = 60, stoneCost = 0, popCost = 1, buildTime = 10, hp = 350, wheatStorage = 12, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "granary.png")},
		--warehouse = {name = "Warehouse", shortcut = "w", buildable = true, goldCost = 50, timberCost= 75, stoneCost = 1, popCost = 1, buildTime = 10, hp = 400, storageSpace = 5, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "warehouse.png")},
		--shelter = {name = "Shelter", buildable = true, goldCost = 75, timberCost = 50, stoneCost = 0, popCost = 1, buildTime = 10, hp = 350, shelterSpace = 6, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "shelter.png")},
		engineerHall = {name = "Engineers Hall", buildable = true, goldCost = 150, timberCost = 50, stoneCost = 0, popCost = 2, peasantPopCost = 3, buildTime = 20, hp = 300, defenseType = "woodStructure", defenseLevel = 2, regimentType = "engineer", regimentSize = 3},
		rubble = {name = "Rubble", buildable = false, goldCost = 0, timberCost = 0, stoneCost = 0, popCost = 0, hp = 1, img = love.graphics.newImage(path .. "rubble.png")}
	}
	villageStructureTypes = {
		tinyHamlet = {name = "Tiny Hamlet", buildable = true, maxPopulation = 6, maxBread = 0.4, peasanProductionRate = 0.03, goldCost = 25, timberCost = 40, stoneCost = 0, buildTime = 6, hp = 200, storageCost = {gold = 10, timber = 15, stone = 0, space = 1}, defenseType = "woodStructure", defenseLevel = 2, upgrade = "smallHamlet", img = love.graphics.newImage(path .. "tinyHamlet.png")},
		smallHamlet = {name = "Small Hamlet", buildable = false, maxPopulation = 9, maxBread = 0.7, peasantProductionRate = 0.045, goldCost = 15, timberCost = 5, stoneCost = 0, buildTime = 8, hp = 220, storageCost = {gold = 15, timber = 20, stone = 0, space = 2}, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "smallHamlet.png")},
		farm = {name = "Farm", buildable = true, goldCost = 20, timberCost = 10, stoneCost = 0, buildTime = 6, hp = 100, employees = 4, production = {resourceType="wheat", rate = 0.5}, storageCost = {gold = 5, timber = 10, stone = 0, space = 1}, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "farm.png")},
		woodlot = {name = "Woodlot", buildable = true, goldCost = 20, timberCost = 0, stoneCost = 0, buildTime = 6, hp = 100, employees = 3, production = {resourceType="timber", rate=2.0}, storageCost = {gold = 5, timber = 10, stone = 0, space = 1}, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "woodlot.png")},
		quarry = {name = "Quarry", buildable = true, goldCost = 30, timberCost = 20, stoneCost = 0, buildTime = 6, hp = 120, employees = 4, production = {resourceType="stone", rate=0.7}, storageCost = {gold = 10, timber = 15, stone = 0, space = 1}, defenseType = "woodStructure", defenseLevel = 2, img = love.graphics.newImage(path .. "quarry.png")}
	}
	towerTypes = {
		arrow = {name = "Archer Tower", buildable = true, goldCost = 50, timberCost = 25, stoneCost = 0, buildTime = 8, popCost = 1, hp = 400, defenseType = "woodStructure", defenseLevel = 2, attack = {range = 3, cooldown = 1.0, speed = 3.0, damage = 15, damageType = "conventional", projectileSize = 3, projectileColor = "black"}, paletteImg = love.graphics.newImage(path .. "archertower.png"), upgrade = "arrow2", mapImg = love.graphics.newImage(path .. "arrow.png")},
		arrow2 = {name = "Archer Tower (Level 2)", buildable = false, goldCost = 75, timberCost = 25, stoneCost = 25, buildTime = 8, popCost = 1, hp = 600, defenseType = "stoneStructure", defenseLevel = 2, attack = {range = 4, cooldown = 0.9, damage = 22, damageType = "conventional", projectileSize = 3, projectileColor = "black"}, prereqs = {"fletcher"}, paletteImg = love.graphics.newImage(path .. "archertower.png"), mapImg = love.graphics.newImage(path .. "arrow.png")},
		cannon = {name = "Cannon Tower", buildable = true, goldCost = 125, timberCost = 15, stoneCost = 50, buildTime = 16, popCost = 2, hp = 500, defenseType = "stoneStructure", defenseLevel = 2, prereqs = {"cannoneer"}, attack = {range = 5, cooldown = 4.0, speed = 2.5, damage = 50, splashDamage = 0, damageType = "cannon", projectileSize = 5, projectileColor = "black"}, paletteImg = love.graphics.newImage(path .. "cannontower.png"), mapImg = love.graphics.newImage(path .. "cannon.png")},
		gatetower = {name = "Gate Tower", buildable = false, goldCost = 0, timberCost = 0, stoneCost = 0, popCost = 0, hp = 1}
	}
	villageTowerTypes = {
		--watchpost = {name = "Watchpost", buildable = true, goldCost = 10, timberCost = 10, stoneCost = 0, hp = 50, defenseType = "woodStructure", defenseLevel = 2},
		trapper = {name = "Trapper", buildable = true, numTraps = 4, trapDuration = 3.0, goldCost = 50, timberCost = 30, stoneCost = 0, buildTime = 6, hp = 50, defenseType = "woodStructure", defenseLevel = 2},
		militiaHQ = {name = "Militia HQ", buildable = true, goldCost = 75, timberCost = 25, stoneCost = 0, buildTime = 6, hp = 100, defenseType = "woodStructure", defenseLevel = 2}
	}
	wallTypes = {
		fence = {name = "Fence", buildable = true, goldCost = 5, timberCost = 10, stoneCost = 0, hp = 100, defenseType = "woodStructure", defenseLevel = 2, paletteImage = love.graphics.newImage(path .. "fence.png"), HAXLINEWIDTH = 2},
		stockade = {name = "Stockade", buildable = true, goldCost = 15, timberCost = 25, stoneCost = 0, hp = 250, defenseType = "woodStructure", defenseLevel = 2, paletteImage = love.graphics.newImage(path .. "stockade.png"), HAXLINEWIDTH = 4},
		stonewall = {name = "Stone Wall", buildable = true, goldCost = 25, timberCost = 5, stoneCost = 10, hp = 400, defenseType = "stoneStructure", defenseLevel = 2, paletteImage = love.graphics.newImage(path .. "stonewall.png"), HAXLINEWIDTH = 6},
		gate = {name = "Gate", buildable = false, goldCost = 0, timberCost = 0, stoneCost = 0, hp = 300, defenseType = "woodStructure", defenseLevel = 2, HAXLINEWIDTH = 7, repairCost = {goldCost = 10, timberCost = 10, stoneCost = 0}}
	}
	regimentTypes = {
		footmen = {name = "Footmen", isFriendly = true, defaultUnitsPerRegiment = 4, speed = 0.8, unitHP = 50, dps = 10.0, moveType = "foot", defenseType="armor", defenseLevel=1, damageType="conventional", capSpace = 1, replenishRate = 1, goldCost = 25, timberCost = 0, stoneCost = 0},
		militia = {name = "Militiamen", isFriendly = true, defaultUnitsPerRegiment = 1, speed = 0.7, unitHP = 30, dps = 7.0, moveType = "foot", defenseType = "none", defenseLevel = 1, damageType = "conventional", capSpace = 0, img = love.graphics.newImage(path .. "militia.png")},
		engineer = {name = "Engineers", isFriendly = true, defaultUnitsPerRegiment = 1, speed = 1.0, unitHP = 30, dps = 2.0, moveType = "foot", defenseType = "none", defenseLevel = 1, damageType = "conventional", capSpace = 0, workRate = 1.0},
		
		goblins = {name = "Goblins", isFriendly = false, defaultUnitsPerRegiment = 12, speed = 0.5, unitHP = 35, dps = 9.0, moveType = "foot", defenseType="none", defenseLevel=2, damageType="conventional", goldReward = 5, img = love.graphics.newImage(path .. "goblin.png")},
		orcs = {name = "Orcs", isFriendly = false, defaultUnitsPerRegiment = 5, speed = 0.4, unitHP = 45, dps = 12.0, moveType = "foot", defenseType = "armor", defenseLevel=2, damageType="conventional", goldReward = 12, img = love.graphics.newImage(path .. "orc.png")},
		wargs = {name ="Wargs", isFriendly = false, defaultUnitsPerRegiment = 3, speed = 0.85, unitHP = 40, murderDPS = 0.1, dps = 5.0, moveType = "horse", defenseType = "none", defenseLevel = 1, damageType = "conventional", goldReward = 10, img = love.graphics.newImage(path .. "warg.png")}
	}
	
	defenseTypes = {
		none = {conventional = 0, fire = 0, cannon = 0, magic = 0},
		armor = {conventional = 0.5, fire = 0.2, cannon = 0, magic = 0},
		magicResist = {conventional = 0, fire = 0, cannon = 0, magic = 0.75},
		fireResist = {conventional = 0, fire = 0.75, cannon = 0, magic = 0},
		woodStructure = {conventional = 0.6, fire = 0.4, cannon = 0.3, magic = 0.6},
		stoneStructure = {conventional = 0.8, fire = 0.9, cannon = 0.3, magic = 0.8}
	}
	defenseLevels = {}
	defenseLevels[1] = 0.5 --i.e. it only blocks half as much
	defenseLevels[2] = 1.0
	defenseLevels[3] = 1.5
	
	--locations within a hex where units stand (0,0 is at center, all number are in hexes [i.e. 0.5 is half a hex width or height])
	unitLocations = {}	
	unitLocations[1] = {x = 0.17, y = 0}
	unitLocations[2] = {x = -0.17, y = 0}
	unitLocations[3] = {x = 0, y = -0.17}
	unitLocations[4] = {x = 0.34, y = -0.17}
	unitLocations[5] = {x = -0.34, y = -0.17}
	unitLocations[6] = {x = 0, y = 0.17}
	unitLocations[7] = {x = 0.34, y = 0.17}
	unitLocations[8] = {x = -0.34, y = 0.17}
	unitLocations[9] = {x = 0.17, y = -0.34}
	unitLocations[10] = {x = -0.17, y = -0.34} 
	unitLocations[11] = {x = 0.17, y = 0.34} 
	unitLocations[12] = {x = -0.17, y = 0.34} 
	
	-- fight positions --
	NUM_FORWARD_FIGHT_POSITIONS = 3
	forwardFightPositions = {}
	--indices here are transition orientations:
	forwardFightPositions[0] = { {x = 0, y = -0.4},  {x = -0.2, y = -0.4}, {x = 0.2, y = -0.4} }
	forwardFightPositions[1] = { {x = 0.375, y = -0.2},  {x = 0.3, y = -0.35}, {x = 0.45, y = -0.05} }
	forwardFightPositions[2] = { {x = 0.375, y = 0.2},  {x = 0.3, y = 0.35}, {x = 0.45, y = 0.05} }
	forwardFightPositions[3] = { {x = 0, y = 0.4},  {x = -0.2, y = 0.4}, {x = 0.2, y = 0.4} }
	forwardFightPositions[4] = { {x = -0.375, y = 0.2}, {x = -0.45, y = 0.05}, {x = -0.3, y = 0.35} }
	forwardFightPositions[5] = { {x = -0.375, y = -0.2}, {x = -0.45, y = -0.05}, {x = -0.3, y = -0.35} }
	rearFightPositions = {}
	rearFightPositions[0] = { {x = -0.1, y = -0.25}, {x = 0.1, y = -0.25}, {x = -0.3, y = -0.25}, {x = 0.3, y = -0.25}, 
							{x = 0, y = -0.125}, {x = -0.2, y = -0.125}, {x = 0.2, y = -0.125}, 
							{x = -0.1, y = 0}, {x = 0.1, y = 0} }
	rearFightPositions[1] = { {x = 0.3, y = -0.05}, {x = 0.2, y = -0.2}, {x = 0.4, y = 0.1}, {x = 0.1, y = -0.35},
								 {x = 0.025, y = -0.2}, {x = 0.1, y = -0.05}, {x = 0.175, y = 0.1}, {x = -0.05, y = -0.35}, {x = 0.25, y = 0.25} }
	rearFightPositions[2] = { {x = 0.3, y = 0.05}, {x = 0.2, y = 0.2}, {x = 0.4, y = -0.1}, {x = 0.1, y = 0.35},
								 {x = 0.025, y = 0.2}, {x = 0.1, y = 0.05}, {x = 0.175, y = -0.1}, {x = -0.05, y = 0.35}, {x = 0.25, y = -0.25} }
	rearFightPositions[3] = { {x = -0.1, y = 0.25}, {x = 0.1, y = 0.25}, {x = -0.3, y = 0.25}, {x = 0.3, y = 0.25},
								{x = 0, y = 0.125}, {x = -0.2, y = 0.125}, {x = 0.2, y = 0.125}, 
								{x = -0.1, y = 0}, {x = 0.1, y = 0} }
	rearFightPositions[4] = { {x = -0.3, y = 0.05}, {x = -0.2, y = 0.2}, {x = -0.4, y = -0.1}, {x = -0.1, y = 0.35},
								 {x = -0.025, y = 0.2}, {x = -0.1, y = 0.05}, {x = -0.175, y = -0.1}, {x = 0.05, y = 0.35}, {x = -0.25, y = -0.25} }
	rearFightPositions[5] = { {x = -0.3, y = -0.05}, {x = -0.2, y = -0.2}, {x = -0.4, y = 0.1}, {x = -0.1, y = -0.35},
								 {x = -0.025, y = -0.2}, {x = -0.1, y = -0.05}, {x = -0.175, y = 0.1}, {x = 0.05, y = -0.35}, {x = -0.25, y = 0.25} }
	towerFrontFightPositions = {}
	towerFrontFightPositions[0] = { {x = -0.25, y = -0.32}, {x = -0.39, y = -0.29}, {x = -0.16, y = -0.42} }
	towerFrontFightPositions[1] = { {x = 0.25, y = -0.32}, {x = 0.39, y = -0.29}, {x = 0.16, y = -0.42} }
	towerFrontFightPositions[2] = { {x = 0.4, y = 0}, {x = 0.5, y = 0.09}, {x = 0.5, y = -0.09} }
	towerFrontFightPositions[3] = { {x = 0.25, y = 0.32}, {x = 0.39, y = 0.29}, {x = 0.16, y = 0.42} }
	towerFrontFightPositions[4] = { {x = -0.25, y = 0.32}, {x = -0.39, y = 0.29}, {x = -0.16, y = 0.42} }
	towerFrontFightPositions[5] = { {x = -0.4, y = 0}, {x = -0.5, y = 0.09}, {x = -0.5, y = -0.09} }
	towerRearFightPositions = {}
	towerRearFightPositions[0] = { {x = -0.3, y = -0.15}, {x = -0.11, y = -0.28},
									{x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0} }
	towerRearFightPositions[1] = { {x = 0.3, y = -0.15}, {x = 0.11, y = -0.28},
									{x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0} }
	towerRearFightPositions[2] = { {x = 0.35, y = 0.18}, {x = 0.35, y = -0.18},
									{x = 0.2, y = -0.09}, {x = 0.2, y = 0.09}, {x = 0.2, y = -0.27}, {x = 0.2, y = 0.27}, 
									 {x = 0.05, y = 0}, {x = 0.05, y = -0.18}, {x = 0.05, y = 0.18} }
	towerRearFightPositions[3] = { {x = 0.3, y = 0.15}, {x = 0.08, y = 0.28}, 
									{x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0} }
	towerRearFightPositions[4] = { {x = -0.3, y = 0.15}, {x = -0.11, y = 0.28},
									{x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0}, {x = 0, y = 0} }
	towerRearFightPositions[5] = { {x = -0.35, y = 0.16}, {x = -0.35, y = -0.16},
									{x = -0.2, y = -0.09}, {x = -0.2, y = 0.09}, {x = -0.2, y = -0.27}, {x = -0.2, y = 0.27}, 
									 {x = -0.05, y = 0}, {x = -0.05, y = -0.18}, {x = -0.05, y = 0.18} }
	
	

	--  MEDIA  --
	colors =	 {	black = {0, 0, 0},
					blue = {0, 0, 255},
					brown = {139, 69, 19},
					burleywood = {222, 184, 135},
					dark_blue = {0, 0, 170},
					dark_gray = {70, 70, 70},
					dark_green = {83, 134, 139},
					dark_red = {170, 0, 0},
					gold = {255, 185, 15},
					green = {0, 255, 0},
					gray = {150, 150, 150},
					ice = {3, 180, 204},
					light_gray = {220, 220, 220},
					purple = {138, 43, 226},
					red = {255, 0, 0},
					white = {255, 255, 255},
					yellow = {255, 255, 0}
					
	}
	fonts = 	{	default = love.graphics.newFont(14),
					font10 = love.graphics.newFont(10),
					font12 = love.graphics.newFont(12),
					font14 = love.graphics.newFont(14),
					font16 = love.graphics.newFont(16),
					font18 = love.graphics.newFont(18),
					font20 = love.graphics.newFont(20),
					font24 = love.graphics.newFont(24),
					font30 = love.graphics.newFont(30)
	}
	images =	{	rallyPoint = love.graphics.newImage(path .. "white_flag.png"),
					defaultStructure = love.graphics.newImage(path .. "defaultStruct.png"),
					defaultVillageStruct = love.graphics.newImage(path .. "defaultVillageStruct.png"),
					structureBuildButton = love.graphics.newImage(path .. "barracks.png"),
					villageStructureBuildButton = love.graphics.newImage(path .. "village_house.png"),
					towerBuildButton = love.graphics.newImage(path .. "archertower.png"),
					villageTowerBuildButton = love.graphics.newImage(path .. "village_tower.png"),
					lock = love.graphics.newImage(path .. "lock.png"),
					construction_icon = love.graphics.newImage(path .. "build_icon.png"),
					trap_icon = love.graphics.newImage(path .. "net.png")
	}
	
	if not isEditor then
		Spell.setStatics()
		Upgrade.setStatics()
		Formation.setStatics()
	end
end

-- ====================================================

function distance(a, b)
	return math.sqrt((a.x - b.x)*(a.x - b.x) + (a.y - b.y)*(a.y - b.y))
end

-- ====================================================

function countSteps(a, b)
	--counts "steps" between two tiles 
	--NOTE: THIS IS PROBABLY/MIGHT BE WRONG (but I don't think so)
	local dY = math.abs(a.y - b.y)
	local dX = math.abs(a.x - b.x)
	--print("(" .. a.x .. ", " .. a.y .. ") - (" .. b.x .. ", " .. b.y .. ") = " .. (dY + math.max(0, dX - dY)))
	return dY + math.max(0, dX - dY)
end

-- ====================================================

function findIntersectingTransition(target, source)
	--finds which transition would be "hit" by a line coming from 'source'
	local attackLine = {x1 = source.x + 1, y1 = source.y + 0.5, x2 = target.x + 1, y2 = target.y + 0.5}
	
	--case 1: horizontal attack line
	if target.y == source.y then
		if target.x > source.x then
			return target:getTransition(-2, 0)
		else
			return target:getTransition(2, 0)
		end
	--case 2: vertical attack line
	elseif target.x == source.x then
		if target.y > source.y then
			return target:getTransition(1, -1)
		else
			return target:getTransition(-1, 1)
		end
	--case 3:
	else
		for key, trans in pairs(target.transitions) do
			if doLineSegmentsIntersect(attackLine, trans:getLineSegment()) then
				return trans
			end
		end
	end
	return nil
end

-- ====================================================

function doesLineIntersectCompleteCover(target, source)
	local attackLine = {x1 = source.x + 1, y1 = source.y + 0.5, x2 = target.x + 1, y2 = target.y + 0.5}
	--test this against all complete cover transitions
	for key, cover in pairs(currentGame.map.completeCover) do
		if doLineSegmentsIntersect(attackLine, cover:getLineSegment()) then
			return true
		end
	end
	return false
end

-- ====================================================

function doLineSegmentsIntersect(a, b)
	--convert into 'y = mx + b' form
	local m = (a.y2 - a.y1)/(a.x2 - a.x1)
	local eqA = {m = m, b = a.y1 - m*a.x1}
	m = (b.y2 - b.y1)/(b.x2 - b.x1)
	local eqB = {m = m, b = b.y1 - m*b.x1}
	
	--handle case for vertical lines:
	local isAVertical = a.x1 == a.x2
	local isBVertical = b.x1 == b.x2
	if isAVertical and isBVertical then
		return a.x1 == b.x1
	end
	
	if not (isAVertical or isBVertical) then
		--find intersect:
		local x = (eqB.b - eqA.b) / (eqA.m - eqB.m)
		return x >= math.min(a.x1, a.x2) and x <= math.max(a.x1, a.x2) and x >= math.min(b.x1, b.x2) and x <= math.max(b.x1, b.x2)
	else
		local x --of vertical line
		local y --value of 'y' when the non-vertical line passes through the vertical line's 'x'
		if isAVertical then
			x = a.x1
			y = eqB.m * x + eqB.b
			return (y >= math.min(a.y1, a.y2) and y <= math.max(a.y1, a.y2)) and
					(x >= math.min(b.x1, b.x2) and x <= math.max(b.x1, b.x2))
		else
			x = b.x1
			y = eqA.m * x + eqA.b
			return (y >= math.min(b.y1, b.y2) and y <= math.max(b.y1, b.y2)) and
					(x >= math.min(a.x1, a.x2) and x <= math.max(a.x1, a.x2))
		end
	end
end

-- ====================================================

function round(d)
	local n = math.floor(d)
	local r = d - n
	if r >= 0.5 then
		return n + 1
	else
		return n
	end
end

-- ====================================================

function getAdjacent(pt)
	local adj = {
		{x = pt.x - 2, y = pt.y},
		{x = pt.x + 2, y = pt.y},
		{x = pt.x - 1, y = pt.y - 1},
		{x = pt.x - 1, y = pt.y + 1},
		{x = pt.x + 1, y = pt.y - 1},
		{x = pt.x + 1, y = pt.y + 1}
	}
	return adj
end

-- ====================================================

function removeFromTable(tbl, elt)
	local idx = -1
	for key, e in pairs(tbl) do
		if e == elt then
			idx = key
			break
		end
	end
	if idx ~= -1 then
		table.remove(tbl, idx)
	end
end

-- ====================================================

function angleTo(a, b)
	local dX = b.x - a.x
	local dY = b.y - a.y
	if dX == 0 then
		if dY < 0 then
			return - math.pi / 2
		else
			return math.pi / 2
		end
	end
	local theta = math.atan(dY / dX)
	if dX < 0 then 
		--no explanation why this is required but it makes it work correctly...
		theta = theta + math.pi
	end
	
	return theta
end

-- ====================================================

function getRealHexDistance(a, b)
	--finds x and y distance (in hex units) but accounts for how they're offset
	local x = b.x - a.x
	local ay = a.y + (a.x%2)*0.5
	local by = b.y + (b.x%2)*0.5
	local y = by - ay
	return {x = x, y = y}
end

-- ====================================================

function calculateDamageAfterDefense(damage, damageType, defenseType, defenseLevel)
	--NOTE: both defenseType and Level should be indices, not tables (or values) themselves
	local blocked = defenseTypes[defenseType][damageType] * defenseLevels[defenseLevel]
	if blocked > 1 then
		blocked = 1 --can't block more than 100% of damage
	end
	return damage * (1 - blocked)
end

-- ====================================================

function drawDottedLine(ax, ay, bx, by, numSegments)
	local lineLength = distance({x = ax, y = ay}, {x = bx, y = by})
	local angle = angleTo({x = ax, y = ay}, {x = bx, y = by})
	local segmentLength = lineLength / numSegments 
	local x1 = ax
	local y1 = ay
	for segmentNumber = 1, numSegments do
		x2 = x1 + math.cos(angle) * segmentLength
		y2 = y1 + math.sin(angle) * segmentLength
		if segmentNumber % 2 == 1 then
			love.graphics.line(x1, y1, x2, y2)
		end
		x1 = x2
		y1 = y2
	end
end

-- ====================================================

function tableContains(tbl, elt)
	for key, temp in pairs(tbl) do
		if temp == elt then
			return true
		end
	end
	return false
end

-- ====================================================
--[[
function getLastSpawn(wave)
	local last = nil
	for key, spawn in pairs(wave.spawns) do
		if last == nil or last.delay < spawn.delay then
			last = spawn
		end
	end
	return last
end
--]]
-- ====================================================