extends RefCounted
## 하루 루프의 화면(처음 화면, 카운터, 정산, 폐점)이 함께 쓰는 만들기 도우미.
## 전부 색 사각형과 글자다(애셋 없음). 화면은 1280x720 기준으로 자리를 직접 적는다.

const BACKGROUND := Color(0.12, 0.12, 0.15)
const COUNTER_COLOR := Color(0.33, 0.23, 0.15)
const COUNTER_TOP_COLOR := Color(0.45, 0.32, 0.2)
const GOLD := Color(0.95, 0.8, 0.3)
const RED := Color(0.95, 0.42, 0.36)
const DIM := Color(1, 1, 1, 0.7)

## 카운터(가로 띠)의 윗변 y.
const COUNTER_Y := 540.0
## 의뢰인 도형의 크기.
const CLIENT_SIZE := Vector2(220, 390)
## 화면이 열린 뒤 누름을 받지 않는 시간(밀리초). 앞 화면에서 빠르게 두 번 누른 것(더블클릭, Space 두 번)의
## 두 번째가 새 화면의 같은 자리 버튼이나 포커스 버튼을 누르지 않게 한다. 임시 값이다(계획 018).
const ARRIVAL_GUARD_MSEC := 400


## 화면이 열린 때(opened_msec)부터 ARRIVAL_GUARD_MSEC가 지나지 않은 때(now_msec)의 마우스 버튼이나 키 입력인가.
## 시각은 Time.get_ticks_msec()다(테스트가 직접 넣는다). 마우스 움직임 같은 다른 입력은 거짓이다.
static func is_arrival_press(event: InputEvent, opened_msec: int, now_msec: int) -> bool:
	if not (event is InputEventMouseButton or event is InputEventKey):
		return false
	return now_msec - opened_msec < ARRIVAL_GUARD_MSEC


## 화면의 _input이 부른다: 그 화면이 현재 씬이고 열린 직후의 누름이면 삼킨다(버튼에 닿지 않는다).
## 다른 씬 아래에 붙은 화면(테스트)에서는 아무것도 하지 않는다.
static func swallow_arrival_press(screen: Control, event: InputEvent, opened_msec: int) -> void:
	if not screen.is_inside_tree() or screen.get_tree().current_scene != screen:
		return
	if is_arrival_press(event, opened_msec, Time.get_ticks_msec()):
		screen.get_viewport().set_input_as_handled()


static func add_background(parent: Control, color := BACKGROUND) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(rect)
	return rect


static func add_label(parent: Node, text: String, font_size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


## 줄바꿈되는 글. 컨테이너 안에 넣어 쓴다.
static func add_wrapped(parent: Node, text: String, font_size: int, color := Color.WHITE) -> Label:
	var label := add_label(parent, text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func add_button(parent: Node, text: String, font_size: int, node_name := "") -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	if node_name != "":
		button.name = node_name
	parent.add_child(button)
	return button


## 자리와 크기를 직접 적은 패널. 안에 여백과 세로 줄 세우기가 들어 있다. 돌려주는 것은 그 세로 상자다.
static func add_panel(parent: Control, rect: Rect2, separation := 10) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.custom_minimum_size = rect.size
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	margin.add_child(column)
	return column


## 의뢰인마다 다른 색. 이름에서 뽑는다.
static func client_color(client_name: String) -> Color:
	var hue := float(absi(hash(client_name)) % 360) / 360.0
	return Color.from_hsv(hue, 0.45, 0.72)


## 의뢰인 도형: 몸과 머리 사각형, 이름 글자. 크기는 CLIENT_SIZE다.
static func make_client(client_name: String) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = CLIENT_SIZE
	root.size = CLIENT_SIZE
	var color := client_color(client_name)

	var body := ColorRect.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.color = color
	body.position = Vector2(20, 150)
	body.size = Vector2(180, 240)
	root.add_child(body)

	var head := ColorRect.new()
	head.name = "Head"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.color = color.lightened(0.3)
	head.position = Vector2(62, 46)
	head.size = Vector2(96, 96)
	root.add_child(head)

	var label := add_label(root, client_name, 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-90, 6)
	label.size = Vector2(400, 30)
	return root


## 카운터(가로 띠). 의뢰인을 먼저 붙이고 이것을 나중에 붙이면 의뢰인이 카운터 뒤에 선다.
static func add_counter_band(parent: Control) -> void:
	var band := ColorRect.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.color = COUNTER_COLOR
	band.position = Vector2(0, COUNTER_Y)
	band.size = Vector2(1280, 720 - COUNTER_Y)
	parent.add_child(band)
	var top := ColorRect.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.color = COUNTER_TOP_COLOR
	top.position = Vector2(0, COUNTER_Y)
	top.size = Vector2(1280, 14)
	parent.add_child(top)


## 방금 돌려보낸 손님의 한마디(흐린 한 줄, 노드 이름 DeclinedLine). 카운터와 폐점이 함께 쓴다.
## declined는 DayState.last_declined다. 돌려보낸 손님이 없거나 한마디가 비어 있으면 만들지 않고 null을 돌려준다.
static func add_declined_line(parent: Control, declined: Dictionary, rect: Rect2) -> Label:
	var line := String(declined.get("line", ""))
	if line == "":
		return null
	var label := add_wrapped(parent, "돌려보낸 손님 — %s: %s" % [declined.get("client_name", ""), line], 16, DIM)
	label.name = "DeclinedLine"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = rect.position
	label.size = rect.size
	return label


## 평판을 글로: "평판 30 · 별 4/5 (다음 38) · 보수 +10%". 카운터가 쓴다. 평판이 없는 day면 빈 글이다.
## "(다음 N)"은 다음 별이 되는 점수이고 별이 가득이면 없다. 보수는 오늘의 기본 보수 덧붙임이고 0이면 적지 않는다.
## 별은 숫자로 적는다(별 문자는 글꼴에 없을 수 있다).
static func reputation_text(day: DayState) -> String:
	if day == null or not day.has_reputation():
		return ""
	var text := "평판 %d · 별 %d/%d" % [day.reputation, day.reputation_stars(), day.reputation_rules.max_stars()]
	var to_next := day.reputation_rules.to_next_star(day.reputation)
	if to_next > 0:
		text += " (다음 %d)" % (day.reputation + to_next)
	var pay_percent := day.reputation_pay_percent()
	if pay_percent != 0:
		text += " · 보수 %+d%%" % pay_percent
	return text


## 화면에 보이는 글자(Label과 Button)를 전부 이어 붙인다. 테스트가 쓴다.
static func all_text(node: Node) -> String:
	var parts: Array[String] = []
	for child in node.find_children("*", "Label", true, false):
		parts.append((child as Label).text)
	for child in node.find_children("*", "Button", true, false):
		parts.append((child as Button).text)
	return "\n".join(parts)
