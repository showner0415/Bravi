extends RefCounted
## T162: 송곳 가림의 규칙(계획 053 결정 828~831 · 837 · 840). 시험 상대는 바르톨로의 사본(빈틈의 확률 끔, 대기 1.0초)에 테스트 안에서 만든 길 셋 이상이다(데이터 opponent_08과 무관).
## States.put으로 놓은 코어에는 advance · tick을 부르지 않는다. 판은 처음부터 tick으로 몬다.

const Bot := preload("res://tests/duel_bots.gd")
const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Summary := preload("res://scripts/duel/duel_summary.gd")

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const EFFECTS_PATH := "res://data/part_effects.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
const LIMIT := 30.0
const L := DT.Direction.LEFT
const C := DT.Direction.CENTER
const R := DT.Direction.RIGHT
const HI := DT.Height.HIGH
const MID := DT.Height.MID
const LO := DT.Height.LOW

var _f: Fourth = Fourth.new()


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T162", "name": "송곳 가림의 규칙: 길이 끝나 열린 빈틈에 가린 줄은 걸려 빈틈이 닫힌다(막힘·패리), 안 열림·내가 맞음·무너짐에는 없다, 런지, 조준 미리보기, 봇·요약, 표지가 끊기지 않는다", "fn": t162_cover_rules},
	]


# ================================================================ 도우미

func _strike(direction: int, tell: float, height: int, recovery := 0.0) -> AttackData:
	var atk := AttackData.new()
	atk.attack_name = "송곳 가림"
	atk.direction = direction as DuelTypes.Direction
	atk.tell_time = tell
	atk.recovery_time = recovery
	atk.heights.append(height)
	return atk


## 길 하나: 뿌리(방향·높이)와 걸음 [[방향, 높이, 간격], …], 가린 줄, 길 끝의 빈틈.
func _route(first_dir: int, first_height: int, steps: Array, cover: Array, recovery := 1.0) -> AttackData:
	var root := _strike(first_dir, 0.9, first_height, recovery)
	root.cover_columns.assign(cover)
	var chain: Array[Resource] = []
	for step: Array in steps:
		chain.append(_strike(int(step[0]), float(step[2]), int(step[1])))
	root.chain = chain
	return root


func _route_a() -> AttackData:
	return _route(L, HI, [[R, MID, 0.65]], [R])


func _route_b() -> AttackData:
	return _route(L, MID, [[R, MID, 0.65]], [R, C])


func _route_c() -> AttackData:
	return _route(C, MID, [], [C])


func _route_d() -> AttackData:
	return _route(L, HI, [[C, MID, 0.65], [R, LO, 0.6]], [R])


## 가운데만 빈 길.
func _route_e() -> AttackData:
	return _route(L, MID, [[R, MID, 0.65]], [L, R])


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


## 판을 차린다. 0초에 한 걸음 들어가 교전에서 시작한다(엉킴은 끈다).
func _new(opp: OpponentData, cfg: Dictionary, core_hook := Callable()) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(_f._rules(), weapon, opp, rng, none, false)
	if core_hook.is_valid():
		core_hook.call(core)
	var run := {"core": core, "bot": Bot.new(core, cfg)}
	core.step(1)
	return run


func _drive(run: Dictionary, cond: Callable, limit: float) -> bool:
	var core: DuelCore = run["core"]
	var bot: Bot = run["bot"]
	while not core.ended and core.time < limit:
		core.tick(DELTA)
		bot.update()
		if cond.call(core):
			return true
	return false


## 패턴이 끝난 틱: 마지막 STRIKE의 다음 타격이 없다.
func _pattern_over() -> Callable:
	return func(c: DuelCore) -> bool:
		var seen := c.record.of_type(DuelRecord.STRIKE)
		return not seen.is_empty() and float(seen.back().get("next_strike", -1.0)) < 0.0


