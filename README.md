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

The screen shows key and mode top left, the current chord top right (`stop`
when the sequence is not running), a scrolling roll of what both hands have
played, the position in the bar, and the two dials for the current page.

## pages

| page | E2 | E3 |
|---|---|---|
| style | style | pace (step when clock-locked) |
| range | register | width |
| hands | left hand | right hand |
| drive | intensity | velocity |
| time | swing | humanize |
| flow | motion | space |
| beat | syncopation | repeat |
| touch | note length | pedal |
| tone | mode | stray |
| feel | rubato | tension |
| shift | harmony | drift |

Everything is also in the parameter menu, along with MIDI device, channels,
polyphony and CC64 output.

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
- **register** sets where the two hands sit, roughly the point where they
  meet; the melody sits about half an octave above it.
- **width** opens the whole texture out around that point, in both directions.
- **left hand** walks an ordered ladder of accompaniment patterns, from
  sustained held chords at the bottom, through bass and comping figures and
  broken chords, up to running arpeggios. At zero the left hand is silent.
  The dial shows the pattern currently playing rather than a percentage; each
  section of the form gets a different one from around the same point on the
  ladder, so the setting picks a character and still gives you variety.
- **right hand** trades songlike phrasing for busier, more ornamented playing.
- **intensity** is a macro over how hard the piece is being played. It leans on
  what the other dials derive rather than overwriting any of them, so 0.5 is
  neutral and a patch built without it sounds exactly as before. Turning it up
  raises the velocity level and widens the dynamic range, adds notes, cuts the
  rests, thickens the right hand toward octaves and chords, promotes the left
  hand to a fuller pattern, shortens the touch slightly toward marcato, and
  lifts the melody a little in register. Turning it down does the reverse. It
  is deliberately left out of Randomize and of the style presets, since it is a
  performance control rather than part of a piece's identity.
- **velocity** sets the base level everything else moves around.
- **motion** and **space** set how much happens and how much room is left
  between events. They pull against each other.
- **repeat** holds onto bars. At the top of the range a bar will repeat
  outright; low down, every bar is freshly generated. It also sets how
  literally a section follows its motif.
- **note length** and **pedal** set the touch. Sustained melody notes overlap
  the next one slightly, the way a finger holds through a legato line, scaled
  by note length.
- **tension** loosens the pull toward chord tones, so the melody spends more
  time on passing and appoggiatura notes inside the scale.
- **stray** controls how often the melody reaches outside the scale of its own
  accord. At zero the right hand is diatonic except where **harmony** has put an
  applied dominant under it. Above it you get leading-tone approaches and
  chromatic lower neighbours, and every one of them resolves by step. The left
  hand is always diatonic.
- **harmony** controls chord richness, from bare triads and dyads up to
  added-note and extended voicings, and rebuilds the progression when moved.
  It also sets how often the right hand thickens out of a single line into
  octaves, thirds and sixths, or block chords under the melody. Above about two
  thirds of the way up it turns diatonic chords that already stand a fifth above
  the chord they move to into applied dominants, by raising their third a
  semitone. That raised note is a leading tone and always resolves up into the
  root of the next chord. This is the one source of out-of-scale notes that is
  not **stray**.
- **drift** lets the piece move on its own. Low down it wanders mode, density
  and register. Higher up it also renews melodic material at the end of each
  pass through the form: one of the three motifs is replaced, and less often
  the contour, the form itself or the chord progression. At zero the piece is
  a fixed loop and only changes when you press K2 or K3.

## how it plays

The right hand is modelled as a hand rather than a stream of pitches. Five
fingers sit over a position on the keys; moving out of that position costs
real time, so a wide leap is only taken when there is room for it, and a
scale run leaves its position by passing the thumb under. The thumb avoids
black keys where it can. Which finger lands on a note colours how it sounds:
the fourth finger is weaker than the others, a note after a hand shift arrives
slightly late and slightly firmer, and a shift or a repeated finger breaks
legato the way it would under a real hand.

Melodies are built as shapes, not note by note. Each bar gets a skeleton tone
picked to connect to the last one by good voice leading, the space between
is filled with passing tones, neighbours and arpeggiation, and whole bars are
searched and scored as complete lines, on contour, a single clear high point,
interval variety and where the line leaves off for the next bar. Phrases arch
toward a peak and descend into cadences that resolve.

The left hand voices chords with inversions rather than root position
throughout, choosing the bass note that keeps the bass line moving by step
where it can. The melody leads the accompaniment by twenty-odd milliseconds,
which is what pianists actually do. With CC64 enabled the pedal is held
through a chord change and lifted just after it, so harmonies join rather than
being clipped at the barline.

## clock

Out of the box the script keeps its own tempo, set by **pace** on the style
page, and ignores the norns transport. Set **tempo** in the Clock parameter
group to `norns clock` and it instead locks to the norns tempo, following
whatever clock source is selected in the system parameters, including MIDI
and Link. **pace** is then ignored and the style page shows the clock tempo
with a `syn` marker, and E3 on that page switches to **step** so the dial
still does something useful.

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
;install https://github.com/danielrigler/hands
```

The script checks for updates on launch and offers to pull them.