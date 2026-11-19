extends RefCounted
## T40, T43: 부위별 데미지 — 부위의 칸 수, 머리 지키기, 조준 표, 판 길이 측정.
## 결투는 core_tests.gd의 도우미로 돌린다. 모자 없는 판(게임의 기본)은 도우미에 모자 여부를 거짓으로 넘긴다.
## 통과 조건은 테스트가 직접 만든 상대(칸 수와 머리 지키기를 직접 적는다)로 본다.
## 로드한 .tres의 값으로 잰 것은 INFO 줄이다(.tres의 조율이 테스트를 깨지 않게).

const Core := preload("res://tests/core_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const SCHEDULE_PATH := "res://data/day_schedule.tres"
const COMMISSION_DIRS: Array[String] = ["res://data/commissions/", "res://data/commissions/variants/"]
const FEATHER_PATH := "res://data/commissions/feather_cut.tres"

const AIM_MID_THRUST := [DT.Direction.CENTER, DT.Height.MID]
const AIM_HEAD_THRUST := [DT.Direction.CENTER, DT.Height.HIGH]

var _h := Core.new()


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T40", "name": "부위의 칸 수, 머리 지키기, 조준 표", "fn": t40_part_cells},
		{"id": "T43", "name": "부위별 데미지의 판 길이 (모자 없는 자유 결투, 시드 %d개)" % Core.SIM_SEEDS, "fn": t43_lengths},
		{"id": "T46", "name": "패리 뒤의 여유: 패리 덧붙임 0.55초와 0.85초", "fn": t46_parry_window},
	]


func cleanup() -> void:
	_h.cleanup()
	_h = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


## 칼 든 쪽 베기의 조준. 중단이면 칼 든 팔, 상단이면(모자 없는 판) 칼 든 손이다.
func _sword_side_cut(opp: OpponentData, height: int) -> Array:
	return [opp.sword_side, height]


## 반대쪽 베기의 조준. 상단이면(모자 없는 판) 머리, 모자를 쓴 판이면 모자다.
func _off_side_cut(opp: OpponentData, height: int) -> Array:
	var side: int = DT.Direction.RIGHT if opp.sword_side == DT.Direction.LEFT else DT.Direction.LEFT
	return [side, height]


func _guard_all() -> Callable:
	return func(_a: AttackData, _i: int) -> StringName: return &"hold"


func _parry_all() -> Callable:
	return func(_a: AttackData, _i: int) -> StringName: return &"parry"


func _counter(aim: Array) -> Callable:
	return func(_ev: Dictionary) -> Variant: return aim


## 첫 공격 판정까지 돌린다. 모자 없는 판이 기본이다.
func _first_attack(opp: OpponentData, cfg: Dictionary, has_hat := false, delta := Core.BASE_DELTA) -> Dictionary:
	var stop := func(record: DuelRecord) -> int: return _h._nth_index(record, DuelRecord.ATTACK, 1)
	var conditions: Array[CommissionCondition] = []
	var r := _h._run(opp, cfg, stop, delta, 40.0, 1, conditions, has_hat)
	if r.stop_index < 0:
		return {}
	var ev: Dictionary = r.core.record.events[r.stop_index].duplicate()
	# 판정 시각에 상대의 회수가 아직 남아 있었는가(피한 공격은 회수를 끝내지 않는다).
	ev["recovery_left"] = r.core.brain.state == DT.OpponentState.RECOVERY and r.core.brain.state_end > float(ev["t"])
	ev["stagger_started"] = not r.core.record.of_type(DuelRecord.STAGGER_START).is_empty()
	return ev


## 공격이 하나뿐인 테스트용 상대에 머리 2칸과 머리 지키기를 직접 적은 것.
func _guarded_opp(kind: String, guards := true, with_habit := false, posture := -1) -> OpponentData:
	var o := _h._make_marked_opp(kind, true) if with_habit else _h._make_opp(kind, false, posture)
	o.graze_head = 2
	o.guards_head = guards
	return o


func _is_graze(ev: Dictionary, part: int, cells: int) -> bool:
	return not ev.is_empty() and ev["result"] == DT.AttackResult.GRAZE and ev["part"] == part \
		and ev["cells"] == cells and ev["dodged"] == false


# ================================================================ T40

