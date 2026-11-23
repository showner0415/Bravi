extends Control
## 처음 화면. 하루 플레이를 시작하거나(저장이 있으면 이어서 하거나 새로 시작한다) 연습(의뢰를 골라 결투)으로 간다.
## 저장이 없으면 버튼은 셋이다(가게를 연다, 연습, 도움말). 도움말 화면은 처음 열 때 만든다(결정 323).

const Ui := preload("res://scripts/day_ui.gd")

const CONTINUE_TEXT := "이어서 한다 — %d일차 아침부터"
const SAVE_INFO := "소지금 %d · 가진 업그레이드 %d개"
const SAVE_INFO_REPUTATION := " · 평판 별 %d/%d"
const NEW_GAME_TEXT := "새로 시작한다"
const NEW_GAME_ARMED := "한 번 더 누르면 새로 시작한다"
const NEW_GAME_WARNING := "지금 가게(%d일차)는 지워진다. 되돌릴 수 없다"
## 첫 누름 뒤 두 번째 누름을 받지 않는 시간(밀리초). 더블클릭과 Enter 연타가 경고를 읽기 전에 지우지 않게 한다.
## 윈도의 기본 더블클릭 간격(0.5초)보다 길게 잡았다. 임시 값이다(계획 018).
const NEW_GAME_LOCK_MSEC := 600
const SAVE_UNREADABLE := "저장 파일을 읽지 못했다 — 가게를 열면 새로 시작하고, 그 파일은 덮어쓴다"
const PRACTICE_TEXT := "연습 — 의뢰를 골라 결투"
const HINT_TEXT := "Space / Enter 또는 클릭"
const HELP_TEXT := "도움말"
const HELP_CLOSE_TEXT := "돌아간다"
const HELP_RECT := Rect2(140, 60, 1000, 560)

## 이어서 할 저장을 되돌린 하루. 비어 있으면 /root/GameSession에서 읽는다. 없으면 저장이 없는 처음 화면이다.
var saved: DayState
## 저장 파일이 있는데 읽을 수 없다. saved와 이것 가운데 하나라도 밖에서 넣었으면(테스트) 세션을 읽지 않는다.
var save_unreadable := false

var _new_game: Button
## "새로 시작한다"를 한 번 눌렀다. 한 번 더 누르면 지금 가게를 지우고 새로 시작한다.
var _armed := false
## "새로 시작한다"를 처음 누른 때(Time.get_ticks_msec()).
var _armed_msec := 0
var _help_button: Button
## 도움말 화면(HelpScreen). 처음 열 때 만든다. 그래서 열기 전의 처음 화면에는 버튼이 하나만 늘어난다.
var _help_screen: Control


func _ready() -> void:
	Ui.add_background(self)

	var title := Ui.add_title(self, "명예 결투 대리 의뢰소", 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 80)

	var subtitle := Ui.add_label(self, "의뢰를 받아 결투를 대신 치러 드립니다 — 부탁받은 그대로", 24, Ui.DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 240)
	subtitle.size = Vector2(1280, 40)

	var session := get_node_or_null(^"/root/GameSession")
	if saved == null and not save_unreadable and session != null:
		saved = session.call("load_saved_day") as DayState
		save_unreadable = saved == null and bool(session.call("save_exists"))

	if saved != null:
		_build_continue()
	else:
		_build_fresh()


## 저장이 없는(또는 읽을 수 없는) 처음 화면: 가게를 연다, 연습.
func _build_fresh() -> void:
	var open := Ui.add_button(self, "가게를 연다", 28, "Proceed", true)
	open.position = Vector2(440, 360)
	open.size = Vector2(400, 84)
	open.pressed.connect(_open_shop)

	var practice := Ui.add_button(self, PRACTICE_TEXT, 20, "Practice")
	practice.position = Vector2(440, 470)
	practice.size = Vector2(400, 54)
	practice.pressed.connect(_practice)
	_add_help_button(Rect2(440, 534, 400, 54))

	var hint := Ui.add_label(self, HINT_TEXT, 16, Ui.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 600)
	hint.size = Vector2(1280, 30)

	if save_unreadable:
		var unreadable := Ui.add_label(self, SAVE_UNREADABLE, 16, Ui.DIM)
		unreadable.name = "SaveUnreadable"
		unreadable.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unreadable.position = Vector2(0, 636)
		unreadable.size = Vector2(1280, 28)

	open.grab_focus()


