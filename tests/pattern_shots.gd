extends Node
## 패턴의 고리 찍기: 하루의 상대의 패턴마다, 길(바탕·변주)마다, 간격 셋에서 예비 동작의 한 순간을 놓는다.
## 게임 창에서 그 순간을 기다려 잡던 것을 대신한다. 실행: tests/run_pattern_shots.ps1 (-Shots <폴더>면 창을 열어 PNG도 남긴다).
## 장마다 "shot,<이름>,<놓은 것>"을 내고, 고리가 HUD의 판과 겹치면 "overlap,<이름>,<번호>,<노드>,<겹친 넓이>"를 낸다.
## --commission=<의뢰 경로>를 주면 그 의뢰의 HUD와 모자로 찍는다(없으면 연습의 자유 결투).
## --tier=<N|last>는 화면의 "N단"(1부터)의 사본으로 찍고 장 이름에 "-tN"을 끼운다(계획 040 결정 592). 없으면 이름이 옛 그대로다.
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
var _tier := ""
var _plan: Array = []
var _i := -1
var _node: Node
var _since := 0
var _frames := 0
var _shot_count := 0


func _ready() -> void:
	# 결투가 InputMap을 읽으므로 플레이어의 바꾼 키가 장에 비치지 않게 처음 값으로 돌린다(계획 S03 결정 523).
	var run_settings := get_node_or_null(^"/root/Settings")
	if run_settings != null and run_settings.has_method("detach_for_run"):
		run_settings.call("detach_for_run")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
		elif arg.begins_with("--commission="):
			_commission_path = arg.trim_prefix("--commission=")
		elif arg.begins_with("--tier="):
			_tier = arg.trim_prefix("--tier=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	var trials := Select.load_trials()
	var raise_plan: Array = []
	for t in trials.size():
		var source := trials[t]
		var opponent := source
		var tag := source.resource_path.get_file().get_basename()
		if _tier != "":
			# 단의 사본은 resource_path가 비어 있어 이름은 사본을 만들기 전의 원본에서 잡는다.
			var count := source.tier_count()
			var number := count if _tier == "last" else clampi(int(_tier), 1, count)
			opponent = source.at_tier(number - 1)
			tag += "-t%d" % number
		# 올려 막기 공격은 attacks가 아니라 버릇의 반응에 있다(계획 041b 결정 629).
		var raise_attack: AttackData = null
		for habit in opponent.habits:
			if habit.response != null and habit.response.needs_raised_guard:
				raise_attack = habit.response
				break
		raise_plan.append({
			"name": "%s-raise-engage" % tag, "opponent": opponent, "line": raise_attack,
			"distance": DT.Distance.ENGAGE,
		})
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
						"name": "%s-p%d-l%d-%s" % [tag, p, l, DISTANCE_TAGS[distance]],
						"opponent": opponent, "line": lines[l], "distance": distance,
					})
			p += 1
	for atk in Select.load_spare_attacks():
		var spare_lines: Array[AttackData] = [atk]
		for variant: AttackData in atk.variants:
			spare_lines.append(variant)
		for l in spare_lines.size():
			_plan.append({
				"name": "spare-%s-l%d-engage" % [atk.resource_path.get_file().get_basename(), l],
				"opponent": trials[0], "line": spare_lines[l], "distance": DT.Distance.ENGAGE,
			})
	_plan.append_array(raise_plan)
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
	if item["line"] == null:
		print("shot,%s,올려 막기 공격 없음" % item["name"])
		_next()
		return
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
		_report_view(shot_name)
		_report_overlaps(shot_name)
		_report_labels(shot_name)
		_report_hints(shot_name)
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
	# 뷰는 start_duel에서 멀리로 스냅해 두어, delta 0의 갱신은 간격을 따라가지 않는다. 다시 setup해 스냅시킨다(결정 615).
	var has_hat := _node.get("commission") != null and (_node.get("commission") as Commission).opponent_wears_hat
	(_node.get_node("OpponentView") as OpponentView).setup(core.opponent_data, core.weapon, has_hat)
	(_node.get_node("PlayerSwordView") as PlayerSwordView).setup()
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
	# 돌아오기 대기의 글은 숨긴 채로도 자리를 잰다(계획 S02 결정 509).
	var hold := _node.get_node("HUD").find_child("ResumeHold", true, false) as Control
	if hold != null:
		boxes.append(["ResumeHold", hold.get_global_rect()])
	var marks := OpponentView.pattern_marks(core.brain, core.time)
	# 고리 노드의 원점이 지금 타격의 자리라 번호 고리는 pos - origin에 그려진다(opponent_view.gd 293·592행).
	var origin := Vector2.ZERO
	for mark in marks:
		if mark["role"] == &"now":
			origin = mark["pos"]
	var index := 0
	for mark in marks:
		if not mark.has("pos"):
			continue
		index += 1
		var center: Vector2 = xf * ((mark["pos"] as Vector2) - origin)
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


