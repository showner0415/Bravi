extends RefCounted
## T74: 내 손 그림(계획 032). 손이 칼 뒤에 있고, 칼의 선, 어느 조준·상태에서도 소매 끝이 화면 밖, 비우면 자리 표시.
## T76: 내 칼 그림(계획 032b). 칠의 상태 색, 막기의 판, 틀, 비우면 다각형과 선.

const DT := preload("res://scripts/duel/duel_types.gd")
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const VIEW_PATH := "res://scenes/duel/player_sword_view.tscn"
const SCREEN := Vector2(1280, 720)
## 결정 305: 텍스처의 아래 두 모서리가 화면 아래 끝보다 이만큼 더 아래.
const SLEEVE_MARGIN := 8.0

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T74", "name": "내 손 그림: 칼 뒤의 손, 칼의 선, 소매 끝이 화면 밖(36경우), 비우면 자리 표시", "fn": t74_hand},
		{"id": "T76", "name": "내 칼 그림: 칠의 상태 색, 막기의 판, 틀, 비우면 다각형과 선", "fn": t76_sword},
	]


func cleanup() -> void:
	_tree = null


func t74_hand() -> String:
	var errs: Array[String] = []
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	var core: DuelCore = duel.get("core")
	var view := duel.get_node("PlayerSwordView") as PlayerSwordView
	var art := view.get_node("HandArt") as Sprite2D
	var sword := view.get_node("Sword") as Polygon2D
	if view.hand_art == null or not art.visible or art.texture != view.hand_art.texture:
		errs.append("HandArt가 보이지 않거나 텍스처가 hand_art와 다름")
	if art.get_index() >= sword.get_index():
		errs.append("HandArt가 Sword 앞(뒤에 그려짐)이 아님: %d, %d" % [art.get_index(), sword.get_index()])
	if (view.get_node("Hand") as CanvasItem).visible or (view.get_node("Label") as CanvasItem).visible:
		errs.append("그림이 있는데 Hand·Label이 보임")
	var outline := sword.get_node_or_null("Outline") as Line2D
	var warning := sword.get_node("BindWarning") as Line2D
	var sword_image := sword.get_node("Art") as Sprite2D
	if view.sword_art != null:
		# 칼 그림에는 선이 들어 있다(결정 328).
		if outline != null or not sword_image.visible or sword_image.texture != view.sword_art.texture:
			errs.append("칼 그림이 있는데 Outline이 있거나 Sword/Art가 보이지 않거나 텍스처가 다름")
		if not is_equal_approx(warning.width, PlayerSwordView.BIND_ART_WIDTH):
			errs.append("엉킴 경고 폭 %.1f (기대 %.1f)" % [warning.width, PlayerSwordView.BIND_ART_WIDTH])
	elif outline == null or outline.points != sword.polygon or not is_equal_approx(outline.width, PlayerSwordView.OUTLINE_WIDTH):
		errs.append("Sword/Outline이 없거나 점·폭이 다름")
	if warning.width <= PlayerSwordView.OUTLINE_WIDTH:
		errs.append("엉킴 경고 폭 %.1f가 칼 선보다 넓지 않음" % warning.width)
	_check_sleeve(core, view, art, errs)
	duel.free()
	var bare: Node = (load(VIEW_PATH) as PackedScene).instantiate()
	bare.set("hand_art", null)
	_tree.root.add_child(bare)
	if not (bare.get_node("Hand") as CanvasItem).visible or not (bare.get_node("Label") as CanvasItem).visible \
			or (bare.get_node("HandArt") as CanvasItem).visible:
		errs.append("hand_art를 비웠는데 자리 표시가 보이지 않거나 HandArt가 보임")
	bare.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


