extends RefCounted
## T83~T85: 공격의 칸과 변주(계획 036b). 높이 막기, 뽑기와 변주·난수 불변, 하루의 상대의 데이터와 표시의 자리.
## 판 돌리기와 상대 만들기는 pattern_tests.gd의 것을 그대로 쓴다(대기 1.0초, 0초에 전진. 타격 시각의 손 셈도 같다).

const Patterns := preload("res://tests/pattern_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const Bot := preload("res://tests/duel_bots.gd")
const Select := preload("res://scripts/commission/commission_select.gd")
const Title := preload("res://scripts/title.gd")

const DAY_PATHS: Array[String] = [
	"res://data/opponents/opponent_01.tres",
	"res://data/opponents/opponent_02.tres",
]
const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const RULES_PATH := "res://data/duel_rules.tres"
const CATALOG_PATH := "res://data/upgrade_catalog.tres"
const LEGS_ONLY_PATH := "res://data/commissions/variants/legs_only.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTAS: Array[float] = [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0]
const EPS := 1e-6

var _tree: SceneTree
var _p := Patterns.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T83", "name": "높이 막기: 칸이 맞아야 막힘·패리, 틀린 높이의 까닭, 높이 없는 타격의 회귀, 패턴의 걸음", "fn": t83_height_guard},
		{"id": "T84", "name": "뽑기와 변주: 예비 동작에서 한 번에, 시드로 재현, 높이 없는 데이터의 난수 불변, 가방 한 장", "fn": t84_draws},
		{"id": "T85", "name": "하루의 상대의 칸과 변주, 고리의 줄, 따라가는 점, 막는 법의 글, 가로만 버튼이 없음", "fn": t85_trial_cells},
		{"id": "T91", "name": "하루의 상대의 패턴: 데이터·옛 규칙 사본·안내·연습의 줄", "fn": t91_day_patterns},
	]


func cleanup() -> void:
	_tree = null
	_p = null


func _atk(direction: int, tell: float, recovery: float, heights: Array[int]) -> AttackData:
	var a: AttackData = _p._atk(direction, tell, recovery)
	a.heights = heights
	return a


## 오른쪽 상단 → 왼쪽 하단 → 가운데 중단(T79의 시각).
func _chain() -> AttackData:
	var root := _atk(DT.Direction.RIGHT, 0.9, 1.2, [DT.Height.HIGH])
	var steps: Array[Resource] = [_atk(DT.Direction.LEFT, 0.75, 0.0, [DT.Height.LOW]), _atk(DT.Direction.CENTER, 0.65, 0.0, [DT.Height.MID])]
	root.chain = steps
	return root


## 왼쪽 상단 → 가운데 중단 → 오른쪽 하단(T80의 시각).
func _sweep() -> AttackData:
	var root := _atk(DT.Direction.LEFT, 1.0, 1.6, [DT.Height.HIGH])
	root.is_big = true
	root.sweep = true
	var steps: Array[Resource] = [_atk(DT.Direction.CENTER, 0.6, 0.0, [DT.Height.MID]), _atk(DT.Direction.RIGHT, 0.6, 0.0, [DT.Height.LOW])]
	root.chain = steps
	return root


func _strikes(core: DuelCore) -> Array:
	return core.record.of_type(DuelRecord.STRIKE)


func _mode(mode: StringName) -> Callable:
	return func(_a: AttackData, _i: int) -> StringName: return mode


