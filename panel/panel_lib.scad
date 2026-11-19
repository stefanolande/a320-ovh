// Panel generator library.
// A layout file sets the variables below, then calls panel_dispatch().
//
// Coordinates: front view, mm, origin at panel centre, x right, y up.
// z: PCB top = 0, panel back = korry panel_back, panel front = panel_back + panel_t.
//
// Layout elements:
//   ["korry",   x, y, "UPPER", "LOWER"]     square cap hole + holder locator ridge
//   ["toggle",  x, y]                      round hole for a panel-mount mini toggle
//   ["rotary",  x, y]                      round hole for a panel-mount rotary switch
//   ["encoder", x, y]                      round hole for an EC11-style encoder
//   ["label",   x, y, "TEXT", size?]       backlit panel text (size optional)
//   ["line",    x1, y1, x2, y2]            backlit line (group brackets etc.)
//
// Bodies (export each, load as one multi-part object in Bambu Studio):
//   label_mode = "through": skin (grey) + core (black) + labels (white/natural, full depth = light pipes)
//   label_mode = "inlay":   skin (grey) + core (grey or black) + labels (white, top inlay only, not backlit)
//   label_mode = "laser":   one body, print natural, paint grey, engrave labels.svg

include <../korry/korry_lib.scad>

/* ---------- defaults a layout may override ---------- */
panel_w      = 120;
panel_h      = 75;
label_mode   = "through";
skin_t       = 0.6;          // grey front skin
inlay_t      = 0.6;
font         = "Liberation Sans:style=Bold";   // try "B612:style=Bold" if installed
label_size   = 3.2;          // OpenSCAD text size (cap height is ~0.72 x this)
line_w       = 0.6;
corner_r     = 1.5;

toggle_hole  = 6.3;          // 6 mm / M6 bushing
rotary_hole  = 9.7;          // 3/8" bushing
encoder_hole = 7.3;          // M7 bushing (EC11)

// PCB clearance cut-outs for panel-mount parts (their bodies pass through the PCB)
toggle_cut   = [11, 15];
rotary_cut_d = 27;
encoder_cut  = [14, 14];

ridge_t      = 1.2;          // holder locator ridge
ridge_h      = 1.5;

boss_d       = 7.5;
insert_d     = 4.0;          // M3 heat-set insert hole
insert_depth = 5.5;
pcb_hole_d   = 3.2;
pcb_inset    = 1.0;          // PCB edge inside panel edge

dzus         = true;         // corner fixing holes to screw the panel to the frame
dzus_d       = 3.4;
dzus_inset   = 5;

$fn = 48;

/* ---------- helpers ---------- */
// panel_front comes from korry_lib (= panel_back + panel_t)
holder_ridge_w = holder_w + 2*fit;

function el_size(e) = len(e) > 4 && e[4] != undef ? e[4] : label_size;

module rrect(w, h, r) offset(r) offset(-r) square([w, h], center = true);

module labels_2d(layout) {
    for (e = layout) {
        if (e[0] == "label")
            translate([e[1], e[2]]) text(e[3], size = el_size(e), font = font,
                                         halign = "center", valign = "center");
        if (e[0] == "line")
            hull() {
                translate([e[1], e[2]]) circle(d = line_w, $fn = 12);
                translate([e[3], e[4]]) circle(d = line_w, $fn = 12);
            }
    }
}

module holes_2d(layout) {
    for (e = layout) translate([e[1], e[2]]) {
        if (e[0] == "korry")   square(hole_w, center = true);
        if (e[0] == "toggle")  circle(d = toggle_hole);
        if (e[0] == "rotary")  circle(d = rotary_hole);
        if (e[0] == "encoder") circle(d = encoder_hole);
    }
    if (dzus)
        for (x = [-1, 1], y = [-1, 1])
            translate([x*(panel_w/2 - dzus_inset), y*(panel_h/2 - dzus_inset)]) circle(d = dzus_d);
}

module plate_2d(layout) difference() { rrect(panel_w, panel_h, corner_r); holes_2d(layout); }

/* ---------- 3D bodies, assembly position ---------- */
module labels_3d(layout) {
    depth = label_mode == "through" ? panel_t : inlay_t;
    translate([0, 0, panel_front - depth]) linear_extrude(depth) labels_2d(layout);
}

module skin(layout)
    difference() {
        translate([0, 0, panel_front - skin_t]) linear_extrude(skin_t) plate_2d(layout);
        if (label_mode != "laser") labels_3d(layout);
    }

