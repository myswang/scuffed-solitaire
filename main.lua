local Stack = require("stack")
local Render = require("render")
local c = require("constants")
local util = require("util")
local Log = require("log")

local renderer = Render:new()
local blank = { rank = 12, suit = 4, visible = true }
local game_log, cur_transaction, cards, stock, foundation, tableau, stacks, cur_stack, prev_stack, point

local function restart_game()
    renderer = Render:new()
    game_log = Log:new()
    cur_transaction = {}
    cards = {}
    stock = {}
    foundation = {}
    tableau = {}
    cur_stack = Stack:new(0, 0, true)
    cur_stack.visible = false

    -- TODO: remove these for loops that basically all do the same thing
    for i = 0, 1 do
        table.insert(stock, Stack:new(10 + (c.CARD_WIDTH + c.STACK_SPACING) * i, 10, false, 1))
    end
    for i = 3, 6 do
        table.insert(foundation, Stack:new(10 + (c.CARD_WIDTH + c.STACK_SPACING) * i, 10, false, 1))
    end
    for i = 0, 6 do
        table.insert(tableau, Stack:new(10 + (c.CARD_WIDTH + c.STACK_SPACING) * i, 15 + c.CARD_HEIGHT, true))
    end

    stacks = { stock = stock, foundation = foundation, tableau = tableau }

    if c.THREE_CARD_HAND then
        stock[2].fanout_count = 3
    end

    for suit = 0, 3 do
        for rank = 0, 12 do
            table.insert(cards, { rank = rank, suit = suit, visible = false })
        end
    end
    -- Fisher-Yates shuffle
    math.randomseed(os.time() * os.clock() * 1000000)
    for i = #cards, 2, -1 do
        local j = math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end

    stock[1].cards = cards

    for i, stack in ipairs(tableau) do
        stock[1]:transfer_to(stack, i)
        stack:get_last().visible = true
    end
end

local function redeal(stack1, stack2)
    for i = #stack1.cards, 1, -1 do
        stack1.cards[i].visible = not stack1.cards[i].visible
        table.insert(stack2.cards, stack1.cards[i])
    end
    stack1.cards = {}
end

