local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'
local ignores = require 'server.modules.ignores'

---@param source integer
local function listIgnored(source)
    local ignored = ignores.list(source)

    if #ignored == 0 then
        return messages.notice(source, 'info', 'notice.ignore_none')
    end

    messages.notice(source, 'success', 'notice.ignore_header')

    for i = 1, #ignored do
        messages.notice(source, 'info', 'notice.ignore_entry', { id = ignored[i], name = players.getPlayerName(ignored[i]) })
    end
end

---@param source integer
---@param args { target?: string }
local function toggleIgnore(source, args)
    if source == 0 then return end

    if not args.target then
        return listIgnored(source)
    end

    local target = players.findClosest(source, args.target)

    if not target then
        return messages.error(source, 'error.player_not_found')
    end

    if target == source then
        return messages.error(source, 'error.ignore_self')
    end

    local ignored = ignores.toggle(source, target)

    messages.notice(source, 'info', ignored and 'notice.ignore_on' or 'notice.ignore_off', {
        id = target,
        name = players.getPlayerName(target)
    })
end

commands.add({
    names = 'ignore',
    help = locale('help.ignore'),
    params = { { name = 'target', help = locale('param.target_optional') } }
}, toggleIgnore)
