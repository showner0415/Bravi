extends RefCounted
## T14, T24: 결투 씬 테스트. 씬을 트리에 붙이고 advance(delta)를 직접 불러 시간을 흘린다.

const OPPONENT_VIEW_PATH := "res://scenes/duel/opponent_view.tscn"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const Bot := preload("res://tests/duel_bots.gd")

## 이후 아트와 리깅의 기준이 되는 파츠 경로 7개.
const PART_PATHS: Array[NodePath] = [
	^"Legs", ^"Torso", ^"Torso/Head", ^"Torso/Head/Hat",
	^"Torso/Arm", ^"Torso/Arm/Hand", ^"Torso/Arm/Hand/Sword",
]

var _tree: SceneTree
var _mouse_pos := Vector2.ZERO


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T14", "name": "상대 파츠 경로 7개, 결투 씬 600프레임", "fn": t14_scene},
		{"id": "T24", "name": "실제 입력 이벤트: 마우스 조준, 좌·우클릭, W/S, F1, Esc, R", "fn": t24_real_input},
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
		_brace_and_close_hit(duel, errs)
	duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


## 올려 막기와 밀착 피격의 표시 경로(계획 003): 새 이벤트 키(braced, posture_loss)를 읽는 HUD와 상대 뷰,
## F1 디버그의 포맷 문자열이 오류 없이 도는지 본다. 기대값은 로드한 상대 데이터에서 끌어온다
## (스위치 표의 값을 바꿔도 이 테스트는 통과해야 한다).
func _brace_and_close_hit(duel: Node, errs: Array[String]) -> void:
	duel.call("start_duel")
	var core: DuelCore = duel.get("core")
	var hud := duel.get_node("HUD")
	hud.call("toggle_debug")
	var opp := core.opponent_data
	var has_habit := false
	var marked := false
	for habit in opp.habits:
		if habit.response != null:
			has_habit = true
			marked = marked or habit.response.needs_raised_guard

	# 버릇 반응 타격을 한 번 막은 뒤부터는 막지 않는다(버릇이 없는 데이터면 여덟 번 막은 뒤부터).
	var in_habit_tell: Array[bool] = [false]
	var habit_strikes: Array[Dictionary] = []
	var hits: Array[Dictionary] = []
	core.event.connect(func(ev: Dictionary) -> void:
		if ev["type"] == DuelRecord.TELL_START:
			in_habit_tell[0] = ev["is_habit"]
		elif ev["type"] == DuelRecord.STRIKE:
			if in_habit_tell[0] and ev["result"] == DuelTypes.StrikeResult.BLOCKED:
				habit_strikes.append(ev)
			elif ev["result"] == DuelTypes.StrikeResult.GRAZE:
				hits.append(ev))
	var guard_fn := func(_a: AttackData, i: int) -> StringName:
		return &"none" if (not habit_strikes.is_empty() or i > 8) else &"keep"
	var bot: RefCounted = Bot.new(core, {"guard_fn": guard_fn, "want_distance": DuelTypes.Distance.CLOSE})

	var frames := 0
	while frames < 3600 and hits.is_empty() and not core.ended:
		duel.call("advance", 1.0 / 60.0)
		bot.call("update")
		frames += 1
	var distance_at_hit := core.distance
	for i in 40:
		duel.call("advance", 1.0 / 60.0)
		bot.call("update")
	hud.call("toggle_debug")

	if has_habit:
		if habit_strikes.size() != 1:
			errs.append("막은 버릇 반응 타격 %d개 (기대 1)" % habit_strikes.size())
		elif habit_strikes[0]["braced"] != marked:
			errs.append("버릇 반응을 들고만 있던 막기로 받았는데 braced가 %s (표시 여부 %s)" % [habit_strikes[0]["braced"], marked])
	if hits.is_empty():
		errs.append("막지 않았는데 60초 동안 맞지 않음")
	else:
		var want := mini(maxi(opp.close_hit_posture_loss, 1), core.rules.player_posture_max)
		if distance_at_hit != DuelTypes.Distance.CLOSE:
			errs.append("맞은 순간의 간격이 밀착이 아님")
		elif hits[0]["posture_loss"] != want:
			errs.append("밀착에서 맞아 깎인 칸 %d (기대 %d)" % [hits[0]["posture_loss"], want])


# ================================================================ T24

## 실제 InputEvent를 엔진의 입력 경로(Input → 창 → _unhandled_input)로 흘려 보낸다.
func _send(ev: InputEvent) -> void:
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


