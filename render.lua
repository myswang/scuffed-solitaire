local Renderer = {}
local _, Stack = require("card")
local constants = require("constants")
Renderer.__index = Renderer

function Renderer:new()
    local obj = setmetatable({}, self)
    obj.texture = love.graphics.newImage("texture.png")
    obj.batch = love.graphics.newSpriteBatch(obj.texture)
    obj.width = 71
    obj.height = 96
    obj.quads = {}
    for y = 1, 6 do
        table.insert(obj.quads, {})
        for x = 1, 13 do
            local quad = love.graphics.newQuad(x*obj.width, y*obj.height, obj.width, obj.height, obj.texture)
            table.insert(obj.quads[y], quad)
        end
    end
end

function Renderer:add_card(card, cx, cy)
    if card == nil then return end
    local quad = self.quads[card.suit+1][card.rank+1]
    if not card.visible then
        quad = self.quads[5][4]
    end
    self.sprite_batch:add(quad, cx, cy)
end

function Renderer:add_stack(stack)
    if stack == nil then return end
    if stack.fanout then
        for i, card in ipairs(stack.cards) do
            self:add_card(card, stack.x, stack.y + (i-1) * constants.fanout_spacing)
        end
    else
        self:add_card(Stack.get_last(stack), stack.x, stack.y)
    end
end



