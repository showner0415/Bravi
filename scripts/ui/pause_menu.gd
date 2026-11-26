class_name PauseMenu
extends CanvasLayer
## 멈춤 화면(계획 S02, 결정 510): 계속 / 설정 / 나가기. 결투의 멈춤과 카운터·정산·폐점의 "잠깐"이 같이 쓴다.
## 열 때마다 만들고 닫으면 지운다. 멈추는 일(깃발)은 연 쪽이 한다: 이 화면은 신호만 낸다.

const Ui := preload("res://scripts/day_ui.gd")
const SessionScript := preload("res://scripts/game_session.gd")

const LAYER := 10
const PANEL_RECT := Rect2(440, 170, 400, 380)
const BUTTON_SIZE := Vector2(340, 54)
const TITLE_DUEL := "멈춤"
const TITLE_DAY := "잠깐"
const RESUME_TEXT := "계속"
const SETTINGS_TEXT := "설정"
const EXIT_DAY_TEXT := "처음 화면으로"

## "계속"이나 Esc. 이 화면은 신호를 내기 전에 스스로 닫는다.
signal resumed
## 나가기 버튼. 닫지 않는다(씬이 바뀌면 함께 사라진다).
signal exit_pressed

var _title_text := TITLE_DUEL
var _exit_text := ""
var _exit_note := ""
var _root: Control
var _resume_button: Button
var _settings_button: Button


## exit_text가 비면 나가기를 만들지 않고, exit_note가 비면 그 아래 글이 없다.
static func open(host: Node, exit_text: String, exit_note: String, title := TITLE_DUEL) -> PauseMenu:
	var menu := PauseMenu.new()
	menu._title_text = title
	menu._exit_text = exit_text
	menu._exit_note = exit_note
	host.add_child(menu)
	return menu


## 카운터·정산·폐점의 Esc(Q3): 같은 창을 "잠깐"으로 연다. 이미 열려 있으면 null이다.
static func open_for_day(screen: Control, day: DayState, on_exit: Callable) -> PauseMenu:
	if screen.get_node_or_null(^"PauseMenu") != null:
		return null
	var session := screen.get_node_or_null(^"/root/GameSession") if screen.is_inside_tree() else null
	var resume_day := int(session.call("resume_day")) if session != null else 0
	var menu := open(screen, EXIT_DAY_TEXT, SessionScript.quit_note(day, resume_day), TITLE_DAY)
	menu.exit_pressed.connect(on_exit)
	return menu


func _ready() -> void:
	name = "PauseMenu"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 도움말 덮개처럼 붙이기 전에 앵커를 둔다(결정 502).
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(Ui.INK, 0.6)
	_root.add_child(dim)

	var column := Ui.add_panel(_root, PANEL_RECT, 14)
	Ui.add_title(column, _title_text, 28)
	_resume_button = _add_button(column, RESUME_TEXT, "PauseResume")
	_resume_button.pressed.connect(_dismiss.bind(true))
	_settings_button = _add_button(column, SETTINGS_TEXT, "PauseSettings")
	_settings_button.pressed.connect(_open_settings)
	_settings_button.disabled = get_node_or_null(^"/root/Settings") == null
	if _exit_text != "":
		var exit := _add_button(column, _exit_text, "PauseExit")
		exit.pressed.connect(exit_pressed.emit)
	if _exit_note != "":
		var note := Ui.add_wrapped(column, _exit_note, 16, Ui.DIM)
		note.name = "PauseExitNote"
	_resume_button.grab_focus()


func _add_button(column: Control, text: String, node_name: String) -> Button:
	var button := Ui.add_button(column, text, 20, node_name)
	button.custom_minimum_size = BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button


func _open_settings() -> void:
	var settings := get_node_or_null(^"/root/Settings")
	if settings == null:
		return
	var screen := SettingsScreen.open(_root, settings)
	screen.closed.connect(_settings_button.grab_focus)


## 설정 화면이 열려 있으면 그쪽이 Esc를 먼저 먹는다(트리에서 뒤에 붙은 노드가 먼저 받는다).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_dismiss(false)


## 닫는다. Esc는 처리됨 표시를 닫기보다 먼저 한다: 같은 누름을 결투의 back이 다시 받아 또 멈추지 않게(결정 510).
func _dismiss(from_button: bool) -> void:
	if not from_button:
		get_viewport().set_input_as_handled()
	var parent := get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()
	resumed.emit()