## 길을 한 번 몰아 패턴이 끝난 틱에서 멈춘다.
func _to_end(route: AttackData, mode: StringName, opp_hook := Callable(), core_hook := Callable(), extra := {}) -> Dictionary:
	var run := _new(_opp(route, opp_hook), _cfg(mode, extra), core_hook)
	_drive(run, _pattern_over(), LIMIT)
	return run


func _last_strike(core: DuelCore) -> Dictionary:
	var seen := core.record.of_type(DuelRecord.STRIKE)
	return seen.back() if not seen.is_empty() else {}


func _attacks(core: DuelCore) -> Array[Dictionary]:
	return core.record.of_type(DuelRecord.ATTACK)


## 내 공격 하나를 누르고 판정이 날 때까지 몬다. 판정 이벤트를 돌려준다(없으면 빈 사전).
func _hit(run: Dictionary, direction: int, height: int) -> Dictionary:
	var core: DuelCore = run["core"]
	var before := _attacks(core).size()
	var bot: Bot = run["bot"]
	var guard := 0
	# 앞의 공격이 끝나 누를 수 있을 때까지 기다린다.
	while not core.ended and guard < 120 and core.player_state != DT.PlayerState.READY and core.player_state != DT.PlayerState.GUARD:
		core.tick(DELTA)
		bot.update()
		guard += 1
	core.set_aim(direction, height)
	core.press_attack()
	guard = 0
	while not core.ended and guard < 240 and _attacks(core).size() <= before:
		core.tick(DELTA)
		bot.update()
		guard += 1
	var seen := _attacks(core)
	return seen[before] if seen.size() > before else {}


## 막은 길의 끝에서 한 번 쳐 본다: 같은 길을 새 판으로 몰아 (방향, 높이)로 친 공격의 판정.
func _after(route_fn: Callable, mode: StringName, direction: int, height: int, opp_hook := Callable()) -> Dictionary:
	var run := _to_end(route_fn.call(), mode, opp_hook)
	return _hit(run, direction, height)


func _sample(errs: Array[String], label: String, ev: Dictionary, result: int, spiked: bool) -> void:
	if ev.is_empty():
		errs.append("[%s] 공격의 판정이 나지 않았다" % label)
		return
	if int(ev["result"]) != result or bool(ev.get("spiked", false)) != spiked:
		errs.append("[%s] 결과 %d · 걸림 %s (기대 %d · %s)" % [label, int(ev["result"]), str(ev.get("spiked", false)), result, str(spiked)])


# ================================================================ T162

func t162_cover_rules() -> String:
	var errs: Array[String] = []
	_t162_block(errs)
	_t162_columns(errs)
	_t162_parry(errs)
	_t162_not_set(errs)
	_t162_stagger(errs)
	_t162_lunge(errs)
	_t162_forecast(errs)
	_t162_off(errs)
	_t162_bots(errs)
	_t162_summary(errs)
	_t162_marks(errs)
	return "OK" if errs.is_empty() else ", ".join(errs)


