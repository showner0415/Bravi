extends RefCounted
## T124: 상태 글자의 귀띔(계획 041b, 결정 624~629). 첫 줄은 늘 한 줄이고 귀띔은 StateHint가 첫 줄의 오른쪽 곁에 선다.
## 길 목록·고리의 셈은 fourth_opponent_tests.gd의 도우미를 빌려 쓴다(그 파일은 고치지 않는다. 빌리는 도우미는 _tree를 쓰지 않는다).
## 올려 막기 공격은 길 목록에 없고 버릇의 반응(habits[].response)에만 있다(기술 검토 T1).

const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
const SCREEN_W := 1280.0
const HINT_MAX_RIGHT := 1272.0
## 효과 글(DuelHud의 EffectLabel): 오른쪽 맞춤 18, 오른쪽 끝 1260, 위 끝 68.
const EFFECT_RIGHT := 1260.0
const EFFECT_TOP := 68.0
const EFFECT_SIZE := 18
## 번호 바탕: 고리 위 42, 반지름 15(opponent_view.gd의 _draw_marks).
const BACKDROP_UP := 42.0
const BACKDROP_RADIUS := 15.0
const HINT_SWEEP := "쥐고 끌어라"
const HINT_DIVE_FAR := "멀리 물러서거나 막아라"
const HINT_DIVE_CLOSE := "막아라"
const HINT_READY := "받아낼 준비"
const HINT_HELD := "막기를 뗐다 다시 올려라"
const ALL_HINTS: Array[String] = [HINT_SWEEP, HINT_DIVE_FAR, HINT_DIVE_CLOSE, HINT_READY, HINT_HELD]
const SLOW_SUFFIX := " (둔함)"

var _tree: SceneTree
var _f: Fourth = Fourth.new()

var _font: Font
var _font_size := 28
var _label_w := 440.0
var _line_h := 0.0
var _body_font: Font
var _effects: Array[String] = []
var _weapon: WeaponData

var _hint_jobs := {}
var _text_checks := 0
var _raised_jobs := 0
var _raised_branch := {&"none": 0, &"ready": 0, &"held": 0}
var _backdrop_hits := 0
var _pull_max := {}
var _five := {}


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T124", "name": "상태 글자의 귀띔: 첫 줄은 한 줄, 귀띔의 글 다섯, 첫 줄 오른쪽 곁의 자리, 고리와 겹치지 않는다", "fn": t124_state_hint},
	]


func cleanup() -> void:
	_tree = null


func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


# ================================================================ 길 목록

## 길(뿌리와 변주)마다 하나: 네 상대의 모든 단, 버릇의 반응(올려 막기 공격이 여기 있다), 주인 없는 공격.
func _build_jobs() -> Array[Dictionary]:
	var jobs: Array[Dictionary] = []
	var seen := {}
	var trials := SelectScript.load_trials()
	for opp in trials:
		var sources: Array[Dictionary] = []
		for attacks: Array in _f._tier_lists(opp):
			for atk: AttackData in attacks:
				sources.append({"atk": atk, "label": opp.display_name})
		for habit in opp.habits:
			if habit != null and habit.response != null:
				sources.append({"atk": habit.response, "label": opp.display_name + " 버릇"})
		for source in sources:
			_add_routes(jobs, seen, opp, source["atk"], source["label"])
	if not trials.is_empty():
		for spare in SelectScript.load_spare_attacks():
			_add_routes(jobs, seen, trials[0], spare, "주인 없는 " + spare.attack_name)
	return jobs


func _add_routes(jobs: Array[Dictionary], seen: Dictionary, opp: OpponentData, atk: AttackData, label: String) -> void:
	var routes: Array[AttackData] = _f._routes(atk)
	for route in routes:
		if seen.has(route.get_instance_id()):
			continue
		seen[route.get_instance_id()] = true
		jobs.append({"opp": opp, "route": route, "label": "%s %s" % [label, route.attack_name]})


# ================================================================ 본 시험

