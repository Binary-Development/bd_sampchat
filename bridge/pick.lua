---@class BridgeDetection
---@field resource string
---@field name string

---@class BridgeChoice
---@field kind string
---@field setting any
---@field options string[]
---@field detection BridgeDetection[]
---@field fallback string

local pick = {}

---@param resource string
---@return boolean
local function isRunning(resource)
    local state = GetResourceState(resource)

    return state == 'started' or state == 'starting'
end

---@param choice BridgeChoice
---@return string
function pick.choose(choice)
    local name = type(choice.setting) == 'string' and choice.setting:lower() or 'auto'

    assert(name == 'auto' or lib.table.contains(choice.options, name), ("config/server.lua: %s = '%s' isn't an option, use one of: auto, %s"):format(
        choice.kind, tostring(choice.setting), table.concat(choice.options, ', ')))

    if name == 'auto' then
        name = choice.fallback

        for i = 1, #choice.detection do
            local entry = choice.detection[i]

            if isRunning(entry.resource) then
                name = entry.name
                break
            end
        end
    end

    lib.print.info(('%s: %s'):format(choice.kind, name))

    return name
end

return pick
