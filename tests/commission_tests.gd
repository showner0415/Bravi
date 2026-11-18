extends RefCounted
## T15~T20: 의뢰 데이터와 조건 3종(첫 피, 깃털, 티 안 나게 지기).
## 결투는 core_tests.gd의 도우미로 돌린다(봇이 코어 이벤트에 반응해 입력).

const Core := preload("res://tests/core_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const THROW_PATH := "res://data/commissions/throw_match.tres"
const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"

const AIM_MID_THRUST := [DT.Direction.CENTER, DT.Height.MID]
const AIM_HIGH_THRUST := [DT.Direction.CENTER, DT.Height.HIGH]
const AIM_HIGH_CUT := [DT.Direction.RIGHT, DT.Height.HIGH]

## 상단 베기(교전 0.70초)가 닿을 만큼 큰 빈틈의 기준(초): 패리당한 베기 1.10, 막힌 큰 베기 1.60.
const BIG_OPENING := 1.0
## 지기 봇이 제대로 싸우는 공격 수. 이 뒤로는 틀린 방향으로 막아 맞는다(가장 빨라도 30초를 넘긴다).
const THROW_FIGHT_TELLS := 20
## T18: 제대로 싸우다 진 판과 가만히 맞은 판의 점수 차 하한.
const THROW_SCORE_GAP := 40

var _h: RefCounted = Core.new()


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T15", "name": "의뢰 .tres 3개와 상대 데이터 로드", "fn": t15_data},
		{"id": "T16", "name": "첫 피: 몸통 100 / 머리 40 / 패배 0", "fn": t16_first_blood},
		{"id": "T17", "name": "깃털: 감점과 종료 조건", "fn": t17_feather},
		{"id": "T18", "name": "지기: 의심도와 게이지", "fn": t18_throw},
		{"id": "T19", "name": "같은 봇이 세 의뢰에서 다른 결과", "fn": t19_same_bot},
		{"id": "T20", "name": "의뢰별 판 길이 (시드 %d개)" % Core.SIM_SEEDS, "fn": t20_lengths},
	]


func cleanup() -> void:
	_h = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


func _conditions(path: String) -> Array[CommissionCondition]:
	return (load(path) as Commission).conditions


func _one(condition: CommissionCondition) -> Array[CommissionCondition]:
	var out: Array[CommissionCondition] = [condition]
	return out


## 결투가 끝날 때까지(또는 stop이 걸릴 때까지) 돌린 코어.
func _duel(opp: OpponentData, cfg: Dictionary, conditions: Array[CommissionCondition],
		stop: Callable = Callable(), max_time := 200.0, seed_value := 1) -> DuelCore:
	var never := func(_record: DuelRecord) -> int: return -1
	return _h.call("_run", opp, cfg, stop if stop.is_valid() else never,
		Core.BASE_DELTA, max_time, seed_value, conditions).core


func _attacks(core: DuelCore) -> Array[Dictionary]:
	return core.record.of_type(DuelRecord.ATTACK)


## 막고, 빈틈이 생기는 공격 뒤에 받아치는 설정.
func _cfg_counter(counter_aim: Array, extra: Dictionary = {}) -> Dictionary:
	var counter := func(ev: Dictionary) -> Variant:
		return counter_aim if float(ev["recovery"]) > 0.0 else null
	var cfg := {"counter_fn": counter}
	cfg.merge(extra)
	return cfg


## 받아칠 때마다 aims를 순서대로 쓴다(마지막 것을 되풀이).
func _cfg_counter_sequence(aims: Array, extra: Dictionary = {}) -> Dictionary:
	var calls: Array[int] = [0]
	var counter := func(ev: Dictionary) -> Variant:
		if float(ev["recovery"]) <= 0.0:
			return null
		var aim: Array = aims[mini(calls[0], aims.size() - 1)]
		calls[0] += 1
		return aim
	var cfg := {"counter_fn": counter}
	cfg.merge(extra)
	return cfg


