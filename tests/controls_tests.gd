extends RefCounted
## T100~T101: 조작 바꾸기(계획 S03) — 부호·이름·예약·읽기·쓰기·분리·격리 / 겹치면 비우기, 조작 탭, 실제 입력, 멈춤, 안내.
## 입력은 T24·T98처럼 엔진의 입력 경로(Input.parse_input_event)로 보낸다. 파일은 TEST_PATH·TEST_SAVE_PATH만 쓰고 끝에 지운다.
## 끝에 InputMap을 처음 값으로 되돌린다(뒤의 테스트가 바뀐 키로 돌지 않게. 결정 523): 엔진 내장 액션까지 다시 읽지 않으려고 넷만 건다.
## preload 상수 이름은 SettingsScript다: 자동 로드 이름(Settings)과 겹치면 경고가 난다.

const Controls := preload("res://scripts/controls.gd")
const Day := preload("res://tests/day_tests.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const SettingsScript := preload("res://scripts/settings.gd")
const SessionScript := preload("res://scripts/game_session.gd")
const Store := preload("res://scripts/save_store.gd")

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const TEST_PATH := "user://bravi_test_settings_S03.json"
const TEST_SAVE_PATH := "user://bravi_test_save_S03.json"
const FREE_SPOT := Vector2(1066, 600)
const OLD_HELP_LINE := "좌클릭 공격 · 우클릭 막기 (떼고 있다가 고리가 띠에 들어올 때 누르면 패리) · 마우스 위치로 방향·높이 · W/S 간격 · R 다시 하기 · Esc 멈춤 · F1 디버그"

var _tree: SceneTree
var _d := Day.new()
var _mouse_pos := Vector2.ZERO
var _made: Array[Node] = []
var _bus_db := 0.0
var _bus_mute := false
var _bus_saved := false
var _click_live := true


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T100", "name": "조작의 부호·예약·읽기: 부호와 이름, 예약, 읽을 때 고치기, 세이브와 분리, 격리", "fn": t100_codes},
		{"id": "T101", "name": "조작 바꾸기: 겹치면 비우기, 탭, 실제 입력, 멈춤, 안내", "fn": t101_rebind},
	]


func cleanup() -> void:
	_free_made()
	_erase_files()
	_restore_inputs()
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


func _erase_files() -> void:
	Store.erase(TEST_PATH)
	Store.erase(TEST_SAVE_PATH)


func _save_bus() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0 and not _bus_saved:
		_bus_db = AudioServer.get_bus_volume_db(bus)
		_bus_mute = AudioServer.is_bus_mute(bus)
		_bus_saved = true


func _restore_bus() -> void:
	if not _bus_saved:
		return
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, _bus_db)
		AudioServer.set_bus_mute(bus, _bus_mute)
	_bus_saved = false


## 자동 로드가 있으면 그 값까지(detach_for_run), 없으면 InputMap의 넷만 처음 값으로.
func _restore_inputs() -> void:
	if _tree == null:
		return
	var autoload := _tree.root.get_node_or_null(^"Settings")
	if autoload != null and autoload.has_method("detach_for_run"):
		autoload.call("detach_for_run")
	Controls.apply_codes(Controls.default_codes())


func _free_made() -> void:
	for node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _make(path := TEST_PATH) -> Node:
	var settings: Node = SettingsScript.new()
	settings.path = path
	_tree.root.add_child(settings)
	_made.append(settings)
	return settings


