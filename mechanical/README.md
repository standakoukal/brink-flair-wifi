# mechanical/

Parametric 3D-printable enclosure for the brink-flair-wifi bridge.

## Files

- `enclosure.scad` — OpenSCAD source. Two halves (bottom + lid), all dimensions parametric.

## Tools you need

- [OpenSCAD](https://openscad.org/) (free, Win/macOS/Linux)
- A slicer (PrusaSlicer, Cura, Bambu Studio) for the export → G-code step
- Calipers (digital, ~150 mm) — required to measure the actual XIAO RS485 Expansion Board, since Seeed does not publish its dimensions

## Workflow

1. Open `enclosure.scad` in OpenSCAD.
2. **Measure your hardware** and update the constants in the `// PCB STACK` and `// STEP-DOWN` blocks at the top of the file. Especially:
   - `RS485_BOARD_L`, `RS485_BOARD_W` — overall PCB size of the expansion board
   - `RS485_TERMINAL_H` — height of the green screw terminals above the PCB
   - `XIAO_USB_OFFSET` — how far the USB-C connector sticks past the XIAO PCB edge
   - `SD_L`, `SD_W`, `SD_H` — step-down module dimensions (defaults match the AliExpress mini 17.4 × 12.1 × 4.3 mm)
3. Press **F5** for a fast preview. The default `PART = "assembly"` shows the enclosure plus ghosted PCB stack and step-down so you can sanity-check the layout.
4. Switch `PART` at the top of the file:
   - `"bottom"` → render bottom shell, **F6** (final render), **File → Export → STL** → `bottom.stl`
   - `"lid"`    → render lid (already rotated for printing skirt-up), **F6**, export → `lid.stl`
5. Slice both STLs and print.

## Print recommendations

| Setting | Value | Notes |
|---|---|---|
| Material | PETG or ASA | resists 24 V wiring heat better than PLA |
| Layer height | 0.2 mm | |
| Walls | 4 perimeters | strong enough for VHB pull-off and self-tap M3 |
| Infill | 25 % gyroid | |
| Supports | none for the bottom; tree supports for USB-C slot if needed | |
| Orientation | bottom shell — open side up; lid — already pre-rotated to print skirt-up | |

## Assembly

1. Press the XIAO RS485 Expansion Board onto the four friction-fit posts in the bottom shell. Plug the XIAO ESP32C3 into the female headers on the expansion board.
2. Wire RS485 (A/B/GND) to the screw terminals; thread the cable through the inlet hole and zip-tie it to the strain-relief ribs *inside* the box.
3. Wire 24 V to the step-down's IN pads. Bond the step-down to the inside of the lid with double-sided tape (3M VHB or Tesa Powerstrips). Solder/wire the OUT pads to the XIAO's `5V` and `GND` pins.
4. Verify polarity, fit the lid, drive four M3 self-tap screws into the corner bosses.
5. Stick the bottom face to the recovery unit / wall with VHB.

## Known TODOs

- Verify the default `RS485_BOARD_L/W` against the real board and amend in a follow-up commit.
- Consider adding a small light-pipe over the XIAO's user LED if the lid is opaque.
- Add a hole/dome for an optional reset-button extension if first-flash debugging needs it from outside.
