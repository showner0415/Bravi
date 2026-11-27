extends RefCounted
## 결투 한 판의 기록을 수로 줄인다. 실행 확인이 화면 대신 이 수를 읽는다(tests/duel_stats.gd, 게임 창의 BRAVI_EVENT_LOG).
## 판정에 쓰지 않는다.

const DT := preload("res://scripts/duel/duel_types.gd")

const END_NAMES := ["진행 중", "패배", "승리", "시간 초과", "조건 종료"]
const DIR_LETTERS := ["왼", "중", "오"]
const HEIGHT_LETTERS := ["상", "중", "하"]


## 열쇠: length, end, tells, patterns{이름: 수}, routes{길: 수}, strikes{막음·패리·스침·유효타·헛침},
## hits{까닭: 수}, guards{열림·안 열림 — 막힘·패리로 빈틈이 걸린 타격. 결정 408}, openings{닿음·머리 피함·늦음·안 침}, finishers{닿음·놓침}, rash(섣부른 공격 수).
static func summarize(record: DuelRecord) -> Dictionary:
	var out := {
		"length": snappedf(record.elapsed, 0.1), "end": END_NAMES[record.end_reason], "tells": 0,
		"patterns": {}, "routes": {},
		"strikes": {"막음": 0, "패리": 0, "스침": 0, "유효타": 0, "헛침": 0},
		"hits": {},
		"guards": {"열림": 0, "안 열림": 0},
		"openings": {"닿음": 0, "머리 피함": 0, "늦음": 0, "안 침": 0},
		"finishers": {"닿음": 0, "놓침": 0},
		"rash": 0,
		"effects": {"팔 둔함": 0, "다리 덤 씀": 0, "머리 스침": 0},
	}
	var strike_keys := ["헛침", "막음", "패리", "스침", "유효타"]
	# 빈틈 하나의 끝: 열린 뒤 다음 예비 동작 전의 내 첫 공격으로 정한다.
	var opening := false
	var staggered := false
	# 치고 빠지기(결정 708): 직전 타격의 빈틈과, 열린 빠짐의 빈틈 안에서 아직 닿지 않았는가.
	var last_recovery := 0.0
	var chasing := false
	for ev in record.events:
		match ev["type"]:
			DuelRecord.TELL_START:
				if opening:
					out["openings"]["안 침"] += 1
					opening = false
				chasing = false
				out["tells"] += 1
				var atk := ev["attack"] as AttackData
				if not atk.chain.is_empty():
					_bump(out["patterns"], atk.attack_name)
					_bump(out["routes"], "%s %s" % [atk.attack_name, _route(atk, ev.get("heights", []))])
			DuelRecord.DISTANCE:
				# 물러남이 하나라도 있는 판에만 열쇠를 만든다(다른 상대의 요약이 그대로이게).
				if ev.get("by", "") == "withdraw":
					if not out.has("withdraws"):
						out["withdraws"] = {"빠짐": 0, "열린 빠짐": 0, "따라붙어 닿음": 0}
					out["withdraws"]["빠짐"] += 1
					if last_recovery > 0.0:
						out["withdraws"]["열린 빠짐"] += 1
						chasing = true
			DuelRecord.FEINT:
				# 헛손질이 하나라도 있는 판에만 열쇠를 만든다(다른 상대의 요약이 그대로이게. 결정 677).
				if not out.has("feints"):
					out["feints"] = {"헛손질": 0, "속음": 0, "잃은 빈틈": 0}
				out["feints"]["헛손질"] += 1
				if ev["bitten"]:
					out["feints"]["속음"] += 1
			DuelRecord.STRIKE:
				out["strikes"][strike_keys[ev["result"]]] += 1
				last_recovery = float(ev.get("recovery", 0.0))
				if ev.get("bitten", false):
					out["feints"]["잃은 빈틈"] += 1
				if ev.get("closed", false):
					# 헛친 뛰어들기의 안 열림은 막힘·패리의 셈에 넣지 않는다(결정 451).
					if ev["result"] == DT.StrikeResult.BLOCKED or ev["result"] == DT.StrikeResult.PARRIED:
						out["guards"]["안 열림"] += 1
				elif (ev["result"] == DT.StrikeResult.BLOCKED or ev["result"] == DT.StrikeResult.PARRIED) \
						and float(ev.get("recovery", 0.0)) > 0.0 and float(ev.get("next_strike", -1.0)) < 0.0:
					out["guards"]["열림"] += 1
				if ev.get("leg_bonus", &"") != &"":
					out["effects"]["다리 덤 씀"] += 1
				if ev["result"] == DT.StrikeResult.GRAZE or ev["result"] == DT.StrikeResult.HIT:
					_bump(out["hits"], _reason(ev))
				elif float(ev.get("recovery", 0.0)) > 0.0 and float(ev.get("next_strike", -1.0)) < 0.0:
					opening = true
			DuelRecord.STAGGER_START:
				staggered = true
			DuelRecord.STAGGER_END:
				staggered = false
			DuelRecord.ATTACK:
				if ev.get("rash", false):
					out["rash"] += 1
				var reached: bool = ev["result"] == DT.AttackResult.GRAZE or ev["result"] == DT.AttackResult.HIT
				if chasing and (reached or ev.get("dodged", false)):
					chasing = false
					out["withdraws"]["따라붙어 닿음"] += 1
				if ev.get("effect", &"") == &"arm_slow":
					out["effects"]["팔 둔함"] += 1
				if ev["result"] == DT.AttackResult.GRAZE and ev["part"] == DT.Part.HEAD:
					out["effects"]["머리 스침"] += 1
				if opening:
					opening = false
					if reached:
						out["openings"]["닿음"] += 1
					elif ev.get("dodged", false):
						out["openings"]["머리 피함"] += 1
					else:
						out["openings"]["늦음"] += 1
				elif staggered or ev["result"] == DT.AttackResult.HIT:
					out["finishers"]["닿음" if reached else "놓침"] += 1
	if opening:
		out["openings"]["안 침"] += 1
	return out


