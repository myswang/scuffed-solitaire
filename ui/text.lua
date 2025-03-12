package.path = package.path .. ";../?.lua"
local c = require("constants")

local Text = {}
Text.__index = Text

function Text:new(x, y)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.sx = 0
    obj.sy = 0
    obj.rx = 0
    obj.ry = 0
    obj.text = "foobar"
    obj.click_handler = function() return false end
    obj.subs = {}
    return obj
end

function Text:add_sub(sub)
    table.insert(self.subs, sub)
    sub.rx = self.rx + self.x
    sub.ry = self.ry + self.y
end

function Text:render()
    love.graphics.setFont(c.FONT)
    love.graphics.print(self.text, self.rx + self.x, self.ry + self.y)
    for _, sub in ipairs(self.subs) do
        sub:render()
    end
end

return Text