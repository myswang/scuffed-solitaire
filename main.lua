local texture = love.graphics.newImage("texture.png")

local card_width = 71
local card_height = 96
local fanout_spacing = 20
local stack_spacing = 20

local blank = { rank = 12, suit = 4, visible = true }
local cards = {}
local card_quads = {}
local blank_quad = love.graphics.newQuad(blank.rank * card_width, blank.suit * card_height, card_width, card_height, texture)
local flip_quad = love.graphics.newQuad(3 * card_width, 4 * card_height, card_width, card_height, texture)
local sprite_batch = love.graphics.newSpriteBatch(texture)

local stock = {
    { x = 10, y = 10, fanout = false, cards = cards },
    { x = 10 + card_width + stack_spacing, y = 10, fanout = false, cards = {} }
}

local foundation = {
    { x = 10 + (card_width + stack_spacing)*3, y = 10, fanout = false, cards = {} },
    { x = 10 + (card_width + stack_spacing)*4, y = 10, fanout = false, cards = {} },
    { x = 10 + (card_width + stack_spacing)*5, y = 10, fanout = false, cards = {} },
    { x = 10 + (card_width + stack_spacing)*6, y = 10, fanout = false, cards = {} },
}

local tableau = {
    { x = 10, y = 10 + card_height + 5, fanout = true, cards = {}},
    { x = 10 + card_width + stack_spacing, y = 10 + card_height + 5, fanout = true, cards = {} },
    { x = 10 + (card_width + stack_spacing)*2, y = 10 + card_height + 5, fanout = true, cards = {} },
    { x = 10 + (card_width + stack_spacing)*3, y = 10 + card_height + 5, fanout = true, cards = {} },
    { x = 10 + (card_width + stack_spacing)*4, y = 10 + card_height + 5, fanout = true, cards = {} },
    { x = 10 + (card_width + stack_spacing)*5, y = 10 + card_height + 5, fanout = true, cards = {} },
    { x = 10 + (card_width + stack_spacing)*6, y = 10 + card_height + 5, fanout = true, cards = {} },
}

local stacks = {
    stock = stock,
    foundation = foundation,
    tableau = tableau
}

local prev_stack = nil
local prev_key = nil
local cur_stack = nil
local pressed = false

-- each line is a series of actions that can be committed atomically
-- examples below: 
-- MOVE(3, src, dst) -> FLIP(src)
-- MOVE(1, src, dst) -> FLIP(dst)
-- REDEAL()
local log = {}

local function get_stack_area(stack)
    if stack.fanout then
        return card_width, card_height + fanout_spacing * #stack.cards
    else
        return card_width, card_height
    end
end

