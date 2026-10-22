-- Conquest XP 1.3.1: Hunt Ledger's XP figures plus Conquest's /lph luminance
-- (AC:Unreal API 2 companion).
--
-- XP: the same calculation as the client's Hunt Ledger (ACELedger.h,
-- FACEHuntLedger) from the same source, total experience (snapshot
-- char_quads["1"]). Only increases count, so spending XP never subtracts.
-- "Last 5 min" sums the gains of the last 300 seconds (one bucket per second),
-- "Per hour" is the total since login or Reset divided by the time elapsed,
-- and "Next level:" (an estimate) divides the XP still needed by that average rate.
-- The level table is Conquest's (levels 1-300), since plugins can't read the
-- game's DAT table. XP is counted every callback, but the XP figures shown
-- refresh every 15 seconds (XP_SHOW_S), and at once after Reset, a level-up
-- or a character change.
--
-- Luminance: Conquest banks luminance, so it comes from the server's /lph
-- tracker instead of the character. After login the plugin sends "@lph start",
-- then "@lph" every 90 seconds (Settings). Replies look like
--   [LPH] You've earned 290,725 Luminance in 00:21:13 for 821,536 Lum/hour (5min 891,144 Lum/hour).
-- Per hour = Lum/hour, Last 5 min = the 5-minute rate / 12. The Total row
-- shows the luminance in your bank, from the "Luminance:" line of /b (below).
-- Every "[LPH]" reply is hidden from the chat windows (display only).
-- Reset clears the XP figures and sends "@lph restart". Switching luminance
-- tracking off in Settings sends "@lph stop". Commands go out with "@" because
-- the client sends a plugin's "/" text as speech.
--
-- Bank deposit (Settings, on by default): "Automatic /b d" sends "@b d" every
-- 2-10 minutes (default 5), which deposits all valid items into the
-- character's bank. The first deposit is one interval after login, switching
-- it on, or changing the interval. Sent only while a character is logged in.
--
-- Bank column: MMDs, Conquest Coins, Dragon Coins and Legendary Keys, read
-- from Conquest's "/b" reply 30 seconds after login and then every 2-10
-- minutes (default 5). The reply looks like
--   [BANK] Pyreals: 2,270,035,723
--   [BANK] Luminance: 15,013,916
--   [BANK] Event Tokens [Dragon Coins] (non-transferable): 29
--   [BANK] Conquest Coins (non-transferable): 1,917
--   [BANK] Legendary Keys: 3,376
-- (plus other lines). MMDs = Pyreals / 250,000, rounded down. Any [BANK]
-- reply updates the counts, including a /b you type. The plugin's own /b
-- replies are hidden for 10 s from when it sends /b (a timed chat filter sent
-- with the request); a /b you type later stays visible.
-- The client drops a plugin's chat filters on logout or character change, so
-- they are sent again for each character.
--
-- Conquest Coins per hour, shown in brackets after the coin count: the coins
-- added to the bank between /b readings (increases only, so spending doesn't
-- count against it), divided by the time from the first reading after login
-- or Reset to the latest one. Shown once a minute or more has passed between
-- readings. Coins still in your packs count once /b d deposits them.

local OPT_DEFAULT = {lum = true, lph_s = 90, bank = true, bank_m = 5, bal_m = 5}
local SIZE = 15          -- 20 px: lands exactly on the game's basefont20, so it stays
                         -- sharp (13/14 are stretched and look soft; 12 and 18 are also exact)
local START_DELAY = 8    -- seconds after login before "@lph start"
local BAL_DELAY = 30     -- seconds after login before the first "@b"
local BAL_HIDE = 10      -- seconds the plugin's own [BANK] replies are hidden

