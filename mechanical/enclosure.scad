// =============================================================================
// brink-flair-wifi - external enclosure for XIAO ESP32C3 + RS485 expansion
// =============================================================================
//
// Layout (bottom to top):
//   1. PCB stack: XIAO RS485 Expansion Board with the XIAO ESP32C3 plugged
//      in on top. Held by friction-fit posts on the bottom shell.
//   2. Step-down module bonded to the inside of the lid with double-sided
//      tape (its own ground plane keeps it isolated from the PCB stack).
//
// Cabling:
//   - 24 V supply enters through the right side wall, terminates at the
//     step-down's IN pads. Strain relief: zip-tie around the cable with
//     the tie head captured behind the internal ribs.
//   - RS485 (A/B/GND) enters through the left side wall, terminates at
//     the expansion board's screw terminals. Same strain-relief scheme.
//   - USB-C is exposed through a slot at the rear so the XIAO can be
//     re-flashed without opening the box.
//
// Mounting: flat bottom face for 3M VHB tape against the recovery unit
// or wall.
//
// !!! IMPORTANT !!!
// The expansion-board dimensions are NOT published by Seeed - measure
// the board with calipers and update RS485_BOARD_L / RS485_BOARD_W /
// RS485_TERMINAL_H below before printing. The defaults are conservative
// estimates based on photos.
//
// Render: F5 preview, F6 final render, then File -> Export -> STL.
// To print bottom and lid separately, set PART = "bottom" or "lid".
// =============================================================================

// ---- WHAT TO RENDER ---------------------------------------------------------
PART = "assembly"; // "bottom" | "lid" | "assembly"

// ---- TOLERANCES & WALLS -----------------------------------------------------
WALL          = 2.0;   // outer wall thickness
LID_OVERLAP   = 4.0;   // depth of the lip that mates lid to bottom
LID_LIP_T     = 1.0;   // lip wall thickness
FIT_TOL       = 0.2;   // clearance between lid lip and bottom inside
PRINT_GAP     = 0.4;   // generic clearance for moving / pressed-in parts

// ---- PCB STACK (bottom layer) ----------------------------------------------
// VERIFY all of these against your actual board.
RS485_BOARD_L = 30.0;  // length of the expansion board
RS485_BOARD_W = 21.0;  // width of the expansion board (matches XIAO)
RS485_BOARD_T = 1.6;   // PCB thickness
RS485_TERMINAL_H = 11.0;   // top of the green screw-terminal above the PCB
RS485_HEADERS_H  = 4.5;    // female-header height under the XIAO
XIAO_T = 1.0;              // XIAO PCB thickness
XIAO_TOP_H = 3.5;          // tallest component on top of XIAO (USB connector)
XIAO_USB_W = 9.5;          // USB-C body width (with a bit of slop)
XIAO_USB_H = 4.0;          // USB-C body height (with a bit of slop)
XIAO_USB_OFFSET = 0.0;     // how far the USB-C body protrudes past the XIAO PCB edge

// Total stack height from board bottom to the highest point on the XIAO.
PCB_STACK_H = RS485_BOARD_T + RS485_HEADERS_H + XIAO_T + XIAO_TOP_H;

// ---- STEP-DOWN (top layer, bonded to lid) ----------------------------------
SD_L = 17.4;
SD_W = 12.1;
SD_H = 4.3;
SD_AIR_GAP = 4.0;   // clearance above PCB stack for air flow and wires

// ---- INTERNAL CLEARANCES ----------------------------------------------------
SIDE_GAP   = 3.0;   // air gap on each side of the PCB
END_GAP    = 4.0;   // extra room at the cable ends (for the screw terminals)
TOP_GAP    = 1.5;   // headroom above the step-down

// ---- POSTS (friction-fit for the expansion board) --------------------------
POST_OD    = 4.0;   // outside diameter of the support posts
POST_ID    = 1.6;   // central pilot hole (only used as a self-tap if you decide to screw the board down later)
POST_INSET = 1.5;   // how far the posts grip into the board edge (small wings)
POST_H     = 4.0;   // post height = how far the board sits above the floor

// ---- CABLE INLETS -----------------------------------------------------------
PWR_CABLE_D    = 4.5;  // 24 V cable diameter
RS485_CABLE_D  = 6.0;  // RS485 cable diameter (twisted pair + shield)
INLET_Z        = 6.0;  // height of the cable hole center above the floor
STRAIN_RIB_T   = 2.0;  // rib thickness for strain-relief loops
STRAIN_RIB_W   = 8.0;  // rib width
STRAIN_RIB_GAP = 1.5;  // gap between two ribs for the zip-tie

// ---- LID FASTENERS ----------------------------------------------------------
SCREW_HOLE_D  = 3.2;   // through hole on the lid (M3)
SCREW_BOSS_OD = 6.0;   // boss diameter on the bottom (self-tap into 2.6 mm pilot)
SCREW_PILOT_D = 2.6;   // pilot hole for self-tap M3
SCREW_HEAD_D  = 6.0;
SCREW_HEAD_H  = 1.8;

