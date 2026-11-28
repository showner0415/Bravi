# Plan 053b task 4: Cornelia's parts sheet (basis/cornelia-parts.png = the P1b redraw, sha256 5FFB7BB5...4622C53F; P1a drew a feather on the commission cap). Same form as cutparts-guglielmo.psd1;
#   a box is the opaque blob bounding box + 3 (eleven blobs on the cut sheet - the two legs stand apart, so the Legs box takes both leg blobs).
# Each part: name, file, box x0,y0,x1,y1 (sheet px), joint x,y (sheet px), scale x,y. units_per_px = K * scale.
# K = 287.9 / (hem bottom 934 - cape top 409 + 1) = 0.54734: the sketch's cape top is 204.6 above the pelvis and the hem 83.3 below it (outlines included); the neck stub above the cape is not in the ruler.
# Joints: Torso = the middle of the hem (x 117-413 on row 915; the arm, the fist and the awl are on the viewer's right), pelvis row = 934 + 1 - 83.3 / K = 782.8.
#   Legs = the middle of the gap between the two legs (x 664-670), pelvis row = top row 631 + 16.5 / (K x 1.27): the top edge sits 16.5 above the pelvis, behind the coat.
#   Head = between the two eye dots (x 148.0 / 221.7 on the first head, 438.7 / 513.8 on the second, the dizzy head by its nose 767.7), neck joint = chin bottom 276 + 1 + 6 / (K x 1.0);
#     neck.y -196 in the art data (formula top 322.4 with the 3 px box margin counted, as in T166).
#   Hat = the brim centre (x 965-1209); with hat_at (0, -96) its band bottom sits at -91.2 (the head cap's brim bottom is at -95.2: 4.0 lower), its top at -130.6 (head cap top -124.8: 5.8 higher),
#     brim half width 67.6 (head cap brim 53.1). No feather is drawn on it (P1b).
#   Feather = its quill 6 right and 16 above the hat origin (the sketch's place, beside the badge), lying back about 24 degrees.
#   Arm = centre, top + 14.6 units. Hand = centre, top + 2.6 units. Sword = the crossbar centre x, bottom - 15.6 units.
# Scales: heads 1.0 (eye line 253.6); hat 1.0; feather 0.70; legs 1.27 (toe 192.1, height 514.5 - the sheet drew the legs short); arm 0.80 (arm 103.7), hand and sword 0.82 (fist 36.8); torso 1 x 1.
@{
  Sheet = 'docs\style\basis\cornelia-parts.png'
  Out = 'assets\art\opponents\cornelia'
  K = 0.54734
  Parts = @(
    @('Head', 'head', 73, 57, 298, 279, 184.9, 287.96, 1, 1), @('HeadOops', 'head_oops', 364, 57, 589, 279, 476.2, 287.96, 1, 1),
    @('HeadDizzy', 'head_dizzy', 656, 57, 880, 279, 767.7, 287.96, 1, 1), @('Hat', 'hat', 960, 192, 1212, 270, 1087, 259.2, 1, 1),
    @('Feather', 'feather', 1285, 182, 1457, 266, 1274.3, 303.8, 0.70, 0.70), @('Torso', 'torso', 114, 387, 466, 937, 265, 782.8, 1, 1),
    @('Legs', 'legs', 573, 628, 761, 933, 667, 654.7, 1.27, 1.27), @('Arm', 'arm', 858, 535, 936, 777, 897, 571.3, 0.80, 0.80),
    @('Hand', 'hand', 1031, 664, 1118, 739, 1074.5, 672.8, 0.82, 0.82), @('Sword', 'sword', 1223, 422, 1359, 904, 1291, 866.2, 0.82, 0.82)
  )
}