class_name DayData
extends Resource
## 하루에 오는 의뢰의 목록. 배열의 순서대로 온다.

@export var commissions: Array[Commission] = []
## 기준 손님 수. 0이면 목록의 손님이 전부 온다(평판과 상관없다).
## 1 이상이면 목록의 앞에서부터 "기준 + 평판의 별에 따른 증감"명이 온다(ReputationRules.guest_count).
## 기준을 넘는 뒤쪽 자리는 평판이 높을 때만 오는 덤 자리다.
@export var base_guests := 0


## 가진 플래그로 거른 하루. 거를 것이 없으면 이 객체 그대로다(결정 752). 원본은 고치지 않는다.
func for_flags(flags: PackedStringArray) -> DayData:
	var kept: Array[Commission] = []
	for commission in commissions:
		if commission == null or commission.allowed_by(flags):
			kept.append(commission)
	if kept.size() == commissions.size():
		return self
	var filtered := DayData.new()
	filtered.commissions = kept
	filtered.base_guests = base_guests
	return filtered
