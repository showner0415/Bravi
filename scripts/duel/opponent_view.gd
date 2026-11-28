class_name OpponentView
extends Node2D
## 파츠 그림으로 된 상대. 표시만 한다(판정은 DuelCore).
##
## 파츠 노드의 이름·계층·원점은 아트와 리깅의 기준이다 (docs/DECISIONS.md 결정 12):
##   Legs / Torso > Head > Hat / Torso > Arm > Hand > Sword. 원점은 관절(골반, 목, 어깨, 손목).
## 그림은 파츠마다 첫 자식 Sprite2D "Art"에 건다(결정 255). 포즈는 관절에서 돌린다(결정 257·258).
## 이 스크립트는 파츠를 Node2D 이상의 타입으로 가정하지 않는다(나중에 Bone2D로 바꿀 수 있게).

const DT := preload("res://scripts/duel/duel_types.gd")
const Controls := preload("res://scripts/controls.gd")
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
## 팔 둔함이 걸린 동안 칼 든 팔 파츠의 물(계획 R02 D4).
const COLOR_ARM_SLOW := Color(0.55, 0.55, 0.58)
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
const DIVE_PULL_SCALE := 0.85
const DIVE_PULL_SHIFT := -25.0
## 치고 빠지기(결정 702): 물러나는 순간의 뜀(초, px)과 고리 밑 꺾쇠(폭, 두 줄 사이, 굵기, 고리 가장자리에서의 간격).
const HOP_TIME := 0.25
const HOP_HEIGHT := 28.0
const WITHDRAW_CHEVRON_WIDTH := 24.0
const WITHDRAW_CHEVRON_GAP := 7.0
const WITHDRAW_CHEVRON_THICK := 3.0
const WITHDRAW_CHEVRON_OFFSET := 8.0

## 줄어드는 고리: 일정한 속도(px/초)로 줄어 0이 되는 순간이 타격이다.
## 패리 창에 해당하는 고정 띠(반지름 = 속도 x 패리 창)를 예비 동작 시작부터 그려 둔다.
## 위치는 상대 기준 화면 좌표(간격에 따라 커지거나 움직이지 않는다).
const RING_SPEED := 240.0
const RING_POSITION: Array[Vector2] = [Vector2(-270, -150), Vector2(0, -140), Vector2(270, -150)]
## 패턴의 번호 고리: 같은 방향이 되풀이되면 아래로 비키는 폭, 고리의 반지름, 번호의 글자 크기(결정 374).
const MARK_REPEAT_SHIFT := 36.0
const MARK_RADIUS := 26.0
const MARK_FONT_SIZE := 24
## 번호 고리의 꼴(AttackData.mark_shape). 박자 고리는 앞 타격부터의 기다림을 막대 길이로 보인다(결정 630·632).
const MARK_SHAPES: Array[StringName] = [&"beat"]
## 막대의 길이 = 그 타격 앞의 기다림(초) x 이 값(px). 막대의 바탕 높이와 흰 막대의 안쪽 여백.
const BEAT_BAR_SPEED := 60.0
const BEAT_BAR_HEIGHT := 14.0
const BEAT_BAR_INSET := 3.0
## 높이를 가진 타격의 고리 줄(상대 기준 y, 상·중·하). 화면의 윗줄·가운뎃줄·아랫줄 안에 온다(결정 388).
const RING_ROW_Y: Array[float] = [-300.0, -150.0, 80.0]
## 예비 동작 동안 높이에 따라 어깨를 옮기는 폭(표시만).
const HEIGHT_SHOULDER_SHIFT: Array[float] = [-16.0, 0.0, 12.0]
## 휩쓸기의 따라가는 점은 두 점 사이 간격의 이만큼에서 다음 점에 먼저 가 기다린다(결정 389).
const SWEEP_DOT_ARRIVE := 0.6
## 상태 글자(공격 이름, 빈틈, 무너짐)의 화면 세로 위치. 자세 칸 바로 아래.
const STATE_LABEL_Y := 62.0
## 귀띔(StateHint)과 첫 줄의 글 끝 사이의 틈. 임시(계획 041b 결정 625).
const STATE_HINT_GAP := 24.0

