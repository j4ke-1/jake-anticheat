# jake-antiCheat

**jake-antiCheat** is a lightweight anti-cheat script for FiveM servers running the QB-Core framework. Designed to detect and ban players for possessing blacklisted items or using hacked weapons, this script ensures fair gameplay without requiring a database. It combines server-side logic with client-side monitoring for robust protection.

## Features
- **Multi-Item Detection**: Monitors player inventories for configurable blacklisted items (e.g., `weapon_redarp`, `weapon_blueglocks`, `weapon_redm4a1`).
- **Hacked Weapon Detection**: Automatically bans players holding weapons not in their QB-Core inventory, checked every 30 seconds.
- **Dual Ban Enforcement**: Bans players by both license and IP address to prevent immediate rejoining.
- **Persistent Bans**: Stores bans in a `bans.json` file, ensuring they persist across server restarts.
- **Admin Unban Command**: Includes a `/unbancheat` command (restricted to admins) to remove bans by license or IP.
- **Discord Logging**: Sends detailed ban and unban notifications to a Discord webhook with player identifiers (license, Discord ID, IP).
- **QB-Core Integration**: Seamlessly integrates with QB-Core for player data and permission checks.

## Installation
1. Download or clone this repository.
2. Place the `jake-anticheat` folder in your FiveM `resources` directory (e.g., `resources/[scripts]/jake-anticheat`).
3. Add the following line to your `server.cfg` after `qb-core`:
   ```
   ensure jake-anticheat
   ```
4. (Optional) Pre-populate `bans.json` with existing bans (see [Configuration](#configuration)).

## Usage
- **Automatic Checks**: The script runs every 30 seconds to scan:
  - Player inventories for blacklisted items.
  - Weapons in hand to ensure they match the inventory.
- **Manual Inventory Check**: Trigger a one-time scan with:
  ```lua
  TriggerServerEvent('qb-anticheat:server:checkInventory')
  ```
  This can be called from another script, command, or server event.
- **Unban Players**: Admins can unban via console or in-game:
  ```
  /unbancheat <license or ip>
  ```
  Example:
  ```
  /unbancheat license:XXXXXXXXXXXXXXX
  /unbancheat ip:XXXXXXXXXXXXXXX
  ```

## Configuration
Edit `server.lua` to customize the script:
- **Blacklisted Items**: Modify the `blacklistedItems` table:
  ```lua
  local blacklistedItems = { "weapon_redarp", "weapon_blueglocks", "weapon_redm4a1" }
  ```
- **Webhook URL**: Replace with your Discord webhook:
  ```lua
  local webhookURL = "https://discord.com/api/webhooks/your-webhook-url-here"
  ```
- **Ban Reasons**: Adjust if needed:
  ```lua
  local banReasonPrefix = "Possessing blacklisted item: "
  local banReasonHackedWeapon = "Using hacked weapon not in inventory"
  ```

Edit `client.lua` for timing:
- **Check Interval**: Change the scan frequency (default: 30 seconds):
  ```lua
  Citizen.Wait(30000) -- Adjust to 10000 for 10 seconds, etc.
  ```

### bans.json
The `bans.json` file stores banned licenses and IPs. It’s auto-generated but can be pre-populated:
```json
{
    "licenses": {
        "license:XXXXXXXXXXXX": true
    },
    "ips": {
        "ip:XXXXXXXXXX": true
    }
}
```
- Start with `{ "licenses": {}, "ips": {} }` for an empty list.

## Dependencies
- [QB-Core](https://github.com/qbcore-framework/qb-core) - Required for player data and permissions.

## Testing
1. Start your server with `jake-anticheat` ensured.
2. Join as a player and:
   - Add a blacklisted item (e.g., `weapon_redarp`) via a command or script.
   - Equip a weapon not in your inventory (e.g., `WEAPON_PISTOL`) using:
     ```lua
     GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PISTOL"), 200, false, true)
     ```
3. Wait up to 30 seconds for automatic checks or trigger manually:
   ```lua
   TriggerServerEvent('qb-anticheat:server:checkInventory')
   ```
4. Verify:
   - You’re kicked with a ban message (e.g., "Possessing blacklisted item: weapon_redarp" or "Using hacked weapon not in inventory").
   - A Discord log appears.
   - `bans.json` updates with your license and IP.
5. Attempt to rejoin—you should be blocked.
6. Unban with `/unbancheat` and test rejoining.

## Notes
- **Persistence**: Bans are stored in `bans.json`, keeping it lightweight and database-free.
- **Scalability**: Best for small to medium servers; larger setups might need a database.
- **Permissions**: Ensure QB-Core’s admin permissions (e.g., `admin` role) are set for `/unbancheat`.
- **Performance**: The 30-second client check interval balances detection and server load—adjust as needed.

## License
This project is licensed under the [MIT License](LICENSE) - free to use, modify, and distribute with attribution.
