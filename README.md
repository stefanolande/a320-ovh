# A320 mini overhead panel

DIY overhead panel for the Fenix A320 (MSFS), built with a Bambu Lab A1 + AMS and a 5 W diode laser.
No hand-cut holes: every square opening is printed.

## Korry pushbutton (`korry/`)

Parametric OpenSCAD model: one 6×6 mm tactile switch, two 3 mm LEDs (upper / lower legend), a printed holder and a printed cap.

| File | Print |
|---|---|
| `cap.stl` + `cap_face.stl` | one object, two parts, face down: face natural/white, body black |
| `holder.stl` | black, sits on the PCB |
| `coupon.stl` | panel test piece with one hole |

Key numbers (defaults): cap 18 mm, panel hole 18.3 mm, PCB-to-panel-back 7.5 mm, LEDs at ±6.35 mm (0.1" grid).

Export a part:

```bash
openscad -D 'part="cap"' -o cap.stl korry/korry.scad
```

### Tuning
- `plunger_gap`: print caps at -0.1 / 0 / +0.1 and keep the one that clicks with no rattle.
- `sw_h`: plunger height of your tactile switch (default 6×6×7).
- `cap_clear`: cap-to-hole clearance.

### Legends
Spray the face dark, then laser-engrave the legend out of the paint.

## Electronics (planned)
MobiFlight: 74HC165 for inputs, 74HC595 with one resistor per LED for annunciators, Fenix variables from HubHop presets.

Status: v0, not yet printed.
