# hands

A generative MIDI player for monome norns. It writes melody, harmony and
accompaniment and sends them out to whatever you have plugged in.
Free-running by default, and it can follow the norns clock instead.

It has three engines. **classic** is a two-hands piano player. **ambient** is a
chord engine. Slowly evolving, voice-led chord pads on up to four voices, with an optional floating melody on top. **loops** is a set of phasing tape loops. Hold K1 and turn E1 to switch.

<img src="https://raw.githubusercontent.com/danielrigler/hands/refs/heads/main/screenshot.png">

## controls

| | |
|---|---|
| E1 | page |
| K1 + E1 | engine: classic / ambient / loops |
| E2, E3 | the two dials on the current page |
| K2 | vary (nudge the current piece) |
| K3 | new piece |
| K1 + K2 | run / stop |
| K1 + K3 | randomize all |

The keys do the same job in every engine. Holding K1 shows what E1, K2 and
K3 will do, and every action flashes the same short confirmation on screen:
`vary`, `new piece`, `randomize`, `run`, `stop`, `classic`, `ambient`, `loops`.

All engines share one screen layout: key and mode top left, the current
chord and its roman numeral top right (`stop` when the sequence is not
running), the music in the middle, a position strip under it, and the two
dials for the current page at the bottom. Each engine remembers its own page.

## classic

The screen shows a scrolling roll of what both hands have played and the
position in the bar.

All three engines share the same page skeleton, so the common controls are
always in the same place: page 1 is **key** and **mode**, page 2 the
engine's main character (style, or the form of the piece), page 3 **pace**
(step when clock-locked) with that engine's timing feel, page 4
**register** with its spread, then the engine's own pages, a **change** page
(what makes the piece evolve on its own) second to last, and a **level**
page with velocity last.

| page | E2 | E3 |
|---|---|---|
| tone | key | mode |
| style | style | intensity |
| time | pace | swing |
| range | register | width |
| hands | left hand | right hand |
| flow | motion | space |
| beat | syncopation | repeat |
| touch | note length | pedal |
| feel | rubato | humanize |
| colour | harmony | tension |
| change | drift | stray |
| level | velocity | balance |

Everything is also in the parameter menu, along with MIDI device, channels,
polyphony and CC64 output.

## what the dials do

- **style** presets the whole feel. Selecting one overwrites the other
  parameters and starts a new piece in that style at the next bar (metre,
  form, harmony and left-hand patterns come from the style), so treat it as a
  starting point you can then shape with the other dials.

  | | |
  |---|---|
  | `free` | no preset; everything is whatever you left it at |
  | `invention` | dry two-part counterpoint, circle-of-fifths motion |
  | `sonatina` | classical, alberti bass, brisk |
  | `nocturne` | slow, pedalled, broken chords, heavy rubato |
  | `reverie` | 3/4, planing lydian ninths, no functional pull |
  | `swing` | swung jazz over major ii-V-I changes with applied dominants, walking bass with chromatic approach notes, Charleston comping, a mostly single-note line on swung eighths |
  | `minimal` | fast interlocking ostinati, almost no harmonic motion |
  | `ballad` | slow jazz ballad, swung eighths, shells, rubato |
  | `groove` | syncopated minor, stabs and pulses |
  | `etude` | fast running arpeggios in minor |
  | `waltz` | oom-pah-pah in 3/4, plain triads |
  | `chorale` | slow block harmony, sustained, a singing top line |
  | `blues` | slow 12-bar shuffle (AAB phrasing): dominant sevenths under a minor-blues melody with blue notes, walking bass, comping and the odd boogie chorus |
  | `toccata` | relentless and dry, both hands running |
  | `parlour` | slow minor vamp under a spare, rubato melody |
  | `ragtime` | stride left hand, syncopated right hand, circle-of-dominants changes, AABB form |
  | `boogie` | 12-bar boogie-woogie, rolling eighth-note bass ostinato, shuffle |
  | `bossa` | bossa nova: root-fifth bass and syncopated comping under ii-V sevenths and ninths |
  | `latin` | montuno vamps, tumbao bass anticipations, very syncopated |
  | `tango` | harmonic minor, habanera bass, staccato touch with rubato |
  | `gospel` | plagal and I-vi-ii-V changes, big chords, octave bass, shuffle |
  | `film` | modern neoclassical: pop-loop progressions under slow broken chords, lots of pedal |
  | `lofi` | swung sixteenths, dorian sevenths and ninths, lazy shells |
  | `still` | slow 3/4: bass on the downbeat, a held chord on beat two, alternating major sevenths |
  | `lullaby` | gentle 3/4 over simple I-IV-V, rocking broken chords, a songlike tune |

  The jazz, blues, boogie and gospel styles swing the eighth notes; **swing**
  swings sixteenths in the other styles. Styles with a fixed chord loop (the
  12-bar forms, the pop loops of `film`, the vamps) keep that loop when you
  press K2 and pick another loop of the same kind instead of a random
  progression, and their form is kept too.
- **register** sets where the two hands sit, roughly the point where they
  meet; the melody sits about half an octave above it.
