extends Node
## 결투 무대의 HUD·1920 찍기(계획 031 작업 7b, 결정 300). 1일차 의뢰 셋마다 결투 씬을 붙여 간격 셋(멀리·교전·밀착)을 찍는다.
## 실행: tests/run_stage_shots.ps1 (창, -- --shots=<폴더>). 폴더가 없거나 헤드리스면 저장하지 않고 돈다.
## 장마다 "size,<장>,<w>x<h>"와 "scale,<장>,<상대 뷰의 scale.x>"를 낸다. 상대의 상태는 정하지 않는다(그것은 opponent_shots --stages).

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const DAY1_PATH := "res://data/days/day_01.tres"
const DIST_NAMES: Array[String] = ["far", "mid", "close"]
## 목표 간격에 닿은 뒤 판을 흘리는 프레임 수. 그 뒤로는 판을 멈추고 실제 시간만 기다린다:
## 간격의 크기는 결투 씬의 _process가 실제 delta로 보간하고(T1), 판 시각이 주사율에 따라 늘지 않게 한다(상대의 접근 1.5초).
const ADVANCE_FRAMES := 36
## exp(-14 x 0.5) = 0.0009: 보간이 끝난다.
const SETTLE_MSEC := 500

var _shots_dir := ""
var _commissions: Array[Commission] = []
var _duel: Node
var _ci := -1
var _di := 0
var _frames := 0
var _reached_msec := -1
var _wait := 0
var _count := 0


func _ready() -> void:
	# 결투가 InputMap을 읽으므로 플레이어의 바꾼 키가 장에 비치지 않게 처음 값으로 돌린다(계획 S03 결정 523).
	var run_settings := get_node_or_null(^"/root/Settings")
	if run_settings != null and run_settings.has_method("detach_for_run"):
		run_settings.call("detach_for_run")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	_commissions.assign((load(DAY1_PATH) as DayData).commissions)
	_next_duel()


func _next_duel() -> void:
	if _duel != null:
		_duel.free()
		_duel = null
	_ci += 1
	if _ci >= _commissions.size():
		print("STAGE SHOTS OK %d" % _count)
		set_process(false)
		get_tree().quit(0)
		return
	_duel = (load(DUEL_PATH) as PackedScene).instantiate()
	_duel.set("commission", _commissions[_ci])
	_duel.set("mouse_aim_enabled", false)
	_duel.set("rng_seed", 1)
	add_child(_duel)
	# 판은 이 씬이 advance로만 흘린다. add_child 뒤에 끈다: Godot은 _ready 직전에 물리 처리를 다시 켠다.
	_duel.set_physics_process(false)
	_di = 0
	_start_distance()


func _start_distance() -> void:
	_frames = 0
	_reached_msec = -1
	_wait = 0


func _process(_delta: float) -> void:
	if _duel == null:
		return
	var core: DuelCore = _duel.get("core")
	if _wait > 0:
		_wait -= 1
		if _wait == 0:
			_capture(core)
		return
	if core.distance < _di and not core.ended:
		# 목표 간격까지 걷는다. 걸음은 플레이어가 준비일 때만 받는다(막기·맞음 중이면 다음 프레임에).
		if core.player_state == DuelTypes.PlayerState.READY:
			core.step(1)
		_duel.call("advance", 1.0 / 60.0)
		return
	if _reached_msec < 0:
		_reached_msec = Time.get_ticks_msec()
	if _frames < ADVANCE_FRAMES:
		_duel.call("advance", 1.0 / 60.0)
		_frames += 1
		return
	if Time.get_ticks_msec() - _reached_msec >= SETTLE_MSEC:
		# 두 프레임 그린 뒤에 찍는다.
		_wait = 2


func _capture(core: DuelCore) -> void:
	var commission: Commission = _commissions[_ci]
	var place := commission.stage.resource_path.get_file().get_basename() if commission.stage != null else "none"
	var shot_name: String = "stage-%s-%s" % [place, DIST_NAMES[_di]]
	var image := get_viewport().get_texture().get_image()
	if _shots_dir != "":
		image.save_png(_shots_dir.path_join(shot_name + ".png"))
	print("size,%s,%dx%d" % [shot_name, image.get_width(), image.get_height()])
	print("scale,%s,%.4f" % [shot_name, (_duel.get_node("OpponentView") as Node2D).scale.x])
	_count += 1
	_di += 1
	if _di >= DIST_NAMES.size() or core.ended:
		_next_duel()
	else:
		_start_distance()
