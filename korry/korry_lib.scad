// Korry library: parameters + modules. Include from korry.scad or panel files.

/* ---------- parameters you will tune ---------- */
cap_w        = 18.0;   // visible cap face, square
cap_clear    = 0.15;   // per side, cap <-> panel hole
protrude     = 2.0;    // cap face above panel front at rest
panel_t      = 3.0;    // front panel thickness
face_t       = 1.2;    // translucent face (print in white/natural)
wall         = 1.0;    // cap skirt wall
flange       = 0.8;    // flange width beyond skirt (stops cap)
flange_t     = 1.0;
divider_t    = 1.2;

sw_body      = 6.0;    // tactile switch body (square)
sw_body_h    = 3.5;    // body height above PCB
sw_h         = 7.0;    // plunger top above PCB (buy 6x6x7)
sw_travel    = 0.25;   // datasheet travel
plunger_gap  = 0.0;    // + = gap at rest (rattle), - = preload. Print -0.1/0/+0.1 and pick

led_d        = 3.0;
led_flange_d = 3.9;
led_y        = 6.35;   // 2.5 x 0.1" from centre -> perfboard friendly
diffuse_gap  = 6.0;    // min distance LED top -> face underside (even glow)
led_h        = 5.3;    // 3 mm LED height above PCB

holder_base  = 1.0;
holder_wall  = 1.2;
fit          = 0.2;    // generic sliding clearance

$fn = 48;

/* ---------- derived ---------- */
skirt_w   = cap_w;                       // skirt = face size, passes through panel hole
flange_w  = cap_w + 2*flange;
hole_w    = cap_w + 2*cap_clear;         // panel hole
sleeve_in = flange_w + 2*fit;
holder_w  = sleeve_in + 2*holder_wall;

face_under = max(led_h + diffuse_gap, 0);  // z of face underside at rest
cap_top    = face_under + face_t;
panel_front= cap_top - protrude;
panel_back = panel_front - panel_t;        // == holder height == flange top at rest
cap_bottom = panel_back - flange_t;        // skirt / flange bottom
piston_w   = sw_body - 0.6;                // presses plunger, runs inside collar
piston_bot = sw_h + plunger_gap;
collar_in  = sw_body + 2*fit;
collar_out = collar_in + 2*0.8;          // 2 perimeters @ 0.4 nozzle
collar_top = piston_bot + 0.6;             // piston dips 0.6 into collar = light labyrinth
holder_div_top = min(piston_bot, cap_bottom) - sw_travel - 0.4; // below cap skirt + divider when pressed
notch_z    = collar_top + sw_travel + 0.4; // divider relief above collar

assert(holder_div_top > led_h - 2, "holder divider too low to separate LEDs - raise diffuse_gap");
assert(notch_z < face_under - 1, "divider relief reaches the face - raise diffuse_gap");
assert(led_y - led_flange_d/2 > collar_out/2 + 0.2, "LED collides with switch collar");
assert(led_y + led_flange_d/2 < sleeve_in/2, "LED outside chamber");

echo(str("panel hole = ", hole_w, " mm square"));
echo(str("holder / standoff height (PCB top -> panel back) = ", panel_back, " mm"));
echo(str("cap total height = ", cap_top - cap_bottom, " mm"));

module sq(w, h, z=0) translate([-w/2, -w/2, z]) cube([w, w, h]);

/* ---------- CAP (print face-down: face in white/natural, rest black) ---------- */
module cap() {
    difference() {
        union() {
            sq(skirt_w, face_under - cap_bottom, cap_bottom); // skirt (face is separate body)
            sq(flange_w, flange_t, cap_bottom);              // flange
        }
        sq(skirt_w - 2*wall, face_under - cap_bottom + 0.01, cap_bottom - 0.01);
    }
    // divider (black) splits upper / lower legend zones
    difference() {
        translate([-skirt_w/2 + 0.01, -divider_t/2, piston_bot])
            cube([skirt_w - 0.02, divider_t, face_under - piston_bot + 0.01]);
        // relief over the switch collar
        translate([-collar_out/2 - 0.5, -divider_t, piston_bot - 0.1])
            cube([collar_out + 1, 2*divider_t, notch_z - piston_bot + 0.1]);
    }
    // piston: presses the plunger, nests in collar to block light crossing over
    sq(piston_w, face_under - piston_bot + 0.01, piston_bot);
}

/* ---------- FACE ONLY (separate body for AMS colour assignment) ---------- */
module cap_face() sq(skirt_w, face_t, face_under);

/* ---------- HOLDER (print black, sits on PCB) ---------- */
module holder() {
    difference() {
        union() {
            // sleeve
            difference() {
                sq(holder_w, panel_back);
                sq(sleeve_in, panel_back + 1, holder_base);
            }
            // switch collar
            sq(collar_out, collar_top);
            // horizontal light divider either side of the collar
            for (s = [-1, 1])
                translate([s > 0 ? collar_out/2 - 0.01 : -sleeve_in/2, -divider_t/2, 0])
                    cube([sleeve_in/2 - collar_out/2 + 0.01, divider_t, holder_div_top]);
        }
        // switch pocket (through)
        sq(collar_in, collar_top + 1, -0.5);
        // LED holes (flange sits on PCB)
        for (s = [-1, 1]) translate([0, s*led_y, -0.5]) cylinder(d = led_flange_d + fit, h = holder_base + 1);
    }
}

/* ---------- PANEL TEST COUPON (one hole, check fit + legend look) ---------- */
module coupon() {
    w = holder_w + 16;
    difference() {
        translate([-w/2, -w/2, panel_back]) cube([w, w, panel_t]);
        sq(hole_w, panel_t + 2, panel_back - 1);
    }
    // locating ridge for the holder on the panel back
    difference() {
        sq(holder_w + 2*1.2 + 2*fit, 1.5, panel_back - 1.5);
        sq(holder_w + 2*fit, 2, panel_back - 1.6);
    }
}

module pcb() color("darkgreen") translate([-15, -15, -1.6]) cube([30, 30, 1.6]);
module parts() {
    pcb();
    color("dimgray") sq(sw_body, sw_body_h);
    color("black") translate([0,0,sw_body_h]) cylinder(d = 3.5, h = sw_h - sw_body_h);
    color("orange") translate([0,  led_y, 0]) cylinder(d = led_d, h = led_h);
    color("white")  translate([0, -led_y, 0]) cylinder(d = led_d, h = led_h);
}
module assembly() {
    parts();
    color([0.15,0.15,0.15]) holder();
    color([0.1,0.1,0.1]) cap();
    color([0.95,0.95,0.9]) cap_face();
    color([0.45,0.5,0.55]) coupon();
}


module exploded() {
    parts();
    color([0.2,0.2,0.2]) translate([0,0,6]) holder();
    color([0.1,0.1,0.1]) translate([0,0,14]) cap();
    color([0.95,0.92,0.8]) translate([0,0,14]) cap_face();
    color([0.45,0.5,0.58]) translate([0,0,26]) coupon();
}
