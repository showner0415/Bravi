extends Control
## 카운터: 손님이 들어와 사연을 말한다. 맡거나 돌려보낸다. 맡기 전에 값을 올려 부를 수 있다(흥정. 한 번뿐이다).
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
# 오늘의 기본 보수 덧붙임(평판의 별). 손님 수가 보통과 다르면 GUEST_NOTE 뒤에 붙이고, 같으면 보수만 알린다.
const GUEST_NOTE_PAY := " · 보수 %+d%%"
const GUEST_NOTE_PAY_ONLY := "평판 별 %d — 오늘은 보수 %+d%%"
# 흥정("값을 올려 부른다")의 글. 성향 한 줄은 손님의 haggle_min_stars를 haggle_hint_index()로 옮겨 읽는다
# (배열을 그 값으로 바로 읽지 않는다). 정확한 별 수도, 받아 줄 확률도 보여 주지 않는다(사용자 결정 2026-11-20).
const HAGGLE_HINTS: Array[String] = [
	"흥정: 값을 올려 부를 수 없는 손님이다",
	"흥정: 값에 너그러운 손님이다",
	"흥정: 가게의 이름을 보고 값을 치를 손님이다",
	"흥정: 아주 이름난 가게라야 값을 올려 줄 손님이다",
]
# 흥정에 대한 손님의 대답(공통 문구). 의뢰에 그 대답이 없을 때 나온다. 성향 한 줄의 자리에 바뀌어 나온다.
const HAGGLE_AGREED := "좋습니다, 그 값에 하지요. 대신 흠 하나 없이 부탁드립니다."
const HAGGLE_REFUSED := "그 값은 못 드립니다. 처음 값으로 하지요 — 얹어 드리려던 것은 좀 줄이겠습니다."
# 흥정 전의 성향 한 줄 뒤에 붙는 거절의 대가(%d는 거절당했을 때의 팁 최대). 감점이 있을 때만 붙는다.
const HAGGLE_CUT := " — 거절당하면 팁 최대 %d"
const HAGGLE_BUTTON := "값을 올려 부른다"
const HAGGLE_BUTTON_AGREED := "올려 받기로 했다"
const HAGGLE_BUTTON_REFUSED := "거절당했다"
# 말풍선의 보수 줄과 그 꼬리. 흥정 전에는 받아 줬을 때의 값과 조건을 미리 보여 주고, 받아 준 뒤에는 조건만 남긴다.
# 거절당한 뒤에는 팁이 깎였다는 것을 알린다(보수 줄의 팁 최대는 이미 깎인 값이다).
const PAY_LINE := "기본 보수 %d · 팁 최대 %d"
const PAY_TAIL_OFFER := " (받아 주면 기본 보수 %d, 대신 100점이어야 팁까지 다 받는다)"
const PAY_TAIL_AGREED := " · 100점이어야 다 받는다"
const PAY_TAIL_REFUSED := " · 거절당해 팁이 깎였다"
# "오늘은 그만" 아래의 한 줄.
const QUIT_NOTE := "오늘 한 일은 남지 않는다 — 이어서 하면 오늘 아침부터다"

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
var day: DayState
## 화면에 내보인 문밖의 손님 수와 오늘 남은 결투 수(계산 그대로. 머리 줄에는 남은 손님 수로 자른 값을 적는다).
## 내보인 것이 없으면 -1.
var shown_waiting := -1
var shown_duels_left := -1
## 화면에 내보인 평판. 평판이 없으면 -1.
var shown_reputation := -1
## 흥정의 버튼과, 흥정에 따라 글이 바뀌는 말풍선의 두 줄(성향 한 줄, 보수 줄). 없으면 null이다.
var _haggle_button: Button
var _haggle_line: Label
var _pay_line: Label
## 화면이 열린 때(Time.get_ticks_msec()). 열린 직후의 누름을 삼키는 데 쓴다(Ui.swallow_arrival_press).
var _opened_msec := 0


## 손님의 haggle_min_stars를 HAGGLE_HINTS의 칸(0~3)으로 옮긴다.
static func haggle_hint_index(min_stars: int) -> int:
	if min_stars <= 0:
		return 0
	if min_stars <= 2:
		return 1
	if min_stars <= 4:
		return 2
	return 3


func _ready() -> void:
	_opened_msec = Time.get_ticks_msec()
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


## 열린 직후의 마우스 버튼·키 입력은 삼킨다(앞 화면의 두 번째 누름이 여기 버튼을 누르지 않게).
func _input(event: InputEvent) -> void:
	Ui.swallow_arrival_press(self, event, _opened_msec)


