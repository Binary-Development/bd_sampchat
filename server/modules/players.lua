local framework = require 'bridge.framework'
local text = require 'shared.text'

local players = {}

---@type table<integer, string>
local masks = {}

---@param name string?
---@return string?
local function cleanName(name)
    local cleaned = text.clean(name, 64)

    return cleaned ~= '' and cleaned or nil
end

---@param source integer
---@return string
function players.getPlayerName(source)
    if source == 0 then return locale('console') end

    return cleanName(GetPlayerName(source)) or ('#%s'):format(source)
end

---@param source integer
---@return string
function players.getName(source)
    if source == 0 then return locale('console') end

    return cleanName(framework.getName(source)) or players.getPlayerName(source)
end

---@param source integer
---@return string
function players.getRoleplayName(source)
    return masks[source] or players.getName(source)
end

---@param source integer
---@return string?
function players.toggleMask(source)
    masks[source] = not masks[source] and locale('mask_name', math.random(1000, 9999)) or nil

    return masks[source]
end

---@param source integer
---@return boolean
function players.exists(source)
    return source > 0 and GetPlayerName(source) ~= nil
end

---@param source integer
---@param range number
---@return integer[]
function players.getNearby(source, range)
    local ped = GetPlayerPed(source)
    if ped == 0 then return {} end

    local origin = GetEntityCoords(ped)
    local bucket = GetPlayerRoutingBucket(source)
    local list = GetPlayers()
    local nearby = {}

    for i = 1, #list do
        ---@type integer
        local target = tonumber(list[i])
        local targetPed = GetPlayerPed(target)

        if targetPed ~= 0 and GetPlayerRoutingBucket(target) == bucket and #(GetEntityCoords(targetPed) - origin) <= range then
            nearby[#nearby + 1] = target
        end
    end

    return nearby
end

---@param query string
---@return integer[]
function players.search(query)
    local id = tonumber(query)

    if id then
        return players.exists(id) and { id } or {}
    end

    local search = query:lower()
    local list = GetPlayers()
    local found = {}

    for i = 1, #list do
        ---@type integer
        local target = tonumber(list[i])

        if players.getName(target):lower():find(search, 1, true) or players.getPlayerName(target):lower():find(search, 1, true) then
            found[#found + 1] = target
        end
    end

    return found
end

---@param source integer
---@param query string
---@return integer?
function players.findClosest(source, query)
    local found = players.search(query)
    if #found < 2 then return found[1] end

    local ped = GetPlayerPed(source)
    local origin = ped ~= 0 and GetEntityCoords(ped)
    if not origin then return found[1] end

    local closest, closestDistance

    for i = 1, #found do
        local targetPed = GetPlayerPed(found[i])
        local distance = targetPed ~= 0 and #(GetEntityCoords(targetPed) - origin) or math.huge

        if not closestDistance or distance < closestDistance then
            closest, closestDistance = found[i], distance
        end
    end

    return closest
end

local function forgetPlayer()
    masks[source] = nil
end

AddEventHandler('playerDropped', forgetPlayer)

return players
