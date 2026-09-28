--
--
--
--          hands v0.10
--           @dddstudio
--
--
--
-- E1 page
-- E2 E3 the two dials
-- K1+E1 engine
--   classic/ambient/loops
--
-- K2 vary
-- K3 new piece
-- K1+K2 run/stop
-- K1+K3 randomize all

local Gen = include('lib/gen')
local Amb = include('lib/ambient')
local Loops = include('lib/loops')
local T = include('lib/theory')
local Update = include('lib/update')
local cs = require 'controlspec'
local tab = require 'tabutil'

local floor, random, max, min = math.floor, math.random, math.max, math.min
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end

local p = {bright=0, space=0.35, motion=0.6, syn=0, rep=0.57, len=0.58, tens=0.35, stray=0.08, lh=0.45, rh=0.3, harm=0.35, drift=0.3,
           centre=66, rngw=48, vel=80, pedal=1.0, rubato=0.4, intens=0.5,
           swing=0.08, hum=0.3, poly=16, root=0, rootlock=false, pedcc=true, step=0.5, style=0, bal=0}

local q = {mode = 6, len = 16, bpc = 2, dev = 0.1, rich = 0.4, susp = 0.35, sparse = 0.3, flow = 0.35,
           smooth = 0.2, surp = 0.2, nat = 0.5, reg = 60, mel = 0.3, evo = 0.25, vel = 70, mvel = 80,
           dim = false, sroot = true, rootlock = false, root = 0,
           ch = 1, chm = 0, chb = 0, cht = 0, cha = 0, chs = 0, lvb = 1, lvt = 0.85, lva = 0.85, lvs = 0.95}

local lq = {mode = 2, n = 5, notes = 2, len = 16, spread = 0.6, reg = 62, width = 24, tones = 5, shift = 0.25,
            space = 0.6, sus = 0.6, drift = 0.3, swell = 0.5, echo = 0.2, et = 6, nat = 0.4, chn = 1,
            ch = 1, vel = 80, rootlock = false, root = 0}

