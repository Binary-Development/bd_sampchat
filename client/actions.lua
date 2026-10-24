local sharedConfig = require 'config.shared'

local actionConfig = sharedConfig.action
local typingConfig = sharedConfig.typing
local durationMs = math.floor(actionConfig.duration * 1000)
local textScale = actionConfig.scale
local red, green, blue = actionConfig.color[1], actionConfig.color[2], actionConfig.color[3]
local chunkSize = 99
local scanIntervalMs = 250
local diceDict = 'anim@amb@carmeet@listen_music@male_a@trans'

---@class OverheadText
---@field label string
---@field chunks string[]

---@class ShownAction : OverheadText
---@field expires integer

---@class NearbyTyper
---@field serverId integer
---@field ped integer

---@type table<integer, ShownAction>
local shown = {}
local shownCount = 0
local rendering = false

---@type OverheadText
local typingText = { label = 'STRING', chunks = { '...' } }

---@type table<integer, true>
local typing = {}
local typingCount = 0
local scanning = false

---@type NearbyTyper[]
local nearbyTyping = {}

---@param value string
---@return string[]
local function splitText(value)
    local chunks = {}
    local position = 1

    while position <= #value do
        local finish = math.min(position + chunkSize - 1, #value)

        while finish < #value and finish > position and value:byte(finish + 1) & 0xC0 == 0x80 do
            finish -= 1
        end

        chunks[#chunks + 1] = value:sub(position, finish)
        position = finish + 1
    end

    return chunks
end

---@param ped integer
---@param camCoords vector3
---@param fov number
---@return vector3 coords
---@return number scale
local function getDrawPoint(ped, camCoords, fov)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 1.0)

    return coords, textScale * 200 / (fov * math.max(#(coords - camCoords), 1.0))
end

---@param coords vector3
---@param scale number
---@param overhead OverheadText
local function drawOverhead(coords, scale, overhead)
    local chunks = overhead.chunks

    SetTextScale(0.0, scale)
    SetTextFont(4)
    SetTextColour(red, green, blue, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText(overhead.label)

    for i = 1, #chunks do
        AddTextComponentSubstringPlayerName(chunks[i])
    end

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

---@param camCoords vector3
---@param fov number
local function drawActions(camCoords, fov)
    local now = GetGameTimer()

    for serverId, action in pairs(shown) do
        local player = GetPlayerFromServerId(serverId)
        local ped = player ~= -1 and GetPlayerPed(player) or 0

        if now > action.expires or ped == 0 then
            shown[serverId] = nil
            shownCount -= 1
        else
            local coords, scale = getDrawPoint(ped, camCoords, fov)

            drawOverhead(coords, scale, action)
        end
    end
end

---@param camCoords vector3
---@param fov number
local function drawTyping(camCoords, fov)
    for i = 1, #nearbyTyping do
        local typer = nearbyTyping[i]

        if typing[typer.serverId] and not shown[typer.serverId] and DoesEntityExist(typer.ped) then
            local coords, scale = getDrawPoint(typer.ped, camCoords, fov)

            drawOverhead(coords, scale, typingText)
        end
    end
end

local function renderOverhead()
    while shownCount > 0 or #nearbyTyping > 0 do
        local camCoords = GetGameplayCamCoord()
        local fov = GetGameplayCamFov()

        drawActions(camCoords, fov)
        drawTyping(camCoords, fov)

        Wait(0)
    end

    rendering = false
end

local function startRendering()
    if rendering then return end

    rendering = true
    CreateThread(renderOverhead)
end

---@param serverId integer
---@param value string
local function showAction(serverId, value)
    if type(serverId) ~= 'number' or type(value) ~= 'string' then return end

    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return end

    local ped = GetPlayerPed(player)

    if serverId ~= cache.serverId and not HasEntityClearLosToEntity(cache.ped, ped, 17) then return end

    if not shown[serverId] then
        shownCount += 1
    end

    shown[serverId] = {
        label = #value > chunkSize and 'CELL_EMAIL_BCON' or 'STRING',
        chunks = splitText(value),
        expires = GetGameTimer() + durationMs
    }

    startRendering()
end

---@return NearbyTyper[]
local function findNearbyTyping()
    local origin = GetEntityCoords(cache.ped)
    local found = {}

    for serverId in pairs(typing) do
        local player = GetPlayerFromServerId(serverId)

        if player == -1 then
            typing[serverId] = nil
            typingCount -= 1
        else
            local ped = GetPlayerPed(player)

            if #(GetEntityCoords(ped) - origin) <= typingConfig.range and HasEntityClearLosToEntity(cache.ped, ped, 17) then
                found[#found + 1] = { serverId = serverId, ped = ped }
            end
        end
    end

    return found
end

local function scanTyping()
    while typingCount > 0 do
        nearbyTyping = findNearbyTyping()

        if #nearbyTyping > 0 then
            startRendering()
        end

        Wait(scanIntervalMs)
    end

    nearbyTyping = {}
    scanning = false
end

---@param bagName string
---@param _ string
---@param value any
local function updateTyping(bagName, _, value)
    local serverId = tonumber(bagName:match('^player:(%d+)$'))
    if not serverId or serverId == cache.serverId then return end

    local isTyping = value == true

    if isTyping == (typing[serverId] == true) then return end

    typing[serverId] = isTyping or nil
    typingCount += isTyping and 1 or -1

    if not isTyping or scanning then return end

    scanning = true
    CreateThread(scanTyping)
end

local function playDiceRoll()
    lib.playAnim(cache.ped, diceDict, 'a_trans_d', 8.0, 1.0, 2000, 49)
end

if typingConfig.enabled then
    assert(type(typingConfig.range) == 'number' and typingConfig.range > 0, 'config/shared.lua: typing.range must be a number above 0')
    AddStateBagChangeHandler('isTyping', nil, updateTyping)
end

RegisterNetEvent('bd_sampchat:client:showedAction', showAction)
RegisterNetEvent('bd_sampchat:client:rolledDice', playDiceRoll)
