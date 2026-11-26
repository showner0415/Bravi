extends RefCounted
## T96: 그린 질감(계획 033b) — 테마가 그림을 가리키는가, 자리는 033 그대로인가, 그림이 없으면 033의 길인가, 헤짐은 큰 판의 바깥 띠에만 있는가.
## 그림이 보기 좋은지는 여기서 보지 않는다(판 U2).

const Ui := preload("res://scripts/day_ui.gd")
const WornEdge := preload("res://scripts/ui/worn_edge.gd")

const PANEL_STYLE := "res://scripts/ui/manuscript_panel_style.gd"
const BUTTON_STYLE := "res://scripts/ui/swallowtail_style.gd"
const PAPER_PATH := "res://assets/ui/paper.png"
const FRAME_PATH := "res://assets/ui/panel_frame.png"
const FRAME_SMALL_PATH := "res://assets/ui/panel_frame_plain.png"
const BUTTON_PATH := "res://assets/ui/button.png"
const WALL_PATH := "res://assets/ui/wall_style.tres"

# 판 U2의 답으로 바뀌는 값: 바뀌면 이 자리의 상수도 같이 바꾼다(U2-3 단계, U2-4 버튼의 못 누름·올림 값, 9조각 축).
const WEAR := 3
const BUTTON_PAINTED := true
const DISABLED_TINT := Color(1.0, 1.0, 1.0, 1.0)
const HOVER_TINT := Color(0.961, 0.945, 0.914, 1.0)
const PRESSED_TINT := Color(0.79, 0.71, 0.60, 1.0)
const BUTTON_AXIS_X := RenderingServer.NINE_PATCH_STRETCH
const BUTTON_AXIS_Y := RenderingServer.NINE_PATCH_STRETCH
const FRAME_AXIS := RenderingServer.NINE_PATCH_TILE_FIT

const BUTTON_STATES: Array[String] = ["normal", "hover", "pressed", "disabled"]
const SIZES: Array[Vector2] = [
	Vector2(830, 440), Vector2(830, 324), Vector2(600, 500), Vector2(592, 500),
	Vector2(1000, 560), Vector2(800, 480), Vector2(300, 420), Vector2(830, 96),
]


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T96", "name": "그린 질감: 테마가 그림을 가리키고, 자리는 033 그대로, 그림이 없으면 033의 길, 헤짐은 큰 판의 바깥 띠에만", "fn": t96_painted},
	]


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _script_path(style: StyleBox) -> String:
	if style == null or style.get_script() == null:
		return ""
	return (style.get_script() as Script).resource_path


func _tex_path(style: StyleBox, prop: String) -> String:
	var tex := style.get(prop) as Texture2D
	return "" if tex == null else tex.resource_path


func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= 0.01 and absf(a.g - b.g) <= 0.01 and absf(a.b - b.b) <= 0.01 and absf(a.a - b.a) <= 0.01


# 안전 칸: 사각형을 12 줄이고 네 모서리를 8씩 깎은 팔각형(사선 x + y = 32 — 설계 상한 28보다 크고 글의 모서리 34보다 작다).
func _safe_octagon(size: Vector2) -> PackedVector2Array:
	var x0 := 12.0
	var y0 := 12.0
	var x1 := size.x - 12.0
	var y1 := size.y - 12.0
	var c := 8.0
	return PackedVector2Array([
		Vector2(x0 + c, y0), Vector2(x1 - c, y0), Vector2(x1, y0 + c), Vector2(x1, y1 - c),
		Vector2(x1 - c, y1), Vector2(x0 + c, y1), Vector2(x0, y1 - c), Vector2(x0, y0 + c)])


