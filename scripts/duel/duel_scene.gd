class_name DuelScene
extends Node2D
## 결투 씬. 입력을 DuelCore에 전달하고 표시를 갱신한다. 규칙은 전부 DuelCore에 있다.

const DT := preload("res://scripts/duel/duel_types.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DEFAULT_OPPONENT_PATH := "res://data/opponents/opponent_01.tres"

## 의뢰. 비어 있으면 /root/GameSession에서 받고, 그것도 없으면 자유 결투다.
@export var commission: Commission

## 끄면 마우스 위치로 조준을 덮어쓰지 않는다(테스트가 코어에 직접 조준을 넣을 때).
var mouse_aim_enabled := true
## 0 이상이면 이 시드로 상대의 난수를 고정한다(테스트용).
var rng_seed := -1

var core: DuelCore

var _display_time := 0.0

@onready var _opponent_view: OpponentView = $OpponentView
@onready var _sword_view: PlayerSwordView = $PlayerSwordView
@onready var _hud: DuelHud = $HUD


func _ready() -> void:
	if commission == null:
		var session := get_node_or_null(^"/root/GameSession")
		if session != null and session.get("commission") is Commission:
			commission = session.get("commission")
	get_viewport().size_changed.connect(_layout)
	_layout()
	start_duel()


## 새 판을 시작한다(R 다시 하기 포함).
func start_duel() -> void:
	var opponent: OpponentData = load(DEFAULT_OPPONENT_PATH)
	if commission != null and commission.opponent != null:
		opponent = commission.opponent
	var weapon: WeaponData = load(WEAPON_PATH)
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	core = DuelCore.new()
	core.setup(load(RULES_PATH), weapon, opponent, rng)
	core.event.connect(_on_core_event)
	_display_time = 0.0
	_opponent_view.setup(opponent, weapon)
	_sword_view.setup()
	_hud.reset()
	_update_views(0.0)


func _physics_process(delta: float) -> void:
	advance(delta)


## 조준 갱신과 코어 tick. 테스트가 실시간을 기다리지 않고 직접 부를 수 있다.
func advance(delta: float) -> void:
	if mouse_aim_enabled:
		_update_aim_from_mouse()
	core.tick(delta)
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


func _unhandled_input(event: InputEvent) -> void:
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
	# back(Esc)은 의뢰 선택 화면이 생기는 작업 6에서 연결한다.


func _update_aim_from_mouse() -> void:
	var size := get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var mouse := get_viewport().get_mouse_position()
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
	_opponent_view.on_event(ev)
	_sword_view.on_event(ev)
	_hud.on_event(ev)


## 화면 크기에 맞춰 배치한다(stretch aspect가 expand라 뷰포트가 커질 수 있다).
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
