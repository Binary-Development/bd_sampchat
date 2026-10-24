local createBridge = require 'bridge.framework.qblike'

---@param source integer
---@return table?
local function getPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

return createBridge(getPlayer)
