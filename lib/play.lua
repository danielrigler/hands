
local P = {}
P.__index = P

local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local random, exp = math.random, math.exp

local BK = {[1] = true, [3] = true, [6] = true, [8] = true, [10] = true}
local FSTR = {2.0, 0.0, 1.2, -4.0, -1.2}

local W = 5
local MAXS = 34

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

function P.new(g)
  local o = setmetatable({}, P)
  o.g = g
  o.hlo, o.span, o.pf, o.pn = 60, 11, 3, 60
  o.li, o.li2 = 0, 0
  o.anchor, o.lastanch = 60, 60
  o.hiw, o.low = 76, 52
  o.climax, o.climaxed = 80, false
  o.A = {pn = {}, li = {}, li2 = {}, hlo = {}, pf = {}, sc = {}}
  o.B = {pn = {}, li = {}, li2 = {}, hlo = {}, pf = {}, sc = {}}
  o.bw, o.bn, o.bf, o.bs, o.bh = {}, {}, {}, {}, {}
  for i = 1, MAXS do o.bw[i], o.bn[i], o.bf[i], o.bs[i], o.bh[i] = {}, {}, {}, {}, {} end
  o.path = {}
  o.cand = {}
  o.pv, o.pw, o.pc = {}, {}, {}
  o.pf2, o.psh, o.pst, o.pnl = {}, {}, {}, {}
  o.outn, o.outf, o.outs, o.outsh = {}, {}, {}, {}
  o.lockw, o.tens, o.song, o.stray, o.altpc, o.clw = 1, 0.35, 0.5, 0, 0, 1
  return o
end

local function upstep(g, n)
  local r = g.root
  for k = 1, 4 do if g.insc[(n - r + k) % 12 + 1] then return n + k end end
  return n + 2
end

local function dnstep(g, n)
  local r = g.root
  for k = 1, 4 do if g.insc[(n - r - k) % 12 + 1] then return n - k end end
  return n - 2
end

local function upct(g, n)
  local r = g.root
  for k = 1, 12 do if g.cpc[(n - r + k) % 12 + 1] then return n + k end end
  return n + 12
end

local function dnct(g, n)
  local r = g.root
  for k = 1, 12 do if g.cpc[(n - r - k) % 12 + 1] then return n - k end end
  return n - 12
end

local G_
local UCS, DCS = {{}, {}}, {{}, {}}
local US, DS, UC, DC = {}, {}, UCS[1], DCS[1]
local function us(n) local x = US[n]; if not x then x = upstep(G_, n); US[n] = x end; return x end
local function ds(n) local x = DS[n]; if not x then x = dnstep(G_, n); DS[n] = x end; return x end
local function uc(n) local x = UC[n]; if not x then x = upct(G_, n); UC[n] = x end; return x end
local function dc(n) local x = DC[n]; if not x then x = dnct(G_, n); DC[n] = x end; return x end

local function isct(g, n) return g.cpc[(n - g.root) % 12 + 1] end

local function nearct(g, x)
  if isct(g, x) then return x end
  local u, d = uc(x), dc(x)
  return (u - x <= x - d) and u or d
end

function P:prime()
  local g = self.g
  G_ = g
  for k in pairs(US) do US[k] = nil end
  for k in pairs(DS) do DS[k] = nil end
  for j = 1, 2 do
    local a, b = UCS[j], DCS[j]
    for k in pairs(a) do a[k] = nil end
    for k in pairs(b) do b[k] = nil end
  end
  UC, DC = UCS[1], DCS[1]
  local tn = g.p.tens or 0.35
  self.lockw = 0.5 + 0.5 * (g.lock or 1) / 2.6
  self.tens = tn
  self.song = g.song or 0.5
  self.stray = g.stray or 0
  self.altpc = g.altpc or 0
  self.clw = 1.2 - 0.6 * tn
end

function P:memo(k)
  UC, DC = UCS[k], DCS[k]
  self.altpc = self.g.altpc or 0
end

