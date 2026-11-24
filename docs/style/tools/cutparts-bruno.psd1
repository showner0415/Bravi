# Plan 035 decision 361: Bruno's parts sheet (basis/bruno-parts.png, P1a). Measured in basis/README.md "trim values (plan 035)".
# Each part: name, file, box x0,y0,x1,y1 (sheet px), joint x,y (sheet px), scale x,y. K = 200 / (pelvis 815 - neck 531).
@{
  Sheet = 'docs\style\basis\bruno-parts.png'
  Out = 'assets\art\opponents\bruno'
  K = 0.7042
  Parts = @(
    @('Head', 'head', 83, 165, 283, 370, 183, 343, 1, 1), @('HeadOops', 'head_oops', 351, 165, 551, 370, 451, 343, 1, 1),
    @('HeadDizzy', 'head_dizzy', 616, 165, 816, 370, 716, 343, 1, 1), @('Hat', 'hat', 925, 221, 1116, 305, 1020.5, 283, 0.95, 0.95),
    @('Feather', 'feather', 1214, 262, 1354, 306, 1180, 329, 0.95, 0.95), @('Torso', 'torso', 102, 506, 385, 826, 243.5, 815, 1, 1),
    @('Legs', 'legs', 493, 530, 731, 823, 612, 542, 1, 1), @('Arm', 'arm', 858, 533, 940, 740, 899, 565, 0.892, 0.892),
    @('Hand', 'hand', 1053, 595, 1133, 666, 1093, 606, 0.96, 0.96), @('Sword', 'sword', 1240, 508, 1360, 863, 1300, 814, 1, 1)
  )
}
