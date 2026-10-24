local serverConfig = require 'config.server'

---@alias ChatParam string | number | { text: string, color?: string }

---@class ChatMessage
---@field color string
---@field template string
---@field params table<string, ChatParam>

local messages = {}

---@param params table<string, ChatParam>
---@return table<string, string>
local function toPlainText(params)
    local plain = {}

    for key, value in pairs(params) do
        plain[key] = type(value) == 'table' and value.text or tostring(value)
    end

    return plain
end

---@param target integer | integer[]
---@param message ChatMessage
function messages.send(target, message)
    if type(target) == 'table' then
        if #target == 0 then return end

        return lib.triggerClientEvent('chat:addMessage', target, message)
    end

    TriggerClientEvent('chat:addMessage', target, message)
end

---@param target integer | integer[]
---@param kind string key in config colors
---@param key string locale key
---@param params? table<string, ChatParam>
function messages.notice(target, kind, key, params)
    if target == 0 then
        return lib.print.info((locale(key):gsub('{(%w+)}', toPlainText(params or {}))))
    end

    messages.send(target, {
        color = serverConfig.colors[kind],
        template = locale(key),
        params = params or {}
    })
end

---@param target integer
---@param key string locale key
---@param params? table<string, ChatParam>
---@return false
function messages.error(target, key, params)
    messages.notice(target, 'error', key, params)

    return false
end

return messages
