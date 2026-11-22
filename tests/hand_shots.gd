extends Node
## 내 손 그림 찍기(계획 032 작업 9). 클라라의 의뢰로 결투 씬을 붙이고, 판을 멈춘 채 내 칼의 상태를 손으로 놓아 열다섯 장을 찍는다.
## 실행: tests/run_hand_shots.ps1 (창, -- --shots=<폴더>). 폴더가 없거나 헤드리스면 저장하지 않고 돈다.
## 장마다 "hand,<장>,<x0>,<y0>,<x1>,<y1>"(HandArt의 화면 상자)과 "bind,<장>,<true|false>"를 낸다.

const DT := preload("res://scripts/duel/duel_types.gd")
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const COMMISSION_PATH := "res://data/commissions/feather_cut.tres"
const DIR_NAMES: Array[String] = ["left", "centre", "right"]
const HEIGHT_NAMES: Array[String] = ["high", "mid", "low"]

var _shots_dir := ""
var _duel: Node
## [장 이름, 상태, 방향, 높이, 표시 시각, 갓 올린 막기, 엉킴 경고]
var _plan: Array = []
var _i := -1
var _wait := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	for d in 3:
		for h in 3:
			_plan.append(["ready-%s-%s" % [DIR_NAMES[d], HEIGHT_NAMES[h]], DT.PlayerState.READY, d, h, 1.0, false, false])
	_plan.append(["guard-fresh-centre", DT.PlayerState.GUARD, DT.Direction.CENTER, DT.Height.MID, 1.0, true, false])
	_plan.append(["guard-left", DT.PlayerState.GUARD, DT.Direction.LEFT, DT.Height.MID, 1.0, false, false])
	for d in 3:
		_plan.append(["windup-end-high-%s" % DIR_NAMES[d], DT.PlayerState.WINDUP, d, DT.Height.HIGH, 1.0, false, false])
	_plan.append(["bind-warning-centre-guard", DT.PlayerState.GUARD, DT.Direction.CENTER, DT.Height.MID, 1.0, false, true])
	_duel = (load(DUEL_PATH) as PackedScene).instantiate()
	_duel.set("commission", load(COMMISSION_PATH))
	_duel.set("mouse_aim_enabled", false)
	_duel.set("rng_seed", 1)
	add_child(_duel)
	# 판과 표시를 이 씬이 놓은 값으로 묶는다. add_child 뒤에 끈다: Godot은 _ready 직전에 처리를 다시 켠다(계획 032 기술 검토 T1).
	_duel.set_process(false)
	_duel.set_physics_process(false)
	_next()


func _next() -> void:
	_i += 1
	if _i >= _plan.size():
		print("HAND SHOTS OK %d" % _plan.size())
		set_process(false)
		get_tree().quit(0)
		return
	var p: Array = _plan[_i]
	var core: DuelCore = _duel.get("core")
	core.player_state = p[1]
	core.player_state_start = 0.0
	core.player_state_end = 1.0
	core.aim_direction = p[2]
	core.aim_height = p[3]
	core.attack_direction = p[2]
	core.attack_height = p[3]
	core.guard_fresh = p[5]
	core.guard_enter_time = p[4] if p[5] else -INF
	var view := _duel.get_node("PlayerSwordView") as PlayerSwordView
	view.setup()
	view.update_view(core, p[4], _duel.get_viewport_rect().size, 1.0)
	if p[6]:
		# 엉킴 값은 코어 밖에서 놓지 않는다. 경고가 켜지는 길은 bind_tests가 본다.
		var warning := view.get_node("Sword/BindWarning") as Line2D
		warning.visible = true
		warning.default_color.a = 1.0
	_wait = 2


func _process(_delta: float) -> void:
	if _wait <= 0:
		return
	_wait -= 1
	if _wait == 0:
		_capture()


func _capture() -> void:
	var p: Array = _plan[_i]
	var view := _duel.get_node("PlayerSwordView") as PlayerSwordView
	var art := view.get_node("HandArt") as Sprite2D
	var size := art.texture.get_size()
	var xf := art.get_global_transform()
	var box := Rect2(xf * art.offset, Vector2.ZERO)
	for c: Vector2 in [Vector2(size.x, 0), Vector2(0, size.y), size]:
		box = box.expand(xf * (art.offset + c))
	if _shots_dir != "":
		get_viewport().get_texture().get_image().save_png(_shots_dir.path_join(String(p[0]) + ".png"))
	print("hand,%s,%d,%d,%d,%d" % [p[0], box.position.x, box.position.y, box.end.x, box.end.y])
	print("bind,%s,%s" % [p[0], str((view.get_node("Sword/BindWarning") as CanvasItem).visible)])
	_next()
