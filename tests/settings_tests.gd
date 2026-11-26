extends RefCounted
## T97: 설정 파일 — 영업 세이브와 따로, 새로 시작해도 남고, 깨지면 처음 값, 설정 화면, 처음 화면의 "설정"(계획 S01).
## 파일은 TEST_PATH·TEST_SAVE_PATH만 쓴다(처음과 끝에 지운다). 플레이어의 설정과 저장 파일은 읽지도 쓰지도 않는다.
## 테스트 인스턴스는 path를 넣은 뒤 트리에 붙인다(_ready가 밖에서 넣은 path를 덮어쓰지 않는다. 결정 500).
## 이 스크립트를 preload한 상수는 SettingsScript다: Settings라고 지으면 자동 로드와 이름이 겹쳐 경고가 난다.

const Day := preload("res://tests/day_tests.gd")
const Session := preload("res://scripts/game_session.gd")
const Store := preload("res://scripts/save_store.gd")
const SettingsScript := preload("res://scripts/settings.gd")
const TEST_PATH := "user://bravi_test_settings.json"
const TEST_SAVE_PATH := "user://bravi_test_save_S01.json"

var _tree: SceneTree
var _d := Day.new()
## 만든 인스턴스와 덮개 부모. 끝에 한꺼번에 놓는다.
var _made: Array[Node] = []
var _bus_db := 0.0
var _bus_mute := false
var _bus_saved := false


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T97", "name": "설정 파일: 영업 세이브와 따로, 새로 시작해도 남고, 깨지면 처음 값", "fn": t97_settings},
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


func _erase_files() -> void:
	Store.erase(TEST_PATH)
	Store.erase(TEST_SAVE_PATH)


## _ready가 건 Master 버스의 볼륨·음소거를 이 테스트가 시작할 때의 값(자동 로드가 건 값)으로 되돌린다.
func _restore_bus() -> void:
	if not _bus_saved:
		return
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, _bus_db)
		AudioServer.set_bus_mute(bus, _bus_mute)


func _free_made() -> void:
	for node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


## path를 넣은 새 Settings를 트리에 붙인다.
func _make(path: String) -> Node:
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


func _fresh_day() -> DayState:
	var rules: EconomyRules = _d._rules(70, 60, 20, 250)
	var catalog: UpgradeCatalog = _d._catalog(_d._test_upgrades())
	return DayState.new(rules, _d._three_fixed(), catalog)


## 읽은 갈래. 없으면 빈 Dictionary.
func _section(data: Dictionary, name: String) -> Dictionary:
	var found: Variant = data.get(name)
	return found as Dictionary if found is Dictionary else {}


func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)


# ================================================================ T97

func t97_settings() -> String:
	var errs: Array[String] = []
	var bus := AudioServer.get_bus_index("Master")
	_expect(errs, bus >= 0, "Master 버스가 없음")
	if bus >= 0:
		_bus_db = AudioServer.get_bus_volume_db(bus)
		_bus_mute = AudioServer.is_bus_mute(bus)
		_bus_saved = true
	_erase_files()

	_check_defaults_and_path(errs)
	_check_write_and_read(errs)
	_check_split_from_save(errs)
	_check_survives_new_game(errs)
	_check_broken_files(errs)
	_check_unknown_kept(errs)
	_check_bus(errs, bus)
	_check_screen(errs)
	_check_title(errs)

	_free_made()
	_erase_files()
	_restore_bus()
	return _result(errs)


## 1. 처음 값과 경로.
func _check_defaults_and_path(errs: Array[String]) -> void:
	var s := _make(TEST_PATH)
	_expect(errs, s.volume == 100 and not s.muted, "[1] 파일이 없을 때 처음 값 %d·%s (기대 100·거짓)" % [s.volume, str(s.muted)])
	_expect(errs, s.path == TEST_PATH, "[1] 붙인 뒤 path가 '%s' (넣은 값이 덮어써짐)" % s.path)
	_expect(errs, not s.save() and not Store.exists(TEST_PATH), "[1] 바꾼 것이 없는데 save()가 파일을 만듦")
	# 쓰기 꺼짐: _ready 뒤에 path를 비운 인스턴스.
	var off := _make(TEST_PATH)
	off.path = ""
	off.set_volume(40)
	_expect(errs, not off.save() and not Store.exists(TEST_PATH), "[1] path가 빈 인스턴스의 save()가 참이거나 파일을 만듦")
	var autoload := _tree.root.get_node_or_null(^"Settings")
	if autoload != null:
		_expect(errs, autoload.path == "", "[1] 자동 로드 Settings의 path가 '%s' (러너가 비웠어야 함)" % autoload.path)
	_free_made()


