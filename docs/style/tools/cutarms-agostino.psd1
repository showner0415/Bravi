# Plan 042 task 12: cutarms.ps1 -Sheet docs/style/basis/agostino-arms.png -Layout docs/style/tools/cutarms-agostino.psd1 -Out assets/art/opponents/agostino (the sheet is A1a)
# Same rules as cutarms-serafina.psd1. Rows read with mA2.ps1 and checked with scan.ps1, cups fitted by the second moments of the cup fill and widened by 13 px (the line and the uneven rim).
# up:      Grip = last row of the line under the guard (dark band 566-574 above the fist's skin), Cuff = first row of the line under the fist (skin ends at 670).
# forward: Cuff = last row of the line above the fist's skin, Guard = cup ellipse cx,cy,rx,ry[,tilt], Split = (lowest row to look for skin, a row where the fist is at full width), Blade box.
# His sleeve ends in a plain hem of the jacket's colour: there is no parchment cuff for the skin test to trip on (serafina's cuff shadow read as skin).
# Arm 3: the blade leaves the rim inside the fist piece's x range; BladeLine keeps the blade's pixels out of the fist piece (fist outline ends at x 1323 on row 490, the blade starts at x 1324 on row 510).
# K 0.413 (board S3, the main agent's ruling 2026-11-27): his rulers are the raised arm's sleeve shaft against his parts-sheet arm (38.5 units), the fist against bartolo's fist (42.4 units),
#   and the line 3.6-7.8 units. On the sheet: sleeve 88 px, fist 118 px, line 8 px. Sleeve passes for K 0.372-0.503, fist for 0.305-0.413, line from 0.450 up: no K passes all three.
#   K 0.413: sleeve 0.94, fist 1.15, line 3.3 units - under 3.6, written and accepted (bartolo's own arm pieces are 3.2). Not redrawn.
#   The other way: K 0.45 = sleeve 1.03, line 3.6, fist 1.25 (= the fist on his torso piece, 53.2), or a redraw with a smaller fist in the pose guide.
#   The boxes, rows and cups do not depend on K; only units_per_px does.
# Joints: up = centre of the sleeve shaft, 16.4 units above the shoulder end (bottom 970 - 16.4 / K, serafina's rule); forward = centre of the sleeve, about 21 units under the shoulder end.
@{
  K = 0.413
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(452.5, 930); Grip = 573; Cuff = 672; Sword = @(374, 21, 528); Sleeve = @(398, 499, 973); Fist = @(383, 519); Box = @(374, 21, 528, 973) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(895, 278); Cuff = 347; Sleeve = @(810, 223, 980); Guard = @(885.0, 578.3, 136, 139); Split = @(468, 398); Blade = @(1017, 551, 1080, 596); Box = @(750, 223, 1080, 716) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1268.5, 315); Cuff = 409; Sleeve = @(1203, 260, 1334); Guard = @(1270.9, 580.0, 111, 78, 50.8); Split = @(511, 446); Blade = @(1312, 453, 1415, 552); Cuts = @(0, 0); BladeLine = @(1340, 492, 1317, 515); Box = @(1179, 260, 1415, 678) }
  )
}
