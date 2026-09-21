
local P = {}
P.__index = P

local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local random, exp = math.random, math.exp

local BK = {[1] = true, [3] = true, [6] = true, [8] = true, [10] = true}
local FSTR = {2.0, 0.0, 1.2, -4.0, -1.2}

local W = 5
local MAXS = 34

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

local function mkbeams()
  local b = {pn = {}, li = {}, li2 = {}, hlo = {}, pf = {}, sc = {},
             path = {}, fing = {}, strn = {}, shft = {}}
  for w = 1, W do
    b.path[w], b.fing[w], b.strn[w], b.shft[w] = {}, {}, {}, {}
  end
  return b
end

function P.new(g)
  local o = setmetatable({}, P)
  o.g = g
  o.hlo, o.span, o.pf, o.pn = 60, 11, 3, 60
  o.li, o.li2 = 0, 0
  o.anchor, o.lastanch = 60, 60
  o.hiw, o.low = 76, 52
  o.climax, o.climaxed = 80, false
  o.A, o.B = mkbeams(), mkbeams()
  o.cand = {}
  o.pv, o.pw, o.pc = {}, {}, {}
  o.pf2, o.psh, o.pst, o.pnl = {}, {}, {}, {}
  o.outn, o.outf, o.outs, o.outsh = {}, {}, {}, {}
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

local function isct(g, n) return g.cpc[(n - g.root) % 12 + 1] end
local function insc(g, n) return g.insc[(n - g.root) % 12 + 1] end

local function nearct(g, x)
  if isct(g, x) then return x end
  local u, d = upct(g, x), dnct(g, x)
  return (u - x <= x - d) and u or d
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
  local rr = abs(n - ppn)
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

  local best, bs = nearct(g, floor(want)), -1e9
  local c = dnct(g, floor(want) + 1)
  for _ = 1, 4 do
    if c >= g.split and c <= g.hi then
      local s = -abs(c - want) * 0.5 - abs(c - self.lastanch) * 0.25
      if abs(c - self.lastanch) <= 4 then s = s + 1.2 end
      if c == self.lastanch then s = s - 1.6 end
      if s > bs then bs = s; best = c end
    end
    c = upct(g, c)
  end
  self.anchor = best
  return best
end

local function add(c, k, x, lo, hi, pn)
  if x < lo or x > hi then return k end
  local d = x - pn
  if d > 16 or d < -16 then return k end
  for i = 1, k do if c[i] == x then return k end end
  k = k + 1; c[k] = x
  return k
end

local function nearpc(c, k, pn, pc, lo, hi)
  local b = pn - (pn - pc) % 12
  k = add(c, k, b, lo, hi, pn)
  return add(c, k, b + 12, lo, hi, pn)
end

function P:cands(pn, tgt, ctx)
  local g = self.g
  local c, k = self.cand, 0
  local lo, hi = g.split, g.hi

  k = add(c, k, upstep(g, pn), lo, hi, pn)
  k = add(c, k, dnstep(g, pn), lo, hi, pn)
  k = add(c, k, upstep(g, upstep(g, pn)), lo, hi, pn)
  k = add(c, k, dnstep(g, dnstep(g, pn)), lo, hi, pn)
  k = add(c, k, pn, lo, hi, pn)

  local u1, d1 = upct(g, pn), dnct(g, pn)
  k = add(c, k, u1, lo, hi, pn)
  k = add(c, k, d1, lo, hi, pn)
  local u2, d2 = upct(g, u1), dnct(g, d1)
  k = add(c, k, u2, lo, hi, pn)
  k = add(c, k, d2, lo, hi, pn)
  k = add(c, k, upct(g, u2), lo, hi, pn)
  k = add(c, k, dnct(g, d2), lo, hi, pn)

  if tgt then
    k = add(c, k, tgt, lo, hi, pn)
    k = add(c, k, tgt > pn and dnstep(g, tgt) or upstep(g, tgt), lo, hi, pn)
  end

  if (g.stray or 0) > 0.02 then
    if isct(g, pn + 1) then k = add(c, k, pn + 1, lo, hi, pn) end
    if isct(g, pn - 1) then k = add(c, k, pn - 1, lo, hi, pn) end
    k = add(c, k, u1 - 1, lo, hi, pn)
  end

  local ap = g.altpc or 0
  if ap > 0 then k = nearpc(c, k, pn, (ap - 1 + g.root) % 12, lo, hi) end

  if ctx.cad then
    k = nearpc(c, k, pn, g.root % 12, lo, hi)
    k = nearpc(c, k, pn, (g.root + g.s[3]) % 12, lo, hi)
  end

  return k
end

