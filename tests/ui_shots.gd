extends Node
## 필사본 UI 찍기(계획 033 작업 7). 견본 025와 짝이 되는 장(pair-*) 다섯을 먼저, 견본이 없는 장을 뒤에 찍는다.
## 실행: tests/run_ui_shots.ps1 (창, -- --shots=<폴더>). 폴더가 없거나 헤드리스면 저장하지 않고 돈다.
## 장마다 "state,<장>,<놓은 것>"과 "size,<장>,<w>x<h>"를 낸다. 화면은 이 씬 아래에 붙으므로 저장하지도 씬을 바꾸지도 않는다.

const DT := preload("res://scripts/duel/duel_types.gd")
const Day := preload("res://tests/day_tests.gd")
const States := preload("res://tests/opponent_states.gd")
const Session := preload("res://scripts/game_session.gd")

const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const USURER_PATH := "res://data/commissions/variants/first_blood_usurer.tres"
const POOR_PATH := "res://data/commissions/variants/first_blood_poor.tres"
## 카운터의 의뢰인이 미끄러져 들어오는 시간(0.45초)과 간격의 보간이 끝날 때까지 기다린다.
const SETTLE_MSEC := 900

var _shots_dir := ""
var _d := Day.new()
var _plan: Array = []
var _i := -1
var _node: Node
var _since := 0
var _frames := 0
## 견본의 정산·카운터 장면을 잇는 하루(클라라 100점 → 비토리오)와 폐점까지 가는 하루.
var _pair_day: DayState
var _closing_day: DayState


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	_d.set("_tree", get_tree())
	_plan = [
		["pair-duel", _pair_duel], ["pair-duel-warn", _pair_duel_warn], ["pair-settle", _pair_settle],
		["pair-counter", _pair_counter], ["pair-closing", _pair_closing],
		["title", _title], ["title-save", _title_save], ["help", _help], ["select", _select],
		["settle-hurt", _settle_hurt], ["duel-far", _duel_far], ["duel-close", _duel_close],
		["duel-close-bighold", _duel_close_bighold], ["duel-right-high", _duel_right_high], ["result", _result],
	]
	_next()


func _next() -> void:
	if _node != null:
		_node.free()
		_node = null
	_i += 1
	if _i >= _plan.size():
		print("UI SHOTS OK %d" % _plan.size())
		set_process(false)
		get_tree().quit(0)
		return
	var note: String = (_plan[_i][1] as Callable).call()
	print("state,%s,%s" % [_plan[_i][0], note])
	_since = Time.get_ticks_msec()
	_frames = 0


func _process(_delta: float) -> void:
	if _node == null:
		return
	_frames += 1
	if _frames >= 3 and Time.get_ticks_msec() - _since >= SETTLE_MSEC:
		# 헤드리스에는 그림이 없다: 크기는 뷰포트에서 읽는다(verify.ps1이 창 없이 돈다).
		var shot_size := Vector2i(get_viewport().get_visible_rect().size)
		if _shots_dir != "":
			var image := get_viewport().get_texture().get_image()
			image.save_png(_shots_dir.path_join(String(_plan[_i][0]) + ".png"))
			shot_size = image.get_size()
		print("size,%s,%dx%d" % [_plan[_i][0], shot_size.x, shot_size.y])
		var grid := _node.find_child("TrialGrid", true, false) as Control
		var help := _node.find_child("PatternHelp", true, false) as Control
		if grid != null and help != null:
			print("fit,%s,%d,%d" % [_plan[_i][0], int(grid.get_global_rect().end.x), int(help.get_global_rect().end.y)])
		_next()


# ---------------------------------------------------------------- 하루 화면

func _screen(path: String, day: DayState) -> void:
	_node = (load(path) as PackedScene).instantiate()
	if day != null:
		_node.set("day", day)
	add_child(_node)


