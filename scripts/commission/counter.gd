extends Control
## 카운터: 손님이 들어와 사연을 말한다. 맡거나 돌려보낸다(협상 없음).
## 하루에 맡는 결투 수는 정해져 있고 손님은 그보다 많이 올 수 있다. 문밖에 몇 명이 기다리는지는
## 보여 주지만 누구인지는 보여 주지 않는다.

const Ui := preload("res://scripts/day_ui.gd")

## 의뢰인이 서는 자리와 미끄러져 들어오는 시간.
const CLIENT_POS := Vector2(120, 164)
const SLIDE_TIME := 0.45
const DECLINE_NOTE := "돌려보내면 오늘 결투가 하나 준다"
# 맡는 값의 방향만 알린다(숫자는 정산에서 보여 준다).
const HINT_BAD := "소문: 맡기만 해도 평판이 깎일 일이다"
const HINT_GOOD := "소문: 맡기만 해도 평판이 오를 일이다"
const GUEST_NOTE := "평판 별 %d — 오늘은 손님이 %d명 온다 (보통 %d명)"

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
var day: DayState
## 화면에 내보인 문밖의 손님 수와 오늘 남은 결투 수. 내보인 것이 없으면 -1.
var shown_waiting := -1
var shown_duels_left := -1
## 화면에 내보인 평판. 평판이 없으면 -1.
var shown_reputation := -1


func _ready() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if day == null and session != null and session.get("day") is DayState:
		day = session.get("day")
	Ui.add_background(self)
	if day == null or day.phase != DayState.Phase.COUNTER or day.current_commission() == null:
		# 잘못 열렸다(이 씬만 실행 등). _ready 안에서는 씬을 바꿀 수 없으므로 미룬다.
		day = null
		call_deferred("_return_to_title")
		return
	_build(day.current_commission())


func _build(commission: Commission) -> void:
	shown_waiting = day.waiting_count()
	shown_duels_left = day.duels_left()
	var header := Ui.add_label(self, "%d일차 · 손님 %d/%d (문밖에 %d명) · 오늘 남은 결투 %d · 소지금 %d" % [
		day.day_number, day.index + 1, day.commission_count(), shown_waiting, shown_duels_left, day.money], 22)
	header.name = "Header"
	header.position = Vector2(32, 16)
	# 방금 돌려보낸 손님의 한마디. 손님을 맡으면 사라진다.
	Ui.add_declined_line(self, day.last_declined, Rect2(32, 46, 1216, 22))
	if day.has_reputation():
		shown_reputation = day.reputation
		var reputation := Ui.add_label(self, Ui.reputation_text(day), 20, Ui.GOLD)
		reputation.name = "ReputationLabel"
		reputation.position = Vector2(848, 18)
		reputation.size = Vector2(400, 28)
		reputation.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		# 그날의 첫 카운터: 평판 때문에 손님 줄이 보통과 다르면 알린다(돌려보낸 손님의 한마디와 같은 자리다.
		# 첫 카운터에는 한마디가 없다).
		var base := day.data.base_guests if day.data != null else 0
		if day.index == 0 and day.results.is_empty() and day.declined.is_empty() and base > 0 and day.commission_count() != base:
			var guests := Ui.add_label(self, GUEST_NOTE % [day.reputation_stars(), day.commission_count(), base], 16, Ui.DIM)
			guests.name = "GuestNote"
			guests.position = Vector2(32, 46)

	# 의뢰인은 카운터 뒤에 선다(카운터를 나중에 붙인다). 옆에서 한 번 미끄러져 들어온다.
	var client := Ui.make_client(commission.client_name)
	client.name = "Client"
	client.position = Vector2(-Ui.CLIENT_SIZE.x, CLIENT_POS.y)
	add_child(client)
	var tween := create_tween()
	tween.tween_property(client, "position", CLIENT_POS, SLIDE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Ui.add_counter_band(self)

	# 말풍선: 사연 전문, 조건, 상대, 보수.
	var bubble := Ui.add_panel(self, Rect2(410, 70, 830, 440), 12)
	var dialogue := Ui.add_wrapped(bubble, commission.dialogue, 19)
	dialogue.name = "Dialogue"
	dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Ui.add_wrapped(bubble, "\n".join(commission.describe()), 18, Ui.GOLD)
	if day.has_reputation():
		var accept := int(commission.reputation_effect.get("accept", 0))
		if accept != 0:
			var hint := Ui.add_label(bubble, HINT_GOOD if accept > 0 else HINT_BAD, 17, Ui.GOLD if accept > 0 else Ui.RED)
			hint.name = "ReputationHint"
	Ui.add_label(bubble, "상대: %s" % (commission.opponent.display_name if commission.opponent != null else "?"), 17, Ui.DIM)
	Ui.add_label(bubble, "기본 보수 %d · 팁 최대 %d" % [commission.base_reward, commission.tip_max], 17, Ui.DIM)

	var proceed := Ui.add_button(self, "맡는다", 28, "Proceed")
	proceed.position = Vector2(900, 590)
	proceed.size = Vector2(320, 76)
	proceed.pressed.connect(_accept)

	var decline := Ui.add_button(self, "돌려보낸다", 20, "Decline")
	decline.position = Vector2(640, 600)
	decline.size = Vector2(230, 56)
	decline.pressed.connect(_decline)
	if shown_waiting < shown_duels_left:
		# 대신 올 손님이 모자라다: 지금 돌려보내면 오늘 치를 수 있는 결투가 하나 준다.
		var note := Ui.add_label(self, DECLINE_NOTE, 15, Ui.DIM)
		note.name = "DeclineNote"
		note.position = Vector2(640, 662)

	var quit := Ui.add_button(self, "오늘은 그만", 16, "Quit")
	quit.position = Vector2(40, 650)
	quit.size = Vector2(170, 42)
	quit.pressed.connect(_quit)

	# 버튼은 의뢰인이 들어오는 것을 기다리지 않고 처음부터 눌린다.
	# 어떤 버튼에도 포커스를 두지 않는다(정산에서 넘어온 Space가 사연을 읽기도 전에 대신 고르지 않게).


func _accept() -> void:
	if day == null or not day.accept():
		return
	_go()


func _decline() -> void:
	if day == null or not day.decline():
		return
	_go()


func _quit() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session == null or get_tree().current_scene != self:
		return
	session.call("end_day_play")
	session.call("go_to_title")


## 지금 단계의 씬으로 간다. 다른 씬 아래에 붙어 있을 때(테스트)는 아무 데도 가지 않는다.
func _go() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and get_tree().current_scene == self:
		session.call("go_to_phase_scene")


func _return_to_title() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and is_inside_tree() and get_tree().current_scene == self:
		session.call("go_to_title")
