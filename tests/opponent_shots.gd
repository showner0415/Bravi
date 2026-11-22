extends Node2D
## 상대 그림 찍기(계획 029 작업 8, 결정 264). 상대 뷰만 띄우고 상태를 정해 장마다 PNG를 저장한다.
## 실행: tests/run_opponent_shots.ps1 (창으로 띄우고 -- --shots=<폴더>). 폴더가 없거나 헤드리스면 저장하지 않고 돌기만 한다.
## 재는 점은 "pt,<장 이름>,<점 이름>,<종류>,<x>,<y>[,<dx>,<dy>]"로 낸다. 앞머리 "pt,<장 이름>,"을 떼면
## tintpair.ps1 -Pts의 한 줄이다(x·y는 정수여야 한다. 계획 029 T2).

const States := preload("res://tests/opponent_states.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const S := DT.OpponentState
const D := DT.Distance

## duel_scene.gd의 anchor와 같다(화면 0.5·0.62).
const ANCHOR := Vector2(640, 446.4)
const ATTACK_KEYS: Array[String] = ["thrust", "cutl", "cutr", "big"]
## 상태 색을 재는 점: 이름, 종류, 파츠 경로, 파츠 단위의 점, 선이면 찾아 걷는 방향(화면 화소).
## 이름은 견본 026의 tintPts 그대로, 값은 교전 크기에서 다시 골랐다(결정 271: 점의 3x3 상자가 덮는 반지름 안에
## 선과 투명이 없고, 선 점은 양쪽이 같은 파츠의 칠인 4화소 이상의 띠. 029의 torso-shadow·arm-line OFF).
const TINT_PTS := [
	["torso-fill", "fill", ^"Torso", Vector2(-39.2, -90.8)], ["torso-shadow", "fill", ^"Torso", Vector2(52.2, -93.2)],
	["arm-fill", "fill", ^"Torso/Arm", Vector2(-7.1, 37.3)], ["arm-shadow", "fill", ^"Torso/Arm", Vector2(8.9, 37.3)],
	["legs-fill", "fill", ^"Legs", Vector2(-2.4, 18.4)], ["legs-shadow", "fill", ^"Legs", Vector2(48.1, 21.4)],
	["torso-line", "line", ^"Torso", Vector2(-30.9, -41.0), Vector2i(1, 0)],
	["legs-line", "line", ^"Legs", Vector2(-26.7, 42.1), Vector2i(1, 0)],
	["arm-line", "line", ^"Torso/Arm", Vector2(-10.7, 95.9), Vector2i(1, 0)],
	["head-skin", "same", ^"Torso/Head", Vector2(0.3, -78.9)], ["hat", "same", ^"Torso/Head/Hat", Vector2(0, -39.1)],
	["blade", "same", ^"Torso/Arm/Hand/Sword", Vector2(0, -125.8)],
]
## 따로 그린 팔의 짝(계획 030, 점은 030c의 새 그림에서 다시 골랐다). 든 팔의 소매 안쪽 선은 교전에서 4화소 띠가 되는 선이 없어 내지 않는다.
## 030c의 뻗은 팔 칼날은 짧은 끝만 보여 반지름 안이 칼날의 칠뿐인 점이 없어 내지 않는다(날밑 점이 칼 색을 본다).
const PAIR_UP_PTS := [
	["up-sleeve-fill", "fill", ^"Torso/Arm/armUp", Vector2(-5.4, -26.3)],
	["up-fist-fill", "fill", ^"Torso/Arm/armUp", Vector2(-6.3, -100.6)],
	["up-sword", "same", ^"Torso/Arm/armUp", Vector2(0.0, -193.7)],
]
const PAIR_THRUST_PTS := [
	["thrust-sleeve-fill", "fill", ^"Torso/Arm/armThrust", Vector2(-8.2, -1.6)],
	["thrust-fist-fill", "fill", ^"Torso/Arm/armThrust", Vector2(-6.0, 37.7)],
	["thrust-guard", "same", ^"Torso/Arm/armThrust", Vector2(-11.4, 100.3)],
	["thrust-sleeve-line", "line", ^"Torso/Arm/armThrust", Vector2(-14.2, -1.9), Vector2i(1, 0)],
]
const SIL_SHADER := preload("res://tests/silhouette.gdshader")

var _shots_dir := ""
var _core: DuelCore
var _opp: OpponentData
var _weapon: WeaponData
var _atks := {}
var _shots: Array[Dictionary] = []
var _index := -1
var _wait := 0
## --sil: 실루엣 28장(결정 270). 아니면 색 57장.
var _sil := false

@onready var _view: OpponentView = $OpponentView


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
		elif arg == "--sil":
			_sil = true
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
		_wait = 30
	else:
		_shots_dir = ""
	_opp = load(States.OPPONENT_PATH)
	_weapon = load(States.WEAPON_PATH)
	_core = States.make_core(false)
	for atk in _opp.attacks:
		_atks[_key_of(atk)] = atk
	for habit in _opp.habits:
		if habit.response != null:
			_atks[_key_of(habit.response)] = habit.response
	_view.anchor = ANCHOR
	if _sil:
		($Back as ColorRect).color = Color.WHITE
		_shots = _sil_plan()
	else:
		_shots = _plan()
		_shots.append_array(_plan_arms())


func _key_of(atk: AttackData) -> String:
	if atk.is_big:
		return "big"
	match atk.direction:
		DT.Direction.CENTER:
			return "thrust"
		DT.Direction.LEFT:
			return "cutl"
	return "cutr"


func _shot(shot_name: String, state: int, atk := "", p := 0.0, dist: int = DT.Distance.ENGAGE, hat := false,
		fx := "", aim := -1) -> Dictionary:
	return {"name": shot_name, "state": state, "atk": atk, "p": p, "dist": dist, "hat": hat, "fx": fx, "aim": aim}


## 029의 41장(작업 8의 표): 4 + 16 + 2 + 4 + 5 + 6 + 2 + 2. 이름 그대로 두어 029와 견준다.
func _plan() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		_shot("idle-far", S.IDLE, "", 0.0, D.FAR), _shot("idle-mid", S.IDLE),
		_shot("idle-close", S.IDLE, "", 0.0, D.CLOSE), _shot("idle-mid-hat", S.IDLE, "", 0.0, D.ENGAGE, true),
	]
	for key in ATTACK_KEYS:
		var hold := OpponentMotion.hold_end((_atks[key] as AttackData).tell_time, _weapon.parry_window, _opp)
		out.append(_shot(key + "-tell25", S.TELL, key, 0.25))
		out.append(_shot(key + "-tell60", S.TELL, key, 0.6))
		out.append(_shot(key + "-hold", S.TELL, key, hold))
		out.append(_shot(key + "-strike", S.TELL, key, 0.9999))
	out.append(_shot("big-tell25-close", S.TELL, "big", 0.25, D.CLOSE))
	out.append(_shot("thrust-tell25-close", S.TELL, "thrust", 0.25, D.CLOSE))
	# 상대는 멀리에서 예비 동작을 시작하지 않는다(duel_core.gd 327~330행): 예비 동작 중에 물러났을 때의 모습이다.
	for key in ATTACK_KEYS:
		var hold := OpponentMotion.hold_end((_atks[key] as AttackData).tell_time, _weapon.parry_window, _opp)
		out.append(_shot(key + "-hold-far", S.TELL, key, hold, D.FAR))
	out.append(_shot("cutl-recover", S.RECOVERY, "cutl", 0.5))
	out.append(_shot("big-recover", S.RECOVERY, "big", 0.5))
	out.append(_shot("stagger", S.STAGGER))
	out.append(_shot("complacent", States.COMPLACENT))
	out.append(_shot("dodge", S.RECOVERY, "cutl", 0.3, D.ENGAGE, false, "dodge"))
	var aims := {"head": DT.Part.HEAD, "hat": DT.Part.HAT, "torso": DT.Part.TORSO, "arm": DT.Part.SWORD_ARM,
			"hand": DT.Part.SWORD_HAND, "legs": DT.Part.LEGS}
	for key: String in aims:
		out.append(_shot("aim-" + key, S.IDLE, "", 0.0, D.ENGAGE, true, "", aims[key]))
	out.append(_shot("touch-legs", S.IDLE, "", 0.0, D.ENGAGE, false, "touch"))
	out.append(_shot("strike-flash", S.RECOVERY, "cutl", 0.0, D.ENGAGE, false, "strike"))
	out.append(_shot("pair-off", S.RECOVERY, "cutl", 0.5, D.ENGAGE, true, "pair-off"))
	out.append(_shot("pair-on", S.RECOVERY, "cutl", 0.5, D.ENGAGE, true))
	return out


