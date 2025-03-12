local Rect = {}
Rect.__index = Rect

function Rect:new(x, y, sx, sy)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.rx = 0
    obj.ry = 0
    obj.click_handler = function() return false end
    obj.subs = {}
    return obj
end

function Rect:set_click_handler(handler)
    self.click_handler = handler
end

function Rect:add_sub(sub)
    table.insert(self.subs, sub)
    sub.rx = self.rx + self.x
    sub.ry = self.ry + self.y
end

function Rect:render()
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.rx + self.x, self.ry + self.y, self.sx, self.sy)
    love.graphics.setColor(1, 1, 1)
    for _, sub in ipairs(self.subs) do
        sub:render()
    end
end

return Rect