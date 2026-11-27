extends RefCounted
## T140: 치고 빠지기의 규칙(계획 045 결정 700~704 · 708). 시험 상대는 바르톨로의 사본에 손으로 만든 빠지는 길 둘이다(데이터 opponent_07과 무관).

const Bot := preload("res://tests/duel_bots.gd")
const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Controls := preload("res://scripts/controls.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
## 두 틱 + 여유: 판정은 틱 사이에서 나고 입력은 틱 끝에서 들어간다.
const TIME_TOL := 0.04
const ROOT_RECOVERY := 1.3
const STEP_GAP := 0.65
const LIMIT := 30.0
const DOUBLE_NAME := "두 번 치고 빠지기"

var _f: Fourth = Fourth.new()


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T140", "name": "빠지기의 규칙: 길이 끝나면 한 칸 물러난다(막힘·패리·맞음), 걷는 중·유효타·그 칸이 없는 길은 물러나지 않는다, 빠진 빈틈의 런지, 봇·요약·표시", "fn": t140_withdraw_rules},
	]


# ================================================================ 도우미

func _near(a: float, b: float, tol := 0.02) -> bool:
	return absf(a - b) <= tol


func _strike(direction: int, tell: float, height: int, recovery := 0.0) -> AttackData:
	var atk := AttackData.new()
	atk.attack_name = "치고 빠지기"
	atk.direction = direction as DuelTypes.Direction
	atk.tell_time = tell
	atk.recovery_time = recovery
	atk.heights.append(height)
	return atk


## 단발: 왼쪽 위로 한 번, 빈틈 1.3.
func _single(withdraw := true) -> AttackData:
	var root := _strike(DT.Direction.LEFT, 0.9, DT.Height.HIGH, ROOT_RECOVERY)
	root.withdraw = withdraw
	return root


## 두 번: 왼중 -> 오중, 빈틈 1.3은 끝에서 한 번. 빠짐은 길의 뿌리에 걸린다.
func _double(withdraw := true) -> AttackData:
	var root := _strike(DT.Direction.LEFT, 0.9, DT.Height.MID, ROOT_RECOVERY)
	root.attack_name = DOUBLE_NAME
	root.withdraw = withdraw
	var second := _strike(DT.Direction.RIGHT, STEP_GAP, DT.Height.MID)
	second.attack_name = DOUBLE_NAME
	var chain: Array[Resource] = [second]
	root.chain = chain
	return root


## 바르톨로의 사본(빈틈의 확률 끔, 대기 1.0초)이 이 길 하나만 되풀이한다. 로드한 자원은 고치지 않는다.
func _opp(route: AttackData, mutate := Callable()) -> OpponentData:
	var opp := _f._drill_opp(load(BARTOLO_PATH) as OpponentData, route)
	opp.opening_miss_limit = 0
	if mutate.is_valid():
		mutate.call(opp)
	return opp


func _cfg(mode: StringName, extra := {}) -> Dictionary:
	var cfg: Dictionary = {"guard_fn": func(_a: AttackData, _i: int) -> StringName: return mode}
	for key in extra:
		cfg[key] = extra[key]
	return cfg