- **width** opens the whole texture out around that point, in both directions.
- **left hand** walks an ordered ladder of accompaniment patterns, from
  sustained held chords at the bottom, through bass and comping figures and
  broken chords, up to running arpeggios. At zero the left hand is silent.
  The dial shows the pattern currently playing rather than a percentage; each
  section of the form gets a different one from around the same point on the
  ladder, so the setting picks a character and still gives you variety.
  With a style selected the ladder is that style's own set of left-hand
  patterns, lightest first (for `swing`: shells, Charleston comping, walking
  bass), so the dial always stays inside the idiom.
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
- **balance** leans the dynamics between the hands: turned up the left hand
  plays louder and the right hand a little softer, turned down the reverse.
  At 0% it is the natural balance.
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

## ambient

The ambient engine generates a whole chord progression up front, loops it, and
plays it as sustained pads. K3 makes a new piece, K2 varies it while keeping
the structure (one chord, or one chord of a repeated phrase everywhere it
recurs, or a fresh colour on a chord or two), K1+K3 randomizes the ambient
settings.

The screen shows the loop the way SpaceWalk does: one line per voice stepping
from chord to chord, the playhead, a strip of chord blocks along the bottom
(brighter ones are the surprise chords) and the melody notes above. Longer
loops are shown sixteen chords at a time.

As in classic, brightness follows velocity: each pad line is lit by how hard
that voice was played (voice levels, chord-to-chord swells and **natural**
all show), with the current chord lifted a little so you can find it, and a
muted voice drawn as a faint trace. Chords not yet reached on this pass show
their expected velocity.

The melody for a whole pass of the loop is written at the start of the pass,
so it is all on screen at once, shaded by velocity, with the note currently
sounding at full brightness. Changing the progression or the **melody** dial
rewrites the rest of the pass from the next chord on; a new piece rewrites
all of it.

| page | E2 | E3 |
|---|---|---|
| tone | key | mode |
| form | length | bars per chord |
| time | pace | deviation |
| range | register | sparseness |
| colour | richness | suspension |
| motion | flow | smoothness |
| melody | melody | natural |
| change | evolve | surprise |
| level | pad velocity | melody velocity |

- **key** is shared with the classic engine. `free` picks a new key with every
  new piece.
- **mode** from bright to dark: lydian, ionian, mixolydian, dorian, aeolian,
  phrygian, plus harmonic minor, melodic minor and locrian. Each mode leans on
  its characteristic chords (the II in lydian, bVII in mixolydian, IV in
  dorian, bII in phrygian and so on). Changing it re-harmonises the same
  progression from the next chord on.
- **length** is the loop in bars, **bars per chord** how long each chord lasts
  (1/2 to 8 bars). Longer loops are built from phrases that repeat and vary,
  not one long random walk.
- **richness**: triads, 7ths, 9ths, lush (11ths and 13ths). In between the
  four positions chords mix the neighbouring levels. Tensions that would
  clash (a minor ninth above a chord tone) are left out.
- **suspension**: none, light, medium, heavy. Replaces the third with a sus2
  or sus4 where the mode allows a clean one.
- **sparseness**: full, medium, light, open. Thins the upper voices from four
  down to two (the third or sus and the most colourful tension survive
  longest) and spreads them wider.
- **register** sets where the pads sit; the bass is about two octaves below.
- **flow**: steps, gentle, moving, jumps. Low values pick chords that share
  tones and move by small steps, high values favour bigger contrasts and let
  the voicing leap. Changing it rebuilds the progression at the next chord.
- **surprise** swaps some chords for borrowed ones from the neighbouring
  modes and, above about a third, chromatic mediants (a major chord a third
  away). Each chord has its own threshold, so turning it up adds surprises
  one by one and turning it down takes the same ones away.
- **smoothness** runs from -50% to +50%. Negative releases each chord early
  so reverb and release tails have room; positive lets it ring into the next.
  Notes that two chords share are always held through, never re-struck.
- **natural** is the human side: chords arrive slightly spread or rolled, per
  voice velocity varies, dynamics swell from chord to chord, the bass takes
  an inversion when that makes it move by step, and the voicing is re-chosen
  a little differently on every pass of the loop.
- **deviation** stretches and shrinks individual chords so they do not all
  last exactly the same time. The loop length stays about the same.
- **pace** is the ambient engine's own tempo, separate from the classic pace, so
  switching engines keeps each one at its own speed.
- **melody** adds a sparse top line above the pads on the melody channel: short
  phrases that land on chord tones and sometimes repeat the rhythm and shape
  of the last one. At zero there is no melody. The melody is kept in tune
  with the pads: it only uses chord tones and tensions that sit cleanly over
  the chord (never a semitone against a note the pads are holding), a note
  that would ring into a chord it does not fit is shortened to end at the
  change, and if the harmony changes under a held note (a key or mode change,
  a variation, a new piece) the note is released as the new chord arrives.
- **evolve** is the chance of a variation at the end of every loop, so the
  progression slowly changes by itself. At zero it loops unchanged.

In the ambient Music group there are also **allow dim/aug** (off by default,
so diminished and augmented chords are replaced by a neighbour) and **start
on root**.

The **Voices** group routes the engine to your synths:

| | |
|---|---|
| melody channel | MIDI channel for the melody line |
| bass / tenor / alto / soprano channel | MIDI channel for that pad voice |
| bass / tenor / alto / soprano level | that voice's velocity as a share of **pad velocity**; 0% mutes it |

Every channel defaults to `main`, which follows **channel** in the Output
group, so out of the box everything plays on one channel. The voices are the
pad notes sorted low to high: bass is the lowest note, soprano the highest,
tenor the one above the bass, and alto whatever sits between tenor and
soprano (with four upper notes, two of them share the alto channel; with
only two upper notes there is no alto).

The parameter menu follows the engine and only shows the groups for the one
that is selected: classic has **Music** and **Feel** (plus left hand channel
and CC64 under Output), ambient has **Music** and **Voices**, loops has
**Music**. **engine** and **key** sit at the top of the menu since every
engine uses them.

## loops

A handful of short phrases, each on its own loop of a different length, all
drawing on one shared set of pitches. Because the lengths do not divide into
each other the loops drift in and out of phase, so the same few notes keep
meeting in new combinations and the whole never quite repeats. Every loop
starts together on a new piece and then slides apart.

The screen gives each loop a lane, lowest voice at the bottom. A lane is
that loop's whole cycle, left to right, with its own playhead, so you watch
the playheads run at different speeds. Notes are shaded by velocity and swell
and turn bright while they sound. The strip underneath is the twelve pitch
classes starting from the key: the pool is lit (its root brighter), notes
sounding now are brightest, and a faint mark means a loop is still holding a
note from before the last harmony change. Top right is the pool's centre
chord.

| page | E2 | E3 |
|---|---|---|
| tone | key | mode |
| form | loops | notes |
| time | pace | natural |
| range | register | width |
| length | length | spread |
| colour | tones | shift |
| space | space | sustain |
| echo | echo | time |
| change | drift | swell |
| level | velocity | channels |

- **loops** is how many run at once, 1 to 8. Adding one brings in a fresh
  loop; removing takes the top one away.
- **notes** is the average phrase length per loop, 1 to 5 notes.
- **length** is the base loop length in beats and **spread** how far the loops
  differ from it (up to about two and a half times longer). The lowest loop
  is the longest. At zero spread they all share one length and lock into a
  single repeating pattern; turned up, lengths are chosen to share almost no common
  factors so the phasing takes as long as possible to come round.
- **register** is the centre and **width** the range the loops fan out over,
  lowest loop at the bottom.
- **tones** is the size of the pitch pool, 3 to 7, filled in order of
  consonance from the centre chord: root, fifth, third, ninth, sixth, fourth,
  seventh. 3 is a bare triad, 5 a pentatonic haze, 7 the whole mode.
- **shift** is how often the harmony moves: the pool re-centres on a related
  chord (a fourth, fifth or third away, and back home again). Nothing jumps:
  each loop only moves its notes into the new pool when it comes round, so a
  change of harmony spreads through the piece one loop at a time, and the
  lowest loop steps onto its new root or fifth. **key**, **mode** and **tones** changes
  arrive the same way.
- **space** is how much of each loop is silence and **sustain** how long the
  notes hold.
- **drift** is the chance that a loop changes a little each time it comes
  round: a note moves up or down the pool, nudges in time, is added or
  dropped, the loop borrows the shape of another loop's phrase, or its length
  shifts by a step so it slides against the others.
- **swell** gives each loop a slow volume cycle over several passes, so
  voices fade in and out on their own; near the top they fall silent for
  part of the cycle.
- **echo** adds decaying repeats of each note, **time** their spacing.
- **natural** loosens timing and velocity.
- **channels** spreads the loops over that many MIDI channels counting up
  from the main one (loop 1 on the main channel, loop 2 on the next, and so
  on, wrapping round), so each voice can go to its own synth.

Notes a semitone apart are never started together across loops, so the
pool can be large without the result turning into a cluster. **notes**,
**space**, **sustain**, **length** and **spread** also take effect loop by
loop as each one comes round.

## presets

Saving a PSET from the norns menu stores every parameter, including which
engine is active, plus the generated material in a `.piece` file next to it:
the classic engine's motifs, form, chord progression and registers, the
ambient engine's progression, chord colours, timing and voicings, and every
loop with its length and notes. Loading it brings back all three engines exactly as they were when saved and restarts from
the top of the piece, whichever engine was playing before.

What plays after that is still generative. The classic engine renders each bar
from the saved material with its usual variation, and in ambient mode the
melody is improvised live, **natural** re-voices each pass of the loop and
**evolve** (and **drift** in classic and loops, **shift** in loops) keep changing things as they run. Set those
to zero if you want a loaded preset to stay put.

## clock

Out of the box the script keeps its own tempo, set by **pace** on the time page, and ignores the norns transport. Set **tempo** in the Clock parameter
group to `norns clock` and it instead locks to the norns tempo, following
whatever clock source is selected in the system parameters, including MIDI
and Link. **pace** is then ignored in every engine: the page that holds it
shows the clock tempo with a `syn` marker, and its dial switches to **step**
so it still does something useful.

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