## 부위 곁의 미리보기 꼬리표(계획 R02 D3): 여유 막대가 가득 차는 여유(초), 막대의 크기, 꼬리표를 놓을 화면 세로 범위.
const FORECAST_FULL_MARGIN := 0.5
const FORECAST_BAR_SIZE := Vector2(80.0, 8.0)
const FORECAST_TAG_Y_RANGE := Vector2(80.0, 520.0)
const FORECAST_COLORS := {
	DT.Forecast.REACH: Color(0.45, 1.0, 0.6), DT.Forecast.LATE: Color(1.0, 0.75, 0.2),
	DT.Forecast.OUT_OF_RANGE: Color(0.8, 0.8, 0.8), DT.Forecast.HEAD_GUARDED: Color(1.0, 0.45, 0.45),
	DT.Forecast.BIND_CUT: Color(0.9, 0.45, 1.0), DT.Forecast.SPIKE_COVERED: Color(0.80, 0.84, 0.90),
}
const COLUMN_NAMES := ["왼쪽", "가운데", "오른쪽"]

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
## 따로 그린 팔(결정 266·268): key -> 묶음, 부위 -> 층의 재질들, 손의 윤곽선들(보통 손 + 주먹 층).
var _arm_groups := {}
var _part_extra := {}
var _outlines: Array[Line2D] = []
var _groups_for: OpponentArt
var _groups_built := false
var _art_key := OpponentArmArt.ARM
## 바뀜이 시작될 때 나온 국면의 팔 그림. 돌아감이 끝날 때까지 남는다(견본 mixPose).
var _leave_art := OpponentArmArt.ARM
var _last_state := -1
var _last_attack: AttackData
var _last_state_end := 0.0
var _warned_arts := {}
var _dodge_k := 0.0
var _dodge_time := 0.3
var _dodge_head_deg := -20.1
## 번쩍임용 시계(실제 시간). 결투가 끝나 코어 시계가 멈춰도 번쩍임은 사라진다.
var _clock := 0.0
var _flash_until := -INF
var _touched_part := -1
## 칼 든 팔이 둔해진 동안(팔 파츠에 잿빛 물이 든다).
var _arm_slowed := false
var _touched_until := -INF
## 섣부른 공격을 받아넘겼을 때("받아넘김")나 버티기가 됐을 때("밀어붙임") 상태 글자 자리에 잠깐 띄우는 글자.
var _deflect_text := ""
var _deflect_until := -INF
var _dodge_until := -INF

var _ring_active := false
var _ring_remaining := 0.0
## 패턴의 번호 고리와 휩쓸기의 길(pattern_marks의 결과). 단발이면 비어 있다.
var _marks: Array[Dictionary] = []
var _ring_sweep := false
## 지금 타격이 헛손질인가(결정 670): 패리의 띠를 그리지 않고 줄어드는 고리가 점선이다.
var _ring_feint := false
## 지금 타격이 빠지는 길의 마지막인가(결정 702): 지금 고리의 띠 아래에 꺾쇠를 그린다.
var _ring_withdraw := false
var _hop_start := -INF
var _height_shift := 0.0
var _dive_start := -INF
var _dive_from_close := false
## 다음 갱신에서 크기와 위치를 보간 없이 맞춘다(시작, 다시 하기).
var _snap := true

@onready var _torso: Node2D = $Torso
@onready var _head: Node2D = $Torso/Head
@onready var _hat: Node2D = $Torso/Head/Hat
@onready var _arm: Node2D = $Torso/Arm
@onready var _arm_sprite: Sprite2D = $Torso/Arm/Art
@onready var _hand: Node2D = $Torso/Arm/Hand
@onready var _hand_outline: Line2D = $Torso/Arm/Hand/Outline
@onready var _sword: Node2D = $Torso/Arm/Hand/Sword
@onready var _feather: Sprite2D = $Torso/Head/Hat/Feather
@onready var _state_label: Label = $StateLabel
var _ring: Node2D
var _state_hint: Label
var _forecast_tag: Label
var _forecast_bar: ColorRect
var _forecast_fill: ColorRect


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
	_build_state_hint()
	_build_forecast_tag()


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
	_hop_start = -INF
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
	# 쉬는 상태의 그림은 그 포즈의 arm_art다. 앞 판의 그림을 남기지 않는다(결정 285).
	_art_key = OpponentArmArt.art_of(_pose)
	_leave_art = _art_key
	_last_state = -1
	_last_attack = null
	_apply_pose(_pose, 0.0)
	_show_arm_art(_art_key)
	if _ring != null:
		_ring.queue_redraw()


## 조준 중인 부위의 테두리를 강조한다. -1이면 강조 없음. 모자를 노리면 깃털도 켠다.
func set_target(part: int) -> void:
	if part == _target_part:
		return
	_target_part = part
	_refresh_target()


# setup이 묶음을 새로 만든 뒤에도 부른다(새 윤곽선이 지금의 조준을 따르게).
func _refresh_target() -> void:
	var part := _target_part
	for p in _materials:
		# 손은 칼 위의 바깥 윤곽선으로만 보인다(결정 269): 손 몫 재질의 안쪽 테두리는 늘 끈다.
		var on: bool = p == part and p != DT.Part.SWORD_HAND
		(_materials[p] as ShaderMaterial).set_shader_parameter(&"outline_on", on)
		for mat in _part_extra.get(p, []):
			(mat as ShaderMaterial).set_shader_parameter(&"outline_on", on)
	_feather_material.set_shader_parameter(&"outline_on", part == DT.Part.HAT)
	for line in _outlines:
		line.visible = part == DT.Part.SWORD_HAND


