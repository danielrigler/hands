local S = {}
S.__index = S

local floor, ceil, abs, max, min = math.floor, math.ceil, math.abs, math.max, math.min
local random, exp, sin = math.random, math.exp, math.sin

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

S.MODES = {
  {short = "lydian",   br = 1, s = {0,2,4,6,7,9,11}, w = {1.0,1.4,0.3,0.3,0.7,0.8,0.5}},
  {short = "ionian",   br = 2, s = {0,2,4,5,7,9,11}, w = {1.0,0.55,0.45,0.9,0.7,0.85,0.2}},
  {short = "mixolyd",  br = 3, s = {0,2,4,5,7,9,10}, w = {1.0,0.4,0.3,0.9,0.5,0.6,1.3}},
  {short = "dorian",   br = 4, s = {0,2,3,5,7,9,10}, w = {1.0,0.6,0.7,1.3,0.6,0.3,0.8}},
  {short = "aeolian",  br = 5, s = {0,2,3,5,7,8,10}, w = {1.0,0.3,0.8,0.8,0.6,1.1,1.0}},
  {short = "phrygian", br = 6, s = {0,1,3,5,7,8,10}, w = {1.0,1.4,0.8,0.7,0.2,0.8,0.9}},
  {short = "harm min", br = 5, s = {0,2,3,5,7,8,11}, w = {1.0,0.3,0.4,0.8,1.1,1.0,0.3}},
  {short = "mel min", br = 4, s = {0,2,3,5,7,9,11}, w = {1.0,0.7,0.3,1.1,0.9,0.3,0.3}},
  {short = "locrian",  br = 7, s = {0,1,3,5,6,8,10}, w = {0.8,1.0,0.7,0.8,0.9,1.0,0.8}},
}
S.MNAMES = {}
for i = 1, #S.MODES do S.MNAMES[i] = S.MODES[i].short end

local BR = {1, 2, 3, 4, 5, 6, 9}
local BOFF = {-1, 1, -2, 2, -1, -3}
local MOFF = {3, 4, 8, 9}
local SUBS = {0, -2, 2, -1, 1, 3}
local LYD = {0,2,4,6,7,9,11}
local T = include("lib/theory")
local PCN, R12 = T.PC, T.R12
local ML = {4, 4, 3, 4, 6, 5, 2, 4}

S.BPC = {0.5, 1, 2, 3, 4, 6, 8}
S.BPCN = {"1/2 bar", "1 bar", "2 bars", "3 bars", "4 bars", "6 bars", "8 bars"}
S.RICH = {"triads", "7ths", "9ths", "lush"}
S.SUSP = {"none", "light", "medium", "heavy"}
S.SPAR = {"full", "medium", "light", "open"}
S.FLOW = {"steps", "gentle", "moving", "jumps"}

function S.lab(t) return function(v) return t[floor(v * 3 + 0.5) + 1] or "?" end end

local function fifth(d, s) return (s[(d + 4) % 7 + 1] - s[d + 1]) % 12 end
local function third(d, s) return (s[(d + 2) % 7 + 1] - s[d + 1]) % 12 end

local function cdist(x, y)
  local d = (x - y) % 12
  return d > 6 and 12 - d or d
end

local function dist(a, b, s)
  local t = 0
  for k = 0, 4, 2 do
    local y = s[(b + k) % 7 + 1]
    local m = 12
    for j = 0, 4, 2 do
      local d = cdist(s[(a + j) % 7 + 1], y)
      if d < m then m = d end
    end
    t = t + m
  end
  return t
end

local function newc(d)
  return {d = d, ue = random(), us = random(), us2 = random(), ub = random(), u7 = random(),
          usp = random(), uz = random(), uk = random(), uo = random(), dv = random() - 0.5,
          dn = 0, ph = 1, pi = 1, len = 16, P = {}, set = {}, vu = {}, vv = {}, vb = 48, U = 0,
          root = 0, th = 4, i5 = 7, sus = 0, name = "", rom = "", kind = 0}
end

local function copyc(c)
  local o = newc(c.d)
  o.ue, o.us, o.us2, o.ub, o.u7, o.usp = c.ue, c.us, c.us2, c.ub, c.u7, c.usp
  o.uz, o.uk, o.uo, o.ph, o.pi = c.uz, c.uk, c.uo, c.ph, c.pi
  return o
end

