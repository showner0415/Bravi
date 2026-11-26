extends RefCounted
## T79~T81: 공격 패턴(계획 036). 이어 베기, 휩쓸기, 하루의 상대의 패턴과 연습의 길.
## 손 셈(멀리에서 0초에 전진): 교전 0.3 → 대기 1.0 → 예비 시작 1.3. 이어 베기 0.9 → 0.75 → 0.65, 휩쓸기 1.0 → 0.6 → 0.6.

const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const DAY_OPPONENTS: Array[String] = [BARTOLO_PATH, BRUNO_PATH, LORENZO_PATH]
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const DELTAS: Array[float] = [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0]
const EPS := 1e-6
## 결정 375의 하한.
const MIN_STEP_GAP := 0.55
const MIN_ROOT_TELL := 0.75

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T79", "name": "이어 베기: 걸음의 시각·막힘·끊김·패리·큰 공격·버티기·단발 회귀", "fn": t79_chain},
		{"id": "T80", "name": "휩쓸기: 쥐고 끌면 막힘, 패리 없음, 떼면 뚫림", "fn": t80_sweep},
		{"id": "T81", "name": "하루의 상대의 패턴·패턴만 상대·번호 고리의 자리·연습의 길", "fn": t81_trial},
	]


func cleanup() -> void:
	_tree = null


func _atk(direction: int, tell: float, recovery := 0.0) -> AttackData:
	var a := AttackData.new()
	a.attack_name = "시험"
	a.direction = direction
	a.tell_time = tell
	a.recovery_time = recovery
	return a


## 대기 1.0초 고정, 버릇·가방 없음, 공격은 pattern 하나인 상대. 로드한 자원은 고치지 않는다.
func _opp(pattern: AttackData) -> OpponentData:
	var o := (load(BARTOLO_PATH) as OpponentData).drill(pattern)
	# 다른 규칙을 보는 테스트다: 빈틈의 확률은 끈다(결정 416). 하루의 판 길이는 T90.
	o.opening_chance = 1.0
	o.idle_time_min = 1.0
	o.idle_time_max = 1.0
	return o


func _chain(big := false, raised := false) -> AttackData:
	var root := _atk(DT.Direction.RIGHT, 0.9, 1.2)
	root.is_big = big
	root.needs_raised_guard = raised
	var steps: Array[Resource] = [_atk(DT.Direction.LEFT, 0.75), _atk(DT.Direction.CENTER, 0.65)]
	root.chain = steps
	return root


func _sweep() -> AttackData:
	var root := _atk(DT.Direction.LEFT, 1.0, 1.6)
	root.is_big = true
	root.sweep = true
	var steps: Array[Resource] = [_atk(DT.Direction.CENTER, 0.6), _atk(DT.Direction.RIGHT, 0.6)]
	root.chain = steps
	return root


## 0초에 전진하고 until초까지 돌린다. 봇과 코어를 돌려준다.
func _run(opp: OpponentData, cfg: Dictionary, until: float, delta := 1.0 / 60.0) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(load(RULES_PATH), weapon, opp, rng, none, false)
	var bot := Bot.new(core, cfg)
	core.step(1)
	while not core.ended and core.time < until:
		core.tick(delta)
		# guard_at: 그 시각을 지난 첫 tick에 오른쪽을 막는다(봇의 &"keep"은 이미 든 막기를 그대로 둔다).
		if cfg.has("guard_at") and core.time >= float(cfg["guard_at"]) and not core.guard_held:
			core.set_aim(DT.Direction.RIGHT, DT.Height.MID)
			core.set_guard(true)
		bot.update()
	return core


func _times(events: Array) -> Array[float]:
	var out: Array[float] = []
	for ev: Dictionary in events:
		out.append(float(ev["t"]))
	return out


func _expect_times(errs: Array[String], got: Array[float], want: Array[float], label: String) -> void:
	if got.size() != want.size():
		errs.append("%s: 시각 %d개 (기대 %d개) %s" % [label, got.size(), want.size(), str(got)])
		return
	for i in got.size():
		if absf(got[i] - want[i]) > EPS:
			errs.append("%s: %d번째 %.6f (기대 %.6f)" % [label, i + 1, got[i], want[i]])


## 타격들의 결과가 want와 차례대로 같은가.
func _is(strikes: Array, want: Array) -> bool:
	if strikes.size() != want.size():
		return false
	for i in strikes.size():
		if int(strikes[i]["result"]) != int(want[i]):
			return false
	return true


