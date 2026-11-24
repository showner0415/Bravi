extends RefCounted
## T72·T73: 결투 무대(계획 031). 무대 데이터와 의뢰의 배정, 결투 씬의 무대. T73은 HUD의 필사본 패널(계획 033).

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const STAGE_DIR := "res://data/stages/"
const DEFAULT_STAGE := "alley.tres"
const DAY1_PATH := "res://data/days/day_01.tres"
## 결정 338: 셋 모두 1920×1080(1920 창에서 1:1).
const STAGE_SIZES := {"alley.tres": Vector2i(1920, 1080), "court.tres": Vector2i(1920, 1080), "piazza.tres": Vector2i(1920, 1080)}
## 결정 295의 표: 의뢰 파일 -> 무대 파일.
const ASSIGNED := {
	"first_blood.tres": "piazza.tres", "feather_cut.tres": "alley.tres", "throw_match.tres": "court.tres",
	"first_blood_usurer.tres": "piazza.tres", "throw_bet.tres": "alley.tres",
	"first_blood_poor.tres": "alley.tres", "legs_only.tres": "court.tres",
}
## 결정 316의 패널: 이름 -> [앵커, 앵커 기준 사각형, 1280×720의 화면 사각형].
const PANELS := {
	"PanelTopLeft": [Vector2(0, 0), Rect2(10, 6, 330, 150), Rect2(10, 6, 330, 150)],
	"PanelTop": [Vector2(0.5, 0), Rect2(-294, 4, 548, 56), Rect2(346, 4, 548, 56)],
	"PanelTopRight": [Vector2(1, 0), Rect2(-380, 6, 372, 58), Rect2(900, 6, 372, 58)],
	"PanelBottomLeft": [Vector2(0, 1), Rect2(10, -164, 340, 58), Rect2(10, 556, 340, 58)],
	"PanelBottomRight": [Vector2(1, 1), Rect2(-500, -170, 492, 64), Rect2(780, 550, 492, 64)],
}
## 덧말이 붙어 자란 조준 패널과 엉킴 경고 글자의 화면 사각형(결정 316·318).
const GROWN_AIM := Rect2(780, 526, 492, 88)
const BIND_WARNING_SCREEN := Rect2(510, 550, 260, 40)
const PANEL_STYLE := "res://scripts/ui/manuscript_panel_style.gd"
## 바이블 6절의 조용한 구역(x 433~847 · y 62~683).
const QUIET := Rect2(433, 62, 414, 621)

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T72", "name": "무대: 데이터 셋, 의뢰 일곱의 배정, 1일차가 서로 다른 곳, 결투 씬의 무대", "fn": t72_stages},
		{"id": "T73", "name": "HUD의 필사본 패널 다섯·층·마우스 무시·조준 패널의 높이(결정 316)", "fn": t73_hud_panels},
	]


func cleanup() -> void:
	_tree = null


func _spawn(commission: Commission) -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	if commission != null:
		duel.set("commission", commission)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	return duel


func t72_stages() -> String:
	var errs: Array[String] = []
	for file: String in STAGE_SIZES:
		var stage := load(STAGE_DIR + file) as StageData
		if stage == null or stage.texture == null or stage.stage_name == "":
			errs.append("%s: StageData·그림·이름 없음" % file)
		elif Vector2i(stage.texture.get_size()) != STAGE_SIZES[file]:
			errs.append("%s: 그림 크기 %s (기대 %s)" % [file, Vector2i(stage.texture.get_size()), STAGE_SIZES[file]])
	var all: Array[Commission] = CommissionLibrary.load_all("res://data/commissions")
	all.append_array(CommissionLibrary.load_all("res://data/commissions/variants"))
	if all.size() != ASSIGNED.size():
		errs.append("의뢰 %d개 (기대 %d)" % [all.size(), ASSIGNED.size()])
	for c in all:
		var file := c.resource_path.get_file()
		var got := c.stage.resource_path.get_file() if c.stage != null else "(없음)"
		if ASSIGNED.get(file, "") != got:
			errs.append("%s의 무대 %s (기대 %s)" % [file, got, ASSIGNED.get(file, "?")])
	var seen := {}
	for c: Commission in (load(DAY1_PATH) as DayData).commissions:
		seen[c.stage] = true
	if seen.size() != 3:
		errs.append("1일차 세 의뢰의 무대가 서로 다르지 않음(%d곳)" % seen.size())
	for path: String in ["res://data/commissions/feather_cut.tres", "res://data/commissions/throw_match.tres", ""]:
		var duel := _spawn(load(path) as Commission if path != "" else null)
		# 의뢰가 없어도 세션의 의뢰를 받을 수 있어(_ready), 기대는 씬이 실제로 쓴 의뢰에서 셈한다.
		var used: Commission = duel.get("commission")
		var want := (used.stage if used != null and used.stage != null else load(STAGE_DIR + DEFAULT_STAGE) as StageData).texture
		var tex := (duel.get_node("Background/Stage") as TextureRect).texture
		if tex == null or tex.resource_path != want.resource_path:
			errs.append("%s: 무대 그림 %s (기대 %s)" % [path if path != "" else "의뢰 없음", tex.resource_path if tex != null else "없음", want.resource_path])
		if not duel.has_node("Background/Color"):
			errs.append("Background/Color가 없음")
		duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