func on_event(ev: Dictionary) -> void:
	match ev["type"]:
		DuelRecord.STRIKE:
			_flash_until = _clock + FLASH_TIME
			if ev["braced"]:
				# 들고만 있던 막기로 표시된 공격을 버텼다: 빈틈이 없다는 것을 상태 글자 자리에 잠깐 띄운다.
				_deflect_text = "밀어붙임"
				_deflect_until = _clock + DEFLECT_TEXT_TIME
			elif ev.get("bitten", false):
				# 헛손질에 속아 막고도 빈틈이 없다(결정 671).
				_deflect_text = "속았다"
				_deflect_until = _clock + DEFLECT_TEXT_TIME
			elif ev.get("closed", false):
				# 막았는데 빈틈을 주지 않았다(결정 404). 상한에 닿았으면 다음은 열린다고 알린다.
				_deflect_text = "틈을 안 준다" + (" — 다음은 열린다" if _limit_reached(ev) else "")
				_deflect_until = _clock + DEFLECT_TEXT_TIME
		DuelRecord.DISTANCE:
			if ev.get("by", "") == "withdraw":
				_hop_start = _clock
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
			if ev.get("spiked", false):
				_deflect_text = "송곳에 걸렸다"
				_deflect_until = _clock + DEFLECT_TEXT_TIME
			elif result == DT.AttackResult.BLOCKED and ev["rash"]:
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
	# 뛰어들기의 예비 동작은 들어서기만큼 물러서고 타격까지 둔다(결정 454). 들어선 순간의 간격은 글자를 위해 잡아 둔다.
	var dive_pull := 0.0
	if brain.state == DT.OpponentState.TELL and brain.current_attack != null and brain.current_attack.dive:
		if brain.state_start != _dive_start:
			_dive_start = brain.state_start
			_dive_from_close = core.distance == DT.Distance.CLOSE
		dive_pull = OpponentMotion.ease_out(clampf((display_time - brain.state_start) / maxf(brain.tell_duration * core.opponent_data.tell_in, 0.001), 0.0, 1.0))
	var target_scale := DISTANCE_SCALE[core.distance] * lerpf(1.0, DIVE_PULL_SCALE, dive_pull)
	var target_pos := anchor + Vector2(0, DISTANCE_SHIFT[core.distance] + DIVE_PULL_SHIFT * dive_pull)
	var hop_k := (_clock - _hop_start) / HOP_TIME
	if hop_k >= 0.0 and hop_k < 1.0:
		target_pos.y -= 4.0 * hop_k * (1.0 - hop_k) * HOP_HEIGHT
	scale = scale.lerp(Vector2.ONE * target_scale, smooth)
	position = position.lerp(target_pos, smooth)
	var inverse := 1.0 / maxf(scale.x, 0.01)

	# --- 상태별 색과 글자. 포즈는 _pose_for가 정한다(결정 258).
	var tint: Variant = null
	var text := ""
	var hint := ""
	_ring_active = false
	_marks = []
	_ring_sweep = false
	_ring_feint = false
	_ring_withdraw = false
	# 머리를 지키는 상대의 머리는 크게 열린 회수에서만 빈틈 색으로 물든다("파랗게 물든 부위가 열린 부위").
	var head_closed := false
	var head_art: PartArt = _art.head if _art != null else null

	# 방심했고 대기 중이면 칼끝을 내린다. 예비 동작·회수·무너짐 중에는 그 상태의 표시가 우선이다.
	var complacent := brain.state == DT.OpponentState.IDLE and core.has_lunge() and core.complacency() >= 1.0

	match brain.state:
		DT.OpponentState.TELL:
			var atk := brain.current_attack
			tint = atk.pose_color
			_marks = pattern_marks(brain, display_time)
			_ring_sweep = brain.is_sweep()
			_ring_feint = atk.feint
			_ring_withdraw = ring_withdraw_of(brain)
			var tell_parts := tell_texts(core, _dive_from_close)
			text = tell_parts[0]
			hint = tell_parts[1]
			_ring_active = true
			_ring_remaining = maxf(brain.state_end - display_time, 0.0)
			_ring.position = _now_mark_position(atk, brain) * inverse
		DT.OpponentState.RECOVERY:
			tint = COLOR_RECOVERY
			text = "빈틈"
			hint = recovery_hint_of(core)
			if _art != null:
				head_art = _art.head_oops
			if core.opponent_data.guards_head:
				if core.head_open_at(core.time):
					text = "머리가 열렸다!" if core.opponent_data.part_effects != null else "크게 열림!"
				else:
					head_closed = true
		DT.OpponentState.STAGGER:
			tint = COLOR_STAGGER
			text = "무너짐!"
			hint = stagger_hint_of(core)
			if _art != null:
				head_art = _art.head_dizzy

	# 피하기는 회수 중에 일어나지만 얼굴을 지켜 낸 것이라 미소 머리다(결정 260).
	if _clock < _dodge_until and _art != null:
		head_art = _art.head
	_pose = _pose_for(core, display_time, complacent)
	# 피하기의 고개는 지금처럼 부드럽게 젖혔다 돌아온다(포즈의 고개 위에 얹는다).
	_dodge_k = lerpf(_dodge_k, 1.0 if _clock < _dodge_until else 0.0, smooth)
	var shift_height := brain.current_height() if brain.state == DT.OpponentState.TELL else -1
	_height_shift = lerpf(_height_shift, HEIGHT_SHOULDER_SHIFT[shift_height] if shift_height >= 0 else 0.0, smooth)
	_apply_pose(_pose, _dodge_k)
	_show_arm_art(_art_key)
	if _art != null:
		_set_head(head_art)

	# --- 색: 상태 색, 타격 순간의 빨강 번쩍임, 닿은 부위의 흰 번쩍임
	if _clock < _flash_until:
		tint = COLOR_STRIKE
		head_closed = false
	_arm_slowed = brain.slow_tells_left > 0 or brain.pattern_slowed
	_apply_colors(tint, head_closed)

	# 받아넘김 글자는 상태 글자가 비어 있을 때만 보인다(예비 동작에 들어가면 공격 이름이 우선).
	if text == "" and _clock < _deflect_until:
		text = _deflect_text
	# 방심: 대기 중이고 다른 글자가 없을 때만 보인다. 빈틈의 색은 쓰지 않는다(파란색은 "보통 공격이 닿는다"는 뜻이다).
	if text == "" and complacent:
		text = COMPLACENT_TEXT

	_place_labels(text, hint, inverse)
	_update_forecast_tag(core, inverse)