func t40_part_cells() -> String:
	var errs: Array[String] = []
	var P := DT.Part
	var AR := DT.AttackResult
	var D := DT.Direction
	var H := DT.Height

	# ---- 조준 표: 모자 없는 판 / 모자를 쓴 판, 칼 든 쪽이 왼쪽인 상대와 오른쪽인 상대
	for sword_side: int in [D.LEFT, D.RIGHT]:
		var off_side: int = D.RIGHT if sword_side == D.LEFT else D.LEFT
		# [방향, 높이, 모자 없는 판의 부위, 모자를 쓴 판의 부위]
		var table := [
			[D.CENTER, H.HIGH, P.HEAD, P.HEAD],
			[sword_side, H.HIGH, P.SWORD_HAND, P.HAT],
			[off_side, H.HIGH, P.HEAD, P.HAT],
			[D.CENTER, H.MID, P.TORSO, P.TORSO],
			[sword_side, H.MID, P.SWORD_ARM, P.SWORD_ARM],
			[off_side, H.MID, P.TORSO, P.TORSO],
			[D.CENTER, H.LOW, P.LEGS, P.LEGS],
			[sword_side, H.LOW, P.LEGS, P.LEGS],
			[off_side, H.LOW, P.LEGS, P.LEGS],
		]
		for row in table:
			var bare := DuelCore.aim_part(row[0], row[1], sword_side)
			var hatted := DuelCore.aim_part(row[0], row[1], sword_side, true)
			_expect(errs, bare == row[2] and hatted == row[3],
				"[조준 표] 칼 든 쪽 %d, 방향 %d, 높이 %d → 모자 없음 %s, 모자 %s (기대 %s, %s)" % [
					sword_side, row[0], row[1], DT.PART_NAMES[bare], DT.PART_NAMES[hatted],
					DT.PART_NAMES[row[2]], DT.PART_NAMES[row[3]]])

	# ---- 기본값: 여섯 부위 모두 1칸이고 머리를 지키지 않는다
	var fresh := OpponentData.new()
	for part in [P.HEAD, P.HAT, P.TORSO, P.SWORD_ARM, P.SWORD_HAND, P.LEGS]:
		_expect(errs, fresh.graze_cells(part) == 1, "[기본값] %s의 칸 수가 1이 아님" % DT.PART_NAMES[part])
	_expect(errs, not fresh.guards_head, "[기본값] 머리를 지킴")

	# ---- 스침의 칸 수 (자세 5, 칼 든 팔 2칸. 막힌 베기 뒤)
	var arm_opp := _h._make_opp("cut", false, 5)
	arm_opp.graze_sword_arm = 2
	var arm_aim := _sword_side_cut(arm_opp, H.MID)
	var arm := _first_attack(arm_opp, {"guard_fn": _guard_all(), "counter_fn": _counter(arm_aim), "max_counters": 1})
	_expect(errs, _is_graze(arm, P.SWORD_ARM, 2) and arm.get("opponent_posture") == 3,
		"[칸 수] 칼 든 팔 스침이 2칸을 깎지 않음: %s" % str(arm))
	var torso := _first_attack(arm_opp, {"guard_fn": _guard_all(), "counter_fn": _counter(AIM_MID_THRUST), "max_counters": 1})
	_expect(errs, _is_graze(torso, P.TORSO, 1) and torso.get("opponent_posture") == 4,
		"[칸 수] 같은 상대의 몸통 스침이 1칸이 아님: %s" % str(torso))

	# ---- 넘치는 칸: 자세 1에 2칸짜리 스침 → 깎인 칸 1, 무너짐이 같은 시각에 시작
	var thin := _h._make_opp("cut", false, 1)
	thin.graze_sword_arm = 2
	var over := _first_attack(thin, {"guard_fn": _guard_all(), "counter_fn": _counter(arm_aim), "max_counters": 1})
	_expect(errs, _is_graze(over, P.SWORD_ARM, 1) and over.get("opponent_posture") == 0 and over.get("stagger_started") == true,
		"[넘치는 칸] 자세 1에 2칸 스침: %s" % str(over))

	# ---- 유효타: 무너진 상대에 넣은 공격은 칸을 깎지 않는다
	var stop_second := func(record: DuelRecord) -> int: return _h._nth_index(record, DuelRecord.ATTACK, 2)
	var no_conditions: Array[CommissionCondition] = []
	var hit_run := _h._run(thin, {"guard_fn": _guard_all(), "counter_fn": _counter(arm_aim), "finisher": arm_aim},
		stop_second, Core.BASE_DELTA, 40.0, 1, no_conditions, false)
	if hit_run.stop_index < 0:
		errs.append("[유효타] 두 번째 공격이 나오지 않음")
	else:
		var hit: Dictionary = hit_run.core.record.events[hit_run.stop_index]
		_expect(errs, hit["result"] == AR.HIT and hit["cells"] == 0 and hit["opponent_posture"] == 0,
			"[유효타] 무너진 상대에 넣은 공격의 깎인 칸이 0이 아님: %s" % str(hit))

	# ---- 0이나 음수로 적은 칸 수는 1칸이다
	var zero := _h._make_opp("cut", false, 5)
	zero.graze_torso = 0
	zero.graze_sword_arm = -3
	var zero_torso := _first_attack(zero, {"guard_fn": _guard_all(), "counter_fn": _counter(AIM_MID_THRUST), "max_counters": 1})
	var zero_arm := _first_attack(zero, {"guard_fn": _guard_all(), "counter_fn": _counter(arm_aim), "max_counters": 1})
	_expect(errs, _is_graze(zero_torso, P.TORSO, 1) and _is_graze(zero_arm, P.SWORD_ARM, 1), "[칸 수 0·음수] 1칸으로 깎이지 않음")

	# ---- 섣부른 공격: 2칸을 깎은 뒤 섣부른 공격이 막히면 돌아오는 칸은 상대 데이터의 값(1) 그대로다
	var rash_opp := _h._make_rash_opp("cut", 1)
	rash_opp.posture_max = 5
	rash_opp.graze_sword_arm = 2
	var rash_run := _h._run(rash_opp, {
			"guard_fn": _guard_all(), "counter_fn": _counter(arm_aim), "max_counters": 1,
			"follow_up": {"aim": AIM_MID_THRUST, "max": 1},
		}, stop_second, Core.BASE_DELTA, 40.0, 1, no_conditions, false)
	if rash_run.stop_index < 0:
		errs.append("[섣부른 공격] 두 번째 공격이 나오지 않음")
	else:
		var rash: Dictionary = rash_run.core.record.events[rash_run.stop_index]
		_expect(errs, rash["result"] == AR.BLOCKED and rash["rash"] == true and rash["posture_gain"] == 1 and rash["opponent_posture"] == 4,
			"[섣부른 공격] 2칸을 깎은 뒤 되찾은 칸이 1이 아님: %s" % str(rash))

	# ---- 머리 지키기 (머리 2칸, 머리를 지키는 상대, 모자 없는 판)
	var head_cfg := {"guard_fn": _guard_all(), "counter_fn": _counter(AIM_HEAD_THRUST), "max_counters": 1}
	var parry_head_cfg := {"guard_fn": _parry_all(), "counter_fn": _counter(AIM_HEAD_THRUST), "max_counters": 1}

	# 막힌 일반 베기 뒤 상단 찌르기 → 피한다
	var dodged := _first_attack(_guarded_opp("cut"), head_cfg)
	_expect(errs, not dodged.is_empty() and dodged["result"] == AR.BLOCKED and dodged["dodged"] == true and dodged["part"] == P.HEAD,
		"[지키기] 막힌 베기 뒤의 머리가 피해지지 않음: %s" % str(dodged))
	if not dodged.is_empty():
		_expect(errs, dodged["rash"] == false and dodged["posture_gain"] == 0 and dodged["cells"] == 0,
			"[지키기] 피한 공격이 섣부른 공격이거나 칸이 움직임: %s" % str(dodged))
		_expect(errs, dodged["opponent_posture"] == _guarded_opp("cut").posture_max, "[지키기] 피했는데 상대 자세가 변함")
		_expect(errs, dodged["recovery_left"] == true, "[지키기] 피한 공격이 상대의 회수를 끝냄")

	# 패리한 찌르기 뒤 상단 찌르기 → 머리 스침 2칸
	var parried_thrust := _first_attack(_guarded_opp("thrust"), parry_head_cfg)
	_expect(errs, _is_graze(parried_thrust, P.HEAD, 2), "[지키기] 패리한 찌르기 뒤 머리 스침이 아님: %s" % str(parried_thrust))

	# 패리한 베기 뒤 상단 반대쪽 베기 → 머리 스침 2칸
	var cut_opp := _guarded_opp("cut")
	var parried_cut := _first_attack(cut_opp, {
		"guard_fn": _parry_all(), "counter_fn": _counter(_off_side_cut(cut_opp, H.HIGH)), "max_counters": 1})
	_expect(errs, _is_graze(parried_cut, P.HEAD, 2), "[지키기] 패리한 베기 뒤 반대쪽 상단 베기가 머리 스침이 아님: %s" % str(parried_cut))

	# 올려 막은 큰 베기(네 번째 공격) 뒤 상단 찌르기 → 머리 스침
	var after_big := func(ev: Dictionary) -> Variant:
		return AIM_HEAD_THRUST if (ev["attack"] as AttackData).is_big else null
	var big := _first_attack(_guarded_opp("cut", true, true), {"guard_fn": _guard_all(), "counter_fn": after_big})
	_expect(errs, _is_graze(big, P.HEAD, 2), "[지키기] 올려 막은 큰 베기 뒤 머리 스침이 아님: %s" % str(big))

	# 헛친 큰 베기 뒤 전진하고 상단 찌르기 → 머리 스침(큰 공격의 회수는 헛쳐도 크게 열린다)
	var retreat_on_big := func(a: AttackData, _i: int) -> StringName:
		return &"retreat" if a.is_big else &"hold"
	var whiffed := _first_attack(_guarded_opp("cut", true, true), {"guard_fn": retreat_on_big, "whiff_fn": _counter(AIM_HEAD_THRUST)})
	_expect(errs, _is_graze(whiffed, P.HEAD, 2), "[지키기] 헛친 큰 베기 뒤 머리 스침이 아님: %s" % str(whiffed))

	# 무너진 상대에 상단 찌르기 → 머리 유효타
	var stagger_run := _h._run(_guarded_opp("cut", true, false, 1),
		{"guard_fn": _guard_all(), "counter_fn": _counter(AIM_MID_THRUST), "finisher": AIM_HEAD_THRUST},
		stop_second, Core.BASE_DELTA, 40.0, 1, no_conditions, false)
	if stagger_run.stop_index < 0:
		errs.append("[지키기] 무너진 상대에 넣은 공격이 나오지 않음")
	else:
		var finish: Dictionary = stagger_run.core.record.events[stagger_run.stop_index]
		_expect(errs, finish["result"] == AR.HIT and finish["part"] == P.HEAD and finish["dodged"] == false,
			"[지키기] 무너진 상대의 머리에 유효타가 아님: %s" % str(finish))

	# 머리를 지키지 않으면 막힌 일반 베기 뒤에도 머리에 닿는다
	var unguarded := _first_attack(_guarded_opp("cut", false), head_cfg)
	_expect(errs, _is_graze(unguarded, P.HEAD, 2), "[지키기 끔] 막힌 베기 뒤 머리 스침이 아님: %s" % str(unguarded))

	# 지키는 것은 머리뿐이다: 막힌 일반 베기 뒤의 몸통과 칼 든 팔은 스침이다
	var body := _first_attack(_guarded_opp("cut"), {"guard_fn": _guard_all(), "counter_fn": _counter(AIM_MID_THRUST), "max_counters": 1})
	var body_arm := _first_attack(_guarded_opp("cut"), {"guard_fn": _guard_all(), "counter_fn": _counter(arm_aim), "max_counters": 1})
	_expect(errs, _is_graze(body, P.TORSO, 1) and _is_graze(body_arm, P.SWORD_ARM, 1), "[지키기] 머리를 지키는 상대의 몸통·팔이 스침이 아님")

	# 모자를 쓴 판: 막힌 베기 뒤(밀착) 상단 반대쪽 베기는 모자 스침이다(머리 지키기와 무관)
	var hat_opp := _guarded_opp("cut")
	var hat := _first_attack(hat_opp, {
			"guard_fn": _guard_all(), "counter_fn": _counter(_off_side_cut(hat_opp, H.HIGH)), "max_counters": 1,
			"want_distance": DT.Distance.CLOSE,
		}, true)
	_expect(errs, _is_graze(hat, P.HAT, 1), "[모자] 모자를 쓴 판의 상단 베기가 모자 스침이 아님: %s" % str(hat))

	# ---- delta 무관: 패리한 찌르기 뒤의 머리 스침과 막힌 베기 뒤의 피함
	for label in ["스침", "피함"]:
		var signatures: Array = []
		for delta in Core.DELTAS:
			var ev := _first_attack(_guarded_opp("thrust"), parry_head_cfg, false, delta) if label == "스침" \
				else _first_attack(_guarded_opp("cut"), head_cfg, false, delta)
			signatures.append([ev.get("result"), ev.get("part"), ev.get("cells"), ev.get("dodged")])
		_expect(errs, signatures[0] == signatures[1] and signatures[1] == signatures[2],
			"[delta] 머리 %s의 판정이 delta에 따라 다름: %s" % [label, str(signatures)])

	# ---- 로드한 상대: 여섯 부위의 칸 수가 1 이상이다(값 자체는 조율값이라 INFO다)
	var real := load(OPPONENT_PATH) as OpponentData
	var raw := [real.graze_head, real.graze_hat, real.graze_torso, real.graze_sword_arm, real.graze_sword_hand, real.graze_legs]
	for value: int in raw:
		_expect(errs, value >= 1, "[로드한 상대] 칸 수 %d (1 이상이어야 함)" % value)
	print("  INFO %s의 칸 수: 머리 %d, 모자 %d, 몸통 %d, 칼 든 팔 %d, 칼 든 손 %d, 다리 %d, 머리를 지킨다 %s" % [
		real.display_name, raw[0], raw[1], raw[2], raw[3], raw[4], raw[5], str(real.guards_head)])

	# ---- 의뢰: 모자를 노리는 조건을 가진 의뢰는 상대가 모자를 쓴다
	var commissions: Array[Commission] = []
	for dir_path in COMMISSION_DIRS:
		for file in DirAccess.get_files_at(dir_path):
			if file.ends_with(".tres"):
				var loaded := load(dir_path + file) as Commission
				if loaded != null:
					commissions.append(loaded)
	var schedule := load(SCHEDULE_PATH) as DaySchedule
	if schedule != null:
		for day in schedule.days:
			if day != null:
				for commission in day.commissions:
					if commission != null and not commissions.has(commission):
						commissions.append(commission)
	_expect(errs, (load(FEATHER_PATH) as Commission).opponent_wears_hat, "[의뢰] 깃털 자르기의 상대가 모자를 쓰지 않음")
	for commission in commissions:
		for condition in commission.conditions:
			var target := condition as TargetPartCondition
			if target != null and target.target_part == P.HAT:
				_expect(errs, commission.opponent_wears_hat, "[의뢰] %s: 모자를 노리는데 상대가 모자를 쓰지 않음" % commission.client_name)
	return _result(errs)