## 판을 차린다. 0초에 한 걸음 들어가 교전에서 시작하고, close면 한 걸음 더 들어가 밀착에서 시작한다(엉킴은 끈다).
func _new(opp: OpponentData, cfg: Dictionary, close := false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(_f._rules(), weapon, opp, rng, none, false)
	var run := {"core": core, "bot": Bot.new(core, cfg)}
	core.step(1)
	if close:
		_drive(run, func(c: DuelCore) -> bool: return c.distance == DT.Distance.ENGAGE and c.player_state == DT.PlayerState.READY, 5.0)
		core.step(1)
		_drive(run, func(c: DuelCore) -> bool: return c.distance == DT.Distance.CLOSE and c.player_state == DT.PlayerState.READY, 5.0)
	return run


## 틱마다 봇 뒤에 cond(core)를 물어 참이면 멈춘다. limit은 코어 시각이다.
func _drive(run: Dictionary, cond: Callable, limit: float) -> bool:
	var core: DuelCore = run["core"]
	var bot: Bot = run["bot"]
	while not core.ended and core.time < limit:
		core.tick(DELTA)
		bot.update()
		if cond.call(core):
			return true
	return false


func _strikes_reached(count: int) -> Callable:
	return func(c: DuelCore) -> bool: return c.record.of_type(DuelRecord.STRIKE).size() >= count


func _attacks_reached(count: int) -> Callable:
	return func(c: DuelCore) -> bool: return c.record.of_type(DuelRecord.ATTACK).size() >= count


func _until_time(t: float) -> Callable:
	return func(c: DuelCore) -> bool: return c.time >= t


func _hops(core: DuelCore, by: String = "withdraw") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in core.record.of_type(DuelRecord.DISTANCE):
		if ev.get("by", "") == by:
			out.append(ev)
	return out


## t보다 늦게 시작한 걸음의 수.
func _steps_after(core: DuelCore, t: float) -> int:
	var count := 0
	for ev in core.record.of_type(DuelRecord.STEP_START):
		if float(ev["t"]) > t:
			count += 1
	return count


func _hint_want() -> String:
	return "막기 떼고 %s" % Controls.help_name(&"step_forward")


func _first_strike(run: Dictionary, errs: Array[String], label: String) -> Dictionary:
	if not _drive(run, _strikes_reached(1), LIMIT):
		errs.append("[%s] %d초 안에 타격이 없다" % [label, int(LIMIT)])
		return {}
	var core: DuelCore = run["core"]
	return core.record.of_type(DuelRecord.STRIKE)[0]


# ================================================================ T140 빠지기의 규칙

func t140_withdraw_rules() -> String:
	var errs: Array[String] = []
	_t140_block(errs)
	_t140_rash_whiff(errs)
	_t140_chase(errs)
	_t140_held_step(errs)
	_t140_parry(errs)
	_t140_close(errs)
	_t140_grazed(errs)
	_t140_closed(errs)
	_t140_walking(errs)
	_t140_two_strikes(errs)
	_t140_defeat(errs)
	_t140_without_flag(errs)
	_t140_lunge(errs)
	_t140_bots(errs)
	_t140_summary(errs)
	_t140_display(errs)
	return "OK" if errs.is_empty() else ", ".join(errs)


## (가) 교전에서 막음: STRIKE(막힘) 다음 DISTANCE{멀리, "withdraw"}가 같은 시각, 회수 1.3, withdrew_at이 그 시각.
func _t140_block(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), _cfg(&"hold"))
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "가")
	if strike.is_empty():
		return
	var t := float(strike["t"])
	if int(strike["result"]) != DT.StrikeResult.BLOCKED or not _near(float(strike["recovery"]), ROOT_RECOVERY):
		errs.append("[가] 결과 %d · 빈틈 %.2f (기대 막힘 · 1.30)" % [int(strike["result"]), float(strike["recovery"])])
	var hops := _hops(core)
	if hops.size() != 1:
		errs.append("[가] 물러남 %d번 (기대 1)" % hops.size())
		return
	var hop := hops[0]
	if int(hop["distance"]) != DT.Distance.FAR or absf(float(hop["t"]) - t) > 0.000001:
		errs.append("[가] 물러난 간격 %d · 시각 차 %.4f (기대 멀리 · 같은 시각)" % [int(hop["distance"]), float(hop["t"]) - t])
	if core.record.events.find(strike) >= core.record.events.find(hop):
		errs.append("[가] DISTANCE가 STRIKE보다 먼저 났다")
	if absf(core.withdrew_at - t) > 0.000001:
		errs.append("[가] withdrew_at %.4f (기대 타격 시각 %.4f)" % [core.withdrew_at, t])
	if core.distance != DT.Distance.FAR or core.brain.state != DT.OpponentState.RECOVERY:
		errs.append("[가] 간격 %d · 상대 상태 %d (기대 멀리 · 회수)" % [core.distance, core.brain.state])
	if not _near(core.brain.state_end - core.brain.state_start, ROOT_RECOVERY):
		errs.append("[가] 회수의 길이 %.2f (기대 1.30)" % (core.brain.state_end - core.brain.state_start))
	if core.is_lunge_now():
		errs.append("[가] 판 처음인데 런지가 나가는 때다")
	# (타) 빠진 빈틈의 귀띔.
	var hint := OpponentView.recovery_hint_of(core)
	if hint != _hint_want():
		errs.append("[타] 빠진 빈틈의 귀띔 '%s' (기대 '%s')" % [hint, _hint_want()])


## (가) 판 처음(방심 0)이라 그 자리에서 누른 공격은 런지가 아니고 헛침이다(섣부르지 않다).
func _t140_rash_whiff(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), _cfg(&"hold"))
	var core: DuelCore = run["core"]
	if _first_strike(run, errs, "가·헛침").is_empty():
		return
	core.set_aim(DT.Direction.CENTER, DT.Height.MID)
	core.press_attack()
	var starts := core.record.of_type(DuelRecord.ATTACK_START)
	if starts.size() != 1 or bool(starts[0]["lunge"]) or bool(starts[0]["rash"]):
		errs.append("[가·헛침] ATTACK_START %s (기대 1개 · lunge 거짓 · rash 거짓)" % str(starts.size()))
		return
	if not _drive(run, _attacks_reached(1), core.time + 3.0):
		errs.append("[가·헛침] 공격의 판정이 없다")
		return
	var attack := core.record.of_type(DuelRecord.ATTACK)[0]
	if int(attack["result"]) != DT.AttackResult.WHIFF or bool(attack["rash"]):
		errs.append("[가·헛침] 결과 %d · rash %s (기대 헛침 · 거짓)" % [int(attack["result"]), str(attack["rash"])])


