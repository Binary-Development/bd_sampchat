local serverConfig = require 'config.server'
local messages = require 'server.modules.messages'
local profanity = require 'server.modules.profanity'
local mutes = require 'server.modules.mutes'
local logs = require 'server.modules.logs'

local guard = {}

---@class RecentMessage
---@field text string
---@field count integer
---@field sentAt integer

assert(type(serverConfig.cooldown) == 'number' and serverConfig.cooldown >= 0, 'config/server.lua: cooldown must be a number of 0 or more')
assert(type(serverConfig.duplicateLimit) == 'number' and serverConfig.duplicateLimit >= 0, 'config/server.lua: duplicateLimit must be a number of 0 or more')
assert(type(serverConfig.duplicateWindow) == 'number' and serverConfig.duplicateWindow > 0, 'config/server.lua: duplicateWindow must be a number above 0')

local cooldownMs = math.floor(serverConfig.cooldown * 1000)
local duplicateLimit = serverConfig.duplicateLimit
local duplicateWindowMs = math.floor(serverConfig.duplicateWindow * 1000)

---@type table<integer, integer>
local lastSent = {}

---@type table<integer, RecentMessage>
local recent = {}

---@param source integer
---@return boolean
function guard.cooldown(source)
    if source == 0 then return true end

    local now = GetGameTimer()
    local last = lastSent[source]

    if last and now - last < cooldownMs then
        return messages.error(source, 'error.too_fast')
    end

    lastSent[source] = now

    return true
end

---@param source integer
---@param message string
---@param context string
---@return boolean
local function isRepeated(source, message, context)
    if duplicateLimit == 0 then return false end

    local key = ('%s\0%s'):format(context, (message:lower():gsub('%s+', ' ')))
    local now = GetGameTimer()
    local last = recent[source]

    if last and last.text == key and now - last.sentAt < duplicateWindowMs then
        last.count += 1
        last.sentAt = now

        return last.count > duplicateLimit
    end

    recent[source] = { text = key, count = 1, sentAt = now }

    return false
end

---@param source integer
---@param message string
---@param context string command or channel the message was sent to
---@return boolean
function guard.allow(source, message, context)
    if source == 0 then return true end

    local mutedFor = mutes.getRemaining(source)

    if mutedFor then
        return messages.error(source, 'error.muted', { minutes = math.ceil(mutedFor / 60) })
    end

    if not guard.cooldown(source) then return false end

    if isRepeated(source, message, context) then
        return messages.error(source, 'error.repeated')
    end

    local word = profanity.find(message)

    if word then
        logs.send('profanity', source, {
            kind = 'profanity',
            message = message,
            fields = {
                { name = locale('log.command'), value = context, inline = true },
                { name = locale('log.word'), value = word, inline = true },
            }
        })

        return messages.error(source, 'error.blocked_word')
    end

    return true
end

local function forgetPlayer()
    lastSent[source] = nil
    recent[source] = nil
end

AddEventHandler('playerDropped', forgetPlayer)

return guard