function P:reach(hlo, pf, ppn, n, gapsec)
  local span = self.span
  local hhi = hlo + span
  local dir = (n > ppn) and 1 or ((n < ppn) and -1 or 0)
  local shift, crossed = 0, false

  if n >= hlo and n <= hhi then
    shift = 0
  elseif dir > 0 and n <= hhi + 4 and pf >= 3 then
    crossed = true; shift = n - hhi
  elseif dir < 0 and n >= hlo - 4 and pf <= 2 then
    crossed = true; shift = hlo - n
  elseif n > hhi then
    shift = n - hhi
  else
    shift = hlo - n
  end

  local nlo = hlo
  if crossed then nlo = (dir > 0) and n or (n - span)
  elseif n > hhi then nlo = n - span
  elseif n < hlo then nlo = n end

  local f
  if crossed then
    f = (dir > 0) and 1 or 5
  else
    f = 1 + floor(4 * (n - nlo) / span + 0.5)
    if f < 1 then f = 1 elseif f > 5 then f = 5 end
    if f == pf and n ~= ppn then
      local alt = (n > ppn) and f + 1 or f - 1
      if alt >= 1 and alt <= 5 then f = alt end
    end
    if f == 1 and BK[n % 12] and (pf ~= 2 or n == ppn) then f = 2 end
  end

  local need = shift > 0 and (0.028 * shift + 0.035) or 0
  if crossed then need = need * 0.45 end
  local strain = 0
  if need > 0 then
    local av = gapsec or 0.25
    if need > av then strain = clamp((need - av) / need, 0, 1) end
  end
  local rr = n - ppn
  if rr < 0 then rr = -rr end
  if rr > 12 and shift == 0 then strain = clamp(strain + (rr - 12) * 0.1, 0, 1) end

  return f, shift, strain, nlo
end

function P:touch(f, strain, shifted)
  local h = self.g.p.hum or 0.3
  local v = (FSTR[f] or 0) * (0.45 + 0.85 * h)
  if shifted then v = v + 1.6 end
  return v - strain * 5
end

function P:lift(f, strain, shifted, pf)
  if f == (pf or self.pf) then return 0.22 end
  if shifted then return 0.1 + strain * 0.3 end
  return 0
end

function P:rehand(n)
  self.hlo = floor(n - self.span * 0.5)
  self.pf, self.pn = 3, n
  self.anchor, self.lastanch = n, n
end

function P:newphrase(centre)
  local g = self.g
  local reach = 5 + 9 * (g.song or 0.5) + 4 * ((g.p and g.p.motion) or 0.5)
  self.climax = floor(centre + reach * (0.6 + 0.5 * random()))
  if self.climax > g.hi - 1 then self.climax = g.hi - 1 end
  self.climaxed = false
  self.hiw = centre + 3
  self.low = centre - 5
end

function P:planbar(ctx)
  local g = self.g
  local want = ctx.target
  local bp, ap = ctx.bps or 4, ctx.apxpos or 2
  if bp > 1 and ctx.pos then
    local d = abs(ctx.pos - ap)
    local near = 1 - min(1, d / max(1, bp * 0.6))
    want = want + (self.climax - want) * near * 0.62
  end
  if ctx.apex and not self.climaxed then
    want = self.climax
    self.climaxed = true
  end
  if ctx.cad and ctx.close > 0 then
    local r = g.root
    local t = self.lastanch - (self.lastanch - r) % 12
    if self.lastanch - t > 6 then t = t + 12 end
    want = t
  end

  local fw = floor(want)
  local best, bs = nearct(g, fw), -1e9
  local c = dc(fw + 1)
  local la = self.lastanch
  for _ = 1, 4 do
    if c >= g.split and c <= g.hi then
      local s = -abs(c - want) * 0.5 - abs(c - la) * 0.25
      if abs(c - la) <= 4 then s = s + 1.2 end
      if c == la then s = s - 1.6 end
      if s > bs then bs = s; best = c end
    end
    c = uc(c)
  end
  self.anchor = best
  return best
end

local C, SEEN, ST, LO, HI, PN = nil, {}, 0, 0, 0, 0

