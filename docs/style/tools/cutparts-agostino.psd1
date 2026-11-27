# Plan 042 task 11: Agostino's parts sheet (basis/agostino-parts.png, P1a). Same form as cutparts-serafina.psd1; a box is the opaque bounding box + 3.
# Each part: name, file, box x0,y0,x1,y1 (sheet px), joint x,y (sheet px), scale x,y. units_per_px = K * scale.
# K = 274.0 / (torso bottom 880 - top 484 + 1) = 0.6902: the top of his shoulder dome (outer edge) is 237.5 above the pelvis and the hem's bottom edge 36.5 below.
# His neck is at -200 (art data neck.y; the sketch had -204): the heads came out 109.9 from the neck joint to the top of the box, and with the scale left at 1
#   the top without the hat is 309.9 (limit 311) and the head-centre ruler 255.0 (limit 252). The other way is neck -204 with the three heads at 0.944 (307.8 / 255.9).
# Joints: Torso = centre of the hem (x 158-326; the arm with the fist hangs on the viewer's right, so the blob centre is not the body centre), pelvis row = 880 + 1 - 36.5 / K.
#   Legs = centre of the legs where they come out from under the hem (x 562-753 on row 623), top of the legs blob 553 + 8.6 / K.
#     The Legs box is ONE box around two blobs - the legs (527-770) and the walking cane that stands apart on the viewer's right (779-801, rows 462-859):
#     the sheet has eleven blobs, the game ten parts. The cane must not leave the ground, so it lives in the part that never moves; the fist of the torso piece covers its head.
#     The top of the Legs box is the top of the cane, not of the hips.
#   Head = centre, chin row (274; 275 on the dizzy head) - 6 / K: no neck stub, the chin line is 6 units under the joint and the beard hangs below it.
#   Hat = centre, 8.6 / K above the cap's bottom edge. Feather = joint so that its base tip (1286, 251.5) sits at hat (19.4, -6.5).
#   Arm = centre, top 538 + 14.6 / K. Hand = centre, top 615 + 4 / K. Sword = centre, bottom 880 - 31 / K (on the grip, under the guard at row 807).
# Scales: Legs x 0.90 so the legs come out from under the hem (legs 132.5 wide on the hem row against the hem's 116.6 -> 119.3; flush would be 0.88) and
#   y 0.925 so the toe is 190.0 by the formula (205.4 as drawn, limit 185~200). The cane shrinks with them: its centre is then 82.3 from the legs joint and its top 66 above the pelvis,
#   under the fist of the torso piece (centre 94.9, skin 73.5~116.3, 35.6~78.4 above the pelvis).
#   Arm, Hand and Sword 0.82: the small parts were drawn about a quarter too big (arm 126.9 long -> 104.0, HP2 89~121; fist 51.1 -> 41.9 = bartolo's 42.4 x 0.99; sword 67.9 x 222.4).
#   Hat and Feather 1 (cap 89.7 x 44.2; with hat_at (0, -98.1) the top with the hat is 335.8 by the formula, engage top y 161).
@{
  Sheet = 'docs\style\basis\agostino-parts.png'
  Out = 'assets\art\opponents\agostino'
  K = 0.6902
  Parts = @(
    @('Head', 'head', 71, 106, 346, 367, 208.5, 265.3, 1, 1), @('HeadOops', 'head_oops', 385, 106, 662, 367, 523.5, 265.3, 1, 1),
    @('HeadDizzy', 'head_dizzy', 699, 107, 975, 368, 837, 266.3, 1, 1), @('Hat', 'hat', 1060, 191, 1195, 260, 1127.5, 245.5, 1, 1),
    @('Feather', 'feather', 1283, 217, 1416, 265, 1257.9, 260.9, 1, 1), @('Torso', 'torso', 88, 481, 421, 883, 242, 828.1, 1, 1),
    @('Legs', 'legs', 524, 459, 804, 862, 657.5, 565.5, 0.90, 0.925), @('Arm', 'arm', 936, 535, 1009, 745, 972.5, 559.2, 0.82, 0.82),
    @('Hand', 'hand', 1120, 612, 1199, 682, 1159.5, 620.8, 0.82, 0.82), @('Sword', 'sword', 1297, 485, 1422, 883, 1359.5, 835.1, 0.82, 0.82)
  )
}
