require "lua/LinkedList"
require "lua/Game"
require "lua/Statics"
require "lua/Map"
require "lua/Structure"
require "lua/ui/UI"
require "lua/Animation"
require "lua/Wall"
require "lua/Regiment"
require "lua/Fight"
require "lua/IDAStar"
require "lua/MonsterAI"
require "lua/Projectile"
require "lua/OrderedList"
require "lua/Spell"
require "lua/Upgrade"
require "lua/CheatManager"
require "lua/Peasant"
require "lua/Trap"
require "lua/Tower"
require "lua/Tutorial"
require "lua/AttackGenerator"
require "lua/EngineerJob"
require "lua/Formation"
require "lua/RegimentMoveManager"
-- ---------------------
require "lua/ui/TextButton"
require "lua/ui/GamePanel"
require "lua/ui/MapPanel"
require "lua/ui/Menu"
require "lua/ui/BottomPanel"
require "lua/ui/StructurePalette"
require "lua/ui/ControlPanel"
require "lua/ui/EndLevelPanel"
require "lua/ui/SpellButtonPanel"
require "lua/ui/MarketPanel"
require "lua/ui/EmployeeControlPanel"
require "lua/ui/ProjectedWheatWidget"
require "lua/ui/TopPanel"
require "lua/ui/AutumnPanel"
require "lua/ui/Popup"
require "lua/ui/WarehouseViewer"
require "lua/ui/SpringBuildPanel"
require "lua/ui/LevelPreviewPanel"
require "lua/ui/TutorialPanel"
-- ---------------------
require "content/Levels"


function love.load()
	setStatics(false)
	initLevels()
	ui = UI.create()
	currentPanel = Menu.create()
end

-- ====================================================

function love.draw()
	love.graphics.setBackgroundColor(255, 255, 255)	
	currentPanel:draw()
end

-- ====================================================

function love.update(dt)
	currentPanel:update(dt)
	if currentGame ~= nil then
		currentGame:update(dt)
	end
end

-- ====================================================

function love.mousepressed(x, y, button) 
	currentPanel:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	currentPanel:mousereleased(x, y, button)
end

-- ====================================================

function love.keypressed(key)
	if key == "q" then
		love.event.push("quit")
	end
	
	currentPanel:keypressed(key)
end

function love.keyreleased(key)
	currentPanel:keyreleased(key)
end

-- ====================================================
--[[
function newGame()
	currentGame = Game.create(levels[1])
	ui:reset()
	currentPanel = GamePanel.create()
end
--]]
-- ====================================================

function nextLevel(level)
	currentGame = Game.create(level)
	ui:reset()
	--currentPanel = GamePanel.create()
	currentPanel = LevelPreviewPanel.create()
end

-- ====================================================

function endLevel()
	--currentPanel = EndLevelPanel.create(levels[currentGame.level.id + 1])
	nextLevel(levels[currentGame.level.id + 1])
end

-- ====================================================

function endGame()
	currentPanel = Menu.create()
	currentGame = nil
	ui:reset()
end

-- ====================================================