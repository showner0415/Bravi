extends Node
## 오토로드 Settings. 설정 파일(영업 세이브와 따로)을 읽고 쓰고, 음량을 Master 버스에 건다(계획 S01, 결정 500·501).
## GameSession은 설정을 모르고 Settings는 세이브를 모른다: 파일·환경 변수·코드가 모두 따로다.

const SaveStore := preload("res://scripts/save_store.gd")
const Controls := preload("res://scripts/controls.gd")
const Display := preload("res://scripts/display.gd")
const SETTINGS_PATH := "user://bravi_settings.json"
const SETTINGS_ENV := "BRAVI_SETTINGS_PATH"
const VERSION := 1
const DEFAULT_VOLUME := 100
const VOLUME_STEP := 5

## 값이 바뀔 때마다. 지금 듣는 곳은 설정 화면뿐이다(S03·S04가 같은 길을 쓴다).
signal changed(section: StringName, key: StringName)

## 설정 파일의 경로. 처음엔 빈 글이고, _ready가 빈 글일 때만 채운다(밖에서 넣은 값은 그대로, 결정 500).
## _ready 뒤에 빈 글이면 save()는 적지 않는다(쓰기 꺼짐: 러너와 찍기가 이렇게 끈다).
var path := ""
var volume := DEFAULT_VOLUME
var muted := false
## 넷의 부호(결정 518). 빈 글은 없음.
var controls: Dictionary = Controls.default_codes()
## 읽을 때 못 읽는·예약된·겹친 값을 처음 값으로 고쳤다(조작 탭이 한 번 알린다).
var controls_repaired := false
## {"mode": &"windowed"|&"fullscreen", "size": Vector2i}(결정 526). size는 창으로 돌아갈 때의 크기다.
var display: Dictionary = Display.default_display()
## 읽을 때 못 읽는 화면 설정을 처음 값으로 고쳤다(화면 탭이 한 번 알린다).
var display_repaired := false
## 창이 잠긴 실행(결정 531): 테스트·찍기는 창 모드·크기를 건드리지 않는다. _ready가 설정을 읽기 전에 정한다.
var window_locked := false
## 마지막으로 건 계획과 걸어 본 횟수(테스트가 본다. 잠겨도 _apply_count는 센다).
var last_plan: Dictionary = {}
var _window_calls := 0
var _apply_count := 0
var _decor: Vector2i = Display.DECOR_FALLBACK

## 읽은 파일 전체(모르는 갈래·칸을 지우지 않고 다시 적으려고 남긴다).
var _data: Dictionary = {}
var _dirty := false
## 조작을 적을 까닭: 읽은 파일에 controls가 있었거나 이 실행에서 바꿨다(음량만 바꾼 파일에 처음 값이 박히지 않게).
var _write_controls := false
## 화면을 적을 까닭(_write_controls와 같은 까닭, 결정 526).
var _write_display := false


func _ready() -> void:
	# 러너·찍기가 detach_for_run을 부르는 때는 이 _ready 뒤라 늦다: 명령 줄로 먼저 잠근다(결정 531).
	window_locked = DisplayServer.get_name() == "headless" or _cmdline_has_tests()
	if path == "":
		var custom := OS.get_environment(SETTINGS_ENV)
		path = custom if custom != "" else SETTINGS_PATH
	_load()
	apply_audio()
	apply_controls()
	apply_display()


static func _cmdline_has_tests() -> bool:
	for arg in OS.get_cmdline_args():
		if String(arg).begins_with("res://tests/"):
			return true
	return false


## 읽은 값에서 아는 칸만 고르고 범위를 맞춘다. 모르는 갈래·칸은 그대로 남긴다. version은 읽은 값과 1 가운데 큰 쪽.
static func normalize(raw: Dictionary) -> Dictionary:
	var out := raw.duplicate(true)
	var version := 1
	var raw_version: Variant = raw.get("version")
	if _is_number(raw_version):
		version = maxi(int(raw_version), 1)
	out["version"] = version
	var audio := {}
	if raw.get("audio") is Dictionary:
		audio = (raw["audio"] as Dictionary).duplicate(true)
	audio["volume"] = _clean_volume(audio.get("volume"))
	audio["muted"] = audio.get("muted") is bool and bool(audio["muted"])
	out["audio"] = audio
	out["controls"] = clean_controls(raw.get("controls"))["codes"]
	out["display"] = clean_display(raw.get("display"))["display"]
	return out


## {"display": {"mode": 글, "width", "height"과 모르는 칸}, "repaired": 고쳤는가}. 칸이 없으면 처음 값(고친 것이 아니다).
static func clean_display(raw: Variant) -> Dictionary:
	var src: Dictionary = raw if raw is Dictionary else {}
	var repaired := raw != null and not raw is Dictionary
	var out := src.duplicate(true)
	var mode: Variant = src.get("mode")
	if mode == null:
		out["mode"] = "windowed"
	elif mode is String and Display.MODES.has(StringName(mode)):
		out["mode"] = mode
	else:
		out["mode"] = "windowed"
		repaired = true
	var width: Variant = src.get("width")
	var height: Variant = src.get("height")
	var size := Display.DEFAULT_SIZE
	if width != null or height != null:
		if _is_whole(width) and _is_whole(height) and Display.is_valid_size(Vector2i(int(width), int(height))):
			size = Vector2i(int(width), int(height))
		else:
			repaired = true
	out["width"] = size.x
	out["height"] = size.y
	return {"display": out, "repaired": repaired}


