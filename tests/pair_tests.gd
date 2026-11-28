extends RefCounted
## T148~T152: 둘이 함께(계획 047, 결정 747~765). 플래그와 거르기, 한 자리 두 쪽, 플래그의 저장, 네 의뢰와 이레 일정, 네 판.
## 판은 씬 없이 코어와 봇만 건다. States.put을 쓰지 않고, 화면은 붙인 뒤 advance·tick 없이 글만 읽는다(계획 043 T1).
## 값(보수·감점·자세 칸)은 .tres에서 읽는다: 결정 760의 사다리가 자세 칸을 옮겨도 이 파일은 그대로다.

const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Store := preload("res://scripts/save_store.gd")
const Counter := preload("res://scripts/commission/counter.gd")

const VARIANT_DIR := "res://data/commissions/variants/"
const PAIR_HATTER_PATH := VARIANT_DIR + "pair_hatter.tres"
const PAIR_BAKER_PATH := VARIANT_DIR + "pair_baker.tres"
const AFTER_HATTER_PATH := VARIANT_DIR + "after_hatter.tres"
const AFTER_BAKER_PATH := VARIANT_DIR + "after_baker.tres"
const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const COMMISSION_DIR := "res://data/commissions"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const BEATRICE_PATH := "res://data/opponents/opponent_06.tres"
const GUGLIELMO_PATH := "res://data/opponents/opponent_07.tres"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const REPUTATION_PATH := "res://data/reputation_rules.tres"
const SCHEDULE_PATH := "res://data/day_schedule.tres"
const DAY_DIR := "res://data/days/"
const TEST_PATH := "user://bravi_test_pair_save.json"
const DELTA := 1.0 / 60.0
const HARD_STOP := 400.0
const TIP_FLOOR := 70
## 6 · 7일차의 평판 배율(%): 3일차부터 200이다.
const SCALE_DAY6 := 200
const ALL_FLAGS: Array[String] = ["sided_hatter", "sided_baker", "baker_helped", "hatter_rematch", "x"]

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T148", "name": "플래그와 거르기: allowed_by의 여섯 갈래, for_flags(같은 객체 · 새 객체), 맡아 정산하면 남고 돌려보내면 안 남고 내일 아침부터 거른다", "fn": t148_flags},
		{"id": "T149", "name": "한 자리, 두 쪽: 말하는 쪽의 전환, 흥정하면 굳는다, 짝 쪽을 맡기, 둘 다 돌려보내기, 카운터의 두 사람과 버튼 글", "fn": t149_pair_slot},
		{"id": "T150", "name": "플래그의 저장: 아침의 flags, 폐점의 flags와 거른 목록, 옛 저장, 쓰레기, GameSession의 길", "fn": t150_flag_save},
		{"id": "T151", "name": "네 의뢰와 이레: 데이터(상대가 엇갈린다, 짝 하나, 플래그), 일정의 여섯째 · 일곱째, 플래그별 목록, 6 · 7일차의 단", "fn": t151_data_and_week},
		{"id": "T152", "name": "네 판: 모자 · 대련 · 칼 든 손을 봇이 끝낸다, 티 안 나게 지기의 기록 셈, 정산의 세 구간과 평판 항목", "fn": t152_duels},
	]


func cleanup() -> void:
	Store.erase(TEST_PATH)
	_tree = null


# ================================================================ 도우미

func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _economy() -> EconomyRules:
	return load(Session.ECONOMY_PATH) as EconomyRules


func _reputation() -> ReputationRules:
	return load(REPUTATION_PATH) as ReputationRules


## 이름과 플래그만 가진 시험용 의뢰(조건이 없어 0점으로 정산된다).
func _plain(client_name: String, sets := [], requires := [], excluded := []) -> Commission:
	var c := Commission.new()
	c.client_name = client_name
	c.base_reward = 10
	c.tip_max = 5
	c.haggle_min_stars = 3
	c.sets_flags = PackedStringArray(sets)
	c.requires_flags = PackedStringArray(requires)
	c.excluded_flags = PackedStringArray(excluded)
	return c


func _day_data(list_of: Array, base := 0) -> DayData:
	var data := DayData.new()
	var typed: Array[Commission] = []
	for c in list_of:
		typed.append(c as Commission)
	data.commissions = typed
	data.base_guests = base
	return data


func _schedule(days: Array) -> DaySchedule:
	var schedule := DaySchedule.new()
	var typed: Array[DayData] = []
	for d in days:
		typed.append(d as DayData)
	schedule.days = typed
	return schedule


## 평판 규칙을 싣거나(with_rep) 안 실은 하루. 날 번호는 바로 넣는다(처음 하루가 이미 시작된 뒤다).
func _day_of(list_of: Array, day_number := 6, with_rep := false) -> DayState:
	var rep := _reputation() if with_rep else null
	var day := DayState.new(_economy(), _day_data(list_of), null, null, rep)
	day.day_number = day_number
	return day


func _end_record(reason: int) -> DuelRecord:
	var rec := DuelRecord.new()
	rec.ended = true
	rec.end_reason = reason
	rec.elapsed = 90.0
	return rec


## 맡아 정산한다(현재 말하는 쪽). 손님은 하나뿐이어야 한다.
func _take(day: DayState, reason := DT.EndReason.TIME_UP) -> void:
	day.accept()
	day.finish_duel(_end_record(reason))


## 정산 뒤에서 폐점까지 민다(남은 손님은 돌려보낸다).
func _to_closing(day: DayState) -> void:
	var guard := 0
	while day.phase != DayState.Phase.CLOSING and guard < 40:
		if day.phase == DayState.Phase.SETTLEMENT:
			day.proceed()
		elif day.phase == DayState.Phase.COUNTER:
			day.decline()
		else:
			break
		guard += 1


## 시험용 짝: 목록에 서는 쪽 P와 그 짝 Q, 짝 없는 X.
func _pair_set() -> Dictionary:
	var q := _plain("짝")
	q.reputation_effect = {"accept": 1, "success": 5, "fail": -4}
	q.sets_flags = PackedStringArray(["from_q"])
	q.decline_line = "짝의 돌려보냄"
	var p := _plain("목록")
	p.partner = q
	p.reputation_effect = {"accept": 0, "success": 1, "fail": -1}
	p.sets_flags = PackedStringArray(["from_p"])
	p.decline_line = "목록의 돌려보냄"
	return {"p": p, "q": q, "x": _plain("홀로")}


func _spar_rec(topples: int) -> DuelRecord:
	var rec := DuelRecord.new()
	for i in topples:
		rec.add({"type": DuelRecord.STAGGER_START, "t": 1.0 + i})
	return rec


## 손으로 만든 기록: 내 ATTACK 이벤트 [결과, 부위] 목록과 끝.
func _rec(attacks: Array, end_reason: int) -> DuelRecord:
	var rec := DuelRecord.new()
	var t := 5.0
	for row: Array in attacks:
		rec.add({"type": DuelRecord.ATTACK, "t": t, "result": row[0], "part": row[1]})
		t += 1.0
	rec.ended = true
	rec.end_reason = end_reason
	rec.elapsed = t + 5.0
	return rec