func _results(strikes: Array) -> Array[int]:
	var out: Array[int] = []
	for ev: Dictionary in strikes:
		out.append(int(ev["result"]))
	return out


func t79_chain() -> String:
	var errs: Array[String] = []
	var SR := DT.StrikeResult
	# 1·2. 누른 채 옮기는 봇: 셋 다 막힘, 시각이 delta와 무관하다.
	for delta in DELTAS:
		var core := _run(_opp(_chain()), {}, 4.75, delta)
		var strikes := core.record.of_type(DuelRecord.STRIKE)
		var steps := core.record.of_type(DuelRecord.PATTERN_STEP)
		_expect_times(errs, _times(strikes), [2.2, 2.95, 3.6], "막기 delta %.4f" % delta)
		if core.record.of_type(DuelRecord.TELL_START).size() != 1 or steps.size() != 2:
			errs.append("TELL_START %d · PATTERN_STEP %d (기대 1 · 2)" % [core.record.of_type(DuelRecord.TELL_START).size(), steps.size()])
		if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]):
			errs.append("막기: 결과 %s" % str(_results(strikes)))
		if strikes.size() == 3 and steps.size() == 2:
			if not is_zero_approx(strikes[0]["recovery"]) or absf(float(strikes[0]["next_strike"]) - 2.95) > EPS \
					or absf(float(strikes[1]["next_strike"]) - 3.6) > EPS:
				errs.append("앞 두 타격의 recovery·next_strike가 어긋남")
			if absf(float(strikes[2]["recovery"]) - 1.2) > EPS or float(strikes[2]["next_strike"]) >= 0.0:
				errs.append("마지막 타격의 recovery %.3f · next_strike %.3f" % [strikes[2]["recovery"], strikes[2]["next_strike"]])
			if int(steps[0]["index"]) != 1 or int(steps[1]["index"]) != 2 or int(steps[0]["count"]) != 3:
				errs.append("PATTERN_STEP의 index·count가 어긋남")
		if core.brain.state != DT.OpponentState.RECOVERY or core.brain.wide_open or core.brain.blocked_streak != 1 \
				or absf(core.brain.state_end - 4.8) > EPS:
			errs.append("끝: 상태 %d, 크게 열림 %s, 연속 막힘 %d, 회수 끝 %.3f" % [
				core.brain.state, core.brain.wide_open, core.brain.blocked_streak, core.brain.state_end])
	# 3. 둘째 타격만 틀린 방향: 그 한 번만 맞고 패턴이 끝난다.
	var wrong_second := func(_a: AttackData, index: int) -> StringName: return &"wrong" if index == 1 else &"hold"
	var hit := _run(_opp(_chain()), {"step_fn": wrong_second}, 3.4)
	var hit_strikes := hit.record.of_type(DuelRecord.STRIKE)
	if not _is(hit_strikes, [SR.BLOCKED, SR.GRAZE]) or hit.brain.state != DT.OpponentState.IDLE \
			or hit.player_posture != hit.rules.player_posture_max - 1:
		errs.append("둘째를 놓침: 결과 %s, 상대 상태 %d, 내 자세 %d" % [str(_results(hit_strikes)), hit.brain.state, hit.player_posture])
	# 4. 박자마다 새로 누르는 봇: 셋 다 패리, 마지막 뒤에 크게 열린다.
	var all_parry := func(_a: AttackData, _i: int) -> StringName: return &"parry"
	var parry := _run(_opp(_chain()), {"guard_fn": all_parry}, 3.7)
	var parry_strikes := parry.record.of_type(DuelRecord.STRIKE)
	var bonus := (load(BARTOLO_PATH) as OpponentData).parried_recovery_bonus
	if not _is(parry_strikes, [SR.PARRIED, SR.PARRIED, SR.PARRIED]) or not parry.brain.wide_open:
		errs.append("패리: 결과 %s, 크게 열림 %s" % [str(_results(parry_strikes)), parry.brain.wide_open])
	elif absf(float(parry_strikes[2]["recovery"]) - (1.2 + bonus)) > EPS:
		errs.append("패리: 마지막 회수 %.3f (기대 %.3f)" % [parry_strikes[2]["recovery"], 1.2 + bonus])
	# 5. 큰 공격인 패턴을 다 막으면 크게 열린다. 걸음 동안은 버티기가 아니다. 버틴 첫 타격은 패턴을 끝낸다.
	var big := _run(_opp(_chain(true)), {}, 3.7)
	if not big.brain.wide_open:
		errs.append("큰 공격 패턴을 다 막았는데 크게 열리지 않음")
	var raised := _run(_opp(_chain(false, true)), {}, 2.5)
	if raised.brain.step_index != 1 or raised.would_brace_now():
		errs.append("올려 막기 뿌리: 걸음 %d, 걸음 동안 버티기 %s" % [raised.brain.step_index, raised.would_brace_now()])
	# 예비 동작 전부터 들고만 있던 막기로 받으면 버티기이고, 버틴 첫 타격은 단발처럼 패턴을 끝낸다.
	var keep := func(_a: AttackData, _i: int) -> StringName: return &"keep"
	var braced := _run(_opp(_chain(false, true)), {"guard_fn": keep, "guard_at": 1.0}, 2.5)
	var braced_strikes := braced.record.of_type(DuelRecord.STRIKE)
	if braced_strikes.size() != 1 or not braced_strikes[0]["braced"] or float(braced_strikes[0]["next_strike"]) >= 0.0 \
			or not braced.record.of_type(DuelRecord.PATTERN_STEP).is_empty():
		errs.append("버틴 첫 타격 뒤에 패턴이 끝나지 않음")
	var retreat := func(_a: AttackData, _i: int) -> StringName: return &"retreat"
	var whiff := _run(_opp(_chain()), {"guard_fn": retreat}, 2.4)
	if not _is(whiff.record.of_type(DuelRecord.STRIKE), [SR.WHIFF]) or not whiff.record.of_type(DuelRecord.PATTERN_STEP).is_empty():
		errs.append("물러났는데 첫 타격이 헛침으로 끝나지 않음")
	# 6. 단발 회귀: chain이 비면 걸음이 없고 next_strike가 -1이다.
	var single := _run(_opp(_atk(DT.Direction.RIGHT, 0.9, 1.2)), {}, 2.4)
	var single_strikes := single.record.of_type(DuelRecord.STRIKE)
	if single_strikes.size() != 1 or float(single_strikes[0]["next_strike"]) >= 0.0 \
			or not single.record.of_type(DuelRecord.PATTERN_STEP).is_empty() or absf(float(single_strikes[0]["recovery"]) - 1.2) > EPS:
		errs.append("단발: 타격 %d개 또는 걸음이 생김" % single_strikes.size())
	return "OK" if errs.is_empty() else ", ".join(errs)


