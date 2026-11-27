# Plan 045b task 4: Guglielmo's parts sheet (basis/guglielmo-parts.png, P1a). Same form as cutparts-beatrice.psd1; a box is the opaque blob bounding box + 3 (blobs026 on the cut sheet: ten blobs).
# Each part: name, file, box x0,y0,x1,y1 (sheet px), joint x,y (sheet px), scale x,y. units_per_px = K * scale.
# K = 223.1 / (apron end bottom 903 - collar top 449 + 1) = 0.4903: the sketch's collar line is 196.6 above the pelvis and the apron end 26.5 below it (outlines included); the neck above the collar is not in the ruler.
# Joints: Torso = the middle of the apron end (x 165-368 on row 895; the arm, the fist and the pin are on the viewer's right), pelvis row = 903 + 1 - 26.5 / K = 850.0.
#   Legs = the seam line between the two legs (x 1066 - no gap), pelvis row = top row 493 + 13.9 / (K x 1.15): the top edge sits 13.9 above the pelvis, behind the apron.
#   Head = the face centre (x 55-282 on row 230 for the first head), neck joint = chin bottom row 312 + 1 + 8 / (K x 1.157) - the chin is 8 above the neck joint as in the sketch; no neck stub (the neck is the torso's).
#   Hat = the band centre; with hat_at (0, -104) its band bottom sits at -87 (the cloth cap's band bottom is at -98.8, so 11.8 lower; the brows start at about -83) and its top with the 3 px box margin at -154 (top with the hat 354.0).
#   Feather = joint so that its thin end sits 50 units right of the hat origin and 16 above it (the sketch's place). Arm = centre, top + 14.6 units. Hand = centre, top + 2.6 units. Sword = centre, bottom - 15.6 units.
# Scales: the sheet drew the heads small against the torso (the front drew them large): heads 1.157 (top 326, head figure 126); the hat 0.962 is the smallest that is wider than the cloth cap
#   while the top with the hat stays under 355 (the baker's cap came out taller for its width than the sketch's); legs 1.15 both ways (toe 204.3, top width 87 - the sheet drew them short, as the front did);
#   arm, hand and sword 0.92 (arm 99.1, fist 39.7 = bartolo's fist). Torso 1 x 1 (belly 166.7 at the sketch's 164.6).
@{
  Sheet = 'docs\style\basis\guglielmo-parts.png'
  Out = 'assets\art\opponents\guglielmo'
  K = 0.4903
  Parts = @(
    @('Head', 'head', 51, 102, 286, 315, 169, 327.1, 1.157, 1.157), @('HeadOops', 'head_oops', 334, 102, 571, 315, 453.5, 327.1, 1.157, 1.157),
    @('HeadDizzy', 'head_dizzy', 613, 102, 851, 315, 733, 327.1, 1.157, 1.157), @('Hat', 'hat', 913, 153, 1184, 297, 1049, 259.0, 0.962, 0.962),
    @('Feather', 'feather', 1236, 205, 1484, 282, 1133.0, 295.9, 0.962, 0.962), @('Torso', 'torso', 94, 415, 506, 906, 267, 850.0, 1, 1),
    @('Legs', 'legs', 986, 490, 1146, 882, 1066.5, 517.65, 1.15, 1.15), @('Arm', 'arm', 591, 506, 677, 763, 634.5, 541.4, 0.92, 0.92),
    @('Hand', 'hand', 774, 609, 867, 694, 821, 617.8, 0.92, 0.92), @('Sword', 'sword', 1260, 455, 1393, 864, 1326.5, 826.4, 0.92, 0.92)
  )
}