// ---- VENTILATION ------------------------------------------------------------
VENT_W       = 2.0;
VENT_L       = 12.0;
VENT_PITCH   = 4.0;
VENT_COUNT   = 4;

// ---- DERIVED INSIDE DIMENSIONS ---------------------------------------------
INSIDE_L = RS485_BOARD_L + 2 * END_GAP;
INSIDE_W = RS485_BOARD_W + 2 * SIDE_GAP;
INSIDE_H = POST_H + PCB_STACK_H + SD_AIR_GAP + SD_H + TOP_GAP;

OUTSIDE_L = INSIDE_L + 2 * WALL;
OUTSIDE_W = INSIDE_W + 2 * WALL;
BOTTOM_H  = WALL + INSIDE_H - LID_OVERLAP;   // bottom shell height
LID_H     = WALL + LID_OVERLAP;              // lid total height

$fn = 64;

// =============================================================================
// LOW-LEVEL HELPERS
// =============================================================================

// A board-support post with two thin wings that grip the board edges.
module support_post() {
    cylinder(d = POST_OD, h = POST_H);
    // Wings rise slightly above the post to grip the board sides.
    translate([0, 0, POST_H])
        cylinder(d1 = POST_OD, d2 = POST_OD - 1.0, h = 1.5);
}

// A pair of strain-relief ribs separated by a slot for a zip-tie.
module strain_relief_pair(rib_h) {
    for (dx = [-(STRAIN_RIB_GAP/2 + STRAIN_RIB_T/2),
                (STRAIN_RIB_GAP/2 + STRAIN_RIB_T/2)])
        translate([dx - STRAIN_RIB_T/2, -STRAIN_RIB_W/2, 0])
            cube([STRAIN_RIB_T, STRAIN_RIB_W, rib_h]);
}

// A row of vertical vent slots cut through a side wall.
module vent_slots() {
    total_w = (VENT_COUNT - 1) * VENT_PITCH;
    for (i = [0 : VENT_COUNT - 1])
        translate([i * VENT_PITCH - total_w/2, 0, 0])
            cube([VENT_W, WALL + 1, VENT_L], center = false);
}

// Threaded boss (no actual thread - tapped by the screw on assembly).
module screw_boss(h) {
    difference() {
        cylinder(d = SCREW_BOSS_OD, h = h);
        translate([0, 0, -0.1])
            cylinder(d = SCREW_PILOT_D, h = h + 0.2);
    }
}

// =============================================================================
// BOTTOM SHELL
// =============================================================================
// Coordinate system: origin at outer bottom-left corner of the bottom shell.
// X axis along the long side (cable inlets at +X and -X ends if you like,
// but here both inlets are on the long sides so the front face stays clean).
// Y axis along the short side. Z up.

module bottom_shell() {
    // PCB stack centered on the floor.
    pcb_x0 = WALL + END_GAP;
    pcb_y0 = WALL + SIDE_GAP;

    difference() {
        union() {
            // Outer shell (filled), then we hollow it.
            cube([OUTSIDE_L, OUTSIDE_W, BOTTOM_H]);

            // Lid lip (a thin rim that the lid slides over).
            // Drawn as a tube around the inside top.
            translate([WALL, WALL, BOTTOM_H - LID_OVERLAP])
                difference() {
                    cube([INSIDE_L, INSIDE_W, LID_OVERLAP]);
                    translate([LID_LIP_T + FIT_TOL, LID_LIP_T + FIT_TOL, -0.1])
                        cube([INSIDE_L - 2*(LID_LIP_T + FIT_TOL),
                              INSIDE_W - 2*(LID_LIP_T + FIT_TOL),
                              LID_OVERLAP + 0.2]);
                }
        }

        // Hollow the inside down to wall thickness on the floor.
        translate([WALL, WALL, WALL])
            cube([INSIDE_L, INSIDE_W, BOTTOM_H]);

        // Cable inlet: 24 V on the +Y side (long side, "back" of enclosure).
        translate([WALL + END_GAP + RS485_BOARD_L * 0.75,
                   OUTSIDE_W,
                   WALL + INLET_Z])
            rotate([90, 0, 0])
                cylinder(d = PWR_CABLE_D, h = WALL + 1);

        // Cable inlet: RS485 on the -Y side (long side, "front").
        translate([WALL + END_GAP + RS485_BOARD_L * 0.25,
                   -1,
                   WALL + INLET_Z])
            rotate([-90, 0, 0])
                cylinder(d = RS485_CABLE_D, h = WALL + 1);

        // USB-C slot on the -X end.
        translate([-1,
                   OUTSIDE_W/2 - XIAO_USB_W/2,
                   WALL + POST_H + RS485_BOARD_T + RS485_HEADERS_H + XIAO_T - 0.5])
            cube([WALL + 1 + XIAO_USB_OFFSET, XIAO_USB_W, XIAO_USB_H]);

        // Vent slots on both long sides next to the step-down zone (top portion).
        // We cut through the lid lip so the air actually circulates.
        vent_z = BOTTOM_H - LID_OVERLAP - VENT_L - 1.0;
        translate([OUTSIDE_L/2, -0.1, vent_z]) vent_slots();
        translate([OUTSIDE_L/2, OUTSIDE_W - WALL + 0.1, vent_z])
            mirror([0, 1, 0]) vent_slots();
    }