## (가) 둘 다 막음: 끝 타격에만 cover, 회수 1.0, 걸리면 막힘·대가 없음·빈틈이 닫힘.
func _t162_block(errs: Array[String]) -> void:
	var run := _to_end(_route_a(), &"hold")
	var core: DuelCore = run["core"]
	var strikes := core.record.of_type(DuelRecord.STRIKE)
	if strikes.size() != 2:
		errs.append("[가] 타격 %d번 (기대 2)" % strikes.size())
		return
	if strikes[0].has("cover") or str(strikes[1].get("cover", [])) != str([R]):
		errs.append("[가] cover 열쇠 첫째 %s · 끝 %s (기대 없음 · [2])" % [str(strikes[0].get("cover", "없음")), str(strikes[1].get("cover", "없음"))])
	if absf(float(strikes[1]["recovery"]) - 1.0) > 0.001 or not core.spike_live() or core.covered_at != float(strikes[1]["t"]):
		errs.append("[가] 회수 %.2f · 살아 있음 %s · covered_at %.3f (기대 1.00 · 참 · 그 시각)" % [float(strikes[1]["recovery"]), str(core.spike_live()), core.covered_at])
	var posture := core.brain.posture
	var ev := _hit(run, R, MID)
	_sample(errs, "가 걸림", ev, DT.AttackResult.BLOCKED, true)
	if not ev.is_empty():
		if bool(ev["dodged"]) or bool(ev["rash"]) or int(ev["posture_gain"]) != 0 or core.brain.posture != posture:
			errs.append("[가] 걸림에 대가가 있다: 피함 %s · 섣부름 %s · 되찾음 %d · 상대 자세 %d → %d" % [str(ev["dodged"]), str(ev["rash"]), int(ev["posture_gain"]), posture, core.brain.posture])
		if int(ev["opponent_state"]) == DT.OpponentState.RECOVERY or core.spike_live():
			errs.append("[가] 걸린 뒤에도 빈틈이 남았다 (상대 상태 %d)" % int(ev["opponent_state"]))
	var again := _hit(run, L, MID)
	if not again.is_empty() and (int(again["result"]) != DT.AttackResult.BLOCKED or bool(again.get("spiked", false))):
		errs.append("[가] 닫힌 빈틈 뒤의 공격이 닿았다 (결과 %d)" % int(again["result"]))
	# 다른 줄은 지금처럼 닿는다.
	_sample(errs, "나 가운데", _after(_route_a, &"hold", C, MID), DT.AttackResult.GRAZE, false)
	_sample(errs, "나 왼쪽", _after(_route_a, &"hold", L, MID), DT.AttackResult.GRAZE, false)


## (다) 두 줄 가림: 왼쪽만 닿고 가운데·오른쪽은 걸린다.
func _t162_columns(errs: Array[String]) -> void:
	_sample(errs, "다 왼쪽", _after(_route_b, &"hold", L, MID), DT.AttackResult.GRAZE, false)
	_sample(errs, "다 가운데", _after(_route_b, &"hold", C, MID), DT.AttackResult.BLOCKED, true)
	_sample(errs, "다 오른쪽", _after(_route_b, &"hold", R, MID), DT.AttackResult.BLOCKED, true)
	# 단발 가림.
	_sample(errs, "다 단발 걸림", _after(_route_c, &"hold", C, MID), DT.AttackResult.BLOCKED, true)
	_sample(errs, "다 단발 왼쪽", _after(_route_c, &"hold", L, MID), DT.AttackResult.GRAZE, false)


## (라) 패리: 회수 1.0 + 0.85로 크게 열려도 가림이 산다. 패리 뒤 가린 줄이 아닌 칼 든 손은 닿는다.
func _t162_parry(errs: Array[String]) -> void:
	var run := _to_end(_route_b(), &"parry")
	var core: DuelCore = run["core"]
	var last := _last_strike(core)
	if last.is_empty() or int(last["result"]) != DT.StrikeResult.PARRIED:
		errs.append("[라] 끝 타격의 결과 %s (기대 패리)" % str(last.get("result", "없음")))
		return
	if absf(float(last["recovery"]) - 1.85) > 0.02 or not core.spike_live():
		errs.append("[라] 회수 %.2f · 가림 %s (기대 1.85 · 참)" % [float(last["recovery"]), str(core.spike_live())])
	_sample(errs, "라 왼쪽 상단", _hit(run, L, HI), DT.AttackResult.GRAZE, false)
	var run2 := _to_end(_route_b(), &"parry")
	_sample(errs, "라 가린 줄", _hit(run2, R, MID), DT.AttackResult.BLOCKED, true)


