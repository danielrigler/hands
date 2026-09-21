local T = include('lib/theory')
local PL = include('lib/play')

local floor, random, exp, abs = math.floor, math.random, math.exp, math.abs
local min, max = math.min, math.max

local G = {}
G.__index = G

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

local function newev(t, d, v, hand)
  return {t = t, d = d, d0 = d, v = v, v0 = v, h = hand, n = {}, r = 1, o = 0}
end

local FORMS = {
  {1,1,2,1}, {1,2,1,3}, {1,1,2,2}, {1,1,1,2}, {1,2,1,2},
  {1,3,2,3}, {1,1,3,2}, {2,1,2,3}, {1,2,3,1},
}
local HFORMS = {
  {1,1,2,1}, {1,1,1,2}, {1,2,1,2}, {1,1,2,2}, {1,1,2,1}, {1,2,1,1},
}

function G.new(p)
  local o = setmetatable({}, G)
  o.p = p
  o.s = {0,2,4,5,7,9,11}
  o.s0 = {0,2,4,5,7,9,11}
  o.pv, o.pf, o.pdir, o.palt = 0, 0, 0, false
  o.barn, o.lastsil = 0, false
  o.tgv, o.oct, o.jump, o.mt, o.melsil, o.resting = 1, 0, false, 5, false, false
  o.octs, o.octc, o.octsc = {0, 0, 0}, 0, 1
  o.replift, o.arcamp = 0, 0
  o.pcw, o.cw, o.chw, o.cpc, o.pcdeg = {}, {}, {}, {}, {}
  o.hpc, o.hk, o.insc = {}, {}, {}
  o.pw, o.rw, o.wb, o.wb0 = {}, {}, {}, {}
  o.pwl = {}
  o.mask, o.sc, o.dur, o.M = {}, {}, {}, {}
  o.ct, o.prev, o.sflat, o.flat = {}, {}, {}, {}
  o.rhm, o.secpat = {}, {1,1,1}
  o.art, o.artbase = 1, 0.9
  o.ev = {}
  for i = 1, 16 do o.ev[i] = {} end
  o.tr = {tp = 0, inv = false, ret = false, aug = 1, disp = 0, frag = false}
  o.motif, o.prog, o.form = {}, {}, {1,1,2,1}
  o.bl, o.nb = 16, 4
  T.metric(16, o.M)
  o.root, o.bcont, o.cdeg, o.infl = 0, 0, 0, 0
  o.shape = T.SHAPES[1].o
  o.bar, o.tick = 0, 0
  o.pn, o.pdeg, o.li, o.div = 64, 1, 0, 0
  o.qual = ""
  o.pc, o.pd = T.pink(6), T.pink(5)
  o.db, o.dd, o.dc = 0, 0, 0
  o.tb, o.td, o.tc = 0, 0, 0
  o.lastb, o.lastdeg, o.lastsh = 0, -1, -1
  o.seqleft, o.seqtp, o.seqinc = 0, 0, 1
  o.atonic, o.conseq = false, false
  o.apxpos, o.bps, o.hr, o.nsec = 1, 4, 1, 4
  o.lhseed = 0
  o.lhallow, o.lhused, o.lhpi = {}, {}, 1
  o.lhord = {0, -1, 1}
  o.choff, o.newchord, o.pedb = 0, true, 1
  o.res, o.resdir = nil, -1
  o.stray, o.resforce = 0, false
  o.ssig, o.flatsig, o.sfsig = 0, -1, -1
  o.bo = 0
  o.progdirty = false
  o.vo, o.pvo = {}, {}
  o.calt, o.caltd, o.altpc, o.lastalt = 0, -1, 0, -1
  o.play = PL.new(o)
  o.rhtex, o.txp, o.sdyn = 1, 0.4, 0
  o.slots = {n = 0, tk = {}, ms = {}, gap = {}, want = {}, ww = {},
             anch = {}, tgt = {}, du = {}, k = {}, last = {}}
  o.pctx = {ms = 0.5, target = 60, cad = false, close = 0, apex = false,
            want = nil, wantw = 0, gapsec = 0.25}
  o.vn, o.mlow = 0, 127
  o.croot, o.binv, o.lhprev = 0, 1, nil
  o.struct, o.mlead, o.ovl = true, 0.1, 0.12
  o:derive()
  o:reroll(false)
  return o
end

function G:derive()
  local p = self.p
  local rh = p.rh
  local ik = ((p.intens or 0.5) - 0.5) * 2
  self.ik = ik
  self.ivel = ik * 26
  self.icent = ik * 2.5
  self.step = p.step or 0.5
  local sl = clamp(self.step * 2, 1, 5)
  self.sl = sl
  self.gs = self.step > 0.5 and 0.5 / self.step or 1
  self.gof = 1 - (0.4 / self.step < 0.8 and 0.4 / self.step or 0.8)
  local b = clamp(p.bright, -5, 2)
  self.bn = b >= 0 and b * 0.5 or b * 0.2
  local mt = 2 ^ ((p.motion or 0.5) * 4) * 1.5 * (1 - p.space * 0.78 / sl ^ 0.4) * sl ^ 0.35
  mt = mt * 2 ^ (ik * 0.7)
  self.mt = clamp(mt, 0.7, self.bl or 16)
  self.dens = clamp(self.mt / (self.bl or 16), 0.04, 0.99)
  self.restp = clamp((p.space - 0.55) * 0.4, 0, 0.08) * sl ^ -1.2 * clamp(1 - 0.6 * ik, 0.2, 1.8)
  self.cx = rh ^ 1.25
  self.song = (1 - rh) ^ 1.1
  self.orn = clamp(rh * 0.85 + (sl - 1) * 0.15, 0, 0.9)
  self.ratch = max(0, rh - 0.65) * 1.4
  self.app = (0.06 + self.song * 0.28) * (0.35 + 1.3 * (p.tens or 0.35))
  self.leapp = clamp(0.10 + 0.15 * self.song + 0.10 * self.cx, 0, 0.36)
  local rp = p.rep or 0.45
  self.rep = clamp(rp ^ 1.7 * 1.1 + (0.12 - 0.24 * rh), 0, 0.97)
  self.tvar = clamp(1.3 - rp * 1.5, 0.05, 1)
  self.freeb = clamp(0.85 - rp * 0.8, 0.05, 1)
  self.syn = p.syn or 0
  self.st = T.STYLE[p.style or 0]
  local sst = self.st
  self.shset, self.lhset = sst and sst.sh, sst and sst.lh
  self.legato = clamp(0.12 + (p.len or 0.55) * 0.86, 0.05, 0.99)
  self.artbase = clamp((0.45 + (p.len or 0.55) * 0.8) * (1 - 0.12 * ik), 0.4, 1.3)
  self.mlead = clamp(0.026 / self.step, 0.04, 0.34)
  self.ovl = 0.06 + 0.18 * self.legato
  local tn = p.tens or 0.35
  local cr = clamp(p.stray or 0, 0, 1)
  self.stray = cr
  self.chrom = cr * cr * 0.34
  self.lock = clamp(2.5 - tn * 2.3 - 0.5 * self.cx, 0.25, 2.6)
  self.pull = 0.28 + tn * 0.5
  local lv = clamp(floor(clamp(p.lh + ik * 0.17, 0, 0.999) * 3.999), 0, 3)
  self.lhlvl = lv
  self.lhthin = clamp((1.15 - p.lh * 1.28) * (1 - 0.5 * ik), 0, 0.92)
  self.lhon = p.lh > 0.02
  self:build_secpat()
  self.coct = -(4 + p.rngw * 0.16) - floor((1 - p.lh) * 8)
  self.pedb = clamp(((p.poly or 16) - 4) / 12, 0.2, 1)
  self.dtime = 200 - 150 * p.drift
  self.vrange = clamp(p.vel * 0.44 * (1 + 0.3 * ik), 10, 58)
  self.lo = clamp(floor(p.centre - p.rngw * 0.62), 12, 118)
  self.hi = clamp(floor(p.centre + p.rngw * 0.44), self.lo + 14, 127)
  self.split = clamp(floor(p.centre - 4 - p.rngw * 0.14), self.lo + 6, self.hi - 6)
  self.lhtop = clamp(floor(p.centre) - 5 - floor(p.rngw * 0.07), self.lo + 6, self.hi - 12)
end

local function hsh(a)
  local x = (a * 1103515245 + 12345) % 2147483648
  x = (x * 1103515245 + 12345) % 2147483648
  return x / 2147483648
end

function G:build_secpat()
  local L, P, sp = T.LADDER, T.LPOS, self.secpat
  local n = #L
  local allow, used = self.lhallow, self.lhused
  for i = 1, n do allow[i] = true; used[i] = false end
  local ls = self.lhset
  if ls then
    local na = 0
    for i = 1, n do allow[i] = false end
    for i = 1, #ls do
      local q = P[ls[i]]
      if q and not allow[q] then allow[q] = true; na = na + 1 end
    end
    if na < 3 then for i = 1, n do allow[i] = true end end
  end
  local lh = clamp(self.p.lh or 0.45, 0, 1)
  local c = 1 + lh * (n - 1)
  local spread = 1.3 + 3.0 * (1 - abs(lh * 2 - 1))
  local seed, ord = self.lhseed, self.lhord
  for slot = 1, 3 do
    local r = hsh(seed * 977 + slot * 71)
    local t = c + ord[slot] * (0.6 + spread * r)
    local bi, bd = 0, 1e9
    for i = 1, n do
      if allow[i] and not used[i] then
        local d = abs(i - t) + hsh(seed * 613 + slot * 149 + i * 17) * 1.1
        if d < bd then bd = d; bi = i end
      end
    end
    if bi == 0 then
      for i = 1, n do if allow[i] then bi = i; break end end
      if bi == 0 then bi = 1 end
    end
    used[bi] = true
    sp[slot] = L[bi]
  end
  self.lhpat = T.LH[sp[1]]
  self.lhpi = P[sp[1]] or 1
end

