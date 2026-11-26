class_name PartEffectData
extends Resource
## 부위별 반격의 손맛 값(계획 R02). 상대 데이터의 part_effects가 비어 있으면 옛 규칙이다.
## 값은 전부 임시이고 data/part_effects.tres 한 파일에서 바뀐다. 0·거짓이면 그 효과가 꺼진다.

## 더한 뒤의 내 예비 시간이 내려가지 않는 바닥(초).
const MIN_WINDUP := 0.05

## 조준 미리보기를 보인다.
@export var show_forecast := true

@export_group("팔")
## 칼 든 팔을 스치면 다음 몇 번의 예비 동작이 길어지는가. 0이면 꺼짐.
@export var arm_slow_tells := 3
@export var arm_tell_multiplier := 1.25

@export_group("다리")
## 다리를 스치면 다음 패리 성공에 덤이 몇 번 붙는가. 0이면 꺼짐.
@export var legs_parry_charges := 1
## 덤 없이는 안 열릴 굴림을 열어 주는 확률 덤과, 덤 없이도 열렸을 패리에 더하는 빈틈의 초.
@export var legs_parry_opening_bonus := 0.30
@export var legs_open_time_bonus := 0.30

@export_group("조준 부위별 예비 (초)")
## 그 부위를 노릴 때 내 예비에 더하는 초(밀착 배율을 곱한 뒤). 음수도 받는다. 몸통의 칸은 없다.
@export var arm_windup_extra := 0.0
@export var legs_windup_extra := 0.10
@export var head_windup_extra := 0.0
@export var hand_windup_extra := 0.0

@export_group("머리")
## 참이면 머리는 큰 공격 뒤의 회수에서만 열린다(패리만으로는 열리지 않는다).
@export var head_big_only := true
## 그 회수가 시작되고 이만큼 안에만 닿는다. 0 이하면 회수 내내.
@export var head_exposed_time := 0.9


## 그 부위를 노릴 때 예비에 더하는 초.
func windup_extra(part: int) -> float:
	match part:
		DuelTypes.Part.SWORD_ARM:
			return arm_windup_extra
		DuelTypes.Part.LEGS:
			return legs_windup_extra
		DuelTypes.Part.HEAD:
			return head_windup_extra
		DuelTypes.Part.SWORD_HAND:
			return hand_windup_extra
	return 0.0
