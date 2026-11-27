class_name DuelHud
extends CanvasLayer
## 결투 화면의 글자와 칸. 전부 코드로 만든다(애셋 없음). 패널은 견본 025의 필사본이다(결정 316~319).
## Control은 전부 마우스를 무시한다(클릭이 결투 씬의 _unhandled_input까지 가야 하므로. 패널이 조준 칸 위에 있다).

const DT := preload("res://scripts/duel/duel_types.gd")
const Ui := preload("res://scripts/day_ui.gd")
const Controls := preload("res://scripts/controls.gd")
const STATE_FONT := preload("res://assets/ui/font_state.tres")

const LOG_LINES := 3
const HELP_RETRY := " · R 다시 하기"
## 하루 모드에서도 남는다(결정 514).
const HELP_PAUSE := " · Esc 멈춤"
## 선공의 안내(넷째 줄). %s에는 횟수가 들어간다("(한 판에 한 번)" 등. 제한이 없는 상대면 빈 글).
## 앞 %s에는 후퇴, 다음에는 공격의 키 이름(토씨를 붙이지 않는다), 뒤 %s에는 횟수.
const HELP_LUNGE := "방심한 상대(칼끝을 내린다)에게는 물러나(%s) 멀리에서 %s — 런지%s · 예비 동작 중에는 뛰어들지 않는다"
## 런지가 나가는 때의 조준 글자. 판정과 같은 코어 함수를 읽어, 닿을 때에만 "닿는다"고 말한다.
const LUNGE_AIM_REACH := "(런지: 닿는다)"
const LUNGE_AIM_WAIT := "(런지: 예비 동작 중 — 헛칠 때까지 기다린다)"
const LUNGE_AIM_DODGE := "(런지: 머리는 피한다)"
## 조준 미리보기(계획 R02 D3). 칸 테두리·꼬리표·덧말이 같은 말을 쓴다.
const FORECAST_WORD := {
	DT.Forecast.REACH: "닿는다", DT.Forecast.LATE: "늦다", DT.Forecast.OUT_OF_RANGE: "멀다",
	DT.Forecast.HEAD_GUARDED: "피한다", DT.Forecast.BIND_CUT: "엉킴",
}
const FORECAST_NOTE := {
	DT.Forecast.REACH: "(닿는다)", DT.Forecast.LATE: "(늦다 — 칼이 닿기 전에 빈틈이 끝난다)",
	DT.Forecast.OUT_OF_RANGE: "(멀리: 닿지 않음)", DT.Forecast.HEAD_GUARDED: "(머리를 지킨다 — 피한다)",
	DT.Forecast.BIND_CUT: "(엉킴 — 공격이 끊긴다)",
}
const HELP_BIND := " · 밀착은 엉킴이 차면 밀려난다 — 차기 전에 먼저 물러난다(%s)"
## 패턴의 막는 법(결정 377). 연습 화면도 같은 글을 쓴다.
const HELP_CHAIN := " · 이어 치기는 번호 차례대로 막기를 옮긴다(누른 채 옮기면 막고, 박자마다 새로 누르면 패리)"
const HELP_SWEEP := " · 휩쓸기는 막기를 쥔 채 점을 따라 끈다(떼면 뚫리고 패리는 없다)"
## 빈틈의 확률이 있는 상대에만 붙는다(결정 404). %s는 상한의 글.
const HELP_OPENING := " · 막아도 틈을 안 줄 때가 있다(낮은 소리)%s"
const HELP_HEIGHT := " · 고리가 뜬 칸(방향과 높이)에 마우스를 두고 막는다"
## 뛰어드는 찌르기(결정 451·454). 연습 화면도 같은 글을 쓴다.
const HELP_DIVE := " · 뛰어드는 찌르기는 막기를 떼고 멀리까지 물러서면 헛친다(막으면 밀착으로 밀고 온다)"
## 박자 고리(계획 042a 결정 635). 연습 화면의 막는 법만 쓴다. 칸 안에 들게 줄인 글이다(계획의 줄인 글).
const HELP_BEAT := " · 엇박은 막대가 길수록 늦게 온다(쥐면 틈이 짧고, 마지막 박에 새로 누르면 크게 열린다)"
## 부위별 반격(계획 R02). 연습 화면의 "반격 실험"도 같은 글을 쓴다.
const HELP_PART := " · 반격 실험: 팔을 스치면 예비 동작이 느려지고, 다리를 스친 뒤 패리는 빈틈이 더 열리며, 머리는 큰 공격 뒤에만 닿는다"
## 엉킴 게이지가 이 값 이상이고 간격이 밀착이면 경고를 낸다(게이지의 색, 가운데 글자, 내 칼의 경고 표시).
const BIND_WARN_RATIO := 0.8
const BIND_WARN_TEXT := "칼이 엉킨다!"
const RESUME_HOLD_TEXT := "다시 시작한다"
## 게이지의 짙은 띠와 무대 위 글의 테두리 색(바이블 6절 경고 규칙 2).
const BAND_COLOR := Color("#2E2620")
## 패널의 층: 무대(−2)와 상대·내 손(0) 사이라 칼과 손이 패널 위로 지난다(결정 316).
const BACK_LAYER := -1
## 조준 패널의 윗변(아래 앵커 기준). 덧말이 붙으면 한 줄만큼 올라간다.
const AIM_PANEL_TOP := -170.0
const AIM_PANEL_GROW := 24.0
## 키 이름은 InputMap에서 읽어 채운다(결정 521): 공격·막기·전진·후퇴. 처음 값이면 옛 글과 글자까지 같다.
const HELP_CONTROLS := "%s 공격 · %s 막기 (떼고 있다가 고리가 띠에 들어올 때 누르면 패리) · 마우스 위치로 방향·높이 · %s/%s 간격"
const HELP_DEBUG := " · F1 디버그"
const HELP_EMPTY := " · 비어 있는 동작: %s — 설정의 조작 탭에서 준다"
const HELP_SECOND := "\n빈틈이 아닐 때 공격하면 상대가 자세를 되찾는다"


