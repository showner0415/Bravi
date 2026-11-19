extends RefCounted
## T49~T51: 선공 — 방심과 런지의 규칙, 밸런스, 표시.
## 결투는 core_tests.gd의 도우미로 돌린다. 통과 조건의 상대는 도우미가 베낀 상대(방심의 값은 옮겨지지 않는다)에
## 방심의 값을 직접 적은 것, 무기는 엉킴 없는 사본에 런지의 값을 직접 적은 것이다. 모자 없는 판이다.
## 로드한 .tres의 값으로 잰 것은 INFO 줄이다.

const Core := preload("res://tests/core_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DUEL_PATH := "res://scenes/duel/duel.tscn"

const AIM_MID_THRUST := [DT.Direction.CENTER, DT.Height.MID]

## 테스트가 적는 값: 방심하는 데 걸리는 시간(초), 한 판에 찔리는 횟수의 상한, 런지의 예비와 회수(초), 상대 자세.
const COMPLACENT_TIME := 20.0
const COMPLACENT_LIMIT := 1
const LUNGE_WINDUP := 0.50
const LUNGE_RECOVER := 0.45
const POSTURE := 9
## 예정 시각을 견줄 때의 여유(초).
const TIME_EPS := 0.001
## 조건 5의 ①: 선공을 붙인 기준 봇의 평균이 붙이지 않은 평균의 이 비율 이상이어야 한다.
const GUARD_MEAN_RATIO_MIN := 0.85
## 조건 5의 ④와 조건 6: 30판에서 닿은 런지의 합의 하한(봇이 실제로 썼다).
const LANDED_TOTAL_MIN := 15

var _tree: SceneTree
var _h := Core.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T49", "name": "선공의 규칙: 방심 게이지, 런지, 한 판에 한 번, 막히는 세 경우", "fn": t49_lunge_rules},
		{"id": "T50", "name": "선공과 밸런스 (시드 %d개)" % Core.SIM_SEEDS, "fn": t50_balance},
		{"id": "T51", "name": "선공의 표시: 방심 게이지, 상태 글자, 조준 글자의 세 갈래, 기록 줄", "fn": t51_display},
	]


func cleanup() -> void:
	_h.cleanup()
	_h = null
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


func _near(a: float, b: float, eps := TIME_EPS) -> bool:
	return absf(a - b) <= eps


## 런지가 있는 테스트용 무기(엉킴은 없다). windup이 0이면 런지 없는 무기다.
func _lunge_weapon(windup := LUNGE_WINDUP, recover := LUNGE_RECOVER) -> WeaponData:
	var w: WeaponData = _h._weapon()
	w.lunge_windup = windup
	w.lunge_recover = recover
	return w


## 상대에 방심의 두 값을 적어 돌려준다(받은 상대를 고친다. 테스트가 만든 상대만 넘긴다).
func _complacent(opp: OpponentData, time := COMPLACENT_TIME, limit := COMPLACENT_LIMIT) -> OpponentData:
	opp.complacent_time = time
	opp.complacent_limit = limit
	return opp


## 아무것도 하지 않는 상대(대기와 접근이 아주 길다). 내 입력만으로 방심과 런지를 본다.
func _idle_opp(posture := -1) -> OpponentData:
	var o: OpponentData = _h._make_opp("thrust", false, posture)
	o.idle_time_min = 1000.0
	o.idle_time_max = 1000.0
	o.approach_delay = 1000.0
	return o


## 예비 시간을 직접 적은 공격 하나뿐인 상대(왼쪽 베기, 대기 1초 고정).
func _slow_cut_opp(tell_time: float) -> OpponentData:
	var o: OpponentData = _h._make_opp("cut")
	var slow := o.attacks[0].duplicate() as AttackData
	slow.tell_time = tell_time
	var only: Array[AttackData] = [slow]
	o.attacks = only
	return o


func _core(opp: OpponentData, weapon: WeaponData, conditions: Array[CommissionCondition] = []) -> DuelCore:
	return _h._make_core(opp, 1, conditions, false, weapon)


func _tick_until(core: DuelCore, cond: Callable, max_time := 60.0, delta := Core.BASE_DELTA) -> bool:
	while not cond.call():
		if core.ended or core.time >= max_time:
			return false
		core.tick(delta)
	return true


func _tick_to(core: DuelCore, at: float, delta := Core.BASE_DELTA) -> void:
	_tick_until(core, func() -> bool: return core.time >= at, at + 1.0, delta)


func _tick_for(core: DuelCore, seconds: float, delta := Core.BASE_DELTA) -> void:
	_tick_to(core, core.time + seconds - delta * 0.5, delta)


func _last(core: DuelCore, type: StringName) -> Dictionary:
	var events := core.record.of_type(type)
	return events[events.size() - 1] if not events.is_empty() else {}


## 지금의 조준 높이로 런지를 누르고 판정까지 돌린다. [공격 시작 이벤트, 공격 판정 이벤트]. 판정이 없으면 빈 Dictionary.
func _lunge(core: DuelCore, height: int, direction: int = DT.Direction.LEFT, delta := Core.BASE_DELTA) -> Array:
	var before := core.record.of_type(DuelRecord.ATTACK).size()
	core.set_aim(direction, height)
	core.press_attack()
	var start := _last(core, DuelRecord.ATTACK_START)
	_tick_until(core, func() -> bool: return core.record.of_type(DuelRecord.ATTACK).size() > before, core.time + 2.0, delta)
	var judged := core.record.of_type(DuelRecord.ATTACK)
	return [start, judged[judged.size() - 1] if judged.size() > before else {}]


## 교전에 서서 direction을 막은 채 until 시각까지 버틴다(상대의 공격이 하나뿐인 판에서 전부 막힌다).
func _hold_guard_until(core: DuelCore, direction: int, until: float) -> void:
	core.step(1)
	_tick_for(core, core.weapon.step_time + 0.05)
	core.set_aim(direction, DT.Height.MID)
	core.set_guard(true)
	_tick_to(core, until)


## 막기를 풀고 한 걸음 물러나 멀리에 닿은 첫 tick까지 돌린다.
func _retreat_to_far(core: DuelCore) -> bool:
	core.set_guard(false)
	core.step(-1)
	return _tick_until(core, func() -> bool:
		return core.distance == DT.Distance.FAR and core.player_state == DT.PlayerState.READY, core.time + 1.0)


# ================================================================ T49 선공의 규칙

