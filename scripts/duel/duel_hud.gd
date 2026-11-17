class_name DuelHud
extends CanvasLayer
## 결투 화면의 글자와 칸. 전부 코드로 만든다(애셋 없음).
## Control은 전부 마우스를 무시한다(클릭이 결투 씬의 _unhandled_input까지 가야 하므로).

const DT := preload("res://scripts/duel/duel_types.gd")

const LOG_LINES := 3
const HELP_TEXT := "좌클릭 공격 · 우클릭 막기 (떼고 있다가 고리가 띠에 들어올 때 누르면 패리) · 마우스 위치로 방향·높이 · W/S 간격 · R 다시 하기 · Esc 의뢰 선택 · F1 디버그\n빈틈이 아닐 때 공격하면 상대가 자세를 되찾는다"


## 자세 칸. 채워진 칸과 빈 칸을 사각형으로 그린다.
class PostureCells extends Control:
	var total := 0
	var filled := 0
	var cell := Vector2(24, 14)
	var gap := 4.0
	var fill_color := Color(0.95, 0.8, 0.3)
	var empty_color := Color(1, 1, 1, 0.16)
	var centered := true

	func set_values(p_total: int, p_filled: int) -> void:
		if p_total == total and p_filled == filled:
			return
		total = p_total
		filled = p_filled
		queue_redraw()

	func _draw() -> void:
		var width := total * cell.x + maxf(total - 1, 0) * gap
		var x0 := (size.x - width) * 0.5 if centered else 0.0
		for i in total:
			var rect := Rect2(x0 + i * (cell.x + gap), 0.0, cell.x, cell.y)
			draw_rect(rect, fill_color if i < filled else empty_color)


## 조건의 게이지(0~100). value는 채워진 막대, pending은 그 위에 옅게 이어 붙인 "지금 끝나면 더해질 양".
class Meter extends Control:
	const BAR_WIDTH := 180.0
	var label := ""
	var value := 0
	var pending := 0

	func set_values(p_label: String, p_value: int, p_pending: int) -> void:
		if p_label == label and p_value == value and p_pending == pending:
			return
		label = p_label
		value = p_value
		pending = p_pending
		queue_redraw()

	func _draw() -> void:
		var bar := Rect2(0, 3, BAR_WIDTH, size.y - 6)
		draw_rect(bar, Color(1, 1, 1, 0.16))
		var filled := BAR_WIDTH * clampf(value / 100.0, 0.0, 1.0)
		var extra := BAR_WIDTH * clampf((value + pending) / 100.0, 0.0, 1.0) - filled
		draw_rect(Rect2(0, bar.position.y, filled, bar.size.y), Color(0.95, 0.35, 0.3))
		if extra > 0.0:
			draw_rect(Rect2(filled, bar.position.y, extra, bar.size.y), Color(0.95, 0.35, 0.3, 0.38))
		var text := "%s %d" % [label, value]
		if pending > 0:
			text += " (지금 끝나면 +%d)" % pending
		draw_string(ThemeDB.fallback_font, Vector2(BAR_WIDTH + 10, size.y - 6), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15)


var _root: Control
var _opponent_label: Label
var _opponent_cells: PostureCells
var _player_label: Label
var _player_cells: PostureCells
var _distance_label: Label
var _time_label: Label
var _aim_label: Label
var _log_label: Label
var _condition_label: Label
var _meter: Meter
var _debug_label: Label
var _log: Array[String] = []
var _commission: Commission


func _ready() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	add_child(_root)

	# 상대 자세: 화면 위 가운데(상대 머리 위)
	_opponent_label = _add_label(Vector2(0.5, 0.0), Rect2(-300, 10, 600, 26), 18, HORIZONTAL_ALIGNMENT_CENTER)
	_opponent_cells = _add_cells(Vector2(0.5, 0.0), Rect2(-300, 40, 600, 14), true)
	# 간격: 왼쪽 위 / 시간: 오른쪽 위
	_distance_label = _add_label(Vector2(0.0, 0.0), Rect2(20, 12, 320, 34), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_time_label = _add_label(Vector2(1.0, 0.0), Rect2(-380, 12, 360, 30), 20, HORIZONTAL_ALIGNMENT_RIGHT)
	# 내 자세: 왼쪽 아래
	_player_label = _add_label(Vector2(0.0, 1.0), Rect2(20, -96, 320, 26), 18, HORIZONTAL_ALIGNMENT_LEFT)
	_player_cells = _add_cells(Vector2(0.0, 1.0), Rect2(20, -66, 320, 14), false)
	_player_cells.fill_color = Color(0.4, 0.9, 0.6)
	# 조준: 오른쪽 아래
	_aim_label = _add_label(Vector2(1.0, 1.0), Rect2(-440, -108, 420, 60), 18, HORIZONTAL_ALIGNMENT_RIGHT)
	# 최근 사건: 왼쪽 가운데
	_log_label = _add_label(Vector2(0.0, 0.5), Rect2(20, -60, 420, 100), 20, HORIZONTAL_ALIGNMENT_LEFT)
	# 조작 안내: 아래 가운데 (두 줄)
	var help := _add_label(Vector2(0.5, 1.0), Rect2(-620, -48, 1240, 44), 14, HORIZONTAL_ALIGNMENT_CENTER)
	help.text = HELP_TEXT
	help.modulate = Color(1, 1, 1, 0.7)
	# 의뢰 조건과 조건의 게이지: 왼쪽 위, 간격 아래
	_condition_label = _add_label(Vector2(0.0, 0.0), Rect2(20, 50, 310, 70), 15, HORIZONTAL_ALIGNMENT_LEFT)
	_condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_condition_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	_meter = Meter.new()
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_meter, Vector2(0.0, 0.0), Rect2(20, 126, 310, 22))
	_meter.visible = false
	_root.add_child(_meter)
	# 디버그: 오른쪽 가운데 (기본 꺼짐)
	_debug_label = _add_label(Vector2(1.0, 0.5), Rect2(-380, -110, 360, 220), 16, HORIZONTAL_ALIGNMENT_RIGHT)
	_debug_label.visible = false