static func _is_whole(value: Variant) -> bool:
	return _is_number(value) and float(value) == floorf(float(value))


## {"codes": 넷과 모르는 칸, "repaired": 고쳤는가}. 칸이 없으면 처음 값(고친 것이 아니다), ""는 없음(유효).
## 못 읽는·예약된 값은 그 칸만, 비지 않은 값끼리 겹치면 넷 모두 처음 값(어느 쪽이 맞는지 모른다).
static func clean_controls(raw: Variant) -> Dictionary:
	var src: Dictionary = raw if raw is Dictionary else {}
	var repaired := raw != null and not raw is Dictionary
	var codes := src.duplicate(true)
	for action in Controls.ACTIONS:
		var fallback := Controls.default_code(action)
		var value: Variant = src.get(String(action))
		if value == null:
			codes[String(action)] = fallback
		elif value is String and value == "":
			codes[String(action)] = ""
		elif value is String and Controls.event_of(value) != null and Controls.reserved_use(value) == "":
			codes[String(action)] = Controls.code_of(Controls.event_of(value))
		else:
			codes[String(action)] = fallback
			repaired = true
	var seen := {}
	var overlap := false
	for action in Controls.ACTIONS:
		var code := String(codes[String(action)])
		if code != "" and seen.has(code):
			overlap = true
		seen[code] = true
	if overlap:
		for action in Controls.ACTIONS:
			codes[String(action)] = Controls.default_code(action)
		repaired = true
	return {"codes": codes, "repaired": repaired}


static func _is_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT) or (typeof(value) == TYPE_FLOAT and is_finite(value))


static func _clean_volume(value: Variant) -> int:
	if not _is_number(value):
		return DEFAULT_VOLUME
	return snappedi(clampi(roundi(float(value)), 0, 100), VOLUME_STEP)


func _load() -> void:
	var raw := SaveStore.read(path)
	_data = normalize(raw)
	volume = int((_data["audio"] as Dictionary)["volume"])
	muted = bool((_data["audio"] as Dictionary)["muted"])
	var cleaned := clean_controls(raw.get("controls"))
	controls = {}
	for action in Controls.ACTIONS:
		controls[action] = String((cleaned["codes"] as Dictionary)[String(action)])
	controls_repaired = bool(cleaned["repaired"])
	_write_controls = raw.has("controls")
	var shown := clean_display(raw.get("display"))
	var file_display: Dictionary = shown["display"]
	display = {"mode": StringName(file_display["mode"]), "size": Vector2i(int(file_display["width"]), int(file_display["height"]))}
	display_repaired = bool(shown["repaired"])
	_write_display = raw.has("display")
	_dirty = false


func set_volume(value: int) -> void:
	var clean := _clean_volume(value)
	if clean == volume:
		return
	volume = clean
	_dirty = true
	apply_audio()
	changed.emit(&"audio", &"volume")


func set_muted(value: bool) -> void:
	if value == muted:
		return
	muted = value
	_dirty = true
	apply_audio()
	changed.emit(&"audio", &"muted")


## Master 버스에 건다(결정 501). 곡선은 진폭 그대로(50 = -6 dB).
func apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, -80.0 if volume <= 0 else linear_to_db(volume / 100.0))
	AudioServer.set_bus_mute(bus, muted)


func apply_controls(changed: Array = Controls.ACTIONS) -> void:
	Controls.apply_codes(controls, changed)


## 결과 {"result", "other", "use"}. other는 비운 동작, use는 예약된 쓰임의 이름(결정 518·519).
func set_control(action: StringName, code: String) -> Dictionary:
	var out := {"result": &"invalid", "other": &"", "use": ""}
	if not Controls.ACTIONS.has(action) or code == "" or Controls.event_of(code) == null:
		return out
	var use := Controls.reserved_use(code)
	if use != "":
		out["result"] = &"reserved"
		out["use"] = use
		return out
	if controls[action] == code:
		out["result"] = &"same"
		return out
	var touched: Array = [action]
	out["result"] = &"bound"
	for other in Controls.ACTIONS:
		if other != action and controls[other] == code:
			controls[other] = ""
			touched.append(other)
			out["other"] = other
			out["result"] = &"cleared"
	controls[action] = code
	_after_controls_change(touched)
	return out


## 빈 동작까지 처음 값으로. 이미 모두 처음 값이면 거짓이고 아무것도 안 한다.
func reset_controls() -> bool:
	var touched: Array = []
	for action in Controls.ACTIONS:
		var code := Controls.default_code(action)
		if controls[action] != code:
			controls[action] = code
			touched.append(action)
	if touched.is_empty():
		return false
	_after_controls_change(touched)
	return true


func _after_controls_change(touched: Array) -> void:
	_dirty = true
	_write_controls = true
	apply_controls(touched)
	for action in touched:
		changed.emit(&"controls", action)