local function add(k, x)
  if x < LO or x > HI then return k end
  local d = x - PN
  if d > 16 or d < -16 then return k end
  if SEEN[x] == ST then return k end
  SEEN[x] = ST
  k = k + 1
  C[k] = x
  return k
end

local function nearpc(k, pc)
  local b = PN - (PN - pc) % 12
  k = add(k, b)
  return add(k, b + 12)
end

function P:cands(pn, tgt, ctx)
  local g = self.g
  C, LO, HI, PN = self.cand, g.split, g.hi, pn
  ST = ST + 1
  if ST > 1e9 then ST = 1; for x in pairs(SEEN) do SEEN[x] = nil end end
  local k = 0
  local u0, d0 = us(pn), ds(pn)
  k = add(k, u0)
  k = add(k, d0)
  k = add(k, us(u0))
  k = add(k, ds(d0))
  k = add(k, pn)

  local u1, d1 = uc(pn), dc(pn)
  k = add(k, u1)
  k = add(k, d1)
  local u2, d2 = uc(u1), dc(d1)
  k = add(k, u2)
  k = add(k, d2)
  k = add(k, uc(u2))
  k = add(k, dc(d2))

  if tgt then
    k = add(k, tgt)
    k = add(k, tgt > pn and ds(tgt) or us(tgt))
  end

  if self.stray > 0.02 then
    if isct(g, pn + 1) then k = add(k, pn + 1) end
    if isct(g, pn - 1) then k = add(k, pn - 1) end
    k = add(k, u1 - 1)
  end

  local ap = self.altpc
  if ap > 0 then k = nearpc(k, (ap - 1 + g.root) % 12) end

  if ctx.cad then
    k = nearpc(k, g.root % 12)
    k = nearpc(k, (g.root + g.s[3]) % 12)
  end

  return k
end

function P:step(n, pn, li, li2, ms, tgt, dist)
  local g = self.g
  local iv = n - pn
  local a = iv < 0 and -iv or iv
  local s = 0
  local cpc = g.cpc
  local ix = (n - g.root) % 12 + 1
  local ct = cpc[ix]

  if ct then
    s = s + (0.85 + 1.5 * ms) * self.lockw
  elseif g.insc[ix] then
    local stepin = a >= 1 and a <= 2
    local samedir = li ~= 0 and (iv > 0) == (li > 0)
    if stepin and samedir then s = s + 0.8 - 0.95 * ms
    elseif stepin and li ~= 0 then s = s + 0.62 - 0.85 * ms
    elseif a >= 3 and ms >= 0.5 then s = s + (0.2 + 0.9 * self.tens) - 0.5 * ms
    else s = s - 0.55 - 1.2 * ms end
  else
    local ap = self.altpc
    if ap > 0 and ix == ap then s = s + 0.7 + 0.5 * ms
    elseif a <= 3 and ((cpc[ix % 12 + 1] and li <= 0) or (cpc[(ix - 2) % 12 + 1] and li >= 0)) then
      s = s + self.stray * 1.7 - 0.7 - 0.9 * ms
    else s = s - 3.2 end
  end

  if g.lhx[ix] then s = s - (0.55 + 2.4 * ms) * self.clw end

  local song = self.song
  if a == 0 then
    s = s - 0.5 - 0.7 * song
    if li == 0 then s = s - 1.4 end
  elseif a <= 2 then
    s = s + 0.55 + 0.75 * song
  elseif a <= 4 then
    s = s + 0.25
  elseif a <= 7 then
    s = s - 0.15
    if li ~= 0 and (iv > 0) ~= (li > 0) then s = s + 0.5 end
    if not ct then s = s - 0.9 end
  else
    s = s - 0.7 - (a - 7) * 0.14
    if not ct then s = s - 1.4 end
    if ms < 0.4 then s = s - 0.6 end
    if li ~= 0 and (iv > 0) ~= (li > 0) then s = s + 0.55 end
  end

  local al = li < 0 and -li or li
  if al >= 5 then
    if (iv > 0) ~= (li > 0) and a <= 2 then s = s + 1.2
    elseif (iv > 0) == (li > 0) and a >= 3 then s = s - 1.1 end
  end
  if al >= 4 and a >= 4 and (iv > 0) == (li > 0) and abs(li + iv) > 12 then
    s = s - 1.3
  end

  if tgt and dist and dist > 0 then
    local before = abs(pn - tgt)
    local after = abs(n - tgt)
    s = s + clamp((before - after) - before / dist, -2, 2) * 0.32
  end

  if n > self.hiw then s = s - (n - self.hiw) * 0.1 end
  if n < self.low then s = s - (self.low - n) * 0.07 end
  if n > self.climax then s = s - (n - self.climax) * 0.3 end

  if li2 ~= 0 and iv == li2 and li == li2 then s = s - 0.6 end

  return s
