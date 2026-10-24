local ignores = {}

---@type table<integer, table<integer, true>>
local lists = {}

---@param listener integer
---@param sender integer
---@return boolean
function ignores.has(listener, sender)
    local list = lists[listener]

    return list ~= nil and list[sender] == true
end

---@param source integer
---@param target integer
---@return boolean ignored
function ignores.toggle(source, target)
    local list = lists[source] or {}

    list[target] = not list[target] or nil
    lists[source] = next(list) and list or nil

    return list[target] == true
end

---@param source integer
---@return integer[]
function ignores.list(source)
    local ignored = {}

    for target in pairs(lists[source] or {}) do
        ignored[#ignored + 1] = target
    end

    table.sort(ignored)

    return ignored
end

---@param listeners integer[]
---@param sender integer
---@return integer[]
function ignores.filter(listeners, sender)
    if not next(lists) then return listeners end

    local kept = {}

    for i = 1, #listeners do
        if not ignores.has(listeners[i], sender) then
            kept[#kept + 1] = listeners[i]
        end
    end

    return kept
end

local function forgetPlayer()
    local dropped = source

    lists[dropped] = nil

    for listener, list in pairs(lists) do
        list[dropped] = nil

        if not next(list) then
            lists[listener] = nil
        end
    end
end

AddEventHandler('playerDropped', forgetPlayer)

return ignores
