# Changelog

## 1.4.3 (2026-10-26)

- Bank commands are sent at least 6 seconds apart. If the server asks to wait ("You must wait ... before using this bank command again."), the command is sent again once the wait is over, and the message is hidden.

## 1.4.2 (2026-10-26)

- The whole reply to the plugin's own `/b d` is hidden, including the "Deposited ..." lines.
- `[LPH]` replies are hidden only after the plugin's own `/lph`. A `/lph` you type now shows.
- Commands you type yourself always show in full.

## 1.4.1 (2026-10-26)

- The "No ... to deposit" lines from the plugin's own `/b d` are hidden.
- New plugin bar icon.

## 1.4.0 (2026-10-26)

- Conquest Coins per hour now counts the coins handed to you ("... gives you Conquest Coin.") since login or Reset. Shown after 5 minutes.
- Lighter: runs every 2 seconds and asks the client only for XP, level and chat, instead of a full snapshot. The window is sent only when something in it changes.
- Needs AC:Unreal client build 135 or newer.

## 1.3.1 (2026-10-21)

- Larger item symbols in the bank column (20 px, was 16).

## 1.3.0 (2026-10-21)

- New bank column to the right of Luminance: MMDs, Conquest Coins, Dragon Coins and Legendary Keys, each with its item symbol. MMDs are your bank pyreals divided by 250,000, rounded down.
- Bank balances are read with `/b` 30 seconds after login, then every 2-10 minutes (new setting "/b update interval (minutes)", default 5). The replies to the plugin's own `/b` are hidden from chat.
- Conquest Coins earned per hour, in brackets beside the coin count.
- Total luminance now shows the luminance in your bank, from `/b`.
- XP figures refresh every 15 seconds, and immediately after Reset or a level-up.
- "Next level (est.)" is now "Next level:", with the estimate under the XP column.
- Larger text (size 15), chosen to stay sharp.
- Fixed: `[LPH]` replies showed in chat again after switching characters.
- Needs AC:Unreal client build 126 or newer.

## 1.1.1 (2026-10-21)

First public release.

- XP for the last 5 minutes, per hour and in total, using the Hunt Ledger's calculation, plus an estimated time to your next level from Conquest's level table.
- Luminance from Conquest's `/lph`: started automatically after login and read on an interval (30-300 seconds, default 90). `[LPH]` replies are hidden from chat.
- Automatic `/b d` bank deposit, on by default, every 2-10 minutes (default 5).
- Reset clears the XP figures and sends `/lph restart`.
