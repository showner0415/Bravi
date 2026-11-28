extends Node
## 의뢰인 열의 카운터 찍기(계획 034 결정 355, 계획 054가 셋을 더했다). 의뢰마다 카운터 한 장, 미끄러짐이 끝난 뒤에 찍는다.
## 실행: tests/run_client_shots.ps1 (창, -- --shots=<폴더>). 폴더가 없거나 헤드리스면 저장하지 않고 돈다.
## 장마다 "size,<장>,<w>x<h>"와 "portrait,<장>,<x>,<y>,<w>,<h>"(Portrait의 1280×720 기준 화면 상자, 없으면 내지 않는다)를 낸다.

const Session := preload("res://scripts/game_session.gd")

## 장 이름 -> 의뢰 파일. 판 X1과 같은 차례다.
const SHOTS := [
	["counter-clara", "res://data/commissions/feather_cut.tres"],
	["counter-vittorio", "res://data/commissions/variants/first_blood_usurer.tres"],
	["counter-emilio", "res://data/commissions/first_blood.tres"],
	["counter-ines", "res://data/commissions/throw_match.tres"],
	["counter-gasparo", "res://data/commissions/variants/throw_bet.tres"],
	["counter-orsola", "res://data/commissions/variants/legs_only.tres"],
	["counter-tomaso", "res://data/commissions/variants/first_blood_poor.tres"],
	["counter-cecilia", "res://data/commissions/variants/court_beehive.tres"],
	["counter-leandro", "res://data/commissions/variants/noble_baker.tres"],
	["counter-nella", "res://data/commissions/variants/washer_ledger.tres"],
]
## 미끄러짐(0.45초)이 끝나고 한참 뒤에 찍는다.
const SETTLE_MSEC := 900

var _shots_dir := ""
var _i := -1
var _node: Node
var _since := 0
var _frames := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	_next()


func _next() -> void:
	if _node != null:
		_node.free()
		_node = null
	_i += 1
	if _i >= SHOTS.size():
		print("CLIENT SHOTS OK %d" % SHOTS.size())
		set_process(false)
		get_tree().quit(0)
		return
	var data := DayData.new()
	var commissions: Array[Commission] = [load(String(SHOTS[_i][1])) as Commission]
	data.commissions = commissions
	var day := DayState.new(load(Session.ECONOMY_PATH), data, load(Session.CATALOG_PATH), null, load(Session.REPUTATION_PATH))
	_node = (load(Session.COUNTER_PATH) as PackedScene).instantiate()
	_node.set("day", day)
	add_child(_node)
	_since = Time.get_ticks_msec()
	_frames = 0


func _process(_delta: float) -> void:
	if _node == null:
		return
	_frames += 1
	if _frames < 3 or Time.get_ticks_msec() - _since < SETTLE_MSEC:
		return
	var shot := String(SHOTS[_i][0])
	var image := get_viewport().get_texture().get_image()
	if _shots_dir != "":
		image.save_png(_shots_dir.path_join(shot + ".png"))
	print("size,%s,%dx%d" % [shot, image.get_width(), image.get_height()])
	var portrait := _node.get_node_or_null("Client/Portrait") as Control
	if portrait != null:
		var box := portrait.get_global_rect()
		print("portrait,%s,%d,%d,%d,%d" % [shot, roundi(box.position.x), roundi(box.position.y), roundi(box.size.x), roundi(box.size.y)])
	_next()
