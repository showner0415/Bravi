class_name DuelHud
extends CanvasLayer
## 결투 화면의 글자와 칸. 전부 코드로 만든다(애셋 없음).
## Control은 전부 마우스를 무시한다(클릭이 결투 씬의 _unhandled_input까지 가야 하므로).

const DT := preload("res://scripts/duel/duel_types.gd")

const LOG_LINES := 3
const HELP_RETRY := " · R 다시 하기 · Esc 의뢰 선택"
## 선공의 안내(넷째 줄). %s에는 횟수가 들어간다("(한 판에 한 번)" 등. 제한이 없는 상대면 빈 글).
const HELP_LUNGE := "방심한 상대(칼끝을 내린다)에게는 S로 물러나 멀리에서 좌클릭 — 런지%s · 예비 동작 중에는 뛰어들지 않는다"
## 런지가 나가는 때의 조준 글자. 판정과 같은 코어 함수를 읽어, 닿을 때에만 "닿는다"고 말한다.
const LUNGE_AIM_REACH := "(런지: 닿는다)"
const LUNGE_AIM_WAIT := "(런지: 예비 동작 중 — 헛칠 때까지 기다린다)"
const LUNGE_AIM_DODGE := "(런지: 머리는 피한다)"
const HELP_BIND := " · 밀착은 엉킴이 차면 밀려난다 — 차기 전에 S로 먼저 물러난다"
## 엉킴 게이지가 이 값 이상이고 간격이 밀착이면 경고를 낸다(게이지의 색, 가운데 글자, 내 칼의 경고 표시).
const BIND_WARN_RATIO := 0.8
const BIND_WARN_TEXT := "칼이 엉킨다!"
## 라벨 테두리와 띠의 색(바이블 6절 경고 규칙 2의 짙은 띠).
const BAND_COLOR := Color("#2E2620")
const HELP_TEXT := "좌클릭 공격 · 우클릭 막기 (떼고 있다가 고리가 띠에 들어올 때 누르면 패리) · 마우스 위치로 방향·높이 · W/S 간격" + HELP_RETRY + " · F1 디버그\n빈틈이 아닐 때 공격하면 상대가 자세를 되찾는다"


## 조작 안내 전체. 둘째 줄의 뒷부분과 셋째 줄은 상대 데이터에서 조립한다(장치를 끈 상대에게 틀린 안내를 하지 않게).
## has_hat: 상대가 모자를 쓴 판인가(그 판에서는 칼 든 손을 노릴 수 없고, 모자 없는 판에서는 모자가 없다).
## weapon: 내 무기. 엉킴이 있는 무기면 둘째 줄에 엉킴 안내가 붙는다.
static func help_text(opponent: OpponentData, p_day_mode := false, has_hat := false,
		weapon: WeaponData = null) -> String:
	var text := HELP_TEXT
	if p_day_mode:
		# 하루 중의 결투는 한 번뿐이다. 다시 하기와 나가기를 안내하지 않는다.
		text = text.replace(HELP_RETRY, "")
	if opponent == null:
		return text
	var marked: AttackData = null
	for atk in opponent.attacks:
		if atk.needs_raised_guard:
			marked = atk
	for habit in opponent.habits:
		if habit.response != null and habit.response.needs_raised_guard:
			marked = habit.response
	if marked != null:
		text += " · %s는 막기를 뗐다 다시 올려야 받아낸다" % marked.attack_name
	if opponent.close_hit_posture_loss > 1:
		text += " · 밀착에서 맞으면 자세 %d칸" % opponent.close_hit_posture_loss
	if weapon != null and weapon.close_bind_time > 0.0:
		text += HELP_BIND
	# 셋째 줄: 스치면 2칸 이상 깎이는 부위와 머리 지키기. 해당이 없으면 줄을 두지 않는다.
	var parts: Array[String] = []
	var by_cells := heavy_parts(opponent, has_hat)
	var counts := by_cells.keys()
	counts.sort()
	for cells: int in counts:
		parts.append("%d칸: %s" % [cells, "·".join(PackedStringArray(by_cells[cells]))])
	if opponent.guards_head:
		parts.append("머리는 패리했거나 큰 공격 뒤에만 닿는다")
	if not parts.is_empty():
		text += "\n" + " · ".join(PackedStringArray(parts))
	# 넷째 줄: 선공. 무기에 런지가 있고 상대가 방심하는 상대일 때만 둔다.
	if weapon != null and weapon.lunge_windup > 0.0 and opponent.complacent_time > 0.0:
		var count := ""
		if opponent.complacent_limit == 1:
			count = "(한 판에 한 번)"
		elif opponent.complacent_limit > 1:
			count = "(한 판에 %d번)" % opponent.complacent_limit
		text += "\n" + HELP_LUNGE % count
	return text


