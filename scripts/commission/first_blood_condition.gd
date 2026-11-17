class_name FirstBloodCondition
extends CommissionCondition
## 첫 피: 상대의 몸에 유효타 한 번이면 끝난다. 머리는 피를 보지만 감점이다.
## 스침은 점수에 영향이 없고, 모자(깃털)는 피가 아니라 세지 않는다.

## 유효타가 들어가면 만점인 부위.
@export var clean_parts: Array[DuelTypes.Part] = [
	DuelTypes.Part.TORSO, DuelTypes.Part.SWORD_ARM, DuelTypes.Part.LEGS,
]
## 유효타가 들어가면 결투는 끝나지만 감점인 부위.
@export var risky_parts: Array[DuelTypes.Part] = [DuelTypes.Part.HEAD]
@export var clean_score := 100
@export var risky_score := 40


func describe() -> String:
	return "첫 피 — 상대의 몸통·팔·다리에 유효타 한 번. 머리를 치면 감점."


func check_end(record: DuelRecord) -> String:
	var hit := _first_blood(record)
	if hit.is_empty():
		return ""
	return "첫 피 — %s" % DuelTypes.PART_NAMES[hit["part"]]


func evaluate(record: DuelRecord) -> int:
	var hit := _first_blood(record)
	if hit.is_empty():
		return 0
	return risky_score if risky_parts.has(hit["part"]) else clean_score


func explain(record: DuelRecord) -> Array[String]:
	var lines: Array[String] = []
	var hit := _first_blood(record)
	if hit.is_empty():
		lines.append("피를 보지 못했다 — 0점")
	elif risky_parts.has(hit["part"]):
		lines.append("%s에 유효타 — 위험한 곳이라 %d점" % [DuelTypes.PART_NAMES[hit["part"]], risky_score])
	else:
		lines.append("%s에 유효타 — %d점" % [DuelTypes.PART_NAMES[hit["part"]], clean_score])
	return lines


## 피를 본 첫 유효타. 없으면 빈 Dictionary.
func _first_blood(record: DuelRecord) -> Dictionary:
	for ev in record.events:
		if ev["type"] == DuelRecord.ATTACK and ev["result"] == DuelTypes.AttackResult.HIT \
				and (clean_parts.has(ev["part"]) or risky_parts.has(ev["part"])):
			return ev
	return {}
