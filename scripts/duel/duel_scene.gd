class_name DuelScene
extends Node2D
## 결투 씬. 입력을 DuelCore에 전달하고 표시를 갱신한다. 규칙은 전부 DuelCore에 있다.

const DT := preload("res://scripts/duel/duel_types.gd")
const EventLog := preload("res://scripts/duel/event_log.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DEFAULT_OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
## 의뢰가 무대를 고르지 않았거나 의뢰가 없을 때의 무대(결정 294).
const DEFAULT_STAGE_PATH := "res://data/stages/alley.tres"
const SELECT_PATH := "res://scenes/ui/commission_select.tscn"
## 하루 모드에서 결과를 넘기는 액션(Space / Enter).
const ACCEPT_ACTION := &"ui_accept"
const DAY_FOOTER := "Space / Enter: 의뢰소로 돌아간다"
const SessionScript := preload("res://scripts/game_session.gd")
## 멈춤 화면을 닫은 뒤 판을 멈춘 채 두는 시간(밀리초, 결정 509). 임시 값이다.
const RESUME_HOLD_MSEC := 400
const EXIT_DAY_TEXT := "처음 화면으로"
const EXIT_PRACTICE_TEXT := "연습 고르기로"

## 의뢰. 비어 있으면 /root/GameSession에서 받고, 그것도 없으면 자유 결투다.
@export var commission: Commission
## 연습에서 의뢰 없이 만나는 상대(결정 377). 비어 있으면 세션의 것을 받는다. 하루의 결투에서는 쓰지 않는다.
var practice_opponent: OpponentData

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
## 있고 그 단계가 결투면 하루 모드다: 의뢰는 day의 지금 의뢰이고, 결투는 한 번뿐이다.
var day: DayState

## 끄면 마우스 위치로 조준을 덮어쓰지 않는다(테스트가 코어에 직접 조준을 넣을 때).
var mouse_aim_enabled := true
var _use_virtual_mouse := OS.get_cmdline_user_args().has("--bravi-virtual-mouse")
var _virtual_mouse := Vector2.ZERO
## 0 이상이면 이 시드로 상대의 난수를 고정한다(테스트용).
var rng_seed := -1
## -1이면 하루는 날을 따르고 연습은 1단이다. 0 이상이면 그 단(0이 1단)으로 고정한다. start_duel 전에 정한다(결정 580).
var style_tier := -1
## 비어 있지 않으면 로드한 무기 대신 이 무기로 판을 만든다(테스트용).
var test_weapon: WeaponData

var core: DuelCore

## 멈춤(멈춤 화면이 열렸거나 돌아오기 대기 중). get_tree().paused를 쓰지 않는 까닭은 결정 507이다.
## 엔진이 부르는 _physics_process·_process·입력만 본다. advance()는 보지 않는다(테스트·스모크·찍기의 직접 걸음).
var paused := false
var resume_hold_msec := RESUME_HOLD_MSEC
var _holding := false
var _hold_until_msec := 0
var _pause_menu: PauseMenu
var _pause_count := 0
var _pause_time := 0.0
var _pause_drift := 0.0
var _swallowed_attacks := 0

var _cover_marks: CoverMarks
var _display_time := 0.0
## 하루 모드인가. _ready에서 한 번 정한다(정산으로 넘긴 뒤 같은 씬에서 R·Esc가 살아나지 않게).
var _day_mode := false
## 하루 모드에서 결투 결과를 day에 이미 넘겼는가.
var _day_reported := false

@onready var _opponent_view: OpponentView = $OpponentView
@onready var _sword_view: PlayerSwordView = $PlayerSwordView
@onready var _hud: DuelHud = $HUD
@onready var _result_panel: ResultPanel = $ResultPanel
@onready var _beeper: Beeper = $Beeper
@onready var _stage: TextureRect = $Background/Stage


func _ready() -> void:
	_virtual_mouse = get_viewport_rect().size * 0.5
	var session := get_node_or_null(^"/root/GameSession")
	if day == null and session != null and session.get("day") is DayState:
		day = session.get("day")
	_day_mode = day != null and day.phase == DayState.Phase.DUEL
	if _day_mode:
		commission = day.current_commission()
		_hud.day_mode = true
		_result_panel.footer_text = DAY_FOOTER
		practice_opponent = null
	elif commission == null and practice_opponent == null and session != null:
		if session.get("commission") is Commission:
			commission = session.get("commission")
		elif session.get("practice_opponent") is OpponentData:
			practice_opponent = session.get("practice_opponent")
	# 송곳 가림의 표지는 씬 파일을 고치지 않고 상대 몸 바로 뒤에 붙인다(결정 831).
	_cover_marks = CoverMarks.new()
	_cover_marks.name = "CoverMarks"
	add_child(_cover_marks)
	move_child(_cover_marks, _opponent_view.get_index() + 1)
	get_viewport().size_changed.connect(_layout)
	_layout()
	start_duel()


## 새 판을 시작한다(R 다시 하기 포함).
func start_duel() -> void:
	var opponent: OpponentData = load(DEFAULT_OPPONENT_PATH)
	if commission != null and commission.opponent != null:
		opponent = commission.opponent
	elif commission == null and practice_opponent != null:
		opponent = practice_opponent
	# 단은 CurveCheck보다 앞에서 골라 코어·뇌·뷰가 같은 사본을 받는다(결정 580).
	if style_tier >= 0:
		opponent = opponent.at_tier(style_tier)
	elif _day_mode and day != null:
		opponent = opponent.for_day(day.day_number)
	if commission != null:
		opponent = commission.fit_opponent(opponent)
	# 반응 싸움 확인(계획 030): 켜져 있으면 표시의 곡선만 다른 사본을 코어와 뷰에 준다. 꺼져 있으면 그대로다.
	opponent = CurveCheck.prepare(opponent)
	var weapon: WeaponData = test_weapon if test_weapon != null else load(WEAPON_PATH)
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var conditions: Array[CommissionCondition] = []
	if commission != null:
		conditions = commission.conditions
	var rules: DuelRules = load(RULES_PATH)
	if _day_mode:
		# 하루 모드: 가진 업그레이드가 적용된 사본을 쓴다. 연습과 자유 결투는 기본 규칙 그대로다.
		rules = day.effective_duel_rules(rules)
	# 모자는 상대의 고정 부위가 아니라 의뢰가 씌운다(깃털 자르기). 의뢰가 없으면 모자도 없다.
	var has_hat := commission != null and commission.opponent_wears_hat
	core = DuelCore.new()
	core.setup(rules, weapon, opponent, rng, conditions, has_hat)
	core.event.connect(_on_core_event)
	_display_time = 0.0
	_clear_pause()
	_pause_count = 0
	_pause_drift = 0.0
	_swallowed_attacks = 0
	_opponent_view.setup(opponent, weapon, has_hat)
	_sword_view.setup()
	_hud.reset()
	_hud.set_commission(commission)
	var empty_note := DuelHud.empty_note(DuelHud.HELP_EMPTY).trim_prefix(" · ")
	if empty_note != "":
		_hud.add_note(empty_note)
	_result_panel.hide_result()
	_apply_stage()
	_update_views(0.0)


## 무대는 표시만 한다: 코어에 넘기지 않는다(결정 294). 그림이 없으면 Background/Color가 바탕이다.
func _apply_stage() -> void:
	var stage: StageData = null
	if commission != null:
		stage = commission.stage
	if stage == null and ResourceLoader.exists(DEFAULT_STAGE_PATH):
		stage = load(DEFAULT_STAGE_PATH) as StageData
	_stage.texture = stage.texture if stage != null else null


func _physics_process(delta: float) -> void:
	if paused and _holding and hold_over(_hold_until_msec, Time.get_ticks_msec()):
		_end_hold()
	if paused:
		return
	advance(delta)


## 돌아오기 대기가 끝났는가(시각은 Time.get_ticks_msec()).
static func hold_over(hold_until_msec: int, now_msec: int) -> bool:
	return now_msec >= hold_until_msec


## 판을 멈추고 멈춤 화면을 연다. 이미 멈춘 화면이 떠 있거나 판이 끝났으면 아무것도 하지 않고 false다.
## 돌아오기 대기 중이면 대기를 접고 다시 멈춤 화면을 연다.
func pause(_reason: StringName) -> bool:
	if core == null or core.ended or (paused and not _holding):
		return false
	_holding = false
	_hud.set_resume_hold(false)
	paused = true
	_pause_count += 1
	_pause_time = core.time
	var exit_text := EXIT_DAY_TEXT if _day_mode else EXIT_PRACTICE_TEXT
	_pause_menu = PauseMenu.open(self, exit_text, _exit_note())
	# 붙이기가 실패하면 "멈췄는데 화면이 없는" 상태가 남는다(Esc·창 닫기 모두 못 푼다): 되돌린다.
	if not _pause_menu.is_inside_tree():
		_pause_menu.free()
		_pause_menu = null
		paused = false
		_pause_count -= 1
		return false
	_pause_menu.resumed.connect(_on_menu_resumed)
	_pause_menu.exit_pressed.connect(_on_exit_pressed)
	return true


## 멈춤 화면을 닫고 돌아오기 대기에 든다(멈춤 화면의 "계속"·Esc와 같다).
func resume() -> void:
	if not paused or _holding:
		return
	var menu := _pause_menu
	_pause_menu = null
	if menu != null and is_instance_valid(menu):
		menu.resumed.disconnect(_on_menu_resumed)
		if menu.get_parent() != null:
			menu.get_parent().remove_child(menu)
		menu.queue_free()
	_begin_hold()


## 하루 중 창 닫기 요청(GameSession.handle_close_request가 부른다). 창 포커스의 조건은 없다(결정 508).
func pause_for_close() -> void:
	pause(&"close")


func _on_menu_resumed() -> void:
	_pause_menu = null
	_begin_hold()


func _begin_hold() -> void:
	# 멈춘 동안 우클릭을 뗐으면 막기가 풀린다. 쥔 채면 새로 누른 것이 아니다(패리 공짜 없음, 결정 509).
	var held := Input.is_action_pressed(&"guard")
	if core.guard_held != held:
		core.set_guard(held)
	if mouse_aim_enabled:
		_update_aim_from_mouse()
	_holding = true
	_hold_until_msec = Time.get_ticks_msec() + resume_hold_msec
	_hud.set_resume_hold(true)


func _end_hold() -> void:
	_pause_drift = maxf(_pause_drift, absf(core.time - _pause_time))
	_holding = false
	paused = false
	# 대기 중 버린 왼쪽 막기를 쥔 채면 이제 막기가 된다(결정 522).
	var held := Input.is_action_pressed(&"guard")
	if core.guard_held != held:
		core.set_guard(held)
	_hud.set_resume_hold(false)


## 새 판(start_duel)이 멈춤과 대기를 모두 지운다.
func _clear_pause() -> void:
	paused = false
	_holding = false
	_hud.set_resume_hold(false)
	if _pause_menu != null and is_instance_valid(_pause_menu):
		if _pause_menu.get_parent() != null:
			_pause_menu.get_parent().remove_child(_pause_menu)
		_pause_menu.queue_free()
	_pause_menu = null


func _exit_note() -> String:
	if not _day_mode:
		return ""
	var session := get_node_or_null(^"/root/GameSession")
	var resume_day := int(session.call("resume_day")) if session != null else 0
	return SessionScript.quit_note(day, resume_day)


func _on_exit_pressed() -> void:
	if get_tree().current_scene != self:
		return
	if _day_mode:
		var session := get_node_or_null(^"/root/GameSession")
		if session != null:
			session.call("end_day_play")
			session.call("go_to_title")
	else:
		get_tree().change_scene_to_file(SELECT_PATH)


## 창 포커스를 잃으면 멈춘다(결정 508 (나)). 물리 걸음이 꺼진 결투(찍기 도구)에서는 멈추지 않는다.
## 돌아와도 저절로 풀리지 않는다.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# 엔진이 이 알림을 propagate_notification으로 돌리는 동안은 add_child가 막힌다(S02 창 확인): 미룬다.
		_pause_from_focus.call_deferred()


func _pause_from_focus() -> void:
	if core != null and is_physics_processing():
		pause(&"focus")


## 조준 갱신과 코어 tick. 테스트가 실시간을 기다리지 않고 직접 부를 수 있다.
func advance(delta: float) -> void:
	if mouse_aim_enabled:
		_update_aim_from_mouse()
	core.tick(delta)
	if core.ended and not _result_panel.is_showing():
		_result_panel.show_result(core, commission)
	_display_time = core.time
	# 부드러운 이동과 번쩍임의 시간은 _process가 흘린다(여기서 또 흘리면 두 배가 된다).
	_update_views(0.0)


func _process(delta: float) -> void:
	# 표시용 시각: 고주사율 화면에서도 매끄럽게 움직이도록 물리 tick 사이를 보간한다.
	# 판정은 건드리지 않는다. 멈춘 동안은 그림도 움직이지 않는다(결정 507).
	if paused:
		return
	if core.ended:
		_display_time = core.time
	else:
		var tick := 1.0 / Engine.physics_ticks_per_second
		_display_time = core.time + Engine.get_physics_interpolation_fraction() * tick
	_update_views(delta)


func _input(event: InputEvent) -> void:
	if _use_virtual_mouse and event is InputEventMouse:
		_virtual_mouse = event.position
		if mouse_aim_enabled and core != null and not paused:
			_update_aim_from_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if _day_mode and event.is_action_pressed(ACCEPT_ACTION):
		_finish_day_duel()
		return
	# 멈춤 화면이 열린 동안은 결투의 액션을 하나도 듣지 않는다(결정 507). 돌아오기 대기 중에는 듣는다(결정 509).
	if paused and not _holding:
		return
	# 대기 중 왼쪽 버튼은 무엇에 묶였든 코어에 넘기지 않는다: "계속"을 누르는 버튼이라 둘째 누름이 막기·걸음이 되던 길을 막는다(결정 522).
	if _holding and event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if event.is_action_pressed(&"attack"):
			_swallowed_attacks += 1
		return
	# F11은 처리됨으로 치지 않는다: Settings가 이어서 화면을 바꾼다(결정 528). 전환 동안의 입력이 판에 닿지 않게 먼저 멈춘다.
	if event.is_action_pressed(&"toggle_fullscreen"):
		pause(&"display")
		return
	if event.is_action_pressed(&"back"):
		if not core.ended:
			pause(&"esc")
		elif not _day_mode and get_tree().current_scene == self:
			# 끝난 판의 Esc는 지금처럼 의뢰 선택으로 간다. 다른 씬 아래에 붙어 있을 때(테스트)는 아무것도 하지 않는다.
			get_tree().change_scene_to_file(SELECT_PATH)
		return
	if _day_mode and event.is_action_pressed(&"retry"):
		# 하루 중의 결투는 한 번뿐이다. 다시 하기를 듣지 않는다.
		return
	if event.is_action_pressed(&"retry"):
		start_duel()
	elif event.is_action_pressed(&"debug_toggle"):
		_hud.toggle_debug()
	elif event.is_action_pressed(&"attack"):
		if _holding:
			# "계속"의 클릭과 더블클릭의 둘째 누름이 공격이 되지 않게(결정 509).
			_swallowed_attacks += 1
		else:
			core.press_attack()
	elif event.is_action_pressed(&"guard"):
		core.set_guard(true)
	elif event.is_action_released(&"guard"):
		core.set_guard(false)
	elif event.is_action_pressed(&"step_forward"):
		core.step(1)
	elif event.is_action_pressed(&"step_back"):
		core.step(-1)


func _update_aim_from_mouse() -> void:
	var size := get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var mouse := _virtual_mouse if _use_virtual_mouse else get_viewport().get_mouse_position()
	var cell := aim_cell(mouse, size)
	core.set_aim(cell.x, cell.y)


## 마우스(뷰포트 좌표)가 가리키는 3x3 조준칸 (열, 행). 테스트가 게임의 셈을 그대로 부른다(결정 530).
static func aim_cell(point: Vector2, size: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x / size.x * 3.0), 0, 2), clampi(int(point.y / size.y * 3.0), 0, 2))