## 2. 적고 읽기.
func _check_write_and_read(errs: Array[String]) -> void:
	var s := _make(TEST_PATH)
	s.set_volume(40)
	s.set_muted(true)
	_expect(errs, s.save(), "[2] 바꾼 뒤 save()가 거짓")
	var back := _make(TEST_PATH)
	_expect(errs, back.volume == 40 and back.muted, "[2] 읽은 값 %d·%s (기대 40·참)" % [back.volume, str(back.muted)])
	var data := Store.read(TEST_PATH)
	var audio := _section(data, "audio")
	_expect(errs, data.has("version") and int(data["version"]) == 1, "[2] 파일에 version 1이 없음")
	_expect(errs, audio.size() > 0 and int(audio.get("volume", -1)) == 40 and audio.get("muted") == true, "[2] 파일의 audio가 40·참이 아님: %s" % str(audio))
	_free_made()


## 3. 설정과 세이브의 분리.
func _check_split_from_save(errs: Array[String]) -> void:
	_expect(errs, SettingsScript.SETTINGS_PATH != Session.SAVE_PATH, "[3] 설정과 세이브의 파일 경로가 같음")
	_expect(errs, SettingsScript.SETTINGS_ENV != Session.SAVE_ENV, "[3] 설정과 세이브의 환경 변수 이름이 같음")
	var saved := _fresh_day().saved_state()
	_expect(errs, not saved.is_empty(), "[3] 새 하루의 saved_state()가 빔")
	Store.write(TEST_SAVE_PATH, saved)
	var save_before := _bytes(TEST_SAVE_PATH)
	var s := _make(TEST_PATH)
	s.set_volume(25)
	s.set_muted(false)
	s.save()
	_expect(errs, _bytes(TEST_SAVE_PATH) == save_before and not save_before.is_empty(), "[3] 설정을 적은 뒤 세이브 파일의 바이트가 달라짐")
	_expect(errs, not saved.has("audio"), "[3] 세이브의 칸에 audio가 있음")
	var settings_data := Store.read(TEST_PATH)
	for key in ["day", "money", "owned"]:
		_expect(errs, not settings_data.has(key), "[3] 설정 파일에 세이브의 칸 '%s'가 있음" % key)
	_free_made()


## 4. 새로 시작해도 남음.
func _check_survives_new_game(errs: Array[String]) -> void:
	var s := _make(TEST_PATH)
	s.set_volume(40)
	s.set_muted(true)
	s.save()
	var before := _bytes(TEST_PATH)
	Store.write(TEST_SAVE_PATH, _fresh_day().saved_state())
	Store.erase(TEST_SAVE_PATH)
	_expect(errs, _bytes(TEST_PATH) == before and not before.is_empty(), "[4] 세이브를 새로 쓰고 지운 뒤 설정 파일의 바이트가 달라짐")
	var back := _make(TEST_PATH)
	_expect(errs, back.volume == 40 and back.muted, "[4] 새로 시작한 뒤 읽은 값 %d·%s (기대 40·참)" % [back.volume, str(back.muted)])
	_free_made()


## 5. 깨진 파일.
func _check_broken_files(errs: Array[String]) -> void:
	_write_text("{not json")
	var broken := _make(TEST_PATH)
	_expect(errs, broken.volume == 100 and not broken.muted, "[5] 깨진 파일에서 %d·%s (기대 100·거짓)" % [broken.volume, str(broken.muted)])
	_write_text('{"audio": {"volume": 170, "muted": "yes"}}')
	var wild := _make(TEST_PATH)
	_expect(errs, wild.volume == 100 and not wild.muted, "[5] 범위 밖·자료형이 틀린 값에서 %d·%s (기대 100·거짓)" % [wild.volume, str(wild.muted)])
	_write_text('{"audio": {"volume": 37}}')
	var between := _make(TEST_PATH)
	_expect(errs, between.volume == 35 and not between.muted, "[5] 37에서 %d·%s (기대 35·거짓)" % [between.volume, str(between.muted)])
	_free_made()


