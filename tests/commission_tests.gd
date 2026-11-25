extends RefCounted
## T15~T20: 의뢰 데이터와 조건 3종(첫 피, 깃털, 티 안 나게 지기).
## 결투는 core_tests.gd의 도우미로 돌린다(봇이 코어 이벤트에 반응해 입력).

const Plain := preload("res://tests/plain_opponent.gd")
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
## T90 시간 초과 한도(%): 1·2일차는 T13·T20의 기준, 3일차는 사용자가 시험용 바르톨로에서 받아들인 수(결정 417).
const DAY_TIMEOUT_EARLY := 10
const DAY_TIMEOUT_LATE := 20

var _h: RefCounted = Core.new()


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T15", "name": "의뢰 .tres 3개와 상대 데이터 로드", "fn": t15_data},
		{"id": "T16", "name": "첫 피: 몸통 100 / 머리 40 / 패배 0", "fn": t16_first_blood},
		{"id": "T17", "name": "깃털: 감점과 종료 조건", "fn": t17_feather},
		{"id": "T18", "name": "지기: 의심도와 게이지", "fn": t18_throw},
		{"id": "T19", "name": "같은 봇이 세 의뢰에서 다른 결과", "fn": t19_same_bot},
		{"id": "T20", "name": "의뢰별 판 길이 (시드 %d개)" % Core.SIM_SEEDS, "fn": t20_lengths},
		{"id": "T90", "name": "하루의 판 길이: 날마다의 확률 (시드 %d개)" % Core.SIM_SEEDS, "fn": t90_day_lengths},
		{"id": "T92", "name": "패턴과 지기의 셈: 타격마다 막아낸 횟수, 높이가 틀린 막기", "fn": t92_throw_with_patterns},
		{"id": "T41", "name": "첫 피: 손은 피, 머리 스침 감점은 꺼져 있다", "fn": t41_first_blood_parts},
		{"id": "T44", "name": "유효타만 보는 조건과 일정의 비중", "fn": t44_hit_only},
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

	_expect(errs, opponent.attacks.size() == 5, "상대 공격 수 %d (기대 5)" % opponent.attacks.size())
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


# ================================================================ T41 첫 피: 손과 머리 스침

const VARIANT_FIRST_BLOOD_PATHS: Array[String] = [
	"res://data/commissions/variants/first_blood_poor.tres",
	"res://data/commissions/variants/first_blood_usurer.tres",
]


## 모자 없는 판(게임의 기본)에서 끝까지 돌린 코어. _duel은 모자를 쓴 판을 만든다.
func _bare_duel(opp: OpponentData, cfg: Dictionary, conditions: Array[CommissionCondition]) -> DuelCore:
	var never := func(_record: DuelRecord) -> int: return -1
	return _h.call("_run", opp, cfg, never, Core.BASE_DELTA, 200.0, 1, conditions, false).core


## 머리를 스쳐도 닿는 테스트용 상대(머리를 지키지 않는다). 스침마다 1칸이다.
func _first_blood_opp(posture: int) -> OpponentData:
	return _h.call("_make_opp", "cut", false, posture)