function G:arcof(i)
  local a = self.arcamp * (i - 1) / max(1, self.nsec - 1)
  if i == self.nsec then a = a - self.arcamp * 0.95 end
  return floor(a / 4 + 0.5) * 4
end

function G:plan_registers()
  local lo, hi, sm, n = 1e9, -1e9, 0, 0
  for c = 0, 1 do
    for i = 1, self.nsec do
      local v = (self.octs[self.form[i]] or 0) + self:arcof(i) + (c == 1 and self.replift or 0)
      if v < lo then lo = v end
      if v > hi then hi = v end
      sm = sm + v; n = n + 1
    end
  end
  self.octc = sm / n
  local sp = hi - lo
  local al = clamp((self.p.rngw or 48) * 0.33, 6, 26)
  self.octsc = sp > al and al / sp or 1
end

function G:bnorm()
  return clamp(self.p.bright + self.bo + self.db, -5, 3)
end

function G:drift(dt)
  local d = self.p.drift
  if d <= 0.005 then
    self.db, self.dd, self.dc = 0, 0, 0
    return
  end
  local tau = self.dtime
  if random() < dt / tau then
    self.tb = T.pnext(self.pc) * 2.8
    self.td = T.pnext(self.pd) * 0.35
    self.tc = T.pnext(self.pc) * 10
  end
  local a = 1 - exp(-dt / (tau * 0.3))
  self.db = self.db + (self.tb * d - self.db) * a
  self.dd = self.dd + (self.td * d - self.dd) * a
  self.dc = self.dc + (self.tc * d - self.dc) * a
end

function G:build_hook()
  local s, hp, k = self.s, self.hpc, self.hk
  local sig = s[1]
  for i = 2, 7 do sig = sig * 25 + s[i] end
  local bi, bj
  if sig == self.hs1 then bi, bj = self.hi1, self.hj1
  elseif sig == self.hs2 then bi, bj = self.hi2, self.hj2
  else
    local bs = -1
    bi, bj = 4, 7
    for a = 2, 7 do
      for b = a + 1, 7 do
        local n = 0
        for i = 1, 7 do
          if i ~= a and i ~= b then n = n + 1; k[n] = s[i] % 12 end
        end
        local mn = 12
        for i = 1, n do
          local d = (i < n) and (k[i+1] - k[i]) or (k[1] + 12 - k[n])
          if d < mn then mn = d end
        end
        local sc = mn * 100
        if a ~= 5 and b ~= 5 then sc = sc + 30 end
        if a ~= 3 and b ~= 3 then sc = sc + 20 end
        if a ~= 2 and b ~= 2 then sc = sc + 5 end
        if sc > bs then bs = sc; bi = a; bj = b end
      end
    end
    self.hs2, self.hi2, self.hj2 = self.hs1, self.hi1, self.hj1
    self.hs1, self.hi1, self.hj1 = sig, bi, bj
  end
  for i = 1, 12 do hp[i] = false end
  for i = 1, 7 do
    if i ~= bi and i ~= bj then hp[s[i] % 12 + 1] = true end
  end
end

function G:update_scale()
  self.bcont = self:bnorm()
  local opv = self.pv
  local pv, f, dir = T.scale_for(self.bcont, self.s0)
  self.pv, self.pf, self.pdir = pv, f, dir
  local keep = (pv > 0 and pv == opv and self.palt) or false
  self:apply_scale(keep)
end

function G:pivot_roll()
  if self.pv == 0 then
    if self.palt then self:apply_scale(false) end
    return
  end
  local f = self.pf
  local th = self.palt and (f - 0.18) or (f - 0.58)
  local a = random() < th
  if a ~= self.palt then self:apply_scale(a) end
end

function G:apply_scale(alt)
  self.palt = alt
  self.ssig = self.ssig + 1
  local s, s0, w = self.s, self.s0, self.pcw
  for i = 1, 7 do s[i] = s0[i] end
  if alt then s[self.pv] = s[self.pv] + self.pdir end
  local inf = self.infl
  if inf == 1 and s[7] < 11 then s[7] = s[7] + 1 end
  local cr = self.stray or 0
  local ch = 0.003 + (0.02 * self.cx + 0.11) * cr * cr
  for i = 1, 12 do w[i] = ch * 0.22 end
  for i = 1, 7 do
    local a = (s[i] - 1) % 12 + 1
    if w[a] < ch then w[a] = ch end
  end
  for i = 1, 7 do
    local d = T.DEG_W[i]
    local a = s[i] % 12 + 1
    if w[a] < d then w[a] = d end
  end
  self:build_hook()
  local sg = self.song
  if sg > 0.02 then
    local hp = self.hpc
    local ff = 1 - 0.40 * sg
    for i = 1, 12 do if not hp[i] then w[i] = w[i] * ff end end
  end
  local iw = 0.18 + 0.82 * cr
  if inf == 2 then
    local b5 = (s[5] - 1) % 12 + 1
    if w[b5] < 0.34 * iw then w[b5] = 0.34 * iw end
    local b3 = (s[3] - 1) % 12 + 1
    if w[b3] < 0.30 * iw then w[b3] = 0.30 * iw end
  elseif inf == 3 then
    local x = (s[4] + 1) % 12 + 1
    if w[x] < 0.42 * iw then w[x] = 0.42 * iw end
  elseif inf == 4 then
    local x = s[6] % 12 + 1
    w[x] = max(w[x], 0.75)
  end
  local pd, ins = self.pcdeg, self.insc
  for i = 1, 12 do pd[i] = 1; ins[i] = false end
  for i = 1, 7 do ins[s[i] % 12 + 1] = true end
  for i = 1, 7 do
    local a = s[i] % 12 + 1
    pd[a] = i
    pd[(s[i] + 1) % 12 + 1] = i
  end
  for i = 1, 7 do pd[s[i] % 12 + 1] = i end
end

function G:update_lut()
  local cx = self.cx
  local vp = 3.2 + 24 * cx * cx
  local vr = (15 + 34 * cx) * (1 + 0.32 * self.bn) * (0.5 + (self.p.rngw or 48) / 64)
  local pw, rw, pwl = self.pw, self.rw, self.pwl
  local vl = 30 + 46 * cx
  for d = -24, 24 do
    local q = d * d
    pw[d+25] = exp(-q / (2 * vp))
    rw[d+25] = exp(-q / (2 * vr))
    local a = d < 0 and -d or d
    pwl[d+25] = exp(-q / (2 * vl)) * (a < 3 and 0.02 or (a < 5 and 0.55 or 1))
  end
  pw[25] = 0.20
end

