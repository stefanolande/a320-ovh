#!/usr/bin/env bash
# Export all print / laser / PCB files for one panel layout.
# usage: ./export.sh apu      -> out/apu/*
set -euo pipefail
cd "$(dirname "$0")"
name=${1:?layout name, e.g. apu}
out=out/$name
mkdir -p "$out"
run() { openscad -q -D "part=\"$1\"" -o "$out/$name-$1.$2" "$name.scad" 2>&1 | grep -v '^ECHO' || true; }
for p in skin core labels single cap_jig; do run "$p" stl; done
run labels_svg svg
run cap_legends_svg svg
run pcb_dxf dxf
openscad -q -D 'part="report"' -o /dev/null --export-format=echo "$name.scad" 2>/dev/null || true
openscad -D 'part="none"' -o "$out/$name.echo" "$name.scad" 2>/dev/null
grep -oE 'PLACE,[^"]*|PCB_TO_PANEL_BACK,[^"]*' "$out/$name.echo" > "$out/$name-placements.csv"
rm -f "$out/$name.echo"
if command -v xvfb-run >/dev/null; then
  xvfb-run -a openscad -q -D 'part="preview"' --preview --imgsize=1400,1000 --colorscheme=Tomorrow \
    --camera=0,0,0,25,0,0,0 --viewall --autocenter -o "$out/$name-preview.png" "$name.scad" || true
fi
if command -v xvfb-run >/dev/null; then
  xvfb-run -a openscad -q -D 'part="preview"' --preview --imgsize=1400,1000 --colorscheme=Tomorrow \
    --camera=0,0,0,155,0,20,0 --viewall --autocenter -o "$out/$name-back.png" "$name.scad" || true
fi
ls -1 "$out"
