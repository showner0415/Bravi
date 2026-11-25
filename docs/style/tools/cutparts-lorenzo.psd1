# Plan 037 task 4: Lorenzo's parts sheet (basis/lorenzo-parts.png, P1a). Same form as cutparts-bruno.psd1; the box is the opaque bounding box + 3.
# Each part: name, file, box x0,y0,x1,y1 (sheet px), joint x,y (sheet px), scale x,y. K = 200 / (pelvis 876 - neck 546).
@{
  Sheet = 'docs\style\basis\lorenzo-parts.png'
  Out = 'assets\art\opponents\lorenzo'
  K = 0.6061
  Parts = @(
    @('Head', 'head', 59, 128, 293, 392, 176, 365, 1, 1), @('HeadOops', 'head_oops', 350, 128, 584, 392, 467, 365, 1, 1),
    @('HeadDizzy', 'head_dizzy', 637, 128, 870, 392, 753.5, 365, 1, 1), @('Hat', 'hat', 926, 211, 1273, 315, 1099.5, 280, 0.85, 0.85),
    @('Feather', 'feather', 1311, 254, 1476, 310, 1289, 316, 0.85, 0.85), @('Torso', 'torso', 98, 521, 303, 887, 200.5, 876, 1, 1),
    @('Legs', 'legs', 446, 553, 684, 883, 565, 565, 1, 1), @('Arm', 'arm', 827, 551, 916, 809, 871.5, 586, 0.8, 0.8),
    @('Hand', 'hand', 1060, 632, 1149, 712, 1104.5, 643, 0.84, 0.84), @('Sword', 'sword', 1302, 513, 1434, 900, 1368, 846, 1, 1)
  )
}