## (가) 막기를 떼고 W -> 0.3초 뒤 교전 -> 찌르기 -> 스침(빈틈 안).
func _t140_chase(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), _cfg(&"hold"))
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "가·따라붙기")
	if strike.is_empty():
		return
	var t := float(strike["t"])
	core.set_guard(false)
	core.step(1)
	if core.player_state != DT.PlayerState.STEPPING:
		errs.append("[가·따라붙기] 막기를 떼고 누른 W가 걸음이 되지 않았다 (상태 %d)" % core.player_state)
		return
	var arrived := func(c: DuelCore) -> bool: return c.distance == DT.Distance.ENGAGE and c.player_state == DT.PlayerState.READY
	if not _drive(run, arrived, core.time + 2.0):
		errs.append("[가·따라붙기] 걸음이 끝나지 않았다")
		return
	var player_hops := _hops(core, "player")
	var last_hop: Dictionary = player_hops[player_hops.size() - 1]
	if float(last_hop["t"]) <= t or int(last_hop["distance"]) != DT.Distance.ENGAGE or absf(float(last_hop["t"]) - t - 0.3) > TIME_TOL:
		errs.append("[가·따라붙기] 마지막 내 걸음 시각 %.3f · 간격 %d (기대 타격 + 0.3 · 교전)" % [float(last_hop["t"]) - t, int(last_hop["distance"])])
	core.set_aim(DT.Direction.CENTER, DT.Height.MID)
	core.press_attack()
	if not _drive(run, _attacks_reached(1), core.time + 2.0):
		errs.append("[가·따라붙기] 공격의 판정이 없다")
		return
	var attack := core.record.of_type(DuelRecord.ATTACK)[0]
	if int(attack["result"]) != DT.AttackResult.GRAZE or float(attack["t"]) >= float(strike["recovery_end"]):
		errs.append("[가·따라붙기] 결과 %d · 판정 %.2f (기대 스침 · 빈틈 %.2f 안)" % [int(attack["result"]), float(attack["t"]), float(strike["recovery_end"])])
	if bool(core.record.of_type(DuelRecord.ATTACK_START)[0]["rash"]):
		errs.append("[가·따라붙기] 빈틈 안의 공격이 섣부르다")
	if _steps_after(core, t) != 1:
		errs.append("[가·따라붙기] 타격 뒤 걸음 %d번 (기대 1)" % _steps_after(core, t))


## (가) 막기를 쥔 채 누른 W는 걸음이 나가지 않는다.
func _t140_held_step(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), _cfg(&"hold"))
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "가·쥔 W")
	if strike.is_empty():
		return
	var t := float(strike["t"])
	core.step(1)
	_drive(run, _until_time(core.time + 0.5), LIMIT)
	if _steps_after(core, t) != 0 or core.distance != DT.Distance.FAR or core.player_state != DT.PlayerState.GUARD:
		errs.append("[가·쥔 W] 걸음 %d번 · 간격 %d · 상태 %d (기대 0 · 멀리 · 막기)" % [_steps_after(core, t), core.distance, core.player_state])


## (나) 패리: 빠지고 빈틈 1.3 + 패리의 덤, 크게 열린다.
func _t140_parry(errs: Array[String]) -> void:
	var opp := _opp(_single())
	var run := _new(opp, _cfg(&"parry"))
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "나")
	if strike.is_empty():
		return
	if int(strike["result"]) != DT.StrikeResult.PARRIED or not _near(float(strike["recovery"]), ROOT_RECOVERY + opp.parried_recovery_bonus):
		errs.append("[나] 결과 %d · 빈틈 %.2f (기대 패리 · %.2f)" % [int(strike["result"]), float(strike["recovery"]), ROOT_RECOVERY + opp.parried_recovery_bonus])
	if not core.brain.wide_open:
		errs.append("[나] 패리 뒤의 빈틈이 크게 열리지 않았다")
	var hops := _hops(core)
	if hops.size() != 1 or core.distance != DT.Distance.FAR or absf(float(hops[0]["t"]) - float(strike["t"])) > 0.000001:
		errs.append("[나] 물러남 %d번 · 간격 %d (기대 1번 · 멀리 · 같은 시각)" % [hops.size(), core.distance])