## 방향 3 × 높이 3 × 상태 넷(준비, 예비 동작의 끝, 회수의 처음, 막기). 상태는 코어의 필드를 직접 놓는다(판정 코드는 부르지 않는다).
func _check_sleeve(core: DuelCore, view: PlayerSwordView, art: Sprite2D, errs: Array[String]) -> void:
	var size := art.texture.get_size()
	var corners := [art.offset + Vector2(0, size.y), art.offset + size]
	# [이름, 상태, 표시 시각]
	var states := [["준비", DT.PlayerState.READY, 1.0], ["예비 동작 끝", DT.PlayerState.WINDUP, 1.0],
		["회수 처음", DT.PlayerState.RECOVER, 0.0], ["막기", DT.PlayerState.GUARD, 1.0]]
	var lowest := INF
	for dir in [DT.Direction.LEFT, DT.Direction.CENTER, DT.Direction.RIGHT]:
		for hgt in [DT.Height.HIGH, DT.Height.MID, DT.Height.LOW]:
			for st: Array in states:
				core.player_state = st[1]
				core.player_state_start = 0.0
				core.player_state_end = 1.0
				core.aim_direction = dir
				core.aim_height = hgt
				core.attack_direction = dir
				core.attack_height = hgt
				view.setup()
				view.update_view(core, st[2], SCREEN, 1.0)
				var xf := art.get_global_transform()
				for c: Vector2 in corners:
					var y := (xf * c).y
					lowest = minf(lowest, y)
					if y < SCREEN.y + SLEEVE_MARGIN:
						errs.append("소매 끝이 화면 안: 방향 %d 높이 %d %s, 모서리 y %.1f" % [dir, hgt, st[0], y])
	if errs.is_empty():
		print("  INFO T74 소매 모서리의 가장 높은 y %.1f (기대 728.1)" % lowest)


func _pose(core: DuelCore, view: PlayerSwordView, state: int, fresh := false) -> void:
	core.player_state = state
	core.player_state_start = 0.0
	core.player_state_end = 1.0
	core.aim_direction = DT.Direction.CENTER
	core.aim_height = DT.Height.MID
	core.attack_direction = DT.Direction.CENTER
	core.attack_height = DT.Height.MID
	core.guard_fresh = fresh
	core.guard_enter_time = 0.5 if fresh else -INF
	view.setup()
	# 번쩍임이 남지 않게 시계를 넉넉히 흘린다.
	view.update_view(core, 0.5, SCREEN, 1.0)


