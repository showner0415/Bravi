# Plan 044b task 5: cutarms.ps1 -Sheet docs/style/basis/beatrice-arms.png -Layout docs/style/tools/cutarms-beatrice.psd1 -Out assets/art/opponents/beatrice (the sheet is A1a; -Out must be given).
# Same rules as cutarms-agostino.psd1. Rows read with mA2.ps1 and checked with scan.ps1 and cutA.ps1, cups fitted by the second moments of the cup fill and widened by 13 px.
# up:      Grip = middle of the dark band under the guard (567-577 on x450), Cuff = first dark row under the fist's skin (skin ends at 677).
# forward: Cuff = last dark row above the skin, Guard = cup ellipse cx,cy,rx,ry[,tilt], Split = (lowest row to look for skin, the row where the fist is widest), Blade box.
# Her sleeve ends in a plain hem of the dress's colour (no parchment cuff for the skin test to trip on).
# K 0.42 (board S3): her rulers are the raised arm's sleeve shaft against her parts-sheet arm (60 px x 0.8125 x 0.657 = 32.0 units), the fist against bartolo's fist (42.4 units)
#   and the line 3.6-7.8 units. On the sheet (drawn from the guide with the fists x0.85, generated/in/044b-in-arms-f85.png): sleeve 82 px, fist 110 px, line 9 px (median of 12 scans
#   on the three sleeves, 7-9 px dark plus antialiasing). Window where all three pass: K 0.400-0.443; K 0.42 = sleeve 1.08, fist 1.09, line 3.8 units.
# Arm 3: the blade leaves the rim inside the fist piece's x range (as agostino's); BladeLine keeps the blade's pixels out of the fist piece (the fist outline ends at x 1322 on rows 443-450, 1320 on row 490 and 1315 on row 505, the blade starts at x 1321 on row 505; the Blade box starts at x 1312 so its left edge is clear).
# Joints: up = centre of the sleeve shaft, about 16 units above the shoulder end; forward = centre of the sleeve, about 21 units under the shoulder end (mA2.ps1's rule).
@{
  K = 0.42
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(455.5, 930); Grip = 572; Cuff = 678; Sword = @(373, 21, 530); Sleeve = @(412, 503, 969); Fist = @(382, 521); Box = @(373, 21, 530, 969) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(888.5, 276); Cuff = 338; Sleeve = @(812, 222, 965); Guard = @(892.1, 572.7, 142, 144); Split = @(452, 389); Blade = @(1031, 549, 1076, 588); Box = @(752, 222, 1076, 716) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1260, 284); Cuff = 386; Sleeve = @(1194, 230, 1326); Guard = @(1267.3, 574.9, 113, 73, 48.3); Split = @(511, 430); Blade = @(1312, 443, 1418, 551); Cuts = @(0, 0); BladeLine = @(1323, 490, 1317, 512); Box = @(1175, 230, 1413, 671) }
  )
}
