extends Control
## 정산: 의뢰인의 한 줄 반응과 받은 돈. 결투 한 건이 끝날 때마다 온다.

const Ui := preload("res://scripts/day_ui.gd")

# 의뢰인의 반응. 충족도 구간 넷의 공통 문구다. 의뢰에 그 구간의 한마디가 없을 때 나온다(reaction_words).
# 승패가 아니라 "부탁한 대로 됐는가"를 말한다. 져 달라는 의뢰인에게도 말이 되어야 한다.
const REACTION_NONE := "…부탁드린 건 이게 아니었는데요. 이래서는 보수를 드릴 수가 없어요."
const REACTION_PARTIAL := "부탁드린 대로는 아니었지만, 애써 주신 만큼은 쳐 드릴게요."
const REACTION_GOOD := "거의 부탁드린 그대로였어요. 고맙습니다, 조금 더 얹었어요."
const REACTION_PERFECT := "부탁드린 그대로예요! 더 바랄 게 없네요. 넉넉히 넣었으니 받아 주세요."
const MISSED_NOTE := "오늘은 더 싸울 수 없다 — 문밖의 손님 %d명은 돌아간다"
# 전액 기준치의 한 줄. 기준치가 100보다 작을 때만 낸다. T33이 이 화면에서 찾는 낱말은 쓰지 않는다.
const FULL_PAY_MET := "기준치 %d 이상 — 보수를 전부 받는다"
const FULL_PAY_MET_BASE_ONLY := "기준치 %d 이상 — 기본 보수를 전부 받는다"
const FULL_PAY_MISSED := "기준치 %d에 못 미쳐 깎였다"
# 흥정을 받아 준 판의 한 줄. 기준치 줄의 자리에 나온다(%d는 흥정한 판의 전액 기준치다).
const HAGGLE_NOTE := "흥정한 값 — %d점이어야 팁까지 전부 받는다"

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
var day: DayState
## 화면에 내보인 합(기본 보수 + 팁). 내보인 것이 없으면 -1.
var shown_total := -1
## 화면이 열린 때(Time.get_ticks_msec()). 열린 직후의 누름을 삼키는 데 쓴다(Ui.swallow_arrival_press).
var _opened_msec := 0


## 충족도에 맞는 반응 문구.
static func reaction_for(score: int, tip_floor: int) -> String:
	if score <= 0:
		return REACTION_NONE
	if score >= 100:
		return REACTION_PERFECT
	return REACTION_PARTIAL if score <= tip_floor else REACTION_GOOD


## 이 판의 반응. 그 구간의 의뢰인의 한마디(결과의 fail_line / partial_line / success_line)가 있으면 그것이고,
## 비어 있으면 공통 문구다. 구간은 reaction_for와 같다(0 이하 / 팁 문턱 이하 / 그 위).
static func reaction_words(result: Dictionary, tip_floor: int) -> String:
	var score := int(result.get("score", 0))
	var key := "success_line"
	if score <= 0:
		key = "fail_line"
	elif score <= tip_floor:
		key = "partial_line"
	var own_words := String(result.get(key, ""))
	return own_words if own_words != "" else reaction_for(score, tip_floor)


func _ready() -> void:
	_opened_msec = Time.get_ticks_msec()
	var session := get_node_or_null(^"/root/GameSession")
	if day == null and session != null and session.get("day") is DayState:
		day = session.get("day")
	Ui.add_background(self)
	if day == null or day.phase != DayState.Phase.SETTLEMENT or day.last_result().is_empty():
		day = null
		call_deferred("_return_to_title")
		return
	_build(day.last_result())


## 열린 직후의 마우스 버튼·키 입력은 삼킨다(앞 화면의 두 번째 누름이 여기 버튼을 누르지 않게).
func _input(event: InputEvent) -> void:
	Ui.swallow_arrival_press(self, event, _opened_msec)