## 조건이 무너짐 동안 띄우길 원하는 귀띔(비어 있지 않은 첫 것). 의뢰·조건이 없는 판은 빈 글이다(계획 043 결정 660).
static func stagger_hint_of(core: DuelCore) -> String:
	for condition in core.conditions:
		if condition != null:
			var hint_text := condition.stagger_hint(core.record)
			if hint_text != "":
				return hint_text
	return ""


## 예비 동작의 글을 [첫 줄, 귀띔]으로 가른다. 상태 글자는 늘 한 줄이고 귀띔은 StateHint가 맡는다(결정 624·625).
## 귀띔이 둘 이상이면 " · "로 한 줄로 잇는다.
static func tell_texts(core: DuelCore, dive_from_close: bool) -> PackedStringArray:
	var brain := core.brain
	var atk := brain.current_attack
	var text := atk.attack_name + ("!!" if atk.is_big else "")
	if brain.pattern_count() > 1:
		# 패턴은 뿌리의 이름과 몇째 타격인지를 보인다(결정 374).
		var root := brain.pattern_root
		text = "%s (%d/%d)%s" % [root.attack_name, brain.step_index + 1, brain.pattern_count(), "!!" if root.is_big else ""]
	# 높이를 가진 타격은 막을 칸의 이름을 붙인다(결정 388).
	var tell_height := brain.current_height()
	if tell_height >= 0:
		text += " · %s %s" % [DT.GUARD_NAMES[atk.direction], DT.HEIGHT_NAMES[tell_height]]
	# 헛손질은 칸 이름 대신 알린다(결정 670).
	if atk.feint:
		text = text.get_slice(" · ", 0) + " · 헛손질"
	if brain.pattern_slowed:
		text += " (둔함)"
	var hints := PackedStringArray()
	# 데이터의 세는 말은 귀띔의 맨 앞이고 패턴 내내 같은 글이다(결정 633).
	if brain.pattern_root != null and brain.pattern_root.tell_hint != "":
		hints.append(brain.pattern_root.tell_hint)
	if brain.is_sweep():
		hints.append("쥐고 끌어라")
	if atk.dive:
		hints.append("막아라" if dive_from_close else "멀리 물러서거나 막아라")
	# 표시된 공격은 예비 동작 내내, 지금의 막기가 버티기만 되는지 받아내는지 알려 준다.
	if brain.step_index == 0 and atk.needs_raised_guard and core.player_state == DT.PlayerState.GUARD:
		hints.append("막기를 뗐다 다시 올려라" if core.would_brace_now() else "받아낼 준비")
	return PackedStringArray([text, " · ".join(hints)])


## 귀띔의 왼쪽 끝(화면 x): 가운데 정렬된 첫 줄의 글 끝 + 틈.
static func hint_left(line_width: float, center_x: float) -> float:
	return center_x + line_width * 0.5 + STATE_HINT_GAP


# 상태 글자와 고리는 간격에 따라 커지거나 움직이지 않게 한다.
func _place_labels(text: String, hint: String, inverse: float) -> void:
	_state_label.text = text
	_state_label.scale = Vector2.ONE * inverse
	_state_label.position = (Vector2(anchor.x - _state_label.size.x * 0.5, STATE_LABEL_Y) - position) * inverse
	# 글이 바뀐 그 호출에서 새 폭을 얻으려고 reset_size를 부른다(귀띔의 자리가 첫 줄의 글 폭을 따른다).
	if _state_hint.text != hint:
		_state_hint.text = hint
		_state_hint.reset_size()
	_state_hint.visible = hint != ""
	_state_hint.scale = Vector2.ONE * inverse
	_state_hint.position = (Vector2(hint_left(_state_label.get_minimum_size().x, anchor.x), STATE_LABEL_Y) - position) * inverse
	_ring.scale = Vector2.ONE * inverse
	_ring.queue_redraw()


