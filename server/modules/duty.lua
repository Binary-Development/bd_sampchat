local duty = {}

---@type table<integer, true>
local onDuty = {}

---@param source integer
---@return boolean
function duty.isOn(source)
    return onDuty[source] == true
end

---@param source integer
---@return boolean onDuty
function duty.toggle(source)
    onDuty[source] = not onDuty[source] or nil

    return onDuty[source] == true
end

local function forgetPlayer()
    onDuty[source] = nil
end

AddEventHandler('playerDropped', forgetPlayer)
exports('isOnDuty', duty.isOn)

return duty
