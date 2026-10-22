# ConquestXP

An XP and luminance tracker plugin for the AC:Unreal client made specifically for the Conquest server. XP figures use the same calculation as the client's built-in Hunt Ledger, but includes the extended 275-300 xp table. Luminance comes from server `/lph` commands, and your bank balances from the server `/b` command.

<img width="213" height="80" alt="conquestxp_2" src="https://github.com/user-attachments/assets/20599288-c4f3-48f6-8470-98cb71ca80c8" />

## Features

- Same layout as the built-in Hunt Ledger, with larger text sized to stay sharp.
- XP and luminance for the last 5 minutes and per hour, your XP total, and the luminance in your bank.
- Estimated time to your next level, using the Conquest specific level table (levels 1-300).
- Bank balances with their item symbols: MMDs, Conquest Coins, Dragon Coins and Legendary Keys.
- Conquest Coins earned per hour, shown in brackets beside the coin count.
- Starts luminance tracking automatically when you log in and refreshes it on an interval (adjustable in settings).
- Reads your bank balances with `/b` 30 seconds after you log in, then on an interval (adjustable in settings).
- `/lph` replies, and the replies to the plugin's own `/b`, are hidden from your chat windows.
- Automatically deposits all valid items into your bank with `/b d` on an interval (adjustable in settings).

## Requirements

- AC:Unreal client build 126 (2026.10.19) or newer.
- The Conquest server. `/lph`, `/b` and `/b d` are Conquest specific commands; on other servers the luminance and bank values stay at `--` and `/b d` isn't recognized.

## Install

1. Download the latest zip from the [Releases](../../releases) page.
2. Unzip into `ACUnreal\Saved\ClientPlugins\Installed`. The zip contains the `ConquestXP` folder, so the path ends in `Installed\ConquestXP\plugin.json`.
3. Open the plugin menu, press **Refresh**, then **Enable** Conquest XP.

## Updating

Replace the files in `Installed\ConquestXP` with the new download and press **Refresh** in Manage Plugins. Your settings are saved outside this folder, so they are retained.

## In game

- The plugin runs whenever it is enabled and there are no specific start/stop buttons. To turn it off, disable it in the plugins menu.

### The window

| | XP | Luminance |
|---|---|---|
| **Last 5 min** | XP gained in the last 5 minutes | Conquest's 5-minute luminance rate, divided by 12 |
| **Per hour** | XP since login or Reset, divided by the time elapsed | Conquest's luminance per hour |
| **Total** | XP gained since login or Reset | the luminance in your bank, from `/b` |

- **Next level:** the estimated time to your next level: the XP still needed, divided by your average XP rate since login or Reset. Before any XP comes in it shows `Waiting for XP`. At level 300 it shows `Max level`.
- **Bank column:** to the right of Luminance, each item's symbol and the amount in your bank:
  - MMDs: your bank pyreals divided by 250,000, rounded down
  - Conquest Coins, with the coins earned per hour in brackets, e.g. `1,929 (117/h)`
  - Dragon Coins
  - Legendary Keys

  Hover over a symbol to see its name.
- **Reset**: clears the XP figures and the coins per hour, and restarts luminance tracking (`/lph restart`).
- **Settings**: shows or hides the settings below.

The XP figures refresh every 15 seconds, and immediately after Reset or a level-up. XP only counts increases, so spending XP on skills or attributes never lowers your figures. The luminance rates show `--` until the first `/lph` reply arrives, or while luminance tracking is off. Total luminance and the bank column show `--` until the first `/b` reply, and update whenever a `/b` reply arrives, including a `/b` you type yourself.

Coins per hour adds up the coins that arrive in your bank between `/b` replies, divided by the time since the first reply after you log in or press Reset. It appears from the second `/b` reply (about 5 minutes after login) and updates with each `/b`. Spending coins doesn't lower it. Coins still in your packs are counted once `/b d` deposits them.

### Settings

- **Luminance tracking**: on by default. Turning it off sends `/lph stop`, and turning it on sends `/lph start`.
- **/lph update interval**: seconds between automatic `/lph` reads (30-300, default 90).
- **Automatic /b d**: on by default. Deposits all valid items into your bank on the interval.
- **/b d interval (minutes)**: minutes between automatic `/b d` (2-10, default 5). The first deposit comes one interval after you log in, turn the option on, or change the interval.
- **/b update interval (minutes)**: minutes between automatic `/b` reads of your bank balances (2-10, default 5).

Settings are saved per character.

### What it sends

- `/lph start`: 8 seconds after you log in.
- `/lph`: on the `/lph` update interval.
- `/lph restart`: when you press Reset.
- `/b`: 30 seconds after you log in, then on the `/b` update interval.
- `/b d`: on the `/b d` interval, while Automatic /b d is on.

Commands go out one at a time, at most one per second, so they never collide. Every `[LPH]` reply is hidden from your chat windows while the plugin runs, including replies to a `/lph` you type yourself. The `[BANK]` reply to the plugin's own `/b` is hidden for 10 seconds after it is sent, so a `/b` you type yourself stays visible. Other chat is not affected.

## Permissions

The plugin uses the following service requests:

| Permission | Used for |
|---|---|
| data | your total XP and level |
| chat | reading the `/lph` and `/b` replies |
| chat_filter | hiding the `[LPH]` replies, and the replies to its own `/b`, from your chat windows |
| say | sending `/lph`, `/b` and `/b d` |
| ui | its window |
| state | saving your settings |

## Credits

- XP calculation follows the AC:Unreal Hunt Ledger by Thwargle.
- Level table from the Conquest server.

## License

MIT. See [LICENSE](LICENSE).