## 여러 판의 요약을 하나로 더한다(수는 합, length는 평균, end는 {끝: 수}).
static func merge(summaries: Array) -> Dictionary:
	var out := {"runs": summaries.size(), "length": 0.0, "end": {}}
	for s: Dictionary in summaries:
		out["length"] += float(s["length"]) / maxf(1.0, summaries.size())
		_bump(out["end"], s["end"])
		for key: String in s:
			if s[key] is Dictionary:
				if not out.has(key):
					out[key] = {}
				for name in s[key]:
					out[key][name] = int(out[key].get(name, 0)) + int(s[key][name])
			elif key != "length" and key != "end":
				out[key] = int(out.get(key, 0)) + int(s[key])
	out["length"] = snappedf(out["length"], 0.1)
	return out


static func _bump(counts: Dictionary, key: String) -> void:
	counts[key] = int(counts.get(key, 0)) + 1


static func _reason(ev: Dictionary) -> String:
	match ev.get("guard_miss", &""):
		&"height":
			return "높이가 틀린 막기"
		&"regrip":
			return "떼었다 다시 누른 막기"
	var situation := int(ev.get("situation", -1))
	return DT.SITUATION_NAMES[situation] if situation >= 0 else "?"


## 패턴의 길: "오상>왼중>중하". 높이가 없으면 방향만. 치고 빠지는 길의 끝은 "^".
static func _route(root: AttackData, heights: Array) -> String:
	var points: Array[AttackData] = [root]
	for step: AttackData in root.chain:
		points.append(step)
	var parts: PackedStringArray = []
	for i in points.size():
		var h := int(heights[i]) if i < heights.size() else -1
		parts.append(DIR_LETTERS[points[i].direction] + (HEIGHT_LETTERS[h] if h >= 0 else "") + ("~" if points[i].feint else "") + ("^" if root.withdraw and i == points.size() - 1 else ""))
	return ">".join(parts)