module core(layout, bosses) {
    difference() {
        union() {
            translate([0, 0, panel_back]) linear_extrude(panel_t - skin_t) plate_2d(layout);
            // holder locator ridges
            for (e = layout) if (e[0] == "korry") translate([e[1], e[2], panel_back - ridge_h])
                linear_extrude(ridge_h + 0.01) difference() {
                    square(holder_ridge_w + 2*ridge_t, center = true);
                    square(holder_ridge_w, center = true);
                }
            // PCB standoff bosses
            for (b = bosses) translate([b[0], b[1], 0]) cylinder(d = boss_d, h = panel_back + 0.01);
        }
        if (label_mode != "laser") labels_3d(layout);
        for (b = bosses) translate([b[0], b[1], -0.01]) cylinder(d = insert_d, h = insert_depth);
    }
}

module panel_single(layout, bosses) { skin(layout); core(layout, bosses); }

/* ---------- PCB outline (DXF for KiCad Edge.Cuts) ---------- */
module pcb_2d(layout, bosses)
    difference() {
        square([panel_w - 2*pcb_inset, panel_h - 2*pcb_inset], center = true);
        for (b = bosses) translate(b) circle(d = pcb_hole_d);
        for (e = layout) translate([e[1], e[2]]) {
            if (e[0] == "toggle")  square(toggle_cut, center = true);
            if (e[0] == "rotary")  circle(d = rotary_cut_d);
            if (e[0] == "encoder") square(encoder_cut, center = true);
        }
    }

/* ---------- cap legends for the laser + matching jig ---------- */
cap_pitch = 24;
function korrys(layout) = [for (e = layout) if (e[0] == "korry") e];

module cap_legends_2d(layout, outline = true) {
    k = korrys(layout);
    for (i = [0 : len(k) - 1]) translate([i*cap_pitch, 0]) {
        if (outline) difference() { square(cap_w, center = true); square(cap_w - 0.2, center = true); }
        translate([0,  cap_w/4]) text(k[i][3], size = 2.6, font = font, halign = "center", valign = "center");
        translate([0, -cap_w/4]) text(k[i][4], size = 2.6, font = font, halign = "center", valign = "center");
    }
}

// holds caps face-up at the same pitch as cap_legends.svg (faces stand 1 mm proud)
module cap_jig(layout) {
    n = len(korrys(layout));
    cap_h = cap_top - cap_bottom;
    t = cap_h;                      // jig thickness
    w = (n - 1)*cap_pitch + cap_w + 12;
    difference() {
        translate([-cap_w/2 - 6, -cap_w/2 - 6, 0]) cube([w, cap_w + 12, t]);
        for (i = [0 : n - 1]) translate([i*cap_pitch, 0, 1])
            linear_extrude(t) square(flange_w + 0.4, center = true);
    }
}

/* ---------- placement list for the PCB (parse ECHO lines) ---------- */
module report(layout, bosses) {
    k = korrys(layout);
    for (i = [0 : len(k) - 1]) {
        e = k[i];
        echo(str("PLACE,SW", i+1, ",tactile_6x6,", e[1], ",", e[2], ",", e[3], "/", e[4]));
        echo(str("PLACE,D", 2*i+1, ",led_3mm_upper,", e[1], ",", e[2] + led_y, ",", e[3]));
        echo(str("PLACE,D", 2*i+2, ",led_3mm_lower,", e[1], ",", e[2] - led_y, ",", e[4]));
    }
    for (e = layout) if (e[0] == "label")
        echo(str("PLACE,BL,label_backlight,", e[1], ",", e[2], ",", e[3]));
    for (e = layout) if (e[0] == "toggle" || e[0] == "rotary" || e[0] == "encoder")
        echo(str("PLACE,PANEL,", e[0], ",", e[1], ",", e[2], ","));
    for (b = bosses) echo(str("PLACE,H,mount_M3,", b[0], ",", b[1], ","));
    echo(str("PCB_TO_PANEL_BACK,", panel_back));
}

/* ---------- preview ---------- */
module preview(layout, bosses) {
    color([0.42, 0.48, 0.55]) skin(layout);
    color([0.12, 0.12, 0.12]) core(layout, bosses);
    if (label_mode != "laser") color([0.97, 0.95, 0.85]) labels_3d(layout);
    for (e = korrys(layout)) translate([e[1], e[2], 0]) {
        color([0.1, 0.1, 0.1]) cap();
        color([0.95, 0.95, 0.9]) cap_face();
    }
}

/* print orientation: face down on the plate */
module face_down() translate([0, 0, panel_front]) rotate([180, 0, 0]) children();

module panel_dispatch(part, layout, bosses) {
    report(layout, bosses);
    if (part == "preview") preview(layout, bosses);
    else if (part == "skin")   face_down() skin(layout);
    else if (part == "core")   face_down() core(layout, bosses);
    else if (part == "labels") face_down() labels_3d(layout);
    else if (part == "single") face_down() panel_single(layout, bosses);
    else if (part == "labels_svg") labels_2d(layout);
    else if (part == "pcb_dxf") pcb_2d(layout, bosses);
    else if (part == "cap_legends_svg") cap_legends_2d(layout);
    else if (part == "cap_jig") cap_jig(layout);
}