## (다) 밀착에서 시작: 교전으로 물러나고, 걸음 없이 친 공격이 닿는다. (타) 교전의 빈틈에는 귀띔이 없다.
func _t140_close(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), _cfg(&"hold"), true)
	var core: DuelCore = run["core"]
	if core.distance != DT.Distance.CLOSE:
		errs.append("[다] 밀착에서 시작하지 못했다 (간격 %d)" % core.distance)
		return
	var strike := _first_strike(run, errs, "다")
	if strike.is_empty():
		return
	var hops := _hops(core)
	if int(strike["result"]) != DT.StrikeResult.BLOCKED or hops.size() != 1 or int(hops[0]["distance"]) != DT.Distance.ENGAGE or core.distance != DT.Distance.ENGAGE:
		errs.append("[다] 결과 %d · 물러남 %d번 · 간격 %d (기대 막힘 · 1번 · 교전)" % [int(strike["result"]), hops.size(), core.distance])
		return
	var hint := OpponentView.recovery_hint_of(core)
	if hint != "":
		errs.append("[타] 교전에서 물러난 빈틈의 귀띔 '%s' (기대 빈 글)" % hint)
	core.set_aim(DT.Direction.CENTER, DT.Height.MID)
	core.press_attack()
	var starts := core.record.of_type(DuelRecord.ATTACK_START)
	if starts.size() != 1 or bool(starts[0]["rash"]) or bool(starts[0]["lunge"]):
		errs.append("[다] 빈틈 안의 공격이 섣부르거나 런지다")
	if not _drive(run, _attacks_reached(1), core.time + 2.0):
		errs.append("[다] 공격의 판정이 없다")
		return
	var attack := core.record.of_type(DuelRecord.ATTACK)[0]
	if int(attack["result"]) != DT.AttackResult.GRAZE or core.record.of_type(DuelRecord.STEP_START).size() != 2:
		errs.append("[다] 결과 %d · 걸음 %d번 (기대 스침 · 시작의 둘뿐)" % [int(attack["result"]), core.record.of_type(DuelRecord.STEP_START).size()])


## (라) 무방비로 맞음(스침): 빠지고 빈틈 0 · 대기, 멀리에서 접근 지연 뒤 DISTANCE by "opponent".
func _t140_grazed(errs: Array[String]) -> void:
	var opp := _opp(_single())
	var run := _new(opp, _cfg(&"none"))
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "라")
	if strike.is_empty():
		return
	var t := float(strike["t"])
	if int(strike["result"]) != DT.StrikeResult.GRAZE or float(strike["recovery"]) != 0.0 or core.brain.state != DT.OpponentState.IDLE:
		errs.append("[라] 결과 %d · 빈틈 %.2f · 상대 상태 %d (기대 스침 · 0 · 대기)" % [int(strike["result"]), float(strike["recovery"]), core.brain.state])
	if _hops(core).size() != 1 or core.distance != DT.Distance.FAR:
		errs.append("[라] 물러남 %d번 · 간격 %d (기대 1번 · 멀리)" % [_hops(core).size(), core.distance])
		return
	if not _drive(run, func(c: DuelCore) -> bool: return _hops(c, "opponent").size() >= 1, t + 4.0):
		errs.append("[라] 접근이 없다")
		return
	var came := float(_hops(core, "opponent")[0]["t"]) - t
	if not _near(came, opp.approach_delay, TIME_TOL):
		errs.append("[라] 접근까지 %.2f초 (기대 %.2f)" % [came, opp.approach_delay])


## (마) 안 열려도 빠지고 대기 · 접근.
func _t140_closed(errs: Array[String]) -> void:
	var opp := _opp(_single())
	var run := _new(opp, _cfg(&"hold"))
	var core: DuelCore = run["core"]
	core.brain.opening_chance = 0.0
	var strike := _first_strike(run, errs, "마")
	if strike.is_empty():
		return
	var t := float(strike["t"])
	if int(strike["result"]) != DT.StrikeResult.BLOCKED or float(strike["recovery"]) != 0.0 or not bool(strike["closed"]) or core.brain.state != DT.OpponentState.IDLE:
		errs.append("[마] 결과 %d · 빈틈 %.2f · closed %s · 상대 상태 %d (기대 막힘 · 0 · 참 · 대기)" % [int(strike["result"]), float(strike["recovery"]), str(strike["closed"]), core.brain.state])
	if _hops(core).size() != 1 or core.distance != DT.Distance.FAR:
		errs.append("[마] 안 열린 막기 뒤 물러남 %d번 · 간격 %d (기대 1번 · 멀리)" % [_hops(core).size(), core.distance])
		return
	if not _drive(run, func(c: DuelCore) -> bool: return _hops(c, "opponent").size() >= 1, t + 4.0):
		errs.append("[마] 접근이 없다")
		return
	if not _near(float(_hops(core, "opponent")[0]["t"]) - t, opp.approach_delay, TIME_TOL):
		errs.append("[마] 접근까지 %.2f초 (기대 %.2f)" % [float(_hops(core, "opponent")[0]["t"]) - t, opp.approach_delay])


