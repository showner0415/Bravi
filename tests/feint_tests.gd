extends RefCounted
## T134: 지킴의 골든(계획 044 결정 679). 코드를 고치기 전에 적은 이벤트 줄의 SHA-256이 고친 뒤에도 같다.
## T135: 헛손질의 규칙(결정 669~671 · 677 · 680). 시험 상대는 바르톨로의 사본에 손으로 만든 속임 길 둘이다(데이터 opponent_06과 무관).

const Digest := preload("res://tests/event_digest.gd")
const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
## 두 틱 + 여유: 타격 사이의 간격은 판정 틱에 얹힌다.
const TIME_TOL := 0.04
const ROOT_RECOVERY := 1.2
const FEINT_GAP := 0.65

var _f: Fourth = Fourth.new()


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T134", "name": "이벤트 줄의 지킴: 골든의 줄을 도구와 같은 digest_row로 다시 셈해 견준다(데이터가 바뀐 줄은 건너뛰고, 모두 건너뛰면 실패)", "fn": t134_event_digest},
		{"id": "T135", "name": "헛손질의 규칙: 판정 없이 넘어가고, 그 칸을 막고 있으면 속아서 그 패턴의 빈틈이 0, 속지 않으면 뿌리의 빈틈, 멀리 · 봐줌 · 요약 · 테두리", "fn": t135_feint_rules},
	]


func t134_event_digest() -> String:
	var golden := Digest.read_golden()
	if golden.is_empty():
		return "골든 파일 %s가 없거나 비었다 — tests/run_event_digest.ps1 -Write로 쓴다" % Digest.GOLDEN_PATH
	var result := Digest.check(golden)
	print("  INFO T134 골든 %d줄, 건너뜀 %d줄" % [int(result["rows"]), int(result["skipped"])])
	for message: String in result["messages"]:
		if message.begins_with("  INFO"):
			print(message)
	if bool(result["ok"]):
		return "OK"
	var diffs: Array = result["diffs"]
	return "; ".join(PackedStringArray(diffs))


# ================================================================ T135 도우미

func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.02


## 시험 타격 하나. 헛손질의 길은 이 타격을 손으로 이어 만든다(로드한 자원을 고치지 않는다).
func _strike(direction: int, tell: float, heights: Array, feint: bool, recovery := 0.0) -> AttackData:
	var atk := AttackData.new()
	atk.attack_name = "속임 베기"
	atk.direction = direction as DuelTypes.Direction
	atk.tell_time = tell
	atk.recovery_time = recovery
	atk.feint = feint
	for h: int in heights:
		atk.heights.append(h)
	return atk


## 길 A: 헛 왼상 -> 오중 (헛손질이 뿌리).
func _route_a() -> AttackData:
	var root := _strike(DT.Direction.LEFT, 0.9, [DT.Height.HIGH], true, ROOT_RECOVERY)
	var chain: Array[Resource] = [_strike(DT.Direction.RIGHT, FEINT_GAP, [DT.Height.MID], false)]
	root.chain = chain
	return root


## 길 B: 왼중 -> 헛 가상 -> 오하 (헛손질이 가운데).
func _route_b() -> AttackData:
	var root := _strike(DT.Direction.LEFT, 0.9, [DT.Height.MID], false, ROOT_RECOVERY)
	var chain: Array[Resource] = [
		_strike(DT.Direction.CENTER, 0.6, [DT.Height.HIGH], true),
		_strike(DT.Direction.RIGHT, FEINT_GAP, [DT.Height.LOW], false),
	]
	root.chain = chain
	return root


func _bartolo() -> OpponentData:
	return load(BARTOLO_PATH) as OpponentData


## 봇의 설정: 첫 예비 동작의 모드와 속는가(bite_fn). extra의 키가 덮는다.
func _cfg(mode: StringName, bite: bool, extra := {}) -> Dictionary:
	var cfg: Dictionary = {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return mode}
	if bite:
		cfg["bite_fn"] = func(_a: AttackData) -> bool: return true
	for key in extra:
		cfg[key] = extra[key]
	return cfg