## 6. 모르는 칸을 남기고 version을 내려 적지 않는다.
func _check_unknown_kept(errs: Array[String]) -> void:
	_write_text('{"version": 1, "audio": {"volume": 60, "muted": false}, "view": {"text_scale": 1.3}, "controls": {"attack": "x"}}')
	var s := _make(TEST_PATH)
	s.set_volume(30)
	_expect(errs, s.save(), "[6] 바꾼 뒤 save()가 거짓")
	var data := Store.read(TEST_PATH)
	var view := _section(data, "view")
	var controls := _section(data, "controls")
	_expect(errs, view.has("text_scale") and is_equal_approx(float(view["text_scale"]), 1.3), "[6] view가 그대로 남지 않음: %s" % str(view))
	_expect(errs, controls.get("attack") == "x", "[6] controls가 그대로 남지 않음: %s" % str(controls))
	_expect(errs, int(_section(data, "audio").get("volume", -1)) == 30, "[6] 바꾼 음량 30이 적히지 않음")
	_free_made()
	_write_text('{"version": 2, "audio": {"volume": 60, "muted": false}}')
	var newer := _make(TEST_PATH)
	newer.set_volume(20)
	newer.save()
	var newer_data := Store.read(TEST_PATH)
	_expect(errs, newer_data.has("version") and int(newer_data["version"]) == 2, "[6] version 2 파일이 %s로 내려 적힘" % str(newer_data.get("version")))
	_free_made()


## 7. Master 버스.
func _check_bus(errs: Array[String], bus: int) -> void:
	if bus < 0:
		return
	var s := _make(TEST_PATH)
	s.set_volume(40)
	s.set_muted(true)
	_expect(errs, absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.4)) <= 0.01, "[7] 음량 40의 버스 %.2f dB (기대 %.2f)" % [AudioServer.get_bus_volume_db(bus), linear_to_db(0.4)])
	_expect(errs, AudioServer.is_bus_mute(bus), "[7] 음소거가 버스에 걸리지 않음")
	s.set_volume(0)
	_expect(errs, AudioServer.get_bus_volume_db(bus) <= -80.0, "[7] 음량 0의 버스 %.2f dB (기대 -80 이하)" % AudioServer.get_bus_volume_db(bus))
	_free_made()
	# 시작 값: 파일의 값이 _ready에서 곧바로 걸린다(자동 로드 차례의 근거, R5).
	AudioServer.set_bus_volume_db(bus, 0.0)
	AudioServer.set_bus_mute(bus, false)
	_write_text('{"version": 1, "audio": {"volume": 40, "muted": true}}')
	_make(TEST_PATH)
	_expect(errs, absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.4)) <= 0.01 and AudioServer.is_bus_mute(bus), "[7] 붙이기만 했는데 시작 값이 버스에 걸리지 않음")
	_free_made()


