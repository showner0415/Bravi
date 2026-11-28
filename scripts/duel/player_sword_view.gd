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

## 접촉(계획 H03 결정 930~933). 값은 전부 임시다.
enum Recover { TOUCH, BOUNCE, DODGE, SHORT }
enum Cue { NONE, BLOCK, PARRY, HIT }
## 손의 끝 자리: 칼날 길이의 이 배율 안으로 부위에 다가서고, 상자 안으로 가둔다(위쪽은 LUNGE).
const REACH_MIN := 0.80
const REACH_MAX := 1.20
const HAND_BOX_X := 160.0
const HAND_BOX_DOWN := 90.0
const BLADE_SCALE_MIN := 0.5
const BLADE_SCALE_MAX := 1.4
## 소매의 두 모서리가 화면 아래보다 이만큼 더 아래에 있어야 한다(결정 305).
const SLEEVE_MARGIN := 8.0
const TURN_LIMIT := 0.61
## 닿지 않는 거리의 목표: 접촉점에서 손 쪽으로 물러나는 폭과, 부위의 상자에 더하는 여유.
const BACK_OFF := 90.0
const BACK_STEP := 10.0
const RECT_PAD := 8.0
const PULL_TIME := 0.05
const PULL_TIP := 24.0
const PULL_HAND := 14.0
const STRIKE_TIME := 0.12
const GUIDE_RATIO := 0.35
## 찌르기의 뻗음이 시작되는 칼끝은 목표에서 이만큼(px) 이상 뒤에 있다.
const MIN_THRUST_TRAVEL := 120.0
## 당김·들기 구간의 손은 칼날이 이 비율 아래로 짧아지지 않게 내려간다(쉬는 자리에서 LIFT_DOWN까지).
const LIFT_BLADE := 0.85
const LIFT_DOWN := 200.0
const GUIDE_OUT := Vector2(200.0, -70.0)
const ARC_LIFT := 60.0
const SCREEN_PAD := 20.0
## 회수의 처음에 예비의 노랑을 지키는 시간(코어 시각).
const YELLOW_HOLD := 0.05
const CUE_TIME: Array[float] = [0.0, 0.16, 0.12, 0.30]

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
## 칼 둘레에 한 겹 더 두르는 짙은 테(바깥으로 보이는 폭). 상대가 내 칼과 같은 색일 때도 칼날의 윤곽이 남는다(판 P2-2).
const RIM_WIDTH := 2.5
## 엉킴 테두리는 그 테 바깥으로 3.5가 보인다(결정 330): (2.5 + 3.5) × 2.
const BIND_ART_WIDTH := 12.0
const GUARD_WIDTH := 1.8
## 막기 때 그림 뒤에 보이는 넓은 색 면의 불투명도(사용자가 고른 시안의 값, 결정 329).
const GUARD_PLATE_ALPHA := 0.784

var _sword_material: ShaderMaterial

@onready var _sword: Polygon2D = $Sword
## 엉킴 경고: 칼의 테두리. 칼 뒤에 그려 칼의 상태 색이 그대로 보인다.
var _bind_warning: Line2D

## 칼끝의 지역 자리(손잡이 기준). 칼날이 가장 높은 점들의 가운데다.
var _tip_local := Vector2(0.0, -240.0)
## 보간하는 자리·기울기·칼날 상태와 따로 들고, 반작용은 그 위에 더한다(보간에 섞이지 않게).
var _pos := Vector2.ZERO
var _rot := 0.0
var _blade_rot := 0.0
var _blade_scale := 1.0
## 부위의 화면 자리와 상자(DuelScene이 예비 동안 넘긴다). 없으면 겨누지 않는다.
var _has_contact := false
var _contact := Vector2.ZERO
var _contact_rect := Rect2()
## 예비의 마지막 장의 겨눔(ATTACK을 받으면 hold로 옮긴다)과 회수 동안 쓰는 겨눔.
var _last_plan := {}
var _hold_plan := {}
var _recover_kind := Recover.TOUCH
var _rec_armed := false
var _rec_set := false
var _rec_start := 0.0
var _rec_elapsed := 0.0
var _cue_kind := Cue.NONE
var _cue_armed := false
var _cue_sx := 0
var _cue_close := false
var _cue_core0 := 0.0
var _cue_clock0 := 0.0
## 멈칫 동안 내가 맞았을 때의 떨림(계획 H03 결정 935): 화면 x(px). update_view가 멈춘 동안에도 자리에 곧바로 놓는다.
var _shake_x := 0.0


