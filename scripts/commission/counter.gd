extends Control
## 카운터: 의뢰인이 들어와 사연을 말한다. 지금은 맡는 것만 할 수 있다(거절·협상 없음).

const Ui := preload("res://scripts/day_ui.gd")

## 의뢰인이 서는 자리와 미끄러져 들어오는 시간.
const CLIENT_POS := Vector2(120, 164)
const SLIDE_TIME := 0.45

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
var day: DayState


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
	var header := Ui.add_label(self, "%d일차 · 의뢰 %d/%d · 소지금 %d" % [
		day.day_number, day.index + 1, day.commission_count(), day.money], 22)
	header.name = "Header"
	header.position = Vector2(32, 20)

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
	Ui.add_label(bubble, "상대: %s" % (commission.opponent.display_name if commission.opponent != null else "?"), 17, Ui.DIM)
	Ui.add_label(bubble, "기본 보수 %d · 팁 최대 %d" % [commission.base_reward, commission.tip_max], 17, Ui.DIM)

	var proceed := Ui.add_button(self, "맡는다", 28, "Proceed")
	proceed.position = Vector2(900, 590)
	proceed.size = Vector2(320, 76)
	proceed.pressed.connect(_accept)

	var quit := Ui.add_button(self, "오늘은 그만", 16, "Quit")
	quit.position = Vector2(40, 650)
	quit.size = Vector2(170, 42)
	quit.pressed.connect(_quit)

	# 버튼은 의뢰인이 들어오는 것을 기다리지 않고 처음부터 눌린다.
	proceed.grab_focus()


func _accept() -> void:
	if day == null or not day.accept():
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