## 지기 의뢰의 봇 (b): THROW_FIGHT_TELLS번은 막고 막을 때마다 받아치다가, 그 뒤로는 틀린 방향으로 막아 맞는다.
func _cfg_throw_fight() -> Dictionary:
	var guard := func(_a: AttackData, i: int) -> StringName:
		return &"hold" if i <= THROW_FIGHT_TELLS else &"wrong"
	var counter := func(_ev: Dictionary) -> Variant: return AIM_MID_THRUST
	return {"guard_fn": guard, "counter_fn": counter}


## 깃털: 교전에서 베기를 패리하고, 큰 빈틈에만 상단 베기.
func _cfg_feather_parry() -> Dictionary:
	var guard := func(a: AttackData, _i: int) -> StringName:
		return &"hold" if a.direction == DT.Direction.CENTER else &"parry"
	return {"guard_fn": guard, "counter_fn": _counter_big_opening(), "finisher": AIM_HIGH_CUT}


## 깃털: 밀착에서 막기만 하고 베기 뒤에 상단 베기.
func _cfg_feather_close() -> Dictionary:
	return _cfg_counter(AIM_HIGH_CUT, {"want_distance": DT.Distance.CLOSE, "finisher": AIM_HIGH_CUT})


## 깃털: 교전에서 막기만. 큰 베기 때만 모자에 닿는다.
func _cfg_feather_engage_guard() -> Dictionary:
	return {"counter_fn": _counter_big_opening(), "finisher": AIM_HIGH_CUT}


## 큰 빈틈에만 상단 베기로 받아친다.
func _counter_big_opening() -> Callable:
	return func(ev: Dictionary) -> Variant:
		return AIM_HIGH_CUT if float(ev["recovery"]) > BIG_OPENING else null


# ================================================================ T15

func t15_data() -> String:
	var errs: Array[String] = []
	var opponent: OpponentData = load(OPPONENT_PATH)
	var expected := [
		[FIRST_BLOOD_PATH, FirstBloodCondition],
		[FEATHER_PATH, TargetPartCondition],
		[THROW_PATH, ThrowUndetectedCondition],
	]
	for row in expected:
		var path: String = row[0]
		var commission := load(path) as Commission
		if commission == null:
			errs.append("%s 가 Commission으로 로드되지 않음" % path)
			continue
		_expect(errs, commission.client_name != "" and commission.dialogue != "", "%s 의뢰인 이름이나 대사가 비어 있음" % path)
		_expect(errs, commission.opponent == opponent, "%s 의 상대가 opponent_01이 아님" % path)
		_expect(errs, commission.conditions.size() == 1, "%s 조건 수 %d (기대 1)" % [path, commission.conditions.size()])
		if commission.conditions.size() == 1:
			_expect(errs, is_instance_of(commission.conditions[0], row[1]), "%s 조건의 타입이 다름" % path)
			_expect(errs, commission.conditions[0].describe() != "", "%s 조건 설명이 비어 있음" % path)
	var feather := load(FEATHER_PATH) as Commission
	if feather != null and feather.conditions.size() == 1 and feather.conditions[0] is TargetPartCondition:
		_expect(errs, (feather.conditions[0] as TargetPartCondition).target_part == DT.Part.HAT, "깃털 의뢰의 지정 부위가 모자가 아님")

	_expect(errs, opponent.attacks.size() == 3, "상대 공격 수 %d (기대 3)" % opponent.attacks.size())
	for atk in opponent.attacks:
		_expect(errs, atk is AttackData, "공격 배열에 AttackData가 아닌 원소")
	_expect(errs, opponent.habits.size() == 1, "상대 버릇 수 %d (기대 1)" % opponent.habits.size())
	for habit in opponent.habits:
		_expect(errs, habit is HabitData and habit.response is AttackData, "버릇이나 그 반응 공격의 타입이 다름")
	return _result(errs)