func t124_state_hint() -> String:
	var errs: Array[String] = []
	_hint_jobs = {}
	_text_checks = 0
	_raised_jobs = 0
	_raised_branch = {&"none": 0, &"ready": 0, &"held": 0}
	_backdrop_hits = 0
	_pull_max = {DT.Distance.ENGAGE: 0.0, DT.Distance.CLOSE: 0.0, DT.Distance.FAR: 0.0}
	_five = {}
	_effects = []
	var trials := SelectScript.load_trials()
	var jobs := _build_jobs()
	if trials.is_empty() or jobs.is_empty():
		return "연습의 상대나 길이 없다"
	_weapon = load(WEAPON_PATH) as WeaponData

	# ② 노드: 여기서 글꼴과 상자 폭을 얻는다.
	_scene_checks(errs, jobs)
	if _font == null:
		return _ok(errs)
	var body_theme := ThemeDB.get_project_theme()
	_body_font = body_theme.default_font if body_theme != null and body_theme.default_font != null else ThemeDB.fallback_font
	_line_h = _font.get_height(_font_size)

	# ①③④⑤ 길마다 한 번씩 돈다.
	for job in jobs:
		_run_job(errs, job)

	# ① 올려 막기 공격은 상대마다 하나 이상, 세 갈래를 공격마다 지났다.
	if _raised_jobs < trials.size():
		errs.append("[①] 본 올려 막기 공격 %d개 (연습의 상대 %d명보다 적다)" % [_raised_jobs, trials.size()])
	for branch: StringName in _raised_branch:
		if int(_raised_branch[branch]) != _raised_jobs:
			errs.append("[①] 올려 막기의 갈래 '%s'를 지난 공격 %d개 (올려 막기 공격 %d개)" % [branch, int(_raised_branch[branch]), _raised_jobs])
	_print_info(jobs.size(), trials.size())
	return _ok(errs)


func _print_info(job_count: int, trial_count: int) -> void:
	print("  INFO T124 길 %d개 · 귀띔이 붙는 길 %d개 · 본 올려 막기 공격 %d개(상대 %d명) · 갈래 빈 글 %d · 받아낼 준비 %d · 뗐다 다시 %d · 한 줄 높이 %.1f · 번호 바탕이 귀띔에 닿은 수 %d" % [
		job_count, _hint_jobs.size(), _raised_jobs, trial_count, int(_raised_branch[&"none"]), int(_raised_branch[&"ready"]),
		int(_raised_branch[&"held"]), _line_h, _backdrop_hits])
	print("  INFO T124 ④ 당김 1의 겹친 높이 최대(판정 아님, 결정 628): 교전 %.1f · 밀착 %.1f · 멀리로 물러선 뒤 %.1f (한 줄 높이 %.1f)" % [
		float(_pull_max[DT.Distance.ENGAGE]), float(_pull_max[DT.Distance.CLOSE]), float(_pull_max[DT.Distance.FAR]), _line_h])
	for key: String in ["arm_plain", "arm_slow", "leg_plain", "leg_slow"]:
		var entry: Array = _five.get(key, [-INF, 0.0, "", 0])
		var kind := ("팔 줄" if key.begins_with("arm") else "다리 줄") + (" · '(둔함)' 붙음" if key.ends_with("slow") else " · '(둔함)' 없음")
		if int(entry[3]) == 0:
			print("  INFO T124 ⑤ %s: 가로로 겹치는 길 없음" % kind)
		else:
			print("  INFO T124 ⑤ %s: 가로로 겹치는 길 %d개, 가장 깊은 가로 겹침 %.0f px (세로 겹침 %.0f px) — %s" % [
				kind, int(entry[3]), float(entry[0]), float(entry[1]), str(entry[2])])


# ================================================================ ② 노드

func _open_scene(opp: OpponentData, solo: AttackData) -> Node:
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var node: Node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	node.set("practice_opponent", _f._drill_opp(opp, solo))
	node.set("test_weapon", weapon)
	node.set("mouse_aim_enabled", false)
	node.set("rng_seed", 1)
	_tree.root.add_child(node)
	node.set_process(false)
	node.set_physics_process(false)
	return node


