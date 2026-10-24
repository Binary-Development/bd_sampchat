local serverConfig = require 'config.server'
local players = require 'server.modules.players'

local logs = {}

local maxQueued = 50
local spacingMs = 1000

local colors = {
    advert = 3066993,
    broadcast = 15105570,
    profanity = 15548997,
    mute = 15548997,
    unmute = 5763719,
    clear = 16776960
}

---@class LogField
---@field name string
---@field value string
---@field inline? boolean

---@class LogEntry
---@field kind 'advert' | 'broadcast' | 'profanity' | 'mute' | 'unmute' | 'clear'
---@field message? string
---@field fields? LogField[]

---@class WebhookQueue
---@field items table[]
---@field head integer
---@field tail integer
---@field busy boolean

---@type table<string, WebhookQueue>
local queues = {}

---@param url string
local function sendNext(url)
    local queue = queues[url]
    local payload = queue.items[queue.head]

    if not payload then
        queue.busy = false
        return
    end

    local function sendAgain()
        sendNext(url)
    end

    ---@param delayMs integer
    local function scheduleNext(delayMs)
        SetTimeout(delayMs, sendAgain)
    end

    ---@param status integer
    ---@param _ string?
    ---@param headers table<string, string>?
    local function handleResponse(status, _, headers)
        if status == 429 then
            local retryAfter = tonumber(headers and (headers['retry-after'] or headers['Retry-After'])) or 2

            return scheduleNext(math.ceil(retryAfter * 1000))
        end

        if status < 200 or status >= 300 then
            lib.print.warn(('discord webhook returned status %s, check the webhooks in config/server.lua'):format(status))
        end

        queue.items[queue.head] = nil
        queue.head += 1
        scheduleNext(spacingMs)
    end

    PerformHttpRequest(url, handleResponse, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

---@param url string
---@param payload table
local function enqueue(url, payload)
    local queue = queues[url]

    if not queue then
        queue = { items = {}, head = 1, tail = 0, busy = false }
        queues[url] = queue
    end

    if queue.tail - queue.head + 1 >= maxQueued then
        return lib.print.warn('discord webhook queue is full, dropping a log')
    end

    queue.tail += 1
    queue.items[queue.tail] = payload

    if queue.busy then return end

    queue.busy = true
    sendNext(url)
end

---@param source integer
---@return LogField[]
local function getPlayerFields(source)
    local discord = GetPlayerIdentifierByType(source, 'discord')

    return {
        { name = locale('log.player'), value = ('%s (ID %s)'):format(players.getPlayerName(source), source), inline = true },
        { name = locale('log.character'), value = players.getName(source), inline = true },
        { name = locale('log.discord'), value = discord and ('<@%s>'):format(discord:sub(9)) or locale('log.not_linked'), inline = true },
        { name = locale('log.license'), value = GetPlayerIdentifierByType(source, 'license') or locale('log.none'), inline = true },
    }
end

---@param webhook 'adverts' | 'staff' | 'profanity'
---@param source integer
---@param entry LogEntry
function logs.send(webhook, source, entry)
    local url = serverConfig.webhooks[webhook]
    if type(url) ~= 'string' or url == '' then return end

    local fields = source > 0 and getPlayerFields(source) or {}

    if entry.fields then
        for i = 1, #entry.fields do
            fields[#fields + 1] = entry.fields[i]
        end
    end

    if entry.message then
        fields[#fields + 1] = { name = locale('log.message'), value = entry.message, inline = false }
    end

    enqueue(url, {
        username = 'Chat',
        allowed_mentions = { parse = {} },
        embeds = {
            {
                title = locale(('log.%s'):format(entry.kind)),
                color = colors[entry.kind],
                fields = fields,
                footer = { text = cache.resource },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
    })
end

return logs
