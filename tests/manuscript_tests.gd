extends RefCounted
## T75: 필사본(계획 033) — 테마와 글꼴, 빠진 글자, 글자 크기의 아홉 단계, 양피지 밖 글의 색, 글이 상자에 드는지.
## 견본처럼 보이는지는 여기서 보지 않는다(playtester의 찍기와 판 N). 하루의 도우미는 day_tests.gd의 것을 쓴다.

const Day := preload("res://tests/day_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")
const Title := preload("res://scripts/title.gd")

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const SELECT_PATH := "res://scenes/ui/commission_select.tscn"
const DAY1_PATH := "res://data/days/day_01.tres"
const PANEL_STYLE := "res://scripts/ui/manuscript_panel_style.gd"
const BUTTON_STYLE := "res://scripts/ui/swallowtail_style.gd"
const BODY_FONT := "res://assets/fonts/NanumSquareRoundEB.ttf"
const TITLE_FONT := "res://assets/ui/font_title.tres"
const STATE_FONT := "res://assets/ui/font_state.tres"
## 바이블 10절의 아홉 단계.
const STEPS: Array[int] = [54, 46, 34, 28, 24, 20, 18, 16, 14]
## 자리와 크기를 직접 정한 버튼: 화면 -> {이름: 코드가 놓은 크기}. 최소 크기가 이보다 크면 버튼이 자란다(결정 314의 여백).
const FRESH_BUTTONS := {"Proceed": Vector2(400, 84), "Practice": Vector2(400, 54), "Help": Vector2(195, 54), "Settings": Vector2(195, 54)}
const SAVED_BUTTONS := {"Continue": Vector2(480, 84), "NewGame": Vector2(400, 50), "Practice": Vector2(400, 50), "Help": Vector2(195, 50), "Settings": Vector2(195, 50)}
const COUNTER_BUTTONS := {"Proceed": Vector2(320, 76), "Decline": Vector2(230, 56), "Quit": Vector2(170, 42), "Haggle": Vector2(210, 56)}
const SETTLE_BUTTONS := {"Proceed": Vector2(320, 76)}
const CLOSING_BUTTONS := {"Proceed": Vector2(380, 76), "Quit": Vector2(220, 46)}
const HELP_BUTTONS := {"HelpClose": Vector2(200, 54)}
const SETTINGS_BUTTONS := {"SettingsClose": Vector2(200, 54)}

var _tree: SceneTree
var _d := Day.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T75", "name": "필사본: 테마·글꼴·빠진 글자·아홉 단계·양피지 밖 글의 색·글이 든다", "fn": t75_manuscript},
	]


func cleanup() -> void:
	_d.cleanup()
	_d = null
	_tree = null


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _script_path(style: StyleBox) -> String:
	if style == null or style.get_script() == null:
		return ""
	return (style.get_script() as Script).resource_path


## 화면의 Label·Button마다: 글자가 그 글꼴(받침 포함)에 있는가, 크기가 아홉 단계 안인가.
func _check_text(errs: Array[String], screen: Node, label: String) -> void:
	var missing := {}
	var nodes: Array[Node] = screen.find_children("*", "Label", true, false)
	nodes.append_array(screen.find_children("*", "Button", true, false))
	for node in nodes:
		var control := node as Control
		var text := String(control.get("text"))
		var font := control.get_theme_font("font")
		for i in text.length():
			var code := text.unicode_at(i)
			if code > 32 and not font.has_char(code):
				missing[String.chr(code)] = true
		var font_size := control.get_theme_font_size("font_size")
		if text != "" and not STEPS.has(font_size):
			errs.append("[%s] %s의 글자 크기 %d가 아홉 단계 밖" % [label, control.name, font_size])
	if not missing.is_empty():
		errs.append("[%s] 글꼴에 없는 글자: %s" % [label, " ".join(PackedStringArray(missing.keys()))])


## 직접 놓은 버튼이 코드가 정한 크기 그대로인가(최소 크기가 크면 자란다).
func _check_buttons(errs: Array[String], screen: Node, label: String, wanted: Dictionary) -> void:
	for button_name: String in wanted:
		var button := screen.find_child(button_name, true, false) as Button
		if button == null:
			continue
		var want: Vector2 = wanted[button_name]
		var need := button.get_combined_minimum_size()
		if need.x > want.x or need.y > want.y:
			errs.append("[%s] %s의 최소 크기 %s가 놓은 크기 %s보다 큼" % [label, button_name, need, want])


