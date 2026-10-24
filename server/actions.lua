local serverConfig = require 'config.server'
local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'

local actions = serverConfig.actions
local maxLength = 150

assert(type(actions.range) == 'number' and actions.range > 0, 'config/server.lua: actions.range must be a number above 0')

---@param format string
---@param values table<string, string>
---@return string
local function fill(format, values)
    return (format:gsub('{(%w+)}', values))
end

---@param index integer
---@param action { command: string, help: string, format: string }
local function registerAction(index, action)
    assert(type(action.command) == 'string' and type(action.format) == 'string',
        ('config/server.lua: actions.commands[%d] needs a command and a format'):format(index))

    ---@param source integer
    ---@param message string
    local function showAction(source, message)
        local shown = fill(action.format, {
            name = players.getRoleplayName(source),
            message = message:gsub('[~<>]', '')
        })

        local nearby = players.getNearby(source, actions.range)

        if #nearby > 0 then
            lib.triggerClientEvent('bd_sampchat:client:showedAction', nearby, source, shown)
        end

        messages.notice(source, 'action', 'notice.action_echo', { text = shown })
    end

    commands.addText({ names = action.command, help = action.help, maxLength = maxLength }, showAction)
end

for i = 1, #actions.commands do
    registerAction(i, actions.commands[i])
end
