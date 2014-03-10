-- useful methods for the editor

EditorUtil = {}
EditorUtil.__index = EditorUtil

-- ====================================================

function EditorUtil.findLevelWithName(name)
	for key, level in pairs(levels) do
		if level.name == name then
			return level
		end
	end
	return nil
end

-- ====================================================

function EditorUtil.initLevel(name)
	--create a Level object with fields initialized
	--NOTE: does not init map blueprint
	local level = {
		name = name,
		id = 0,
		initialResources = {gold = 0, timber = 0, stone = 0},
		initialPeasantPopulation = 0,
		initialStructures = {},
		initialVillageStructures = {},
		initialTowers = {},
		initialWallType = "fence",
		wallGapOrientation = 0,
		restrictions = {
			structures = {},
			villageStructs = {},
			towers = {},
			villageTowers = {},
			upgrades = {}
		},
		spawnPoints = {},
		waves = {},
		description = "",
		isTutorial = false
	}
	return level
end

-- ====================================================

function EditorUtil.getAllLevelNames()
	local names = {}
	for key, level in pairs(levels) do
		table.insert(names, level.name)
	end
	return names
end

-- ====================================================

function EditorUtil.getBuildable(tbl)
	local list = {}
	for key, elt in pairs(tbl) do
		if elt.buildable then
			table.insert(list, elt)
		end
	end
	return list
end

-- ====================================================

function EditorUtil.getTableOfNames(tbl)
	local list = {}
	for key, elt in pairs(tbl) do
		table.insert(list, elt.name)
	end
	return list
end

-- ====================================================