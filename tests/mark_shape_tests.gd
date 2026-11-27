extends RefCounted
## T125: 고리의 꼴과 박자(계획 042a, 결정 630~635). 꼴이 있는 길은 연습의 길 목록에서 스스로 찾는다 — 042가 엇박을 상대에게 옮겨도 고치지 않는다.
## 길 목록·도우미는 fourth_opponent_tests.gd에서 빌린다(그 파일은 고치지 않는다). 로드한 자원은 고치지 않고 사본만 쓴다.

const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const WEAPON_PATH := "res://data/weapons/rapier.tres"
const SCREEN_W := 1280.0
const SCREEN_MARGIN := 8.0
## 번호 바탕: 고리 위 42, 반지름 15(opponent_view.gd의 _draw_marks).
const BACKDROP_UP := 42.0
const BACKDROP_RADIUS := 15.0
const PLAIN_KEYS := "number,pos,role,time"
const FEINT_KEYS := "feint,number,pos,role,time"
const WITHDRAW_KEYS := "number,pos,role,time,withdraw"
const PATH_KEYS :="dot,points,role"
const EM_DASH := 0x2014
const MIN_LENGTH_GAP := 20.0
const LONG_BEAT := 1.0
const TIME_EPS := 0.001
const SIM_SECONDS := 12.0

var _tree: SceneTree
var _f: Fourth = Fourth.new()

var _font: Font
var _font_size := 28
var _label_w := 440.0
var _line_h := 0.0
var _stats := {}


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T125", "name": "고리의 꼴과 박자: 꼴이 빈 길은 그대로, 박자 고리의 막대(길이·쪽·겹침), 세는 말과 박자의 일치, 막는 법의 줄, 판정이 같다", "fn": t125_mark_shape},
	]


func cleanup() -> void:
	_tree = null


func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


# ================================================================ 길 목록

## 길(뿌리와 변주)마다 하나: 연습의 모든 상대의 모든 단, 버릇의 반응, 주인 없는 공격.
func _build_jobs() -> Array[Dictionary]:
	var jobs: Array[Dictionary] = []
	var seen := {}
	var trials := SelectScript.load_trials()
	for opp in trials:
		var roots: Array[AttackData] = []
		for attacks: Array in _f._tier_lists(opp):
			for atk: AttackData in attacks:
				roots.append(atk)
		for habit in opp.habits:
			if habit != null and habit.response != null:
				roots.append(habit.response)
		for root in roots:
			_add_routes(jobs, seen, opp, root, opp.display_name)
	if not trials.is_empty():
		for spare in SelectScript.load_spare_attacks():
			_add_routes(jobs, seen, trials[0], spare, "주인 없는 " + spare.attack_name)
	return jobs


func _add_routes(jobs: Array[Dictionary], seen: Dictionary, opp: OpponentData, root: AttackData, label: String) -> void:
	var routes: Array[AttackData] = _f._routes(root)
	for route in routes:
		if seen.has(route.get_instance_id()):
			continue
		seen[route.get_instance_id()] = true
		jobs.append({"opp": opp, "root": root, "route": route, "label": "%s %s" % [label, route.attack_name]})


## 꼴과 세는 말을 비운 사본(변주는 이미 뗀 길을 받는다).
func _blank(route: AttackData) -> AttackData:
	var copy := route.duplicate() as AttackData
	copy.mark_shape = &""
	copy.tell_hint = ""
	return copy


## 예비 동작이 막 시작된 뇌의 표시 목록. 높이를 넘기면 뇌의 strike_heights를 그것으로 덮는다.
func _marks_for(opp: OpponentData, solo: AttackData, heights: Array[int]) -> Array[Dictionary]:
	var brain := OpponentBrain.new(_f._drill_opp(opp, solo), _f._seeded())
	brain.start_idle(0.0)
	brain.start_tell(0.0, false)
	if not heights.is_empty():
		brain.strike_heights = heights
	var out: Array[Dictionary] = []
	if brain.pattern_root == null or brain.state != DT.OpponentState.TELL:
		return out
	return OpponentView.pattern_marks(brain, 0.0)


func _has_bar(mark: Dictionary) -> bool:
	return mark.has("shape") and OpponentView.MARK_SHAPES.has(mark["shape"]) and float(mark["wait"]) > 0.0


