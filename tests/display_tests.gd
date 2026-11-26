extends RefCounted
## T102~T103: 화면 모드·창 크기(계획 S04) — 값·격리·셈·좌표 / 화면 탭·F11·결투의 멈춤.
## 창은 건드리지 않는다(결정 531): 러너는 헤드리스이고 명령 줄에 res://tests/가 있어 Settings가 잠긴다. 파일은 TEST_PATH·TEST_SAVE_PATH만 쓰고 끝에 지운다.
## 입력은 엔진의 입력 경로(Input.parse_input_event)로 보낸다. preload 상수 이름은 SettingsScript다(자동 로드 이름과 겹치면 경고가 난다).

const Controls := preload("res://scripts/controls.gd")
const Day := preload("res://tests/day_tests.gd")
const Display := preload("res://scripts/display.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const SettingsScript := preload("res://scripts/settings.gd")
const SessionScript := preload("res://scripts/game_session.gd")
const Store := preload("res://scripts/save_store.gd")

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const TEST_PATH := "user://bravi_test_settings_S04.json"
const TEST_SAVE_PATH := "user://bravi_test_save_S04.json"
const V1600 := Vector2i(1600, 900)
const V1280 := Vector2i(1280, 720)
const V1920 := Vector2i(1920, 1080)
const DECOR := Vector2i(16, 40)

var _tree: SceneTree
var _d := Day.new()
var _mouse_pos := Vector2.ZERO
var _made: Array[Node] = []
var _stand_in: Node = null


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T102", "name": "화면 설정: 값·격리·셈 — 늘이기, 읽기, 쓰기·분리, 크기 목록, 좌표, 예약", "fn": t102_display_values},
		{"id": "T103", "name": "화면 탭·F11·결투의 멈춤 — 탭, 실제 클릭, F11, 결투", "fn": t103_display_screen},
	]


func cleanup() -> void:
	_free_made()
	_erase_files()
	_restore()
	if _stand_in != null and is_instance_valid(_stand_in):
		_stand_in.free()
	_stand_in = null
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


## 자동 로드의 화면·조작을 처음 값으로(detach_for_run).
func _restore() -> void:
	if _tree == null:
		return
	var autoload := _tree.root.get_node_or_null(^"Settings")
	if autoload != null and autoload.has_method("detach_for_run"):
		autoload.call("detach_for_run")
	if _stand_in != null and is_instance_valid(_stand_in):
		_stand_in.call("detach_for_run")
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


## 자동 로드. 러너에 없으면 같은 이름의 대역을 한 번 만들어 둔다(결투·처음 화면이 /root/Settings를 찾는다).
func _autoload() -> Node:
	var found := _tree.root.get_node_or_null(^"Settings")
	if found == null:
		if _stand_in == null:
			_stand_in = SettingsScript.new()
			_stand_in.path = ""
			_stand_in.name = "Settings"
			_tree.root.add_child(_stand_in)
		found = _stand_in
	return found