## pos는 뷰포트 좌표다. 이벤트는 창 좌표로 보낸다(헤드리스의 창은 64x64라 늘이기 변환이 걸린다).
func _send_mouse_move(pos: Vector2) -> void:
	var window_pos := _tree.root.get_screen_transform() * pos
	var ev := InputEventMouseMotion.new()
	ev.position = window_pos
	ev.global_position = window_pos
	_mouse_pos = window_pos
	_send(ev)


func _send_mouse_button(button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	ev.position = _mouse_pos
	ev.global_position = _mouse_pos
	_send(ev)


func _send_key(key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = key
		ev.physical_keycode = key
		ev.pressed = pressed
		_send(ev)


func _advance(duel: Node, seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		duel.call("advance", 1.0 / 60.0)


## 봇이 코어에 직접 넣는 입력이 아니라, 마우스·키보드 이벤트가 결투 씬을 거쳐 코어에 닿는지 본다.
func t24_real_input() -> String:
	var errs: Array[String] = []
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("rng_seed", 1)  # mouse_aim_enabled는 기본값(켜짐) 그대로 둔다
	_tree.root.add_child(duel)
	var core: DuelCore = duel.get("core")
	var size: Vector2 = (duel as Node2D).get_viewport_rect().size

	# 마우스 위치 → 조준 3x3 칸
	for column in 3:
		for row in 3:
			_send_mouse_move(Vector2((column + 0.5) / 3.0 * size.x, (row + 0.5) / 3.0 * size.y))
			_advance(duel, 1.0 / 60.0)
			if core.aim_direction != column or core.aim_height != row:
				errs.append("마우스 칸 (%d,%d) → 조준 (%d,%d)" % [column, row, core.aim_direction, core.aim_height])

	# W / S → 간격 한 단계 전진 / 후퇴
	_send_key(KEY_W)
	if core.player_state != DuelTypes.PlayerState.STEPPING:
		errs.append("W를 눌렀는데 이동 상태가 아님")
	_advance(duel, core.weapon.step_time + 0.05)
	if core.distance != DuelTypes.Distance.ENGAGE:
		errs.append("W 뒤 간격이 교전이 아님 (%d)" % core.distance)
	_send_key(KEY_S)
	_advance(duel, core.weapon.step_time + 0.05)
	if core.distance != DuelTypes.Distance.FAR:
		errs.append("S 뒤 간격이 멀리가 아님 (%d)" % core.distance)

	# 우클릭 누르고 있기 → 막기, 떼면 풀림
	_send_mouse_button(MOUSE_BUTTON_RIGHT, true)
	if not core.guard_held or core.player_state != DuelTypes.PlayerState.GUARD:
		errs.append("우클릭을 눌렀는데 막기 상태가 아님")
	_advance(duel, 0.1)
	if core.player_state != DuelTypes.PlayerState.GUARD:
		errs.append("우클릭을 누르고 있는데 막기가 풀림")
	_send_mouse_button(MOUSE_BUTTON_RIGHT, false)
	if core.guard_held or core.player_state != DuelTypes.PlayerState.READY:
		errs.append("우클릭을 뗐는데 막기가 풀리지 않음")

	# 좌클릭 → 공격 예비
	_send_mouse_button(MOUSE_BUTTON_LEFT, true)
	if core.player_state != DuelTypes.PlayerState.WINDUP:
		errs.append("좌클릭을 눌렀는데 공격 예비 상태가 아님")
	_send_mouse_button(MOUSE_BUTTON_LEFT, false)

	# F1 → 디버그 표시 켜기 / 끄기
	var debug_label: Label = duel.get_node("HUD").get("_debug_label")
	_send_key(KEY_F1)
	if not debug_label.visible:
		errs.append("F1을 눌렀는데 디버그 표시가 켜지지 않음")
	_send_key(KEY_F1)
	if debug_label.visible:
		errs.append("F1을 다시 눌렀는데 디버그 표시가 꺼지지 않음")

	# Esc → 다른 노드 아래에 붙어 있을 때는 아무 일도 없다
	_send_key(KEY_ESCAPE)
	if not is_instance_valid(duel) or not duel.is_inside_tree():
		errs.append("Esc가 테스트 중인 씬을 바꿈")

	# R → 새 판
	_send_key(KEY_R)
	var new_core: DuelCore = duel.get("core")
	if new_core == core:
		errs.append("R을 눌렀는데 새 판이 시작되지 않음")
	elif new_core.time != 0.0 or new_core.player_state != DuelTypes.PlayerState.READY:
		errs.append("R 뒤의 새 판이 처음 상태가 아님")

	duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
