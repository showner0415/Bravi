extends RefCounted
## 하루 루프의 화면(처음 화면, 카운터, 정산, 폐점)이 함께 쓰는 만들기 도우미.
## 꼴은 025 견본의 필사본이고 프로젝트 테마(`assets/ui/manuscript_theme.tres`)가 그린다(결정 312~315).
## 화면은 1280x720 기준으로 자리를 직접 적는다.

const HatchRect := preload("res://scripts/ui/hatch_rect.gd")
const WALL_STYLE := preload("res://assets/ui/wall_style.tres")

## 붉은 글자(조건, 평판, 나쁜 소문, 다침, 손해, 경고). 좋고 나쁨은 붉은 글자가 있고 없음으로 가른다(결정 315).
const ACCENT := Color("84422F")
const DIM := Color("6B5440")
const INK := Color("3B2A1E")
const PARCHMENT := Color("E9D8B4")
## 카운터 나무 띠 위에 바로 놓는 글.
const ON_WOOD := Color("E9D8B4")
const COUNTER_COLOR := Color("7A5232")
const COUNTER_TOP_COLOR := Color("A8895E")
## 들보의 빗금: 견본 hatchBg(간격 6, −35°, 1.1, #6B5440)를 알파 0.5로.
const HATCH_COLOR := Color("6B5440", 0.5)
const RULE_WIDTH := 2.5
const HEADER_HEIGHT := 64.0

## 카운터(가로 띠)의 윗변 y.
const COUNTER_Y := 540.0
## 의뢰인 도형의 크기.
const CLIENT_SIZE := Vector2(220, 390)
## 카운터와 정산이 같은 자리를 써야 화면이 바뀔 때 의뢰인이 튀지 않는다.
const CLIENT_POS := Vector2(120, 164)
## 의뢰인 그림과 그 위 이름 글의 자리(CLIENT_POS 기준). 화면 (80, 120) 300×450은 사용자가 맞다고 한 견본의 자리다(결정 346).
const CLIENT_ART_RECT := Rect2(-40, -44, 300, 450)
const CLIENT_ART_NAME_RECT := Rect2(-40, -76, 300, 28)
## 카운터 배경 그림 둘(결정 352). 파일이 없으면 코드 그림(들보, 나무 띠)으로 돌아간다.
const COUNTER_ROOM_PATH := "res://assets/art/counter/room.png"
const COUNTER_FRONT_PATH := "res://assets/art/counter/front.png"
## front.png가 시작하는 y: 1920 그림의 F행(810) ÷ 1.5. F는 윗변 짙은 선 안이라 의뢰인 위에 벽 줄이 얹히지 않는다(결정 352).
const COUNTER_FRONT_Y := 540.0
## 화면이 열린 뒤 누름을 받지 않는 시간(밀리초). 앞 화면에서 빠르게 두 번 누른 것(더블클릭, Space 두 번)의
## 두 번째가 새 화면의 같은 자리 버튼이나 포커스 버튼을 누르지 않게 한다. 임시 값이다(계획 018).
const ARRIVAL_GUARD_MSEC := 400


## 화면이 열린 때(opened_msec)부터 ARRIVAL_GUARD_MSEC가 지나지 않은 때(now_msec)의 마우스 버튼이나 키 입력인가.
## 시각은 Time.get_ticks_msec()다(테스트가 직접 넣는다). 마우스 움직임 같은 다른 입력은 거짓이다.
static func is_arrival_press(event: InputEvent, opened_msec: int, now_msec: int) -> bool:
	if not (event is InputEventMouseButton or event is InputEventKey):
		return false
	return now_msec - opened_msec < ARRIVAL_GUARD_MSEC


## 테스트는 화면을 root 아래에 붙여 쓰므로 현재 씬이 아니다: 그때는 씬을 바꾸거나 저장하지 않는다.
static func is_current_scene(screen: Node) -> bool:
	return screen.is_inside_tree() and screen.get_tree().current_scene == screen