func _refresh_view(node: Node, core: DuelCore, view: OpponentView, first: bool) -> void:
	if first:
		# 뷰는 멀리로 스냅해 있다. 다시 setup해 지금 간격으로 스냅시킨다(pattern_shots와 같은 길).
		view.setup(core.opponent_data, core.weapon, false)
	node.set("_display_time", core.time)
	node.call("_update_views", 0.0)


func _scene_checks(errs: Array[String], jobs: Array[Dictionary]) -> void:
	var dive_job := {}
	for job in jobs:
		if (job["route"] as AttackData).dive:
			dive_job = job
			break
	if dive_job.is_empty():
		errs.append("[②] 뛰어들기 공격이 없어 노드를 볼 수 없다")
		return
	var solo: AttackData = _f._solo(dive_job["route"])
	var opp: OpponentData = dive_job["opp"]
	for distance: int in [DT.Distance.ENGAGE, DT.Distance.CLOSE]:
		var tag := "교전" if distance == DT.Distance.ENGAGE else "밀착"
		var node := _open_scene(opp, solo)
		var core: DuelCore = node.get("core")
		var view := node.get_node("OpponentView") as OpponentView
		var label := view.get_node("StateLabel") as Label
		var hint := view.get_node_or_null("StateHint") as Label
		if hint == null:
			errs.append("[②] OpponentView/StateHint가 없다")
			node.free()
			return
		if _font == null:
			_font = label.get_theme_font(&"font")
			_font_size = label.get_theme_font_size(&"font_size")
			_label_w = label.size.x
		core.distance = distance
		var guard := 0
		while guard < 1500 and core.brain.state != DT.OpponentState.TELL:
			core.tick(DELTA)
			guard += 1
		if core.brain.state != DT.OpponentState.TELL:
			errs.append("[② %s] 예비 동작이 오지 않는다" % tag)
			node.free()
			continue
		_refresh_view(node, core, view, true)
		var want_hint := _expected_hint(solo, solo, 0, &"none", distance == DT.Distance.CLOSE)
		_check_nodes(errs, "② %s 예비 동작" % tag, view, label, hint, want_hint)
		# 같은 판의 예비 동작 밖(빈틈이나 대기): 첫 줄의 자리는 그대로, 귀띔은 숨는다.
		guard = 0
		while guard < 900 and not core.ended and core.brain.state == DT.OpponentState.TELL:
			core.tick(DELTA)
			guard += 1
		if core.brain.state == DT.OpponentState.TELL:
			errs.append("[② %s] 예비 동작이 끝나지 않는다" % tag)
		else:
			_refresh_view(node, core, view, false)
			_check_nodes(errs, "② %s 예비 동작 밖(상태 %d)" % [tag, core.brain.state], view, label, hint, "")
		node.free()