func reset() -> void:
	_log.clear()
	_log_label.text = ""


## 의뢰 조건을 상시 표시한다. null이면 자유 결투다.
func set_commission(commission: Commission) -> void:
	_commission = commission
	_condition_label.text = "\n".join(commission.describe()) if commission != null else "자유 결투 (의뢰 없음)"
	_meter.visible = false


func toggle_debug() -> void:
	_debug_label.visible = not _debug_label.visible


func on_event(ev: Dictionary) -> void:
	var text := _describe(ev)
	if text == "":
		return
	_log.append(text)
	while _log.size() > LOG_LINES:
		_log.pop_front()
	_log_label.text = "\n".join(_log)


func refresh(core: DuelCore) -> void:
	var opp := core.opponent_data
	_opponent_label.text = "%s — 자세 %d/%d" % [opp.display_name, core.brain.posture, opp.posture_max]
	_opponent_cells.set_values(opp.posture_max, core.brain.posture)
	_player_label.text = "내 자세 %d/%d" % [core.player_posture, core.rules.player_posture_max]
	_player_cells.set_values(core.rules.player_posture_max, core.player_posture)
	_distance_label.text = "간격: %s" % DT.DISTANCE_NAMES[core.distance]
	_time_label.text = "남은 시간 %.1f초 · 경과 %.1f초" % [maxf(core.rules.time_limit - core.time, 0.0), core.time]

	var part := core.current_aim_part()
	var aim := "조준: %s · %s → %s" % [
		DT.DIRECTION_NAMES[core.aim_direction], DT.HEIGHT_NAMES[core.aim_height], DT.PART_NAMES[part]]
	if core.distance == DT.Distance.FAR:
		aim += " (멀리: 닿지 않음)"
	var state: String = DT.PLAYER_STATE_NAMES[core.player_state]
	if core.player_state == DT.PlayerState.GUARD:
		state += " — %s" % DT.GUARD_NAMES[core.aim_direction]
	if core.ended:
		state = "결투 종료"
	_aim_label.text = "%s\n내 상태: %s" % [aim, state]

	# 조건의 게이지. 조건이 무엇인지는 모른다: 비어 있지 않은 첫 live_meter를 그린다.
	var meter := {}
	if _commission != null:
		for condition in _commission.conditions:
			if condition != null:
				meter = condition.live_meter(core.record)
				if not meter.is_empty():
					break
	_meter.visible = not meter.is_empty()
	if not meter.is_empty():
		_meter.set_values(str(meter["label"]), int(meter["value"]), int(meter["pending"]))

	if _debug_label.visible:
		var brain := core.brain
		var remain := brain.state_end - core.time
		_debug_label.text = "[디버그]\n상대 상태: %s\n남은 시간: %s\n연속 막힘: %d\n공격: %s\n내 상태 남은 시간: %s\n막기 쿨다운: %.2f\n지금 누르면 섣부른 공격: %s" % [
			DT.OPPONENT_STATE_NAMES[brain.state],
			("%.2f" % remain) if is_finite(remain) else "-",
			brain.blocked_streak,
			brain.current_attack.attack_name if brain.current_attack != null else "-",
			("%.2f" % (core.player_state_end - core.time)) if is_finite(core.player_state_end) else "-",
			maxf(core.guard_cooldown_end - core.time, 0.0),
			"예" if core.is_rash_now() else "아니오",
		]


func _describe(ev: Dictionary) -> String:
	match ev["type"]:
		DuelRecord.STRIKE:
			match ev["result"]:
				DT.StrikeResult.BLOCKED:
					return "막음"
				DT.StrikeResult.PARRIED:
					return "패리!"
				DT.StrikeResult.WHIFF:
					return "상대가 헛침"
				DT.StrikeResult.GRAZE:
					return "스침당함 — 내 자세 -1 (%s)" % DT.SITUATION_NAMES[ev["situation"]]
				DT.StrikeResult.HIT:
					return "유효타를 맞음! (%s)" % DT.SITUATION_NAMES[ev["situation"]]
		DuelRecord.ATTACK:
			var part: String = DT.PART_NAMES[ev["part"]]
			match ev["result"]:
				DT.AttackResult.WHIFF:
					return "헛침 (멀리)"
				DT.AttackResult.BLOCKED:
					if ev["rash"]:
						if ev["posture_gain"] > 0:
							return "섣부른 공격 — 상대 자세 +%d" % ev["posture_gain"]
						return "섣부른 공격 — 빈틈이 아니다"
					return "닿지 않음 — %s" % part
				DT.AttackResult.GRAZE:
					return "스침 — %s" % part
				DT.AttackResult.HIT:
					return "유효타! — %s" % part
		DuelRecord.STAGGER_START:
			return "상대가 무너졌다!"
		DuelRecord.STAGGER_END:
			return "상대가 자세를 되찾았다"
	return ""


func _add_label(anchor: Vector2, rect: Rect2, font_size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = align
	_place(label, anchor, rect)
	_root.add_child(label)
	return label


func _add_cells(anchor: Vector2, rect: Rect2, centered: bool) -> PostureCells:
	var cells := PostureCells.new()
	cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cells.centered = centered
	_place(cells, anchor, rect)
	_root.add_child(cells)
	return cells


## anchor 지점을 기준으로 한 고정 크기 사각형에 놓는다.
func _place(control: Control, anchor: Vector2, rect: Rect2) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y
