class_name WeaponData
extends Resource
## 플레이어 무기의 수치.

@export var weapon_name := "무기"
## 찌르기(가운데) 예비 시간(초).
@export var thrust_windup := 0.20
## 베기(왼쪽·오른쪽) 예비 시간(초).
@export var cut_windup := 0.35
## 상단을 노릴 때 예비 시간에 곱하는 배율.
@export var high_multiplier := 2.0
## 공격 판정 뒤 회수 시간(초).
@export var recover_time := 0.30
## 패리 창(초). 타격 이 시간 전 안에 새로 누른 막기가 패리다.
@export var parry_window := 0.18
## 막기를 벗어난 뒤 다시 누를 수 있기까지의 시간(초).
@export var guard_cooldown := 0.20
## 간격 한 단계 이동 시간(초).
@export var step_time := 0.30
## 밀착에서 내 공격 예비 시간에 곱하는 배율.
@export var close_windup_multiplier := 0.6


## 조준과 간격으로 정해지는 공격 예비 시간.
func windup_for(direction: int, height: int, distance: int) -> float:
	var t := thrust_windup if direction == DuelTypes.Direction.CENTER else cut_windup
	if height == DuelTypes.Height.HIGH:
		t *= high_multiplier
	if distance == DuelTypes.Distance.CLOSE:
		t *= close_windup_multiplier
	return t