## 고정 점수의 의뢰에 실제 의뢰의 이름·한마디·평판·무대·그림을 입힌다(결투를 돌리지 않고 견본의 점수를 낸다).
func _scored(real_path: String, base_reward: int, tip_max: int, score: int) -> Commission:
	var real := load(real_path) as Commission
	var commission: Commission = _d._fixed_commission(real.client_name, base_reward, tip_max, score)
	commission.success_line = real.success_line
	commission.partial_line = real.partial_line
	commission.fail_line = real.fail_line
	commission.reputation_effect = real.reputation_effect
	commission.opponent = real.opponent
	commission.client_portrait = real.client_portrait
	return commission


func _new_day(commissions: Array[Commission]) -> DayState:
	var data := DayData.new()
	data.commissions = commissions
	return DayState.new(load(Session.ECONOMY_PATH), data, load(Session.CATALOG_PATH), null, load(Session.REPUTATION_PATH))


func _pair_settle() -> String:
	var commissions: Array[Commission] = [_scored(FEATHER_PATH, 45, 25, 100), load(USURER_PATH), load(POOR_PATH)]
	_pair_day = _new_day(commissions)
	_pair_day.accept()
	_pair_day.finish_duel(_d._record(DT.EndReason.CONDITION))
	_screen(Session.SETTLEMENT_PATH, _pair_day)
	return "클라라 100점(고정 점수 의뢰) 평판 %d" % _pair_day.reputation


func _pair_counter() -> String:
	_pair_day.proceed()
	_screen(Session.COUNTER_PATH, _pair_day)
	return "비토리오 손님 %d/%d 소지금 %d" % [_pair_day.index + 1, _pair_day.commission_count(), _pair_day.money]


## 견본의 폐점: 클라라 100 · 비토리오 85 · 토마소 60(다침). 견본의 돌려보낸 이네스는 넣지 않았다.
func _closed_day() -> DayState:
	var commissions: Array[Commission] = [_scored(FEATHER_PATH, 45, 25, 100), _scored(USURER_PATH, 55, 20, 85), _scored(POOR_PATH, 30, 10, 60)]
	var day := _new_day(commissions)
	for end_reason: int in [DT.EndReason.CONDITION, DT.EndReason.CONDITION, DT.EndReason.PLAYER_DEFEATED]:
		day.accept()
		day.finish_duel(_d._record(end_reason))
		if end_reason != DT.EndReason.PLAYER_DEFEATED:
			day.proceed()
	return day


func _pair_closing() -> String:
	_closing_day = _closed_day()
	_closing_day.proceed()
	_screen(Session.CLOSING_PATH, _closing_day)
	return "셋을 끝낸 폐점(돌려보낸 손님 없음) 소지금 %d" % _closing_day.money


func _settle_hurt() -> String:
	_screen(Session.SETTLEMENT_PATH, _closed_day())
	return "토마소 60점 다침"


func _title() -> String:
	# 처음 화면은 세션에서 저장을 읽는다. 찍는 동안만 저장 자리를 비워 저장 없는 꼴을 낸다.
	var session := get_node_or_null(^"/root/GameSession")
	var kept := String(session.get("save_path")) if session != null else ""
	if session != null:
		session.set("save_path", "")
	_screen(Session.TITLE_PATH, null)
	if session != null:
		session.set("save_path", kept)
	return "저장 없음"


func _title_save() -> String:
	_node = (load(Session.TITLE_PATH) as PackedScene).instantiate()
	_node.set("saved", _closing_day)
	add_child(_node)
	return "저장 있음(%d일차)" % _closing_day.day_number


func _help() -> String:
	_title_save()
	(_node.find_child("Help", true, false) as Button).pressed.emit()
	return "도움말 화면"


func _select() -> String:
	_screen(Session.SELECT_PATH, null)
	return "연습 선택"


# ---------------------------------------------------------------- 결투

func _duel(commission_path: String) -> DuelCore:
	_node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	_node.set("commission", load(commission_path))
	_node.set("mouse_aim_enabled", false)
	_node.set("rng_seed", 1)
	add_child(_node)
	# 판과 표시를 이 씬이 놓은 값으로 묶는다. add_child 뒤에 끈다: Godot은 _ready 직전에 처리를 다시 켠다.
	_node.set_process(false)
	_node.set_physics_process(false)
	return _node.get("core")