# ================================================================ T43 판 길이

## 팔 봇의 평균이 몸통 봇의 평균보다 이만큼(초) 이상 짧아야 한다(2칸이 실제로 판을 줄인다).
const ARM_MEAN_GAP := 5.0


## 막기만 하고, 빈틈이 생기면 aim_fn(타격 이벤트)이 고른 곳을 친다. 무너지면 중단 찌르기로 끝낸다.
func _cfg_guard(aim_fn: Callable) -> Callable:
	return func() -> Dictionary:
		return {
			"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold",
			"counter_fn": func(ev: Dictionary) -> Variant:
				return aim_fn.call(ev) if float(ev["recovery"]) > 0.0 else null,
			"finisher": AIM_MID_THRUST,
		}


## 전부 패리하고 aim_fn(타격 이벤트)이 고른 곳을 친다.
func _cfg_parry(aim_fn: Callable) -> Callable:
	return func() -> Dictionary:
		return {
			"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"parry",
			"counter_fn": func(ev: Dictionary) -> Variant: return aim_fn.call(ev),
			"finisher": AIM_MID_THRUST,
		}


## 받아치기를 타격 delay초 뒤에 누르는 손.
func _late(cfg_fn: Callable, delay: float) -> Callable:
	return func() -> Dictionary:
		var cfg: Dictionary = cfg_fn.call()
		cfg["counter_delay"] = delay
		return cfg