## (바) 타격 직전에 W를 눌러 걷는 중: 빠지지 않고 간격은 내 걸음의 것이다.
func _t140_walking(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), _cfg(&"none"))
	var core: DuelCore = run["core"]
	var fired := {}
	var walk := func(c: DuelCore) -> bool:
		if not fired.has("on") and c.brain.state == DT.OpponentState.TELL and c.player_state == DT.PlayerState.READY and c.time >= c.brain.state_end - 0.1:
			fired["on"] = true
			c.step(1)
		return c.record.of_type(DuelRecord.STRIKE).size() >= 1
	if not _drive(run, walk, LIMIT) or not fired.has("on"):
		errs.append("[바] 걷는 중의 타격이 없다")
		return
	var t := float(core.record.of_type(DuelRecord.STRIKE)[0]["t"])
	var steps := core.record.of_type(DuelRecord.STEP_START)
	if steps.size() != 2 or float(steps[1]["end_time"]) <= t:
		errs.append("[바] 타격 때 걷는 중이 아니었다 (걸음 %d번)" % steps.size())
		return
	_drive(run, _until_time(t + 0.6), LIMIT)
	var mine := _hops(core, "player")
	if not _hops(core).is_empty() or core.withdrew_at > -INF:
		errs.append("[바] 걷는 중인데 물러났다")
	if mine.is_empty() or float(mine[mine.size() - 1]["t"]) <= t or int(mine[mine.size() - 1]["distance"]) != DT.Distance.CLOSE or core.distance != DT.Distance.CLOSE:
		errs.append("[바] 간격이 내 걸음의 것이 아니다 (간격 %d, 기대 밀착)" % core.distance)


## (사) 두 번 길: 첫 막힘 뒤 DISTANCE 없음, 끝에서 한 번. 첫 타격을 맞으면 그 자리에서 빠진다.
func _t140_two_strikes(errs: Array[String]) -> void:
	var run := _new(_opp(_double()), _cfg(&"hold"))
	var core: DuelCore = run["core"]
	if not _drive(run, _strikes_reached(2), LIMIT):
		errs.append("[사] 두 타격이 나지 않았다")
		return
	var strikes := core.record.of_type(DuelRecord.STRIKE)
	var hops := _hops(core)
	if hops.size() != 1 or absf(float(hops[0]["t"]) - float(strikes[1]["t"])) > 0.000001 or absf(float(hops[0]["t"]) - float(strikes[0]["t"])) < 0.1:
		errs.append("[사] 물러남 %d번 (기대 끝의 타격에서 한 번)" % hops.size())
	if float(strikes[0]["next_strike"]) < 0.0 or not _near(float(strikes[1]["recovery"]), ROOT_RECOVERY):
		errs.append("[사] 첫 타격의 next_strike %.2f · 끝의 빈틈 %.2f (기대 이어짐 · 1.30)" % [float(strikes[0]["next_strike"]), float(strikes[1]["recovery"])])
	# 첫 타격을 맞으면 길이 끝나고 그 자리에서 빠진다.
	var hit_run := _new(_opp(_double()), _cfg(&"none"))
	var hit_core: DuelCore = hit_run["core"]
	var first := _first_strike(hit_run, errs, "사·맞음")
	if first.is_empty():
		return
	_drive(hit_run, _until_time(float(first["t"]) + 1.0), LIMIT)
	var hit_hops := _hops(hit_core)
	if int(first["result"]) != DT.StrikeResult.GRAZE or hit_core.record.of_type(DuelRecord.STRIKE).size() != 1 or hit_hops.size() != 1 or absf(float(hit_hops[0]["t"]) - float(first["t"])) > 0.000001:
		errs.append("[사·맞음] 결과 %d · 타격 %d번 · 물러남 %d번 (기대 스침 · 1번 · 1번 · 같은 시각)" % [int(first["result"]), hit_core.record.of_type(DuelRecord.STRIKE).size(), hit_hops.size()])