func _ready() -> void:
	# 엉킴 테두리가 바뀐 다각형을 따르게 맨 먼저 한다.
	var has_sword_art := _apply_sword_art()
	_tip_local = tip_of(_sword.polygon, _tip_local)
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
	# 그림의 자식이라 막기에서도 늘지 않고 그림을 따라간다. 좌표는 텍스처 화소다.
	var rim := Line2D.new()
	rim.name = "Rim"
	for point in sword_art.outline:
		rim.add_point(point - sword_art.joint)
	rim.closed = true
	rim.width = 2.0 * RIM_WIDTH / sword_art.units_per_px.x
	rim.default_color = OUTLINE_COLOR
	rim.joint_mode = Line2D.LINE_JOINT_ROUND
	rim.show_behind_parent = true
	art.add_child(rim)
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
	_has_contact = false
	_last_plan = {}
	_hold_plan = {}
	_rec_armed = false
	_rec_set = false
	_cue_kind = Cue.NONE
	_cue_armed = false
	_shake_x = 0.0


## 예비 동안 매 장 부위의 화면 자리와 상자를 받는다(계획 H03 결정 930).
func set_contact(point: Vector2, rect: Rect2) -> void:
	_has_contact = true
	_contact = point
	_contact_rect = rect


## 칼끝의 화면 자리와, 회수에 잡아 둔 접촉점(없으면 INF).
func tip_global() -> Vector2:
	return _sword.get_global_transform() * _tip_local


func held_contact() -> Vector2:
	return _hold_plan.get("contact", Vector2.INF)


## 멈칫 동안의 떨림(결정 935)을 곧바로 자리에 놓는다. 0이면 거둔다.
func set_shake(x: float) -> void:
	position.x += x - _shake_x
	_shake_x = x


## 소매 끝(손 그림의 아래 두 모서리)의 가장 높은 y. 그림이 없으면 INF.
func sleeve_top_at(pos: Vector2, rot: float) -> float:
	return sleeve_top(hand_art, pos, rot)


func on_event(ev: Dictionary) -> void:
	var type: StringName = ev.get("type", &"")
	if type == DuelRecord.ATTACK:
		_on_attack(ev)
	elif type == DuelRecord.STRIKE:
		_on_strike(ev)


## 결과로 회수의 그림을 고른다. 빠진 열쇠는 "닿음 아닌 쪽"(튕김)이다.
func _on_attack(ev: Dictionary) -> void:
	var result: int = ev.get("result", DT.AttackResult.BLOCKED)
	if bool(ev.get("dodged", false)):
		_recover_kind = Recover.DODGE
	elif result == DT.AttackResult.WHIFF:
		# 칼끝이 이미 접촉점에 가 있었는데 헛쳤다면 부위가 물러난 것이다: 닿을 자리를 지나친다.
		_recover_kind = Recover.SHORT if bool(_last_plan.get("short", true)) else Recover.DODGE
	elif result == DT.AttackResult.GRAZE or result == DT.AttackResult.HIT:
		_recover_kind = Recover.TOUCH
	else:
		_recover_kind = Recover.BOUNCE
	_hold_plan = _last_plan
	_last_plan = {}
	_rec_armed = true
	_rec_set = false