## 0초에 한 걸음 들어가 교전에서 시작한다(Fourth._play와 같다). 틱마다 봇 뒤에 hook(core)을 부른다.
func _run(route: AttackData, cfg: Dictionary, stop: Callable, until: float, hook := Callable()) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(_f._rules(), weapon, _f._drill_opp(_bartolo(), route), rng, none, false)
	var bot := Bot.new(core, cfg)
	core.step(1)
	while not core.ended and core.time < until:
		core.tick(DELTA)
		bot.update()
		if hook.is_valid():
			hook.call(core)
		if stop.call(core):
			break
	return core


func _feints(core: DuelCore) -> Array[Dictionary]:
	return core.record.of_type(DuelRecord.FEINT)


func _strikes_of(core: DuelCore) -> Array[Dictionary]:
	return core.record.of_type(DuelRecord.STRIKE)


## 타격 하나의 결과 · 빈틈 · bitten 열쇠를 견준다.
func _expect_strike(errs: Array[String], label: String, ev: Dictionary, result: int, recovery: float, bitten: bool) -> void:
	if int(ev["result"]) != result:
		errs.append("[%s] 결과 %d (기대 %d)" % [label, int(ev["result"]), result])
	if not _near(float(ev["recovery"]), recovery):
		errs.append("[%s] 빈틈 %.2f (기대 %.2f)" % [label, float(ev["recovery"]), recovery])
	if ev.has("bitten") != bitten or (bitten and ev["bitten"] != true):
		errs.append("[%s] bitten 열쇠 %s (기대 %s)" % [label, str(ev.get("bitten", "없음")), "참" if bitten else "없음"])


## 공격 판정(ATTACK)이 나면 멈춘다.
func _stop_attack_judged() -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.ATTACK).size() >= 1


## 첫 타격 뒤 delay초에 한 번 공격을 누른다. shot은 누른 표시다.
func _press_hook(delay: float, shot: Dictionary) -> Callable:
	return func(core: DuelCore) -> void:
		var seen := core.record.of_type(DuelRecord.STRIKE)
		if shot.has("done") or seen.is_empty():
			return
		if core.time >= float(seen[0]["t"]) + delay:
			shot["done"] = true
			core.press_attack()


# ================================================================ T135 헛손질의 규칙

func t135_feint_rules() -> String:
	var errs: Array[String] = []
	_t135_a_route(errs)
	_t135_parry(errs)
	_t135_mid_route(errs)
	_t135_not_bitten(errs)
	_t135_far_and_rash(errs)
	_t135_reset_and_plain(errs)
	_t135_frame(errs)
	_t135_summary(errs)
	return "OK" if errs.is_empty() else ", ".join(errs)