## 이 판에서 노릴 수 있는 부위 가운데 스치면 2칸 이상 깎이는 것. {칸 수: [부위 이름, …]}
static func heavy_parts(opponent: OpponentData, has_hat := false) -> Dictionary:
	var out := {}
	var order := [DuelTypes.Part.HEAD, DuelTypes.Part.HAT, DuelTypes.Part.TORSO,
		DuelTypes.Part.SWORD_ARM, DuelTypes.Part.SWORD_HAND, DuelTypes.Part.LEGS]
	for part: int in order:
		# 모자를 쓴 판에서는 칼 든 손을, 모자 없는 판에서는 모자를 노릴 수 없다.
		if part == (DuelTypes.Part.SWORD_HAND if has_hat else DuelTypes.Part.HAT):
			continue
		var cells := opponent.graze_cells(part)
		if cells >= 2:
			if not out.has(cells):
				out[cells] = []
			(out[cells] as Array).append(DT.PART_NAMES[part])
	return out


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


## 엉킴 게이지(0~1). 간격 글자 옆에 늘 보인다. warn이면 색이 바뀐다.
class BindBar extends Control:
	const LABEL_WIDTH := 44.0
	const COLOR_FILL := Color(0.6, 0.75, 0.95)
	const COLOR_WARN := Color(1.0, 0.45, 0.2)
	var ratio := 0.0
	var warn := false

	func set_values(p_ratio: float, p_warn: bool) -> void:
		if is_equal_approx(p_ratio, ratio) and p_warn == warn:
			return
		ratio = p_ratio
		warn = p_warn
		queue_redraw()

	## 지금 막대의 색.
	func bar_color() -> Color:
		return COLOR_WARN if warn else COLOR_FILL

	func _draw() -> void:
		draw_string(ThemeDB.fallback_font, Vector2(0, size.y - 6), "엉킴", HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			bar_color() if warn else Color(1, 1, 1, 0.8))
		var bar := Rect2(LABEL_WIDTH, 4, size.x - LABEL_WIDTH, size.y - 8)
		draw_rect(bar, Color(1, 1, 1, 0.16))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(ratio, 0.0, 1.0), bar.size.y)), bar_color())


## 상대의 방심 게이지(0~1). 상대 자세 칸 옆에 보인다. 다 차면 색이 바뀌고("방심!"),
## 찔린 횟수가 상한에 닿은 뒤에는 빈 채로 "경계"를 알린다(이 판에서는 다시 오지 않는다).
class ComplacencyBar extends Control:
	const LABEL_WIDTH := 46.0
	const COLOR_FILL := Color(0.75, 0.75, 0.8)
	const COLOR_FULL := Color(0.95, 0.8, 0.3)
	var ratio := 0.0
	var wary := false

	func set_values(p_ratio: float, p_wary: bool) -> void:
		# 글자가 "다 찼는가"로 갈리므로 어림으로 견주지 않는다(0.9999와 1을 같다고 보면 "방심!"이 뜨지 않는다).
		if p_ratio == ratio and p_wary == wary:
			return
		ratio = p_ratio
		wary = p_wary
		queue_redraw()

	## 지금의 글자: 경계 / 방심 / 방심!
	func caption() -> String:
		if wary:
			return "경계"
		return "방심!" if ratio >= 1.0 else "방심"

	func _draw() -> void:
		var full := ratio >= 1.0 and not wary
		var color := COLOR_FULL if full else COLOR_FILL
		draw_string(ThemeDB.fallback_font, Vector2(0, size.y - 5), caption(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			color if full else Color(1, 1, 1, 0.45 if wary else 0.8))
		var bar := Rect2(LABEL_WIDTH, 4, size.x - LABEL_WIDTH, size.y - 8)
		draw_rect(bar, Color(1, 1, 1, 0.16))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(ratio, 0.0, 1.0), bar.size.y)), color)