## 앞 상태를 그린 뒤 대기로 넘겨 after초 뒤를 찍는다(결정 268의 돌아감).
func _ret(shot_name: String, state: int, atk: String, p: float, after: float) -> Dictionary:
	var shot := _shot(shot_name, state, atk, p)
	shot["after"] = after
	return shot


## 계획 030의 16장(작업 7의 표): 따로 그린 팔, 막힌 찌르기(D2), 손의 윤곽선, 짝.
func _plan_arms() -> Array[Dictionary]:
	var big_hold := OpponentMotion.hold_end((_atks["big"] as AttackData).tell_time, _weapon.parry_window, _opp)
	var settle := _opp.return_time + 0.05
	var out: Array[Dictionary] = [
		_shot("big-swing", S.TELL, "big", big_hold + (1.0 - big_hold) * 0.5),
		_shot("thrust-recover", S.RECOVERY, "thrust", 0.5),
		_ret("thrust-return", S.RECOVERY, "thrust", 0.99, 0.1),
		_ret("thrust-return-end", S.RECOVERY, "thrust", 0.99, settle),
		_ret("thrust-blocked-005", S.TELL, "thrust", 0.9999, 0.05),
		_ret("thrust-blocked-015", S.TELL, "thrust", 0.9999, 0.15),
		_ret("thrust-blocked-end", S.TELL, "thrust", 0.9999, settle),
		_shot("aim-hand-up", S.TELL, "big", big_hold, D.ENGAGE, false, "", DT.Part.SWORD_HAND),
		_shot("aim-arm-up", S.TELL, "big", big_hold, D.ENGAGE, false, "", DT.Part.SWORD_ARM),
		_shot("aim-hand-thrust", S.RECOVERY, "thrust", 0.5, D.ENGAGE, false, "", DT.Part.SWORD_HAND),
		_shot("aim-arm-thrust", S.RECOVERY, "thrust", 0.5, D.ENGAGE, false, "", DT.Part.SWORD_ARM),
		_shot("touch-hand-thrust", S.RECOVERY, "thrust", 0.5, D.ENGAGE, false, "touch-hand"),
		_shot("pair-up-off", S.TELL, "big", big_hold, D.ENGAGE, false, "pair-up-off"),
		_shot("pair-up-on", S.TELL, "big", big_hold, D.ENGAGE, false, "pair"),
		_shot("pair-thrust-off", S.RECOVERY, "thrust", 0.5, D.ENGAGE, false, "pair-thrust-off"),
		_shot("pair-thrust-on", S.RECOVERY, "thrust", 0.5, D.ENGAGE, false, "pair"),
	]
	return out