## (가)(나)(라) 길 A: 진짜의 칸을 쥔 손 / 헛손질의 칸을 쥔 손 / 속고 옮기지 않은 손.
func _t135_a_route(errs: Array[String]) -> void:
	var SR := DT.StrikeResult
	var kept := _run(_route_a(), _cfg(&"hold", false), _f._stop_strikes(1), 30.0)
	var feints := _feints(kept)
	var strikes := _strikes_of(kept)
	if feints.size() != 1 or strikes.size() != 1:
		errs.append("[가] 헛손질 %d · 타격 %d (기대 1 · 1)" % [feints.size(), strikes.size()])
		return
	if feints[0]["bitten"] != false or int(feints[0]["index"]) != 0 or int(feints[0]["height"]) != DT.Height.HIGH:
		errs.append("[가] FEINT bitten %s · index %d · height %d (기대 거짓 · 0 · 0)" % [str(feints[0]["bitten"]), int(feints[0]["index"]), int(feints[0]["height"])])
	if float(strikes[0]["t"]) <= float(feints[0]["t"]) or (strikes[0]["attack"] as AttackData).feint:
		errs.append("[가] STRIKE가 헛손질의 시각에 났다 (타격 %.2f · 헛손질 %.2f)" % [float(strikes[0]["t"]), float(feints[0]["t"])])
	if absf(float(feints[0]["next_strike"]) - (float(feints[0]["t"]) + FEINT_GAP)) > TIME_TOL:
		errs.append("[가] FEINT의 next_strike %.2f (기대 헛손질 %.2f + 0.65)" % [float(feints[0]["next_strike"]), float(feints[0]["t"])])
	var steps := kept.record.of_type(DuelRecord.PATTERN_STEP)
	if steps.size() != 1 or absf(float(steps[0]["strike_time"]) - (float(feints[0]["t"]) + FEINT_GAP)) > TIME_TOL:
		errs.append("[가] PATTERN_STEP %d개 · 다음 시각이 헛손질 + 0.65가 아니다" % steps.size())
	_expect_strike(errs, "가·쥔 손", strikes[0], SR.BLOCKED, ROOT_RECOVERY, false)
	if bool(strikes[0].get("closed", false)):
		errs.append("[가] 안 열림(closed)으로 났다")
	# (나) 헛손질의 칸을 쥐고 진짜의 칸으로 옮긴다.
	var bitten := _run(_route_a(), _cfg(&"hold", true), _f._stop_strikes(1), 30.0)
	feints = _feints(bitten)
	strikes = _strikes_of(bitten)
	if feints.size() != 1 or strikes.size() != 1:
		errs.append("[나] 헛손질 %d · 타격 %d (기대 1 · 1)" % [feints.size(), strikes.size()])
		return
	if feints[0]["bitten"] != true:
		errs.append("[나] FEINT bitten이 거짓이다")
	_expect_strike(errs, "나·속고 옮김", strikes[0], SR.BLOCKED, 0.0, true)
	if bool(strikes[0].get("closed", false)) or int(strikes[0]["closed_streak"]) != 0:
		errs.append("[나] closed %s · closed_streak %d (기대 거짓 · 0)" % [str(strikes[0].get("closed", false)), int(strikes[0]["closed_streak"])])
	if bitten.brain.state != DT.OpponentState.IDLE:
		errs.append("[나] 상대의 상태 %d (기대 대기 %d)" % [bitten.brain.state, DT.OpponentState.IDLE])
	# 봐줌: 그 뒤 0.3초의 공격은 섣부른 공격이 아니고, 봐주는 때(0.6초)가 지난 공격은 섣부르다.
	var grace := bitten.rules.closed_counter_grace
	for item: Array in [[0.3, false], [grace + 0.15, true]]:
		var shot := {}
		var late := _run(_route_a(), _cfg(&"hold", true), _stop_attack_judged(), 30.0, _press_hook(float(item[0]), shot))
		var starts := late.record.of_type(DuelRecord.ATTACK_START)
		if starts.size() != 1 or bool(starts[0]["rash"]) != bool(item[1]):
			errs.append("[나·%.2f초 뒤의 공격] rash %s (기대 %s)" % [float(item[0]), str(starts[0]["rash"]) if starts.size() == 1 else "공격 없음", str(item[1])])
		elif not bool(item[1]):
			var judged := late.record.of_type(DuelRecord.ATTACK)
			if judged.size() == 1 and int(judged[0]["posture_gain"]) != 0:
				errs.append("[나·0.3초 뒤의 공격] posture_gain %d (기대 0)" % int(judged[0]["posture_gain"]))
	# (라) 속고 옮기지 않으면(걸음에서 아무것도 안 한다) 진짜의 칸이 아니라 맞는다.
	var stayed := _run(_route_a(), _cfg(&"hold", true, {"step_fn": _f._step_only(1, &"stay")}), _f._stop_strikes(1), 30.0)
	strikes = _strikes_of(stayed)
	if strikes.size() != 1 or int(strikes[0]["result"]) != SR.GRAZE or int(strikes[0]["situation"]) != DT.Situation.WRONG_GUARD:
		errs.append("[라] 결과 %s (기대 스침 · WRONG_GUARD)" % (_f._result_text(strikes) if strikes.is_empty() else "%d · 상황 %d" % [int(strikes[0]["result"]), int(strikes[0]["situation"])]))