var _root: Control
var _opponent_label: Label
var _opponent_cells: PostureCells
var _player_label: Label
var _player_cells: PostureCells
var _distance_label: Label
var _bind_bar: BindBar
var _complacency_bar: ComplacencyBar
var _bind_warning: Label
var _time_label: Label
var _aim_label: Label
var _log_label: Label
var _condition_label: Label
var _meter: Meter
var _debug_label: Label
var _help_label: Label
## 하루 플레이 중의 결투인가(조작 안내에서 다시 하기·나가기를 뺀다).
var day_mode := false
var _log: Array[String] = []
var _commission: Commission


func _ready() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	add_child(_root)
	# 무대의 밝은 가장자리 위에서도 읽히게 칸·막대 묶음 뒤에 짙은 띠. 033이 필사본 패널로 바꿀 때까지(결정 298).
	_add_band("BandTopLeft", Vector2(0.0, 0.0), Rect2(12, 6, 334, 148))
	_add_band("BandTop", Vector2(0.5, 0.0), Rect2(-306, 6, 672, 55))
	_add_band("BandBottomLeft", Vector2(0.0, 1.0), Rect2(12, -156, 334, 52))

	# 상대 자세: 화면 위 가운데(상대 머리 위)
	_opponent_label = _add_label(Vector2(0.5, 0.0), Rect2(-300, 10, 600, 26), 18, HORIZONTAL_ALIGNMENT_CENTER)
	_opponent_cells = _add_cells(Vector2(0.5, 0.0), Rect2(-300, 40, 600, 14), true)
	# 간격: 왼쪽 위 / 시간: 오른쪽 위
	_distance_label = _add_label(Vector2(0.0, 0.0), Rect2(20, 12, 320, 34), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_time_label = _add_label(Vector2(1.0, 0.0), Rect2(-380, 12, 360, 30), 20, HORIZONTAL_ALIGNMENT_RIGHT)
	# 엉킴 게이지: 간격 글자 옆. 엉킴이 없는 무기면 숨긴다.
	_bind_bar = BindBar.new()
	_bind_bar.name = "BindBar"
	_bind_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_bind_bar, Vector2(0.0, 0.0), Rect2(160, 17, 170, 24))
	_bind_bar.visible = false
	_root.add_child(_bind_bar)
	# 엉킴 경고: 화면 가운데, 상대의 상태 글자 아래. 밀착에서 눈이 가 있는 자리다.
	_bind_warning = _add_label(Vector2(0.5, 0.0), Rect2(-300, 104, 600, 34), 26, HORIZONTAL_ALIGNMENT_CENTER)
	_bind_warning.name = "BindWarning"
	_bind_warning.text = BIND_WARN_TEXT
	_bind_warning.add_theme_color_override("font_color", BindBar.COLOR_WARN)
	_bind_warning.visible = false
	# 방심 게이지: 상대 자세 칸의 오른쪽. 선공이 없는 판에서는 숨긴다.
	_complacency_bar = ComplacencyBar.new()
	_complacency_bar.name = "ComplacencyBar"
	_complacency_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_complacency_bar, Vector2(0.5, 0.0), Rect2(210, 36, 150, 22))
	_complacency_bar.visible = false
	_root.add_child(_complacency_bar)
	# 내 자세: 왼쪽 아래
	_player_label = _add_label(Vector2(0.0, 1.0), Rect2(20, -150, 320, 26), 18, HORIZONTAL_ALIGNMENT_LEFT)
	_player_cells = _add_cells(Vector2(0.0, 1.0), Rect2(20, -120, 320, 14), false)
	_player_cells.fill_color = Color(0.4, 0.9, 0.6)
	# 조준: 오른쪽 아래. 가장 긴 글(런지의 "기다린다")이 한 줄에 들어가는 폭이다.
	_aim_label = _add_label(Vector2(1.0, 1.0), Rect2(-720, -162, 700, 60), 18, HORIZONTAL_ALIGNMENT_RIGHT)
	# 최근 사건: 왼쪽 가운데
	_log_label = _add_label(Vector2(0.0, 0.5), Rect2(20, -60, 520, 100), 20, HORIZONTAL_ALIGNMENT_LEFT)
	# 조작 안내: 아래 가운데 (네 줄까지). 내 손과 겹치는 자리라 글자가 묻히지 않게 어두운 띠를 깐다.
	var help_bar := ColorRect.new()
	help_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_bar.color = Color(0.08, 0.08, 0.1, 0.85)
	help_bar.anchor_right = 1.0
	help_bar.anchor_top = 1.0
	help_bar.anchor_bottom = 1.0
	help_bar.offset_top = -104.0
	_root.add_child(help_bar)
	_help_label = _add_label(Vector2(0.5, 1.0), Rect2(-620, -102, 1240, 98), 14, HORIZONTAL_ALIGNMENT_CENTER)
	_help_label.text = HELP_TEXT
	_help_label.modulate = Color(1, 1, 1, 0.7)
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
	_debug_label = _add_label(Vector2(1.0, 0.5), Rect2(-380, -130, 360, 260), 16, HORIZONTAL_ALIGNMENT_RIGHT)
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
	var help := help_text(opp, day_mode, core.opponent_has_hat, core.weapon)
	if _help_label.text != help:
		_help_label.text = help
	_player_label.text = "내 자세 %d/%d" % [core.player_posture, core.rules.player_posture_max]
	_player_cells.set_values(core.rules.player_posture_max, core.player_posture)
	_distance_label.text = "간격: %s" % DT.DISTANCE_NAMES[core.distance]
	var bind_warn := bind_warning_now(core)
	_bind_bar.visible = core.has_bind()
	_bind_bar.set_values(core.bind_gauge(), bind_warn)
	_bind_warning.visible = bind_warn
	_complacency_bar.visible = core.has_lunge()
	_complacency_bar.set_values(core.complacency(), core.has_lunge() and core.brain.is_wary())
	_time_label.text = "남은 시간 %.1f초 · 경과 %.1f초" % [maxf(core.rules.time_limit - core.time, 0.0), core.time]

	# 런지가 나가는 때(멀리 + 방심)에는 방향 대신 "런지"를 적고, 부위는 런지가 노리는 부위(가운데 세로줄)다.
	var lunge := core.is_lunge_now()
	var part := core.current_aim_part()
	var aim := "조준: %s · %s → %s" % [
		"런지" if lunge else DT.DIRECTION_NAMES[core.aim_direction], DT.HEIGHT_NAMES[core.aim_height], DT.PART_NAMES[part]]
	# 스치면 2칸 이상 깎이는 부위는 칸 수를 붙인다.
	var aim_cells := opp.graze_cells(part)
	if aim_cells >= 2:
		aim += " (%d칸)" % aim_cells
	if lunge:
		aim += " " + lunge_aim_note(core)
	elif core.distance == DT.Distance.FAR:
		aim += " (멀리: 닿지 않음)"
	var state: String = DT.PLAYER_STATE_NAMES[core.player_state]
	if core.player_state == DT.PlayerState.GUARD:
		state += " — %s" % DT.GUARD_NAMES[core.aim_direction]
	if core.is_shoved():
		state = "밀려남"
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
		var bag := brain.bag_remaining()
		_debug_label.text = "[디버그]\n상대 상태: %s\n남은 시간: %s\n연속 막힘: %d\n공격: %s\n내 상태 남은 시간: %s\n막기 쿨다운: %.2f\n지금 누르면 섣부른 공격: %s\n지금 타격이 오면 버티기: %s\n가방에 남은 장 수: %s\n방심 게이지: %.2f (찔린 횟수 %d)\n지금 좌클릭이 런지: %s" % [
			DT.OPPONENT_STATE_NAMES[brain.state],
			("%.2f" % remain) if is_finite(remain) else "-",
			brain.blocked_streak,
			brain.current_attack.attack_name if brain.current_attack != null else "-",
			("%.2f" % (core.player_state_end - core.time)) if is_finite(core.player_state_end) else "-",
			maxf(core.guard_cooldown_end - core.time, 0.0),
			"예" if core.is_rash_now() else "아니오",
			"예" if core.would_brace_now() else "아니오",
			str(bag) if bag >= 0 else "-",
			core.complacency(), brain.lunge_touches,
			"예" if core.is_lunge_now() else "아니오",
		]


