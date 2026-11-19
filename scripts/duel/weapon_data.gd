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
## 런지(선공): 방심한 상대에게 멀리에서 뛰어들어 찌르는 공격의 예비 시간(초). 높이와 간격의 배율은 붙지 않는다.
## 예비가 끝나는 시각에 교전에 닿으며 판정한다. 0 이하면 런지가 없다.
@export var lunge_windup := 0.0
## 런지의 판정 뒤 회수 시간(초). 그동안 막을 수 없다.
@export var lunge_recover := 0.45
## 엉킴: 밀착에 있는 동안 엉킴 게이지가 0에서 다 차는 데 걸리는 시간(초). 다 차면 교전으로 밀려난다.
## 0 이하면 엉킴이 없다(밀착에 얼마든지 머문다).
@export var close_bind_time := 0.0
## 밀착이 아닌 동안 엉킴 게이지가 가득에서 다 풀리는 데 걸리는 시간(초). 0 이하면 밀착을 벗어나는 즉시 0이 된다.
@export var close_bind_release_time := 0.0
## 엉킴이 다 차서 교전으로 밀려나는 데 걸리는 시간(초). 그동안 막거나 칠 수 없다.
@export var close_shove_time := 0.45


## 조준과 간격으로 정해지는 공격 예비 시간.
func windup_for(direction: int, height: int, distance: int) -> float:
	var t := thrust_windup if direction == DuelTypes.Direction.CENTER else cut_windup
	if height == DuelTypes.Height.HIGH:
		t *= high_multiplier
	if distance == DuelTypes.Distance.CLOSE:
		t *= close_windup_multiplier
	return t