## 모드가 바뀌면 크기가 같아도 바뀐 것이다(전체 화면에서 눌린 크기 버튼은 그 크기의 창으로 돌아온다). 모드·크기가 모두 같으면
## 창에만 다시 걸고(끌거나 최대화한 창을 되돌린다) 거짓이다: 파일·changed·_dirty는 그대로(결정 526).
func set_window_size(size: Vector2i) -> bool:
	if not Display.is_valid_size(size):
		return false
	var touched: Array = []
	if display["mode"] != &"windowed":
		touched.append(&"mode")
	if size != display["size"]:
		touched.append(&"size")
	if touched.is_empty():
		apply_display()
		return false
	display["mode"] = &"windowed"
	display["size"] = size
	_after_display_change(touched)
	return true


func set_display_mode(mode: StringName) -> bool:
	if not Display.MODES.has(mode):
		return false
	if mode == display["mode"]:
		apply_display()
		return false
	display["mode"] = mode
	_after_display_change([&"mode"])
	return true


func toggle_fullscreen() -> void:
	set_display_mode(&"windowed" if display["mode"] == &"fullscreen" else &"fullscreen")


func _after_display_change(touched: Array) -> void:
	_dirty = true
	_write_display = true
	apply_display()
	for key in touched:
		changed.emit(&"display", key)


## 창이 잠긴 실행에서는 본보기 모니터(결정 525)를 쓴다: 찍기의 장이 verifier의 모니터에 따라 달라지지 않게.
func available_sizes() -> Array:
	var monitor := _monitor()
	return Display.sizes_for(monitor["usable"], monitor["decor"])


func _monitor() -> Dictionary:
	if window_locked:
		return {"usable": Display.LOCKED_USABLE, "decor": Display.LOCKED_DECOR}
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		var measured := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
		if measured.x >= 0 and measured.y > 0:
			_decor = measured
	var screen := DisplayServer.window_get_current_screen()
	return {"usable": DisplayServer.screen_get_usable_rect(screen).size, "decor": _decor}


## 곧바로 건다(되돌림 타이머 없음, 결정 527). 새 코드에 _notification을 두지 않는다(S02의 교훈).
func apply_display() -> void:
	_apply_count += 1
	var monitor := _monitor()
	last_plan = Display.plan(display, monitor["usable"], monitor["decor"])
	if window_locked:
		return
	_window_calls += 1
	_apply_plan_to_window(last_plan)


## 자동 확인이 닿지 않는 유일한 곳이다. MODE_FULLSCREEN을 쓴 까닭과 대안은 결정 527.
func _apply_plan_to_window(plan: Dictionary) -> void:
	var window := get_window()
	window.min_size = Display.MIN_SIZE
	if plan["mode"] == &"fullscreen":
		window.mode = Window.MODE_FULLSCREEN
		return
	window.mode = Window.MODE_WINDOWED
	window.size = plan["size"]
	window.move_to_center()
	# 모드를 바꾼 같은 프레임에 크기가 먹지 않을 때를 위해 다음 프레임에 한 번 더(R5).
	call_deferred("_refit_window")


func _refit_window() -> void:
	var window := get_window()
	if window.mode == Window.MODE_WINDOWED and last_plan.get("mode") == &"windowed":
		window.size = last_plan["size"]
		window.move_to_center()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_fullscreen"):
		toggle_fullscreen()
		save()
		get_viewport().set_input_as_handled()


## 러너·찍기·스모크가 쓴다(결정 523·531): 쓰기를 끄고 조작·화면을 처음 값으로. 플레이어의 파일이 테스트의 키·창을 바꾸지 않게.
## _window_calls·_apply_count는 건드리지 않는다(되돌리면 확인 줄이 실패할 수 없게 된다).
func detach_for_run() -> void:
	path = ""
	controls = Controls.default_codes()
	controls_repaired = false
	apply_controls()
	window_locked = true
	display = Display.default_display()
	display_repaired = false
	last_plan = Display.plan(display, Display.LOCKED_USABLE, Display.LOCKED_DECOR)


## 바뀐 것이 없거나 쓰기가 꺼져 있으면(path가 빈 글) 적지 않고 false다.
func save() -> bool:
	if path == "" or not _dirty:
		return false
	var out := _data.duplicate(true)
	var audio: Dictionary = out.get("audio", {})
	audio["volume"] = volume
	audio["muted"] = muted
	out["audio"] = audio
	if _write_controls:
		var saved: Dictionary = out.get("controls", {})
		for action in Controls.ACTIONS:
			saved[String(action)] = controls[action]
		out["controls"] = saved
	else:
		out.erase("controls")
	if _write_display:
		var shown: Dictionary = out.get("display", {})
		shown["mode"] = String(display["mode"])
		shown["width"] = (display["size"] as Vector2i).x
		shown["height"] = (display["size"] as Vector2i).y
		out["display"] = shown
	else:
		out.erase("display")
	out["version"] = maxi(int(out.get("version", 1)), 1)
	if not SaveStore.write(path, out):
		return false
	_data = out
	_dirty = false
	return true
