class_name HitFeelData
extends Resource
## 맞은 포즈·쳐내진 포즈의 값(계획 H03 결정 929·934·936). 포즈는 맞기 전의 포즈에 더하는 값이다. 값은 전부 임시다.
## 베기 값은 왼쪽 베기(s = +1)와 칼 든 팔이 왼쪽인 그림을 기준으로 적고, 부호는 pose_for가 뒤집는다.

const DT := preload("res://scripts/duel/duel_types.gd")

@export var torso: PoseData
@export var head: PoseData
@export var sword_arm: PoseData
@export var sword_hand: PoseData
@export var legs: PoseData
@export var hat: PoseData
## 찌르기에서 베기와 다른 부위의 값(팔·손은 베기의 것을 쓴다).
@export var torso_thrust: PoseData
@export var head_thrust: PoseData
@export var legs_thrust: PoseData
@export var hat_thrust: PoseData
@export var parried: PoseData
## 찌르기에 몸통을 맞으면 뿌리의 크기가 이만큼으로 줄어든다(뒤로 밀림).
@export var torso_thrust_scale := 0.96
@export var cells2_scale := 1.4
@export var hit_scale := 1.8
@export var return_time := 0.32
@export var parried_return := 0.45
## 판이 끝난 뒤에도 맞은 포즈가 이 아래로 거둬지지 않는다.
@export var end_floor := 0.6
## 상대 그림 데이터의 파일 이름(예: "bartolo_art.tres") -> 배율. 없으면 1.0.
@export var scale_by_art := {}


## 맞은 부위·방향에 더할 포즈. direction은 내 공격의 방향이고 가운데면 찌르기다.
func pose_for(part: int, direction: int, sword_side: int, strength: float) -> PoseData:
	var thrust := direction == DT.Direction.CENTER
	var s := 1.0 if direction == DT.Direction.LEFT else -1.0
	var src := _slash_of(part)
	if thrust:
		var own := _thrust_of(part)
		src = own if own != null else src
		s = 1.0 if own != null else 0.0
	var out := 1.0 if sword_side == DT.Direction.LEFT else -1.0
	var r := PoseData.new()
	if src == null:
		return r
	r.arm_deg = src.arm_deg * out * strength
	r.sword_deg = src.sword_deg * out * strength
	r.lean_deg = src.lean_deg * s * strength
	r.head_deg = src.head_deg * s * strength
	r.shoulder = src.shoulder * strength
	return r


func parried_pose(sword_side: int, strength: float) -> PoseData:
	var out := 1.0 if sword_side == DT.Direction.LEFT else -1.0
	var r := PoseData.new()
	if parried == null:
		return r
	r.arm_deg = parried.arm_deg * out * strength
	r.sword_deg = parried.sword_deg * out * strength
	r.lean_deg = parried.lean_deg * out * strength
	r.head_deg = parried.head_deg * out * strength
	r.shoulder = parried.shoulder * strength
	return r


## 뿌리의 크기 배율(1.0이면 그대로). 찌르기에 몸통을 맞았을 때만 줄어든다.
func root_scale(part: int, direction: int, strength: float) -> float:
	if direction == DT.Direction.CENTER and part == DT.Part.TORSO:
		return lerpf(1.0, torso_thrust_scale, strength)
	return 1.0


## 세기: 1칸 1.0, 2칸 cells2_scale, 유효타 hit_scale, 그 위에 그림별 배율.
func strength_for(ev: Dictionary, art_name: String) -> float:
	var base := 1.0
	if int(ev.get("result", DT.AttackResult.GRAZE)) == DT.AttackResult.HIT:
		base = hit_scale
	elif int(ev.get("cells", 1)) >= 2:
		base = cells2_scale
	return base * float(scale_by_art.get(art_name, 1.0))


func _slash_of(part: int) -> PoseData:
	match part:
		DT.Part.TORSO:
			return torso
		DT.Part.HEAD:
			return head
		DT.Part.SWORD_ARM:
			return sword_arm
		DT.Part.SWORD_HAND:
			return sword_hand
		DT.Part.LEGS:
			return legs
		DT.Part.HAT:
			return hat
	return null


func _thrust_of(part: int) -> PoseData:
	match part:
		DT.Part.TORSO:
			return torso_thrust
		DT.Part.HEAD:
			return head_thrust
		DT.Part.LEGS:
			return legs_thrust
		DT.Part.HAT:
			return hat_thrust
	return null