func _write_text(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _read(text: String) -> Node:
	_write_text(text)
	return _make()


func _codes(s: Node) -> Array:
	var out := []
	for action in Controls.ACTIONS:
		out.append(String(s.controls[action]))
	return out


func _default_list() -> Array:
	var out := []
	for action in Controls.ACTIONS:
		out.append(Controls.default_code(action))
	return out


func _section(data: Dictionary, name: String) -> Dictionary:
	var found: Variant = data.get(name)
	return found as Dictionary if found is Dictionary else {}


## InputMap에 실제로 걸린 이벤트의 부호들.
func _im(action: StringName) -> Array:
	var out := []
	for ev in InputMap.action_get_events(action):
		out.append(Controls.code_of(ev))
	return out


## 넷이 서로 다르거나 비어 있다.
func _distinct(s: Node) -> bool:
	var seen := {}
	for code in _codes(s):
		if code != "" and seen.has(code):
			return false
		seen[code] = true
	return true


func _key_event(keycode: Key, physical: Key, shift := false, echo := false, pressed := true) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = physical
	ev.shift_pressed = shift
	ev.echo = echo
	ev.pressed = pressed
	return ev


func _mouse_event(button: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	return ev


func _send(ev: InputEvent) -> void:
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


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


func _click(button: MouseButton) -> void:
	_button(button, true)
	_button(button, false)


func _key_down(key: Key, echo := false) -> void:
	_send(_key_event(key, key, false, echo, true))


func _key_up(key: Key) -> void:
	_send(_key_event(key, key, false, false, false))


func _key(key: Key) -> void:
	_key_down(key)
	_key_up(key)


func _advance(duel: Node, seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		duel.call("advance", 1.0 / 60.0)


## 코드로 만든 컨테이너는 한 프레임 안에 자리를 잡지 않는다(러너는 프레임 없이 돈다): 위에서부터 한 번 앉힌다.
func _layout_now(node: Node) -> void:
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child in node.get_children():
		_layout_now(child)


func _finish_hold(duel: Node) -> void:
	duel.set("_hold_until_msec", 0)
	duel.call("_physics_process", 1.0 / 60.0)


func _spawn_practice() -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	_made.append(duel)
	return duel


func _attack_starts(core: DuelCore) -> int:
	return core.record.of_type(DuelRecord.ATTACK_START).size()


func _focus_path() -> String:
	var owner := _tree.root.gui_get_focus_owner()
	return str(owner.get_path()) if owner != null else ""


func _open_screen(s: Node) -> SettingsScreen:
	var parent := Control.new()
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tree.root.add_child(parent)
	_made.append(parent)
	var screen := SettingsScreen.open(parent, s)
	_layout_now(screen)
	return screen


func _btn(screen: Node, node_name: String) -> Button:
	return screen.find_child(node_name, true, false) as Button


## 눌러서 일을 일으키고(신호) 몸이 새로 지어졌을 수 있으니 다시 앉힌다.
func _press(screen: Node, node_name: String) -> void:
	var button := _btn(screen, node_name)
	if button != null:
		button.pressed.emit()
	_layout_now(screen)


func _note(screen: Node) -> Label:
	return screen.find_child("ControlsNote", true, false) as Label


func _pull_capture(screen: Node) -> void:
	screen.set("_capture_msec", Time.get_ticks_msec() - 1000)


func _click_center(screen: Node, node_name: String) -> void:
	var button := _btn(screen, node_name)
	if button == null:
		return
	_move(button.get_global_rect().get_center())
	_click(MOUSE_BUTTON_LEFT)


func _settings_node() -> Node:
	var found := _tree.root.get_node_or_null(^"Settings")
	if found == null:
		var stand_in: Node = SettingsScript.new()
		stand_in.path = TEST_PATH
		stand_in.name = "Settings"
		_tree.root.add_child(stand_in)
		_made.append(stand_in)
		found = stand_in
	return found


# ================================================================ T100

func t100_codes() -> String:
	var errs: Array[String] = []
	_save_bus()
	_erase_files()
	_check_isolation(errs)
	_check_codes(errs)
	_check_reserved(errs)
	_check_read(errs)
	_free_made()
	_check_split(errs)
	_free_made()
	_check_write(errs)
	_free_made()
	_erase_files()
	_restore_inputs()
	_restore_bus()
	return _result(errs)


## 1. 부호와 이름.
func _check_codes(errs: Array[String]) -> void:
	var wanted := {&"attack": "mouse:1", &"guard": "mouse:2", &"step_forward": "key:87", &"step_back": "key:83"}
	for action: StringName in wanted:
		var events: Array = (ProjectSettings.get_setting("input/%s" % action) as Dictionary)["events"]
		_expect(errs, Controls.code_of(events[0]) == wanted[action], "[1] project.godot의 %s 부호 %s" % [action, Controls.code_of(events[0])])
		_expect(errs, Controls.default_code(action) == wanted[action], "[1] default_code(%s) %s" % [action, Controls.default_code(action)])
	var names := {"mouse:1": "좌클릭", "mouse:2": "우클릭", "mouse:3": "가운데 클릭", "mouse:8": "옆 버튼 1", "mouse:9": "옆 버튼 2",
		"key:87": "W", "key:83": "S", "": "없음"}
	for code: String in names:
		_expect(errs, Controls.name_of(code) == names[code], "[1] name_of('%s') = '%s' (기대 '%s')" % [code, Controls.name_of(code), names[code]])
		if code != "":
			_expect(errs, Controls.code_of(Controls.event_of(code)) == code, "[1] %s가 event_of→code_of로 되돌아오지 않음" % code)
	_expect(errs, Controls.event_of("") == null and Controls.is_valid("") and not Controls.is_valid("key:abc"), "[1] 빈 글·못 읽는 부호의 event_of·is_valid")
	_expect(errs, not Controls.is_valid("mouse:4") and not Controls.is_valid("key:0"), "[1] 휠·키 0이 유효로 읽힘")
	var bad := {
		"휠 위": _mouse_event(MOUSE_BUTTON_WHEEL_UP), "휠 아래": _mouse_event(MOUSE_BUTTON_WHEEL_DOWN),
		"Meta": _key_event(KEY_META, KEY_META), "echo": _key_event(KEY_J, KEY_J, false, true),
		"키 0": _key_event(KEY_NONE, KEY_NONE), "물리 키 없음": _key_event(KEY_J, KEY_NONE),
	}
	for label: String in bad:
		_expect(errs, Controls.code_of(bad[label]) == "", "[1] %s가 못 쓰는 입력이 아님: '%s'" % [label, Controls.code_of(bad[label])])
	var shifted := _key_event(KEY_J, KEY_J, true)
	_expect(errs, Controls.code_of(shifted) == "key:74", "[1] Shift+J의 부호 '%s'" % Controls.code_of(shifted))
	var built := Controls.event_of("key:74") as InputEventKey
	_expect(errs, built != null and not built.shift_pressed and not built.ctrl_pressed and not built.alt_pressed and not built.meta_pressed and built.device == -1,
		"[1] event_of가 수식키를 담거나 device가 -1이 아님")


## 2. 예약.
func _check_reserved(errs: Array[String]) -> void:
	var cases := {"key:%d" % KEY_ESCAPE: "멈춤", "key:%d" % KEY_R: "다시 하기", "key:%d" % KEY_F1: "디버그",
		"key:%d" % KEY_SPACE: "화면 넘기기", "key:%d" % KEY_ENTER: "화면 넘기기", "key:%d" % KEY_KP_ENTER: "화면 넘기기",
		"key:%d" % KEY_W: "", "key:%d" % KEY_J: "", "mouse:1": ""}
	for code: String in cases:
		_expect(errs, Controls.reserved_use(code) == cases[code], "[2] reserved_use(%s) '%s' (기대 '%s')" % [code, Controls.reserved_use(code), cases[code]])


## 3. 읽기.
func _check_read(errs: Array[String]) -> void:
	var defaults := _default_list()
	var s := _read('{"version": 1}')
	_expect(errs, _codes(s) == defaults and not s.controls_repaired, "[3] controls가 없는 파일: %s" % str(_codes(s)))
	s = _read('{"controls": {"attack": "key:74"}}')
	_expect(errs, _codes(s) == ["key:74", defaults[1], defaults[2], defaults[3]] and not s.controls_repaired, "[3] 칸이 빠진 파일: %s·%s" % [str(_codes(s)), str(s.controls_repaired)])
	s = _read('{"controls": {"guard": ""}}')
	_expect(errs, _codes(s) == [defaults[0], "", defaults[2], defaults[3]] and not s.controls_repaired, "[3] 빈 막기: %s·%s" % [str(_codes(s)), str(s.controls_repaired)])
	s = _read('{"controls": {"attack": "", "guard": ""}}')
	_expect(errs, _codes(s) == ["", "", defaults[2], defaults[3]] and not s.controls_repaired, "[3] 빈 칸 둘이 겹침으로 침: %s·%s" % [str(_codes(s)), str(s.controls_repaired)])
	s = _read('{"controls": {"attack": "mouse:2", "guard": ""}}')
	_expect(errs, _codes(s) == ["mouse:2", "", defaults[2], defaults[3]] and not s.controls_repaired, "[3] 공격 우클릭·막기 없음: %s·%s" % [str(_codes(s)), str(s.controls_repaired)])
	for bad in ['5', '"key:abc"', '"mouse:4"', '"key:%d"' % KEY_ESCAPE]:
		s = _read('{"controls": {"attack": %s}}' % bad)
		_expect(errs, _codes(s) == defaults and s.controls_repaired, "[3] 못 쓰는 값 %s: %s·%s" % [bad, str(_codes(s)), str(s.controls_repaired)])
	s = _read('{"controls": {"attack": "key:83"}}')
	_expect(errs, _codes(s) == defaults and s.controls_repaired, "[3] 후퇴와 겹침: %s·%s (넷 모두 처음 값이어야 함)" % [str(_codes(s)), str(s.controls_repaired)])
	var cleaned: Dictionary = SettingsScript.normalize({"controls": {"dodge": "z"}})
	_expect(errs, (cleaned["controls"] as Dictionary).get("dodge") == "z", "[3] 모르는 칸 dodge가 남지 않음")
	s = _read("{not json")
	_expect(errs, _codes(s) == defaults and not s.controls_repaired, "[3] 깨진 JSON: %s" % str(_codes(s)))


func _fresh_day() -> DayState:
	return DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed(), _d._catalog(_d._test_upgrades()))


## 4. 분리.
func _check_split(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	var saved := _fresh_day().saved_state()
	Store.write(TEST_SAVE_PATH, saved)
	var save_before := FileAccess.get_file_as_bytes(TEST_SAVE_PATH)
	var s := _make()
	s.set_control(&"attack", "key:74")
	_expect(errs, s.save(), "[4] 조작을 바꾼 뒤 save()가 거짓")
	_expect(errs, FileAccess.get_file_as_bytes(TEST_SAVE_PATH) == save_before and not save_before.is_empty(), "[4] 조작을 적은 뒤 세이브의 바이트가 달라짐")
	_expect(errs, not saved.has("controls"), "[4] 세이브에 controls가 있음")
	var before := FileAccess.get_file_as_bytes(TEST_PATH)
	Store.write(TEST_SAVE_PATH, _fresh_day().saved_state())
	Store.erase(TEST_SAVE_PATH)
	_expect(errs, FileAccess.get_file_as_bytes(TEST_PATH) == before and not before.is_empty(), "[4] 세이브를 덮어쓰고 지운 뒤 설정 파일이 달라짐")
	_expect(errs, _section(Store.read(TEST_PATH), "controls").get("attack") == "key:74", "[4] 설정 파일의 controls가 남지 않음")


## 5. 쓰기.
func _check_write(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	var s := _make()
	s.set_volume(40)
	_expect(errs, s.save() and not Store.read(TEST_PATH).has("controls"), "[5] 음량만 바꾼 파일에 controls가 적힘")
	_free_made()
	Store.erase(TEST_PATH)
	s = _make()
	s.set_control(&"attack", "key:74")
	s.save()
	var controls := _section(Store.read(TEST_PATH), "controls")
	_expect(errs, controls.size() >= 4 and controls.get("attack") == "key:74" and controls.has("guard") and controls.has("step_forward") and controls.has("step_back"),
		"[5] 조작을 바꾼 파일의 controls: %s" % str(controls))
	_free_made()
	_make()
	_expect(errs, _im(&"attack") == ["key:74"], "[5] 새 인스턴스가 읽은 뒤 InputMap의 attack %s (기대 J 하나)" % str(_im(&"attack")))
	_free_made()
	Store.erase(TEST_PATH)
	s = _make()
	s.set_control(&"step_forward", "mouse:2")
	s.save()
	_expect(errs, _section(Store.read(TEST_PATH), "controls").get("guard") == "", "[5] 빈 막기가 \"\"로 적히지 않음")
	_free_made()
	_make()
	_expect(errs, InputMap.has_action(&"guard") and InputMap.action_get_events(&"guard").is_empty(), "[5] 빈 막기를 읽은 뒤 guard의 이벤트가 0개이거나 액션이 없음")


## 6. 격리: 러너가 detach_for_run을 불렀다.
func _check_isolation(errs: Array[String]) -> void:
	var autoload := _tree.root.get_node_or_null(^"Settings")
	if autoload == null:
		return
	_expect(errs, autoload.path == "", "[6] 자동 로드 Settings의 path가 '%s'" % autoload.path)
	_expect(errs, _codes(autoload) == _default_list(), "[6] 자동 로드 Settings의 조작이 처음 값이 아님: %s" % str(_codes(autoload)))
	for action in Controls.ACTIONS:
		_expect(errs, _im(action) == [Controls.default_code(action)], "[6] InputMap의 %s가 처음 값이 아님: %s" % [action, str(_im(action))])


# ================================================================ T101

func t101_rebind() -> String:
	var errs: Array[String] = []
	_save_bus()
	_erase_files()
	_check_set_control(errs)
	_free_made()
	_restore_inputs()
	_check_tab(errs)
	_free_made()
	_restore_inputs()
	_check_real_input(errs)
	_free_made()
	_restore_inputs()
	_check_pause_change(errs)
	_free_made()
	_restore_inputs()
	_check_left_hold(errs)
	_free_made()
	_restore_inputs()
	_check_help(errs)
	_free_made()
	_erase_files()
	_restore_inputs()
	_restore_bus()
	return _result(errs)


## 1. set_control.
func _check_set_control(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	var s := _make()
	var changes := []
	s.changed.connect(func(section: StringName, key: StringName): changes.append([section, key]))
	var r: Dictionary = s.set_control(&"attack", "key:74")
	_expect(errs, r["result"] == &"bound" and changes == [[&"controls", &"attack"]] and _im(&"attack") == ["key:74"] and _distinct(s),
		"[1] 공격→J: %s, changed %s, InputMap %s" % [str(r), str(changes), str(_im(&"attack"))])
	changes.clear()
	r = s.set_control(&"guard", "key:74")
	_expect(errs, r["result"] == &"cleared" and r["other"] == &"attack" and s.controls["attack"] == "" and _im(&"attack").is_empty() and _im(&"guard") == ["key:74"],
		"[1] 막기→J(겹침): %s, 공격 '%s'" % [str(r), str(s.controls["attack"])])
	_expect(errs, changes.size() == 2 and InputMap.has_action(&"attack") and _distinct(s), "[1] 겹침의 changed가 %d번 (기대 2) 또는 액션이 사라짐" % changes.size())
	for action in Controls.ACTIONS:
		_expect(errs, not Input.is_action_pressed(action), "[1] 바꾼 뒤 %s가 눌린 채임" % action)
	s.save()
	changes.clear()
	var dirty_before: bool = s.get("_dirty")
	r = s.set_control(&"attack", "key:%d" % KEY_ESCAPE)
	_expect(errs, r["result"] == &"reserved" and r["use"] == "멈춤" and changes.is_empty() and s.controls["attack"] == "" and s.get("_dirty") == dirty_before,
		"[1] 공격→Esc: %s, changed %d" % [str(r), changes.size()])
	r = s.set_control(&"attack", "")
	_expect(errs, r["result"] == &"invalid" and changes.is_empty(), "[1] 공격→빈 글이 invalid가 아님: %s" % str(r))
	r = s.set_control(&"guard", "key:74")
	_expect(errs, r["result"] == &"same" and changes.is_empty(), "[1] 같은 값이 same이 아님: %s" % str(r))
	r = s.set_control(&"attack", "key:75")
	_expect(errs, r["result"] == &"bound" and s.controls["attack"] == "key:75" and _distinct(s), "[1] 빈 공격→K: %s" % str(r))
	for action in Controls.ACTIONS:
		_expect(errs, not Input.is_action_pressed(action), "[1] 적용 뒤 %s가 눌린 채임" % action)
	s.set_control(&"guard", "key:75")
	_expect(errs, s.controls["attack"] == "" and _distinct(s), "[1] 공격이 K를 잃고 비지 않음")
	_expect(errs, s.reset_controls() and _codes(s) == _default_list() and _im(&"attack") == ["mouse:1"], "[1] reset_controls가 빈 것까지 처음 값으로 되돌리지 못함: %s" % str(_codes(s)))
	_expect(errs, not s.reset_controls(), "[1] 이미 처음 값인데 reset_controls가 참")


## 2. 조작 탭.
func _check_tab(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	var s := _make()
	var changes := [0]
	s.changed.connect(func(_a, _b): changes[0] += 1)
	var screen := _open_screen(s)
	_press(screen, "TabControls")
	var warn := screen.find_child("ControlsEmptyWarn", true, false) as Label
	_expect(errs, _btn(screen, "TabControls").button_pressed and not _btn(screen, "TabAudio").button_pressed, "[2] 조작 탭으로 갔는데 TabControls가 눌린 모습이 아님")
	_expect(errs, changes[0] == 0 and not Store.exists(TEST_PATH), "[2] 탭을 여는 것만으로 changed·파일이 생김")
	_expect(errs, warn != null and not warn.visible, "[2] 처음 값에서 ControlsEmptyWarn이 보임")
	_press(screen, "Bind_attack")
	_expect(errs, _btn(screen, "Bind_attack").text == "누른다…" and _note(screen).visible, "[2] 기다림이 시작되지 않음 ('%s')" % _btn(screen, "Bind_attack").text)
	screen.set("_capture_msec", Time.get_ticks_msec())
	_key(KEY_J)
	_expect(errs, screen.get("_waiting") == &"attack" and s.controls["attack"] == "mouse:1", "[2] 400밀리초 안의 J가 버려지지 않음")
	_pull_capture(screen)
	_key(KEY_R)
	_expect(errs, screen.get("_waiting") == &"attack" and _note(screen).text.contains("다시 하기"), "[2] R의 알림 '%s'" % _note(screen).text)
	_send(_mouse_event(MOUSE_BUTTON_WHEEL_UP))
	_expect(errs, screen.get("_waiting") == &"attack" and _note(screen).text.contains("쓸 수 없는 입력"), "[2] 휠의 알림 '%s'" % _note(screen).text)
	_key(KEY_ESCAPE)
	_expect(errs, screen.get("_waiting") == &"" and _note(screen).text == "그대로 두었다" and screen.get_parent() != null and screen.is_inside_tree(),
		"[2] Esc가 기다림만 취소하지 않음 ('%s')" % _note(screen).text)

	# 실제 버튼 위의 클릭. 양성 대조: 기다림 밖에서 ControlsReset의 가운데를 누르면 눌려야 한다.
	_layout_now(screen)
	_click_center(screen, "ControlsReset")
	_click_live = _note(screen).text == "이미 처음 값이다"
	if not _click_live:
		print("  INFO T101 [2] 실제 클릭이 버튼에 닿지 않음 — 아래 셋은 건너뛰고 R3는 사용자 몫")
	else:
		_check_tab_clicks(errs, s, screen, changes)
	_check_tab_rest(errs)


## (가)~(다): 잡은 좌클릭과 다른 버튼 위의 좌클릭.
func _check_tab_clicks(errs: Array[String], s: Node, screen: SettingsScreen, changes: Array) -> void:
	# 가. 같은 칸
	_press(screen, "Bind_guard")
	_pull_capture(screen)
	_layout_now(screen)
	_click_center(screen, "Bind_guard")
	_expect(errs, s.controls["guard"] == "mouse:1" and s.controls["attack"] == "", "[2 가] 같은 칸 좌클릭: 막기 %s·공격 '%s'" % [s.controls["guard"], s.controls["attack"]])
	_expect(errs, _note(screen).text == "겹쳤다 — 막기: 좌클릭 · 공격은 이제 비었다", "[2 가] 알림 '%s'" % _note(screen).text)
	_expect(errs, screen.get("_waiting") == &"", "[2 가] 잡은 누름이 새어 기다림이 다시 열림")
	var warn := screen.find_child("ControlsEmptyWarn", true, false) as Label
	_expect(errs, _btn(screen, "Bind_guard").text == "좌클릭" and _btn(screen, "Bind_attack").text == "없음" and warn.visible and warn.text.contains("공격"),
		"[2 가] 버튼 글·경고: '%s'·'%s'·'%s'" % [_btn(screen, "Bind_guard").text, _btn(screen, "Bind_attack").text, warn.text])
	_expect(errs, _section(Store.read(TEST_PATH), "controls").get("attack") == "", "[2 가] 파일에 attack \"\"가 없음")

	# 나. 다른 버튼
	_press(screen, "ControlsReset")
	_expect(errs, s.controls["attack"] == "mouse:1" and s.controls["guard"] == "mouse:2", "[2 나] 처음 값으로가 되돌리지 못함")
	var before: int = changes[0]
	_press(screen, "Bind_attack")
	_pull_capture(screen)
	_layout_now(screen)
	_click_center(screen, "ControlsReset")
	_expect(errs, screen.get("_waiting") == &"" and _note(screen).text == "이미 처음 값이다" and s.controls["attack"] == "mouse:1" and changes[0] == before,
		"[2 나] ControlsReset 위 좌클릭: 기다림 %s, 알림 '%s', changed +%d" % [str(screen.get("_waiting")), _note(screen).text, changes[0] - before])
	_press(screen, "Bind_attack")
	_pull_capture(screen)
	_layout_now(screen)
	_click_center(screen, "TabAudio")
	_expect(errs, screen.get("_waiting") == &"" and screen.find_child("VolumeSlider", true, false) != null and s.controls["attack"] == "mouse:1",
		"[2 나] TabAudio 위 좌클릭이 취소하고 탭을 바꾸지 않음")
	_layout_now(screen)
	_press(screen, "TabControls")
	_press(screen, "Bind_attack")
	_pull_capture(screen)
	_layout_now(screen)
	_click_center(screen, "SettingsClose")
	_expect(errs, screen.get_parent() == null and s.controls["attack"] == "mouse:1", "[2 나] SettingsClose 위 좌클릭이 취소하고 닫지 않음")
	_free_made()

	# 다. 빈 곳
	s = _make()
	screen = _open_screen(s)
	_press(screen, "TabControls")
	_press(screen, "Bind_guard")
	_pull_capture(screen)
	_layout_now(screen)
	var title_label: Label = null
	for label in screen.find_children("*", "Label", true, false):
		if (label as Label).text == "설정":
			title_label = label as Label
	_expect(errs, title_label != null, "[2 다] 제목 줄을 찾지 못함")
	if title_label != null:
		_move(title_label.get_global_rect().get_center())
		_click(MOUSE_BUTTON_LEFT)
		_expect(errs, s.controls["guard"] == "mouse:1" and s.controls["attack"] == "" and screen.get("_waiting") == &"",
			"[2 다] 빈 곳 좌클릭: 막기 %s·공격 '%s'" % [s.controls["guard"], s.controls["attack"]])
	s.reset_controls()
	_free_made()


## 우클릭의 기다림, 닫기, 경고, 처음 값으로, 고친 알림. 실제 클릭이 닿지 않아도 돈다.
func _check_tab_rest(errs: Array[String]) -> void:
	_free_made()
	Store.erase(TEST_PATH)
	var s := _make()
	var screen := _open_screen(s)
	_press(screen, "TabControls")
	_press(screen, "Bind_attack")
	_pull_capture(screen)
	_move(Vector2(640, 300))
	_button(MOUSE_BUTTON_RIGHT, true)
	_button(MOUSE_BUTTON_RIGHT, false)
	_expect(errs, s.controls["attack"] == "mouse:2" and s.controls["guard"] == "", "[2] 우클릭 기다림: 공격 %s·막기 '%s'" % [s.controls["attack"], s.controls["guard"]])
	_press(screen, "SettingsClose")
	_expect(errs, screen.get_parent() == null, "[2] 빈 동작이 있는데 닫기가 막힘")
	screen = _open_screen(s)
	_press(screen, "TabControls")
	var warn := screen.find_child("ControlsEmptyWarn", true, false) as Label
	_expect(errs, warn != null and warn.visible, "[2] 다시 연 조작 탭에 경고가 없음")
	_press(screen, "ControlsReset")
	_expect(errs, _codes(s) == _default_list() and _note(screen).text == "처음 값으로 되돌렸다" and not warn.visible, "[2] 처음 값으로 뒤: 알림 '%s'" % _note(screen).text)
	_free_made()
	_restore_inputs()
	_write_text('{"controls": {"attack": "key:abc"}}')
	s = _make()
	screen = _open_screen(s)
	_press(screen, "TabControls")
	_expect(errs, _note(screen).visible and _note(screen).text.contains("읽을 수 없는 조작"), "[2] 고친 알림이 뜨지 않음")
	_press(screen, "SettingsClose")
	screen = _open_screen(s)
	_press(screen, "TabControls")
	_expect(errs, not _note(screen).visible, "[2] 고친 알림이 두 번째 열기에도 뜸")


## 3. 실제 입력.
func _check_real_input(errs: Array[String]) -> void:
	Controls.apply_codes({&"attack": "key:%d" % KEY_J, &"guard": "key:%d" % KEY_G, &"step_forward": "key:%d" % KEY_UP, &"step_back": "key:%d" % KEY_K})
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	_move(FREE_SPOT)
	_expect(errs, _tree.root.gui_get_focus_owner() == null, "[3] 새 판에서 초점 가진 노드가 있음: %s" % _focus_path())
	_key(KEY_UP)
	_expect(errs, core.player_state == DuelTypes.PlayerState.STEPPING, "[3] Up이 전진이 아님")
	_advance(duel, core.weapon.step_time + 0.05)
	_expect(errs, core.distance == DuelTypes.Distance.ENGAGE, "[3] Up 뒤 간격이 교전이 아님 (%d)" % core.distance)
	_key(KEY_K)
	_advance(duel, core.weapon.step_time + 0.05)
	_expect(errs, core.distance == DuelTypes.Distance.FAR, "[3] K 뒤 간격이 멀리가 아님 (%d)" % core.distance)
	_key(KEY_W)
	_key(KEY_S)
	_expect(errs, core.player_state == DuelTypes.PlayerState.READY and core.distance == DuelTypes.Distance.FAR, "[3] W·S가 아직 동작함")
	_click(MOUSE_BUTTON_LEFT)
	_expect(errs, _attack_starts(core) == 0 and core.player_state == DuelTypes.PlayerState.READY, "[3] 좌클릭이 공격이 됨")
	_key_down(KEY_G)
	_expect(errs, core.guard_held and core.player_state == DuelTypes.PlayerState.GUARD, "[3] G가 막기가 아님")
	var entered := core.guard_enter_time
	_key_down(KEY_G, true)
	_expect(errs, core.guard_enter_time == entered, "[3] G의 echo가 막기를 새로 누른 것으로 침")
	_key_up(KEY_G)
	_expect(errs, not core.guard_held, "[3] G를 뗐는데 막기가 풀리지 않음")
	_advance(duel, 0.2)
	_key(KEY_J)
	_expect(errs, core.player_state == DuelTypes.PlayerState.WINDUP and _attack_starts(core) == 1, "[3] J가 공격이 아님 (상태 %d)" % core.player_state)

	# 공격을 비운 판: 막기를 J로.
	_free_made()
	Controls.apply_codes({&"attack": "", &"guard": "key:%d" % KEY_J, &"step_forward": "key:%d" % KEY_UP, &"step_back": "key:%d" % KEY_K})
	duel = _spawn_practice()
	core = duel.get("core")
	_key_down(KEY_J)
	_expect(errs, core.player_state == DuelTypes.PlayerState.GUARD and _attack_starts(core) == 0, "[3] 막기가 된 J가 GUARD가 아님")
	_click(MOUSE_BUTTON_LEFT)
	_key_down(KEY_J, true)
	_expect(errs, _attack_starts(core) == 0, "[3] 빈 공격에서 좌클릭이나 J가 공격이 됨")
	_key_up(KEY_J)


## 4. 멈춤 → 설정 → 조작 → 닫기 → 계속.
func _check_pause_change(errs: Array[String]) -> void:
	var settings := _settings_node()
	settings.call("reset_controls")
	settings.call("set_control", &"step_forward", "key:%d" % KEY_UP)
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	_move(FREE_SPOT)
	_button(MOUSE_BUTTON_RIGHT, true)
	_expect(errs, core.guard_held, "[4] 우클릭이 막기가 아님")
	_key(KEY_ESCAPE)
	var open_button := duel.find_child("PauseSettings", true, false) as Button
	_expect(errs, open_button != null and not open_button.disabled, "[4] PauseSettings가 없거나 꺼져 있음")
	if open_button == null or open_button.disabled:
		return
	open_button.pressed.emit()
	var screen := duel.find_child("SettingsScreen", true, false) as SettingsScreen
	_expect(errs, screen != null, "[4] SettingsScreen이 없음")
	if screen == null:
		return
	_layout_now(screen)
	_press(screen, "TabControls")
	_press(screen, "Bind_guard")
	_pull_capture(screen)
	_key(KEY_G)
	_expect(errs, _im(&"guard") == ["key:%d" % KEY_G], "[4] 바꾼 직후 InputMap의 guard %s (기대 G 하나)" % str(_im(&"guard")))
	_press(screen, "SettingsClose")
	_button(MOUSE_BUTTON_RIGHT, false)
	_key(KEY_ESCAPE)
	_expect(errs, not core.guard_held and not Input.is_action_pressed(&"guard"), "[4] 계속 뒤 막기가 붙어 있음 (guard_held %s)" % str(core.guard_held))
	var swallowed_before := int(duel.get("_swallowed_attacks"))
	_click(MOUSE_BUTTON_LEFT)
	_expect(errs, _attack_starts(core) == 0 and int(duel.get("_swallowed_attacks")) == swallowed_before + 1,
		"[4] 대기 중 좌클릭: 공격 %d, 버려진 수 %d (기대 %d)" % [_attack_starts(core), int(duel.get("_swallowed_attacks")), swallowed_before + 1])
	_finish_hold(duel)
	# 계속에서 막기를 푼 직후라 막기 쿨다운이 돈다(코어 set_guard): 지나게 한 뒤 새로 누른다.
	_advance(duel, 1.0)
	_key_down(KEY_G)
	_expect(errs, core.guard_held and core.player_state == DuelTypes.PlayerState.GUARD, "[4] 대기 뒤 G가 막기가 아님")
	_key_up(KEY_G)
	_expect(errs, _tree.root.gui_get_focus_owner() == null, "[4] 멈춤·설정·닫기·계속 뒤 초점 가진 노드가 남음: %s" % _focus_path())
	_key(KEY_UP)
	_expect(errs, core.player_state == DuelTypes.PlayerState.STEPPING, "[4] 계속 뒤 Up이 전진이 아님")
	settings.call("detach_for_run")


## 5. 대기 중 왼쪽 버튼(결정 522 (나)).
func _check_left_hold(errs: Array[String]) -> void:
	var settings := _settings_node()
	settings.call("reset_controls")
	settings.call("set_control", &"guard", "mouse:1")
	settings.call("set_control", &"attack", "key:%d" % KEY_J)
	var duel := _spawn_practice()
	var core: DuelCore = duel.get("core")
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	_expect(errs, bool(duel.get("paused")) and bool(duel.get("_holding")), "[5] 대기 상태를 만들지 못함")
	var events_before := core.record.events.size()
	_click(MOUSE_BUTTON_LEFT)
	_expect(errs, not core.guard_held and core.record.events.size() == events_before, "[5] 대기 중 왼쪽 클릭이 코어에 닿음")
	var swallowed_before := int(duel.get("_swallowed_attacks"))
	_key(KEY_J)
	_expect(errs, int(duel.get("_swallowed_attacks")) == swallowed_before + 1 and _attack_starts(core) == 0, "[5] 대기 중 J가 버려지지 않음")
	_button(MOUSE_BUTTON_LEFT, true)
	_finish_hold(duel)
	_expect(errs, core.guard_held, "[5] 쥔 왼쪽 막기가 대기 끝에 맞춰지지 않음")
	_button(MOUSE_BUTTON_LEFT, false)
	_free_made()

	# 막기가 빈 판.
	settings.call("reset_controls")
	settings.call("set_control", &"attack", "mouse:2")
	duel = _spawn_practice()
	core = duel.get("core")
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	_button(MOUSE_BUTTON_RIGHT, true)
	_finish_hold(duel)
	_expect(errs, not core.guard_held, "[5] 막기가 빈 판의 대기 끝에서 막기가 붙음")
	_button(MOUSE_BUTTON_RIGHT, false)
	_free_made()

	# 기본 묶음: 대기 중 우클릭은 지금처럼 막기.
	settings.call("reset_controls")
	duel = _spawn_practice()
	core = duel.get("core")
	_move(FREE_SPOT)
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	_button(MOUSE_BUTTON_RIGHT, true)
	_expect(errs, core.guard_held and core.player_state == DuelTypes.PlayerState.GUARD, "[5] 기본 묶음의 대기 중 우클릭이 막기가 아님")
	_button(MOUSE_BUTTON_RIGHT, false)
	settings.call("detach_for_run")


## 6. 안내.
func _check_help(errs: Array[String]) -> void:
	var opponent := load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData
	var lunge_opponent := opponent.duplicate() as OpponentData
	lunge_opponent.complacent_time = 20.0
	lunge_opponent.complacent_limit = 1
	var weapon := load(DuelScene.WEAPON_PATH) as WeaponData
	var text := DuelHud.help_text(lunge_opponent, false, false, weapon)
	_expect(errs, text.split("\n")[0].begins_with(OLD_HELP_LINE) and not text.contains("비어 있는 동작"), "[6] 처음 값의 첫 줄이 옛 글과 다름: %s" % text.split("\n")[0])
	Controls.apply_codes({&"attack": "key:%d" % KEY_J, &"guard": "mouse:2", &"step_forward": "key:%d" % KEY_UP, &"step_back": "key:%d" % KEY_K})
	text = DuelHud.help_text(lunge_opponent, false, false, weapon)
	_expect(errs, text.contains("J 공격") and text.contains("Up/K 간격"), "[6] 바꾼 키의 첫 줄: %s" % text.split("\n")[0])
	if weapon.close_bind_time > 0.0:
		_expect(errs, text.contains("물러난다(K)"), "[6] 엉킴 줄에 후퇴의 키가 없음")
	if weapon.lunge_windup > 0.0:
		_expect(errs, text.contains("물러나(K) 멀리에서 J"), "[6] 런지 줄에 키 이름이 없음")
	Controls.apply_codes({&"attack": "", &"guard": "mouse:2", &"step_forward": "key:%d" % KEY_W, &"step_back": "key:%d" % KEY_S})
	text = DuelHud.help_text(lunge_opponent, false, false, weapon)
	_expect(errs, text.contains("— 공격") and text.split("\n")[0].contains("F1 디버그 · 비어 있는 동작: 공격 — 설정의 조작 탭에서 준다"), "[6] 빈 공격의 첫 줄: %s" % text.split("\n")[0])
	if weapon.lunge_windup > 0.0:
		_expect(errs, text.contains("멀리에서 —"), "[6] 빈 공격의 런지 줄")

	# 처음 화면: 열 때마다 새로 짓는다.
	Controls.apply_codes(Controls.default_codes())
	var title: Node = (load(SessionScript.TITLE_PATH) as PackedScene).instantiate()
	_tree.root.add_child(title)
	_made.append(title)
	_press(title, "Help")
	_expect(errs, _all_text(title).contains("좌클릭 공격"), "[6] 처음 도움말에 '좌클릭 공격'이 없음")
	_press(title, "HelpClose")
	Controls.apply_codes({&"attack": "key:%d" % KEY_J, &"guard": "mouse:2", &"step_forward": "key:%d" % KEY_W, &"step_back": "key:%d" % KEY_S})
	_press(title, "Help")
	_expect(errs, _all_text(title).contains("J 공격") and title.find_children("HelpScreen", "", true, false).size() == 1,
		"[6] 다시 연 도움말이 새 글이 아니거나 HelpScreen이 %d개" % title.find_children("HelpScreen", "", true, false).size())

	# 결투 시작의 기록 줄.
	Controls.apply_codes(Controls.default_codes())
	var duel := _spawn_practice()
	var log_label := duel.get_node("HUD").get("_log_label") as Label
	_expect(errs, not log_label.text.contains("비어 있는 동작"), "[6] 처음 값의 판에 기록 줄이 있음: %s" % log_label.text)
	var plain_events: int = (duel.get("core") as DuelCore).record.events.size()
	Controls.apply_codes({&"attack": "mouse:1", &"guard": "", &"step_forward": "key:%d" % KEY_W, &"step_back": "key:%d" % KEY_S})
	duel.call("start_duel")
	_expect(errs, log_label.text.contains("비어 있는 동작: 막기"), "[6] 막기가 빈 판의 기록 줄: '%s'" % log_label.text)
	_expect(errs, (duel.get("core") as DuelCore).record.events.size() == plain_events, "[6] 기록 줄이 판의 사건 기록에 들어감")


func _all_text(node: Node) -> String:
	var parts: Array[String] = []
	for child in node.find_children("*", "Label", true, false):
		parts.append((child as Label).text)
	for child in node.find_children("*", "Button", true, false):
		parts.append((child as Button).text)
	return "\n".join(parts)
