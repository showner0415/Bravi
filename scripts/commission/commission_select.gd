extends Control
## 연습 화면. 왼쪽 목록 둘(상대·의뢰, 쪽 넘김)에서 하나씩 고르면 오른쪽에 고른 상대의 시험 칸과 의뢰 카드 한 장이 선다(계획 040b).
## 데이터 폴더의 파일을 더하면 코드 없이 목록에 나온다. Esc로 처음 화면에 돌아간다.

const Ui := preload("res://scripts/day_ui.gd")

const COMMISSION_DIR := "res://data/commissions"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const TITLE_PATH := "res://scenes/ui/title.tscn"
## 연습의 줄을 만드는 상대들(결정 428). 이 폴더의 상대마다 목록에 한 줄이 선다.
const PRACTICE_DIR := "res://data/opponents"
const SPARE_DIR := "res://data/attacks"
const RULES_PATH := "res://data/duel_rules.tres"
const EFFECTS_PATH := "res://data/part_effects.tres"
const THEME_PATH := "res://assets/ui/manuscript_theme.tres"
## 빈틈 줄의 버튼(결정 407). 0은 늘 열린다, 1~3은 그 날의 확률.
const OPENING_DAYS := [[0, "늘 열린다"], [1, "1일차"], [2, "2일차"], [3, "3일차부터"]]

## 이 값들이 화면의 크기를 정한다: 데이터의 길이가 화면을 키우지 못하게(결정 596).
const LIST_ROWS := 5
const LIST_WIDTH := 360
const RIGHT_WIDTH := 836
const BODY_GAP := 20
const ROW_FONT := 16
const DRILL_COLUMNS := 4
const DRILL_MAX := 6
const DRILL_WIDTH := 200
const GRID_GAP := 12
const HELP_FONT := 16
const HELP_LINES := 4
## 막는 법 칸의 실제 폭(RIGHT_WIDTH) 이하.
const HELP_WIDTH := 830
const STORY_FONT := 16
const STORY_LINES := 7
## 카드 안쪽의 실제 폭(RIGHT_WIDTH − 여백 36 = 800) 이하여야 한다: 셈이 실제보다 너그럽지 않게(결정 603).
const STORY_WIDTH := 780
const COND_FONT := 18
const COND_LINES := 3
## 조건 칸의 실제 폭(카드 안쪽 800 − 시작 버튼 240 − 간격 12 = 548) 이하.
const COND_WIDTH := 540
const START_WIDTH := 240
## 머리 줄의 높이는 단 고르기가 있든 없든 같다(주인 없는 검술을 골라도 아래 칸이 움직이지 않게).
const TRIAL_HEAD_HEIGHT := 52
## 쪽 넘김의 글. 본문 글꼴에 없으면 여기만 바꾼다(결정 596).
const PREV_TEXT := "◀"
const NEXT_TEXT := "▶"
const OPPONENT := "Opponent"
const COMMISSION := "Commission"
const SPARE_TEXT := "주인 없는 검술"
const ROW_COLOR_KEYS := ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]

## 시험 줄의 버튼이 탈 날. 버튼이 묶어 둔 상대는 그대로 두고 넘기기 직전에 사본을 만든다.
## static: 결투에서 돌아와도 고른 날이 남는다(2026-11-25 playtester).
static var _opening_day := 1
## "반격 실험"이 켜져 있는가(계획 R02). 결투에서 돌아와도 남는다. 의뢰 카드의 판에는 타지 않는다.
static var _part_effects := false
## 연습의 검술 단(0부터, 결정 589). 결투에서 돌아와도 남는다. 상대의 단 수를 넘으면 그 상대에게는 마지막 단으로 보인다(값은 그대로).
static var _style_tier := 0
## 고른 줄의 번호. 상대는 "주인 없는 검술"이 마지막 번호다(결정 597).
static var _picked_opponent := 0
static var _picked_commission := 0
static var _dots := {}

## 시험 데이터를 넣는 길(결정 602): 트리에 붙이기 전에 채우고 use_sources를 켜면 폴더 대신 셋 다 이것으로 짓는다. 게임에서는 늘 꺼져 있다.
var trial_source: Array[OpponentData] = []
var spare_source: Array[AttackData] = []
var commission_source: Array[Commission] = []
var use_sources := false