## 첫 줄은 화면 y 62·가운데 · 배율 1, 귀띔은 첫 줄 오른쪽 곁. want_hint가 빈 글이면 숨어 있어야 한다.
func _check_nodes(errs: Array[String], tag: String, view: OpponentView, label: Label, hint: Label, want_hint: String) -> void:
	if label.text.contains("\n"):
		errs.append("[%s] 상태 글자에 줄바꿈이 있다: '%s'" % [tag, label.text.replace("\n", "\\n")])
	var lt := label.get_global_transform()
	var scale_x := lt.get_scale().x
	var center_x := lt.origin.x + label.size.x * scale_x * 0.5
	if absf(lt.origin.y - OpponentView.STATE_LABEL_Y) > 0.5 or absf(center_x - view.anchor.x) > 0.5 or absf(scale_x - 1.0) > 0.01:
		errs.append("[%s] 첫 줄의 자리 y %.1f · 가운데 x %.1f(기대 %.1f) · 배율 %.2f (기대 y %.0f · 배율 1)" % [
			tag, lt.origin.y, center_x, view.anchor.x, scale_x, OpponentView.STATE_LABEL_Y])
	if label.text != "":
		var line_w := _font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		if absf(line_w - label.get_minimum_size().x) > 1.0:
			errs.append("[%s] 첫 줄 '%s'의 글 폭: 글꼴로 잰 값 %.1f · 노드 %.1f (1px 안이어야 한다)" % [tag, label.text, line_w, label.get_minimum_size().x])
	if want_hint == "":
		if hint.visible:
			errs.append("[%s] 귀띔이 숨지 않았다: '%s'" % [tag, hint.text])
		return
	if not hint.visible or hint.text != want_hint:
		errs.append("[%s] 귀띔 '%s'(보임 %s) (기대 '%s')" % [tag, hint.text, hint.visible, want_hint])
		return
	var ht := hint.get_global_transform()
	var want_left := OpponentView.hint_left(label.get_minimum_size().x, view.anchor.x)
	if absf(ht.origin.x - want_left) > 1.0 or absf(ht.origin.y - OpponentView.STATE_LABEL_Y) > 0.5 or absf(ht.get_scale().x - 1.0) > 0.01:
		errs.append("[%s] 귀띔의 자리 x %.1f(기대 %.1f) · y %.1f(기대 %.0f) · 배율 %.2f" % [
			tag, ht.origin.x, want_left, ht.origin.y, OpponentView.STATE_LABEL_Y, ht.get_scale().x])
	var right := ht.origin.x + hint.get_minimum_size().x * ht.get_scale().x
	if right > HINT_MAX_RIGHT:
		errs.append("[%s] 귀띔의 오른쪽 끝 %.1f (%.0f 안이어야 한다)" % [tag, right, HINT_MAX_RIGHT])
	if hint.get_theme_font(&"font") != label.get_theme_font(&"font") or hint.get_theme_font_size(&"font_size") != label.get_theme_font_size(&"font_size") \
			or not hint.get_theme_color(&"font_color").is_equal_approx(label.get_theme_color(&"font_color")) \
			or not hint.get_theme_color(&"font_outline_color").is_equal_approx(label.get_theme_color(&"font_outline_color")) \
			or hint.get_theme_constant(&"outline_size") != label.get_theme_constant(&"outline_size"):
		errs.append("[%s] 귀띔의 글꼴·크기·색·테두리가 상태 글자와 다르다" % tag)
	if hint.z_index != 9:
		errs.append("[%s] 귀띔의 z_index %d (기대 9)" % [tag, hint.z_index])


# ================================================================ ① 글 · ③ 고리 · ④ 한 줄 · ⑤ 효과 글

## 귀띔의 표(결정 625): 휩쓸기는 뿌리가, 뛰어들기와 올려 막기는 지금 타격이 정한다(올려 막기는 첫 타격뿐).
func _expected_hint(root: AttackData, atk: AttackData, step: int, mode: StringName, from_close: bool) -> String:
	var parts: Array[String] = []
	if root.sweep and not root.chain.is_empty():
		parts.append(HINT_SWEEP)
	if atk.dive:
		parts.append(HINT_DIVE_CLOSE if from_close else HINT_DIVE_FAR)
	if step == 0 and atk.needs_raised_guard:
		if mode == &"ready":
			parts.append(HINT_READY)
		elif mode == &"held":
			parts.append(HINT_HELD)
	return " · ".join(parts)


## 그 공격의 첫 예비 동작까지 판을 돌린다. none: 막기 없음 · ready: 예비 동작에서 새로 올림 · held: 전부터 들고 있음.
func _tell_core(opp: OpponentData, mode: StringName) -> DuelCore:
	var cfg: Dictionary = {}
	var stop: Callable = _f._stop_first_tell()
	if mode == &"none":
		cfg = {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"none"}
	elif mode == &"held":
		cfg = {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"keep"}
		var armed := [false]
		stop = func(c: DuelCore) -> bool:
			if not armed[0]:
				armed[0] = true
				c.set_guard(true)
			return c.record.of_type(DuelRecord.TELL_START).size() >= 1
	var core: DuelCore = _f._play(opp, cfg, stop, 20.0)
	if core.brain.state != DT.OpponentState.TELL or core.brain.current_attack == null:
		return null
	return core