## 티 안 나게 지기의 기록: 막기 넷 · 닿음 여섯 · 40초 뒤 패배. 마지막 맞음의 상황만 인자다.
func _throw_rec(situation: int) -> DuelRecord:
	var rec := DuelRecord.new()
	var events: Array[Dictionary] = [{"type": DuelRecord.DISTANCE, "t": 0.5, "distance": DT.Distance.ENGAGE}]
	for k in 6:
		events.append({"type": DuelRecord.ATTACK, "t": 5.0 + 5.0 * k, "result": DT.AttackResult.GRAZE, "part": DT.Part.TORSO,
			"pressed_distance": DT.Distance.ENGAGE})
	for k in 4:
		events.append({"type": DuelRecord.STRIKE, "t": 6.0 + 6.0 * k, "result": DT.StrikeResult.BLOCKED, "situation": DT.Situation.UNGUARDED})
	events.append({"type": DuelRecord.STRIKE, "t": 35.0, "result": DT.StrikeResult.HIT, "situation": situation})
	# 시각순으로 넣는다: 조건의 셈이 앞 이벤트와의 간격으로 쉼을 센다.
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	for ev in events:
		rec.add(ev)
	rec.ended = true
	rec.end_reason = DT.EndReason.PLAYER_DEFEATED
	rec.elapsed = 40.0
	return rec


## 카운터를 붙이고(처리는 그대로) 돌려준다. 호출한 쪽이 free()한다. advance · tick 없이 글만 읽는다.
func _counter(day: DayState) -> Node:
	var counter: Node = (load(Session.COUNTER_PATH) as PackedScene).instantiate()
	counter.set("day", day)
	_tree.root.add_child(counter)
	return counter


func _button(screen: Node, node_name: String) -> Button:
	return screen.find_child(node_name, true, false) as Button


func _any_label_contains(screen: Node, needle: String) -> bool:
	for child in screen.find_children("*", "Label", true, false):
		if (child as Label).text.contains(needle):
			return true
	return false


# ================================================================ T148 플래그와 거르기

func t148_flags() -> String:
	var errs: Array[String] = []
	_check_allowed(errs)
	_check_for_flags(errs)
	_check_flow(errs)
	return _ok(errs)


func _check_allowed(errs: Array[String]) -> void:
	var blank := _plain("빈칸")
	_expect(errs, blank.allowed_by(PackedStringArray()) and blank.allowed_by(PackedStringArray(["a", "b"])), "[① 빈 칸] 늘 참이 아니다")
	var need := _plain("필요", [], ["a", "b"])
	_expect(errs, not need.allowed_by(PackedStringArray()), "[① requires] 플래그 없음인데 참")
	_expect(errs, not need.allowed_by(PackedStringArray(["a"])), "[① requires] 하나만 있는데 참(모두 있어야 한다)")
	_expect(errs, need.allowed_by(PackedStringArray(["a", "b", "c"])), "[① requires] 모두 있는데 거짓")
	var ban := _plain("금지", [], [], ["a", "b"])
	_expect(errs, ban.allowed_by(PackedStringArray()) and ban.allowed_by(PackedStringArray(["c"])), "[① excluded] 없는데 거짓")
	_expect(errs, not ban.allowed_by(PackedStringArray(["b"])), "[① excluded] 하나라도 있으면 거짓이어야 한다")
	var both := _plain("둘 다", [], ["a"], ["z"])
	_expect(errs, both.allowed_by(PackedStringArray(["a"])) and not both.allowed_by(PackedStringArray(["a", "z"])) and not both.allowed_by(PackedStringArray()),
		"[① 둘 다] requires · excluded가 함께 걸리는 갈래가 틀림")


func _check_for_flags(errs: Array[String]) -> void:
	var blank := _plain("빈칸")
	var need := _plain("필요", [], ["a"])
	var plain_day := _day_data([blank], 3)
	_expect(errs, plain_day.for_flags(PackedStringArray(["a"])) == plain_day, "[②] 거를 것이 없는데 새 객체")
	var mixed := _day_data([blank, need], 4)
	var none := mixed.for_flags(PackedStringArray())
	_expect(errs, none != mixed and none.commissions.size() == 1 and none.commissions[0] == blank and none.base_guests == 4, "[②] 거르면 새 객체 · 거른 목록 · 같은 base_guests")
	_expect(errs, mixed.commissions.size() == 2, "[②] 원본의 목록 길이가 바뀜 (%d)" % mixed.commissions.size())
	_expect(errs, mixed.for_flags(PackedStringArray(["a"])) == mixed, "[②] 모두 통과하는데 새 객체")
	for n in range(1, 6):
		var real := load(DAY_DIR + "day_0%d.tres" % n) as DayData
		for flag in ALL_FLAGS:
			_expect(errs, real.for_flags(PackedStringArray([flag])) == real, "[②] day_0%d가 플래그 %s에 같은 객체가 아님" % [n, flag])
		_expect(errs, real.for_flags(PackedStringArray(ALL_FLAGS)) == real, "[②] day_0%d가 모든 플래그에 같은 객체가 아님" % n)


func _check_flow(errs: Array[String]) -> void:
	var a := _plain("A", ["x"])
	var d := _plain("D")
	var day1 := _day_data([a, d])
	var r := _plain("R", [], ["x"])
	var e := _plain("E", [], [], ["x"])
	var p := _plain("P")
	var day2 := _day_data([r, e, p])
	var schedule := _schedule([day1, day2])
	var day := DayState.new(_economy(), day1, null, schedule, null)
	_expect(errs, day.data == day1 and day.flags.is_empty(), "[③] 1일차의 data가 원본이 아니거나 플래그가 비어 있지 않다")
	_expect(errs, day.tomorrow_data().commissions.size() == 2 and day.tomorrow_data().commissions[0] == e and day.tomorrow_guests() == 2, "[③] 정산 전 내일 목록 %d (기대 [E, P])" % day.tomorrow_data().commissions.size())
	_take(day)
	_expect(errs, day.flags == PackedStringArray(["x"]), "[③] 맡아 정산한 뒤 flags %s (기대 [x])" % str(day.flags))
	_expect(errs, day.data == day1 and day.commission_count() == 2, "[③] 하루 중에 손님 목록이 바뀜")
	_expect(errs, day.tomorrow_data().commissions.size() == 2 and day.tomorrow_data().commissions[0] == r and day.tomorrow_data().commissions[1] == p,
		"[③] 내일 목록이 [R, P]가 아님")
	_expect(errs, day.tomorrow_guests() == 2, "[③] 내일 손님 수 %d (기대 2)" % day.tomorrow_guests())
	_to_closing(day)
	_expect(errs, day.phase == DayState.Phase.CLOSING and day.next_day(), "[③] 폐점에서 다음 날로 넘어가지 못함")
	_expect(errs, day.day_number == 2 and day.data.commissions.size() == 2 and day.data.commissions[0] == r and day.data.commissions[1] == p,
		"[③] 2일차의 목록이 [R, P]가 아님 (%d명)" % day.data.commissions.size())
	_expect(errs, day.flags == PackedStringArray(["x"]), "[③] 날을 넘으며 flags가 바뀜")
	# ④ 돌려보내면 남지 않는다. 0점(시간 초과)으로 정산해도 남는다. 겹치지 않고 빈 글은 넣지 않는다.
	var declined_day := DayState.new(_economy(), _day_data([_plain("A", ["x"])]), null, null, null)
	declined_day.decline()
	_expect(errs, declined_day.flags.is_empty(), "[④] 돌려보냈는데 플래그가 남음")
	var zero_day := DayState.new(_economy(), _day_data([_plain("A", ["x", "x", ""]), _plain("A2", ["x", "y"])]), null, null, null)
	_take(zero_day, DT.EndReason.TIME_UP)
	_expect(errs, int(zero_day.last_result()["score"]) == 0, "[④] 시험 의뢰의 점수가 0이 아님")
	_expect(errs, zero_day.flags == PackedStringArray(["x"]), "[④] 0점 정산 뒤 flags %s (기대 [x] — 겹침 · 빈 글 없음)" % str(zero_day.flags))
	zero_day.proceed()
	_take(zero_day, DT.EndReason.TIME_UP)
	_expect(errs, zero_day.flags == PackedStringArray(["x", "y"]), "[④] 둘째 정산 뒤 flags %s (기대 [x, y])" % str(zero_day.flags))