## 봇 일곱. 이름 → 설정을 만드는 함수.
func _bots(opp: OpponentData) -> Dictionary:
	var arm_aim := _sword_side_cut(opp, DT.Height.MID)
	var to_arm := func(_ev: Dictionary) -> Variant: return arm_aim
	var to_head := func(_ev: Dictionary) -> Variant: return AIM_HEAD_THRUST
	# 느린 손의 무난한 플레이: 큰 베기 뒤에만 칼 든 팔, 나머지 빈틈에는 몸통.
	var big_only := func(ev: Dictionary) -> Variant:
		return arm_aim if (ev["attack"] as AttackData).is_big else AIM_MID_THRUST
	# 가운데로 온 공격(찌르기, 큰 베기)을 패리하면 머리, 베기를 패리하면 칼 든 팔.
	var two_cells := func(ev: Dictionary) -> Variant:
		return AIM_HEAD_THRUST if (ev["attack"] as AttackData).direction == DT.Direction.CENTER else arm_aim
	return {
		"torso": _h._cfg_guard_only,
		"arm": _cfg_guard(to_arm),
		"big": _cfg_guard(big_only),
		"head": _cfg_guard(to_head),
		"parry_torso": _h._cfg_parry_all,
		"parry_two": _cfg_parry(two_cells),
		"keep": _h._cfg_guard_keep,
	}


