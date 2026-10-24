local core = exports.ND_Core

---@type FrameworkBridge
local nd = {}

function nd.getName(source)
    local player = core:getPlayer(source)

    return player and player.fullname
end

function nd.getJob(source)
    local player = core:getPlayer(source)
    local job = player and player.job
    if not job then return end

    local name = type(job) == 'table' and job.name or job
    local info = player.jobInfo

    return { name = name, label = info and info.label or name }
end

function nd.removeMoney(source, account, amount, reason)
    local player = core:getPlayer(source)
    if not player or (player[account] or 0) < amount then return false end

    player.deductMoney(account, amount, reason)

    return true
end

return nd
