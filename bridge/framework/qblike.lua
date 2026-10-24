---@param getPlayer fun(source: integer): table?
---@return FrameworkBridge
local function createBridge(getPlayer)
    ---@type FrameworkBridge
    local bridge = {}

    function bridge.getName(source)
        local player = getPlayer(source)
        local info = player and player.PlayerData.charinfo
        if not info then return end

        return ('%s %s'):format(info.firstname, info.lastname)
    end

    function bridge.getJob(source)
        local player = getPlayer(source)
        local job = player and player.PlayerData.job

        return job and { name = job.name, label = job.label or job.name }
    end

    function bridge.removeMoney(source, account, amount, reason)
        local player = getPlayer(source)
        if not player or (player.PlayerData.money[account] or 0) < amount then return false end

        return player.Functions.RemoveMoney(account, amount, reason) ~= false
    end

    return bridge
end

return createBridge
