class_name DayData
extends Resource
## 하루에 오는 의뢰의 목록. 배열의 순서대로 온다.

@export var commissions: Array[Commission] = []
## 기준 손님 수. 0이면 목록의 손님이 전부 온다(평판과 상관없다).
## 1 이상이면 목록의 앞에서부터 "기준 + 평판의 별에 따른 증감"명이 온다(ReputationRules.guest_count).
## 기준을 넘는 뒤쪽 자리는 평판이 높을 때만 오는 덤 자리다.
@export var base_guests := 0