local XP_LEVEL = {
  0, 1000, 2777, 5697, 10248, 17031, 26784, 40391, 58895, 83511,
  115645, 156898, 209088, 274259, 354692, 452925, 571762, 714286, 883872, 1084206,
  1319289, 1593459, 1911400, 2278153, 2699136, 3180153, 3727407, 4347513, 5047517, 5834900,
  6717600, 7704021, 8803044, 10024047, 11376914, 12872048, 14520384, 16333408, 18323161, 20502261,
  22883912, 25481915, 28310688, 31385275, 34721359, 38335275, 42244029, 46465302, 51017472, 55919623,
  61191556, 66853809, 72927666, 79435170, 86399136, 93843170, 101791673, 110269863, 119303784, 128920317,
  139147200, 150013037, 161547311, 173780397, 186743581, 200469064, 214989984, 230340425, 246555428, 263671011,
  281724178, 300752932, 320796288, 341894292, 364088025, 387419625, 411932296, 437670319, 464679072, 493005039,
  522695823, 553800159, 586367933, 620450186, 656099136, 693368187, 732311940, 772986213, 815448050, 859755734,
  905968800, 954148054, 1004355577, 1056654747, 1111110248, 1167788081, 1226755584, 1288081441, 1351835695, 1418089761,
  1486916445, 1558389948, 1632585888, 1709581309, 1789454692, 1872285975, 1958156562, 2047149336, 2139348672, 2234840456,
  2333712089, 2436052509, 2541952200, 2651503203, 2764799136, 2881935203, 3003008207, 3128116563, 3257360317, 3390841150,
  3528662400, 3670929071, 3817747844, 3969227097, 4125476914, 4286609098, 4452737184, 4623976457, 4800443961, 4982258511,
  5169540711, 5362412965, 5560999488, 5765426325, 5975821358, 6192314325, 6415036828, 6644122352, 6879706272, 7121925872,
  7370920356, 7626830859, 7889800466, 8159974219, 8437499136, 8722524219, 9015200473, 9315680913, 9624120583, 9940676567,
  10265508000, 10598776087, 10940644110, 11291277447, 11650843580, 12019512114, 12397454784, 12784845474, 13181860228, 13588677261,
  14005476978, 14432441981, 14869757088, 15317609341, 15776188025, 16245684675, 16726293095, 17218209369, 17721631872, 18236761289,
  18763800622, 19302955209, 19854432732, 20418443236, 20995199136, 21584915236, 22187808740, 22804099263, 23434008850, 24077761983,
  24735585600, 25407709103, 26094364377, 26795785797, 27512210247, 28243877131, 28991028384, 29753908491, 30532764494, 31327846011,
  32139405244, 32967696998, 33812978688, 34675510358, 35555554692, 36453377025, 37369245362, 38303430385, 39256205472, 40227846705,
  41218632889, 42228845559, 43258768999, 44308690253, 45378899136, 46469688253, 47581353006, 48714191613, 49868505116, 51044597400,
  52242775200, 53463348120, 54706628644, 55972932147, 57262576914, 58575884147, 59913177984, 61274785507, 62661036761, 64072264761,
  65508805511, 66970998015, 68459184288, 69973709375, 71514921358, 73083171375, 74678813628, 76302205402, 77953707072, 79633682122,
  81342497156, 83080521909, 84848129266, 86645695269, 88473599136, 90332223269, 92221953273, 94143177963, 96096289383, 98081682817,
  100099756800, 102150913137, 104235556910, 106354096497, 108506943580, 110694513164, 112917223584, 115175496524, 117469757028, 119800433511,
  122167957778, 124572765031, 127015293888, 129495986391, 132015288025, 134573647725, 137171517895, 139809354419, 142487616672, 145206767539,
  147967273422, 150769604259, 153614233532, 156501638286, 159432299136, 162406700286, 165425329540, 168488678313, 171597241650, 174751518233,
  177952010400, 181199224153, 184493669177, 187835858847, 191226310247, 194665023377, 198152685223, 201689992550, 205277652043, 208916380445,
  212606904701, 216349962105, 220146300445, 223996678153, 227901864460, 231862639544, 235879794689, 239954132442, 244086466776, 248277623248,
  252528439169, 256839763767, 261212458359, 265647396522, 270145464270, 274707560226, 279334595807, 284027495403, 288787196561, 293614650176}