end

function P:barscore(path, np, ctx, tgt)
  if np < 2 then return 0 end
  local s = 0
  local turns, same = 0, 0
  local hi, lo = path[1], path[1]
  local last, prev = 0, 0
  for i = 2, np do
    local x = path[i]
    local d = x - path[i - 1]
    if d ~= 0 and last ~= 0 and (d > 0) ~= (last > 0) then turns = turns + 1 end
    if d ~= 0 then last = d end
    if d == prev and d ~= 0 then same = same + 1 end
    prev = d
    if x > hi then hi = x end
    if x < lo then lo = x end
  end

  s = s - abs(turns - (1 + np * 0.2)) * 0.36

  local rng = hi - lo
  if rng < 3 then s = s - (3 - rng) * 0.7 end
  if rng > 17 then s = s - (rng - 17) * 0.3 end

  s = s - same * 0.22

  local peaks = 0
  for i = 1, np do if path[i] == hi then peaks = peaks + 1 end end
  if peaks > 2 then s = s - (peaks - 2) * 0.4 end

  if tgt then s = s - abs(path[np] - tgt) * 0.12 end

  if ctx.cad and ctx.close > 0.5 then
    local d = path[np] - path[np - 1]
    if d < 0 and d >= -2 then s = s + 1.1
    elseif abs(d) <= 2 then s = s + 0.5 end
  end

  return s
end

