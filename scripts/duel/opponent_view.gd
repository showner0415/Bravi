class_name OpponentView
extends Node2D
## 도형으로 된 상대. 표시만 한다(판정은 DuelCore).
##
## 파츠 노드의 이름·계층·원점은 이후 아트와 리깅의 기준이다 (docs/DECISIONS.md 결정 12):
##   Legs / Torso > Head > Hat / Torso > Arm > Hand > Sword. 원점은 관절(골반, 목, 어깨, 손목).
## 이 스크립트는 파츠를 Node2D 이상의 타입으로 가정하지 않는다(나중에 Bone2D로 바꿀 수 있게).

const DT := preload("res://scripts/duel/duel_types.gd")

const PART_PATHS := {
	DT.Part.LEGS: ^"Legs",
	DT.Part.TORSO: ^"Torso",
	DT.Part.HEAD: ^"Torso/Head",
	DT.Part.HAT: ^"Torso/Head/Hat",
	DT.Part.SWORD_ARM: ^"Torso/Arm",
	DT.Part.SWORD_HAND: ^"Torso/Arm/Hand",
}
## 상태 색을 입히는 파츠. 모자와 칼은 제 색을 유지한다.
const TINTED: Array[int] = [DT.Part.LEGS, DT.Part.TORSO, DT.Part.HEAD, DT.Part.SWORD_ARM, DT.Part.SWORD_HAND]

const COLOR_STRIKE := Color(0.95, 0.2, 0.2)
const COLOR_RECOVERY := Color(0.3, 0.5, 0.95)
const COLOR_STAGGER := Color(0.65, 0.35, 0.85)
const COLOR_TOUCHED := Color(1.0, 1.0, 1.0)
const TINT_AMOUNT := 0.8
const FLASH_TIME := 0.1
const TOUCH_FLASH_TIME := 0.18
const DEFLECT_TEXT_TIME := 0.6
## 머리를 노린 공격을 피할 때 고개를 젖히는 시간(초)과 각도.
const DODGE_TIME := 0.3
const DODGE_HEAD_ROTATION := -0.35

## 포즈 좌표의 기준: 가슴 중앙의 어깨 높이.
const CHEST := Vector2(0, -180)
const SHOULDER_X := 65.0
const REST_SWORD_ROTATION := -25.0
## 타격 지점(방향별): 팔 위치(CHEST 기준)와 칼 회전(도). "도착 = 타격".
const STRIKE_OFFSET: Array[Vector2] = [Vector2(-120, 40), Vector2(0, 60), Vector2(120, 40)]
const STRIKE_ROTATION: Array[float] = [-120.0, 180.0, 120.0]
const STAGGER_ARM_DROP := Vector2(0, 50)
const STAGGER_SWORD_ROTATION := 165.0
const STAGGER_HEAD_ROTATION := 0.4
## 방심한 대기 포즈: 팔은 그대로 두고 칼끝만 내린다(무너짐과 헷갈리지 않게 팔은 떨어뜨리지 않는다).
const COMPLACENT_SWORD_ROTATION := -140.0
const COMPLACENT_TEXT := "방심"

## 간격별 크기와 세로 이동(표시만).
const DISTANCE_SCALE: Array[float] = [0.55, 0.85, 1.1]
const DISTANCE_SHIFT: Array[float] = [-40.0, 0.0, 30.0]

## 줄어드는 고리: 일정한 속도(px/초)로 줄어 0이 되는 순간이 타격이다.
## 패리 창에 해당하는 고정 띠(반지름 = 속도 x 패리 창)를 예비 동작 시작부터 그려 둔다.
## 위치는 상대 기준 화면 좌표(간격에 따라 커지거나 움직이지 않는다).
const RING_SPEED := 240.0
const RING_POSITION: Array[Vector2] = [Vector2(-270, -150), Vector2(0, -140), Vector2(270, -150)]
## 상태 글자(공격 이름, 빈틈, 무너짐)의 화면 세로 위치. 자세 칸 바로 아래.
const STATE_LABEL_Y := 62.0

## 교전 거리 기준 위치. 결투 씬이 화면 크기에 맞춰 정한다.
var anchor := Vector2.ZERO

var _sword_side: int = DT.Direction.LEFT
var _parry_window := 0.18
var _base_colors := {}
var _outlines := {}
var _target_part := -1
## 번쩍임용 시계(실제 시간). 결투가 끝나 코어 시계가 멈춰도 번쩍임은 사라진다.
var _clock := 0.0
var _flash_until := -INF
var _touched_part := -1
var _touched_until := -INF
## 섣부른 공격을 받아넘겼을 때("받아넘김")나 버티기가 됐을 때("밀어붙임") 상태 글자 자리에 잠깐 띄우는 글자.
var _deflect_text := ""
var _deflect_until := -INF
var _dodge_until := -INF

var _ring_active := false
var _ring_remaining := 0.0
## 다음 갱신에서 크기와 위치를 보간 없이 맞춘다(시작, 다시 하기).
var _snap := true