func _on_strike(ev: Dictionary) -> void:
	var closed := bool(ev.get("closed", false)) or bool(ev.get("bitten", false))
	var kind := Cue.NONE
	match int(ev.get("result", -1)):
		DT.StrikeResult.PARRIED:
			_flash_color = COLOR_PARRY
			_flash_until = _clock + 0.25
			kind = Cue.BLOCK if closed else Cue.PARRY
		DT.StrikeResult.BLOCKED:
			_flash_color = COLOR_BLOCK
			_flash_until = _clock + 0.12
			kind = Cue.BLOCK
		DT.StrikeResult.GRAZE, DT.StrikeResult.HIT:
			_flash_color = COLOR_GRAZED
			_flash_until = _clock + 0.25
			kind = Cue.HIT
	if kind == Cue.NONE:
		return
	var attack: Variant = ev.get("attack")
	_cue_sx = (attack as AttackData).direction - 1 if attack is AttackData else 0
	_cue_kind = kind
	_cue_armed = true


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
	# 공격 중에는 겨눈 자리를 곧바로 놓는다(지수 보간을 쓰지 않는다 — 결정 931).
	var pose := {}
	var rest := target
	if not attacking:
		_has_contact = false
		_last_plan = {}
		_hold_plan = {}
		_rec_set = false
	match state:
		DT.PlayerState.WINDUP:
			color = COLOR_WINDUP
			pose = _windup_pose(core, display_time, rest, tilt, viewport_size)
		DT.PlayerState.RECOVER:
			pose = _recover_pose(core, display_time, rest, tilt)
			color = COLOR_WINDUP if _rec_elapsed < YELLOW_HOLD else COLOR_RECOVER
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
	if pose.is_empty():
		_pos = _pos.lerp(target, smooth)
		_rot = lerpf(_rot, tilt, smooth)
		_blade_rot = lerpf(_blade_rot, 0.0, smooth)
		_blade_scale = lerpf(_blade_scale, 1.0, smooth)
	else:
		_pos = pose["pos"]
		_rot = pose["rot"]
		_blade_rot = pose["blade_rot"]
		_blade_scale = pose["blade_scale"]
	var cue := _cue_now(core, display_time)
	position = _pos + (cue["vec"] as Vector2) + Vector2(_shake_x, 0.0)
	rotation = _rot
	_sword.rotation = _blade_rot + float(cue["snap"])
	_sword.color = color
	_sword.scale = Vector2(blade_width, _blade_scale)
	if _sword_material != null:
		_sword_material.set_shader_parameter(&"tint_color", Vector3(color.r, color.g, color.b))
		# 그림은 늘이지 않는다: 판의 가로 배율을 되돌린다(결정 329).
		($Sword/Art as Sprite2D).scale.x = sword_art.units_per_px.x / blade_width
		_sword.self_modulate.a = GUARD_PLATE_ALPHA if state == DT.PlayerState.GUARD else 0.0
	# 엉킴 경고는 칼의 색을 덮지 않는다(막기·패리 창의 색이 그대로 보여야 한다). 테두리만 켠다.
	_bind_warning.visible = DuelHud.bind_warning_now(core)
	if _bind_warning.visible:
		_bind_warning.default_color.a = 0.55 + 0.45 * absf(sin(_clock * PI * BIND_BLINK_RATE))


## 예비의 한 장. 접촉점이 없으면 겨누지 않고 지금까지처럼 위로 LUNGE만큼 오른다.
func _windup_pose(core: DuelCore, display_time: float, rest: Vector2, tilt: float, view_size: Vector2) -> Dictionary:
	var span := maxf(core.player_state_end - core.player_state_start, 0.001)
	var elapsed := clampf(display_time - core.player_state_start, 0.0, span)
	if not _has_contact:
		return {"pos": rest + Vector2(0.0, -LUNGE * elapsed / span), "rot": tilt, "blade_rot": 0.0, "blade_scale": 1.0}
	var short := core.distance == DT.Distance.FAR and not core.attack_lunge
	var plan := make_plan(rest, tilt, _tip_local, _contact, _contact_rect, short, core.attack_direction, view_size, hand_art)
	_last_plan = plan
	var at := attack_tip(elapsed, span, plan)
	return pose_from(at["hand"], rho_at(plan, at["frac"]), _tip_local, at["tip"])


## 회수의 한 장. q는 ATTACK 뒤 첫 갱신의 display_time에서 잰다(결정 928): 이벤트 없이 RECOVER가 됐으면 코어의 시작에서.
func _recover_pose(core: DuelCore, display_time: float, rest: Vector2, tilt: float) -> Dictionary:
	if _rec_armed:
		_rec_armed = false
		_rec_set = true
		_rec_start = display_time
	var start := _rec_start if _rec_set else core.player_state_start
	_rec_elapsed = maxf(display_time - start, 0.0)
	var q := clampf(_rec_elapsed / maxf(core.player_state_end - start, 0.001), 0.0, 1.0)
	if _hold_plan.is_empty():
		return {"pos": rest + Vector2(0.0, -LUNGE * (1.0 - q)), "rot": tilt, "blade_rot": 0.0, "blade_scale": 1.0}
	var at := recover_tip(_recover_kind, q, _hold_plan)
	return pose_from(at["hand"], rho_at(_hold_plan, at["frac"]), _tip_local, at["tip"])