func _build(result: Dictionary) -> void:
	var rules := day.effective_rules()
	Ui.add_beams(self)
	Ui.add_header_rule(self)
	var header := Ui.add_title(self, "%d일차 · 오늘의 결투 %d/%d 정산" % [
		day.day_number, day.results.size(), rules.duels_per_day], 28)
	header.name = "Header"
	header.position = Vector2(32, 14)

	var client := Ui.make_client(result["client_name"])
	client.name = "Client"
	client.position = Ui.CLIENT_POS
	add_child(client)
	Ui.add_counter_band(self)

	var bubble := Ui.add_panel(self, Rect2(410, 70, 830, 96))
	# 그 구간의 의뢰인의 한마디가 있으면 공통 문구 대신 그것을 보여 준다.
	var words := reaction_words(result, rules.tip_floor)
	var reaction := Ui.add_wrapped(bubble, words, 20)
	reaction.name = "Reaction"

	var ledger := Ui.add_panel(self, Rect2(410, 186, 830, 324), 6)
	Ui.add_title(ledger, "충족도 %d" % result["score"], 34)
	var threshold := int(result.get("full_pay_score", 100))
	var haggle_pay := int(result.get("haggle_percent", 0))
	if haggle_pay > 0:
		# 흥정을 받아 준 판: 기준치 줄의 자리에 흥정의 조건을 적는다.
		var haggle_note := Ui.add_label(ledger, HAGGLE_NOTE % threshold, 18, Ui.DIM)
		haggle_note.name = "HaggleNote"
	elif threshold < 100:
		var note_text := FULL_PAY_MISSED
		if result.get("full_pay", false):
			note_text = FULL_PAY_MET if rules.full_pay_covers_tip else FULL_PAY_MET_BASE_ONLY
		var note := Ui.add_label(ledger, note_text % threshold, 18, Ui.DIM)
		note.name = "FullPayNote"
	# 오늘의 평판(별)이나 흥정이 기본 보수의 비율을 바꿨으면 그 비율을 뒤에 붙인다(0이 아닌 것만).
	# 최대(base_max)도 덧붙임이 든 값이다.
	var base_name := "기본 보수"
	var star_pay := int(result.get("reputation_pay_percent", 0))
	var bonus_parts: Array[String] = []
	if star_pay != 0:
		bonus_parts.append("평판 %+d%%" % star_pay)
	if haggle_pay > 0:
		bonus_parts.append("흥정 +%d%%" % haggle_pay)
	if not bonus_parts.is_empty():
		base_name += "  (%s)" % " · ".join(PackedStringArray(bonus_parts))
	Ui.add_ledger_row(ledger, "Base", base_name, "%d / %d" % [result["base"], result["base_max"]], 24)
	# 흥정을 거절당한 판이면 팁의 감점을 뒤에 붙인다. 최대(tip_max)는 이미 깎인 값이다.
	var tip_name := "팁"
	var tip_cut := int(result.get("haggle_tip_cut_percent", 0))
	if tip_cut > 0:
		tip_name += "  (흥정 거절 %+d%%)" % [-tip_cut]
	Ui.add_ledger_row(ledger, "Tip", tip_name, "%d / %d" % [result["tip"], result["tip_max"]], 24)
	shown_total = int(result["total"])
	Ui.add_ledger_row(ledger, "Total", "받은 돈", "%d" % shown_total, 28, true)
	Ui.add_ledger_row(ledger, "Money", "소지금", "%d" % day.money, 20, false, Ui.DIM)
	if result["injured"]:
		Ui.add_wrapped(ledger, "유효타를 맞았다 — 치료비 %d (가게를 닫을 때 낸다)" % result["medical_fee"], 18, Ui.ACCENT)

	# 평판 줄: 장부 패널과 버튼 사이. 결과에 평판이 없으면(평판이 없는 하루) 만들지 않는다.
	if result.has("reputation_before") and day.has_reputation():
		var line := Ui.add_label(self, reputation_line(result, day.reputation_rules), 18, Ui.ACCENT)
		line.name = "ReputationLine"
		line.position = Vector2(432, 514)
		line.size = Vector2(808, 28)

	var proceed := Ui.add_button(self, "다음 의뢰인" if day.has_next_commission() else "가게를 닫는다", 28, "Proceed", true)
	proceed.position = Vector2(900, 590)
	proceed.size = Vector2(320, 76)
	proceed.pressed.connect(_proceed)
	proceed.grab_focus()

	if day.duels_left() <= 0 and day.waiting_count() > 0:
		# 결투 수가 찼는데 손님이 남았다. 그 손님들은 만나지 못한다.
		var missed := Ui.add_wrapped(self, MISSED_NOTE % day.waiting_count(), 18, Ui.ON_WOOD)
		missed.name = "MissedNote"
		missed.position = Vector2(410, 604)
		missed.size = Vector2(460, 52)


## 정산의 평판 줄: "평판 9 → 11 · 해냈다 +1 · 흠 없이 +1". 항목이 없으면 "평판 9 — 그대로".
## 별이 바뀌었으면 "별 3 → 4"를 붙인다.
static func reputation_line(result: Dictionary, rules: ReputationRules) -> String:
	var before := int(result.get("reputation_before", 0))
	var after := int(result.get("reputation_after", before))
	var items: Array = result.get("reputation_items", [])
	if items.is_empty():
		return "평판 %d — 그대로" % before
	var parts: Array[String] = ["평판 %d → %d" % [before, after]]
	for item: Array in items:
		parts.append("%s %+d" % [item[0], int(item[1])])
	if rules != null and rules.stars(before) != rules.stars(after):
		parts.append("별 %d → %d" % [rules.stars(before), rules.stars(after)])
	return " · ".join(PackedStringArray(parts))


func _proceed() -> void:
	if day == null or not day.proceed():
		return
	var session := Ui.current_session(self)
	if session != null:
		session.call("go_to_phase_scene")


func _return_to_title() -> void:
	var session := Ui.current_session(self)
	if session != null:
		session.call("go_to_title")
