class_name DuelRules
extends Resource
## 결투 한 판의 공통 규칙 수치.

## 제한 시간(초). 지나면 시간 초과로 끝난다.
@export var time_limit := 90.0
## 플레이어 자세. 이만큼 스침당한 뒤 한 번 더 맞으면 패배한다.
@export var player_posture_max := 3
## 빈틈 인정 유예(초). 상대의 빈틈(회수·무너짐)이 끝난 뒤 이 시간 안에 누른 공격은 섣부른 공격으로 치지 않는다.
@export var opening_grace := 0.15

@export_group("빈틈의 확률 (계획 036c)")
## 날마다 상대의 바탕에 곱하는 값(1일차, 2일차, 3일차부터. 끝 값이 되풀이된다).
## 0.85·0.7에서 3일차 봇의 시간 초과가 13~17%라 한 번 올렸다(결정 405의 기준 10%).
@export var opening_day_scale: Array[float] = [1.0, 0.9, 0.8]
## 깎여도 이 아래로는 내려가지 않는다.
@export var opening_chance_floor := 0.4
## 업그레이드가 더하는 칸(UpgradeData.property가 가리킨다. 결정 406).
@export var opening_chance_bonus := 0.0
## 패리일 때 확률에 더하는 덤(사용자 답 2026-11-25 "패리는 확률에 덤". 결정 400).
@export var parry_opening_bonus := 0.25
## 안 열린 막기 뒤 이 시간 안에 누른 공격은 섣부른 공격이 아니다(열렸는지 보고 누르는 반응 싸움이 되지 않게. 결정 402).
@export var closed_counter_grace := 0.6
## 이 판의 날. 0이면 날이 없다(연습). .tres에 적지 않고 DayState가 사본에 싣는다(결정 406).
@export var stage_day := 0


## 이 판에서 막힘·패리가 빈틈이 될 확률. 바탕이 1.0 이상이면 꺼짐이라 1.0이다(결정 397).
func opening_chance_for(base: float, day: int) -> float:
	if base >= 1.0:
		return 1.0
	var scale := 1.0
	if day > 0 and not opening_day_scale.is_empty():
		scale = opening_day_scale[clampi(day - 1, 0, opening_day_scale.size() - 1)]
	return clampf(base * scale + opening_chance_bonus, opening_chance_floor, 1.0)
