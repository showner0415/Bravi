class_name DaySchedule
extends Resource
## 날의 순서. N일차의 손님은 days의 N번째 하루이고, 끝까지 가면 처음으로 돌아간다.
## day_01만 남기면 날마다 같은 손님이 오는 하루다.

@export var days: Array[DayData] = []


## N일차(1부터)의 하루. 빈 칸은 건너뛰고 센다. 쓸 날이 없으면 null.
func day_for(day_number: int) -> DayData:
	var filled: Array[DayData] = []
	for day in days:
		if day != null:
			filled.append(day)
	if filled.is_empty():
		return null
	return filled[posmod(day_number - 1, filled.size())]