## 뷰의 간격 자리: 멈춘 뷰로 찍지 않았는지 보는 줄(결정 615). 판정이 아니라 적는 수다.
func _report_view(shot: String) -> void:
	var view := _node.get_node("OpponentView") as Node2D
	print("view,%s,%.1f,%.3f" % [shot, view.global_position.y, view.global_scale.x])


## 번호 고리와 상태 글자의 상자가 겹친 넓이와 높이(결정 616). 판정이 아니라 적는 수라 접두를 overlap과 달리 둔다.
## 번호 고리가 없는 단발은 Ring의 원점을 번호 0으로 잰다.
func _report_labels(shot: String) -> void:
	var core: DuelCore = _node.get("core")
	var label := _node.get_node("OpponentView/StateLabel") as Label
	if label.text == "":
		return
	var ring := _node.get_node("OpponentView/Ring") as Node2D
	var xf := ring.get_global_transform()
	var radius := OpponentView.MARK_RADIUS * xf.get_scale().x
	var label_box: Rect2 = label.get_global_transform() * Rect2(Vector2.ZERO, label.size)
	var lines := label.text.count("\n") + 1
	var marks := OpponentView.pattern_marks(core.brain, core.time)
	var origin := Vector2.ZERO
	for mark in marks:
		if mark["role"] == &"now":
			origin = mark["pos"]
	var centers: Array[Vector2] = []
	for mark in marks:
		if mark.has("pos"):
			centers.append(xf * ((mark["pos"] as Vector2) - origin))
	if centers.is_empty():
		centers.append(xf * Vector2.ZERO)
	for n in centers.size():
		var box := Rect2(centers[n] - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
		var cut := box.intersection(label_box)
		print("label,%s,%d,%d,%d,%d" % [shot, n + 1 if not marks.is_empty() else 0, roundi(cut.get_area()), lines, roundi(cut.size.y)])


## 귀띔(StateHint)의 실제 노드 상자와 번호 고리·지금 고리의 패리 띠가 겹친 넓이와 높이(계획 041b 결정 627). 0이 아니면 러너가 FAIL을 낸다.
## 귀띔이 숨어 있으면 내지 않는다. 지금 고리의 상자는 휩쓸기가 아니면 패리 띠의 반지름으로 잰다.
func _report_hints(shot: String) -> void:
	var hint := _node.get_node("OpponentView/StateHint") as Label
	if not hint.visible or hint.text == "":
		return
	var core: DuelCore = _node.get("core")
	var ring := _node.get_node("OpponentView/Ring") as Node2D
	var xf := ring.get_global_transform()
	var scale := xf.get_scale().x
	var hint_box: Rect2 = hint.get_global_transform() * Rect2(Vector2.ZERO, hint.size)
	var band := OpponentView.RING_SPEED * core.weapon.parry_window * scale
	var marks := OpponentView.pattern_marks(core.brain, core.time)
	var origin := Vector2.ZERO
	for mark in marks:
		if mark["role"] == &"now":
			origin = mark["pos"]
	var boxes: Array = []
	for mark in marks:
		if not mark.has("pos"):
			continue
		var radius := OpponentView.MARK_RADIUS * scale
		if mark["role"] == &"now" and not core.brain.is_sweep():
			radius = maxf(radius, band)
		boxes.append([xf * ((mark["pos"] as Vector2) - origin), radius])
	if boxes.is_empty():
		boxes.append([xf * Vector2.ZERO, maxf(OpponentView.MARK_RADIUS * scale, band)])
	for n in boxes.size():
		var center: Vector2 = boxes[n][0]
		var r: float = boxes[n][1]
		var cut := Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0).intersection(hint_box)
		print("hint,%s,%d,%d,%d" % [shot, n + 1 if not marks.is_empty() else 0, roundi(cut.get_area()), roundi(cut.size.y)])