## 막기·패리·맞음의 반작용(결정 933). 시작은 이벤트 뒤 첫 갱신이고 코어 시각과 _clock 가운데 더 흐른 쪽으로 센다.
func _cue_now(core: DuelCore, display_time: float) -> Dictionary:
	var none := {"vec": Vector2.ZERO, "snap": 0.0}
	if _cue_kind == Cue.NONE:
		return none
	if _cue_armed:
		_cue_armed = false
		_cue_core0 = display_time
		_cue_clock0 = _clock
		_cue_close = core.distance == DT.Distance.CLOSE
	var k := maxf(display_time - _cue_core0, _clock - _cue_clock0) / CUE_TIME[_cue_kind]
	if k >= 1.0:
		_cue_kind = Cue.NONE
		return none
	return cue_offset(_cue_kind, _cue_sx, _cue_close, k)


## 칼날 다각형에서 가장 높은 점들의 가운데(손잡이 기준).
static func tip_of(polygon: PackedVector2Array, fallback: Vector2) -> Vector2:
	if polygon.is_empty():
		return fallback
	var top := INF
	for point: Vector2 in polygon:
		top = minf(top, point.y)
	var sum := 0.0
	var count := 0
	for point: Vector2 in polygon:
		if point.y <= top + 2.0:
			sum += point.x
			count += 1
	return Vector2(sum / count, top)


## 손 그림의 아래 두 모서리의 가장 높은 y(T74와 같은 셈). 그림이 없으면 INF.
static func sleeve_top(art: PartArt, pos: Vector2, rot: float) -> float:
	if art == null or art.texture == null:
		return INF
	var size := art.texture.get_size()
	var top := INF
	for corner: Vector2 in [Vector2(0.0, size.y), size]:
		top = minf(top, pos.y + ((corner - art.joint) * art.units_per_px).rotated(rot).y)
	return top


static func ease_out(k: float, power: float) -> float:
	return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), power)


## 손에서 칼끝으로 닿게 하는 (뿌리와 칼날의 합친 각, 칼날의 세로 배율). 배율은 BLADE_SCALE_* 안으로 가둔다.
static func blade_for(hand: Vector2, tip_local: Vector2, tip: Vector2) -> Vector2:
	var offset := tip - hand
	var length := offset.length()
	if length < 1.0 or absf(tip_local.y) < 1.0:
		return Vector2(0.0, 1.0)
	var scale_y := clampf(sqrt(maxf(length * length - tip_local.x * tip_local.x, 0.0)) / absf(tip_local.y), BLADE_SCALE_MIN, BLADE_SCALE_MAX)
	var blade := Vector2(tip_local.x, tip_local.y * scale_y)
	return Vector2(atan2(offset.x, -offset.y) - atan2(blade.x, -blade.y), scale_y)


static func pose_from(hand: Vector2, rho: float, tip_local: Vector2, tip: Vector2) -> Dictionary:
	var blade := blade_for(hand, tip_local, tip)
	return {"pos": hand, "rot": rho, "blade_rot": wrapf(blade.x - rho, -PI, PI), "blade_scale": blade.y}


static func rho_at(plan: Dictionary, frac: float) -> float:
	return lerpf(plan["tilt"], plan["rho1"], frac)


## 닿지 않는 거리의 목표: 접촉점에서 손 쪽으로 물러나 부위의 상자(여유 포함) 밖에 선다(결정 930).
static func unreachable_target(contact: Vector2, hand: Vector2, rect: Rect2) -> Vector2:
	var away := hand - contact
	var dir := away.normalized() if away.length() > 0.001 else Vector2.DOWN
	var point := contact + dir * BACK_OFF
	var guard := 0
	while rect.grow(RECT_PAD).has_point(point) and guard < 60:
		point += dir * BACK_STEP
		guard += 1
	return point


## 손의 끝 자리와 뿌리의 기울기(결정 930): 손이 먼저 자리를 잡고, 뿌리는 소매가 허락하는 만큼만 돌고, 남은 각은 칼날이 맡는다.
static func solve_reach(h0: Vector2, tilt: float, tip_local: Vector2, target: Vector2, view_size: Vector2, art: PartArt) -> Dictionary:
	var blade := maxf(-tip_local.y, 1.0)
	var away := h0 - target
	var dir := away.normalized() if away.length() > 0.001 else Vector2.DOWN
	var h1 := target + dir * clampf(away.length(), blade * REACH_MIN, blade * REACH_MAX)
	h1.x = clampf(h1.x, h0.x - HAND_BOX_X, h0.x + HAND_BOX_X)
	h1.y = clampf(h1.y, h0.y - LUNGE, h0.y + HAND_BOX_DOWN)
	var delta := angle_difference(tilt, blade_for(h1, tip_local, target).x)
	var share := 1.0
	var floor_y := view_size.y + SLEEVE_MARGIN
	if art == null or art.texture == null:
		share = minf(1.0, TURN_LIMIT / maxf(absf(delta), 0.0001))
	elif sleeve_top(art, h1, tilt + delta) < floor_y:
		var low := 0.0
		var high := 1.0
		for i in 6:
			var mid := (low + high) * 0.5
			if sleeve_top(art, h1, tilt + delta * mid) >= floor_y:
				low = mid
			else:
				high = mid
		share = low
	return {"h1": h1, "rho1": tilt + delta * share}


