local util = {}

function util.colliding(obj1, obj2)
    return obj1.x < obj2.x+obj2.sx
    and    obj1.x+obj1.sx > obj2.x
    and    obj1.y < obj2.y+obj2.sy
    and    obj1.y+obj1.sy > obj2.y
end

function util.distance(obj1, obj2)
    local cx1 = obj1.x + obj1.sx / 2
    local cy1 = obj1.y + obj1.sy / 2
    local cx2 = obj2.x + obj2.sx / 2
    local cy2 = obj2.y + obj2.sy / 2

    local dx = cx2 - cx1
    local dy = cy2 - cy1

    return math.sqrt(dx*dx + dy*dy)
end

return util