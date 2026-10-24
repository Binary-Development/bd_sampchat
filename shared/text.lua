local text = {}

local colorCodes = { '%^#%x+', '%^[%d%*_~=r/]', '~%a~' }

---@param value string
---@return string
local function dropInvalidUtf8(value)
    if utf8.len(value) then return value end

    local parts = {}
    local position = 1

    while position <= #value do
        local _, badAt = utf8.len(value, position)

        if not badAt then
            parts[#parts + 1] = value:sub(position)
            break
        end

        parts[#parts + 1] = value:sub(position, badAt - 1)
        position = badAt + 1
    end

    return table.concat(parts)
end

---@param value string
---@param maxLength integer
---@return string
local function truncate(value, maxLength)
    local cut = utf8.offset(value, maxLength + 1)

    return cut and value:sub(1, cut - 1) or value
end

---@param value string
---@return string
function text.stripCodes(value)
    local changed = true

    while changed do
        changed = false

        for i = 1, #colorCodes do
            local count

            value, count = value:gsub(colorCodes[i], '')
            changed = changed or count > 0
        end
    end

    return value
end

---@param value any
---@param maxLength integer
---@return string
function text.sanitize(value, maxLength)
    if type(value) ~= 'string' then return '' end

    value = dropInvalidUtf8(value)
        :gsub('\239\191\189', '')
        :gsub('\226\128[\139-\143\170-\174]', '')
        :gsub('\226\129[\166-\169]', '')
        :gsub('%c', ' ')
        :gsub('%s+', ' ')

    return truncate(value:match('^%s*(.-)%s*$'), maxLength)
end

---@param value any
---@param maxLength integer
---@return string
function text.clean(value, maxLength)
    return text.sanitize(type(value) == 'string' and text.stripCodes(value) or value, maxLength)
end

return text
