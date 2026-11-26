extends Node
## 오토로드 Settings. 설정 파일(영업 세이브와 따로)을 읽고 쓰고, 음량을 Master 버스에 건다(계획 S01, 결정 500·501).
## GameSession은 설정을 모르고 Settings는 세이브를 모른다: 파일·환경 변수·코드가 모두 따로다.

const SaveStore := preload("res://scripts/save_store.gd")
const Controls := preload("res://scripts/controls.gd")
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

## 읽은 파일 전체(모르는 갈래·칸을 지우지 않고 다시 적으려고 남긴다).
var _data: Dictionary = {}
var _dirty := false
## 조작을 적을 까닭: 읽은 파일에 controls가 있었거나 이 실행에서 바꿨다(음량만 바꾼 파일에 처음 값이 박히지 않게).
var _write_controls := false


func _ready() -> void:
	if path == "":
		var custom := OS.get_environment(SETTINGS_ENV)
		path = custom if custom != "" else SETTINGS_PATH
	_load()
	apply_audio()
	apply_controls()


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
	return out


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


## 러너·찍기·스모크가 쓴다(결정 523): 쓰기를 끄고 조작을 처음 값으로. 플레이어의 파일이 테스트의 키를 바꾸지 않게.
func detach_for_run() -> void:
	path = ""
	controls = Controls.default_codes()
	controls_repaired = false
	apply_controls()


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
	out["version"] = maxi(int(out.get("version", 1)), 1)
	if not SaveStore.write(path, out):
		return false
	_data = out
	_dirty = false
	return true