func t41_first_blood_parts() -> String:
	var errs: Array[String] = []
	var AR := DT.AttackResult

	# ---- 기본값의 조건: 머리 스침은 채점하지 않는다(지금의 채점)
	var plain := FirstBloodCondition.new()
	_expect(errs, plain.risky_graze_penalty == 0, "기본값의 머리 스침 감점이 0이 아님")
	_expect(errs, plain.describe().contains("손") and not plain.describe().contains("스치기만"), "기본값의 설명 글이 다름: %s" % plain.describe())

	# 머리를 두 번 스친 뒤 몸통 유효타 → 100점
	var a := _bare_duel(_first_blood_opp(2), _cfg_counter(AIM_HIGH_THRUST, {"finisher": AIM_MID_THRUST}), _one(plain))
	var a_hits := _attacks(a)
	_expect(errs, a.end_reason == DT.EndReason.CONDITION, "[41a] 조건으로 끝나지 않음")
	_expect(errs, a_hits.size() == 3 and a_hits[0]["part"] == DT.Part.HEAD and a_hits[0]["result"] == AR.GRAZE \
		and a_hits[1]["part"] == DT.Part.HEAD and a_hits[2]["result"] == AR.HIT and a_hits[2]["part"] == DT.Part.TORSO,
		"[41a] 머리 스침 둘과 몸통 유효타가 아님")
	_expect(errs, plain.evaluate(a.record) == 100, "[41a] 점수 %d (기대 100)" % plain.evaluate(a.record))
	_expect(errs, not " ".join(plain.explain(a.record)).contains("머리 스침"), "[41a] 감점이 꺼져 있는데 내역에 머리 스침 줄이 있음")

	# 칼 든 손 유효타(모자 없는 판, 칼 쪽 상단 베기로 끝냄) → 100점
	var hand_opp := _first_blood_opp(1)
	var hand_aim := [hand_opp.sword_side, DT.Height.HIGH]
	var b := _bare_duel(hand_opp, _cfg_counter(AIM_MID_THRUST, {"finisher": hand_aim}), _one(plain))
	var b_hits := _attacks(b)
	_expect(errs, b.end_reason == DT.EndReason.CONDITION, "[41b] 조건으로 끝나지 않음")
	_expect(errs, b_hits.size() == 2 and b_hits[1]["result"] == AR.HIT and b_hits[1]["part"] == DT.Part.SWORD_HAND, "[41b] 칼 든 손 유효타가 아님")
	_expect(errs, plain.evaluate(b.record) == 100, "[41b] 점수 %d (기대 100)" % plain.evaluate(b.record))

	# ---- 감점을 10으로 적은 조건
	var strict := FirstBloodCondition.new()
	strict.risky_graze_penalty = 10
	_expect(errs, strict.describe().contains("스치기만"), "감점을 켠 조건의 설명 글에 스침 문구가 없음")

	# 머리를 두 번 스친 뒤 몸통 유효타 → 80점, 내역에 머리 스침 줄
	var c := _bare_duel(_first_blood_opp(2), _cfg_counter(AIM_HIGH_THRUST, {"finisher": AIM_MID_THRUST}), _one(strict))
	_expect(errs, strict.evaluate(c.record) == 80, "[41c] 점수 %d (기대 80)" % strict.evaluate(c.record))
	_expect(errs, " ".join(strict.explain(c.record)).contains("머리 스침 2회"), "[41c] 내역에 머리 스침 줄이 없음")

	# 머리를 한 번 스친 뒤 머리 유효타 → 30점
	var d := _bare_duel(_first_blood_opp(1), _cfg_counter(AIM_HIGH_THRUST, {"finisher": AIM_HIGH_THRUST}), _one(strict))
	_expect(errs, strict.evaluate(d.record) == 30, "[41d] 점수 %d (기대 30)" % strict.evaluate(d.record))

	# 몸통을 세 번 스친 뒤 몸통 유효타 → 100점
	var e := _bare_duel(_first_blood_opp(3), _cfg_counter(AIM_MID_THRUST, {"finisher": AIM_MID_THRUST}), _one(strict))
	_expect(errs, _attacks(e).size() == 4 and strict.evaluate(e.record) == 100, "[41e] 점수 %d (기대 100)" % strict.evaluate(e.record))

	# ---- 감점이 커도 0 아래로 내려가지 않는다
	var harsh := FirstBloodCondition.new()
	harsh.risky_graze_penalty = 50
	var f := _bare_duel(_first_blood_opp(3), _cfg_counter(AIM_HIGH_THRUST, {"finisher": AIM_MID_THRUST}), _one(harsh))
	_expect(errs, _attacks(f).size() == 4 and harsh.evaluate(f.record) == 0, "[41f] 점수 %d (기대 0)" % harsh.evaluate(f.record))

	# ---- 로드한 세 첫 피 의뢰는 감점이 꺼져 있다(계획 007이 켜지 않기로 한 것. 켜려면 이 줄도 함께 고친다)
	var paths: Array[String] = [FIRST_BLOOD_PATH]
	paths.append_array(VARIANT_FIRST_BLOOD_PATHS)
	for path in paths:
		var commission := load(path) as Commission
		var condition := commission.conditions[0] as FirstBloodCondition if commission != null else null
		_expect(errs, condition != null and condition.risky_graze_penalty == 0, "[%s] 머리 스침 감점이 켜져 있거나 첫 피 조건이 아님" % path)
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


# ================================================================ T44 유효타만 보는 조건

const SCHEDULE_PATH := "res://data/day_schedule.tres"
const KIND_FIRST_BLOOD := "첫 피"
const KIND_TARGET_HIT_ONLY := "지정 부위·유효타만"
const KIND_TARGET_GRAZE := "지정 부위·스침도"
const KIND_THROW := "지기"
const KIND_OTHER := "그 밖"
const KINDS: Array[String] = [KIND_FIRST_BLOOD, KIND_TARGET_HIT_ONLY, KIND_TARGET_GRAZE, KIND_THROW, KIND_OTHER]


