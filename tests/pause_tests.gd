extends RefCounted
## T98~T99: 멈춤과 나가기(계획 S02) — 멈춘 동안 판이 같이 멈추고, "계속"의 클릭이 공격이 되지 않고, 막기는 쥔 상태에 맞춘다 /
## 돌아올 날의 글, 창 닫기의 확인, 처음 화면의 게임 종료, 카운터·정산·폐점의 "잠깐".
## 입력은 T24처럼 엔진의 입력 경로(Input.parse_input_event)로 보낸다. 파일은 TEST_SAVE·TEST_SETTINGS만 쓰고 끝에 지운다.
## preload 상수 이름은 SessionScript·SettingsScript다: 자동 로드 이름(GameSession·Settings)과 겹치면 경고가 난다.
## 실제 get_tree().quit()은 불리지 않는다: 트리 밖 세션의 quit_game()은 아무것도 하지 않고, 처음 화면은 현재 씬이 아니다.

const Day := preload("res://tests/day_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const SessionScript := preload("res://scripts/game_session.gd")
const SettingsScript := preload("res://scripts/settings.gd")
const Store := preload("res://scripts/save_store.gd")

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const TEST_SAVE := "user://bravi_test_save_S02.json"
const TEST_SETTINGS := "user://bravi_test_settings_S02.json"
## 결투 씬의 HUD 판이 없는 곳(T24가 왼쪽 클릭을 보낸 자리와 같다). 대기 중의 좌클릭은 여기로 보낸다.
const FREE_SPOT := Vector2(1066, 600)

var _tree: SceneTree
var _d := Day.new()
var _mouse_pos := Vector2.ZERO
var _made: Array[Node] = []
var _bus_db := 0.0
var _bus_mute := false
var _bus_saved := false
## 실제 클릭이 버튼에 닿지 않아 pressed.emit()으로 바꾼 단계가 있는가(보고용).
var _click_fallback := false


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T98", "name": "멈춤: 판의 시간·상대가 같이 멈추고, '계속'의 클릭은 공격이 되지 않고, 막기는 쥔 상태에 맞춘다", "fn": t98_pause},
		{"id": "T99", "name": "나가기와 끄기: 돌아올 날의 글, 창 닫기의 확인, 처음 화면의 게임 종료, 잠깐", "fn": t99_quit},
	]


func cleanup() -> void:
	_free_made()
	_erase_files()
	_restore_bus()
	_d.cleanup()
	_d = null
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


func _free_made() -> void:
	for node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _erase_files() -> void:
	Store.erase(TEST_SAVE)
	Store.erase(TEST_SETTINGS)


func _restore_bus() -> void:
	if not _bus_saved:
		return
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, _bus_db)
		AudioServer.set_bus_mute(bus, _bus_mute)
	_bus_saved = false


func _send(ev: InputEvent) -> void:
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


## pos는 뷰포트 좌표다(T24와 같다: 헤드리스의 창은 64x64라 늘이기 변환이 걸린다).
func _move(pos: Vector2) -> void:
	var window_pos := _tree.root.get_screen_transform() * pos
	var ev := InputEventMouseMotion.new()
	ev.position = window_pos
	ev.global_position = window_pos
	_mouse_pos = window_pos
	_send(ev)


