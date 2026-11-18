extends Control
## 정산: 의뢰인의 한 줄 반응과 받은 돈. 결투 한 건이 끝날 때마다 온다.

const Ui := preload("res://scripts/day_ui.gd")

const CLIENT_POS := Vector2(120, 164)

# 의뢰인의 반응. 충족도 구간 넷의 공통 문구다(의뢰별 대사는 아직 없다).
# 승패가 아니라 "부탁한 대로 됐는가"를 말한다. 져 달라는 의뢰인에게도 말이 되어야 한다.
const REACTION_NONE := "…부탁드린 건 이게 아니었는데요. 이래서는 보수를 드릴 수가 없어요."
const REACTION_PARTIAL := "부탁드린 대로는 아니었지만, 애써 주신 만큼은 쳐 드릴게요."
const REACTION_GOOD := "거의 부탁드린 그대로였어요. 고맙습니다, 조금 더 얹었어요."
const REACTION_PERFECT := "부탁드린 그대로예요! 더 바랄 게 없네요. 넉넉히 넣었으니 받아 주세요."

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
var day: DayState
## 화면에 내보인 합(기본 보수 + 팁). 내보인 것이 없으면 -1.
var shown_total := -1


## 충족도에 맞는 반응 문구.
static func reaction_for(score: int, tip_floor: int) -> String:
	if score <= 0:
		return REACTION_NONE
	if score >= 100:
		return REACTION_PERFECT
	return REACTION_PARTIAL if score <= tip_floor else REACTION_GOOD


func _ready() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if day == null and session != null and session.get("day") is DayState:
		day = session.get("day")
	Ui.add_background(self)
	if day == null or day.phase != DayState.Phase.SETTLEMENT or day.last_result().is_empty():
		day = null
		call_deferred("_return_to_title")
		return
	_build(day.last_result())


func _build(result: Dictionary) -> void:
	var header := Ui.add_label(self, "%d일차 · 의뢰 %d/%d 정산" % [
		day.day_number, day.index + 1, day.commission_count()], 22)
	header.name = "Header"
	header.position = Vector2(32, 20)

	var client := Ui.make_client(result["client_name"])
	client.name = "Client"
	client.position = CLIENT_POS
	add_child(client)
	Ui.add_counter_band(self)

	var bubble := Ui.add_panel(self, Rect2(410, 70, 830, 96))
	var reaction := Ui.add_wrapped(bubble, reaction_for(result["score"], day.rules.tip_floor), 22)
	reaction.name = "Reaction"

	var ledger := Ui.add_panel(self, Rect2(410, 186, 830, 324), 10)
	Ui.add_label(ledger, "충족도 %d" % result["score"], 34, Ui.GOLD)
	Ui.add_label(ledger, "기본 보수   %d / %d" % [result["base"], result["base_max"]], 22)
	Ui.add_label(ledger, "팁   %d / %d" % [result["tip"], result["tip_max"]], 22)
	shown_total = int(result["total"])
	Ui.add_label(ledger, "받은 돈   %d" % shown_total, 28)
	Ui.add_label(ledger, "소지금   %d" % day.money, 20, Ui.DIM)
	if result["injured"]:
		Ui.add_wrapped(ledger, "유효타를 맞았다 — 치료비 %d (가게를 닫을 때 낸다)" % result["medical_fee"], 20, Ui.RED)

	var proceed := Ui.add_button(self, "다음 의뢰인" if day.has_next_commission() else "가게를 닫는다", 28, "Proceed")
	proceed.position = Vector2(900, 590)
	proceed.size = Vector2(320, 76)
	proceed.pressed.connect(_proceed)
	proceed.grab_focus()


func _proceed() -> void:
	if day == null or not day.proceed():
		return
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and get_tree().current_scene == self:
		session.call("go_to_phase_scene")


func _return_to_title() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and is_inside_tree() and get_tree().current_scene == self:
		session.call("go_to_title")