func t80_sweep() -> String:
	var errs: Array[String] = []
	var SR := DT.StrikeResult
	# 1·4. 쥐고 끄는 봇: 셋 다 막힘, 패리 없음, 시각이 delta와 무관하다.
	for delta in DELTAS:
		var core := _run(_opp(_sweep()), {}, 5.0, delta)
		var strikes := core.record.of_type(DuelRecord.STRIKE)
		_expect_times(errs, _times(strikes), [2.3, 2.9, 3.5], "휩쓸기 delta %.4f" % delta)
		if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]) or not core.brain.wide_open \
				or absf(core.brain.state_end - 5.1) > EPS:
			errs.append("쥐고 끌기: 결과 %s, 크게 열림 %s, 회수 끝 %.3f" % [str(_results(strikes)), core.brain.wide_open, core.brain.state_end])
	var mid := _run(_opp(_sweep()), {}, 2.5)
	if mid.brain.step_index != 1 or not mid.brain.is_sweep() or mid.would_brace_now():
		errs.append("휩쓸기의 걸음: 번호 %d, 버티기 %s" % [mid.brain.step_index, mid.would_brace_now()])
	# 2. 새로 눌러도 패리가 아니고, 떼었다 다시 누르면 그 점에서 뚫린다.
	var all_parry := func(_a: AttackData, _i: int) -> StringName: return &"parry"
	var parry := _run(_opp(_sweep()), {"guard_fn": all_parry}, 3.3)
	var parry_strikes := parry.record.of_type(DuelRecord.STRIKE)
	if not _is(parry_strikes, [SR.BLOCKED, SR.GRAZE]):
		errs.append("떼었다 누름: 결과 %s (기대 막힘 뒤 스침)" % str(_results(parry_strikes)))
	elif int(parry_strikes[1]["situation"]) != DT.Situation.WRONG_GUARD:
		errs.append("떼었다 누른 점의 상황 %d" % parry_strikes[1]["situation"])
	# 3. 셋째 점만 틀린 방향이면 셋째에서 맞는다.
	var wrong_last := func(_a: AttackData, index: int) -> StringName: return &"wrong" if index == 2 else &"hold"
	var late := _run(_opp(_sweep()), {"step_fn": wrong_last}, 3.8)
	if not _is(late.record.of_type(DuelRecord.STRIKE), [SR.BLOCKED, SR.BLOCKED, SR.GRAZE]):
		errs.append("셋째를 놓침: 결과 %s" % str(_results(late.record.of_type(DuelRecord.STRIKE))))
	return "OK" if errs.is_empty() else ", ".join(errs)