## 조작 안내 전체. 둘째 줄의 뒷부분과 셋째 줄은 상대 데이터에서 조립한다(장치를 끈 상대에게 틀린 안내를 하지 않게).
## has_hat: 상대가 모자를 쓴 판인가(그 판에서는 칼 든 손을 노릴 수 없고, 모자 없는 판에서는 모자가 없다).
## weapon: 내 무기. 엉킴이 있는 무기면 둘째 줄에 엉킴 안내가 붙는다.
## 빈틈의 확률을 알리는 한 줄. 상한이 0이면 뒤 문장을 뺀다.
static func opening_help(opponent: OpponentData) -> String:
	var limit := opponent.opening_miss_limit
	return HELP_OPENING % (". %s 안 주면 다음은 반드시 열린다" % ("두 번" if limit == 2 else "%d번" % limit) if limit > 0 else "")


## 이 상대에 높이를 가진 타격이 있는가(공격·걸음·변주·버릇 반응. 결정 391).
static func uses_heights(opponent: OpponentData) -> bool:
	if opponent == null or not opponent.use_heights:
		return false
	var roots: Array[AttackData] = []
	roots.append_array(opponent.attacks)
	for habit in opponent.habits:
		if habit.response != null:
			roots.append(habit.response)
	for root in roots:
		var lines: Array[AttackData] = [root]
		for variant: AttackData in root.variants:
			lines.append(variant)
		for line in lines:
			if not line.heights.is_empty():
				return true
			for step: AttackData in line.chain:
				if not step.heights.is_empty():
					return true
	return false


## 비어 있는 동작이 있으면 틀(%s에 이름들)을 채운 글, 없으면 빈 글.
static func empty_note(template: String) -> String:
	var names: Array[String] = []
	for action in Controls.empty_actions():
		names.append(String(Controls.LABELS[action]))
	return template % "·".join(PackedStringArray(names)) if not names.is_empty() else ""


