local serverConfig = require 'config.server'
local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'
local ranks = require 'server.modules.ranks'
local duty = require 'server.modules.duty'
local logs = require 'server.modules.logs'

---@class BroadcastConfig
---@field command string
---@field help string
---@field minRank string
---@field audience 'everyone' | 'staff'
---@field color string
---@field format string
---@field log? boolean

local area = serverConfig.areaAnnounce
local minRange = 5.0

---@param source integer
---@param message string
---@return table<string, ChatParam> params
---@return Rank? rank
local function getStaffParams(source, message)
    local rank = ranks.get(source)

    return {
        id = source,
        name = players.getName(source),
        player = players.getPlayerName(source),
        rank = rank and { text = rank.label, color = rank.color } or locale('console'),
        message = message
    }, rank
end

---@param index integer
---@param broadcast BroadcastConfig
local function registerBroadcast(index, broadcast)
    local path = ('config/server.lua: broadcasts[%d]'):format(index)

    assert(type(broadcast.command) == 'string', ('%s.command is missing'):format(path))
    assert(broadcast.audience == 'everyone' or broadcast.audience == 'staff', ("%s.audience must be 'everyone' or 'staff'"):format(path))
    assert(type(broadcast.format) == 'string', ('%s.format is missing'):format(path))

    ---@param source integer
    ---@param message string
    local function sendBroadcast(source, message)
        local params, rank = getStaffParams(source, message)
        local color = broadcast.color == 'rank' and (rank and rank.color or '#FFFFFF') or broadcast.color

        messages.send(broadcast.audience == 'staff' and ranks.getOnlineStaffIds() or -1, {
            color = color,
            template = broadcast.format,
            params = params
        })

        if not broadcast.log then return end

        logs.send('staff', source, {
            kind = 'broadcast',
            message = message,
            fields = {
                { name = locale('log.command'), value = ('/%s'):format(broadcast.command), inline = true },
                { name = locale('log.rank'), value = rank and rank.label or locale('console'), inline = true },
            }
        })
    end

    commands.addText({
        names = broadcast.command,
        help = broadcast.help,
        minRank = broadcast.minRank,
        configPath = ('%s.minRank'):format(path)
    }, sendBroadcast)
end

---@param source integer
---@param message string
local function sendAreaAnnouncement(source, message)
    if source == 0 then return end

    local typedRange, rest = message:match('^(%d+%.?%d*)%s+(.+)$')
    local range = area.defaultRange

    if typedRange then
        range = math.min(math.max(tonumber(typedRange) or range, minRange), area.maxRange)
        message = rest
    end

    local nearby = players.getNearby(source, range)

    messages.send(nearby, {
        color = area.color,
        template = area.format,
        params = getStaffParams(source, message)
    })

    messages.notice(source, 'success', 'notice.area_sent', { count = math.max(#nearby - 1, 0), range = math.floor(range) })
end

---@param source integer
local function toggleDuty(source)
    if source == 0 then return end

    local rank = ranks.get(source)
    if not rank then return end

    local isOnDuty = duty.toggle(source)
    local staff = ranks.getOnlineStaffIds()
    local others = {}

    for i = 1, #staff do
        if staff[i] ~= source then
            others[#others + 1] = staff[i]
        end
    end

    messages.notice(source, 'staff', isOnDuty and 'notice.duty_on_self' or 'notice.duty_off_self')
    messages.notice(others, 'staff', isOnDuty and 'notice.duty_on' or 'notice.duty_off', {
        name = { text = players.getPlayerName(source), color = rank.color }
    })
end

---@param source integer
---@param kind 'admins' | 'testers'
local function listStaff(source, kind)
    local staff = ranks.getOnlineStaff()
    local wantTesters = kind == 'testers'
    local listed = {}

    for i = 1, #staff do
        if staff[i].rank.tester == wantTesters then
            listed[#listed + 1] = staff[i]
        end
    end

    if #listed == 0 then
        return messages.notice(source, 'info', ('notice.%s_none'):format(kind))
    end

    messages.notice(source, 'success', ('notice.%s_header'):format(kind))

    for i = 1, #listed do
        local member = listed[i]
        local isOnDuty = duty.isOn(member.source)

        messages.notice(source, isOnDuty and 'success' or 'info', isOnDuty and 'notice.staff_on_duty' or 'notice.staff_off_duty', {
            id = member.source,
            rank = { text = member.rank.label, color = member.rank.color },
            name = players.getPlayerName(member.source)
        })
    end
end

---@param source integer
local function listAdmins(source)
    listStaff(source, 'admins')
end

---@param source integer
local function listTesters(source)
    listStaff(source, 'testers')
end

assert(type(area.defaultRange) == 'number' and type(area.maxRange) == 'number', 'config/server.lua: areaAnnounce.defaultRange and maxRange must be numbers')

for i = 1, #serverConfig.broadcasts do
    registerBroadcast(i, serverConfig.broadcasts[i])
end

commands.addText({
    names = area.command,
    help = area.help,
    minRank = area.minRank,
    configPath = 'config/server.lua: areaAnnounce.minRank'
}, sendAreaAnnouncement)

commands.add({
    names = 'adminduty',
    help = locale('help.adminduty'),
    minRank = serverConfig.staffCommands.adminDuty,
    configPath = 'config/server.lua: staffCommands.adminDuty'
}, toggleDuty)

commands.add({ names = 'admins', help = locale('help.admins') }, listAdmins)
commands.add({ names = 'testers', help = locale('help.testers') }, listTesters)