## (다) 패리: 속지 않고 진짜를 패리하면 패리의 빈틈, 속고 패리하면 0.
func _t135_parry(errs: Array[String]) -> void:
	var SR := DT.StrikeResult
	var bonus := _bartolo().parried_recovery_bonus
	var clean := _run(_route_a(), _cfg(&"parry", false), _f._stop_strikes(1), 30.0)
	var strikes := _strikes_of(clean)
	if strikes.size() != 1:
		errs.append("[다·속지 않음] 타격 %d개" % strikes.size())
	else:
		_expect_strike(errs, "다·속지 않고 패리", strikes[0], SR.PARRIED, ROOT_RECOVERY + bonus, false)
	var fooled := _run(_route_a(), _cfg(&"parry", true), _f._stop_strikes(1), 30.0)
	strikes = _strikes_of(fooled)
	if strikes.size() != 1:
		errs.append("[다·속음] 타격 %d개" % strikes.size())
	else:
		_expect_strike(errs, "다·속고 패리", strikes[0], SR.PARRIED, 0.0, true)
	var feints := _feints(fooled)
	if feints.size() != 1 or feints[0]["bitten"] != true:
		errs.append("[다·속음] 새로 누른 막기가 속지 않았다")


## (마) 가운데 낀 헛손질(길 B): 흘리면 끝의 빈틈, 따라가 속으면 0. 예비 동작의 높이는 시작할 때 다 뽑힌다.
func _t135_mid_route(errs: Array[String]) -> void:
	var SR := DT.StrikeResult
	var kept := _run(_route_b(), _cfg(&"hold", false), _f._stop_strikes(2), 30.0)
	var strikes := _strikes_of(kept)
	var feints := _feints(kept)
	if strikes.size() != 2 or feints.size() != 1:
		errs.append("[마·흘림] 타격 %d · 헛손질 %d (기대 2 · 1)" % [strikes.size(), feints.size()])
	else:
		if feints[0]["bitten"] != false or int(feints[0]["index"]) != 1:
			errs.append("[마·흘림] FEINT bitten %s · index %d (기대 거짓 · 1)" % [str(feints[0]["bitten"]), int(feints[0]["index"])])
		if float(strikes[0]["t"]) >= float(feints[0]["t"]) or float(strikes[1]["t"]) <= float(feints[0]["t"]):
			errs.append("[마·흘림] 타격 · 헛손질의 차례가 어긋났다")
		_expect_strike(errs, "마·흘림 첫 타격", strikes[0], SR.BLOCKED, 0.0, false)
		_expect_strike(errs, "마·흘림 끝", strikes[1], SR.BLOCKED, ROOT_RECOVERY, false)
	var tells := kept.record.of_type(DuelRecord.TELL_START)
	if tells.is_empty() or str(tells[0]["heights"]) != str([DT.Height.MID, DT.Height.HIGH, DT.Height.LOW]):
		errs.append("[마] 예비 동작의 높이 %s (기대 [1, 0, 2])" % (str(tells[0]["heights"]) if not tells.is_empty() else "예비 동작 없음"))
	var followed := _run(_route_b(), _cfg(&"hold", true), _f._stop_strikes(2), 30.0)
	strikes = _strikes_of(followed)
	feints = _feints(followed)
	if strikes.size() != 2 or feints.size() != 1 or feints[0]["bitten"] != true:
		errs.append("[마·따라감] 타격 %d · 헛손질 %d · bitten %s (기대 2 · 1 · 참)" % [strikes.size(), feints.size(), str(feints[0]["bitten"]) if not feints.is_empty() else "-"])
	else:
		_expect_strike(errs, "마·따라간 첫 타격", strikes[0], SR.BLOCKED, 0.0, false)
		_expect_strike(errs, "마·따라가 속음", strikes[1], SR.BLOCKED, 0.0, true)