func _arm_keys(opp: OpponentData) -> Array[StringName]:
	var keys: Array[StringName] = [&"Arm"]
	for arm_art in opp.art.arm_arts:
		keys.append(arm_art.key)
	return keys


func _check_pattern(errs: Array[String], opp: OpponentData, root: AttackData, weapon: WeaponData, label: String) -> void:
	var count := 1 + root.chain.size()
	if count < 2 or count > 4:
		errs.append("%s: 타격 %d개 (2~4)" % [label, count])
	if root.tell_time < MIN_ROOT_TELL - EPS:
		errs.append("%s: 뿌리 예비 %.2f (하한 %.2f)" % [label, root.tell_time, MIN_ROOT_TELL])
	# 올려 막기는 단발에만 쓴다(버티기와 이어 치기가 섞이지 않게. 기술 검토의 제안).
	if root.needs_raised_guard:
		errs.append("%s: 패턴의 뿌리가 올려 막기 공격임" % label)
	var gap := maxf(MIN_STEP_GAP, weapon.guard_cooldown + weapon.parry_window)
	var keys := _arm_keys(opp)
	var prev := root
	for step: AttackData in root.chain:
		if step.tell_time < gap - EPS:
			errs.append("%s: 걸음 간격 %.2f (하한 %.2f)" % [label, step.tell_time, gap])
		if root.sweep and absi(int(step.direction) - int(prev.direction)) != 1:
			errs.append("%s: 휩쓸기의 이웃한 점이 한 칸 차가 아님" % label)
		if not step.chain.is_empty():
			errs.append("%s: 걸음이 또 걸음을 가짐" % label)
		prev = step
	var all: Array[AttackData] = [root]
	for step: AttackData in root.chain:
		all.append(step)
	for atk in all:
		for pose: PoseData in [atk.tell_pose, atk.strike_pose]:
			if pose == null or not keys.has(pose.arm_art):
				errs.append("%s: 포즈가 없거나 그 상대에 없는 팔 그림" % label)


