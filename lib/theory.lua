local T = {}

local floor, random = math.floor, math.random

T.PC = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}
T.FLAT_ORDER = {4,7,3,6,2,5}
T.SHARP_ORDER = {5,2}
T.DEG_W = {0.81,0.68,0.90,0.51,1.00,0.37,0.22}
T.ROMAN = {"I","II","III","IV","V","VI","VII"}
T.R12 = {"I","bII","II","bIII","III","IV","#IV","V","bVI","VI","bVII","VII"}

T.MODE = {}
T.MODE[3] = "lyd#2#5"
T.MODE[2] = "lyd aug"
T.MODE[1] = "lydian"
T.MODE[0] = "ionian"
T.MODE[-1] = "mixolyd"
T.MODE[-2] = "dorian"
T.MODE[-3] = "aeolian"
T.MODE[-4] = "phrygian"
T.MODE[-5] = "locrian"
T.MODE[-6] = "altered"

T.INFL = {"", " harm", " blue", " #11", " 6"}

function T.mode_label(b)
  local m = floor(b + 0.5)
  if m > 3 then m = 3 elseif m < -6 then m = -6 end
  return T.MODE[m] or "?"
end

function T.scale_for(b, s)
  s[1],s[2],s[3],s[4],s[5],s[6],s[7] = 0,2,4,6,7,9,11
  local steps = 1 - b
  local w = floor(steps + 0.5)
  local f = steps - w
  if w < 0 then
    local n = -w
    if n > 2 then n = 2 end
    for i = 1, n do local d = T.SHARP_ORDER[i]; s[d] = s[d] + 1 end
    return 0, 0, 0
  end
  if w > 6 then w = 6; f = 0 end
  for i = 1, w do local d = T.FLAT_ORDER[i]; s[d] = s[d] - 1 end
  if f > 0.02 and w < 6 then return T.FLAT_ORDER[w+1], f, -1 end
  if f < -0.02 and w > 0 then return T.FLAT_ORDER[w], -f, 1 end
  return 0, 0, 0
end

function T.metric(bl, out)
  local nb = bl // 4
  for i = 0, bl - 1 do
    local u, b = i % 4, i // 4
    local w
    if i == 0 then w = 5
    elseif u == 0 then w = (nb == 4 and b == 2) and 4 or 3
    elseif u == 2 then w = 2
    else w = 1 end
    out[i+1] = w
  end
  return out
end

function T.euclid(k, n, rot, out)
  if k < 1 then k = 1 elseif k > n then k = n end
  for i = 0, n-1 do
    local j = (i + rot) % n
    out[i+1] = ((j * k) % n) < k and 1 or 0
  end
  return out
end

T.NODES = {
  {1,.10,.40,.15,.70,.12,.45,.20,.85,.10,.40,.18,.65,.14,.50,.30},
  {1,.15,.35,.60,.20,.50,.75,.15,.40,.25,.80,.20,.55,.30,.45,.70},
  {1,.05,.20,.08,.30,.10,.75,.40,.90,.06,.25,.50,.35,.12,.60,.45},
  {1,.48,.58,.44,.54,.50,.60,.44,.70,.48,.58,.44,.54,.50,.64,.52},
  {1,.08,.15,.70,.12,.65,.20,.55,.35,.10,.60,.25,.75,.15,.30,.80},
  {1,.30,.72,.10,.22,.68,.14,.30,.78,.12,.26,.70,.16,.34,.62,.20},
}

T.SHAPES = {
  {b = 0.00, o = {0,2,4}},
  {b = 0.18, o = {0,2,4,6}},
  {b = 0.40, o = {0,2,4,6,8}},
  {b = 0.08, o = {0,3,4}},
  {b = 0.32, o = {0,1,4}},
  {b = 0.62, o = {0,3,6,9}},
  {b = 0.50, o = {0,2,4,5}},
  {b = -0.12, o = {0,2,6}},
  {b = 0.46, o = {0,2,4,8}},
  {b = -0.30, o = {0,4}},
  {b = 0.70, o = {0,4,8,10}},
  {b = -0.55, o = {0,1,2,4}},
  {b = -0.20, o = {0,2,4,6,10}},
  {b = 0.24, o = {0,4,9}},
}

for i = 1, #T.SHAPES do T.SHAPES[i].n = #T.SHAPES[i].o end