## (마) 내가 끝 타격을 맞음 · 안 열림 · 버티기: cover 열쇠도 가림도 없다.
func _t162_not_set(errs: Array[String]) -> void:
	var hit_run := _to_end(_route_a(), &"none")
	var hit_core: DuelCore = hit_run["core"]
	for ev in hit_core.record.of_type(DuelRecord.STRIKE):
		if ev.has("cover"):
			errs.append("[마] 내가 맞은 판의 STRIKE에 cover가 있다")
	if hit_core.spike_live() or hit_core.covered_at != -INF:
		errs.append("[마] 내가 맞은 판에 가림이 섰다 (covered_at %.3f)" % hit_core.covered_at)
	var closed_run := _to_end(_route_a(), &"hold", Callable(), func(c: DuelCore) -> void: c.brain.opening_chance = 0.0)
	var closed_core: DuelCore = closed_run["core"]
	var closed_last := _last_strike(closed_core)
	if closed_last.is_empty() or not bool(closed_last.get("closed", false)):
		errs.append("[마] 확률 0의 판에서 안 열림이 나지 않았다")
	if closed_last.has("cover") or closed_core.spike_live() or closed_core.covered_at != -INF:
		errs.append("[마] 안 열린 막기에 가림이 섰다")
	var braced := _route(C, MID, [], [C])
	braced.needs_raised_guard = true
	# 첫 예비 동작이 시작되기 전에 막기를 쥐어 둔다(would_brace_now는 막기가 예비 동작보다 앞서야 버티기다).
	var keep_run := _new(_opp(braced), _cfg(&"keep"))
	var keep_core: DuelCore = keep_run["core"]
	_drive(keep_run, func(c: DuelCore) -> bool: return c.time >= 0.5 and c.player_state == DT.PlayerState.READY, 5.0)
	keep_core.set_aim(C, MID)
	keep_core.set_guard(true)
	_drive(keep_run, _braced_seen(), LIMIT)
	var braced_seen := 0
	for ev in keep_core.record.of_type(DuelRecord.STRIKE):
		if not bool(ev.get("braced", false)):
			continue
		braced_seen += 1
		if ev.has("cover"):
			errs.append("[마] 버티기에 cover가 있다")
	if braced_seen == 0:
		errs.append("[마] 버티기 표본이 없다")
	elif keep_core.spike_live() or keep_core.covered_at != -INF:
		errs.append("[마] 버티기에 가림이 섰다")


## 버티기였던 타격이 하나라도 났는가.
func _braced_seen() -> Callable:
	return func(c: DuelCore) -> bool:
		for ev in c.record.of_type(DuelRecord.STRIKE):
			if bool(ev.get("braced", false)):
				return true
		return false


## (바) 무너짐: 자세 1의 사본에서 빈 줄 스침 → 무너짐 → 가린 줄 공격이 유효타.
func _t162_stagger(errs: Array[String]) -> void:
	var run := _to_end(_route_a(), &"hold", func(o: OpponentData) -> void: o.posture_max = 1)
	var core: DuelCore = run["core"]
	var first := _hit(run, L, MID)
	_sample(errs, "바 빈 줄", first, DT.AttackResult.GRAZE, false)
	if core.brain.state != DT.OpponentState.STAGGER:
		errs.append("[바] 자세 1의 스침 뒤 상대 상태 %d (기대 무너짐)" % core.brain.state)
		return
	if core.spike_live():
		errs.append("[바] 무너져도 가림이 살아 있다")
	_drive(run, func(c: DuelCore) -> bool: return c.player_state == DT.PlayerState.READY or c.player_state == DT.PlayerState.GUARD, 10.0)
	_sample(errs, "바 가린 줄", _hit(run, R, MID), DT.AttackResult.HIT, false)


## (사) 런지: 판정은 가운데 줄로 센다. 가운데가 가려진 회수면 걸리고, 아니면 닿고, 대기에서는 가림이 없다(결정 829).
func _t162_lunge(errs: Array[String]) -> void:
	var covered := _to_end(_route_c(), &"hold")
	var core: DuelCore = covered["core"]
	var until := core.brain.state_end
	var engage := DT.Distance.ENGAGE
	var recovery := DT.OpponentState.RECOVERY
	if core._verdict(DT.Part.TORSO, true, engage, recovery, until, core.time + 0.1, C) != DT.Forecast.SPIKE_COVERED:
		errs.append("[사] 가운데가 가려진 회수의 런지가 걸리지 않는다")
	if not core.lunge_spiked_now():
		errs.append("[사] lunge_spiked_now가 거짓이다")
	if core._verdict(DT.Part.TORSO, true, engage, DT.OpponentState.IDLE, until, core.time + 0.1, C) != DT.Forecast.REACH:
		errs.append("[사] 대기 중인 상대에게 간 런지가 가림을 만난다")
	var open := _to_end(_route_a(), &"hold")
	var open_core: DuelCore = open["core"]
	if open_core._verdict(DT.Part.TORSO, true, engage, recovery, open_core.brain.state_end, open_core.time + 0.1, C) != DT.Forecast.REACH or open_core.lunge_spiked_now():
		errs.append("[사] 가운데가 안 가려진 회수의 런지가 닿지 않는다")


