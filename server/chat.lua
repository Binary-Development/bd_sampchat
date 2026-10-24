local sharedConfig = require 'config.shared'
local serverConfig = require 'config.server'
local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'
local ranks = require 'server.modules.ranks'
local guard = require 'server.modules.guard'
local ignores = require 'server.modules.ignores'
local text = require 'shared.text'

---@class ProximityChannel
---@field commands string[]
---@field help string
---@field range number
---@field color string
---@field format string
---@field default? boolean
---@field togsDefault? boolean
---@field ooc? boolean

---@type table<integer, true>
local togs = {}

---@type ProximityChannel
local defaultChannel

---@type ProximityChannel
local togsChannel

local sweepAt = 0
local sweepScheduled = false

---@param source integer
---@param channel ProximityChannel
---@param message string
local function sendToChannel(source, channel, message)
    local rank = ranks.get(source)
    local playerName = players.getPlayerName(source)
    local nearby = players.getNearby(source, channel.range)

    messages.send(channel.ooc and ignores.filter(nearby, source) or nearby, {
        color = channel.color,
        template = channel.format,
        params = {
            id = source,
            name = channel.ooc and players.getName(source) or players.getRoleplayName(source),
            player = rank and { text = playerName, color = rank.color } or playerName,
            message = message
        }
    })
end

---@param index integer
---@param channel ProximityChannel
local function registerChannel(index, channel)
    local path = ('config/server.lua: proximity[%d]'):format(index)

    assert(type(channel.commands) == 'table' and #channel.commands > 0, ("%s.commands must be a list like { 'say', 's' }"):format(path))
    assert(type(channel.range) == 'number' and channel.range > 0, ('%s.range must be a number above 0'):format(path))
    assert(type(channel.format) == 'string', ('%s.format is missing'):format(path))

    ---@param source integer
    ---@param message string
    local function sendChannelMessage(source, message)
        sendToChannel(source, channel, message)
    end

    commands.addText({ names = channel.commands, help = channel.help }, sendChannelMessage)

    if channel.default then defaultChannel = channel end
    if channel.togsDefault then togsChannel = channel end
end

for i = 1, #serverConfig.proximity do
    registerChannel(i, serverConfig.proximity[i])
end

assert(defaultChannel, 'config/server.lua: one proximity entry needs default = true')
assert(togsChannel, 'config/server.lua: one proximity entry needs togsDefault = true')

---@param message string
local function routeTypedMessage(message)
    local source = source

    message = text.clean(message, sharedConfig.maxLength)

    if message == '' then return end

    local channel = togs[source] and togsChannel or defaultChannel

    if not guard.allow(source, message, ('/%s'):format(channel.commands[1])) then return end

    TriggerEvent('chatMessage', source, players.getPlayerName(source), message)

    if WasEventCanceled() then return end

    sendToChannel(source, channel, message)
end

---@param source integer
local function toggleTogs(source)
    togs[source] = not togs[source] or nil

    messages.notice(source, 'info', togs[source] and 'notice.togs_on' or 'notice.togs_off')
end

---@param source integer
local function toggleMask(source)
    local mask = players.toggleMask(source)

    if mask then
        return messages.notice(source, 'info', 'notice.mask_on', { name = mask })
    end

    messages.notice(source, 'info', 'notice.mask_off')
end

---@param command string
local function reportUnknownCommand(command)
    local source = source

    CancelEvent()

    if source < 1 then return end

    messages.error(source, 'error.unknown_command', { command = text.clean(command:match('^%S+'), 32) })
end

---@param target integer
---@param registered { name: string }[]
local function sendCommands(target, registered)
    local names, known = commands.getAllowed(target, registered)

    TriggerClientEvent('bd_sampchat:client:receivedCommands', target, names, known)
end

local function sendCommandsToJoined()
    sendCommands(source, GetRegisteredCommands())
end

local function sweepCommands()
    local remaining = sweepAt - GetGameTimer()

    if remaining > 0 then
        return SetTimeout(remaining, sweepCommands)
    end

    sweepScheduled = false

    local registered = GetRegisteredCommands()
    local list = GetPlayers()

    for i = 1, #list do
        ---@type integer
        local target = tonumber(list[i])

        sendCommands(target, registered)
    end
end

local function scheduleCommandSweep()
    sweepAt = GetGameTimer() + 1000

    if sweepScheduled then return end

    sweepScheduled = true
    SetTimeout(1000, sweepCommands)
end

---@param target integer | table
---@param message? table | string
local function addMessage(target, message)
    if message == nil then
        message, target = target, -1
    end

    if type(message) == 'string' then
        message = { args = { message } }
    end

    if type(message) ~= 'table' then return end

    TriggerClientEvent('chat:addMessage', target, message)
end

local function forgetPlayer()
    togs[source] = nil
end

commands.add({ names = 'togs', help = locale('help.togs') }, toggleTogs)
commands.add({ names = 'maskname', help = locale('help.maskname') }, toggleMask)

RegisterNetEvent('bd_sampchat:server:sentMessage', routeTypedMessage)
RegisterNetEvent('chat:init', sendCommandsToJoined)
AddEventHandler('__cfx_internal:commandFallback', reportUnknownCommand)
AddEventHandler('onServerResourceStart', scheduleCommandSweep)
AddEventHandler('onServerResourceStop', scheduleCommandSweep)
AddEventHandler('playerDropped', forgetPlayer)
exports('addMessage', addMessage)
