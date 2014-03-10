-- MAP EDITOR FOR KASTEL; USE THIS TO QUICKLY BUILD LEVELS

require("levels/EditorLevels")
require("../lua/Statics")
-- ---------------------
require("lua/MainMenu")
require("lua/TextButton")
require("lua/TextField")
require("lua/EditorUtil")
require("lua/MapBlueprintEditorPanel")
require("lua/Chooserwidget")
require("lua/EditorMainPanel")
require("lua/MapEditorPanel")
require("lua/LevelRestrictionsEditorPanel")
require("lua/EditorSaveUtil")
require("lua/MiscLevelEditorPanel")
require("lua/CheckBox")
require("lua/MapPanel")
require("../lua/Map")


function love.load()
	setStatics(true)
	initLevels()
	currentPanel = MainMenu.create()
end

-- ====================================================

function love.draw()
	love.graphics.setBackgroundColor(unpack(colors["light_gray"]))
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