func _update_views(delta: float) -> void:
	_opponent_view.set_target(core.current_aim_part())
	_opponent_view.update_view(core, _display_time, delta)
	_sword_view.update_view(core, _display_time, get_viewport_rect().size, delta)
	_hud.refresh(core)
	if _cover_marks != null:
		_cover_marks.core = core
		_cover_marks.queue_redraw()
	queue_redraw()


func _on_core_event(ev: Dictionary) -> void:
	CurveCheck.on_event(ev, core)
	EventLog.on_event(ev, core, "하루" if _day_mode else ("의뢰 연습" if commission != null else "자유 결투"),
			{"pauses": _pause_count, "pause_drift": _pause_drift, "swallowed_attacks": _swallowed_attacks})
	_opponent_view.on_event(ev)
	_sword_view.on_event(ev)
	_hud.on_event(ev)
	_beeper.on_event(ev)


## 화면 크기에 맞춰 배치한다. stretch aspect가 keep이라 뷰포트는 늘 1280x720이지만,
## 그 설정이 바뀌어도 따라가도록 크기를 직접 읽는다.
func _layout() -> void:
	var size := get_viewport_rect().size
	_opponent_view.anchor = Vector2(size.x * 0.5, size.y * 0.62)
	queue_redraw()


## 조준 칸(3x3)과 지금 조준 중인 칸.
func _draw() -> void:
	var size := get_viewport_rect().size
	var cell := size / 3.0
	var line_color := Color(1, 1, 1, 0.08)
	for i in range(1, 3):
		draw_line(Vector2(cell.x * i, 0), Vector2(cell.x * i, size.y), line_color, 2.0)
		draw_line(Vector2(0, cell.y * i), Vector2(size.x, cell.y * i), line_color, 2.0)
	if core != null:
		var rect := Rect2(Vector2(cell.x * core.aim_direction, cell.y * core.aim_height), cell)
		draw_rect(rect, Color(1, 1, 1, 0.05))
		draw_rect(rect, Color(1, 1, 1, 0.25), false, 2.0)
		if DuelHud.forecast_on(core):
			_draw_forecast_frame(rect.grow(-10.0), core.attack_forecast()["verdict"])
		# 높이를 가진 타격이 오는 칸: 예비 색 테두리, 내 막기가 그 칸에 있으면 초록(결정 388).
		var frame := strike_cell_frame(core)
		if not frame.is_empty():
			var unit: Rect2 = frame["rect"]
			var target := Rect2(unit.position * cell, unit.size * cell).grow(-4.0)
			draw_rect(target, Color(0.3, 1.0, 0.5, 0.75) if frame["guarded"] else Color(1.0, 0.9, 0.25, 0.5), false, 4.0)


