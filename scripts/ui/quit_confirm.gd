class_name QuitConfirm
extends CanvasLayer
## 하루 중 창 닫기의 확인 창(계획 S02, 결정 512). 멈춤 화면(층 10)보다 위다.
## 끄는 일은 하지 않는다: confirmed를 듣는 쪽(GameSession.quit_game)이 한다.

const Ui := preload("res://scripts/day_ui.gd")

const LAYER := 20
const PANEL_RECT := Rect2(390, 220, 500, 280)
const TITLE_TEXT := "게임을 끈다"
const YES_TEXT := "끈다"
const NO_TEXT := "돌아간다"

signal confirmed
signal cancelled

var _note := ""
var _no_button: Button


static func open(host: Node, note: String) -> QuitConfirm:
	var confirm := QuitConfirm.new()
	confirm._note = note
	host.add_child(confirm)
	return confirm


func _ready() -> void:
	name = "QuitConfirm"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(Ui.INK, 0.6)
	root.add_child(dim)

	var column := Ui.add_panel(root, PANEL_RECT, 14)
	Ui.add_title(column, TITLE_TEXT, 28)
	var note := Ui.add_wrapped(column, _note, 18)
	note.name = "ConfirmNote"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	var yes := Ui.add_button(row, YES_TEXT, 20, "QuitYes")
	yes.custom_minimum_size = Vector2(200, 54)
	yes.pressed.connect(confirmed.emit)
	_no_button = Ui.add_button(row, NO_TEXT, 20, "QuitNo")
	_no_button.custom_minimum_size = Vector2(200, 54)
	_no_button.pressed.connect(_cancel)
	_no_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()


func _cancel() -> void:
	var parent := get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()
	cancelled.emit()