## (아) 자세 0에서 맞음(유효타): DISTANCE 없이 끝난다.
func _t140_defeat(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), _cfg(&"none"))
	var core: DuelCore = run["core"]
	core.player_posture = 0
	if not _drive(run, func(c: DuelCore) -> bool: return c.ended, LIMIT):
		errs.append("[아] 판이 끝나지 않았다")
		return
	var strikes := core.record.of_type(DuelRecord.STRIKE)
	if strikes.size() != 1 or int(strikes[0]["result"]) != DT.StrikeResult.HIT or core.end_reason != DT.EndReason.PLAYER_DEFEATED:
		errs.append("[아] 타격 %d번 · 끝 %d (기대 유효타 1번 · 패배)" % [strikes.size(), core.end_reason])
	if not _hops(core).is_empty() or core.withdrew_at > -INF:
		errs.append("[아] 유효타 뒤에 물러났다")


## (자) 같은 길의 withdraw = false 사본은 물러남을 한 번도 내지 않고 withdrew_at이 -INF다.
func _t140_without_flag(errs: Array[String]) -> void:
	for item: Array in [["단발", _single(false)], ["두 번", _double(false)]]:
		var run := _new(_opp(item[1]), _cfg(&"hold"))
		var core: DuelCore = run["core"]
		var count := 2 if item[0] == "단발" else 4
		if not _drive(run, _strikes_reached(count), LIMIT):
			errs.append("[자·%s] 타격이 모자란다" % item[0])
			continue
		if not _hops(core).is_empty() or core.withdrew_at > -INF or core.distance == DT.Distance.FAR:
			errs.append("[자·%s] 물러남 %d번 · withdrew_at %s · 간격 %d (기대 0번 · -INF · 멀리 아님)" % [item[0], _hops(core).size(), str(core.withdrew_at), core.distance])


## (파) 빠진 빈틈의 런지(결정 701): 방심이 찬 판에서는 한 번 닿고, 다음 빠진 빈틈의 좌클릭은 런지가 아니라 헛친다.
func _t140_lunge(errs: Array[String]) -> void:
	var opp := _opp(_single(), func(o: OpponentData) -> void: o.complacent_time = 2.0)
	var run := _new(opp, _cfg(&"hold"))
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "파")
	if strike.is_empty():
		return
	var t1 := float(strike["t"])
	if not core.is_lunge_now():
		errs.append("[파] 첫 빠진 빈틈(%.2f초)에 방심이 차지 않았다" % t1)
		return
	core.set_aim(DT.Direction.CENTER, DT.Height.MID)
	var forecast := core.attack_forecast()
	if int(forecast["verdict"]) != DT.Forecast.REACH:
		errs.append("[파] 미리보기 %d (기대 닿는다 %d)" % [int(forecast["verdict"]), DT.Forecast.REACH])
	core.press_attack()
	var starts := core.record.of_type(DuelRecord.ATTACK_START)
	if starts.size() != 1 or not bool(starts[0]["lunge"]) or bool(starts[0]["rash"]):
		errs.append("[파] 첫 공격 ATTACK_START %d개 · lunge %s · rash %s (기대 참 · 거짓)" % [starts.size(), str(starts[0]["lunge"]) if starts.size() == 1 else "-", str(starts[0]["rash"]) if starts.size() == 1 else "-"])
		return
	if not _drive(run, _attacks_reached(1), core.time + 3.0):
		errs.append("[파] 런지의 판정이 없다")
		return
	var lunge := core.record.of_type(DuelRecord.ATTACK)[0]
	if int(lunge["result"]) != DT.AttackResult.GRAZE or not bool(lunge["lunge"]) or float(lunge["t"]) >= float(strike["recovery_end"]):
		errs.append("[파] 런지 결과 %d · 판정 %.2f (기대 스침 · 빈틈 %.2f 안)" % [int(lunge["result"]), float(lunge["t"]), float(strike["recovery_end"])])
	var mine := _hops(core, "player")
	if mine.is_empty() or int(mine[mine.size() - 1]["distance"]) != DT.Distance.ENGAGE or absf(float(mine[mine.size() - 1]["t"]) - t1 - 0.5) > TIME_TOL:
		errs.append("[파] 런지의 DISTANCE가 타격 + 0.5초의 교전이 아니다")
	# 다음 빠진 빈틈: 경계해 런지가 아니다. 2초 넘게 지난 뒤의 좌클릭으로 견준다.
	if not _drive(run, func(c: DuelCore) -> bool: return _hops(c).size() >= 2, core.time + 15.0):
		errs.append("[파] 둘째 빠진 빈틈이 없다")
		return
	var t2 := float(_hops(core)[1]["t"])
	_drive(run, _until_time(t2 + 0.8), LIMIT)
	if core.time - float(lunge["t"]) <= 2.0:
		errs.append("[파] 런지 뒤 %.2f초밖에 지나지 않아 경계를 못 가린다" % (core.time - float(lunge["t"])))
	if core.distance != DT.Distance.FAR or core.is_lunge_now():
		errs.append("[파] 둘째 빠진 빈틈의 간격 %d · 런지 %s (기대 멀리 · 거짓)" % [core.distance, str(core.is_lunge_now())])
	core.set_aim(DT.Direction.CENTER, DT.Height.MID)
	core.press_attack()
	starts = core.record.of_type(DuelRecord.ATTACK_START)
	if starts.size() != 2 or bool(starts[1]["lunge"]) or bool(starts[1]["rash"]):
		errs.append("[파] 둘째 공격 ATTACK_START %d개 (기대 2개 · 둘째는 lunge 거짓 · rash 거짓)" % starts.size())
		return
	if not _drive(run, _attacks_reached(2), core.time + 3.0):
		errs.append("[파] 둘째 공격의 판정이 없다")
		return
	if int(core.record.of_type(DuelRecord.ATTACK)[1]["result"]) != DT.AttackResult.WHIFF:
		errs.append("[파] 둘째 공격 결과 %d (기대 헛침)" % int(core.record.of_type(DuelRecord.ATTACK)[1]["result"]))


