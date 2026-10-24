local serverConfig = require 'config.server'
local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'
local guard = require 'server.modules.guard'
local text = require 'shared.text'

local maxResults = 10

local coinSides = { 'side.heads', 'side.tails' }
local handSigns = { 'side.rock', 'side.paper', 'side.scissors' }
local diceKeys = { 'notice.dice_1', 'notice.dice_2', 'notice.dice_3' }

assert(type(serverConfig.gamesRange) == 'number' and serverConfig.gamesRange > 0, 'config/server.lua: gamesRange must be a number above 0')

---@param source integer
---@param target integer
local function sendPlayerLine(source, target)
    messages.notice(source, 'info', 'notice.id', {
        id = target,
        name = players.getName(target),
        player = players.getPlayerName(target)
    })
end

---@param source integer
---@param _ table
---@param raw string
local function lookUpPlayer(source, _, raw)
    local query = text.clean(commands.getTextAfter(raw, 1), 64)

    if query == '' then
        if source > 0 then sendPlayerLine(source, source) end
        return
    end

    local found = players.search(query)

    if #found == 0 then
        return messages.error(source, 'error.player_not_found')
    end

    for i = 1, math.min(#found, maxResults) do
        sendPlayerLine(source, found[i])
    end
end

---@param source integer
local function countPlayers(source)
    messages.notice(source, 'info', 'notice.players', { count = GetNumPlayerIndices() })
end

---@param source integer
---@param key string
---@param params table<string, ChatParam>
local function sendGameResult(source, key, params)
    params.name = players.getRoleplayName(source)

    messages.notice(players.getNearby(source, serverConfig.gamesRange), 'games', key, params)
end

---@param source integer
---@param args { count?: string }
local function rollDice(source, args)
    if source == 0 or not guard.cooldown(source) then return end

    local count = tonumber(args.count) or 1

    if not diceKeys[count] then
        return messages.error(source, 'error.dice_count')
    end

    TriggerClientEvent('bd_sampchat:client:rolledDice', source)
    sendGameResult(source, diceKeys[count], {
        first = math.random(1, 6),
        second = math.random(1, 6),
        third = math.random(1, 6)
    })
end

---@param source integer
local function flipCoin(source)
    if source == 0 or not guard.cooldown(source) then return end

    sendGameResult(source, 'notice.coin', { side = locale(coinSides[math.random(#coinSides)]) })
end

---@param source integer
local function playRockPaperScissors(source)
    if source == 0 or not guard.cooldown(source) then return end

    sendGameResult(source, 'notice.rps', { side = locale(handSigns[math.random(#handSigns)]) })
end

commands.add({
    names = 'id',
    help = locale('help.id'),
    params = { { name = 'query', help = locale('param.query') } }
}, lookUpPlayer)

commands.add({ names = 'players', help = locale('help.players') }, countPlayers)

commands.add({
    names = 'dice',
    help = locale('help.dice'),
    params = { { name = 'count', help = locale('param.dice') } }
}, rollDice)

commands.add({ names = 'flipcoin', help = locale('help.flipcoin') }, flipCoin)
commands.add({ names = 'rps', help = locale('help.rps') }, playRockPaperScissors)
