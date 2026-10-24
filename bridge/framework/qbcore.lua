local createBridge = require 'bridge.framework.qblike'
local QBCore = exports['qb-core']:GetCoreObject()

return createBridge(QBCore.Functions.GetPlayer)
