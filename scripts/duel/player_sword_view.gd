class_name PlayerSwordView
extends Node2D
## 화면 아래의 내 손과 칼. 표시만 한다(판정은 DuelCore).

const DT := preload("res://scripts/duel/duel_types.gd")

const COLOR_READY := Color(0.85, 0.85, 0.9)
const COLOR_WINDUP := Color(1.0, 0.9, 0.3)
const COLOR_RECOVER := Color(0.45, 0.45, 0.5)
const COLOR_GUARD := Color(0.3, 0.85, 0.45)
const COLOR_GUARD_FRESH := Color(0.4, 0.95, 1.0)
const COLOR_STEPPING := Color(0.6, 0.75, 0.95)
const COLOR_PARRY := Color(1.0, 0.85, 0.2)
const COLOR_BLOCK := Color(1.0, 1.0, 1.0)
const COLOR_GRAZED := Color(0.95, 0.25, 0.25)
## 엉킴 경고의 테두리 색. 칼의 색(상태)은 바꾸지 않고 테두리만 두른다.
const COLOR_BIND := Color(1.0, 0.45, 0.2)
const BIND_OUTLINE_WIDTH := 7.0
## 엉킴 경고의 깜박임(1초에 몇 번). 깜박임은 테두리의 투명도로 한다(visible은 경고의 켜짐·꺼짐이다).
const BIND_BLINK_RATE := 3.0

## 방향별 가로 위치(화면 너비 비율)와 칼 기울기(라디안).
const DIRECTION_X: Array[float] = [0.3, 0.5, 0.7]
const DIRECTION_TILT: Array[float] = [-0.4, 0.0, 0.4]
## 높이별 세로 이동(px). 상단은 칼을 높이 든다.
const HEIGHT_SHIFT: Array[float] = [-70.0, 0.0, 45.0]
## 공격 때 칼이 앞으로(화면 위로) 나가는 거리.
const LUNGE := 150.0

var _flash_color := Color.WHITE
var _flash_until := -INF
var _snap := true
## 번쩍임용 시계(실제 시간).
var _clock := 0.0

@onready var _sword: Polygon2D = $Sword
## 엉킴 경고: 칼의 테두리. 칼 뒤에 그려 칼의 상태 색이 그대로 보인다.
var _bind_warning: Line2D


func _ready() -> void:
	_bind_warning = Line2D.new()
	_bind_warning.name = "BindWarning"
	_bind_warning.points = _sword.polygon
	_bind_warning.closed = true
	_bind_warning.width = BIND_OUTLINE_WIDTH
	_bind_warning.default_color = COLOR_BIND
	_bind_warning.joint_mode = Line2D.LINE_JOINT_ROUND
	_bind_warning.show_behind_parent = true
	_bind_warning.visible = false
	_sword.add_child(_bind_warning)


func setup() -> void:
	_flash_until = -INF
	_snap = true


func on_event(ev: Dictionary) -> void:
	if ev["type"] != DuelRecord.STRIKE:
		return
	match ev["result"]:
		DT.StrikeResult.PARRIED:
			_flash_color = COLOR_PARRY
			_flash_until = _clock + 0.25
		DT.StrikeResult.BLOCKED:
			_flash_color = COLOR_BLOCK
			_flash_until = _clock + 0.12
		DT.StrikeResult.GRAZE, DT.StrikeResult.HIT:
			_flash_color = COLOR_GRAZED
			_flash_until = _clock + 0.25


func update_view(core: DuelCore, display_time: float, viewport_size: Vector2, delta: float) -> void:
	_clock += delta
	var state := core.player_state
	var attacking := state == DT.PlayerState.WINDUP or state == DT.PlayerState.RECOVER
	# 공격 중에는 좌클릭 순간에 고정된 조준을 보여 준다.
	var direction := core.attack_direction if attacking else core.aim_direction
	var height := core.attack_height if attacking else core.aim_height

	var target := Vector2(viewport_size.x * DIRECTION_X[direction],
		viewport_size.y - 70.0 + HEIGHT_SHIFT[height])
	var tilt := DIRECTION_TILT[direction]
	var color := COLOR_READY
	var blade_width := 1.0

	var span := maxf(core.player_state_end - core.player_state_start, 0.001)
	var progress := clampf((display_time - core.player_state_start) / span, 0.0, 1.0)
	match state:
		DT.PlayerState.WINDUP:
			target.y -= LUNGE * progress
			color = COLOR_WINDUP
		DT.PlayerState.RECOVER:
			target.y -= LUNGE * (1.0 - progress)
			color = COLOR_RECOVER
		DT.PlayerState.GUARD:
			target.y -= 25.0
			blade_width = 1.8
			var in_parry_window := display_time - core.guard_enter_time <= core.weapon.parry_window
			color = COLOR_GUARD_FRESH if (core.guard_fresh and in_parry_window) else COLOR_GUARD
		DT.PlayerState.STEPPING:
			color = COLOR_STEPPING

	if _clock < _flash_until:
		color = _flash_color

	var smooth := 1.0 - exp(-22.0 * delta) if delta > 0.0 else 0.0
	if _snap:
		smooth = 1.0
		_snap = false
	position = position.lerp(target, smooth)
	rotation = lerpf(rotation, tilt, smooth)
	_sword.color = color
	_sword.scale = Vector2(blade_width, 1.0)
	# 엉킴 경고는 칼의 색을 덮지 않는다(막기·패리 창의 색이 그대로 보여야 한다). 테두리만 켠다.
	_bind_warning.visible = DuelHud.bind_warning_now(core)
	if _bind_warning.visible:
		_bind_warning.default_color.a = 0.55 + 0.45 * absf(sin(_clock * PI * BIND_BLINK_RATE))
