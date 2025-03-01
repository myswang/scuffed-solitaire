local Game = require("game")

local game

function love.load()
    love.window.setTitle("Scuffed Solitaire")
    love.window.setMode(637, 600)
    love.graphics.setBackgroundColor(0, 99/255, 0)
    game = Game:new()
end

function love.draw()
    game:render()
end