## (아) 미리보기: 같은 함수라 판정과 같다. 방향 인자가 없으면 가린 빈틈에서도 닿는다.
func _t162_forecast(errs: Array[String]) -> void:
	var fx := load(EFFECTS_PATH) as PartEffectData
	var mark_fx := func(o: OpponentData) -> void: o.part_effects = fx
	var run := _to_end(_route_a(), &"hold", mark_fx)
	var core: DuelCore = run["core"]
	core.set_aim(R, MID)
	if int(core.attack_forecast()["verdict"]) != DT.Forecast.SPIKE_COVERED:
		errs.append("[아] 가린 줄 미리보기 %d (기대 송곳)" % int(core.attack_forecast()["verdict"]))
	core.set_aim(C, MID)
	if int(core.attack_forecast()["verdict"]) != DT.Forecast.REACH:
		errs.append("[아] 열린 줄 미리보기 %d (기대 닿는다)" % int(core.attack_forecast()["verdict"]))
	var plain := core._verdict(DT.Part.TORSO, false, DT.Distance.ENGAGE, DT.OpponentState.RECOVERY, core.brain.state_end, core.time + 0.1)
	if plain != DT.Forecast.REACH:
		errs.append("[아] 방향 인자 없는 판정 %d (기대 닿는다)" % plain)
	# 아홉 칸 모두: 미리보기의 답과 실제 판정이 같다.
	for direction in 3:
		for height in 3:
			var fresh := _new(_opp(_route_a(), mark_fx), _cfg(&"hold"))
			_drive(fresh, _pattern_over(), LIMIT)
			var fc: DuelCore = fresh["core"]
			fc.set_aim(direction, height)
			var verdict := int(fc.attack_forecast()["verdict"])
			var ev := _hit(fresh, direction, height)
			if ev.is_empty():
				errs.append("[아] %d·%d 판정이 나지 않았다" % [direction, height])
				continue
			var got := DT.Forecast.REACH
			if bool(ev.get("spiked", false)):
				got = DT.Forecast.SPIKE_COVERED
			elif bool(ev["dodged"]):
				got = DT.Forecast.HEAD_GUARDED
			elif int(ev["result"]) != DT.AttackResult.GRAZE and int(ev["result"]) != DT.AttackResult.HIT:
				got = DT.Forecast.NO_OPENING
			if verdict != got:
				errs.append("[아] (%d, %d) 미리보기 %d · 실제 %d" % [direction, height, verdict, got])


## (자) 칸이 빈 같은 길: 열쇠 둘이 한 번도 없고 covered_at이 -INF다.
func _t162_off(errs: Array[String]) -> void:
	var bare := _route(L, HI, [[R, MID, 0.65]], [])
	var run := _to_end(bare, &"hold")
	var core: DuelCore = run["core"]
	var ev := _hit(run, R, MID)
	for strike in core.record.of_type(DuelRecord.STRIKE):
		if strike.has("cover"):
			errs.append("[자] 칸이 빈 길의 STRIKE에 cover가 있다")
	if ev.is_empty() or ev.has("spiked") or core.covered_at != -INF or core.spike_live():
		errs.append("[자] 칸이 빈 길에 가림의 흔적이 있다")
	if ev.is_empty() or int(ev["result"]) != DT.AttackResult.GRAZE:
		errs.append("[자] 칸이 빈 길의 오른쪽 공격이 닿지 않는다")