func _is_on_wood(control: Control) -> bool:
	return control != null and control.get_theme_color("font_color").is_equal_approx(Ui.ON_WOOD)


func t75_manuscript() -> String:
	var errs: Array[String] = []

	# 1. 테마
	var theme := ThemeDB.get_project_theme()
	_expect(errs, theme != null, "[테마] 프로젝트 테마가 없음")
	if theme == null:
		return ", ".join(errs)
	_expect(errs, theme.default_font != null and theme.default_font.resource_path == BODY_FONT, "[테마] 기본 글꼴이 본문 글꼴이 아님")
	_expect(errs, theme.default_font_size == 20, "[테마] 기본 크기 %d (기대 20)" % theme.default_font_size)
	for type_name: String in ["Panel", "PanelContainer"]:
		_expect(errs, _script_path(theme.get_stylebox("panel", type_name)) == PANEL_STYLE, "[테마] %s의 panel이 필사본 패널이 아님" % type_name)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		_expect(errs, _script_path(theme.get_stylebox(state, "Button")) == BUTTON_STYLE, "[테마] Button의 %s가 제비꼬리가 아님" % state)
	for variation: Array in [["TitleLabel", "Label"], ["PrimaryButton", "Button"], ["HaggledButton", "Button"]]:
		_expect(errs, theme.get_type_variation_base(variation[0]) == StringName(variation[1]),
			"[테마] %s의 바탕 형이 %s가 아님" % [variation[0], variation[1]])
	var title_font := load(TITLE_FONT) as FontVariation
	_expect(errs, title_font != null and title_font.fallbacks.size() == 1 and title_font.fallbacks[0].resource_path == BODY_FONT,
		"[테마] 제목 글꼴의 받침이 본문 글꼴이 아님")
	for variation_name: String in ["TitleLabel", "PrimaryButton"]:
		_expect(errs, theme.get_font("font", variation_name) == title_font, "[테마] %s가 제목 글꼴을 쓰지 않음" % variation_name)
	var state_font := load(STATE_FONT) as FontVariation
	var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
	_expect(errs, state_font != null and int(state_font.variation_opentype.get(wght, 0)) == 900, "[테마] 상태 글자의 굵기가 900이 아님")
	var body := theme.default_font

	# 2~4. 화면마다: 글자, 크기, 버튼
	var fresh: Node = (load(Session.TITLE_PATH) as PackedScene).instantiate()
	_tree.root.add_child(fresh)
	_check_buttons(errs, fresh, "처음 화면", FRESH_BUTTONS)
	_expect(errs, not _d._has_node(fresh, "HelpScreen"), "[도움말] 열기 전인데 HelpScreen이 있음")
	_expect(errs, _d._press(fresh, "Help"), "[도움말] Help 버튼이 없음")
	var help_screen := fresh.find_child("HelpScreen", true, false) as Control
	_expect(errs, help_screen != null and help_screen.visible and help_screen.mouse_filter == Control.MOUSE_FILTER_STOP,
		"[도움말] Help를 눌렀는데 HelpScreen이 보이지 않거나 클릭을 막지 않음")
	_check_text(errs, fresh, "처음 화면·도움말")
	_check_buttons(errs, fresh, "도움말", HELP_BUTTONS)
	# 도움말의 글이 패널 안쪽(폭 956, 높이 528)에 든다: 머리 글과 밑줄, 묶음 사이 10.
	var groups := Title.help_groups()
	var used := body.get_height(28) + 1.0 + 10.0 * (groups.size() + 1)
	for group in groups:
		used += body.get_multiline_string_size(group, HORIZONTAL_ALIGNMENT_LEFT, Title.HELP_RECT.size.x - 44.0, 18).y
	_expect(errs, groups.size() >= 2 and used <= Title.HELP_RECT.size.y - 32.0,
		"[도움말] 글의 높이 %.0f가 패널 안쪽 %.0f를 넘거나 묶음이 %d개" % [used, Title.HELP_RECT.size.y - 32.0, groups.size()])
	_expect(errs, _d._press(fresh, "HelpClose") and help_screen != null and not help_screen.visible, "[도움말] HelpClose로 닫히지 않음")
	# 설정 화면(계획 S01)도 글자·크기·버튼을 한 번 지난다.
	if _d._press(fresh, "Settings") and _d._has_node(fresh, "SettingsScreen"):
		_check_text(errs, fresh, "처음 화면·설정")
		_check_buttons(errs, fresh, "설정", SETTINGS_BUTTONS)
		_expect(errs, _d._press(fresh, "SettingsClose") and not _d._has_node(fresh, "SettingsScreen"), "[설정] SettingsClose로 닫히지 않음")
	fresh.free()

	var day1 := DayState.new(_d._rules(70, 60, 20, 250), load(DAY1_PATH) as DayData)
	while day1.phase == DayState.Phase.COUNTER and day1.current_commission() != null:
		var counter: Node = _d._spawn_screen(Session.COUNTER_PATH, day1)
		var who := day1.current_commission().client_name
		_check_text(errs, counter, "카운터 " + who)
		_check_buttons(errs, counter, "카운터 " + who, COUNTER_BUTTONS)
		var header := counter.find_child("Header", true, false) as Label
		if header != null:
			var end_x := header.position.x + header.get_theme_font("font").get_string_size(
				header.text, HORIZONTAL_ALIGNMENT_LEFT, -1, header.get_theme_font_size("font_size")).x
			_expect(errs, end_x < 848.0, "[카운터 %s] 머리 줄의 끝 %.0f가 평판 줄(848)에 닿음" % [who, end_x])
		_expect(errs, _d._has_node(counter, "PanelHead"), "[카운터 %s] 말풍선에 PanelHead가 없음" % who)
		for note_name: String in ["DeclineNote", "QuitNote"]:
			var note := counter.find_child(note_name, true, false) as Label
			_expect(errs, note == null or _is_on_wood(note), "[카운터 %s] 나무 띠 위의 %s가 양피지 색이 아님" % [who, note_name])
		counter.free()
		day1.decline()

	var hurt := DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed())
	for end_reason: int in [DT.EndReason.CONDITION, DT.EndReason.PLAYER_DEFEATED, DT.EndReason.CONDITION]:
		hurt.accept()
		hurt.finish_duel(_d._record(end_reason))
		var settlement: Node = _d._spawn_screen(Session.SETTLEMENT_PATH, hurt)
		_check_text(errs, settlement, "정산")
		_check_buttons(errs, settlement, "정산", SETTLE_BUTTONS)
		for key: String in ["Base", "Tip", "Total", "Money"]:
			var row := settlement.find_child("Ledger" + key, true, false)
			var value: Label = row.find_child("Value", true, false) as Label if row != null else null
			_expect(errs, value != null and value.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT and row.find_child("Name", true, false) is Label,
				"[정산] 장부 줄 Ledger%s에 Name·오른쪽 맞춤 Value가 없음" % key)
		settlement.free()
		hurt.proceed()
	var closing: Node = _d._spawn_screen(Session.CLOSING_PATH, hurt)
	_check_text(errs, closing, "폐점")
	_check_buttons(errs, closing, "폐점", CLOSING_BUTTONS)
	for key: String in ["Income", "Rent", "Medical", "Profit", "Money"]:
		var row := closing.find_child("Ledger" + key, true, false)
		var value: Label = row.find_child("Value", true, false) as Label if row != null else null
		_expect(errs, value != null and value.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "[폐점] 장부 줄 Ledger%s가 없음" % key)
	var reputation := closing.find_child("ReputationLedger", true, false) as Label
	_expect(errs, reputation == null or _is_on_wood(reputation), "[폐점] 나무 띠 위의 평판 줄이 양피지 색이 아님")
	closing.free()

	# 저장이 있는 처음 화면(이어서 하기와 도움말).
	var saved_title: Node = (load(Session.TITLE_PATH) as PackedScene).instantiate()
	saved_title.set("saved", hurt)
	_tree.root.add_child(saved_title)
	_check_text(errs, saved_title, "처음 화면(저장 있음)")
	_check_buttons(errs, saved_title, "처음 화면(저장 있음)", SAVED_BUTTONS)
	_expect(errs, _d._press(saved_title, "Help") and _d._has_node(saved_title, "HelpScreen"), "[도움말] 저장이 있는 처음 화면에서 열리지 않음")
	saved_title.free()

	var select: Node = (load(SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	_check_text(errs, select, "연습 선택")
	select.free()

	# 결투: HUD, 결과 패널, 상태 글자
	var feather := load("res://data/commissions/feather_cut.tres") as Commission
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("commission", feather)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	var core: DuelCore = duel.get("core")
	var hud := duel.get_node("HUD")
	hud.call("refresh", core)
	(duel.get_node("ResultPanel") as ResultPanel).show_result(core, feather)
	_check_text(errs, duel, "결투")

	# 6. 양피지 밖의 글은 색을 직접 가진다(결정 314).
	var state_label := duel.get_node("OpponentView/StateLabel") as Label
	_expect(errs, state_label.get_theme_color("font_color").is_equal_approx(Color.WHITE) and state_label.get_theme_constant("outline_size") == 8
		and state_label.get_theme_font("font") == state_font, "[색] 상태 글자가 흰 글자·테두리 8·상태 글꼴이 아님")
	var warning := hud.get("_bind_warning") as Label
	_expect(errs, warning.get_theme_color("font_color").is_equal_approx(DuelHud.BindBar.COLOR_WARN) and warning.get_theme_font("font") == state_font,
		"[색] 엉킴 경고가 경고 색(BindBar.COLOR_WARN)·상태 글꼴이 아님")
	for field: String in ["_log_label", "_debug_label"]:
		_expect(errs, _is_on_wood(hud.get(field) as Label), "[색] 무대 위 글 %s가 양피지 색이 아님" % field)
	duel.free()

	# 4. 글이 상자에 든다(글꼴로 잰다. 화면의 배치는 한 프레임 안에 끝나지 않는다).
	var all: Array[Commission] = CommissionLibrary.load_all("res://data/commissions")
	all.append_array(CommissionLibrary.load_all("res://data/commissions/variants"))
	for commission in all:
		var height := body.get_multiline_string_size("\n".join(commission.describe()), HORIZONTAL_ALIGNMENT_LEFT, 310, 16).y
		_expect(errs, height <= 74.0, "[글] %s의 HUD 조건 글 높이 %.0f (74 안이어야 함)" % [commission.client_name, height])
	var longest_aim := ""
	for direction: String in DT.DIRECTION_NAMES + ["런지"]:
		for height_name: String in DT.HEIGHT_NAMES:
			for part: String in DT.PART_NAMES:
				var aim := "조준: %s · %s → %s (2칸)" % [direction, height_name, part]
				if aim.length() > longest_aim.length():
					longest_aim = aim
	var lines: Array[String] = [longest_aim, DuelHud.LUNGE_AIM_WAIT, DuelHud.LUNGE_AIM_DODGE, "내 상태: 막기 — 오른쪽"]
	for state_name: String in DT.PLAYER_STATE_NAMES:
		lines.append("내 상태: " + state_name)
	for line in lines:
		var width := body.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		_expect(errs, width <= 472.0, "[글] 조준 줄 '%s'의 폭 %.0f (472 안이어야 함)" % [line, width])
	_expect(errs, body.get_height(18) * 3.0 <= 84.0, "[글] 조준 세 줄의 높이 %.0f (84 안이어야 함)" % (body.get_height(18) * 3.0))
	var state_width := state_font.get_string_size("막기를 뗐다 다시 올려라", HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	_expect(errs, state_width <= 414.0, "[글] 상태 글자의 가장 넓은 줄 %.0f (414 안이어야 함)" % state_width)
	var meter_width := DuelHud.Meter.BAR_WIDTH + 10.0 + body.get_string_size("의심 100 (지금 끝나면 +100)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_expect(errs, meter_width <= 316.0, "[글] 조건 게이지와 글의 폭 %.0f (316 안이어야 함)" % meter_width)
	# 줄 높이는 Godot과 견본(Edge)이 다르게 잰다. 통과 조건이 아니라 판 N에서 눈으로 본다.
	print("  INFO T75 상태 글자 두 줄의 높이 %.0f (바이블 9절의 상자 80), 가장 넓은 줄 %.0f, 가장 긴 조준 줄 '%s'" % [
		state_font.get_multiline_string_size("큰 베기!!\n받아낼 준비", HORIZONTAL_ALIGNMENT_CENTER, -1, 28).y, state_width, longest_aim])
	return "OK" if errs.is_empty() else ", ".join(errs)