## 지금 엉킴 경고를 낼 때인가: 엉킴이 있는 무기이고, 간격이 밀착이고, 게이지가 BIND_WARN_RATIO 이상이다.
## HUD와 내 칼의 표시가 함께 쓴다.
static func bind_warning_now(core: DuelCore) -> bool:
	return core.has_bind() and not core.ended and core.distance == DuelTypes.Distance.CLOSE 		and core.bind_gauge() >= BIND_WARN_RATIO


## 런지가 나가는 때의 조준 글자. 판정이 쓰는 코어 함수를 그대로 읽는다(HUD가 따로 계산하지 않는다).
## "닿는다"는 닿을 때에만 말한다: 상대가 예비 동작 중이면 "기다린다", 머리를 노리는데 피할 때면 "피한다".
static func lunge_aim_note(core: DuelCore) -> String:
	if core.is_rash_now():
		return LUNGE_AIM_WAIT
	if core.current_aim_part() == DuelTypes.Part.HEAD and core.lunge_head_dodged_now():
		return LUNGE_AIM_DODGE
	return LUNGE_AIM_REACH


func _describe(ev: Dictionary) -> String:
	match ev["type"]:
		DuelRecord.STRIKE:
			match ev["result"]:
				DT.StrikeResult.BLOCKED:
					if ev["braced"]:
						return "버텼다 — 빈틈 없음 (들고만 있던 막기)"
					if (ev["attack"] as AttackData).needs_raised_guard:
						return "받아냄!"
					return "막음"
				DT.StrikeResult.PARRIED:
					return "패리!"
				DT.StrikeResult.WHIFF:
					return "상대가 헛침"
				DT.StrikeResult.GRAZE:
					var loss: int = ev["posture_loss"]
					return "스침당함 — 내 자세 -%d%s (%s)" % [
						loss, " (밀착)" if loss >= 2 else "", DT.SITUATION_NAMES[ev["situation"]]]
				DT.StrikeResult.HIT:
					return "유효타를 맞음! (%s)" % DT.SITUATION_NAMES[ev["situation"]]
		DuelRecord.ATTACK:
			var part: String = DT.PART_NAMES[ev["part"]]
			match ev["result"]:
				DT.AttackResult.WHIFF:
					return "헛침 (멀리)"
				DT.AttackResult.BLOCKED:
					if ev["dodged"]:
						return "머리를 피했다 — 패리했거나 큰 공격 뒤에만 닿는다"
					if ev.get("lunge", false) and ev["rash"]:
						var regained := " · 상대 자세 +%d" % ev["posture_gain"] if ev["posture_gain"] > 0 else ""
						return "런지가 막혔다 — 상대는 예비 동작 중이었다" + regained
					if ev["rash"]:
						if ev["posture_gain"] > 0:
							return "섣부른 공격 — 상대 자세 +%d" % ev["posture_gain"]
						return "섣부른 공격 — 빈틈이 아니다"
					return "닿지 않음 — %s" % part
				DT.AttackResult.GRAZE:
					if ev.get("lunge", false):
						return "선공! 런지 — %s%s" % [part, " (-%d)" % ev["cells"] if int(ev["cells"]) >= 2 else ""]
					if int(ev["cells"]) >= 2:
						return "스침 — %s (-%d)" % [part, ev["cells"]]
					return "스침 — %s" % part
				DT.AttackResult.HIT:
					return "유효타! — %s" % part
		DuelRecord.SHOVE:
			return "칼이 엉켜 밀려났다 — 그동안 막을 수 없다"
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
	# 무대 위에서 흰·노란 글자가 묻히지 않게(결정 298)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", BAND_COLOR)
	_place(label, anchor, rect)
	_root.add_child(label)
	return label


func _add_band(band_name: String, anchor: Vector2, rect: Rect2) -> void:
	var band := ColorRect.new()
	band.name = band_name
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.color = Color(BAND_COLOR, 0.85)
	_place(band, anchor, rect)
	_root.add_child(band)


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
