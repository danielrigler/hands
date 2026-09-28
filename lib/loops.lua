local L = {}
L.__index = L

local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local random, cos = math.random, math.cos
local TAU = 6.2831853

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

local function gcd(a, b)
  while b > 0 do a, b = b, a % b end
  return a
end

local CONS = {0, 4, 2, 1, 5, 3, 6}
local R12 = {"I","bII","II","bIII","III","IV","#IV","V","bVI","VI","bVII","VII"}
local PCN = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}

L.ET = {2, 3, 4, 6, 8, 12, 16}
L.ETN = {"1/8", "3/16", "1/4", "3/8", "1/2", "3/4", "1"}

local function newloop()
  return {ul = random(), uk = random(), us = random(), uo = random(), uc = random(3),
          per = 2 + random() * 5, ph = random() * TAU, notes = {}, pos = 0, cyc = 0,
          len = 64, vph = -1, vln = -1}
end

function L.new(q, cb, modes)
  local o = setmetatable({q = q, cb = cb, modes = modes}, L)
  o.root, o.centre = 0, 0
  o.pool, o.lp, o.snd, o.tl = {}, {}, {}, {}
  o.gs, o.ss = 0, 0.25
  o.vph, o.vln = 0, 0
  o.pend, o.dn = false, false
  o:newp(true)
  return o
end

function L:scale() return self.modes[self.q.mode].s end

function L:mkpool()
  local s, pool = self:scale(), self.pool
  for i = 0, 11 do pool[i] = nil end
  for j = 1, self.q.tones do
    local d = (self.centre + CONS[j]) % 7
    local pc = (self.root + s[d + 1]) % 12
    if not pool[pc] then pool[pc] = j end
  end
end

function L:band(i)
  local q, n = self.q, #self.lp
  if n <= 1 then return q.reg end
  return floor(q.reg - q.width * 0.5 + q.width * (i - 1) / (n - 1) + 0.5)
end

function L:lens()
  local q, lp, out = self.q, self.lp, self.tl
  local n, B, sp = #self.lp, q.len * 4, q.spread
  local r = {}
  for i = 1, n do
    r[i] = 1 + sp * 1.5 * (((i - 1) * 0.618034 + 0.31) % 1) + sp * 0.12 * (lp[i].ul - 0.5)
  end
  table.sort(r, function(a, b) return a > b end)
  for i = 1, n do
    local x = max(4, floor(B * r[i] + 0.5))
    if sp > 0.04 then
      for _ = 1, 16 do
        local bad = false
        for j = 1, i - 1 do
          local y = out[j]
          if y == x or (x > 8 and gcd(x, y) > 2) then bad = true; break end
        end
        if not bad then break end
        x = x + 1
      end
    end
    out[i] = x
  end
  for i = #out, n + 1, -1 do out[i] = nil end
  return out
end

function L:near(n, dir)
  local pool = self.pool
  for d = 1, 12 do
    local x = n + d * dir
    if pool[x % 12] then return x end
  end
  return n
end

function L:snap(n)
  local pool = self.pool
  if pool[n % 12] then return n end
  for d = 1, 6 do
    if pool[(n - d) % 12] then return n - d end
    if pool[(n + d) % 12] then return n + d end
  end
  return n
end

