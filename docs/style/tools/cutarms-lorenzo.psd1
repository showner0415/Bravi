# Plan 037 task 5 (decisions 441, 442): cutarms.ps1 -Sheet docs/style/generated/037-A1a-lorenzo-arms.png -Layout docs/style/tools/cutarms-lorenzo.psd1 (the sheet is A1a)
# Same rules as cutarms-bruno.psd1. Rows read with scan.ps1, cups fitted by the second moments of the cup fill and widened by 13 px (the line and the uneven rim).
# K: the arms sheet draws the fist large against the sleeve (fist 1.37x the sleeve; the parts sheet has 1.05x), so no single K gets both to 1.00.
# K 0.418 keeps both inside 0.85-1.15 (arm-up sleeve 0.86, fist 1.14); the default 0.3165 gives fist 0.86, sleeve 0.65. See measure-A1a.txt.
@{
  K = 0.418
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(448, 930); Grip = 573; Cuff = 711; Sword = @(372, 20, 525); Sleeve = @(396, 499, 978); Fist = @(384, 514); Box = @(372, 20, 525, 978) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(885, 276); Cuff = 357; Sleeve = @(753, 222, 1002); Guard = @(878, 590, 128, 130); Split = @(505, 458); Blade = @(1000, 550, 1068, 615); Box = @(753, 222, 1068, 720) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1260, 267); Cuff = 433; Sleeve = @(1166, 218, 1342); Guard = @(1255.5, 611.2, 110, 70, 45); Split = @(620, 545); Blade = @(1300, 470, 1408, 585); Cuts = @(8, 0); BladeLine = @(1330, 520, 1306, 550); Box = @(1166, 218, 1408, 705) }
  )
}