func t76_sword() -> String:
	var errs: Array[String] = []
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	duel.set_process(false)
	duel.set_physics_process(false)
	var core: DuelCore = duel.get("core")
	var view := duel.get_node("PlayerSwordView") as PlayerSwordView
	var sword := view.get_node("Sword") as Polygon2D
	var art := sword.get_node("Art") as Sprite2D
	var upp := view.sword_art.units_per_px if view.sword_art != null else Vector2.ONE
	if view.sword_art == null or not art.visible or not (art.material is ShaderMaterial):
		errs.append("칼 그림이 없거나 Sword/Art에 상태 색 재질이 없음")
		duel.free()
		return ", ".join(errs)
	var material := art.material as ShaderMaterial
	# 1. 상태마다 칼의 색과 그림의 틴트가 같다.
	var cases := [["준비", DT.PlayerState.READY, false, PlayerSwordView.COLOR_READY], ["예비 동작", DT.PlayerState.WINDUP, false, PlayerSwordView.COLOR_WINDUP],
		["회수", DT.PlayerState.RECOVER, false, PlayerSwordView.COLOR_RECOVER], ["막기", DT.PlayerState.GUARD, false, PlayerSwordView.COLOR_GUARD],
		["갓 올린 막기", DT.PlayerState.GUARD, true, PlayerSwordView.COLOR_GUARD_FRESH], ["이동", DT.PlayerState.STEPPING, false, PlayerSwordView.COLOR_STEPPING]]
	for row: Array in cases:
		_pose(core, view, row[1], row[2])
		var want: Color = row[3]
		var tint: Vector3 = material.get_shader_parameter(&"tint_color")
		if not sword.color.is_equal_approx(want) or not tint.is_equal_approx(Vector3(want.r, want.g, want.b)):
			errs.append("%s: 칼 색 %s, 틴트 %s (기대 %s)" % [row[0], sword.color, tint, want])
		# 2. 막기: 판은 1.8배이고 조금 비친다. 그림은 늘지 않는다.
		var guarding: bool = row[1] == DT.PlayerState.GUARD
		var want_alpha := PlayerSwordView.GUARD_PLATE_ALPHA if guarding else 0.0
		if not is_equal_approx(sword.self_modulate.a, want_alpha) or not is_equal_approx(sword.scale.x, PlayerSwordView.GUARD_WIDTH if guarding else 1.0):
			errs.append("%s: 판의 알파 %.3f·가로 배율 %.2f" % [row[0], sword.self_modulate.a, sword.scale.x])
		if absf(art.scale.x * sword.scale.x - upp.x) > 0.001:
			errs.append("%s: 그림의 가로 배율 %.4f (기대 %.4f, 늘지 않는다)" % [row[0], art.scale.x * sword.scale.x, upp.x])
	if not is_equal_approx(float(material.get_shader_parameter(&"tint_amount")), PlayerSwordView.TINT_AMOUNT):
		errs.append("틴트의 세기가 TINT_AMOUNT가 아님")
	# 패리의 번쩍임도 칼의 색으로 간다(시계를 흘리지 않고 본다).
	_pose(core, view, DT.PlayerState.GUARD)
	view.on_event({"type": DuelRecord.STRIKE, "result": DT.StrikeResult.PARRIED})
	view.update_view(core, 0.5, SCREEN, 0.0)
	if not sword.color.is_equal_approx(PlayerSwordView.COLOR_PARRY):
		errs.append("패리 뒤 칼 색 %s (기대 금빛)" % sword.color)
	# 3. 틀: 칼끝 −280(판 P1b에서 사용자가 고른 긴 칼날), 아랫변 +4, 폭 104 안, 좌우 대칭. 엉킴 테두리는 판의 꼴.
	var size := art.texture.get_size()
	var top := (art.offset.y) * upp.y
	var bottom := (art.offset.y + size.y) * upp.y
	var left := art.offset.x * upp.x
	var right := (art.offset.x + size.x) * upp.x
	if absf(top + 280.0) > 3.0 or absf(bottom - 4.0) > 2.0 or right - left > 104.0 or absf(right + left) > 4.0:
		errs.append("칼 그림의 틀: 위 %.1f 아래 %.1f 왼 %.1f 오른 %.1f" % [top, bottom, left, right])
	var rim := art.get_node_or_null("Rim") as Line2D
	if rim == null or absf(rim.width * upp.x - 2.0 * PlayerSwordView.RIM_WIDTH) > 0.01 or rim.points.size() != sword.polygon.size():
		errs.append("칼 둘레의 짙은 테(Sword/Art/Rim)가 없거나 폭·점이 다름")
	if (sword.get_node("BindWarning") as Line2D).points != sword.polygon:
		errs.append("엉킴 테두리의 점이 판의 다각형과 다름")
	if Geometry2D.triangulate_polygon(sword.polygon).is_empty():
		errs.append("판의 다각형이 삼각형으로 나뉘지 않음(자기 교차)")
	duel.free()
	# 4. 칼 그림을 비우면 지금까지의 다각형과 선이다.
	var bare: Node = (load(VIEW_PATH) as PackedScene).instantiate()
	bare.set("sword_art", null)
	_tree.root.add_child(bare)
	var bare_sword := bare.get_node("Sword") as Polygon2D
	if bare_sword.polygon.size() != 8 or bare_sword.get_node_or_null("Outline") == null or (bare_sword.get_node("Art") as CanvasItem).visible \
			or not is_equal_approx(bare_sword.self_modulate.a, 1.0) \
			or not is_equal_approx((bare_sword.get_node("BindWarning") as Line2D).width, PlayerSwordView.BIND_OUTLINE_WIDTH):
		errs.append("sword_art를 비웠는데 여덟 점·선·알파 1·경고 폭 10의 꼴이 아님")
	bare.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
