local ESX = exports.es_extended:getSharedObject()

local accounts = {
    cash = 'money',
    bank = 'bank'
}

---@type FrameworkBridge
local esx = {}

function esx.getName(source)
    local player = ESX.GetPlayerFromId(source)

    return player and player.getName()
end

function esx.getJob(source)
    local player = ESX.GetPlayerFromId(source)
    local job = player and player.getJob()

    return job and { name = job.name, label = job.label or job.name }
end

function esx.removeMoney(source, account, amount, reason)
    local player = ESX.GetPlayerFromId(source)
    if not player then return false end

    local name = accounts[account]
    local balance = player.getAccount(name)
    if not balance or balance.money < amount then return false end

    player.removeAccountMoney(name, amount, reason)

    return true
end

return esx
