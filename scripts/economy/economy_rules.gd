class_name EconomyRules
extends Resource
## 정산과 장부의 수치. 전부 임시다(계획 004).

## 충족도가 이 값을 넘는 만큼에 비례해 팁이 붙는다. 이 값 이하면 팁은 0이다. 0 이상 100 미만.
@export var tip_floor := 70
## 하루의 임대료. 가게를 닫을 때 낸다.
@export var rent := 60
## 유효타를 맞고 끝난 결투 한 건의 치료비. 가게를 닫을 때 낸다.
@export var medical_fee := 20
## 첫날의 소지금.
@export var starting_money := 0