const BOT_NAMES := {
	"torso": "몸통 봇", "arm": "팔 봇", "big": "큰 빈틈 봇", "head": "막기·머리 봇",
	"parry_torso": "패리·몸통 봇", "parry_two": "패리·2칸 봇", "keep": "누르고만 있는 봇",
}


## 모자 없는 자유 결투로 잰다.
func _sim(opp: OpponentData, cfg_fn: Callable) -> Dictionary:
	var no_conditions: Array[CommissionCondition] = []
	return _h._simulate(opp, cfg_fn, no_conditions, false)


func _same(a: Dictionary, b: Dictionary) -> bool:
	return is_equal_approx(a["mean"], b["mean"]) and is_equal_approx(a["min"], b["min"]) and is_equal_approx(a["max"], b["max"])


func _opp_line(label: String, opp: OpponentData) -> String:
	return "  INFO [%s] 자세 %d · 머리 %d · 모자 %d · 몸통 %d · 칼 든 팔 %d · 칼 든 손 %d · 다리 %d · 머리를 지킨다 %s" % [
		label, opp.posture_max, opp.graze_head, opp.graze_hat, opp.graze_torso, opp.graze_sword_arm,
		opp.graze_sword_hand, opp.graze_legs, str(opp.guards_head)]


func _line(label: String, st: Dictionary) -> String:
	return _h._stat_line(label, st) + ", 2칸 스침 %.1f회/판, 피함 %.1f회/판, 큰 베기 %.1f회/판" % [
		st["big_grazes"], st["dodges"], st["big"]]


