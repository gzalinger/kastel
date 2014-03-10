--place for static info about levels
-- NOTE: some level-related utility functions also live here


function initLevels()
	--called when game first starts
	levels = {}
	
	levels[1] = {
		id = 1,
		mapBlueprint = {
			width = 8, height = 8, defaultTerrainType = "plains",
			townHallLoc = {x = 4, y = 4},
			terrain = {},
			roads = {{x=0,y=1}, {x=1,y=1}, {x=1,y=2}, {x=2,y=3}}
		},
		initialResources = {gold = 1000, timber = 1000, stone = 500},
		initialPeasantPopulation = 6,
		initialStructures = { {structType="barracks",x=3,y=4} },
		initialVillageStructures = { {structType="tinyHamlet",x=5,y=3} },
		initialWallType = "fence",
		initialTowers = { {towerType="arrow", x=4, y=4, orientation=1} },
		wallGapOrientation = 3,
		restrictions = {
			structures = {"manor", "armory", "fletcher", "wizardTower", "cannoneer"},
			villageStructs = {},
			towers = {"cannon"},
			villageTowers = {},
			upgrades = {}
		},
		spawnPoints = {left = {x=0, y=1}, top = {x=6, y=0}, right = {x=7, y=5}, bottom = {x=3, y=7}},
		description = "Tutorial",
		isTutorial = false
	} --end level 1
	levels[2] = {
		id = 2,
		mapBlueprint = {
			width = 10, height = 10, defaultTerrainType = "plains",
			townHallLoc = {x = 7, y = 7},
			terrain = {{x=5,y=9,terrain="deepWater"}, {x=6,y=9,terrain="deepWater"}, {x=7,y=9,terrain="deepWater"}, {x=8,y=9,terrain="deepWater"}, {x=9,y=9,terrain="deepWater"}, {x=7,y=8,terrain="deepWater"}, {x=8,y=8,terrain="deepWater"},{x=9,y=8,terrain="deepWater"}, {x=9,y=7,terrain="deepWater"}, {x=9,y=6,terrain="deepWater"} },
			roads = {{x=4,y=7}, {x=3,y=6}, {x=2,y=6}, {x=1,y=6}, {x=0,y=6},   {x=7,y=5}, {x=7,y=4}, {x=6,y=4}, {x=5,y=3}, {x=5,y=2}, {x=5,y=1}, {x=4,y=1}, {x=4,y=0}}
		}, --end blueprint
		initialResources = {gold = 575, timber = 500, stone = 525},
		initialPeasantPopulation = 4,
		initialStructures = {},-- {structType="barracks", x=7, y=6} },
		initialVillageStructures = { {structType="tinyHamlet",x=6,y=8}, {structType="tinyHamlet",x=8,y=7}, {structType="woodlot",x=6,y=7} },
		initialWallType = "fence",
		initialTowers = {},
		wallGapOrientation = 3,
		restrictions = {
			structures = {"manor", "quarry"},--, "gatehouse"},
			villageStructs = {},
			towers = {},
			villageTowers = {},
			upgrades = {"footmenRegimentSize8"}
		},
		spawnPoints = {left = {x=0, y=6}, top = {x=4, y=0}, bottom = {x=1, y=9}},
		description = "Defend the Kingdom!",
		isTutorial = false
	} --end level 2
	-- ====================================================
	levels[3] = {
		id = 3,
		mapBlueprint = {width = 13, height = 13, defaultTerrainType = "plains",
			townHallLoc = {x=8,y=9},
			terrain = {{x=10, y=9, terrain="deepWater"}, {x=10, y=10, terrain="deepWater"}, {x=9, y=10, terrain="deepWater"}, {x=8, y=11, terrain="deepWater"}, {x=7, y=10, terrain="deepWater"}},
			roads = {{x=8,y=8}, {x=8,y=7}, {x=8,y=6}, {x=7,y=5}, {x=7,y=4}, {x=6,y=4}, {x=6,y=3}, {x=5,y=2}, {x=4,y=2}, {x=4,y=1}, {x=4,y=0},
					{x=7,y=9}, {x=6,y=9}, {x=5,y=8}, {x=4,y=8}, {x=3,y=7}, {x=2,y=7}, {x=1,y=6}, {x=0,y=6}}
		}, --end map blueprint
		initialResources = {gold = 1000, timber = 1000, stone = 1000},
		initialPeasantPopulation = 0,
		initialStructures = { {structType="barracks", x=9, y=8} },
		initialVillageStructures = {},
		initialWallType = "fence",
		initialTowers = { },--{towerType="arrow", x=9, y=8, orientation=0} },
		wallGapOrientation = 3,
		restrictions = {
			structures = {}, villageStructs = {}, towers = {}, villageTowers = {}, upgrades = {}
		},
		spawnPoints = {a = {x=4,y=0}, b = {x=0,y=6}},
		description = "foo",
		isTutorial = false
	} --end level 3
	-- ====================================================
	levels[4] = {
		id = 4,
		mapBlueprint = {width = 9, height = 9, defaultTerrainType = "plains",
			townHallLoc = {x=5, y=5},
			terrain = {},
			roads = {}
		},
		initialResources = {gold = 1000, timber = 1000, stone = 1000},
		initialPeasantPopulation = 0,
		wallGapOrientation = 3,
		restrictions = {
			structures = {}, villageStructs = {}, towers = {}, villageTowers = {}, upgrades = {}
		},
		spawnPoints = {a = {x=0, y=0}},
		description = "foo",
		isTutorial = false
	} --end level 4
	
	-- ====================================================
	--   SANDBOX LEVEL
	levels["sandbox"] = {
		id = -1,
		mapBlueprint = {width = 12, height = 12, defaultTerrainType = "plains",
			townHallLoc = {x = 6, y = 6},
			terrain = {},
			roads = {},
		},
		initialResources = {gold = 1000, timber = 1000, stone = 1000},
		initialPeasantPopulation = 5,
		initialStructures = {},
		initialVillageStructures = { {structType="tinyHamlet",x=5,y=6} },
		initialWallType = "fence",
		initialTowers = { },
		wallGapOrientation = 5,
		restrictions = {
			structures = {}, villageStructs = {}, towers = {}, villageTowers = {}, upgrades = {}
		},
		spawnPoints = {topleft = {x=2, y=0}, topRight = {x=11, y=1}, right = {x=0, y=7}, bottom = {x=7, y=11}},
		description = "Play as long as you like against gradually increasing monster attacks.",
		isTutorial = false
	}
	
	
	
	--post processing:
	for key, level in pairs(levels) do
		if level.dayDuration == nil then
			level.dayDuration = DEFAULT_DAY_DURATION
		end
		if level.nightDuration == nil then
			level.nightDuration = DEFAULT_NIGHT_DURATION
		end
	end
end

-- ====================================================