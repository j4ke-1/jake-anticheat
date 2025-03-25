local QBCore = exports['qb-core']:GetCoreObject()

-- Configuration
local blacklistedItems = { "INSERT ITEMS HERE" } -- Table of blacklisted items
local webhookURL = "INSERT WEBHOOK HERE"
local banReasonPrefix = "Possessing blacklisted item: "
local banReasonHackedWeapon = "Using hacked weapon not in inventory"

-- In-memory ban list
local bannedPlayers = {
    licenses = {},
    ips = {}
}

-- Load bans from file on script start
local function loadBans()
    local file = LoadResourceFile(GetCurrentResourceName(), "bans.json")
    if file then
        local loadedBans = json.decode(file)
        if loadedBans and type(loadedBans) == "table" then
            bannedPlayers.licenses = loadedBans.licenses or {}
            bannedPlayers.ips = loadedBans.ips or {}
            print("[DEBUG] Loaded bans from bans.json: " .. json.encode(bannedPlayers))
        else
            print("[DEBUG] Invalid bans.json format, using default empty ban list.")
        end
    else
        print("[DEBUG] No bans.json found, starting with empty ban list.")
    end
end

-- Save bans to file
local function saveBans()
    SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(bannedPlayers), -1)
    print("[DEBUG] Saved bans to bans.json")
end

-- Load bans when script starts
loadBans()

local function sendToDiscord(name, message, color)
    local embed = {
        {
            ["color"] = color or 16711680,
            ["title"] = "Anti-Cheat Log",
            ["description"] = message,
            ["footer"] = { ["text"] = "Time: " .. os.date("%Y-%m-%d %H:%M:%S") }
        }
    }
    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({username = "Anti-Cheat Bot", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- Check inventory for blacklisted items
RegisterNetEvent('qb-anticheat:server:checkInventory', function()
    local src = source
    print("[DEBUG] Event triggered for source: " .. tostring(src))
    if not src or src <= 0 then
        print("[DEBUG] Invalid source ID: " .. tostring(src))
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[DEBUG] Player not found for source: " .. src)
        return 
    end

    local inventory = Player.PlayerData.items
    for _, item in pairs(inventory) do
        for _, bannedItem in ipairs(blacklistedItems) do
            if item.name == bannedItem then
                local identifiers = {
                    license = QBCore.Functions.GetIdentifier(src, 'license'),
                    discord = QBCore.Functions.GetIdentifier(src, 'discord'),
                    ip = QBCore.Functions.GetIdentifier(src, 'ip')
                }
                local banReason = banReasonPrefix .. bannedItem

                bannedPlayers.licenses[identifiers.license] = true
                if identifiers.ip then
                    bannedPlayers.ips[identifiers.ip] = true
                end
                print("[DEBUG] Added to ban list - License: " .. identifiers.license .. ", IP: " .. (identifiers.ip or "N/A"))
                saveBans()

                local message = string.format(
                    "Player **%s** (ID: %d) was permanently banned for possessing **%s**.\n" ..
                    "Identifiers:\n- License: %s\n- Discord: %s\n- IP: %s",
                    GetPlayerName(src),
                    src,
                    bannedItem,
                    identifiers.license or "N/A",
                    identifiers.discord or "N/A",
                    identifiers.ip or "N/A"
                )
                sendToDiscord("Anti-Cheat", message, 16711680)

                DropPlayer(src, "You have been permanently banned for: " .. banReason .. "\nCheck our Discord for more info: discord.gg/inverserp")
                return
            end
        end
    end
end)

-- Check for hacked weapons in hand
RegisterNetEvent('qb-anticheat:server:checkWeaponInHand', function(currentWeapon)
    local src = source
    if not src or src <= 0 then
        print("[DEBUG] Invalid source ID for weapon check: " .. tostring(src))
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[DEBUG] Player not found for weapon check source: " .. src)
        return 
    end

    local inventory = Player.PlayerData.items
    local weaponInInventory = false
    local weaponName = GetWeaponNameFromHash(currentWeapon)

    -- Check if the weapon in hand is in the inventory
    for _, item in pairs(inventory) do
        if item.name == weaponName then
            weaponInInventory = true
            break
        end
    end

    -- Ban if weapon is not in inventory
    if not weaponInInventory and weaponName then
        local identifiers = {
            license = QBCore.Functions.GetIdentifier(src, 'license'),
            discord = QBCore.Functions.GetIdentifier(src, 'discord'),
            ip = QBCore.Functions.GetIdentifier(src, 'ip')
        }

        bannedPlayers.licenses[identifiers.license] = true
        if identifiers.ip then
            bannedPlayers.ips[identifiers.ip] = true
        end
        print("[DEBUG] Added to ban list for hacked weapon - License: " .. identifiers.license .. ", IP: " .. (identifiers.ip or "N/A"))
        saveBans()

        local message = string.format(
            "Player **%s** (ID: %d) was permanently banned for using hacked weapon **%s** not in inventory.\n" ..
            "Identifiers:\n- License: %s\n- Discord: %s\n- IP: %s",
            GetPlayerName(src),
            src,
            weaponName,
            identifiers.license or "N/A",
            identifiers.discord or "N/A",
            identifiers.ip or "N/A"
        )
        sendToDiscord("Anti-Cheat", message, 16711680)

        DropPlayer(src, "You have been permanently banned for: " .. banReasonHackedWeapon .. "\nCheck our Discord for more info: discord.gg/inverserp")
    end
end)

-- Utility function to get weapon name from hash (approximation)
function GetWeaponNameFromHash(weaponHash)
    for _, weapon in pairs(QBCore.Shared.Weapons) do
        if GetHashKey(weapon.name) == weaponHash then
            return weapon.name
        end
    end
    return nil -- Unknown weapon
end

-- Check for bans on player join
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    deferrals.defer()
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    local ip = QBCore.Functions.GetIdentifier(src, 'ip')

    if (license and bannedPlayers.licenses[license]) or (ip and bannedPlayers.ips[ip]) then
        deferrals.done("You are permanently banned for a blacklisted item or hacked weapon.\nCheck our Discord for more info: discord.gg/inverserp")
    else
        deferrals.done()
    end
end)

-- Unban command
RegisterCommand('unbancheat', function(source, args, rawCommand)
    if source ~= 0 then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player or not QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('chatMessage', source, '^1You do not have permission to use this command.')
            return
        end
    end

    if #args < 1 then
        print("[ERROR] Usage: /unbancheat <license or ip>")
        return
    end

    local identifier = args[1]
    local unbanned = false

    if bannedPlayers.licenses[identifier] then
        bannedPlayers.licenses[identifier] = nil
        unbanned = true
        print("[DEBUG] Unbanned license: " .. identifier)
    end

    if bannedPlayers.ips[identifier] then
        bannedPlayers.ips[identifier] = nil
        unbanned = true
        print("[DEBUG] Unbanned IP: " .. identifier)
    end

    if unbanned then
        saveBans()
        sendToDiscord("Anti-Cheat", "Player with identifier **" .. identifier .. "** has been unbanned by an admin.", 65280)
    else
        print("[ERROR] No ban found for identifier: " .. identifier)
    end
end, false)