func t96_painted() -> String:
	var errs: Array[String] = []
	var theme := ThemeDB.get_project_theme()
	_expect(errs, theme != null, "[테마] 프로젝트 테마가 없음")
	if theme == null:
		return ", ".join(errs)

	# 1. 테마의 스타일이 033 스크립트 그대로이고 그림을 가리킨다
	var panel := theme.get_stylebox("panel", "Panel")
	var container := theme.get_stylebox("panel", "PanelContainer")
	for pair: Array in [["Panel", panel], ["PanelContainer", container]]:
		_expect(errs, _script_path(pair[1]) == PANEL_STYLE, "[1] %s의 panel이 필사본 패널이 아님" % pair[0])
	for state in BUTTON_STATES:
		_expect(errs, _script_path(theme.get_stylebox(state, "Button")) == BUTTON_STYLE, "[1] Button의 %s가 제비꼬리가 아님" % state)
	if panel == null or container == null:
		return ", ".join(errs)
	_expect(errs, _tex_path(container, "paper") == PAPER_PATH, "[1] PanelContainer의 paper가 %s가 아님" % PAPER_PATH)
	_expect(errs, _tex_path(container, "frame") == FRAME_PATH, "[1] PanelContainer의 frame이 %s가 아님" % FRAME_PATH)
	for pair: Array in [["Panel", panel], ["PanelContainer", container]]:
		_expect(errs, _tex_path(pair[1], "frame_small") == FRAME_SMALL_PATH, "[1] %s의 frame_small이 %s가 아님" % [pair[0], FRAME_SMALL_PATH])
		_expect(errs, float(pair[1].get("frame_small_below")) == 160.0, "[1] %s의 frame_small_below가 %s (기대 160)" % [pair[0], pair[1].get("frame_small_below")])
	_expect(errs, panel != container, "[1] Panel과 PanelContainer가 같은 자원임")
	_expect(errs, _tex_path(panel, "paper") == PAPER_PATH, "[1] Panel의 paper가 PanelContainer와 다름")
	var panel_frame := _tex_path(panel, "frame")
	_expect(errs, panel_frame == FRAME_PATH or panel_frame == "", "[1] Panel의 frame이 같은 파일도 빈 칸도 아님: %s" % panel_frame)
	_expect(errs, int(panel.get("wear")) == 0, "[1] Panel의 wear가 %d (기대 0)" % int(panel.get("wear")))
	for state in BUTTON_STATES:
		var want := BUTTON_PATH if BUTTON_PAINTED else ""
		var got := _tex_path(theme.get_stylebox(state, "Button"), "texture")
		_expect(errs, got == want, "[1] Button %s의 texture '%s' (기대 '%s')" % [state, got, want])
	var wall := load(WALL_PATH) as StyleBox
	_expect(errs, wall != null and _tex_path(wall, "paper") == _tex_path(container, "paper"), "[1] 벽의 paper가 패널의 것과 다름")
	_expect(errs, wall != null and int(wall.get("wear")) == 0, "[1] 벽의 wear가 0이 아님")

	# 2. 글자 여백(033의 값)
	for state in BUTTON_STATES:
		var b := theme.get_stylebox(state, "Button")
		var top := 8.0 if state == "pressed" else 6.0
		var bottom := 4.0 if state == "pressed" else 6.0
		_expect(errs, b.content_margin_left == 28.0 and b.content_margin_right == 28.0 and b.content_margin_top == top and b.content_margin_bottom == bottom,
			"[2] Button %s의 글자 여백 %s/%s/%s/%s" % [state, b.content_margin_left, b.content_margin_top, b.content_margin_right, b.content_margin_bottom])
	for pair: Array in [["Panel", panel], ["PanelContainer", container]]:
		var s: StyleBox = pair[1]
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			_expect(errs, s.get_margin(side) == 0.0, "[2] %s의 글자 여백(%d)이 %s (기대 0)" % [pair[0], side, s.get_margin(side)])

	# 3. 그림의 크기
	var paper := container.get("paper") as Texture2D
	if paper != null:
		var wr := paper.get_width() / 1280.0
		var hr := paper.get_height() / 720.0
		_expect(errs, absf(wr - hr) <= 0.01, "[3] 종이의 폭 비 %.3f와 높이 비 %.3f가 다름" % [wr, hr])
	_expect(errs, float(container.get("frame_margin")) * 2.0 <= 56.0, "[3] 테두리의 조각 %s × 2 > 56" % container.get("frame_margin"))
	if BUTTON_PAINTED:
		for state in BUTTON_STATES:
			var b := theme.get_stylebox(state, "Button")
			var tex := b.get("texture") as Texture2D
			if tex == null:
				continue
			var density := float(b.get("density"))
			_expect(errs, absf(tex.get_height() / density - 56.0) <= 1.0, "[3] Button %s의 높이 %.1f (기대 56 ±1)" % [state, tex.get_height() / density])
			_expect(errs, float(b.get("band")) * 2.0 < 42.0, "[3] Button %s의 band × 2 가 42 이상" % state)
			_expect(errs, float(b.get("cap")) * 2.0 < 170.0, "[3] Button %s의 cap × 2 가 170 이상" % state)

	# 4. 버튼 상태의 곱하는 색과 내려앉음
	if BUTTON_PAINTED:
		var tints := {"normal": Color.WHITE, "hover": HOVER_TINT, "pressed": PRESSED_TINT, "disabled": DISABLED_TINT}
		for state in BUTTON_STATES:
			var b := theme.get_stylebox(state, "Button")
			_expect(errs, _near(b.get("tint"), tints[state]), "[4] Button %s의 tint %s (기대 %s)" % [state, b.get("tint"), tints[state]])
	for state in BUTTON_STATES:
		var want_sink := 2.0 if state == "pressed" else 0.0
		var got_sink := float(theme.get_stylebox(state, "Button").get("sink"))
		_expect(errs, absf(got_sink - want_sink) <= 0.01, "[4] Button %s의 sink %s (기대 %s)" % [state, got_sink, want_sink])

	# 5. 빈 칸: new()로 만들면 그림이 비고 wear 0(되돌림의 길)
	var fresh_panel := (load(PANEL_STYLE) as GDScript).new() as StyleBox
	_expect(errs, fresh_panel.get("paper") == null and fresh_panel.get("frame") == null and int(fresh_panel.get("wear")) == 0,
		"[5] 새 패널 스타일의 그림 칸이 비어 있지 않거나 wear가 0이 아님")
	var fresh_button := (load(BUTTON_STYLE) as GDScript).new() as StyleBox
	_expect(errs, fresh_button.get("texture") == null, "[5] 새 버튼 스타일의 texture가 비어 있지 않음")

	# 6. 머리 띠
	var holder := Control.new()
	Ui.add_header_rule(holder)
	var band := holder.get_child(0) as Panel
	_expect(errs, band != null, "[6] add_header_rule의 첫 자식이 Panel이 아님")
	if band != null:
		_expect(errs, band.get_theme_stylebox("panel") == Ui.WALL_STYLE, "[6] 머리 띠가 WALL_STYLE을 쓰지 않음")
		_expect(errs, band.position == Vector2.ZERO and band.size == Vector2(1280, 64), "[6] 머리 띠의 자리 %s 크기 %s (기대 (0,0) (1280,64))" % [band.position, band.size])
		_expect(errs, band.mouse_filter == Control.MOUSE_FILTER_IGNORE, "[6] 머리 띠가 MOUSE_FILTER_IGNORE가 아님")
	holder.free()

	# 7. 9조각의 축
	for state in BUTTON_STATES:
		var b := theme.get_stylebox(state, "Button")
		_expect(errs, int(b.get("axis_y")) == BUTTON_AXIS_Y, "[7] Button %s의 axis_y가 %d (기대 %d)" % [state, int(b.get("axis_y")), BUTTON_AXIS_Y])
		_expect(errs, int(b.get("axis_x")) == BUTTON_AXIS_X, "[7] Button %s의 axis_x가 %d (기대 %d)" % [state, int(b.get("axis_x")), BUTTON_AXIS_X])
	for pair: Array in [["Panel", panel], ["PanelContainer", container]]:
		_expect(errs, int(pair[1].get("frame_axis")) == FRAME_AXIS, "[7] %s의 frame_axis가 %d (기대 %d)" % [pair[0], int(pair[1].get("frame_axis")), FRAME_AXIS])

	# 8. 헤짐의 갈래
	_expect(errs, int(container.get("wear")) == WEAR, "[8] PanelContainer의 wear가 %d (기대 %d)" % [int(container.get("wear")), WEAR])
	_expect(errs, float(container.get("wear_min_side")) == 160.0, "[8] PanelContainer의 wear_min_side가 %s (기대 160)" % container.get("wear_min_side"))

	# 9. 가장자리 셈
	for size in SIZES:
		var big := minf(size.x, size.y) >= WornEdge.MIN_SIDE
		var rect := Rect2(Vector2.ZERO, size).grow(0.01)
		var safe := _safe_octagon(size)
		var level2_clean := 0
		var level2_shapes := {}
		for level in range(0, 4):
			for index in 8:
				var tag := "%s 순서 %d 단계 %d" % [size, index, level]
				var o1 := WornEdge.outline(size, index, level, 0)
				var o2 := WornEdge.outline(size, index, level, 0)
				_expect(errs, o1 == o2 and WornEdge.cuts(size, index, level, 0).size() == WornEdge.cuts(size, index, level, 0).size(),
					"[9a] %s: 같은 인자인데 점이 다름" % tag)
				if level == 0 or not big:
					# (e)
					_expect(errs, o1.size() == 4 and WornEdge.cuts(size, index, level, 0).is_empty(), "[9e] %s: 꼭짓점 넷이 아님(%d)" % [tag, o1.size()])
					continue
				_expect(errs, Geometry2D.clip_polygons(safe, o1).is_empty(), "[9b] %s: 안전 칸이 outline 밖으로 나옴" % tag)
				var inside := true
				for p in o1:
					if not rect.has_point(p):
						inside = false
				_expect(errs, inside, "[9c] %s: 점이 사각형 밖" % tag)
				_expect(errs, not Geometry2D.triangulate_polygon(o1).is_empty(), "[9d] %s: 삼각형 나누기가 빔" % tag)
				var cuts := WornEdge.cuts(size, index, level, 0)
				_expect(errs, cuts.size() <= level, "[9g] %s: 자름 %d개 > 상한 %d" % [tag, cuts.size(), level])
				var kinds := {}
				for cut: Dictionary in cuts:
					kinds[cut["kind"]] = int(kinds.get(cut["kind"], 0)) + 1
				if level == 1:
					for k: String in kinds:
						_expect(errs, k == "fray" or k == "worn", "[9g] %s: 단계 1에 %s" % [tag, k])
				if level == 2:
					_expect(errs, int(kinds.get("tear", 0)) <= 1 and int(kinds.get("drop", 0)) <= 1, "[9g] %s: 찢김·떨어진 모서리가 둘 이상" % tag)
					if cuts.is_empty():
						level2_clean += 1
					level2_shapes[hash(o1)] = true
		# (f) 짧은 변이 문턱 아래인 판은 깎지 않으므로 큰 판에만
		if big:
			_expect(errs, level2_clean >= 1, "[9f] %s: 단계 2에서 순서 0~7이 모두 헤짐(깨끗한 판 0)" % size)
			_expect(errs, level2_shapes.size() >= 2, "[9f] %s: 단계 2에서 순서 0~7의 outline이 모두 같음" % size)

	return "OK" if errs.is_empty() else ", ".join(errs)