function S.new(q, cb)
  local o = setmetatable({q = q, cb = cb}, S)
  o.root = 0
  o.prog, o.start = {}, {}
  o.idx, o.cstep, o.total, o.pass, o.gs = 1, 0, 16, 0, 0
  o.act, o.ws, o.keys = {}, {}, {}
  o.m = {notes = {}, carry = 0, mp = nil, li = 0, last = nil}
  o.mact = {}
  o.ss = 0.25
  o.pend = false
  o.ds, o.dr, o.dv, o.dt, o.dm = false, false, false, false, false
  o:newp(true)
  return o
end

function S:pick(s, a, b, nx)
  local q = self.q
  local W = S.MODES[q.mode].w
  local ws = self.ws
  local tgt = 1.2 + q.flow * 4.2
  local tp = 0.55 + q.surp * 0.7
  local tot = 0
  for d = 0, 6 do
    local w = 0
    if d ~= a and (q.dim or d == 0 or fifth(d, s) == 7) then
      w = W[d + 1]
      if b and d == b then w = w * 0.55 end
      if a then
        local x = dist(a, d, s) - tgt
        w = w * exp(-(x * x) / 4.5)
        if (d - a) % 7 == 3 then w = w * 1.25 end
      end
      if nx then
        if d == nx then w = 0
        else
          local y = dist(d, nx, s) - tgt
          w = w * exp(-(y * y) / 6)
        end
      end
      if w > 0 then w = w ^ (1 / tp) end
    end
    ws[d + 1] = w
    tot = tot + w
  end
  if tot <= 0 then return ((a or 0) + 2) % 7 end
  local r = random() * tot
  for d = 0, 6 do
    r = r - ws[d + 1]
    if r <= 0 then return d end
  end
  return 0
end

function S:phrase(m, a, b, first)
  local q = self.q
  local s = S.MODES[q.mode].s
  local ph = {}
  for k = 1, m do
    local d
    if first and k == 1 and q.sroot then d = 0
    else d = self:pick(s, a, b, (first and k == m and m > 1) and ph[1] or nil) end
    ph[k] = d
    b = a; a = d
  end
  return ph
end

