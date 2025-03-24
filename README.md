# jake-AntiCheat

**jake-AntiCheat** is a lightweight, server-side anti-cheat script for FiveM servers running the QB-Core framework. Designed to detect and ban players possessing blacklisted items, this script offers a simple yet effective solution for maintaining fair gameplay without relying on a database.

## Features
- **Multi-Item Detection**: Monitors player inventories for multiple configurable blacklisted items (e.g., `weapon_redarp`, `weapon_blueglocks`, `weapon_redm4a1`).
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
- **Trigger Inventory Check**: Use the following server-side event to scan a player’s inventory:
  ```lua
  TriggerServerEvent('qb-anticheat:server:checkInventory')
  ```
  This can be called from another script, a command, or a server event.

- **Unban Players**: Admins can unban players via console or in-game:
  ```
  /unbancheat <license or ip>
  ```
  Example:
  ```
  /unbancheat license:03831582c67e91338c580198b3758ffe2fb617e4
  /unbancheat ip:26.55.118.146
  ```

## Configuration
Edit `server.lua` to customize the script:
- **Blacklisted Items**: Modify the `blacklistedItems` table to add or remove items:
  ```lua
  local blacklistedItems = { "weapon_redarp", "weapon_blueglocks", "weapon_redm4a1" }
  ```
- **Webhook URL**: Replace the `webhookURL` with your Discord webhook:
  ```lua
  local webhookURL = "https://discord.com/api/webhooks/your-webhook-url-here"
  ```
- **Ban Reason**: Adjust `banReasonPrefix` if needed:
  ```lua
  local banReasonPrefix = "Possessing blacklisted item: "
  ```

### bans.json
The `bans.json` file stores banned licenses and IPs. It’s auto-generated but can be pre-populated:
```json
{
    "licenses": {
        "license:03831582c67e91338c580198b3758ffe2fb617e4": true
    },
    "ips": {
        "ip:26.55.118.146": true
    }
}
```
- Leave it as `{ "licenses": {}, "ips": {} }` for an empty start.

## Dependencies
- [QB-Core](https://github.com/qbcore-framework/qb-core) - Required for player data and permissions.

## Testing
1. Start your server with `jake-anticheat` ensured.
2. Join as a player and give yourself a blacklisted item (e.g., via a command or script).
3. Trigger the inventory check:
   ```lua
   TriggerServerEvent('qb-anticheat:server:checkInventory')
   ```
4. Verify:
   - You’re kicked with a ban message.
   - A Discord log appears.
   - `bans.json` updates with your license and IP.
5. Attempt to rejoin—you should be blocked.
6. Unban yourself with `/unbancheat` and test rejoining.

## Notes
- **Persistence**: Bans are stored in `bans.json`, making them lightweight but non-relational (no SQL required).
- **Scalability**: Ideal for small to medium servers. Larger servers may benefit from a database for better ban management.
- **Permissions**: Ensure QB-Core’s admin permissions are configured (e.g., `admin` role) for the unban command.


## License
This project is licensed under the [MIT License](LICENSE) - free to use, modify, and distribute with attribution.
