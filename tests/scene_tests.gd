extends RefCounted
## T14, T24: 결투 씬 테스트. 씬을 트리에 붙이고 advance(delta)를 직접 불러 시간을 흘린다.

const OPPONENT_VIEW_PATH := "res://scenes/duel/opponent_view.tscn"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const Plain := preload("res://tests/plain_opponent.gd")
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
		{"id": "T42", "name": "씬: 모자, 조준 윗줄, 칸 수와 머리 지키기의 표시", "fn": t42_hat_and_display},
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
	# 다른 규칙을 보는 테스트다: 패턴·높이·확률을 끈 옛 규칙 사본이다(결정 416·426). 하루의 판 길이는 T90.
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
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
	# 이 판은 엉킴 없는 무기로 돌린다(막기를 누른 채 밀착에 오래 머문다). 엉킴이 있는 씬 경로는 T48이 본다.
	var no_bind := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	no_bind.close_bind_time = 0.0
	duel.set("test_weapon", no_bind)
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
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
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

	# Esc → 멈춤 화면(계획 S02). 씬은 그대로이고, 한 번 더 누르면 닫혀 돌아오기 대기에 든다.
	_send_key(KEY_ESCAPE)
	if not is_instance_valid(duel) or not duel.is_inside_tree():
		errs.append("Esc가 테스트 중인 씬을 바꿈")
	elif not duel.get("paused") or duel.get_node_or_null(^"PauseMenu") == null:
		errs.append("Esc를 눌렀는데 멈춤 화면이 뜨지 않음")
	else:
		_send_key(KEY_ESCAPE)
		if duel.get_node_or_null(^"PauseMenu") != null:
			errs.append("멈춤 화면에서 Esc를 눌렀는데 닫히지 않음")
		elif not duel.get("paused"):
			errs.append("멈춤 화면을 닫은 직후 돌아오기 대기가 아님")

	# R → 새 판(대기도 지워진다)
	_send_key(KEY_R)
	var new_core: DuelCore = duel.get("core")
	if new_core == core:
		errs.append("R을 눌렀는데 새 판이 시작되지 않음")
	elif new_core.time != 0.0 or new_core.player_state != DuelTypes.PlayerState.READY:
		errs.append("R 뒤의 새 판이 처음 상태가 아님")
	if duel.get("paused"):
		errs.append("R 뒤에도 멈춤 상태가 남음")

	duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


# ================================================================ T42 모자와 표시

const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const HAT_PATH := ^"OpponentView/Torso/Head/Hat"


## 결투 씬을 붙인다(마우스 조준 끔, 시드 1). commission이 null이면 의뢰 없는 결투다.
func _spawn_duel(commission: Commission) -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	if commission != null:
		var pinned := commission.duplicate() as Commission
		pinned.opponent = Plain.of(commission.opponent)
		duel.set("commission", pinned)
	else:
		duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	return duel


## 그 조준으로 한 프레임 흘린 뒤의 조준 글자.
func _aim_text(duel: Node, direction: int, height: int) -> String:
	var core: DuelCore = duel.get("core")
	core.set_aim(direction, height)
	duel.call("advance", 1.0 / 60.0)
	return (duel.get_node("HUD").get("_aim_label") as Label).text