var _head: HBoxContainer
var _right: VBoxContainer
var _trial_head: Control
var _trial_grid: GridContainer
var _pattern_help: Label
var _card: Control
var _trials: Array[OpponentData] = []
var _spare: Array[AttackData] = []
var _commissions: Array[Commission] = []
var _commission_texts: Array[String] = []
var _opponent_page := 0
var _commission_page := 0
var _lists := {}


func _ready() -> void:
	_load_data()
	Ui.add_background(self)

	var margin := MarginContainer.new()
	margin.name = "ScreenMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	var title := Label.new()
	title.text = "연습  (Esc: 처음 화면)"
	title.add_theme_font_size_override("font_size", 28)
	title.theme_type_variation = &"TitleLabel"
	# 빈틈 버튼은 제목 줄의 오른쪽에 둔다: 줄을 하나 더 쌓으면 막는 법이 720 밖으로 나간다(2026-11-25 playtester).
	_head = HBoxContainer.new()
	_head.add_theme_constant_override("separation", 12)
	column.add_child(_head)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_head.add_child(title)
	if not _trials.is_empty():
		_add_opening_row(_head)
		_add_part_toggle(_head)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", BODY_GAP)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 16)
	left.custom_minimum_size = Vector2(LIST_WIDTH, 0)
	body.add_child(left)
	_right = VBoxContainer.new()
	_right.name = "RightColumn"
	_right.add_theme_constant_override("separation", 10)
	_right.custom_minimum_size = Vector2(RIGHT_WIDTH, 0)
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_right)

	_picked_opponent = clampi(_picked_opponent, 0, maxi(_opponent_entries() - 1, 0))
	_picked_commission = clampi(_picked_commission, 0, maxi(_commissions.size() - 1, 0))
	_opponent_page = _page_for(_picked_opponent)
	_commission_page = _page_for(_picked_commission)
	left.add_child(_make_list(OPPONENT, "상대"))
	left.add_child(_make_list(COMMISSION, "의뢰"))
	_refill(OPPONENT)
	_refill(COMMISSION)

	if not _trials.is_empty():
		_build_trial_head()
		_build_trial_grid()
		_build_pattern_help()
	_build_card()

	var start := _card.find_child("CommissionStart", true, false) as Button
	if start != null:
		start.grab_focus()
	elif _trials.size() > 0 or _commissions.size() > 0:
		_ensure_focus(OPPONENT if not _trials.is_empty() else COMMISSION)


func _load_data() -> void:
	if use_sources:
		_trials = trial_source
		_spare = spare_source
		_commissions = commission_source
	else:
		_trials = load_trials()
		_spare = load_spare_attacks()
		_commissions = CommissionLibrary.load_tree(COMMISSION_DIR)
	var seen := {}
	_commission_texts.clear()
	for commission in _commissions:
		var text := "%s · %s" % [commission.client_name, commission.opponent.display_name if commission.opponent != null else "?"]
		var times: int = seen.get(text, 0)
		seen[text] = times + 1
		_commission_texts.append(text if times == 0 else "%s (%d)" % [text, times + 1])


# ---- 목록 ----

## 상대 줄의 수: 상대마다 하나, 상대가 있고 주인 없는 공격이 있으면 끝에 "주인 없는 검술" 한 줄.
func _opponent_entries() -> int:
	if _trials.is_empty():
		return 0
	return _trials.size() + (1 if not _spare.is_empty() else 0)


func _entry_count(prefix: String) -> int:
	return _opponent_entries() if prefix == OPPONENT else _commissions.size()


func _page_count(count: int) -> int:
	return maxi(ceili(float(count) / LIST_ROWS), 1)


func _page_for(index: int) -> int:
	return floori(float(index) / LIST_ROWS)


func _page_of(prefix: String) -> int:
	return _opponent_page if prefix == OPPONENT else _commission_page


func _set_page(prefix: String, page: int) -> void:
	if prefix == OPPONENT:
		_opponent_page = page
	else:
		_commission_page = page


func _picked_of(prefix: String) -> int:
	return _picked_opponent if prefix == OPPONENT else _picked_commission


func _rows_of(prefix: String) -> VBoxContainer:
	return (_lists[prefix] as Dictionary)["rows"] as VBoxContainer


func _entry_text(prefix: String, index: int) -> String:
	if prefix == COMMISSION:
		return _commission_texts[index]
	if index >= _trials.size():
		return SPARE_TEXT
	var opponent := _trials[index]
	return opponent.display_name if opponent.style_name.is_empty() else "%s · %s" % [opponent.display_name, opponent.style_name]