# ================================================================ T149 한 자리, 두 쪽

func t149_pair_slot() -> String:
	var errs: Array[String] = []
	_check_switch(errs)
	_check_haggle_lock(errs)
	_check_take_partner(errs)
	_check_decline_both(errs)
	_check_counter_screen(errs)
	return _ok(errs)


func _check_switch(errs: Array[String]) -> void:
	var s := _pair_set()
	var day := _day_of([s["p"], s["x"]])
	_expect(errs, day.current_commission() == s["p"] and day.partner_commission() == s["q"], "[①] 처음엔 목록의 의뢰가 말하고 짝이 뒤에 선다")
	_expect(errs, day.can_switch_side() and day.switch_side(), "[①] 짝의 말을 들을 수 없다")
	_expect(errs, day.current_commission() == s["q"] and day.partner_commission() == s["p"], "[①] 전환 뒤 말하는 쪽이 짝이 아님")
	_expect(errs, day.switch_side() and day.current_commission() == s["p"] and day.partner_commission() == s["q"], "[①] 다시 전환하면 목록의 의뢰로 돌아와야 한다")
	# ② 짝 없는 자리.
	var alone := _day_of([s["x"]])
	_expect(errs, alone.partner_commission() == null and not alone.can_switch_side(), "[②] 짝이 없는데 전환할 수 있다고 함")
	var before_index := alone.index
	_expect(errs, not alone.switch_side() and alone.current_commission() == s["x"] and alone.index == before_index and alone.phase == DayState.Phase.COUNTER,
		"[②] 짝이 없는 자리에서 switch_side가 거짓이 아니거나 상태가 바뀜")


func _check_haggle_lock(errs: Array[String]) -> void:
	for row: Array in [["받아 줌", 3, 0], ["거절", 5, 99]]:
		var s := _pair_set()
		(s["p"] as Commission).haggle_min_stars = int(row[1])
		var day := _day_of([s["p"]], 6, true)
		_expect(errs, day.can_switch_side(), "[③ %s] 흥정 전에는 전환할 수 있어야 한다" % row[0])
		_expect(errs, day.haggle(int(row[2])) and day.haggle_state() != DayState.Haggle.NONE, "[③ %s] 흥정이 되지 않음" % row[0])
		_expect(errs, not day.can_switch_side() and not day.switch_side() and day.current_commission() == s["p"], "[③ %s] 값을 부른 뒤에 전환됨" % row[0])
	var s2 := _pair_set()
	var agreed := _day_of([s2["p"]], 6, true)
	agreed.haggle(0)
	_expect(errs, agreed.haggle_state() == DayState.Haggle.AGREED, "[③] 받아 줌 주사위가 받아 줌이 아님")


func _check_take_partner(errs: Array[String]) -> void:
	var s := _pair_set()
	var day := _day_of([s["p"]], 6, true)
	day.switch_side()
	day.accept()
	day.finish_duel(_end_record(DT.EndReason.TIME_UP))
	var result := day.last_result()
	_expect(errs, result["client_name"] == "짝", "[④] 정산의 client_name '%s' (기대 짝)" % result["client_name"])
	var rep := _reputation()
	var want := rep.settle_items((s["q"] as Commission).reputation_effect, int(result["score"]), day.effective_rules().tip_floor, bool(result["won"]), rep.scale_for_day(6))
	_expect(errs, result["reputation_items"] == want, "[④] 평판 항목 %s (기대 짝의 값 %s)" % [str(result["reputation_items"]), str(want)])
	_expect(errs, day.flags == PackedStringArray(["from_q"]), "[④] 플래그 %s (기대 짝의 [from_q])" % str(day.flags))


func _check_decline_both(errs: Array[String]) -> void:
	var s := _pair_set()
	var day := _day_of([s["p"], s["x"]])
	_expect(errs, day.decline(), "[⑤] 둘 다 돌려보내지 못함")
	_expect(errs, day.declined.size() == 1 and day.declined[0] == "목록 · 짝", "[⑤] declined %s (기대 한 칸 '목록 · 짝')" % str(day.declined))
	_expect(errs, day.last_declined["client_name"] == "목록" and day.last_declined["line"] == "목록의 돌려보냄", "[⑤] last_declined가 말하던 쪽이 아님")
	_expect(errs, day.current_commission() == s["x"] and day.can_switch_side() == false, "[⑤] 다음 손님이 목록의 것이 아니거나 전환됨")
	# 짝의 말을 듣다가 돌려보내면 말하던 쪽은 짝이다. 다음 손님은 늘 목록 쪽(_side 0).
	var s2 := _pair_set()
	var other := _day_of([s2["p"], s2["p"].duplicate(), s2["x"]])
	other.switch_side()
	other.decline()
	_expect(errs, other.last_declined["client_name"] == "짝" and other.last_declined["line"] == "짝의 돌려보냄", "[⑤] 짝이 말하던 중의 last_declined가 짝의 것이 아님")
	_expect(errs, other.current_commission() == other.data.commissions[1], "[⑤] 다음 손님에서 _side가 0으로 돌아오지 않음")
	# 폐점의 missed: 짝 있는 한 자리는 짝 없는 한 자리와 같다.
	var s3 := _pair_set()
	var paired := _day_of([s3["p"], s3["x"]])
	paired.decline()
	paired.decline()
	var single := _day_of([_plain("목록"), _plain("홀로")])
	single.decline()
	single.decline()
	_expect(errs, paired.phase == DayState.Phase.CLOSING and single.phase == DayState.Phase.CLOSING, "[⑤] 폐점에 가지 못함")
	_expect(errs, paired.closing_summary()["missed"] == single.closing_summary()["missed"], "[⑤] missed %s (기대 %s — 짝 없는 같은 하루)" % [
		str(paired.closing_summary()["missed"]), str(single.closing_summary()["missed"])])