## (바) 방향이 같고 높이가 다른 막기와 막지 않은 손은 속지 않는다.
func _t135_not_bitten(errs: Array[String]) -> void:
	var cases := [[&"wrong_height", "높이가 다른 막기"], [&"none", "막지 않은 손"]]
	for item: Array in cases:
		var core := _run(_route_a(), _cfg(item[0], true), _f._stop_strikes(1), 30.0)
		var feints := _feints(core)
		if feints.size() != 1 or feints[0]["bitten"] != false:
			errs.append("[바·%s] 속았다 (헛손질 %d개)" % [item[1], feints.size()])


## (사) 멀리: 헛손질이 넘어가고 진짜는 헛친다(막고 있어도 속지 않는다). (아) 헛손질을 기다리는 동안 누른 공격은 섣부르다.
func _t135_far_and_rash(errs: Array[String]) -> void:
	var SR := DT.StrikeResult
	var seen := {}
	var far_hook := func(core: DuelCore) -> void:
		if core.distance == DT.Distance.FAR and core.brain.state == DT.OpponentState.TELL and not core.guard_held:
			core.set_aim(DT.Direction.LEFT, DT.Height.HIGH)
			core.set_guard(true)
		if not seen.has("distance") and not _feints(core).is_empty():
			seen["distance"] = core.distance
	var far := _run(_route_a(), _cfg(&"retreat", false), _f._stop_strikes(1), 30.0, far_hook)
	var feints := _feints(far)
	var strikes := _strikes_of(far)
	if feints.size() != 1 or seen.get("distance", -1) != DT.Distance.FAR:
		errs.append("[사] 헛손질 %d개 · 그때의 간격 %s (기대 1개 · 멀리)" % [feints.size(), str(seen.get("distance", "없음"))])
	elif feints[0]["bitten"] != false:
		errs.append("[사] 멀리인데 속았다")
	if strikes.size() != 1 or int(strikes[0]["result"]) != SR.WHIFF or strikes[0].has("bitten"):
		errs.append("[사] 진짜의 결과 %s (기대 헛침 · bitten 없음)" % _f._result_text(strikes))
	var pressed := {}
	var rash_hook := func(core: DuelCore) -> void:
		if not pressed.has("done") and core.brain.state == DT.OpponentState.TELL:
			pressed["done"] = true
			core.press_attack()
	var stop_start := func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.ATTACK_START).size() >= 1
	var rash := _run(_route_a(), _cfg(&"none", false), stop_start, 30.0, rash_hook)
	var starts := rash.record.of_type(DuelRecord.ATTACK_START)
	if starts.size() != 1 or starts[0]["rash"] != true:
		errs.append("[아] 헛손질을 기다리며 누른 공격의 rash %s (기대 참)" % (str(starts[0]["rash"]) if starts.size() == 1 else "공격 없음"))