# ================================================================ T16 첫 피

func t16_first_blood() -> String:
	var errs: Array[String] = []
	var cond := FirstBloodCondition.new()
	var conds := _one(cond)

	# 무너뜨린 뒤 몸통 유효타 → 승리 종료, 100점
	var a := _duel(_h.call("_make_opp", "cut", false, 1), _cfg_counter(AIM_MID_THRUST, {"finisher": AIM_MID_THRUST}), conds)
	var a_hits := _attacks(a)
	_expect(errs, a.ended and a.end_reason == DT.EndReason.CONDITION, "[16a] 조건으로 끝나지 않음")
	_expect(errs, a_hits.size() == 2 and a_hits[1]["result"] == DT.AttackResult.HIT and a_hits[1]["part"] == DT.Part.TORSO, "[16a] 몸통 유효타가 아님")
	_expect(errs, cond.evaluate(a.record) == 100, "[16a] 점수 %d (기대 100)" % cond.evaluate(a.record))

	# 머리 유효타 → 40점
	var b := _duel(_h.call("_make_opp", "cut", false, 1), _cfg_counter(AIM_MID_THRUST, {"finisher": AIM_HIGH_THRUST}), conds)
	var b_hits := _attacks(b)
	_expect(errs, b.end_reason == DT.EndReason.CONDITION, "[16b] 조건으로 끝나지 않음")
	_expect(errs, b_hits.size() == 2 and b_hits[1]["part"] == DT.Part.HEAD, "[16b] 머리 유효타가 아님")
	_expect(errs, cond.evaluate(b.record) == 40, "[16b] 점수 %d (기대 40)" % cond.evaluate(b.record))

	# 패배 → 0점
	var none := func(_a: AttackData, _i: int) -> StringName: return &"none"
	var c := _duel(_h.call("_make_opp", "thrust"), {"guard_fn": none}, conds)
	_expect(errs, c.end_reason == DT.EndReason.PLAYER_DEFEATED, "[16c] 패배로 끝나지 않음")
	_expect(errs, cond.evaluate(c.record) == 0, "[16c] 점수 %d (기대 0)" % cond.evaluate(c.record))

	# 스침은 결투를 끝내지 않는다
	var stop := func(record: DuelRecord) -> int: return _h.call("_nth_index", record, DuelRecord.ATTACK, 2)
	var d := _duel(_h.call("_make_opp", "cut", false, 3), _cfg_counter(AIM_MID_THRUST), conds, stop)
	var d_hits := _attacks(d)
	_expect(errs, d_hits.size() == 2 and d_hits[0]["result"] == DT.AttackResult.GRAZE and d_hits[1]["result"] == DT.AttackResult.GRAZE, "[16d] 스침 두 번이 아님")
	_expect(errs, not d.ended, "[16d] 스침으로 결투가 끝남")
	return _result(errs)


# ================================================================ T17 깃털