func t49_lunge_rules() -> String:
	var errs: Array[String] = []
	var AR := DT.AttackResult
	var PS := DT.PlayerState
	var H := DT.Height

	# ---- 꺼짐: 방심하지 않는 상대, 또는 런지가 없는 무기 — 멀리의 좌클릭은 지금처럼 헛침이다
	for row in [["방심 시간 0", _complacent(_idle_opp(), 0.0), _lunge_weapon()], ["런지 없는 무기", _complacent(_idle_opp()), _lunge_weapon(0.0)]]:
		var off := _core(row[1], row[2])
		_tick_to(off, 25.0)
		_expect(errs, not off.has_lunge() and not off.is_lunge_now() and is_zero_approx(off.complacency()), "[꺼짐·%s] 선공이 있다고 하거나 게이지가 0이 아님" % row[0])
		var off_ev := _lunge(off, H.MID, DT.Direction.CENTER)
		_expect(errs, off_ev[0]["lunge"] == false and _near(float(off_ev[0]["judge_time"]) - float(off_ev[0]["t"]), off.weapon.thrust_windup),
			"[꺼짐·%s] 멀리의 좌클릭이 보통 찌르기가 아님: %s" % [row[0], str(off_ev[0])])
		_expect(errs, not off_ev[1].is_empty() and off_ev[1]["result"] == AR.WHIFF and off_ev[1]["lunge"] == false and off.distance == DT.Distance.FAR,
			"[꺼짐·%s] 멀리의 좌클릭이 헛침이 아님" % row[0])

	# ---- 게이지: 판 처음에 0, t / 20으로 차고 20초부터 1. 20초 전의 멀리 좌클릭은 헛침이고 게이지를 바꾸지 않는다
	var g := _core(_complacent(_idle_opp()), _lunge_weapon())
	_expect(errs, g.has_lunge() and is_zero_approx(g.complacency()), "[게이지] 판 처음의 게이지가 0이 아님")
	_tick_to(g, 5.0)
	_expect(errs, _near(g.complacency(), g.time / COMPLACENT_TIME) and _near(g.complacency(), 0.25, 0.01), "[게이지] 5초의 게이지 %.4f (기대 0.25)" % g.complacency())
	_expect(errs, not g.is_lunge_now(), "[게이지] 다 차기 전인데 런지가 나간다고 함")
	var early := _lunge(g, H.MID)
	_expect(errs, early[0]["lunge"] == false and early[1].get("result") == AR.WHIFF, "[게이지] 20초 전의 멀리 좌클릭이 헛침이 아님")
	_expect(errs, _near(g.complacency(), g.time / COMPLACENT_TIME), "[게이지] 헛손질이 게이지를 바꿈 (%.4f)" % g.complacency())
	_tick_to(g, COMPLACENT_TIME - 0.1)
	_expect(errs, g.complacency() < 1.0 and not g.is_lunge_now(), "[게이지] 20초 직전인데 다 참")
	_tick_to(g, COMPLACENT_TIME + 0.1)
	_expect(errs, is_equal_approx(g.complacency(), 1.0) and g.is_lunge_now(), "[게이지] 20초 뒤인데 방심하지 않음 (%.4f)" % g.complacency())
	_tick_to(g, 30.0)
	_expect(errs, is_equal_approx(g.complacency(), 1.0), "[게이지] 1에서 멈추지 않음")

	# ---- 닿는다: 조준을 "왼쪽 베기 · 중단"에 두어도 런지는 가운데 찌르기다. delta 셋에서 같다.
	for delta: float in Core.DELTAS:
		var label := "[닿는다 @1/%d]" % roundi(1.0 / delta)
		var hit := _core(_complacent(_idle_opp()), _lunge_weapon())
		_tick_to(hit, COMPLACENT_TIME + 0.1, delta)
		hit.set_aim(DT.Direction.LEFT, H.MID)
		_expect(errs, hit.is_lunge_now() and hit.current_aim_part() == DT.Part.TORSO and not hit.is_rash_now(),
			"%s 런지가 나가는 때의 부위나 섣부른 공격 판단이 다름" % label)
		var top := hit.brain.posture
		var ev := _lunge(hit, H.MID, DT.Direction.LEFT, delta)
		var start: Dictionary = ev[0]
		var judged: Dictionary = ev[1]
		if judged.is_empty():
			errs.append("%s 런지의 판정이 나오지 않음" % label)
			continue
		_expect(errs, start["lunge"] == true and start["direction"] == DT.Direction.CENTER and start["part"] == DT.Part.TORSO,
			"%s 공격 시작 이벤트가 가운데 런지가 아님: %s" % [label, str(start)])
		_expect(errs, _near(float(start["judge_time"]) - float(start["t"]), LUNGE_WINDUP) and _near(float(judged["t"]) - float(start["t"]), LUNGE_WINDUP),
			"%s 판정 시각 − 누른 시각 %.4f (기대 %.2f)" % [label, float(judged["t"]) - float(start["t"]), LUNGE_WINDUP])
		_expect(errs, judged["result"] == AR.GRAZE and judged["part"] == DT.Part.TORSO and judged["cells"] == 1 and judged["rash"] == false \
			and judged["lunge"] == true and judged["pressed_distance"] == DT.Distance.FAR and judged["distance"] == DT.Distance.ENGAGE,
			"%s 판정이 몸통 1칸 스침(섣부른 공격 아님, 멀리에서 눌러 교전에 닿음)이 아님: %s" % [label, str(judged)])
		# 간격 이벤트(교전, 플레이어)가 같은 시각에 먼저 오고 공격 판정이 뒤따른다.
		var moved := _last(hit, DuelRecord.DISTANCE)
		_expect(errs, not moved.is_empty() and moved["distance"] == DT.Distance.ENGAGE and moved["by"] == "player" and _near(moved["t"], judged["t"]) \
			and hit.record.events.find(moved) < hit.record.events.find(judged), "%s 교전에 닿는 간격 이벤트가 판정보다 먼저가 아님" % label)
		_expect(errs, hit.brain.posture == top - 1 and hit.brain.state == DT.OpponentState.IDLE and hit.brain.lunge_touches == 1,
			"%s 닿은 뒤 상대의 자세·상태·찔린 횟수가 다름" % label)
		_expect(errs, hit.player_state == PS.RECOVER and _near(hit.player_state_end, float(judged["t"]) + LUNGE_RECOVER), "%s 판정 뒤 회수 %.2f초가 아님" % [label, LUNGE_RECOVER])
		_tick_to(hit, float(judged["t"]) + LUNGE_RECOVER + 0.05, delta)
		_expect(errs, hit.player_state == PS.READY, "%s 회수 뒤 준비가 아님" % label)

		# 횟수 제한을 푼 사본: 판정 뒤 t초의 게이지가 t / 20이다(delta 무관).
		var free := _core(_complacent(_idle_opp(), COMPLACENT_TIME, 0), _lunge_weapon())
		_tick_to(free, COMPLACENT_TIME + 0.1, delta)
		var free_ev := _lunge(free, H.MID, DT.Direction.LEFT, delta)
		_tick_to(free, float(free_ev[1]["t"]) + 5.0, delta)
		_expect(errs, _near(free.complacency(), (free.time - float(free_ev[1]["t"])) / COMPLACENT_TIME),
			"%s 제한을 푼 사본에서 판정 뒤의 게이지 %.4f가 (지난 시간 / 20)이 아님" % [label, free.complacency()])

	# ---- 한 판에 한 번: 닿은 뒤에는 그 판에서 다시 방심하지 않는다
	var once := _core(_complacent(_idle_opp()), _lunge_weapon())
	_tick_to(once, COMPLACENT_TIME + 0.1)
	var once_top := once.brain.posture
	var once_ev := _lunge(once, H.MID)
	_tick_to(once, float(once_ev[1]["t"]) + LUNGE_RECOVER + 0.05)
	# 닿은 직후 교전에서 낸 보통 공격은 섣부른 공격이다(상대는 빈틈이 아니라 대기다).
	_expect(errs, once.is_rash_now(), "[한 번] 런지가 닿은 직후의 교전이 빈틈으로 판단됨")
	var again := _lunge(once, H.MID, DT.Direction.CENTER)
	_expect(errs, again[0]["lunge"] == false and again[1].get("result") == AR.BLOCKED and again[1].get("rash") == true and again[1].get("posture_gain") == 1 \
		and once.brain.posture == once_top, "[한 번] 닿은 직후의 한 번 더가 칸을 돌려주는 섣부른 막힘이 아님: %s" % str(again[1]))
	_tick_for(once, once.weapon.recover_time + 0.05)
	once.step(-1)
	_tick_for(once, 25.0)
	_expect(errs, once.distance == DT.Distance.FAR and is_zero_approx(once.complacency()) and once.brain.is_wary() and not once.is_lunge_now(),
		"[한 번] 찔린 뒤 25초가 지났는데 다시 방심함 (게이지 %.3f)" % once.complacency())
	var whiff := _lunge(once, H.MID)
	_expect(errs, whiff[0]["lunge"] == false and whiff[1].get("result") == AR.WHIFF, "[한 번] 찔린 뒤의 멀리 좌클릭이 헛침이 아님")

	# 횟수 제한을 푼 사본(상한 0)에서는 20초 뒤의 런지가 또 닿는다.
	var twice := _core(_complacent(_idle_opp(), COMPLACENT_TIME, 0), _lunge_weapon())
	_tick_to(twice, COMPLACENT_TIME + 0.1)
	var first := _lunge(twice, H.MID)
	_tick_for(twice, LUNGE_RECOVER + 0.05)
	twice.step(-1)
	_tick_to(twice, float(first[1]["t"]) + COMPLACENT_TIME + 0.1)
	var second := _lunge(twice, H.MID)
	_expect(errs, second[0]["lunge"] == true and second[1].get("result") == AR.GRAZE and twice.brain.lunge_touches == 2 and not twice.brain.is_wary(),
		"[제한 없음] 20초 뒤의 둘째 런지가 닿지 않음: %s" % str(second[1]))

	# ---- 높이: 하단은 다리, 상단은 머리(지키는 상대면 피한다. 피한 런지는 횟수를 쓰지 않는다)
	var low := _core(_complacent(_idle_opp()), _lunge_weapon())
	_tick_to(low, COMPLACENT_TIME + 0.1)
	var low_ev := _lunge(low, H.LOW)
	_expect(errs, low_ev[1].get("result") == AR.GRAZE and low_ev[1].get("part") == DT.Part.LEGS, "[높이] 하단 런지가 다리 스침이 아님: %s" % str(low_ev[1]))

	var guarded_opp := _complacent(_idle_opp())
	guarded_opp.guards_head = true
	var head := _core(guarded_opp, _lunge_weapon())
	_tick_to(head, COMPLACENT_TIME + 0.1)
	head.set_aim(DT.Direction.LEFT, H.HIGH)
	_expect(errs, head.is_lunge_now() and head.current_aim_part() == DT.Part.HEAD and head.lunge_head_dodged_now(), "[높이] 머리를 지키는 상대인데 '피한다'가 아님")
	var head_top := head.brain.posture
	var head_ev := _lunge(head, H.HIGH)
	_expect(errs, head_ev[1].get("result") == AR.BLOCKED and head_ev[1].get("dodged") == true and head_ev[1].get("posture_gain") == 0 \
		and head_ev[1].get("rash") == false and head.brain.posture == head_top, "[높이] 머리를 지키는 상대의 머리 런지가 대가 없는 피함이 아님: %s" % str(head_ev[1]))
	_expect(errs, head.brain.lunge_touches == 0 and head.complacency() < 0.01, "[높이] 피한 런지가 횟수를 쓰거나 방심을 풀지 않음")
	_tick_for(head, LUNGE_RECOVER + 0.05)
	head.step(-1)
	_tick_to(head, float(head_ev[1]["t"]) + COMPLACENT_TIME + 0.1)
	var head_retry := _lunge(head, H.MID)
	_expect(errs, head_retry[0]["lunge"] == true and head_retry[1].get("result") == AR.GRAZE and head_retry[1].get("part") == DT.Part.TORSO,
		"[높이] 피한 뒤 20초가 지나 다시 낸 중단 런지가 닿지 않음: %s" % str(head_retry[1]))

	var open_head := _core(_complacent(_idle_opp()), _lunge_weapon())
	_tick_to(open_head, COMPLACENT_TIME + 0.1)
	_expect(errs, not open_head.lunge_head_dodged_now(), "[높이] 머리를 지키지 않는 상대인데 '피한다'임")
	var open_ev := _lunge(open_head, H.HIGH)
	_expect(errs, open_ev[1].get("result") == AR.GRAZE and open_ev[1].get("part") == DT.Part.HEAD, "[높이] 머리를 지키지 않는 상대의 머리 런지가 스침이 아님")

	# ---- 런지가 막히는 세 경우 (상대의 자세는 미리 1칸 깎아 둔다)
	# (1) 예비 동작을 보고 물러나 큰 공격(예비 1.1초)에 뛰어든다 → 막히고, 자세를 돌려주고, 그 타격을 회수 중에 맞는다
	var big := _core(_complacent(_slow_cut_opp(1.1)), _lunge_weapon())
	big.brain.posture -= 1
	_hold_guard_until(big, DT.Direction.LEFT, COMPLACENT_TIME)
	if _tick_until(big, func() -> bool: return big.brain.state == DT.OpponentState.TELL and big.time - big.brain.state_start < 0.05, 30.0) and _retreat_to_far(big):
		var strikes_before := big.record.of_type(DuelRecord.STRIKE).size()
		_expect(errs, big.is_lunge_now() and big.is_rash_now(), "[막힘·큰 공격] 멀리에 닿았을 때 런지가 나가지 않거나 섣부른 공격으로 판단되지 않음")
		var big_ev := _lunge(big, H.MID)
		_expect(errs, big_ev[0]["lunge"] == true and big_ev[0]["rash"] == true, "[막힘·큰 공격] 누른 것이 섣부른 런지가 아님")
		_expect(errs, big_ev[1].get("result") == AR.BLOCKED and big_ev[1].get("dodged") == false and big_ev[1].get("posture_gain") == 1 \
			and big.brain.posture == big.opponent_data.posture_max, "[막힘·큰 공격] 런지가 막히고 상대가 1칸을 되찾지 않음: %s" % str(big_ev[1]))
		_expect(errs, big.brain.lunge_touches == 0 and big.complacency() < 0.01, "[막힘·큰 공격] 막힌 런지가 횟수를 쓰거나 방심을 풀지 않음")
		_tick_until(big, func() -> bool: return big.record.of_type(DuelRecord.STRIKE).size() > strikes_before, big.time + 2.0)
		var big_strike := _last(big, DuelRecord.STRIKE)
		_expect(errs, big.record.of_type(DuelRecord.STRIKE).size() == strikes_before + 1 and big_strike["result"] == DT.StrikeResult.GRAZE \
			and big_strike["situation"] == DT.Situation.IN_ATTACK, "[막힘·큰 공격] 이어지는 타격을 '공격 중'에 맞지 않음: %s" % str(big_strike))
		# 막힌 런지는 한 판의 한 번을 쓰지 않는다: 게이지가 다시 찬다.
		_tick_for(big, 2.0)
		_expect(errs, big.complacency() > 0.05, "[막힘·큰 공격] 막힌 뒤 게이지가 다시 차지 않음")
	else:
		errs.append("[막힘·큰 공격] 20초 뒤의 예비 동작을 보고 물러나지 못함")

	# (2) 예비 동작을 보고 물러나면 찌르기(0.65초)는 먼저 헛친다 → 런지는 대기로 돌아간 상대에게 닿는다
	var thrust := _core(_complacent(_h._make_opp("thrust")), _lunge_weapon())
	thrust.brain.posture -= 1
	_hold_guard_until(thrust, DT.Direction.CENTER, COMPLACENT_TIME)
	if _tick_until(thrust, func() -> bool: return thrust.brain.state == DT.OpponentState.TELL and thrust.time - thrust.brain.state_start < 0.05, 30.0) and _retreat_to_far(thrust):
		var whiffs_before := thrust.record.count_where(DuelRecord.STRIKE, "result", DT.StrikeResult.WHIFF)
		_expect(errs, thrust.is_lunge_now() and thrust.is_rash_now(), "[찌르기는 헛친다] 멀리에 닿았을 때 상대가 예비 동작 중이 아님")
		var thrust_ev := _lunge(thrust, H.MID)
		_expect(errs, thrust.record.count_where(DuelRecord.STRIKE, "result", DT.StrikeResult.WHIFF) == whiffs_before + 1, "[찌르기는 헛친다] 런지 판정 전에 찌르기가 헛치지 않음")
		_expect(errs, thrust_ev[1].get("result") == AR.GRAZE and thrust_ev[1].get("posture_gain") == 0 and thrust.brain.lunge_touches == 1,
			"[찌르기는 헛친다] 런지가 대기로 돌아간 상대에게 닿지 않음: %s" % str(thrust_ev[1]))
	else:
		errs.append("[찌르기는 헛친다] 20초 뒤의 예비 동작을 보고 물러나지 못함")

	# (3) 물러나는 사이에 시작된 찌르기에는 막힌다: 막은 타격 + 0.75초에 물러나면 + 1.0초에 다음 예비 동작이 시작된다
	#     (간격 값은 아직 교전이다). 멀리에 닿은 첫 tick에 누른 런지는 그 타격보다 먼저 판정된다.
	var mid := _core(_complacent(_h._make_opp("thrust")), _lunge_weapon())
	mid.brain.posture -= 1
	_hold_guard_until(mid, DT.Direction.CENTER, COMPLACENT_TIME)
	var mid_strikes := mid.record.of_type(DuelRecord.STRIKE).size()
	if _tick_until(mid, func() -> bool: return mid.record.of_type(DuelRecord.STRIKE).size() > mid_strikes, 30.0):
		var blocked_at: float = _last(mid, DuelRecord.STRIKE)["t"]
		_tick_to(mid, blocked_at + 0.75)
		var tells_before := mid.record.of_type(DuelRecord.TELL_START).size()
		var reached := _retreat_to_far(mid)
		var tell := _last(mid, DuelRecord.TELL_START)
		_expect(errs, reached and mid.record.of_type(DuelRecord.TELL_START).size() == tells_before + 1 and _near(tell["t"], blocked_at + 1.0),
			"[물러나는 사이] 물러나는 중에 다음 예비 동작이 시작되지 않음")
		_expect(errs, mid.is_lunge_now() and mid.is_rash_now(), "[물러나는 사이] 멀리에 닿았을 때 섣부른 런지로 판단되지 않음")
		var mid_ev := _lunge(mid, H.MID)
		_expect(errs, mid_ev[1].get("result") == AR.BLOCKED and mid_ev[1].get("rash") == true and mid_ev[1].get("posture_gain") == 1,
			"[물러나는 사이] 런지가 칸을 돌려주는 섣부른 막힘이 아님: %s" % str(mid_ev[1]))
		_expect(errs, not mid_ev[1].is_empty() and float(mid_ev[1]["t"]) < float(tell["strike_time"]), "[물러나는 사이] 런지의 판정이 타격보다 늦음")
		_tick_to(mid, float(tell["strike_time"]) + 0.05)
		var mid_strike := _last(mid, DuelRecord.STRIKE)
		_expect(errs, _near(mid_strike["t"], tell["strike_time"]) and mid_strike["result"] == DT.StrikeResult.GRAZE and mid_strike["situation"] == DT.Situation.IN_ATTACK,
			"[물러나는 사이] 그 타격을 '공격 중'에 맞지 않음: %s" % str(mid_strike))
		_expect(errs, mid.brain.lunge_touches == 0, "[물러나는 사이] 막힌 런지가 횟수를 씀")
	else:
		errs.append("[물러나는 사이] 20초 뒤의 타격을 막지 못함")

	# ---- 예비 중에 상대가 먼저 다가온다: 런지는 닿고, 교전이 되는 간격 이벤트는 한 번뿐이다(주체는 상대)
	var near_opp := _complacent(_idle_opp())
	near_opp.approach_delay = COMPLACENT_TIME + 0.3
	var near := _core(near_opp, _lunge_weapon())
	_tick_to(near, COMPLACENT_TIME + 0.02)
	var near_ev := _lunge(near, H.MID)
	var near_moves := near.record.of_type(DuelRecord.DISTANCE)
	_expect(errs, near_ev[0]["lunge"] == true and near_ev[1].get("result") == AR.GRAZE, "[상대가 다가옴] 런지가 닿지 않음: %s" % str(near_ev[1]))
	_expect(errs, near_moves.size() == 1 and near_moves[0]["by"] == "opponent" and float(near_moves[0]["t"]) < float(near_ev[1].get("t", 0.0)),
		"[상대가 다가옴] 교전이 되는 간격 이벤트가 상대의 한 번이 아님: %s" % str(near_moves))

	# ---- 무너뜨린다: 자세 1인 상대는 런지에 무너진다. 무너진 상대에게 낸 런지는 유효타다
	var last_cell := _core(_complacent(_idle_opp(1)), _lunge_weapon())
	_tick_to(last_cell, COMPLACENT_TIME + 0.1)
	var last_ev := _lunge(last_cell, H.MID)
	var stagger := _last(last_cell, DuelRecord.STAGGER_START)
	_expect(errs, last_ev[1].get("result") == AR.GRAZE and not stagger.is_empty() and _near(stagger["t"], last_ev[1]["t"]) \
		and last_cell.brain.state == DT.OpponentState.STAGGER, "[무너뜨린다] 자세 1인 상대가 런지에 무너지지 않음")

	var cut_opp: OpponentData = _complacent(_h._make_opp("cut", false, 1))
	var finish := _core(cut_opp, _lunge_weapon())
	_hold_guard_until(finish, DT.Direction.LEFT, COMPLACENT_TIME)
	var finish_strikes := finish.record.of_type(DuelRecord.STRIKE).size()
	if _tick_until(finish, func() -> bool: return finish.record.of_type(DuelRecord.STRIKE).size() > finish_strikes, 30.0):
		# 막고 받아쳐 무너뜨린 뒤, 물러나 곧바로 런지 — 회수 0.30 + 물러나기 0.30 + 예비 0.50초가 무너짐 안이다.
		var counter := _lunge(finish, H.MID, DT.Direction.CENTER)
		_expect(errs, counter[0]["lunge"] == false and counter[1].get("result") == AR.GRAZE and finish.brain.state == DT.OpponentState.STAGGER, "[유효타] 받아쳐 무너뜨리지 못함")
		_tick_until(finish, func() -> bool: return finish.player_state == PS.GUARD or finish.player_state == PS.READY, finish.time + 1.0)
		if _retreat_to_far(finish):
			_expect(errs, finish.is_lunge_now() and not finish.is_rash_now() and not finish.lunge_head_dodged_now(), "[유효타] 무너진 상대 앞의 멀리에서 런지가 나가지 않음")
			var finisher := _lunge(finish, H.MID)
			_expect(errs, finisher[0]["lunge"] == true and finisher[1].get("result") == AR.HIT and finish.end_reason == DT.EndReason.OPPONENT_HIT,
				"[유효타] 무너진 상대에게 낸 런지가 유효타가 아님: %s" % str(finisher[1]))
		else:
			errs.append("[유효타] 무너뜨린 뒤 물러나지 못함")
	else:
		errs.append("[유효타] 20초 뒤의 타격을 막지 못함")

	# ---- 지기 조건: 런지의 판정은 "공격 없이 버틴 시계"를 0으로 돌린다. 멀리에서 누른 헛손질은 세지 않는다
	#      (이 시나리오만 방심 시간을 5초로 적는다. 20초를 교전에서 기다리면 "공격 없이 6초"가 먼저 쌓인다)
	var meters: Array[int] = []
	for with_lunge: bool in [true, false]:
		var cond := ThrowUndetectedCondition.new()
		var conds: Array[CommissionCondition] = [cond]
		var throw_core := _core(_complacent(_idle_opp(), 5.0), _lunge_weapon(LUNGE_WINDUP if with_lunge else 0.0), conds)
		_tick_to(throw_core, 0.7)
		throw_core.step(1)
		_tick_to(throw_core, 5.0)
		throw_core.step(-1)
		_tick_until(throw_core, func() -> bool: return throw_core.distance == DT.Distance.FAR and throw_core.player_state == PS.READY, 6.0)
		var throw_ev := _lunge(throw_core, H.MID)
		_expect(errs, throw_ev[0]["lunge"] == with_lunge, "[지기] 런지 여부가 무기와 다름")
		if not with_lunge:
			# 헛손질 뒤 W로 다시 교전에 들어간다.
			_tick_for(throw_core, throw_core.weapon.recover_time + 0.05)
			throw_core.step(1)
		_tick_to(throw_core, 5.0 + throw_core.weapon.step_time + LUNGE_WINDUP + 3.0)
		_expect(errs, throw_core.distance == DT.Distance.ENGAGE, "[지기] 3초 뒤 교전에 있지 않음")
		meters.append(int(cond.live_meter(throw_core.record)["value"]))
	_expect(errs, meters == [0, ThrowUndetectedCondition.new().idle_suspicion], "[지기] 런지 뒤 3초의 의심 %s (기대 [0, %d]: 런지는 시계를 돌리고 헛손질은 돌리지 않는다)" % [
		str(meters), ThrowUndetectedCondition.new().idle_suspicion])

	# ---- 로드한 값: 범위만 통과 조건이다
	var opponent := load(OPPONENT_PATH) as OpponentData
	var weapon := load(WEAPON_PATH) as WeaponData
	var rules := load(Core.RULES_PATH) as DuelRules
	_expect(errs, opponent.complacent_time >= 0.0 and weapon.lunge_windup >= 0.0 and weapon.lunge_recover >= 0.0, "로드한 방심·런지의 값에 음수가 있음")
	if opponent.complacent_time > 0.0 and weapon.lunge_windup > 0.0:
		# 한 판에 닿을 수 있는 런지의 상한이 상대의 자세 칸 수보다 작아야 한다(선공만으로는 무너뜨릴 수 없다).
		var cap := int(floor(rules.time_limit / opponent.complacent_time))
		if opponent.complacent_limit > 0:
			cap = mini(cap, opponent.complacent_limit)
		_expect(errs, cap < opponent.posture_max, "로드한 값: 한 판에 닿을 수 있는 런지 %d번이 상대 자세 %d칸 이상임" % [cap, opponent.posture_max])
	print("  INFO 로드한 값: 방심 시간 %.1f초, 한 판에 찔리는 횟수 %d, 런지 예비 %.2f초, 회수 %.2f초" % [
		opponent.complacent_time, opponent.complacent_limit, weapon.lunge_windup, weapon.lunge_recover])
	return _result(errs)


