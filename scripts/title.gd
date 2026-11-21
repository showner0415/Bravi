extends Control
## 처음 화면. 하루 플레이를 시작하거나(저장이 있으면 이어서 하거나 새로 시작한다) 연습(의뢰를 골라 결투)으로 간다.
## 저장이 없으면 버튼은 둘이다(가게를 연다, 연습).

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

## 이어서 할 저장을 되돌린 하루. 비어 있으면 /root/GameSession에서 읽는다. 없으면 저장이 없는 처음 화면이다.
var saved: DayState
## 저장 파일이 있는데 읽을 수 없다. saved와 이것 가운데 하나라도 밖에서 넣었으면(테스트) 세션을 읽지 않는다.
var save_unreadable := false

var _new_game: Button
## "새로 시작한다"를 한 번 눌렀다. 한 번 더 누르면 지금 가게를 지우고 새로 시작한다.
var _armed := false
## "새로 시작한다"를 처음 누른 때(Time.get_ticks_msec()).
var _armed_msec := 0


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
	var open := Ui.add_button(self, "가게를 연다", 30, "Proceed")
	open.position = Vector2(440, 360)
	open.size = Vector2(400, 84)
	open.pressed.connect(_open_shop)

	var practice := Ui.add_button(self, PRACTICE_TEXT, 20, "Practice")
	practice.position = Vector2(440, 470)
	practice.size = Vector2(400, 54)
	practice.pressed.connect(_practice)

	var hint := Ui.add_label(self, HINT_TEXT, 16, Ui.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1280, 30)

	if save_unreadable:
		var unreadable := Ui.add_label(self, SAVE_UNREADABLE, 16, Ui.DIM)
		unreadable.name = "SaveUnreadable"
		unreadable.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unreadable.position = Vector2(0, 600)
		unreadable.size = Vector2(1280, 28)

	open.grab_focus()


## 저장이 있는 처음 화면: 이어서 한다(포커스), 저장의 정보 한 줄, 새로 시작한다, 연습.
func _build_continue() -> void:
	var resume := Ui.add_button(self, CONTINUE_TEXT % saved.day_number, 28, "Continue")
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

	var hint := Ui.add_label(self, HINT_TEXT, 16, Ui.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 590)
	hint.size = Vector2(1280, 30)

	resume.grab_focus()


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
	var warning := Ui.add_label(self, NEW_GAME_WARNING % saved.day_number, 18, Ui.RED)
	warning.name = "NewGameWarning"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.position = Vector2(0, 624)
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
