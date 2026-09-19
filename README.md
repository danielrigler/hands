# hands

A two-hands piano player for monome norns. It generates melody and
accompaniment as MIDI and sends them out to whatever you have plugged in.
Free-running by default, and it can follow the norns clock instead.

<img src="https://raw.githubusercontent.com/danielrigler/hands/refs/heads/main/screenshot.png">

## controls

| | |
|---|---|
| E1 | page |
| E2, E3 | the two dials on the current page |
| K2 | vary (nudge the current piece) |
| K3 | new piece |
| K1 + K2 | run / stop |
| K1 + K3 | randomize all |

Holding K1 shows what K2 and K3 will do, and each of the four actions
flashes a short confirmation on screen.

The screen shows key and mode top left, the current chord top right, a
scrolling roll of what both hands have played, the position in the bar, and
the two dials for the current page.

## pages

| page | E2 | E3 |
|---|---|---|
| style | style | pace |
| time | swing | humanize |
| flow | motion | space |
| beat | syncopation | repeat |
| touch | note length | pedal |
| tone | mode | register |
| hands | left hand | right hand |
| feel | rubato | tension |
| shift | harmony | drift |

Everything is also in the parameter menu, along with MIDI device, channels,
polyphony, velocity and CC64 output.

## what the dials do

- **style** presets the whole feel. Selecting one overwrites the other
  parameters, so treat it as a starting point rather than a mode.

  | | |
  |---|---|
  | `free` | no preset; everything is whatever you left it at |
  | `invention` | dry two-part counterpoint, circle-of-fifths motion |
  | `sonatina` | classical, alberti bass, brisk |
  | `nocturne` | slow, pedalled, broken chords, heavy rubato |
  | `reverie` | 3/4, planing lydian ninths, no functional pull |
  | `swing` | medium swung jazz over ii-V-I changes |
  | `minimal` | fast interlocking ostinati, almost no harmonic motion |
  | `ambient` | very slow, sustained, drifting |
  | `ballad` | slow swing, spacious, rubato |
  | `groove` | syncopated minor, stabs and pulses |
  | `etude` | fast running arpeggios in minor |
  | `waltz` | oom-pah-pah in 3/4, plain triads |
  | `chorale` | slow block harmony, sustained, a singing top line |
  | `blues` | mixolydian with the blue notes, shells and comping |
  | `toccata` | relentless and dry, both hands running |
  | `parlour` | slow minor vamp under a spare, rubato melody |
- **motion** and **space** set how much happens and how much room is left
  between events. They pull against each other.
- **repeat** holds onto bars. At the top of the range a bar will repeat
  outright; low down, every bar is freshly generated.
- **tension** loosens the pull toward chord tones and raises the chance of
  chromatic and appoggiatura notes.
- **harmony** controls chord richness, from bare triads and dyads up to
  added-note and extended voicings, and rebuilds the progression when moved.
- **left hand** goes from a single held bass through blocked and broken
  patterns to running arpeggios. At zero the left hand is silent.
- **right hand** trades songlike phrasing for busier, more ornamented playing.
- **drift** lets mode, density and register wander slowly on their own.

## clock

Out of the box the script keeps its own tempo, set by **pace** on the style
page, and ignores the norns transport. Set **tempo** in the Clock parameter
group to `norns clock` and it instead locks to the norns tempo, following
whatever clock source is selected in the system parameters, including MIDI
and Link. **pace** is then ignored and the style page shows the clock tempo
with a `syn` marker.

**step** sets how long one step of the sequence is in note values, default
`1/16`. A bar is 16 steps (12 in the 3/4 styles), so at `1/16` a bar is one
4/4 measure. Swing still works while locked: steps land on the grid and the
off-steps are pushed late by hand.

**follow transport** starts and stops the script with the external transport,
restarting the piece from the top of its form on each start. Turn it off to
stay locked to the tempo while keeping K1+K2 as the only start/stop.

Tempo changes are picked up live. A change of more than a couple of percent
also re-derives the generator, since how much fits in a bar depends on how
long a bar is.

## install

```
;install https://github.com/dddstudio/hands
```

The script checks for updates on launch and offers to pull them if the
working tree is clean.
