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
## 칼 선(폭 2.9) 바깥으로 지금과 같은 폭 3.5가 보이게 넓혔다(결정 306).
const BIND_OUTLINE_WIDTH := 10.0
const OUTLINE_COLOR := Color("3B2A1E")
const OUTLINE_WIDTH := 2.9
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

## 손 그림. 비면 자리 표시(Hand·Label)가 보인다(결정 302).
@export var hand_art: PartArt
## 칼 그림(레이피어). 비면 씬의 여덟 점 다각형과 선이다(결정 328).
@export var sword_art: PartArt

## 상대의 상태 색 셰이더를 내 칼 그림에 쓴다: 칠만 상태 색이 되고 짙은 선은 남는다(결정 327).
const TINT_SHADER := preload("res://scenes/duel/opponent_part.gdshader")
## 칼에는 남길 고유 색이 없어 상태 색을 다 얹는다(상대는 80%).
const TINT_AMOUNT := 1.0
## 그림이 테두리 위에 그려져 바깥 절반 3.5만 보인다(결정 330).
const BIND_ART_WIDTH := 7.0
const GUARD_WIDTH := 1.8
## 막기 때 그림 뒤에 보이는 넓은 색 면의 불투명도(사용자가 고른 시안의 값, 결정 329).
const GUARD_PLATE_ALPHA := 0.784

var _sword_material: ShaderMaterial

@onready var _sword: Polygon2D = $Sword
## 엉킴 경고: 칼의 테두리. 칼 뒤에 그려 칼의 상태 색이 그대로 보인다.
var _bind_warning: Line2D


func _ready() -> void:
	# 엉킴 테두리가 바뀐 다각형을 따르게 맨 먼저 한다.
	var has_sword_art := _apply_sword_art()
	_bind_warning = Line2D.new()
	_bind_warning.name = "BindWarning"
	_bind_warning.points = _sword.polygon
	_bind_warning.closed = true
	_bind_warning.width = BIND_ART_WIDTH if has_sword_art else BIND_OUTLINE_WIDTH
	_bind_warning.default_color = COLOR_BIND
	_bind_warning.joint_mode = Line2D.LINE_JOINT_ROUND
	_bind_warning.show_behind_parent = true
	_bind_warning.visible = false
	_sword.add_child(_bind_warning)
	# 그림에는 선이 들어 있다. 따로 긋는 선은 그림이 없을 때만 쓴다.
	if not has_sword_art:
		var outline := Line2D.new()
		outline.name = "Outline"
		outline.points = _sword.polygon
		outline.closed = true
		outline.width = OUTLINE_WIDTH
		outline.default_color = OUTLINE_COLOR
		outline.joint_mode = Line2D.LINE_JOINT_ROUND
		_sword.add_child(outline)
	_apply_hand_art()


## 칼 그림을 건다. Sword(다각형)는 그림의 실루엣 꼴이 되어 막기 때만 보이는 신호 판으로 남는다(결정 328).
func _apply_sword_art() -> bool:
	var art: Sprite2D = $Sword/Art
	var has_art := sword_art != null and sword_art.texture != null and sword_art.outline.size() >= 3
	art.visible = has_art
	if not has_art:
		return false
	var points := PackedVector2Array()
	for point in sword_art.outline:
		points.append((point - sword_art.joint) * sword_art.units_per_px)
	_sword.polygon = points
	art.texture = sword_art.texture
	art.offset = -sword_art.joint
	art.scale = sword_art.units_per_px
	_sword_material = ShaderMaterial.new()
	_sword_material.shader = TINT_SHADER
	_sword_material.set_shader_parameter(&"tint_amount", TINT_AMOUNT)
	art.material = _sword_material
	return true


func _apply_hand_art() -> void:
	var art: Sprite2D = $HandArt
	var has_art := hand_art != null and hand_art.texture != null
	art.visible = has_art
	$Hand.visible = not has_art
	$Label.visible = not has_art
	if has_art:
		art.texture = hand_art.texture
		art.offset = -hand_art.joint
		art.scale = hand_art.units_per_px


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
			blade_width = GUARD_WIDTH
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
	if _sword_material != null:
		_sword_material.set_shader_parameter(&"tint_color", Vector3(color.r, color.g, color.b))
		# 그림은 늘이지 않는다: 판의 가로 배율을 되돌린다(결정 329).
		($Sword/Art as Sprite2D).scale.x = sword_art.units_per_px.x / blade_width
		_sword.self_modulate.a = GUARD_PLATE_ALPHA if state == DT.PlayerState.GUARD else 0.0
	# 엉킴 경고는 칼의 색을 덮지 않는다(막기·패리 창의 색이 그대로 보여야 한다). 테두리만 켠다.
	_bind_warning.visible = DuelHud.bind_warning_now(core)
	if _bind_warning.visible:
		_bind_warning.default_color.a = 0.55 + 0.45 * absf(sin(_clock * PI * BIND_BLINK_RATE))