function G:dn(d)
  return self.root + 12 * (d // 7) + self.s[d % 7 + 1]
end

function G:sdeg(d)
  local x = self.s[d % 7 + 1]
  if self.calt == 1 and (d % 7) == self.caltd then x = x + 1 end
  return x
end

function G:dna(d)
  return self.root + 12 * (d // 7) + self:sdeg(d)
end

function G:build_chord(deg, shi)
  local shape = T.SHAPES[shi].o
  self.cdeg = deg
  self.shape = shape
  local w, cp, ct = self.chw, self.cpc, self.ct
  local s = self.s
  local nsw = 0.02 + 0.20 * (self.stray or 0)
  for i = 1, 12 do w[i] = nsw; cp[i] = false end
  for i = 1, 7 do w[s[i] % 12 + 1] = 0.34 end
  local n = #shape
  local r0 = self:dna(deg)
  for i = 1, n do
    local d = deg + shape[i]
    local pc = self:sdeg(d) % 12 + 1
    local r = i == 1 and 1.00 or (i == 2 and 0.94 or (i == 3 and 0.82 or (i == 4 and 0.70 or 0.48)))
    if w[pc] < r then w[pc] = r end
    cp[pc] = true
    ct[i] = self:dna(d) - r0
  end
  for i = n + 1, #ct do ct[i] = nil end
  self.altpc = (self.calt == 1) and (self:sdeg(deg + 2) % 12 + 1) or 0
  local a = self:sdeg(deg)
  local b = self:sdeg(deg + 2)
  local c = self:sdeg(deg + 4)
  local t3, t5 = (b - a) % 12, (c - a) % 12
  local q = t3 == 3 and "m" or (t3 == 4 and "" or "s")
  if t5 == 6 then q = q .. "\u{b0}" elseif t5 == 8 then q = q .. "+" end
  if n >= 4 and shape[2] == 2 then q = q .. "7" end
  self.qual = T.ROMAN[deg % 7 + 1] .. q
  local tgt = self.p.centre + self.coct
  local top = clamp(floor(self.cbase) - 12, self.lhtop, floor(self.p.centre) + 4)
  local bi = (self.newchord or not ct[self.binv]) and self:pick_inv(r0, tgt, top) or self.binv
  if not ct[bi] then bi = 1 end
  local b = self:bassfold(r0 + ct[bi], tgt, top)
  self.lhbase = b
  self.croot = b - ct[bi]
  self.binv = bi
  if self.newchord then self.lhprev = b end
  self:voice_chord()
end

local INVOK = {[3] = true, [4] = true, [6] = true, [7] = true, [8] = true, [9] = true}

function G:bassfold(x, tgt, top)
  local b = x + 12 * floor((tgt - x) / 12 + 0.5)
  local prev = self.lhprev
  if prev then
    local a = b + ((prev > b) and 12 or -12)
    if a >= self.lo and a <= top and abs(a - tgt) <= 7
      and abs(a - prev) < abs(b - prev) then b = a end
  end
  while b < self.lo do b = b + 12 end
  while b > top do b = b - 12 end
  if self.cbase - b > 17 and b + 12 <= top then b = b + 12 end
  if b < self.lo then b = b + 12 end
  return b
end

function G:pick_inv(r0, tgt, top)
  local ct = self.ct
  local n = #ct
  if self.struct or n < 3 then return 1 end
  local prev = self.lhprev
  local nc = n < 4 and n or 4
  local bs, bi = -1e9, 1
  for i = 1, nc do
    local c = ct[i]
    if c and (i == 1 or INVOK[c % 12]) then
      local b = self:bassfold(r0 + c, tgt, top)
      local sc
      if i == 1 then sc = 1.9
      elseif i == 2 then sc = 1.6
      elseif i == 3 then sc = 1.25
      else sc = 0.4 end
      if prev then
        local d = prev - b
        if d < 0 then d = -d end
        if d == 0 then sc = sc + 0.15
        elseif d <= 2 then sc = sc + 1.9
        elseif d <= 4 then sc = sc + 0.8
        elseif d <= 7 then sc = sc + 0.2
        else sc = sc - 0.26 * (d - 7) end
      end
      sc = sc * (0.82 + random() * 0.36)
      if sc > bs then bs = sc; bi = i end
    end
  end
  return bi
end

local function minint(n)
  if n < 40 then return 12
  elseif n < 47 then return 7
  elseif n < 53 then return 5
  elseif n < 59 then return 4
  end
  return 2
end

local function stack(vo, pv, ct, n, base, bi, r0, top)
  local last, k = base, 1
  local rootin = false
  for i = 1, n do
    if i ~= bi then
      local x = r0 + ct[i]
      local ref = pv[i] or (base + 4 + max(0, i - 2) * 4)
      x = x + 12 * floor((ref - x) / 12 + 0.5)
      local gap = minint(last)
      while x < last + gap do x = x + 12 end
      while x > top and x - 12 >= last + gap do x = x - 12 end
      while x - last > 16 and x - 12 >= last + gap do x = x - 12 end
      if x <= top then
        k = k + 1
        vo[k] = x
        pv[i] = x
        last = x
        if i == 1 then rootin = true end
      end
    end
  end
  return rootin
end

function G:voice_chord()
  local ct, vo, pv = self.ct, self.vo, self.pvo
  local n = #ct
  local base = self.lhbase
  local mel = (self.mlow or 127) - 2
  if base + 7 > mel and base - 12 >= self.lo then base = base - 12 end
  for i = #vo, 1, -1 do vo[i] = nil end
  vo[1] = base
  if n < 2 then return end
  local top = self.split + 4
  local m = floor(self.cbase) - 2
  if m < top then top = m end
  if top < base + 7 then top = base + 7 end
  if mel < top then top = mel end
  local r0 = (self.croot or base) + (base - self.lhbase)
  local bi = self.binv or 1
  if stack(vo, pv, ct, n, base, bi, r0, top) or bi == 1 then return end
  local rr = r0 + 12 * floor((base - r0) / 12)
  if rr < self.lo then return end
  for i = #vo, 1, -1 do vo[i] = nil end
  base = rr
  vo[1] = base
  if top < base + 7 then top = base + 7 end
  stack(vo, pv, ct, n, base, 1, r0, top)
end

function G:lhnote(k)
  local vo = self.vo
  local n = #vo
  if n < 1 then return self.lhbase end
  local o = (k - 1) // n
  local i = (k - 1) % n + 1
  return vo[i] + 12 * o
end

function G:emit(pn, ms)
  self.li = pn - self.pn
  self.pn = pn
  local iv = (pn - self.root) % 12 + 1
  self.pdeg = self.pcdeg[iv]
  if not self.insc[iv] then
    self.res = pn
    self.resforce = true
    local up = self.insc[iv % 12 + 1]
    local dn = self.insc[(iv - 2) % 12 + 1]
    if up and not dn then self.resdir = 1
    elseif dn and not up then self.resdir = -1
    else self.resdir = (self.li >= 0) and 1 or -1 end
  elseif ms and ms >= 0.5 and not self.cpc[iv] then
    self.res = pn
    self.resforce = false
    self.resdir = (self.pdeg == 7) and 1 or -1
  else
    self.res = nil
    self.resforce = false
  end
end

function G:fold(n, lo, hi)
  lo = lo or self.split
  hi = hi or self.hi
  while n < lo do n = n + 12 end
  while n > hi do n = n - 12 end
  if n < lo then n = n + 12 end
  return n
end

function G:snaps(n)
  local ins, r = self.insc, self.root
  if ins[(n - r) % 12 + 1] then return n end
  if ins[(n - r - 1) % 12 + 1] then return n - 1 end
  return n + 1
end

function G:snapc(n)
  local cp, r = self.cpc, self.root
  if cp[(n - r) % 12 + 1] then return n end
  for k = 1, 3 do
    if cp[(n - r - k) % 12 + 1] then return n - k end
    if cp[(n - r + k) % 12 + 1] then return n + k end
  end
  return n
end

function G:near(n)
  local d = n - self.pn
  while d > 16 do n = n - 12; d = d - 12 end
  while d < -16 do n = n + 12; d = d + 12 end
  return n
end

function G:fit(mask, target)
  local sc, M, bl = self.sc, self.M, self.bl
  local sp = 0.35 + 4.2 * self.cx
  local sy = self.syn
  local hp = self.song * 1.6 * (1 - sy)
  local mw = 1 - 2.1 * sy
  local cnt = 0
  for i = 1, bl do
    sc[i] = M[i] * mw + random() * sp - (i % 2 == 0 and hp or 0)
    cnt = cnt + mask[i]
  end
  while cnt < target do
    local bi, bv = 0, -1
    for i = 1, bl do
      if mask[i] == 0 and sc[i] > bv then bv = sc[i]; bi = i end
    end
    if bi == 0 then break end
    mask[bi] = 1; sc[bi] = -1; cnt = cnt + 1
  end
  while cnt > target do
    local bi, bv = 0, 1e9
    for i = 1, bl do
      if mask[i] == 1 and sc[i] < bv then bv = sc[i]; bi = i end
    end
    if bi == 0 then break end
    mask[bi] = 0; sc[bi] = 1e9; cnt = cnt - 1
  end
end

function G:rhythm(out, dens, cad)
  local cx, M, bl = self.cx, self.M, self.bl
  local st = self.rstyle
  if st == 1 then
    local a = 0.95 - 0.6 * cx
    for i = 1, bl do
      local ms = (M[i] - 1) * 0.25
      out[i] = (random() < dens + a * (ms - 0.5)) and 1 or 0
    end
  elseif st == 2 then
    T.euclid(floor(dens * (bl - 4) + 2), bl, self.rrot, out)
    if cx > 0.45 then
      for i = 1, bl do
        if random() < (cx - 0.45) * 0.5 then out[i] = 1 - out[i] end
      end
    end
  elseif st == 3 then
    local A, B = T.NODES[self.na], T.NODES[self.nb2]
    local x, th = self.nmix, 1.02 - dens
    for i = 1, bl do
      out[i] = (A[i] + (B[i] - A[i]) * x + (random() - 0.5) * cx * 0.6) > th and 1 or 0
    end
  else
    local st2 = self.pstep
    for i = 1, bl do out[i] = 0 end
    for i = 1, bl, st2 do out[i] = 1 end
    for i = 1, bl do
      if out[i] == 0 and random() < dens * 0.55 * (0.4 + cx) then out[i] = 1 end
    end
  end
  local sg = self.song
  if sg > 0.3 then
    local q = sg * 0.8 * (1 - self.syn)
    for i = 2, bl, 2 do if out[i] == 1 and random() < q then out[i] = 0 end end
  end
  local tg = floor(dens * bl * self.tgv + 0.5)
  if cad then tg = floor(tg * 0.78) end
  if tg < 1 then tg = 1 elseif tg > bl - 1 then tg = bl - 1 end
  if random() < 0.88 then self:fit(out, tg) end
  if self.melsil or dens < 0.22 or self.step * bl > 12
    or random() < (0.78 + 0.2 * dens) * (1 - 0.75 * self.syn) then out[1] = 1 end
  if self.syn > 0.1 then
    local q = self.syn * 0.85
    for i = bl - 1, 2, -1 do
      if out[i] == 0 and out[i+1] == 1 and M[i+1] >= 2 and random() < q then
        out[i] = 1; out[i+1] = 0
      end
    end
  end
  if cad then
    for i = bl - 5, bl do if i > 0 and random() < 0.55 then out[i] = 0 end end
  end
end

function G:durations(mask, out, cad)
  local leg, M, bl = self.legato, self.M, self.bl
  for i = 1, bl do
    if mask[i] == 1 then
      local j = i + 1
      while j <= bl and mask[j] == 0 do j = j + 1 end
      local g = j - i
      if random() < leg then
        out[i] = g
      else
        out[i] = max(1, g - (g > 2 and floor(g * 0.4) or (random() < 0.5 and 1 or 0)))
      end
      if M[i] >= 4 and random() < 0.3 then out[i] = min(bl - i + 1, out[i] + g) end
    else
      out[i] = 0
    end
  end
  if cad then
    for i = bl, 1, -1 do
      if mask[i] == 1 then out[i] = min(bl, out[i] + bl // 2); break end
    end
  end
end

function G:make_motif(len, avoid)
  local sg = self.song
  local m = {len = len, n = 0, dens = 0.35, t = {}, d = {}, u = {}}
  local mask, du = self.mask, self.dur
  self:rhythm(mask, 0.38, false)
  if sg > 0.25 then mask[1] = 1 end
  self:durations(mask, du, false)
  local d, li, k = 0, 0, 0
  local ct = sg > 0.4 and ({1,4,6,1})[random(4)] or (1 + random(6))
  if avoid and ct == avoid then ct = ct % 6 + 1 end
  self.lastct = ct
  local non = 0
  for i = 1, len do if mask[i] == 1 then non = non + 1 end end
  for i = 1, len do
    if mask[i] == 1 then
      local wide = sg > 0.4
      local mx = wide and 4 or (1 + floor(self.cx * 4))
      local lim = 8 - floor(sg * 2)
      local st
      if abs(li) >= 4 then
        st = (li > 0 and -1 or 1) * (random() < 0.7 and 1 or 2)
      else
        st = (wide and T.HSTEP or T.MSTEP)[random(16)]
        if st > mx then st = mx elseif st < -mx then st = -mx end
        if li ~= 0 and random() < 0.45 then st = (li > 0 and 1 or -1) * abs(st) end
      end
      if k == 0 then st = 0 end
      if k > 0 and k >= non * 0.66 and d ~= 0 and random() < 0.28 + 0.5 * sg then
        st = d > 0 and -1 or 1
        if d > 2 or d < -2 then st = st * 2 end
      end
      local nd = d + st
      local tgt = floor(T.contour(ct, (i - 1) / len) * (self.marc or 3))
      if abs(nd - tgt) > 5 + (self.marc or 3) then nd = d - st end
      li = nd - d
      d = clamp(nd, -lim, lim + 2)
      k = k + 1
      m.t[k] = i
      m.d[k] = d
      m.u[k] = du[i]
    end
  end
  m.n = k
  if k == 0 then m.n = 1; m.t[1] = 1; m.d[1] = 0; m.u[1] = 4 end
  if m.n >= 3 then
    local fl = true
    for i = 2, m.n do if m.d[i] ~= m.d[1] then fl = false; break end end
    if fl then
      for i = 2, m.n, 2 do m.d[i] = m.d[1] + (random() < 0.5 and 2 or -2) end
    end
  end
  return m
end

function G:score_motif(m)
  local n = m.n
  if n < 2 then return -100 end
  local lo, hi = 99, -99
  local steps, leaps, reps = 0, 0, 0
  local prev = m.d[1]
  for i = 1, n do
    local d = m.d[i]
    if d < lo then lo = d end
    if d > hi then hi = d end
    if i > 1 then
      local a = d - prev
      if a < 0 then a = -a end
      if a == 0 then reps = reps + 1
      elseif a == 1 then steps = steps + 1
      else leaps = leaps + 1 end
      prev = d
    end
  end
  local span = hi - lo
  local sc = 0
  if span >= 3 and span <= 8 then sc = sc + 30
  else sc = sc - 16 * (span < 3 and (3 - span) or (span - 8)) end
  local iv = n - 1
  if iv > 0 then
    local lr = leaps / iv
    local e = lr - 0.26
    sc = sc + 25 - 210 * e * e + 30 * (steps / iv) - reps * 7
    if leaps == 0 and iv >= 3 then sc = sc - 26 end
  end
  local wrap = m.d[n] - m.d[1]
  if wrap < 0 then wrap = -wrap end
  if wrap <= 1 then sc = sc + 20
  elseif wrap <= 3 then sc = sc + 12
  else sc = sc - 9 * (wrap - 3) end
  local nap, api = 0, 1
  for i = 1, n do
    if m.d[i] == hi then
      nap = nap + 1
      if nap == 1 then api = i end
    end
  end
  if nap == 1 then sc = sc + 22 elseif nap == 2 then sc = sc + 7 else sc = sc - 6 * nap end
  local ap = (api - 1) / max(1, n - 1)
  if ap > 0.2 and ap < 0.92 then sc = sc + 13 end
  if m.d[n] < hi then sc = sc + 10 end
  local d1 = m.d[1]
  if d1 == 0 or d1 == 2 or d1 == 4 then sc = sc + 8 end
  if m.t[1] == 1 then sc = sc + 10 end
  local umin, umax = 99, 0
  for i = 1, n do
    local u = m.u[i]
    if u < umin then umin = u end
    if u > umax then umax = u end
  end
  if umax > umin then sc = sc + 9 end
  if n >= 3 and n <= 9 then sc = sc + 8 end
  return sc
end

function G:best_motif(len, avoid)
  local tries = 9 + floor(self.song * 7)
  local cand, sc, mx = {}, {}, -1e9
  for i = 1, tries do
    local m = self:make_motif(len, avoid)
    cand[i] = m
    sc[i] = self:score_motif(m)
    if sc[i] > mx then mx = sc[i] end
  end
  local temp = 10 + 26 * (1 - self.song)
  local tot, w = 0, {}
  for i = 1, tries do
    w[i] = exp((sc[i] - mx) / temp)
    tot = tot + w[i]
  end
  local r, acc = random() * tot, 0
  for i = 1, tries do
    acc = acc + w[i]
    if r <= acc then return cand[i] end
  end
  return cand[tries]
end

function G:pick_transform()
  local t = self.tr
  t.tp = 0; t.inv = false; t.ret = false; t.aug = 1; t.disp = 0; t.frag = false
  local sg = self.song
  if self.seqleft > 0 then
    self.seqleft = self.seqleft - 1
    self.seqtp = self.seqtp + self.seqinc
    if self.seqtp > 5 or self.seqtp < -5 then self.seqleft = 0 else t.tp = self.seqtp; return t end
  end
  if self.div > 4 then self.div = 0; return t end
  if random() > (0.12 + 0.74 * self.cx) * self.tvar then return t end
  local r, c = random(), 0
  local tw = 0.30 + 0.5 * sg
  local q = 1 - sg
  if r < tw then
    t.tp = T.TP[random(8)]
    c = 1
    if sg > 0.3 and random() < sg * 0.8 then
      self.seqtp = t.tp
      self.seqinc = t.tp > 0 and 1 or -1
      self.seqleft = random(2)
    end
  elseif r < tw + 0.16 * q then t.aug = random() < 0.5 and 2 or 0.5; c = 2
  elseif r < tw + 0.30 * q then t.disp = T.DISP[random(6)]; c = 1
  elseif r < tw + 0.40 * q then t.inv = true; c = 3
  elseif r < tw + 0.48 * q then t.ret = true; c = 3
  elseif r < tw + 0.58 * q then t.frag = true; c = 2
  else t.tp = T.TP[random(8)]; c = 1 end
  self.div = self.div + c
  return t
end

function G:dyn(pos)
  local a = self.apxpos / max(1, self.bps - 1)
  local t = pos / max(1, self.bps - 1)
  local x = (t <= a) and (t / max(0.05, a)) or (1 - (t - a) / max(0.05, 1 - a))
  return (x - 0.45) * self.vrange * 0.55
end

function G:vel(i, acc, hand)
  local p = self.p
  local ms = (self.M[i] - 1) * 0.25
  local amp = 3 + p.hum * 30
  self.vn = self.vn * 0.58 + (random() - 0.5) * amp * 0.72
  local v = p.vel + (self.ivel or 0) + (ms - 0.7) * self.vrange * 0.8 + self.vn + acc + self.bdyn
  if hand == 1 then
    v = v - 13 - self.vrange * 0.12
  else
    local d = self.li
    if d > 10 then d = 10 elseif d < -10 then d = -10 end
    v = v + d * 0.55 * (0.4 + 0.6 * self.song)
  end
  return clamp(floor(v), 1, 127)
end

function G:lag(hand, cad, last)
  local p = self.p
  local r, h = p.rubato, p.hum
  local o
  if hand == 1 then
    o = self.mlead + h * (0.16 + (random() - 0.5) * 0.34)
    if r > 0.01 then o = o + random() * r * 0.12 end
  else
    o = h * (0.1 + (random() - 0.5) * 0.34)
    if r > 0.01 then
      if last or cad then
        o = o + r * (0.14 + random() * 0.22)
        if cad and last then o = o + r * 0.4 end
      elseif random() < 0.22 then
        o = o + r * random() * 0.2
      end
    end
  end
  if o < 0 then o = 0 end
  return o * self.gs
end

function G:ped(d, tk, hand)
  local bl = self.bl
  local pd = self.p.pedal
  if d > bl * 1.2 then d = bl * 1.2 end
  local ov = (hand == 0 and d >= 0.9) and self.ovl or 0
  if pd < 0.5 then return d * (0.4 + 1.2 * pd) + ov end
  if self.p.pedcc then return d + ov end
  local x = (pd - 0.5) * 2 * self.pedb * (hand == 1 and 1 or 0.62)
  local room = self.hr * bl - self.choff - tk + 1 + x * 0.7
  local cap = room + bl * 0.3
  if d > cap then d = cap end
  if x <= 0.01 or room <= d then return d + ov end
  return d + (room - d) * x + ov
end

function G:chordvel(base, i, n)
  local d
  if n < 2 then d = 0
  elseif i == 1 then d = 4
  elseif i == n then d = 8
  else d = -11 end
  return clamp(floor(base + d + (random() - 0.5) * (2 + self.p.hum * 10)), 1, 127)
end

function G:left_hand(flat, pos, cad, rhn, rhm)
  if not self.lhon then return end
  local q = self.restp * 0.8 * (0.3 + 0.24 * self.lhlvl)
  if rhn == 0 then q = self.lastsil and 0 or q * 0.3 end
  if random() < q then return end
  local bl, nb, M = self.bl, self.nb, self.M
  local pat = self.lhpat
  if rhn == 0 and self.lhlvl < 3 and random() < 0.7 then
    local q = min(#T.LADDER, self.lhpi + 2 + floor(random() * 4))
    pat = T.LH[T.LADDER[q]]
  end
  local busy = rhn / bl
  local thin = clamp(self.lhthin + self.p.space * 0.7 + busy * 0.42 * (1.1 - self.p.lh * 0.45), 0, 0.95)
  local hits = {}
  local nh = 0
  local fi, fk, fm = 0, 0, -1
  for i = 0, bl - 1 do
    local k0 = pat.f(i, i // 4, i % 4, nb)
    local k = k0
    if k0 ~= 0 and M[i+1] > fm then fi, fk, fm = i + 1, k0, M[i+1] end
    if k ~= 0 then
      if M[i+1] <= 1 and random() < thin * 0.9 then k = 0
      elseif M[i+1] <= 2 and random() < thin * 0.5 then k = 0 end
      if cad and i > bl * 0.6 and random() < 0.3 then k = 0 end
    end
    if k ~= 0 then
      nh = nh + 1
      hits[nh] = i + 1
      hits[-nh] = k
    end
  end
  if nh == 0 and rhn > 0 and fk ~= 0 then
    nh = 1; hits[1] = fi; hits[-1] = fk
  end
  self:voice_chord()
  local top = self.vo[#self.vo] or (self.split + 4)
  local ar = 0.72 + 0.28 * self.art
  for j = 1, nh do
    local tk = hits[j]
    local k = hits[-j]
    local nxt = (j < nh) and hits[j+1] or (bl + 1)
    local base = self:vel(tk, rhm[tk] == 1 and 5 or 0, 1)
    local e = newev(tk, max(0.6, (nxt - tk) * ar), base, 1)
    e.o = self:lag(1)
    if k < 0 then
      local nn = min(#self.vo, 4)
      for i = 1, nn do
        local x = self:lhnote(i)
        if x >= self.lo and x <= top then e.n[#e.n+1] = x end
      end
      if #e.n == 0 then e.n[1] = self.lhbase end
      local c = #e.n
      local vs = {}
      for i = 1, c do vs[i] = self:chordvel(base, i, c) end
      e.vs = vs
      e.s = ((k == -2) and (1 + random() * 1.5) or (0.04 + self.p.hum * 0.22)) * self.gs
    else
      local x = self:lhnote(k)
      while x > top do x = x - 12 end
      while x < self.lo do x = x + 12 end
      e.n[1] = x
    end
    flat[#flat+1] = e
  end
end

function G:ornament(flat, ev, pn, tk)
  local o = self.orn
  if o <= 0 or random() > o * 0.55 then return end
  local dir = random() < 0.62 and -1 or 1
  local g = self:snapc(pn) ~= pn and pn or pn + dir * (random() < 0.75 and 1 or 2)
  if dir > 0 or random() > (self.stray or 0) * 0.8 then g = self:snaps(g) end
  g = self:fold(g)
  if g == pn then return end
  if tk < 2 then return end
  local e = newev(tk - 1, 1, max(1, ev.v - 18), 0)
  e.n[1] = g
  e.g = true
  e.o = clamp(self.gof + self:lag(0) * 0.4, 0, 0.95)
  flat[#flat+1] = e
end

function G:chrapp(flat, ev, pn, tk, ms)
  if self.chrom <= 0 or tk < 2 then return end
  local q = self.chrom * ((ms and ms >= 0.5) and 1.0 or 0.45)
  if random() > q then return end
  local dir = (random() < 0.78) and -1 or 1
  local g = pn + dir
  if g < self.lo or g > self.hi then return end
  if self.insc[(g - self.root) % 12 + 1] then return end
  local e = newev(tk - 1, 1, max(1, ev.v - 14), 0)
  e.n[1] = g
  e.g = true
  e.o = clamp(self.gof + self:lag(0) * 0.4, 0, 0.95)
  flat[#flat+1] = e
end

function G:fill(flat, a, b, tk)
  local gap = b - a
  if abs(gap) < 3 or abs(gap) > 12 then return end
  if random() > self.orn * 0.5 then return end
  local t = tk - 1
  if t < 1 then return end
  local mid = self:fold(self:snapc(self:fold(a + (gap > 0 and 2 or -2))))
  local e = newev(t, 1, clamp(self.p.vel - 22, 1, 127), 0)
  e.n[1] = mid
  e.g = true
  e.o = clamp(self.gof + self:lag(0) * 0.4, 0, 0.95)
  flat[#flat+1] = e
end

function G:ratchet(e, i)
  local r = self.ratch
  if r <= 0 then return end
  local ms = (self.M[i] - 1) * 0.25
  if random() > r * 0.4 * (1.1 - ms) then return end
  e.r = random() < 0.55 and 2 or (random() < 0.7 and 3 or 4)
end

function G:cadence_note(pn, final)
  local tgt
  if final then tgt = 0
  elseif random() < self.song then tgt = random() < 0.55 and 4 or 2
  else tgt = random() < 0.5 and 4 or (random() < 0.5 and 1 or 6) end
  local pc = self.s[tgt + 1] % 12
  for k = 0, 6 do
    if (pn - k - self.root) % 12 == pc then return self:fold(pn - k) end
    if (pn + k - self.root) % 12 == pc then return self:fold(pn + k) end
  end
  return pn
end

function G:render_motif(flat, m, tr, cad, final, dens, apex)
  local bl = self.bl
  local ad = self.atonic and 0 or self.cdeg
  local anchor = ad + self.mbase
  local n = m.n
  local kmax = tr.frag and max(1, (n + 1) // 2) or n
  local d0 = m.d[tr.ret and n or 1]
  if tr.inv then d0 = -d0 end
  local cb = self.cbase
  local ref = self.pn + (cb - self.pn) * 0.5
  if apex then ref = ref + 2 end
  if ref < cb - 11 then ref = cb - 11 elseif ref > cb + 11 then ref = cb + 11 end
  local oct = 12 * floor((ref - self:dn(anchor + d0 + tr.tp)) / 12 + 0.5)
  local sg = self.song
  local sf = clamp(m.dens / dens, 0.3, 6)
  local keep = clamp(0.92 + (dens - m.dens) * 0.5, 0.42, 1)
  local extra = clamp((dens - m.dens) * 1.6, 0, 0.9) * (1 - 0.55 * sg)
  local span = floor(m.len * tr.aug * sf + 0.5)
  if span < 1 then span = 1 end
  local reps, boff = 1, 0
  if span > bl then
    boff = -bl * (self.bar % ((span + bl - 1) // bl))
  else
    reps = bl // span
    if reps > 6 then reps = 6 end
  end
  local prevn, prevtk = nil, nil
  local sl, sn = self.slots, 0
  for r = 0, reps - 1 do
    local off = r * span
    local rtp = (r > 0 and random() < 0.35 * (1 - 0.5 * sg)) and (random() < 0.5 and 1 or -1) or 0
    local lastrep = r == reps - 1
    for k = 1, kmax do
      local si = tr.ret and (n - k + 1) or k
      local d = m.d[si]
      if tr.inv then d = -d end
      d = d + tr.tp + rtp
      local tk = floor((m.t[k] - 1) * tr.aug * sf + 0.5) + 1 + tr.disp + off + boff
      if tk >= 1 and tk <= bl and sn < 34 then
        local nk = k + 1
        local ntk = nk <= kmax
          and (floor((m.t[nk] - 1) * tr.aug * sf + 0.5) + 1 + tr.disp + off + boff)
          or (tk + 2)
        sn = sn + 1
        sl.tk[sn] = tk
        sl.ms[sn] = (self.M[tk] - 1) * 0.25
        sl.gap[sn] = max(1, ntk - tk) * self.step
        sl.want[sn] = self:fold(self:near(self:dn(anchor + d) + oct))
        sl.ww[sn] = 0.7 + 1.5 * self.rep
        sl.anch[sn] = (k == 1)
        sl.du[sn] = max(1, floor(m.u[si] * tr.aug * sf + 0.5))
        sl.k[sn] = k
        sl.last[sn] = lastrep and k == kmax
      end
    end
  end
  sl.n = sn
  if sn == 0 then return end

  local cx = self.pctx
  cx.target = ref
  cx.cad = cad
  cx.close = cad and 1 or 0
  cx.apex = apex or false
  cx.pos = self.mpos
  cx.bps = self.bps
  cx.apxpos = self.apxpos
  local pl = self.play
  local got = pl:runbar(sl, cx)

  for q = 1, got do
    local tk = sl.tk[q]
    local pn = pl.outn[q]
    local fg, strain, shifted = pl.outf[q], pl.outs[q], pl.outsh[q]
    local ms, k, lastn = sl.ms[q], sl.k[q], sl.last[q]
    if (pn ~= self.pn or tk - (prevtk or -9) >= 2) and random() < keep then
      self:emit(pn, ms)
      local dq = sl.du[q]
      if cad and lastn then dq = dq + bl // 2 end
      local e = newev(tk, max(0.6, dq * self.art),
        self:vel(tk, k == 1 and (4 + floor(sg * 5)) or (apex and 6 or 0), 0), 0)
      e.n[1] = pn
      e.v = clamp(floor(e.v + pl:touch(fg, strain, shifted) + 0.5), 1, 127)
      e.d = max(0.4, e.d - pl:lift(fg, strain, shifted))
      e.d0 = e.d
      e.o = self:lag(0, cad, lastn) + strain * 0.12
      self:ratchet(e, tk)
      flat[#flat+1] = e
      if prevn then
        self:fill(flat, prevn, pn, tk)
        if tk - prevtk >= 2 and random() < extra then
          local mt = prevtk + (tk - prevtk) // 2
          local mn = self:fold(self:snapc(self:fold(prevn + (pn > prevn and 2 or -2))))
          if mn ~= prevn and mn ~= pn then
            local me = newev(mt, max(1, tk - mt), self:vel(mt, -6, 0), 0)
            me.n[1] = mn
            me.o = self:lag(0)
            flat[#flat+1] = me
          end
        end
      end
      self:ornament(flat, e, pn, tk)
      self:chrapp(flat, e, pn, tk, ms)
      prevn, prevtk = pn, tk
    end
  end
end

function G:gen_bar(flat, sec, pos, cad, final, bi, plen)
  local p = self.p
  local bl = self.bl
  self.cbase = p.centre + (self.icent or 0) + self.bn * 3 + self.dc + T.pnext(self.pc) * 2 * (1 - 0.6 * self.song) + 4
  local oc = self.oct
  local tg2 = clamp(self.cbase + oc, self.split + 3, self.hi - 3)
  oc = tg2 - self.cbase
  self.cbase = tg2
  if self.jump then
    self.jump = false
    if oc ~= 0 then self.pn = clamp(floor(self.cbase), self.split, self.hi); self.li = 0 end
  end
  self.mpos = pos
  if pos == 0 then
    self.play:newphrase(self.cbase)
    self:pick_tex()
    local d = (self.sdyn or 0) * 0.55 + (random() - 0.5) * self.vrange * 0.78
    self.sdyn = clamp(d, -self.vrange * 0.62, self.vrange * 0.62)
  end
  local dens = clamp(self.dens + self.dd + T.pnext(self.pd) * 0.1, 0.03, 0.99)
  if cad then dens = dens * 0.78 end
  self.bdyn = self:dyn(pos) + (self.sdyn or 0)
  local rhm = self.rhm
  for i = 1, bl do rhm[i] = 0 end

  if self.conseq then
    local sf = self.sflat
    if self.sfsig ~= self.ssig then self:refit(sf); self.sfsig = self.ssig end
    local ln = 0
    for i = 1, #sf do
      local e = sf[i]
      e.o = self:lag(e.h, cad, false)
      e.v = clamp(floor((e.v0 or e.v) + (random() - 0.5) * (3 + p.hum * 16)), 1, 127)
      flat[#flat+1] = e
      ln = #flat
    end
    if ln > 0 then
      local e = flat[ln]
      local c = newev(e.t, e.d0 + bl // 4, e.v, 0)
      c.n[1] = self:cadence_note(e.n[1], final)
      c.o = self:lag(0, true, true)
      flat[ln] = c
      self:emit(c.n[1])
    end
    self:hands(flat, pos, cad, rhm)
    return
  end

  self.resting = not self.melsil and random() < self.restp * (cad and 2.2 or 0.3)
  if self.resting then
    self:hands(flat, pos, cad, rhm)
    return
  end

  local apex = (pos == self.apxpos) and random() < 0.35 + 0.55 * self.song
  local slot = self.form[sec]
  local mask, du = self.mask, self.dur

  if slot == 3 and random() < self.freeb then
    self:rhythm(mask, dens, cad)
    self:durations(mask, du, cad)
    local ct = self.ctr
    local pl = self.play
    local sl = self.slots
    local sn = 0
    local btg, bms = self.cbase, -1
    for i = 1, bl do
      if mask[i] == 1 and sn < 34 then
        local t = (bi * bl + i - 1) / (plen * bl)
        local ms = (self.M[i] - 1) * 0.25
        local centre = self.cbase + self.camp * T.contour(ct, t) + T.pnext(self.pc) * 4 * (1 - 0.7 * self.song)
        if apex then centre = centre + 3 + 4 * self.song end
        local nx = i + 1
        while nx <= bl and mask[nx] == 0 do nx = nx + 1 end
        sn = sn + 1
        sl.tk[sn] = i
        sl.ms[sn] = ms
        sl.gap[sn] = (min(nx, bl + 1) - i) * self.step
        sl.want[sn] = nil
        sl.ww[sn] = 0
        sl.anch[sn] = ms >= 0.95
        sl.du[sn] = du[i]
        sl.k[sn] = i
        sl.last[sn] = i >= bl - 2
        if ms > bms then bms = ms; btg = centre end
      end
    end
    sl.n = sn
    local cx = self.pctx
    cx.target = btg
    cx.cad = cad
    cx.close = cad and 1 or 0
    cx.apex = apex or false
    cx.pos = pos
    cx.bps = self.bps
    cx.apxpos = self.apxpos
    local got = pl:runbar(sl, cx)
    for q = 1, got do
      local i = sl.tk[q]
      local pn = pl.outn[q]
      local fg, strain, shifted = pl.outf[q], pl.outs[q], pl.outsh[q]
      local lastn = sl.last[q]
      self:emit(pn, sl.ms[q])
      local e = newev(i, max(0.6, du[i] * self.art), self:vel(i, apex and 6 or 0, 0), 0)
      e.n[1] = pn
      e.v = clamp(floor(e.v + pl:touch(fg, strain, shifted) + 0.5), 1, 127)
      e.d = max(0.4, e.d - pl:lift(fg, strain, shifted))
      e.d0 = e.d
      e.o = self:lag(0, cad, lastn) + strain * 0.12
      self:ratchet(e, i)
      flat[#flat+1] = e
      self:ornament(flat, e, pn, i)
    end
  else
    local m = self.motif[slot] or self.motif[(slot - 1) % 2 + 1]
    local tr = self:pick_transform()
    if apex then tr.tp = tr.tp + (random() < 0.6 and 2 or 1) end
    self:render_motif(flat, m, tr, cad, final, dens, apex)
  end
  self:hands(flat, pos, cad, rhm)
end

local THIRDS = {[3] = true, [4] = true, [8] = true, [9] = true}
local VOICED = {[3] = true, [4] = true, [5] = true, [7] = true, [8] = true, [9] = true}

function G:ctbelow(n, ok, lo)
  local r = self.root
  for d = 3, 9 do
    if ok[d] then
      local x = n - d
      if x >= lo and self.cpc[(x - r) % 12 + 1] then return x end
    end
  end
  return nil
end

function G:pick_tex()
  local h = self.p.harm or 0.5
  local sg = self.song or 0.5
  local ik = self.ik or 0
  local w1 = max(0.02, 2.5 - 1.2 * h - 1.0 * ik)
  local w2 = max(0.02, 0.30 + 1.00 * h + 0.55 * ik)
  local w3 = max(0.02, 0.25 + 0.95 * h * (0.4 + 0.6 * sg) + 0.30 * ik)
  local w4 = max(0.02, 0.10 + 0.85 * h * (0.3 + 0.7 * sg) + 0.45 * ik)
  local tot = w1 + w2 + w3 + w4
  local r = random() * tot
  if r < w1 then self.rhtex = 1
  elseif r < w1 + w2 then self.rhtex = 2
  elseif r < w1 + w2 + w3 then self.rhtex = 3
  else self.rhtex = 4 end
  self.txp = clamp(0.30 + 0.55 * h + 0.28 * ik, 0.05, 0.95)
end

function G:thicken(flat)
  local tx = self.rhtex or 1
  local lo = self.split - 2
  local apex = self.bdyn > self.vrange * 0.2
  for i = 1, #flat do
    local e = flat[i]
    if e.h == 0 and not e.g and e.n[1] then
      if e.tx then
        for q = #e.n, 2, -1 do e.n[q] = nil end
        local vs = e.vs
        if vs then for q = 1, #vs do vs[q] = nil end end
        e.tx = false
      end
      if tx > 1 then
        local n = e.n[1]
        local t = e.t
        local ms = (t >= 1 and t <= self.bl) and (self.M[t] - 1) * 0.25 or 0.5
        if (ms >= 0.45 or e.d >= 2) and random() < self.txp then
          local mode = tx
          if apex and tx >= 3 and random() < 0.45 then mode = 2 end
          local k = 1
          if mode == 2 then
            local x = n - 12
            if x >= lo then k = 2; e.n[2] = x end
          elseif mode == 3 then
            local x = self:ctbelow(n, THIRDS, lo)
            if x then k = 2; e.n[2] = x end
          else
            local a = self:ctbelow(n, VOICED, lo)
            if a then
              k = 2; e.n[2] = a
              local b = self:ctbelow(a, VOICED, lo)
              if b and random() < 0.55 then k = 3; e.n[3] = b end
            end
          end
          if k > 1 then
            e.tx = true
            local vs = e.vs
            if not vs then vs = {}; e.vs = vs end
            vs[1] = e.v
            for q = 2, k do vs[q] = max(1, e.v - 9 - (q - 2) * 5) end
            for q = k + 1, #vs do vs[q] = nil end
          end
        end
      end
    end
  end
end

function G:hands(flat, pos, cad, rhm)
  local bl, rhn = self.bl, 0
  local mlow = 127
  self:thicken(flat)
  for i = 1, #flat do
    local e = flat[i]
    if e.h == 0 then
      for q = 1, #e.n do
        local x = e.n[q]
        if x and x < mlow then mlow = x end
      end
      if e.t >= 1 and e.t <= bl and rhm[e.t] == 0 then
        rhm[e.t] = 1
        rhn = rhn + 1
      end
    end
  end
  self.mlow = mlow
  self:left_hand(flat, pos, cad, rhn, rhm)
end

function G:bar_begin()
  local ev, bl = self.ev, self.bl
  for i = 1, 16 do
    local e = ev[i]
    for j = #e, 1, -1 do e[j] = nil end
  end
  local plen = self.nsec * self.bps
  local bi = self.bar % plen
  local sec = bi // self.bps + 1
  local pos = bi % self.bps
  local last = pos == self.bps - 1
  local final = last and sec == self.nsec

  if abs(self.db - self.lastb) > 0.03 then
    self.lastb = self.db
    self:update_scale()
    self:update_lut()
  end
  if bi == 0 and self.bar > 0 then self:renew() end
  if bi % self.hr == 0 then self:pivot_roll() end
  if pos == 0 then
    local pix = self.secpat[self.form[sec]] or self.secpat[1]
    self.lhpat = T.LH[pix]
    self.lhpi = T.LPOS[pix] or 1
    self.art = clamp(self.artbase + (random() - 0.5) * 0.3, 0.35, 1.4)
    self.tgv = 1 + (random() - 0.5) * 0.34
    local raw = (self.octs[self.form[sec]] or 0) + self:arcof(sec)
      + ((self.bar // (self.bps * self.nsec)) % 2 == 1 and self.replift or 0)
    local o = floor((raw - self.octc) * self.octsc + 0.5)
    if o ~= self.oct then self.oct = o; self.jump = true end
  end
  if pos == 0 and self.progdirty then
    self.progdirty = false
    self:build_prog(self.pstyle or 1)
  end
  local ci = bi // self.hr % #self.prog + 1
  local pr = self.prog[ci]
  local shi = self:shape_for(pr)
  local calt = pr[6] or 0
  local same = (self.lastdeg == pr[1] and self.lastsh == shi and self.lastalt == calt)
  self.newchord = not same
  self.choff = (bi % self.hr) * bl
  self.lastdeg, self.lastsh, self.lastalt = pr[1], shi, calt
  self.struct = (pos == 0) or last or final
  self.calt, self.caltd = calt, (pr[1] + 2) % 7
  self:build_chord(pr[1], shi)

  local flat = self.flat
  self.conseq = last and pos > 0 and #self.sflat > 0 and random() < self.song * 0.55
  local elig = (pos > 0) or (sec > 1 and self.form[sec] == self.form[sec - 1])
  if final or (last and self.rep < 0.7) then elig = false end
  local reuse = elig and #flat > 0
    and random() < self.rep * (same and 1 or (0.4 + 0.55 * self.rep))
  if reuse then
    self.bdyn = self:dyn(pos)
    local stale = self.flatsig ~= self.ssig
    if stale then self:refit(flat); self.flatsig = self.ssig end
    if (not same) or stale then self:reseat(flat, pos, last) end
    self:refresh(flat, last)
  else
    for i = #flat, 1, -1 do flat[i] = nil end
    self:gen_bar(flat, sec, pos, last, final, bi, plen)
    self.flatsig = self.ssig
  end
  if pos == 0 and not reuse then
    local sf = self.sflat
    for i = #sf, 1, -1 do sf[i] = nil end
    for i = 1, #flat do if flat[i].h == 0 then sf[#sf+1] = flat[i] end end
    self.sfsig = self.ssig
  end
  local used = self.sc
  for i = 1, bl do used[i] = 0 end
  local ln, lt, np, nm = -1, -9, 0, 0
  for i = 1, #flat do
    local e = flat[i]
    local t = e.t
    if t >= 1 and t <= bl and (e.h == 1 or (used[t] == 0 and not (e.n[1] == ln and t - lt < 2))) then
      e.d = e.g and e.d0 or self:ped(e.d0, t, e.h)
      if e.h == 0 then
        used[t] = 1; ln = e.n[1]; lt = t
      end
      local l = ev[t]
      l[#l+1] = e
      np = np + 1
      if e.h == 0 then nm = nm + 1 end
    end
  end
  if nm == 0 and not self.resting then
    local e = newev(1, max(2, bl // 2), self:vel(1, 0, 0), 0)
    local n = self:fold(self:near(self:snapc(self.pn)))
    e.n[1] = n
    e.d = self:ped(e.d0, 1, 0)
    self:emit(n, 1)
    local l = ev[1]
    l[#l+1] = e
    np = np + 1
    nm = 1
  end
  self.barn = np
  self.lastsil = np == 0
  self.melsil = nm == 0
end

function G:refit(flat)
  local ins, r = self.insc, self.root
  for i = 1, #flat do
    local e = flat[i]
    if e.h == 0 then
      local n = e.n
      for j = 1, #n do
        local x = n[j]
        if not ins[(x - r) % 12 + 1] then
          local q = self:snaps(x)
          if abs(q - x) <= 2 then n[j] = q end
        end
      end
    end
  end
end

function G:refresh(flat, cad)
  local hum = self.p.hum
  local amp = 3 + hum * 16
  for i = 1, #flat do
    local e = flat[i]
    e.o = self:lag(e.h, cad, false)
    e.v = clamp(floor((e.v0 or e.v) + (random() - 0.5) * amp), 1, 127)
    local vs = e.vs
    if vs then
      local c = #vs
      for j = 1, c do vs[j] = self:chordvel(e.v, j, c) end
    end
  end
end

function G:reseat(flat, pos, cad)
  local bl = self.bl
  local w = 0
  for i = 1, #flat do
    local e = flat[i]
    if e.h == 0 then
      w = w + 1
      flat[w] = e
      local t = e.t
      local ms = (t >= 1 and t <= bl) and self.M[t] or 1
      if e.n[1] and ms >= 3 and not e.g then
        local q = self:snapc(e.n[1])
        if q ~= e.n[1] and abs(q - e.n[1]) <= 2 then e.n[1] = q end
      end
    end
  end
  for i = #flat, w + 1, -1 do flat[i] = nil end
  local rhm = self.rhm
  for i = 1, bl do rhm[i] = 0 end
  self:hands(flat, pos, cad, rhm)
end

function G:advance()
  self.tick = self.tick + 1
  if self.tick >= self.bl then
    self.tick = 0
    self.bar = self.bar + 1
  end
end

function G:reset()
  self.bar, self.tick, self.div = 0, 0, 0
  self.lhprev, self.binv = nil, 1
  if self.play then
    self.play:rehand(floor(self.p.centre))
    self.play:newphrase(self.p.centre)
  end
  self.res, self.conseq = nil, false
  self.bdyn, self.barn, self.choff, self.vn = 0, 0, 0, 0
  self.lastsil, self.melsil, self.resting, self.newchord = false, false, false, true
  for i = #self.sflat, 1, -1 do self.sflat[i] = nil end
  for i = #self.flat, 1, -1 do self.flat[i] = nil end
  for i = #self.prev, 1, -1 do self.prev[i] = nil end
end

function G:shape_for(pr)
  local base = pr[2]
  if self.plane then return base end
  local w, w0 = self.wb, self.wb0
  local ns = #T.SHAPES
  local bt = clamp(self.bn * 0.55 + self.cx * 0.3, -0.7, 0.9)
  local hm = self.p.harm or 0.35
  if pr[3] and abs((pr[4] or 9) - bt) < 0.08 and abs((pr[5] or 9) - hm) < 0.08 then
    return pr[3]
  end
  if bt ~= self.wbt then
    self.wbt = bt
    for j = 1, ns do
      local dd = T.SHAPES[j].b - bt
      w0[j] = exp(-(dd * dd) / 0.20) + 0.015
    end
  end
  local set = self.shset
  local hs = hm - 0.4
  for j = 1, ns do
    local f = 1 + (T.SHAPES[j].n - 3) * hs * 1.15
    if f < 0.06 then f = 0.06 end
    w[j] = w0[j] * f
  end
  if w[base] then w[base] = w[base] * 3.2 end
  if set then
    for j = 1, ns do w[j] = w[j] * 0.002 end
    for i = 1, #set do w[set[i]] = w[set[i]] * 900 end
  end
  local r = T.wpick(w, ns)
  pr[3], pr[4], pr[5] = r, bt, hm
  return r
end

function G:build_prog(style)
  local n = max(1, (self.nsec * self.bps) // self.hr)
  local pr = self.prog
  for i = #pr, 1, -1 do pr[i] = nil end
  local d = 0
  local w = {}
  local ph = random(#T.SHAPES)
  if style == 6 and self.shset then ph = self.shset[random(#self.shset)] end
  self.plane = style == 6
  local fix = {}
  if style ~= 5 and style ~= 6 then
    local cp = 0.15 + 0.55 * self.p.harm + 0.28 * self.song
    local mid = self.nsec // 2
    for s = 1, self.nsec do
      local idx = ((s * self.bps - 1) // self.hr) + 1
      if idx > 1 and idx <= n and not fix[idx] then
        local must = (s == self.nsec) or (n >= 6 and mid > 1 and s == mid)
        if must or random() < cp then
          local pre = (s == self.nsec) and 4 or (random() < 0.6 and 4 or 3)
          fix[idx] = pre
          if idx < n and not fix[idx + 1] then
            if pre == 4 then fix[idx + 1] = (random() < 0.82) and 0 or 5
            else fix[idx + 1] = (random() < 0.62) and 4 or 0 end
          end
        end
      end
    end
  end
  fix[1] = 0
  for i = 1, n do
    if fix[i] then
      d = fix[i]
    elseif i > 1 then
      if style == 1 then
        local row = T.CLASSIC[d + 1]
        for j = 1, 7 do w[j] = row[j] end
      elseif style == 2 then
        local ca = T.COFPOS[d + 1]
        for j = 1, 7 do
          w[j] = T.FREQ[j] * (self.cof ^ abs(T.COFPOS[j] - ca))
        end
      elseif style == 3 then
        for j = 1, 7 do w[j] = 0.02 end
        w[1] = 0.5; w[self.vamp + 1] = 0.5
      elseif style == 5 then
        for j = 1, 7 do w[j] = 0 end
        w[d + 1] = 1
      elseif style == 6 then
        for j = 1, 7 do w[j] = 0 end
        local m = ({1,-1,2,-2,1,-1,3})[random(7)]
        w[(d + m) % 7 + 1] = 1
      elseif style == 7 then
        for j = 1, 7 do w[j] = 0 end
        local nxt
        if d == 1 then nxt = 4
        elseif d == 4 then nxt = random() < 0.82 and 0 or 5
        elseif d == 2 then nxt = 5
        elseif d == 5 then nxt = 1
        elseif d == 3 then nxt = random() < 0.5 and 1 or 4
        else
          local r = random()
          nxt = (r < 0.4 and 1) or (r < 0.6 and 2) or (r < 0.82 and 3) or 5
        end
        w[nxt + 1] = 1
      else
        for j = 1, 7 do w[j] = 1 end
        w[d + 1] = 0.15
      end
      d = T.wpick(w, 7) - 1
    end
    pr[i] = {d, (style == 6 and ph) or random(#T.SHAPES)}
  end
  local sd = clamp((self.p.harm or 0) - 0.55, 0, 0.45) * 1.8
  if sd > 0 and style ~= 5 and style ~= 6 then
    local s = self.s
    for i = 1, #pr do
      local nx = pr[i + 1] or pr[1]
      local d = pr[i][1]
      if nx and nx[1] ~= d and d == (nx[1] + 4) % 7
        and (s[(d + 2) % 7 + 1] - s[d % 7 + 1]) % 12 == 3
        and random() < sd then
        pr[i][6] = 1
      end
    end
  end
  self.pstyle = style
end

function G:set_meter(bl)
  self.bl = bl
  self.nb = bl // 4
  T.metric(bl, self.M)
end

function G:reroll(chaos)
  local p = self.p
  if chaos then
    local sd = T.STYLE[p.style or 0]
    sd = sd and sd.d
    if sd then
      local function j(v, a) return clamp(v + (random() - 0.5) * 2 * a, 0, 1) end
      p.bright = clamp(sd.mode + ({-1,0,0,0,1})[random(5)], -5, 3)
      p.space = j(sd.space, 0.16)
      p.motion = j(sd.motion, 0.13)
      p.syn = sd.syn > 0.02 and j(sd.syn, 0.14) or (random() < 0.25 and random() * 0.12 or 0)
      p.rep = j(sd.rep, 0.18)
      p.len = j(sd.len, 0.15)
      p.tens = j(sd.tens, 0.15)
      p.stray = clamp((sd.stray or 0.08) + (random() - 0.5) * 0.14, 0, 1)
      p.rh = j(sd.right, 0.18)
      p.lh = j(sd.left, 0.18)
      p.harm = j(sd.harm, 0.13)
      p.swing = sd.swing > 0.02 and j(sd.swing, 0.1) or 0
      p.hum = j(sd.hum, 0.13)
    else
      local mm = -5.2 + random() * 8.4
      p.bright = clamp(random() < 0.72 and floor(mm + 0.5) or mm, -5, 3)
      p.space = 0.05 + random() * 0.7
      p.motion = 0.2 + random() * 0.7
      p.syn = random() < 0.45 and random() * 0.7 or 0
      p.rep = 0.15 + random() * 0.8
      p.len = 0.15 + random() * 0.8
      p.tens = random() * 0.8
      p.stray = random() < 0.55 and random() * 0.22 or (0.22 + random() * 0.45)
      p.rh = random() ^ 1.3
      p.lh = random() < 0.12 and 0 or (0.1 + random() * 0.9)
      p.harm = random()
      p.swing = random() < 0.45 and random() * 0.55 or 0
      p.hum = 0.05 + random() * 0.6
    end
    self:derive()
  end
  local st = T.STYLE[p.style or 0]
  if p.rootlock then self.root = p.root else self.root = random(12) - 1 end
  self.bo = 0
  if st then
    self.infl = st.inf[random(#st.inf)]
  else
    self.infl = (random() < 0.55) and random(4) or 0
  end
  self:set_meter(st and st.bl or (random() < 0.24 and 12 or 16))
  self:update_scale()
  self:update_lut()

  local mo, sg = p.harm, self.song
  self.nsec = 4
  self.bps = st and st.bps or (random() < 0.35 + 0.45 * sg and 2 or 4)
  local hw = {mo + 0.15, 0.5, (1 - mo) * 0.8 + 0.1, (1 - mo) * 0.9}
  self.hr = st and st.hr or ({1,1,2,4})[T.wpick(hw, 4)]
  if self.hr > self.bps then self.hr = self.bps end
  self.form = (random() < sg * 0.9) and HFORMS[random(#HFORMS)] or FORMS[random(#FORMS)]
  self.cof = 0.35 + random() * 0.55
  self.vamp = random(6)
  local sw = {mo * 1.2 + 0.15, mo * 0.9 + 0.2, (1 - mo) * 0.75 + 0.12,
              (1 - mo) * 0.85 + 0.15, (1 - mo) * (1 - mo) * 0.8}
  self:build_prog(st and st.ps or T.wpick(sw, 5))

  self.rstyle = random(4)
  self.rrot = random(self.bl) - 1
  self.na, self.nb2 = random(#T.NODES), random(#T.NODES)
  self.nb = self.bl // 4
  self.nmix = random()
  self.pstep = ({2,4,3,4,8})[random(5)]
  self.ctr = random(6)
  self.camp = (2 + random() * 9) * (1 - 0.55 * sg)
  self.marc = 2.4 + random() * 4.2
  self.mbase = (st and st.mb) or ((random() < sg * 0.85) and 0 or ({0,0,7,-7,7,14})[random(6)])
  self.seqleft = 0
  self.atonic = (not (st and st.at == 0)) and random() < sg * 0.35
  self.lhseed = random(20)
  local oc = self.octs
  local oa = st and st.oct or 1
  oc[1] = random() < 0.22 * oa and T.OCTS[random(#T.OCTS)] or 0
  oc[2] = floor(T.OCTS[random(#T.OCTS)] * oa + 0.5)
  oc[3] = floor(T.OCTS[random(#T.OCTS)] * oa + 0.5)
  local a, same = oc[self.form[1]], true
  for i = 2, self.nsec do if oc[self.form[i]] ~= a then same = false; break end end
  if same then
    for i = 2, self.nsec do
      local sl = self.form[i]
      if sl ~= self.form[1] then oc[sl] = a + (random() < 0.7 and 12 or -7); break end
    end
  end
  self.replift = random() < 0.45 * oa and 12 or 0
  self.arcamp = random() < 0.62 and (2 + random() * 5) * oa or 0
  self:plan_registers()
  self:derive()

  self.apxpos = max(1, floor(self.bps * 0.6))
  self.motif[1] = self:best_motif((random() < 0.45 + 0.35 * sg) and self.bl // 2 or self.bl)
  self.motif[2] = self:best_motif((random() < 0.55 + 0.25 * sg) and self.bl // 2 or self.bl, self.lastct)
  self.motif[3] = self:best_motif((random() < 0.5 + 0.3 * sg) and self.bl // 2 or self.bl, self.lastct)

  self.cbase = p.centre + self.bn * 3 + 4
  self.pn = clamp(floor(self.cbase), self.split, self.hi)
  self.li = 0
  self.lastdeg, self.lastsh, self.lastalt = -1, -1, -1
  self:reset()
end

local function pne(n, cur)
  local v = random(n)
  if v == cur then v = v % n + 1 end
  return v
end

function G:mutate()
  local r = random(10)
  if r == 1 then self.motif[1] = self:best_motif(self.motif[1].len)
  elseif r == 2 then self.motif[2] = self:best_motif(self.motif[2].len)
  elseif r == 3 then self:build_prog(pne(5, self.pstyle))
  elseif r == 4 then self.rstyle = pne(4, self.rstyle); self.rrot = random(self.bl) - 1; self.nmix = random()
  elseif r == 5 then
    local f = (random() < self.song * 0.9) and HFORMS or FORMS
    local i = random(#f)
    if f[i] == self.form then i = i % #f + 1 end
    self.form = f[i]
    self:plan_registers()
  elseif r == 6 then self.ctr = pne(6, self.ctr); self.camp = 2 + random() * 9
  elseif r == 7 then
    self.mbase = (random() < self.song * 0.85) and 0 or ({0,0,7,-7,7,14})[random(6)]
    elseif r == 8 then self.lhseed = pne(20, self.lhseed); self:derive()
  elseif r == 9 then
    local oc = self.octs
    oc[pne(3, 1)] = T.OCTS[random(#T.OCTS)]
    self:plan_registers()
  else self.infl = pne(5, self.infl + 1) - 1; self:update_scale() end
  self.div = 0
  self.seqleft = 0
  for i = #self.flat, 1, -1 do self.flat[i] = nil end
end

function G:renew()
  local d = self.p.drift or 0
  if d <= 0.01 then return end
  local q = d * 0.8
  if random() < q then
    local k = random(3)
    local m = self.motif[k]
    self.motif[k] = self:best_motif(m and m.len or self.bl, self.lastct)
  end
  if random() < q * 0.5 then
    self.ctr = pne(6, self.ctr)
    self.marc = 2.4 + random() * 4.2
  end
  if random() < q * 0.34 then
    self.form = (random() < self.song * 0.9) and HFORMS[random(#HFORMS)] or FORMS[random(#FORMS)]
  end
  if random() < q * 0.26 then self.progdirty = true end
  if random() < q * 0.20 then
    self.octs[random(3)] = floor(T.OCTS[random(#T.OCTS)] + 0.5)
    self:plan_registers()
  end
end

function G:save_state()
  return {
    v = 1, root = self.root, bo = self.bo, infl = self.infl, bl = self.bl,
    bps = self.bps, hr = self.hr, nsec = self.nsec, apxpos = self.apxpos,
    form = self.form, prog = self.prog, pstyle = self.pstyle,
    cof = self.cof, vamp = self.vamp, rstyle = self.rstyle, rrot = self.rrot,
    na = self.na, nb2 = self.nb2, nmix = self.nmix, pstep = self.pstep,
    legato = self.legato, ctr = self.ctr, camp = self.camp, mbase = self.mbase,
    atonic = self.atonic and 1 or 0, lhseed = self.lhseed, artbase = self.artbase,
    octs = self.octs, replift = self.replift, arcamp = self.arcamp,
    db = self.db, dd = self.dd, dc = self.dc, pc = self.pc, pd = self.pd,
    m1 = self.motif[1], m2 = self.motif[2], m3 = self.motif[3],
    marc = self.marc,
  }
end

function G:load_state(t)
  if type(t) ~= "table" or t.v ~= 1 or not t.m1 then return false end
  self.root, self.bo, self.infl = t.root, t.bo, t.infl
  self:set_meter(t.bl)
  self.bps, self.hr, self.nsec, self.apxpos = t.bps, t.hr, t.nsec, t.apxpos
  self.form, self.prog, self.pstyle = t.form, t.prog, t.pstyle
  self.cof, self.vamp = t.cof, t.vamp
  self.rstyle, self.rrot, self.na = t.rstyle, t.rrot, t.na
  self.nb2, self.nmix, self.pstep = t.nb2, t.nmix, t.pstep
  self.legato, self.ctr, self.camp = t.legato, t.ctr, t.camp
  self.marc = t.marc or 3
  self.mbase, self.atonic = t.mbase, t.atonic == 1
  self.lhseed, self.artbase = t.lhseed, t.artbase
  self.octs = t.octs or {0, 0, 0}
  self.replift, self.arcamp = t.replift or 0, t.arcamp or 0
  self:plan_registers()
  self.db, self.dd, self.dc = t.db or 0, t.dd or 0, t.dc or 0
  if t.pc and t.pc.n then self.pc = t.pc end
  if t.pd and t.pd.n then self.pd = t.pd end
  self.tb, self.td, self.tc = self.db, self.dd, self.dc
  self.motif[1], self.motif[2] = t.m1, t.m2
  self.motif[3] = t.m3 or t.m2
  self:derive()
  self:update_scale()
  self:update_lut()
  self.lastb = self.db
  self.cbase = self.p.centre + self.bn * 3 + 4
  self.pn = clamp(floor(self.cbase), self.split, self.hi)
  self.li, self.seqleft = 0, 0
  self.lastdeg, self.lastsh, self.lastalt = -1, -1, -1
  self:reset()
  return true
end

function G:info()
  local b = floor(self.bcont + 0.5)
  if b > 3 then b = 3 elseif b < -5 then b = -5 end
  local k = b * 100 + self.infl
  if k ~= self.ikey then
    self.ikey = k
    self.iname = (T.MODE[b] or "?") .. T.INFL[self.infl + 1]
  end
  return T.PC[self.root + 1], self.iname, self.qual,
         self.lhon and self.lhpat.n or "solo"
end

return G