# 꼴은 상태 글자의 값을 읽어 온다(새 색·크기를 쓰지 않는다. 결정 625).
func _build_state_hint() -> void:
	_state_hint = Label.new()
	_state_hint.name = "StateHint"
	_state_hint.visible = false
	_state_hint.z_index = 9
	_state_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_hint.add_theme_font_override(&"font", _state_label.get_theme_font(&"font"))
	_state_hint.add_theme_font_size_override(&"font_size", _state_label.get_theme_font_size(&"font_size"))
	_state_hint.add_theme_color_override(&"font_color", _state_label.get_theme_color(&"font_color"))
	_state_hint.add_theme_color_override(&"font_outline_color", _state_label.get_theme_color(&"font_outline_color"))
	_state_hint.add_theme_constant_override(&"outline_size", _state_label.get_theme_constant(&"outline_size"))
	add_child(_state_hint)


func _build_forecast_tag() -> void:
	_forecast_tag = Label.new()
	_forecast_tag.name = "ForecastTag"
	_forecast_tag.visible = false
	_forecast_tag.z_index = 9
	_forecast_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_forecast_tag.add_theme_font_override(&"font", _state_label.get_theme_font(&"font"))
	_forecast_tag.add_theme_font_size_override(&"font_size", 22)
	_forecast_tag.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 1))
	_forecast_tag.add_theme_constant_override(&"outline_size", 8)
	add_child(_forecast_tag)
	_forecast_bar = ColorRect.new()
	_forecast_bar.color = Color(0.12, 0.1, 0.08, 0.8)
	_forecast_bar.size = FORECAST_BAR_SIZE
	_forecast_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_forecast_tag.add_child(_forecast_bar)
	_forecast_fill = ColorRect.new()
	_forecast_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_forecast_bar.add_child(_forecast_fill)


## 조준한 부위 곁의 "닿는다/늦다/멀다/피한다/엉킴" 꼬리표. 코어의 미리보기 답만 읽는다(따로 셈하지 않는다).
func _update_forecast_tag(core: DuelCore, inverse: float) -> void:
	var verdict := -1
	var margin := 0.0
	if DuelHud.forecast_on(core):
		var forecast := core.attack_forecast()
		verdict = forecast["verdict"]
		margin = forecast["margin"]
	if not DuelHud.FORECAST_WORD.has(verdict):
		_forecast_tag.visible = false
		return
	var word: String = DuelHud.FORECAST_WORD[verdict]
	var color: Color = FORECAST_COLORS[verdict]
	if _forecast_tag.text != word:
		_forecast_tag.text = word
		_forecast_tag.reset_size()
	_forecast_tag.add_theme_color_override(&"font_color", color)
	var has_bar := verdict == DT.Forecast.REACH or verdict == DT.Forecast.LATE
	_forecast_bar.visible = has_bar
	_forecast_bar.position = Vector2(0.0, _forecast_tag.size.y)
	_forecast_fill.color = color
	_forecast_fill.size = Vector2(FORECAST_BAR_SIZE.x * clampf(margin / FORECAST_FULL_MARGIN, 0.0, 1.0) if verdict == DT.Forecast.REACH else 0.0, FORECAST_BAR_SIZE.y)
	# 윤곽선 옆(오른쪽)에 둔다. 화면 밖으로 나가면 왼쪽으로 넘긴다. 상태 글자·내 칼·판과 겹치지 않게 세로를 가둔다.
	var rect := _part_screen_rect(core.current_aim_part())
	var width := _forecast_tag.size.x * scale.x
	var at := Vector2(rect.end.x + 10.0, clampf(rect.get_center().y - _forecast_tag.size.y * scale.y * 0.5, FORECAST_TAG_Y_RANGE.x, FORECAST_TAG_Y_RANGE.y))
	if at.x + maxf(width, FORECAST_BAR_SIZE.x * scale.x) > get_viewport_rect().size.x - 8.0:
		at.x = rect.position.x - 10.0 - maxf(width, FORECAST_BAR_SIZE.x * scale.x)
	_forecast_tag.scale = Vector2.ONE * inverse
	_forecast_tag.position = (at - position) * inverse
	_forecast_tag.visible = true