func _entry_tip(prefix: String, index: int) -> String:
	if prefix == OPPONENT:
		return _entry_text(prefix, index)
	var lines := _commissions[index].describe()
	return "%s\n%s" % [_commission_texts[index], lines[0]] if not lines.is_empty() else _commission_texts[index]


## 줄 앞의 색 점: 상대의 고유 색. 의뢰는 그 의뢰의 상대 것. 없으면 투명.
func _entry_color(prefix: String, index: int) -> Color:
	if prefix == COMMISSION:
		return _signature_color(_commissions[index].opponent)
	if index >= _trials.size():
		return Color.TRANSPARENT
	return _signature_color(_trials[index])


static func _signature_color(opponent: OpponentData) -> Color:
	if opponent == null:
		return Color.TRANSPARENT
	var pools: Array = [opponent.attacks]
	for tier in opponent.tiers:
		pools.append(tier.attacks)
	for pool: Array in pools:
		for atk: AttackData in pool:
			if atk.signature:
				return atk.pose_color
	return Color.TRANSPARENT


static func _dot(color: Color) -> Texture2D:
	if _dots.has(color):
		return _dots[color] as Texture2D
	var image := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in 14:
		for x in 14:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(7, 7))
			if distance <= 6.5:
				image.set_pixel(x, y, color if distance <= 5.2 else Ui.INK)
	var texture := ImageTexture.create_from_image(image)
	_dots[color] = texture
	return texture


## 목록 하나의 틀: 머리(이름과 쪽 넘김)와 줄 칸. 줄은 _refill이 채운다.
func _make_list(prefix: String, title: String) -> VBoxContainer:
	var list := VBoxContainer.new()
	list.name = "%sList" % prefix
	list.add_theme_constant_override("separation", 4)

	var head := HBoxContainer.new()
	head.name = "%sHead" % prefix
	head.add_theme_constant_override("separation", 6)
	list.add_child(head)
	var caption := Label.new()
	caption.text = title
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Ui.ACCENT)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(caption)
	var prev := _pager_button(head, prefix + "Prev", PREV_TEXT)
	var page := Label.new()
	page.name = prefix + "Page"
	page.add_theme_font_size_override("font_size", ROW_FONT)
	page.custom_minimum_size = Vector2(48, 0)
	page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(page)
	var next := _pager_button(head, prefix + "Next", NEXT_TEXT)
	prev.pressed.connect(_flip.bind(prefix, -1))
	next.pressed.connect(_flip.bind(prefix, 1))

	var rows := VBoxContainer.new()
	rows.name = prefix + "Rows"
	rows.add_theme_constant_override("separation", 4)
	list.add_child(rows)
	_lists[prefix] = {"rows": rows, "prev": prev, "next": next, "page": page, "group": ButtonGroup.new()}
	return list