## (차) 봇: 키 없는 first_blood_cfg는 빠진 빈틈에 막기를 떼고 걸어 들어가 스침을 낸다. chase_fn 거짓이면 걸음 · 공격이 없다. 빠짐 없는 상대는 걸음이 0이다.
func _t140_bots(errs: Array[String]) -> void:
	var run := _new(_opp(_single()), Bot.first_blood_cfg())
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "차")
	if strike.is_empty():
		return
	if not _drive(run, _attacks_reached(1), core.time + 3.0):
		errs.append("[차] 봇이 따라붙어 치지 않았다")
	else:
		var attack := core.record.of_type(DuelRecord.ATTACK)[0]
		if _steps_after(core, float(strike["t"])) != 1 or int(attack["result"]) != DT.AttackResult.GRAZE or float(attack["t"]) >= float(strike["recovery_end"]):
			errs.append("[차] 걸음 %d번 · 결과 %d (기대 1번 · 스침 · 빈틈 안)" % [_steps_after(core, float(strike["t"])), int(attack["result"])])
	var cfg := Bot.first_blood_cfg()
	cfg["chase_fn"] = func(_ev: Dictionary) -> bool: return false
	var idle_run := _new(_opp(_single()), cfg)
	var idle_core: DuelCore = idle_run["core"]
	var idle_strike := _first_strike(idle_run, errs, "차·chase 거짓")
	if not idle_strike.is_empty():
		_drive(idle_run, _until_time(float(idle_strike["t"]) + 1.0), LIMIT)
		if _steps_after(idle_core, float(idle_strike["t"])) != 0 or not idle_core.record.of_type(DuelRecord.ATTACK).is_empty():
			errs.append("[차·chase 거짓] 걸음 %d번 · 공격 %d번 (기대 0 · 0)" % [_steps_after(idle_core, float(idle_strike["t"])), idle_core.record.of_type(DuelRecord.ATTACK).size()])
	# 빠짐 없는 상대(바르톨로)는 같은 봇으로 60초 — 시작의 걸음 하나뿐이다.
	var plain_opp := (load(BARTOLO_PATH) as OpponentData).duplicate() as OpponentData
	var plain := _new(plain_opp, Bot.first_blood_cfg())
	var plain_core: DuelCore = plain["core"]
	_drive(plain, func(_c: DuelCore) -> bool: return false, 60.0)
	if plain_core.record.of_type(DuelRecord.STEP_START).size() != 1 or not _hops(plain_core).is_empty():
		errs.append("[차] 빠짐 없는 상대에게 걸음 %d번 · 물러남 %d번 (기대 1번(시작) · 0번)" % [plain_core.record.of_type(DuelRecord.STEP_START).size(), _hops(plain_core).size()])


