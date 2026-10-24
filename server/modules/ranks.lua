local serverConfig = require 'config.server'

---@class Rank
---@field group string
---@field principal string
---@field ace string
---@field label string
---@field color string
---@field tester boolean
---@field level integer

---@class StaffMember
---@field source integer
---@field rank Rank

local ranks = {}

---@type Rank[]
local list = {}

---@type table<string, Rank>
local byGroup = {}

---@param group string
---@return string
local function toPrincipal(group)
    return group:find('.', 1, true) and group or ('group.%s'):format(group)
end

---@param index integer
---@param entry table
---@return Rank
local function buildRank(index, entry)
    local path = ('config/server.lua: ranks[%d]'):format(index)

    assert(type(entry.group) == 'string' and entry.group ~= '', ('%s.group is missing'):format(path))
    assert(type(entry.label) == 'string', ('%s.label is missing'):format(path))
    assert(type(entry.color) == 'string' and entry.color:match('^#%x+$'), ("%s.color must look like '#FF0000'"):format(path))
    assert(not byGroup[entry.group], ("config/server.lua: rank '%s' is listed twice"):format(entry.group))

    return {
        group = entry.group,
        principal = toPrincipal(entry.group),
        ace = ('bd_sampchat.rank.%s'):format(entry.group),
        label = entry.label,
        color = entry.color,
        tester = entry.tester == true,
        level = #serverConfig.ranks - index + 1
    }
end

for i = 1, #serverConfig.ranks do
    local rank = buildRank(i, serverConfig.ranks[i])

    list[i] = rank
    byGroup[rank.group] = rank

    if not IsPrincipalAceAllowed(rank.principal, rank.ace) then
        lib.addAce(rank.principal, rank.ace)
    end
end

---@param group string
---@param path string
---@return Rank
function ranks.require(group, path)
    local rank = byGroup[group]

    assert(rank, ("%s: '%s' isn't a rank in the ranks list"):format(path, tostring(group)))

    return rank
end

---@param group string
---@param path string
---@return string[]
function ranks.principalsFrom(group, path)
    local lowest = ranks.require(group, path)
    local principals = {}

    for i = 1, #list do
        principals[i] = list[i].principal

        if list[i] == lowest then break end
    end

    return principals
end

---@param source integer
---@return Rank?
function ranks.get(source)
    if source == 0 then return end

    for i = 1, #list do
        if IsPlayerAceAllowed(source, list[i].ace) then
            return list[i]
        end
    end
end

---@return StaffMember[]
function ranks.getOnlineStaff()
    local players = GetPlayers()
    local staff = {}

    for i = 1, #players do
        ---@type integer
        local source = tonumber(players[i])
        local rank = ranks.get(source)

        if rank then
            staff[#staff + 1] = { source = source, rank = rank }
        end
    end

    return staff
end

---@return integer[]
function ranks.getOnlineStaffIds()
    local staff = ranks.getOnlineStaff()
    local ids = {}

    for i = 1, #staff do
        ids[i] = staff[i].source
    end

    return ids
end

---@param resource string
local function removeAces(resource)
    if resource ~= cache.resource then return end

    for i = 1, #list do
        lib.removeAce(list[i].principal, list[i].ace)
    end
end

AddEventHandler('onResourceStop', removeAces)

return ranks
