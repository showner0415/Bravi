class_name TargetPartCondition
extends CommissionCondition
## 지정 부위만: 그 부위에 유효타가 들어가면 끝난다. 다른 부위를 건드리면 감점이다.
## 다른 부위의 유효타로는 결투가 끝나지 않는다. 지정 부위의 스침은 감점이 없다.

@export var target_part: DuelTypes.Part = DuelTypes.Part.HAT
## 다른 부위를 스칠 때마다 깎이는 점수.
@export var graze_penalty := 10
## 다른 부위에 유효타가 들어갈 때마다 깎이는 점수.
@export var hit_penalty := 30


func describe() -> String:
	return "%s만 — %s에 유효타 한 번. 다른 곳은 스치기만 해도 감점." % [_target_name(), _target_name()]


func check_end(record: DuelRecord) -> String:
	if _count(record, DuelTypes.AttackResult.HIT, true) > 0:
		return "%s에 유효타" % _target_name()
	return ""


func evaluate(record: DuelRecord) -> int:
	if _count(record, DuelTypes.AttackResult.HIT, true) == 0:
		return 0
	var lost := graze_penalty * _count(record, DuelTypes.AttackResult.GRAZE, false) \
		+ hit_penalty * _count(record, DuelTypes.AttackResult.HIT, false)
	return maxi(100 - lost, 0)


func explain(record: DuelRecord) -> Array[String]:
	var lines: Array[String] = []
	var grazes := _count(record, DuelTypes.AttackResult.GRAZE, false)
	var hits := _count(record, DuelTypes.AttackResult.HIT, false)
	if _count(record, DuelTypes.AttackResult.HIT, true) == 0:
		lines.append("%s에 유효타를 넣지 못했다 — 0점" % _target_name())
	else:
		lines.append("%s에 유효타 — 100점에서 시작" % _target_name())
	if grazes > 0:
		lines.append("다른 부위 스침 %d회 — -%d" % [grazes, grazes * graze_penalty])
	if hits > 0:
		lines.append("다른 부위 유효타 %d회 — -%d" % [hits, hits * hit_penalty])
	return lines


func _target_name() -> String:
	return DuelTypes.PART_NAMES[target_part]


## 결과가 result이고, 부위가 지정 부위인(on_target) 또는 아닌 공격 판정의 수.
func _count(record: DuelRecord, result: int, on_target: bool) -> int:
	var n := 0
	for ev in record.events:
		if ev["type"] == DuelRecord.ATTACK and ev["result"] == result \
				and (ev["part"] == target_part) == on_target:
			n += 1
	return n
