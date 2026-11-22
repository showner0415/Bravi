class_name OpponentView
extends Node2D
## 파츠 그림으로 된 상대. 표시만 한다(판정은 DuelCore).
##
## 파츠 노드의 이름·계층·원점은 아트와 리깅의 기준이다 (docs/DECISIONS.md 결정 12):
##   Legs / Torso > Head > Hat / Torso > Arm > Hand > Sword. 원점은 관절(골반, 목, 어깨, 손목).
## 그림은 파츠마다 첫 자식 Sprite2D "Art"에 건다(결정 255). 포즈는 관절에서 돌린다(결정 257·258).
## 이 스크립트는 파츠를 Node2D 이상의 타입으로 가정하지 않는다(나중에 Bone2D로 바꿀 수 있게).

const DT := preload("res://scripts/duel/duel_types.gd")
const PART_SHADER := preload("res://scenes/duel/opponent_part.gdshader")

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
const COMPLACENT_TEXT := "방심"
## 조준 테두리의 굵기(파츠 단위). 텍스처 화소로는 이 값 ÷ 단위/화소.
const OUTLINE_UNITS := 5.0
const OUTLINE_COLOR := Color(1.0, 1.0, 0.4)

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
## 파츠 → 그 파츠 Art의 재질. 칼에는 재질을 두지 않는다(조준할 수 없고 상태 색을 받지 않는다, 결정 241).
var _materials := {}
var _feather_material: ShaderMaterial
var _target_part := -1
var _art: OpponentArt
var _head_art: PartArt
var _shoulder_base := Vector2(-65, -180)
## 화면의 포즈와, 지금 바뀜의 시작(결정 258). _pose는 늘 새것으로 바꾸고 제자리에서 고치지 않는다.
var _pose := PoseData.new()
var _blend_from := PoseData.new()
## (상태, 방심, 시작 시각). 바뀌면 그때 화면의 포즈에서 새로 섞는다.
var _phase_key := Vector3(-1, 0, 0)
var _phase_start := 0.0
var _dodge_k := 0.0
var _dodge_time := 0.3
var _dodge_head_deg := -20.1
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

@onready var _torso: Node2D = $Torso
@onready var _head: Node2D = $Torso/Head
@onready var _hat: Node2D = $Torso/Head/Hat
@onready var _arm: Node2D = $Torso/Arm
@onready var _hand: Node2D = $Torso/Arm/Hand
@onready var _sword: Node2D = $Torso/Arm/Hand/Sword
@onready var _feather: Sprite2D = $Torso/Head/Hat/Feather
@onready var _state_label: Label = $StateLabel
var _ring: Node2D


func _ready() -> void:
	# 유니폼이 파츠마다 다르므로 재질을 따로 만든다.
	for part in PART_PATHS:
		var mat := _new_material()
		_art_of(part).material = mat
		_materials[part] = mat
	_feather_material = _new_material()
	_feather.material = _feather_material
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
	_dodge_time = opponent.dodge_time
	_dodge_head_deg = opponent.dodge_head_deg
	_flash_until = -INF
	_touched_until = -INF
	_deflect_until = -INF
	_dodge_until = -INF
	_ring_active = false
	_snap = true
	_dodge_k = 0.0
	_hat.visible = has_hat
	_feather.visible = true
	_apply_art(opponent.art)
	if _sword_side != DT.Direction.LEFT:
		# 그림과 포즈는 칼 팔이 왼쪽인 상대만 있다(결정 263, BACKLOG 029-1). 어깨 x만 뒤집는다.
		push_warning("OpponentView: 칼 팔이 오른쪽인 상대의 그림·포즈는 아직 없다 (%s)" % opponent.display_name)
		_shoulder_base.x = -_shoulder_base.x
	_pose = _rest(opponent.idle_pose)
	_blend_from = _pose
	_phase_key = Vector3(-1, 0, 0)
	_phase_start = 0.0
	_apply_pose(_pose, 0.0)
	if _ring != null:
		_ring.queue_redraw()


