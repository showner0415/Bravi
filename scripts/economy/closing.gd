extends Control
## 폐점: 오늘의 의뢰, 수입과 지출, 손익. 다음 날을 열거나 처음 화면으로 돌아간다.

const Ui := preload("res://scripts/day_ui.gd")

## 하루 플레이의 상태. 비어 있으면 /root/GameSession의 것을 본다.
var day: DayState
## 화면에 내보인 오늘의 손익. shown이 거짓이면 내보인 것이 없다.
var shown_profit := 0
var shown := false


func _ready() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if day == null and session != null and session.get("day") is DayState:
		day = session.get("day")
	Ui.add_background(self)
	if day == null or day.phase != DayState.Phase.CLOSING or day.closing_summary().is_empty():
		day = null
		call_deferred("_return_to_title")
		return
	_build(day.closing_summary())


func _build(summary: Dictionary) -> void:
	var header := Ui.add_label(self, "%d일차 — 가게를 닫는다" % day.day_number, 30)
	header.name = "Header"
	header.position = Vector2(32, 20)

	var book := Ui.add_panel(self, Rect2(200, 84, 880, 500), 8)
	Ui.add_label(book, "오늘의 의뢰", 20, Ui.DIM)
	if day.results.is_empty():
		Ui.add_label(book, "맡은 의뢰가 없다", 20)
	for result in day.results:
		var line := "%s — 충족도 %d · 기본 보수 %d · 팁 %d" % [
			result["client_name"], result["score"], result["base"], result["tip"]]
		if result["injured"]:
			line += " · 다침"
		Ui.add_label(book, line, 20)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	book.add_child(gap)

	Ui.add_label(book, "수입   +%d" % summary["income"], 22)
	Ui.add_label(book, "임대료   -%d" % summary["rent"], 22)
	Ui.add_label(book, "치료비   -%d  (%d x %d회)" % [
		summary["medical"], day.rules.medical_fee, summary["injuries"]], 22)
	shown_profit = int(summary["profit"])
	shown = true
	var profit_text := "오늘의 손익   %s%d" % ["+" if shown_profit >= 0 else "", shown_profit]
	var profit := Ui.add_label(book, profit_text, 32, Ui.GOLD if shown_profit >= 0 else Ui.RED)
	profit.name = "Profit"
	Ui.add_label(book, "소지금   %d → %d" % [summary["money_before"], summary["money_after"]], 22)

	var proceed := Ui.add_button(self, "다음 날을 연다", 28, "Proceed")
	proceed.position = Vector2(700, 610)
	proceed.size = Vector2(380, 76)
	proceed.pressed.connect(_next_day)

	var quit := Ui.add_button(self, "처음 화면으로", 18, "Quit")
	quit.position = Vector2(200, 626)
	quit.size = Vector2(220, 46)
	quit.pressed.connect(_quit)

	proceed.grab_focus()


func _next_day() -> void:
	if day == null or not day.next_day():
		return
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and get_tree().current_scene == self:
		session.call("go_to_phase_scene")


func _quit() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session == null or get_tree().current_scene != self:
		return
	session.call("end_day_play")
	session.call("go_to_title")


func _return_to_title() -> void:
	var session := get_node_or_null(^"/root/GameSession")
	if session != null and is_inside_tree() and get_tree().current_scene == self:
		session.call("go_to_title")
