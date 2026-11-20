class_name EconomyRules
extends Resource
## 정산과 장부의 수치. 전부 임시다(계획 004).

## 충족도가 이 값을 넘는 만큼에 비례해 팁이 붙는다. 이 값 이하면 팁은 0이다. 0 이상 100 미만.
@export var tip_floor := 70
## 전액 기준치. 충족도가 이 값 이상이면 보수를 전부 받고, 그 아래로 내려가면 그때부터 깎인다.
## 100이면 기준치가 없다(충족도 그대로 계산한다). 1~100으로 잘라 쓴다.
@export var full_pay_score := 100
## 기준치가 팁에도 걸리는가. 거짓이면 기준치는 기본 보수에만 걸리고 팁은 원래 충족도로 계산한다.
@export var full_pay_covers_tip := true
## 팁에 덧붙는 비율(%). 30이면 팁과 팁의 최대가 1.3배다. 업그레이드가 올린다.
@export var tip_bonus_percent := 0
## 기본 보수에 덧붙는 비율(%). 0이면 덧붙임이 없을 때와 같은 값이다.
## 지금은 평판(별)이 그날의 사본에만 더한다(DayState.settle_rules).
@export var base_bonus_percent := 0
## 흥정("값을 올려 부른다")을 받아 준 판의 기본 보수 덧붙임(%). 0이면 흥정이 없다(버튼도 없다).
@export var haggle_bonus_percent := 0
## 흥정한 판의 전액 기준치. 흥정한 판은 충족도가 이 값 이상이어야 보수를 전부 받는다.
@export var haggle_full_pay_score := 100
## 흥정을 받아 줄 확률(%). 차(지금 평판의 별 − 손님의 haggle_min_stars)가 0, +1, +2…일 때의 값이다.
## 표가 끝나면 마지막 값을 계속 쓴다. 비면 100이다(계획 014의 동작).
@export var haggle_chance_met := PackedInt32Array()
## 차가 −1, −2, −3…일 때의 값. 표가 끝나면 마지막 값을 계속 쓴다. 비면 0이다.
@export var haggle_chance_short := PackedInt32Array()
## 흥정을 거절당한 손님의 판에서 팁의 덧붙임(tip_bonus_percent)에서 빼는 값(%). 0이면 감점이 없다.
@export var haggle_refuse_tip_cut_percent := 0
## 하루에 맡을 수 있는 결투의 수. 차면 남은 손님은 만나지 못하고 돌아간다.
@export var duels_per_day := 3
## 하루의 임대료. 가게를 닫을 때 낸다.
@export var rent := 60
## 유효타를 맞고 끝난 결투 한 건의 치료비. 가게를 닫을 때 낸다.
@export var medical_fee := 20
## 첫날의 소지금.
@export var starting_money := 0


## 그 차(지금 평판의 별 − 손님의 haggle_min_stars)에서 흥정을 받아 줄 확률(%, 0~100).
func haggle_chance_for(gap: int) -> int:
	var table: PackedInt32Array = haggle_chance_met if gap >= 0 else haggle_chance_short
	if table.is_empty():
		return 100 if gap >= 0 else 0
	var slot := gap if gap >= 0 else -gap - 1
	return clampi(table[mini(slot, table.size() - 1)], 0, 100)