func t43_lengths() -> String:
	var errs: Array[String] = []

	# ---- 통과 조건: 테스트가 직접 적은 상대(자세는 실제 상대의 값)
	var two := _h._copy_opponent()
	two.graze_sword_arm = 2
	two.graze_sword_hand = 2
	two.graze_head = 2
	two.guards_head = true
	var one := _h._copy_opponent()
	var open := _h._copy_opponent()
	open.graze_sword_arm = 2
	open.graze_sword_hand = 2
	open.graze_head = 2
	open.guards_head = false
	var bots := _bots(two)

	var two_torso := _sim(two, bots["torso"])
	var two_arm := _sim(two, bots["arm"])
	var two_head := _sim(two, bots["head"])
	var two_parry_torso := _sim(two, bots["parry_torso"])
	var two_parry_two := _sim(two, bots["parry_two"])
	var one_torso := _sim(one, bots["torso"])
	var one_arm := _sim(one, bots["arm"])
	var open_head := _sim(open, bots["head"])

	# 1. 칸 수와 머리 지키기는 몸통 1칸의 길을 건드리지 않는다.
	_expect(errs, _same(two_torso, one_torso), "[1] 몸통 봇이 2칸 상대(%.1f초)와 1칸 상대(%.1f초)에서 다름" % [two_torso["mean"], one_torso["mean"]])
	# 2. 팔 봇은 전부 이긴다.
	_expect(errs, two_arm["wins"] == Core.SIM_SEEDS and two_arm["timeouts"] == 0, "[2] 팔 봇: 승 %d, 시간 초과 %d" % [two_arm["wins"], two_arm["timeouts"]])
	# 3. 2칸이 실제로 판을 줄인다.
	_expect(errs, two_arm["mean"] <= two_torso["mean"] - ARM_MEAN_GAP, "[3] 팔 봇 평균 %.1f초가 몸통 봇 평균 %.1f초보다 %.0f초 이상 짧지 않음" % [two_arm["mean"], two_torso["mean"], ARM_MEAN_GAP])
	# 4. 패리하는 손에게도 2칸이 판을 줄인다.
	_expect(errs, two_parry_two["mean"] < two_parry_torso["mean"], "[4] 패리·2칸 봇 평균 %.1f초가 패리·몸통 봇 평균 %.1f초보다 짧지 않음" % [two_parry_two["mean"], two_parry_torso["mean"]])
	# 5. 칸 수가 전부 1이면 팔은 이득이 아니다(베기가 찌르기보다 늦게 닿는다).
	_expect(errs, one_arm["mean"] >= one_torso["mean"], "[5] 1칸 상대에서 팔 봇 평균 %.1f초가 몸통 봇 평균 %.1f초보다 짧음" % [one_arm["mean"], one_torso["mean"]])
	# 6. 머리 지키기: 막기만으로는 머리가 큰 베기 뒤에만 열린다. 지키기를 끄면 머리가 가장 빠른 길이다.
	_expect(errs, two_head["mean"] > two_torso["mean"], "[6] 머리를 지키는데 막기·머리 봇 평균 %.1f초가 몸통 봇 평균 %.1f초보다 길지 않음" % [two_head["mean"], two_torso["mean"]])
	var head_shorter := 0
	for i in Core.SIM_SEEDS:
		if two_head["lengths"][i] <= two_torso["lengths"][i]:
			head_shorter += 1
	_expect(errs, head_shorter == 0, "[6] 머리를 지키는데 막기·머리 봇이 몸통 봇보다 길지 않은 시드 %d개" % head_shorter)
	_expect(errs, open_head["mean"] < two_torso["mean"], "[6] 머리 지키기를 껐는데 막기·머리 봇 평균 %.1f초가 몸통 봇 평균 %.1f초보다 짧지 않음" % [open_head["mean"], two_torso["mean"]])

	# 7. 로드한 값의 사본은 칸 수와 머리 지키기를 잃지 않는다(INFO의 측정이 이 사본으로 잰다).
	var real := load(OPPONENT_PATH) as OpponentData
	var copy := real.duplicate() as OpponentData
	var stats := {}
	for name: String in bots:
		stats[name] = _sim(copy, bots[name])
	_expect(errs, _same(stats["arm"], _sim(real, bots["arm"])) and _same(stats["torso"], _sim(real, bots["torso"])),
		"[7] 로드한 상대의 사본으로 잰 팔 봇·몸통 봇이 실제 상대로 잰 것과 다름")
	_expect(errs, real.posture_max == copy.posture_max and real.graze_sword_arm == copy.graze_sword_arm \
		and real.graze_head == copy.graze_head and real.guards_head == copy.guards_head, "[7] 사본이 값을 잃음")

	# ---- INFO (통과 조건 아님): 전부 로드한 값의 사본으로 잰다. 변형은 사본의 값 필드만 고친다.
	print("  INFO 부위별 데미지의 판 길이: 시드 1..%d, 모자 없는 자유 결투" % Core.SIM_SEEDS)
	print(_opp_line("로드한 값", copy))
	for name: String in bots:
		print(_line(BOT_NAMES[name], stats[name]))

	# 늦게 누르는 손
	var late_arm_10 := _sim(copy, _late(bots["arm"], 0.10))
	print(_line("팔 봇 · 0.10초 늦게 누름", late_arm_10))
	print(_line("팔 봇 · 0.20초 늦게 누름", _sim(copy, _late(bots["arm"], 0.20))))
	print(_line("큰 빈틈 봇 · 0.20초 늦게 누름", _sim(copy, _late(bots["big"], 0.20))))

	# 머리 지키기를 뒤집었을 때(로드한 값이 참이면 끔, 거짓이면 켬)
	var flipped := real.duplicate() as OpponentData
	flipped.guards_head = not real.guards_head
	print(_opp_line("머리 지키기만 뒤집음", flipped))
	print(_line("막기·머리 봇", _sim(flipped, bots["head"])))
	print(_line("패리·2칸 봇", _sim(flipped, bots["parry_two"])))

	# 칼 든 팔만 1칸으로(머리가 팔에 가려지는지 볼 수 있게)
	var arm_one := real.duplicate() as OpponentData
	arm_one.graze_sword_arm = 1
	print(_opp_line("칼 든 팔만 1칸", arm_one))
	for name: String in ["arm", "big", "parry_two"]:
		print(_line(BOT_NAMES[name], _sim(arm_one, bots[name])))

	# 상대 자세 칸 수
	for posture: int in [11, 12, 13, 14]:
		var alt := real.duplicate() as OpponentData
		alt.posture_max = posture
		var same_as_loaded: bool = posture == real.posture_max
		print(_opp_line("자세 %d칸" % posture, alt))
		for name: String in ["arm", "big", "parry_two", "torso", "keep"]:
			var st: Dictionary = stats[name] if same_as_loaded else _sim(alt, bots[name])
			print(_line("자세 %d칸 · %s" % [posture, BOT_NAMES[name]], st))
		var late: Dictionary = late_arm_10 if same_as_loaded else _sim(alt, _late(bots["arm"], 0.10))
		print(_line("자세 %d칸 · 팔 봇 · 0.10초 늦게 누름" % posture, late))
	return _result(errs)