## (카) 요약: 빠짐이 없는 판에는 withdraws 열쇠가 없고, 있는 판에는 세 수와 길 글의 "^".
func _t140_summary(errs: Array[String]) -> void:
	var plain_opp := (load(BARTOLO_PATH) as OpponentData).duplicate() as OpponentData
	var plain := _new(plain_opp, Bot.first_blood_cfg())
	_drive(plain, func(_c: DuelCore) -> bool: return false, 30.0)
	if Summary.summarize((plain["core"] as DuelCore).record).has("withdraws"):
		errs.append("[카] 빠짐이 없는 판의 요약에 withdraws 열쇠가 있다")
	var run := _new(_opp(_double()), Bot.first_blood_cfg())
	var core: DuelCore = run["core"]
	if not _drive(run, _attacks_reached(1), LIMIT):
		errs.append("[카] 따라붙은 공격이 없다")
		return
	var summary := Summary.summarize(core.record)
	if not summary.has("withdraws"):
		errs.append("[카] 빠짐이 있는 판의 요약에 withdraws 열쇠가 없다")
		return
	var counts: Dictionary = summary["withdraws"]
	if int(counts["빠짐"]) != 1 or int(counts["열린 빠짐"]) != 1 or int(counts["따라붙어 닿음"]) != 1:
		errs.append("[카] withdraws %s (기대 빠짐 1 · 열린 빠짐 1 · 따라붙어 닿음 1)" % str(counts))
	var key := "%s 왼중>오중^" % DOUBLE_NAME
	if not (summary["routes"] as Dictionary).has(key):
		errs.append("[카] 길 글 %s (기대 '%s')" % [str((summary["routes"] as Dictionary).keys()), key])


## (타) 표시의 정적 함수: 빠짐 없는 상대가 멀리에서 헛친 뒤의 빈틈에는 귀띔이 없고, 고리의 꺾쇠는 빠지는 길의 마지막 타격에만 선다.
func _t140_display(errs: Array[String]) -> void:
	var run := _new(_opp(_single(false)), _cfg(&"retreat"))
	var core: DuelCore = run["core"]
	var strike := _first_strike(run, errs, "타·헛침")
	if not strike.is_empty():
		if int(strike["result"]) != DT.StrikeResult.WHIFF or core.brain.state != DT.OpponentState.RECOVERY or core.distance != DT.Distance.FAR:
			errs.append("[타] 시험의 판이 어긋났다: 결과 %d · 상대 상태 %d · 간격 %d (기대 헛침 · 회수 · 멀리)" % [int(strike["result"]), core.brain.state, core.distance])
		elif OpponentView.recovery_hint_of(core) != "":
			errs.append("[타] 빠짐 없는 상대의 헛친 빈틈 귀띔 '%s' (기대 빈 글)" % OpponentView.recovery_hint_of(core))
	var in_tell := func(c: DuelCore) -> bool: return c.brain.state == DT.OpponentState.TELL
	var single := _new(_opp(_single()), _cfg(&"none"))
	var single_core: DuelCore = single["core"]
	if _drive(single, in_tell, LIMIT):
		if not OpponentView.ring_withdraw_of(single_core.brain):
			errs.append("[타] 단발 빠지는 길의 고리에 꺾쇠가 서지 않는다")
	else:
		errs.append("[타] 단발의 예비 동작이 없다")
	var double := _new(_opp(_double()), _cfg(&"hold"))
	var double_core: DuelCore = double["core"]
	if _drive(double, in_tell, LIMIT):
		var marks := OpponentView.pattern_marks(double_core.brain, double_core.time)
		if OpponentView.ring_withdraw_of(double_core.brain) or marks.size() != 2 or marks[0].has("withdraw") or not bool(marks[1].get("withdraw", false)):
			errs.append("[타] 두 번 길의 첫 타격: 꺾쇠 %s · 표시 %d개 (기대 없음 · 표시 둘 중 끝에만 꺾쇠)" % [str(OpponentView.ring_withdraw_of(double_core.brain)), marks.size()])
		var at_end := func(c: DuelCore) -> bool: return c.brain.state == DT.OpponentState.TELL and c.brain.step_index == 1
		if _drive(double, at_end, double_core.time + 3.0):
			var late := OpponentView.pattern_marks(double_core.brain, double_core.time)
			if not OpponentView.ring_withdraw_of(double_core.brain) or late.size() != 1 or not bool(late[0].get("withdraw", false)):
				errs.append("[타] 두 번 길의 끝 타격: 꺾쇠 %s · 표시 %d개 (기대 꺾쇠 · 1개)" % [str(OpponentView.ring_withdraw_of(double_core.brain)), late.size()])
		else:
			errs.append("[타] 두 번 길의 둘째 타격에 닿지 못했다")
	else:
		errs.append("[타] 두 번 길의 예비 동작이 없다")
	var plain := _new(_opp(_double(false)), _cfg(&"hold"))
	var plain_core: DuelCore = plain["core"]
	if _drive(plain, in_tell, LIMIT):
		for mark in OpponentView.pattern_marks(plain_core.brain, plain_core.time):
			if mark.has("withdraw"):
				errs.append("[타] withdraw가 없는 길의 표시에 꺾쇠 열쇠가 있다")
		if OpponentView.ring_withdraw_of(plain_core.brain):
			errs.append("[타] withdraw가 없는 길의 고리에 꺾쇠가 선다")
