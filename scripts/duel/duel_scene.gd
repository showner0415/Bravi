class_name DuelScene
extends Node2D
## 결투 씬. 입력을 DuelCore에 전달하고 표시를 갱신한다. 규칙은 전부 DuelCore에 있다.

const DT := preload("res://scripts/duel/duel_types.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DEFAULT_OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
## 의뢰가 무대를 고르지 않았거나 의뢰가 없을 때의 무대(결정 294).
const DEFAULT_STAGE_PATH := "res://data/stages/alley.tres"
const SELECT_PATH := "res://scenes/ui/commission_select.tscn"
## 하루 모드에서 결과를 넘기는 액션(Space / Enter).
const ACCEPT_ACTION := &"ui_accept"
const DAY_FOOTER := "Space / Enter: 의뢰소로 돌아간다"

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
## 비어 있지 않으면 로드한 무기 대신 이 무기로 판을 만든다(테스트용).
var test_weapon: WeaponData

var core: DuelCore

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
	_opponent_view.setup(opponent, weapon, has_hat)
	_sword_view.setup()
	_hud.reset()
	_hud.set_commission(commission)
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
	advance(delta)


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
	# 판정은 건드리지 않는다.
	if core.ended:
		_display_time = core.time
	else:
		var tick := 1.0 / Engine.physics_ticks_per_second
		_display_time = core.time + Engine.get_physics_interpolation_fraction() * tick
	_update_views(delta)


func _input(event: InputEvent) -> void:
	if _use_virtual_mouse and event is InputEventMouse:
		_virtual_mouse = event.position
		if mouse_aim_enabled and core != null:
			_update_aim_from_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if _day_mode and (event.is_action_pressed(&"retry") or event.is_action_pressed(&"back")):
		# 하루 중의 결투는 한 번뿐이다. 다시 하기와 나가기를 듣지 않는다.
		return
	if _day_mode and event.is_action_pressed(ACCEPT_ACTION):
		_finish_day_duel()
		return
	if event.is_action_pressed(&"retry"):
		start_duel()
	elif event.is_action_pressed(&"debug_toggle"):
		_hud.toggle_debug()
	elif event.is_action_pressed(&"attack"):
		core.press_attack()
	elif event.is_action_pressed(&"guard"):
		core.set_guard(true)
	elif event.is_action_released(&"guard"):
		core.set_guard(false)
	elif event.is_action_pressed(&"step_forward"):
		core.step(1)
	elif event.is_action_pressed(&"step_back"):
		core.step(-1)
	elif event.is_action_pressed(&"back"):
		# 의뢰 선택으로 돌아간다. 다른 씬 아래에 붙어 있을 때(테스트)는 아무것도 하지 않는다.
		if get_tree().current_scene == self:
			get_tree().change_scene_to_file(SELECT_PATH)


func _update_aim_from_mouse() -> void:
	var size := get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var mouse := _virtual_mouse if _use_virtual_mouse else get_viewport().get_mouse_position()
	var column := clampi(int(mouse.x / size.x * 3.0), 0, 2)
	var row := clampi(int(mouse.y / size.y * 3.0), 0, 2)
	core.set_aim(column, row)


func _update_views(delta: float) -> void:
	_opponent_view.set_target(core.current_aim_part())
	_opponent_view.update_view(core, _display_time, delta)
	_sword_view.update_view(core, _display_time, get_viewport_rect().size, delta)
	_hud.refresh(core)
	queue_redraw()


func _on_core_event(ev: Dictionary) -> void:
	CurveCheck.on_event(ev, core)
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
		# 높이를 가진 타격이 오는 칸: 예비 색 테두리, 내 막기가 그 칸에 있으면 초록(결정 388).
		var strike_height := core.brain.current_height()
		if core.brain.state == DuelTypes.OpponentState.TELL and strike_height >= 0:
			var strike_dir: int = core.brain.current_attack.direction
			var guarded := core.player_state == DuelTypes.PlayerState.GUARD and core.aim_direction == strike_dir \
					and core.aim_height == strike_height
			var target := Rect2(Vector2(cell.x * strike_dir, cell.y * strike_height), cell).grow(-4.0)
			draw_rect(target, Color(0.3, 1.0, 0.5, 0.75) if guarded else Color(1.0, 0.9, 0.25, 0.5), false, 4.0)


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
