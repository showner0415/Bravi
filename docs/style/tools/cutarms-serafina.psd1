# Plan 041 task 13: cutarms.ps1 -Sheet docs/style/basis/serafina-arms.png -Layout docs/style/tools/cutarms-serafina.psd1 (the sheet is A1a)
# Same rules as cutarms-lorenzo.psd1. Rows read with scan.ps1, cups fitted by the second moments of the cup fill and widened by 13 px (the line and the uneven rim).
# K: her rulers are her own (plan 041, board S3): the raised arm's sleeve shaft against her parts-sheet arm (30.3 units), the fist against bartolo's fist (42.4 units),
# the line 3.6-7.8 units. On the sheet: sleeve 72 px, fist 103 px, line 9 px -> all three pass for K 0.400-0.473. K 0.42: sleeve 1.00, fist 1.02, line 3.8 units.
# The two arms that point at the viewer are drawn thicker (thrust sleeve 90 px = 1.25, aim sleeve 86 px = 1.19), as the pose guide has them.
# Arm 3: the blade leaves the rim beside the thumb; BladeLine keeps the blade's pixels out of the fist piece (the thumb ends at y 508, the blade starts right of x 1331).
@{
  K = 0.42
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(448.5, 931); Grip = 572; Cuff = 686; Sword = @(373, 21, 522); Sleeve = @(407, 490, 973); Fist = @(394, 502); Box = @(373, 21, 522, 973) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(889.5, 276); Cuff = 343; Sleeve = @(810, 221, 962); Guard = @(888.8, 577.5, 138, 148); Split = @(486, 439); Blade = @(1010, 540, 1084, 598); Box = @(750, 221, 1084, 726) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1269.5, 299); Cuff = 412; Sleeve = @(1211, 246, 1333); Guard = @(1272.2, 578, 113, 75, 52.7); Split = @(512, 480); Blade = @(1312, 448, 1417, 548); Cuts = @(0, 0); BladeLine = @(1331.5, 512, 1312, 540); Box = @(1182, 246, 1417, 677) }
  )
}
