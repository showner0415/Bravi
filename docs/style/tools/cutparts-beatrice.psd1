# Plan 044b task 4: Beatrice's parts sheet (basis/beatrice-parts.png, P1a). Same form as cutparts-agostino.psd1; a box is the opaque bounding box + 3.
# Each part: name, file, box x0,y0,x1,y1 (sheet px), joint x,y (sheet px), scale x,y. units_per_px = K * scale.
# K = 207.2 / (belt bottom 738 - shoulder top 484 + 1) = 0.8125: the sketch's bodice runs from its shoulder line 194.6 above the pelvis to the belt's bottom edge 12.6 below it (outlines included).
# Joints: Torso = centre of the belt band (x 156-289 on row 730; the arm, the cord and the hat box hang on the viewer's right, so the blob centre is not the body centre), pelvis row = 738 + 1 - 12.6 / K.
#   Legs (the skirt) = centre of the skirt top (x 584-707), pelvis row = top row 461 + 17 / (K x 0.643): the top edge sits 17 above the pelvis, behind the bodice.
#   Head = the face centre (x 117-266 on row 250 for the first head; the pins are not symmetric), chin bottom row + 1 - 8.6 units (no neck stub: the bare neck belongs to the torso piece).
#   Hat = the brim centre. Feather = joint so that its base sits 12 units right of the hat origin and 10 below its own middle (the sketch's place).
#   Arm = centre, top 487 + 14.6 units. Hand = centre, top 560 + 2.6 units. Sword = centre, bottom 876 - 15.6 units (on the grip, under the guard).
# Scales: the sheet drew every part large against the bodice (as 042's did):
#   heads 0.746 (head figure 132, crown 109.6 above the joint, eye line about 265; neck stays -206); hat and feather 0.624 (hat 75 wide; hat_at -110 gives top with the hat about 352);
#   torso x 0.85 (the bodice came out stout: 108 wide at the belt against the sketch's 77; at x 1 the skirt top under the belt is narrower than the bodice and the seam supplement fails),
#   skirt x 0.615, y 0.643 (hem 205, toe 205 - it came out 1.6 x the bodice height and 3.1 x the belt width); arm, hand, sword 0.657 (arm 117 with the outlines; 042 needed 0.82).
@{
  Sheet = 'docs\style\basis\beatrice-parts.png'
  Out = 'assets\art\opponents\beatrice'
  K = 0.8125
  Parts = @(
    @('Head', 'head', 49, 84, 340, 327, 191.5, 307.8, 0.746, 0.746), @('HeadOops', 'head_oops', 381, 84, 671, 328, 523.5, 308.8, 0.746, 0.746),
    @('HeadDizzy', 'head_dizzy', 721, 84, 1012, 328, 863.5, 308.8, 0.746, 0.746), @('Hat', 'hat', 1054, 214, 1208, 311, 1131, 288, 0.624, 0.624),
    @('Feather', 'feather', 1265, 248, 1460, 302, 1244.3, 294.7, 0.624, 0.624), @('Torso', 'torso', 138, 439, 383, 879, 222.5, 723.5, 0.85, 1),
    @('Legs', 'legs', 439, 458, 855, 888, 647, 493.5, 0.615, 0.643), @('Arm', 'arm', 913, 484, 978, 709, 945.5, 514.3, 0.657, 0.657),
    @('Hand', 'hand', 1081, 557, 1154, 625, 1117.5, 564.9, 0.657, 0.657), @('Sword', 'sword', 1266, 448, 1390, 879, 1328, 846.8, 0.657, 0.657)
  )
}