## 부위의 화면 상자. 그림이 있으면 그 그림의 상자, 팔·손(따로 그린 그림으로 바뀐다)과 그림 없는 부위는 관절 둘레의 작은 상자다.
func _part_screen_rect(part: int) -> Rect2:
	var node := get_node(PART_PATHS[part]) as Node2D
	var sprite := _art_of(part)
	if sprite.texture != null and part != DT.Part.SWORD_ARM and part != DT.Part.SWORD_HAND:
		return sprite.get_global_transform() * sprite.get_rect()
	var joint := node.global_position
	return Rect2(joint - Vector2(30.0, 30.0) * scale.x, Vector2(60.0, 60.0) * scale.x)


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
		_leave_art = OpponentArmArt.leaving(_last_state, _last_attack, _last_state_end, start, _art_key)
		_phase_key = key
		_phase_start = start
		_blend_from = _pose
	_last_state = brain.state
	_last_attack = brain.current_attack
	_last_state_end = brain.state_end
	var atk := brain.current_attack
	if brain.state == DT.OpponentState.TELL and atk != null:
		var p := (display_time - start) / maxf(brain.tell_duration, 0.001)
		if brain.is_sweep() and brain.step_index > 0:
			# 휩쓸기의 걸음은 멈칫 없이 앞 점에서 이 점으로 곧게 간다(결정 374).
			var root := brain.pattern_root
			var prev: AttackData = root if brain.step_index == 1 else (root.chain[brain.step_index - 2] as AttackData)
			_art_key = OpponentArmArt.art_of(atk.strike_pose)
			return OpponentMotion.sweep_pose(prev, atk, p)
		_art_key = OpponentArmArt.art_of(atk.tell_pose)
		return OpponentMotion.tell_pose(atk, _blend_from, p, brain.tell_duration, _parry_window, opp)
	if brain.state == DT.OpponentState.RECOVERY and atk != null:
		_art_key = OpponentArmArt.art_of(atk.strike_pose)
		var q := (display_time - start) / maxf(brain.state_end - start, 0.001)
		return OpponentMotion.recover_pose(atk, q)
	var target := _rest(opp.idle_pose)
	if brain.state == DT.OpponentState.STAGGER:
		target = _rest(opp.stagger_pose)
	elif complacent:
		target = _rest(opp.complacent_pose)
	# 돌아감은 빠르게(결정 236): 그때 화면의 포즈에서 return_time초.
	var k := clampf((display_time - start) / maxf(opp.return_time, 0.001), 0.0, 1.0)
	# 섞는 동안은 나온 국면의 그림(결정 268), 끝나면 그 상태 포즈의 그림(결정 285). 거짓이면 섞는 동안도 그 상태의 그림(판 F의 갈래).
	_art_key = _leave_art if k < 1.0 and opp.strike_art_on_return else OpponentArmArt.art_of(target)
	return OpponentMotion.blend(_blend_from, target, OpponentMotion.ease_in_out(k))


## 따로 그린 팔이 보이는 동안 Arm의 그림과 Hand(칼·윤곽선까지)를 감춘다(결정 237).
func _show_arm_art(key: StringName) -> void:
	if key != OpponentArmArt.ARM and not _arm_groups.has(key):
		if not _warned_arts.has(key):
			_warned_arts[key] = true
			push_warning("OpponentView: 그림에 없는 팔 그림 '%s' — 보통 팔로 그린다" % key)
		key = OpponentArmArt.ARM
	var plain := key == OpponentArmArt.ARM
	_arm_sprite.visible = plain
	_hand.visible = plain
	for k in _arm_groups:
		(_arm_groups[k] as Node2D).visible = k == key


func _apply_pose(pose: PoseData, dodge_k: float) -> void:
	_torso.rotation_degrees = pose.lean_deg
	_arm.position = _shoulder_base + pose.shoulder + Vector2(0, _height_shift)
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
		elif part == DT.Part.SWORD_ARM and _arm_slowed:
			color = COLOR_ARM_SLOW
			amount = TINT_AMOUNT
		elif part == DT.Part.HEAD and head_closed:
			amount = 0.0
		elif tint != null and TINTED.has(part):
			color = tint as Color
			amount = TINT_AMOUNT
		_set_tint(_materials[part], color, amount)
		for mat in _part_extra.get(part, []):
			_set_tint(mat, color, amount)
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
	_hand_outline.width = OUTLINE_UNITS
	_hand_outline.default_color = OUTLINE_COLOR
	_hand_outline.points = OpponentArmArt.outline_points(joints.hand, OUTLINE_UNITS)
	_build_arm_groups(art)
	_refresh_target()


## 같은 그림이면 다시 만들지 않는다(찍기 씬이 장마다 setup을 부른다). 다른 그림이면 옛 묶음을 떼어 지운다.
func _build_arm_groups(art: OpponentArt) -> void:
	if _groups_built and art == _groups_for:
		return
	_groups_built = true
	for old: Node2D in _arm_groups.values():
		_arm.remove_child(old)
		old.queue_free()
	_arm_groups.clear()
	_part_extra.clear()
	_outlines.assign([_hand_outline])
	_groups_for = art
	if art == null:
		return
	var at := _arm_sprite.get_index() + 1
	for arm_art in art.arm_arts:
		var group := OpponentArmArt.build_group(arm_art, _new_material, OUTLINE_UNITS, OUTLINE_COLOR,
				_part_extra, _outlines)
		_arm.add_child(group)
		_arm.move_child(group, at)
		at += 1
		_arm_groups[arm_art.key] = group


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


## 지금 타격이 빠지는 길의 마지막 타격인가(결정 702). 단발이면 그 타격이다.
static func ring_withdraw_of(brain: OpponentBrain) -> bool:
	if brain.state != DT.OpponentState.TELL or brain.current_attack == null:
		return false
	var root := brain.pattern_root if brain.pattern_root != null else brain.current_attack
	return root.withdraw and brain.step_index == brain.pattern_count() - 1


## 물러난 판정에서 시작된 멀리의 빈틈이면 따라붙는 길의 귀띔, 아니면 빈 글(결정 702).
static func recovery_hint_of(core: DuelCore) -> String:
	var brain := core.brain
	if brain.state == DT.OpponentState.RECOVERY and core.distance == DT.Distance.FAR and core.withdrew_at == brain.state_start:
		return "막기 떼고 %s" % Controls.help_name(&"step_forward")
	if core.spike_live():
		var open: Array[String] = []
		for column in 3:
			if not core.covered_dirs.has(column):
				open.append(COLUMN_NAMES[column])
		# 가운데 상단은 머리라 머리가 닫힌 빈틈에서는 막기만으로 닿지 않는다.
		var tail := "(머리 말고)" if open.size() == 1 and core.covered_dirs.has(0) and core.covered_dirs.has(2) \
				and not core.head_open_at(core.time) else ""
		return "송곳 — 빈 줄: %s%s" % [" · ".join(open), tail]
	return ""