func _check_counter_screen(errs: Array[String]) -> void:
	var hatter := load(PAIR_HATTER_PATH) as Commission
	var baker := load(PAIR_BAKER_PATH) as Commission
	if hatter == null or baker == null:
		errs.append("[⑥] pair_hatter · pair_baker가 로드되지 않는다")
		return
	var day := _day_of([hatter], 6, true)
	var counter := _counter(day)
	_expect(errs, counter.find_child("Partner", true, false) != null, "[⑥] Partner가 없다")
	var switch_button := _button(counter, "SwitchSide")
	_expect(errs, switch_button != null and switch_button.text == Counter.SWITCH_BUTTON % baker.client_name and not switch_button.disabled,
		"[⑥] SwitchSide의 글이 '%s'가 아님" % (switch_button.text if switch_button != null else "(없음)"))
	_expect(errs, _button(counter, "Proceed") != null and _button(counter, "Proceed").text == Counter.PAIR_ACCEPT, "[⑥] Proceed의 글이 PAIR_ACCEPT가 아님")
	_expect(errs, _button(counter, "Decline") != null and _button(counter, "Decline").text == Counter.PAIR_DECLINE, "[⑥] Decline의 글이 PAIR_DECLINE이 아님")
	_expect(errs, _any_label_contains(counter, "상대: 굴리엘모 · 치고 빠지기") and _any_label_contains(counter, Counter.PAIR_OPPONENT_TAIL),
		"[⑥] '상대:' 줄에 굴리엘모의 갈래와 꼬리가 없다")
	counter.free()
	# 쪽을 바꾼 하루로 새로 붙인 카운터: 이름 · 사연 · 상대 줄이 짝의 것.
	day.switch_side()
	var other := _counter(day)
	var dialogue := other.find_child("Dialogue", true, false)
	_expect(errs, dialogue != null and String(dialogue.get("text")) == baker.dialogue, "[⑥ 바꾼 하루] 사연이 짝의 것이 아님")
	_expect(errs, _any_label_contains(other, "상대: 베아트리체 · 속임 베기"), "[⑥ 바꾼 하루] '상대: 베아트리체 · 속임 베기'가 없다")
	var back_button := _button(other, "SwitchSide")
	_expect(errs, back_button != null and back_button.text == Counter.SWITCH_BUTTON % hatter.client_name, "[⑥ 바꾼 하루] 돌아갈 버튼이 목록 쪽의 이름이 아님")
	other.free()
	# 흥정한 뒤의 새 카운터는 버튼이 꺼진 채로 선다.
	var haggled_day := _day_of([hatter], 6, true)
	haggled_day.haggle(0)
	var locked := _counter(haggled_day)
	var locked_button := _button(locked, "SwitchSide")
	_expect(errs, locked_button != null and locked_button.disabled and locked_button.text == Counter.SWITCH_LOCKED, "[⑥ 흥정한 뒤의 새 카운터] SwitchSide가 꺼져 있지 않거나 글이 SWITCH_LOCKED가 아님")
	locked.free()
	# (T2) 같은 카운터에서 흥정하면 그 자리에서 꺼진다(받아 줌 · 거절 · _on_haggle 그대로).
	for row: Array in [["_on_haggle", -1], ["받아 줌", 0], ["거절", 99]]:
		var live_day := _day_of([hatter], 6, true)
		var live := _counter(live_day)
		var live_button := _button(live, "SwitchSide")
		_expect(errs, live_button != null and not live_button.disabled, "[⑥ %s] 흥정 전에는 켜져 있어야 한다" % row[0])
		if int(row[1]) < 0:
			live.call("_on_haggle")
		else:
			live_day.haggle(int(row[1]))
			live.call("_refresh_haggle")
		_expect(errs, live_button != null and live_button.disabled and live_button.text == Counter.SWITCH_LOCKED, "[⑥ %s] 흥정한 같은 카운터에서 SwitchSide가 꺼지지 않음" % row[0])
		live.call("_on_switch_side")
		_expect(errs, live_day.current_commission() == hatter, "[⑥ %s] 흥정한 뒤 누름 함수가 쪽을 바꿈" % row[0])
		live.free()
	# ⑦ 짝 없는 손님: 지금 그대로.
	var solo_day := _day_of([load(FIRST_BLOOD_PATH)], 1, true)
	var solo := _counter(solo_day)
	_expect(errs, solo.find_child("Partner", true, false) == null and solo.find_child("SwitchSide", true, false) == null, "[⑦] 짝 없는 손님에 Partner · SwitchSide가 있다")
	_expect(errs, _button(solo, "Proceed").text == "맡는다" and _button(solo, "Decline").text == "돌려보낸다", "[⑦] 짝 없는 손님의 버튼 글이 바뀜")
	_expect(errs, not _any_label_contains(solo, Counter.PAIR_OPPONENT_TAIL), "[⑦] 짝 없는 손님의 '상대:' 줄에 꼬리가 있다")
	solo.free()


# ================================================================ T150 플래그의 저장

func _saved_morning(day_number: int, flags_value: Variant) -> Dictionary:
	var saved := {"version": 1, "day": day_number, "money": 50, "owned": [], "reputation": 20, "dice_seed": 7}
	if flags_value != null:
		saved["flags"] = flags_value
	return saved


## 진짜 일정과 평판 규칙을 실은 새 하루(GameSession과 같은 재료).
func _real_day() -> DayState:
	return DayState.new(_economy(), load(Session.DAY_PATH) as DayData, load(Session.CATALOG_PATH) as UpgradeCatalog,
		load(Session.SCHEDULE_PATH) as DaySchedule, _reputation())


func t150_flag_save() -> String:
	var errs: Array[String] = []
	_check_save_values(errs)
	_check_save_garbage(errs)
	_check_session_path(errs)
	return _ok(errs)


func _check_save_values(errs: Array[String]) -> void:
	# ① 새 하루의 아침 저장에 flags가 빈 배열.
	var fresh := _real_day()
	var morning := fresh.saved_state()
	_expect(errs, morning.has("flags") and morning["flags"] is Array and (morning["flags"] as Array).is_empty(), "[①] 아침 저장의 flags가 빈 배열이 아님")
	_expect(errs, int(morning["version"]) == 1, "[①] SAVE_VERSION이 1이 아님")
	# ② 폐점의 저장: 그날 남긴 플래그, restore → 같은 flags와 거른 내일.
	var day := _real_day()
	day.restore(_saved_morning(6, []))
	_expect(errs, day.current_commission() != null and day.current_commission().resource_path == PAIR_HATTER_PATH, "[②] 6일차 첫 손님이 pair_hatter가 아님")
	day.switch_side()
	day.accept()
	day.finish_duel(_spar_rec(3))
	_to_closing(day)
	var closed := day.saved_state()
	_expect(errs, int(closed.get("day", 0)) == 7 and closed.get("flags") == ["sided_baker"], "[②] 폐점의 저장 %s (기대 7일차 · [sided_baker])" % str(closed))
	var loaded: Variant = JSON.parse_string(JSON.stringify(closed))
	var back := _real_day()
	_expect(errs, loaded is Dictionary and back.restore(loaded), "[②] JSON을 지난 저장을 되돌리지 못함")
	_expect(errs, back.day_number == 7 and back.flags == PackedStringArray(["sided_baker"]), "[②] 되돌린 하루 %d일차 flags %s" % [back.day_number, str(back.flags)])
	var first := back.current_commission()
	_expect(errs, first != null and first.resource_path == AFTER_BAKER_PATH, "[②] 되돌린 7일차의 첫 손님이 after_baker가 아님")
	for c in back.data.commissions:
		_expect(errs, c.resource_path != AFTER_HATTER_PATH, "[②] 되돌린 7일차 목록에 after_hatter가 있다")
	# ③ flags가 없는 옛 저장은 읽히고 빈 목록(6일차 목록은 거르지 않는다).
	var old := _real_day()
	_expect(errs, old.restore(_saved_morning(6, null)) and old.flags.is_empty() and old.day_number == 6, "[③] flags 없는 옛 저장이 읽히지 않거나 flags가 비어 있지 않다")
	_expect(errs, old.current_commission().resource_path == PAIR_HATTER_PATH, "[③] 옛 저장의 6일차 첫 손님이 pair_hatter가 아님")


