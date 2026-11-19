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

`korry_lib.scad` holds the parameters and modules (included by the panel generator); `korry.scad` exports single parts:

```bash
openscad -D 'part="cap"' -o cap.stl korry/korry.scad
```

### Tuning
- `plunger_gap`: print caps at -0.1 / 0 / +0.1 and keep the one that clicks with no rattle.
- `sw_h`: plunger height of your tactile switch (default 6×6×7).
- `cap_clear`: cap-to-hole clearance.

### Legends
Spray the face dark, then laser-engrave the legend out of the paint.

## Panel generator (`panel/`)

Each sub-panel is one layout file (e.g. `panel/apu.scad`) listing its controls in front-view mm, origin at panel centre:

```
["korry",   x, y, "UPPER", "LOWER"]   square cap hole + holder locator ridge on the back
["toggle",  x, y]                      round hole, 6 mm bushing
["rotary",  x, y]                      round hole, 3/8" bushing
["encoder", x, y]                      round hole, M7 (EC11)
["label",   x, y, "TEXT", size?]       backlit text
["line",    x1, y1, x2, y2]            backlit line
```

plus `bosses` (PCB standoff positions, M3 heat-set inserts). Export everything with:

```bash
panel/export.sh apu
```

Output in `panel/out/apu/`:

| File | Use |
|---|---|
| `apu-skin.stl` + `apu-core.stl` + `apu-labels.stl` | one object, three parts, already face-down: skin grey, core black (blocks light bleed), labels white/natural (full-depth light pipes) |
| `apu-single.stl` | whole panel as one body (for the paint + laser method, set `label_mode = "laser"`) |
| `apu-labels_svg.svg` | panel labels for laser engraving |
| `apu-cap_legends_svg.svg` + `apu-cap_jig.stl` | Korry legends for the laser, and a jig holding the caps at the same pitch |
| `apu-pcb_dxf.dxf` | PCB outline, mounting holes, cut-outs for panel-mount parts (KiCad Edge.Cuts) |
| `apu-placements.csv` | switch / LED / backlight / mounting-hole positions for the PCB |
| `apu-preview.png`, `apu-back.png` | renders |

`label_mode`: `through` (default, backlit), `inlay` (white text, not backlit), `laser` (no text in the print).

The APU layout is a **draft**: panel size, positions and legends still need confirming against references.

## Electronics (planned)
MobiFlight: 74HC165 for inputs, 74HC595 with one resistor per LED for annunciators, Fenix variables from HubHop presets.

Status: v0, not yet printed.
