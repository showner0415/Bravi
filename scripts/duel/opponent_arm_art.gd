class_name OpponentArmArt
extends RefCounted
## 따로 그린 팔의 묶음과 손의 바깥 윤곽선을 만든다(결정 266·268·269). OpponentView가 부른다.

const ARM := &"Arm"


## 손 그림의 다각형(자른 그림의 화소 모서리 좌표)을 파츠 단위로 바꿔 굵기의 절반만큼 바깥으로 민다.
## 모서리 좌표라 (점 - 관절) x 단위/화소에 반 화소 차이가 없다(Sprite2D centered = false, 결정 269).
static func outline_points(pa: PartArt, width: float) -> PackedVector2Array:
	if pa == null or pa.outline.is_empty():
		return PackedVector2Array()
	var poly := PackedVector2Array()
	for p in pa.outline:
		poly.append((p - pa.joint) * pa.units_per_px)
	var best := _largest(Geometry2D.offset_polygon(poly, width * 0.5, Geometry2D.JOIN_ROUND))
	# 민 쪽은 꼭짓점의 돌림 방향에 달려 있다: 작아졌으면 반대로 민다(T70은 점이 다각형 밖인지 본다).
	if absf(_area(best)) < absf(_area(poly)):
		best = _largest(Geometry2D.offset_polygon(poly, -width * 0.5, Geometry2D.JOIN_ROUND))
	return best


static func _largest(polys: Array[PackedVector2Array]) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := -1.0
	for p in polys:
		var area := absf(_area(p))
		if area > best_area:
			best_area = area
			best = p
	return best


static func make_outline(pa: PartArt, width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.name = "Outline"
	line.closed = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.width = width
	line.default_color = color
	line.points = outline_points(pa, width)
	line.visible = false
	return line


## 묶음 하나: 층마다 Sprite2D(부위가 있으면 재질), 주먹 층마다 윤곽선을 끝에 둔다(칼 위에 그려지게).
## mats에는 부위 -> 재질 배열을 채운다. 돌려주는 노드는 감춘 채다.
static func build_group(arm_art: ArmArt, new_material: Callable, outline_units: float,
		outline_color: Color, mats: Dictionary, outlines: Array[Line2D]) -> Node2D:
	var group := Node2D.new()
	group.name = String(arm_art.key)
	group.rotation_degrees = arm_art.rotation_deg
	group.visible = false
	var fists: Array[ArmLayer] = []
	for layer in arm_art.layers:
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = layer.texture
		sprite.offset = -layer.joint
		sprite.scale = layer.units_per_px
		if layer.part >= 0:
			var mat: ShaderMaterial = new_material.call()
			mat.set_shader_parameter(&"outline_texels",
					Vector2(outline_units / layer.units_per_px.x, outline_units / layer.units_per_px.y))
			sprite.material = mat
			if not mats.has(layer.part):
				mats[layer.part] = []
			(mats[layer.part] as Array).append(mat)
		if layer.part == DuelTypes.Part.SWORD_HAND:
			fists.append(layer)
		group.add_child(sprite)
	for fist in fists:
		var line := make_outline(fist, outline_units, outline_color)
		group.add_child(line)
		outlines.append(line)
	return group


static func _area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		s += a.x * b.y - b.x * a.y
	return s * 0.5


static func art_of(pose: PoseData) -> StringName:
	return pose.arm_art if pose != null else ARM


## 바뀜이 시작될 때 앞 국면이 보이던 팔 그림(결정 268). 예비 동작에서 곧장 대기로 왔으면, 새 시작이 그 예비 동작의
## 끝(타격 시각) 이후일 때만 타격이 있었던 것으로 본다(찌르기는 회수가 0이라 막히면 곧장 대기다).
## 앞이 쉬는 상태(대기·방심·무너짐)이거나 없으면 그때 보이던 그림 shown이다: 대기 중 경계를 다시 세울 때 깜빡이지 않게(결정 285).
static func leaving(last_state: int, last_attack: AttackData, last_state_end: float, new_start: float,
		shown: StringName = ARM) -> StringName:
	if last_state < 0 or last_state == DuelTypes.OpponentState.IDLE or last_state == DuelTypes.OpponentState.STAGGER:
		return shown
	if last_attack == null:
		return ARM
	if last_state == DuelTypes.OpponentState.TELL:
		return art_of(last_attack.strike_pose if new_start >= last_state_end else last_attack.tell_pose)
	if last_state == DuelTypes.OpponentState.RECOVERY:
		return art_of(last_attack.strike_pose)
	return ARM