## 겨눔점 G에서 칼날이 LIFT_BLADE 이상 길게 서도록 손을 G의 반대로 내린 자리. 쉬는 손이 이미 그만큼 멀면 그 자리 그대로다.
static func lift_hand_for(pull_hand: Vector2, guide: Vector2, tip_local: Vector2) -> Vector2:
	var want := absf(tip_local.y) * LIFT_BLADE
	if pull_hand.distance_to(guide) >= want:
		return pull_hand
	var dir := (pull_hand - guide).normalized() if pull_hand.distance_to(guide) > 0.001 else Vector2.DOWN
	var hand := guide + dir * want
	hand.y = minf(hand.y, pull_hand.y + LIFT_DOWN)
	return hand


## 한 번의 공격의 겨눔: 목표 T, 손의 끝 자리, 겨눔점 G, 온 길의 방향(결정 930·931). 예비 동안 매 장 새로 짠다.
static func make_plan(h0: Vector2, tilt: float, tip_local: Vector2, contact: Vector2, rect: Rect2, short: bool,
		direction: int, view_size: Vector2, art: PartArt) -> Dictionary:
	var target := unreachable_target(contact, h0, rect) if short else contact
	var reach := solve_reach(h0, tilt, tip_local, target, view_size, art)
	var tip_rest := h0 + tip_local.rotated(tilt)
	var thrust := direction == DT.Direction.CENTER
	var side := direction - 1
	var pull_tip := tip_rest + (h0 - tip_rest).normalized() * PULL_TIP
	# 쉬는 칼끝이 부위 위에 겹쳐 있어도 뻗음이 보이게, 겨눔점은 온 길 뒤로 MIN_THRUST_TRAVEL 이상 둔다.
	var back := (h0 - target).normalized() if (h0 - target).length() > 0.001 else Vector2.DOWN
	var guide := target + back * maxf(MIN_THRUST_TRAVEL, (1.0 - GUIDE_RATIO) * pull_tip.distance_to(target))
	var in_dir := target - guide
	if not thrust:
		guide = target + Vector2(side * GUIDE_OUT.x, GUIDE_OUT.y)
		guide = Vector2(clampf(guide.x, SCREEN_PAD, view_size.x - SCREEN_PAD), clampf(guide.y, SCREEN_PAD, view_size.y - SCREEN_PAD))
		in_dir = target - ((guide + target) * 0.5 + Vector2(0.0, -ARC_LIFT))
	var lift_hand := lift_hand_for(h0 + Vector2(0.0, PULL_HAND), guide, tip_local)
	return {
		"contact": contact, "target": target, "rect": rect, "short": short, "thrust": thrust, "side": side,
		"h0": h0, "tilt": tilt, "tip_rest": tip_rest, "pull_tip": pull_tip, "guide": guide,
		"h1": reach["h1"], "rho1": reach["rho1"], "lift_hand": lift_hand,
		"in_dir": in_dir.normalized() if in_dir.length() > 0.001 else Vector2.UP,
	}


