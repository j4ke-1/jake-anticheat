local QBCore = exports['qb-core']:GetCoreObject()

-- Check inventory and weapon in hand every 30 seconds
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000) -- Check every 30 seconds
        local ped = PlayerPedId()
        local weaponHash = GetSelectedPedWeapon(ped)

        -- Trigger server-side checks
        TriggerServerEvent('qb-anticheat:server:checkInventory') -- Check blacklisted items
        if weaponHash ~= GetHashKey("WEAPON_UNARMED") then -- Ignore unarmed state
            TriggerServerEvent('qb-anticheat:server:checkWeaponInHand', weaponHash) -- Check weapon in hand
        end
    end
end)