## 8. 설정 화면.
func _check_screen(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	var s := _make(TEST_PATH)
	var parent := Control.new()
	_tree.root.add_child(parent)
	_made.append(parent)

	# 가. 열기만 하면 아무것도 생기지 않는다.
	var changes := [0]
	s.changed.connect(func(_section_name, _key): changes[0] += 1)
	var closed_count := [0]
	var first := SettingsScreen.open(parent, s)
	first.closed.connect(func(): closed_count[0] += 1)
	_expect(errs, first.preview_count == 0 and changes[0] == 0, "[8 가] 연 직후 preview_count %d·changed %d (기대 0·0)" % [first.preview_count, changes[0]])
	(first.find_child("SettingsClose", true, false) as Button).pressed.emit()
	_expect(errs, closed_count[0] == 1, "[8 가] 닫기에서 closed가 %d번 (기대 1)" % closed_count[0])
	_expect(errs, not Store.exists(TEST_PATH), "[8 가] 아무것도 바꾸지 않고 닫았는데 설정 파일이 생김")

	# 나. 슬라이더와 미리 듣기의 거르기.
	var screen := SettingsScreen.open(parent, s)
	var slider := screen.find_child("VolumeSlider", true, false) as HSlider
	var mute := screen.find_child("MuteButton", true, false) as Button
	var close := screen.find_child("SettingsClose", true, false) as Button
	var tab_row := screen.find_child("TabRow", true, false)
	_expect(errs, slider != null and mute != null and close != null, "[8 나] VolumeSlider·MuteButton·SettingsClose 가운데 없는 것이 있음")
	_expect(errs, tab_row != null and tab_row.get_child_count() == 1 and (tab_row.get_child(0) as Button).text == "소리", "[8 나] 탭 줄이 '소리' 하나가 아님")
	if slider == null or mute == null or close == null:
		return
	slider.value = 60
	_expect(errs, s.volume == 60 and screen.preview_count == 1, "[8 나] 60으로 옮긴 뒤 음량 %d·preview_count %d (기대 60·1)" % [s.volume, screen.preview_count])
	slider.value = 65
	_expect(errs, screen.preview_count == 1, "[8 나] 120밀리초 안의 65에서 preview_count %d (기대 1)" % screen.preview_count)
	slider.drag_ended.emit(true)
	_expect(errs, screen.preview_count == 2, "[8 나] 거른 값이 있었는데 drag_ended 뒤 preview_count %d (기대 2)" % screen.preview_count)
	_expect(errs, int(_section(Store.read(TEST_PATH), "audio").get("volume", -1)) == 65, "[8 나] drag_ended 뒤 파일에 65가 없음")
	slider.drag_ended.emit(true)
	_expect(errs, screen.preview_count == 2, "[8 나] 거른 값이 없는데 drag_ended가 소리를 냄 (%d)" % screen.preview_count)

	# 다. 음소거면 미리 듣기가 없고, 닫으면 마지막 값이 적힌다.
	mute.button_pressed = true
	slider.value = 70
	_expect(errs, screen.preview_count == 2 and s.volume == 70, "[8 다] 음소거 중 70에서 preview_count %d·음량 %d (기대 2·70)" % [screen.preview_count, s.volume])
	close.pressed.emit()
	var audio := _section(Store.read(TEST_PATH), "audio")
	_expect(errs, int(audio.get("volume", -1)) == 70 and audio.get("muted") == true, "[8 다] 닫은 뒤 파일 %s (기대 70·참)" % str(audio))


## 9. 처음 화면의 "설정".
func _check_title(errs: Array[String]) -> void:
	_free_made()
	Store.erase(TEST_PATH)
	# --script 실행에 자동 로드가 없으면 이 이름의 대역을 붙인다(처음 화면이 /root/Settings를 읽는다).
	var stand_in: Node = null
	if _tree.root.get_node_or_null(^"Settings") == null:
		stand_in = _make(TEST_PATH)
		stand_in.name = "Settings"
	for with_save in [false, true]:
		var title: Node = (load(Session.TITLE_PATH) as PackedScene).instantiate()
		if with_save:
			title.set("saved", _fresh_day())
		_tree.root.add_child(title)
		var label := "저장 있음" if with_save else "저장 없음"
		var button := title.find_child("Settings", true, false) as Button
		_expect(errs, button != null, "[9] %s: 설정 버튼이 없음" % label)
		if button == null:
			title.free()
			continue
		button.pressed.emit()
		var screen := title.find_child("SettingsScreen", true, false)
		_expect(errs, screen != null, "[9] %s: 누른 뒤 SettingsScreen이 없음" % label)
		if screen != null:
			var cancel := InputEventAction.new()
			cancel.action = &"ui_cancel"
			cancel.pressed = true
			screen._unhandled_input(cancel)
			_expect(errs, title.find_child("SettingsScreen", true, false) == null, "[9] %s: ui_cancel 뒤에도 SettingsScreen이 트리에 있음" % label)
			_expect(errs, _tree.root.gui_get_focus_owner() == button, "[9] %s: 닫은 뒤 초점이 설정 버튼에 없음" % label)
		title.free()
	if stand_in != null:
		_free_made()