## 패턴의 표시 목록(결정 374). 타격마다 {"role": &"now"·&"next"·&"later", "number", "pos", "time"}이고,
## 휩쓸기면 끝에 {"role": &"path", "points", "dot"}가 붙는다. 자리는 RING_POSITION의 좌표다(같은 방향이 되풀이되면 아래로 비킨다).
## 지난 타격은 넣지 않는다. 패턴이 아니거나 예비 동작 중이 아니면 빈 배열이다.
static func pattern_marks(brain: OpponentBrain, display_time: float) -> Array[Dictionary]:
	var marks: Array[Dictionary] = []
	if brain.state != DT.OpponentState.TELL or brain.pattern_root == null or brain.pattern_count() < 2:
		return marks
	var root := brain.pattern_root
	var times := brain.pattern_strike_times()
	var seen := {}
	var points := PackedVector2Array()
	for i in times.size():
		var atk: AttackData = root if i == 0 else (root.chain[i - 1] as AttackData)
		var height := brain.strike_heights[i] if i < brain.strike_heights.size() else -1
		# 같은 칸(방향과 높이)이 되풀이될 때만 아래로 비킨다. 높이가 없으면 방향으로 센다.
		var cell := Vector2i(atk.direction, height)
		var repeats := int(seen.get(cell, 0))
		seen[cell] = repeats + 1
		var pos: Vector2 = ring_position(atk.direction, height) + Vector2(0, MARK_REPEAT_SHIFT * repeats)
		points.append(pos)
		if i < brain.step_index:
			continue
		var role := &"now" if i == brain.step_index else (&"next" if i == brain.step_index + 1 else &"later")
		var mark := {"role": role, "number": i + 1, "pos": pos, "time": times[i]}
		if atk.feint:
			mark["feint"] = true
		if root.withdraw and i == times.size() - 1:
			mark["withdraw"] = true
		if root.mark_shape != &"":
			# 막대는 칼 든 팔의 반대쪽으로 뻗는다(예비 동작을 보이는 팔과 칼을 가리지 않게. 결정 632).
			mark["shape"] = root.mark_shape
			mark["wait"] = times[i] - times[i - 1] if i > 0 else 0.0
			mark["side"] = 1 if brain.data.sword_side == DT.Direction.LEFT else -1
		marks.append(mark)
	if brain.is_sweep():
		# 따라가는 점: 첫 점의 시각까지 첫 자리에서 기다리고, 그 뒤 닿는 시각마다 그 점에 오도록 고르게 간다.
		var dot := points[0]
		for i in range(1, times.size()):
			if display_time >= times[i - 1]:
				var k := clampf((display_time - times[i - 1]) / maxf((times[i] - times[i - 1]) * SWEEP_DOT_ARRIVE, 0.001), 0.0, 1.0)
				dot = points[i - 1].lerp(points[i], k)
		marks.append({"role": &"path", "points": points, "dot": dot})
	return marks


## 박자 고리의 기다림 막대(바탕) 상자. mark["pos"]와 같은 좌표(상대 기준)이고, 고리의 가장자리에서 side 쪽으로 wait x BEAT_BAR_SPEED px 뻗는다.
static func beat_bar_rect(mark: Dictionary) -> Rect2:
	var pos: Vector2 = mark["pos"]
	var length: float = float(mark["wait"]) * BEAT_BAR_SPEED
	var side: int = mark["side"]
	var left := pos.x + MARK_RADIUS if side > 0 else pos.x - MARK_RADIUS - length
	return Rect2(left, pos.y - BEAT_BAR_HEIGHT * 0.5, length, BEAT_BAR_HEIGHT)


## 지금 타격의 고리 자리. 패턴이면 번호 고리의 자리(되풀이 방향의 비킴 포함)다.
func _now_mark_position(atk: AttackData, brain: OpponentBrain) -> Vector2:
	for mark in _marks:
		if mark["role"] == &"now":
			return mark["pos"]
	return ring_position(atk.direction, brain.current_height())


## 고리의 자리(상대 기준). 높이가 없으면(-1) 지금의 세 자리, 있으면 그 줄이다(결정 388).
static func ring_position(direction: int, height: int) -> Vector2:
	if height < 0 or height >= RING_ROW_Y.size():
		return RING_POSITION[direction]
	return Vector2(RING_POSITION[direction].x, RING_ROW_Y[height])