## 실루엣 28장: 견본 r026.ps1 15~20행과 같은 진행·간격(공격 넷 x 여섯) + 대기 둘, 방심, 팔 없음.
func _sil_plan() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key in ATTACK_KEYS:
		for p in [["25", 0.25], ["60", 0.6]]:
			for d in [["mid", D.ENGAGE], ["far", D.FAR]]:
				out.append(_shot("sil-%s-tell%s-%s" % [key, p[0], d[0]], S.TELL, key, p[1], d[1]))
		out.append(_shot("sil-%s-recover-mid" % key, S.RECOVERY, key, 0.5))
		out.append(_shot("sil-%s-tell25-close" % key, S.TELL, key, 0.25, D.CLOSE))
	out.append(_shot("sil-idle-mid", S.IDLE))
	out.append(_shot("sil-idle-far", S.IDLE, "", 0.0, D.FAR))
	out.append(_shot("sil-complacent-mid", States.COMPLACENT))
	out.append(_shot("sil-idle-mid-noarm", S.IDLE, "", 0.0, D.ENGAGE, false, "noarm"))
	return out


func _process(_delta: float) -> void:
	if _wait > 0:
		_wait -= 1
		return
	if _index >= 0 and _shots_dir != "":
		var image := get_viewport().get_texture().get_image()
		image.save_png(_shots_dir.path_join(str(_shots[_index]["name"]) + ".png"))
	_index += 1
	if _index >= _shots.size():
		set_process(false)
		print("OPPONENT SHOTS OK %d" % _shots.size())
		get_tree().quit(0)
		return
	_put(_shots[_index])
	# 두 프레임 그린 뒤에 찍는다.
	_wait = 2 if _shots_dir != "" else 0