## 트리 밖에서 절대 경로를 찾으면 엔진이 오류 줄을 찍으므로 현재 씬인지 먼저 본다.
static func current_session(screen: Node) -> Node:
	if not is_current_scene(screen):
		return null
	return screen.get_node_or_null(^"/root/GameSession")


## 화면의 _input이 부른다: 그 화면이 현재 씬이고 열린 직후의 누름이면 삼킨다(버튼에 닿지 않는다).
## 다른 씬 아래에 붙은 화면(테스트)에서는 아무것도 하지 않는다.
static func swallow_arrival_press(screen: Control, event: InputEvent, opened_msec: int) -> void:
	if not is_current_scene(screen):
		return
	if is_arrival_press(event, opened_msec, Time.get_ticks_msec()):
		screen.get_viewport().set_input_as_handled()


## 양피지 벽(칠과 결만). 화면의 맨 뒤에 붙인다.
static func add_background(parent: Control) -> Panel:
	var wall := Panel.new()
	wall.name = "Wall"
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall.add_theme_stylebox_override("panel", WALL_STYLE)
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(wall)
	return wall


## 들보의 빗금 띠: x 0부터 160마다 폭 22, 나무 띠 위까지(견본 counterBg).
static func add_beams(parent: Control) -> void:
	for x in range(0, 1280, 160):
		var beam := HatchRect.new()
		beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		beam.color = HATCH_COLOR
		beam.position = Vector2(x, 0)
		beam.size = Vector2(22, COUNTER_Y)
		parent.add_child(beam)


## 화면 위쪽 머리 띠: 벽과 같은 종이와 그 아래 잉크 선(견본 counterBg, 결정 489의 예외).
static func add_header_rule(parent: Control) -> void:
	var band := Panel.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_stylebox_override("panel", WALL_STYLE)
	band.position = Vector2.ZERO
	band.size = Vector2(1280, HEADER_HEIGHT)
	parent.add_child(band)
	_add_rect(parent, Rect2(0, HEADER_HEIGHT - RULE_WIDTH / 2.0, 1280, RULE_WIDTH), INK)


static func _add_rect(parent: Control, rect: Rect2, color: Color) -> ColorRect:
	var shape := ColorRect.new()
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shape.color = color
	shape.position = rect.position
	shape.size = rect.size
	parent.add_child(shape)
	return shape


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


## primary면 주 버튼(제목 글꼴의 붉은 글자, 테마의 PrimaryButton).
static func add_button(parent: Node, text: String, font_size: int, node_name := "", primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	if primary:
		button.theme_type_variation = &"PrimaryButton"
	if node_name != "":
		button.name = node_name
	parent.add_child(button)
	return button


## 제목 글꼴(송명)의 글. 화면 머리 줄과 큰 수가 쓴다(결정 320).
static func add_title(parent: Node, text: String, font_size: int, color := Color.WHITE) -> Label:
	var label := add_label(parent, text, font_size, color)
	label.theme_type_variation = &"TitleLabel"
	return label


## 패널의 머리 글: 붉은 글자와 가는 밑줄(견본 panelHead, 결정 324).
static func add_panel_head(column: Control, text: String) -> VBoxContainer:
	var head := VBoxContainer.new()
	head.name = "PanelHead"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 4)
	column.add_child(head)
	add_label(head, text, 20, ACCENT).mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_rule([0.0], DIM))
	return head


## 장부의 한 줄(결정 325): 위에 줄선, 이름은 왼쪽·수는 오른쪽 맞춤. total이면 줄선 대신 두 줄 선(합계).
## 노드는 Ledger<key> 아래 Name·Value다(테스트가 찾는다).
static func add_ledger_row(parent: Control, key: String, name_text: String, value_text: String,
		font_size: int, total := false, color := Color.WHITE, title := false) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.name = "Ledger" + key
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	row.add_child(_rule([0.0, 4.0], INK) if total else _rule([0.0], Color(DIM, 0.6)))
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var name_label: Label = add_title(line, name_text, font_size, color) if title else add_label(line, name_text, font_size, color)
	name_label.name = "Name"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var value: Label = add_title(line, value_text, font_size, color) if title else add_label(line, value_text, font_size, color)
	value.name = "Value"
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return row


