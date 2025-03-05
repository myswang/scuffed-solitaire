local constants = require("constants")

local Stack = {}
Stack.__index = Stack

function Stack:new(x, y, fanout, fanout_count)
    local obj = setmetatable({}, self)
    obj.x, obj.y = x, y
    obj.fanout = fanout
    obj.fanout_count = fanout_count or math.huge
    obj.visible = true
    obj.cards = {}
    obj.sx, obj.sy = self.dimensions(obj)
    return obj
end

function Stack:get_first()
    return self.cards[1]
end

function Stack:get_last()
    return self.cards[#self.cards]
end

function Stack:dimensions()
    local count = math.min(self.fanout_count, #self.cards)
    if count < 1 then
        count = 1
    end
    if self.fanout then
        return constants.CARD_WIDTH,
        constants.CARD_HEIGHT + constants.FANOUT_SPACING * (count - 1)
    else
        return constants.CARD_WIDTH + constants.FANOUT_SPACING * (count - 1),
        constants.CARD_HEIGHT
    end
end

function Stack:transfer_to(dst, count)
    for i = #self.cards - count + 1, #self.cards do
        table.insert(dst.cards, self.cards[i])
    end
    for _ = #dst.cards - count + 1, #dst.cards do
        table.remove(self.cards)
    end
    self.sx, self.sy = self:dimensions()
    dst.sx, dst.sy = dst:dimensions()
end

function Stack:flip_last()
    local last = self:get_last()
    if last ~= nil then
        last.visible = not last.visible
    end
end

return Stack