-- Bank column: one item per row (header, Last 5 min, Per hour, Total).
-- icon/underlay/overlay/effects/item_type: the item's inventory artwork, as the
-- Supply Ledger saved it (Trade Note (250,000) wcid 20630, Conquest Coin
-- 13370001, Dragon Coin 13370002, Aged Legendary Key 48746). Without an icon
-- the short label is shown instead.
local BANK_ITEMS = {
  {key = "mmd",  label = "MMD",  tip = "MMDs (bank pyreals / 250,000)",
   icon = 100673377, underlay = 0, overlay = 0, effects = 0, item_type = 262144},
  {key = "cc",   label = "CC",   tip = "Conquest Coins (coins per hour since login or Reset)",
   icon = 100667518, underlay = 0, overlay = 100669182, effects = 16, item_type = 128},
  {key = "dc",   label = "DC",   tip = "Dragon Coins",
   icon = 100667518, underlay = 0, overlay = 100667937, effects = 16, item_type = 128},
  {key = "keys", label = "Keys", tip = "Legendary Keys",
   icon = 100693001, underlay = 0, overlay = 0, effects = 64, item_type = 16384},
}
local BANK_RE = "^\\[BANK\\] (.+): ([\\d,]+)\\s*$"

-- Helpers (no string.find/match/gsub in the sandbox) -----------------------
local function commas(n)
  n = math.floor((tonumber(n) or 0) + 0.5)
  local s, neg = tostring(math.abs(n)), n < 0
  local out = ""
  while #s > 3 do out = "," .. string.sub(s, -3) .. out; s = string.sub(s, 1, -4) end
  return (neg and "-" or "") .. s .. out
end
local function digits(t)  -- "290,725" -> 290725
  local n = 0
  for i = 1, #t do
    local b = string.byte(t, i)
    if b >= 48 and b <= 57 then n = n * 10 + (b - 48) end
  end
  return n
end

-- State ---------------------------------------------------------------------
local st                     -- saved per character: {opt = {...}}
local function opt(k) local v = st.opt[k]; if v == nil then return OPT_DEFAULT[k] end; return v end
local dirty = false
local player = nil
local xp = {}                -- the Hunt Ledger: started, total, prev, has, buckets
local XP_SHOW_S = 15      -- seconds between refreshes of the XP figures shown
local xpv = {}           -- XP figures as last shown: at, level, five, hour, total, est
local function reset_xp(now)
  xp = {started = now, total = 0, prev = 0, has = false, buckets = {}}
  xpv = {}
end
local lum = {total = nil, hour = nil, five = nil, at = nil}
local bal = {}               -- bank counts by BANK_ITEMS key
local ccr = {}               -- Conquest Coins rate: base_at, last, last_at, gained
local cmd = {queue = {}, sent_at = -1e9, serial = 0, started = false, next_poll = nil, start_at = nil, inflight = {}, next_bank = nil, next_bal = nil, hide_bank = false}
local show_settings = false

