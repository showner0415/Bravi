extends RefCounted
## T72·T73: 결투 무대(계획 031). 무대 데이터와 의뢰의 배정, 결투 씬의 무대, HUD의 임시 띠.

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const STAGE_DIR := "res://data/stages/"
const DEFAULT_STAGE := "alley.tres"
const DAY1_PATH := "res://data/days/day_01.tres"
## 결정 296의 자른 크기.
const STAGE_SIZES := {"alley.tres": Vector2i(1536, 864), "court.tres": Vector2i(1524, 857), "piazza.tres": Vector2i(1524, 857)}
## 결정 295의 표: 의뢰 파일 -> 무대 파일.
const ASSIGNED := {
	"first_blood.tres": "piazza.tres", "feather_cut.tres": "alley.tres", "throw_match.tres": "court.tres",
	"first_blood_usurer.tres": "piazza.tres", "throw_bet.tres": "alley.tres",
	"first_blood_poor.tres": "alley.tres", "legs_only.tres": "court.tres",
}
## 결정 298의 띠: 이름 -> [앵커, 앵커 기준 사각형, 1280×720의 화면 사각형].
const BANDS := {
	"BandTopLeft": [Vector2(0, 0), Rect2(12, 6, 334, 148), Rect2(12, 6, 334, 148)],
	"BandTop": [Vector2(0.5, 0), Rect2(-306, 6, 672, 55), Rect2(334, 6, 672, 55)],
	"BandBottomLeft": [Vector2(0, 1), Rect2(12, -156, 334, 52), Rect2(12, 564, 334, 52)],
}
## 바이블 6절의 조용한 구역(x 433~847 · y 62~683).
const QUIET := Rect2(433, 62, 414, 621)

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T72", "name": "무대: 데이터 셋, 의뢰 일곱의 배정, 1일차가 서로 다른 곳, 결투 씬의 무대", "fn": t72_stages},
		{"id": "T73", "name": "HUD의 임시 띠 셋과 라벨 테두리(조용한 구역 밖)", "fn": t73_hud_bands},
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


func t73_hud_bands() -> String:
	var errs: Array[String] = []
	var duel := _spawn(null)
	var root := duel.get_node("HUD/Root")
	for band_name: String in BANDS:
		var band := root.get_node_or_null(band_name) as ColorRect
		var want: Array = BANDS[band_name]
		if band == null:
			errs.append("%s 없음" % band_name)
			continue
		var anchor: Vector2 = want[0]
		var local: Rect2 = want[1]
		var at := Vector2(band.anchor_left, band.anchor_top)
		var off := Rect2(band.offset_left, band.offset_top, band.offset_right - band.offset_left, band.offset_bottom - band.offset_top)
		if not at.is_equal_approx(anchor) or not off.is_equal_approx(local):
			errs.append("%s: 앵커 %s 사각형 %s" % [band_name, at, off])
		var screen := Rect2(anchor * Vector2(1280, 720) + local.position, local.size)
		if not screen.is_equal_approx(want[2]) or screen.intersects(QUIET):
			errs.append("%s: 화면 사각형 %s가 결정 298과 다르거나 조용한 구역에 걸침" % [band_name, screen])
	for child in root.get_children():
		if child is Label and (child as Label).get_theme_constant("outline_size") != 4:
			errs.append("라벨 %s의 테두리 %d" % [child.name, (child as Label).get_theme_constant("outline_size")])
	duel.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