func t81_trial() -> String:
	var errs: Array[String] = []
	var weapon := load(WEAPON_PATH) as WeaponData
	var pattern_total := 0
	# 1·2·3. 하루의 상대: 단발 셋이 앞에, 패턴이 뒤에. 패턴은 하한 안이다. 패턴만 상대는 원본을 고치지 않는다.
	for trial_path: String in DAY_OPPONENTS:
		var trial := load(trial_path) as OpponentData
		var label := trial_path.get_file()
		if trial == null:
			errs.append("%s: 로드되지 않음" % label)
			continue
		var patterns: Array[AttackData] = []
		var dives := 0
		var seen_pattern := false
		for i in trial.attacks.size():
			if trial.attacks[i].chain.is_empty() and not trial.attacks[i].dive:
				if seen_pattern:
					errs.append("%s: 단발 %d가 패턴 뒤에 있음" % [label, i])
			else:
				seen_pattern = true
				if trial.attacks[i].dive:
					dives += 1
				else:
					patterns.append(trial.attacks[i])
		var singles := trial.attacks.size() - patterns.size() - dives
		if singles != 3:
			errs.append("%s: 단발 %d개 (기대 3)" % [label, singles])
		if patterns.is_empty() and dives == 0:
			errs.append("%s: 패턴도 뛰어들기도 없음" % label)
		for root in patterns:
			_check_pattern(errs, trial, root, weapon, "%s · %s" % [label, root.attack_name])
			var before := trial.attacks.size()
			var drill := trial.drill(root)
			if drill.attacks.size() != 1 or drill.attacks[0] != root or not drill.habits.is_empty() or drill.attack_bag_sets != 0 \
					or trial.attacks.size() != before or drill.display_name != trial.display_name or drill.art != trial.art:
				errs.append("%s · %s: 패턴만 상대가 어긋남" % [label, root.attack_name])
		pattern_total += patterns.size() + dives
	# 4. 번호 고리의 자리.
	var ring := OpponentView.RING_POSITION
	var start := _run(_opp(_chain()), {}, 1.5)
	var marks := OpponentView.pattern_marks(start.brain, start.time)
	if marks.size() != 3 or marks[0]["role"] != &"now" or marks[1]["role"] != &"next" or marks[2]["role"] != &"later" \
			or marks[0]["pos"] != ring[DT.Direction.RIGHT] or marks[1]["pos"] != ring[DT.Direction.LEFT] \
			or marks[2]["pos"] != ring[DT.Direction.CENTER] or int(marks[2]["number"]) != 3:
		errs.append("번호 고리(예비 시작): %s" % str(marks))
	var after := _run(_opp(_chain()), {}, 2.5)
	var later := OpponentView.pattern_marks(after.brain, after.time)
	if later.size() != 2 or int(later[0]["number"]) != 2 or later[0]["role"] != &"now":
		errs.append("번호 고리(첫 타격 뒤): %s" % str(later))
	var again := _chain()
	(again.chain[1] as AttackData).direction = DT.Direction.RIGHT
	var repeat := _run(_opp(again), {}, 1.5)
	var repeat_marks := OpponentView.pattern_marks(repeat.brain, repeat.time)
	if repeat_marks.size() != 3 or repeat_marks[2]["pos"] != ring[DT.Direction.RIGHT] + Vector2(0, OpponentView.MARK_REPEAT_SHIFT):
		errs.append("되풀이 방향의 고리가 아래로 비키지 않음")
	var sweep := _run(_opp(_sweep()), {}, 1.5)
	var sweep_marks := OpponentView.pattern_marks(sweep.brain, sweep.time)
	if sweep_marks.size() != 4 or sweep_marks[3]["role"] != &"path" or (sweep_marks[3]["points"] as PackedVector2Array).size() != 3 \
			or sweep_marks[3]["dot"] != ring[DT.Direction.LEFT]:
		errs.append("휩쓸기의 길 표시: %s" % str(sweep_marks))
	var single := _run(_opp(_atk(DT.Direction.RIGHT, 0.9, 1.2)), {}, 1.5)
	if not OpponentView.pattern_marks(single.brain, single.time).is_empty() or single.brain.state != DT.OpponentState.TELL:
		errs.append("단발 예비 동작에 번호 고리가 있음")
	if not OpponentView.pattern_marks(after.brain, 99.0).size() == 2:
		errs.append("번호 고리가 표시 시각에 따라 수가 바뀜")
	# 5. 결투 씬: 연습의 상대는 의뢰가 없을 때만 쓴다.
	var trial_opp := load(BRUNO_PATH) as OpponentData
	for with_commission: bool in [false, true]:
		var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
		var commission := load("res://data/commissions/first_blood.tres") as Commission
		duel.set("practice_opponent", trial_opp)
		if with_commission:
			duel.set("commission", commission)
		duel.set("mouse_aim_enabled", false)
		duel.set("rng_seed", 1)
		_tree.root.add_child(duel)
		var used: OpponentData = (duel.get("core") as DuelCore).opponent_data
		var want: OpponentData = commission.opponent if with_commission else trial_opp
		if used != want:
			errs.append("결투 씬의 상대가 어긋남(의뢰 %s)" % with_commission)
		duel.free()
	# 6. 연습 화면: 시험용 상대마다 자유 결투, 패턴마다 패턴만, 의뢰 카드는 그대로.
	var select: Node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	var free_buttons := select.find_children("TrialDuel*", "Button", true, false).size()
	var drill_buttons := select.find_children("PatternDrill*", "Button", true, false).size()
	var cards := 0
	for button: Button in select.find_children("*", "Button", true, false):
		if button.text == "이 의뢰를 맡는다":
			cards += 1
	if free_buttons != DAY_OPPONENTS.size() or drill_buttons != pattern_total or cards != 3:
		errs.append("연습 화면: 자유 결투 %d · 패턴만 %d(기대 %d) · 의뢰 카드 %d" % [free_buttons, drill_buttons, pattern_total, cards])
	select.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