## 장마다 setup으로 간격의 보간을 건너뛰고(결정 264), 간격 → 상태 → update_view의 차례로 정한다.
func _put(shot: Dictionary) -> void:
	var atk: AttackData = _atks.get(shot["atk"]) if shot["atk"] != "" else null
	var fx: String = shot["fx"]
	_view.setup(_opp, _weapon, shot["hat"])
	_view.set_target(shot["aim"])
	var t := States.put(_core, shot["state"], atk, shot["p"], shot["dist"])
	_view.update_view(_core, t, 0.0)
	if shot.has("after"):
		var start := _core.brain.state_end
		t = States.to_idle(_core, start, start + float(shot["after"]))
		_view.update_view(_core, t, 0.0)
	match fx:
		"dodge":
			_view.on_event(_attack_event(DT.AttackResult.WHIFF, DT.Part.HEAD, true))
			_view.update_view(_core, t, 0.15)
		"touch", "touch-hand":
			var part := DT.Part.SWORD_HAND if fx == "touch-hand" else DT.Part.LEGS
			_view.on_event(_attack_event(DT.AttackResult.GRAZE, part, false))
			_view.update_view(_core, t, 0.01)
		"strike":
			_view.on_event({"type": DuelRecord.STRIKE, "braced": false})
			_view.update_view(_core, t, 0.05)
	# 짝 장은 off·on 모두 고리와 상태 글자를 감춘다: 큰 베기의 고리가 가슴께에 반투명하게 깔린다(T3).
	var pair := fx.begins_with("pair") or str(shot["name"]).begins_with("pair")
	(_view.get_node(^"Ring") as CanvasItem).visible = not pair and not _sil
	(_view.get_node(^"StateLabel") as CanvasItem).visible = not pair and not _sil
	if fx.ends_with("-off"):
		var pts: Array = TINT_PTS if fx == "pair-off" else (PAIR_UP_PTS if fx == "pair-up-off" else PAIR_THRUST_PTS)
		_print_points(str(shot["name"]), pts)
		_zero_tints()
	if _sil:
		_silhouette(fx == "noarm")


# 물드는 부위의 상태 색만 끈다(따로 그린 팔의 층 포함): on 장과 같은 포즈에서 칠만 다르다.
func _zero_tints() -> void:
	var extra: Dictionary = _view.get("_part_extra")
	for part in OpponentView.TINTED:
		var mat := (_view.get_node(OpponentView.PART_PATHS[part]).get_node(^"Art") as CanvasItem).material as ShaderMaterial
		mat.set_shader_parameter(&"tint_amount", 0.0)
		for m in extra.get(part, []):
			(m as ShaderMaterial).set_shader_parameter(&"tint_amount", 0.0)


# 견본 silArt의 갈래: 칼 팔 묶음 전부 파랑, 머리 빨강, 몸통·다리 회색. 모자·윤곽선은 감춘다.
func _silhouette(noarm: bool) -> void:
	_view.get_node(^"Torso/Head/Hat").set("visible", false)
	(_view.get_node(^"Torso/Arm") as CanvasItem).visible = not noarm
	for sprite in _view.find_children("*", "Sprite2D", true, false):
		var color := Color(0.502, 0.502, 0.502)
		var path := str(_view.get_path_to(sprite))
		if path.begins_with("Torso/Arm"):
			color = Color(0, 0, 1)
		elif path == "Torso/Head/Art":
			color = Color(1, 0, 0)
		var mat := ShaderMaterial.new()
		mat.shader = SIL_SHADER
		mat.set_shader_parameter(&"sil_color", color)
		(sprite as Sprite2D).material = mat
	for line in _view.find_children("*", "Line2D", true, false):
		(line as Line2D).visible = false



func _attack_event(result: int, part: int, dodged: bool) -> Dictionary:
	return {"type": DuelRecord.ATTACK, "result": result, "part": part, "dodged": dodged, "rash": false, "posture_gain": 0}


func _print_points(shot_name: String, pts: Array) -> void:
	var to_image := get_viewport().get_final_transform()
	for pt: Array in pts:
		var node := _view.get_node(pt[2] as NodePath) as Node2D
		var at: Vector2 = to_image * node.get_global_transform_with_canvas() * (pt[3] as Vector2)
		var line := "pt,%s,%s,%s,%d,%d" % [shot_name, pt[0], pt[1], roundi(at.x), roundi(at.y)]
		if pt.size() > 4:
			var dir: Vector2i = pt[4]
			line += ",%d,%d" % [dir.x, dir.y]
		print(line)