## 의뢰의 종류(첫 조건으로 본다).
func _kind(commission: Commission) -> String:
	if commission == null or commission.conditions.is_empty():
		return KIND_OTHER
	var condition := commission.conditions[0]
	if condition is FirstBloodCondition:
		return KIND_FIRST_BLOOD
	if condition is TargetPartCondition:
		return KIND_TARGET_HIT_ONLY if (condition as TargetPartCondition).graze_penalty <= 0 else KIND_TARGET_GRAZE
	if condition is ThrowUndetectedCondition:
		return KIND_THROW
	return KIND_OTHER


func t44_hit_only() -> String:
	var errs: Array[String] = []
	var AR := DT.AttackResult
	var close := {"want_distance": DT.Distance.CLOSE, "finisher": AIM_HIGH_CUT}

	# ---- 유효타만 보는 조건(스침 감점 0, 지정 부위 모자)
	var hit_only := TargetPartCondition.new()
	hit_only.target_part = DT.Part.HAT
	hit_only.graze_penalty = 0

	# 몸통을 세 번 스친 뒤 모자 유효타 → 조건으로 끝나고 100점, 내역에 스침 줄이 없다
	var a := _duel(_h.call("_make_opp", "cut", false, 3),
		_cfg_counter_sequence([AIM_MID_THRUST, AIM_MID_THRUST, AIM_MID_THRUST], close), _one(hit_only))
	var a_hits := _attacks(a)
	_expect(errs, a.end_reason == DT.EndReason.CONDITION, "[44a] 조건으로 끝나지 않음")
	_expect(errs, a_hits.size() == 4, "[44a] 공격 수 %d (기대 4: 몸통 스침 셋, 모자 유효타)" % a_hits.size())
	if a_hits.size() == 4:
		for i in 3:
			_expect(errs, a_hits[i]["result"] == AR.GRAZE and a_hits[i]["part"] == DT.Part.TORSO, "[44a] %d번째 공격이 몸통 스침이 아님" % (i + 1))
		_expect(errs, a_hits[3]["result"] == AR.HIT and a_hits[3]["part"] == DT.Part.HAT, "[44a] 넷째 공격이 모자 유효타가 아님")
	_expect(errs, hit_only.evaluate(a.record) == 100, "[44a] 점수 %d (기대 100)" % hit_only.evaluate(a.record))
	_expect(errs, not " ".join(hit_only.explain(a.record)).contains("스침"), "[44a] 유효타만 보는데 내역에 스침 줄이 있음")

	# 무너진 상대의 몸통에 유효타 한 번 뒤 모자 유효타 → 70점. 몸통 유효타로는 끝나지 않는다.
	var b_cfg := _cfg_counter(AIM_HIGH_CUT, {
		"want_distance": DT.Distance.CLOSE, "finisher": AIM_MID_THRUST,
		"follow_up": {"aim": AIM_HIGH_CUT},
	})
	var b := _duel(_h.call("_make_opp", "cut", false, 1), b_cfg, _one(hit_only))
	var b_hits := _attacks(b)
	_expect(errs, b.end_reason == DT.EndReason.CONDITION, "[44b] 조건으로 끝나지 않음")
	_expect(errs, b_hits.size() == 3 and b_hits[1]["result"] == AR.HIT and b_hits[1]["part"] == DT.Part.TORSO \
		and b_hits[2]["result"] == AR.HIT and b_hits[2]["part"] == DT.Part.HAT, "[44b] 몸통 유효타 뒤 모자 유효타가 아님")
	_expect(errs, hit_only.evaluate(b.record) == 70, "[44b] 점수 %d (기대 70)" % hit_only.evaluate(b.record))

	# 모자를 못 자르고 지면 0점
	var none := func(_a: AttackData, _i: int) -> StringName: return &"none"
	var c := _duel(_h.call("_make_opp", "thrust"), {"guard_fn": none}, _one(hit_only))
	_expect(errs, c.end_reason == DT.EndReason.PLAYER_DEFEATED, "[44c] 패배로 끝나지 않음")
	_expect(errs, hit_only.evaluate(c.record) == 0, "[44c] 점수 %d (기대 0)" % hit_only.evaluate(c.record))

	# ---- 스침도 보는 조건(스크립트 기본값): 몸통을 두 번 스친 뒤 모자 유효타 → 80점
	var with_graze := TargetPartCondition.new()
	with_graze.target_part = DT.Part.HAT
	_expect(errs, with_graze.graze_penalty == 10, "스크립트 기본값의 스침 감점 %d (기대 10)" % with_graze.graze_penalty)
	var d := _duel(_h.call("_make_opp", "cut", false, 3),
		_cfg_counter_sequence([AIM_MID_THRUST, AIM_MID_THRUST, AIM_HIGH_CUT], close), _one(with_graze))
	_expect(errs, d.end_reason == DT.EndReason.CONDITION, "[44d] 조건으로 끝나지 않음")
	_expect(errs, with_graze.evaluate(d.record) == 80, "[44d] 점수 %d (기대 80)" % with_graze.evaluate(d.record))
	_expect(errs, " ".join(with_graze.explain(d.record)).contains("다른 부위 스침 2회"), "[44d] 스침도 보는데 내역에 스침 줄이 없음")

	# ---- 설명 글이 종류를 말한다
	var hit_text := hit_only.describe()
	var graze_text := with_graze.describe()
	_expect(errs, hit_text.contains("유효타만 본다") and not hit_text.contains("스치기만"), "유효타만 보는 조건의 설명 글이 다름: %s" % hit_text)
	_expect(errs, graze_text.contains("스침도 본다") and graze_text.contains("스치기만"), "스침도 보는 조건의 설명 글이 다름: %s" % graze_text)
	_expect(errs, FirstBloodCondition.new().describe().contains("유효타만 본다"), "기본값의 첫 피 조건의 설명 글에 '유효타만 본다'가 없음")

	# ---- 로드한 깃털 의뢰: 구조만 본다(스침 감점의 값은 조율값이라 통과 조건이 아니다)
	var feather := load(FEATHER_PATH) as Commission
	var feather_cond := feather.conditions[0] as TargetPartCondition if feather != null and feather.conditions.size() == 1 else null
	_expect(errs, feather_cond != null and feather_cond.target_part == DT.Part.HAT, "깃털 의뢰의 조건이 모자를 노리는 TargetPartCondition이 아님")

	# ---- INFO (통과 조건 아님): 일정의 손님 자리를 종류별로 센다
	var schedule := load(SCHEDULE_PATH) as DaySchedule
	if schedule == null:
		errs.append("%s 가 DaySchedule로 로드되지 않음" % SCHEDULE_PATH)
		return _result(errs)
	var counts := {}
	for kind in KINDS:
		counts[kind] = 0
	var day_lines: Array[String] = []
	for i in schedule.days.size():
		var names: Array[String] = []
		if schedule.days[i] != null:
			for commission in schedule.days[i].commissions:
				var kind := _kind(commission)
				counts[kind] += 1
				names.append(kind)
		day_lines.append("  INFO %d일차: %s" % [i + 1, " → ".join(PackedStringArray(names))])
	var parts: Array[String] = []
	for kind in KINDS:
		if kind != KIND_OTHER or counts[kind] > 0:
			parts.append("%s %d" % [kind, counts[kind]])
	var fewest := true
	for kind in [KIND_FIRST_BLOOD, KIND_TARGET_HIT_ONLY, KIND_THROW]:
		if counts[KIND_TARGET_GRAZE] >= counts[kind]:
			fewest = false
	print("  INFO 일정의 손님 자리: %s — 스침도 보는 의뢰가 가장 적은가: %s" % [", ".join(PackedStringArray(parts)), "예" if fewest else "아니오"])
	for line in day_lines:
		print(line)
	if feather_cond != null:
		print("  INFO 로드한 깃털 의뢰의 스침 감점 %d (%s)" % [feather_cond.graze_penalty, _kind(feather)])
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
	# 다른 규칙을 보는 테스트다: 패턴·높이·확률을 끈 옛 규칙 사본이다(결정 416·426). 하루의 판 길이는 T90.
	var real: OpponentData = Plain.of(load(OPPONENT_PATH) as OpponentData)

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
	var real: OpponentData = Plain.of(load(OPPONENT_PATH) as OpponentData)
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
	var real: OpponentData = Plain.of(load(OPPONENT_PATH) as OpponentData)
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


