--panel for editing a level's tech restrictions

LevelRestrictionsEditorPanel = {}
LevelRestrictionsEditorPanel.__index = LevelRestrictionsEditorPanel


function LevelRestrictionsEditorPanel.create(x, y, w, h)
	local temp = {}
	setmetatable(temp, LevelRestrictionsEditorPanel)
	temp.x = x
	temp.y = y
	temp.width = w
	temp.height = h
	temp.hasUnsavedChanges = false
	return temp
end

-- ====================================================

function LevelRestrictionsEditorPanel:saveChanges()
	--todo
end

-- ====================================================

function LevelRestrictionsEditorPanel:draw()
	--bg and border:
	love.graphics.setColor(colors["white"])
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(colors["black"])
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

-- ====================================================

function LevelRestrictionsEditorPanel:update(dt)
	--nothing
end

-- ====================================================

function LevelRestrictionsEditorPanel:mousepressed(x, y, button)
	--nothing
end

-- ====================================================

function LevelRestrictionsEditorPanel:keypressed(key)
	--nothing
end

-- ====================================================