## 번호 고리와 휩쓸기의 길. 고리 노드의 원점이 지금 타격의 자리라 그 차로 그린다.
func _draw_marks() -> void:
	var origin := Vector2.ZERO
	for mark in _marks:
		if mark["role"] == &"now":
			origin = mark["pos"]
	var font := ThemeDB.fallback_font
	for mark in _marks:
		if mark["role"] == &"path":
			var line := PackedVector2Array()
			for point: Vector2 in mark["points"]:
				line.append(point - origin)
			_ring.draw_polyline(line, Color(1.0, 1.0, 1.0, 0.55), 10.0, true)
			var dot: Vector2 = mark["dot"]
			_ring.draw_circle(dot - origin, 13.0, Color(0.3, 1.0, 0.5, 0.95))
			_ring.draw_arc(dot - origin, 13.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.95), 3.0)
			continue
		var at: Vector2 = mark["pos"] - origin
		var alpha := 0.95 if mark["role"] == &"now" else (0.8 if mark["role"] == &"next" else 0.4)
		if mark["role"] != &"now":
			if mark.get("feint", false):
				# 헛손질은 빈 고리: 어두운 바탕 없이 점선 테두리(결정 670).
				_draw_dashed_circle(at, MARK_RADIUS, Color(1.0, 1.0, 1.0, alpha), 3.0)
			else:
				_ring.draw_circle(at, MARK_RADIUS, Color(0.12, 0.1, 0.08, 0.55 * alpha))
				_ring.draw_arc(at, MARK_RADIUS, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, alpha), 3.0)
			if mark.has("shape") and MARK_SHAPES.has(mark["shape"]) and float(mark["wait"]) > 0.0:
				var bar := beat_bar_rect(mark)
				bar.position -= origin
				_ring.draw_rect(bar, Color(0.12, 0.1, 0.08, 0.55 * alpha))
				_ring.draw_rect(bar.grow(-BEAT_BAR_INSET), Color(1.0, 1.0, 1.0, alpha))
			if mark.get("withdraw", false):
				_draw_chevrons(at + Vector2(0, MARK_RADIUS + WITHDRAW_CHEVRON_OFFSET), alpha)
		var label := str(mark["number"])
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_FONT_SIZE).x
		var base := at + Vector2(-width * 0.5, -MARK_RADIUS - 8.0)
		# 번호가 내 칼이나 상대의 몸에 묻히지 않게 어두운 바탕을 깐다(결정 389).
		_ring.draw_circle(at + Vector2(0, -MARK_RADIUS - 16.0), 15.0, Color(0.12, 0.1, 0.08, 0.75 * alpha))
		_ring.draw_string_outline(font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_FONT_SIZE, 6, Color(0, 0, 0, alpha))
		_ring.draw_string(font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1, MARK_FONT_SIZE, Color(1, 1, 1, alpha))


## 위로 향한 겹 꺾쇠(︽): 치고 빠지는 길의 표지(결정 702). top은 윗꺾쇠의 가운데 위 끝이다.
func _draw_chevrons(top: Vector2, alpha: float) -> void:
	var half := WITHDRAW_CHEVRON_WIDTH * 0.5
	for k in 2:
		var tip := top + Vector2(0, WITHDRAW_CHEVRON_GAP * k)
		var line := PackedVector2Array([tip + Vector2(-half, half * 0.5), tip, tip + Vector2(half, half * 0.5)])
		_ring.draw_polyline(line, Color(0.12, 0.1, 0.08, alpha), WITHDRAW_CHEVRON_THICK + 3.0, true)
		_ring.draw_polyline(line, Color(1.0, 1.0, 1.0, alpha), WITHDRAW_CHEVRON_THICK, true)


## 점선 원: 짧은 호 열둘(결정 670).
func _draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float) -> void:
	var step := TAU / 12.0
	for k in 12:
		_ring.draw_arc(center, radius, step * k, step * k + step * 0.5, 8, color, width)


func _draw_ring() -> void:
	if not _ring_active:
		return
	_draw_marks()
	var band := RING_SPEED * _parry_window
	# 고정 띠(목표 고리): 줄어드는 고리가 이 안에 들어와 있을 때 새로 누르면 패리다. 휩쓸기에는 패리가 없어 그리지 않는다.
	# 헛손질에도 그리지 않는다: 받아낼 것이 없다(결정 670).
	if not _ring_sweep and not _ring_feint:
		_ring.draw_circle(Vector2.ZERO, band, Color(0.3, 1.0, 0.5, 0.22))
		_ring.draw_arc(Vector2.ZERO, band, 0.0, TAU, 48, Color(0.3, 1.0, 0.5, 0.95), 3.0)
	if _ring_withdraw:
		_draw_chevrons(Vector2(0, maxf(band, MARK_RADIUS) + WITHDRAW_CHEVRON_OFFSET), 0.95)
	# 줄어드는 고리: 0이 되는 순간이 타격.
	var radius := _ring_remaining * RING_SPEED
	if radius > 1.0:
		if _ring_feint:
			_draw_dashed_circle(Vector2.ZERO, radius, Color(1.0, 1.0, 1.0, 0.95), 5.0)
		else:
			_ring.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.95), 5.0)
	_ring.draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 1.0, 0.9))


## 안 열린 타격으로 연속 상한에 닿았는가(다음 막기는 반드시 열린다. 결정 401).
static func _limit_reached(ev: Dictionary) -> bool:
	return int(ev.get("miss_limit", 0)) > 0 and int(ev.get("closed_streak", 0)) >= int(ev.get("miss_limit", 0))