func _combo_sets(opp: OpponentData, solo: AttackData, strikes: Array[AttackData]) -> Array[Dictionary]:
	var raw: Array[Array] = []
	if opp.use_heights:
		raw = _f._height_combos(strikes)
	else:
		var flat: Array = []
		for _s in strikes:
			flat.append(-1)
		raw = [flat]
	var out: Array[Dictionary] = []
	for combo: Array in raw:
		var heights: Array[int] = []
		for h in combo:
			heights.append(int(h))
		var positions: Array[Vector2] = _f._ring_positions(opp, solo, heights)
		out.append({"heights": heights, "positions": positions})
	return out


func _cfgs(dive: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{"distance": DT.Distance.ENGAGE, "pull": 0.0, "close": false},
		{"distance": DT.Distance.CLOSE, "pull": 0.0, "close": true},
	]
	if dive:
		# 뛰어들기의 당김 1, 그리고 보고 멀리로 물러선 뒤의 자리(결정 628).
		out.append({"distance": DT.Distance.ENGAGE, "pull": 1.0, "close": false})
		out.append({"distance": DT.Distance.CLOSE, "pull": 1.0, "close": true})
		out.append({"distance": DT.Distance.FAR, "pull": 1.0, "close": false})
	return out


func _box(center: Vector2, radius: float) -> Rect2:
	return Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))


func _overlap_height(a: Rect2, b: Rect2) -> float:
	if a.end.x <= b.position.x or b.end.x <= a.position.x:
		return 0.0
	return maxf(0.0, minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y))