func _pager_button(head: Control, node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.add_theme_font_size_override("font_size", ROW_FONT)
	head.add_child(button)
	return button


## 보이는 쪽의 줄을 다시 짓는다. 눌린 줄의 pressed 길에서는 부르지 않는다(신호를 내는 노드를 지우지 않게).
func _refill(prefix: String) -> void:
	var rows := _rows_of(prefix)
	for child in rows.get_children():
		rows.remove_child(child)
		child.free()
	var info := _lists[prefix] as Dictionary
	var count := _entry_count(prefix)
	var pages := _page_count(count)
	var page := clampi(_page_of(prefix), 0, pages - 1)
	_set_page(prefix, page)
	if count == 0:
		var none := Label.new()
		none.text = "상대가 없습니다" if prefix == OPPONENT else "의뢰가 없습니다 (%s)" % COMMISSION_DIR
		none.add_theme_font_size_override("font_size", ROW_FONT)
		none.add_theme_color_override("font_color", Ui.DIM)
		rows.add_child(none)
	var picked := _picked_of(prefix)
	for i in range(page * LIST_ROWS, mini(count, (page + 1) * LIST_ROWS)):
		var button := Button.new()
		button.name = "%sPick%d" % [prefix, i]
		button.text = _entry_text(prefix, i)
		button.tooltip_text = _entry_tip(prefix, i)
		button.toggle_mode = true
		button.button_group = info["group"] as ButtonGroup
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.custom_minimum_size = Vector2(LIST_WIDTH, 0)
		button.add_theme_font_size_override("font_size", ROW_FONT)
		var color := _entry_color(prefix, i)
		if color.a > 0.0:
			button.icon = _dot(color)
		button.set_meta("index", i)
		rows.add_child(button)
		button.set_pressed_no_signal(i == picked)
		button.pressed.connect(pick_opponent.bind(i) if prefix == OPPONENT else pick_commission.bind(i))
		if prefix == COMMISSION:
			_mark_row(button, i)
	if rows.get_child_count() > 0 and count > 0:
		var first := rows.get_child(0) as Button
		rows.custom_minimum_size.y = first.get_combined_minimum_size().y * LIST_ROWS + 4 * (LIST_ROWS - 1)
	_update_pager(prefix)


func _update_pager(prefix: String) -> void:
	var info := _lists[prefix] as Dictionary
	var pages := _page_count(_entry_count(prefix))
	var page := _page_of(prefix)
	(info["page"] as Label).text = "%d/%d" % [page + 1, pages]
	(info["prev"] as Button).disabled = page <= 0
	(info["next"] as Button).disabled = page >= pages - 1


## 쪽 넘김 버튼: 고른 번호는 그대로 두고 보이는 쪽만 바꾼다.
func _flip(prefix: String, delta: int) -> void:
	_set_page(prefix, _page_of(prefix) + delta)
	_refill(prefix)
	var info := _lists[prefix] as Dictionary
	var pressed := info["next" if delta > 0 else "prev"] as Button
	var other := info["prev" if delta > 0 else "next"] as Button
	if not is_inside_tree():
		return
	if not pressed.disabled:
		pressed.grab_focus()
	elif not other.disabled:
		other.grab_focus()


## 다시 지은 뒤 포커스의 주인이 없으면 고른 줄이 잡는다.
func _ensure_focus(prefix: String) -> void:
	if not is_inside_tree() or get_viewport().gui_get_focus_owner() != null:
		return
	var row := _rows_of(prefix).find_child("%sPick%d" % [prefix, _picked_of(prefix)], false, false) as Button
	if row != null:
		row.grab_focus()


## 목록의 상대 줄을 고른다(줄을 누른 것과 같다). 다른 쪽의 번호면 쪽도 넘긴다.
func pick_opponent(index: int) -> void:
	var count := _opponent_entries()
	if count == 0:
		return
	_picked_opponent = clampi(index, 0, count - 1)
	var page := _page_for(_picked_opponent)
	if page != _opponent_page:
		_opponent_page = page
		_refill(OPPONENT)
	else:
		for row in _rows_of(OPPONENT).get_children():
			if row is Button:
				(row as Button).set_pressed_no_signal(int(row.get_meta("index")) == _picked_opponent)
	_build_trial_head()
	_build_trial_grid()
	_build_pattern_help()
	for row in _rows_of(COMMISSION).get_children():
		if row is Button:
			_mark_row(row as Button, int(row.get_meta("index")))
	_ensure_focus(OPPONENT)


## 목록의 의뢰 줄을 고른다(줄을 누른 것과 같다). 카드만 다시 짓는다.
func pick_commission(index: int) -> void:
	if _commissions.is_empty():
		return
	_picked_commission = clampi(index, 0, _commissions.size() - 1)
	var page := _page_for(_picked_commission)
	if page != _commission_page:
		_commission_page = page
		_refill(COMMISSION)
	else:
		for row in _rows_of(COMMISSION).get_children():
			if row is Button:
				(row as Button).set_pressed_no_signal(int(row.get_meta("index")) == _picked_commission)
	_build_card()
	_ensure_focus(COMMISSION)


## 고른 상대가 서는 의뢰의 줄은 강조색 글자다(결정 599). 색 덮어쓰기라 줄을 다시 짓지 않는다.
func _mark_row(button: Button, index: int) -> void:
	var marked := _stands_for_picked(index)
	for key: String in ROW_COLOR_KEYS:
		if marked:
			button.add_theme_color_override(key, Ui.ACCENT)
		else:
			button.remove_theme_color_override(key)


func _stands_for_picked(commission_index: int) -> bool:
	if _picked_opponent >= _trials.size():
		return false
	var mine := _commissions[commission_index].opponent
	var picked := _trials[_picked_opponent]
	if mine == null:
		return false
	return mine == picked or (not mine.resource_path.is_empty() and mine.resource_path == picked.resource_path)


# ---- 오른쪽 칸 ----

## 오른쪽 기둥의 차례는 늘 TrialHead, TrialGrid, PatternHelp, CommissionCard다(결정 600).
func _swap(old: Node, fresh: Control, slot: int) -> void:
	if old != null:
		old.get_parent().remove_child(old)
		old.free()
	_right.add_child(fresh)
	_right.move_child(fresh, mini(slot, _right.get_child_count() - 1))


func _build_trial_head() -> void:
	var head := HBoxContainer.new()
	head.name = "TrialHead"
	head.custom_minimum_size = Vector2(0, TRIAL_HEAD_HEIGHT)
	head.add_theme_constant_override("separation", 10)
	_swap(_trial_head, head, 0)
	_trial_head = head
	if _picked_opponent >= _trials.size():
		var caption := Label.new()
		caption.name = "SpareCaption"
		caption.text = "%s — 다음 상대 몫" % SPARE_TEXT
		caption.add_theme_font_size_override("font_size", 24)
		caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(caption)
		return
	var opponent := _trials[_picked_opponent]
	var color := _signature_color(opponent)
	if color.a > 0.0:
		var dot := ColorRect.new()
		dot.color = color
		dot.custom_minimum_size = Vector2(16, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(dot)
	var name_label := Label.new()
	name_label.text = opponent.display_name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(name_label)
	var style_label := Label.new()
	style_label.text = opponent.style_name
	style_label.add_theme_font_size_override("font_size", 18)
	style_label.add_theme_color_override("font_color", Ui.DIM)
	style_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(style_label)
	_add_tier_pick(head, opponent)


## 단 고르기(결정 589). 단이 하나뿐이면 만들지 않는다.
func _add_tier_pick(row: HBoxContainer, opponent: OpponentData) -> void:
	var count := opponent.tier_count()
	if count <= 1:
		return
	var pick := OptionButton.new()
	pick.name = "StyleTierPick"
	for i in count:
		pick.add_item("검술 %d단" % (i + 1))
	pick.select(clampi(_style_tier, 0, count - 1))
	pick.custom_minimum_size = Vector2(120, 0)
	pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pick.add_theme_font_size_override("font_size", 18)
	pick.item_selected.connect(_on_tier_picked)
	row.add_child(pick)


## 단을 고르면 칸과 막는 법만 다시 짓는다: 픽과 그 조상은 지우지 않는다(신호를 내는 중이다. 결정 600).
func _on_tier_picked(index: int) -> void:
	_style_tier = index
	_build_trial_grid()
	_build_pattern_help()


## 지금 보이는 단의 상대.
func _picked_tiered() -> OpponentData:
	var opponent := _trials[_picked_opponent]
	return opponent.at_tier(clampi(_style_tier, 0, opponent.tier_count() - 1))


func _build_trial_grid() -> void:
	var grid := GridContainer.new()
	grid.name = "TrialGrid"
	grid.columns = DRILL_COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	_swap(_trial_grid, grid, 1)
	_trial_grid = grid
	if _picked_opponent >= _trials.size():
		for i in mini(_spare.size(), DRILL_MAX):
			_add_trial_button(grid, _spare[i].attack_name, "SpareDrill%d" % i, _trials[0].drill(_spare[i]))
	else:
		var opponent := _picked_tiered()
		_add_trial_button(grid, "자유 결투", "TrialDuel0", opponent)
		# "베기만"은 첫 상대에만 있다(R02의 판 P 전에는 넓히지 않는다).
		var slash := _plain_slash(opponent) if _picked_opponent == 0 else null
		if slash != null:
			_add_trial_button(grid, "베기만", "SlashDrill", opponent.drill(slash))
		var drills := 0
		for atk in opponent.attacks:
			if atk.signature and drills < DRILL_MAX:
				_add_trial_button(grid, atk.attack_name, "PatternDrill%d" % drills, opponent.drill(atk))
				drills += 1
	if grid.get_child_count() > 0:
		# 버튼이 적어도 두 줄의 높이를 차지해 아래 칸이 밀리지 않는다.
		grid.custom_minimum_size.y = (grid.get_child(0) as Button).get_combined_minimum_size().y * 2 + GRID_GAP


## 막는 법: 지금 보이는 단의 공격(주인 없는 검술이면 그 공격들)에 있는 줄만 싣는다(결정 598).
static func help_text(opponent: OpponentData, attacks: Array) -> String:
	var flat: Array[AttackData] = []
	for atk: AttackData in attacks:
		flat.append(atk)
		for variant in atk.variants:
			if variant is AttackData:
				flat.append(variant as AttackData)
	var has_chain := false
	var has_sweep := false
	var has_dive := false
	for atk in flat:
		has_chain = has_chain or (not atk.chain.is_empty() and not atk.sweep)
		has_sweep = has_sweep or atk.sweep
		has_dive = has_dive or atk.dive
	var lines: Array[String] = []
	if has_chain:
		lines.append(DuelHud.HELP_CHAIN.trim_prefix(" · "))
	if has_sweep:
		lines.append(DuelHud.HELP_SWEEP.trim_prefix(" · "))
	lines.append(DuelHud.HELP_HEIGHT.trim_prefix(" · ") + DuelHud.opening_help(opponent))
	if has_dive:
		lines.append(DuelHud.HELP_DIVE.trim_prefix(" · "))
	return "\n".join(lines)


func _build_pattern_help() -> void:
	var how := Label.new()
	how.name = "PatternHelp"
	if _picked_opponent >= _trials.size():
		how.text = help_text(_trials[0], _spare)
	else:
		var opponent := _picked_tiered()
		how.text = help_text(opponent, opponent.attacks)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	how.max_lines_visible = HELP_LINES
	how.mouse_filter = Control.MOUSE_FILTER_STOP
	how.tooltip_text = how.text
	how.custom_minimum_size = Vector2(0, ceilf(_body_font().get_height(HELP_FONT) * HELP_LINES))
	how.add_theme_font_size_override("font_size", HELP_FONT)
	how.add_theme_color_override("font_color", Ui.DIM)
	_swap(_pattern_help, how, 2)
	_pattern_help = how


## 의뢰 카드 한 장(결정 599). 사연은 말줄임 없이 다 보이고 넘치면 칸 안에서 스크롤된다.
func _build_card() -> void:
	var panel := PanelContainer.new()
	panel.name = "CommissionCard"
	_swap(_card, panel, 3)
	_card = panel
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	if _commissions.is_empty():
		var empty := Label.new()
		empty.text = "의뢰가 없습니다 (%s)" % COMMISSION_DIR
		column.add_child(empty)
		return
	var commission := _commissions[_picked_commission]

	var client := Label.new()
	client.text = "%s · 상대: %s" % [commission.client_name, commission.opponent.display_name if commission.opponent != null else "?"]
	client.add_theme_font_size_override("font_size", 20)
	column.add_child(client)

	var story := RichTextLabel.new()
	story.name = "CommissionStory"
	story.bbcode_enabled = false
	story.fit_content = false
	story.scroll_active = true
	story.focus_mode = Control.FOCUS_ALL
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.custom_minimum_size = Vector2(0, story_height())
	# 테마에 RichTextLabel 칸이 없어 글자색이 흰색이다: Label의 글자색을 옮긴다. 크기의 이름은 normal_font_size다.
	story.add_theme_color_override("default_color", get_theme_color(&"font_color", &"Label"))
	story.add_theme_font_size_override("normal_font_size", STORY_FONT)
	story.add_theme_stylebox_override("focus", focus_box())
	story.text = commission.dialogue
	column.add_child(story)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var condition := Label.new()
	condition.name = "CommissionCondition"
	condition.text = "\n".join(commission.describe())
	condition.tooltip_text = condition.text
	condition.mouse_filter = Control.MOUSE_FILTER_STOP
	condition.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	condition.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	condition.max_lines_visible = COND_LINES
	condition.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	condition.custom_minimum_size = Vector2(0, ceilf(_body_font().get_height(COND_FONT) * COND_LINES))
	condition.add_theme_font_size_override("font_size", COND_FONT)
	condition.add_theme_color_override("font_color", Ui.ACCENT)
	row.add_child(condition)
	var button := Button.new()
	button.name = "CommissionStart"
	button.text = "이 의뢰를 맡는다"
	button.custom_minimum_size = Vector2(START_WIDTH, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_END
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(_start.bind(commission))
	row.add_child(button)


# ---- 글을 재는 길(프레임 없이 된다. 결정 603) ----

static func _body_font() -> Font:
	return (load(THEME_PATH) as Theme).default_font


## 사연 칸의 높이: 글꼴의 줄 높이 × STORY_LINES.
static func story_height() -> float:
	return ceilf(_body_font().get_height(STORY_FONT) * STORY_LINES) + 6.0


## 글이 정해진 폭에서 몇 줄이 되는가. 문단(\n)마다 TextParagraph로 센다. 깃발은 RichTextLabel의 기본(AUTOWRAP_WORD_SMART)과 같다.
static func text_lines(text: String, font_size: int, width: float) -> int:
	var font := _body_font()
	var total := 0
	for paragraph in text.split("\n"):
		var shaped := TextParagraph.new()
		shaped.width = width
		shaped.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE | TextServer.BREAK_TRIM_EDGE_SPACES
		shaped.add_string(paragraph, font, font_size)
		total += maxi(shaped.get_line_count(), 1)
	return total


static func story_lines(commission: Commission) -> int:
	return text_lines(commission.dialogue, STORY_FONT, STORY_WIDTH)


static func condition_lines(commission: Commission) -> int:
	return text_lines("\n".join(commission.describe()), COND_FONT, COND_WIDTH)


static func help_lines(text: String) -> int:
	return text_lines(text, HELP_FONT, HELP_WIDTH)


## 가운데를 칠하지 않는 테두리(테마의 Button 포커스와 같은 꼴, 결정 605).
static func focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = Ui.ACCENT
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	return box


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


## 다음 상대 몫의 공격을 읽는다(파일 이름 차례, 결정 470). 폴더가 없거나 비면 빈 배열이다.
static func load_spare_attacks() -> Array[AttackData]:
	var out: Array[AttackData] = []
	if not DirAccess.dir_exists_absolute(SPARE_DIR):
		return out
	var files := Array(DirAccess.get_files_at(SPARE_DIR))
	files.sort()
	for file: String in files:
		var path := SPARE_DIR.path_join(file.trim_suffix(".remap"))
		if path.ends_with(".tres") and load(path) is AttackData:
			out.append(load(path) as AttackData)
	return out


## 단발 베기 하나(첫 공격 가운데 사슬·뛰어들기·큰 공격이 아니고 찌르기도 아닌 것). 없으면 null.
func _plain_slash(opponent: OpponentData) -> AttackData:
	for atk in opponent.attacks:
		if atk.chain.is_empty() and not atk.dive and not atk.is_big and atk.direction != DuelTypes.Direction.CENTER:
			return atk
	return null


func _caption(row: HBoxContainer, caption: String) -> HBoxContainer:
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size = Vector2(110, 0)
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)
	return row


## 시험 칸의 버튼: 폭이 정해져 있고 넘치는 글은 잘리며 풍선말이 전체 글이다(결정 596).
func _add_trial_button(row: Container, text: String, node_name: String, opponent: OpponentData) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.tooltip_text = text
	button.clip_text = true
	button.custom_minimum_size = Vector2(DRILL_WIDTH, 0)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_start_opponent.bind(opponent))
	row.add_child(button)
	return button


## 결투로 넘길 사본: 고른 날의 빈틈 확률(결정 407)과 켜져 있으면 부위별 반격의 값(계획 R02)을 싣는다.
func _trial_copy(opponent: OpponentData) -> OpponentData:
	var chance := 1.0
	if _opening_day > 0:
		chance = (load(RULES_PATH) as DuelRules).opening_chance_for(opponent.opening_chance, _opening_day)
	var tried := opponent.with_opening(chance)
	if _part_effects:
		tried = tried.with_part_effects(load(EFFECTS_PATH) as PartEffectData)
	return tried


## 의뢰 없이 그 상대와 결투한다.
func _start_opponent(opponent: OpponentData) -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null:
		session.set("commission", null)
		session.set("practice_opponent", _trial_copy(opponent))
	get_tree().change_scene_to_file(DUEL_PATH)


## 반격 실험: 켜면 시험 줄의 버튼이 부위별 반격의 새 규칙을 싣고 간다.
func _add_part_toggle(row: HBoxContainer) -> void:
	var button := Button.new()
	button.name = "PartCounterToggle"
	button.text = "반격 실험"
	button.toggle_mode = true
	button.button_pressed = _part_effects
	button.tooltip_text = DuelHud.HELP_PART.trim_prefix(" · ")
	button.add_theme_font_size_override("font_size", 18)
	button.toggled.connect(func(on: bool) -> void: _part_effects = on)
	row.add_child(button)


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