func _big_attack(opponent: OpponentData) -> AttackData:
	for atk in opponent.attacks:
		# 패턴의 뿌리(세 번 베기)는 큰 공격이지만 버릇의 큰 베기가 아니다(결정 426).
		if atk.is_big and atk.chain.is_empty():
			return atk
	for habit in opponent.habits:
		if habit.response != null and habit.response.is_big:
			return habit.response
	return null


## 상대의 상태와 내 칼을 놓고 화면을 한 번 그린다. big_hold면 큰 베기의 예비 동작이 멈춘 자리다.
func _pose(core: DuelCore, distance: int, big_hold: bool, player_state: int, direction: int, height: int, fresh := false) -> void:
	var now := 0.0
	if big_hold:
		var big := _big_attack(core.opponent_data)
		var tell := big.tell_time * (core.opponent_data.close_tell_multiplier if distance == DT.Distance.CLOSE else 1.0)
		now = States.put(core, DT.OpponentState.TELL, big, OpponentMotion.hold_end(tell, core.weapon.parry_window, core.opponent_data), distance)
	else:
		now = States.put(core, DT.OpponentState.IDLE, null, 0.0, distance)
	core.player_state = player_state
	core.player_state_start = now - 1.0
	core.player_state_end = now + 1.0
	core.aim_direction = direction
	core.aim_height = height
	core.attack_direction = direction
	core.attack_height = height
	core.guard_fresh = fresh
	core.guard_enter_time = now if fresh else -INF
	(_node.get_node("OpponentView") as OpponentView).setup(core.opponent_data, core.weapon, core.opponent_has_hat)
	(_node.get_node("PlayerSwordView") as PlayerSwordView).setup()
	_node.set("_display_time", now)
	_node.call("_update_views", 0.0)


func _pair_duel() -> String:
	var core := _duel(FEATHER_PATH)
	_pose(core, DT.Distance.ENGAGE, true, DT.PlayerState.GUARD, DT.Direction.CENTER, DT.Height.MID, true)
	return "교전 큰 베기 hold · 갓 올린 막기 가운데 · 방심 %.2f(견본 0.45) · 엉킴 %.2f(견본 0.30) · 충족도 게이지 없음(견본 0.6)" % [
		core.complacency(), core.bind_gauge()]


func _pair_duel_warn() -> String:
	var core := _duel(FEATHER_PATH)
	_pose(core, DT.Distance.CLOSE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	# 엉킴과 방심의 값은 코어 밖에서 놓지 않는다. 표시만 견본의 경고 장면으로 놓는다(견본도 드문 조합이라고 적었다).
	var hud := _node.get_node("HUD")
	(hud.get("_bind_bar") as DuelHud.BindBar).set_values(0.9, true)
	(hud.get("_bind_warning") as Label).visible = true
	(hud.get("_complacency_bar") as DuelHud.ComplacencyBar).set_values(1.0, false)
	var outline := _node.get_node("PlayerSwordView/Sword/BindWarning") as Line2D
	outline.visible = true
	outline.default_color.a = 1.0
	return "밀착 대기 · 엉킴 0.9 경고와 방심 가득은 표시만 놓음"


func _duel_far() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.FAR, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	return "멀리 대기(조준 패널이 한 줄 자란다)"


func _duel_close() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.CLOSE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	return "밀착 대기"


func _duel_close_bighold() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.CLOSE, true, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	return "밀착 큰 베기 hold(칼이 위 가운데 패널 위로)"


func _duel_right_high() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.ENGAGE, false, DT.PlayerState.READY, DT.Direction.RIGHT, DT.Height.HIGH)
	return "교전 대기 · 오른쪽 상단 조준(날밑과 조준 패널)"


func _result() -> String:
	var core := _duel(FEATHER_PATH)
	_pose(core, DT.Distance.ENGAGE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	core.ended = true
	core.end_reason = DT.EndReason.TIME_UP
	(_node.get_node("ResultPanel") as ResultPanel).show_result(core, load(FEATHER_PATH))
	return "결과 패널(시간 초과)"