func t17_feather() -> String:
	var errs: Array[String] = []
	var cond := TargetPartCondition.new()
	cond.target_part = DT.Part.HAT
	var conds := _one(cond)
	var close := {"want_distance": DT.Distance.CLOSE, "finisher": AIM_HIGH_CUT}

	# 몸에 손대지 않고 모자를 자름 → 100점. 모자 스침은 감점이 없다.
	var a := _duel(_h.call("_make_opp", "cut", false, 1), _cfg_counter(AIM_HIGH_CUT, close), conds)
	var a_hits := _attacks(a)
	_expect(errs, a.end_reason == DT.EndReason.CONDITION, "[17a] 조건으로 끝나지 않음")
	_expect(errs, a_hits.size() == 2 and a_hits[0]["result"] == DT.AttackResult.GRAZE and a_hits[0]["part"] == DT.Part.HAT, "[17a] 첫 공격이 모자 스침이 아님")
	_expect(errs, cond.evaluate(a.record) == 100, "[17a] 점수 %d (기대 100)" % cond.evaluate(a.record))

	# 몸통 스침 2회 뒤 모자를 자름 → 80점
	var b := _duel(_h.call("_make_opp", "cut", false, 3),
		_cfg_counter_sequence([AIM_MID_THRUST, AIM_MID_THRUST, AIM_HIGH_CUT], close), conds)
	_expect(errs, b.end_reason == DT.EndReason.CONDITION, "[17b] 조건으로 끝나지 않음")
	_expect(errs, cond.evaluate(b.record) == 80, "[17b] 점수 %d (기대 80)" % cond.evaluate(b.record))

	# 무너진 상대의 몸통에 유효타 1회 뒤 모자 → 70점. 몸통 유효타로는 끝나지 않는다.
	var c_cfg := _cfg_counter(AIM_HIGH_CUT, {
		"want_distance": DT.Distance.CLOSE, "finisher": AIM_MID_THRUST,
		"follow_up": {"aim": AIM_HIGH_CUT},
	})
	var c := _duel(_h.call("_make_opp", "cut", false, 1), c_cfg, conds)
	var c_hits := _attacks(c)
	_expect(errs, c_hits.size() == 3, "[17c] 공격 수 %d (기대 3: 모자 스침, 몸통 유효타, 모자 유효타)" % c_hits.size())
	if c_hits.size() == 3:
		_expect(errs, c_hits[1]["result"] == DT.AttackResult.HIT and c_hits[1]["part"] == DT.Part.TORSO, "[17c] 둘째 공격이 몸통 유효타가 아님")
		_expect(errs, c_hits[2]["result"] == DT.AttackResult.HIT and c_hits[2]["part"] == DT.Part.HAT, "[17c] 셋째 공격이 모자 유효타가 아님")
	_expect(errs, c.end_reason == DT.EndReason.CONDITION, "[17c] 조건으로 끝나지 않음")
	_expect(errs, cond.evaluate(c.record) == 70, "[17c] 점수 %d (기대 70)" % cond.evaluate(c.record))

	# 모자를 못 자르고 끝남 → 0점
	var none := func(_a: AttackData, _i: int) -> StringName: return &"none"
	var d := _duel(_h.call("_make_opp", "thrust"), {"guard_fn": none}, conds)
	_expect(errs, d.end_reason == DT.EndReason.PLAYER_DEFEATED, "[17d] 패배로 끝나지 않음")
	_expect(errs, cond.evaluate(d.record) == 0, "[17d] 점수 %d (기대 0)" % cond.evaluate(d.record))
	return _result(errs)


# ================================================================ T18 지기

## 한 판을 돌리며 매 tick 게이지가 줄어들지 않는지 본다. [코어, 마지막 게이지]를 돌려준다.
func _throw_duel(cond: ThrowUndetectedCondition, opp: OpponentData, cfg: Dictionary,
		label: String, errs: Array[String]) -> Array:
	var core: DuelCore = _h.call("_make_core", opp, 1, _one(cond))
	var bot: RefCounted = Bot.new(core, cfg)
	var last := -1
	var dropped := false
	var meter := {}
	while not core.ended and core.time < 200.0:
		core.tick(Core.BASE_DELTA)
		bot.call("update")
		meter = cond.live_meter(core.record)
		if int(meter["value"]) < last:
			dropped = true
		last = int(meter["value"])
	_expect(errs, not dropped, "[%s] 게이지 값이 줄어든 tick이 있음" % label)
	return [core, meter]