static func help_text(opponent: OpponentData, p_day_mode := false, has_hat := false,
		weapon: WeaponData = null) -> String:
	var text := HELP_CONTROLS % [Controls.help_name(&"attack"), Controls.help_name(&"guard"),
			Controls.help_name(&"step_forward"), Controls.help_name(&"step_back")]
	text += HELP_RETRY + HELP_PAUSE + HELP_DEBUG + empty_note(HELP_EMPTY) + HELP_SECOND
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
	# 패턴이 있는 상대만 막는 법을 덧붙인다(결정 377).
	var has_chain := false
	var has_sweep := false
	for atk in opponent.attacks:
		if not atk.chain.is_empty():
			has_sweep = has_sweep or atk.sweep
			has_chain = has_chain or not atk.sweep
	if has_chain:
		text += HELP_CHAIN
	if has_sweep:
		text += HELP_SWEEP
	if uses_heights(opponent):
		text += HELP_HEIGHT
	if opponent.opening_chance < 1.0:
		text += opening_help(opponent)
	for atk in opponent.attacks:
		if atk.dive:
			text += HELP_DIVE
			break
	if opponent.part_effects != null:
		text += HELP_PART
	if opponent.close_hit_posture_loss > 1:
		text += " · 밀착에서 맞으면 자세 %d칸" % opponent.close_hit_posture_loss
	if weapon != null and weapon.close_bind_time > 0.0:
		text += HELP_BIND % Controls.help_name(&"step_back")
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
		text += "\n" + HELP_LUNGE % [Controls.help_name(&"step_back"), Controls.help_name(&"attack"), count]
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


## 필사본 게이지의 색(바이블 6절, 결정 317).
const INK := Color("3B2A1E")
const PARCHMENT := Color("E9D8B4")
const PARCHMENT_EDGE := Color("A8895E")
## 짙은 띠 위의 게이지 글자 크기.
const GAUGE_FONT_SIZE := 16


## 사각형 안을 −35° 빗금으로 채운다(바이블 6절 "빗금은 띠로만"의 무늬, 빈 자세 칸).
static func draw_hatch(canvas: CanvasItem, rect: Rect2, color: Color, spacing := 6.0) -> void:
	var direction := Vector2(0.573576, 0.819152)
	var normal := Vector2(direction.y, -direction.x)
	var low := INF
	var high := -INF
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
		low = minf(low, normal.dot(corner))
		high = maxf(high, normal.dot(corner))
	var reach := rect.size.length()
	var k := floorf(low / spacing) * spacing
	while k <= high:
		var segment := _clip_segment(normal * k - direction * reach, normal * k + direction * reach, rect)
		if segment.size() == 2:
			canvas.draw_line(segment[0], segment[1], color, 1.0, true)
		k += spacing


## 선분을 사각형으로 자른다(Liang–Barsky). 안에 들지 않으면 빈 배열.
static func _clip_segment(a: Vector2, b: Vector2, rect: Rect2) -> PackedVector2Array:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x - rect.position.x, rect.end.x - a.x, a.y - rect.position.y, rect.end.y - a.y]
	for i in 4:
		var pi_value: float = p[i]
		var qi_value: float = q[i]
		if is_zero_approx(pi_value):
			if qi_value < 0.0:
				return PackedVector2Array()
			continue
		var t := qi_value / pi_value
		if pi_value < 0.0:
			t0 = maxf(t0, t)
		else:
			t1 = minf(t1, t)
	if t0 > t1:
		return PackedVector2Array()
	return PackedVector2Array([a + d * t0, a + d * t1])


## 짙은 띠 위의 게이지(엉킴·방심): 띠, 라벨, 테두리가 있는 막대(견본 bandGauge).
static func draw_band_gauge(canvas: Control, label_width: float, caption: String, label_color: Color,
		ratio: float, fill: Color) -> void:
	var size := canvas.size
	canvas.draw_rect(Rect2(Vector2.ZERO, size), BAND_COLOR)
	canvas.draw_string(canvas.get_theme_default_font(), Vector2(6, size.y * 0.5 + 6), caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, GAUGE_FONT_SIZE, label_color)
	var bar := Rect2(label_width, 4, size.x - label_width - 6, size.y - 8)
	var inner := bar.grow(-1)
	canvas.draw_rect(Rect2(inner.position, Vector2(inner.size.x * clampf(ratio, 0.0, 1.0), inner.size.y)), fill)
	canvas.draw_rect(bar, PARCHMENT_EDGE, false, 1.5)


