# Changelog

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