local KEYS = {"free","C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}

local gen, sp, lp
local eng = 1
local EN = {}
local ENAMES = {"classic", "ambient", "loops"}

local function nname(v) v = floor(v + 0.5) return T.PC[v % 12 + 1] .. tostring(v // 12 - 1) end
local function pct(v) return floor(v * 100 + 0.5) .. "%" end

local synced, sdiv, follow = false, 0.25, true
local SDIV = {"1/32", "1/16", "1/8", "1/4"}

local function cid(c) return type(c[1]) == "function" and c[1]() or c[1] end

local NV = {"whole", "half", "qtr", "8th", "16th"}
local function nval(v)
  local x = v * 4
  local i = floor(x + 0.5)
  return NV[i + 1] or "16th"
end

local function spct(v) local x = floor(v * 100 + 0.5) return (x > 0 and "+" or "") .. x .. "%" end
local function int(v) return tostring(floor(v + 0.5)) end
local function keyv(v) return KEYS[v] end
local function modev(v) return Amb.MODES[v].short end

local function tempo(id, fine)
  return {function() return synced and "tdiv" or id end,
          function()
            if synced then return floor(clock.get_tempo() + 0.5) .. " syn" end
            return "pace" end,
          function(v)
            if synced then return SDIV[v] or "?" end
            return floor(v + 0.5) .. "bpm" end,
          fine and function() return synced and 1 or fine end or nil}
end

local PAGES = {
  {"tone",   {"key", "key", keyv},
             {"mode", "mode", T.mode_label}},
  {"style",  {"style", "style", function(v) return T.SNAMES[floor(v + 0.5)] or "?" end},
             {"intens", "intensity", pct}},
  {"time",   tempo("pace", 0.4),
             {"swing", "swing", pct}},
  {"range",  {"reg", "register", nname},
             {"rngw", "width", int}},
  {"hands",  {"left", "left", function()
               return gen and select(4, gen:info()) or "-" end},
             {"right", "right", pct}},
  {"flow",   {"motion", "motion", nval},
             {"space", "space", pct}},
  {"beat",   {"syn", "synco", pct},
             {"rep", "repeat", pct}},
  {"touch",  {"len", "length", pct},
             {"pedal", "pedal", pct}},
  {"feel",   {"rubato", "rubato", pct},
             {"hum", "humanize", pct}},
  {"colour", {"harm", "harmony", pct},
             {"tens", "tension", pct}},
  {"change", {"drift", "drift", pct},
             {"stray", "stray", pct}},
  {"level",  {"vel", "velocity", int},
             {"bal", "balance", spct}},
}

local SPAGES = {
  {"tone",   {"key", "key", keyv},
             {"sp_mode", "mode", modev}},
  {"form",   {"sp_len", "length", function(v) return v .. " bars" end},
             {"sp_bpc", "chord", function(v) return Amb.BPCN[v] end}},
  {"time",   tempo("sp_pace"),
             {"sp_dev", "deviate", pct}},
  {"range",  {"sp_reg", "register", nname},
             {"sp_sparse", "sparse", Amb.lab(Amb.SPAR)}},
  {"colour", {"sp_rich", "rich", Amb.lab(Amb.RICH)},
             {"sp_susp", "suspend", Amb.lab(Amb.SUSP)}},
  {"motion", {"sp_flow", "flow", Amb.lab(Amb.FLOW)},
             {"sp_smooth", "smooth", spct}},
  {"melody", {"sp_mel", "melody", pct},
             {"sp_nat", "natural", pct}},
  {"change", {"sp_evo", "evolve", pct},
             {"sp_surp", "surprise", pct}},
  {"level",  {"sp_vel", "pads", int},
             {"vel", "melody", int}},
}

local LPAGES = {
  {"tone",   {"key", "key", keyv},
             {"lp_mode", "mode", modev}},
  {"form",   {"lp_n", "loops", int},
             {"lp_notes", "notes", int}},
  {"time",   tempo("lp_pace"),
             {"lp_nat", "natural", pct}},
  {"range",  {"lp_reg", "register", nname},
             {"lp_width", "width", int}},
  {"length", {"lp_len", "length", function(v) return v .. " beats" end},
             {"lp_spread", "spread", pct}},
  {"colour", {"lp_tones", "tones", int},
             {"lp_shift", "shift", pct}},
  {"space",  {"lp_space", "space", pct},
             {"lp_sus", "sustain", pct}},
  {"echo",   {"lp_echo", "echo", pct},
             {"lp_et", "time", function(v) return Loops.ETN[v] end}},
  {"change", {"lp_drift", "drift", pct},
             {"lp_swell", "swell", pct}},
  {"level",  {"vel", "velocity", int},
             {"lp_chn", "channels", int}},
}

local PG = {PAGES, SPAGES, LPAGES}
local pages = {1, 1, 1}

local md
local ch, lch = 1, 1
local pedcc = true
local pedco
local own, oc = {}, {}
local lowp, lastmel = {}, nil
local nser, nheld, poly = 0, 0, 16
local seq
local running = true
local dirty = false
local step_sec = 0.55
local slen = 0.55
local tlast = 0
local sdirty = true
local alt = false
local pacc = 0
local upd
local gstep = 0
local ctick = 0
local hist, hn = {}, 0
local HL = 224
local devs = {}
local epoch = 0
local drift_clk, rdm
local restyle = false
local hdr, hdr_r, hdr_m = "", nil, nil
local toast, toast_t = nil, 0
local TOAST = 0.85

local function beatsec()
  if clock.get_beat_sec then return clock.get_beat_sec() end
  return 60 / clock.get_tempo()
end

local function say(t)
  toast = t
  toast_t = util.time() + TOAST
  sdirty = true
end

local function playing(ep) return running and ep == epoch end

local function steal()
  local bk, bs = nil, 1e18
  for k, t in pairs(oc) do
    if lowp[k] and t < bs then bs = t; bk = k end
  end
  if not bk then
    bs = 1e18
    for k, t in pairs(oc) do
      if k ~= lastmel and t < bs then bs = t; bk = k end
    end
  end
  if not bk then
    bs = 1e18
    for k, t in pairs(oc) do if t < bs then bs = t; bk = k end end
  end
  if not bk then nheld = 0; return false end
  md:note_off(bk % 200, 0, bk // 200)
  own[bk] = nil; oc[bk] = nil; lowp[bk] = nil
  if lastmel == bk then lastmel = nil end
  nheld = nheld - 1
  return true
end

local function non(n, v, chn, hold)
  if n < 0 or n > 127 then return end
  local k = n + chn * 200
  if hold then
    if own[k] == nil then lowp[k] = true end
  else
    lowp[k] = nil; lastmel = k
  end
  local c = own[k]
  if c then
    own[k] = c + 1
    if hold then nser = nser + 1; oc[k] = nser; return end
    md:note_off(n, 0, chn)
  else
    while nheld >= poly do if not steal() then break end end
    own[k] = 1
    nheld = nheld + 1
  end
  nser = nser + 1
  oc[k] = nser
  md:note_on(n, v, chn)
end

local function noff(n, chn)
  local k = n + chn * 200
  local c = own[k]
  if not c then return end
  c = c - 1
  if c > 0 then own[k] = c; return end
  own[k] = nil; oc[k] = nil; lowp[k] = nil
  if lastmel == k then lastmel = nil end
  nheld = nheld - 1
  md:note_off(n, 0, chn)
end

local function pcc(v)
  if not md then return end
  md:cc(64, v, ch)
  if lch ~= ch then md:cc(64, v, lch) end
end

local function repedal(hold, ep)
  if hold <= 0 or not playing(ep) then pcc(0); return end
  local lead = min(0.14, step_sec * 0.6)
  clock.sleep(lead)
  if not playing(ep) then pcc(0); return end
  pcc(0)
  clock.sleep(0.035)
  if not playing(ep) or not pedcc then return end
  pcc(127)
  clock.sleep(max(0.05, hold - lead - 0.035))
  pcc(0)
end

local function panic()
  epoch = epoch + 1
  if pedco then clock.cancel(pedco); pedco = nil end
  if pedcc then pcc(0) end
  for k in pairs(own) do md:note_off(k % 200, 0, k // 200) end
  for k in pairs(own) do own[k] = nil end
  for k in pairs(oc) do oc[k] = nil end
  for k in pairs(lowp) do lowp[k] = nil end
  if sp then sp:clear() end
  lastmel = nil
  nheld = 0
end

local function clear_roll()
  for i = 1, #hist do hist[i].n = nil end
end

local function log(e)
  hn = hn % HL + 1
  local h = hist[hn]
  if not h then h = {}; hist[hn] = h end
  h.s = gstep + e.o; h.d = e.d; h.v = e.v
  h.n = e.n[1]; h.h = e.h
  local c = #e.n
  if c > 4 then c = 4 end
  h.k = c
  for j = 1, c do h[j] = e.n[j] end
end

local function voice(e)
  local ep = epoch
  local chn = e.c or ((e.h == 1) and lch or ch)
  if e.o > 0 then
    clock.sleep(e.o * step_sec)
    if not playing(ep) then return end
  end
  local n = {table.unpack(e.n)}
  local cnt = #n
  if e.r > 1 then
    local sub = e.d * step_sec / e.r
    for j = 1, e.r do
      if not playing(ep) then return end
      non(n[1], max(1, e.v - (j - 1) * 9), chn)
      clock.sleep(sub * 0.72)
      if ep ~= epoch then return end
      noff(n[1], chn)
      if j < e.r then clock.sleep(sub * 0.28) end
    end
    return
  end
  local dur = min(150, max(0.03, e.d * step_sec * (1 + (random() - 0.5) * p.hum * 0.28)))
  local st = (e.s or 0) * step_sec * 0.35
  local hold = e.h == 1
  local vs = e.vs
  if st > 0 and cnt > 1 then
    for i = 1, cnt do
      if not playing(ep) then break end
      non(n[i], vs and vs[i] or e.v, chn, hold)
      if i < cnt then clock.sleep(st) end
    end
  else
    for i = 1, cnt do non(n[i], vs and vs[i] or e.v, chn, hold) end
  end
  clock.sleep(max(0.03, dur - (st > 0 and st * (cnt - 1) or 0)))
  if ep ~= epoch then return end
  for i = 1, cnt do noff(n[i], chn) end
end

local function pad(e)
  local ep = epoch
  if e.o > 0 then clock.sleep(e.o) end
  if playing(ep) and not e.cut then
    non(e.n, e.v, e.c, not e.mel)
    e.on = true
    while true do
      local r = e.te - util.time()
      if r <= 0 or not playing(ep) then break end
      local w = e.mel and 0.05 or 0.25
      clock.sleep(r < w and r or w)
    end
    if ep == epoch and not e.cut then noff(e.n, e.c) end
  end
  e.dead = true
end

local function tick()
  if synced then clock.sync(1) end
  tlast = util.time()
  while true do
    if gen.tick == 0 then
      if restyle then restyle = false; gen:reroll(false); clear_roll() end
      if dirty then
        gen:derive(); gen:update_scale(); gen:update_lut(); gen:plan_registers(); dirty = false
      end
      gen:bar_begin()
      if pedcc and gen.newchord and gen.barn > 0 then
        if pedco then clock.cancel(pedco) end
        pedco = clock.run(repedal,
          max(0, p.pedal - 0.5) * 2 * gen.hr * gen.bl * step_sec * 0.94
            * (1 - 0.5 * (gen.dens or 0.3)) - 0.04, epoch)
      end
    end
    local l = gen.ev[gen.tick + 1]
    for i = 1, #l do
      local e = l[i]
      if not e.g or random() < 0.8 then
        clock.run(voice, e)
        log(e)
      end
    end
    ctick = gen.tick
    local t4 = gen.tick % 4
    local s8 = gen.s8
    local lng = s8 and t4 < 2 or (not s8 and t4 % 2 == 0)
    gen:advance()
    local f = p.swing / 3
    slen = step_sec * (lng and (1 + f) or (1 - f))
    if synced then
      local st = beatsec() * sdiv
      if math.abs(st - step_sec) > step_sec * 0.02 then
        step_sec = st
        p.step = st
        dirty = true
      end
      clock.sync(sdiv)
      local dl = s8 and ((t4 == 1 or t4 == 2) and 2 * f or 0) or (lng and f or 0)
      if dl > 0.001 then clock.sleep(step_sec * dl) end
    else
      clock.sleep(slen)
    end
    gstep = gstep + 1
    tlast = util.time()
  end
end

local function tick_eng()
  if synced then clock.sync(1) end
  tlast = util.time()
  local E = EN[eng]
  while true do
    E:tick(step_sec)
    if synced then
      step_sec = beatsec() * sdiv
      p.step = step_sec
      slen = step_sec
      clock.sync(sdiv)
    else
      slen = step_sec
      clock.sleep(step_sec)
    end
    gstep = gstep + 1
    tlast = util.time()
  end
end

local function retime()
  if synced then step_sec = beatsec() * sdiv
  else step_sec = 15 / params:get(({"pace", "sp_pace", "lp_pace"})[eng]) end
  p.step = step_sec
  dirty = true
  sdirty = true
end

local VG = {{"music_grp", "feel_grp", "lchan", "pedcc"}, {"sp_grp", "spv_grp"}, {"lp_grp"}}

local function vis()
  for e = 1, #VG do
    for _, id in ipairs(VG[e]) do if e == eng then params:show(id) else params:hide(id) end end
  end
  if _menu and _menu.rebuild_params then _menu.rebuild_params() end
end

local function run() seq = clock.run(eng == 1 and tick or tick_eng) end

local function stop_seq()
  if not running then return end
  running = false
  if seq then clock.cancel(seq); seq = nil end
  panic()
  sdirty = true
end

local function start_seq(fromtop)
  if running then return end
  if fromtop then
    if eng > 1 then EN[eng]:reset() elseif gen then gen:reset() end
  end
  running = true
  run()
  sdirty = true
end

local function set_engine(v)
  if v == eng then return end
  eng = v
  if not lp then return end
  if seq then clock.cancel(seq); seq = nil end
  panic()
  retime()
  if eng > 1 then EN[eng]:reset() else gen:reset() end
  if running then run() end
end

local function drifter()
  while true do
    clock.sleep(1)
    gen:drift(1)
  end
end

local function build_devs()
  for i = #devs, 1, -1 do devs[i] = nil end
  for i = 1, #midi.vports do
    local nm = midi.vports[i].name
    devs[i] = i .. ": " .. (#nm > 14 and util.acronym(nm) or nm)
  end
end

function init()
  math.randomseed(floor(util.time() * 1000) % 2147483647)
  build_devs()

  params:add_separator("act", "")

  params:add_option("engine", "engine", ENAMES, 1)
  params:set_action("engine", function(v) set_engine(v); vis(); sdirty = true end)
  params:add_option("key", "key", KEYS, 1)
  params:set_action("key", function(v)
    p.rootlock = v > 1
    q.rootlock = v > 1
    lq.rootlock = v > 1
    if v > 1 then
      p.root = v - 2; q.root = v - 2
      if gen then gen.root = v - 2 end
      if sp then sp.root = v - 2; sp.dr = true end
      lq.rootlock, lq.root = true, v - 2
      if lp then lp:set_root(v - 2) end
    end
    sdirty = true
  end)
  params:add_trigger("newp", "New Piece")
  params:set_action("newp", function()
    if eng > 1 then
      if EN[eng] then EN[eng]:newp(not running) end
    elseif gen then gen:reroll(false); clear_roll() end
    say("new piece")
  end)
  params:add_trigger("vary", "Vary")
  params:set_action("vary", function()
    if eng > 1 then
      if EN[eng] then EN[eng]:vary() end
    elseif gen then gen:mutate() end
    say("vary")
  end)
  params:add_trigger("chaos", "Randomize All")
  params:set_action("chaos", function()
    if eng == 3 then
      if not lp then return end
      local r = random
      params:set("lp_mode", r(#Amb.MODES))
      params:set("lp_n", 3 + r(5))
      params:set("lp_notes", r(4))
      params:set("lp_len", ({8, 12, 16, 16, 20, 24, 32})[r(7)])
      params:set("lp_spread", 0.25 + r() * 0.75)
      params:set("lp_tones", 3 + r(4))
      params:set("lp_shift", r() * 0.6)
      params:set("lp_space", 0.3 + r() * 0.6)
      params:set("lp_sus", 0.2 + r() * 0.8)
      params:set("lp_drift", r() * 0.6)
      params:set("lp_swell", r())
      params:set("lp_echo", r() < 0.3 and 0 or r() * 0.6)
      params:set("lp_et", r(#Loops.ET))
      params:set("lp_reg", 54 + r(14))
      params:set("lp_width", 12 + r(24))
      lp:newp(not running)
      say("randomize")
      return
    end
    if eng == 2 then
      if not sp then return end
      local r = random
      params:set("sp_mode", r(#Amb.MODES))
      local b = ({2, 3, 3, 4, 5})[r(5)]
      params:set("sp_bpc", b)
      params:set("sp_len", clamp(Amb.BPC[b] * ({4, 4, 6, 8, 8})[r(5)], 4, 128))
      params:set("sp_dev", r() * 0.3)
      params:set("sp_rich", r())
      params:set("sp_susp", r())
      params:set("sp_sparse", r())
      params:set("sp_flow", r())
      params:set("sp_smooth", -0.2 + r() * 0.7)
      params:set("sp_surp", r() ^ 1.5)
      params:set("sp_nat", 0.2 + r() * 0.6)
      params:set("sp_mel", r() < 0.2 and 0 or r() * 0.6)
      params:set("sp_reg", 52 + r(16))
      sp:newp(not running)
      say("randomize")
      return
    end
    if not gen then return end
    local sd = T.STYLE[p.style]
    sd = sd and sd.d
    local function j(v, a) return clamp(v + (random() - 0.5) * 2 * a, 0, 1) end
    if sd then
      params:set("pace", clamp(sd.pace * (0.86 + random() * 0.3), 6, 200), true)
      params:set("pedal", j(sd.pedal, 0.14), true)
      params:set("rubato", j(sd.rubato, 0.15), true)
      params:set("reg", clamp(60 + random(13), 40, 92), true)
    else
      params:set("pace", 8 + random() ^ 2 * 120, true)
      params:set("pedal", random() ^ 0.7, true)
      params:set("rubato", random() * 0.8, true)
      params:set("reg", 52 + random(28), true)
    end
    retime()
    p.pedal = params:get("pedal")
    p.rubato = params:get("rubato")
    p.centre = params:get("reg")
    gen:reroll(true)
    clear_roll()
    params:set("mode", p.bright, true)
    params:set("space", p.space, true)
    params:set("motion", p.motion, true)
    params:set("syn", p.syn, true)
    params:set("rep", p.rep, true)
    params:set("len", p.len, true)
    params:set("tens", p.tens, true)
    params:set("stray", p.stray, true)
    params:set("left", p.lh, true)
    params:set("right", p.rh, true)
    params:set("harm", p.harm, true)
    params:set("swing", p.swing, true)
    params:set("hum", p.hum, true)
    say("randomize")
  end)

  params:add_separator("sett", "")

  params:add_group("music_grp", "Music", 18)
    params:add_option("style", "style", T.SNAMES, 1)
  params:set_action("style", function(v)
    p.style = v - 1
    local st = T.STYLE[p.style]
    if st then for k, x in pairs(st.d) do params:set(k, x) end end
    restyle = gen ~= nil
    dirty = true
    sdirty = true
  end)

  params:add_number("rngw", "range", 14, 74, 48)
  params:set_action("rngw", function(v) p.rngw = v; dirty = true end)
  params:add_control("pace", "pace", cs.new(6, 200, 'exp', 0, 30, "bpm"))
  params:set_action("pace", function(v)
    if not synced and eng == 1 then step_sec = 15 / v; p.step = step_sec end
    dirty = true
  end)
  params:add_control("space", "space", cs.new(0, 1, 'lin', 0, 0.35))
  params:set_action("space", function(v) p.space = v; dirty = true end)
  params:add_control("motion", "motion", cs.new(0, 1, 'lin', 0, 0.6))
  params:set_action("motion", function(v) p.motion = v; dirty = true end)
  params:add_control("syn", "syncopation", cs.new(0, 1, 'lin', 0, 0))
  params:set_action("syn", function(v) p.syn = v; dirty = true end)
  params:add_control("rep", "repeat", cs.new(0, 1, 'lin', 0, 0.57))
  params:set_action("rep", function(v) p.rep = v; dirty = true end)
  params:add_control("len", "note length", cs.new(0, 1, 'lin', 0, 0.58))
  params:set_action("len", function(v) p.len = v; dirty = true end)
  params:add_control("tens", "tension", cs.new(0, 1, 'lin', 0, 0.35))
  params:set_action("tens", function(v) p.tens = v; dirty = true end)
  params:add_control("mode", "mode", cs.new(-5, 3, 'lin', 0, 0))
  params:set_action("mode", function(v) p.bright = v; dirty = true end)
  params:add_control("stray", "stray", cs.new(0, 1, 'lin', 0, 0.08))
  params:set_action("stray", function(v) p.stray = v; dirty = true end)
  params:add_number("reg", "register", 40, 92, 66)
  params:set_action("reg", function(v) p.centre = v; dirty = true end)
  params:add_control("left", "left hand", cs.new(0, 1, 'lin', 0, 0.45))
  params:set_action("left", function(v) p.lh = v; dirty = true end)
  params:add_control("right", "right hand", cs.new(0, 1, 'lin', 0, 0.3))
  params:set_action("right", function(v) p.rh = v; dirty = true end)
  params:add_control("harm", "harmony", cs.new(0, 1, 'lin', 0, 0.35))
  params:set_action("harm", function(v)
    if gen and math.abs(v - (gen.harmb or v)) > 0.06 then gen.progdirty = true end
    p.harm = v
    dirty = true
  end)
  params:add_control("intens", "intensity", cs.new(0, 1, 'lin', 0, 0.5))
  params:set_action("intens", function(v) p.intens = v; dirty = true end)
  params:add_control("drift", "drift", cs.new(0, 1, 'lin', 0, 0.3))
  params:set_action("drift", function(v) p.drift = v; dirty = true end)
  params:add_control("bal", "hand balance", cs.new(-1, 1, 'lin', 0, 0))
  params:set_action("bal", function(v) p.bal = v end)

  params:add_group("feel_grp", "Feel", 4)
  params:add_control("pedal", "pedal", cs.new(0, 1, 'lin', 0, 1.0))
  params:set_action("pedal", function(v) p.pedal = v end)
  params:add_control("swing", "swing", cs.new(0, 1, 'lin', 0, 0.08))
  params:set_action("swing", function(v) p.swing = v; sdirty = true end)
  params:add_control("hum", "humanize", cs.new(0, 1, 'lin', 0, 0.3))
  params:set_action("hum", function(v) p.hum = v end)
  params:add_control("rubato", "rubato", cs.new(0, 1, 'lin', 0, 0.4))
  params:set_action("rubato", function(v) p.rubato = v end)

  params:add_group("Clock", 3)
  params:add_option("sync", "tempo", {"free running", "norns clock"}, 1)
  params:set_action("sync", function(v)
    synced = v == 2
    retime()
  end)
  params:add_option("tdiv", "step", {"1/32", "1/16", "1/8", "1/4"}, 2)
  params:set_action("tdiv", function(v)
    sdiv = ({0.125, 0.25, 0.5, 1})[v]
    if synced then retime() end
    sdirty = true
  end)
  params:add_binary("xport", "follow transport", "toggle", 1)
  params:set_action("xport", function(v) follow = v == 1 end)

  local function sa(id, f, fl)
    params:set_action(id, function(v)
      q[f] = v
      if sp and fl then sp[fl] = true end
      sdirty = true
    end)
  end
  params:add_group("sp_grp", "Music", 18)
  params:add_option("sp_mode", "mode", Amb.MNAMES, 6)
  sa("sp_mode", "mode", "dr")
  params:add_number("sp_len", "length (bars)", 4, 128, 16)
  sa("sp_len", "len", "ds")
  params:add_option("sp_bpc", "bars per chord", Amb.BPCN, 3)
  params:set_action("sp_bpc", function(v) q.bpc = Amb.BPC[v]; if sp then sp.ds = true end; sdirty = true end)
  params:add_control("sp_dev", "deviation", cs.new(0, 1, 'lin', 0, 0.1))
  sa("sp_dev", "dev", "dt")
  params:add_control("sp_rich", "richness", cs.new(0, 1, 'lin', 0, 0.4))
  sa("sp_rich", "rich", "dr")
  params:add_control("sp_susp", "suspension", cs.new(0, 1, 'lin', 0, 0.35))
  sa("sp_susp", "susp", "dr")
  params:add_control("sp_sparse", "sparseness", cs.new(0, 1, 'lin', 0, 0.3))
  sa("sp_sparse", "sparse", "dr")
  params:add_control("sp_flow", "flow", cs.new(0, 1, 'lin', 0, 0.35))
  sa("sp_flow", "flow", "ds")
  params:add_control("sp_smooth", "smoothness", cs.new(-0.5, 0.5, 'lin', 0, 0.2))
  sa("sp_smooth", "smooth")
  params:add_control("sp_surp", "surprise", cs.new(0, 1, 'lin', 0, 0.2))
  sa("sp_surp", "surp", "dr")
  params:add_control("sp_nat", "natural", cs.new(0, 1, 'lin', 0, 0.5))
  sa("sp_nat", "nat")
  params:add_number("sp_reg", "register", 36, 84, 60)
  sa("sp_reg", "reg", "dv")
  params:add_control("sp_mel", "melody", cs.new(0, 1, 'lin', 0, 0.3))
  sa("sp_mel", "mel", "dm")
  params:add_control("sp_evo", "evolve", cs.new(0, 1, 'lin', 0, 0.25))
  sa("sp_evo", "evo")
  params:add_control("sp_pace", "pace", cs.new(20, 160, 'exp', 0, 60, "bpm"))
  params:set_action("sp_pace", function() if eng == 2 and not synced then retime() end end)
  params:add_number("sp_vel", "pad velocity", 1, 127, 70)
  sa("sp_vel", "vel")
  params:add_binary("sp_dim", "allow dim/aug", "toggle", 0)
  params:set_action("sp_dim", function(v) q.dim = v == 1; if sp then sp.dr = true; sp.ds = true end end)
  params:add_binary("sp_root", "start on root", "toggle", 1)
  params:set_action("sp_root", function(v) q.sroot = v == 1; if sp then sp.dr = true; sp.ds = true end end)

  params:add_group("spv_grp", "Voices", 9)
  local CHO = {"main"}
  for i = 1, 16 do CHO[i + 1] = tostring(i) end
  local function lvf(pp) return floor(pp:get() * 100 + 0.5) .. "%" end
  params:add_option("sp_chm", "melody channel", CHO, 1)
  params:set_action("sp_chm", function(v) panic(); q.chm = v - 1 end)
  for _, x in ipairs({{"b", "bass"}, {"t", "tenor"}, {"a", "alto"}, {"s", "soprano"}}) do
    params:add_option("sp_ch" .. x[1], x[2] .. " channel", CHO, 1)
    params:set_action("sp_ch" .. x[1], function(v) panic(); q["ch" .. x[1]] = v - 1 end)
    params:add_control("sp_lv" .. x[1], x[2] .. " level", cs.new(0, 1, 'lin', 0, q["lv" .. x[1]]), lvf)
    params:set_action("sp_lv" .. x[1], function(v) q["lv" .. x[1]] = v end)
  end

  local function la(id, f, fl)
    params:set_action(id, function(v)
      lq[f] = v
      if lp then
        if fl == "ph" then lp.vph = lp.vph + 1
        elseif fl == "ln" then lp.vln = lp.vln + 1
        elseif fl == "pool" then lp:mkpool()
        elseif fl == "n" then lp.dn = true end
      end
      sdirty = true
    end)
  end
  params:add_group("lp_grp", "Music", 18)
  params:add_option("lp_mode", "mode", Amb.MNAMES, 2)
  la("lp_mode", "mode", "pool")
  params:add_number("lp_n", "loops", 1, 8, 5)
  la("lp_n", "n", "n")
  params:add_number("lp_notes", "notes", 1, 5, 2)
  la("lp_notes", "notes", "ph")
  params:add_number("lp_len", "length (beats)", 4, 64, 16)
  la("lp_len", "len", "ln")
  params:add_control("lp_spread", "spread", cs.new(0, 1, 'lin', 0, 0.6))
  la("lp_spread", "spread", "ln")
  params:add_number("lp_reg", "register", 36, 84, 62)
  la("lp_reg", "reg")
  params:add_number("lp_width", "width", 0, 36, 24)
  la("lp_width", "width")
  params:add_number("lp_tones", "tones", 3, 7, 5)
  la("lp_tones", "tones", "pool")
  params:add_control("lp_shift", "shift", cs.new(0, 1, 'lin', 0, 0.25))
  la("lp_shift", "shift")
  params:add_control("lp_space", "space", cs.new(0, 1, 'lin', 0, 0.6))
  la("lp_space", "space", "ph")
  params:add_control("lp_sus", "sustain", cs.new(0, 1, 'lin', 0, 0.6))
  la("lp_sus", "sus", "ph")
  params:add_control("lp_drift", "drift", cs.new(0, 1, 'lin', 0, 0.3))
  la("lp_drift", "drift")
  params:add_control("lp_swell", "swell", cs.new(0, 1, 'lin', 0, 0.5))
  la("lp_swell", "swell")
  params:add_control("lp_echo", "echo", cs.new(0, 1, 'lin', 0, 0.2))
  la("lp_echo", "echo")
  params:add_option("lp_et", "echo time", Loops.ETN, 4)
  params:set_action("lp_et", function(v) lq.et = Loops.ET[v]; sdirty = true end)
  params:add_control("lp_nat", "natural", cs.new(0, 1, 'lin', 0, 0.4))
  la("lp_nat", "nat")
  params:add_control("lp_pace", "pace", cs.new(20, 160, 'exp', 0, 60, "bpm"))
  params:set_action("lp_pace", function() if eng == 3 and not synced then retime() end end)
  params:add_number("lp_chn", "channels", 1, 8, 1)
  params:set_action("lp_chn", function(v) panic(); lq.chn = v end)

  params:add_group("Output", 6)
  params:add_option("dev", "midi device", devs, 1)
  params:set_action("dev", function(v) panic(); md = midi.connect(v) end)
  params:add_number("chan", "channel", 1, 16, 1)
  params:set_action("chan", function(v) panic(); ch = v; q.ch = v; lq.ch = v end)
  params:add_number("lchan", "left hand ch", 1, 16, 1)
  params:set_action("lchan", function(v) panic(); lch = v end)
  params:add_number("poly", "synth voices", 1, 64, 16)
  params:set_action("poly", function(v) poly = v; p.poly = v; dirty = true end)
  params:add_control("vel", "velocity", cs.new(20, 127, 'lin', 1, 80))
  params:set_action("vel", function(v) p.vel = v; q.mvel = v; lq.vel = v; dirty = true end)
  params:add_binary("pedcc", "send cc64", "toggle", 1)
  params:set_action("pedcc", function(v)
    pedcc = v == 1
    p.pedcc = pedcc
    dirty = true
    if not pedcc then
      if pedco then clock.cancel(pedco); pedco = nil end
      pcc(0)
    end
  end)

  local function piecefile(fn)
    return (tostring(fn):gsub("%.pset$", ".piece"))
  end
  params.action_write = function(fn)
    if gen then
      local t = gen:save_state()
      if sp then t.sp = sp:save() end
      if lp then t.lp = lp:save() end
      tab.save(t, piecefile(fn))
    end
  end
  params.action_read = function(fn)
    local t = tab.load(piecefile(fn))
    if type(t) ~= "table" then return end
    panic()
    restyle = false
    if gen and gen:load_state(t) then dirty = true; clear_roll() end
    if sp then sp:load(t.sp) end
    if lp then lp:load(t.lp) end
    sdirty = true
  end
  params.action_delete = function(fn) os.remove(piecefile(fn)) end

  gen = Gen.new(p)
  params:bang()
  gen:derive(); gen:reroll(false)
  sp = Amb.new(q, {
    pad = function(e) clock.run(pad, e) end,
    note = function(e) clock.run(voice, e) end,
    cut = function(e)
      if e.dead or e.cut then return end
      e.cut = true
      if e.on then noff(e.n, e.c) end
    end,
  })
  lp = Loops.new(lq, {note = function(e) clock.run(voice, e) end}, Amb.MODES)
  EN[2], EN[3] = sp, lp
  retime()
  run()
  drift_clk = clock.run(drifter)

  rdm = metro.init()
  rdm.event = function()
    if running or sdirty or toast or alt then sdirty = false; redraw() end
  end
  rdm:start(1 / 15)

  upd = Update:new{name = "hands", on_change = function() sdirty = true end}
  clock.run(function() clock.sleep(2); upd:check() end)

  clock.transport.start = function() if follow and synced then start_seq(true) end end
  clock.transport.stop = function() if follow and synced then stop_seq() end end

  function midi.add()
    build_devs()
    if _menu and _menu.rebuild_params then _menu.rebuild_params() end
  end
  function midi.remove() clock.run(function() clock.sleep(0.2); build_devs() end) end
end

function enc(n, d)
  if upd:pending() then return end
  if n == 1 then
    pacc = (pacc > 0) == (d > 0) and pacc + d or d
    if pacc < 3 and pacc > -3 then return end
    local s = pacc > 0 and 1 or -1
    pacc = 0
    if alt then
      params:set("engine", clamp(eng + s, 1, #ENAMES))
      say(ENAMES[eng])
    else
      pages[eng] = clamp(pages[eng] + s, 1, #PG[eng])
    end
  else
    local c = PG[eng][pages[eng]][n]
    local st = c[4]
    if type(st) == "function" then st = st() end
    params:delta(cid(c), d * (st or 1))
  end
  sdirty = true
end

function key(n, z)
  if upd:pending() then upd:key(n, z); sdirty = true; return end
  if n == 1 then alt = z == 1; sdirty = true; return end
  if z == 0 then return end
  if n == 2 then
    if alt then
      if running then stop_seq() else start_seq(false) end
      say(running and "run" or "stop")
    else
      params:set("vary", 1)
    end
  else
    params:set(alt and "chaos" or "newp", 1)
  end
  sdirty = true
end

local function cell(x, w, nm, val, v)
  screen.level(3)
  screen.move(x, 57)
  screen.text(nm)
  screen.level(15)
  screen.move(x + w, 57)
  screen.text_right(val)
  screen.level(2)
  screen.rect(x + 0.5, 60.5, w - 1, 2)
  screen.stroke()
  screen.level(9)
  screen.rect(x, 60, clamp(v, 0, 1) * w, 3)
  screen.fill()
end

local PP = {}
local function nrm(id, v)
  local pp = PP[id]
  if not pp then pp = params:lookup_param(id); PP[id] = pp end
  if pp.raw then return pp.raw end
  if pp.options then return (v - 1) / max(1, #pp.options - 1) end
  if pp.min and pp.max and pp.max > pp.min then return (v - pp.min) / (pp.max - pp.min) end
  return v
end

local function draw_classic()
  local ph = gstep
  if running and slen > 0 then
    ph = ph + clamp((util.time() - tlast) / slen, 0, 1)
  end
  local lo, hi = gen.lo, gen.hi
  local sp = 32 / max(1, hi - lo)
  local alo, ahi, blo, bhi = 127, 0, 127, 0
  for i = 1, HL do
    local h = hist[i]
    if h and h.n then
      local age = ph - h.s
      if age >= 0 and age <= 43 then
        if h.h == 1 then
          if h.v < blo then blo = h.v end
          if h.v > bhi then bhi = h.v end
        else
          if h.v < alo then alo = h.v end
          if h.v > ahi then ahi = h.v end
        end
      end
    end
  end
  if ahi - alo < 20 then local m = (alo + ahi) * 0.5; alo, ahi = m - 10, m + 10 end
  if bhi - blo < 20 then local m = (blo + bhi) * 0.5; blo, bhi = m - 10, m + 10 end
  local asc, bsc = 1 / (ahi - alo), 1 / (bhi - blo)
  screen.aa(1)
  for i = 1, HL do
    local h = hist[i]
    if h and h.n then
      local age = ph - h.s
      if age >= 0 then
        local x = 126 - age * 3
        local w = (age < h.d and age or h.d) * 3
        if w > 129 then w = 129 end
        if w < 1 then w = 1 end
        if x < 0 then w = w + x; x = 0 end
        if x + w > 127 then w = 127 - x end
        if w > 0 and x < 127 then
          if h.h == 1 then
            screen.level(2 + floor(clamp((h.v - blo) * bsc, 0, 1) * 6 + 0.5))
            for j = 1, h.k do
              screen.rect(x, floor(clamp(42 - (h[j] - lo) * sp, 10, 42)), w, 1)
              screen.fill()
            end
          else
            screen.level(6 + floor(clamp((h.v - alo) * asc, 0, 1) * 9 + 0.5))
            screen.rect(x, floor(clamp(42 - (h.n - lo) * sp, 10, 42)) - 1, w, 2)
            screen.fill()
          end
        end
      end
    end
  end
  screen.aa(0)
  screen.level(running and 5 or 2)
  screen.move(126.5, 9)
  screen.line(126.5, 43)
  screen.stroke()

  screen.level(alt and 7 or 1)
  screen.move(0, 44.5)
  screen.line(128, 44.5)
  screen.stroke()

  local bl = gen.bl
  local tw = 124 / bl
  for i = 0, bl - 1 do
    screen.level(i == ctick and 15 or (i % 4 == 0 and 5 or 1))
    screen.rect(i * tw, 46, i == ctick and tw - 1 or 2, 2)
    screen.fill()
  end
end

local function draw_ambient()
  local prog, st, m = sp.prog, sp.start, sp.m
  local n, idx = #prog, sp.idx
  local w0, w1 = 1, n
  if n > 16 then w0 = floor((idx - 1) / 16) * 16 + 1; w1 = min(n, w0 + 15) end
  local ws = st[w0]
  local span = st[w1] + prog[w1].len - ws
  local sx = 127 / span
  local lo, hi = 127, 0
  local alo, ahi, blo, bhi = 127, 0, 127, 0
  for i = w0, w1 do
    local c = prog[i]
    if c.vb < lo then lo = c.vb end
    local t = c.vu[#c.vu] or c.vb
    if t > hi then hi = t end
    for v = 0, #c.vu do
      local x = sp:vel(c, v)
      if x > 0 then
        if x < blo then blo = x end
        if x > bhi then bhi = x end
      end
    end
  end
  local mn = m.notes
  for i = 1, #mn do
    local b = mn[i]
    if b.p >= ws and b.p < ws + span then
      local v = sp:mvel(b)
      if b.n > hi then hi = b.n end
      if v < alo then alo = v end
      if v > ahi then ahi = v end
    end
  end
  if hi - lo < 24 then local c = (hi + lo) * 0.5; lo, hi = c - 12, c + 12 end
  if ahi - alo < 20 then local c = (alo + ahi) * 0.5; alo, ahi = c - 10, c + 10 end
  if bhi - blo < 20 then local c = (blo + bhi) * 0.5; blo, bhi = c - 10, c + 10 end
  local asc, bsc = 1 / (ahi - alo), 1 / (bhi - blo)
  local sy = 31 / (hi - lo)
  local function y(v) return clamp(floor(42 - (v - lo) * sy + 0.5), 11, 42) end
  local p0 = sp:pos()
  if running then
    p0 = p0 - 1 + (slen > 0 and clamp((util.time() - tlast) / slen, 0, 1) or 0)
    if p0 < 0 then p0 = p0 + sp.total end
  end
  for i = w0, w1 do
    local c = prog[i]
    local xa = floor((st[i] - ws) * sx)
    local xb = floor((st[i] + c.len - ws) * sx)
    local cur = i == idx
    local U = #c.vu
    for v = 0, U do
      local nt = v == 0 and c.vb or c.vu[v]
      local vl = sp:vel(c, v)
      screen.level(vl <= 0 and 1 or (2 + floor(clamp((vl - blo) * bsc, 0, 1) * 6 + 0.5) + (cur and 4 or 0)))
      screen.rect(xa, y(nt), max(1, xb - xa), 1)
      screen.fill()
    end
    if i > w0 then
      local pc = prog[i - 1]
      local pU = #pc.vu
      screen.level(2)
      for v = 0, U do
        local a = v == 0 and pc.vb or pc.vu[floor((v - 1) * (pU - 1) / max(1, U - 1) + 0.5) + 1]
        local b = v == 0 and c.vb or c.vu[v]
        if a and a ~= b then
          screen.move(xa + 0.5, y(a) + 0.5)
          screen.line(xa + 0.5, y(b) + 0.5)
          screen.stroke()
        end
      end
    end
    screen.level(cur and 15 or (c.kind > 0 and 6 or 2))
    screen.rect(xa, 46, max(1, xb - xa - 1), 2)
    screen.fill()
  end
  for i = 1, #mn do
    local b = mn[i]
    if b.p >= ws and b.p < ws + span then
      local x = floor((b.p - ws) * sx)
      local on = running and p0 >= b.p and p0 < b.p + b.d
      screen.level(on and 15 or (5 + floor(clamp((sp:mvel(b) - alo) * asc, 0, 1) * 7 + 0.5)))
      screen.rect(x, y(b.n) - 1, max(2, floor(b.d * sx)), 2)
      screen.fill()
    end
  end
  local px = floor((p0 - ws) * sx) + 0.5
  if px >= 0 and px <= 128 then
    screen.level(running and 5 or 2)
    screen.move(px, 10)
    screen.line(px, 43)
    screen.stroke()
  end
  screen.level(alt and 7 or 1)
  screen.move(0, 44.5)
  screen.line(128, 44.5)
  screen.stroke()
end

local function draw_loops()
  local L = lp.lp
  local n = #L
  local gs = lp.gs
  local fr = (running and slen > 0) and clamp((util.time() - tlast) / slen, 0, 1) or 0
  local h, nh, bh = 8, 3, 3
  for k = 8, 2, -1 do
    h, nh = k, k >= 6 and 3 or (k >= 4 and 2 or 1)
    bh = (n - 1) * h + nh
    if bh <= 33 then break end
  end
  local y0 = 9 + floor((33 - bh) / 2)
  local ph = h - nh >= 2 and 1 or 0
  for i = 1, n do
    local l = L[i]
    local ny = y0 + (n - i) * h
    local sx = 128 / l.len
    local sw = lp:swell(l)
    screen.level(1)
    screen.rect(0, ny + floor(nh / 2), 128, 1)
    screen.fill()
    for _, x in ipairs(l.notes) do
      local on = running and x.on > gs
      screen.level(on and 15 or (2 + floor(x.v * sw * 8 + 0.5)))
      local xa, w = floor(x.t * sx), max(1, floor(x.d * sx + 0.5))
      screen.rect(xa, ny, min(w, 128 - xa), nh)
      screen.fill()
      if xa + w > 128 then
        screen.rect(0, ny, xa + w - 128, nh)
        screen.fill()
      end
    end
    local px = floor(((running and (l.pos - 1 + fr) or l.pos) % l.len) * sx)
    screen.level(running and 8 or 3)
    screen.rect(px, ny - ph, 1, nh + ph * 2)
    screen.fill()
  end
  screen.level(alt and 7 or 1)
  screen.move(0, 44.5)
  screen.line(128, 44.5)
  screen.stroke()
  local pool, snd, R = lp.pool, lp.snd, lp.root
  for k = 0, 11 do
    local pc = (R + k) % 12
    local lv = pool[pc] and (pool[pc] == 1 and 7 or 4) or 1
    for _, s in ipairs(snd) do if s.n % 12 == pc then lv = 15; break end end
    if lv < 4 then
      for _, l in ipairs(L) do
        for _, x in ipairs(l.notes) do if x.n % 12 == pc then lv = 2 end end
      end
    end
    screen.level(lv)
    screen.rect(floor(k * 128 / 12), 46, 9, 2)
    screen.fill()
  end
end

function redraw()
  if upd:pending() then upd:redraw() return end
  screen.clear()
  screen.aa(0)
  local rt, mo, ch = (eng == 1 and gen or EN[eng]):info()
  if rt ~= hdr_r or mo ~= hdr_m then hdr_r, hdr_m, hdr = rt, mo, rt .. " " .. mo end
  screen.level(15)
  screen.move(0, 6)
  screen.text(hdr)
  screen.level(running and 8 or 15)
  screen.move(128, 6)
  screen.text_right(running and ch or "stop")
  if eng == 2 then draw_ambient() elseif eng == 3 then draw_loops() else draw_classic() end

  local pg = PG[eng][pages[eng]]
  local a, b = pg[2], pg[3]
  local ai, bi = cid(a), cid(b)
  local av, bv = params:get(ai), params:get(bi)
  cell(0, 61, type(a[2]) == "function" and a[2]() or a[2], a[3](av), nrm(ai, av))
  screen.level(1)
  screen.move(64.5, 51)
  screen.line(64.5, 62)
  screen.stroke()
  cell(67, 61, type(b[2]) == "function" and b[2]() or b[2], b[3](bv), nrm(bi, bv))

  local msg
  if toast then
    if util.time() < toast_t then msg = toast else toast = nil end
  end
  if not msg and alt then msg = "e1 engine  " .. (running and "k2 stop" or "k2 run") .. "  k3 rand" end
  if msg then
    local w = (screen.text_extents and screen.text_extents(msg) or #msg * 4) + 12
    if w > 126 then w = 126 end
    local x = floor((128 - w) / 2)
    screen.level(0)
    screen.rect(x, 17, w, 14)
    screen.fill()
    screen.level(4)
    screen.rect(x + 0.5, 17.5, w - 1, 13)
    screen.stroke()
    screen.level(15)
    screen.move(x + w / 2, 26)
    screen.text_center(msg)
  end

  screen.update()
end

function cleanup()
  clock.transport.start = function() end
  clock.transport.stop = function() end
  running = false
  if seq then clock.cancel(seq); seq = nil end
  if drift_clk then clock.cancel(drift_clk); drift_clk = nil end
  if rdm then rdm:stop() end
  panic()
end