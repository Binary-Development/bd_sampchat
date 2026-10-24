local serverConfig = require 'config.server'
local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'
local ranks = require 'server.modules.ranks'
local mutes = require 'server.modules.mutes'
local logs = require 'server.modules.logs'

local maxMuteMinutes = serverConfig.maxMuteMinutes

assert(type(maxMuteMinutes) == 'number' and maxMuteMinutes >= 1, 'config/server.lua: maxMuteMinutes must be a number of 1 or more')

---@param source integer
---@param target integer
---@return boolean
local function outranks(source, target)
    if source == 0 then return true end

    local targetRank = ranks.get(target)
    if not targetRank then return true end

    local rank = ranks.get(source)

    return rank ~= nil and rank.level > targetRank.level
end

---@param target integer
---@return LogField[]
local function getTargetFields(target)
    return {
        { name = locale('log.target'), value = ('%s (ID %s)'):format(players.getPlayerName(target), target), inline = true },
        { name = locale('log.target_license'), value = GetPlayerIdentifierByType(target, 'license') or locale('log.none'), inline = true },
    }
end

---@param source integer
---@param key string
---@param params table<string, ChatParam>
local function tellStaff(source, key, params)
    messages.notice(ranks.getOnlineStaffIds(), 'staff', key, params)

    if source == 0 then
        messages.notice(0, 'staff', key, params)
    end
end

---@param source integer
---@param query string?
---@return integer?
local function findTarget(source, query)
    local target = query and players.findClosest(source, query)

    if not target then
        messages.error(source, 'error.player_not_found')
        return
    end

    if target == source then
        messages.error(source, 'error.moderate_self')
        return
    end

    if not outranks(source, target) then
        messages.error(source, 'error.moderate_rank')
        return
    end

    return target
end

---@param source integer
---@param reason string
---@param args { target?: string, minutes?: string }
local function muteFromChat(source, reason, args)
    local target = findTarget(source, args.target)
    if not target then return end

    local minutes = math.tointeger(tonumber(args.minutes))

    if not minutes or minutes < 1 or minutes > maxMuteMinutes then
        return messages.error(source, 'error.mute_minutes', { max = maxMuteMinutes })
    end

    mutes.set(target, minutes)

    messages.notice(target, 'error', 'notice.muted_target', { minutes = minutes, reason = reason })
    tellStaff(source, 'notice.muted_staff', {
        staff = players.getPlayerName(source),
        name = players.getPlayerName(target),
        id = target,
        minutes = minutes,
        reason = reason
    })

    local fields = getTargetFields(target)

    fields[#fields + 1] = { name = locale('log.minutes'), value = tostring(minutes), inline = true }
    fields[#fields + 1] = { name = locale('log.reason'), value = reason, inline = false }

    logs.send('staff', source, { kind = 'mute', fields = fields })
end

---@param source integer
---@param args { target?: string }
local function unmuteFromChat(source, args)
    local target = findTarget(source, args.target)
    if not target then return end

    if not mutes.getRemaining(target) then
        return messages.error(source, 'error.not_muted')
    end

    mutes.clear(target)

    messages.notice(target, 'success', 'notice.unmuted_target')
    tellStaff(source, 'notice.unmuted_staff', {
        staff = players.getPlayerName(source),
        name = players.getPlayerName(target),
        id = target
    })

    logs.send('staff', source, { kind = 'unmute', fields = getTargetFields(target) })
end

---@param source integer
local function clearChat(source)
    TriggerClientEvent('bd_sampchat:client:clearedChat', -1)
    messages.notice(-1, 'staff', 'notice.chat_cleared')

    if source == 0 then
        messages.notice(0, 'staff', 'notice.chat_cleared')
    end

    logs.send('staff', source, { kind = 'clear' })
end

commands.addText({
    names = 'chatmute',
    help = locale('help.chatmute'),
    params = {
        { name = 'target', help = locale('param.target') },
        { name = 'minutes', help = locale('param.minutes', maxMuteMinutes) }
    },
    textParam = { name = 'reason', help = locale('param.reason') },
    minRank = serverConfig.staffCommands.chatMute,
    configPath = 'config/server.lua: staffCommands.chatMute'
}, muteFromChat)

commands.add({
    names = 'chatunmute',
    help = locale('help.chatunmute'),
    params = { { name = 'target', help = locale('param.target') } },
    minRank = serverConfig.staffCommands.chatMute,
    configPath = 'config/server.lua: staffCommands.chatMute'
}, unmuteFromChat)

commands.add({
    names = 'clearchat',
    help = locale('help.clearchat'),
    minRank = serverConfig.staffCommands.clearChat,
    configPath = 'config/server.lua: staffCommands.clearChat'
}, clearChat)
