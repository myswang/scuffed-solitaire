local game = require("game")

function love.load()
    love.window.setTitle("Scuffed Solitaire")
    love.window.setMode(637, 600)
    love.graphics.setBackgroundColor(0, 99/255, 0)
    game.restart()
end

function love.mousepressed(x, y, button)
    game.handle_mouse_pressed(x, y, button)
end

function love.mousemoved(_, _, dx, dy)
    game.handle_mouse_moved(dx, dy)
end

function love.mousereleased(_, _, button)
    game.handle_mouse_released(button)
end

function love.keypressed(key)
    game.handle_key_pressed(key)
end

function love.draw()
    game.render()
end