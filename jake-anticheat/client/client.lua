local QBCore = exports['qb-core']:GetCoreObject()

-- Check inventory every 30 seconds
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000) -- 30 seconds
        TriggerServerEvent('qb-anticheat:server:checkInventory')
    end
end)