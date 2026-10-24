local sharedConfig = require 'config.shared'
local ranks = require 'server.modules.ranks'
local messages = require 'server.modules.messages'
local guard = require 'server.modules.guard'
local text = require 'shared.text'

---@class CommandParam
---@field name string
---@field help string

---@class CommandDefinition
---@field names string | string[]
---@field help string
---@field params? CommandParam[]
---@field minRank? string
---@field configPath? string

---@class TextCommandDefinition : CommandDefinition
---@field maxLength? integer
---@field textParam? CommandParam

---@class Suggestion
---@field name string
---@field help string
---@field params CommandParam[]

local commands = {}

---@type table<string, Suggestion>
local suggestions = {}

---@param raw string
---@param skip integer words to skip, the command name counts as one
---@return string
function commands.getTextAfter(raw, skip)
    local position = 1

    for _ = 1, skip do
        local _, finish = raw:find('^%s*%S+', position)
        if not finish then return '' end

        position = finish + 1
    end

    return raw:sub(position)
end

---@param params CommandParam[]
---@return CommandParam[]
local function toOptional(params)
    local optional = {}

    for i = 1, #params do
        optional[i] = { name = params[i].name, help = params[i].help, optional = true }
    end

    return optional
end

---@param definition CommandDefinition
---@param handler fun(source: integer, args: table, raw: string)
function commands.add(definition, handler)
    local names = type(definition.names) == 'table' and definition.names or { definition.names }
    local params = definition.params or {}
    local restricted = definition.minRank and ranks.principalsFrom(definition.minRank, definition.configPath or 'config/server.lua')

    for i = 1, #names do
        suggestions[names[i]] = { name = ('/%s'):format(names[i]), help = definition.help, params = params }
    end

    lib.addCommand(names, {
        help = definition.help,
        params = toOptional(params),
        restricted = restricted
    }, handler)
end

---@param definition TextCommandDefinition
---@param handler fun(source: integer, message: string, args: table)
function commands.addText(definition, handler)
    local names = type(definition.names) == 'table' and definition.names or { definition.names }
    local params = definition.params or {}
    local maxLength = definition.maxLength or sharedConfig.maxLength
    local textParam = definition.textParam or { name = 'message', help = locale('param.message') }
    local usageParts = { ('/%s'):format(names[1]) }

    for i = 1, #params do
        usageParts[#usageParts + 1] = ('[%s]'):format(params[i].name)
    end

    usageParts[#usageParts + 1] = ('[%s]'):format(textParam.name)

    local usage = table.concat(usageParts, ' ')
    local allParams = lib.table.deepclone(params)

    allParams[#allParams + 1] = textParam

    ---@param source integer
    ---@param args table
    ---@param raw string
    local function runTextCommand(source, args, raw)
        local after = commands.getTextAfter(raw, 1 + #params)
        local message = text.clean(after, maxLength)

        if message == '' then
            return messages.notice(source, 'info', 'error.usage', { usage = usage })
        end

        local context = ('/%s'):format(text.clean(raw:sub(1, #raw - #after), 64))

        if not guard.allow(source, message, context) then return end

        handler(source, message, args)
    end

    commands.add({
        names = names,
        help = definition.help,
        params = allParams,
        minRank = definition.minRank,
        configPath = definition.configPath
    }, runTextCommand)
end

---@param source integer
---@param registered { name: string }[]
---@return string[] names
---@return Suggestion[] known
function commands.getAllowed(source, registered)
    local names = {}
    local known = {}

    for i = 1, #registered do
        local name = registered[i].name

        if IsPlayerAceAllowed(source, ('command.%s'):format(name)) then
            names[#names + 1] = name
            known[#known + 1] = suggestions[name]
        end
    end

    return names, known
end

return commands
