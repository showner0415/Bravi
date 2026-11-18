extends Control
## 처음 화면. 하루 플레이를 시작하거나 연습(의뢰를 골라 결투)으로 간다.

const Ui := preload("res://scripts/day_ui.gd")


func _ready() -> void:
	Ui.add_background(self)

	var title := Ui.add_label(self, "명예 결투 대리 의뢰소", 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 80)

	var subtitle := Ui.add_label(self, "의뢰를 받아 결투를 대신 치러 드립니다 — 부탁받은 그대로", 22, Ui.DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 240)
	subtitle.size = Vector2(1280, 40)

	var open := Ui.add_button(self, "가게를 연다", 30, "Proceed")
	open.position = Vector2(440, 360)
	open.size = Vector2(400, 84)
	open.pressed.connect(_open_shop)

	var practice := Ui.add_button(self, "연습 — 의뢰를 골라 결투", 20, "Practice")
	practice.position = Vector2(440, 470)
	practice.size = Vector2(400, 54)
	practice.pressed.connect(_practice)

	var hint := Ui.add_label(self, "Space / Enter 또는 클릭", 16, Ui.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1280, 30)

	open.grab_focus()


func _open_shop() -> void:
	# 다른 씬 아래에 붙어 있을 때(테스트)는 아무 데도 가지 않는다.
	var session := get_node_or_null(^"/root/GameSession")
	if session == null or get_tree().current_scene != self:
		return
	session.call("start_day_play")
	session.call("go_to_phase_scene")


func _practice() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session == null or get_tree().current_scene != self:
		return
	session.call("go_to_practice")