@onready var _head: Node2D = $Torso/Head
@onready var _hat: CanvasItem = $Torso/Head/Hat
@onready var _arm: Node2D = $Torso/Arm
@onready var _sword: Node2D = $Torso/Arm/Hand/Sword
@onready var _feather: CanvasItem = $Torso/Head/Hat/Feather
@onready var _state_label: Label = $StateLabel
var _ring: Node2D


func _ready() -> void:
	for part in PART_PATHS:
		var shape := _shape_of(part)
		if shape == null:
			continue
		_base_colors[part] = shape.color
		# 조준 강조용 테두리. 파츠 아래에 붙여 파츠와 함께 움직이게 한다.
		var outline := Line2D.new()
		outline.name = "Outline"
		outline.points = shape.polygon
		outline.closed = true
		outline.width = 5.0
		outline.default_color = Color(1.0, 1.0, 0.4)
		outline.visible = false
		get_node(PART_PATHS[part]).add_child(outline)
		_outlines[part] = outline
	_ring = Node2D.new()
	_ring.name = "Ring"
	# 고리와 상태 글자는 내 칼보다 위에 그린다.
	_ring.z_index = 10
	add_child(_ring)
	_ring.draw.connect(_draw_ring)
	_state_label.z_index = 9


## has_hat: 이 판의 상대가 모자를 쓰는가. 모자는 고정 부위가 아니라 의뢰가 씌운다.
## 쓰지 않으면 모자 파츠를 숨긴다(노드는 그대로 둔다. 자식인 깃털과 글자도 함께 숨는다).
func setup(opponent: OpponentData, weapon: WeaponData, has_hat := false) -> void:
	_sword_side = opponent.sword_side
	_parry_window = weapon.parry_window
	_flash_until = -INF
	_touched_until = -INF
	_deflect_until = -INF
	_dodge_until = -INF
	_ring_active = false
	_snap = true
	_hat.visible = has_hat
	_feather.visible = true
	_head.rotation = 0.0
	_arm.position = _shoulder()
	_sword.rotation_degrees = REST_SWORD_ROTATION
	if _ring != null:
		_ring.queue_redraw()


## 조준 중인 부위의 테두리를 강조한다. -1이면 강조 없음.
func set_target(part: int) -> void:
	if part == _target_part:
		return
	_target_part = part
	for p in _outlines:
		(_outlines[p] as Line2D).visible = (p == part)


func on_event(ev: Dictionary) -> void:
	match ev["type"]:
		DuelRecord.STRIKE:
			_flash_until = _clock + FLASH_TIME
			if ev["braced"]:
				# 들고만 있던 막기로 표시된 공격을 버텼다: 빈틈이 없다는 것을 상태 글자 자리에 잠깐 띄운다.
				_deflect_text = "밀어붙임"
				_deflect_until = _clock + DEFLECT_TEXT_TIME
		DuelRecord.ATTACK:
			var result: int = ev["result"]
			if result == DT.AttackResult.GRAZE or result == DT.AttackResult.HIT:
				_touched_part = ev["part"]
				_touched_until = _clock + TOUCH_FLASH_TIME
			if result == DT.AttackResult.HIT and ev["part"] == DT.Part.HAT:
				_feather.visible = false
			if ev["dodged"]:
				# 얼굴을 지킨다: 고개를 젖혀 피한다.
				_dodge_until = _clock + DODGE_TIME
			if result == DT.AttackResult.BLOCKED and ev["rash"]:
				_deflect_text = "받아넘김"
				if ev["posture_gain"] > 0:
					_deflect_text += " +%d" % ev["posture_gain"]
				_deflect_until = _clock + DEFLECT_TEXT_TIME