## T90: 하루의 상대를 날마다의 확률로 돌린 판 길이. 기준은 재 보기 전에 정했다(결정 417).
func t90_day_lengths() -> String:
	var errs: Array[String] = []
	var real := load(OPPONENT_PATH) as OpponentData
	var rules := load(Core.RULES_PATH) as DuelRules
	var boosted := rules.duplicate() as DuelRules
	boosted.opening_chance_bonus = 0.15
	var limit: float = rules.time_limit
	var feather := _conditions(FEATHER_PATH)
	var throw_match := _conditions(THROW_PATH)
	var none: Array[CommissionCondition] = []
	var guard_only := Callable(_h, "_cfg_guard_only")
	# [이름, 설정, 조건, 날, 규칙(덤), 통과 조건 한도(%), 0이면 참고]
	var rows := [
		["막기 봇 · 1일차", guard_only, none, 1, rules, DAY_TIMEOUT_EARLY],
		["막기 봇 · 2일차", guard_only, none, 2, rules, DAY_TIMEOUT_EARLY],
		["막기 봇 · 3일차", guard_only, none, 3, rules, DAY_TIMEOUT_LATE],
		["깃털 · 교전에서 베기를 패리 · 3일차", _cfg_feather_parry, feather, 3, rules, DAY_TIMEOUT_LATE],
		["지기 · 싸우다 짐 · 3일차", _cfg_throw_fight, throw_match, 3, rules, DAY_TIMEOUT_LATE],
		["(참고) 막기 봇 · 3일차 + 검술 교본", guard_only, none, 3, boosted, 0],
		["(참고) 깃털 · 밀착에서 막기만 · 3일차", _cfg_feather_close, feather, 3, rules, 0],
	]
	for row in rows:
		var day_rules: DuelRules = row[4]
		var chance := day_rules.opening_chance_for(real.opening_chance, row[3])
		var st: Dictionary = _h.call("_simulate", real.with_opening(chance), row[1], row[2])
		print(str(_h.call("_stat_line", row[0], st)) + ", 확률 %.2f" % chance)
		var max_pct: int = row[5]
		if max_pct == 0:
			continue
		_expect(errs, st["mean"] >= 30.0 and st["mean"] <= limit, "%s 평균 %.1f초가 30~%.0f초 밖" % [row[0], st["mean"], limit])
		_expect(errs, st["timeouts"] * 100 <= max_pct * Core.SIM_SEEDS, "%s 시간 초과 %d판 (%d%% 초과)" % [row[0], st["timeouts"], max_pct])
	return _result(errs)


