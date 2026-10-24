local sharedConfig = require 'config.shared'
local text = require 'shared.text'

local hideStates = { active = 'always', always = 'hidden', hidden = 'active' }

local nuiReady = false
local inputOpen = false
local forcedHidden = false
local refreshAt = 0
local refreshScheduled = false
local hideState = GetResourceKvpString('hideState')

---@type table[]
local pending = {}

if not hideStates[hideState] then
    hideState = 'active'
end

---@param data table
local function sendNui(data)
    if not nuiReady then
        pending[#pending + 1] = data
        return
    end

    SendNUIMessage(data)
end

---@param message table | string
local function addMessage(message)
    if type(message) == 'string' then
        message = { args = { message } }
    end

    if type(message) ~= 'table' then return end

    sendNui({ action = 'addMessage', message = message })
end

---@param author string
---@param color number[]
---@param body string
local function addLegacyMessage(author, color, body)
    addMessage({
        color = color,
        multiline = true,
        args = author ~= '' and { author, body } or { body }
    })
end

---@param output string
local function addServerPrint(output)
    print(output)
    addMessage({ templateId = 'print', multiline = true, args = { output } })
end

---@param suggestions table
local function addSuggestions(suggestions)
    if type(suggestions) ~= 'table' then return end

    sendNui({ action = 'addSuggestions', suggestions = suggestions.name and { suggestions } or suggestions })
end

---@param name string
---@param help? string
---@param params? table
local function addSuggestion(name, help, params)
    addSuggestions({ { name = name, help = help, params = params } })
end

---@param name string
local function removeSuggestion(name)
    sendNui({ action = 'removeSuggestion', name = name })
end

---@param id string
---@param html string
local function addTemplate(id, html)
    sendNui({ action = 'addTemplate', id = id, html = html })
end

local function clearMessages()
    sendNui({ action = 'clear' })
end

local function clearLines()
    sendNui({ action = 'clearLines' })
end

---@param names string[]
---@param suggestions table[]
local function receiveServerCommands(names, suggestions)
    sendNui({ action = 'setServerCommands', names = names, suggestions = suggestions })
end

local function sendClientCommands()
    local registered = GetRegisteredCommands()
    local names = {}

    for i = 1, #registered do
        local name = registered[i].name

        if not name:find('^[%+%-_]') then
            names[#names + 1] = name
        end
    end

    sendNui({ action = 'setClientCommands', names = names })
end

local function refreshClientCommands()
    local remaining = refreshAt - GetGameTimer()

    if remaining > 0 then
        return SetTimeout(remaining, refreshClientCommands)
    end

    refreshScheduled = false
    sendClientCommands()
end

local function scheduleCommandRefresh()
    refreshAt = GetGameTimer() + 500

    if refreshScheduled then return end

    refreshScheduled = true
    SetTimeout(500, refreshClientCommands)
end

---@param typing boolean
local function setTyping(typing)
    if LocalPlayer.state.isTyping == typing then return end

    LocalPlayer.state:set('isTyping', typing, true)
end

local function closeInput()
    inputOpen = false
    SetNuiFocus(false, false)
    setTyping(false)
end

local function openInput()
    if not nuiReady or inputOpen or IsNuiFocused() or IsPauseMenuActive() then return end

    inputOpen = true
    setTyping(true)
    SendNUIMessage({ action = 'open' })
end

local function focusInput()
    if not inputOpen then return end

    SetNuiFocus(true, false)
end

local function cycleHideState()
    hideState = hideStates[hideState]
    SetResourceKvp('hideState', hideState)
    sendNui({ action = 'setHideState', state = hideState, announce = true })
end

---@param data { message?: string }
---@param cb fun(result: any)
local function submitMessage(data, cb)
    cb(1)
    closeInput()

    local message = text.sanitize(data.message, sharedConfig.maxLength)

    if message == '' then return end

    if message:sub(1, 1) == '/' then
        local command = message:sub(2)

        if command ~= '' then ExecuteCommand(command) end

        return
    end

    TriggerServerEvent('bd_sampchat:server:sentMessage', message)
end

---@param _ any
---@param cb fun(result: any)
local function cancelInput(_, cb)
    cb(1)
    closeInput()
end

---@param _ any
---@param cb fun(result: any)
local function finishLoading(_, cb)
    cb(1)

    nuiReady = true

    SendNUIMessage({
        action = 'init',
        settings = {
            maxLength = sharedConfig.maxLength,
            fadeTime = sharedConfig.fadeTime,
            history = sharedConfig.history
        },
        hideState = hideState,
        labels = {
            active = locale('hide_state.active'),
            always = locale('hide_state.always'),
            hidden = locale('hide_state.hidden')
        }
    })

    for i = 1, #pending do
        SendNUIMessage(pending[i])
    end

    pending = {}

    sendClientCommands()
    TriggerServerEvent('chat:init')
end

local function watchScreenState()
    while true do
        local hidden = IsScreenFadedOut() or IsPauseMenuActive()

        if hidden ~= forcedHidden then
            forcedHidden = hidden
            sendNui({ action = 'setForcedHidden', hidden = hidden })
        end

        Wait(250)
    end
end

lib.addKeybind({
    name = 'bd_sampchat_open',
    description = locale('keybind.open'),
    defaultKey = sharedConfig.openKey,
    onPressed = openInput,
    onReleased = focusInput
})

lib.addKeybind({
    name = 'bd_sampchat_toggle',
    description = locale('keybind.toggle'),
    defaultKey = sharedConfig.toggleKey,
    onPressed = cycleHideState
})

SetTextChatEnabled(false)
SetNuiFocus(false, false)
CreateThread(watchScreenState)

RegisterNUICallback('loaded', finishLoading)
RegisterNUICallback('submit', submitMessage)
RegisterNUICallback('cancel', cancelInput)

RegisterNetEvent('chat:addMessage', addMessage)
RegisterNetEvent('chatMessage', addLegacyMessage)
RegisterNetEvent('chat:addSuggestion', addSuggestion)
RegisterNetEvent('chat:addSuggestions', addSuggestions)
RegisterNetEvent('chat:removeSuggestion', removeSuggestion)
RegisterNetEvent('chat:addTemplate', addTemplate)
RegisterNetEvent('chat:clear', clearMessages)
RegisterNetEvent('bd_sampchat:client:clearedChat', clearLines)
RegisterNetEvent('__cfx_internal:serverPrint', addServerPrint)
RegisterNetEvent('bd_sampchat:client:receivedCommands', receiveServerCommands)
AddEventHandler('onClientResourceStart', scheduleCommandRefresh)
AddEventHandler('onClientResourceStop', scheduleCommandRefresh)

exports('addMessage', addMessage)
exports('addSuggestion', addSuggestion)
