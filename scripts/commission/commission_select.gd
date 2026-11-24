extends Control
## 의뢰 선택 화면(연습). data/commissions의 의뢰마다 카드 하나를 만든다(전부 코드로, 애셋 없음).
## Esc로 처음 화면에 돌아간다.

const Ui := preload("res://scripts/day_ui.gd")

const COMMISSION_DIR := "res://data/commissions"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const TITLE_PATH := "res://scenes/ui/title.tscn"
## 패턴을 시험하는 상대(결정 369·377). 이 폴더의 상대마다 "자유 결투" 버튼, 그 패턴마다 "패턴만" 버튼이 생긴다.
const TRIAL_DIR := "res://data/opponents/trial"


func _ready() -> void:
	Ui.add_background(self)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	var title := Label.new()
	title.text = "연습 — 의뢰를 골라 결투  (Esc: 처음 화면)"
	title.add_theme_font_size_override("font_size", 28)
	title.theme_type_variation = &"TitleLabel"
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
	_add_trials(column)


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
	opponent.add_theme_color_override("font_color", Ui.DIM)
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
	condition.add_theme_font_size_override("font_size", 18)
	condition.add_theme_color_override("font_color", Ui.ACCENT)
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
		session.set("practice_opponent", null)
	get_tree().change_scene_to_file(DUEL_PATH)


func _unhandled_input(event: InputEvent) -> void:
	# 다른 씬 아래에 붙어 있을 때(테스트)는 아무 데도 가지 않는다.
	if event.is_action_pressed(&"back") and get_tree().current_scene == self:
		get_tree().change_scene_to_file(TITLE_PATH)


## 시험용 상대를 읽는다(파일 이름 차례). 폴더가 없거나 비면 빈 배열이다.
static func load_trials() -> Array[OpponentData]:
	var out: Array[OpponentData] = []
	if not DirAccess.dir_exists_absolute(TRIAL_DIR):
		return out
	var files := Array(DirAccess.get_files_at(TRIAL_DIR))
	files.sort()
	for file: String in files:
		# 내보낸 빌드에서는 .tres가 .remap으로 보인다.
		var path := TRIAL_DIR.path_join(file.trim_suffix(".remap"))
		if path.ends_with(".tres") and load(path) is OpponentData:
			out.append(load(path) as OpponentData)
	return out


## 카드 아래의 시험 줄 둘과 막는 법(결정 377). 시험용 상대가 없으면 아무것도 만들지 않는다.
func _add_trials(column: VBoxContainer) -> void:
	var trials := load_trials()
	if trials.is_empty():
		return
	var free_row := _add_row(column, "자유 결투")
	var drill_row := _add_row(column, "패턴만")
	var drills := 0
	for i in trials.size():
		var opponent := trials[i]
		_add_trial_button(free_row, opponent.display_name, "TrialDuel%d" % i, opponent)
		# 같은 상대를 높이 없이: 9칸과 가로만을 바로 견줘 본다(결정 391).
		_add_trial_button(free_row, "%s (가로만)" % opponent.display_name, "TrialFlat%d" % i, opponent.flat())
		for atk in opponent.attacks:
			if atk.chain.is_empty():
				continue
			_add_trial_button(drill_row, "%s · %s" % [opponent.display_name, atk.attack_name],
				"PatternDrill%d" % drills, opponent.drill(atk))
			drills += 1
	var how := Label.new()
	how.name = "PatternHelp"
	how.text = "%s\n%s\n%s" % [DuelHud.HELP_CHAIN.trim_prefix(" · "), DuelHud.HELP_SWEEP.trim_prefix(" · "),
			DuelHud.HELP_HEIGHT.trim_prefix(" · ")]
	how.add_theme_font_size_override("font_size", 16)
	how.add_theme_color_override("font_color", Ui.DIM)
	column.add_child(how)


func _add_row(column: VBoxContainer, caption: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size = Vector2(110, 0)
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)
	return row


func _add_trial_button(row: HBoxContainer, text: String, node_name: String, opponent: OpponentData) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_start_opponent.bind(opponent))
	row.add_child(button)


## 의뢰 없이 그 상대와 결투한다.
func _start_opponent(opponent: OpponentData) -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null:
		session.set("commission", null)
		session.set("practice_opponent", opponent)
	get_tree().change_scene_to_file(DUEL_PATH)