function P:step(n, pn, li, li2, ms, ctx, tgt, dist)
  local g = self.g
  local iv = n - pn
  local a = abs(iv)
  local s = 0
  local ct = isct(g, n)

  local lockw = 0.5 + 0.5 * (g.lock or 1) / 2.6
  if ct then
    s = s + (0.85 + 1.5 * ms) * lockw
  elseif insc(g, n) then
    local stepin = a >= 1 and a <= 2
    local samedir = li ~= 0 and (iv > 0) == (li > 0)
    if stepin and samedir then s = s + 0.8 - 0.95 * ms
    elseif stepin and li ~= 0 then s = s + 0.62 - 0.85 * ms
    elseif a >= 3 and ms >= 0.5 then s = s + (0.2 + 0.9 * (g.p.tens or 0.35)) - 0.5 * ms
    else s = s - 0.55 - 1.2 * ms end
  else
    local ap = (g.altpc or 0) > 0 and ((n - g.root) % 12 + 1) == g.altpc
    if ap then s = s + 0.7 + 0.5 * ms
    elseif a <= 3 and ((isct(g, n + 1) and li <= 0) or (isct(g, n - 1) and li >= 0)) then
      s = s + (g.stray or 0) * 1.7 - 0.7 - 0.9 * ms
    else s = s - 3.2 end
  end

  local song = g.song or 0.5
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

  if abs(li) >= 5 then
    if (iv > 0) ~= (li > 0) and a <= 2 then s = s + 1.2
    elseif (iv > 0) == (li > 0) and a >= 3 then s = s - 1.1 end
  end
  if abs(li) >= 4 and a >= 4 and (iv > 0) == (li > 0) and abs(li + iv) > 12 then
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
    local d = path[i] - path[i - 1]
    if d ~= 0 and last ~= 0 and (d > 0) ~= (last > 0) then turns = turns + 1 end
    if d ~= 0 then last = d end
    if d == prev and d ~= 0 then same = same + 1 end
    prev = d
    if path[i] > hi then hi = path[i] end
    if path[i] < lo then lo = path[i] end
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

  local tgt = self:planbar(ctx)
  local A, B = self.A, self.B
  local pv, pw, pc = self.pv, self.pw, self.pc
  local pf2, psh, pst, pnl = self.pf2, self.psh, self.pst, self.pnl
  local anch = sl.anch

  A.pn[1], A.li[1], A.li2[1] = self.pn, self.li, self.li2
  A.hlo[1], A.pf[1], A.sc[1] = self.hlo, self.pf, 0
  local nb = 1

  local strk = 1.6 + 2.4 * (1 - (g.p.tens or 0.35))

  for i = 1, ns do
    local ms = sl.ms[i] or 0.5
    local gap = sl.gap[i] or 0.2
    local want = sl.want[i]
    local ww = sl.ww[i] or 0
    local isa = anch and anch[i]
    local dist = ns - i + 1
    local slotgt = (isa or i == ns) and tgt or nil

    local np = 0
    for w = 1, nb do
      local k = self:cands(A.pn[w], tgt, ctx)
      for ci = 1, k do
        local n = self.cand[ci]
        local rf, rsh, strain, rnl = self:reach(A.hlo[w], A.pf[w], A.pn[w], n, gap)
        local s = A.sc[w] + self:step(n, A.pn[w], A.li[w], A.li2[w], ms, ctx, slotgt, dist)
          - strain * strk
        if want then
          local wd = abs(n - want)
          s = s + (wd == 0 and ww or (ww * (1 - min(1, wd / 5)) - 0.1 * wd))
        end
        if isa and n == tgt then s = s + 1.3 + 1.2 * ms end
        np = np + 1
        pv[np] = s; pw[np] = w; pc[np] = n
        pf2[np] = rf; psh[np] = rsh; pst[np] = strain; pnl[np] = rnl
      end
    end
    if np == 0 then break end

    local keep = min(W, np)
    for slot = 1, keep do
      local bv, bidx = -1e9, 0
      for j = 1, np do
        if pv[j] > bv then bv = pv[j]; bidx = j end
      end
      if bidx == 0 then keep = slot - 1; break end
      local w, n = pw[bidx], pc[bidx]
      pv[bidx] = -1e9
      local f, shift, strain, nlo = pf2[bidx], psh[bidx], pst[bidx], pnl[bidx]
      B.pn[slot] = n
      B.li[slot] = n - A.pn[w]
      B.li2[slot] = A.li[w]
      B.hlo[slot] = nlo
      B.pf[slot] = f
      B.sc[slot] = bv
      local sp, dp = A.path[w], B.path[slot]
      local sf, df = A.fing[w], B.fing[slot]
      local ss, ds = A.strn[w], B.strn[slot]
      local sh, dh = A.shft[w], B.shft[slot]
      for q = 1, i - 1 do dp[q] = sp[q]; df[q] = sf[q]; ds[q] = ss[q]; dh[q] = sh[q] end
      dp[i] = n; df[i] = f; ds[i] = strain; dh[i] = shift > 0
    end
    if keep <= 0 then break end
    A, B = B, A
    nb = keep
  end

  self.A, self.B = A, B
  if nb <= 0 then return 0 end

  local bv = -1e9
  for w = 1, nb do
    A.sc[w] = A.sc[w] / ns + self:barscore(A.path[w], ns, ctx, tgt)
    if A.sc[w] > bv then bv = A.sc[w] end
  end
  local temp = 0.2 + 0.5 * (g.tvar or 0.5) + 0.3 * (g.cx or 0.3)
  local tot = 0
  for w = 1, nb do
    A.sc[w] = exp((A.sc[w] - bv) / temp)
    tot = tot + A.sc[w]
  end
  local r = random() * tot
  local best = 1
  for w = 1, nb do
    r = r - A.sc[w]
    if r <= 0 then best = w; break end
  end

  local outn, outf, outs, outsh = self.outn, self.outf, self.outs, self.outsh
  local bp, bf, bs2, bh = A.path[best], A.fing[best], A.strn[best], A.shft[best]
  for i = 1, ns do
    outn[i] = bp[i]; outf[i] = bf[i]; outs[i] = bs2[i]; outsh[i] = bh[i]
  end

  self.pn = bp[ns]
  if ns >= 2 then self.li = bp[ns] - bp[ns - 1] end
  if ns >= 3 then self.li2 = bp[ns - 1] - bp[ns - 2] end
  self.hlo, self.pf = A.hlo[best], A.pf[best]
  self.lastanch = tgt
  for i = 1, ns do
    if bp[i] > self.hiw then self.hiw = bp[i] end
    if bp[i] < self.low then self.low = bp[i] end
  end
  self.hiw = self.hiw - 0.35
  self.low = self.low + 0.35

  return ns
end

return P