func t18_throw() -> String:
	var errs: Array[String] = []
	var cond := ThrowUndetectedCondition.new()
	var real: OpponentData = load(OPPONENT_PATH)

	# (a) 아무것도 안 하고 네 번 맞음 → 낮은 점수
	var none := func(_a: AttackData, _i: int) -> StringName: return &"none"
	var a := _throw_duel(cond, real, {"guard_fn": none}, "18a", errs)
	var a_core: DuelCore = a[0]
	var a_score := cond.evaluate(a_core.record)
	_expect(errs, a_core.end_reason == DT.EndReason.PLAYER_DEFEATED, "[18a] 패배로 끝나지 않음")

	# (b) 30초 넘게 막고 받아치다가 틀린 방향 막기로 네 번 맞음 → 높은 점수
	var b := _throw_duel(cond, real, _cfg_throw_fight(), "18b", errs)
	var b_core: DuelCore = b[0]
	var b_score := cond.evaluate(b_core.record)
	_expect(errs, b_core.end_reason == DT.EndReason.PLAYER_DEFEATED, "[18b] 패배로 끝나지 않음")
	_expect(errs, b_core.record.elapsed > cond.min_duration, "[18b] 결투 시간 %.1f초가 %.0f초를 넘지 않음" % [b_core.record.elapsed, cond.min_duration])
	_expect(errs, b_score - a_score >= THROW_SCORE_GAP, "(b) %d점과 (a) %d점의 차가 %d 미만" % [b_score, a_score, THROW_SCORE_GAP])
	print("  INFO 지기: 가만히 맞음 %d점 (%.1f초) / 싸우다 짐 %d점 (%.1f초)" % [
		a_score, a_core.record.elapsed, b_score, b_core.record.elapsed])

	# 패배로 끝난 뒤: 의심도 = min(100, 마지막 게이지 값 + 종료 시 확정 항목 합)
	for pair: Array in [["18a", a], ["18b", b]]:
		var core: DuelCore = pair[1][0]
		var meter: Dictionary = pair[1][1]
		var want := mini(100, int(meter["value"]) + int(meter["pending"]))
		var got := 100 - cond.evaluate(core.record)
		_expect(errs, got == want, "[%s] 의심도 %d (기대 %d = 게이지 %d + 확정 %d)" % [pair[0], got, want, meter["value"], meter["pending"]])
		_expect(errs, not cond.explain(core.record).is_empty(), "[%s] 내역이 비어 있음" % pair[0])

	# (c) 상대를 무너뜨리고 유효타를 넣어 이겨 버림 → 0점
	var c := _duel(_h.call("_make_opp", "cut", false, 1), _cfg_counter(AIM_MID_THRUST, {"finisher": AIM_MID_THRUST}), _one(cond))
	_expect(errs, c.end_reason == DT.EndReason.CONDITION, "[18c] 상대 유효타로 끝나지 않음")
	_expect(errs, cond.evaluate(c.record) == 0, "[18c] 점수 %d (기대 0)" % cond.evaluate(c.record))
	return _result(errs)


# ================================================================ T19 같은 봇, 세 의뢰

func t19_same_bot() -> String:
	var errs: Array[String] = []
	var real: OpponentData = load(OPPONENT_PATH)
	# 막고, 베기 뒤 중단 찌르기, 무너지면 중단 찌르기.
	var cfg_fn := func() -> Dictionary: return _cfg_counter(AIM_MID_THRUST, {"finisher": AIM_MID_THRUST})

	var first := load(FIRST_BLOOD_PATH) as Commission
	var a := _duel(real, cfg_fn.call(), first.conditions)
	_expect(errs, a.end_reason == DT.EndReason.CONDITION, "첫 피: 조건으로 끝나지 않음")
	_expect(errs, first.evaluate(a.record) == 100, "첫 피: 점수 %d (기대 100)" % first.evaluate(a.record))

	var feather := load(FEATHER_PATH) as Commission
	var b := _duel(real, cfg_fn.call(), feather.conditions)
	var body_hits := b.record.count_where(DuelRecord.ATTACK, "result", DT.AttackResult.HIT)
	_expect(errs, b.end_reason == DT.EndReason.TIME_UP, "깃털: 시간 초과로 끝나지 않음 (몸통 유효타로 끝나면 안 된다)")
	_expect(errs, body_hits >= 1, "깃털: 몸통 유효타가 한 번도 없음")
	_expect(errs, feather.evaluate(b.record) == 0, "깃털: 점수 %d (기대 0)" % feather.evaluate(b.record))

	var throw_match := load(THROW_PATH) as Commission
	var c := _duel(real, cfg_fn.call(), throw_match.conditions)
	_expect(errs, c.end_reason == DT.EndReason.CONDITION, "지기: 이겨 버림으로 끝나지 않음")
	_expect(errs, throw_match.evaluate(c.record) == 0, "지기: 점수 %d (기대 0)" % throw_match.evaluate(c.record))
	return _result(errs)