func t42_hat_and_display() -> String:
	var errs: Array[String] = []
	var D := DuelTypes.Direction
	var H := DuelTypes.Height
	var P := DuelTypes.Part

	# ---- 깃털 의뢰: 모자를 쓴 판
	var feather := _spawn_duel(load(FEATHER_PATH) as Commission)
	var core: DuelCore = feather.get("core")
	var sword_side: int = core.opponent_data.sword_side
	var off_side: int = D.RIGHT if sword_side == D.LEFT else D.LEFT
	if not core.opponent_has_hat:
		errs.append("깃털 의뢰의 판이 모자를 쓴 판이 아님")
	if not (feather.get_node(HAT_PATH) as CanvasItem).visible:
		errs.append("깃털 의뢰인데 모자 파츠가 보이지 않음")
	core.set_aim(off_side, H.HIGH)
	if core.current_aim_part() != P.HAT:
		errs.append("깃털 의뢰의 반대쪽 상단 베기가 모자가 아님")
	feather.call("start_duel")
	core = feather.get("core")
	if not core.opponent_has_hat or not (feather.get_node(HAT_PATH) as CanvasItem).visible:
		errs.append("깃털 의뢰에서 새 판을 시작하니 모자가 사라짐")
	feather.free()

	# ---- 첫 피 의뢰와 의뢰 없는 결투: 모자 없는 판
	for commission: Commission in [load(FIRST_BLOOD_PATH) as Commission, null]:
		var label := "첫 피 의뢰" if commission != null else "의뢰 없는 결투"
		var bare := _spawn_duel(commission)
		var bare_core: DuelCore = bare.get("core")
		if bare_core.opponent_has_hat or (bare.get_node(HAT_PATH) as CanvasItem).visible:
			errs.append("[%s] 모자를 쓴 판이거나 모자 파츠가 보임" % label)
		bare_core.set_aim(off_side, H.HIGH)
		if bare_core.current_aim_part() != P.HEAD:
			errs.append("[%s] 반대쪽 상단 베기가 머리가 아님" % label)
		bare_core.set_aim(sword_side, H.HIGH)
		if bare_core.current_aim_part() != P.SWORD_HAND:
			errs.append("[%s] 칼 쪽 상단 베기가 칼 든 손이 아님" % label)
		bare.free()

	# ---- 조준 글자와 조작 안내(기대값은 로드한 상대에서 끌어온다)
	var duel := _spawn_duel(null)
	core = duel.get("core")
	var opp := core.opponent_data
	# 모자 없는 판에서 부위마다의 조준.
	var aims := {
		P.HEAD: [D.CENTER, H.HIGH], P.SWORD_HAND: [sword_side, H.HIGH],
		P.TORSO: [D.CENTER, H.MID], P.SWORD_ARM: [sword_side, H.MID], P.LEGS: [D.CENTER, H.LOW],
	}
	# 조작 안내는 결투 화면이 아니라 처음 화면의 도움말이 보인다(결정 323). 글은 같은 함수가 만든다.
	var help: String = DuelHud.help_text(opp, false, core.opponent_has_hat, core.weapon)
	for part: int in aims:
		var text := _aim_text(duel, aims[part][0], aims[part][1])
		var heavy := opp.graze_cells(part) >= 2
		if text.contains("칸)") != heavy:
			errs.append("[조준 글자] %s(%d칸): '%s'" % [DuelTypes.PART_NAMES[part], opp.graze_cells(part), text])
	help = DuelHud.help_text(opp, false, core.opponent_has_hat, core.weapon)
	for part: int in aims:
		if opp.graze_cells(part) >= 2 and not help.contains(DuelTypes.PART_NAMES[part]):
			errs.append("[조작 안내] 2칸 이상인 %s의 이름이 없음" % DuelTypes.PART_NAMES[part])
	if help.contains("머리는 ") != opp.guards_head:
		errs.append("[조작 안내] 머리 지키기 안내의 유무가 상대 데이터와 다름")

	# ---- 표시 경로(F1 디버그를 켠 채): 칼 든 팔 스침, 큰 베기 뒤 칼 든 손 스침, 머리를 노려 피해짐
	duel.call("start_duel")
	core = duel.get("core")
	duel.get_node("HUD").call("toggle_debug")
	var has_big := false
	for habit in opp.habits:
		has_big = has_big or (habit.response != null and habit.response.is_big)
	var plain_counters: Array[int] = [0]
	var counter := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		if (ev["attack"] as AttackData).is_big:
			return [sword_side, H.HIGH]
		# 그냥 막힌 베기 뒤: 처음에는 머리(지키면 피한다), 그다음부터는 칼 든 팔.
		plain_counters[0] += 1
		return [D.CENTER, H.HIGH] if plain_counters[0] == 1 else [sword_side, H.MID]
	var bot: RefCounted = Bot.new(core, {"counter_fn": counter})
	var state_label := duel.get_node("OpponentView/StateLabel") as Label
	var log_label := duel.get_node("HUD").get("_log_label") as Label
	var plain_texts: Array[String] = []
	var big_texts: Array[String] = []
	var saw := {"arm": false, "hand": false, "dodged": false, "cells_log": false, "dodge_log": false}
	var frames := 0
	while frames < 5400 and not core.ended:
		duel.call("advance", 1.0 / 60.0)
		bot.call("update")
		frames += 1
		if core.brain.state == DuelTypes.OpponentState.RECOVERY and core.brain.current_attack != null:
			if core.brain.current_attack.is_big:
				big_texts.append(state_label.text)
			elif not core.brain.wide_open:
				plain_texts.append(state_label.text)
		if log_label.text.contains("(-"):
			saw["cells_log"] = true
		if log_label.text.contains("머리를 피했다"):
			saw["dodge_log"] = true
		for ev in core.record.of_type(DuelRecord.ATTACK):
			if ev["result"] == DuelTypes.AttackResult.GRAZE and ev["part"] == P.SWORD_ARM:
				saw["arm"] = true
			if ev["result"] == DuelTypes.AttackResult.GRAZE and ev["part"] == P.SWORD_HAND:
				saw["hand"] = true
			if ev["dodged"]:
				saw["dodged"] = true
		if saw["arm"] and (saw["hand"] or not has_big) and (saw["dodged"] or not opp.guards_head) and frames > 600:
			break
	if not saw["arm"]:
		errs.append("[표시] 칼 든 팔을 스치지 못함")
	if has_big and not saw["hand"]:
		errs.append("[표시] 큰 베기 뒤에 칼 든 손을 스치지 못함")
	if opp.guards_head:
		if not saw["dodged"] or not saw["dodge_log"]:
			errs.append("[표시] 머리를 노린 공격이 피해지지 않았거나 기록 줄이 없음")
	elif saw["dodged"]:
		errs.append("[표시] 머리를 지키지 않는 상대가 피함")
	if (opp.graze_cells(P.SWORD_ARM) >= 2 or (has_big and opp.graze_cells(P.SWORD_HAND) >= 2)) and not saw["cells_log"]:
		errs.append("[표시] 2칸 스침의 기록 줄에 깎인 칸 수가 없음")

	# ---- 상태 글자: 그냥 막힌 베기의 회수는 "빈틈", 큰 베기의 회수는 머리를 지키는 상대면 "크게 열림!"
	for text in plain_texts:
		if text != "빈틈":
			errs.append("[상태 글자] 그냥 막힌 베기의 회수 중 글자가 '%s'" % text)
			break
	var want_big := "크게 열림!" if opp.guards_head else "빈틈"
	for text in big_texts:
		if text != want_big:
			errs.append("[상태 글자] 큰 베기의 회수 중 글자가 '%s' (기대 '%s')" % [text, want_big])
			break
	if plain_texts.is_empty():
		errs.append("[상태 글자] 그냥 막힌 베기의 회수를 한 번도 보지 못함")
	if has_big and big_texts.is_empty():
		errs.append("[상태 글자] 큰 베기의 회수를 한 번도 보지 못함")
	duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
