extends Node
## 오토로드 Settings. 설정 파일(영업 세이브와 따로)을 읽고 쓰고, 음량을 Master 버스에 건다(계획 S01, 결정 500·501).
## GameSession은 설정을 모르고 Settings는 세이브를 모른다: 파일·환경 변수·코드가 모두 따로다.

const SaveStore := preload("res://scripts/save_store.gd")
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

## 읽은 파일 전체(모르는 갈래·칸을 지우지 않고 다시 적으려고 남긴다).
var _data: Dictionary = {}
var _dirty := false


func _ready() -> void:
	if path == "":
		var custom := OS.get_environment(SETTINGS_ENV)
		path = custom if custom != "" else SETTINGS_PATH
	_load()
	apply_audio()


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
	return out


static func _is_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT) or (typeof(value) == TYPE_FLOAT and is_finite(value))


static func _clean_volume(value: Variant) -> int:
	if not _is_number(value):
		return DEFAULT_VOLUME
	return snappedi(clampi(roundi(float(value)), 0, 100), VOLUME_STEP)


func _load() -> void:
	_data = normalize(SaveStore.read(path))
	volume = int((_data["audio"] as Dictionary)["volume"])
	muted = bool((_data["audio"] as Dictionary)["muted"])
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


## 바뀐 것이 없거나 쓰기가 꺼져 있으면(path가 빈 글) 적지 않고 false다.
func save() -> bool:
	if path == "" or not _dirty:
		return false
	var out := _data.duplicate(true)
	var audio: Dictionary = out.get("audio", {})
	audio["volume"] = volume
	audio["muted"] = muted
	out["audio"] = audio
	out["version"] = maxi(int(out.get("version", 1)), 1)
	if not SaveStore.write(path, out):
		return false
	_data = out
	_dirty = false
	return true