func _check_save_garbage(errs: Array[String]) -> void:
	var three := _real_day()
	_expect(errs, three.restore(_saved_morning(6, 3)) and three.flags.is_empty(), "[④] flags: 3 → 빈 목록이 아님")
	var mixed := _real_day()
	mixed.restore(_saved_morning(6, [1, "", "a", "a", "x".repeat(65)]))
	_expect(errs, mixed.flags == PackedStringArray(["a"]), "[④] 쓰레기 섞인 flags %s (기대 [a])" % str(mixed.flags))
	var many: Array = []
	for i in 70:
		many.append("f%d" % i)
	var capped := _real_day()
	capped.restore(_saved_morning(6, many))
	_expect(errs, capped.flags.size() == 64, "[④] 70개의 flags가 %d개 (기대 64)" % capped.flags.size())
	var edge := _real_day()
	edge.restore(_saved_morning(6, ["y".repeat(64)]))
	_expect(errs, edge.flags.size() == 1, "[④] 64자 flags가 걸러짐")


func _check_session_path(errs: Array[String]) -> void:
	Store.erase(TEST_PATH)
	Store.write(TEST_PATH, _saved_morning(6, []))
	var writer: Node = Session.new()
	writer.set("save_path", TEST_PATH)
	_expect(errs, bool(writer.call("continue_day_play")), "[⑤] 6일차 아침에서 이어 하지 못함")
	var day := writer.get("day") as DayState
	if day == null:
		errs.append("[⑤] 이어 한 뒤에 하루가 없다")
		writer.free()
		return
	_expect(errs, day.day_number == 6 and day.current_commission().resource_path == PAIR_HATTER_PATH, "[⑤] 이어 한 하루가 6일차 pair_hatter가 아님")
	day.switch_side()
	var morning := day.saved_state()
	var file_now := Store.read(TEST_PATH)
	_expect(errs, int(morning.get("day", 0)) == 6 and (morning.get("flags") as Array).is_empty() and (file_now.get("flags") as Array).is_empty(), "[⑤] 쪽을 바꿨다고 아침 저장이 달라짐(쪽은 저장에 들지 않는다)")
	day.accept()
	day.finish_duel(_spar_rec(3))
	_expect(errs, day.flags == PackedStringArray(["sided_baker"]), "[⑤] 짝 쪽을 맡아 정산했는데 flags가 sided_baker가 아님")
	# 하루 중에 그만두고 이어 하면 플래그는 아침의 것(비어 있다).
	var quitter: Node = Session.new()
	quitter.set("save_path", TEST_PATH)
	_expect(errs, bool(quitter.call("continue_day_play")), "[⑤] 하루 중에 그만둔 뒤 이어 하지 못함")
	var resumed := quitter.get("day") as DayState
	_expect(errs, resumed != null and resumed.day_number == 6 and resumed.flags.is_empty(), "[⑤] 그만두고 이어 한 하루의 flags가 아침의 것이 아님")
	quitter.free()
	# 폐점에서 적고 이어 하면 7일차의 첫 손님이 after_baker.
	_to_closing(day)
	_expect(errs, bool(writer.call("save_game")) and int(writer.get("saved_day")) == 7, "[⑤] 폐점에서 적지 못함")
	var reader: Node = Session.new()
	reader.set("save_path", TEST_PATH)
	_expect(errs, bool(reader.call("continue_day_play")), "[⑤] 폐점 뒤에 이어 하지 못함")
	var next := reader.get("day") as DayState
	_expect(errs, next != null and next.day_number == 7 and next.current_commission().resource_path == AFTER_BAKER_PATH, "[⑤] 이어 한 7일차의 첫 손님이 after_baker가 아님")
	reader.free()
	writer.free()
	Store.erase(TEST_PATH)


# ================================================================ T151 네 의뢰와 이레

func _check_posture_cells(errs: Array[String], label: String, commission: Commission) -> void:
	var base := commission.opponent
	var fitted := commission.fit_opponent(base)
	if commission.opponent_posture_max == 0 and commission.opponent_recover_posture == 0:
		_expect(errs, fitted == base, "[④ %s] 자세 칸이 0인데 fit_opponent가 다른 객체다" % label)
	else:
		var posture := commission.opponent_posture_max
		var recover := commission.opponent_recover_posture
		_expect(errs, recover >= 1 and recover <= posture and posture <= 9, "[④ %s] 자세 칸 %d · %d (기대 1 ≤ 되찾는 ≤ 자세 ≤ 9)" % [label, posture, recover])
		_expect(errs, fitted != base, "[④ %s] 자세 칸이 있는데 상대가 사본이 아니다" % label)


func t151_data_and_week() -> String:
	var errs: Array[String] = []
	var hatter := load(PAIR_HATTER_PATH) as Commission
	var baker := load(PAIR_BAKER_PATH) as Commission
	var after_hatter := load(AFTER_HATTER_PATH) as Commission
	var after_baker := load(AFTER_BAKER_PATH) as Commission
	if hatter == null or baker == null or after_hatter == null or after_baker == null:
		return "네 의뢰 가운데 Commission으로 로드되지 않는 것이 있다"
	_check_four_data(errs, hatter, baker, after_hatter, after_baker)
	_check_week(errs, hatter, after_hatter, after_baker)
	_check_tiers(errs)
	_check_posture_cells(errs, "모자", hatter)
	_check_posture_cells(errs, "대련", baker)
	_check_posture_cells(errs, "칼 든 손", after_hatter)
	_check_posture_cells(errs, "지기", after_baker)
	return _ok(errs)