## 조준 중인 부위의 테두리를 강조한다. -1이면 강조 없음. 모자를 노리면 깃털도 켠다.
func set_target(part: int) -> void:
	if part == _target_part:
		return
	_target_part = part
	for p in _materials:
		(_materials[p] as ShaderMaterial).set_shader_parameter(&"outline_on", p == part)
	_feather_material.set_shader_parameter(&"outline_on", part == DT.Part.HAT)


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
				_dodge_until = _clock + _dodge_time
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

	# --- 상태별 색과 글자. 포즈는 _pose_for가 정한다(결정 258).
	var tint: Variant = null
	var text := ""
	_ring_active = false
	# 머리를 지키는 상대의 머리는 크게 열린 회수에서만 빈틈 색으로 물든다("파랗게 물든 부위가 열린 부위").
	var head_closed := false
	var head_art: PartArt = _art.head if _art != null else null

	# 방심했고 대기 중이면 칼끝을 내린다. 예비 동작·회수·무너짐 중에는 그 상태의 표시가 우선이다.
	var complacent := brain.state == DT.OpponentState.IDLE and core.has_lunge() and core.complacency() >= 1.0

	match brain.state:
		DT.OpponentState.TELL:
			var atk := brain.current_attack
			tint = atk.pose_color
			text = atk.attack_name + ("!!" if atk.is_big else "")
			# 표시된 공격은 예비 동작 내내, 지금의 막기가 버티기만 되는지 받아내는지 알려 준다.
			if atk.needs_raised_guard and core.player_state == DT.PlayerState.GUARD:
				text += "\n" + ("막기를 뗐다 다시 올려라" if core.would_brace_now() else "받아낼 준비")
			_ring_active = true
			_ring_remaining = maxf(brain.state_end - display_time, 0.0)
			_ring.position = RING_POSITION[atk.direction] * inverse
		DT.OpponentState.RECOVERY:
			tint = COLOR_RECOVERY
			text = "빈틈"
			if _art != null:
				head_art = _art.head_oops
			if core.opponent_data.guards_head:
				if brain.wide_open:
					text = "크게 열림!"
				else:
					head_closed = true
		DT.OpponentState.STAGGER:
			tint = COLOR_STAGGER
			text = "무너짐!"
			if _art != null:
				head_art = _art.head_dizzy

	# 피하기는 회수 중에 일어나지만 얼굴을 지켜 낸 것이라 미소 머리다(결정 260).
	if _clock < _dodge_until and _art != null:
		head_art = _art.head
	_pose = _pose_for(core, display_time, complacent)
	# 피하기의 고개는 지금처럼 부드럽게 젖혔다 돌아온다(포즈의 고개 위에 얹는다).
	_dodge_k = lerpf(_dodge_k, 1.0 if _clock < _dodge_until else 0.0, smooth)
	_apply_pose(_pose, _dodge_k)
	if _art != null:
		_set_head(head_art)

	# --- 색: 상태 색, 타격 순간의 빨강 번쩍임, 닿은 부위의 흰 번쩍임
	if _clock < _flash_until:
		tint = COLOR_STRIKE
		head_closed = false
	_apply_colors(tint, head_closed)

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


## 지금 화면에 둘 포즈. 바뀜의 시작 시각은 알아챈 프레임이 아니라 데이터에서 센다(결정 258, 계획 029 T1).
func _pose_for(core: DuelCore, display_time: float, complacent: bool) -> PoseData:
	var brain := core.brain
	var opp := core.opponent_data
	var start := brain.state_start
	if brain.state == DT.OpponentState.IDLE:
		# 방심은 상태가 아니라 시각의 함수다: 들 때는 게이지가 1에 닿은 시각, 풀릴 때는 경계를 다시 세운 시각.
		if complacent:
			start = maxf(brain.state_start, brain.alert_since + opp.complacent_time)
		else:
			start = maxf(brain.state_start, brain.alert_since)
	var key := Vector3(brain.state, 1.0 if complacent else 0.0, start)
	if key != _phase_key:
		_phase_key = key
		_phase_start = start
		_blend_from = _pose
	var atk := brain.current_attack
	if brain.state == DT.OpponentState.TELL and atk != null:
		var p := (display_time - start) / maxf(brain.tell_duration, 0.001)
		return OpponentMotion.tell_pose(atk, _blend_from, p, brain.tell_duration, _parry_window, opp)
	if brain.state == DT.OpponentState.RECOVERY and atk != null:
		var q := (display_time - start) / maxf(brain.state_end - start, 0.001)
		return OpponentMotion.recover_pose(atk, q)
	var target := _rest(opp.idle_pose)
	if brain.state == DT.OpponentState.STAGGER:
		target = _rest(opp.stagger_pose)
	elif complacent:
		target = _rest(opp.complacent_pose)
	# 돌아감은 빠르게(결정 236): 그때 화면의 포즈에서 return_time초.
	var k := clampf((display_time - start) / maxf(opp.return_time, 0.001), 0.0, 1.0)
	return OpponentMotion.blend(_blend_from, target, OpponentMotion.ease_in_out(k))