func _button(button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	ev.position = _mouse_pos
	ev.global_position = _mouse_pos
	_send(ev)


## ResumeHold는 HUD 바로 아래가 아니라 _root 아래에 있다. 못 찾으면 실패로 적고 보이지 않는 빈 라벨을 준다.
func _resume_hold(duel: Node, errs: Array[String]) -> Label:
	var found := duel.get_node("HUD").find_child("ResumeHold", true, false) as Label
	if found == null:
		errs.append("ResumeHold 라벨을 찾지 못함")
		return Label.new()
	return found


func _click(button: MouseButton) -> void:
	_button(button, true)
	_button(button, false)


func _key(key: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = key
		ev.physical_keycode = key
		ev.pressed = pressed
		_send(ev)


func _advance(duel: Node, seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		duel.call("advance", 1.0 / 60.0)


## 코드로 만든 컨테이너는 한 프레임 안에 자리를 잡지 않는다(러너는 프레임 없이 돈다): 위에서부터 한 번 앉힌다.
func _layout_now(node: Node) -> void:
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child in node.get_children():
		_layout_now(child)


## 연습 결투(바르톨로 옛 규칙 사본, 시드 1, 마우스 조준 끔). 끝에 놓는다.
func _spawn_practice() -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	_made.append(duel)
	return duel


## 결투 단계의 하루를 가진 하루 결투. [씬, DayState].
func _spawn_day_duel() -> Array:
	var day := DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed())
	day.accept()
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("day", day)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	_made.append(duel)
	return [duel, day]


func _menu_count(duel: Node) -> int:
	var count := 0
	for child in duel.get_children():
		if child is PauseMenu:
			count += 1
	return count


func _attack_starts(core: DuelCore) -> int:
	return core.record.of_type(DuelRecord.ATTACK_START).size()


## 멈춘 동안 같아야 하는 값들.
func _snapshot(duel: Node) -> Array:
	var core: DuelCore = duel.get("core")
	var time_label := duel.get_node("HUD").get("_time_label") as Label
	return [core.time, core.brain.state, core.brain.state_end, core.bind_gauge(), core.complacency(),
		core.player_state, core.record.events.size(), time_label.text]


func _focus_name() -> String:
	var owner := _tree.root.gui_get_focus_owner()
	return String(owner.name) if owner != null else ""


## 돌아오기 대기를 시각만 당겨 끝낸다(실시간 400밀리초를 기다리지 않는다).
func _finish_hold(duel: Node) -> void:
	duel.set("_hold_until_msec", 0)
	duel.call("_physics_process", 1.0 / 60.0)


func _label_with_text(root: Node, text: String) -> bool:
	for label in root.find_children("*", "Label", true, false):
		if (label as Label).text == text:
			return true
	return false


# ================================================================ T98

func t98_pause() -> String:
	var errs: Array[String] = []
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		_bus_db = AudioServer.get_bus_volume_db(bus)
		_bus_mute = AudioServer.is_bus_mute(bus)
		_bus_saved = true
	_erase_files()
	_click_fallback = false

	# 검사마다 씬을 놓는다: 남은 결투가 같은 Esc를 또 받아 멈춤 화면을 더 열지 않게.
	_check_freeze(errs)
	_free_made()
	_check_resume_click(errs)
	_free_made()
	_check_guard(errs)
	_free_made()
	_check_focus(errs)
	_free_made()
	_check_ended(errs)
	_free_made()
	_check_exit_shape(errs)
	_free_made()
	_check_settings(errs)
	_free_made()
	_check_retry(errs)

	if _click_fallback:
		print("  INFO T98 [2] 실제 클릭이 PauseResume에 닿지 않아 pressed.emit()으로 바꿈")
	_free_made()
	_erase_files()
	_restore_bus()
	return _result(errs)


## 1. 멈춤: Esc로 멈추면 시간·상대·게이지·내 상태가 그대로이고, 덮개는 입력을 먹는다.
func _check_freeze(errs: Array[String]) -> void:
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	_advance(duel, 1.0)
	var before := _snapshot(duel)
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	_expect(errs, bool(duel.get("paused")), "[1] Esc 뒤 paused가 거짓")
	_expect(errs, _menu_count(duel) == 1, "[1] Esc 뒤 PauseMenu가 %d개 (기대 1)" % _menu_count(duel))
	_expect(errs, _focus_name() == "PauseResume", "[1] 초점이 PauseResume이 아니라 '%s'" % _focus_name())
	for i in 20:
		duel.call("_physics_process", 0.5)
		duel.call("_process", 0.016)
	_expect(errs, _snapshot(duel) == before, "[1] 멈춘 동안 값이 바뀜: %s → %s" % [str(before), str(_snapshot(duel))])
	_move(Vector2(20, 20))
	_click(MOUSE_BUTTON_LEFT)
	_key(KEY_W)
	_expect(errs, _snapshot(duel) == before, "[1] 덮개의 빈 곳 좌클릭·W가 판을 건드림: %s" % str(_snapshot(duel)))
	_expect(errs, _attack_starts(core) == 0, "[1] 멈춘 동안 공격이 나감")
	_expect(errs, not _tree.paused, "[1] get_tree().paused가 참(깃발로만 멈춰야 함)")
	_move(FREE_SPOT)


## 2. "계속"의 클릭과 더블클릭의 둘째 누름은 공격이 되지 않고, 대기가 끝나야 공격이 다시 된다.
func _check_resume_click(errs: Array[String]) -> void:
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	_advance(duel, 1.0)
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	var menu := duel.get_node_or_null(^"PauseMenu")
	var resume := duel.find_child("PauseResume", true, false) as Button
	_expect(errs, menu != null and resume != null, "[2] 멈춤 화면이나 PauseResume이 없음")
	if menu == null or resume == null:
		return
	_layout_now(menu)
	var center := resume.get_global_rect().get_center()
	_move(center)
	_click(MOUSE_BUTTON_LEFT)
	if duel.get_node_or_null(^"PauseMenu") != null:
		# 헤드리스의 작은 창에서 클릭이 버튼에 닿지 않았다: 그 한 단계만 신호로 바꾸고 같은 자리의 누름·뗌을 보낸다.
		_click_fallback = true
		resume.pressed.emit()
		_click(MOUSE_BUTTON_LEFT)
	_expect(errs, duel.get_node_or_null(^"PauseMenu") == null, "[2] 클릭 뒤에도 멈춤 화면이 남음")
	_expect(errs, bool(duel.get("paused")), "[2] 계속 뒤 대기가 아님(paused 거짓)")
	_expect(errs, _resume_hold(duel, errs).visible, "[2] 대기 중인데 ResumeHold가 보이지 않음")
	_expect(errs, _attack_starts(core) == 0, "[2] '계속'의 클릭이 공격이 됨")
	_expect(errs, core.player_state == DuelTypes.PlayerState.READY, "[2] 계속 뒤 내 상태가 READY가 아님 (%d)" % core.player_state)
	var swallowed_before := int(duel.get("_swallowed_attacks"))
	_move(FREE_SPOT)
	_button(MOUSE_BUTTON_LEFT, true)
	_expect(errs, int(duel.get("_swallowed_attacks")) == swallowed_before + 1, "[2] 대기 중 좌클릭이 버려진 수 %d (기대 %d)" % [
		int(duel.get("_swallowed_attacks")), swallowed_before + 1])
	_button(MOUSE_BUTTON_LEFT, false)
	_expect(errs, _attack_starts(core) == 0, "[2] 더블클릭의 둘째 누름이 공격이 됨")
	var time_before := core.time
	_finish_hold(duel)
	_expect(errs, not bool(duel.get("paused")), "[2] 대기가 끝났는데 paused가 참")
	_expect(errs, not _resume_hold(duel, errs).visible, "[2] 대기가 끝났는데 ResumeHold가 보임")
	_expect(errs, is_equal_approx(core.time, time_before + 1.0 / 60.0), "[2] 대기 뒤 첫 걸음의 시간 %.4f (기대 %.4f)" % [core.time, time_before + 1.0 / 60.0])
	_click(MOUSE_BUTTON_LEFT)
	_expect(errs, core.player_state == DuelTypes.PlayerState.WINDUP and _attack_starts(core) == 1,
		"[2] 대기가 끝난 뒤 좌클릭이 공격이 되지 않음 (상태 %d, 공격 %d)" % [core.player_state, _attack_starts(core)])
	_expect(errs, not DuelScene.hold_over(1000, 999) and DuelScene.hold_over(1000, 1000) and DuelScene.hold_over(1000, 1001),
		"[2] hold_over의 경계(끝 직전 거짓, 끝 그때 참)가 다름")


## 3. 막기: 멈춘 동안 뗐으면 풀리고, 쥔 채면 이어진다(새로 누른 것이 아니다).
func _check_guard(errs: Array[String]) -> void:
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	_advance(duel, 0.2)
	_move(FREE_SPOT)
	_button(MOUSE_BUTTON_RIGHT, true)
	_expect(errs, core.guard_held and core.player_state == DuelTypes.PlayerState.GUARD, "[3 가] 우클릭 뒤 막기가 아님")
	_key(KEY_ESCAPE)
	_button(MOUSE_BUTTON_RIGHT, false)
	_expect(errs, bool(duel.get("paused")) and core.guard_held, "[3 가] 멈춘 동안 뗀 우클릭이 코어에 들어감(guard_held %s)" % str(core.guard_held))
	_key(KEY_ESCAPE)
	_expect(errs, not core.guard_held and core.player_state == DuelTypes.PlayerState.READY,
		"[3 가] 멈춘 동안 뗐는데 돌아온 뒤 막기가 풀리지 않음 (guard_held %s, 상태 %d)" % [str(core.guard_held), core.player_state])
	_free_made()

	var duel2 := _spawn_practice()
	var core2: DuelCore = duel2.get("core")
	_advance(duel2, 0.2)
	_button(MOUSE_BUTTON_RIGHT, true)
	_expect(errs, core2.player_state == DuelTypes.PlayerState.GUARD, "[3 나] 우클릭 뒤 막기가 아님")
	var entered := core2.guard_enter_time
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	_expect(errs, core2.guard_held and core2.player_state == DuelTypes.PlayerState.GUARD,
		"[3 나] 쥔 채 멈췄다 돌아왔는데 막기가 이어지지 않음 (상태 %d)" % core2.player_state)
	_expect(errs, core2.guard_enter_time == entered, "[3 나] 돌아오며 막기를 새로 누른 것으로 침(guard_enter_time %s → %s)" % [str(entered), str(core2.guard_enter_time)])
	_button(MOUSE_BUTTON_RIGHT, false)
	_expect(errs, not core2.guard_held, "[3 나] 대기 중에 뗀 우클릭이 막기를 풀지 않음")


## 4. 포커스: 잃으면 멈추고 돌아와도 풀리지 않는다. 물리 걸음이 꺼진 판(찍기 도구)은 포커스로 멈추지 않는다.
func _check_focus(errs: Array[String]) -> void:
	var out_app: int = Node.NOTIFICATION_APPLICATION_FOCUS_OUT
	var in_app: int = Node.NOTIFICATION_APPLICATION_FOCUS_IN
	var out_win: int = Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT

	# 실제 길: 엔진은 포커스 알림을 트리 전체에 propagate_notification으로 돌린다. 그 안에서는 add_child가 막혀
	# (S02 창 확인의 버그) 알림은 멈춤을 미루기만 한다. 러너는 프레임이 없어 미룬 호출을 _pause_from_focus로 직접 돌린다.
	var d0 := _spawn_practice()
	_tree.root.propagate_notification(out_app)
	_expect(errs, not bool(d0.get("paused")) and _menu_count(d0) == 0, "[4] 포커스 알림 안에서 바로 멈춤(미뤄야 함)")
	d0.call("_pause_from_focus")
	_expect(errs, bool(d0.get("paused")) and _menu_count(d0) == 1 and d0.get("_pause_menu") != null,
		"[4] propagate 뒤 미룬 호출이 멈춤 화면을 붙이지 못함 (paused %s, 화면 %d)" % [str(d0.get("paused")), _menu_count(d0)])
	_key(KEY_ESCAPE)
	_expect(errs, bool(d0.get("paused")) and _menu_count(d0) == 0 and bool(d0.get("_holding")), "[4] propagate로 멈춘 뒤 Esc가 대기로 들이지 못함")
	_free_made()

	var dw := _spawn_practice()
	_tree.root.propagate_notification(out_win)
	dw.call("_pause_from_focus")
	_expect(errs, bool(dw.get("paused")) and _menu_count(dw) == 1, "[4] propagate WM_WINDOW_FOCUS_OUT 뒤 멈춤 화면이 없음")
	_key(KEY_ESCAPE)
	_expect(errs, bool(dw.get("_holding")) and _menu_count(dw) == 0, "[4] propagate WM_WINDOW_FOCUS_OUT 뒤 Esc가 대기로 들이지 못함")
	_free_made()

	var d1 := _spawn_practice()
	d1.notification(out_app)
	d1.call("_pause_from_focus")
	_expect(errs, bool(d1.get("paused")) and _menu_count(d1) == 1, "[4] APPLICATION_FOCUS_OUT 뒤 멈춤 화면이 없음")
	d1.notification(in_app)
	_expect(errs, bool(d1.get("paused")) and _menu_count(d1) == 1, "[4] FOCUS_IN 뒤 멈춤이 풀리거나 화면이 사라짐")
	_free_made()

	var d2 := _spawn_practice()
	d2.notification(out_win)
	d2.call("_pause_from_focus")
	_expect(errs, bool(d2.get("paused")) and _menu_count(d2) == 1, "[4] WM_WINDOW_FOCUS_OUT 뒤 멈춤 화면이 없음")
	_free_made()

	var d3 := _spawn_practice()
	d3.notification(out_app)
	d3.notification(out_win)
	d3.call("_pause_from_focus")
	d3.call("_pause_from_focus")
	_expect(errs, _menu_count(d3) == 1, "[4] 두 알림이 잇달아 와서 PauseMenu가 %d개 (기대 1)" % _menu_count(d3))
	_free_made()

	var d4 := _spawn_practice()
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	_expect(errs, bool(d4.get("paused")) and _menu_count(d4) == 0, "[4] 대기 상태를 만들지 못함")
	d4.notification(out_app)
	d4.call("_pause_from_focus")
	_expect(errs, bool(d4.get("paused")) and _menu_count(d4) == 1, "[4] 대기 중의 포커스 잃음이 멈춤 화면을 다시 열지 않음")
	_free_made()

	var d5 := _spawn_practice()
	var core5: DuelCore = d5.get("core")
	_advance(d5, 0.3)
	var time5 := core5.time
	d5.set_physics_process(false)
	_tree.root.propagate_notification(out_app)
	_tree.root.propagate_notification(out_win)
	d5.call("_pause_from_focus")
	_expect(errs, not bool(d5.get("paused")) and _menu_count(d5) == 0 and core5.time == time5,
		"[4] 물리 걸음이 꺼진 판이 포커스 알림으로 멈춤 (paused %s, 화면 %d)" % [str(d5.get("paused")), _menu_count(d5)])
	_key(KEY_ESCAPE)
	_expect(errs, bool(d5.get("paused")) and _menu_count(d5) == 1, "[4] 물리 걸음이 꺼진 판에서도 Esc는 멈춰야 함")


## 5. 끝난 판은 멈추지 않는다.
func _check_ended(errs: Array[String]) -> void:
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	var guard := 0
	while not core.ended and guard < 7000:
		core.tick(1.0 / 60.0)
		guard += 1
	duel.call("advance", 0.0)
	_expect(errs, core.ended, "[5] 판이 끝나지 않음")
	_key(KEY_ESCAPE)
	duel.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	duel.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	duel.call("_pause_from_focus")
	_expect(errs, not bool(duel.get("paused")) and _menu_count(duel) == 0, "[5] 끝난 판이 멈춤 (paused %s, 화면 %d)" % [str(duel.get("paused")), _menu_count(duel)])


## 6. 나가기의 꼴: 연습은 "연습 고르기로"(노트 없음), 하루 결투는 "처음 화면으로"와 돌아올 날의 글. 하루의 R은 새 판을 만들지 않는다.
func _check_exit_shape(errs: Array[String]) -> void:
	var practice := _spawn_practice()
	_key(KEY_ESCAPE)
	var exit := practice.find_child("PauseExit", true, false) as Button
	_expect(errs, exit != null and exit.text == "연습 고르기로", "[6] 연습의 PauseExit 글 '%s'" % (exit.text if exit != null else "없음"))
	_expect(errs, practice.find_child("PauseExitNote", true, false) == null, "[6] 연습의 멈춤 화면에 PauseExitNote가 있음")
	_free_made()

	var pair := _spawn_day_duel()
	var duel: Node = pair[0]
	var day: DayState = pair[1]
	var core: DuelCore = duel.get("core")
	_key(KEY_ESCAPE)
	var day_exit := duel.find_child("PauseExit", true, false) as Button
	var note := duel.find_child("PauseExitNote", true, false) as Label
	var autoload := _tree.root.get_node_or_null(^"GameSession")
	var resume_day := int(autoload.call("resume_day")) if autoload != null else 0
	var want := SessionScript.quit_note(day, resume_day)
	_expect(errs, day_exit != null and day_exit.text == "처음 화면으로", "[6] 하루 결투의 PauseExit 글 '%s'" % (day_exit.text if day_exit != null else "없음"))
	_expect(errs, note != null and note.text == want, "[6] 하루 결투의 노트 '%s' (기대 '%s')" % [note.text if note != null else "없음", want])
	_key(KEY_R)
	_expect(errs, duel.get("core") == core, "[6] 하루 결투의 멈춤 화면이 열린 동안 R이 새 판을 만듦")
	_key(KEY_ESCAPE)
	_expect(errs, bool(duel.get("paused")) and _menu_count(duel) == 0, "[6] 하루 결투의 대기 상태를 만들지 못함")
	_key(KEY_R)
	_expect(errs, duel.get("core") == core, "[6] 하루 결투의 대기 중 R이 새 판을 만듦")


## 7. 설정: 멈춤 화면 아래에 설정 화면이 뜨고, Esc는 설정 화면만 닫고 초점이 PauseSettings로 돌아온다.
func _check_settings(errs: Array[String]) -> void:
	# --script 실행에 자동 로드가 없으면 이 이름의 대역을 붙인다(멈춤 화면이 /root/Settings를 읽는다). 파일은 테스트 이름만 쓴다.
	if _tree.root.get_node_or_null(^"Settings") == null:
		var stand_in: Node = SettingsScript.new()
		stand_in.path = TEST_SETTINGS
		stand_in.name = "Settings"
		_tree.root.add_child(stand_in)
		_made.append(stand_in)
	var duel := _spawn_practice()
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	var button := duel.find_child("PauseSettings", true, false) as Button
	_expect(errs, button != null and not button.disabled, "[7] PauseSettings가 없거나 꺼져 있음")
	if button == null or button.disabled:
		return
	button.pressed.emit()
	_expect(errs, duel.find_child("SettingsScreen", true, false) != null, "[7] 설정을 눌렀는데 SettingsScreen이 없음")
	_expect(errs, _menu_count(duel) == 1, "[7] 설정 아래의 멈춤 화면이 사라짐")
	_key(KEY_ESCAPE)
	_expect(errs, duel.find_child("SettingsScreen", true, false) == null, "[7] Esc 뒤에도 SettingsScreen이 남음")
	_expect(errs, _menu_count(duel) == 1 and bool(duel.get("paused")), "[7] Esc가 설정 화면만 닫지 않고 멈춤 화면까지 닫음")
	_expect(errs, _focus_name() == "PauseSettings", "[7] 닫은 뒤 초점이 PauseSettings가 아니라 '%s'" % _focus_name())


## 8. R(연습, 대기 중)은 새 판이고 멈춤을 지운다.
func _check_retry(errs: Array[String]) -> void:
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	_advance(duel, 0.5)
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	_expect(errs, bool(duel.get("paused")) and _menu_count(duel) == 0, "[8] 대기 상태를 만들지 못함")
	_key(KEY_R)
	var fresh: DuelCore = duel.get("core")
	_expect(errs, fresh != core and fresh.time == 0.0, "[8] 대기 중 R이 새 판을 시작하지 않음")
	_expect(errs, not bool(duel.get("paused")) and not _resume_hold(duel, errs).visible, "[8] R 뒤에도 멈춤·대기가 남음")


# ================================================================ T99

## 하루를 날로 되돌린 DayState(그날 아침, 카운터 단계).
func _morning(day_number: int) -> DayState:
	var day := DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed(), _d._catalog(_d._test_upgrades()))
	day.restore({"version": 1, "day": day_number, "money": 100, "owned": []})
	return day


## 트리 밖의 세션(save_path가 테스트 파일). quit_game()은 이 세션에서 아무것도 하지 않는다.
func _session(day: DayState) -> Node:
	var session: Node = SessionScript.new()
	session.set("save_path", TEST_SAVE)
	session.set("day", day)
	_made.append(session)
	return session


func _scene_stub() -> Control:
	var stub := Control.new()
	_tree.root.add_child(stub)
	_made.append(stub)
	return stub


func t99_quit() -> String:
	var errs: Array[String] = []
	_erase_files()
	_check_quit_note(errs)
	_check_resume_day(errs)
	_free_made()
	_check_close_request(errs)
	_free_made()
	_check_title_button(errs)
	_free_made()
	_check_counter_note(errs)
	_free_made()
	_check_day_menus(errs)
	_free_made()
	_erase_files()
	return _result(errs)


## 1. quit_note의 네 갈래.
func _check_quit_note(errs: Array[String]) -> void:
	var counter_day := _morning(3)
	var note := SessionScript.quit_note(counter_day, 3)
	_expect(errs, note.contains("3일차 아침부터") and note.contains("남지 않는다"), "[1] 카운터·3: '%s'" % note)
	var closing_day := _morning(3)
	_d._run_fixed_day(closing_day)
	_expect(errs, closing_day.phase == DayState.Phase.CLOSING, "[1] 폐점 단계를 만들지 못함")
	note = SessionScript.quit_note(closing_day, 4)
	_expect(errs, note.contains("4일차") and note.contains("적혀 있다"), "[1] 폐점·4: '%s'" % note)
	note = SessionScript.quit_note(closing_day, 3)
	_expect(errs, note.contains("3일차") and note.contains("남지 않는다"), "[1] 폐점·3(쓰기 실패): '%s'" % note)
	note = SessionScript.quit_note(counter_day, 0)
	_expect(errs, note.contains("적힌 아침이 없다"), "[1] 0: '%s'" % note)


## 2. resume_day: 파일이 진실이다.
func _check_resume_day(errs: Array[String]) -> void:
	var session := _session(_morning(3))
	_expect(errs, bool(session.call("save_game")), "[2] 3일차 아침을 적지 못함")
	_expect(errs, int(session.call("resume_day")) == 3, "[2] 적은 뒤 resume_day %d (기대 3)" % int(session.call("resume_day")))
	Store.erase(TEST_SAVE)
	_expect(errs, int(session.call("resume_day")) == 0, "[2] 파일이 없는데 resume_day가 0이 아님")
	Store.write(TEST_SAVE, {"day": "x"})
	_expect(errs, int(session.call("resume_day")) == 0, "[2] 날이 글자인데 resume_day가 0이 아님")
	Store.erase(TEST_SAVE)
	Store.write(TEST_SAVE, {"version": 1, "day": 3, "money": 1, "owned": []})
	session.set("save_path", "")
	_expect(errs, int(session.call("resume_day")) == 0, "[2] save_path가 비었는데 resume_day가 0이 아님")
	Store.erase(TEST_SAVE)


## 3. 창 닫기: 하루 밖은 바로, 하루 중은 확인 창, 두 번째는 바로, 저장된 폐점은 바로.
func _check_close_request(errs: Array[String]) -> void:
	var quit_action: int = SessionScript.CloseAction.QUIT
	var confirm_action: int = SessionScript.CloseAction.CONFIRM

	var stub := _scene_stub()
	var no_day := _session(null)
	_expect(errs, int(no_day.call("handle_close_request", stub)) == quit_action and stub.get_child_count() == 0,
		"[3] 하루가 없는데 바로 꺼지지 않거나 무언가 붙음")

	var day := _morning(3)
	var session := _session(day)
	session.call("save_game")
	var confirmed := [0]
	var cancelled := [0]
	_expect(errs, int(session.call("handle_close_request", null)) == quit_action, "[3] 장면이 없는데 QUIT이 아님")
	_expect(errs, int(session.call("handle_close_request", stub)) == confirm_action, "[3] 카운터 단계의 닫기가 CONFIRM이 아님")
	var confirm := stub.get_node_or_null(^"QuitConfirm") as QuitConfirm
	_expect(errs, confirm != null, "[3] QuitConfirm이 붙지 않음")
	if confirm == null:
		return
	confirm.cancelled.connect(func(): cancelled[0] += 1)
	confirm.confirmed.connect(func(): confirmed[0] += 1)
	var note := confirm.find_child("ConfirmNote", true, false) as Label
	_expect(errs, note != null and note.text.contains("3일차"), "[3] 확인 창의 글 '%s' ('3일차'가 없음)" % (note.text if note != null else "없음"))
	_expect(errs, int(session.call("handle_close_request", stub)) == quit_action, "[3] 확인 창이 떠 있는데 두 번째 닫기가 QUIT이 아님")
	(confirm.find_child("QuitNo", true, false) as Button).pressed.emit()
	_expect(errs, stub.get_node_or_null(^"QuitConfirm") == null and cancelled[0] == 1, "[3] 돌아간다 뒤 확인 창이 남거나 cancelled가 %d번" % cancelled[0])

	# Esc도 돌아간다.
	session.call("handle_close_request", stub)
	var again := stub.get_node_or_null(^"QuitConfirm") as QuitConfirm
	if again != null:
		again.cancelled.connect(func(): cancelled[0] += 1)
		_key(KEY_ESCAPE)
		_expect(errs, stub.get_node_or_null(^"QuitConfirm") == null and cancelled[0] == 2, "[3] Esc가 확인 창을 닫지 않음 (cancelled %d)" % cancelled[0])

	# 끈다: 트리 밖 세션의 quit_game()은 아무것도 하지 않는다. 신호만 본다.
	session.call("handle_close_request", stub)
	var third := stub.get_node_or_null(^"QuitConfirm") as QuitConfirm
	if third != null:
		third.confirmed.connect(func(): confirmed[0] += 1)
		(third.find_child("QuitYes", true, false) as Button).pressed.emit()
		_expect(errs, confirmed[0] == 1, "[3] 끈다 뒤 confirmed가 %d번 (기대 1)" % confirmed[0])
		session.call("quit_game")

	# 저장된 폐점은 바로 꺼진다. 저장이 안 된 폐점은 확인 창이 뜬다.
	var closing_stub := _scene_stub()
	var closing_day := _morning(3)
	_d._run_fixed_day(closing_day)
	var closing_session := _session(closing_day)
	_expect(errs, int(closing_session.call("handle_close_request", closing_stub)) == confirm_action, "[3] 저장이 안 된 폐점의 닫기가 CONFIRM이 아님")
	closing_stub.get_node(^"QuitConfirm").free()
	closing_session.call("save_game")
	_expect(errs, int(closing_session.call("resume_day")) == 4, "[3] 폐점을 적은 뒤 resume_day가 4가 아님")
	_expect(errs, int(closing_session.call("handle_close_request", closing_stub)) == quit_action and closing_stub.get_node_or_null(^"QuitConfirm") == null,
		"[3] 저장된 폐점의 닫기가 바로 꺼지지 않음")
	Store.erase(TEST_SAVE)

	# 하루 결투: 결투가 멈춤 화면을 열고 확인 창이 그 위에 선다.
	var pair := _spawn_day_duel()
	var duel: Node = pair[0]
	var duel_day: DayState = pair[1]
	var duel_session := _session(duel_day)
	Store.write(TEST_SAVE, {"version": 1, "day": 1, "money": 250, "owned": []})
	_expect(errs, int(duel_session.call("handle_close_request", duel)) == confirm_action, "[3] 하루 결투의 닫기가 CONFIRM이 아님")
	var menu := duel.get_node_or_null(^"PauseMenu") as PauseMenu
	var duel_confirm := duel.get_node_or_null(^"QuitConfirm") as QuitConfirm
	_expect(errs, bool(duel.get("paused")) and menu != null and duel_confirm != null, "[3] 결투가 멈춤 화면과 확인 창을 열지 않음")
	if menu != null and duel_confirm != null:
		_expect(errs, duel_confirm.layer > menu.layer, "[3] 확인 창의 층 %d가 멈춤 화면의 층 %d보다 위가 아님" % [duel_confirm.layer, menu.layer])
		(duel_confirm.find_child("QuitNo", true, false) as Button).pressed.emit()
		_expect(errs, duel.get_node_or_null(^"QuitConfirm") == null and duel.get_node_or_null(^"PauseMenu") != null and bool(duel.get("paused")),
			"[3] 돌아간다 뒤 멈춤 화면이 남지 않음")
	Store.erase(TEST_SAVE)


## 4. 처음 화면의 "게임 종료": 저장 없음·있음 모두 있고, 누르면 아무 일도 없다(현재 씬이 아니다).
func _check_title_button(errs: Array[String]) -> void:
	for with_save in [false, true]:
		var title: Node = (load(SessionScript.TITLE_PATH) as PackedScene).instantiate()
		if with_save:
			title.set("saved", _morning(2))
		_tree.root.add_child(title)
		_made.append(title)
		var label := "저장 있음" if with_save else "저장 없음"
		var button := title.find_child("QuitGame", true, false) as Button
		_expect(errs, button != null and button.text == "게임 종료", "[4] %s: QuitGame이 없거나 글이 '게임 종료'가 아님" % label)
		if button != null:
			button.pressed.emit()
		_expect(errs, is_instance_valid(title) and title.is_inside_tree(), "[4] %s: 누른 뒤 화면이 사라짐" % label)


## 5. 카운터의 QuitNote: 세션이 없으면 지금 글, 글감에 %d가 하나.
func _check_counter_note(errs: Array[String]) -> void:
	var counter_script: GDScript = load("res://scripts/commission/counter.gd")
	var template := String(counter_script.get_script_constant_map().get("QUIT_NOTE", ""))
	_expect(errs, template.count("%d") == 1, "[5] QUIT_NOTE의 %%d가 %d개 (기대 1)" % template.count("%d"))
	var counter := _d._spawn_screen(SessionScript.COUNTER_PATH, _morning(1))
	_made.append(counter)
	var note: String = _d._label_text(counter, "QuitNote")
	_expect(errs, note.contains("오늘 아침부터다"), "[5] 적힌 아침이 없을 때의 QuitNote '%s' (기대 '오늘 아침부터다')" % note)


## 6. 카운터·정산·폐점의 Esc는 "잠깐" 창을 열고 한 번 더 누르면 닫는다. 정산에도 나가기가 있고 노트는 quit_note다.
func _check_day_menus(errs: Array[String]) -> void:
	var autoload := _tree.root.get_node_or_null(^"GameSession")
	var resume_day := int(autoload.call("resume_day")) if autoload != null else 0

	var counter_day := _morning(1)
	var settle_day := _morning(1)
	settle_day.accept()
	settle_day.finish_duel(_d._record(DT.EndReason.CONDITION))
	var closing_day := _morning(1)
	_d._run_fixed_day(closing_day)
	var cases := [
		["카운터", SessionScript.COUNTER_PATH, counter_day, false],
		["정산", SessionScript.SETTLEMENT_PATH, settle_day, true],
		["폐점", SessionScript.CLOSING_PATH, closing_day, false],
	]
	for entry in cases:
		var label: String = entry[0]
		var screen: Node = _d._spawn_screen(entry[1], entry[2])
		_made.append(screen)
		_key(KEY_ESCAPE)
		var menu := screen.get_node_or_null(^"PauseMenu")
		_expect(errs, menu != null and _label_with_text(menu, "잠깐"), "[6] %s: Esc 뒤 '잠깐' 멈춤 화면이 없음" % label)
		if menu != null:
			var exit := menu.find_child("PauseExit", true, false) as Button
			var note := menu.find_child("PauseExitNote", true, false) as Label
			var want := SessionScript.quit_note(entry[2], resume_day)
			_expect(errs, exit != null and exit.text == "처음 화면으로", "[6] %s: PauseExit이 없거나 글이 다름" % label)
			_expect(errs, note != null and note.text == want, "[6] %s: 노트 '%s' (기대 '%s')" % [label, note.text if note != null else "없음", want])
		_key(KEY_ESCAPE)
		_expect(errs, screen.get_node_or_null(^"PauseMenu") == null, "[6] %s: 한 번 더 누른 Esc가 닫지 않음" % label)
		screen.free()
