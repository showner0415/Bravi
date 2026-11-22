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
## 견본 026의 tintPts(296~302행): 이름, 종류, 파츠 경로, 파츠 단위의 점, 선이면 찾아 걷는 방향(화면 화소).
const TINT_PTS := [
	["torso-fill", "fill", ^"Torso", Vector2(-39.2, -90.8)], ["torso-shadow", "fill", ^"Torso", Vector2(49.9, -90.8)],
	["arm-fill", "fill", ^"Torso/Arm", Vector2(-7.1, 37.4)], ["arm-shadow", "fill", ^"Torso/Arm", Vector2(8.9, 37.4)],
	["legs-fill", "fill", ^"Legs", Vector2(-2.4, 18.4)], ["legs-shadow", "fill", ^"Legs", Vector2(48.1, 21.4)],
	["torso-line", "line", ^"Torso", Vector2(-80.7, -90.8), Vector2i(1, 0)],
	["legs-line", "line", ^"Legs", Vector2(-73.6, 21.4), Vector2i(1, 0)],
	["arm-line", "line", ^"Torso/Arm", Vector2(-23.6, 37.4), Vector2i(1, 0)],
	["head-skin", "same", ^"Torso/Head", Vector2(0, -78.9)], ["hat", "same", ^"Torso/Head/Hat", Vector2(0, -39)],
	["blade", "same", ^"Torso/Arm/Hand/Sword", Vector2(0, -125.8)],
]

var _shots_dir := ""
var _core: DuelCore
var _opp: OpponentData
var _weapon: WeaponData
var _atks := {}
var _shots: Array[Dictionary] = []
var _index := -1
var _wait := 0

@onready var _view: OpponentView = $OpponentView


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
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
	_shots = _plan()


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


## 41장(계획 029 작업 8의 표): 4 + 16 + 2 + 4 + 5 + 6 + 2 + 2.
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
	_view.setup(_opp, _weapon, shot["hat"])
	_view.set_target(shot["aim"])
	var t := States.put(_core, shot["state"], atk, shot["p"], shot["dist"])
	_view.update_view(_core, t, 0.0)
	match shot["fx"]:
		"dodge":
			_view.on_event(_attack_event(DT.AttackResult.WHIFF, DT.Part.HEAD, true))
			_view.update_view(_core, t, 0.15)
		"touch":
			_view.on_event(_attack_event(DT.AttackResult.GRAZE, DT.Part.LEGS, false))
			_view.update_view(_core, t, 0.01)
		"strike":
			_view.on_event({"type": DuelRecord.STRIKE, "braced": false})
			_view.update_view(_core, t, 0.05)
		"pair-off":
			_print_points(str(shot["name"]))
			# 물드는 파츠의 상태 색만 끈다: pair-on과 같은 포즈에서 칠만 다르다.
			for part in OpponentView.TINTED:
				var mat := (_view.get_node(OpponentView.PART_PATHS[part]).get_node(^"Art") as CanvasItem).material as ShaderMaterial
				mat.set_shader_parameter(&"tint_amount", 0.0)


func _attack_event(result: int, part: int, dodged: bool) -> Dictionary:
	return {"type": DuelRecord.ATTACK, "result": result, "part": part, "dodged": dodged, "rash": false, "posture_gain": 0}


func _print_points(shot_name: String) -> void:
	var to_image := get_viewport().get_final_transform()
	for pt: Array in TINT_PTS:
		var node := _view.get_node(pt[2] as NodePath) as Node2D
		var at: Vector2 = to_image * node.get_global_transform_with_canvas() * (pt[3] as Vector2)
		var line := "pt,%s,%s,%s,%d,%d" % [shot_name, pt[0], pt[1], roundi(at.x), roundi(at.y)]
		if pt.size() > 4:
			var dir: Vector2i = pt[4]
			line += ",%d,%d" % [dir.x, dir.y]
		print(line)