## 세 번 베기 하나만 되풀이하는 상대(확률 1.0, 대기 1.0초 고정). 로드한 자원은 고치지 않는다.
func _three_strike_opponent() -> OpponentData:
	var real := load(OPPONENT_PATH) as OpponentData
	var root: AttackData = null
	for atk in real.attacks:
		if atk.attack_name == "세 번 베기":
			root = atk
	if root == null:
		return null
	var drill := real.drill(root)
	drill.opening_chance = 1.0
	drill.idle_time_min = 1.0
	drill.idle_time_max = 1.0
	return drill


## T92: 패턴의 막음은 타격마다 "막아낸 횟수"에 든다(결정 430). 높이만 틀린 막기도 지기의 "틀린 막기"다.
func t92_throw_with_patterns() -> String:
	var errs: Array[String] = []
	var opp := _three_strike_opponent()
	if opp == null:
		return "세 번 베기를 찾지 못함"
	var conditions := _conditions(THROW_PATH)
	# 1. 들고 막는 봇이 세 번 베기 하나를 다 막으면 막힘·패리인 타격이 3이다.
	var stop_third: Callable = _h.call("_stop_at", DuelRecord.STRIKE, 3)
	var held: Variant = _h.call("_run", opp, {}, stop_third, Core.BASE_DELTA, 40.0, 1, conditions, false)
	var blocks := 0
	var strikes: Array[Dictionary] = held.core.record.of_type(DuelRecord.STRIKE)
	for ev in strikes.slice(0, 3):
		if ev["result"] == DT.StrikeResult.BLOCKED or ev["result"] == DT.StrikeResult.PARRIED:
			blocks += 1
	if strikes.size() < 3 or blocks != 3:
		errs.append("세 번 베기를 다 막았을 때 막힘·패리 %d (기대 3, 타격 %d번)" % [blocks, strikes.size()])
	# 2. 첫 타격을 높이만 틀리게 막으면 틀린 막기이고 까닭이 높이다.
	var wrong: Callable = func(_a: AttackData, _i: int) -> StringName: return &"wrong_height"
	var stop_first: Callable = _h.call("_stop_at", DuelRecord.STRIKE, 1)
	var missed: Variant = _h.call("_run", opp, {"guard_fn": wrong}, stop_first, Core.BASE_DELTA, 40.0, 1, conditions, false)
	var first: Array[Dictionary] = missed.core.record.of_type(DuelRecord.STRIKE)
	if first.is_empty():
		errs.append("높이를 틀린 판에 타격이 없음")
	elif first[0]["situation"] != DT.Situation.WRONG_GUARD or first[0]["guard_miss"] != &"height":
		errs.append("높이를 틀린 첫 타격: 상황 %s · 까닭 %s (기대 틀린 막기 · height)" % [str(first[0]["situation"]), str(first[0]["guard_miss"])])
	return _result(errs)