    // PCB support posts (4 corners of the expansion board).
    translate([pcb_x0,                  pcb_y0,                  WALL]) support_post();
    translate([pcb_x0 + RS485_BOARD_L,  pcb_y0,                  WALL]) support_post();
    translate([pcb_x0,                  pcb_y0 + RS485_BOARD_W,  WALL]) support_post();
    translate([pcb_x0 + RS485_BOARD_L,  pcb_y0 + RS485_BOARD_W,  WALL]) support_post();

    // Strain-relief ribs inside, behind each cable inlet.
    // 24 V side
    translate([WALL + END_GAP + RS485_BOARD_L * 0.75,
               OUTSIDE_W - WALL - 5,
               WALL])
        strain_relief_pair(INLET_Z + PWR_CABLE_D);
    // RS485 side
    translate([WALL + END_GAP + RS485_BOARD_L * 0.25,
               WALL + 5 - STRAIN_RIB_W,
               WALL])
        strain_relief_pair(INLET_Z + RS485_CABLE_D);

    // Lid screw bosses in 4 corners (M3 self-tap).
    boss_h = BOTTOM_H - WALL;
    boss_inset = SCREW_BOSS_OD/2 + LID_LIP_T + FIT_TOL + 0.5;
    for (cx = [boss_inset, OUTSIDE_L - boss_inset])
        for (cy = [boss_inset, OUTSIDE_W - boss_inset])
            translate([cx, cy, WALL]) screw_boss(boss_h);
}

// =============================================================================
// LID
// =============================================================================

module lid() {
    boss_inset = SCREW_BOSS_OD/2 + LID_LIP_T + FIT_TOL + 0.5;

    difference() {
        union() {
            // Top plate.
            cube([OUTSIDE_L, OUTSIDE_W, WALL]);

            // Lid skirt that fits inside the bottom shell's lip.
            translate([WALL + LID_LIP_T + FIT_TOL,
                       WALL + LID_LIP_T + FIT_TOL,
                       WALL])
                difference() {
                    cube([INSIDE_L - 2*(LID_LIP_T + FIT_TOL),
                          INSIDE_W - 2*(LID_LIP_T + FIT_TOL),
                          LID_OVERLAP - 0.5]);
                    // Hollow it.
                    translate([WALL, WALL, -0.1])
                        cube([INSIDE_L - 2*(LID_LIP_T + FIT_TOL) - 2*WALL,
                              INSIDE_W - 2*(LID_LIP_T + FIT_TOL) - 2*WALL,
                              LID_OVERLAP + 1]);
                }
        }

        // Through holes for M3 screws + countersink for the head.
        for (cx = [boss_inset, OUTSIDE_L - boss_inset])
            for (cy = [boss_inset, OUTSIDE_W - boss_inset]) {
                translate([cx, cy, -0.1])
                    cylinder(d = SCREW_HOLE_D, h = WALL + 0.2);
                translate([cx, cy, WALL - SCREW_HEAD_H])
                    cylinder(d = SCREW_HEAD_D, h = SCREW_HEAD_H + 0.1);
            }

        // Mark a small "BRINK" notch at one end so orientation is obvious.
        translate([5, OUTSIDE_W/2 - 4, -0.1])
            linear_extrude(0.6) text("BRINK", size = 4);
    }
}

// =============================================================================
// VISUALIZATION (preview only - not exported)
// =============================================================================

module preview_pcb_stack() {
    pcb_x0 = WALL + END_GAP;
    pcb_y0 = WALL + SIDE_GAP;
    color("DarkGreen") translate([pcb_x0, pcb_y0, WALL + POST_H])
        cube([RS485_BOARD_L, RS485_BOARD_W, RS485_BOARD_T]);
    color("DimGray") translate([pcb_x0 + 5, pcb_y0 + 2,
                                WALL + POST_H + RS485_BOARD_T + RS485_HEADERS_H])
        cube([21, 17.8, XIAO_T]);  // XIAO PCB
}

module preview_stepdown() {
    color("Khaki") translate([(OUTSIDE_L - SD_L)/2,
                              (OUTSIDE_W - SD_W)/2,
                              BOTTOM_H + WALL - SD_H - 0.5])
        cube([SD_L, SD_W, SD_H]);
}

// =============================================================================
// PART SELECTION
// =============================================================================

if (PART == "bottom") {
    bottom_shell();
} else if (PART == "lid") {
    // Print the lid upside down (skirt up) for best top finish.
    rotate([180, 0, 0]) translate([0, -OUTSIDE_W, -WALL]) lid();
} else {
    // assembly view
    bottom_shell();
    preview_pcb_stack();
    %translate([0, 0, BOTTOM_H]) lid();   // ghosted lid
    %preview_stepdown();
}
