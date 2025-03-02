local Log = {}
Log.__index = Log

function Log:new()
    local obj = setmetatable({}, self)
    obj.log = {}
    obj.idx = 1
    return obj
end

function Log:add(action)
    local new_log = {}
    for i = 1, self.idx - 1 do
        new_log[i] = self.log[i]
    end
    new_log[self.idx] = action
    self.log = new_log
    self.idx = self.idx + 1
end

function Log:undo()
    if self.idx > 1 then
        self.idx = self.idx - 1
        return self.log[self.idx]
    end
end

function Log:redo()
    if self.idx <= #self.log then
        local res = self.log[self.idx]
        self.idx = self.idx + 1
        return res
    end
end

return Log