local serverConfig = require 'config.server'
local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'
local ranks = require 'server.modules.ranks'
local duty = require 'server.modules.duty'
local ignores = require 'server.modules.ignores'

---@type table<integer, true>
local doNotDisturb = {}

---@param source integer
---@param target integer
---@return boolean
local function canMessage(source, target)
    if target == source then
        return messages.error(source, 'error.pm_self')
    end

    if ranks.get(source) then return true end

    if ignores.has(target, source) then
        return messages.error(source, 'error.pm_ignored')
    end

    if doNotDisturb[target] then
        return messages.error(source, 'error.pm_dnd')
    end

    local targetRank = ranks.get(target)

    if targetRank and not targetRank.tester and duty.isOn(target) then
        return messages.error(source, 'error.pm_on_duty')
    end

    return true
end

---@param source integer
---@param message string
---@param args { target: string }
local function sendPrivateMessage(source, message, args)
    if source == 0 then return end

    local target = players.findClosest(source, args.target)

    if not target then
        return messages.error(source, 'error.player_not_found')
    end

    if not canMessage(source, target) then return end

    messages.notice(target, 'pm', 'notice.pm_received', { id = source, name = players.getName(source), message = message })
    messages.notice(source, 'pm', 'notice.pm_sent', { id = target, name = players.getName(target), message = message })
end

---@param source integer
local function toggleDoNotDisturb(source)
    doNotDisturb[source] = not doNotDisturb[source] or nil

    messages.notice(source, 'info', doNotDisturb[source] and 'notice.dnd_on' or 'notice.dnd_off')
end

local function forgetPlayer()
    doNotDisturb[source] = nil
end

commands.addText({
    names = 'pm',
    help = locale('help.pm'),
    params = { { name = 'target', help = locale('param.target') } }
}, sendPrivateMessage)

commands.add({
    names = 'dnd',
    help = locale('help.dnd'),
    minRank = serverConfig.staffCommands.dnd,
    configPath = 'config/server.lua: staffCommands.dnd'
}, toggleDoNotDisturb)

AddEventHandler('playerDropped', forgetPlayer)
