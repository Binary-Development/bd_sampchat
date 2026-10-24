local Ox = require '@ox_core.lib.init'

---@type FrameworkBridge
local ox = {}

function ox.getName(source)
    local player = Ox.GetPlayer(source)
    local firstName = player and player.get('firstName')
    if not firstName then return end

    return ('%s %s'):format(firstName, player.get('lastName') or '')
end

function ox.getJob(source)
    local player = Ox.GetPlayer(source)
    local group = player and player.get('activeGroup')
    if not group then return end

    local data = Ox.GetGroup(group)

    return { name = group, label = data and data.label or group }
end

function ox.removeMoney(source, account, amount, reason)
    if account == 'cash' then
        if exports.ox_inventory:GetItemCount(source, 'money') < amount then return false end

        return exports.ox_inventory:RemoveItem(source, 'money', amount) == true
    end

    local player = Ox.GetPlayer(source)
    local bank = player and player.getAccount()
    if not bank then return false end

    local result = bank.removeBalance({ amount = amount, message = reason })

    return result == true or type(result) == 'table' and result.success == true
end

return ox