# ================================================================ T50 선공과 밸런스

## 설정에 "선공 쓰기"를 붙인다.
func _with_lunge(cfg_fn: Callable) -> Callable:
	return func() -> Dictionary:
		var cfg: Dictionary = cfg_fn.call()
		cfg["lunge"] = {"height": DT.Height.MID}
		return cfg


## 전부 막되 받아치지 않는 봇(선공만 쓰는 봇의 바탕).
func _cfg_guard_never_counter() -> Dictionary:
	return {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold"}


## 전부 패리하고 칼 든 팔을 친다.
func _cfg_parry_arm(opp: OpponentData) -> Callable:
	var arm_aim := [opp.sword_side, DT.Height.MID]
	return func() -> Dictionary:
		return {
			"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"parry",
			"counter_fn": func(_ev: Dictionary) -> Variant: return arm_aim,
			"finisher": AIM_MID_THRUST,
		}


## 막기만 하고 빈틈에 칼 든 팔을 delay초 늦게 친다(교전에서만).
func _cfg_late_arm(opp: OpponentData, delay: float) -> Callable:
	var arm_aim := [opp.sword_side, DT.Height.MID]
	return func() -> Dictionary:
		return {
			"guard_fn": func(_a: AttackData, _i: int) -> StringName: return &"hold",
			"counter_fn": func(ev: Dictionary) -> Variant:
				return arm_aim if float(ev["recovery"]) > 0.0 else null,
			"finisher": AIM_MID_THRUST,
			"counter_delay": delay,
		}


## 봇 하나를 시드 1..SIM_SEEDS로 돌린 통계. 판 길이와 런지의 쓰임새.
func _measure(opp: OpponentData, cfg_fn: Callable, weapon: WeaponData) -> Dictionary:
	var n := float(Core.SIM_SEEDS)
	var out := {
		"mean": 0.0, "min": INF, "max": 0.0, "lengths": [], "wins": 0, "losses": 0, "timeouts": 0,
		"landed": 0, "blocked": 0, "dodged": 0, "cells": 0, "hits_in_lunge": 0,
		"max_landed": 0, "over_cap": 0, "first_judged": INF, "min_posture_left": 1000,
	}
	var never := func(_record: DuelRecord) -> int: return -1
	var no_conditions: Array[CommissionCondition] = []
	for seed_value in range(1, Core.SIM_SEEDS + 1):
		var core: DuelCore = _h._run(opp, cfg_fn.call(), never, Core.SIM_DELTA, 10000.0, seed_value, no_conditions, false, weapon).core
		var record := core.record
		var length := record.elapsed
		(out["lengths"] as Array).append(length)
		out["mean"] += length / n
		out["min"] = minf(out["min"], length)
		out["max"] = maxf(out["max"], length)
		match core.end_reason:
			DT.EndReason.TIME_UP:
				out["timeouts"] += 1
			DT.EndReason.OPPONENT_HIT, DT.EndReason.CONDITION:
				out["wins"] += 1
			DT.EndReason.PLAYER_DEFEATED:
				out["losses"] += 1
		out["min_posture_left"] = mini(out["min_posture_left"], core.brain.posture)
		var landed := 0
		var judged := 0
		var spans: Array = []
		for ev in record.of_type(DuelRecord.ATTACK):
			if not ev.get("lunge", false):
				continue
			judged += 1
			out["first_judged"] = minf(out["first_judged"], float(ev["t"]))
			spans.append([float(ev["t"]) - weapon.lunge_windup, float(ev["t"]) + weapon.lunge_recover])
			if ev["result"] == DT.AttackResult.GRAZE or ev["result"] == DT.AttackResult.HIT:
				landed += 1
				out["cells"] += int(ev["cells"])
			elif ev["dodged"]:
				out["dodged"] += 1
			else:
				out["blocked"] += 1
		out["landed"] += landed
		out["max_landed"] = maxi(out["max_landed"], landed)
		# 판정된 런지의 수가 (판 길이 / 방심 시간)의 내림을 넘은 판의 수.
		if opp.complacent_time > 0.0 and judged > int(floor(length / opp.complacent_time)):
			out["over_cap"] += 1
		for strike in record.of_type(DuelRecord.STRIKE):
			if strike["result"] != DT.StrikeResult.GRAZE and strike["result"] != DT.StrikeResult.HIT:
				continue
			for span: Array in spans:
				if float(strike["t"]) >= span[0] and float(strike["t"]) <= span[1]:
					out["hits_in_lunge"] += 1
					break
	return out


func _line(label: String, st: Dictionary) -> String:
	var n := float(Core.SIM_SEEDS)
	return "  INFO %s: 평균 %.1f초 (최소 %.1f, 최대 %.1f), 승 %d / 패 %d / 시간 초과 %d, 런지 닿음 %.2f · 막힘 %.2f · 피함 %.2f회/판, 런지로 깎은 칸 %.2f/판, 런지 중에 맞음 %.2f회/판" % [
		label, st["mean"], st["min"], st["max"], st["wins"], st["losses"], st["timeouts"],
		st["landed"] / n, st["blocked"] / n, st["dodged"] / n, st["cells"] / n, st["hits_in_lunge"] / n]


func t50_balance() -> String:
	var errs: Array[String] = []
	var seeds := Core.SIM_SEEDS
	var weapon := _lunge_weapon()
	var on: OpponentData = _complacent(_h._copy_opponent())
	on.posture_max = POSTURE
	var off: OpponentData = _complacent(_h._copy_opponent(), 0.0)
	off.posture_max = POSTURE
	var free: OpponentData = _complacent(_h._copy_opponent(), COMPLACENT_TIME, 0)
	free.posture_max = POSTURE

	# ---- 1. 쓰지 않으면 글자 그대로 같다: 선공을 쓰지 않는 봇 다섯의 시드별 판 길이가 방심을 켠 상대와 끈 상대에서 같다
	var unused := {
		"전부 패리": _h._cfg_parry_all, "막기": _h._cfg_guard_only, "막을 때마다 받아치기": _h._cfg_always_counter,
		"세 번에 한 번 섣불리": _h._cfg_rash_one_in_three, "누르고만 있기": _h._cfg_guard_keep,
	}
	var plain := {}
	for name: String in unused:
		var with_on := _measure(on, unused[name], weapon)
		var with_off := _measure(off, unused[name], weapon)
		plain[name] = with_on
		_expect(errs, with_on["lengths"] == with_off["lengths"], "[1] 선공을 쓰지 않는 '%s' 봇의 판 길이가 방심을 켠 상대(%.2f초)와 끈 상대(%.2f초)에서 다름" % [
			name, with_on["mean"], with_off["mean"]])
		_expect(errs, with_on["landed"] + with_on["blocked"] + with_on["dodged"] == 0, "[1] 선공을 쓰지 않는 '%s' 봇의 판에 런지가 있음" % name)
	var guard: Dictionary = plain["막기"]
	var keep: Dictionary = plain["누르고만 있기"]

	# ---- 2. 횟수의 상한: 쓸 수 있는 대로 쓰는 봇의 모든 판에서 닿은 런지가 1번 이하, 판정된 런지 ≤ (판 길이 / 20)의 내림,
	#         첫 판정 시각 ≥ 20초
	var guard_lunge := _measure(on, _with_lunge(_h._cfg_guard_only), weapon)
	_expect(errs, guard_lunge["max_landed"] <= COMPLACENT_LIMIT, "[2] 한 판에 닿은 런지가 %d번인 판이 있음 (상한 %d)" % [guard_lunge["max_landed"], COMPLACENT_LIMIT])
	_expect(errs, guard_lunge["over_cap"] == 0, "[2] 판정된 런지가 (판 길이 / %.0f)의 내림을 넘은 판 %d개" % [COMPLACENT_TIME, guard_lunge["over_cap"]])
	_expect(errs, guard_lunge["first_judged"] >= COMPLACENT_TIME, "[2] 첫 런지의 판정 %.2f초가 방심 시간 %.0f초보다 이름" % [guard_lunge["first_judged"], COMPLACENT_TIME])

	# ---- 3. 선공만으로는 못 이긴다: 전부 막되 받아치지 않고 선공만 쓰는 봇은 전부 시간 초과다
	var only := _measure(on, _with_lunge(_cfg_guard_never_counter), weapon)
	_expect(errs, only["timeouts"] == seeds and only["wins"] == 0 and only["losses"] == 0, "[3] 선공만 쓰는 봇: 승 %d / 패 %d / 시간 초과 %d (기대 전부 시간 초과)" % [
		only["wins"], only["losses"], only["timeouts"]])
	_expect(errs, only["min_posture_left"] >= POSTURE - COMPLACENT_LIMIT, "[3] 선공만 쓴 판의 상대 자세가 %d까지 내려감 (기대 %d 이상)" % [only["min_posture_left"], POSTURE - COMPLACENT_LIMIT])
	_expect(errs, only["landed"] >= LANDED_TOTAL_MIN, "[3] 선공만 쓰는 봇이 %d판에서 런지를 %d번밖에 넣지 못함" % [seeds, only["landed"]])
	var only_free := _measure(free, _with_lunge(_cfg_guard_never_counter), weapon)
	var free_cap := int(floor((load(Core.RULES_PATH) as DuelRules).time_limit / COMPLACENT_TIME))
	_expect(errs, only_free["timeouts"] == seeds and only_free["min_posture_left"] >= POSTURE - free_cap,
		"[3] 횟수 제한을 풀어도: 시간 초과 %d/%d, 상대 자세 최소 %d (기대 전부 시간 초과, %d 이상)" % [only_free["timeouts"], seeds, only_free["min_posture_left"], POSTURE - free_cap])

	# ---- 4. 짧은 판은 그대로다: 방심 시간보다 짧게 끝나던 판은 선공을 붙여도 길이가 같다
	var arm_on := on.duplicate() as OpponentData
	arm_on.graze_sword_arm = 2
	var fast := _measure(arm_on, _cfg_parry_arm(arm_on), weapon)
	var fast_lunge := _measure(arm_on, _with_lunge(_cfg_parry_arm(arm_on)), weapon)
	var short_games := 0
	for i in seeds:
		if fast["lengths"][i] < COMPLACENT_TIME:
			short_games += 1
			if not is_equal_approx(fast["lengths"][i], fast_lunge["lengths"][i]):
				errs.append("[4] 시드 %d: %.2f초에 끝나던 판이 선공을 붙이자 %.2f초가 됨" % [i + 1, fast["lengths"][i], fast_lunge["lengths"][i]])
	_expect(errs, short_games >= 1, "[4] 방심 시간보다 짧게 끝나는 판이 없어 볼 것이 없음")

	# ---- 5. 기준 봇의 폭: 막기 봇(T13의 기준 봇)에 선공을 붙여도 T13의 기준 안이다
	var ratio: float = guard_lunge["mean"] / guard["mean"]
	_expect(errs, ratio >= GUARD_MEAN_RATIO_MIN, "[5-①] 선공을 붙인 막기 봇 평균 %.1f초가 붙이지 않은 평균 %.1f초의 %.0f%% 미만 (%.1f%%)" % [
		guard_lunge["mean"], guard["mean"], GUARD_MEAN_RATIO_MIN * 100.0, ratio * 100.0])
	_expect(errs, guard_lunge["mean"] >= Core.GUARD_MEAN_MIN and guard_lunge["mean"] <= Core.GUARD_MEAN_MAX, "[5-②] 선공을 붙인 막기 봇 평균 %.1f초가 %.0f~%.0f초 밖" % [
		guard_lunge["mean"], Core.GUARD_MEAN_MIN, Core.GUARD_MEAN_MAX])
	_expect(errs, guard_lunge["losses"] == 0, "[5-③] 선공을 붙인 막기 봇이 %d판 짐" % guard_lunge["losses"])
	_expect(errs, guard_lunge["landed"] >= LANDED_TOTAL_MIN, "[5-④] 선공을 붙인 막기 봇이 %d판에서 런지를 %d번밖에 넣지 못함" % [seeds, guard_lunge["landed"]])
	_expect(errs, guard_lunge["max"] - guard_lunge["min"] <= Core.GUARD_SPREAD_MAX and guard_lunge["timeouts"] * 10 <= seeds,
		"[5-⑤] 선공을 붙인 막기 봇의 판 길이 폭 %.1f초(기준 %.0f초 이하), 시간 초과 %d판(10%% 이하)" % [
			guard_lunge["max"] - guard_lunge["min"], Core.GUARD_SPREAD_MAX, guard_lunge["timeouts"]])

	# ---- 6. 올려 막기의 대가가 남는다: 선공을 붙인 뒤에도 누르고만 있는 봇이 막기 봇보다 15초 이상 길다
	var keep_lunge := _measure(on, _with_lunge(_h._cfg_guard_keep), weapon)
	_expect(errs, keep_lunge["mean"] >= guard_lunge["mean"] + Core.KEEP_MEAN_GAP, "[6] 선공을 붙인 누르고만 있는 봇 평균 %.1f초가 선공을 붙인 막기 봇 평균 + %.0f초(%.1f초)보다 짧음" % [
		keep_lunge["mean"], Core.KEEP_MEAN_GAP, guard_lunge["mean"] + Core.KEEP_MEAN_GAP])
	_expect(errs, keep_lunge["landed"] >= LANDED_TOTAL_MIN, "[6] 선공을 붙인 누르고만 있는 봇이 %d판에서 런지를 %d번밖에 넣지 못함" % [seeds, keep_lunge["landed"]])

	print("  INFO [테스트가 만든 값] 자세 %d · 방심 %.0f초 · 한 판에 %d번 · 런지 %.2f / %.2f초, 시드 1..%d, 모자 없는 자유 결투" % [
		POSTURE, COMPLACENT_TIME, COMPLACENT_LIMIT, LUNGE_WINDUP, LUNGE_RECOVER, seeds])
	print("  INFO 조건 5: 막기 봇 %.1f초 → 선공을 붙여 %.1f초 (%.1f%%, 폭 %.1f초) / 조건 6: 누르고만 있는 봇 %.1f초 → %.1f초, 두 봇의 차이 %.1f초 → %.1f초 (기준 %.0f초 이상)" % [
		guard["mean"], guard_lunge["mean"], ratio * 100.0, guard_lunge["max"] - guard_lunge["min"],
		keep["mean"], keep_lunge["mean"], keep["mean"] - guard["mean"], keep_lunge["mean"] - guard_lunge["mean"], Core.KEEP_MEAN_GAP])
	print("  INFO 조건 4: 방심 시간보다 짧게 끝난 판 %d/%d (패리·팔 봇, 선공을 붙여도 길이가 같다)" % [short_games, seeds])

	# ---- INFO (통과 조건 아님): 로드한 상대와 무기. 봇마다 선공을 붙이지 않은 것과 붙인 것을 나란히.
	var real := (load(OPPONENT_PATH) as OpponentData).duplicate() as OpponentData
	var real_weapon := load(WEAPON_PATH) as WeaponData
	print("  INFO [로드한 값] 자세 %d · 방심 %.1f초 · 한 판에 %d번 · 런지 %.2f / %.2f초 · 엉킴 %.1f초" % [
		real.posture_max, real.complacent_time, real.complacent_limit, real_weapon.lunge_windup, real_weapon.lunge_recover, real_weapon.close_bind_time])
	var bots := [
		["막기 봇", _h._cfg_guard_only],
		["누르고만 있는 봇", _h._cfg_guard_keep],
		["0.20초 늦는 팔 봇", _cfg_late_arm(real, 0.20)],
		["패리·몸통 봇", _h._cfg_parry_all],
		["패리·팔 봇", _cfg_parry_arm(real)],
		["선공만 쓰는 봇(받아치지 않는다)", _cfg_guard_never_counter],
	]
	for row in bots:
		print(_line(row[0], _measure(real, row[1], real_weapon)))
		print(_line("%s + 선공" % row[0], _measure(real, _with_lunge(row[1]), real_weapon)))
	# 횟수 제한을 푼 사본: 한 판에 한 번으로 묶은 것이 무엇을 바꾸는지.
	var real_free := real.duplicate() as OpponentData
	real_free.complacent_limit = 0
	var free_guard := _measure(real_free, _with_lunge(_h._cfg_guard_only), real_weapon)
	var free_keep := _measure(real_free, _with_lunge(_h._cfg_guard_keep), real_weapon)
	print(_line("(횟수 제한을 풀면) 막기 봇 + 선공", free_guard))
	print(_line("(횟수 제한을 풀면) 누르고만 있는 봇 + 선공", free_keep))
	print("  INFO (횟수 제한을 풀면) 두 봇의 차이 %.1f초" % (free_keep["mean"] - free_guard["mean"]))
	return _result(errs)


# ================================================================ T51 선공의 표시

## 표시 테스트의 방심 시간(초). 씬을 프레임 단위로 흘리므로 짧게 적는다.
const SHOW_TIME := 3.0


## 상대를 실은 테스트용 의뢰(조건 없음).
func _commission_for(opp: OpponentData) -> Commission:
	var commission := Commission.new()
	commission.client_name = "테스트"
	commission.dialogue = "테스트용 사연"
	commission.opponent = opp
	return commission


## 결투 씬을 붙인다(마우스 조준 끔, 시드 1, F1 디버그 켬). 상대는 의뢰에 실어 넘기고 무기는 test_weapon이다.
func _spawn_duel(opp: OpponentData, weapon: WeaponData) -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("commission", _commission_for(opp))
	duel.set("test_weapon", weapon)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	duel.get_node("HUD").call("toggle_debug")
	return duel


## 같은 씬에서 다른 상대로 새 판을 시작한다.
func _restart(duel: Node, opp: OpponentData) -> DuelCore:
	duel.set("commission", _commission_for(opp))
	duel.call("start_duel")
	return duel.get("core")


func _advance(duel: Node, seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		duel.call("advance", 1.0 / 60.0)


func _advance_until(duel: Node, cond: Callable, max_frames := 1800) -> bool:
	var frames := 0
	while not cond.call():
		if (duel.get("core") as DuelCore).ended or frames >= max_frames:
			return false
		duel.call("advance", 1.0 / 60.0)
		frames += 1
	return true


## 그 조준으로 한 프레임 흘린 뒤의 조준 글자.
func _aim_text(duel: Node, direction: int, height: int) -> String:
	(duel.get("core") as DuelCore).set_aim(direction, height)
	duel.call("advance", 1.0 / 60.0)
	return (duel.get_node("HUD").get("_aim_label") as Label).text


func _state_text(duel: Node) -> String:
	return (duel.get_node("OpponentView/StateLabel") as Label).text


func _log_text(duel: Node) -> String:
	return (duel.get_node("HUD").get("_log_label") as Label).text


## 교전에서 막기를 든 채 방심을 기다리다, 그 뒤의 예비 동작이 막 시작됐을 때 물러나 멀리에 닿은 프레임까지 흘린다.
func _retreat_on_tell(duel: Node) -> bool:
	var core: DuelCore = duel.get("core")
	core.step(1)
	_advance(duel, core.weapon.step_time + 0.05)
	core.set_aim(DT.Direction.LEFT, DT.Height.MID)
	core.set_guard(true)
	var seen := _advance_until(duel, func() -> bool:
		return core.complacency() >= 1.0 and core.brain.state == DT.OpponentState.TELL and core.time - core.brain.state_start < 0.05)
	if not seen:
		return false
	core.set_guard(false)
	core.step(-1)
	return _advance_until(duel, func() -> bool:
		return core.distance == DT.Distance.FAR and core.player_state == DT.PlayerState.READY, 60)


func t51_display() -> String:
	var errs: Array[String] = []
	var H := DT.Height
	var weapon := _lunge_weapon()

	# ---- 상대 A: 아무것도 하지 않고 머리를 지킨다. 방심 3초, 한 판에 한 번.
	var opp_a := _complacent(_idle_opp(), SHOW_TIME, 1)
	opp_a.guards_head = true
	var duel := _spawn_duel(opp_a, weapon)
	var core: DuelCore = duel.get("core")
	var bar := duel.get_node("HUD").get("_complacency_bar") as Control
	_expect(errs, bar != null and bar.name == "ComplacencyBar", "방심 게이지의 노드 이름이 ComplacencyBar가 아님")

	# 방심 전
	_advance(duel, 1.0)
	_expect(errs, bar.visible and is_equal_approx(float(bar.get("ratio")), core.complacency()) and core.complacency() > 0.0 and core.complacency() < 1.0,
		"[A·방심 전] 게이지가 보이지 않거나 값이 코어와 다름 (%.3f, 코어 %.3f)" % [float(bar.get("ratio")), core.complacency()])
	_expect(errs, not _state_text(duel).contains("방심"), "[A·방심 전] 상태 글자에 '방심'이 있음")
	_expect(errs, _aim_text(duel, DT.Direction.LEFT, H.MID).contains("닿지 않음"), "[A·방심 전] 멀리의 조준 글자에 '닿지 않음'이 없음")

	# 방심 뒤(상대는 대기)
	_advance(duel, SHOW_TIME)
	_expect(errs, core.is_lunge_now() and _state_text(duel).contains("방심"), "[A·방심 뒤] 상태 글자에 '방심'이 없음: '%s'" % _state_text(duel))
	_expect(errs, bar.call("caption") == "방심!", "[A·방심 뒤] 게이지의 글자가 '방심!'이 아님")
	var reach := _aim_text(duel, DT.Direction.LEFT, H.MID)
	_expect(errs, reach.contains("런지") and reach.contains("닿는다") and not reach.contains("닿지 않음") and reach.contains(DT.PART_NAMES[DT.Part.TORSO]),
		"[A·방심 뒤] 중단의 조준 글자가 '런지 … 몸통 … 닿는다'가 아님: %s" % reach)
	var dodge := _aim_text(duel, DT.Direction.LEFT, H.HIGH)
	_expect(errs, dodge.contains("런지") and not dodge.contains("닿는다") and dodge.contains("피한다"), "[A·방심 뒤] 상단의 조준 글자가 '피한다'가 아님: %s" % dodge)
	_expect(errs, (duel.get_node("HUD").get("_debug_label") as Label).text.contains("지금 좌클릭이 런지: 예"), "[A·방심 뒤] F1 디버그에 런지 줄이 없음")
	# 교전에서는 런지가 아니다.
	core.step(1)
	_advance(duel, core.weapon.step_time + 0.05)
	_expect(errs, not _aim_text(duel, DT.Direction.LEFT, H.MID).contains("런지"), "[A·방심 뒤] 교전의 조준 글자에 '런지'가 있음")
	core.step(-1)
	_advance(duel, core.weapon.step_time + 0.05)

	# 좌클릭(중단) → 선공. 그 뒤로는 다시 방심하지 않는다(한 판에 한 번).
	core.set_aim(DT.Direction.LEFT, H.MID)
	core.press_attack()
	_advance(duel, LUNGE_WINDUP + 0.1)
	_expect(errs, _log_text(duel).contains("선공"), "[A·좌클릭] 기록 줄에 '선공'이 없음: %s" % _log_text(duel))
	_expect(errs, is_zero_approx(core.complacency()) and not _state_text(duel).contains("방심"), "[A·좌클릭] 찔린 뒤에도 방심이 남아 있음")
	_advance(duel, LUNGE_RECOVER + 0.05)
	core.step(-1)
	_advance(duel, 5.0)
	_expect(errs, core.distance == DT.Distance.FAR and not _state_text(duel).contains("방심") and bar.call("caption") == "경계",
		"[A·한 번] 찔린 뒤 5초가 지났는데 다시 방심하거나 게이지가 '경계'가 아님")
	_expect(errs, _aim_text(duel, DT.Direction.LEFT, H.MID).contains("닿지 않음"), "[A·한 번] 찔린 뒤의 멀리 조준 글자가 '닿지 않음'이 아님")

	# ---- 상대 B: 예비 1.1초인 공격 하나뿐이다. 예비 동작 중에는 "닿는다"라고 말하지 않는다.
	var opp_b := _complacent(_slow_cut_opp(1.1), SHOW_TIME, 1)
	core = _restart(duel, opp_b)
	if _retreat_on_tell(duel):
		var wait := (duel.get_node("HUD").get("_aim_label") as Label).text
		_expect(errs, core.is_lunge_now() and core.is_rash_now(), "[B·예비 동작 중] 멀리에 닿았을 때 코어가 섣부른 런지로 판단하지 않음")
		_expect(errs, wait.contains("런지") and not wait.contains("닿는다") and wait.contains("예비 동작"), "[B·예비 동작 중] 조준 글자가 '예비 동작 중'이 아님: %s" % wait)
		core.press_attack()
		_advance(duel, LUNGE_WINDUP + 0.1)
		_expect(errs, _log_text(duel).contains("런지가 막혔다"), "[B·예비 동작 중] 기록 줄에 '런지가 막혔다'가 없음: %s" % _log_text(duel))
	else:
		errs.append("[B·예비 동작 중] 방심 뒤의 예비 동작을 보고 물러나지 못함")

	# 같은 순서로 물러난 뒤 누르지 않고 기다리면: 타격이 헛친 뒤의 조준 글자는 "닿는다"다.
	core = _restart(duel, opp_b)
	if _retreat_on_tell(duel):
		var whiffed := _advance_until(duel, func() -> bool:
			return core.record.count_where(DuelRecord.STRIKE, "result", DT.StrikeResult.WHIFF) > 0, 120)
		duel.call("advance", 1.0 / 60.0)
		var after := (duel.get_node("HUD").get("_aim_label") as Label).text
		_expect(errs, whiffed and core.distance == DT.Distance.FAR and after.contains("런지") and after.contains("닿는다"),
			"[B·기다린 뒤] 타격이 헛친 뒤의 조준 글자가 '닿는다'가 아님: %s" % after)
	else:
		errs.append("[B·기다린 뒤] 방심 뒤의 예비 동작을 보고 물러나지 못함")

	# ---- 선공이 없는 판(방심 시간 0)
	core = _restart(duel, _complacent(_idle_opp(), 0.0))
	_advance(duel, 10.0)
	_expect(errs, not bar.visible and not _state_text(duel).contains("방심"), "[선공 없음] 게이지가 보이거나 '방심'이 뜸")
	_expect(errs, _aim_text(duel, DT.Direction.LEFT, H.MID).contains("닿지 않음"), "[선공 없음] 멀리의 조준 글자가 '닿지 않음'이 아님")
	duel.free()

	# ---- 조작 안내
	var with_help := DuelHud.help_text(opp_a, false, false, weapon)
	_expect(errs, with_help.contains("런지") and with_help.contains("예비 동작") and with_help.contains("한 판에 한 번"), "선공이 있는 판의 조작 안내에 런지 안내가 없음")
	_expect(errs, not DuelHud.help_text(_complacent(_idle_opp(), 0.0), false, false, weapon).contains("런지"), "방심하지 않는 상대인데 조작 안내에 런지가 있음")
	_expect(errs, not DuelHud.help_text(opp_a, false, false, _lunge_weapon(0.0)).contains("런지"), "런지가 없는 무기인데 조작 안내에 런지가 있음")
	_expect(errs, not DuelHud.help_text(_complacent(_idle_opp(), SHOW_TIME, 0), false, false, weapon).contains("한 판에"), "횟수 제한이 없는 상대인데 조작 안내에 횟수가 있음")
	return _result(errs)