func _check_four_data(errs: Array[String], hatter: Commission, baker: Commission, after_hatter: Commission, after_baker: Commission) -> void:
	# 상대가 엇갈린다: 저마다 짝의 의뢰인 본인이다.
	_expect(errs, hatter.opponent.resource_path == GUGLIELMO_PATH and baker.opponent.resource_path == BEATRICE_PATH, "[①] 두 쪽의 상대가 엇갈리지 않는다(모자 → 굴리엘모, 대련 → 베아트리체)")
	_expect(errs, after_hatter.opponent.resource_path == LORENZO_PATH and after_baker.opponent.resource_path == BEATRICE_PATH, "[①] 뒷이야기의 상대가 로렌초 · 베아트리체가 아님")
	# 조건 타입과 값.
	_expect(errs, hatter.conditions.size() == 1 and hatter.conditions[0] is TargetPartCondition, "[①] 모자 의뢰의 조건이 TargetPartCondition 하나가 아니다")
	if hatter.conditions.size() == 1 and hatter.conditions[0] is TargetPartCondition:
		var hat_cond := hatter.conditions[0] as TargetPartCondition
		_expect(errs, hat_cond.target_part == DT.Part.HAT and hat_cond.graze_penalty == 0 and hat_cond.hit_penalty == 30, "[①] 모자 의뢰의 지정 부위 · 감점이 표와 다름")
	_expect(errs, baker.conditions.size() == 1 and baker.conditions[0] is SparCondition, "[①] 대련 의뢰의 조건이 SparCondition 하나가 아니다")
	if baker.conditions.size() == 1 and baker.conditions[0] is SparCondition:
		var spar_cond := baker.conditions[0] as SparCondition
		_expect(errs, spar_cond.topples_needed == 3 and spar_cond.wound_score == 0, "[①] 대련 의뢰의 횟수 · 상처 점수가 표와 다름")
	_expect(errs, after_hatter.conditions.size() == 1 and after_hatter.conditions[0] is TargetPartCondition, "[①] 칼 든 손 의뢰의 조건이 TargetPartCondition 하나가 아니다")
	if after_hatter.conditions.size() == 1 and after_hatter.conditions[0] is TargetPartCondition:
		var hand_cond := after_hatter.conditions[0] as TargetPartCondition
		_expect(errs, hand_cond.target_part == DT.Part.SWORD_HAND and hand_cond.graze_penalty == 0 and hand_cond.hit_penalty == 30, "[①] 칼 든 손 의뢰의 지정 부위 · 감점이 표와 다름")
	_expect(errs, after_baker.conditions.size() == 1 and after_baker.conditions[0] is ThrowUndetectedCondition, "[①] 지기 의뢰의 조건이 ThrowUndetectedCondition 하나가 아니다")
	# 모자 · 무대 · 그림.
	_expect(errs, hatter.opponent_wears_hat and not baker.opponent_wears_hat and not after_hatter.opponent_wears_hat and not after_baker.opponent_wears_hat, "[①] 모자는 모자 의뢰에만 씌운다")
	for c in [hatter, baker, after_baker]:
		_expect(errs, c.stage != null and c.stage.resource_path.get_file() == "piazza.tres", "[①] %s의 무대가 광장이 아님" % c.resource_path.get_file())
	_expect(errs, after_hatter.stage != null and after_hatter.stage.resource_path.get_file() == "alley.tres", "[①] after_hatter의 무대가 뒷골목이 아님")
	var portraits := {hatter: "beatrice.png", after_baker: "beatrice.png", baker: "guglielmo.png", after_hatter: "guglielmo.png"}
	for c: Commission in portraits:
		_expect(errs, c.client_portrait != null and c.client_portrait.resource_path.get_file() == portraits[c], "[①] %s의 의뢰인 그림이 %s가 아님" % [c.resource_path.get_file(), portraits[c]])
	# 짝은 하나이고 한쪽에만 적는다.
	_expect(errs, hatter.partner == baker, "[①] pair_hatter.partner가 pair_baker가 아님")
	_expect(errs, baker.partner == null and baker.requires_flags.is_empty() and baker.excluded_flags.is_empty(), "[①] 짝의 partner · 거름 칸이 비어 있지 않다")
	var schedule := load(SCHEDULE_PATH) as DaySchedule
	for c in CommissionLibrary.load_tree(COMMISSION_DIR):
		_expect(errs, c.partner == null or c.partner.partner == null, "[①] %s의 짝이 또 짝을 가진다" % c.resource_path.get_file())
	for d in schedule.days:
		for c in d.commissions:
			_expect(errs, c != baker, "[①] 짝(pair_baker)이 하루의 목록에 서 있다")
	# 플래그의 칸이 결정 754 · 756 그대로.
	_expect(errs, hatter.sets_flags == PackedStringArray(["sided_hatter"]) and hatter.excluded_flags == PackedStringArray(["sided_hatter", "sided_baker"]) and hatter.requires_flags.is_empty(), "[①] pair_hatter의 플래그 칸이 결정 754와 다름")
	_expect(errs, baker.sets_flags == PackedStringArray(["sided_baker"]), "[①] pair_baker의 sets_flags가 결정 754와 다름")
	_expect(errs, after_hatter.requires_flags == PackedStringArray(["sided_hatter"]) and after_hatter.excluded_flags == PackedStringArray(["baker_helped"]) and after_hatter.sets_flags == PackedStringArray(["baker_helped"]), "[①] after_hatter의 플래그 칸이 결정 756과 다름")
	_expect(errs, after_baker.requires_flags == PackedStringArray(["sided_baker"]) and after_baker.excluded_flags == PackedStringArray(["hatter_rematch"]) and after_baker.sets_flags == PackedStringArray(["hatter_rematch"]), "[①] after_baker의 플래그 칸이 결정 756과 다름")
	var lorenzo := load(LORENZO_PATH) as OpponentData
	_expect(errs, after_hatter.dialogue.contains(lorenzo.display_name), "[①] after_hatter의 사연에 '%s'가 없다" % lorenzo.display_name)
	for c in [hatter, baker, after_hatter, after_baker]:
		var paragraphs: PackedStringArray = (c as Commission).dialogue.split("\n")
		_expect(errs, paragraphs.size() == 2 and (c as Commission).dialogue.length() <= 280, "[①] %s의 사연이 문단 둘 · 280자 안이 아님" % (c as Commission).resource_path.get_file())


func _kinds_in(data: DayData) -> Array[String]:
	var names: Array[String] = []
	for c in data.commissions:
		names.append(c.resource_path.get_file())
	return names


