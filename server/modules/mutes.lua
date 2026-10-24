local mutes = {}

local keyPrefix = 'mute:'

---@type table<integer, integer>
local expiries = {}

---@param source integer
---@return string?
local function getKey(source)
    local license = GetPlayerIdentifierByType(source, 'license')

    return license and keyPrefix .. license
end

---@param source integer
---@return integer
local function loadExpiry(source)
    local key = getKey(source)

    return key and tonumber(GetResourceKvpString(key)) or 0
end

---@param source integer
function mutes.clear(source)
    expiries[source] = 0

    local key = getKey(source)

    if key then
        DeleteResourceKvp(key)
    end
end

---@param source integer
---@param minutes integer
function mutes.set(source, minutes)
    local expires = os.time() + minutes * 60

    expiries[source] = expires

    local key = getKey(source)

    if key then
        SetResourceKvp(key, tostring(expires))
    end
end

---@param source integer
---@return integer? seconds left, nil when not muted
function mutes.getRemaining(source)
    if source == 0 then return end

    local expires = expiries[source]

    if not expires then
        expires = loadExpiry(source)
        expiries[source] = expires
    end

    if expires == 0 then return end

    local remaining = expires - os.time()

    if remaining > 0 then return remaining end

    mutes.clear(source)
end

local function removeExpired()
    local handle = StartFindKvp(keyPrefix)
    if handle == -1 then return end

    local now = os.time()
    local expired = {}

    repeat
        local key = FindKvp(handle)

        if key and (tonumber(GetResourceKvpString(key)) or 0) <= now then
            expired[#expired + 1] = key
        end
    until not key

    EndFindKvp(handle)

    for i = 1, #expired do
        DeleteResourceKvp(expired[i])
    end
end

local function forgetPlayer()
    expiries[source] = nil
end

removeExpired()

AddEventHandler('playerDropped', forgetPlayer)

return mutes