function L:phrase(lp, i)
  local q = self.q
  local len = lp.len
  local k = clamp(floor(q.notes + (lp.uk - 0.5) * 1.6 + 0.5), 1, 6)
  local span = max(4, floor(len * (1 - q.space * 0.85) * (0.55 + 0.45 * lp.us)))
  local g = (span / k >= 8) and 4 or 2
  k = min(k, max(1, floor((len - 2) / g)))
  span = min(max(span, k * g), len)
  local cells = max(k, floor(span / g))
  local pick, cnt = {[0] = true}, 1
  while cnt < k do
    local c = random(cells) - 1
    if not pick[c] then pick[c] = true; cnt = cnt + 1 end
  end
  local off = floor(lp.uo * max(0, len - span) / 4) * 4
  local N = lp.notes
  for j = #N, 1, -1 do N[j] = nil end
  for c = 0, cells - 1 do
    if pick[c] then N[#N + 1] = {t = off + c * g, d = 1, n = 0, v = 1, on = -1, lv = 0} end
  end
  local sus = 0.35 + q.sus * 1.2
  for j = 1, #N do
    local x = N[j]
    local gap = (j < #N) and (N[j + 1].t - x.t) or (off + span - x.t + 8)
    local d = (j < #N) and gap * sus or min(gap * (0.4 + q.sus * 1.4), 8 + q.sus * 48)
    x.d = clamp(floor(d + 0.5), 1, max(1, len - 2))
  end
  local c = self:band(i)
  local x = self:snap(c)
  if i == 1 then
    local best, bd = x, 99
    for n = c - 6, c + 6 do
      local r = self.pool[n % 12]
      if r and r <= 2 and abs(n - c) < bd then best, bd = n, abs(n - c) end
    end
    x = best
  end
  local half = (#N + 1) * 0.5
  for j = 1, #N do
    local e = N[j]
    if j > 1 then
      local r = random()
      local st = r < 0.1 and 0 or (r < 0.72 and 1 or 2)
      local up
      if lp.uc == 1 then up = j <= half elseif lp.uc == 2 then up = false else up = true end
      if random() < 0.25 then up = not up end
      if x > c + 7 then up = false elseif x < c - 7 then up = true end
      for _ = 1, st do x = self:near(x, up and 1 or -1) end
    end
    e.n = x
    e.v = j == 1 and 1 or (0.72 + random() * 0.22)
  end
end

function L:fit(lp, i)
  local c = self:band(i)
  local pool = self.pool
  for j, x in ipairs(lp.notes) do
    local n = x.n
    while n > c + 10 do n = n - 12 end
    while n < c - 10 do n = n + 12 end
    n = self:snap(n)
    if i == 1 and j == 1 and #self.lp > 2 and pool[n % 12] > 2 then
      for d = 1, 5 do
        local r = pool[(n - d) % 12]
        if r and r <= 2 then n = n - d; break end
        r = pool[(n + d) % 12]
        if r and r <= 2 then n = n + d; break end
      end
    end
    x.n = n
  end
end

function L:rescale(lp, nl)
  local ol = lp.len
  lp.len = nl
  if ol == nl then return end
  local seen = {}
  for _, x in ipairs(lp.notes) do
    local t = min(nl - 1, floor(x.t * nl / ol + 0.5))
    while seen[t] and t < nl - 1 do t = t + 1 end
    seen[t] = true
    x.t = t
    if x.d > nl - 2 then x.d = max(1, nl - 2) end
  end
  if lp.pos >= nl then lp.pos = 0 end
end

function L:mutate(lp, i)
  local N = lp.notes
  if #N == 0 then return end
  local r = random()
  if r < 0.42 then
    local x = N[random(#N)]
    x.n = self:near(x.n, random() < 0.5 and 1 or -1)
  elseif r < 0.6 then
    local x = N[random(#N)]
    local nt = x.t + (random() < 0.5 and -2 or 2)
    local free = nt >= 0 and nt < lp.len
    for _, y in ipairs(N) do if y.t == nt then free = false end end
    if free then x.t = nt end
  elseif r < 0.72 and #N < 6 then
    local a = N[#N]
    local nt = a.t + 4
    if nt < lp.len - 2 then
      a.d = min(a.d, 4)
      N[#N + 1] = {t = nt, d = clamp(floor(4 + self.q.sus * 20), 1, lp.len - 2), n = self:near(a.n, random() < 0.5 and 1 or -1),
                   v = 0.72 + random() * 0.2, on = -1, lv = 0}
    end
  elseif r < 0.82 and #N > 1 then
    table.remove(N, random(2, #N))
  elseif r < 0.93 and #self.lp > 1 then
    local j = random(#self.lp - 1)
    if j >= i then j = j + 1 end
    local M = self.lp[j].notes
    if #M > 0 then
      local base, m0 = N[1].n, M[1].n
      for k = 2, #N do
        local s = M[(k - 1) % #M + 1]
        N[k].n = self:snap(base + s.n - m0)
      end
    end
  else
    self:rescale(lp, max(4, lp.len + (random() < 0.5 and -1 or 1) * random(2)))
  end
end

function L:wrap(lp, i)
  lp.cyc = lp.cyc + 1
  if lp.vln ~= self.vln then
    lp.vln = self.vln
    self:rescale(lp, self:lens()[i] or lp.len)
  end
  if lp.vph ~= self.vph then
    lp.vph = self.vph
    self:phrase(lp, i)
  end
  self:fit(lp, i)
  if random() < self.q.drift * 0.45 then self:mutate(lp, i) end
end

function L:build()
  local q, lp = self.q, self.lp
  self:mkpool()
  for i = #lp, 1, -1 do lp[i] = nil end
  for i = 1, q.n do lp[i] = newloop() end
  local ls = self:lens()
  for i = 1, #lp do
    local x = lp[i]
    x.len, x.vln, x.vph = ls[i], self.vln, self.vph
    self:phrase(x, i)
    self:fit(x, i)
  end
  for k in pairs(self.snd) do self.snd[k] = nil end
end

function L:fit_n()
  self.dn = false
  local lp, n = self.lp, self.q.n
  if #lp == n then return end
  while #lp > n do lp[#lp] = nil end
  while #lp < n do
    local x = newloop()
    lp[#lp + 1] = x
    x.len, x.vln, x.vph = self:lens()[#lp], self.vln, self.vph
    self:phrase(x, #lp)
    self:fit(x, #lp)
  end
  self.vln = self.vln + 1
end

function L:newp(now)
  local q = self.q
  self.root = q.rootlock and q.root or (random(12) - 1)
  self.centre = 0
  if now then self:build() else self.pend = true end
end

function L:vary()
  local lp = self.lp
  if #lp == 0 then return end
  for _ = 1, 3 do
    local i = random(#lp)
    self:mutate(lp[i], i)
  end
end

function L:set_root(r)
  self.root = r
  self:mkpool()
end

function L:shift()
  local q = self.q
  if q.shift < 0.01 or random() >= q.shift * q.shift * self.ss / 40 then return end
  local s = self:scale()
  local c = self.centre
  local nc
  if c ~= 0 and random() < 0.4 then nc = 0
  else
    for _ = 1, 6 do
      local x = (c + ({3, 4, 5, 2})[random(4)]) % 7
      if (s[(x + 4) % 7 + 1] - s[x + 1]) % 12 == 7 then nc = x; break end
    end
  end
  if nc and nc ~= c then self.centre = nc; self:mkpool() end
end

function L:swell(lp)
  local s = self.q.swell
  if s <= 0 then return 1 end
  local ph = (lp.cyc + lp.pos / lp.len) / lp.per * TAU + lp.ph
  return 1 - s * 0.9 * (0.5 - 0.5 * cos(ph))
end

function L:chan(i)
  local q = self.q
  return (q.ch - 1 + (i - 1) % q.chn) % 16 + 1
end

function L:play(lp, i, x)
  local q, cb, gs = self.q, self.cb, self.gs
  local sw = self:swell(lp)
  if sw < 0.28 then return end
  local n = x.n
  for _, s in ipairs(self.snd) do
    if s.i ~= i then
      local d = abs(n - s.n)
      if d == 1 or d == 13 then return end
    end
  end
  local v = clamp(floor(q.vel * x.v * sw * (1 + (random() - 0.5) * 0.3 * q.nat)), 1, 127)
  local ch = self:chan(i)
  cb.note({n = {n}, v = v, d = x.d, o = random() * q.nat * 0.4, h = 0, r = 1, c = ch})
  x.on, x.lv = gs + x.d, v
  self.snd[#self.snd + 1] = {n = n, e = gs + x.d, i = i}
  if q.echo > 0.02 then
    local fb, et = 0.3 + 0.45 * q.echo, q.et
    local vv = v
    for k = 1, floor(1 + q.echo * 3.2) do
      vv = vv * fb
      if vv < 5 then break end
      if random() < 0.85 then
        cb.note({n = {n}, v = floor(vv), d = max(1, x.d * 0.5), o = k * et + random() * q.nat * 0.2, h = 0, r = 1, c = ch})
      end
    end
  end
end

function L:tick(ss)
  self.ss = ss
  if self.pend then self.pend = false; self:build() end
  if self.dn then self:fit_n() end
  self:shift()
  local gs, snd = self.gs, self.snd
  local k = 0
  for j = 1, #snd do if snd[j].e > gs then k = k + 1; snd[k] = snd[j] end end
  for j = #snd, k + 1, -1 do snd[j] = nil end
  for i, lp in ipairs(self.lp) do
    for _, x in ipairs(lp.notes) do
      if x.t == lp.pos then self:play(lp, i, x) end
    end
    lp.pos = lp.pos + 1
    if lp.pos >= lp.len then lp.pos = 0; self:wrap(lp, i) end
  end
  self.gs = gs + 1
end

function L:reset()
  for _, lp in ipairs(self.lp) do lp.pos, lp.cyc = 0, 0 end
  for k in pairs(self.snd) do self.snd[k] = nil end
end

function L:info()
  local s = self:scale()
  local c = self.centre
  local rt = (self.root + s[c + 1]) % 12
  local r = R12[(rt - self.root) % 12 + 1]
  if (s[(c + 2) % 7 + 1] - s[c + 1]) % 12 == 3 then r = r:lower() end
  return PCN[self.root + 1], self.modes[self.q.mode].short, PCN[rt + 1] .. " " .. r
end

function L:save()
  local t = {root = self.root, centre = self.centre, lp = {}}
  for i, lp in ipairs(self.lp) do
    local N = {}
    for j, x in ipairs(lp.notes) do N[j] = {x.t, x.d, x.n, x.v} end
    t.lp[i] = {lp.len, lp.ul, lp.uk, lp.us, lp.uo, lp.uc, lp.per, lp.ph, N}
  end
  return t
end

function L:load(t)
  if type(t) ~= "table" or type(t.lp) ~= "table" or #t.lp == 0 then return false end
  self.root = self.q.rootlock and self.q.root or (t.root or 0)
  self.centre = t.centre or 0
  self:mkpool()
  local lp = self.lp
  for i = #lp, 1, -1 do lp[i] = nil end
  for i, r in ipairs(t.lp) do
    local x = newloop()
    x.len, x.ul, x.uk, x.us, x.uo, x.uc, x.per, x.ph = r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8]
    x.vln, x.vph = self.vln, self.vph
    for j, e in ipairs(r[9]) do x.notes[j] = {t = e[1], d = e[2], n = e[3], v = e[4], on = -1, lv = 0} end
    lp[i] = x
  end
  self.pend, self.dn = false, #lp ~= self.q.n
  self:reset()
  return true
end

return L