func _check_week(errs: Array[String], hatter: Commission, after_hatter: Commission, after_baker: Commission) -> void:
	var schedule := load(SCHEDULE_PATH) as DaySchedule
	_expect(errs, schedule.days.size() >= 7, "[②] 일정에 날이 일곱 미만이다")
	if schedule.days.size() < 7:
		return
	var sixth: DayData = schedule.days[5]
	var seventh: DayData = schedule.days[6]
	_expect(errs, sixth.resource_path == DAY_DIR + "day_06.tres" and seventh.resource_path == DAY_DIR + "day_07.tres", "[②] 여섯째 · 일곱째 날이 day_06 · day_07이 아니다")
	_expect(errs, sixth.commissions.size() >= 1 and sixth.commissions[0] == hatter, "[②] day_06의 첫째가 pair_hatter가 아님")
	var names := _kinds_in(seventh)
	_expect(errs, names.size() >= 5 and names[0] == "after_hatter.tres" and names[1] == "after_baker.tres", "[②] day_07의 첫째 · 둘째가 after_hatter · after_baker가 아님 %s" % str(names))
	var tail := names.slice(maxi(names.size() - 3, 0))
	_expect(errs, str(tail) == str(["throw_bet.tres", "first_blood_usurer.tres", "throw_match.tres"]), "[②] day_07의 끝 셋이 throw_bet · first_blood_usurer · throw_match가 아님 %s" % str(tail))
	var rules := _reputation()
	var economy := _economy()
	for flags in [[], ["sided_hatter"], ["sided_baker"], ["sided_hatter", "sided_baker"]]:
		for d: DayData in [sixth, seventh]:
			var filtered := d.for_flags(PackedStringArray(flags))
			for star in range(1, rules.max_stars() + 1):
				var count := ReputationRules.guest_count(filtered.commissions.size(), filtered.base_guests, rules.guest_change(star), economy.duels_per_day)
				_expect(errs, count >= 3, "[②] %s · 플래그 %s · 별 %d의 손님 %d (기대 3 이상)" % [d.resource_path.get_file(), str(flags), star, count])
	for n in range(1, 6):
		var early := load(DAY_DIR + "day_0%d.tres" % n) as DayData
		for c in early.commissions:
			_expect(errs, c != hatter and c != after_hatter and c != after_baker and c.partner == null, "[②] day_0%d에 047의 의뢰가 있다" % n)
	for d: DayData in [sixth, seventh]:
		for c in d.commissions:
			_expect(errs, c.resource_path != "res://data/commissions/spar.tres", "[②] %s에 spar.tres가 있다" % d.resource_path.get_file())
	# ③ 거름.
	var none7 := _kinds_in(seventh.for_flags(PackedStringArray()))
	_expect(errs, not none7.has("after_hatter.tres") and not none7.has("after_baker.tres") and sixth.for_flags(PackedStringArray()).commissions[0] == hatter, "[③ 플래그 없음] 뒷이야기가 서 있거나 pair_hatter가 빠짐")
	var hatter7 := seventh.for_flags(PackedStringArray(["sided_hatter"]))
	_expect(errs, hatter7.commissions[0] == after_hatter and not _kinds_in(hatter7).has("after_baker.tres"), "[③ sided_hatter] day_07의 첫째가 after_hatter가 아니거나 after_baker가 남음")
	_expect(errs, not sixth.for_flags(PackedStringArray(["sided_hatter"])).commissions.has(hatter), "[③ sided_hatter] day_06에 pair_hatter가 남음")
	var baker7 := seventh.for_flags(PackedStringArray(["sided_baker"]))
	_expect(errs, baker7.commissions[0] == after_baker and not _kinds_in(baker7).has("after_hatter.tres"), "[③ sided_baker] day_07의 첫째가 after_baker가 아니거나 after_hatter가 남음")
	_expect(errs, not sixth.for_flags(PackedStringArray(["sided_baker"])).commissions.has(hatter), "[③ sided_baker] day_06에 pair_hatter가 남음")
	var done7 := _kinds_in(seventh.for_flags(PackedStringArray(["sided_hatter", "baker_helped"])))
	_expect(errs, not done7.has("after_hatter.tres") and not done7.has("after_baker.tres"), "[③ sided_hatter · baker_helped] 뒷이야기가 남음")


func _check_tiers(errs: Array[String]) -> void:
	var gul := load(GUGLIELMO_PATH) as OpponentData
	var bea := load(BEATRICE_PATH) as OpponentData
	var lor := load(LORENZO_PATH) as OpponentData
	_expect(errs, gul.style_label(6) == "굴리엘모 · 치고 빠지기", "[④ 6일차] 굴리엘모 '%s'" % gul.style_label(6))
	_expect(errs, bea.style_label(6) == "베아트리체 · 속임 베기", "[④ 6일차] 베아트리체 '%s'" % bea.style_label(6))
	_expect(errs, lor.style_label(7) == "로렌초 · 뛰어드는 찌르기 2단", "[④ 7일차] 로렌초 '%s'" % lor.style_label(7))
	_expect(errs, bea.style_label(7) == "베아트리체 · 속임 베기 2단", "[④ 7일차] 베아트리체 '%s'" % bea.style_label(7))


# ================================================================ T152 네 판

## 바깥의 기본 봇: 막고(쥐고), 빈틈에 가운데 중단으로 받아치고, 무너지면 finisher(없으면 안 침)로 끝낸다.
## chase면 치고 빠진 빈틈에 늘 따라붙는다. retreat면 뛰어드는 찌르기에 막기를 떼고 물러서 헛치게 한다.
func _cfg(finisher: Variant, chase: bool, retreat := false) -> Dictionary:
	var hold := func(atk: AttackData, _index: int) -> StringName:
		if retreat and atk.dive:
			return &"retreat"
		return &"hold"
	var aim := func(ev: Dictionary) -> Variant:
		return [DT.Direction.CENTER, DT.Height.MID] if float(ev["recovery"]) > 0.0 else null
	var cfg := {"guard_fn": hold, "step_fn": hold, "counter_fn": aim, "counter_delay": 0.25, "want_distance": DT.Distance.ENGAGE}
	if finisher != null:
		cfg["finisher"] = finisher
	if chase:
		cfg["chase_fn"] = func(_ev: Dictionary) -> bool:
			return true
	if retreat:
		cfg["whiff_fn"] = func(ev: Dictionary) -> Variant:
			return [DT.Direction.CENTER, DT.Height.MID] if float(ev["recovery"]) > 0.0 else null
	return cfg