local function send(text) cmd.queue[#cmd.queue + 1] = text end
local function bank_every() return 60 * math.max(2, math.min(10, math.floor(tonumber(opt("bank_m")) or 5))) end
local function bal_every() return 60 * math.max(2, math.min(10, math.floor(tonumber(opt("bal_m")) or 5))) end

-- XP ledger (FACEHuntLedger) ---------------------------------------------
local function observe(total, now)
  if not total then return end
  local gain = 0
  if xp.has then gain = math.max(0, total - xp.prev) end
  xp.prev, xp.has = total, true
  if gain <= 0 then return end
  xp.total = xp.total + gain
  local second = math.floor(now)
  local b = xp.buckets[second % 301]
  if not b or b.s ~= second then b = {s = second, xp = 0}; xp.buckets[second % 301] = b end
  b.xp = b.xp + gain
end
local function last5(now)
  local second, sum = math.floor(now), 0
  for _, b in pairs(xp.buckets) do
    if b.s > second - 300 and b.s <= second then sum = sum + b.xp end
  end
  return sum
end
local function elapsed(now) return math.max(0, now - xp.started) end
local function per_hour(total, now)
  local e = elapsed(now)
  if e < 1 then return 0 end
  return total * 3600 / e
end
local function estimate(level, total, now)
  if not level or level <= 0 or not total then return "--" end
  local next_total = XP_LEVEL[level + 1]
  if not next_total then return "Max level" end
  local needed = next_total - total
  if needed <= 0 then return "Leveling..." end
  local e = elapsed(now)
  if xp.total <= 0 or e < 1 then return "Waiting for XP" end
  local seconds = needed * e / xp.total
  if seconds < 60 then return "<1m" end
  if seconds >= 86400 then return string.format("%dd %02dh", math.floor(seconds / 86400), math.floor((seconds / 3600) % 24)) end
  local minutes = math.ceil(seconds / 60)
  if minutes >= 60 then return string.format("%dh %02dm", minutes // 60, minutes % 60) end
  return string.format("%dm", minutes)
end

-- /lph replies ----------------------------------------------------------------
local LPH_RE = "You've earned ([\\d,]+) Luminance in (\\d+):(\\d+):(\\d+) for ([\\d,]+) Lum/hour(?: \\(5min ([\\d,]+) Lum/hour\\))?"
local function lph_line(text, now)
  if string.sub(text, 1, 5) ~= "[LPH]" or #text > 1024 then return end
  local m = regexmatch(text, LPH_RE)
  if m then
    lum.total, lum.hour = digits(m["1"]), digits(m["5"])
    lum.five = m["6"] and (digits(m["6"]) / 12) or nil
    lum.at = now
  elseif string.contains(text, "tracking started") then
    lum.total, lum.hour, lum.five, lum.at = 0, 0, 0, now
  elseif string.contains(text, "tracking stopped") then
    lum.total, lum.hour, lum.five, lum.at = nil, nil, nil, nil
  end
end

-- /b replies -------------------------------------------------------------------
local function cc_reading(n, now)
  if ccr.last then ccr.gained = ccr.gained + math.max(0, n - ccr.last)
  else ccr.base_at, ccr.gained = now, 0 end
  ccr.last, ccr.last_at = n, now
end
local function cc_rate()
  if not ccr.last_at or ccr.last_at - ccr.base_at < 60 then return nil end
  return math.floor(ccr.gained * 3600 / (ccr.last_at - ccr.base_at) + 0.5)
end
local function bank_line(text, now)
  if string.sub(text, 1, 6) ~= "[BANK]" or #text > 300 then return end
  local m = regexmatch(text, BANK_RE)
  if not m then return end
  local name, n = m["1"], digits(m["2"])
  if name == "Pyreals" then bal.mmd = n // 250000
  elseif name == "Luminance" then bal.lum = n
  elseif string.contains(name, "Dragon Coins") then bal.dc = n
  elseif string.contains(name, "Conquest Coins") then bal.cc = n; cc_reading(n, now)
  elseif string.contains(name, "Legendary Keys") then bal.keys = n end
end

-- Window ----------------------------------------------------------------------
-- Tight rows: no padding around the rows or their cells (the client's default
-- is 2 px on every side of each). The client still adds 2-3 px between controls.
local function cell(id, text) return {id = id, type = "text", size = SIZE, text = text, padding = 0} end
-- Bank item: the item tile at ICON px (natural width), then the count at the
-- window's text size, both straight in the row: a nested row would add the
-- client's fixed 3 px around each of its children again. An item_icon's
-- "size" also sets its own (empty) label's font, so the tile is kept small
-- to keep the row about one text line high.
local ICON = 20          -- user's choice; the game's item pictures are 32 px (16 is the client minimum)
local function add_item(kids, id, it)
  local n = bal[it.key]
  local count = n and commas(n) or "--"
  if it.key == "cc" and n then
    local r = cc_rate()
    if r then count = count .. " (" .. commas(r) .. "/h)" end
  end
  if it.icon then
    kids[#kids + 1] = {id = id .. "i", type = "item_icon", size = ICON, padding = 0, auto_width = true, tooltip = it.tip,
      icon = it.icon, underlay = it.underlay, overlay = it.overlay, effects = it.effects, item_type = it.item_type}
    local c = cell(id .. "n", count); c.tooltip = it.tip
    kids[#kids + 1] = c
  else
    local c = cell(id .. "n", it.label .. "  " .. count); c.tooltip = it.tip
    kids[#kids + 1] = c
  end
end
local function row(id, a, b, c, it)
  local kids = {cell(id .. "a", a), cell(id .. "b", b), cell(id .. "c", c)}
  if it then add_item(kids, id .. "d", it) end
  return {id = id, type = "row", padding = 0, children = kids}
end
local function lumtext(v) if not opt("lum") or v == nil then return "--" end; return commas(v) end

local function build(now, level, total)
  if not xpv.at or now - xpv.at >= XP_SHOW_S or level ~= xpv.level then
    xpv = {at = now, level = level, five = commas(last5(now)), hour = commas(per_hour(xp.total, now)), total = commas(xp.total),
      est = estimate(level, total, now)}
  end
  local ui = {
    row("h", "", "XP", "Luminance", BANK_ITEMS[1]),
    row("r5", "Last 5 min", xpv.five, lumtext(lum.five), BANK_ITEMS[2]),
    row("rh", "Per hour", xpv.hour, lumtext(lum.hour), BANK_ITEMS[3]),
    row("rt", "Total", xpv.total, bal.lum and commas(bal.lum) or "--", BANK_ITEMS[4]),
    -- Next level: same columns as the rows above, the estimate under XP. An
    -- empty natural-width cell stands in for the item tile (the estimate still
    -- starts a few px right of the XP numbers: the tile is wider than nothing).
    {id = "est", type = "row", padding = 0, children = {
      (function() local c = cell("esta", "Next level:"); c.wrap = false; c.tooltip = "Estimated time to your next level"; return c end)(),
      (function() local c = cell("estb", xpv.est); c.wrap = false; return c end)(), cell("estc", ""),
      {id = "estd", type = "text", size = SIZE, text = "", padding = 0, auto_width = true}, cell("este", "")}},
    {id = "btns", type = "row", children = {
      {id = "reset", type = "button", size = SIZE, text = "Reset", tooltip = "Clear the XP figures and restart luminance tracking (/lph restart)"},
      {id = "settings", type = "button", size = SIZE, text = "Settings"}}},
  }
  if show_settings then
    ui[#ui + 1] = {id = "opt|lum", type = "checkbox", size = SIZE, text = "Luminance tracking", value = opt("lum"),
      tooltip = "Off sends /lph stop; on sends /lph start"}
    ui[#ui + 1] = {id = "opt|lph_s", type = "number", size = SIZE, text = "/lph update interval", min = 30, max = 300, step = 1,
      value = tonumber(opt("lph_s")) or 90, enabled = opt("lum"), tooltip = "Seconds between automatic /lph reads (30-300)"}
    ui[#ui + 1] = {id = "opt|bank", type = "checkbox", size = SIZE, text = "Automatic /b d", value = opt("bank"),
      tooltip = "Deposits all valid items into your bank on the interval"}
    ui[#ui + 1] = {id = "opt|bank_m", type = "number", size = SIZE, text = "/b d interval (minutes)", min = 2, max = 10, step = 1,
      value = tonumber(opt("bank_m")) or 5, enabled = opt("bank"), tooltip = "Minutes between automatic /b d (2-10)"}
    ui[#ui + 1] = {id = "opt|bal_m", type = "number", size = SIZE, text = "/b update interval (minutes)", min = 2, max = 10, step = 1,
      value = tonumber(opt("bal_m")) or 5, tooltip = "Minutes between automatic /b reads of your bank balances (2-10)"}
  end
  return ui
end

return function(s, p)
  local now = tonumber(s.time) or 0
  local out = {}
  if not st then
    local saved = type(s.state) == "table" and s.state or {}
    st = {opt = type(saved.opt) == "table" and saved.opt or {}}
    reset_xp(now)
    cmd.start_at = now + START_DELAY
  end
  -- A different character: start over.
  local pl = tonumber(s.player)
  if pl and pl ~= player then
    if player then reset_xp(now); lum = {}; bal = {}; ccr = {}; cmd.started = false; cmd.start_at = now + START_DELAY end
    player = pl
    cmd.next_bank = now + bank_every()
    cmd.next_bal = now + BAL_DELAY
    -- Hide every [LPH] reply from the chat windows while the plugin runs (the
    -- client drops plugin filters on logout or character change).
    out.chat_filters = {{id = "lph", prefix = "[LPH]", sender = ""}}
  end

  -- XP from the full snapshot (data permission)
  local quads = type(s.char_quads) == "table" and s.char_quads or {}
  local ints = type(s.char_ints) == "table" and s.char_ints or {}
  local total = tonumber(quads["1"])
  local level = tonumber(ints["25"])
  observe(total, now)

  -- Events: buttons and settings
  for _, e in ipairs(s.events or {}) do
    local id = type(e.id) == "string" and e.id or ""
    if e.type == "click" then
      if id == "reset" then
        reset_xp(now); xp.prev, xp.has = total or 0, total ~= nil
        -- Coins per hour starts again from the current count.
        ccr = {}; if bal.cc then cc_reading(bal.cc, now) end
        if opt("lum") then send("@lph restart"); cmd.next_poll = now + 5 end
      elseif id == "settings" then show_settings = not show_settings end
    elseif e.type == "change" and string.sub(id, 1, 4) == "opt|" then
      local k = string.sub(id, 5)
      if k == "bal_m" then
        local v = math.floor(tonumber(e.value) or 5)
        st.opt.bal_m = math.max(2, math.min(10, v))
        cmd.next_bal = now + bal_every()
      elseif k == "lph_s" then
        local v = math.floor(tonumber(e.value) or 90)
        st.opt.lph_s = math.max(30, math.min(300, v))
      elseif k == "bank_m" then
        local v = math.floor(tonumber(e.value) or 5)
        st.opt.bank_m = math.max(2, math.min(10, v))
        cmd.next_bank = now + bank_every()
      elseif k == "bank" then
        st.opt.bank = e.value == true
        cmd.next_bank = now + bank_every()
      elseif k == "lum" then
        st.opt.lum = e.value == true
        if st.opt.lum then send("@lph start"); cmd.started = true; cmd.next_poll = now + 5
        else send("@lph stop"); cmd.started = false; lum = {} end
      end
      dirty = true
    end
  end

  -- Chat: /lph replies
  for _, e in ipairs(s.chat_events or {}) do
    if (e.sender or "") == "" and type(e.raw_text) == "string" then lph_line(e.raw_text, now); bank_line(e.raw_text, now) end
  end

  -- /lph start after login, then /lph on the interval
  if opt("lum") then
    if not cmd.started and cmd.start_at and now >= cmd.start_at then
      send("@lph start"); cmd.started = true; cmd.next_poll = now + (tonumber(opt("lph_s")) or 90)
    elseif cmd.started and cmd.next_poll and now >= cmd.next_poll then
      send("@lph"); cmd.next_poll = now + (tonumber(opt("lph_s")) or 90)
    end
  end
  -- Automatic bank deposit on its interval, while logged in.
  if opt("bank") and player and cmd.next_bank and now >= cmd.next_bank then
    send("@b d"); cmd.next_bank = now + bank_every()
  end
  -- Bank balances: /b 30 s after login, then on its interval.
  if player and cmd.next_bal and now >= cmd.next_bal then
    send("@b"); cmd.next_bal = now + bal_every()
  end
  -- A send refused by the rate limit goes again.
  for _, e in ipairs(s.events or {}) do
    if e.type == "result" and type(e.id) == "string" and cmd.inflight[e.id] then
      local text = cmd.inflight[e.id]; cmd.inflight[e.id] = nil
      if e.ok == false and type(e.error) == "string" and (string.contains(e.error, "second") or string.contains(e.error, "rate limit")) then
        table.insert(cmd.queue, 1, text)
      end
    end
  end
  -- One chat send per callback, at most one per 1.2 s (the service allows one per second).
  if #cmd.queue > 0 and now - cmd.sent_at >= 1.2 then
    cmd.serial = cmd.serial + 1
    local id, text = "lph" .. cmd.serial, table.remove(cmd.queue, 1)
    cmd.inflight[id] = text
    out.requests = {{id = id, service = "chat", operation = "send", text = text}}
    cmd.sent_at = now
    -- Our own /b: hide its [BANK] reply for BAL_HIDE seconds. The client installs
    -- the rule before this request is sent; the full set replaces the old one.
    if text == "@b" then
      out.chat_filters = {{id = "lph", prefix = "[LPH]", sender = ""},
        {id = "bank", prefix = "[BANK]", sender = "", seconds = BAL_HIDE}}
    end
  end

  out.ui = build(now, level, total)
  out.status = ""
  if dirty then out.state = {opt = st.opt}; dirty = false end
  return out
end
