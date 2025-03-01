local Card = {}
Card.__index = Card

function Card:new(rank, suit, visible)
    local obj = setmetatable({}, self)
    obj.rank = rank
    obj.suit = suit
    obj.visible = visible
end

local Stack = {}
Stack.__index = Stack

function Stack:new(x, y, fanout)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.fanout = fanout
    obj.cards = {}
end

function Stack:push(card)
    table.insert(self.cards, card)
end

function Stack:pop()
    return table.remove(self.cards)
end

function Stack:get_first()
    return self.cards[1]
end

function Stack:get_last()
    return self.cards[#self.cards]
end

function Stack:transfer_to(dst, count)
    for i = #self.cards - count + 1, #self.cards do
        dst:push(self.cards[i])
    end
    for _ = #dst.cards - count + 1, #dst.cards do
        self:pop()
    end
end

function Stack:flip_last()
    local last = self:get_last()
    if last ~= nil then
        last.visible = not last.visible
    end
end

return { Card, Stack }