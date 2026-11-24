@{
  # Plan 035 decisions 359-361: cutarms.ps1 -Sheet docs/style/basis/bruno-arms.png -Layout docs/style/tools/cutarms-bruno.psd1 (the sheet is A1c)
  # Same rules as cutarms-030c.psd1. Rows read with scan.ps1, cups fitted by the second moments of the cup fill and widened by the line and the uneven rim (13 px).
  # K: the arms sheet is drawn smaller than Bartolo's, so the fist width (127 px) is matched to the parts-sheet hand (74 px x 0.7042 x 0.96 = 50.0 units).
  K = 0.3937
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(450, 927); Grip = 577; Cuff = 692; Sword = @(375, 20, 525); Sleeve = @(393, 506, 978); Fist = @(384, 515); Box = @(375, 20, 525, 978) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(886, 286); Cuff = 371; Sleeve = @(753, 220, 1020); Guard = @(886.4, 584.8, 137, 138); Split = @(505, 450); Blade = @(1005, 550, 1080, 612); Box = @(753, 220, 1080, 724) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1262.5, 249); Cuff = 421; Sleeve = @(1179, 185, 1345); Guard = @(1268.8, 582.9, 114, 71, 48); Split = @(600, 507); Blade = @(1315, 440, 1420, 575); Cuts = @(8, 0); BladeLine = @(1331, 498, 1320, 512); Box = @(1179, 185, 1420, 680) }
  )
}