func _apply_pose(pose: PoseData, dodge_k: float) -> void:
	_torso.rotation_degrees = pose.lean_deg
	_arm.position = _shoulder_base + pose.shoulder
	_arm.rotation_degrees = pose.arm_deg
	# 칼은 Arm > Hand의 자식이라 지역 각 = 화면 각 - 팔 각 - 몸 기울기(견본 026 rotParams).
	_sword.rotation_degrees = pose.sword_deg - pose.arm_deg - pose.lean_deg
	_head.rotation_degrees = lerpf(pose.head_deg, _dodge_head_deg, dodge_k)


func _rest(pose: PoseData) -> PoseData:
	return pose if pose != null else PoseData.new()


func _apply_colors(tint: Variant, head_closed: bool) -> void:
	for part in _materials:
		var color := Color.WHITE
		var amount := 0.0
		if part == _touched_part and _clock < _touched_until:
			# 흰 번쩍임도 칠에만: 선이 남아 무엇이 닿았는지 읽힌다(결정 259).
			color = COLOR_TOUCHED
			amount = 1.0
		elif part == DT.Part.HEAD and head_closed:
			amount = 0.0
		elif tint != null and TINTED.has(part):
			color = tint as Color
			amount = TINT_AMOUNT
		_set_tint(_materials[part], color, amount)
		if part == DT.Part.HAT:
			_set_tint(_feather_material, color, amount)


func _set_tint(mat: ShaderMaterial, color: Color, amount: float) -> void:
	mat.set_shader_parameter(&"tint_color", Vector3(color.r, color.g, color.b))
	mat.set_shader_parameter(&"tint_amount", amount)


## 그림을 파츠에 걸고 관절 자리를 노드 위치로 준다. 그림이 없으면 텍스처 없이(관절은 기본값) 돈다(결정 256).
func _apply_art(art: OpponentArt) -> void:
	_art = art
	var joints: OpponentArt = art if art != null else OpponentArt.new()
	_head.position = joints.neck
	_hat.position = joints.hat_at
	_hand.position = joints.hand_at
	_sword.position = joints.sword_at
	_shoulder_base = joints.shoulder
	_set_art(_art_of(DT.Part.LEGS), joints.legs, _materials[DT.Part.LEGS])
	_set_art(_art_of(DT.Part.TORSO), joints.torso, _materials[DT.Part.TORSO])
	_set_art(_art_of(DT.Part.HAT), joints.hat, _materials[DT.Part.HAT])
	_set_art(_art_of(DT.Part.SWORD_ARM), joints.arm, _materials[DT.Part.SWORD_ARM])
	_set_art(_art_of(DT.Part.SWORD_HAND), joints.hand, _materials[DT.Part.SWORD_HAND])
	_set_art(_sword.get_node(^"Art") as Sprite2D, joints.sword, null)
	_set_art(_feather, joints.feather, _feather_material)
	_head_art = joints.head
	_set_art(_art_of(DT.Part.HEAD), joints.head, _materials[DT.Part.HEAD])


## 머리 셋은 관절이 반 화소씩 달라 텍스처와 함께 offset도 바꾼다(결정 260, MANIFEST 7~9행).
func _set_head(pa: PartArt) -> void:
	if pa == _head_art:
		return
	_head_art = pa
	_set_art(_art_of(DT.Part.HEAD), pa, _materials[DT.Part.HEAD])


func _set_art(sprite: Sprite2D, pa: PartArt, mat: ShaderMaterial) -> void:
	sprite.texture = pa.texture if pa != null else null
	if pa == null:
		return
	sprite.offset = -pa.joint
	sprite.scale = pa.units_per_px
	if mat != null:
		mat.set_shader_parameter(&"outline_texels", Vector2(OUTLINE_UNITS / pa.units_per_px.x, OUTLINE_UNITS / pa.units_per_px.y))


func _art_of(part: int) -> Sprite2D:
	return get_node(PART_PATHS[part]).get_node(^"Art") as Sprite2D


func _new_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = PART_SHADER
	mat.set_shader_parameter(&"outline_color", OUTLINE_COLOR)
	return mat


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
