# Conquest XP (ConquestXP)

An XP and luminance tracker plugin for the AC:Unreal client, made for the Conquest server. XP figures use the same calculation as the client's built-in Hunt Ledger. Luminance comes from Conquest's `/lph` command, because Conquest banks luminance instead of adding it to your character. The plugin runs whenever it is enabled and there are no start/stop buttons.

## Features

- Same layout and text size as the built-in Hunt Ledger.
- XP and luminance for the last 5 minutes, per hour, and in total.
- Estimated time to your next level, using Conquest's level table (levels 1-300).
- Starts luminance tracking automatically when you log in and refreshes it on an interval (adjustable in settings).
- `/lph` replies are hidden from your chat windows.
- Automatically deposits all valid items into your bank with `/b d` on an interval (adjustable in settings).

## Requirements

- AC:Unreal client build 123 (2026.10.18) or newer.
- The Conquest server. `/lph` and `/b d` are Conquest commands; on other servers the luminance column stays at `--` and `/b d` isn't recognized.

## Install

1. Download the latest zip from the [Releases](../../releases) page.
2. Unzip into `ACUnreal\Saved\ClientPlugins\Installed`. The zip contains the `ConquestXP` folder, so the path ends in `Installed\ConquestXP\plugin.json`.
3. Open the plugin menu, press **Refresh**, then **Enable** Conquest XP.

## Updating

Replace the files in `Installed\ConquestXP` with the new download and press **Refresh** in Manage Plugins. Your settings are saved outside this folder, so they are retained.

## In game

### The window

| | XP | Luminance |
|---|---|---|
| **Last 5 min** | XP gained in the last 5 minutes | Conquest's 5-minute luminance rate, divided by 12 |
| **Per hour** | XP since login or Reset, divided by the time elapsed | Conquest's luminance per hour |
| **Total** | XP gained since login or Reset | luminance earned since tracking started |

- **Next level (est.)**: the XP still needed for your next level, divided by your average XP rate since login or Reset. Before any XP comes in it shows `Waiting for XP`. At level 300 it shows `Max level`.
- **Reset**: clears the XP figures and restarts luminance tracking (`/lph restart`).
- **Settings**: shows or hides the settings below.

XP only counts increases, so spending XP on skills or attributes never lowers your figures. Luminance shows `--` until the first `/lph` reply arrives, or while luminance tracking is off.

### Settings

- **Luminance tracking**: on by default. Turning it off sends `/lph stop`, and turning it on sends `/lph start`.
- **/lph update interval**: seconds between automatic `/lph` reads (30-300, default 90).
- **Automatic /b d**: on by default. Deposits all valid items into your bank on the interval.
- **/b d interval (minutes)**: minutes between automatic `/b d` (2-10, default 5). The first deposit comes one interval after you log in, turn the option on, or change the interval.

Settings are saved per character.

### What it sends

- `/lph start`: 8 seconds after you log in.
- `/lph`: on the `/lph` update interval.
- `/lph restart`: when you press Reset.
- `/b d`: on the `/b d` interval, while Automatic /b d is on.

Commands go out one at a time, at most one per second, so they never collide. Every `[LPH]` reply is hidden from your chat windows while the plugin runs, including replies to a `/lph` you type yourself. Other chat is not affected.

## Permissions

The plugin uses the following service requests:

| Permission | Used for |
|---|---|
| data | your total XP and level |
| chat | reading the `/lph` replies |
| chat_filter | hiding the `[LPH]` replies from your chat windows |
| say | sending `/lph` and `/b d` |
| ui | its window |
| state | saving your settings |

## Credits

- XP calculation follows the AC:Unreal Hunt Ledger by Thwargle.
- Level table from the Conquest server.

## License

MIT. See [LICENSE](LICENSE).