## display_time은 표시용 시각(코어 시계 + 물리 보간). delta는 부드러운 이동과 번쩍임에만 쓴다.
func update_view(core: DuelCore, display_time: float, delta: float) -> void:
	var brain := core.brain
	_clock += delta
	var smooth := 1.0 - exp(-14.0 * delta) if delta > 0.0 else 0.0
	if _snap:
		smooth = 1.0
		_snap = false

	# --- 간격: 크기와 세로 위치 (표시만 보간)
	var target_scale := DISTANCE_SCALE[core.distance]
	var target_pos := anchor + Vector2(0, DISTANCE_SHIFT[core.distance])
	scale = scale.lerp(Vector2.ONE * target_scale, smooth)
	position = position.lerp(target_pos, smooth)
	var inverse := 1.0 / maxf(scale.x, 0.01)

	# --- 상태별 포즈, 색, 글자
	var tint: Variant = null
	var text := ""
	var arm_target := _shoulder()
	var sword_target := REST_SWORD_ROTATION
	var head_target := 0.0
	var exact := false
	_ring_active = false
	# 머리를 지키는 상대의 머리는 크게 열린 회수에서만 빈틈 색으로 물든다("파랗게 물든 부위가 열린 부위").
	var head_closed := false

	# 방심했고 대기 중이면 칼끝을 내린다. 예비 동작·회수·무너짐 중에는 그 상태의 표시가 우선이다.
	var complacent := brain.state == DT.OpponentState.IDLE and core.has_lunge() and core.complacency() >= 1.0
	if complacent:
		sword_target = COMPLACENT_SWORD_ROTATION

	match brain.state:
		DT.OpponentState.TELL:
			var atk := brain.current_attack
			var progress := clampf((display_time - brain.state_start) / maxf(brain.tell_duration, 0.001), 0.0, 1.0)
			# 팔과 칼이 예비 시간 전체에 걸쳐 포즈에서 타격 지점으로 움직인다. 도착 = 타격.
			arm_target = CHEST + atk.pose_arm_offset.lerp(STRIKE_OFFSET[atk.direction], progress)
			sword_target = lerpf(atk.pose_sword_rotation, STRIKE_ROTATION[atk.direction], progress)
			exact = true
			tint = atk.pose_color
			text = atk.attack_name + ("!!" if atk.is_big else "")
			# 표시된 공격은 예비 동작 내내, 지금의 막기가 버티기만 되는지 받아내는지 알려 준다.
			if atk.needs_raised_guard and core.player_state == DT.PlayerState.GUARD:
				text += "\n" + ("막기를 뗐다 다시 올려라" if core.would_brace_now() else "받아낼 준비")
			_ring_active = true
			_ring_remaining = maxf(brain.state_end - display_time, 0.0)
			_ring.position = RING_POSITION[atk.direction] * inverse
		DT.OpponentState.RECOVERY:
			var atk := brain.current_attack
			if atk != null:
				arm_target = CHEST + STRIKE_OFFSET[atk.direction]
				sword_target = STRIKE_ROTATION[atk.direction]
			tint = COLOR_RECOVERY
			text = "빈틈"
			if core.opponent_data.guards_head:
				if brain.wide_open:
					text = "크게 열림!"
				else:
					head_closed = true
		DT.OpponentState.STAGGER:
			arm_target = _shoulder() + STAGGER_ARM_DROP
			sword_target = STAGGER_SWORD_ROTATION
			head_target = STAGGER_HEAD_ROTATION
			tint = COLOR_STAGGER
			text = "무너짐!"

	if exact:
		_arm.position = arm_target
		_sword.rotation_degrees = sword_target
	else:
		_arm.position = _arm.position.lerp(arm_target, smooth)
		_sword.rotation_degrees = lerpf(_sword.rotation_degrees, sword_target, smooth)
	if _clock < _dodge_until:
		head_target = DODGE_HEAD_ROTATION
	_head.rotation = lerpf(_head.rotation, head_target, smooth)

	# --- 색: 상태 색, 타격 순간의 빨강 번쩍임, 닿은 부위의 흰 번쩍임
	if _clock < _flash_until:
		tint = COLOR_STRIKE
		head_closed = false
	for part in PART_PATHS:
		var shape := _shape_of(part)
		if shape == null:
			continue
		var base: Color = _base_colors[part]
		if part == _touched_part and _clock < _touched_until:
			shape.color = COLOR_TOUCHED
		elif part == DT.Part.HEAD and head_closed:
			shape.color = base
		elif tint != null and TINTED.has(part):
			shape.color = base.lerp(tint as Color, TINT_AMOUNT)
		else:
			shape.color = base

	# 받아넘김 글자는 상태 글자가 비어 있을 때만 보인다(예비 동작에 들어가면 공격 이름이 우선).
	if text == "" and _clock < _deflect_until:
		text = _deflect_text
	# 방심: 대기 중이고 다른 글자가 없을 때만 보인다. 빈틈의 색은 쓰지 않는다(파란색은 "보통 공격이 닿는다"는 뜻이다).
	if text == "" and complacent:
		text = COMPLACENT_TEXT

	# --- 상태 글자와 고리는 간격에 따라 커지거나 움직이지 않게 한다.
	_state_label.text = text
	_state_label.scale = Vector2.ONE * inverse
	_state_label.position = (Vector2(anchor.x - _state_label.size.x * 0.5, STATE_LABEL_Y) - position) * inverse
	_ring.scale = Vector2.ONE * inverse
	_ring.queue_redraw()


func _shoulder() -> Vector2:
	var x := -SHOULDER_X if _sword_side == DT.Direction.LEFT else SHOULDER_X
	return CHEST + Vector2(x, 0)


func _shape_of(part: int) -> Polygon2D:
	if not PART_PATHS.has(part):
		return null
	return get_node(PART_PATHS[part]).get_node_or_null(^"Shape") as Polygon2D


func _draw_ring() -> void:
	if not _ring_active:
		return
	var band := RING_SPEED * _parry_window
	# 고정 띠(목표 고리): 줄어드는 고리가 이 안에 들어와 있을 때 새로 누르면 패리다.
	_ring.draw_circle(Vector2.ZERO, band, Color(0.3, 1.0, 0.5, 0.22))
	_ring.draw_arc(Vector2.ZERO, band, 0.0, TAU, 48, Color(0.3, 1.0, 0.5, 0.95), 3.0)
	# 줄어드는 고리: 0이 되는 순간이 타격.
	var radius := _ring_remaining * RING_SPEED
	if radius > 1.0:
		_ring.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.95), 5.0)
	_ring.draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 1.0, 0.9))