func t83_height_guard() -> String:
	var errs: Array[String] = []
	var SR := DT.StrikeResult
	var single := func() -> OpponentData: return _p._opp(_atk(DT.Direction.RIGHT, 0.9, 1.2, [DT.Height.HIGH]))
	# 1. 단발(오른쪽 상단): 칸이 맞으면 막힘·패리, 높이가 틀리면 그 까닭과 함께 맞는다.
	var held: DuelCore = _p._run(single.call(), {}, 2.4)
	if not _p._is(_strikes(held), [SR.BLOCKED]) or int(_strikes(held)[0]["height"]) != DT.Height.HIGH:
		errs.append("칸을 맞춘 막기: %s" % str(_p._results(_strikes(held))))
	var low: DuelCore = _p._run(single.call(), {"guard_fn": _mode(&"wrong_height")}, 2.4)
	var low_strikes := _strikes(low)
	if not _p._is(low_strikes, [SR.GRAZE]) or int(low_strikes[0]["situation"]) != DT.Situation.WRONG_GUARD \
			or low_strikes[0]["guard_miss"] != &"height" or low.player_posture != low.rules.player_posture_max - 1:
		errs.append("높이가 틀린 막기: %s" % str(low_strikes))
	var side: DuelCore = _p._run(single.call(), {"guard_fn": _mode(&"wrong")}, 2.4)
	if not _p._is(_strikes(side), [SR.GRAZE]) or _strikes(side)[0]["guard_miss"] != &"":
		errs.append("방향이 틀린 막기의 guard_miss가 비지 않음")
	var parried: DuelCore = _p._run(single.call(), {"guard_fn": _mode(&"parry")}, 2.4)
	if not _p._is(_strikes(parried), [SR.PARRIED]):
		errs.append("그 칸에서 새로 누른 막기가 패리가 아님: %s" % str(_p._results(_strikes(parried))))
	# 2. 회귀: 높이가 없거나 꺼진 상대면 어느 높이로 막아도 막힌다(봇은 중단으로 막는다).
	var no_heights: Array[int] = []
	var plain: DuelCore = _p._run(_p._opp(_atk(DT.Direction.RIGHT, 0.9, 1.2, no_heights)), {"guard_fn": _mode(&"wrong_height")}, 2.4)
	if not _p._is(_strikes(plain), [SR.BLOCKED]) or int(_strikes(plain)[0]["height"]) != -1:
		errs.append("높이 없는 타격이 방향만으로 막히지 않음")
	var flat_opp: OpponentData = (single.call() as OpponentData).flat()
	var flat: DuelCore = _p._run(flat_opp, {}, 2.4)
	if not _p._is(_strikes(flat), [SR.BLOCKED]) or int(_strikes(flat)[0]["height"]) != -1 or flat.aim_height != DT.Height.MID:
		errs.append("높이를 끈 상대가 높이를 봄")
	# 3. 이어 베기: 칸을 따라 옮기면 셋 다 막히고 시각은 그대로다. 둘째의 높이만 틀리면 거기서 끝난다.
	for delta in DELTAS:
		var chain: DuelCore = _p._run(_p._opp(_chain()), {}, 4.75, delta)
		_p._expect_times(errs, _p._times(_strikes(chain)), [2.2, 2.95, 3.6], "칸 이어 베기 delta %.4f" % delta)
		if not _p._is(_strikes(chain), [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]):
			errs.append("칸 이어 베기: %s" % str(_p._results(_strikes(chain))))
	var second := func(_a: AttackData, index: int) -> StringName: return &"wrong_height" if index == 1 else &"hold"
	var cut: DuelCore = _p._run(_p._opp(_chain()), {"step_fn": second}, 3.4)
	if not _p._is(_strikes(cut), [SR.BLOCKED, SR.GRAZE]) or _strikes(cut)[1]["guard_miss"] != &"height":
		errs.append("둘째의 높이만 틀림: %s" % str(_p._results(_strikes(cut))))
	# 4. 휩쓸기: 높이가 바뀌어도 쥔 채 끌면 이어진 막기다. 떼었다 누르면 그 까닭과 함께 맞는다.
	var sweep: DuelCore = _p._run(_p._opp(_sweep()), {}, 3.7)
	if not _p._is(_strikes(sweep), [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]):
		errs.append("칸 휩쓸기: %s" % str(_p._results(_strikes(sweep))))
	var regrip: DuelCore = _p._run(_p._opp(_sweep()), {"guard_fn": _mode(&"parry")}, 3.3)
	if not _p._is(_strikes(regrip), [SR.BLOCKED, SR.GRAZE]) or _strikes(regrip)[1]["guard_miss"] != &"regrip":
		errs.append("휩쓸기에서 떼었다 누름: %s" % str(_strikes(regrip)))
	# 5. 이벤트의 높이.
	var tells := sweep.record.of_type(DuelRecord.TELL_START)
	var chain_run: DuelCore = _p._run(_p._opp(_chain()), {}, 3.7)
	var chain_tell: Dictionary = chain_run.record.of_type(DuelRecord.TELL_START)[0]
	var chain_steps := chain_run.record.of_type(DuelRecord.PATTERN_STEP)
	if tells.is_empty() or str(chain_tell["heights"]) != "[0, 2, 1]" or int(chain_tell["height"]) != 0 \
			or chain_steps.size() != 2 or int(chain_steps[0]["height"]) != 2 or int(chain_steps[1]["height"]) != 1:
		errs.append("이벤트의 높이: %s" % str(chain_tell.get("heights", [])))
	return "OK" if errs.is_empty() else ", ".join(errs)


