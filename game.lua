local Game = {}
local objects = require("objects")
local Render = require("render")
local c = require("constants")
local util = require("util")
Game.__index = Game

function Game:new()
    local obj = setmetatable({}, self)
    obj.renderer = Render:new()
    obj.cards = {}
    obj.stock = {}
    obj.foundation = {}
    obj.tableau = {}
    obj.blank = objects.Card:new(12, 4, true)
    obj.cur_stack = objects.Stack:new(0, 0, true)
    obj.cur_stack.visible = false
    -- TODO: remove these for loops that basically all do the same thing
    for i = 0, 1 do
        table.insert(obj.stock, objects.Stack:new(10 + (c.CARD_WIDTH+c.STACK_SPACING)*i, 10, false))
    end
    for i = 3, 6 do
        table.insert(obj.foundation, objects.Stack:new(10 + (c.CARD_WIDTH+c.STACK_SPACING)*i, 10, false))
    end
    for i = 0, 6 do
        table.insert(obj.tableau, objects.Stack:new(10 + (c.CARD_WIDTH+c.STACK_SPACING)*i, 15 + c.CARD_HEIGHT, true))
    end

    obj.stacks = { stock=obj.stock, foundation=obj.foundation, tableau=obj.tableau }

    for suit = 0, 3 do
        for rank = 0, 12 do
            table.insert(obj.cards, objects.Card:new(rank, suit, false))
        end
    end
    -- Fisher-Yates shuffle
    math.randomseed(os.time())
    for i = #obj.cards, 2, -1 do
        local j = math.random(i)
        obj.cards[i], obj.cards[j] = obj.cards[j], obj.cards[i]
    end

    obj.stock[1].cards = obj.cards

    for i, stack in ipairs(obj.tableau) do
        obj.stock[1]:transfer_to(stack, i)
        obj.stock[1]:get_last().visible = true
    end

    return obj
end

function Game:render()
    self.renderer.batch:clear()
    for _, stack_group in pairs(self.stacks) do
        for _, stack in ipairs(stack_group) do
            if #stack.cards == 0 then
                self.renderer:add_card(self.blank, stack.x, stack.y)
            else
                self.renderer:add_stack(stack)
            end
        end
    end

    self.renderer:add_stack(self.cur_stack)
    love.graphics.draw(self.renderer.batch)
end

return Game