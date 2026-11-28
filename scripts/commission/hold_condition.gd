class_name HoldCondition
extends CommissionCondition
## 받아 주기: 상대의 공격을 정한 수만큼 받아낸 뒤 이긴다. 그 전에 먼저 댄 칼은 감점이다(계획 048 결정 767·768).
## 상태 없음: 받아냄과 먼저 댄 칼은 매번 record에서 센다. 시각이 아니라 유효타로 끝난다(039 결정 577).

@export var blocks_needed := 12
@export var early_touch_penalty := 35
@export var early_hint := "아직"
@export var ready_text := "이제 쳐라"


func describe() -> String:
	return "받아 주기 — 상대의 공격을 %d번 받아낸(막기 · 받아넘김) 뒤 이긴다. 그 전에 먼저 칼을 대면 감점." % blocks_needed


func check_end(record: DuelRecord) -> String:
	if _won(record):
		return "이겼다 — 받아냄 %d/%d" % [mini(counted_blocks(record), blocks_needed), blocks_needed]
	return ""


func evaluate(record: DuelRecord) -> int:
	if not _won(record):
		return 0
	return maxi(100 - early_touch_penalty * early_touches(record), 0)


func explain(record: DuelRecord) -> Array[String]:
	var lines: Array[String] = []
	lines.append("받아냄 %d/%d" % [mini(counted_blocks(record), blocks_needed), blocks_needed])
	var early := early_touches(record)
	if early > 0:
		lines.append("먼저 댄 칼 %d번 — -%d" % [early, mini(early * early_touch_penalty, 100)])
	if not _won(record):
		lines.append("이기지 못했다 — 0점")
	return lines


## 글에 늘 마디가 실린다: 받는 마디는 early_hint, 다 차면 ready_text(결정 768).
func live_meter(record: DuelRecord) -> Dictionary:
	var count := mini(counted_blocks(record), blocks_needed)
	var tail := ready_text if count >= blocks_needed else early_hint
	return {
		"label": "받아냄",
		"value": int(100.0 * count / maxi(blocks_needed, 1)),
		"pending": 0,
		"text": "받아냄 %d/%d · %s" % [count, blocks_needed, tail],
	}


func stagger_hint(record: DuelRecord) -> String:
	if record.ended or counted_blocks(record) >= blocks_needed:
		return ""
	return early_hint


## 막힘·받아넘김만 센다. 멀리의 헛침과 내가 맞은 것, 밀린 것은 세지 않는다(결정 768).
func counted_blocks(record: DuelRecord) -> int:
	var count := 0
	for ev in record.of_type(DuelRecord.STRIKE):
		if ev["result"] == DuelTypes.StrikeResult.BLOCKED or ev["result"] == DuelTypes.StrikeResult.PARRIED:
			count += 1
	return count


## N번째 받아냄 앞에 난 스침(런지 포함). 판을 끝내는 유효타는 세지 않는다.
func early_touches(record: DuelRecord) -> int:
	var blocks := 0
	var touches := 0
	for ev in record.events:
		if ev["type"] == DuelRecord.STRIKE:
			if ev["result"] == DuelTypes.StrikeResult.BLOCKED or ev["result"] == DuelTypes.StrikeResult.PARRIED:
				blocks += 1
		elif ev["type"] == DuelRecord.ATTACK and blocks < blocks_needed and ev["result"] == DuelTypes.AttackResult.GRAZE:
			touches += 1
	return touches


## N번째 받아냄의 시각. 못 채웠으면 -1.
func reach_time(record: DuelRecord) -> float:
	var blocks := 0
	for ev in record.of_type(DuelRecord.STRIKE):
		if ev["result"] == DuelTypes.StrikeResult.BLOCKED or ev["result"] == DuelTypes.StrikeResult.PARRIED:
			blocks += 1
			if blocks >= blocks_needed:
				return ev["t"]
	return -1.0


func _won(record: DuelRecord) -> bool:
	for ev in record.of_type(DuelRecord.ATTACK):
		if ev["result"] == DuelTypes.AttackResult.HIT:
			return true
	return false
