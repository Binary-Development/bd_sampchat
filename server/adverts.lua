local serverConfig = require 'config.server'
local framework = require 'bridge.framework'
local commands = require 'server.modules.commands'
local messages = require 'server.modules.messages'
local players = require 'server.modules.players'
local logs = require 'server.modules.logs'

---@class AdvertConfig
---@field command string
---@field help string
---@field cost number
---@field cooldown number
---@field color string
---@field format string
---@field allowedJobs string[]
---@field blockedJobs string[]

local advertsEnabled = true

assert(serverConfig.payWith == 'cash' or serverConfig.payWith == 'bank', "config/server.lua: payWith must be 'cash' or 'bank'")

---@param advert AdvertConfig
---@param job FrameworkJob?
---@return boolean
local function isJobAllowed(advert, job)
    local jobName = job and job.name

    if #advert.allowedJobs > 0 and not lib.table.contains(advert.allowedJobs, jobName) then
        return false
    end

    return not (jobName and lib.table.contains(advert.blockedJobs, jobName))
end

---@param index integer
---@param advert AdvertConfig
local function registerAdvert(index, advert)
    local path = ('config/server.lua: adverts[%d]'):format(index)

    assert(type(advert.command) == 'string', ('%s.command is missing'):format(path))
    assert(type(advert.cost) == 'number' and advert.cost >= 0, ('%s.cost must be a number of 0 or more'):format(path))
    assert(type(advert.cooldown) == 'number' and advert.cooldown >= 0, ('%s.cooldown must be a number of 0 or more'):format(path))
    assert(type(advert.format) == 'string', ('%s.format is missing'):format(path))

    advert.allowedJobs = advert.allowedJobs or {}
    advert.blockedJobs = advert.blockedJobs or {}

    local cooldownMs = math.floor(advert.cooldown * 1000)

    ---@type table<integer, integer>
    local lastPosted = {}

    ---@param source integer
    ---@param message string
    local function postAdvert(source, message)
        if source == 0 then return end

        if not advertsEnabled then
            return messages.error(source, 'error.adverts_off')
        end

        local job = framework.getJob(source)

        if not isJobAllowed(advert, job) then
            return messages.error(source, 'error.advert_job')
        end

        local now = GetGameTimer()
        local last = lastPosted[source]

        if last and now - last < cooldownMs then
            return messages.error(source, 'error.advert_cooldown', { seconds = math.ceil((cooldownMs - (now - last)) / 1000) })
        end

        if advert.cost > 0 and not framework.removeMoney(source, serverConfig.payWith, advert.cost, ('/%s'):format(advert.command)) then
            return messages.error(source, 'error.no_money', { cost = ('$%s'):format(advert.cost) })
        end

        lastPosted[source] = now

        local jobLabel = job and job.label or ''

        messages.send(-1, {
            color = advert.color,
            template = advert.format,
            params = { id = source, name = players.getName(source), job = jobLabel, message = message }
        })

        logs.send('adverts', source, {
            kind = 'advert',
            message = message,
            fields = {
                { name = locale('log.command'), value = ('/%s'):format(advert.command), inline = true },
                { name = locale('log.job'), value = job and ('%s (%s)'):format(jobLabel, job.name) or locale('log.none'), inline = true },
            }
        })
    end

    local function forgetPlayer()
        lastPosted[source] = nil
    end

    commands.addText({ names = advert.command, help = advert.help }, postAdvert)
    AddEventHandler('playerDropped', forgetPlayer)
end

local function toggleAdverts()
    advertsEnabled = not advertsEnabled

    messages.notice(-1, 'info', advertsEnabled and 'notice.adverts_on' or 'notice.adverts_off')
end

for i = 1, #serverConfig.adverts do
    registerAdvert(i, serverConfig.adverts[i])
end

commands.add({
    names = 'togglead',
    help = locale('help.togglead'),
    minRank = serverConfig.staffCommands.toggleAdverts,
    configPath = 'config/server.lua: staffCommands.toggleAdverts'
}, toggleAdverts)
