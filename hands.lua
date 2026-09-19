--
--
--
--          hands v0.03
--           @dddstudio
--
--
--
-- E1 page
-- E2 E3 the two dials
--
-- K2 vary
-- K3 new piece
-- K1+K2 run/stop
-- K1+K3 randomize all
--
-- free running by default;
-- params > clock to follow
-- the norns tempo

local Gen = include('lib/gen')
local T = include('lib/theory')
local Update = include('lib/update')
local cs = require 'controlspec'
local tab = require 'tabutil'

local floor, random, max, min = math.floor, math.random, math.max, math.min
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end

local p = {bright=0, space=0.35, motion=0.6, syn=0, rep=0.57, len=0.58, tens=0.35, stray=0.08, lh=0.45, rh=0.3, harm=0.35, drift=0.3,
           centre=66, rngw=48, vel=80, pedal=1.0, rubato=0.4, reso=0,
           swing=0.08, hum=0.3, poly=16, root=0, rootlock=false, pedcc=true, step=0.5, style=0}

local KEYS = {"free","C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}

local gen

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

local PAGES = {
  {"style", {"style", "style", function(v) return T.SNAMES[floor(v + 0.5)] or "?" end},
            {function() return synced and "tdiv" or "pace" end,
             function()
               if synced then return floor(clock.get_tempo() + 0.5) .. " syn" end
               return "pace" end,
             function(v)
               if synced then return SDIV[v] or "?" end
               return floor(v + 0.5) .. "bpm" end,
             function() return synced and 1 or 0.4 end}},
  {"range", {"reg", "register", nname},
            {"rngw", "width", function(v) return tostring(floor(v + 0.5)) end}},
  {"hands", {"left", "left", function()
              return gen and select(4, gen:info()) or "-" end},
            {"right", "right", pct}},
  {"time",  {"swing", "swing", pct},
            {"hum", "humanize", pct}},
  {"flow",  {"motion", "motion", nval},
            {"space", "space", pct}},
  {"beat",  {"syn", "synco", pct},
            {"rep", "repeat", pct}},
  {"touch", {"len", "length", pct},
            {"pedal", "pedal", pct}},
  {"tone",  {"mode", "mode", T.mode_label},
            {"stray", "stray", pct}},
  {"feel",  {"rubato", "rubato", pct},
            {"tens", "tension", pct}},
  {"shift", {"harm", "harmony", pct},
            {"drift", "drift", pct}},
}

local md
local ch, lch = 1, 1
local pedcc = true
local pedco
local own, oc = {}, {}
local nser, nheld, poly = 0, 0, 16
local seq
local running = true
local dirty = false
local step_sec = 0.55
local slen = 0.55
local tlast = 0
local sdirty = true
local alt = false
local page = 1
local pacc = 0
local upd
local gstep = 0
local ctick = 0
local hist, hn = {}, 0
local HL = 224
local devs = {}
local epoch = 0
local drift_clk, rdm
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
  for k, t in pairs(oc) do if t < bs then bs = t; bk = k end end
  if not bk then nheld = 0; return false end
  md:note_off(bk % 200, 0, bk // 200)
  own[bk] = nil; oc[bk] = nil
  nheld = nheld - 1
  return true
end

local function non(n, v, chn, hold)
  if n < 0 or n > 127 then return end
  local k = n + chn * 200
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
  own[k] = nil; oc[k] = nil
  nheld = nheld - 1
  md:note_off(n, 0, chn)
end

local function pcc(v)
  if not md then return end
  md:cc(64, v, ch)
  if lch ~= ch then md:cc(64, v, lch) end
end

local function repedal(hold, ep)
  pcc(0)
  if hold <= 0 or not playing(ep) then return end
  clock.sleep(0.04)
  if not playing(ep) then return end
  pcc(127)
  clock.sleep(hold)
  pcc(0)
end

local function panic()
  epoch = epoch + 1
  if pedco then clock.cancel(pedco); pedco = nil end
  if pedcc then pcc(0) end
  for k in pairs(own) do md:note_off(k % 200, 0, k // 200) end
  for k in pairs(own) do own[k] = nil end
  for k in pairs(oc) do oc[k] = nil end
  nheld = 0
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

local function echo(n, v, chn, dly, dur, ep)
  clock.sleep(dly)
  if not playing(ep) then return end
  non(n, v, chn, true)
  clock.sleep(dur)
  noff(n, chn)
end

local function voice(e)
  local ep = epoch
  local chn = (e.h == 1) and lch or ch
  if e.o > 0 then
    clock.sleep(e.o * step_sec)
    if not playing(ep) then return end
  end
  local n = e.n
  local cnt = #n
  if e.r > 1 then
    local sub = e.d * step_sec / e.r
    for j = 1, e.r do
      if not playing(ep) then return end
      non(n[1], max(1, e.v - (j - 1) * 9), chn)
      clock.sleep(sub * 0.72)
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
  local b = e.b
  if b then
    local rs = p.reso
    local v, d = e.v, 0
    for i = 1, #b do
      v = max(30, floor(v * (0.74 + 0.14 * rs)))
      d = d + 0.12 + random() * step_sec * (1.1 + 3.2 * rs)
      clock.run(echo, b[i], v, chn, d, min(90, dur * (0.5 + random() * 0.55)), ep)
    end
  end
  clock.sleep(max(0.03, dur - (st > 0 and st * (cnt - 1) or 0)))
  for i = 1, cnt do noff(n[i], chn) end
end

local function tick()
  if synced then clock.sync(1) end
  tlast = util.time()
  while true do
    if gen.tick == 0 then
      if dirty then
        gen:derive(); gen:update_scale(); gen:update_lut(); gen:plan_registers(); dirty = false
      end
      gen:bar_begin()
      if pedcc and gen.newchord and gen.barn > 0 then
        if pedco then clock.cancel(pedco) end
        pedco = clock.run(repedal,
          max(0, p.pedal - 0.5) * 2 * gen.hr * gen.bl * step_sec * 0.94 - 0.04, epoch)
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
    local even = gen.tick % 2 == 0
    gen:advance()
    local f = p.swing / 3
    if synced then
      local st = beatsec() * sdiv
      if math.abs(st - step_sec) > step_sec * 0.02 then
        step_sec = st
        p.step = st
        dirty = true
      end
      slen = step_sec * (even and (1 + f) or (1 - f))
      clock.sync(sdiv)
      if even and f > 0.001 then clock.sleep(step_sec * f) end
    else
      slen = step_sec * (even and (1 + f) or (1 - f))
      clock.sleep(slen)
    end
    gstep = gstep + 1
    tlast = util.time()
  end
end

local function stop_seq()
  if not running then return end
  running = false
  if seq then clock.cancel(seq); seq = nil end
  panic()
  sdirty = true
end

local function start_seq(fromtop)
  if running then return end
  if fromtop and gen then gen:reset() end
  running = true
  seq = clock.run(tick)
  sdirty = true
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
  
  params:add_trigger("newp", "New Piece")
  params:set_action("newp", function()
    if gen then gen:reroll(false); say("new piece") end
  end)
  params:add_trigger("vary", "Vary")
  params:set_action("vary", function()
    if gen then gen:mutate(); say("vary") end
  end)
  params:add_trigger("chaos", "Randomize All")
  params:set_action("chaos", function()
    if not gen then return end
    local sd = T.STYLE[p.style]
    sd = sd and sd.d
    local function j(v, a) return clamp(v + (random() - 0.5) * 2 * a, 0, 1) end
    if sd then
      params:set("pace", clamp(sd.pace * (0.86 + random() * 0.3), 6, 200), true)
      params:set("pedal", j(sd.pedal, 0.14), true)
      params:set("rubato", j(sd.rubato, 0.15), true)
      params:set("reso", j(sd.reso, 0.15), true)
      params:set("reg", clamp(60 + random(13), 40, 92), true)
    else
      params:set("pace", 8 + random() ^ 2 * 120, true)
      params:set("pedal", random() ^ 0.7, true)
      params:set("rubato", random() * 0.8, true)
      params:set("reso", random() * 0.6, true)
      params:set("reg", 52 + random(28), true)
    end
    step_sec = 15 / params:get("pace")
    p.step = step_sec
    p.pedal = params:get("pedal")
    p.rubato = params:get("rubato")
    p.reso = params:get("reso")
    p.centre = params:get("reg")
    gen:reroll(true)
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

  params:add_group("Music", 17)
    params:add_option("style", "style", T.SNAMES, 1)
  params:set_action("style", function(v)
    p.style = v - 1
    local st = T.STYLE[p.style]
    if st then for k, x in pairs(st.d) do params:set(k, x) end end
    dirty = true
    sdirty = true
  end)
  params:add_option("key", "key", KEYS, 1)
  params:set_action("key", function(v)
    p.rootlock = v > 1
    if v > 1 then p.root = v - 2; if gen then gen.root = v - 2 end end
    sdirty = true
  end)

  params:add_number("rngw", "range", 14, 74, 48)
  params:set_action("rngw", function(v) p.rngw = v; dirty = true end)
  params:add_control("pace", "pace", cs.new(6, 200, 'exp', 0, 30, "bpm"))
  params:set_action("pace", function(v)
    if not synced then step_sec = 15 / v; p.step = step_sec end
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
    if gen and math.abs(v - p.harm) > 0.06 then gen.progdirty = true end
    p.harm = v
    dirty = true
  end)
  params:add_control("drift", "drift", cs.new(0, 1, 'lin', 0, 0.3))
  params:set_action("drift", function(v) p.drift = v; dirty = true end)

  params:add_group("Feel", 5)
  params:add_control("pedal", "pedal", cs.new(0, 1, 'lin', 0, 1.0))
  params:set_action("pedal", function(v) p.pedal = v end)
  params:add_control("swing", "swing", cs.new(0, 1, 'lin', 0, 0.08))
  params:set_action("swing", function(v) p.swing = v; sdirty = true end)
  params:add_control("hum", "humanize", cs.new(0, 1, 'lin', 0, 0.3))
  params:set_action("hum", function(v) p.hum = v end)
  params:add_control("rubato", "rubato", cs.new(0, 1, 'lin', 0, 0.4))
  params:set_action("rubato", function(v) p.rubato = v end)
  params:add_control("reso", "resonance", cs.new(0, 1, 'lin', 0, 0))
  params:set_action("reso", function(v) p.reso = v; dirty = true end)


  params:add_group("Clock", 3)
  params:add_option("sync", "tempo", {"free running", "norns clock"}, 1)
  params:set_action("sync", function(v)
    synced = v == 2
    sdirty = true
    step_sec = synced and (beatsec() * sdiv) or (15 / params:get("pace"))
    p.step = step_sec
    dirty = true
    sdirty = true
  end)
  params:add_option("tdiv", "step", {"1/32", "1/16", "1/8", "1/4"}, 2)
  params:set_action("tdiv", function(v)
    sdiv = ({0.125, 0.25, 0.5, 1})[v]
    if synced then step_sec = beatsec() * sdiv; p.step = step_sec; dirty = true end
    sdirty = true
  end)
  params:add_binary("xport", "follow transport", "toggle", 1)
  params:set_action("xport", function(v) follow = v == 1 end)

  params:add_group("Output", 6)
  params:add_option("dev", "midi device", devs, 1)
  params:set_action("dev", function(v) panic(); md = midi.connect(v) end)
  params:add_number("chan", "channel", 1, 16, 1)
  params:set_action("chan", function(v) panic(); ch = v end)
  params:add_number("lchan", "left hand ch", 1, 16, 1)
  params:set_action("lchan", function(v) panic(); lch = v end)
  params:add_number("poly", "synth voices", 1, 64, 16)
  params:set_action("poly", function(v) poly = v; p.poly = v; dirty = true end)
  params:add_control("vel", "velocity", cs.new(20, 127, 'lin', 1, 80))
  params:set_action("vel", function(v) p.vel = v; dirty = true end)
  params:add_binary("pedcc", "send cc64", "toggle", 1)
  params:set_action("pedcc", function(v)
    pedcc = v == 1
    p.pedcc = pedcc
    dirty = true
    if not pedcc then pcc(0) end
  end)

  local function piecefile(fn)
    return (tostring(fn):gsub("%.pset$", ".piece"))
  end
  params.action_write = function(fn)
    if gen then tab.save(gen:save_state(), piecefile(fn)) end
  end
  params.action_read = function(fn)
    if gen and gen:load_state(tab.load(piecefile(fn))) then sdirty = true end
  end
  params.action_delete = function(fn) os.remove(piecefile(fn)) end

  gen = Gen.new(p)
  params:bang()
  gen:derive(); gen:reroll(false)
  seq = clock.run(tick)
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
    page = clamp(page + (pacc > 0 and 1 or -1), 1, #PAGES)
    pacc = 0
  else
    local c = PAGES[page][n]
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

function redraw()
  if upd:pending() then upd:redraw() return end
  screen.clear()
  screen.aa(0)
  local rt, mo, q = gen:info()

  if rt ~= hdr_r or mo ~= hdr_m then hdr_r, hdr_m, hdr = rt, mo, rt .. " " .. mo end
  screen.level(15)
  screen.move(0, 6)
  screen.text(hdr)
  screen.level(running and 4 or 15)
  screen.move(128, 6)
  screen.text_right(running and q or "stop")

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

  local pg = PAGES[page]
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
  if not msg and alt then msg = (running and "k2 stop" or "k2 run") .. "    k3 randomize" end
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