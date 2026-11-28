# Plan 053b task 5: cutarms.ps1 -Sheet docs/style/basis/cornelia-arms.png -Layout docs/style/tools/cutarms-cornelia.psd1 -Out assets/art/opponents/cornelia (the sheet is A1a; -Out must be given).
# Same rules as cutarms-guglielmo.psd1. Rows read with mA2.ps1 and checked with scan.ps1 and cutA.ps1, cups fitted by the second moments of the cup fill and widened by 13 px.
# up:      Grip = middle of the dark band under the guard (568-583 on x446), Cuff = first dark row under the fist's skin (skin ends at 654).
# forward: Cuff = last dark row above the skin, Guard = cup ellipse cx,cy,rx,ry[,tilt], Split = (lowest row to look for skin, the row where the fist is widest), Blade box.
# Her sleeve ends in a plain hem of the coat's slate grey at the wrist (no cuff of another colour, no bare forearm).
# K 0.355 (board S3): her rulers are the raised arm's sleeve shaft against her parts-sheet arm (73 px x 0.54734 x 0.80 = 32.0 units), the fist against bartolo's fist (42.4 units)
#   and the line 3.6-7.8 units. On the sheet: sleeve 101 px, fist 110 px, line 9 px. No K passes all three (sleeve <= 0.364, line >= 0.400) - as 042, the line is written and taken:
#   K 0.355 = sleeve 1.12, fist 0.92, line 3.2 units (the two forward sleeves 1.35 / 1.21 - written only).
# Arm 3: the blade leaves the fist on the right (rows 448-530); BladeLine keeps the blade's pixels out of the fist piece.
# Joints: up = centre of the sleeve shaft, 16 units above the shoulder end; forward = centre of the sleeve, 23 units under the shoulder end.
@{
  K = 0.355
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(446, 933); Grip = 576; Cuff = 652; Sword = @(368, 20, 525); Sleeve = @(392, 500, 978); Fist = @(390, 505); Box = @(368, 20, 525, 978) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(891.5, 284.8); Cuff = 363; Sleeve = @(817, 220, 966); Guard = @(886.4, 576.5, 141, 148); Split = @(450, 414); Blade = @(1024, 552, 1080, 595); Box = @(746, 220, 1080, 724) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1270, 323.8); Cuff = 447; Sleeve = @(1209, 259, 1331); Guard = @(1270.1, 584.3, 109, 74, 46.2); Split = @(526, 491); Blade = @(1318, 446, 1415, 548); Cuts = @(0, 0); BladeLine = @(1331, 470, 1320, 522); Box = @(1178, 259, 1415, 678) }
  )
}