func _box(center: Vector2, radius: float) -> Rect2:
	return Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))


func _combo_heights(opp: OpponentData, strikes: Array[AttackData]) -> Array[Array]:
	if opp.use_heights:
		return _f._height_combos(strikes)
	var flat: Array = []
	for _s in strikes:
		flat.append(-1)
	var out: Array[Array] = [flat]
	return out


# ================================================================ 본 시험

func t125_mark_shape() -> String:
	var errs: Array[String] = []
	_stats = {"plain_routes": 0, "plain_multi": 0, "beat_routes": 0, "bars": 0, "combos": 0, "ring_touch": 0, "hint_routes": 0, "event_lines": 0, "help_lists": 0, "help_beat_lists": 0, "help_max_lines": 0}
	var jobs := _build_jobs()
	if jobs.is_empty():
		return "연습의 상대나 길이 없다"

	var beat_jobs: Array[Dictionary] = []
	for job in jobs:
		var route: AttackData = job["route"]
		if route.mark_shape == &"":
			_check_plain(errs, job)
		else:
			beat_jobs.append(job)
	if _stats["plain_multi"] == 0:
		_f._note(errs, "[①] 꼴이 빈 패턴 길을 하나도 보지 못했다")
	if beat_jobs.is_empty():
		_f._note(errs, "[②] 꼴이 있는 길이 하나도 없다 (엇박 찌르기에 mark_shape가 있어야 한다)")
	else:
		_open_font(beat_jobs[0])
		_check_roots(errs, beat_jobs)
		for job in beat_jobs:
			_stats["beat_routes"] = int(_stats["beat_routes"]) + 1
			_check_shaped(errs, job)
		_check_dash_glyph(errs, beat_jobs)
	_check_help(errs)
	_print_info(jobs.size())
	return _ok(errs)


func _print_info(job_count: int) -> void:
	print("  INFO T125 길 %d개 · 꼴이 빈 길 %d개(패턴 %d개) · 박자 고리 길 %d개 · 본 막대 %d개(높이 조합 %d) · 막대가 다른 고리와 닿은 수(판정 아님) %d · 세는 말이 있는 길 %d · 이벤트 줄 %d · 막는 법 목록 %d개(박자 줄 %d개, 박자 목록의 최대 줄 수 %d/%d)" % [
		job_count, int(_stats["plain_routes"]), int(_stats["plain_multi"]), int(_stats["beat_routes"]), int(_stats["bars"]), int(_stats["combos"]),
		int(_stats["ring_touch"]), int(_stats["hint_routes"]), int(_stats["event_lines"]), int(_stats["help_lists"]), int(_stats["help_beat_lists"]),
		int(_stats["help_max_lines"]), SelectScript.HELP_LINES])


# ================================================================ ① 꼴이 빈 길

## 예비 동작의 표시 목록의 키가 이전과 같다: 번호 고리는 number·pos·role·time, 휩쓸기의 길은 dot·points·role.
func _check_plain(errs: Array[String], job: Dictionary) -> void:
	_stats["plain_routes"] = int(_stats["plain_routes"]) + 1
	var opp: OpponentData = job["opp"]
	var label: String = job["label"]
	var solo: AttackData = _f._solo(job["route"])
	var none: Array[int] = []
	var marks := _marks_for(opp, solo, none)
	if marks.is_empty():
		return
	_stats["plain_multi"] = int(_stats["plain_multi"]) + 1
	var strikes: Array[AttackData] = _f._strike_list(solo)
	for mark in marks:
		var names: Array[String] = []
		for key in mark.keys():
			names.append(str(key))
		names.sort()
		var joined := ",".join(names)
		var want := PATH_KEYS if mark["role"] == &"path" else PLAIN_KEYS
		# 헛손질인 타격의 고리에만 feint 열쇠가 더 선다(결정 680).
		if mark["role"] != &"path":
			var index := int(mark["number"]) - 1
			if index >= 0 and index < strikes.size() and strikes[index].feint:
				want = FEINT_KEYS
			# 빠지는 길의 마지막 고리에만 withdraw 열쇠가 선다(결정 711).
			if index == strikes.size() - 1 and solo.withdraw:
				want = WITHDRAW_KEYS
		if joined != want:
			_f._note(errs, "[①] %s: 표시의 키 '%s' (기대 '%s')" % [label, joined, want])
			return


