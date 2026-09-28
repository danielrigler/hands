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

## install

```
;install https://github.com/danielrigler/hands
```

The script checks for updates on launch and offers to pull them.