## (차) 봇: 가운데로 받아치는 봇은 걸리지 않고, 마지막 줄 손은 읽지 않으면 걸리고 읽으면 빈 줄로 바꾼다. 가림 없는 판은 cover_read_fn에 흔들리지 않는다.
func _t162_bots(errs: Array[String]) -> void:
	var last_cell := func(ev: Dictionary) -> Variant:
		var atk := ev["attack"] as AttackData
		var height := int(ev.get("height", -1))
		return [atk.direction, height if height >= 0 else MID]
	var centre := Bot.first_blood_cfg()
	centre["counter_delay"] = 0.25
	var run := _new(_opp(_route_a()), _cfg(&"hold", centre))
	_drive(run, func(c: DuelCore) -> bool: return not c.record.of_type(DuelRecord.ATTACK).is_empty(), LIMIT)
	_sample(errs, "차 가운데 손", _first_attack(run), DT.AttackResult.GRAZE, false)
	var blind := _new(_opp(_route_a()), _cfg(&"hold", {"counter_fn": last_cell, "counter_delay": 0.25, "cover_read_fn": func(_ev: Dictionary) -> bool: return false}))
	_drive(blind, func(c: DuelCore) -> bool: return not c.record.of_type(DuelRecord.ATTACK).is_empty(), LIMIT)
	_sample(errs, "차 안 읽음", _first_attack(blind), DT.AttackResult.BLOCKED, true)
	var reads := _new(_opp(_route_a()), _cfg(&"hold", {"counter_fn": last_cell, "counter_delay": 0.25}))
	_drive(reads, func(c: DuelCore) -> bool: return not c.record.of_type(DuelRecord.ATTACK).is_empty(), LIMIT)
	var read_ev := _first_attack(reads)
	_sample(errs, "차 읽음", read_ev, DT.AttackResult.GRAZE, false)
	if not read_ev.is_empty() and int(read_ev["direction"]) != C:
		errs.append("[차] 읽은 봇이 가운데 줄로 바꾸지 않았다 (방향 %d)" % int(read_ev["direction"]))
	# 가림이 없는 바르톨로: cover_read_fn을 줘도 이벤트 줄이 같다.
	var lines_a := _bartolo_lines({"counter_fn": last_cell, "counter_delay": 0.25})
	var lines_b := _bartolo_lines({"counter_fn": last_cell, "counter_delay": 0.25, "cover_read_fn": func(_ev: Dictionary) -> bool: return false})
	if lines_a != lines_b:
		errs.append("[차] 가림이 없는 판의 이벤트 줄이 cover_read_fn에 따라 달라졌다")


func _first_attack(run: Dictionary) -> Dictionary:
	var seen := _attacks(run["core"])
	return seen[0] if not seen.is_empty() else {}


func _bartolo_lines(extra: Dictionary) -> Array[String]:
	var opp := (load(BARTOLO_PATH) as OpponentData).duplicate() as OpponentData
	var run := _new(opp, _cfg(&"hold", extra))
	_drive(run, func(_c: DuelCore) -> bool: return false, 30.0)
	return _f._lines(run["core"])


## (카) 요약: 가림이 없으면 covers 열쇠가 없고, 있으면 세 수와 길 글의 "#"이 있다.
func _t162_summary(errs: Array[String]) -> void:
	var off := _to_end(_route(L, HI, [[R, MID, 0.65]], []), &"hold")
	var off_summary := Summary.summarize((off["core"] as DuelCore).record)
	if off_summary.has("covers"):
		errs.append("[카] 가림이 없는 판의 요약에 covers가 있다")
	var run := _to_end(_route_a(), &"hold")
	_hit(run, C, MID)
	var summary := Summary.summarize((run["core"] as DuelCore).record)
	if not summary.has("covers") or int(summary["covers"]["가림"]) != 1 or int(summary["covers"]["걸림"]) != 0 or int(summary["covers"]["비껴 닿음"]) != 1:
		errs.append("[카] covers %s (기대 가림 1 · 걸림 0 · 비껴 닿음 1)" % str(summary.get("covers", "없음")))
	var has_mark := false
	for key: String in summary["routes"]:
		has_mark = has_mark or key.ends_with("#")
	if not has_mark:
		errs.append("[카] 길 글의 끝에 #이 없다 (%s)" % str(summary["routes"].keys()))
	var run2 := _to_end(_route_a(), &"hold")
	_hit(run2, R, MID)
	var summary2 := Summary.summarize((run2["core"] as DuelCore).record)
	if not summary2.has("covers") or int(summary2["covers"]["걸림"]) != 1:
		errs.append("[카] 걸린 판의 covers %s (기대 걸림 1)" % str(summary2.get("covers", "없음")))