func _build(commission: Commission) -> void:
	shown_waiting = day.waiting_count()
	shown_duels_left = day.duels_left()
	# 머리 줄의 남은 결투는 지금 손님과 문밖 손님을 합친 수를 넘지 않게 적는다(손님이 모자라면 그만큼만 치른다).
	var duels_to_show := mini(shown_duels_left, shown_waiting + 1)
	var header := Ui.add_label(self, "%d일차 · 손님 %d/%d (문밖에 %d명) · 오늘 남은 결투 %d · 소지금 %d" % [
		day.day_number, day.index + 1, day.commission_count(), shown_waiting, duels_to_show, day.money], 22)
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
		# 그날의 첫 카운터: 평판 때문에 손님 줄이나 기본 보수가 보통과 다르면 알린다(돌려보낸 손님의 한마디와 같은 자리다.
		# 첫 카운터에는 한마디가 없다).
		var base := day.data.base_guests if day.data != null else 0
		var pay_percent := day.reputation_pay_percent()
		var first_counter := day.index == 0 and day.results.is_empty() and day.declined.is_empty()
		if first_counter and base > 0 and (day.commission_count() != base or pay_percent != 0):
			var guest_text := GUEST_NOTE_PAY_ONLY % [day.reputation_stars(), pay_percent]
			if day.commission_count() != base:
				guest_text = GUEST_NOTE % [day.reputation_stars(), day.commission_count(), base]
				if pay_percent != 0:
					guest_text += GUEST_NOTE_PAY % pay_percent
			var guests := Ui.add_label(self, guest_text, 16, Ui.DIM)
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
	# 흥정의 한 줄: 손님의 성향이고, 흥정한 뒤에는 손님의 대답이다. 흥정이 켜져 있을 때만 있다.
	if day.effective_rules().haggle_bonus_percent > 0:
		_haggle_line = Ui.add_label(bubble, "", 17, Ui.DIM)
		_haggle_line.name = "HaggleLine"
	Ui.add_label(bubble, "상대: %s" % (commission.opponent.display_name if commission.opponent != null else "?"), 17, Ui.DIM)
	# 보수 줄. 글은 _refresh_haggle()이 채운다(흥정에 따라 바뀐다).
	_pay_line = Ui.add_label(bubble, "", 17, Ui.DIM)
	_pay_line.name = "PayLine"

	# 흥정의 버튼: 값을 올려 부를 수 있는 손님이거나, 이 손님에게 이미 흥정했을 때만 있다.
	if day.can_haggle() or day.haggle_state() != DayState.Haggle.NONE:
		_haggle_button = Ui.add_button(self, HAGGLE_BUTTON, 18, "Haggle")
		_haggle_button.position = Vector2(410, 600)
		_haggle_button.size = Vector2(210, 56)
		_haggle_button.pressed.connect(_on_haggle)
	_refresh_haggle()

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
	# 하루 중에 그만두면 버려지는 것을 누르기 전에 알린다(저장은 하루 단위다).
	var quit_note := Ui.add_label(self, QUIT_NOTE, 13, Ui.DIM)
	quit_note.name = "QuitNote"
	quit_note.position = Vector2(40, 694)

	# 버튼은 의뢰인이 다 들어오기를 기다리지 않는다. 다만 열린 뒤 Ui.ARRIVAL_GUARD_MSEC 동안은 누름을 삼킨다(_input).
	# 어떤 버튼에도 포커스를 두지 않는다(정산에서 넘어온 Space가 사연을 읽기도 전에 대신 고르지 않게).


## 흥정의 버튼과 말풍선의 두 줄을 지금 상태로 채운다. 노드는 새로 만들지 않는다.
## 버튼이나 성향 한 줄이 없는 손님(흥정할 수 없는 손님, 흥정이 꺼진 규칙)에서도 부른다.
func _refresh_haggle() -> void:
	if day == null or day.current_commission() == null:
		return
	var commission := day.current_commission()
	var state := day.haggle_state()
	if _haggle_button != null:
		_haggle_button.disabled = state != DayState.Haggle.NONE
		if state == DayState.Haggle.AGREED:
			_haggle_button.text = HAGGLE_BUTTON_AGREED
			_haggle_button.add_theme_color_override("font_disabled_color", Ui.GOLD)
		elif state == DayState.Haggle.REFUSED:
			_haggle_button.text = HAGGLE_BUTTON_REFUSED
		else:
			_haggle_button.text = HAGGLE_BUTTON
	if _haggle_line != null:
		var hint_text: String = HAGGLE_HINTS[haggle_hint_index(commission.haggle_min_stars)]
		if state == DayState.Haggle.AGREED:
			hint_text = commission.haggle_agree_line if commission.haggle_agree_line != "" else HAGGLE_AGREED
		elif state == DayState.Haggle.REFUSED:
			hint_text = commission.haggle_refuse_line if commission.haggle_refuse_line != "" else HAGGLE_REFUSED
		elif day.can_haggle():
			# 흥정 전: 거절당했을 때의 팁 최대를 미리 보여 준다. 받아 줄 확률은 보여 주지 않는다.
			var refused_rules := day.haggle_refused_rules()
			if refused_rules.haggle_refuse_tip_cut_percent > 0:
				hint_text += HAGGLE_CUT % DayState.boosted_tip_max(commission.tip_max, refused_rules)
		_haggle_line.text = hint_text
	if _pay_line != null:
		# 둘 다 오늘 실제로 받을 수 있는 최대다(정산과 같은 규칙). 기본 보수에는 오늘의 평판(별)과 받아 준 흥정의
		# 덧붙임이, 팁 최대에는 가진 업그레이드의 덧붙임이 들어 있다.
		var today_rules := day.settle_rules()
		var pay_text := PAY_LINE % [DayState.boosted_base_max(commission.base_reward, today_rules),
			DayState.boosted_tip_max(commission.tip_max, today_rules)]
		if day.can_haggle():
			# 흥정 전: 받아 줬을 때의 기본 보수와 조건을 미리 보여 준다(받아 주면 되돌릴 수 없다).
			pay_text += PAY_TAIL_OFFER % DayState.boosted_base_max(commission.base_reward, day.haggle_preview_rules())
		elif state == DayState.Haggle.AGREED:
			pay_text += PAY_TAIL_AGREED
		elif state == DayState.Haggle.REFUSED and today_rules.haggle_refuse_tip_cut_percent > 0:
			pay_text += PAY_TAIL_REFUSED
		_pay_line.text = pay_text


## 값을 올려 부른다. 손님이 받아 주거나 거절한다(확률에 따른 무작위). 어느 쪽이든 버튼은 다시 눌리지 않는다.
func _on_haggle() -> void:
	if day == null or not day.haggle():
		return
	_refresh_haggle()
	# 어떤 버튼에도 포커스를 두지 않는다(카운터의 다른 버튼과 같다).
	if _haggle_button != null:
		_haggle_button.release_focus()


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