func t73_hud_panels() -> String:
	var errs: Array[String] = []
	var duel := _spawn(null)
	var hud := duel.get_node("HUD")
	# 판은 멀리에서 시작해 조준 패널이 이미 한 줄 자라 있다. 패널의 자리는 교전에서 견준다.
	var start_core: DuelCore = duel.get("core")
	start_core.distance = DuelTypes.Distance.ENGAGE
	hud.call("refresh", start_core)
	var back := hud.get_node_or_null("Back") as CanvasLayer
	if back == null or back.layer != -1:
		errs.append("HUD/Back 층이 없거나 layer가 -1이 아님")
	if (duel.get_node("Background") as CanvasLayer).layer != -2:
		errs.append("Background의 layer %d (기대 -2)" % (duel.get_node("Background") as CanvasLayer).layer)
	var root := hud.get_node_or_null("Back/Root")
	var screens: Array[Rect2] = []
	for panel_name: String in PANELS:
		var panel: Panel = root.get_node_or_null(panel_name) as Panel if root != null else null
		var want: Array = PANELS[panel_name]
		if panel == null:
			errs.append("%s가 HUD/Back/Root 아래에 없거나 Panel이 아님" % panel_name)
			continue
		var style := panel.get_theme_stylebox("panel")
		if style == null or style.get_script() == null or (style.get_script() as Script).resource_path != PANEL_STYLE:
			errs.append("%s의 패널 꼴이 필사본이 아님" % panel_name)
		var anchor: Vector2 = want[0]
		var local: Rect2 = want[1]
		var at := Vector2(panel.anchor_left, panel.anchor_top)
		var off := Rect2(panel.offset_left, panel.offset_top, panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top)
		if not at.is_equal_approx(anchor) or not off.is_equal_approx(local):
			errs.append("%s: 앵커 %s 사각형 %s" % [panel_name, at, off])
		var screen := Rect2(anchor * Vector2(1280, 720) + local.position, local.size)
		if not screen.is_equal_approx(want[2]):
			errs.append("%s: 화면 사각형 %s가 결정 316과 다름" % [panel_name, screen])
		if screen.intersects(QUIET) != (panel_name == "PanelBottomRight"):
			errs.append("%s: 조용한 구역과의 겹침이 결정 316과 다름" % panel_name)
		screens.append(screen)
	# 조준 패널은 덧말이 있으면 위로 24 자란다. 자란 꼴도 다른 패널·엉킴 경고와 겹치지 않아야 한다.
	screens.append(GROWN_AIM)
	screens.append(BIND_WARNING_SCREEN)
	var aim_rect: Rect2 = PANELS["PanelBottomRight"][2]
	for i in screens.size():
		for j in range(i + 1, screens.size()):
			# 자라기 전과 뒤의 조준 패널끼리는 겹치는 것이 맞다.
			if screens[i].is_equal_approx(aim_rect) and screens[j].is_equal_approx(GROWN_AIM):
				continue
			if screens[i].intersects(screens[j]):
				errs.append("사각형 %s와 %s가 겹침" % [screens[i], screens[j]])
	var warning := hud.find_child("BindWarning", true, false) as Label
	if warning == null or not Rect2(warning.anchor_left * 1280 + warning.offset_left, warning.anchor_top * 720 + warning.offset_top,
			warning.offset_right - warning.offset_left, warning.offset_bottom - warning.offset_top).is_equal_approx(BIND_WARNING_SCREEN):
		errs.append("엉킴 경고의 자리가 결정 318과 다름")
	if hud.find_child("HelpBar", true, false) != null or hud.get("_help_label") != null:
		errs.append("결투 HUD에 도움말 띠나 글이 남아 있음(결정 323)")
	# 패널 안의 글은 테두리 없음, 무대 위 글(기록·디버그·엉킴 경고)은 테두리 있음(결정 319).
	if root != null:
		for label: Label in root.find_children("*", "Label", true, false):
			if label.get_theme_constant("outline_size") != 0:
				errs.append("패널 안 라벨 %s의 테두리 %d" % [label.name, label.get_theme_constant("outline_size")])
	for field: String in ["_log_label", "_debug_label", "_bind_warning"]:
		var label := hud.get(field) as Label
		if label == null or label.get_theme_constant("outline_size") <= 0 or label.get_parent().get_parent() != hud:
			errs.append("무대 위 글 %s가 앞 층에 없거나 테두리가 없음" % field)
	# 조준 패널의 높이: 멀리에서는 덧말 한 줄만큼 높다.
	var core: DuelCore = duel.get("core")
	var aim_panel: Panel = root.get_node_or_null("PanelBottomRight") as Panel if root != null else null
	if core != null and aim_panel != null:
		for row: Array in [[DuelTypes.Distance.FAR, 526.0], [DuelTypes.Distance.ENGAGE, 550.0]]:
			core.distance = row[0]
			hud.call("refresh", core)
			if not is_equal_approx(720.0 + aim_panel.offset_top, row[1]):
				errs.append("간격 %d에서 조준 패널의 윗변 %.0f (기대 %.0f)" % [row[0], 720.0 + aim_panel.offset_top, row[1]])
	# 결투 입력은 _unhandled_input으로 받으므로 HUD와 결과 패널의 Control은 모두 마우스를 무시해야 한다(결정 314).
	for owner_path: String in ["HUD", "ResultPanel"]:
		for control: Control in duel.get_node(owner_path).find_children("*", "Control", true, false):
			if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				errs.append("%s의 %s가 마우스를 받음" % [owner_path, control.name])
	duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
