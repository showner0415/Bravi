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
## 하루에 맡을 수 있는 결투의 수. 차면 남은 손님은 만나지 못하고 돌아간다.
@export var duels_per_day := 3
## 하루의 임대료. 가게를 닫을 때 낸다.
@export var rent := 60
## 유효타를 맞고 끝난 결투 한 건의 치료비. 가게를 닫을 때 낸다.
@export var medical_fee := 20
## 첫날의 소지금.
@export var starting_money := 0