# ================================================================ ② 꼴이 있는 길

## 뿌리와 변주가 같은 꼴을 갖고 그 이름을 뷰가 안다.
func _check_roots(errs: Array[String], beat_jobs: Array[Dictionary]) -> void:
	var seen := {}
	for job in beat_jobs:
		var root: AttackData = job["root"]
		if seen.has(root.get_instance_id()):
			continue
		seen[root.get_instance_id()] = true
		var routes: Array[AttackData] = _f._routes(root)
		for route in routes:
			if route.mark_shape != root.mark_shape:
				_f._note(errs, "[②] %s: 변주의 꼴 '%s'가 뿌리의 '%s'와 다르다" % [root.attack_name, route.mark_shape, root.mark_shape])
		if not OpponentView.MARK_SHAPES.has(root.mark_shape):
			_f._note(errs, "[②] %s: 꼴 '%s'를 MARK_SHAPES가 모른다" % [root.attack_name, root.mark_shape])


func _check_shaped(errs: Array[String], job: Dictionary) -> void:
	var opp: OpponentData = job["opp"]
	var label: String = job["label"]
	var route: AttackData = job["route"]
	var solo: AttackData = _f._solo(route)
	var strikes: Array[AttackData] = _f._strike_list(solo)
	_check_marks(errs, label, opp, solo, strikes)
	_check_bars(errs, label, opp, solo, strikes)
	_check_sides(errs, label, opp, solo)
	_check_hint(errs, label, opp, solo, strikes)
	_check_same_events(errs, label, opp, solo)


## 첫 타격의 wait는 0, 둘째부터 그 걸음의 tell_time이고 shape가 그 이름이며 고리의 자리는 꼴을 비운 사본과 같다.
func _check_marks(errs: Array[String], label: String, opp: OpponentData, solo: AttackData, strikes: Array[AttackData]) -> void:
	var none: Array[int] = []
	var marks := _marks_for(opp, solo, none)
	var plain := _marks_for(opp, _blank(solo), none)
	if marks.size() != strikes.size() or plain.size() != strikes.size():
		_f._note(errs, "[②] %s: 표시 %d개 · 꼴 없는 사본 %d개 (타격 %d개)" % [label, marks.size(), plain.size(), strikes.size()])
		return
	for i in marks.size():
		var mark: Dictionary = marks[i]
		var bare: Dictionary = plain[i]
		if not mark.has("shape") or not mark.has("wait") or not mark.has("side"):
			_f._note(errs, "[②] %s %d번째 표시에 shape·wait·side가 없다" % [label, i + 1])
			continue
		if bare.has("shape") or bare.has("wait") or bare.has("side"):
			_f._note(errs, "[②] %s %d번째: 꼴을 비운 사본에 shape·wait·side가 남았다" % [label, i + 1])
		var want_wait := 0.0 if i == 0 else strikes[i].tell_time
		var wait: float = mark["wait"]
		if absf(wait - want_wait) > TIME_EPS:
			_f._note(errs, "[②] %s %d번째 타격: wait %.4f (기대 %.4f)" % [label, i + 1, wait, want_wait])
		if mark["shape"] != solo.mark_shape:
			_f._note(errs, "[②] %s %d번째 타격: shape '%s' (기대 '%s')" % [label, i + 1, mark["shape"], solo.mark_shape])
		var pos: Vector2 = mark["pos"]
		var bare_pos: Vector2 = bare["pos"]
		if not pos.is_equal_approx(bare_pos):
			_f._note(errs, "[②] %s %d번째 타격: 고리의 자리 %s (꼴을 비운 사본 %s)" % [label, i + 1, str(pos), str(bare_pos)])


# ================================================================ ③ 막대