# ================================================================ T20 의뢰별 판 길이

func t20_lengths() -> String:
	var errs: Array[String] = []
	var real: OpponentData = load(OPPONENT_PATH)
	var limit: float = (load(Core.RULES_PATH) as DuelRules).time_limit
	var feather := _conditions(FEATHER_PATH)
	var throw_match := _conditions(THROW_PATH)
	# [이름, 설정, 조건, 통과 조건을 거는가]
	var rows := [
		["깃털 · 교전에서 베기를 패리", _cfg_feather_parry, feather, true],
		["깃털 · 밀착에서 막기만", _cfg_feather_close, feather, true],
		["지기 · 싸우다 짐", _cfg_throw_fight, throw_match, true],
		["(참고) 깃털 · 교전에서 막기만", _cfg_feather_engage_guard, feather, false],
	]
	for row in rows:
		var st: Dictionary = _h.call("_simulate", real, row[1], row[2])
		print(_h.call("_stat_line", row[0], st))
		if not row[3]:
			continue
		_expect(errs, st["mean"] >= 30.0 and st["mean"] <= limit, "%s 평균 %.1f초가 30~%.0f초 밖" % [row[0], st["mean"], limit])
		_expect(errs, st["timeouts"] * 10 <= Core.SIM_SEEDS, "%s 시간 초과 %d판 (10%% 초과)" % [row[0], st["timeouts"]])

	# 참고용(통과 조건 아님): 받아치기를 늦게 누르는 손. 밀착에서 막힌 베기 뒤의 상단 베기는
	# 타격 뒤 0.13초 안에 눌러야 닿는다(빈틈 0.55초 − 밀착 상단 베기 0.42초).
	for row in [
		["(참고) 깃털 · 밀착에서 막기만 · 0.10초 늦게 누름", _cfg_feather_close, 0.10],
		["(참고) 깃털 · 밀착에서 막기만 · 0.20초 늦게 누름", _cfg_feather_close, 0.20],
		["(참고) 깃털 · 교전에서 베기를 패리 · 0.20초 늦게 누름", _cfg_feather_parry, 0.20],
	]:
		var base_cfg: Callable = row[1]
		var delay: float = row[2]
		var late_cfg := func() -> Dictionary:
			var cfg: Dictionary = base_cfg.call()
			cfg["counter_delay"] = delay
			return cfg
		print(_h.call("_stat_line", row[0], _h.call("_simulate", real, late_cfg, feather)))

	# 참고용(통과 조건 아님): 버릇 식히기(장치 D)를 켜고 버릇 횟수를 2로 했을 때의 깃털.
	var cooled: OpponentData = _h.call("_real_with_habit", true, 2)
	for row in [
		["(참고) 식히기 켬 · 횟수 2 · 깃털 · 교전에서 베기를 패리", _cfg_feather_parry],
		["(참고) 식히기 켬 · 횟수 2 · 깃털 · 교전에서 막기만", _cfg_feather_engage_guard],
	]:
		var st: Dictionary = _h.call("_simulate", cooled, row[1], feather)
		print(str(_h.call("_stat_line", row[0], st)) + ", 큰 베기 %.1f회/판" % st["big"])
	return _result(errs)