## 자세 칸. 찬 칸은 칠, 빈 칸은 양피지에 빗금, 칸마다 잉크 테두리.
class PostureCells extends Control:
	var total := 0
	var filled := 0
	var cell := Vector2(24, 14)
	var gap := 4.0
	var fill_color := Color("7A5232")
	var empty_color := DuelHud.PARCHMENT
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
			if i >= filled:
				DuelHud.draw_hatch(self, rect, Color(DuelHud.INK, 0.6))
			draw_rect(rect, DuelHud.INK, false, 1.5)


## 조건의 게이지(0~100). value는 채워진 막대, pending은 그 위에 옅게 이어 붙인 "지금 끝나면 더해질 양".
## 견본의 자: 양피지 막대, 잉크 눈금 아홉, 글은 막대 오른쪽.
class Meter extends Control:
	const BAR_WIDTH := 110.0
	const FILL := Color("59663F")
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
		var bar := Rect2(0, 0, BAR_WIDTH, size.y)
		draw_rect(bar, DuelHud.PARCHMENT)
		var inner := bar.grow(-1)
		var filled := inner.size.x * clampf(value / 100.0, 0.0, 1.0)
		var extra := inner.size.x * clampf((value + pending) / 100.0, 0.0, 1.0) - filled
		draw_rect(Rect2(inner.position, Vector2(filled, inner.size.y)), FILL)
		if extra > 0.0:
			draw_rect(Rect2(inner.position.x + filled, inner.position.y, extra, inner.size.y), Color(FILL, 0.38))
		for k in range(1, 10):
			var x := BAR_WIDTH * k / 10.0
			var tick := size.y * (0.6 if k == 5 else 0.35)
			draw_line(Vector2(x, size.y), Vector2(x, size.y - tick), DuelHud.INK, 1.0)
		draw_rect(bar, DuelHud.INK, false, 1.5)
		var text := "%s %d" % [label, value]
		if pending > 0:
			text += " (지금 끝나면 +%d)" % pending
		draw_string(get_theme_default_font(), Vector2(BAR_WIDTH + 10, size.y - 4), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, DuelHud.INK)


## 엉킴 게이지(0~1). 간격 글자 옆에 늘 보인다. warn이면 색이 바뀐다.
class BindBar extends Control:
	const LABEL_WIDTH := 44.0
	const COLOR_FILL := Color("8FA3B3")
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
		DuelHud.draw_band_gauge(self, LABEL_WIDTH, "엉킴", COLOR_WARN if warn else DuelHud.PARCHMENT, ratio, bar_color())


## 상대의 방심 게이지(0~1). 위 오른쪽 패널에 보인다. 다 차면 색이 바뀌고("방심!"),
## 찔린 횟수가 상한에 닿은 뒤에는 빈 채로 "경계"를 알린다(이 판에서는 다시 오지 않는다).
class ComplacencyBar extends Control:
	const LABEL_WIDTH := 52.0
	const COLOR_FILL := Color("CFC8BA")
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
		var label_color := COLOR_FULL if full else Color(DuelHud.PARCHMENT, 0.45 if wary else 1.0)
		DuelHud.draw_band_gauge(self, LABEL_WIDTH, caption(), label_color, ratio, COLOR_FULL if full else COLOR_FILL)


## 무대 위에 바로 놓는 글(기록·디버그·엉킴 경고)이 있는 앞 층(HUD, layer 1).
var _root: Control
## 필사본 패널과 그 안의 글·게이지. 상대·내 손 밑 층(Back, layer −1)이다(결정 316).
var _back_root: Control
var _aim_panel: Panel
var _opponent_label: Label
var _opponent_cells: PostureCells
## 상대에게 걸린 지속 효과(팔 둔함·다리 흔들림. 계획 R02). 걸려 있을 때만 보인다.
var _effect_label: Label
var _player_label: Label
var _player_cells: PostureCells
var _distance_label: Label
var _bind_bar: BindBar
var _complacency_bar: ComplacencyBar
var _bind_warning: Label
var _resume_hold: Label
## 돌아오기 대기 중이다. 그동안 HUD의 엉킴 경고 글을 숨긴다(refresh가 보고 한다. 내 칼의 경고와 게이지는 그대로).
var _holding := false
var _time_label: Label
var _aim_label: Label
var _log_label: Label
var _condition_label: Label
var _meter: Meter
var _debug_label: Label
## 결투 씬이 놓는다. 조작 안내가 처음 화면의 도움말로 옮겨 가 지금은 쓰는 곳이 없다(결정 323).
var day_mode := false
var _log: Array[String] = []
var _commission: Commission


