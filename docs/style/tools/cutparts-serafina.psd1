# Plan 041 task 12: Serafina's parts sheet (basis/serafina-parts.png, P1a). Same form as cutparts-lorenzo.psd1; the box is the opaque bounding box + 3.
# Each part: name, file, box x0,y0,x1,y1 (sheet px), joint x,y (sheet px), scale x,y. units_per_px = K * scale.
# K = 215.2 / (torso body bottom 894 - shoulder top 519 + 1) = 0.5723: her neck is at -212 (the shoulder's outer edge is 212.6 above the pelvis, the body's bottom edge 2.6 below).
# Joints: Torso = centre of the column of cloth (x 122-269), pelvis row 889.5 (body bottom - 2.6 / K; the cord tail hangs below it). Legs = column centre, top 527 + 8.6 / K.
#   Head = centre, chin row 304 + 18 / K (long neck: the joint lies inside the collar stub of the head piece). Hat = centre, 14 px above the cap's bottom edge.
#   Feather = joint so that its base tip (1259, 283) sits at hat (28, -9). Arm = centre, top 543 + 0.447 x width. Hand = centre, top + 7. Sword = centre, bottom 914 - 31 / K.
# Scales: Hat and Feather 0.88 (the cap came out 41.8 tall; with hat_at (0, -113) the top with the hat is 355.8 by the formula, engage top y about 144).
#   Legs x 1.057 so the lower gown (140 px) is as wide as the column of the torso (148 px) at the cord belt; y 1 (toe 219.8 by the formula, limit 221).
#   If the toe ever has to come down, lower the Legs scale y only - a plain column takes it.
@{
  Sheet = 'docs\style\basis\serafina-parts.png'
  Out = 'assets\art\opponents\serafina'
  K = 0.5723
  Parts = @(
    @('Head', 'head', 84, 97, 272, 350, 178, 335.4, 1, 1), @('HeadOops', 'head_oops', 357, 97, 545, 350, 451, 335.4, 1, 1),
    @('HeadDizzy', 'head_dizzy', 628, 97, 816, 350, 722, 335.4, 1, 1), @('Hat', 'hat', 931, 219, 1154, 297, 1042.5, 280, 0.88, 0.88),
    @('Feather', 'feather', 1256, 241, 1415, 295, 1203.4, 300.9, 0.88, 0.88), @('Torso', 'torso', 119, 466, 342, 920, 195.5, 889.5, 1, 1),
    @('Legs', 'legs', 495, 524, 640, 925, 567.5, 542, 1.057, 1), @('Arm', 'arm', 822, 540, 880, 777, 851, 566.7, 1, 1),
    @('Hand', 'hand', 1041, 606, 1114, 671, 1077.5, 616, 1, 1), @('Sword', 'sword', 1278, 515, 1396, 917, 1337, 860, 1, 1)
  )
}
