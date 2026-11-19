class_name ThrowUndetectedCondition
extends CommissionCondition
## 티 안 나게 지기: 플레이어가 유효타를 맞아 지는 것이 목표다. 충족도는 100 - 의심도.
## 이기거나 시간 초과면 0점이다.
##
## 의심도는 두 부분이다.
## - 진행 중에 쌓이는 것(게이지의 value, 줄어들지 않는다): 맞을 때의 상황, 공격 없이 버틴 시간, 멀리에 머문 시간
## - 지는 순간에 확정되는 것(게이지의 pending, 조건을 채우면 사라진다): 너무 빨리 짐, 막아낸 횟수 부족, 닿은 횟수 부족

@export_group("맞을 때의 상황")
@export var unguarded_suspicion := 20
@export var wrong_guard_suspicion := 5
@export var in_attack_suspicion := 0

@export_group("소극적인 태도")
## 교전·밀착에서 공격 없이 이 시간(초)이 찰 때마다 의심이 오른다.
@export var idle_period := 6.0
@export var idle_suspicion := 15
## 멀리에 머문 누적 시간이 이 시간(초)을 넘으면 초당 의심이 오른다.
@export var far_allowance := 8.0
@export var far_suspicion_per_second := 5.0

@export_group("지는 순간에 확정")
## 이 시간(초) 안에 지면 의심이 오른다.
@export var min_duration := 30.0
@export var early_loss_suspicion := 30
## 막아낸(막기·패리) 횟수가 이보다 적으면 의심이 오른다.
@export var min_blocks := 4
@export var few_blocks_suspicion := 20
## 상대에게 닿은(스침·유효타) 횟수가 이보다 적으면 의심이 오른다.
@export var min_touches := 2
@export var few_touches_suspicion := 15


func describe() -> String:
	return "티 안 나게 지기 — 유효타를 맞아 진다. 제대로 싸우다 진 것처럼 보여야 한다. 이기면 실패."


func check_end(record: DuelRecord) -> String:
	for ev in record.events:
		if ev["type"] == DuelRecord.ATTACK and ev["result"] == DuelTypes.AttackResult.HIT:
			return "상대에게 유효타 — 이겨 버렸다"
	return ""


func evaluate(record: DuelRecord) -> int:
	if record.end_reason != DuelTypes.EndReason.PLAYER_DEFEATED:
		return 0
	var tally := _tally(record)
	return 100 - mini(100, int(tally["value"]) + int(tally["pending"]))


func explain(record: DuelRecord) -> Array[String]:
	var lines: Array[String] = []
	if record.end_reason != DuelTypes.EndReason.PLAYER_DEFEATED:
		lines.append("지지 못했다 — 0점")
		return lines
	var tally := _tally(record)
	for item: Array in tally["items"]:
		lines.append("%s — 의심 +%d" % [item[0], item[1]])
	var total := mini(100, int(tally["value"]) + int(tally["pending"]))
	if lines.is_empty():
		lines.append("의심받을 만한 것이 없었다")
	lines.append("의심도 %d — 충족도 %d점" % [total, 100 - total])
	return lines


func live_meter(record: DuelRecord) -> Dictionary:
	var tally := _tally(record)
	return {"label": "의심", "value": mini(100, int(tally["value"])), "pending": int(tally["pending"])}


## 기록을 처음부터 훑어 의심도를 센다.
## 돌려주는 것: value(진행 중 누적 합), pending(지금 지면 더해질 합), items([설명, 점수] 목록).
func _tally(record: DuelRecord) -> Dictionary:
	var distance: int = DuelTypes.Distance.FAR
	var last_t := 0.0
	var far_time := 0.0
	var idle_clock := 0.0
	var idle_count := 0
	var taken := [0, 0, 0]  # Situation 순서
	var blocks := 0
	var touches := 0

	for ev in record.events:
		var t: float = ev["t"]
		var gap := t - last_t
		last_t = t
		if distance == DuelTypes.Distance.FAR:
			far_time += gap
		else:
			idle_clock += gap
			while idle_clock >= idle_period:
				idle_clock -= idle_period
				idle_count += 1
		match ev["type"]:
			DuelRecord.DISTANCE:
				distance = ev["distance"]
			DuelRecord.ATTACK:
				# 공격 없이 버틴 시계는 교전·밀착에서 낸 공격의 판정 시각에 0으로 돌아간다.
				# 멀리에서 누른 공격은 닿지 않는 헛손질이라 세지 않는다. 런지는 멀리에서 누르지만 닿는 공격이라 센다.
				if ev["pressed_distance"] != DuelTypes.Distance.FAR or ev.get("lunge", false):
					idle_clock = 0.0
				if ev["result"] == DuelTypes.AttackResult.GRAZE or ev["result"] == DuelTypes.AttackResult.HIT:
					touches += 1
			DuelRecord.STRIKE:
				match ev["result"]:
					DuelTypes.StrikeResult.BLOCKED, DuelTypes.StrikeResult.PARRIED:
						blocks += 1
					DuelTypes.StrikeResult.GRAZE, DuelTypes.StrikeResult.HIT:
						taken[ev["situation"]] += 1

	# 마지막 이벤트부터 지금(record.elapsed)까지.
	var tail := maxf(record.elapsed - last_t, 0.0)
	if distance == DuelTypes.Distance.FAR:
		far_time += tail
	else:
		idle_clock += tail
		while idle_clock >= idle_period:
			idle_clock -= idle_period
			idle_count += 1

	var items: Array = []
	var value := 0
	var per_situation := [unguarded_suspicion, wrong_guard_suspicion, in_attack_suspicion]
	for situation in taken.size():
		var points: int = taken[situation] * per_situation[situation]
		if points > 0:
			items.append(["%s 상태로 맞음 %d회" % [DuelTypes.SITUATION_NAMES[situation], taken[situation]], points])
			value += points
	if idle_count > 0:
		items.append(["공격 없이 %.0f초를 버팀 %d번" % [idle_period, idle_count], idle_count * idle_suspicion])
		value += idle_count * idle_suspicion
	var far_points := int(floor(maxf(far_time - far_allowance, 0.0) * far_suspicion_per_second))
	if far_points > 0:
		items.append(["멀리에 %.0f초 머묾" % far_time, far_points])
		value += far_points

	var pending := 0
	if record.elapsed < min_duration:
		items.append(["%.0f초도 안 되어 짐" % min_duration, early_loss_suspicion])
		pending += early_loss_suspicion
	if blocks < min_blocks:
		items.append(["막아낸 횟수 %d회 (%d회 미만)" % [blocks, min_blocks], few_blocks_suspicion])
		pending += few_blocks_suspicion
	if touches < min_touches:
		items.append(["상대에게 닿은 횟수 %d회 (%d회 미만)" % [touches, min_touches], few_touches_suspicion])
		pending += few_touches_suspicion
	return {"value": value, "pending": pending, "items": items}