## 가로 줄선(두께 1)들. ys는 줄마다의 y(줄선 상자 안).
static func _rule(ys: Array, color: Color) -> Control:
	var rule := Control.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.custom_minimum_size = Vector2(0, float(ys.back()) + 1.0)
	for y in ys:
		var line := ColorRect.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.color = color
		line.anchor_right = 1.0
		line.offset_top = float(y)
		line.offset_bottom = float(y) + 1.0
		rule.add_child(line)
	return rule


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


## 의뢰인: 그림(portrait)이 있으면 그림과 그 위 이름 글, 없으면 몸과 머리 사각형과 이름 글자. 루트의 크기는 CLIENT_SIZE다.
static func make_client(client_name: String, portrait: Texture2D = null) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = CLIENT_SIZE
	root.size = CLIENT_SIZE
	if portrait != null:
		var art := _add_art(root, portrait, CLIENT_ART_RECT, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		art.name = "Portrait"
		var name_label := add_label(root, client_name, 20)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = CLIENT_ART_NAME_RECT.position
		name_label.size = CLIENT_ART_NAME_RECT.size
		return root
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


## 그림 한 장을 rect에 놓는다. 텍스처 크기를 최소 크기로 삼지 않게 한다(1920 그림이 1280 화면을 넘지 않게).
static func _add_art(parent: Control, texture: Texture2D, rect: Rect2, stretch: TextureRect.StretchMode) -> TextureRect:
	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = stretch
	art.position = rect.position
	art.size = rect.size
	parent.add_child(art)
	return art


## 카운터 방 그림(벽·들보·칼 선반·카운터, 결정 352). 그림 파일이 없으면 들보의 빗금이다. 벽(add_background) 바로 위에 붙인다.
static func add_room(parent: Control) -> void:
	if not ResourceLoader.exists(COUNTER_ROOM_PATH):
		add_beams(parent)
		return
	var room := _add_art(parent, load(COUNTER_ROOM_PATH) as Texture2D, Rect2(0, 0, 1280, 720), TextureRect.STRETCH_SCALE)
	room.name = "Room"


## 카운터 앞 띠: 방 그림의 F행 아래를 의뢰인 위에 얹는다(결정 352). 그림 파일이 없으면 코드의 나무 띠다.
## 의뢰인을 먼저 붙이고 이것을 나중에 붙인다.
static func add_counter_front(parent: Control) -> void:
	if not ResourceLoader.exists(COUNTER_FRONT_PATH):
		add_counter_band(parent)
		return
	var front := _add_art(parent, load(COUNTER_FRONT_PATH) as Texture2D,
		Rect2(0, COUNTER_FRONT_Y, 1280, 720 - COUNTER_FRONT_Y), TextureRect.STRETCH_SCALE)
	front.name = "CounterFront"


## 카운터(가로 띠). 의뢰인을 먼저 붙이고 이것을 나중에 붙이면 의뢰인이 카운터 뒤에 선다.
## 나무 띠, 윗줄 14, 그 위아래 잉크 선(견본 counterBand).
static func add_counter_band(parent: Control) -> void:
	_add_rect(parent, Rect2(0, COUNTER_Y, 1280, 720 - COUNTER_Y), COUNTER_COLOR)
	_add_rect(parent, Rect2(0, COUNTER_Y, 1280, 14), COUNTER_TOP_COLOR)
	for y in [COUNTER_Y, COUNTER_Y + 14.0]:
		_add_rect(parent, Rect2(0, y - RULE_WIDTH / 2.0, 1280, RULE_WIDTH), INK)


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