## 길이는 wait에 비례하고, 교전·밀착의 화면 자리에서 화면 안이며 상태 글자의 줄 · 번호 바탕 · 다른 막대와 겹치지 않는다. 고리와 닿는 수는 적기만 한다.
func _check_bars(errs: Array[String], label: String, opp: OpponentData, solo: AttackData, strikes: Array[AttackData]) -> void:
	var line_box := Rect2(Vector2(SCREEN_W * 0.5 - _label_w * 0.5, OpponentView.STATE_LABEL_Y), Vector2(_label_w, _line_h))
	var combos := _combo_heights(opp, strikes)
	for combo in combos:
		var heights: Array[int] = []
		for h in combo:
			heights.append(int(h))
		var marks := _marks_for(opp, solo, heights)
		if marks.size() != strikes.size():
			continue
		_stats["combos"] = int(_stats["combos"]) + 1
		var bar_count := 0
		var lengths: Array[float] = []
		var waits: Array[float] = []
		for mark in marks:
			if mark["role"] == &"now" or not _has_bar(mark):
				continue
			bar_count += 1
			var rel: Rect2 = OpponentView.beat_bar_rect(mark)
			var wait: float = mark["wait"]
			lengths.append(rel.size.x)
			waits.append(wait)
			if absf(rel.size.x - wait * OpponentView.BEAT_BAR_SPEED) > 0.01 or absf(rel.size.y - OpponentView.BEAT_BAR_HEIGHT) > 0.01:
				_f._note(errs, "[③] %s 높이 %s: 막대 크기 %s (기대 길이 %.2f · 높이 %.1f)" % [label, str(heights), str(rel.size), wait * OpponentView.BEAT_BAR_SPEED, OpponentView.BEAT_BAR_HEIGHT])
		_stats["bars"] = int(_stats["bars"]) + bar_count
		# 예비 동작이 시작될 때 보이는 막대의 수 = 걸음의 수.
		if bar_count != solo.chain.size():
			_f._note(errs, "[③] %s 높이 %s: 막대 %d개 (걸음 %d개)" % [label, str(heights), bar_count, solo.chain.size()])
		for a in lengths.size():
			for b in range(a + 1, lengths.size()):
				var gap_wait := absf(waits[a] - waits[b])
				if gap_wait >= 0.5 and absf(lengths[a] - lengths[b]) < MIN_LENGTH_GAP:
					_f._note(errs, "[③] %s: 박이 %.2f초 다른 막대의 길이 차 %.1f px (%.0f px 이상이어야 한다)" % [label, gap_wait, absf(lengths[a] - lengths[b]), MIN_LENGTH_GAP])
		for distance: int in [DT.Distance.ENGAGE, DT.Distance.CLOSE]:
			_check_bar_screen(errs, label, heights, marks, distance, line_box)


func _check_bar_screen(errs: Array[String], label: String, heights: Array[int], marks: Array[Dictionary], distance: int, line_box: Rect2) -> void:
	var tag: String = DT.DISTANCE_NAMES[distance]
	var bars: Array[Rect2] = []
	var owners: Array[int] = []
	var backdrops: Array[Rect2] = []
	var rings: Array[Rect2] = []
	for i in marks.size():
		var mark: Dictionary = marks[i]
		var pos: Vector2 = mark["pos"]
		var center: Vector2 = _f._screen_point(distance, 0.0, pos)
		backdrops.append(_box(center + Vector2(0.0, -BACKDROP_UP), BACKDROP_RADIUS))
		rings.append(_box(center, OpponentView.MARK_RADIUS))
		if mark["role"] == &"now" or not _has_bar(mark):
			continue
		var rel: Rect2 = OpponentView.beat_bar_rect(mark)
		bars.append(Rect2(_f._screen_point(distance, 0.0, rel.position), rel.size))
		owners.append(i)
	for k in bars.size():
		var bar := bars[k]
		if bar.position.x < SCREEN_MARGIN or bar.end.x > SCREEN_W - SCREEN_MARGIN:
			_f._note(errs, "[③] %s 높이 %s (%s): 막대 %s가 화면 밖이다 (x %.0f~%.0f 안이어야 한다)" % [label, str(heights), tag, str(bar), SCREEN_MARGIN, SCREEN_W - SCREEN_MARGIN])
		if bar.intersects(line_box):
			_f._note(errs, "[③] %s 높이 %s (%s): 막대 %s가 상태 글자의 줄 %s와 겹친다" % [label, str(heights), tag, str(bar), str(line_box)])
		for backdrop in backdrops:
			if bar.intersects(backdrop):
				_f._note(errs, "[③] %s 높이 %s (%s): 막대 %s가 번호 바탕 %s와 겹친다" % [label, str(heights), tag, str(bar), str(backdrop)])
		for j in range(k + 1, bars.size()):
			if bar.intersects(bars[j]):
				_f._note(errs, "[③] %s 높이 %s (%s): 막대 %s와 %s가 겹친다" % [label, str(heights), tag, str(bar), str(bars[j])])
		for r in rings.size():
			if r != owners[k] and bar.intersects(rings[r]):
				_stats["ring_touch"] = int(_stats["ring_touch"]) + 1