local function grab_stack(x, y, stack)
    local sx, sy = get_stack_area(stack)
    if x >= stack.x and x <= stack.x+sx and y >= stack.y and y <= stack.y+sy then
        local largest_idx = 0
        if stack.fanout then
            for i, _ in ipairs(stack.cards) do
                local card_x, card_y = stack.x, stack.y + (i-1) * fanout_spacing
                if x >= card_x and x <= card_x+card_width and y >= card_y and y <= card_y+card_height and i > largest_idx then
                    largest_idx = i
                end
            end
        else
            largest_idx = #stack.cards
        end

        -- TODO: investigate spurious error: attempt to index a nil value
        if #stack.cards == 0 or (#stack.cards > 0 and not stack.cards[largest_idx].visible) then
            if stack == stock[1] then
                local entry = {}
                if #stack.cards > 0 then
                    table.insert(stock[2].cards, table.remove(stack.cards))
                    stock[2].cards[#stock[2].cards].visible = true
                    table.insert(entry, { "move", 1, stack, stock[2] })
                    table.insert(entry, { "flip", stock[2] })
                else
                    for i = #stock[2].cards, 1, -1 do
                        table.insert(stack.cards, stock[2].cards[i])
                        stock[2].cards[i].visible = false
                    end
                    stock[2].cards = {}
                    table.insert(entry, { "redeal" })
                end
                table.insert(log, entry)
                return true
            end
            return false
        end

        local new_stack = {
            x = stack.x,
            y = stack.y,
            fanout = stack.fanout,
            cards = {}
        }

        if stack.fanout then
            new_stack.y = new_stack.y + (largest_idx-1) * fanout_spacing
        end

        local old_cards = {}
        for i, card in ipairs(stack.cards) do
            if i < largest_idx then
                table.insert(old_cards, card)
            else
                table.insert(new_stack.cards, card)
            end
        end

        stack.cards = old_cards

        cur_stack = new_stack
        prev_stack = stack
        pressed = true
        return true
    end
    return false
end

-- check if stack1 is colliding with stack2.
-- if they are, get the distance between their centers
-- otherwise, return math.huge
local function colliding(stack1, stack2)
    local sx1, sy1 = get_stack_area(stack1)
    local sx2, sy2 = get_stack_area(stack2)

    if stack1.x < stack2.x+sx2 and stack1.x+sx1 > stack2.x
    and stack1.y < stack2.y+sy2 and stack1.y+sy1 > stack2.y then
        local cx1 = stack1.x + sx1 / 2
        local cy1 = stack1.y + sy1 / 2
        local cx2 = stack2.x + sx2 / 2
        local cy2 = stack2.y + sy2 / 2

        local dx = cx2 - cx1
        local dy = cy2 - cy1

        return math.sqrt(dx * dx + dy * dy)
    end
    return math.huge
end

local function restart_game()
    local pairs = {}
    for suit = 0, 3 do
        table.insert(card_quads, {})
        for rank = 0, 12 do
            table.insert(pairs, {suit, rank})
            table.insert(card_quads[#card_quads], love.graphics.newQuad(rank * card_width, suit * card_height, card_width, card_height, texture))
        end
    end

    -- shuffle cards
    local seed = math.randomseed(os.time())
    for i = #pairs, 2, -1 do
        local j = math.random(i)
        pairs[i], pairs[j] = pairs[j], pairs[i]
    end

    for _, pair in ipairs(pairs) do
        table.insert(cards, {
            rank = pair[2],
            suit = pair[1],
            visible = false
        })
    end

    for i, stack in ipairs(tableau) do
        for _ = 0, i-1 do
            table.insert(stack.cards, table.remove(cards))
        end
        stack.cards[#stack.cards].visible = true
    end
end

function love.load()
    love.window.setTitle("Scuffed Solitaire")
    love.window.setMode(637, 600)
    love.graphics.setBackgroundColor(0, 99/255, 0)
    restart_game()
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    for key, stack_group in pairs(stacks) do
        for _, stack in ipairs(stack_group) do
            if grab_stack(x, y, stack) then
                prev_key = key
                return
            end
        end
    end
end

local function get_dists(candidates, s, label)
    for i, stack in ipairs(s) do
        local dist = colliding(cur_stack, stack)
        if dist < math.huge then
            table.insert(candidates, { dist, i, label })
        end
    end
end

local function handle_foundation(stack)
    if cur_stack == nil then return false end
    local card = cur_stack.cards[1]
    if (#stack.cards == 0 and card.rank == 0)
    or (#stack.cards > 0 and card.rank == stack.cards[#stack.cards].rank + 1 and card.suit == stack.cards[#stack.cards].suit) then
        stack.suit = card.suit
        table.insert(stack.cards, table.remove(cur_stack.cards))
        return true
    end
    return false
end

local function handle_tableau(stack)
    if cur_stack == nil then return false end
    local card = cur_stack.cards[1]
    if (#stack.cards == 0 and card.rank == 12)
    or (#stack.cards > 0 and stack.cards[#stack.cards].rank == card.rank+1
        and (math.abs(stack.cards[#stack.cards].suit - card.suit) % 2 == 1))then
        for _, c in ipairs(cur_stack.cards) do
            table.insert(stack.cards, c)
        end
        return true
    end
    return false
end

local function update_prev()
    if prev_stack ~= nil and prev_key == "tableau" and #prev_stack.cards > 0 and not prev_stack.cards[#prev_stack.cards].visible then
        prev_stack.cards[#prev_stack.cards].visible = true
        return true
    end
    return false
end

local function reset_stacks()
    if cur_stack == nil or prev_stack == nil then return end
    for _, card in ipairs(cur_stack.cards) do
        table.insert(prev_stack.cards, card)
    end
end

local function undo()
    if #log == 0 then return end
    local entry = table.remove(log)
    for i = #entry, 1, -1 do
        local action = entry[i]
        if action[1] == "move" then
            local count = action[2]
            local src = action[3]
            local dst = action[4]
            for j = #dst.cards - count + 1, #dst.cards do
                table.insert(src.cards, dst.cards[j])
            end
            for _ = #dst.cards - count + 1, #dst.cards do
                table.remove(dst.cards)
            end
        elseif action[1] == "flip" then
            local src = action[2]
            src.cards[#src.cards].visible = not src.cards[#src.cards].visible
        elseif action[1] == "redeal" then
            for j = #stock[1].cards, 1, -1 do
                table.insert(stock[2].cards, stock[1].cards[j])
                stock[1].cards[j].visible = true
            end
            stock[1].cards = {}
        end
    end
end

function love.mousereleased(_, _, button)
    if button == 1 and cur_stack ~= nil and prev_stack ~= nil then
        local candidates = {}
        get_dists(candidates, foundation, "foundation")
        get_dists(candidates, tableau, "tableau")
        table.sort(candidates, function(a, b) return a[1] < b[1] end)
        local dest = nil

        if #candidates > 0 then
            for _, c in ipairs(candidates) do
                if c[3] == "foundation" then
                    local stack = foundation[c[2]]
                    if stack ~= prev_stack and #cur_stack.cards == 1 and handle_foundation(stack) then
                        local entry = {}
                        table.insert(entry, { "move", 1, prev_stack, stack })
                        if update_prev() then
                            table.insert(entry, { "flip", prev_stack })
                        end
                        dest = stack
                        table.insert(log, entry)
                        break
                    end
                elseif c[3] == "tableau" then
                    local stack = tableau[c[2]]
                    if stack ~= prev_stack and handle_tableau(stack) then
                        local entry = {}
                        table.insert(entry, { "move", #cur_stack.cards, prev_stack, stack })
                        if update_prev() then
                            table.insert(entry, { "flip", prev_stack })
                        end
                        dest = stack
                        table.insert(log, entry)
                        break
                    end
                end
            end
        end

        if dest == nil then
            reset_stacks()
        end
        cur_stack = nil
        prev_stack = nil
        prev_key = nil
        pressed = false
    end
end

function love.mousemoved(_, _, dx, dy)
    if pressed and cur_stack ~= nil then
        cur_stack.x = cur_stack.x + dx
        cur_stack.y = cur_stack.y + dy
    end
end

function love.keypressed(key)
    if key == "u" then
        undo()
    end
end

local function draw_card(cx, cy, card)
    if card == nil then return end
    local quad = flip_quad
    if card == blank then
        quad = blank_quad
    elseif card.visible then
        quad = card_quads[card.suit + 1][card.rank + 1]
    end
    sprite_batch:add(quad, cx, cy)
end

local function draw_stack(stack)
    if stack == nil then return end
    if stack.fanout then
        for i, card in ipairs(stack.cards) do
            draw_card(stack.x, stack.y + (i-1) * fanout_spacing, card)
        end
    else
        draw_card(stack.x, stack.y, stack.cards[#stack.cards])
    end
end

function love.draw()
    sprite_batch:clear()
    for _, stack_group in pairs(stacks) do
        for _, stack in ipairs(stack_group) do
            if #stack.cards == 0 then
                draw_card(stack.x, stack.y, blank)
            else
                draw_stack(stack)
            end
        end
    end

    draw_stack(cur_stack)
    love.graphics.draw(sprite_batch)

end