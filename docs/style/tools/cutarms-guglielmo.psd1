# Plan 045b task 5: cutarms.ps1 -Sheet docs/style/basis/guglielmo-arms.png -Layout docs/style/tools/cutarms-guglielmo.psd1 -Out assets/art/opponents/guglielmo (the sheet is A1a; -Out must be given).
# Same rules as cutarms-beatrice.psd1. Rows read with mA2.ps1 and checked with scan.ps1 and cutA.ps1, cups fitted by the second moments of the cup fill and widened by 13 px.
# up:      Grip = middle of the dark band under the guard (568-577 on x450), Cuff = first dark row under the fist's skin (skin ends at 676).
# forward: Cuff = last dark row above the skin, Guard = cup ellipse cx,cy,rx,ry[,tilt], Split = (lowest row to look for skin, the row where the fist is widest), Blade box.
# His sleeve ends in a plain hem of the shirt's grey-blue at the wrist (no cuff of another colour, no bare forearm).
# K 0.403 (board S3): his rulers are the raised arm's sleeve shaft against his parts-sheet arm (81 px x 0.4903 x 0.92 = 36.5 units), the fist against bartolo's fist (42.4 units)
#   and the line 3.6-7.8 units. On the sheet (drawn from the guide with the sleeves x1.00 and the fists x0.85, generated/in/045b-in-arms-f85.png): sleeve 97 px, fist 120 px, line 9 px.
#   Window where all three pass: K 0.400-0.406; K 0.403 = sleeve 1.07, fist 1.14, line 3.6 units (the two forward sleeves 1.16 / 1.17 - written only, as 044b's).
# Arm 3: the blade leaves the rim inside the fist piece's x range (as beatrice's); BladeLine keeps the blade's pixels out of the fist piece (the fist outline ends at x 1333 on rows 450-470, 1330 on row 490 and 1311 on row 500, the blade starts at x 1326 on row 510; the Blade box starts at x 1286, left of the cup rim's outline that leaves the ellipse on rows 520-527, so its left edge is clear).
# Joints: up = centre of the sleeve shaft, about 16 units above the shoulder end; forward = centre of the sleeve, about 23 units under the shoulder end (mA2.ps1's rule at this K).
@{
  K = 0.403
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(448, 931); Grip = 572; Cuff = 677; Sword = @(373, 20, 526); Sleeve = @(396, 500, 975); Fist = @(380, 519); Box = @(373, 20, 526, 975) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(889.5, 296); Cuff = 346; Sleeve = @(812, 236, 967); Guard = @(887.1, 575.1, 141, 147); Split = @(452, 396); Blade = @(1025, 550, 1085, 597); Box = @(746, 236, 1085, 721) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1268, 283); Cuff = 406; Sleeve = @(1200, 223, 1336); Guard = @(1269.1, 580.5, 112, 72, 47.9); Split = @(523, 446); Blade = @(1286, 440, 1425, 552); Cuts = @(0, 0); BladeLine = @(1334, 488, 1323, 512); Box = @(1178, 223, 1425, 676) }
  )
}