T.CLASSIC = {
  {0.05,0.15,0.05,0.25,0.30,0.18,0.02},
  {0.03,0.10,0.01,0.06,0.60,0.03,0.17},
  {0.05,0.05,0.10,0.35,0.10,0.33,0.02},
  {0.18,0.18,0.02,0.10,0.45,0.02,0.05},
  {0.60,0.03,0.03,0.06,0.10,0.16,0.02},
  {0.05,0.30,0.05,0.25,0.25,0.08,0.02},
  {0.75,0.02,0.05,0.02,0.10,0.04,0.02},
}

T.COFPOS = {2,4,6,1,3,5,7}
T.FREQ = {0.33,0.06,0.05,0.23,0.17,0.13,0.03}

T.TEND = {}
T.TEND[7] = {1, 4.0}
T.TEND[4] = {3, 3.0}
T.TEND[6] = {5, 2.4}
T.TEND[2] = {1, 1.5}

T.OCTS = {0,12,-12,12,7,5,-5,12,-12,4}

T.SNAMES = {"free", "invention", "sonatina", "nocturne", "reverie", "swing",
            "minimal", "ballad", "groove", "etude",
            "waltz", "chorale", "blues", "toccata", "parlour",
            "ragtime", "boogie", "bossa", "latin", "tango", "gospel",
            "film", "lofi", "still", "lullaby"}

T.BLUES = {{0,0,0,0,3,3,0,0,4,3,0,4}, {0,3,0,0,3,3,0,0,4,3,0,4}, {0,3,0,0,3,3,0,0,4,4,0,4}}

