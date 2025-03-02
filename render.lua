local Render = {}
local constants = require("constants")
Render.__index = Render

function Render:new()
    local obj = setmetatable({}, self)
    obj.texture = love.graphics.newImage("texture.png")
    obj.batch = love.graphics.newSpriteBatch(obj.texture)
    obj.quads = {}
    for y = 1, 6 do
        table.insert(obj.quads, {})
        for x = 1, 13 do
            local quad = love.graphics.newQuad(
                (x-1)*constants.CARD_WIDTH,
                (y-1)*constants.CARD_HEIGHT,
                constants.CARD_WIDTH,
                constants.CARD_HEIGHT,
                obj.texture
            )
            table.insert(obj.quads[y], quad)
        end
    end
    return obj
end

function Render:add_card(card, cx, cy)
    if card == nil then return end
    local quad = self.quads[card.suit+1][card.rank+1]
    if not card.visible then
        quad = self.quads[5][4]
    end
    self.batch:add(quad, cx, cy)
end

function Render:add_stack(stack)
    if stack == nil or not stack.visible then return end
    if stack.fanout and stack.fanout_side then
        local count = 3
        if #stack.cards < count then
            count = #stack.cards
        end
        for i = 1, count do
            self:add_card(stack.cards[#stack.cards-count+i], stack.x + (i-1) * constants.FANOUT_SPACING, stack.y)
        end
    elseif stack.fanout then
        for i, card in ipairs(stack.cards) do
            self:add_card(card, stack.x, stack.y + (i-1) * constants.FANOUT_SPACING)
        end
    else
        self:add_card(stack:get_last(), stack.x, stack.y)
    end
end

return Render


