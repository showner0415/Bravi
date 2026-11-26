extends Control
## 의뢰 선택 화면(연습). data/commissions의 의뢰마다 카드 하나를 만든다(전부 코드로, 애셋 없음).
## Esc로 처음 화면에 돌아간다.

const Ui := preload("res://scripts/day_ui.gd")

const COMMISSION_DIR := "res://data/commissions"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const TITLE_PATH := "res://scenes/ui/title.tscn"
## 연습의 줄을 만드는 상대들(결정 428). 이 폴더의 상대마다 "자유 결투" 버튼, 그 패턴마다 "패턴만" 버튼이 생긴다.
const PRACTICE_DIR := "res://data/opponents"
const RULES_PATH := "res://data/duel_rules.tres"
## 빈틈 줄의 버튼(결정 407). 0은 늘 열린다, 1~3은 그 날의 확률.
const OPENING_DAYS := [[0, "늘 열린다"], [1, "1일차"], [2, "2일차"], [3, "3일차부터"]]

## 시험 줄의 버튼이 탈 날. 버튼이 묶어 둔 상대는 그대로 두고 넘기기 직전에 사본을 만든다.
## static: 결투에서 돌아와도 고른 날이 남는다(2026-11-25 playtester).
static var _opening_day := 1
var _head: HBoxContainer
var _trial_grid: HBoxContainer
var _trial_count := 0
var _drill_count := 0


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
	# 빈틈 버튼은 제목 줄의 오른쪽에 둔다: 줄을 하나 더 쌓으면 막는 법이 720 밖으로 나간다(2026-11-25 playtester).
	_head = HBoxContainer.new()
	_head.add_theme_constant_override("separation", 12)
	column.add_child(_head)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_head.add_child(title)

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
	if not DirAccess.dir_exists_absolute(PRACTICE_DIR):
		return out
	var files := Array(DirAccess.get_files_at(PRACTICE_DIR))
	files.sort()
	for file: String in files:
		# 내보낸 빌드에서는 .tres가 .remap으로 보인다.
		var path := PRACTICE_DIR.path_join(file.trim_suffix(".remap"))
		if path.ends_with(".tres") and load(path) is OpponentData:
			out.append(load(path) as OpponentData)
	return out


## 카드 아래의 시험 줄 둘과 막는 법(결정 377). 시험용 상대가 없으면 아무것도 만들지 않는다.
func _add_trials(column: VBoxContainer) -> void:
	var trials := load_trials()
	if trials.is_empty():
		return
	_add_opening_row(_head)
	# 상대별 칸으로 묶는다: 상대가 셋이 되어도 1280 안에 들고 줄 수는 둘이다(결정 448).
	_trial_grid = HBoxContainer.new()
	_trial_grid.name = "TrialGrid"
	_trial_grid.add_theme_constant_override("separation", 24)
	column.add_child(_trial_grid)
	var captions := VBoxContainer.new()
	captions.add_theme_constant_override("separation", 20)
	captions.custom_minimum_size = Vector2(110, 0)
	_trial_grid.add_child(captions)
	for caption in ["자유 결투", "패턴만"]:
		var label := Label.new()
		label.text = caption
		label.add_theme_font_size_override("font_size", 18)
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		captions.add_child(label)
	for opponent in trials:
		_add_trial_column(opponent)
	var how := Label.new()
	how.name = "PatternHelp"
	how.text = "%s\n%s\n%s%s" % [DuelHud.HELP_CHAIN.trim_prefix(" · "), DuelHud.HELP_SWEEP.trim_prefix(" · "),
			DuelHud.HELP_HEIGHT.trim_prefix(" · ") + DuelHud.opening_help(trials[0]),
			"\n" + DuelHud.HELP_DIVE.trim_prefix(" · ") if _any_dive(trials) else ""]
	how.add_theme_font_size_override("font_size", 16)
	how.add_theme_color_override("font_color", Ui.DIM)
	column.add_child(how)


func _any_dive(opponents: Array) -> bool:
	for opponent: OpponentData in opponents:
		for atk in opponent.attacks:
			if atk.dive:
				return true
	return false


func _add_trial_column(opponent: OpponentData) -> void:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 20)
	_trial_grid.add_child(cell)
	var free_button := _add_trial_button(cell, opponent.display_name, "TrialDuel%d" % _trial_count, opponent)
	free_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_trial_count += 1
	var drills := HBoxContainer.new()
	drills.add_theme_constant_override("separation", 12)
	cell.add_child(drills)
	for atk in opponent.attacks:
		if atk.chain.is_empty() and not atk.dive:
			continue
		_add_trial_button(drills, atk.attack_name, "PatternDrill%d" % _drill_count, opponent.drill(atk))
		_drill_count += 1


func _caption(row: HBoxContainer, caption: String) -> HBoxContainer:
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size = Vector2(110, 0)
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)
	return row


func _add_trial_button(row: Container, text: String, node_name: String, opponent: OpponentData) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_start_opponent.bind(opponent))
	row.add_child(button)
	return button


## 의뢰 없이 그 상대와 결투한다. 고른 날의 빈틈 확률을 실은 사본을 넘긴다(결정 407).
func _start_opponent(opponent: OpponentData) -> void:
	var chance := 1.0
	if _opening_day > 0:
		chance = (load(RULES_PATH) as DuelRules).opening_chance_for(opponent.opening_chance, _opening_day)
	var session := get_node_or_null(^"/root/GameSession")
	if session != null:
		session.set("commission", null)
		session.set("practice_opponent", opponent.with_opening(chance))
	get_tree().change_scene_to_file(DUEL_PATH)


## 빈틈 줄: 버튼 넷 가운데 하나만 눌린다(결정 407).
func _add_opening_row(row: HBoxContainer) -> void:
	_caption(row, "빈틈").get_child(-1).custom_minimum_size = Vector2.ZERO
	var group := ButtonGroup.new()
	for entry: Array in OPENING_DAYS:
		var button := Button.new()
		button.name = "OpeningDay%d" % entry[0]
		button.text = entry[1]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = entry[0] == _opening_day
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(func() -> void: _opening_day = entry[0])
		row.add_child(button)