## 칼 팔이 왼쪽이면 고리의 오른쪽으로, 뒤집은 사본에서는 왼쪽으로 뻗는다.
func _check_sides(errs: Array[String], label: String, opp: OpponentData, solo: AttackData) -> void:
	var none: Array[int] = []
	for flipped in [false, true]:
		var copy := opp.duplicate() as OpponentData
		copy.sword_side = DT.Direction.RIGHT if flipped else DT.Direction.LEFT
		var marks := _marks_for(copy, solo, none)
		for mark in marks:
			if mark["role"] == &"now" or not _has_bar(mark):
				continue
			var pos: Vector2 = mark["pos"]
			var rel: Rect2 = OpponentView.beat_bar_rect(mark)
			if flipped and (rel.end.x > pos.x + 0.01 or int(mark["side"]) != -1):
				_f._note(errs, "[③] %s: 칼 팔이 오른쪽인데 막대 %s가 고리 x %.1f의 왼쪽이 아니다 (side %d)" % [label, str(rel), pos.x, int(mark["side"])])
			elif not flipped and (rel.position.x < pos.x - 0.01 or int(mark["side"]) != 1):
				_f._note(errs, "[③] %s: 칼 팔이 왼쪽인데 막대 %s가 고리 x %.1f의 오른쪽이 아니다 (side %d)" % [label, str(rel), pos.x, int(mark["side"])])


# ================================================================ ④ 세는 말

## tell_texts의 귀띔이 데이터의 글로 시작하고 둘째 타격의 예비에서도 같다. 쉼표(짧은 박)·줄표(긴 박)가 걸음의 간격과 일치한다.
func _check_hint(errs: Array[String], label: String, opp: OpponentData, solo: AttackData, strikes: Array[AttackData]) -> void:
	if solo.tell_hint == "":
		return
	_stats["hint_routes"] = int(_stats["hint_routes"]) + 1
	var core: DuelCore = _f._play(_f._drill_opp(opp, solo), {}, _f._stop_first_tell(), 20.0)
	if core.brain.state != DT.OpponentState.TELL or core.brain.pattern_root == null:
		_f._note(errs, "[④] %s: 예비 동작까지 판이 가지 않는다" % label)
		return
	for step in mini(strikes.size(), 2):
		core.brain.step_index = step
		core.brain.current_attack = strikes[step]
		var parts := OpponentView.tell_texts(core, false)
		if parts.size() != 2 or not parts[1].begins_with(solo.tell_hint):
			_f._note(errs, "[④] %s %d번째 타격: 귀띔 '%s' (기대 시작 '%s')" % [label, step + 1, parts[1] if parts.size() == 2 else "?", solo.tell_hint])
	var seps: Array[bool] = []
	for ch in solo.tell_hint:
		if ch == ",":
			seps.append(false)
		elif ch == "—":
			seps.append(true)
	if seps.size() != strikes.size() - 1:
		_f._note(errs, "[④] %s: 세는 말 '%s'의 쉼표·줄표 %d개 (걸음 %d개)" % [label, solo.tell_hint, seps.size(), strikes.size() - 1])
		return
	for i in seps.size():
		var want_long: bool = strikes[i + 1].tell_time >= LONG_BEAT
		if seps[i] != want_long:
			_f._note(errs, "[④] %s: 세는 말 '%s'의 %d번째 사이는 %s인데 걸음의 간격은 %.2f초다" % [label, solo.tell_hint, i + 1, "줄표(긴 박)" if seps[i] else "쉼표(짧은 박)", strikes[i + 1].tell_time])