local function grab_stack()
    for _, stack_group in pairs(stacks) do
        for _, stack in ipairs(stack_group) do
            if stack ~= stock[1] and util.colliding(point, stack) then
                local largest_idx = 1
                local lx, ly
                local count = math.min(stack.fanout_count, #stack.cards)
                for i = 1, count do
                    local card_x, card_y = stack.x + (i - 1) * c.FANOUT_SPACING, stack.y
                    if stack.fanout then
                        card_x, card_y = stack.x, stack.y + (i - 1) * c.FANOUT_SPACING
                    end
                    local bb = { x = card_x, y = card_y, sx = c.CARD_WIDTH, sy = c.CARD_HEIGHT }
                    if util.colliding(point, bb) then
                        largest_idx = #stack.cards - count + i
                        lx, ly = card_x, card_y
                    end
                end
                count = #stack.cards - largest_idx + 1

                if (stack ~= stock[2] and #stack.cards > 0 and stack.cards[largest_idx].visible)
                or (stack == stock[2] and c.THREE_CARD_HAND and count == 1) then
                    cur_stack.visible = true
                    prev_stack = stack
                    cur_stack.x, cur_stack.y = lx, ly
                    return stack, count
                end
                return nil
            end
        end
    end
    return nil
end

local function place_stack()
    local candidates = {}
    for key, stack_group in pairs(stacks) do
        if key ~= "stock" then
            for _, stack in ipairs(stack_group) do
                if util.colliding(cur_stack, stack) then
                    table.insert(candidates, { util.distance(cur_stack, stack), key, stack })
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b) return a[1] < b[1] end)
    for _, candidate in ipairs(candidates) do
        local kind, stack = candidate[2], candidate[3]
        if kind == "foundation" and #cur_stack.cards == 1 and stack ~= prev_stack then
            local first = cur_stack:get_first()
            local last = stack:get_last()
            if (#stack.cards == 0 and first.rank == 0)
                or (#stack.cards > 0 and first.rank == last.rank + 1 and first.suit == last.suit) then
                return stack, 1
            end
        elseif kind == "tableau" and stack ~= prev_stack then
            local first = cur_stack:get_first()
            local last = stack:get_last()
            if (#stack.cards == 0 and first.rank == 12)
                or (#stack.cards > 0 and last.rank == first.rank + 1
                    and (math.abs(last.suit - first.suit) % 2 == 1)) then
                return stack, #cur_stack.cards
            end
        end
    end
    return nil
end

local function deal_cards()
    if c.THREE_CARD_HAND then
        if #stock[1].cards > 0 then
            local count = 3
            if #stock[1].cards < count then
                count = #stock[1].cards
            end
            for _ = 1, count do
                table.insert(cur_transaction, { kind = "move", args = { stock[1], stock[2], 1 } })
                table.insert(cur_transaction, { kind = "flip", args = { stock[2] } })
            end
        else
            table.insert(cur_transaction, { kind = "redeal", args = { stock[2], stock[1] } })
        end
    else
        if #stock[1].cards > 0 then
            table.insert(cur_transaction, { kind = "move", args = { stock[1], stock[2], 1 } })
            table.insert(cur_transaction, { kind = "flip", args = { stock[2] } })
        else
            table.insert(cur_transaction, { kind = "redeal", args = { stock[2], stock[1] } })
        end
    end
end

local function apply_action(action, rollback)
    local kind = action.kind
    local args = action.args

    if kind == "move" then
        local stack1, stack2, count = args[1], args[2], args[3]
        if not rollback then
            stack1:transfer_to(stack2, count)
        else
            stack2:transfer_to(stack1, count)
        end
    elseif kind == "flip" then
        local stack = args[1]
        stack:flip_last()
    elseif kind == "redeal" then
        local stack1, stack2 = args[1], args[2]
        if not rollback then
            redeal(stack1, stack2)
        else
            redeal(stack2, stack1)
        end
    end
end

local function apply_transaction(transaction, rollback)
    if transaction == nil then return end
    if not rollback then
        for i = 1, #transaction do
            apply_action(transaction[i], rollback)
        end
    else
        for i = #transaction, 1, -1 do
            apply_action(transaction[i], rollback)
        end
    end
end

function love.load()
    love.window.setTitle("Scuffed Solitaire")
    love.window.setMode(637, 600)
    love.graphics.setBackgroundColor(0, 99 / 255, 0)
    restart_game()
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    local p = { x = x, y = y, sx = 0, sy = 0 }

    if util.colliding(p, stock[1]) then
        deal_cards()
        apply_transaction(cur_transaction, false)
        game_log:add(cur_transaction)
        cur_transaction = {}
    else
        point = p
    end
end

function love.mousemoved(_, _, dx, dy)
    if point ~= nil and not cur_stack.visible then
        local src, count = grab_stack()
        if src ~= nil then
            table.insert(cur_transaction, { kind = "move", args = { src, cur_stack, count } })
            apply_transaction(cur_transaction, false)
        else
            point = nil
        end
    end

    if cur_stack.visible then
        cur_stack.x = cur_stack.x + dx
        cur_stack.y = cur_stack.y + dy
    end
end

function love.mousereleased(_, _, button)
    if button ~= 1 or not cur_stack.visible then
        point = nil
        return
    end
    local dst, count = place_stack()
    if dst ~= nil then
        local action = { kind = "move", args = { cur_stack, dst, count } }
        apply_action(action, false)
        table.insert(cur_transaction, action)
        if #prev_stack.cards > 0 and not prev_stack:get_last().visible then
            action = { kind = "flip", args = { prev_stack } }
            apply_action(action, false)
            table.insert(cur_transaction, action)
        end
        game_log:add(cur_transaction)
    else
        apply_transaction(cur_transaction, true)
    end
    cur_stack.visible = false
    cur_transaction = {}
    prev_stack = nil
    point = nil
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "return" then
        restart_game()
    elseif key == "u" then
        apply_transaction(game_log:undo(), true)
    elseif key == "r" then
        apply_transaction(game_log:redo(), false)
    end
end

function love.draw()
    renderer.batch:clear()
    for _, stack_group in pairs(stacks) do
        for _, stack in ipairs(stack_group) do
            if #stack.cards == 0 then
                renderer:add_card(blank, stack.x, stack.y)
            else
                renderer:add_stack(stack)
            end
        end
    end

    renderer:add_stack(cur_stack)
    love.graphics.draw(renderer.batch)
end