# ================================================================ T46 패리 뒤의 여유

const AIM_HIGH_CUT := [DT.Direction.RIGHT, DT.Height.HIGH]
## 견주는 두 패리 덧붙임(초): 계획 008 앞의 값과 뒤의 값. 테스트가 직접 적는다.
const BONUS_BEFORE := 0.55
const BONUS_AFTER := 0.85


## 찌르기만 하는 테스트용 상대에 패리 덧붙임을 직접 적은 것.
func _thrust_opp(bonus: float) -> OpponentData:
	var o := _h._make_opp("thrust")
	o.parried_recovery_bonus = bonus
	return o


## 실제 상대를 베껴(칸 수는 전부 1, 머리를 지키지 않는다) 패리 덧붙임을 직접 적은 것.
func _bonus_copy(bonus: float) -> OpponentData:
	var o := _h._copy_opponent()
	o.parried_recovery_bonus = bonus
	return o


func t46_parry_window() -> String:
	var errs: Array[String] = []
	var AR := DT.AttackResult

	# ---- 패리한 찌르기 뒤 0.40초 늦게 누른 중단 찌르기
	var late_cfg := {"guard_fn": _parry_all(), "counter_fn": _counter(AIM_MID_THRUST), "max_counters": 1, "counter_delay": 0.40}
	var late_after := _first_attack(_thrust_opp(BONUS_AFTER), late_cfg)
	_expect(errs, _is_graze(late_after, DT.Part.TORSO, 1), "[덧붙임 %.2f] 0.40초 늦은 중단 찌르기가 스침이 아님: %s" % [BONUS_AFTER, str(late_after)])
	var late_before := _first_attack(_thrust_opp(BONUS_BEFORE), late_cfg)
	_expect(errs, not late_before.is_empty() and late_before["result"] == AR.BLOCKED and late_before["rash"] == false,
		"[덧붙임 %.2f] 0.40초 늦은 중단 찌르기가 (섣부르지 않은) 막힘이 아님: %s" % [BONUS_BEFORE, str(late_before)])

	# ---- 패리한 찌르기 뒤 곧바로 누른 상단 베기(모자 없는 판이라 머리다)
	var high_cfg := {"guard_fn": _parry_all(), "counter_fn": _counter(AIM_HIGH_CUT), "max_counters": 1}
	var high_after := _first_attack(_thrust_opp(BONUS_AFTER), high_cfg)
	_expect(errs, not high_after.is_empty() and high_after["result"] == AR.GRAZE, "[덧붙임 %.2f] 곧바로 누른 상단 베기가 스침이 아님: %s" % [BONUS_AFTER, str(high_after)])
	var high_before := _first_attack(_thrust_opp(BONUS_BEFORE), high_cfg)
	_expect(errs, not high_before.is_empty() and high_before["result"] == AR.BLOCKED, "[덧붙임 %.2f] 곧바로 누른 상단 베기가 막힘이 아님: %s" % [BONUS_BEFORE, str(high_before)])

	# ---- 판 길이: 늦는 손은 덧붙임이 길면 짧아지고, 늦지 않는 봇은 달라지지 않는다
	var before := _bonus_copy(BONUS_BEFORE)
	var after := _bonus_copy(BONUS_AFTER)
	var late_parry := _late(_h._cfg_parry_all, 0.40)
	var slow_before := _sim(before, late_parry)
	var slow_after := _sim(after, late_parry)
	_expect(errs, slow_after["mean"] < slow_before["mean"], "0.40초 늦는 패리·몸통 봇의 평균이 덧붙임 %.2f(%.1f초)에서 %.2f(%.1f초)보다 짧지 않음" % [
		BONUS_AFTER, slow_after["mean"], BONUS_BEFORE, slow_before["mean"]])
	var fast_before := _sim(before, _h._cfg_parry_all)
	var fast_after := _sim(after, _h._cfg_parry_all)
	_expect(errs, _same(fast_before, fast_after), "늦지 않는 패리·몸통 봇의 판 길이가 덧붙임에 따라 다름 (%.1f초, %.1f초)" % [fast_before["mean"], fast_after["mean"]])

	# ---- INFO (통과 조건 아님): 로드한 값의 사본과, 같은 사본에서 패리 덧붙임만 되돌린 것
	var real := load(OPPONENT_PATH) as OpponentData
	var loaded := real.duplicate() as OpponentData
	var reverted := real.duplicate() as OpponentData
	reverted.parried_recovery_bonus = BONUS_BEFORE
	var bots := _bots(loaded)
	for row in [["로드한 값", loaded], ["패리 덧붙임만 %.2f로" % BONUS_BEFORE, reverted]]:
		var opp: OpponentData = row[1]
		print("  INFO [%s] 패리 덧붙임 %.2f초 · 자세 %d" % [row[0], opp.parried_recovery_bonus, opp.posture_max])
		for name: String in ["parry_torso", "parry_two"]:
			for delay: float in [0.20, 0.30, 0.40]:
				print(_line("%s · %.2f초 늦게 누름" % [BOT_NAMES[name], delay], _sim(opp, _late(bots[name], delay))))
	return _result(errs)
