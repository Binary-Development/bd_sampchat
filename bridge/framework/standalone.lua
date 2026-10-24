---@type FrameworkBridge
local standalone = {}

function standalone.getName(source)
    return GetPlayerName(source)
end

function standalone.getJob()
    return nil
end

function standalone.removeMoney()
    return true
end

return standalone