function S:build()
  local q = self.q
  local s = S.MODES[q.mode].s
  local n = max(1, ceil(q.len / q.bpc - 1e-6))
  local degs, pid, pix
  for _ = 1, 6 do
    degs, pid, pix = {}, {}, {}
    if n <= 5 then
      local A = self:phrase(n, nil, nil, true)
      for i = 1, n do degs[i] = A[i]; pid[i] = 1; pix[i] = i end
    else
      local m = min(n, ML[random(#ML)])
      local phs = {self:phrase(m, nil, nil, true)}
      local i, k = 0, 0
      while i < n do
        k = k + 1
        local id = 1
        if k > 1 then
          local r = random()
          if r < 0.42 then id = 1
          elseif r < 0.62 and #phs > 1 then id = random(2, #phs)
          else
            phs[#phs + 1] = self:phrase(m, degs[i], degs[i - 1], false)
            id = #phs
          end
        end
        local P = phs[id]
        for j = 1, m do
          if i < n then i = i + 1; degs[i] = P[j]; pid[i] = id; pix[i] = j end
        end
      end
    end
    for i = 2, n do
      if degs[i] == degs[i - 1] then
        degs[i] = self:pick(s, degs[i - 1], degs[i - 2], degs[i + 1] or degs[1])
        pid[i] = 0
      end
    end
    if n > 2 and degs[n] == degs[1] then
      degs[n] = self:pick(s, degs[n - 1], degs[n - 2], degs[1])
      pid[n] = 0
    end
    local seen, dc = {}, 0
    for i = 1, n do if not seen[degs[i]] then seen[degs[i]] = true; dc = dc + 1 end end
    if dc >= min(3, n) then break end
  end
  local tpl, prog = {}, self.prog
  for i = #prog, 1, -1 do prog[i] = nil end
  local w = 0
  for i = 1, n do
    local key = pid[i] * 100 + pix[i]
    local c
    if pid[i] > 0 and tpl[key] and tpl[key].d == degs[i] then
      c = copyc(tpl[key])
      if random() < 0.12 then c.uz = random(); c.ue = random() end
    else
      c = newc(degs[i])
      c.ph, c.pi = pid[i], pix[i]
      if pid[i] > 0 then tpl[key] = c end
    end
    w = w * 0.6 + (random() - 0.5) * 20
    c.dn = w
    prog[i] = c
  end
end

function S:safe(d, s)
  if self.q.dim then return d end
  for i = 1, #SUBS do
    local x = (d + SUBS[i]) % 7
    if fifth(x, s) == 7 then return x end
  end
  return d
end

local function addp(P, x, dup)
  if not x then return end
  if not dup then for i = 1, #P do if P[i] == x then return end end end
  P[#P + 1] = x
end

function S:realize(c, first, prt)
  local q = self.q
  local m = S.MODES[q.mode]
  local s = m.s
  local R = self.root
  local kind, d, rt = 0, c.d, 0
  local sur = not (first and q.sroot) and c.uz < q.surp * 0.42
  if sur and q.surp > 0.35 and c.uk < 0.38 then
    kind = 2
    s = LYD
    d = 0
    rt = ((prt or R) + MOFF[floor(c.uo * 4) + 1]) % 12
  else
    if sur then
      local b = clamp(m.br + BOFF[floor(c.uo * #BOFF) + 1], 1, 7)
      local bs = S.MODES[BR[b]].s
      if b ~= m.br and (q.dim or fifth(d, bs) == 7)
        and (bs[d + 1] ~= s[d + 1] or third(d, bs) ~= third(d, s) or fifth(d, bs) ~= fifth(d, s)) then
        s = bs
        kind = 1
      end
    end
    if d == 0 and kind == 0 and not q.dim and fifth(0, s) ~= 7 then s = S.MODES[6].s end
    d = self:safe(d, s)
    rt = (R + s[d + 1]) % 12
  end
  local b0 = s[d + 1]
  local function iv(k) return (s[(d + k) % 7 + 1] - b0) % 12 end
  local i3, i5, i7, i9, i11, i13 = iv(2), iv(4), iv(6), iv(1), iv(3), iv(5)
  local lvl = floor(q.rich * 3 + c.ue)
  if lvl > 3 then lvl = 3 end
  local th, sus = i3, 0
  if c.us < q.susp * 0.9 then
    local s4, s2 = i11 == 5, i9 == 2
    if s4 and (c.us2 < 0.55 or not s2) then th = 5; sus = 4
    elseif s2 then th = 2; sus = 2 end
  end
  local sev = lvl >= 1 and i7 or nil
  if lvl == 2 and c.u7 > 0.62 then sev = nil end
  local nine, ext
  if lvl >= 2 and i9 ~= 1 and i9 ~= th then nine = i9 end
  if lvl >= 3 then
    if i11 ~= th and (i11 - th) % 12 ~= 1 then ext = i11
    elseif i13 ~= sev and (i13 - i5) % 12 ~= 1 then ext = i13 end
  end
  local P = c.P
  for i = #P, 1, -1 do P[i] = nil end
  addp(P, th)
  if ext then addp(P, ext) elseif nine and not sev then addp(P, nine) end
  addp(P, sev)
  addp(P, nine)
  addp(P, i5)
  addp(P, 0)
  if #P < 4 then addp(P, 0, true) end
  local U = clamp(floor(4 - q.sparse * 2.2 + c.usp * 0.9), 2, 4)
  if U > #P then U = #P end
  c.U = U
  local set = c.set
  for i = 0, 11 do set[i] = nil end
  for i = 1, #P do set[(rt + P[i]) % 12] = true end
  c.root, c.th, c.i5, c.sus, c.kind, c.sc = rt, th, i5, sus, kind, s
  local q3
  if sus > 0 then q3 = "sus" .. sus
  elseif th == 3 then q3 = (i5 == 6 and not sev) and "\u{b0}" or "m"
  else q3 = (i5 == 8) and "+" or "" end
  local top = (ext and (ext == i11 and "11" or "13")) or (nine and sev and "9") or (sev and "7") or nil
  local tag = ""
  if ext and ext == i11 and i11 == 6 then
    tag = (sev == 11 and "maj7" or (sev and "7" or "add")) .. "#11"
  elseif top then
    if th == 3 and i5 == 6 and sev == 9 then q3, tag = "", "\u{b0}" .. top
    elseif th == 3 and i5 == 6 then tag = top .. "b5"
    elseif sev == 11 and th == 3 then tag = "(maj" .. top .. ")"
    elseif sev == 11 then tag = "maj" .. top
    else tag = top end
  elseif nine then tag = "add9" end
  local nm = PCN[rt + 1]
  if sus > 0 and tag ~= "" then c.name = nm .. q3 .. "(" .. tag .. ")" else c.name = nm .. q3 .. tag end
  local r = R12[(rt - R) % 12 + 1]
  if sus == 0 and th == 3 then r = r:lower() end
  if i5 == 6 then r = r .. "\u{b0}" elseif i5 == 8 then r = r .. "+" end
  c.rom = r
end

function S:realize_all()
  local prog = self.prog
  local pr = nil
  for i = 1, #prog do
    self:realize(prog[i], i == 1, pr)
    pr = prog[i].root
  end
end

function S:timeline()
  local q, prog = self.q, self.prog
  local n = #prog
  local base = floor(q.bpc * 16 + 0.5)
  local tot = q.len * 16
  local mean = 0
  for i = 1, n do mean = mean + prog[i].dv end
  mean = mean / n
  local st, t = self.start, 0
  for i = 1, n do
    local c = prog[i]
    local L = (i < n) and base or (tot - base * (n - 1))
    L = L * (1 + q.dev * (c.dv - mean) * 1.2)
    c.len = max(4, floor(L + 0.5))
    st[i] = t
    t = t + c.len
  end
  for i = #st, n + 1, -1 do st[i] = nil end
  self.total = t
end

local CA, CN = {{}, {}, {}, {}}, {0, 0, 0, 0}
local pk, tmp, bv = {}, {}, {}
local V = {bc = 1e9}

local function evalv(U)
  for i = 1, U do tmp[i] = pk[i] end
  for i = 2, U do
    local x, j = tmp[i], i - 1
    while j >= 1 and tmp[j] > x do tmp[j + 1] = tmp[j]; j = j - 1 end
    tmp[j + 1] = x
  end
  for i = 2, U do if tmp[i] == tmp[i - 1] then return end end
  local cost, mg, gx = 0, V.mg, V.gx
  for i = 2, U do
    local g = tmp[i] - tmp[i - 1]
    if g < mg then cost = cost + (mg - g) * 0.8 end
    if g > gx then cost = cost + (g - gx) * 0.45 end
    if g == 1 then cost = cost + 2 elseif g == 2 and tmp[i - 1] < 57 then cost = cost + 1 end
  end
  local g0 = tmp[1] - V.vb
  if g0 < 3 then cost = cost + 3 end
  if tmp[1] < 52 and g0 < 7 then cost = cost + 1.5 end
  local sum = 0
  for i = 1, U do sum = sum + tmp[i] end
  cost = cost + abs(sum / U - V.ctr) * 0.2
  local pu = V.pu
  if pu then
    local k = #pu
    local vl = 0
    if k == U then
      for i = 1, U do vl = vl + abs(tmp[i] - pu[i]) end
    else
      for i = 1, U do
        local m = 99
        for j = 1, k do local d = abs(tmp[i] - pu[j]); if d < m then m = d end end
        vl = vl + m
      end
      for j = 1, k do
        local m = 99
        for i = 1, U do local d = abs(tmp[i] - pu[j]); if d < m then m = d end end
        vl = vl + m
      end
      vl = vl * 0.5
    end
    local tm = abs(tmp[U] - pu[k])
    cost = cost + (vl + tm * 0.6) * V.wv
    if tm > 7 then cost = cost + (tm - 7) * 0.4 * (1 - V.fl) end
  end
  if tmp[U] % 12 == V.rt then cost = cost + 0.7 end
  cost = cost + random() * V.tp
  if cost < V.bc then
    V.bc = cost
    for i = 1, U do bv[i] = tmp[i] end
  end
end

local function rec(k, U)
  if k > U then evalv(U) return end
  local a = CA[k]
  for i = 1, CN[k] do pk[k] = a[i]; rec(k + 1, U) end
end

local function near(pc, ref) return ref + ((pc - ref + 6) % 12) - 6 end

function S:voice(c, pb, pu)
  local q = self.q
  local reg, sp, fl = q.reg, q.sparse, q.flow
  local rt = c.root
  local bt = reg - 22
  local b = near(rt, pb or bt)
  while b - bt > 7 do b = b - 12 end
  while bt - b > 7 do b = b + 12 end
  if pb and c.sus == 0 and c.ub < q.nat * 0.3 then
    for k = 1, 2 do
      local nb = near((rt + (k == 1 and c.th or c.i5)) % 12, pb)
      local dn = abs(nb - pb)
      if dn <= 2 and dn < abs(b - pb) and abs(nb - bt) <= 8 then b = nb; break end
    end
  end
  c.vb = b
  local lo = max(b + 7 + floor(sp * 5), reg - 10)
  local hi = reg + 13 + floor(sp * 8)
  V.mg, V.gx = 2 + sp * 3.5, 9 + sp * 7
  V.vb, V.pu, V.rt = b, (pu and #pu > 0) and pu or nil, rt
  V.ctr = reg + 4 + sp * 4
  V.wv, V.fl = 1 - 0.55 * fl, fl
  V.tp = 0.05 + q.nat * 1.6
  local U = c.U
  local vu = c.vu
  while U >= 1 do
    for k = 1, U do
      local pc = (rt + c.P[k]) % 12
      local a, cnt = CA[k], 0
      local x = lo + (pc - lo) % 12
      while x <= hi do cnt = cnt + 1; a[cnt] = x; x = x + 12 end
      CN[k] = cnt
    end
    V.bc = 1e9
    rec(1, U)
    if V.bc < 1e9 then break end
    U = U - 1
  end
  for i = #vu, 1, -1 do vu[i] = nil end
  local vv = c.vv
  for i = #vv, 1, -1 do vv[i] = nil end
  for i = 1, U do vu[i] = bv[i] end
  if U < 1 then vu[1] = lo + (rt + c.P[1] - lo) % 12 end
end

function S:revoice(from)
  local prog = self.prog
  local n = #prog
  local pb, pu = self.pb, self.pu
  for k = 0, n - 1 do
    local c = prog[(from - 1 + k) % n + 1]
    self:voice(c, pb, pu)
    pb, pu = c.vb, c.vu
  end
end

function S:finish()
  self:realize_all()
  self:timeline()
  if not self.pu then
    self:revoice(1)
    local l = self.prog[#self.prog]
    self.pb, self.pu = l.vb, l.vu
    self:revoice(1)
    self.pb, self.pu = nil, nil
  else
    self:revoice(1)
  end
  self.ds, self.dr, self.dv, self.dt = false, false, false, false
end

function S:newp(now)
  local q = self.q
  if q.rootlock then self.root = q.root else self.root = random(12) - 1 end
  if now then
    self:build()
    self:finish()
    self.idx, self.cstep = 1, 0
  else
    self.pend = true
  end
end

function S:vary()
  local q, prog = self.q, self.prog
  local n = #prog
  local s = S.MODES[q.mode].s
  if n < 2 or random() < 0.28 then
    for _ = 1, random(2) do
      local c = prog[random(n)]
      c.ue, c.us, c.us2, c.usp, c.u7, c.uz = random(), random(), random(), random(), random(), random()
    end
  else
    local i = q.sroot and random(2, n) or random(n)
    local c = prog[i]
    local a, b, nx = prog[(i - 2) % n + 1].d, prog[(i - 3) % n + 1].d, prog[i % n + 1].d
    local nd = self:pick(s, a, b, nx)
    if nd == c.d then nd = self:pick(s, a, b, nx) end
    local all = c.ph > 0 and random() < 0.65
    for j = 1, n do
      local x = prog[j]
      if j == i or (all and x.ph == c.ph and x.pi == c.pi) then
        local pa, px = prog[(j - 2) % n + 1].d, prog[j % n + 1].d
        if nd ~= pa and nd ~= px then
          x.d = nd
          x.uz, x.ue, x.us = random(), random(), random()
        end
      end
    end
  end
  self.dr = true
end

function S:clear()
  for k in pairs(self.act) do self.act[k] = nil end
  self.restrike = self.cstep > 0
end

function S:reset()
  self.idx, self.cstep, self.restrike = 1, 0, false
  for k in pairs(self.act) do self.act[k] = nil end
  local m = self.m
  m.carry, m.mp, m.li = 0, nil, 0
  for k = #self.mact, 1, -1 do self.mact[k] = nil end
  for i = #m.notes, 1, -1 do m.notes[i] = nil end
end

local function slotch(q, i, U)
  local c
  if i == 0 then c = q.chb elseif i == U then c = q.chs elseif i == 1 then c = q.cht else c = q.cha end
  return c > 0 and c or q.ch
end

local function slotlv(q, i, U)
  if i == 0 then return q.lvb elseif i == U then return q.lvs elseif i == 1 then return q.lvt end
  return q.lva
end

function S:vel(c, v)
  local x = c.vv[v + 1]
  if x then return x end
  local q, U = self.q, #c.vu
  local lv = slotlv(q, v, U)
  if lv <= 0 then return 0 end
  return clamp(floor(q.vel * lv + c.dn * q.nat + (v == U and 3 or 0)), 1, 127)
end

function S:has(c, n, ch)
  local q = self.q
  if c.vb == n and slotch(q, 0, #c.vu) == ch then return true end
  local vu, U = c.vu, #c.vu
  for i = 1, U do
    if vu[i] == n and slotch(q, i, U) == ch then return true end
  end
  return false
end

function S:release(now, ov, keys)
  for k, a in pairs(self.act) do
    if a.dead then self.act[k] = nil
    elseif not (keys and keys[k]) and a.te > now + ov then a.te = now + ov end
  end
end

function S:start_chord(i, plen, off)
  local q, prog = self.q, self.prog
  local n = #prog
  local c = prog[i]
  self.pb, self.pu = c.vb, c.vu
  local now = util.time()
  local ss = self.ss
  local sm = q.smooth
  local keys = self.keys
  for k in pairs(keys) do keys[k] = nil end
  local U = #c.vu
  for v = 0, U do
    local x = v == 0 and c.vb or c.vu[v]
    keys[x + slotch(q, v, U) * 200] = true
  end
  self:release(now, max(0, sm) * 0.5 * min(plen or c.len, 32) * ss, keys)
  local ma, mk = self.mact, 0
  for j = 1, #ma do
    local a = ma[j]
    if not a.dead then
      if not self:fits(c, a.n) then self.cb.cut(a) end
      mk = mk + 1; ma[mk] = a
    end
  end
  for j = #ma, mk + 1, -1 do ma[j] = nil end
  local roll = random() < q.nat * 0.4
  local rs = 0.03 + q.nat * 0.08
  local dyn = c.dn * q.nat
  for v = 0, U do
    local x = v == 0 and c.vb or c.vu[v]
    local ch = slotch(q, v, U)
    local key = x + ch * 200
    local L, el, j, cnt = c.len - (off or 0), c.len, i % n + 1, 1
    while cnt < n and self:has(prog[j], x, ch) do
      L = L + prog[j].len; el = prog[j].len
      j = j % n + 1; cnt = cnt + 1
    end
    local adj = sm * 0.5 * min(el, 32)
    if adj < -el * 0.6 then adj = -el * 0.6 end
    local tr = (L + adj) * ss
    local a = self.act[key]
    if a and not a.dead then
      a.te = now + a.o + tr
      c.vv[v + 1] = a.v
    else
      local lv = slotlv(q, v, U)
      c.vv[v + 1] = 0
      if lv > 0 then
        local o = roll and v * rs or random() * q.nat * 0.35
        local vel = q.vel * lv * (1 + (random() - 0.5) * 0.35 * q.nat) + dyn + (v == U and 3 or 0)
        local e = {n = x, c = ch, v = clamp(floor(vel), 1, 127), o = o, te = now + o + tr}
        self.act[key] = e
        self.cb.pad(e)
        c.vv[v + 1] = e.v
      end
    end
  end
end

function S:boundary()
  local plen = self.lastlen
  local ch = self.ds or self.dr or self.dv or self.dt or self.dm
  if self.ds then
    local n0 = self.idx
    self:build()
    self:realize_all()
    self:timeline()
    self.idx = (n0 - 1) % #self.prog + 1
    self:revoice(self.idx)
    self.ds, self.dr, self.dv, self.dt = false, false, false, false
  else
    if self.dt then self:timeline(); self.dt = false end
    if self.dr then self:realize_all() end
    if self.dr or self.dv then self:revoice(self.idx) end
    self.dr, self.dv = false, false
  end
  if self.idx == 1 then self:mplan(0) elseif ch then self:mplan(self.start[self.idx]) end
  self:start_chord(self.idx, plen)
end

function S:wrap()
  self.pass = self.pass + 1
  if random() < self.q.evo then self:vary() end
  if self.q.nat > 0.1 then self.dv = true end
end

function S:tick(ss)
  self.ss = ss
  if self.pend then
    self.pend = false
    self:build()
    self:finish()
    self:release(util.time(), max(0, self.q.smooth) * 8 * ss)
    self.idx, self.cstep = 1, 0
    self.m.carry = 0
  end
  if self.cstep == 0 then self:boundary()
  elseif self.restrike then self:start_chord(self.idx, nil, self.cstep) end
  self.restrike = false
  self:mtick()
  self.gs = self.gs + 1
  self.cstep = self.cstep + 1
  local c = self.prog[self.idx]
  if self.cstep >= c.len then
    self.lastlen = c.len
    self.cstep = 0
    self.idx = self.idx + 1
    if self.idx > #self.prog then self.idx = 1; self:wrap() end
  end
end

function S:pos() return (self.start[self.idx] or 0) + self.cstep end

local IOI = {2, 4, 6, 8, 12, 16}

function S:idx_at(p)
  local st = self.start
  p = p % max(1, self.total)
  for i = #self.prog, 1, -1 do if p >= st[i] then return i end end
  return 1
end

function S:chord_at(p) return self.prog[self:idx_at(p)] end

function S:fits(c, x)
  local pc = x % 12
  if (pc - c.vb) % 12 == 1 then return false end
  for i = 1, #c.vu do
    local v = c.vu[i]
    if (pc - v) % 12 == 1 or v - x == 1 or v - x == 13 then return false end
  end
  if c.set[pc] then return true end
  if c.kind == 2 then return false end
  local s, R, ins = c.sc, self.root, false
  for i = 1, 7 do if (R + s[i]) % 12 == pc then ins = true; break end end
  if not ins then return false end
  for i = 0, 11 do
    if c.set[i] and ((pc - i) % 12 == 1 or (i - pc) % 12 == 1) then return false end
  end
  return true
end

function S:clear_of(x)
  for _, a in pairs(self.act) do
    if not a.dead then
      local d = x - a.n
      if (d > 0 and d % 12 == 1) or d == -1 or d == -13 then return false end
    end
  end
  return true
end

function S:clip(t, d, x)
  local prog, n = self.prog, #self.prog
  local i = self:idx_at(t)
  local base = t - t % self.total
  local tt = base + self.start[i] + prog[i].len
  local k = 0
  while tt < t + d and k < n do
    i = i % n + 1
    if not self:fits(prog[i], x) then return max(1, tt - t - 0.25) end
    tt = tt + prog[i].len
    k = k + 1
  end
  return d
end

function S:phrase_plan(t)
  local q, m = self.q, self.m
  local a = q.mel
  local ph = {k = 1, io = {}, iv = nil, rec = {}}
  local L = m.last
  if L and random() < 0.45 then
    ph.n = L.n
    for i = 1, L.n do ph.io[i] = L.io[i] end
    ph.iv = L.iv
  else
    ph.n = 2 + floor(a * 3 + random() * 3)
    local w = {max(0, a - 0.55), a, a * 0.7 + 0.1, 0.7, 0.9 - 0.5 * a, 1 - 0.8 * a}
    for i = 1, ph.n do
      local tot = 0
      for j = 1, #w do tot = tot + w[j] end
      local r = random() * tot
      local x = 8
      for j = 1, #w do r = r - w[j]; if r <= 0 then x = IOI[j]; break end end
      ph.io[i] = x
    end
  end
  ph.ct = random(3)
  ph.amp = 3 + random() * 5
  local c = self:chord_at(t)
  local top = c.vu[#c.vu] or q.reg
  ph.c = max(top + 4, q.reg + 9) + random(0, 3)
  ph.t = t
  ph.rest = floor((1 - a) * 40 + random() * 24 + 4)
  return ph
end

local function contour(k, t)
  if k == 1 then return sin(3.14159265 * t) * 2 - 0.6
  elseif k == 2 then return 0.8 - 1.6 * t end
  return t < 0.6 and t * 2 - 0.4 or 0.8
end

function S:mpick(ph, c, cp, cn)
  local q, m = self.q, self.m
  local vu = c.vu
  local top = vu[#vu] or q.reg
  local k, n = ph.k, ph.n
  local tgt = ph.c + contour(ph.ct, (k - 1) / max(1, n - 1)) * ph.amp
  local lo, hi = q.reg + 3, q.reg + 24
  local edge = k == 1 or k == n
  local best, bs = nil, -1e9
  local mp = m.mp
  for x = lo, hi do
    local pc = x % 12
    local ins = self:fits(c, x) and (not cp or self:fits(cp, x))
    if ins then
      local sc = (cn and self:fits(cn, x)) and 0.6 or 0
      if c.set[pc] then sc = sc + 1.3 + (edge and 0.6 or 0)
      else
        local av = false
        for i = 0, 11 do if c.set[i] and (pc - i) % 12 == 1 then av = true; break end end
        sc = sc + (av and -1.6 or 0.2)
      end
      if mp then
        local iv = x - mp
        local a = abs(iv)
        if a == 0 then sc = sc - 0.8
        elseif a <= 2 then sc = sc + 1.0
        elseif a <= 4 then sc = sc + 0.6
        elseif a <= 7 then sc = sc - 0.1
        else sc = sc - 1.2 - (a - 7) * 0.2 end
        if abs(m.li) >= 5 and (iv > 0) ~= (m.li > 0) and a <= 3 then sc = sc + 0.9 end
        if ph.iv and ph.iv[k] then sc = sc - abs(iv - ph.iv[k]) * 0.35 end
      end
      sc = sc - abs(x - tgt) * 0.22
      if x <= top then sc = sc - 1.0 end
      for i = 1, #vu do if abs(x - vu[i]) == 1 then sc = sc - 1.5 end end
      sc = sc + random() * 0.9
      if sc > bs then bs = sc; best = x end
    end
  end
  return best
end

function S:mplan(from)
  local q, m = self.q, self.m
  local L = m.notes
  local k = 0
  for i = 1, #L do if L[i].p < from then k = k + 1; L[k] = L[i] end end
  for i = #L, k + 1, -1 do L[i] = nil end
  self.dm = false
  if q.mel < 0.02 then m.carry = 0; return end
  local total = self.total
  local nx = from == 0 and max(0, m.carry or 0) or from
  local ph = nil
  while true do
    if not ph then
      local t = ceil(nx / 4) * 4
      if t >= total then break end
      ph = self:phrase_plan(t)
    end
    local t = ph.t
    if t >= total then break end
    local kk, n = ph.k, ph.n
    local io = ph.io[kk] or 8
    local ci = self:idx_at(t)
    local pi = (ci - 2) % #self.prog + 1
    local ov = max(0, q.smooth) * 0.5 * min(self.prog[pi].len, 32)
    local cp = (t % self.total - self.start[ci] < ov + 1) and self.prog[pi] or nil
    local x = self:mpick(ph, self.prog[ci], cp, self.prog[ci % #self.prog + 1])
    if x then
      local dur = (kk == n) and (io + 8 + random(0, 12)) or io * (0.8 + random() * 0.25)
      dur = self:clip(t, dur, x)
      local dv = sin(3.14159265 * (kk - 0.5) / n) * 9 - 4 + (random() - 0.5) * 14 * q.nat
      L[#L + 1] = {p = t, n = x, d = dur, dv = dv, o = random() * q.nat * 0.25}
      if m.mp then ph.rec[kk] = x - m.mp; m.li = x - m.mp end
      m.mp = x
    end
    ph.k = kk + 1
    ph.t = t + io
    if ph.k > n then
      m.last = {n = n, io = ph.io, iv = ph.rec}
      nx = t + io + ph.rest
      ph = nil
    end
  end
  m.carry = ph and 0 or (nx - total)
end

function S:mvel(e) return clamp(floor(self.q.mvel + e.dv), 1, 127) end

function S:mtick()
  local q, L = self.q, self.m.notes
  local p = self:pos()
  for i = 1, #L do
    local e = L[i]
    if e.p == p and self:clear_of(e.n) then
      local o = e.o * self.ss
      local a = {n = e.n, v = self:mvel(e), c = q.chm > 0 and q.chm or q.ch, o = o,
                 te = util.time() + o + e.d * self.ss, mel = true}
      local ma = self.mact
      ma[#ma + 1] = a
      self.cb.pad(a)
    end
  end
end

function S:save()
  local t = {root = self.root, c = {}}
  for i, c in ipairs(self.prog) do
    local vu = {}
    for j = 1, #c.vu do vu[j] = c.vu[j] end
    t.c[i] = {c.d, c.ue, c.us, c.us2, c.ub, c.u7, c.usp, c.uz, c.uk, c.uo, c.dv, c.dn, c.ph, c.pi, c.vb, vu}
  end
  return t
end

function S:load(t)
  if type(t) ~= "table" or type(t.c) ~= "table" or #t.c == 0 then return false end
  local prog = self.prog
  for i = #prog, 1, -1 do prog[i] = nil end
  for i, r in ipairs(t.c) do
    local c = newc(r[1])
    c.ue, c.us, c.us2, c.ub, c.u7, c.usp = r[2], r[3], r[4], r[5], r[6], r[7]
    c.uz, c.uk, c.uo, c.dv, c.dn, c.ph, c.pi = r[8], r[9], r[10], r[11], r[12], r[13], r[14]
    prog[i] = c
  end
  self.root = self.q.rootlock and self.q.root or (t.root or 0)
  self.pb, self.pu = nil, nil
  self.pend = false
  self:finish()
  for i, r in ipairs(t.c) do
    local c, vu = prog[i], r[16]
    if r[15] and type(vu) == "table" and #vu > 0 then
      c.vb = r[15]
      for j = #c.vu, 1, -1 do c.vu[j] = nil end
      for j = 1, #vu do c.vu[j] = vu[j] end
    end
  end
  self:reset()
  return true
end

function S:info()
  local c = self.prog[self.idx]
  return PCN[self.root + 1], S.MODES[self.q.mode].short, c and (c.name .. " " .. c.rom) or ""
end

return S
