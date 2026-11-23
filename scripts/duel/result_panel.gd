class_name ResultPanel
extends CanvasLayer
## 결투가 끝나면 결투 씬 위에 뜨는 패널: 결과, 충족도, 항목별 내역, 결투 시간.
## 전부 코드로 만든다(애셋 없음). 패널은 테마의 필사본이다(결정 314). Control은 전부 마우스를 무시한다.

const DT := preload("res://scripts/duel/duel_types.gd")
const Ui := preload("res://scripts/day_ui.gd")

const PANEL_SIZE := Vector2(820, 490)

const DEFAULT_FOOTER := "R: 다시 하기 · Esc: 의뢰 선택"

## 화면에 표시한 충족도. 의뢰가 없는 자유 결투는 -1이다.
var shown_score := -1
## 맨 아래 안내 글. 하루 플레이 중의 결투는 다른 글을 넣는다.
var footer_text := DEFAULT_FOOTER

var _panel: Panel
var _title: Label
var _score: Label
var _details: Label
var _footer: Label


func _ready() -> void:
	_panel = Panel.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	add_child(_panel)

	_title = _add_label(Rect2(20, 18, PANEL_SIZE.x - 40, 44), 28)
	_title.theme_type_variation = &"TitleLabel"
	_score = _add_label(Rect2(20, 66, PANEL_SIZE.x - 40, 64), 46)
	_score.theme_type_variation = &"TitleLabel"
	# 내역은 가장 많을 때 열 줄쯤이다(지기 의뢰의 의심 항목 전부 + 합계 + 결투 시간).
	_details = _add_label(Rect2(40, 138, PANEL_SIZE.x - 80, 290), 20)
	_details.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer = _add_label(Rect2(20, PANEL_SIZE.y - 54, PANEL_SIZE.x - 40, 36), 20)
	_footer.add_theme_color_override("font_color", Ui.DIM)
	hide_result()


func is_showing() -> bool:
	return _panel.visible


func hide_result() -> void:
	_panel.visible = false
	shown_score = -1


## 끝난 결투의 결과를 보여 준다. commission이 없으면 자유 결투다.
func show_result(core: DuelCore, commission: Commission) -> void:
	var record := core.record
	var lines: Array[String] = []
	if commission != null:
		shown_score = commission.evaluate(record)
		_title.text = "%s — %s" % [commission.client_name, _end_text(core)]
		_score.text = "충족도 %d" % shown_score
		lines = commission.explain(record)
	else:
		shown_score = -1
		_title.text = "자유 결투"
		_score.text = _end_text(core)
	lines.append("결투 시간 %.1f초" % record.elapsed)
	_details.text = "\n".join(lines)
	_footer.text = footer_text
	_panel.visible = true


func _end_text(core: DuelCore) -> String:
	match core.end_reason:
		DT.EndReason.OPPONENT_HIT:
			return "승리 — 유효타!"
		DT.EndReason.PLAYER_DEFEATED:
			return "유효타를 맞고 졌다"
		DT.EndReason.TIME_UP:
			return "시간 초과"
	return core.record.end_detail


func _add_label(rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = rect.position
	label.size = rect.size
	_panel.add_child(label)
	return label
