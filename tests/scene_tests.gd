extends RefCounted
## T14: 결투 씬 테스트. 씬을 트리에 붙이고 advance(delta)를 직접 불러 시간을 흘린다.

const OPPONENT_VIEW_PATH := "res://scenes/duel/opponent_view.tscn"
const DUEL_PATH := "res://scenes/duel/duel.tscn"

## 이후 아트와 리깅의 기준이 되는 파츠 경로 7개.
const PART_PATHS: Array[NodePath] = [
	^"Legs", ^"Torso", ^"Torso/Head", ^"Torso/Head/Hat",
	^"Torso/Arm", ^"Torso/Arm/Hand", ^"Torso/Arm/Hand/Sword",
]

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T14", "name": "상대 파츠 경로 7개, 결투 씬 600프레임", "fn": t14_scene},
	]


func cleanup() -> void:
	_tree = null


func t14_scene() -> String:
	var errs: Array[String] = []

	var view: Node = (load(OPPONENT_VIEW_PATH) as PackedScene).instantiate()
	for path in PART_PATHS:
		if not view.has_node(path):
			errs.append("파츠 없음: %s" % path)
		elif not (view.get_node(path) is Node2D):
			errs.append("파츠가 Node2D가 아님: %s" % path)
	view.free()

	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	var core: DuelCore = duel.get("core")
	if core == null:
		errs.append("씬이 트리에 들어온 뒤에도 core가 없음")
	else:
		var tells: Array[int] = [0]
		core.event.connect(func(ev: Dictionary) -> void:
			if ev["type"] == DuelRecord.TELL_START:
				tells[0] += 1)
		for i in 600:
			duel.call("advance", 1.0 / 60.0)
		if tells[0] < 1:
			errs.append("600프레임 동안 상대가 예비 동작에 들어가지 않음")
		if not is_equal_approx(core.time, 10.0) and not core.ended:
			errs.append("코어 시각 %.3f (기대 10.0)" % core.time)

		# 섣부른 공격의 표시 경로: 새 판에서 대기 중인 상대를 공격하고 HUD와 상대 뷰가 이벤트를 받게 한다.
		duel.call("start_duel")
		core = duel.get("core")  # start_duel이 코어를 새로 만든다
		var waited := 0
		while waited < 600 and not (core.distance == DuelTypes.Distance.ENGAGE \
				and core.brain.state == DuelTypes.OpponentState.IDLE):
			duel.call("advance", 1.0 / 60.0)
			waited += 1
		# 돌아올 칸이 있어야 "+1" 글자 분기까지 지난다.
		core.brain.posture -= 1
		core.press_attack()
		for i in 40:
			duel.call("advance", 1.0 / 60.0)
		var rash_blocked := 0
		for ev in core.record.of_type(DuelRecord.ATTACK):
			if ev["rash"] and ev["posture_gain"] == 1:
				rash_blocked += 1
		if rash_blocked != 1:
			errs.append("대기 중인 상대를 공격했는데 칸을 돌려준 섣부른 공격이 %d개 (기대 1)" % rash_blocked)
	duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
