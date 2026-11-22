extends RefCounted
## T71: 반응 싸움 확인의 기록(계획 030 결정 273). 만든 기록으로 lead·late, 곡선의 차례, 켜는 길을 본다.

const DT := preload("res://scripts/duel/duel_types.gd")
const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T71", "name": "반응 싸움의 기록: 앞선 막기·늦은 막기, ABBA 차례, 켜는 길", "fn": t71_curve_check},
	]


func _thrust() -> AttackData:
	for atk in (load(OPPONENT_PATH) as OpponentData).attacks:
		if atk.direction == DT.Direction.CENTER and not atk.is_big:
			return atk
	return null


func t71_curve_check() -> String:
	var errs: Array[String] = []
	var atk := _thrust()
	var rec := DuelRecord.new()
	rec.add({"type": DuelRecord.TELL_START, "t": 1.0, "attack": atk, "strike_time": 1.65, "duration": 0.65, "is_habit": false})
	rec.add({"type": DuelRecord.GUARD_START, "t": 1.5, "fresh": true})
	rec.add({"type": DuelRecord.STRIKE, "t": 1.65, "attack": atk, "result": DT.StrikeResult.PARRIED})
	rec.add({"type": DuelRecord.TELL_START, "t": 3.0, "attack": atk, "strike_time": 3.65, "duration": 0.65, "is_habit": false})
	rec.add({"type": DuelRecord.GUARD_START, "t": 3.6, "fresh": false})
	rec.add({"type": DuelRecord.STRIKE, "t": 3.65, "attack": atk, "result": DT.StrikeResult.BLOCKED})
	rec.add({"type": DuelRecord.GUARD_START, "t": 3.85, "fresh": true})
	var rows := CurveCheck.rows(rec, "hold", "1", "s")
	if rows.size() != 2:
		return "줄 %d (기대 2)" % rows.size()
	var a := ",".join(rows[0])
	var b := ",".join(rows[1])
	if a != "s,1,hold,%s,false,false,1.650,PARRIED,0.150," % atk.attack_name:
		errs.append("첫 줄 %s" % a)
	if b != "s,1,hold,%s,false,false,3.650,BLOCKED,,0.200" % atk.attack_name:
		errs.append("둘째 줄 %s" % b)
	var order := ""
	for i in range(1, 9):
		order += "H" if CurveCheck.curve_for(i) else "F"
	if not CurveCheck.curve_for(0) or order != "HFFHHFFH":
		errs.append("곡선의 차례 %s (기대 몸풀기 H, HFFHHFFH)" % order)
	var cases := [
		[PackedStringArray([CurveCheck.ARG]), "", true], [PackedStringArray(), "1", true],
		[PackedStringArray(), "", false], [PackedStringArray(), "0", false],
	]
	for c in cases:
		if CurveCheck.enabled_from(c[0], c[1]) != c[2]:
			errs.append("enabled_from(%s, '%s')가 %s가 아님" % [str(c[0]), c[1], c[2]])
	if CurveCheck.enabled():
		errs.append("테스트 실행에서 켜져 있음(BRAVI_CURVE_CHECK를 지운 창에서 돌린다)")
	return "OK" if errs.is_empty() else ", ".join(errs)
