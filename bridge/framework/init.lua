local pick = require 'bridge.pick'
local serverConfig = require 'config.server'

---@class FrameworkJob
---@field name string
---@field label string

---@class FrameworkBridge
---@field getName fun(source: integer): string?
---@field getJob fun(source: integer): FrameworkJob?
---@field removeMoney fun(source: integer, account: 'cash' | 'bank', amount: number, reason: string): boolean

local name = pick.choose({
    kind = 'framework',
    setting = serverConfig.framework,
    options = { 'esx', 'qbcore', 'qbox', 'ox', 'nd', 'standalone' },
    detection = {
        { resource = 'qbx_core', name = 'qbox' },
        { resource = 'es_extended', name = 'esx' },
        { resource = 'ox_core', name = 'ox' },
        { resource = 'ND_Core', name = 'nd' },
        { resource = 'qb-core', name = 'qbcore' },
    },
    fallback = 'standalone'
})

---@type FrameworkBridge
return require(('bridge.framework.%s'):format(name))