## 상태 글자의 글꼴이 줄표를 갖고 있다(세는 말이 두부로 나오지 않는다).
func _check_dash_glyph(errs: Array[String], beat_jobs: Array[Dictionary]) -> void:
	var needs := false
	for job in beat_jobs:
		var route: AttackData = job["route"]
		if route.tell_hint.contains("—"):
			needs = true
	if needs and (_font == null or not _font.has_char(EM_DASH)):
		_f._note(errs, "[④] 상태 글자의 글꼴이 줄표(U+2014)를 갖고 있지 않다")


## 상태 글자의 글꼴·크기·상자 폭을 연습 화면의 결투 노드에서 얻는다(T124와 같은 길).
func _open_font(job: Dictionary) -> void:
	var opp: OpponentData = job["opp"]
	var solo: AttackData = _f._solo(job["route"])
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
	var label := node.get_node("OpponentView/StateLabel") as Label
	_font = label.get_theme_font(&"font")
	_font_size = label.get_theme_font_size(&"font_size")
	_label_w = maxf(label.size.x, _label_w) if label.size.x > 1.0 else _label_w
	_line_h = _font.get_height(_font_size)
	node.free()


# ================================================================ ⑥ 판정이 같다

## 꼴과 세는 말을 비운 사본과 같은 씨앗으로 돌려 이벤트 줄이 같다.
func _check_same_events(errs: Array[String], label: String, opp: OpponentData, solo: AttackData) -> void:
	var with_shape := _f._lines(_f._play(_f._drill_opp(opp, solo), {}, _f._never(), SIM_SECONDS))
	var without := _f._lines(_f._play(_f._drill_opp(opp, _blank(solo)), {}, _f._never(), SIM_SECONDS))
	_stats["event_lines"] = int(_stats["event_lines"]) + with_shape.size()
	if with_shape.is_empty():
		_f._note(errs, "[⑥] %s: 판의 이벤트가 하나도 없다" % label)
	elif with_shape != without:
		_f._note(errs, "[⑥] %s: 꼴·세는 말을 비운 사본과 이벤트 줄이 다르다 (%d줄 · %d줄)" % [label, with_shape.size(), without.size()])


# ================================================================ ⑤ 막는 법

func _list_has_beat(attacks: Array) -> bool:
	for atk: AttackData in attacks:
		if atk.mark_shape == &"beat":
			return true
		for variant in atk.variants:
			if variant is AttackData and (variant as AttackData).mark_shape == &"beat":
				return true
	return false


## 박자의 줄은 박자 고리가 있는 목록에만 있고, 그 목록의 막는 법은 칸 안에 든다.
func _check_help(errs: Array[String]) -> void:
	var trials := SelectScript.load_trials()
	if trials.is_empty():
		return
	var beat_line := DuelHud.HELP_BEAT.trim_prefix(" · ")
	for opp in trials:
		for attacks: Array in _f._tier_lists(opp):
			_check_help_list(errs, opp, attacks, opp.display_name, beat_line)
	_check_help_list(errs, trials[0], SelectScript.load_spare_attacks(), "주인 없는 검술", beat_line)


func _check_help_list(errs: Array[String], opp: OpponentData, attacks: Array, label: String, beat_line: String) -> void:
	_stats["help_lists"] = int(_stats["help_lists"]) + 1
	var text := SelectScript.help_text(opp, attacks)
	var has_beat := _list_has_beat(attacks)
	if text.contains(beat_line) != has_beat:
		_f._note(errs, "[⑤] %s: 박자의 줄이 %s (박자 고리의 공격 %s)" % [label, "있다" if text.contains(beat_line) else "없다", "있음" if has_beat else "없음"])
	if not has_beat:
		return
	_stats["help_beat_lists"] = int(_stats["help_beat_lists"]) + 1
	var lines := SelectScript.help_lines(text)
	_stats["help_max_lines"] = maxi(int(_stats["help_max_lines"]), lines)
	if lines > SelectScript.HELP_LINES:
		_f._note(errs, "[⑤] %s: 막는 법이 %d줄이다 (%d줄 안이어야 한다)" % [label, lines, SelectScript.HELP_LINES])
