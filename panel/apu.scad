// APU panel - DRAFT layout, confirm each control against references.
// Export everything:  ./export.sh apu

part = "preview";

include <panel_lib.scad>

panel_w = 120;
panel_h = 75;

layout = [
    ["label",   0,  30, "APU", 4.0],
    ["line",  -50,  30, -12, 30],
    ["line",   12,  30,  50, 30],

    ["label", -25,  15, "MASTER SW"],
    ["korry", -25,  -6, "FAULT", "ON"],

    ["label",  25,  15, "START"],
    ["korry",  25,  -6, "ON", "AVAIL"],
];

// PCB standoffs (x, y): keep clear of holder ridges (~13 mm from each Korry centre)
bosses = [[-50, -25], [50, -25], [0, -25], [0, 15]];

panel_dispatch(part, layout, bosses);