## (자) 다음 예비 동작에서 feint_bitten이 거짓으로 돌아온다. 헛손질이 없는 판의 STRIKE에는 bitten이 없고 FEINT도 요약의 feints도 없다.
func _t135_reset_and_plain(errs: Array[String]) -> void:
	var sample := {}
	var sample_hook := func(core: DuelCore) -> void:
		if not sample.has("bitten") and not _feints(core).is_empty():
			sample["bitten"] = core.brain.feint_bitten
	var stop_second := func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.TELL_START).size() >= 2
	var again := _run(_route_a(), _cfg(&"hold", true), stop_second, 40.0, sample_hook)
	if sample.get("bitten", false) != true:
		errs.append("[자] 속은 직후의 feint_bitten %s (기대 참)" % str(sample.get("bitten", "표본 없음")))
	if again.record.of_type(DuelRecord.TELL_START).size() < 2:
		errs.append("[자] 40초 안에 둘째 예비 동작이 없다")
	elif again.brain.feint_bitten:
		errs.append("[자] 다음 예비 동작에서 feint_bitten이 거짓으로 돌아오지 않았다")
	for atk in _bartolo().attacks:
		var core := _run(atk, _cfg(&"hold", false), _f._stop_strikes(1), 30.0)
		var strikes := _strikes_of(core)
		if strikes.is_empty():
			errs.append("[자·%s] 30초 안에 타격이 없다" % atk.attack_name)
		elif strikes[0].has("bitten") or not _feints(core).is_empty():
			errs.append("[자·%s] 헛손질이 없는 판에 bitten 또는 FEINT가 있다" % atk.attack_name)
		elif Summary.summarize(core.record).has("feints"):
			errs.append("[카·%s] FEINT가 없는 판의 요약에 feints 열쇠가 있다" % atk.attack_name)


## (타) 막을 칸의 테두리: 헛손질의 예비 동작에는 없고, 진짜는 칸 단위 rect와 막고 있는지(guarded)를 낸다.
func _t135_frame(errs: Array[String]) -> void:
	var frames := {}
	var frame_hook := func(core: DuelCore) -> void:
		if core.brain.state == DT.OpponentState.TELL and not frames.has(core.brain.step_index):
			frames[core.brain.step_index] = DuelScene.strike_cell_frame(core)
	_run(_route_b(), _cfg(&"hold", false), _f._stop_strikes(2), 30.0, frame_hook)
	var want := {0: [DT.Direction.LEFT, DT.Height.MID], 2: [DT.Direction.RIGHT, DT.Height.LOW]}
	for index in want:
		var frame: Dictionary = frames.get(index, {})
		var cell: Array = want[index]
		if frame.is_empty():
			errs.append("[타] %d번째 타격의 테두리가 비었다" % index)
			continue
		var rect: Rect2 = frame["rect"]
		if rect != Rect2(Vector2(cell[0], cell[1]), Vector2.ONE) or frame["direction"] != cell[0] or frame["height"] != cell[1] or frame["guarded"] != true:
			errs.append("[타] %d번째 타격의 테두리 rect %s · 방향 %s · 높이 %s · guarded %s (기대 칸 %s · 막는 중)" % [
				index, str(rect), str(frame["direction"]), str(frame["height"]), str(frame["guarded"]), str(cell)])
	if not frames.has(1) or not (frames[1] as Dictionary).is_empty():
		errs.append("[타] 헛손질의 예비 동작에 테두리가 있다 (%s)" % str(frames.get(1, "표본 없음")))


## (카) 요약: FEINT가 있는 판에는 feints 열쇠와 길 글의 "~". (FEINT가 없는 판은 _t135_reset_and_plain이 본다.)
func _t135_summary(errs: Array[String]) -> void:
	var core := _run(_route_a(), _cfg(&"hold", true), _f._stop_strikes(1), 30.0)
	var summary := Summary.summarize(core.record)
	if not summary.has("feints"):
		errs.append("[카] 헛손질이 있는 판의 요약에 feints 열쇠가 없다")
		return
	var counts: Dictionary = summary["feints"]
	if int(counts["헛손질"]) != 1 or int(counts["속음"]) != 1 or int(counts["잃은 빈틈"]) != 1:
		errs.append("[카] feints %s (기대 헛손질 1 · 속음 1 · 잃은 빈틈 1)" % str(counts))
	var routes: Dictionary = summary["routes"]
	if not routes.has("속임 베기 왼상~>오중"):
		errs.append("[카] 길 글 %s (기대 '속임 베기 왼상~>오중')" % str(routes.keys()))