## 저장이 있는 처음 화면: 이어서 한다(포커스), 저장의 정보 한 줄, 새로 시작한다, 연습.
func _build_continue() -> void:
	var resume := Ui.add_button(self, CONTINUE_TEXT % saved.day_number, 28, "Continue", true)
	resume.position = Vector2(400, 330)
	resume.size = Vector2(480, 84)
	resume.pressed.connect(_continue)

	var info_text := SAVE_INFO % [saved.money, saved.owned.size()]
	if saved.has_reputation():
		info_text += SAVE_INFO_REPUTATION % [saved.reputation_stars(), saved.reputation_rules.max_stars()]
	var info := Ui.add_label(self, info_text, 18, Ui.DIM)
	info.name = "SaveInfo"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.position = Vector2(0, 422)
	info.size = Vector2(1280, 28)

	_new_game = Ui.add_button(self, NEW_GAME_TEXT, 20, "NewGame")
	_new_game.position = Vector2(440, 462)
	_new_game.size = Vector2(400, 50)
	_new_game.pressed.connect(_on_new_game)

	var practice := Ui.add_button(self, PRACTICE_TEXT, 20, "Practice")
	practice.position = Vector2(440, 522)
	practice.size = Vector2(400, 50)
	practice.pressed.connect(_practice)
	_add_help_button(Rect2(440, 582, 400, 50))

	var hint := Ui.add_label(self, HINT_TEXT, 16, Ui.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 642)
	hint.size = Vector2(1280, 30)

	resume.grab_focus()


## 도움말 화면의 글: 결투 안내(연습 결투가 의뢰 없이 쓰는 기본 상대·무기)를 줄마다 한 묶음으로,
## 묶음 안의 항목마다 한 줄로 펼친다(결정 323. 결투 화면에는 안내가 없다).
static func help_groups() -> Array[String]:
	var opponent := load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData
	var weapon := load(DuelScene.WEAPON_PATH) as WeaponData
	var groups: Array[String] = []
	for line in DuelHud.help_text(opponent, false, false, weapon).split("\n"):
		var items: Array[String] = []
		for item in line.split(" · "):
			items.append("· " + item)
		groups.append("\n".join(PackedStringArray(items)))
	return groups


func _add_help_button(rect: Rect2) -> void:
	_help_button = Ui.add_button(self, HELP_TEXT, 20, "Help")
	_help_button.position = rect.position
	_help_button.size = rect.size
	_help_button.pressed.connect(_show_help)


func _build_help() -> void:
	_help_screen = Control.new()
	_help_screen.name = "HelpScreen"
	_help_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 아래 버튼의 클릭을 막는다(마우스를 받는 화면은 이것 하나다. 결정 314).
	_help_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_help_screen)
	Ui.add_background(_help_screen)
	var column := Ui.add_panel(_help_screen, HELP_RECT, 10)
	Ui.add_title(column, HELP_TEXT, 28)
	var underline := ColorRect.new()
	underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underline.color = Ui.DIM
	underline.custom_minimum_size = Vector2(0, 1)
	column.add_child(underline)
	for group in help_groups():
		Ui.add_wrapped(column, group, 18)
	var close := Ui.add_button(_help_screen, HELP_CLOSE_TEXT, 20, "HelpClose")
	close.position = Vector2(540, 636)
	close.size = Vector2(200, 54)
	close.pressed.connect(_hide_help)


func _show_help() -> void:
	if _help_screen == null:
		_build_help()
	_help_screen.visible = true
	# Space·Enter가 아래의 버튼을 누르지 않게 초점을 닫기 버튼으로 옮긴다.
	(_help_screen.find_child("HelpClose", true, false) as Button).grab_focus()


func _hide_help() -> void:
	if _help_screen == null:
		return
	_help_screen.visible = false
	if _help_button != null:
		_help_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _help_screen != null and _help_screen.visible and event.is_action_pressed(&"ui_cancel"):
		_hide_help()
		get_viewport().set_input_as_handled()


## 두 번째 누름을 받는가: 첫 누름(armed_msec)에서 NEW_GAME_LOCK_MSEC가 지났다.
static func can_confirm_new_game(armed_msec: int, now_msec: int) -> bool:
	return now_msec - armed_msec >= NEW_GAME_LOCK_MSEC


## 새로 시작한다: 지금 가게를 지우는 선택이라 두 번 눌러야 한다. 첫 번째는 알리기만 한다(파일은 그대로다).
## 첫 누름 직후의 누름(더블클릭, Enter 연타)은 받지 않는다. 잠깐 뒤에 다시 누르면 지운다.
func _on_new_game() -> void:
	if _armed:
		if can_confirm_new_game(_armed_msec, Time.get_ticks_msec()):
			_open_shop()
		return
	_armed = true
	_armed_msec = Time.get_ticks_msec()
	_new_game.text = NEW_GAME_ARMED
	var warning := Ui.add_label(self, NEW_GAME_WARNING % saved.day_number, 18, Ui.ACCENT)
	warning.name = "NewGameWarning"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.position = Vector2(0, 676)
	warning.size = Vector2(1280, 28)


## 저장된 아침에서 잇는다. 그 사이에 파일이 사라졌으면 처음 화면을 다시 연다.
func _continue() -> void:
	var session := Ui.current_session(self)
	if session == null:
		return
	if bool(session.call("continue_day_play")):
		session.call("go_to_phase_scene")
	else:
		session.call("go_to_title")


## 새 1일차를 시작한다(그 아침이 적힌다. 옛 저장은 덮어쓴다).
func _open_shop() -> void:
	var session := Ui.current_session(self)
	if session == null:
		return
	session.call("start_day_play")
	session.call("go_to_phase_scene")


func _practice() -> void:
	var session := Ui.current_session(self)
	if session == null:
		return
	session.call("go_to_practice")