function P:runbar(sl, ctx)
  local g = self.g
  local ns = sl.n
  if ns <= 0 then return 0 end
  if ns > MAXS then ns = MAXS end
  if self.pn < g.split - 4 or self.pn > g.hi + 4 then
    self:rehand(clamp(floor(ctx.target or self.pn), g.split, g.hi))
  end
  local scx = sl.split and sl.cx or nil
  if scx then g:usectx(1) end
  self:prime()

  local tgt = self:planbar(ctx)
  local tg1, tg2, curk = tgt, nil, 1
  if scx then
    g:usectx(2); self:memo(2)
    tg2 = nearct(g, tgt)
    g:usectx(1); self:memo(1)
  end
  local A, B = self.A, self.B
  local pv, pw, pc = self.pv, self.pw, self.pc
  local pf2, psh, pst, pnl = self.pf2, self.psh, self.pst, self.pnl
  local bw, bn, bf, bs, bh = self.bw, self.bn, self.bf, self.bs, self.bh
  local cand = self.cand
  local anch = sl.anch
  local sms, sgap, swant, sww = sl.ms, sl.gap, sl.want, sl.ww

  A.pn[1], A.li[1], A.li2[1] = self.pn, self.li, self.li2
  A.hlo[1], A.pf[1], A.sc[1] = self.hlo, self.pf, 0
  local nb = 1

  local strk = 1.6 + 2.4 * (1 - self.tens)
  local done = ns

  for i = 1, ns do
    if scx and scx[i] ~= curk then
      curk = scx[i]
      g:usectx(curk); self:memo(curk)
      tgt = curk == 2 and tg2 or tg1
    end
    local ms = sms[i] or 0.5
    local gap = sgap[i] or 0.2
    local want = swant[i]
    local ww = sww[i] or 0
    local isa = anch and anch[i]
    local dist = ns - i + 1
    local slotgt = (isa or i == ns) and tgt or nil
    local abon = 1.3 + 1.2 * ms

    local np = 0
    local Apn, Ali, Ali2, Ahlo, Apf, Asc = A.pn, A.li, A.li2, A.hlo, A.pf, A.sc
    for w = 1, nb do
      local apn, ahlo, apf, ali, ali2, asc = Apn[w], Ahlo[w], Apf[w], Ali[w], Ali2[w], Asc[w]
      local k = self:cands(apn, tgt, ctx)
      for ci = 1, k do
        local n = cand[ci]
        local rf, rsh, strain, rnl = self:reach(ahlo, apf, apn, n, gap)
        local s = asc + self:step(n, apn, ali, ali2, ms, slotgt, dist) - strain * strk
        if want then
          local wd = n - want
          if wd < 0 then wd = -wd end
          s = s + (wd == 0 and ww or (ww * (1 - min(1, wd / 5)) - 0.1 * wd))
        end
        if isa and n == tgt then s = s + abon end
        np = np + 1
        pv[np] = s; pw[np] = w; pc[np] = n
        pf2[np] = rf; psh[np] = rsh; pst[np] = strain; pnl[np] = rnl
      end
    end
    if np == 0 then done = i - 1; break end

    local keep = min(W, np)
    local Bw, Bn, Bf, Bs, Bh = bw[i], bn[i], bf[i], bs[i], bh[i]
    local Bpn, Bli, Bli2, Bhlo, Bpf, Bsc = B.pn, B.li, B.li2, B.hlo, B.pf, B.sc
    for slot = 1, keep do
      local bv, bidx = -1e9, 0
      for j = 1, np do
        if pv[j] > bv then bv = pv[j]; bidx = j end
      end
      if bidx == 0 then keep = slot - 1; break end
      local w, n = pw[bidx], pc[bidx]
      pv[bidx] = -1e9
      Bpn[slot] = n
      Bli[slot] = n - Apn[w]
      Bli2[slot] = Ali[w]
      Bhlo[slot] = pnl[bidx]
      Bpf[slot] = pf2[bidx]
      Bsc[slot] = bv
      Bw[slot] = w; Bn[slot] = n; Bf[slot] = pf2[bidx]; Bs[slot] = pst[bidx]; Bh[slot] = psh[bidx] > 0
    end
    if keep <= 0 then done = i - 1; break end
    A, B = B, A
    nb = keep
  end

  self.A, self.B = A, B
  if scx then g:usectx(1) end
  ns = done
  if nb <= 0 or ns <= 0 then return 0 end

  local path = self.path
  local bv = -1e9
  local sc = A.sc
  for w = 1, nb do
    local x = w
    for i = ns, 1, -1 do path[i] = bn[i][x]; x = bw[i][x] end
    sc[w] = sc[w] / ns + self:barscore(path, ns, ctx, tgt)
    if sc[w] > bv then bv = sc[w] end
  end
  local temp = 0.2 + 0.5 * (g.tvar or 0.5) + 0.3 * (g.cx or 0.3)
  local tot = 0
  for w = 1, nb do
    sc[w] = exp((sc[w] - bv) / temp)
    tot = tot + sc[w]
  end
  local r = random() * tot
  local best = 1
  for w = 1, nb do
    r = r - sc[w]
    if r <= 0 then best = w; break end
  end

  local outn, outf, outs, outsh = self.outn, self.outf, self.outs, self.outsh
  local x = best
  for i = ns, 1, -1 do
    outn[i] = bn[i][x]; outf[i] = bf[i][x]; outs[i] = bs[i][x]; outsh[i] = bh[i][x]
    x = bw[i][x]
  end

  self.pn = outn[ns]
  if ns >= 2 then self.li = outn[ns] - outn[ns - 1] end
  if ns >= 3 then self.li2 = outn[ns - 1] - outn[ns - 2] end
  self.hlo, self.pf = A.hlo[best], A.pf[best]
  self.lastanch = tgt
  local hiw, low = self.hiw, self.low
  for i = 1, ns do
    local y = outn[i]
    if y > hiw then hiw = y end
    if y < low then low = y end
  end
  self.hiw = hiw - 0.35
  self.low = low + 0.35

  return ns
end

return P
