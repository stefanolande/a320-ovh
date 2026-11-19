// Parametric DIY Korry-style pushbutton
//   1 x 6x6 mm THT tactile switch (centre)
//   2 x 3 mm THT LEDs (upper zone / lower zone)
//   printed holder (sits on PCB) + printed cap (slides through panel hole)
//
// Stack, z = 0 at PCB top surface:
//   PCB -> holder (light chambers, switch collar) -> panel back
//   cap flange is trapped between holder sleeve and panel back,
//   tactile switch dome pushes the cap back up.
//
// Render one part at a time:  openscad -D 'part="cap"' -o cap.stl korry.scad
// part = "cap" | "cap_face" | "holder" | "coupon" | "assembly" | "exploded"

part = "exploded";

include <korry_lib.scad>

if (part == "cap") cap();
else if (part == "cap_face") cap_face();
else if (part == "holder") holder();
else if (part == "coupon") coupon();
else if (part == "assembly") assembly();
else if (part == "exploded") exploded();
