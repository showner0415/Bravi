extends Node
## 패턴의 고리 찍기: 하루의 상대의 패턴마다, 길(바탕·변주)마다, 간격 셋에서 예비 동작의 한 순간을 놓는다.
## 게임 창에서 그 순간을 기다려 잡던 것을 대신한다. 실행: tests/run_pattern_shots.ps1 (-Shots <폴더>면 창을 열어 PNG도 남긴다).
## 장마다 "shot,<이름>,<놓은 것>"을 내고, 고리가 HUD의 판과 겹치면 "overlap,<이름>,<번호>,<노드>,<겹친 넓이>"를 낸다.
## --commission=<의뢰 경로>를 주면 그 의뢰의 HUD와 모자로 찍는다(없으면 연습의 자유 결투).
## 겹침은 알릴 뿐 판정하지 않는다. 판은 실제 코어를 돌려 놓는다(예비 동작의 이벤트가 뷰에 그대로 간다).

const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Select := preload("res://scripts/commission/commission_select.gd")

const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DISTANCE_TAGS := ["far", "engage", "close"]
const DELTA := 1.0 / 60.0
## 예비 동작의 이만큼 지난 순간을 찍는다.
const PROGRESS := 0.35
const SETTLE_MSEC := 250

var _shots_dir := ""
var _commission_path := ""
var _plan: Array = []
var _i := -1
var _node: Node
var _since := 0
var _frames := 0
var _shot_count := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
		elif arg.begins_with("--commission="):
			_commission_path = arg.trim_prefix("--commission=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	var trials := Select.load_trials()
	for t in trials.size():
		var opponent := trials[t]
		var p := 0
		for base in opponent.attacks:
			if base.chain.is_empty() and not base.dive:
				continue
			var lines: Array[AttackData] = [base]
			for variant: AttackData in base.variants:
				lines.append(variant)
			for l in lines.size():
				for distance in 3:
					_plan.append({
						"name": "%s-p%d-l%d-%s" % [opponent.resource_path.get_file().get_basename(), p, l, DISTANCE_TAGS[distance]],
						"opponent": opponent, "line": lines[l], "distance": distance,
					})
			p += 1
	_next()


func _next() -> void:
	if _node != null:
		_node.free()
		_node = null
	_i += 1
	if _i >= _plan.size():
		print("PATTERN SHOTS OK %d" % _shot_count)
		set_process(false)
		get_tree().quit(0)
		return
	var item: Dictionary = _plan[_i]
	var note := _pose(item)
	print("shot,%s,%s" % [item["name"], note])
	_since = Time.get_ticks_msec()
	_frames = 0


func _process(_delta: float) -> void:
	if _node == null:
		return
	_frames += 1
	if _frames >= 3 and Time.get_ticks_msec() - _since >= SETTLE_MSEC:
		var shot_name: String = _plan[_i]["name"]
		_report_overlaps(shot_name)
		if _shots_dir != "":
			get_viewport().get_texture().get_image().save_png(_shots_dir.path_join(shot_name + ".png"))
		_shot_count += 1
		_next()


## 그 길만 내는 상대로 판을 열고, 간격을 놓고, 예비 동작이 PROGRESS만큼 지날 때까지 코어를 돌린다.
func _pose(item: Dictionary) -> String:
	var solo := (item["line"] as AttackData).duplicate() as AttackData
	var no_variants: Array[Resource] = []
	solo.variants = no_variants
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	_node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	var drilled := (item["opponent"] as OpponentData).drill(solo)
	if _commission_path != "":
		# 의뢰의 HUD와 모자가 뜬 채 찍는다. 읽어 온 의뢰는 고치지 않고 사본에 상대만 바꾼다(결정 433).
		var copy := (load(_commission_path) as Commission).duplicate() as Commission
		copy.opponent = drilled
		_node.set("commission", copy)
	else:
		_node.set("practice_opponent", drilled)
	_node.set("test_weapon", weapon)
	_node.set("mouse_aim_enabled", false)
	_node.set("rng_seed", 1)
	add_child(_node)
	_node.set_process(false)
	_node.set_physics_process(false)
	var core: DuelCore = _node.get("core")
	var distance: int = item["distance"]
	core.distance = distance
	core.brain.state_end = core.time
	var guard := 0
	while guard < 1200 and core.brain.state != DT.OpponentState.TELL:
		core.tick(DELTA)
		guard += 1
	if core.brain.state != DT.OpponentState.TELL:
		return "예비 동작이 오지 않음(간격 %s)" % DT.DISTANCE_NAMES[distance]
	# 교전의 장에서는 첫 칸을 막는다: 맞게 막은 칸의 테두리와 내 칼이 고리를 가리는지 본다.
	var height := core.brain.current_height()
	if distance == DT.Distance.ENGAGE:
		core.set_aim(core.brain.current_attack.direction, height if height >= 0 else DT.Height.MID)
		core.set_guard(true)
	var until := core.brain.state_start + PROGRESS * (core.brain.state_end - core.brain.state_start)
	while core.time < until and core.brain.state == DT.OpponentState.TELL:
		core.tick(DELTA)
	_node.set("_display_time", core.time)
	_node.call("_update_views", 0.0)
	return "%s · %s · 높이 %s · %s%s" % [
		(item["opponent"] as OpponentData).display_name, solo.attack_name, str(core.brain.strike_heights),
		DT.DISTANCE_NAMES[core.distance], " · 첫 칸을 막음" if distance == DT.Distance.ENGAGE else ""]


## 번호 고리의 네모가 HUD의 판의 네모와 겹치는 넓이.
func _report_overlaps(shot: String) -> void:
	var core: DuelCore = _node.get("core")
	var ring := _node.get_node("OpponentView/Ring") as Node2D
	var xf := ring.get_global_transform()
	var radius := OpponentView.MARK_RADIUS * xf.get_scale().x
	var boxes: Array = []
	_collect(_node.get_node("HUD"), boxes)
	var index := 0
	for mark in OpponentView.pattern_marks(core.brain, core.time):
		if not mark.has("pos"):
			continue
		index += 1
		var center: Vector2 = xf * (mark["pos"] as Vector2)
		var box := Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
		if not get_viewport().get_visible_rect().encloses(box):
			print("overlap,%s,%d,화면 밖,%d" % [shot, index, roundi(box.get_area())])
		for entry: Array in boxes:
			var cut := box.intersection(entry[1])
			if cut.get_area() >= 1.0:
				print("overlap,%s,%d,%s,%d" % [shot, index, entry[0], roundi(cut.get_area())])


func _collect(node: Node, boxes: Array) -> void:
	for child in node.get_children():
		if child is Control and not (child as Control).is_visible_in_tree():
			continue
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		if child is Panel or child is PanelContainer:
			var rect := (child as Control).get_global_rect()
			# 화면을 덮는 바탕은 뺀다.
			if rect.size.x < 900.0 and rect.get_area() > 0.0:
				boxes.append([String(child.name), rect])
		_collect(child, boxes)