## 예비의 e초째(총 w초)의 칼끝·손과 뿌리가 돈 비율. 당김 → 들기 → 뻗음(결정 931). 끝에서 칼끝 = 목표.
static func attack_tip(e: float, w: float, plan: Dictionary) -> Dictionary:
	var h0: Vector2 = plan["h0"]
	var h1: Vector2 = plan["h1"]
	var tip_rest: Vector2 = plan["tip_rest"]
	var pull_tip: Vector2 = plan["pull_tip"]
	var guide: Vector2 = plan["guide"]
	var target: Vector2 = plan["target"]
	var pull := minf(PULL_TIME, 0.25 * w)
	var strike := minf(STRIKE_TIME, 0.45 * w)
	var raise := w - pull - strike
	var pull_hand := h0 + Vector2(0.0, PULL_HAND)
	if e <= pull:
		var eased := ease_out(e / pull, 2.0)
		return {"tip": tip_rest.lerp(pull_tip, eased), "hand": h0.lerp(pull_hand, eased), "frac": 0.0}
	var frac := clampf((e - pull) / (raise + strike), 0.0, 1.0)
	var lift_hand: Vector2 = plan["lift_hand"]
	if e <= pull + raise:
		var rise := (e - pull) / raise
		return {"tip": pull_tip.lerp(guide, rise), "hand": pull_hand.lerp(lift_hand, rise), "frac": frac}
	var run := clampf((e - pull - raise) / strike, 0.0, 1.0)
	var hand := lift_hand.lerp(h1, run)
	run *= run
	var tip := guide.lerp(target, run)
	if not plan["thrust"]:
		var ctrl := (guide + target) * 0.5 + Vector2(0.0, -ARC_LIFT)
		tip = guide.lerp(ctrl, run).lerp(ctrl.lerp(target, run), run)
	return {"tip": tip, "hand": hand, "frac": frac}


## 회수의 q(0~1)에서의 칼끝·손과 뿌리가 되돌아온 비율의 나머지(결정 932). 닿음·튕김·피함·못 미침.
static func recover_tip(kind: int, q: float, plan: Dictionary) -> Dictionary:
	var h0: Vector2 = plan["h0"]
	var h1: Vector2 = plan["h1"]
	var tip_rest: Vector2 = plan["tip_rest"]
	var target: Vector2 = plan["target"]
	var in_dir: Vector2 = plan["in_dir"]
	var side: int = plan["side"]
	var back := -in_dir
	var out_end := 0.25
	var out_tip := target + back * 22.0
	var out_hand := h1 + Vector2(0.0, 6.0)
	match kind:
		Recover.BOUNCE:
			var perp := Vector2(-in_dir.y, in_dir.x) * (-1.0 if side < 0 else 1.0)
			out_end = 0.15
			out_tip = target + back * 32.0 + perp * 30.0
			out_hand = h1 + Vector2(0.0, 4.0)
		Recover.DODGE:
			out_end = 0.35
			out_tip = target + in_dir.rotated(-side * 0.2618) * 60.0
			out_hand = h1
		Recover.SHORT:
			out_end = 0.35
			var rect: Rect2 = plan["rect"]
			var reach := 0.0
			while reach + 3.0 <= 30.0 and not rect.grow(RECT_PAD).has_point(target + in_dir * (reach + 3.0)):
				reach += 3.0
			out_tip = target + in_dir * reach
			out_hand = h1
	var tip: Vector2
	var hand: Vector2
	var back_share := 0.0
	var wobble := 0.0
	if q <= out_end:
		var eased := ease_out(q / out_end, 2.0)
		tip = target.lerp(out_tip, eased)
		hand = h1.lerp(out_hand, eased)
	else:
		var run := (q - out_end) / (1.0 - out_end)
		back_share = ease_out(run, 3.0)
		tip = out_tip.lerp(tip_rest, back_share)
		hand = out_hand.lerp(h0, back_share)
		if kind == Recover.BOUNCE:
			wobble = 0.1222 * (1.0 - run) * sin(4.0 * PI * run)
	if wobble != 0.0:
		tip = hand + (tip - hand).rotated(wobble)
	return {"tip": tip, "hand": hand, "frac": 1.0 - back_share}


static func cue_pulse(k: float) -> float:
	if k < 0.25:
		return k / 0.25
	return pow(1.0 - (k - 0.25) / 0.75, 2.0)


## 막기(밀림)·패리(쳐 나감)·맞음(내려앉음)의 손의 이동과 칼날의 스냅. sx는 타격이 온 쪽(왼쪽 −1, 가운데 0, 오른쪽 +1).
static func cue_offset(kind: int, sx: int, close: bool, k: float) -> Dictionary:
	var pulse := cue_pulse(k)
	var vec := Vector2.ZERO
	var snap := 0.0
	match kind:
		Cue.BLOCK:
			vec = Vector2(-sx * 8.5, 8.5) if sx != 0 else Vector2(0.0, 12.0)
			if close:
				vec *= 17.0 / 12.0
		Cue.PARRY:
			vec = Vector2(sx * 11.3, -11.3) if sx != 0 else Vector2(0.0, -16.0)
			snap = deg_to_rad(6.0) * (sx if sx != 0 else 1)
		Cue.HIT:
			vec = Vector2(-sx * 10.0, 26.0)
	return {"vec": vec * pulse, "snap": snap * pulse}
