extends Control
## 의뢰 선택 화면. data/commissions의 의뢰마다 카드 하나를 만든다(전부 코드로, 애셋 없음).

const COMMISSION_DIR := "res://data/commissions"
const DUEL_PATH := "res://scenes/duel/duel.tscn"


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.15)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	var title := Label.new()
	title.text = "명예 결투 대리 의뢰소 — 오늘의 의뢰"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 20)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(cards)

	var first_button: Button = null
	for commission in CommissionLibrary.load_all(COMMISSION_DIR):
		var button := _add_card(cards, commission)
		if first_button == null:
			first_button = button
	if first_button == null:
		var empty := Label.new()
		empty.text = "의뢰가 없습니다 (%s)" % COMMISSION_DIR
		cards.add_child(empty)
	else:
		first_button.grab_focus()


## 의뢰 하나의 카드를 만들고 시작 버튼을 돌려준다.
func _add_card(parent: Control, commission: Commission) -> Button:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var client := Label.new()
	client.text = commission.client_name
	client.add_theme_font_size_override("font_size", 24)
	column.add_child(client)

	var opponent := Label.new()
	opponent.text = "상대: %s" % (commission.opponent.display_name if commission.opponent != null else "?")
	opponent.modulate = Color(1, 1, 1, 0.7)
	column.add_child(opponent)

	var dialogue := Label.new()
	dialogue.text = commission.dialogue
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue.add_theme_font_size_override("font_size", 16)
	column.add_child(dialogue)

	var condition := Label.new()
	condition.text = "\n".join(commission.describe())
	condition.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	condition.add_theme_font_size_override("font_size", 17)
	condition.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	column.add_child(condition)

	var button := Button.new()
	button.text = "이 의뢰를 맡는다"
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(_start.bind(commission))
	column.add_child(button)
	return button


func _start(commission: Commission) -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null:
		session.set("commission", commission)
	get_tree().change_scene_to_file(DUEL_PATH)