T.STYLE = {
  {bl=16, bps=4, hr=1, ps=2, oct=0.4, mb=0, at=0,
   sh={1,2,8}, lh={1,4,9,12,14}, inf={0},
   d={pace=96, motion=0.85, space=0.08, syn=0.05, rep=0.5, len=0.75, swing=0,
      pedal=0.12, hum=0.15, rubato=0.05, harm=0.75, left=0.72, right=0.5,
      mode=0, drift=0.05, tens=0.30, rngw=40, stray=0.05}},
  {bl=16, bps=4, hr=1, ps=1, oct=0.6, mb=0, at=0,
   sh={1,2}, lh={1,4,6,5,8,12}, inf={0},
   d={pace=126, motion=0.7, space=0.22, syn=0.05, rep=0.62, len=0.5, swing=0,
      pedal=0.32, hum=0.18, rubato=0.12, harm=1.0, left=0.75, right=0.38,
      mode=0, drift=0.08, tens=0.28, rngw=46, stray=0.06}},
  {bl=16, bps=4, hr=1, ps=1, oct=1.0, at=0,
   sh={1,2,3,9}, lh={2,7,6,9,12}, inf={0,1},
   d={pace=64, motion=0.55, space=0.3, syn=0.1, rep=0.4, len=0.85, swing=0,
      pedal=0.92, hum=0.3, rubato=0.8, harm=0.6, left=0.66, right=0.62,
      mode=-2, drift=0.25, tens=0.55, rngw=62, stray=0.16}},
  {bl=12, bps=4, hr=2, ps=6, oct=0.8,
   sh={3,6,11,13,7}, lh={2,7,6,9,13}, inf={3,4},
   d={pace=58, motion=0.45, space=0.38, syn=0.04, rep=0.62, len=0.95, swing=0,
      pedal=1.0, hum=0.16, rubato=0.45, harm=0.06, left=0.42, right=0.3,
      mode=1, drift=0.22, tens=0.2, rngw=54, stray=0.1}},
  {bl=16, bps=4, hr=1, ps=7, oct=0.5, s8=true,
   sh={2,3,8,13}, lh={17,26,19}, inf={0,2}, tx=0.14,
   d={pace=132, motion=0.72, space=0.2, syn=0.4, rep=0.5, len=0.6, swing=0.62,
      pedal=0.2, hum=0.22, rubato=0.1, harm=0.72, left=0.8, right=0.5,
      mode=0, drift=0.1, tens=0.5, rngw=46, stray=0.22}},
  {bl=16, bps=4, hr=4, ps=3, oct=0.3, mb=0, at=0,
   sh={1,2,10}, lh={1,16,10,14,12,13}, inf={0},
   d={pace=126, motion=0.9, space=0.05, syn=0.15, rep=0.95, len=0.45, swing=0,
      pedal=0.35, hum=0.06, rubato=0, harm=0.12, left=0.5, right=0.14,
      mode=0, drift=0.04, tens=0.12, rngw=44, stray=0.02}},
  {bl=16, bps=4, hr=1, ps=7, oct=0.4, s8=true,
   sh={2,3,13,8}, lh={7,17,26,19}, inf={0,2}, tx=0.3,
   d={pace=64, motion=0.42, space=0.4, syn=0.25, rep=0.8, len=0.8, swing=0.5,
      pedal=0.7, hum=0.3, rubato=0.7, harm=0.55, left=0.4, right=0.35,
      mode=0, drift=0.12, tens=0.5, rngw=46, stray=0.2}},
  {bl=16, bps=4, hr=2, ps=3, oct=0.4, mb=0,
   sh={2,3,13}, lh={1,16,11,10,14}, inf={0},
   d={pace=123, motion=0.75, space=0.22, syn=0.65, rep=0.85, len=0.35, swing=0.08,
      pedal=0.3, hum=0.15, rubato=0.06, harm=0.28, left=0.6, right=0.3,
      mode=-3, drift=0.05, tens=0.30, rngw=46, stray=0.18}},
  {bl=16, bps=4, hr=2, ps=1, oct=0.5, mb=0, at=0,
   sh={1,2,10}, lh={1,7,10,8,12,13}, inf={0},
   d={pace=104, motion=0.95, space=0.05, syn=0.1, rep=0.9, len=0.3, swing=0,
      pedal=0.28, hum=0.04, rubato=0, harm=0.5, left=0.92, right=0.28,
      mode=-3, drift=0.04, tens=0.20, rngw=48, stray=0.08}},
  {bl=12, bps=4, hr=1, ps=1, oct=0.5, mb=0, at=0,
   sh={1,2,8}, lh={2,6,5,8,12}, inf={0},
   d={pace=150, motion=0.7, space=0.15, syn=0.02, rep=0.55, len=0.6, swing=0,
      pedal=0.5, hum=0.14, rubato=0.18, harm=0.85, left=0.35, right=0.4,
      mode=0, drift=0.06, tens=0.25, rngw=44, stray=0.06}},
  {bl=16, bps=4, hr=1, ps=7, oct=0.2, mb=0, at=0,
   sh={1,2,7}, lh={1,2,17,9,12}, inf={0},
   d={pace=52, motion=0.22, space=0.18, syn=0, rep=0.45, len=1.0, swing=0,
      pedal=0.55, hum=0.12, rubato=0.25, harm=1.0, left=0.3, right=0.15,
      mode=0, drift=0.04, tens=0.15, rngw=50, stray=0.02}},
  {bl=16, bps=4, hr=1, ps=8, ns=3, fm={1,1,2}, oct=0.3, mb=0, at=0, s8=true, lp=T.BLUES, dom=true,
   sh={2,8,13}, lh={17,26,19,20}, inf={2}, tx=0.22,
   d={pace=88, motion=0.62, space=0.25, syn=0.35, rep=0.75, len=0.6, swing=0.65,
      pedal=0.2, hum=0.25, rubato=0.2, harm=0.45, left=0.6, right=0.45,
      mode=-2, drift=0.08, tens=0.55, rngw=46, stray=0.3}},
  {bl=16, bps=4, hr=2, ps=2, oct=0.7, mb=0, at=0,
   sh={1,2,10}, lh={1,7,10,14,12,13}, inf={0,1},
   d={pace=168, motion=1.0, space=0.02, syn=0.08, rep=0.85, len=0.25, swing=0,
      pedal=0.12, hum=0.05, rubato=0, harm=0.6, left=0.88, right=0.35,
      mode=-3, drift=0.03, tens=0.35, rngw=52, stray=0.1}},
  {bl=16, bps=4, hr=1, ps=3, oct=0.3,
   sh={2,3,9,13}, lh={2,4,5,8,12}, inf={1,2},
   d={pace=70, motion=0.35, space=0.42, syn=0.05, rep=0.62, len=0.85, swing=0,
      pedal=0.7, hum=0.2, rubato=0.6, harm=0.12, left=0.4, right=0.22,
      mode=-3, drift=0.12, tens=0.35, rngw=48, stray=0.12}},
  {bl=16, bps=4, hr=2, ps=8, fm={1,1,2,2}, oct=0.4, mb=0, at=0,
   lp={{0,0,4,4}, {0,5,1,4}, {0,3,0,4}, {0,0,1,4}, {3,0,1,4}},
   sh={1,7,2}, lh={5,18}, inf={0},
   d={pace=92, motion=0.8, space=0.08, syn=0.55, rep=0.7, len=0.45, swing=0,
      pedal=0.2, hum=0.1, rubato=0.05, harm=0.85, left=0.7, right=0.45,
      mode=0, drift=0.05, tens=0.35, rngw=52, stray=0.22}},
  {bl=16, bps=4, hr=1, ps=8, ns=3, fm={1,1,2}, oct=0.3, mb=0, at=0, s8=true, lp=T.BLUES, dom=true,
   sh={2,7,1}, lh={19,20}, inf={2}, tx=0.3,
   d={pace=138, motion=0.72, space=0.12, syn=0.35, rep=0.82, len=0.4, swing=0.6,
      pedal=0.1, hum=0.12, rubato=0, harm=0.35, left=0.9, right=0.55,
      mode=-2, drift=0.03, tens=0.5, rngw=50, stray=0.3}},
  {bl=16, bps=4, hr=2, ps=8, oct=0.3, mb=0,
   lp={{1,4,0,0}, {0,0,1,4}, {1,4,2,5}, {0,5,1,4}, {3,3,2,5}},
   sh={2,3,13,9}, lh={15,21}, inf={0,3},
   d={pace=128, motion=0.55, space=0.35, syn=0.6, rep=0.75, len=0.55, swing=0,
      pedal=0.15, hum=0.14, rubato=0.05, harm=0.5, left=0.62, right=0.3,
      mode=0, drift=0.06, tens=0.5, rngw=44, stray=0.1}},
  {bl=16, bps=4, hr=1, ps=8, oct=0.3, mb=0, at=0,
   lp={{0,3,4,3}, {0,4,0,4}, {0,3,0,4}, {5,1,4,0}},
   sh={1,2}, lh={16,24}, inf={0},
   d={pace=104, motion=0.9, space=0.05, syn=0.75, rep=0.92, len=0.35, swing=0,
      pedal=0.05, hum=0.06, rubato=0, harm=0.2, left=0.72, right=0.3,
      mode=0, drift=0.03, tens=0.25, rngw=46, stray=0.05}},
  {bl=16, bps=4, hr=2, ps=8, oct=0.5, mb=0, at=0,
   lp={{0,0,4,4}, {0,3,4,0}, {0,5,4,0}, {3,0,4,0}},
   sh={1,2}, lh={16,22}, inf={1},
   d={pace=112, motion=0.6, space=0.2, syn=0.45, rep=0.65, len=0.3, swing=0,
      pedal=0.1, hum=0.15, rubato=0.45, harm=0.4, left=0.62, right=0.45,
      mode=-3, drift=0.08, tens=0.55, rngw=50, stray=0.2}},
  {bl=16, bps=4, hr=1, ps=8, oct=0.4, mb=0, s8=true,
   lp={{0,3,0,4}, {0,5,1,4}, {3,0,4,0}, {0,3,5,4}, {0,0,3,3}},
   sh={2,7,3,13}, lh={17,23,19}, inf={2,0},
   d={pace=72, motion=0.6, space=0.25, syn=0.35, rep=0.7, len=0.65, swing=0.55,
      pedal=0.6, hum=0.22, rubato=0.3, harm=0.95, left=0.6, right=0.35,
      mode=0, drift=0.08, tens=0.5, rngw=50, stray=0.3}},
  {bl=16, bps=4, hr=1, ps=8, oct=0.6, mb=0,
   lp={{0,4,5,3}, {5,3,0,4}, {0,5,3,4}, {5,4,3,4}, {0,2,5,3}},
   sh={1,9,5,14}, lh={8,9,12}, inf={0},
   d={pace=76, motion=0.55, space=0.3, syn=0.05, rep=0.78, len=0.9, swing=0,
      pedal=0.95, hum=0.2, rubato=0.45, harm=0.25, left=0.66, right=0.2,
      mode=-3, drift=0.15, tens=0.2, rngw=54, stray=0.02}},
  {bl=16, bps=4, hr=2, ps=8, oct=0.3, mb=0,
   lp={{1,4,0,5}, {3,2,1,0}, {0,5,1,4}, {3,4,2,5}},
   sh={2,3,13,8}, lh={17,15,19}, inf={0,3},
   d={pace=78, motion=0.55, space=0.35, syn=0.45, rep=0.8, len=0.5, swing=0.4,
      pedal=0.4, hum=0.4, rubato=0.2, harm=0.6, left=0.5, right=0.3,
      mode=-2, drift=0.1, tens=0.55, rngw=44, stray=0.15}},
  {bl=12, bps=4, hr=1, ps=8, oct=0.3, mb=0, at=0,
   lp={{0,3}, {3,0}, {0,3,0,3,5,3,1,4}},
   sh={2}, lh={2,25}, inf={0},
   d={pace=70, motion=0.2, space=0.5, syn=0, rep=0.7, len=1.0, swing=0,
      pedal=0.85, hum=0.2, rubato=0.5, harm=0.1, left=0.7, right=0.1,
      mode=0, drift=0.12, tens=0.45, rngw=56, stray=0.03}},
  {bl=12, bps=4, hr=1, ps=8, oct=0.3, mb=0, at=0,
   lp={{0,3,0,4}, {0,4,0,4}, {0,5,3,4}, {0,3,4,0}},
   sh={1,9}, lh={6,8,9}, inf={0},
   d={pace=66, motion=0.35, space=0.35, syn=0, rep=0.8, len=0.85, swing=0,
      pedal=0.8, hum=0.2, rubato=0.4, harm=0.1, left=0.5, right=0.05,
      mode=0, drift=0.05, tens=0.15, rngw=44, stray=0}},
}
T.HSTEP = {1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,2,-2,2,-3}
T.MSTEP = {1,-1,1,-1,1,-1,2,-2,1,-1,2,-2,3,-3,4,-4}
T.TP = {-2,2,-1,1,3,-3,4,-4}
T.DISP = {-2,2,1,-1,-4,4}

