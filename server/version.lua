local versionUrl = 'https://raw.githubusercontent.com/Binary-Development/bd_sampchat/main/version'

---@param value string
---@return integer[]?
local function parseVersion(value)
    local major, minor, patch = value:match('^(%d+)%.(%d+)%.(%d+)')
    if not major then return end

    return { tonumber(major), tonumber(minor), tonumber(patch) }
end

---@param remote string
---@param current string
---@return boolean
local function isNewer(remote, current)
    local remoteParts = parseVersion(remote)
    local currentParts = parseVersion(current)
    if not remoteParts or not currentParts then return false end

    for i = 1, 3 do
        if remoteParts[i] ~= currentParts[i] then
            return remoteParts[i] > currentParts[i]
        end
    end

    return false
end

---@param status integer
---@param body string?
local function compareVersion(status, body)
    if status ~= 200 or type(body) ~= 'string' then return end

    local current = GetResourceMetadata(cache.resource, 'version', 0) or '0.0.0'
    local remote = body:match('%d+%.%d+%.%d+')

    if remote and isNewer(remote, current) then
        lib.print.warn(('update available: v%s is on github (running v%s)'):format(remote, current))
    end
end

PerformHttpRequest(versionUrl, compareVersion, 'GET')
