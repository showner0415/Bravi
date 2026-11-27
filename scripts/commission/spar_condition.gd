class_name SparCondition
extends CommissionCondition
## 대련: 스치기만으로 상대의 자세를 정해진 횟수 무너뜨리면 끝이고, 무너진 상대를 치면 실패다(계획 043 결정 653~657).
## 상태 없음: 무너뜨린 수와 상처는 매번 record에서 센다. 내가 맞은 스침은 채점하지 않는다.

@export var topples_needed := 3
## 무너뜨린 수별 부분 점수(시간 초과·패배). 칸이 모자라면 마지막 값.
@export var partial_scores := PackedInt32Array([0, 25, 50])
## 무너진 상대를 쳐서 다치게 했을 때의 점수.
@export var wound_score := 0
@export var hold_hint := "치지 마라"


func describe() -> String:
	return "대련 — 스치기만으로 %d번 무너뜨린다. 무너진 상대는 치지 않는다(다치게 하면 실패)." % topples_needed


func check_end(record: DuelRecord) -> String:
	if _wounded(record):
		return "무너진 상대를 쳤다 — 대련이 깨졌다"
	if _topples(record) >= topples_needed:
		return "%d번 무너뜨렸다 — 대련 끝" % topples_needed
	return ""


func evaluate(record: DuelRecord) -> int:
	if _wounded(record):
		return wound_score
	var count := _topples(record)
	if count >= topples_needed:
		return 100
	if partial_scores.is_empty():
		return 0
	return partial_scores[mini(count, partial_scores.size() - 1)]


func explain(record: DuelRecord) -> Array[String]:
	var lines: Array[String] = []
	var score := evaluate(record)
	if _wounded(record):
		lines.append("무너진 상대를 쳐서 다치게 했다 — %d점" % score)
	elif _topples(record) >= topples_needed:
		lines.append("%d번 무너뜨렸다 — %d점" % [topples_needed, score])
	else:
		lines.append("무너뜨린 횟수 %d/%d — %d점" % [_topples(record), topples_needed, score])
	return lines


func live_meter(record: DuelRecord) -> Dictionary:
	var count := mini(_topples(record), topples_needed)
	return {
		"label": "무너뜨림",
		"value": int(100.0 * count / maxi(topples_needed, 1)),
		"pending": 0,
		"text": "무너뜨림 %d/%d" % [count, topples_needed],
	}


## 판이 끝난 뒤(세 번째 무너짐 등)에는 결과 화면에 귀띔이 남지 않게 비운다.
func stagger_hint(record: DuelRecord) -> String:
	if record.ended:
		return ""
	return hold_hint


func _topples(record: DuelRecord) -> int:
	return record.of_type(DuelRecord.STAGGER_START).size()


## 코어에서 유효타(HIT)는 무너진 상대에게만 난다.
func _wounded(record: DuelRecord) -> bool:
	for ev in record.of_type(DuelRecord.ATTACK):
		if ev["result"] == DuelTypes.AttackResult.HIT:
			return true
	return false