T.LH = {
  {n = "hold",    a = 0, f = function(s,b,u,nb) return s == 0 and -1 or 0 end},
  {n = "pedal",   a = 0, f = function(s,b,u,nb) return s == 0 and 1 or 0 end},
  {n = "swell",   a = 0, f = function(s,b,u,nb) if u ~= 0 then return 0 end return b == 0 and -2 or 0 end},
  {n = "bass",    a = 1, f = function(s,b,u,nb)
      if u ~= 0 then return 0 end
      if b == 0 then return 1 elseif nb == 4 and b == 2 then return 2 end
      return 0 end},
  {n = "oompah",  a = 1, f = function(s,b,u,nb)
      if u ~= 0 then return 0 end
      return b % 2 == 0 and 1 or -1 end},
  {n = "waltz",   a = 1, f = function(s,b,u,nb)
      if u ~= 0 then return 0 end
      return b == 0 and 1 or -1 end},
  {n = "roll",    a = 1, f = function(s,b,u,nb)
      if u ~= 0 then return 0 end
      return (b == 0 or (nb == 4 and b == 2)) and -2 or 0 end},
  {n = "alberti", a = 2, f = function(s,b,u,nb)
      if u % 2 ~= 0 then return 0 end
      local i = (s // 2) % 4
      return (i == 0 and 1) or (i == 1 and 4) or (i == 2 and 2) or 4 end},
  {n = "broken",  a = 2, f = function(s,b,u,nb)
      if u % 2 ~= 0 then return 0 end
      return ((s // 2) % 4) + 1 end},
  {n = "ostin",   a = 2, f = function(s,b,u,nb)
      if u % 2 ~= 0 then return 0 end
      local i = (s // 2) % 4
      return (i == 0 and 1) or (i == 1 and 3) or (i == 2 and 2) or 3 end},
  {n = "pulse",   a = 2, f = function(s,b,u,nb) return u == 0 and -1 or 0 end},
  {n = "arp",     a = 3, f = function(s,b,u,nb)
      local k = s % 6
      return k < 4 and k + 1 or 7 - k end},
  {n = "cascade", a = 3, f = function(s,b,u,nb)
      local k = s % 8
      return k < 5 and k + 1 or 9 - k end},
  {n = "rush",    a = 3, f = function(s,b,u,nb) return s % 3 + 1 end},
  {n = "comp",    a = 1, f = function(s,b,u,nb)
      local k = s % 8
      return (k == 3 or k == 6) and -1 or 0 end},
  {n = "stab",    a = 1, f = function(s,b,u,nb)
      return (s % 4 == 2) and -1 or 0 end},
  {n = "shell",   a = 1, f = function(s,b,u,nb)
      if s % 8 == 0 then return 1 end
      return (s % 8 == 5) and -1 or 0 end},
  {n = "stride", keep = true, a = 1, f = function(s,b,u,nb)
      if u ~= 0 then return 0 end
      if b % 2 == 1 then return -3 end
      return b == 0 and 200 or 204 end},
  {n = "walk", keep = true, a = 1, f = function(s,b,u,nb)
      if u ~= 0 then return 0 end
      if b == 0 then return 200 end
      if b == nb - 1 then return random() < 0.75 and 250 or ({205, 206, 203})[random(3)] end
      if b == 1 then return ({201, 202, 202, 204})[random(4)] end
      return ({204, 204, 202, 205})[random(4)] end},
  {n = "boogie", keep = true, a = 3, f = function(s,b,u,nb)
      if u % 2 ~= 0 then return 0 end
      return 200 + ({0,2,4,5,6,5,4,2})[(s // 2) % 8 + 1] end},
  {n = "bossa", keep = true, a = 2, f = function(s,b,u,nb)
      local k = s % 16
      if k == 0 then return 200 elseif k == 8 then return 204 end
      return (k == 3 or k == 6 or k == 10 or k == 13) and -1 or 0 end},
  {n = "haban", keep = true, a = 2, f = function(s,b,u,nb)
      local k = s % 8
      if k == 0 then return 200 elseif k == 3 or k == 6 then return 204 end
      return k == 4 and 202 or 0 end},
  {n = "gospel",  a = 1, f = function(s,b,u,nb)
      local k = s % 16
      if k == 0 then return 200 elseif k == 8 then return 204 end
      return (k == 6 or k == 14) and -3 or 0 end},
  {n = "tumbao", keep = true, a = 1, f = function(s,b,u,nb)
      local k = s % 16
      if k == 6 then return 204 elseif k == 12 then return 200 end
      return (k == 3 or k == 10) and -1 or 0 end},
  {n = "sara",    a = 0, f = function(s,b,u,nb)
      if u ~= 0 then return 0 end
      if b == 0 then return 1 end
      return b == 1 and -3 or 0 end},
  {n = "charl",   a = 1, f = function(s,b,u,nb)
      local k = s % 16
      if k == 0 then return 1 end
      return (k == 6 or k == 14) and -1 or 0 end},
}

T.LADDER = {1, 2, 3, 25, 4, 19, 7, 17, 26, 15, 23, 16, 24, 22, 21, 6, 5, 18, 11, 10, 20, 9, 8, 14, 12, 13}
T.LPOS = {}
for i = 1, #T.LADDER do T.LPOS[T.LADDER[i]] = i end

T.LHA = {{}, {}, {}, {}}
for i = 1, #T.LH do
  local a = T.LH[i].a
  if a >= 0 then local g = T.LHA[a + 1]; g[#g+1] = i end
end

function T.contour(k, t)
  if k == 1 then return math.sin(3.14159265 * t)
  elseif k == 2 then return 1 - 2*t
  elseif k == 3 then return 2*t - 1
  elseif k == 4 then local u = t < 0.5 and t*2 or (1-t)*2; return u*u*1.2 - 0.4
  elseif k == 5 then return -math.sin(3.14159265 * t)
  elseif k == 6 then return math.sin(6.2831853 * t) * 0.7
  end
  return 0
end

function T.pink(n)
  local s = {n = n, c = 0, t = 0}
  for i = 1, n do s[i] = random(); s.t = s.t + s[i] end
  return s
end

function T.pnext(s)
  local n = s.n
  s.c = s.c + 1
  local k, x = 1, s.c
  while x % 2 == 0 and k < n do x = x // 2; k = k + 1 end
  s.t = s.t - s[k]
  s[k] = random()
  s.t = s.t + s[k]
  return (s.t + random()) / (n + 1) * 2 - 1
end

function T.wpick(w, n)
  local tot = 0
  for i = 1, n do tot = tot + w[i] end
  if tot <= 0 then return random(n) end
  local r = random() * tot
  for i = 1, n do
    r = r - w[i]
    if r <= 0 then return i end
  end
  return n
end

return T