func _write_text(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _read_json(raw: Dictionary) -> Node:
	_write_text(JSON.stringify(raw))
	return _make()


func _section(data: Dictionary, name: String) -> Dictionary:
	var found: Variant = data.get(name)
	return found as Dictionary if found is Dictionary else {}


func _bytes() -> PackedByteArray:
	return FileAccess.get_file_as_bytes(TEST_PATH)


func _calls(s: Node) -> int:
	return int(s.get("_window_calls"))


func _applied(s: Node) -> int:
	return int(s.get("_apply_count"))


func _key_event(key: Key, pressed: bool, echo: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.echo = echo
	ev.pressed = pressed
	return ev


func _send(ev: InputEvent) -> void:
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _key_down(key: Key, echo := false) -> void:
	_send(_key_event(key, true, echo))


func _key_up(key: Key) -> void:
	_send(_key_event(key, false, false))


func _key(key: Key) -> void:
	_key_down(key)
	_key_up(key)


## 창 좌표로 직접 움직인다(엔진의 변환을 테스트가 쓰지 않는다).
func _move_window(window_pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = window_pos
	ev.global_position = window_pos
	_mouse_pos = window_pos
	_send(ev)


## 뷰포트 좌표로 움직인다(실제 클릭용: 엔진이 이 창의 변환으로 되돌린다).
func _move(pos: Vector2) -> void:
	_move_window(_tree.root.get_screen_transform() * pos)


func _button(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = _mouse_pos
	ev.global_position = _mouse_pos
	_send(ev)


func _click() -> void:
	_button(true)
	_button(false)


## 코드로 만든 컨테이너는 한 프레임 안에 자리를 잡지 않는다(러너는 프레임 없이 돈다): 위에서부터 한 번 앉힌다.
func _layout_now(node: Node) -> void:
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child in node.get_children():
		_layout_now(child)


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


func _press(screen: Node, node_name: String) -> void:
	var button := _btn(screen, node_name)
	if button != null:
		button.pressed.emit()
	_layout_now(screen)


func _on(screen: Node, node_name: String) -> bool:
	var button := _btn(screen, node_name)
	return button != null and button.button_pressed


func _label(screen: Node, node_name: String) -> Label:
	return screen.find_child(node_name, true, false) as Label


func _now_text(screen: Node) -> String:
	var label := _label(screen, "DisplayNow")
	return label.text if label != null else "(DisplayNow 없음)"


func _spawn_practice() -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	_made.append(duel)
	return duel


func _listen(s: Node) -> Array:
	var seen := []
	s.changed.connect(func(section: StringName, key: StringName) -> void: seen.append("%s:%s" % [section, key]))
	return seen


# ================================================================ T102

func t102_display_values() -> String:
	var errs: Array[String] = []
	_erase_files()
	_check_stretch(errs)
	_check_read(errs)
	_free_made()
	_check_write(errs)
	_free_made()
	_check_sizes(errs)
	_check_coordinates(errs)
	_check_engine_path(errs)
	_check_reserved(errs)
	_free_made()
	_erase_files()
	_restore()
	return _result(errs)


## 1. 늘이기 설정과 러너의 잠금.
func _check_stretch(errs: Array[String]) -> void:
	_expect(errs, Display.base() == V1280, "[1] 뷰포트 크기 %s" % str(Display.base()))
	_expect(errs, str(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items", "[1] stretch/mode가 canvas_items가 아님")
	_expect(errs, str(ProjectSettings.get_setting("display/window/stretch/aspect", "keep")) == "keep", "[1] stretch/aspect가 keep이 아님")
	var a := _autoload()
	_expect(errs, a.window_locked, "[1] 러너의 Settings가 잠기지 않음")
	_expect(errs, _calls(a) == 0, "[1] 러너에서 창 걸음 %d" % _calls(a))
	_expect(errs, a.path == "", "[1] 자동 로드의 path가 '%s'" % a.path)
	_expect(errs, a.display["mode"] == &"windowed" and a.display["size"] == V1280, "[1] 자동 로드의 화면이 처음 값이 아님: %s" % str(a.display))
	_expect(errs, a.last_plan.get("size") == V1280 and a.last_plan.get("clamped") == false,
		"[1] last_plan이 본보기 모니터의 처음 값이 아님: %s" % str(a.last_plan))


## 2. 읽기.
func _check_read(errs: Array[String]) -> void:
	# [읽은 display, 모드, 폭, 높이, 고쳤는가]
	var table: Array = [
		[null, "windowed", 1280, 720, false],
		[{"mode": "fullscreen"}, "fullscreen", 1280, 720, false],
		[{"width": 1216, "height": 684}, "windowed", 1216, 684, false],
		[{"mode": "exclusive"}, "windowed", 1280, 720, true],
		[{"mode": 3}, "windowed", 1280, 720, true],
		[{"width": "1600", "height": 900}, "windowed", 1280, 720, true],
		[{"width": 1600, "height": 1000}, "windowed", 1280, 720, true],
		[{"width": 1040, "height": 585}, "windowed", 1280, 720, true],
		[{"width": 320, "height": 180}, "windowed", 1280, 720, true],
		[{"width": 8192, "height": 4608}, "windowed", 1280, 720, true],
	]
	for row: Array in table:
		var got: Dictionary = SettingsScript.clean_display(row[0])
		var shown: Dictionary = got["display"]
		var label := str(row[0])
		_expect(errs, shown["mode"] == row[1] and int(shown["width"]) == int(row[2]) and int(shown["height"]) == int(row[3]),
			"[2] %s → %s %sx%s" % [label, shown["mode"], str(shown["width"]), str(shown["height"])])
		_expect(errs, bool(got["repaired"]) == bool(row[4]), "[2] %s의 repaired %s" % [label, str(got["repaired"])])
	var unknown: Dictionary = SettingsScript.normalize({"display": {"vsync": true}})["display"]
	_expect(errs, unknown.get("vsync") == true, "[2] 모르는 칸 vsync가 사라짐")
	# 새 인스턴스: 못 읽는 모드는 그 칸만, 깨진 JSON은 처음 값.
	var s := _read_json({"version": 1, "display": {"mode": "exclusive", "width": 1600, "height": 900}})
	_expect(errs, s.display["mode"] == &"windowed" and s.display["size"] == V1600 and s.display_repaired, "[2] 못 읽는 모드만 처음 값이어야 함: %s" % str(s.display))
	_free_made()
	_write_text("{broken")
	s = _make()
	_expect(errs, s.display["mode"] == &"windowed" and s.display["size"] == V1280 and not s.display_repaired, "[2] 깨진 JSON이 처음 값이 아님")
	_expect(errs, _calls(s) == 0, "[2] 읽기에서 창 걸음 %d" % _calls(s))


## 3. 쓰기·분리·같은 값.
func _check_write(errs: Array[String]) -> void:
	_erase_files()
	Store.write(TEST_SAVE_PATH, {"day": 3, "money": 10})
	var save_before := FileAccess.get_file_as_bytes(TEST_SAVE_PATH)
	var s := _make()
	_expect(errs, s.window_locked, "[3] 새 인스턴스가 잠기지 않음")
	s.set_volume(50)
	s.save()
	_expect(errs, not Store.read(TEST_PATH).has("display"), "[3] 음량만 바꾼 파일에 display가 적힘")
	var seen := _listen(s)
	_expect(errs, s.set_window_size(V1600), "[3] set_window_size(1600x900)가 거짓")
	s.save()
	var shown := _section(Store.read(TEST_PATH), "display")
	_expect(errs, shown.get("mode") == "windowed" and int(shown.get("width", 0)) == 1600 and int(shown.get("height", 0)) == 900,
		"[3] 파일의 display가 다름: %s" % str(shown))
	_expect(errs, seen == ["display:size"], "[3] changed가 %s" % str(seen))
	var s2 := _make()
	_expect(errs, s2.display["size"] == V1600 and s2.display["mode"] == &"windowed" and s2.last_plan.get("size") == V1600,
		"[3] 새 인스턴스가 1600x900을 읽지 않음: %s / %s" % [str(s2.display), str(s2.last_plan)])
	s.set_display_mode(&"fullscreen")
	s.save()
	var s3 := _make()
	_expect(errs, s3.display["mode"] == &"fullscreen" and s3.display["size"] == V1600, "[3] 전체 화면을 읽고 크기 1600x900이 남아야 함: %s" % str(s3.display))
	_expect(errs, s3.last_plan.get("mode") == &"fullscreen", "[3] last_plan의 모드가 전체 화면이 아님")
	s.set_display_mode(&"windowed")
	s.save()

	# 같은 값: 거짓, changed·_dirty·파일은 그대로, 창에는 다시 건다.
	seen.clear()
	var bytes := _bytes()
	var applied := _applied(s)
	_expect(errs, not s.set_window_size(V1600), "[3] 같은 크기가 참")
	_expect(errs, not s.set_display_mode(&"windowed"), "[3] 같은 모드가 참")
	_expect(errs, _applied(s) == applied + 2, "[3] 같은 값에서 _apply_count +%d (기대 2)" % (_applied(s) - applied))
	_expect(errs, seen.is_empty() and not bool(s.get("_dirty")) and _bytes() == bytes and not s.save(), "[3] 같은 값이 changed·_dirty·파일을 건드림: %s" % str(seen))

	# 전체 화면에서 같은 크기: 모드가 바뀌므로 바뀐 것이다.
	s.set_display_mode(&"fullscreen")
	s.save()
	seen.clear()
	_expect(errs, s.set_window_size(V1600), "[3] 전체 화면에서 같은 크기가 거짓")
	s.save()
	_expect(errs, s.display["mode"] == &"windowed" and s.display["size"] == V1600, "[3] 창·1600x900으로 돌아오지 않음")
	_expect(errs, seen == ["display:mode"], "[3] 모드만 바뀐 changed가 %s" % str(seen))
	_expect(errs, _section(Store.read(TEST_PATH), "display").get("mode") == "windowed", "[3] 파일이 windowed로 다시 적히지 않음")

	_expect(errs, FileAccess.get_file_as_bytes(TEST_SAVE_PATH) == save_before and not Store.read(TEST_SAVE_PATH).has("display"), "[3] 영업 세이브가 바뀌었거나 display가 적힘")
	for settings: Node in [s, s2, s3]:
		_expect(errs, _calls(settings) == 0, "[3] 창 걸음 %d" % _calls(settings))
	var a := _autoload()
	var calls := _calls(a)
	var count := _applied(a)
	a.detach_for_run()
	_expect(errs, _calls(a) == calls and _applied(a) == count, "[3] detach_for_run이 _window_calls·_apply_count를 건드림")


## 4. 크기 목록·맞춤(셈만).
func _check_sizes(errs: Array[String]) -> void:
	var cases: Array = [
		[Vector2i(1920, 1040), [V1280, V1600]],
		[Vector2i(2560, 1400), [V1280, V1600, V1920]],
		[Vector2i(3840, 2120), [V1280, V1600, V1920, Vector2i(2560, 1440)]],
		[Vector2i(1366, 728), [Vector2i(1216, 684)]],
		[Vector2i(7680, 4280), [V1280, V1600, V1920, Vector2i(2560, 1440), Vector2i(3840, 2160)]],
		[Vector2i(0, 0), [V1280]],
		[Vector2i(600, 300), [V1280]],
	]
	for row: Array in cases:
		var got: Array = Display.sizes_for(row[0], DECOR)
		_expect(errs, got == row[1], "[4] sizes_for(%s) = %s (기대 %s)" % [str(row[0]), str(got), str(row[1])])
	_expect(errs, Display.fit_size(V1920, Vector2i(0, 0), DECOR) == V1280, "[4] fit_size(1920x1080, 0x0)")
	_expect(errs, Display.fit_size(V1920, Vector2i(1920, 1040), DECOR) == V1600, "[4] fit_size(1920x1080, 1920x1040)")
	_expect(errs, Display.fit_size(V1600, Vector2i(2560, 1400), DECOR) == V1600, "[4] 들어가는 크기는 그대로")
	var plan := Display.plan({"mode": &"windowed", "size": V1920}, Vector2i(1920, 1040), DECOR)
	_expect(errs, plan["size"] == V1600 and plan["clamped"] == true, "[4] plan이 줄이지 못함: %s" % str(plan))
	var plain := Display.plan({"mode": &"fullscreen", "size": V1600}, Vector2i(2560, 1400), DECOR)
	_expect(errs, plain["size"] == V1600 and plain["clamped"] == false and plain["mode"] == &"fullscreen", "[4] 맞는 plan이 다름: %s" % str(plain))
	_expect(errs, _autoload().available_sizes() == [V1280, V1600, V1920], "[4] 잠긴 실행의 available_sizes: %s" % str(_autoload().available_sizes()))
	_expect(errs, Display.size_name(V1600) == "1600×900", "[4] size_name '%s'" % Display.size_name(V1600))
	# 알림의 조사: 끝자리 0·3·6·7은 "으로", 나머지(1·2·4·5·8·9)는 "로".
	for pair: Array in [["1280×720", "으로"], ["1600×900", "으로"], ["1216×684", "로"], ["1920×1080", "으로"], ["1152×648", "로"], ["1024×576", "으로"], ["2560×1441", "로"]]:
		_expect(errs, SettingsScreen._with_ro(pair[0]) == pair[0] + pair[1], "[4] _with_ro(%s) = %s" % [pair[0], SettingsScreen._with_ro(pair[0])])


## 창 크기마다 9칸의 가운데·칸 안쪽 3화소 점과 띠 위의 점을 [창 좌표, 기대 칸]으로(Display의 셈).
func _cell_points(window: Vector2i) -> Array:
	var out: Array = []
	var rect := Display.content_rect(window)
	var scale := rect.size.x / 1280.0
	var cell_w := 1280.0 / 3.0
	var cell_h := 240.0
	for c in 3:
		for r in 3:
			var xs := [(c + 0.5) * cell_w, c * cell_w + 3.0, (c + 1) * cell_w - 3.0]
			var ys := [(r + 0.5) * cell_h, r * cell_h + 3.0, (r + 1) * cell_h - 3.0]
			for x: float in xs:
				for y: float in ys:
					out.append([(rect.position + Vector2(x, y) * scale).round(), Vector2i(c, r)])
	if rect.position.x > 1.0:
		out.append([Vector2(rect.position.x / 2.0, window.y / 2.0).round(), Vector2i(0, 1)])
	if rect.position.y > 1.0:
		out.append([Vector2(0.0, rect.position.y / 2.0).round(), Vector2i(0, 0)])
	out.append([Vector2(0.0, window.y / 2.0), Vector2i(0, 1)])
	return out


const WINDOWS: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1366, 768),
		Vector2i(1280, 1024), Vector2i(2560, 1080), Vector2i(3440, 1440), Vector2i(1000, 700)]


## 5. 좌표(셈).
func _check_coordinates(errs: Array[String]) -> void:
	for window: Vector2i in WINDOWS:
		var rect := Display.content_rect(window)
		var want_scale := minf(window.x / 1280.0, window.y / 720.0)
		_expect(errs, absf(rect.size.x - 1280.0 * want_scale) < 0.01 and absf(rect.size.y - 720.0 * want_scale) < 0.01, "[5] %s의 그림 크기 %s" % [str(window), str(rect.size)])
		if window.x * 9 == window.y * 16:
			_expect(errs, rect.position.is_zero_approx(), "[5] 16:9 창 %s에 띠가 있음 %s" % [str(window), str(rect.position)])
		_expect(errs, absf(rect.position.x * 2.0 + rect.size.x - window.x) < 0.01 and absf(rect.position.y * 2.0 + rect.size.y - window.y) < 0.01,
			"[5] %s의 그림이 가운데가 아님 %s" % [str(window), str(rect)])
		for point: Array in _cell_points(window):
			var back := Display.to_viewport(point[0], window)
			var cell := DuelScene.aim_cell(back, Vector2(1280, 720))
			_expect(errs, cell == point[1], "[5] 창 %s의 점 %s → 칸 %s (기대 %s)" % [str(window), str(point[0]), str(cell), str(point[1])])


## 5의 엔진의 길(헤드리스에서만): 루트 창의 크기를 바꿔 엔진의 변환을 재고, 같은 창 좌표를 결투에 보내 칸을 본다.
func _check_engine_path(errs: Array[String]) -> void:
	if DisplayServer.get_name() != "headless":
		return
	var root := _tree.root
	var first_size := root.size
	var first_xf := root.get_screen_transform()
	var windows: Array = [Vector2i(1600, 1000), Vector2i(1366, 768)]
	for window: Vector2i in windows:
		root.size = window
		var xf := root.get_screen_transform()
		if window == windows[0] and xf == first_xf:
			errs.append("[5 엔진] 헤드리스 루트 창의 크기가 늘이기에 반영되지 않음")
			root.size = first_size
			return
		var rect := Display.content_rect(window)
		var scale := xf.x.length()
		_expect(errs, absf(scale - rect.size.x / 1280.0) * 1280.0 <= 1.0, "[5 엔진] 창 %s의 배율 %.4f (기대 %.4f)" % [str(window), scale, rect.size.x / 1280.0])
		var origin := xf.origin - Vector2(root.position)
		_expect(errs, absf(origin.x - rect.position.x) <= 1.0 and absf(origin.y - rect.position.y) <= 1.0, "[5 엔진] 창 %s의 이동 %s (기대 %s)" % [str(window), str(origin), str(rect.position)])
		_check_engine_aim(errs, window)
	root.size = first_size
	_expect(errs, root.size == first_size and root.get_screen_transform() == first_xf, "[5 엔진] 루트 창을 처음 크기·변환으로 되돌리지 못함")


func _check_engine_aim(errs: Array[String], window: Vector2i) -> void:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
	duel.set("rng_seed", 1)
	duel.set("_use_virtual_mouse", true)
	duel.set("mouse_aim_enabled", true)
	_tree.root.add_child(duel)
	_made.append(duel)
	var core: DuelCore = duel.get("core")
	for point: Array in _cell_points(window):
		_move_window(point[0])
		var cell := Vector2i(core.aim_direction, core.aim_height)
		_expect(errs, cell == point[1], "[5 엔진] 창 %s의 점 %s → 조준 %s (기대 %s)" % [str(window), str(point[0]), str(cell), str(point[1])])
	_made.erase(duel)
	duel.free()


## 6. 예약.
func _check_reserved(errs: Array[String]) -> void:
	_expect(errs, Controls.reserved_use("key:%d" % KEY_F11) == "전체 화면", "[6] F11이 예약되지 않음: '%s'" % Controls.reserved_use("key:%d" % KEY_F11))
	var cleaned: Dictionary = SettingsScript.clean_controls({"attack": "key:%d" % KEY_F11})
	var codes: Dictionary = cleaned["codes"]
	_expect(errs, codes["attack"] == Controls.default_code(&"attack") and bool(cleaned["repaired"]), "[6] F11에 묶인 공격이 처음 값으로 돌아오지 않음: %s" % str(codes["attack"]))
	_expect(errs, codes["guard"] == Controls.default_code(&"guard"), "[6] 다른 칸이 바뀜")


# ================================================================ T103

func t103_display_screen() -> String:
	var errs: Array[String] = []
	_erase_files()
	_restore()
	_check_tab(errs)
	_free_made()
	_check_tab_notes(errs)
	_free_made()
	_check_clicks(errs)
	_free_made()
	_check_f11(errs)
	_free_made()
	_check_duel(errs)
	_free_made()
	_erase_files()
	_restore()
	return _result(errs)


## 1. 탭(테스트 인스턴스, 처음 값에서).
func _check_tab(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	var s := _make()
	var seen := _listen(s)
	var screen := _open_screen(s)
	_press(screen, "TabDisplay")
	_expect(errs, _on(screen, "TabDisplay") and not _on(screen, "TabAudio"), "[1] 화면 탭이 눌린 모습이 아님")
	_expect(errs, seen.is_empty() and not Store.exists(TEST_PATH), "[1] 탭을 여는 것만으로 changed·파일이 생김")
	_expect(errs, _on(screen, "DisplayWindowed") and not _on(screen, "DisplayFullscreen") and _on(screen, "Size_1280x720"), "[1] 처음 눌림이 창·1280x720이 아님")
	_expect(errs, screen.find_children("Size_*", "Button", true, false).size() == 3, "[1] 크기 버튼이 셋이 아님")
	_expect(errs, _now_text(screen) == "지금: 창 1280×720", "[1] DisplayNow '%s'" % _now_text(screen))
	_expect(errs, _label(screen, "DisplayNote") != null and not _label(screen, "DisplayNote").visible, "[1] 처음 값에서 DisplayNote가 보임")

	_press(screen, "Size_1600x900")
	_expect(errs, s.display["size"] == V1600 and s.display["mode"] == &"windowed" and seen == ["display:size"], "[1] 1600x900을 누른 뒤 값 %s, changed %s" % [str(s.display), str(seen)])
	_expect(errs, _section(Store.read(TEST_PATH), "display").get("width") == 1600.0, "[1] 파일에 1600이 없음")
	_expect(errs, _on(screen, "Size_1600x900") and not _on(screen, "Size_1280x720") and _now_text(screen) == "지금: 창 1600×900", "[1] 눌림·글이 따라오지 않음: '%s'" % _now_text(screen))
	_press(screen, "DisplayFullscreen")
	_expect(errs, s.display["mode"] == &"fullscreen" and _on(screen, "DisplayFullscreen") and not _on(screen, "DisplayWindowed"), "[1] 전체 화면 버튼이 듣지 않음")
	_expect(errs, _on(screen, "Size_1600x900") and _now_text(screen) == "지금: 전체 화면", "[1] 전체 화면에서 크기 눌림·글: '%s'" % _now_text(screen))

	seen.clear()
	_press(screen, "Size_1600x900")
	_expect(errs, s.display["mode"] == &"windowed" and s.display["size"] == V1600 and seen == ["display:mode"], "[1] 전체 화면에서 눌린 크기가 창으로 돌리지 못함: %s %s" % [str(s.display), str(seen)])
	_expect(errs, _section(Store.read(TEST_PATH), "display").get("mode") == "windowed" and _on(screen, "DisplayWindowed"), "[1] 파일·창 버튼이 창으로 바뀌지 않음")

	# 이미 눌린 버튼을 다시: 창에 다시 걸 뿐 changed·파일은 그대로.
	seen.clear()
	var bytes := _bytes()
	var applied := _applied(s)
	_press(screen, "Size_1600x900")
	_expect(errs, _applied(s) == applied + 1, "[1] 눌린 크기 버튼을 다시 눌러도 창에 다시 걸지 않음")
	_press(screen, "DisplayWindowed")
	_expect(errs, _applied(s) == applied + 2 and seen.is_empty() and _bytes() == bytes, "[1] 눌린 창 버튼: _apply_count +%d, changed %s" % [_applied(s) - applied, str(seen)])
	s.set_display_mode(&"fullscreen")
	_press(screen, "Size_1280x720")
	_expect(errs, s.display["mode"] == &"windowed" and s.display["size"] == V1280, "[1] 전체 화면에서 1280x720이 창으로 돌리지 못함")
	_expect(errs, _calls(s) == 0, "[1] 창 걸음 %d" % _calls(s))


## 1의 알림 둘.
func _check_tab_notes(errs: Array[String]) -> void:
	var s := _read_json({"version": 1, "display": {"mode": "exclusive"}})
	var screen := _open_screen(s)
	_press(screen, "TabDisplay")
	var note := _label(screen, "DisplayNote")
	_expect(errs, note != null and note.visible and note.text.contains("읽을 수 없는 화면 설정"), "[1] 고친 화면 설정의 알림이 없음")
	var again := _open_screen(s)
	_press(again, "TabDisplay")
	_expect(errs, _label(again, "DisplayNote") != null and not _label(again, "DisplayNote").visible, "[1] 알림이 두 번째에도 뜸")
	_free_made()
	var c := _read_json({"version": 1, "display": {"mode": "windowed", "width": 1920, "height": 1080}})
	c.last_plan = {"mode": &"windowed", "size": V1600, "clamped": true}
	var clamped_screen := _open_screen(c)
	_press(clamped_screen, "TabDisplay")
	var clamped := _label(clamped_screen, "DisplayNote")
	_expect(errs, clamped != null and clamped.visible and clamped.text.contains("1920×1080 창이 들어가지 않아 1600×900으로 열었다"), "[1] 줄인 크기의 알림: '%s'" % (clamped.text if clamped != null else "없음"))


## 2. 실제 클릭. 양성 대조: 처음 클릭이 닿아야 나머지를 본다.
func _check_clicks(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	var s := _make()
	var seen := _listen(s)
	var screen := _open_screen(s)
	_press(screen, "TabDisplay")
	var target := _btn(screen, "Size_1600x900")
	if target == null:
		errs.append("[2] Size_1600x900이 없음")
		return
	_move(target.get_global_rect().get_center())
	_click()
	if s.display["size"] != V1600:
		errs.append("[2] 실제 클릭이 버튼에 닿지 않음")
		return
	_expect(errs, s.display["mode"] == &"windowed" and _on(screen, "Size_1600x900"), "[2] 클릭 뒤 창·1600x900이 아님")
	seen.clear()
	var applied := _applied(s)
	_layout_now(screen)
	_move(target.get_global_rect().get_center())
	_click()
	_expect(errs, _applied(s) == applied + 1 and seen.is_empty() and _on(screen, "Size_1600x900"),
		"[2] 이미 눌린 크기 버튼의 클릭: _apply_count +%d, changed %s, 눌림 %s" % [_applied(s) - applied, str(seen), str(_on(screen, "Size_1600x900"))])
	s.set_display_mode(&"fullscreen")
	seen.clear()
	_layout_now(screen)
	_move(target.get_global_rect().get_center())
	_click()
	_expect(errs, s.display["mode"] == &"windowed" and s.display["size"] == V1600 and seen == ["display:mode"],
		"[2] 전체 화면에서의 크기 클릭이 창으로 돌리지 못함: %s %s" % [str(s.display), str(seen)])


## 3. F11(실제 입력 길). 앞의 인스턴스를 모두 치운 뒤 자동 로드로 본다: 뒤에 붙은 인스턴스가 먼저 받아 가로채지 않게.
func _check_f11(errs: Array[String]) -> void:
	var a := _autoload()
	a.detach_for_run()
	var title: Node = (load(SessionScript.TITLE_PATH) as PackedScene).instantiate()
	_tree.root.add_child(title)
	_made.append(title)
	_key(KEY_F11)
	_expect(errs, a.display["mode"] == &"fullscreen" and a.last_plan.get("mode") == &"fullscreen", "[3] 처음 화면의 F11이 전체 화면이 아님: %s" % str(a.display))
	_expect(errs, _calls(a) == 0 and a.path == "", "[3] F11이 창을 건드리거나 파일 경로를 가짐")
	_key_down(KEY_F11, true)
	_key_up(KEY_F11)
	_expect(errs, a.display["mode"] == &"fullscreen", "[3] echo 누름이 바꿈")
	_key(KEY_F11)
	_expect(errs, a.display["mode"] == &"windowed", "[3] 다시 F11이 창이 아님")
	_made.erase(title)
	title.free()

	var screen := _open_screen(a)
	_press(screen, "TabDisplay")
	_key(KEY_F11)
	_expect(errs, _on(screen, "DisplayFullscreen") and _now_text(screen) == "지금: 전체 화면", "[3] 설정 화면이 F11을 따라오지 않음: '%s'" % _now_text(screen))
	_key(KEY_F11)
	_expect(errs, _on(screen, "DisplayWindowed") and _now_text(screen) == "지금: 창 1280×720", "[3] 두 번째 F11을 따라오지 않음: '%s'" % _now_text(screen))
	_press(screen, "TabControls")
	_press(screen, "Bind_attack")
	screen.set("_capture_msec", Time.get_ticks_msec() - 1000)
	_key(KEY_F11)
	var note := _label(screen, "ControlsNote")
	_expect(errs, a.display["mode"] == &"windowed" and screen.get("_waiting") == &"attack" and note != null and note.text.contains("전체 화면"),
		"[3] 기다림 중 F11: 모드 %s, 기다림 %s, 알림 '%s'" % [str(a.display["mode"]), str(screen.get("_waiting")), note.text if note != null else ""])
	_expect(errs, _calls(a) == 0, "[3] 창 걸음 %d" % _calls(a))


## 4. 결투의 멈춤.
func _check_duel(errs: Array[String]) -> void:
	var a := _autoload()
	a.detach_for_run()
	var duel := _spawn_practice()
	_key(KEY_F11)
	_expect(errs, bool(duel.get("paused")) and duel.get("_pause_menu") != null and a.display["mode"] == &"fullscreen", "[4] 흐르는 결투의 F11: paused %s, 모드 %s" % [str(duel.get("paused")), str(a.display["mode"])])
	var pauses := int(duel.get("_pause_count"))
	_expect(errs, pauses == 1, "[4] pauses %d (기대 1)" % pauses)
	_key(KEY_F11)
	_expect(errs, a.display["mode"] == &"windowed" and int(duel.get("_pause_count")) == pauses and bool(duel.get("paused")), "[4] 멈춤 화면 위의 F11: 모드 %s, pauses %d" % [str(a.display["mode"]), int(duel.get("_pause_count"))])
	duel.call("resume")
	_expect(errs, bool(duel.get("paused")) and bool(duel.get("_holding")), "[4] 계속 뒤 대기가 아님")
	_key(KEY_F11)
	_expect(errs, bool(duel.get("paused")) and not bool(duel.get("_holding")) and duel.get("_pause_menu") != null and int(duel.get("_pause_count")) == pauses + 1 and a.display["mode"] == &"fullscreen",
		"[4] 대기 중 F11이 다시 멈추지 못함: holding %s, pauses %d" % [str(duel.get("_holding")), int(duel.get("_pause_count"))])
	_free_made()
	a.detach_for_run()
	var ended := _spawn_practice()
	var core: DuelCore = ended.get("core")
	core.ended = true
	_key(KEY_F11)
	_expect(errs, not bool(ended.get("paused")) and ended.get("_pause_menu") == null and a.display["mode"] == &"fullscreen", "[4] 끝난 판의 F11: paused %s, 모드 %s" % [str(ended.get("paused")), str(a.display["mode"])])
	_free_made()
	a.detach_for_run()
	_expect(errs, a.display["mode"] == &"windowed" and _calls(a) == 0, "[4] detach_for_run 뒤 모드·창 걸음")