## 높이를 가진 타격이 오는 칸의 테두리 값. 빈 사전이면 긋지 않는다. rect는 칸 단위(위치 = 방향·높이, 크기 1x1)이고
## 헛손질의 예비 동작에는 긋지 않는다: 초록이 속는 손에 "맞게 막았다"를 띄우지 않게(결정 670).
static func strike_cell_frame(p_core: DuelCore) -> Dictionary:
	var brain := p_core.brain
	var strike_height := brain.current_height()
	if brain.state != DuelTypes.OpponentState.TELL or strike_height < 0:
		return {}
	if brain.current_attack.feint:
		return {}
	var strike_dir: int = brain.current_attack.direction
	var guarded := p_core.player_state == DuelTypes.PlayerState.GUARD and p_core.aim_direction == strike_dir \
			and p_core.aim_height == strike_height
	return {
		"rect": Rect2(Vector2(strike_dir, strike_height), Vector2.ONE), "guarded": guarded,
		"direction": strike_dir, "height": strike_height,
	}


## 조준 칸의 미리보기 테두리. 색만이 아니라 꼴로 가른다: 닿는다 굵은 실선, 늦다 점선, 멀다 꺾쇠, 피한다 실선과 가위표, 엉킴 잔 점선.
func _draw_forecast_frame(rect: Rect2, verdict: int) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	match verdict:
		DuelTypes.Forecast.REACH:
			draw_rect(rect, Color(0.3, 1.0, 0.5, 0.95), false, 6.0)
		DuelTypes.Forecast.LATE:
			var color := Color(1.0, 0.75, 0.2, 0.95)
			for i in 4:
				draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 4.0, 22.0)
		DuelTypes.Forecast.OUT_OF_RANGE:
			var color := Color(0.8, 0.8, 0.8, 0.9)
			for i in 4:
				var toward: Vector2 = (corners[(i + 1) % 4] - corners[i]).normalized()
				var back: Vector2 = (corners[(i + 3) % 4] - corners[i]).normalized()
				draw_polyline(PackedVector2Array([corners[i] + toward * 36.0, corners[i], corners[i] + back * 36.0]), color, 4.0)
		DuelTypes.Forecast.HEAD_GUARDED:
			var color := Color(1.0, 0.4, 0.4, 0.95)
			draw_rect(rect, color, false, 4.0)
			draw_line(rect.position, rect.end, color, 4.0)
			draw_line(corners[1], corners[3], color, 4.0)
		DuelTypes.Forecast.BIND_CUT:
			var color := Color(0.9, 0.4, 1.0, 0.95)
			for i in 4:
				draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 4.0, 8.0)
		DuelTypes.Forecast.SPIKE_COVERED:
			var color: Color = OpponentView.FORECAST_COLORS[DuelTypes.Forecast.SPIKE_COVERED]
			draw_rect(rect, color, false, 5.0)
			var tip := rect.position + Vector2(18.0, 6.0)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(14.0, 0.0), tip + Vector2(7.0, 26.0)]), color)


## 하루 모드: 끝난 결투의 기록을 day에 넘기고 정산 화면으로 간다. 한 번만 넘긴다.
func _finish_day_duel() -> void:
	if _day_reported or not core.ended or not _result_panel.is_showing():
		return
	if not day.finish_duel(core.record):
		return
	_day_reported = true
	# 다른 씬 아래에 붙어 있을 때(테스트)는 씬을 바꾸지 않는다.
	if get_tree().current_scene == self:
		var session := get_node_or_null(^"/root/GameSession")
		if session != null:
			session.call("go_to_phase_scene")