## 의뢰의 조건 · 모자 · 상대(빈틈 1.0 + 의뢰의 자세 칸)로 판 하나를 끝까지 돌린다.
func _duel(commission: Commission, opponent: OpponentData, cfg: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var fitted := commission.fit_opponent(opponent.with_opening(1.0))
	var core := DuelCore.new()
	core.setup(load(RULES_PATH), load(WEAPON_PATH), fitted, rng, commission.conditions, commission.opponent_wears_hat)
	var bot := Bot.new(core, cfg)
	while not core.ended and core.time < HARD_STOP:
		core.tick(DELTA)
		bot.update()
	var hits: Array[int] = []
	for ev in core.record.events:
		if ev["type"] == DuelRecord.ATTACK and ev["result"] == DT.AttackResult.HIT:
			hits.append(int(ev["part"]))
	return {"ended": core.ended, "reason": core.record.end_reason, "score": commission.evaluate(core.record), "time": core.time, "hits": hits}


func t152_duels() -> String:
	var errs: Array[String] = []
	_check_hat_duel(errs)
	_check_spar_duel(errs)
	_check_hand_duel(errs)
	_check_throw_record(errs)
	_check_settle_sections(errs)
	return _ok(errs)


func _check_hat_duel(errs: Array[String]) -> void:
	var hatter := load(PAIR_HATTER_PATH) as Commission
	var gul := hatter.opponent
	var top := [gul.sword_side, DT.Height.HIGH]
	var done := 0
	for seed_value in range(1, 6):
		var r := _duel(hatter, gul, _cfg(top, true), seed_value)
		print("  INFO 모자 씨앗 %d: %.1f초 끝 %d 점수 %d" % [seed_value, r["time"], r["reason"], r["score"]])
		if int(r["reason"]) == DT.EndReason.CONDITION and int(r["score"]) == 100:
			done += 1
	_expect(errs, done >= 1, "[①] 윗줄 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")
	for seed_value in range(1, 4):
		var mid := _duel(hatter, gul, _cfg([DT.Direction.CENTER, DT.Height.MID], true), seed_value)
		_expect(errs, int(mid["reason"]) != DT.EndReason.CONDITION, "[① 씨앗 %d] 가운데 중단 봇이 모자를 베었다(끝 %d 점수 %d)" % [seed_value, mid["reason"], mid["score"]])


func _check_spar_duel(errs: Array[String]) -> void:
	var baker := load(PAIR_BAKER_PATH) as Commission
	var bea := baker.opponent
	var done := 0
	var hit_duels := 0
	for seed_value in range(1, 6):
		var r := _duel(baker, bea, _cfg(null, false), seed_value)
		print("  INFO 대련 씨앗 %d: %.1f초 끝 %d 점수 %d 유효타 %d" % [seed_value, r["time"], r["reason"], r["score"], (r["hits"] as Array).size()])
		if int(r["reason"]) == DT.EndReason.CONDITION and int(r["score"]) == 100:
			done += 1
		if not (r["hits"] as Array).is_empty():
			hit_duels += 1
	_expect(errs, done >= 1, "[②] 속지 않는 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")
	_expect(errs, hit_duels == 0, "[②] 무너진 그녀를 친 판이 %d개(유효타 없는 봇이다)" % hit_duels)


func _check_hand_duel(errs: Array[String]) -> void:
	var after_hatter := load(AFTER_HATTER_PATH) as Commission
	var lor := after_hatter.opponent.at_tier(1)
	var top := [lor.sword_side, DT.Height.HIGH]
	var done := 0
	for seed_value in range(1, 6):
		var r := _duel(after_hatter, lor, _cfg(top, false, true), seed_value)
		print("  INFO 칼 든 손 씨앗 %d: %.1f초 끝 %d 점수 %d" % [seed_value, r["time"], r["reason"], r["score"]])
		if int(r["reason"]) == DT.EndReason.CONDITION and int(r["score"]) == 100:
			done += 1
			_expect(errs, (r["hits"] as Array).size() == 1 and int((r["hits"] as Array)[0]) == DT.Part.SWORD_HAND, "[③ 씨앗 %d] 유효타가 칼 든 손 하나가 아님 %s" % [seed_value, str(r["hits"])])
	_expect(errs, done >= 1, "[③] 윗줄 봇이 씨앗 1~5에서 100점으로 끝낸 판이 없다")


## ④ 틀린 칸을 쥐고 맞으면(WRONG_GUARD 5) 아무것도 안 쥐고 맞은(UNGUARDED 20) 기록보다 점수가 높다.
func _check_throw_record(errs: Array[String]) -> void:
	var cond := (load(AFTER_BAKER_PATH) as Commission).conditions[0] as ThrowUndetectedCondition
	var guarded := cond.evaluate(_throw_rec(DT.Situation.WRONG_GUARD))
	var bare := cond.evaluate(_throw_rec(DT.Situation.UNGUARDED))
	_expect(errs, guarded > bare, "[④] 쥔 채 맞은 기록 %d점이 맨몸으로 맞은 기록 %d점보다 높지 않다" % [guarded, bare])
	_expect(errs, guarded > 0 and bare > 0, "[④] 두 기록이 0점이다 (%d · %d)" % [guarded, bare])
	_expect(errs, guarded - bare == cond.unguarded_suspicion - cond.wrong_guard_suspicion, "[④] 두 기록의 차 %d (기대 %d)" % [guarded - bare, cond.unguarded_suspicion - cond.wrong_guard_suspicion])


## 한 의뢰를 6 · 7일차의 평판 규칙으로 정산한다. 점수 · 항목 · 정산 화면의 한마디.
func _settle(commission: Commission, record: DuelRecord, day_number: int) -> Dictionary:
	var day := _day_of([commission], day_number, true)
	day.accept()
	day.finish_duel(record)
	var result := day.last_result()
	var settlement: Node = (load(Session.SETTLEMENT_PATH) as PackedScene).instantiate()
	settlement.set("day", day)
	_tree.root.add_child(settlement)
	var reaction := settlement.find_child("Reaction", true, false) as Label
	var out := {"score": int(result["score"]), "items": result.get("reputation_items", []), "won": bool(result["won"]),
		"reaction": reaction.text if reaction != null else "(없음)"}
	settlement.free()
	return out


func _check_settle_sections(errs: Array[String]) -> void:
	var rep := _reputation()
	_expect(errs, rep.scale_for_day(6) == SCALE_DAY6 and rep.scale_for_day(7) == SCALE_DAY6, "[⑤] 6 · 7일차의 배율이 200이 아님")
	var G := DT.AttackResult.GRAZE
	var H := DT.AttackResult.HIT
	var rows: Array = [
		[PAIR_HATTER_PATH, 6, _rec([[H, DT.Part.HAT]], DT.EndReason.CONDITION), _rec([[H, DT.Part.HAT], [H, DT.Part.TORSO]], DT.EndReason.CONDITION), _rec([], DT.EndReason.TIME_UP)],
		[PAIR_BAKER_PATH, 6, _spar_rec(3), _spar_rec(1), _spar_rec(0)],
		[AFTER_HATTER_PATH, 7, _rec([[H, DT.Part.SWORD_HAND]], DT.EndReason.CONDITION), _rec([[H, DT.Part.SWORD_HAND], [H, DT.Part.TORSO]], DT.EndReason.CONDITION), _rec([], DT.EndReason.TIME_UP)],
		[AFTER_BAKER_PATH, 7, _throw_rec(DT.Situation.WRONG_GUARD), _throw_rec(DT.Situation.UNGUARDED), _rec([[G, DT.Part.TORSO]], DT.EndReason.TIME_UP)],
	]
	for row: Array in rows:
		var commission := load(row[0]) as Commission
		var label := commission.resource_path.get_file()
		var want_lines := [commission.success_line, commission.partial_line, commission.fail_line]
		var section_names := ["해냄", "부분", "못 해냄"]
		for k in 3:
			var r := _settle(commission, row[2 + k], int(row[1]))
			var score := int(r["score"])
			_expect(errs, r["reaction"] == want_lines[k], "[⑤ %s %s] 한마디 '%s' (기대 그 구간의 글)" % [label, section_names[k], r["reaction"]])
			if k == 0:
				_expect(errs, score > TIP_FLOOR, "[⑤ %s] 해냄 구간의 점수 %d가 팁 문턱 이하" % [label, score])
			elif k == 1:
				_expect(errs, score > 0 and score <= TIP_FLOOR, "[⑤ %s] 부분 구간의 점수 %d가 1~70이 아님" % [label, score])
			else:
				_expect(errs, score == 0, "[⑤ %s] 못 해냄 구간의 점수 %d가 0이 아님" % [label, score])
			var want_items := rep.settle_items(commission.reputation_effect, score, TIP_FLOOR, bool(r["won"]), SCALE_DAY6)
			_expect(errs, r["items"] == want_items, "[⑤ %s %s] 평판 항목 %s (기대 reputation_effect × 2 → %s)" % [label, section_names[k], str(r["items"]), str(want_items)])