func _width(text: String, font: Font, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _run_job(errs: Array[String], job: Dictionary) -> void:
	var opp: OpponentData = job["opp"]
	var label: String = job["label"]
	var solo: AttackData = _f._solo(job["route"])
	var strikes: Array[AttackData] = _f._strike_list(solo)
	var drilled: OpponentData = _f._drill_opp(opp, solo)
	var modes: Array[StringName] = [&"none"]
	if solo.needs_raised_guard:
		modes.append(&"ready")
		modes.append(&"held")
		_raised_jobs += 1
	var combos := _combo_sets(opp, solo, strikes)
	var cfgs := _cfgs(solo.dive)
	var parry_band := OpponentView.RING_SPEED * _weapon.parry_window
	for mode in modes:
		var core := _tell_core(drilled, mode)
		if core == null:
			_f._note(errs, "[①] %s (%s): 예비 동작까지 판이 가지 않는다" % [label, mode])
			continue
		if not _check_mode_state(errs, label, mode, core):
			continue
		_check_first_tell(errs, label, mode, core, solo)
		if mode == &"none":
			_check_one_line_invariant(errs, label, strikes, combos, cfgs)
		_check_geometry(errs, label, mode, core, solo, strikes, combos, cfgs, parry_band)


## 막기의 모드가 정말 그 상태를 만들었는가(시험 장치의 점검).
func _check_mode_state(errs: Array[String], label: String, mode: StringName, core: DuelCore) -> bool:
	var guarding := core.player_state == DT.PlayerState.GUARD
	var ok := true
	match mode:
		&"none":
			ok = not guarding
		&"ready":
			ok = guarding and not core.would_brace_now()
		&"held":
			ok = guarding and core.would_brace_now()
	if not ok:
		_f._note(errs, "[①] %s (%s): 막기의 상태가 모드와 다르다 (막는 중 %s · 버티기 %s)" % [label, mode, guarding, core.would_brace_now()])
	return ok


## ① 실제 첫 예비 동작의 글: 한 줄, 귀띔의 표와 같다.
func _check_first_tell(errs: Array[String], label: String, mode: StringName, core: DuelCore, solo: AttackData) -> void:
	var raised_ok := true
	for from_close: bool in [false, true]:
		var parts := OpponentView.tell_texts(core, from_close)
		_text_checks += 1
		if parts.size() != 2:
			_f._note(errs, "[①] %s: tell_texts가 %d칸을 돌려준다" % [label, parts.size()])
			raised_ok = false
			continue
		var want := _expected_hint(solo, solo, 0, mode, from_close)
		if parts[1] != want:
			_f._note(errs, "[①] %s (%s, 밀착 시작 %s): 귀띔 '%s' (기대 '%s')" % [label, mode, from_close, parts[1], want])
			raised_ok = false
		if parts[0].contains("\n") or parts[1].contains("\n") or parts[0] == "":
			_f._note(errs, "[①] %s: 첫 줄 '%s'이나 귀띔 '%s'에 줄바꿈이 있거나 첫 줄이 비었다" % [label, parts[0].replace("\n", "\\n"), parts[1].replace("\n", "\\n")])
			raised_ok = false
		for text in ALL_HINTS:
			if parts[0].contains(text):
				_f._note(errs, "[①] %s: 첫 줄 '%s'에 귀띔의 글 '%s'가 섞였다" % [label, parts[0], text])
				raised_ok = false
	if solo.needs_raised_guard and raised_ok:
		_raised_branch[mode] = int(_raised_branch[mode]) + 1


## ④ 당김 0에서 번호 고리는 상태 글자의 상자와 겹치지 않는다. 당김 1의 겹친 높이는 적기만 한다.
func _check_one_line_invariant(errs: Array[String], label: String, strikes: Array[AttackData], combos: Array[Dictionary], cfgs: Array[Dictionary]) -> void:
	if strikes.size() < 2:
		return
	var line_box := Rect2(Vector2(SCREEN_W * 0.5 - _label_w * 0.5, OpponentView.STATE_LABEL_Y), Vector2(_label_w, _line_h))
	for cs in combos:
		var positions: Array[Vector2] = cs["positions"]
		if positions.size() != strikes.size():
			_f._note(errs, "[④] %s: 고리 %d개 (타격 %d개)" % [label, positions.size(), strikes.size()])
			continue
		for cfg in cfgs:
			var distance: int = cfg["distance"]
			var pull: float = cfg["pull"]
			for pos in positions:
				var ring := _box(_f._screen_point(distance, pull, pos), OpponentView.MARK_RADIUS)
				if pull == 0.0:
					if ring.intersects(line_box):
						_f._note(errs, "[④] %s 높이 %s (%s): 번호 고리 %s가 상태 글자 상자 %s와 겹친다" % [
							label, str(cs["heights"]), DT.DISTANCE_NAMES[distance], str(ring), str(line_box)])
				else:
					_pull_max[distance] = maxf(float(_pull_max[distance]), _overlap_height(ring, line_box))


## ③ 귀띔의 상자가 번호 고리·패리 띠와 겹치지 않는다, ⑤ 효과 글과의 거리(INFO). 높이 조합과 걸음마다 뇌를 고쳐 가며 실제 tell_texts를 부른다.
func _check_geometry(errs: Array[String], label: String, mode: StringName, core: DuelCore, solo: AttackData, strikes: Array[AttackData],
		combos: Array[Dictionary], cfgs: Array[Dictionary], parry_band: float) -> void:
	_ensure_effects(core)
	var brain := core.brain
	var pattern := strikes.size() > 1
	var flags: Array[bool] = [false]
	if solo.dive:
		flags.append(true)
	for cs in combos:
		var heights: Array[int] = cs["heights"]
		var positions: Array[Vector2] = cs["positions"]
		if positions.size() != strikes.size():
			continue
		brain.strike_heights = heights
		for step in strikes.size():
			brain.step_index = step
			brain.current_attack = strikes[step]
			var texts := {}
			for from_close in flags:
				var parts := OpponentView.tell_texts(core, from_close)
				var want := _expected_hint(solo, strikes[step], step, mode, from_close)
				if parts[0].contains("\n") or parts[1].contains("\n") or parts[1] != want:
					_f._note(errs, "[①] %s (%s) %d번째 타격 높이 %s: 첫 줄 '%s' · 귀띔 '%s' (기대 '%s', 줄바꿈 없음)" % [
						label, mode, step + 1, str(heights), parts[0].replace("\n", "\\n"), parts[1], want])
				texts[from_close] = parts
			for cfg in cfgs:
				var parts: PackedStringArray = texts[bool(cfg["close"]) and solo.dive]
				if parts[1] == "":
					continue
				_hint_jobs[label] = true
				var line_w := _width(parts[0], _font, _font_size)
				var hint_w := _width(parts[1], _font, _font_size)
				var left := OpponentView.hint_left(line_w, SCREEN_W * 0.5)
				var hint_box := Rect2(Vector2(left, OpponentView.STATE_LABEL_Y), Vector2(hint_w, _line_h))
				var distance: int = cfg["distance"]
				var pull: float = cfg["pull"]
				if hint_box.end.x > HINT_MAX_RIGHT:
					_f._note(errs, "[③] %s (%s) %d번째 타격: 귀띔의 오른쪽 끝 %.1f (%.0f 안이어야 한다)" % [label, mode, step + 1, hint_box.end.x, HINT_MAX_RIGHT])
				if pattern:
					for k in positions.size():
						var center: Vector2 = _f._screen_point(distance, pull, positions[k])
						if hint_box.intersects(_box(center, OpponentView.MARK_RADIUS)):
							_f._note(errs, "[③] %s (%s) 높이 %s · %d번째 타격 · %s 당김 %.0f: 귀띔 상자 %s가 %d번 고리와 겹친다" % [
								label, mode, str(heights), step + 1, DT.DISTANCE_NAMES[distance], pull, str(hint_box), k + 1])
						if hint_box.intersects(_box(center + Vector2(0.0, -BACKDROP_UP), BACKDROP_RADIUS)):
							_backdrop_hits += 1
				if not solo.sweep:
					var band_center: Vector2 = _f._screen_point(distance, pull, positions[step])
					if hint_box.intersects(_box(band_center, parry_band)):
						_f._note(errs, "[③] %s (%s) 높이 %s · %d번째 타격 · %s 당김 %.0f: 귀띔 상자 %s가 패리 띠(반지름 %.1f)와 겹친다" % [
							label, mode, str(heights), step + 1, DT.DISTANCE_NAMES[distance], pull, str(hint_box), parry_band])
				if pull == 0.0:
					_measure_effects(label, mode, step, parts, hint_w, line_w)


## 효과 글의 줄 둘(DuelHud.effect_text)의 글. 팔 줄 · 다리 줄 차례다.
func _ensure_effects(core: DuelCore) -> void:
	if not _effects.is_empty():
		return
	core.brain.slow_tells_left = 3
	core.brain.parry_charges = 1
	var text := DuelHud.effect_text(core)
	core.brain.slow_tells_left = 0
	core.brain.parry_charges = 0
	for line in text.split("\n"):
		_effects.append(line)


## ⑤ 귀띔의 오른쪽 끝과 효과 글 두 줄의 왼쪽 끝(순수 셈, 판정하지 않는다).
func _measure_effects(label: String, mode: StringName, step: int, parts: PackedStringArray, hint_w: float, line_w: float) -> void:
	if _effects.size() != 2:
		return
	var eh := _body_font.get_height(EFFECT_SIZE)
	var rows: Array = [[EFFECT_TOP, EFFECT_TOP + eh], [EFFECT_TOP + eh, EFFECT_TOP + eh * 2.0]]
	for slow in [false, true]:
		var first_w := _width(parts[0] + (SLOW_SUFFIX if slow else ""), _font, _font_size) if slow else line_w
		var right := OpponentView.hint_left(first_w, SCREEN_W * 0.5) + hint_w
		for index in 2:
			var key := ("arm" if index == 0 else "leg") + ("_slow" if slow else "_plain")
			var left := EFFECT_RIGHT - _width(_effects[index], _body_font, EFFECT_SIZE)
			var deep := right - left
			if deep <= 0.0:
				continue
			var used_rows: Array = [0] if index == 0 else [0, 1]
			var vertical := 0.0
			for row: int in used_rows:
				var top: float = rows[row][0]
				var bottom: float = rows[row][1]
				vertical = maxf(vertical, minf(OpponentView.STATE_LABEL_Y + _line_h, bottom) - maxf(OpponentView.STATE_LABEL_Y, top))
			var entry: Array = _five.get(key, [-INF, 0.0, "", 0])
			entry[3] = int(entry[3]) + 1
			if deep > float(entry[0]):
				entry[0] = deep
				entry[1] = maxf(vertical, 0.0)
				entry[2] = "%s (%s) %d번째 타격 '%s' + '%s'" % [label, mode, step + 1, parts[0], parts[1]]
			_five[key] = entry
