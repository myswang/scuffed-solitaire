local game = {}
local objects = require("objects")
local Render = require("render")
local c = require("constants")
local util = require("util")
local log = require("log")

local renderer = Render:new()
local blank = objects.Card:new(12, 4, true)
local cur_stack = objects.Stack:new(0, 0, true)
cur_stack.visible = false
local game_log, cur_transaction, cards, stock, foundation, tableau, stacks

function game.restart()
    renderer = Render:new()
    game_log = log.Log:new()
    cur_transaction = {}
    cards = {}
    stock = {}
    foundation = {}
    tableau = {}
    -- TODO: remove these for loops that basically all do the same thing
    for i = 0, 1 do
        table.insert(stock, objects.Stack:new(10 + (c.CARD_WIDTH+c.STACK_SPACING)*i, 10, false))
    end
    for i = 3, 6 do
        table.insert(foundation, objects.Stack:new(10 + (c.CARD_WIDTH+c.STACK_SPACING)*i, 10, false))
    end
    for i = 0, 6 do
        table.insert(tableau, objects.Stack:new(10 + (c.CARD_WIDTH+c.STACK_SPACING)*i, 15 + c.CARD_HEIGHT, true))
    end

    stacks = { stock=stock, foundation=foundation, tableau=tableau }

    for suit = 0, 3 do
        for rank = 0, 12 do
            table.insert(cards, objects.Card:new(rank, suit, false))
        end
    end
    -- Fisher-Yates shuffle
    math.randomseed(os.time())
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

function game.render()
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

local function redeal(stack1, stack2)
    for i = #stack1.cards, 1, -1 do        
        stack1.cards[i].visible = not stack1.cards[i].visible
        table.insert(stack2.cards, stack1.cards[i])
    end
    stack1.cards = {}
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
        if not rollback then
            redeal(stock[2], stock[1])
        else
            redeal(stock[1], stock[2])
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

function game.handle_mouse_pressed(x, y, button)
    if button ~= 1 then return end
    local point = { x=x, y=y, sx=0, sy=0 }

    if util.colliding(point, stock[1]) then
        if #stock[1].cards > 0 then
            table.insert(cur_transaction, log.Action:new("move", {stock[1], stock[2], 1}))
            table.insert(cur_transaction, log.Action:new("flip", {stock[2]}))
        else
            table.insert(cur_transaction, log.Action:new("redeal", {}))
        end

        apply_transaction(cur_transaction, false)

        game_log:add(cur_transaction)
        cur_transaction = {}
    end
end

function game.handle_mouse_moved(dx, dy)

end

function game.handle_mouse_released(button)

end

function game.handle_key_pressed(key)
    if key == "u" then
        apply_transaction(game_log:undo(), true)
    elseif key == "r" then
        apply_transaction(game_log:redo(), false)
    end
end

return game