func _ready() -> void:
	_root = _make_root(self)
	var back := CanvasLayer.new()
	back.name = "Back"
	back.layer = BACK_LAYER
	add_child(back)
	_back_root = _make_root(back)

	# 패널 다섯: 견본 duelHud의 자리(결정 316). 위 가운데만 양옆과 겹치지 않게 좁혔다.
	_add_panel("PanelTopLeft", Vector2(0.0, 0.0), Rect2(10, 6, 330, 150))
	_add_panel("PanelTop", Vector2(0.5, 0.0), Rect2(-294, 4, 548, 56))
	_add_panel("PanelTopRight", Vector2(1.0, 0.0), Rect2(-380, 6, 372, 58))
	_add_panel("PanelBottomLeft", Vector2(0.0, 1.0), Rect2(10, -164, 340, 58))
	_aim_panel = _add_panel("PanelBottomRight", Vector2(1.0, 1.0), Rect2(-500, AIM_PANEL_TOP, 492, 64))

	# 위 가운데: 상대 이름과 자세
	_opponent_label = _add_label(Vector2(0.5, 0.0), Rect2(-294, 9, 548, 26), 18, HORIZONTAL_ALIGNMENT_CENTER)
	_opponent_cells = _add_cells(Vector2(0.5, 0.0), Rect2(-294, 40, 548, 14), true)
	_effect_label = _add_label(Vector2(1.0, 0.0), Rect2(-380, 68, 360, 44), 18, HORIZONTAL_ALIGNMENT_RIGHT, true)
	_effect_label.name = "EffectLabel"
	_effect_label.visible = false
	# 위 왼쪽: 간격, 엉킴 막대, 조건, 조건의 게이지
	_distance_label = _add_label(Vector2(0.0, 0.0), Rect2(20, 12, 130, 34), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_bind_bar = BindBar.new()
	_bind_bar.name = "BindBar"
	_bind_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_bind_bar, Vector2(0.0, 0.0), Rect2(152, 17, 182, 24))
	_bind_bar.visible = false
	_back_root.add_child(_bind_bar)
	_condition_label = _add_label(Vector2(0.0, 0.0), Rect2(20, 50, 310, 74), 16, HORIZONTAL_ALIGNMENT_LEFT)
	_condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_condition_label.add_theme_color_override("font_color", Ui.ACCENT)
	_meter = Meter.new()
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_meter, Vector2(0.0, 0.0), Rect2(20, 128, 310, 18))
	_meter.visible = false
	_back_root.add_child(_meter)
	# 위 오른쪽: 시간과 방심 막대(견본 자리)
	_time_label = _add_label(Vector2(1.0, 0.0), Rect2(-380, 9, 360, 26), 20, HORIZONTAL_ALIGNMENT_RIGHT)
	_complacency_bar = ComplacencyBar.new()
	_complacency_bar.name = "ComplacencyBar"
	_complacency_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_complacency_bar, Vector2(1.0, 0.0), Rect2(-374, 35, 210, 24))
	_complacency_bar.visible = false
	_back_root.add_child(_complacency_bar)
	# 아래 왼쪽: 내 자세
	_player_label = _add_label(Vector2(0.0, 1.0), Rect2(20, -160, 320, 26), 18, HORIZONTAL_ALIGNMENT_LEFT)
	_player_cells = _add_cells(Vector2(0.0, 1.0), Rect2(20, -130, 320, 14), false)
	_player_cells.fill_color = Color("59663F")
	# 아래 오른쪽: 조준. 덧말(런지·멀리)이 붙으면 한 줄 늘고 패널이 위로 자란다(refresh).
	_aim_label = _add_label(Vector2(1.0, 1.0), Rect2(-492, -194, 472, 84), 18, HORIZONTAL_ALIGNMENT_RIGHT)
	_aim_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	# 엉킴 경고: 아래 가운데, 내 칼 바로 위(결정 318. 밀착의 모자·상태 글자와 겹치지 않는다).
	_bind_warning = _add_label(Vector2(0.5, 1.0), Rect2(-130, -170, 260, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, true)
	_bind_warning.name = "BindWarning"
	_bind_warning.text = BIND_WARN_TEXT
	_bind_warning.add_theme_font_override("font", STATE_FONT)
	_bind_warning.add_theme_color_override("font_color", BindBar.COLOR_WARN)
	_bind_warning.add_theme_color_override("font_outline_color", Color.BLACK)
	_bind_warning.add_theme_constant_override("outline_size", 8)
	_bind_warning.visible = false
	# 돌아오기 대기의 글(결정 509): 엉킴 경고와 같은 사각형이라 고리와 테두리를 가리지 않는다.
	_resume_hold = _add_label(Vector2(0.5, 1.0), Rect2(-130, -170, 260, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, true)
	_resume_hold.name = "ResumeHold"
	_resume_hold.text = RESUME_HOLD_TEXT
	_resume_hold.add_theme_font_override("font", STATE_FONT)
	_resume_hold.add_theme_constant_override("outline_size", 8)
	_resume_hold.add_theme_color_override("font_outline_color", Color.BLACK)
	_resume_hold.visible = false
	# 최근 사건: 왼쪽 가운데, 조용한 구역 밖(결정 319)
	_log_label = _add_label(Vector2(0.0, 0.5), Rect2(20, -80, 410, 160), 20, HORIZONTAL_ALIGNMENT_LEFT, true)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 디버그: 오른쪽 가운데 (기본 꺼짐)
	_debug_label = _add_label(Vector2(1.0, 0.5), Rect2(-380, -130, 360, 260), 16, HORIZONTAL_ALIGNMENT_RIGHT, true)
	_debug_label.visible = false


func reset() -> void:
	_log.clear()
	_log_label.text = ""


## 의뢰 조건을 상시 표시한다. null이면 자유 결투다.
func set_commission(commission: Commission) -> void:
	_commission = commission
	_condition_label.text = "\n".join(commission.describe()) if commission != null else "자유 결투 (의뢰 없음)"
	_meter.visible = false


## 돌아오기 대기를 켜고 끈다(결정 509). 켜면 엉킴 경고 글을 바로 숨기고 끄면 다음 refresh가 되돌린다.
func set_resume_hold(on: bool) -> void:
	_holding = on
	_resume_hold.visible = on
	if on:
		_bind_warning.visible = false


## 기록 줄에 한 줄을 넣는다(판의 기록·사건 기록에는 넣지 않는다, 결정 521).
func add_note(text: String) -> void:
	_log.append(text)
	while _log.size() > LOG_LINES:
		_log.pop_front()
	_log_label.text = "\n".join(_log)


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
	_refresh_effects(core)
	_player_label.text = "내 자세 %d/%d" % [core.player_posture, core.rules.player_posture_max]
	_player_cells.set_values(core.rules.player_posture_max, core.player_posture)
	_distance_label.text = "간격: %s" % DT.DISTANCE_NAMES[core.distance]
	var bind_warn := bind_warning_now(core)
	_bind_bar.visible = core.has_bind()
	_bind_bar.set_values(core.bind_gauge(), bind_warn)
	_bind_warning.visible = bind_warn and not _holding
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
	# 덧말은 줄을 바꿔 붙이고, 그동안 조준 패널이 한 줄 자란다(견본보다 한 줄 많은 유일한 때. 결정 316).
	var note := ""
	if forecast_on(core):
		var verdict: int = core.attack_forecast()["verdict"]
		note = lunge_aim_note(core, verdict) if lunge else FORECAST_NOTE.get(verdict, "")
	elif lunge:
		note = lunge_aim_note(core)
	elif core.distance == DT.Distance.FAR:
		note = "(멀리: 닿지 않음)"
	if note != "":
		aim += "\n" + note
	_aim_panel.offset_top = AIM_PANEL_TOP - (AIM_PANEL_GROW if note != "" else 0.0)
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
		_debug_label.text = "[디버그]\n상대 상태: %s\n남은 시간: %s\n연속 막힘: %d\n공격: %s\n내 상태 남은 시간: %s\n막기 쿨다운: %.2f\n지금 누르면 섣부른 공격: %s\n지금 타격이 오면 버티기: %s\n가방에 남은 장 수: %s\n방심 게이지: %.2f (찔린 횟수 %d)\n지금 좌클릭이 런지: %s\n빈틈 확률: %.2f (연속 안 열림 %d)" % [
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
			brain.opening_chance, brain.closed_streak,
		]


## 지금 엉킴 경고를 낼 때인가: 엉킴이 있는 무기이고, 간격이 밀착이고, 게이지가 BIND_WARN_RATIO 이상이다.
## HUD와 내 칼의 표시가 함께 쓴다.
static func bind_warning_now(core: DuelCore) -> bool:
	return core.has_bind() and not core.ended and core.distance == DuelTypes.Distance.CLOSE 		and core.bind_gauge() >= BIND_WARN_RATIO


## 걸려 있는 지속 효과의 글: 남은 횟수만큼 점을 찍는다. 아무것도 없으면 빈 글이다.
static func effect_text(core: DuelCore) -> String:
	var lines: PackedStringArray = []
	if core.brain.slow_tells_left > 0:
		lines.append("팔 둔함 " + "●".repeat(core.brain.slow_tells_left))
	if core.brain.parry_charges > 0:
		lines.append("다리 흔들림 ◆ 다음 패리")
	return "\n".join(lines)


func _refresh_effects(core: DuelCore) -> void:
	var text := effect_text(core) if core.opponent_data.part_effects != null else ""
	_effect_label.text = text
	_effect_label.visible = text != ""


## 조준 미리보기를 보일 판인가(상대 데이터가 켰다). 칸 테두리·꼬리표·덧말이 함께 본다.
static func forecast_on(core: DuelCore) -> bool:
	var fx := core.opponent_data.part_effects
	return fx != null and fx.show_forecast


## 런지가 나가는 때의 조준 글자. 판정이 쓰는 코어 함수를 그대로 읽는다(HUD가 따로 계산하지 않는다).
## "닿는다"는 닿을 때에만 말한다: 상대가 예비 동작 중이면 "기다린다", 머리를 노리는데 피할 때면 "피한다".
## verdict가 0 이상이면 새 규칙: 판정의 미리보기만 읽는다(UNSURE면 덧말 없음).
static func lunge_aim_note(core: DuelCore, verdict := -1) -> String:
	if verdict >= 0:
		match verdict:
			DT.Forecast.REACH:
				return LUNGE_AIM_REACH
			DT.Forecast.HEAD_GUARDED:
				return LUNGE_AIM_DODGE
			DT.Forecast.NO_OPENING:
				return LUNGE_AIM_WAIT
		return ""
	if core.is_rash_now():
		return LUNGE_AIM_WAIT
	if core.current_aim_part() == DuelTypes.Part.HEAD and core.lunge_head_dodged_now():
		return LUNGE_AIM_DODGE
	return LUNGE_AIM_REACH


## 맞은 까닭의 글. 막고 있었고 방향도 맞았으면 무엇이 틀렸는지 적는다(결정 392).
static func _hit_reason(ev: Dictionary) -> String:
	match ev.get("guard_miss", &""):
		&"height":
			return "높이가 틀린 막기"
		&"regrip":
			return "떼었다 다시 누른 막기"
	return DT.SITUATION_NAMES[ev["situation"]]


func _describe(ev: Dictionary) -> String:
	match ev["type"]:
		DuelRecord.PATTERN_STEP:
			var step_atk := ev["attack"] as AttackData
			var step_height := int(ev.get("height", -1))
			var where := ""
			if step_height >= 0:
				where = " · %s %s" % [DT.GUARD_NAMES[step_atk.direction], DT.HEIGHT_NAMES[step_height]]
			return "이어서 %s (%d/%d)%s" % [step_atk.attack_name, int(ev["index"]) + 1, int(ev["count"]), where]
		DuelRecord.STRIKE:
			if ev.get("closed", false):
				return "%s — 틈을 안 줬다%s" % ["헛침" if ev["result"] == DT.StrikeResult.WHIFF \
						else "패리" if ev["result"] == DT.StrikeResult.PARRIED else "막음",
					" (다음은 열린다)" if OpponentView._limit_reached(ev) else ""]
			match ev["result"]:
				DT.StrikeResult.BLOCKED:
					if ev["braced"]:
						return "버텼다 — 빈틈 없음 (들고만 있던 막기)"
					if (ev["attack"] as AttackData).needs_raised_guard:
						return "받아냄!"
					return "막음"
				DT.StrikeResult.PARRIED:
					# 다리 덤의 글은 일어난 일(leg_bonus)만 읽는다. none이면 덤은 한 일이 없어 말하지 않는다.
					match ev.get("leg_bonus", &""):
						&"opened":
							return "패리! — 다리가 풀려 틈이 열렸다"
						&"time":
							return "패리! — 다리가 풀려 빈틈 +%s초" % str(snappedf(float(ev["leg_time"]), 0.01))
					return "패리!"
				DT.StrikeResult.WHIFF:
					return "상대가 헛침"
				DT.StrikeResult.GRAZE:
					var loss: int = ev["posture_loss"]
					return "스침당함 — 내 자세 -%d%s (%s)" % [
						loss, " (밀착)" if loss >= 2 else "", _hit_reason(ev)]
				DT.StrikeResult.HIT:
					return "유효타를 맞음! (%s)" % _hit_reason(ev)
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
					var after := ""
					match ev.get("effect", &""):
						&"arm_slow":
							after = " · 다음 공격 %d번이 느려진다" % int(ev["slow_left"])
						&"legs_parry":
							after = " · 다음 패리에 덤"
					if ev.get("lunge", false):
						return "선공! 런지 — %s%s%s" % [part, " (-%d)" % ev["cells"] if int(ev["cells"]) >= 2 else "", after]
					if int(ev["cells"]) >= 2:
						return "스침 — %s (-%d)%s" % [part, ev["cells"], after]
					return "스침 — %s%s" % [part, after]
				DT.AttackResult.HIT:
					return "유효타! — %s" % part
		DuelRecord.SHOVE:
			return "칼이 엉켜 밀려났다 — 그동안 막을 수 없다"
		DuelRecord.STAGGER_START:
			return "상대가 무너졌다!"
		DuelRecord.STAGGER_END:
			return "상대가 자세를 되찾았다"
	return ""


## on_stage면 무대 위에 바로 놓는 글이다(앞 층, 양피지 글자에 짙은 테두리. 결정 319).
## 아니면 패널 안의 글이다(뒤 층, 테마의 잉크 글자, 테두리 없음).
func _add_label(anchor: Vector2, rect: Rect2, font_size: int, align: HorizontalAlignment, on_stage := false) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = align
	if on_stage:
		label.add_theme_color_override("font_color", Ui.ON_WOOD)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", BAND_COLOR)
	_place(label, anchor, rect)
	(_root if on_stage else _back_root).add_child(label)
	return label


func _add_panel(panel_name: String, anchor: Vector2, rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	# Panel의 기본값은 STOP이다. 놓치면 패널 위 조준 칸의 클릭이 공격·막기로 가지 않는다(결정 314).
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(panel, anchor, rect)
	_back_root.add_child(panel)
	return panel


func _add_cells(anchor: Vector2, rect: Rect2, centered: bool) -> PostureCells:
	var cells := PostureCells.new()
	cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cells.centered = centered
	_place(cells, anchor, rect)
	_back_root.add_child(cells)
	return cells


static func _make_root(layer: CanvasLayer) -> Control:
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	layer.add_child(root)
	return root


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
