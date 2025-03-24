local QBCore = exports['qb-core']:GetCoreObject()

-- Configuration
local blacklistedItems = { "INSERT ITEMS HERE" } -- Table of blacklisted items
local webhookURL = "INSERT WEBHOOK HERE"
local banReasonPrefix = "Possessing blacklisted item: "

-- In-memory ban list (initialized with sub-tables)
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
            -- Ensure loaded data has the correct structure
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

                -- Add player to ban list (both license and IP)
                bannedPlayers.licenses[identifiers.license] = true
                if identifiers.ip then
                    bannedPlayers.ips[identifiers.ip] = true
                end
                print("[DEBUG] Added to ban list - License: " .. identifiers.license .. ", IP: " .. (identifiers.ip or "N/A"))
                saveBans() -- Persist the ban

                -- Log to Discord with detailed info
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

                -- Kick the player
                DropPlayer(src, "You have been permanently banned for: " .. banReason .. "\nCheck our Discord for more info: discord.gg/inverserp")

                return -- Exit after banning to avoid multiple bans in one check
            end
        end
    end
end)

-- Check for bans on player join
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    deferrals.defer()
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    local ip = QBCore.Functions.GetIdentifier(src, 'ip')

    if (license and bannedPlayers.licenses[license]) or (ip and bannedPlayers.ips[ip]) then
        deferrals.done("You are permanently banned for a blacklisted item.\nCheck our Discord for more info: discord.gg/inverserp")
    else
        deferrals.done()
    end
end)

-- Unban command (can unban by license or IP)
RegisterCommand('unbancheat', function(source, args, rawCommand)
    if source ~= 0 then -- Restrict to server console or admins
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

    -- Check if it's a license
    if bannedPlayers.licenses[identifier] then
        bannedPlayers.licenses[identifier] = nil
        unbanned = true
        print("[DEBUG] Unbanned license: " .. identifier)
    end

    -- Check if it's an IP
    if bannedPlayers.ips[identifier] then
        bannedPlayers.ips[identifier] = nil
        unbanned = true
        print("[DEBUG] Unbanned IP: " .. identifier)
    end

    if unbanned then
        saveBans() -- Update the file
        sendToDiscord("Anti-Cheat", "Player with identifier **" .. identifier .. "** has been unbanned by an admin.", 65280) -- Green color
    else
        print("[ERROR] No ban found for identifier: " .. identifier)
    end
end, false)