## (타) 표시: 첫 예비 동작부터 빈틈이 끝날 때까지 한 틱도 끊기지 않는다(결정 831).
func _t162_marks(errs: Array[String]) -> void:
	_check_marks(errs, "Ⓐ", _route_a(), [R], "송곳 — 빈 줄: 왼쪽 · 가운데")
	_check_marks(errs, "Ⓓ", _route_d(), [R], "송곳 — 빈 줄: 왼쪽 · 가운데")
	_check_marks(errs, "Ⓑ", _route_b(), [R, C], "송곳 — 빈 줄: 왼쪽")
	# 가운데만 빈 길: 막으면 (머리 말고), 패리하면 머리가 열려 덧말이 없다.
	var shut := _to_end(_route_e(), &"hold")
	var shut_hint := OpponentView.recovery_hint_of(shut["core"])
	if shut_hint != "송곳 — 빈 줄: 가운데(머리 말고)":
		errs.append("[타] 가운데만 빈 길의 막힘 귀띔 '%s'" % shut_hint)
	var parried := _to_end(_route_e(), &"parry")
	var parried_hint := OpponentView.recovery_hint_of(parried["core"])
	if parried_hint != "송곳 — 빈 줄: 가운데":
		errs.append("[타] 가운데만 빈 길의 패리 귀띔 '%s'" % parried_hint)
	var none := _to_end(_route(L, HI, [[R, MID, 0.65]], []), &"hold")
	if OpponentView.recovery_hint_of(none["core"]) != "":
		errs.append("[타] 가림 없는 회수에 귀띔이 있다")


func _check_marks(errs: Array[String], label: String, route: AttackData, want: Array, hint: String) -> void:
	var run := _new(_opp(route), _cfg(&"hold"))
	var core: DuelCore = run["core"]
	var bot: Bot = run["bot"]
	var total := route.chain.size() + 1
	var started := false
	var gaps := 0
	var ticks := 0
	var hint_seen := ""
	var closed := false
	while not core.ended and core.time < LIMIT:
		core.tick(DELTA)
		bot.update()
		if not started:
			started = not core.record.of_type(DuelRecord.TELL_START).is_empty()
			if not started:
				continue
		ticks += 1
		var marks := CoverMarks.cover_marks_of(core)
		var strikes := core.record.of_type(DuelRecord.STRIKE).size()
		if strikes < total:
			if marks.is_empty() or str(marks["columns"]) != str(want) or bool(marks["live"]):
				gaps += 1
		elif core.brain.state == DT.OpponentState.RECOVERY:
			if marks.is_empty() or str(marks["columns"]) != str(want) or not bool(marks["live"]):
				gaps += 1
			hint_seen = OpponentView.recovery_hint_of(core)
		else:
			if not marks.is_empty():
				errs.append("[타 %s] 빈틈이 끝난 뒤에도 표지가 남았다" % label)
			closed = true
			break
	if not closed or ticks < 60:
		errs.append("[타 %s] 빈틈이 끝나는 틱까지 가지 못했다 (틱 %d)" % [label, ticks])
	if gaps != 0:
		errs.append("[타 %s] 표지가 끊기거나 어긋난 틱 %d개" % [label, gaps])
	if hint_seen != hint:
		errs.append("[타 %s] 빈틈의 귀띔 '%s' (기대 '%s')" % [label, hint_seen, hint])