## 변주 둘을 가진 패턴. 모든 타격의 높이 묶음이 상·중이다.
func _varied() -> AttackData:
	var both: Array[int] = [DT.Height.HIGH, DT.Height.MID]
	var make := func(first: int, second: int) -> AttackData:
		var root := _atk(first, 0.9, 1.2, both)
		var steps: Array[Resource] = [_atk(second, 0.75, 0.0, both)]
		root.chain = steps
		return root
	var base: AttackData = make.call(DT.Direction.RIGHT, DT.Direction.LEFT)
	var others: Array[Resource] = [make.call(DT.Direction.LEFT, DT.Direction.RIGHT), make.call(DT.Direction.CENTER, DT.Direction.LEFT)]
	base.variants = others
	return base


## 뇌를 직접 60번 돌려 [고른 공격, 높이 배열]의 열을 낸다.
func _draw_run(pattern: AttackData, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var brain := OpponentBrain.new(_p._opp(pattern), rng)
	var out: Array = []
	for i in 60:
		brain.start_tell(float(i), false)
		out.append([brain.current_attack, brain.strike_heights])
		brain.start_idle(float(i) + 0.5)
	return out


func t84_draws() -> String:
	var errs: Array[String] = []
	# 1. 뇌를 직접: 바탕과 변주가 모두 나오고, 높이는 묶음 안이고, 시드로 재현된다.
	var pattern := _varied()
	var allowed: Array = [pattern, pattern.variants[0], pattern.variants[1]]
	var first := _draw_run(pattern, 7)
	var again := _draw_run(pattern, 7)
	var seen_roots := {}
	var seen_heights := {}
	for i in first.size():
		var root: AttackData = first[i][0]
		var heights: Array = first[i][1]
		if not allowed.has(root):
			errs.append("%d번째에 바탕·변주가 아닌 공격" % i)
		seen_roots[root] = true
		if heights.size() != 2:
			errs.append("%d번째의 높이 %d개 (기대 2)" % [i, heights.size()])
		for h: int in heights:
			seen_heights[h] = true
			if h != DT.Height.HIGH and h != DT.Height.MID:
				errs.append("%d번째에 묶음 밖의 높이 %d" % [i, h])
		if root != again[i][0] or heights != again[i][1]:
			errs.append("같은 시드인데 %d번째가 다름" % i)
		if i > 0 and is_same(first[i][1], first[i - 1][1]):
			errs.append("%d번째의 높이 배열이 앞의 것과 같은 배열" % i)
	if seen_roots.size() != 3 or seen_heights.size() != 2:
		errs.append("60번에 나온 길 %d가지(기대 3) · 높이 %d가지(기대 2)" % [seen_roots.size(), seen_heights.size()])
	# 2. 한 판: 예비 동작의 heights가 뒤따르는 타격·걸음의 높이와 같다(이벤트가 사본을 싣는다).
	var core: DuelCore = _p._run(_p._opp(_varied()), {}, 200.0)
	var expected: Array = []
	var index := 0
	var tells := 0
	for ev: Dictionary in core.record.events:
		match ev["type"]:
			DuelRecord.TELL_START:
				expected = ev["heights"]
				index = 0
				tells += 1
				if int(ev["height"]) != int(expected[0]):
					errs.append("TELL_START의 height가 heights[0]과 다름")
			DuelRecord.STRIKE:
				if index >= expected.size() or int(ev["height"]) != int(expected[index]):
					errs.append("%.2f초 타격의 높이가 예비 동작의 값과 다름" % float(ev["t"]))
				index += 1
			DuelRecord.PATTERN_STEP:
				if index >= expected.size() or int(ev["height"]) != int(expected[index]):
					errs.append("%.2f초 걸음의 높이가 예비 동작의 값과 다름" % float(ev["t"]))
	if tells < 10:
		errs.append("한 판의 예비 동작 %d번 (10번 이상이어야 견줌이 뜻이 있다)" % tells)
	# 3. 난수 불변: 높이 없음(A), 크기 1인 묶음(B), 크기 2인 묶음을 끈 상대(C)의 시각이 같다.
	var no_heights: Array[int] = []
	var one: Array[int] = [DT.Height.MID]
	var two: Array[int] = [DT.Height.MID, DT.Height.LOW]
	var runs: Array = []
	for heights: Array[int] in [no_heights, one, two]:
		var opp: OpponentData = _p._opp(_atk(DT.Direction.RIGHT, 0.9, 0.6, heights))
		opp.idle_time_max = 1.6
		if heights.size() == 2:
			opp.use_heights = false
		var run: DuelCore = _p._run(opp, {}, 20.0)
		runs.append([_p._times(run.record.of_type(DuelRecord.TELL_START)), _p._times(_strikes(run))])
	if runs[0] != runs[1] or runs[0] != runs[2] or (runs[0][0] as Array).size() < 5:
		errs.append("높이를 뽑지 않는 상대들의 시각이 서로 다름(난수 차례가 바뀜)")
	# 4. 가방: 변주가 있는 공격도 한 장이다.
	var bag_opp: OpponentData = _p._opp(_varied())
	bag_opp.attack_bag_sets = 1
	var bag_rng := RandomNumberGenerator.new()
	bag_rng.seed = 3
	var bag_brain := OpponentBrain.new(bag_opp, bag_rng)
	bag_brain.start_tell(0.0, false)
	if bag_brain.bag_remaining() != 0:
		errs.append("변주가 있는 공격 하나의 가방에 %d장이 남음(기대 0)" % bag_brain.bag_remaining())
	return "OK" if errs.is_empty() else ", ".join(errs)


## 한 길(뿌리와 걸음)의 타격들.
func _points(root: AttackData) -> Array[AttackData]:
	var out: Array[AttackData] = [root]
	for step: AttackData in root.chain:
		out.append(step)
	return out


## 공격 하나의 길들: 바탕과 변주.
func _lines(base: AttackData) -> Array[AttackData]:
	var out: Array[AttackData] = [base]
	for variant: AttackData in base.variants:
		out.append(variant)
	return out


func _check_line(errs: Array[String], opp: OpponentData, base: AttackData, line: AttackData, weapon: WeaponData, label: String) -> void:
	var points := _points(line)
	var with_height := 0
	for point in points:
		for h in point.heights:
			if h < 0 or h > 2:
				errs.append("%s: 높이 값 %d" % [label, h])
		if not point.heights.is_empty():
			with_height += 1
		if line.sweep and point.heights.size() > 1:
			errs.append("%s: 휩쓸기의 점이 높이를 둘 이상 가짐" % label)
	if with_height != 0 and with_height != points.size():
		errs.append("%s: 높이가 있는 타격과 없는 타격이 섞임" % label)
	if line != base:
		if line.attack_name != base.attack_name or line.is_big != base.is_big or line.sweep != base.sweep \
				or line.chain.size() != base.chain.size() or not line.variants.is_empty():
			errs.append("%s: 변주가 바탕과 이름·큰 공격·휩쓸기·타격 수가 다르거나 변주를 또 가짐" % label)
	if not line.chain.is_empty():
		_p._check_pattern(errs, opp, line, weapon, label)
	if line.sweep:
		for i in range(1, points.size()):
			var dh := 0
			if not points[i].heights.is_empty() and not points[i - 1].heights.is_empty():
				dh = absi(points[i].heights[0] - points[i - 1].heights[0])
			if dh > 1:
				errs.append("%s: 휩쓸기의 이웃한 점이 높이로 두 칸 이상 떨어짐" % label)


func t85_trial_cells() -> String:
	var errs: Array[String] = []
	var weapon := load(WEAPON_PATH) as WeaponData
	var cell_sets: Array = []
	# 1·2. 하루의 상대의 칸과 변주.
	for path in DAY_PATHS:
		var opp := load(path) as OpponentData
		var label := path.get_file()
		var cells := {}
		var variant_count := 0
		var bases: Array[AttackData] = []
		bases.append_array(opp.attacks)
		for habit in opp.habits:
			if habit.response != null:
				bases.append(habit.response)
		for base in bases:
			variant_count += base.variants.size()
			for line in _lines(base):
				_check_line(errs, opp, base, line, weapon, "%s · %s" % [label, line.attack_name])
				for point in _points(line):
					for h in point.heights:
						cells[Vector2i(point.direction, h)] = true
		if variant_count == 0:
			errs.append("%s: 변주가 없음" % label)
		if cells.size() < 4:
			errs.append("%s: 쓰는 칸 %d개 (넷 이상)" % [label, cells.size()])
		var keys := cells.keys()
		keys.sort()
		cell_sets.append(str(keys))
		# 5. 막는 법의 글: 높이를 쓰는 상대에만 붙는다.
		if not DuelHud.help_text(opp).contains(DuelHud.HELP_HEIGHT) or DuelHud.help_text(opp.flat()).contains(DuelHud.HELP_HEIGHT):
			errs.append("%s: HELP_HEIGHT가 9칸에 없거나 가로만에 있음" % label)
	if cell_sets.size() == 2 and cell_sets[0] == cell_sets[1]:
		errs.append("두 상대가 쓰는 칸의 모음이 같음")
	# 3. 고리의 줄.
	var ring := OpponentView.RING_POSITION
	for d in 3:
		if OpponentView.ring_position(d, -1) != ring[d]:
			errs.append("높이 없는 고리의 자리가 바뀜(방향 %d)" % d)
		for h in 3:
			if OpponentView.ring_position(d, h) != Vector2(ring[d].x, OpponentView.RING_ROW_Y[h]):
				errs.append("고리의 자리 (%d, %d)" % [d, h])
	var chain: DuelCore = _p._run(_p._opp(_chain()), {}, 1.5)
	var marks := OpponentView.pattern_marks(chain.brain, chain.time)
	if marks.size() != 3 or marks[0]["pos"] != OpponentView.ring_position(DT.Direction.RIGHT, DT.Height.HIGH) \
			or marks[1]["pos"] != OpponentView.ring_position(DT.Direction.LEFT, DT.Height.LOW):
		errs.append("높이를 가진 번호 고리의 자리: %s" % str(marks))
	# 같은 방향·다른 높이는 비키지 않고, 같은 칸이 되풀이될 때만 비킨다.
	var repeat := _chain()
	(repeat.chain[0] as AttackData).direction = DT.Direction.RIGHT
	var same_cell: Array[int] = [DT.Height.HIGH]
	(repeat.chain[1] as AttackData).direction = DT.Direction.RIGHT
	(repeat.chain[1] as AttackData).heights = same_cell
	var repeat_run: DuelCore = _p._run(_p._opp(repeat), {}, 1.5)
	var repeat_marks := OpponentView.pattern_marks(repeat_run.brain, repeat_run.time)
	if repeat_marks.size() != 3 or repeat_marks[1]["pos"] != OpponentView.ring_position(DT.Direction.RIGHT, DT.Height.LOW) \
			or repeat_marks[2]["pos"] != OpponentView.ring_position(DT.Direction.RIGHT, DT.Height.HIGH) + Vector2(0, OpponentView.MARK_REPEAT_SHIFT):
		errs.append("되풀이 칸의 비킴: %s" % str(repeat_marks))
	# 4. 따라가는 점은 간격의 60%에 다음 점에 먼저 가 있다(첫 점 2.3, 간격 0.6).
	var sweep: DuelCore = _p._run(_p._opp(_sweep()), {}, 1.5)
	var early: Dictionary = OpponentView.pattern_marks(sweep.brain, 2.0)[3]
	var arrived: Dictionary = OpponentView.pattern_marks(sweep.brain, 2.3 + 0.6 * OpponentView.SWEEP_DOT_ARRIVE + 0.01)[3]
	var points: PackedVector2Array = early["points"]
	if not (early["dot"] as Vector2).is_equal_approx(points[0]) or not (arrived["dot"] as Vector2).is_equal_approx(points[1]):
		errs.append("따라가는 점: 처음 %s, 60%% 뒤 %s (점들 %s)" % [early["dot"], arrived["dot"], points])
	# 6. 연습 화면: 가로만 버튼은 없다(결정 428).
	var select: Node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	var flat_buttons := select.find_children("TrialFlat*", "Button", true, false).size()
	if flat_buttons != 0:
		errs.append("연습 화면의 가로만 버튼 %d개 (기대 0)" % flat_buttons)
	select.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


## 하루의 규칙(그 날의 확률)으로 코어를 만든다. 시드 1, 모자 없음.
func _day_core(opp: OpponentData, day_number: int) -> DuelCore:
	var day := DayState.new(EconomyRules.new(), DayData.new(), load(CATALOG_PATH) as UpgradeCatalog)
	day.day_number = day_number
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(day.effective_duel_rules(load(RULES_PATH) as DuelRules), weapon, opp, rng, none, false)
	return core


## 들고 막는 봇으로 seconds초까지 돌린다.
func _day_run(opp: OpponentData, seconds: float) -> DuelCore:
	var core := _day_core(opp, 1)
	var bot := Bot.new(core, {})
	core.step(1)
	while not core.ended and core.time < seconds:
		core.tick(1.0 / 60.0)
		bot.update()
	return core


func t91_day_patterns() -> String:
	var errs: Array[String] = []
	# 1. 데이터: 단발 셋 + 패턴 둘, 바르톨로는 이어 베기·브루노는 휩쓸기, 높이와 변주, 확률 0.8.
	for row: Array in [[DAY_PATHS[0], false], [DAY_PATHS[1], true]]:
		var opp := load(row[0]) as OpponentData
		var label: String = String(row[0]).get_file()
		var singles := 0
		var patterns := 0
		var sweeps := 0
		var variants := 0
		for atk in opp.attacks:
			variants += atk.variants.size()
			if atk.chain.is_empty():
				singles += 1
			else:
				patterns += 1
				sweeps += 1 if atk.sweep else 0
		if opp.attacks.size() != 5 or singles != 3 or patterns != 2 or sweeps != (2 if row[1] else 0):
			errs.append("%s: 공격 %d · 단발 %d · 패턴 %d · 휩쓸기 %d" % [label, opp.attacks.size(), singles, patterns, sweeps])
		if not DuelHud.uses_heights(opp) or variants < 1:
			errs.append("%s: 높이 %s · 변주 %d" % [label, str(DuelHud.uses_heights(opp)), variants])
		if not is_equal_approx(opp.opening_chance, 0.8):
			errs.append("%s: 빈틈의 확률 %.2f (기대 0.80)" % [label, opp.opening_chance])
	if DirAccess.dir_exists_absolute("res://data/opponents/trial"):
		errs.append("시험용 폴더가 남아 있음")
	# 2. 가방: 한 벌 7장(3 + 1 + 1 + 1 + 1), 첫 예비 동작에서 한 장을 꺼내면 6.
	var bag_core := _day_core(load(BARTOLO_PATH) as OpponentData, 1)
	bag_core.distance = DT.Distance.ENGAGE
	var guard := 0
	while guard < 3000 and bag_core.brain.state != DT.OpponentState.TELL:
		bag_core.tick(1.0 / 60.0)
		guard += 1
	if bag_core.brain.bag_remaining() != 6:
		errs.append("가방에 남은 장 %d (기대 6)" % bag_core.brain.bag_remaining())
	# 3. 하루의 판에 패턴과 높이가 나온다.
	var real := load(BARTOLO_PATH) as OpponentData
	var live := _day_run(real, 60.0)
	var tall := 0
	for ev in live.record.of_type(DuelRecord.TELL_START):
		if int(ev["height"]) >= 0:
			tall += 1
	if live.record.of_type(DuelRecord.PATTERN_STEP).is_empty() or tall < 1:
		errs.append("하루의 판: 패턴 걸음 %d · 높이가 있는 예비 동작 %d" % [live.record.of_type(DuelRecord.PATTERN_STEP).size(), tall])
	# 4. 옛 규칙 사본: 단발 셋, 높이·패턴·확률 없음. 원본은 그대로.
	var plain := Plain.of(real)
	var all_single := true
	for atk in plain.attacks:
		all_single = all_single and atk.chain.is_empty()
	if plain.attacks.size() != 3 or not all_single or plain.use_heights or not is_equal_approx(plain.opening_chance, 1.0) \
			or plain.habits.size() != 1:
		errs.append("옛 규칙 사본: 공격 %d · 높이 %s · 확률 %.2f · 버릇 %d" % [plain.attacks.size(), str(plain.use_heights), plain.opening_chance, plain.habits.size()])
	if real.attacks.size() != 5 or not real.use_heights or not is_equal_approx(real.opening_chance, 0.8):
		errs.append("사본을 만든 뒤 원본이 바뀜: 공격 %d · 높이 %s · 확률 %.2f" % [real.attacks.size(), str(real.use_heights), real.opening_chance])
	var old := _day_run(plain, 60.0)
	var raised := 0
	for ev in old.record.of_type(DuelRecord.TELL_START):
		if int(ev["height"]) != -1:
			raised += 1
	if not old.record.of_type(DuelRecord.PATTERN_STEP).is_empty() or raised != 0 or old.record.count_where(DuelRecord.STRIKE, "closed", true) != 0:
		errs.append("옛 규칙 사본의 판: 패턴 걸음 %d · 높이가 있는 예비 동작 %d · 안 열린 타격 %d" % [
			old.record.of_type(DuelRecord.PATTERN_STEP).size(), raised, old.record.count_where(DuelRecord.STRIKE, "closed", true)])
	if Plain.of(load(DAY_PATHS[1]) as OpponentData).attacks.size() != 3:
		errs.append("브루노의 옛 규칙 사본 공격 수가 3이 아님")
	# 5. 안내: 바르톨로는 이어 베기와 높이, 브루노는 휩쓸기와 높이. 도움말 화면과 오르솔라의 사연.
	var help := DuelHud.help_text(real)
	if not help.contains(DuelHud.HELP_CHAIN) or not help.contains(DuelHud.HELP_HEIGHT) or help.contains(DuelHud.HELP_SWEEP):
		errs.append("바르톨로의 막는 법 글: \"%s\"" % help)
	var bruno_help := DuelHud.help_text(load(DAY_PATHS[1]) as OpponentData)
	if not bruno_help.contains(DuelHud.HELP_SWEEP) or not bruno_help.contains(DuelHud.HELP_HEIGHT):
		errs.append("브루노의 막는 법 글: \"%s\"" % bruno_help)
	var screen := "\n".join(PackedStringArray(Title.help_groups()))
	if not screen.contains("번호 차례대로") or not screen.contains("고리가 뜬 칸"):
		errs.append("도움말 화면에 이어 베기나 높이의 글이 없음")
	if not (load(LEGS_ONLY_PATH) as Commission).dialogue.contains("휩쓸"):
		errs.append("오르솔라의 사연에 휩쓸기의 귀띔이 없음")
	# 6. 연습의 줄: 하루의 상대 둘, 그림 데이터는 섞이지 않는다.
	var trials := Select.load_trials()
	if trials.size() != 2 or trials[0].resource_path != DAY_PATHS[0] or trials[1].resource_path != DAY_PATHS[1]:
		errs.append("연습의 상대 %d명" % trials.size())
	var select: Node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	var counts := [
		select.find_children("TrialDuel*", "Button", true, false).size(),
		select.find_children("PatternDrill*", "Button", true, false).size(),
		select.find_children("TrialFlat*", "Button", true, false).size(),
		select.find_children("OpeningDay*", "Button", true, false).size(),
	]
	if counts != [2, 4, 0, 4]:
		errs.append("연습 화면의 버튼 (자유 결투·패턴만·가로만·빈틈) %s (기대 [2, 4, 0, 4])" % str(counts))
	select.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
