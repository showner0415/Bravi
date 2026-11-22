@{
  # Plan 030c decision 292: cutarms.ps1 -Sheet docs/style/basis/bartolo-arms2.png -Layout docs/style/tools/cutarms-030c.psd1
  # Rows and ovals read on the sheet with scan.ps1 (rows) and a moment fit of the cup fill (ovals); the reasons are in docs/style/tools/README.md.
  # Joints: raised arm 47 px above the sleeve end like bartolo-arms.png; forward arms 60 px below the sleeve top (bartolo-arms.png thrust: 62).
  Arms = @(
    @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(450, 926); Grip = 575; Cuff = 693; Sword = @(372, 14, 532); Sleeve = @(398, 505, 980); Fist = @(388, 515); Box = @(372, 14, 532, 980) }
    @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(886, 283); Cuff = 357; Sleeve = @(750, 218, 1010); Guard = @(889, 585, 140, 143); Split = @(500, 440); Blade = @(1011, 535, 1085, 615); Box = @(750, 218, 1085, 730) }
    @{ Kind = 'forward'; Name = 'ArmAim'; File = 'arm_aim'; Joint = @(1267, 237); Cuff = 406; Sleeve = @(1175, 172, 1340); Guard = @(1271, 580, 126, 72, 44); Split = @(600, 495); Blade = @(1305, 445, 1422, 575); Cuts = @(8, 0); BladeLine = @(1340, 502, 1317, 519); Box = @(1175, 172, 1422, 676) }
  )
}
