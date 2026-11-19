class_name FirstBloodCondition
extends CommissionCondition
## 첫 피: 상대의 몸에 유효타 한 번이면 끝난다. 머리는 피를 보지만 감점이다.
## 스침은 점수에 영향이 없고(risky_graze_penalty를 켜지 않는 한), 모자(깃털)는 피가 아니라 세지 않는다.

## 유효타가 들어가면 만점인 부위.
@export var clean_parts: Array[DuelTypes.Part] = [
	DuelTypes.Part.TORSO, DuelTypes.Part.SWORD_ARM, DuelTypes.Part.SWORD_HAND, DuelTypes.Part.LEGS,
]
## 유효타가 들어가면 결투는 끝나지만 감점인 부위.
@export var risky_parts: Array[DuelTypes.Part] = [DuelTypes.Part.HEAD]
@export var clean_score := 100
@export var risky_score := 40
## 위험 부위를 스칠 때마다 깎는 점수. 0이면 스침을 채점하지 않는다(기본).
@export var risky_graze_penalty := 0


func describe() -> String:
	var body := "상대의 몸통·팔·손·다리에 유효타 한 번. 머리를 치면 감점."
	if risky_graze_penalty > 0:
		return "첫 피 — %s 머리는 스치기만 해도 감점." % body
	return "첫 피 — 유효타만 본다. %s" % body


func check_end(record: DuelRecord) -> String:
	var hit := _first_blood(record)
	if hit.is_empty():
		return ""
	return "첫 피 — %s" % DuelTypes.PART_NAMES[hit["part"]]


func evaluate(record: DuelRecord) -> int:
	var hit := _first_blood(record)
	if hit.is_empty():
		return 0
	var score := risky_score if risky_parts.has(hit["part"]) else clean_score
	if risky_graze_penalty > 0:
		score = maxi(score - risky_graze_penalty * _risky_grazes(record), 0)
	return score


func explain(record: DuelRecord) -> Array[String]:
	var lines: Array[String] = []
	var hit := _first_blood(record)
	if hit.is_empty():
		lines.append("피를 보지 못했다 — 0점")
		return lines
	if risky_parts.has(hit["part"]):
		lines.append("%s에 유효타 — 위험한 곳이라 %d점" % [DuelTypes.PART_NAMES[hit["part"]], risky_score])
	else:
		lines.append("%s에 유효타 — %d점" % [DuelTypes.PART_NAMES[hit["part"]], clean_score])
	var grazes := _risky_grazes(record)
	if risky_graze_penalty > 0 and grazes > 0:
		lines.append("머리 스침 %d회 — -%d x %d" % [grazes, risky_graze_penalty, grazes])
	return lines


## 피를 본 첫 유효타. 없으면 빈 Dictionary.
func _first_blood(record: DuelRecord) -> Dictionary:
	for ev in record.events:
		if ev["type"] == DuelRecord.ATTACK and ev["result"] == DuelTypes.AttackResult.HIT \
				and (clean_parts.has(ev["part"]) or risky_parts.has(ev["part"])):
			return ev
	return {}


## 위험 부위를 스친 횟수.
func _risky_grazes(record: DuelRecord) -> int:
	var count := 0
	for ev in record.events:
		if ev["type"] == DuelRecord.ATTACK and ev["result"] == DuelTypes.AttackResult.GRAZE \
				and risky_parts.has(ev["part"]):
			count += 1
	return count
