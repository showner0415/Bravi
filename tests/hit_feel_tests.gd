extends RefCounted
## T210~T212: 타격감(계획 H02) — 순간 고르기·값·소리 / 멈칫과 움찔(살아 있는 판에서만, 읽기 층은 그대로) / 한 판의 멈칫 합.
## T211은 결투 씬을 트리에 두고 advance·_physics_process를 직접 부른다(프레임을 돌리지 않는다, 실제 시간에 기대지 않는다).

const Bot := preload("res://tests/duel_bots.gd")
const Digest := preload("res://tests/event_digest.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const DELTA := 1.0 / 60.0
const Sr := DT.StrikeResult
const Ar := DT.AttackResult

var _tree: SceneTree
var _made: Array[Node] = []


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T210", "name": "타격감의 값과 고르기·소리: 순간의 표 아홉과 그 밖(안 열린 것·가운데·헛침은 비움), 손으로 만든 이벤트, 위계, 새 음", "fn": t210_values},
		{"id": "T211", "name": "멈칫과 움찔: 살아 있는 판에서만 서고, 멈칫은 시간을 멈추고 누르면 끝나고, 움찔은 거둬지고 읽기 층은 그대로", "fn": t211_stop_and_flinch},
		{"id": "T212", "name": "멈칫의 합: 여덟 상대 1단 봇 한 판마다 판 길이의 6% 이하", "fn": t212_stop_budget},
	]


func cleanup() -> void:
	for node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


func _strike(result: int, next := -1.0, extra := {}) -> Dictionary:
	var ev := {"type": DuelRecord.STRIKE, "result": result, "next_strike": next, "braced": false, "closed": false,
			"recovery": 1.0}
	ev.merge(extra, true)
	return ev


func _attack(result: int, extra := {}) -> Dictionary:
	var ev := {"type": DuelRecord.ATTACK, "result": result, "direction": DT.Direction.CENTER, "cells": 1,
			"rash": false, "dodged": false}
	ev.merge(extra, true)
	return ev


func _sweep_root() -> AttackData:
	var root := AttackData.new()
	root.sweep = true
	root.chain.append(AttackData.new())
	return root


func _dive_root() -> AttackData:
	var root := AttackData.new()
	root.dive = true
	return root


func _spawn(seed_value := 1, physics := true) -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", seed_value)
	_tree.root.add_child(duel)
	duel.set_physics_process(physics)
	_made.append(duel)
	return duel


## 한 틱씩 걸으며 처음으로 내 공격이 닿은 순간의 이벤트들(그 틱의 것 전부)을 찾는다. 못 찾으면 빈 배열.
func _until_dealt(duel: Node, driver: Bot, limit_ticks := 4000) -> Array:
	var core: DuelCore = duel.get("core")
	var seen := core.record.events.size()
	for i in limit_ticks:
		duel.call("advance", DELTA)
		var fresh: Array = core.record.events.slice(seen)
		seen = core.record.events.size()
		for ev: Dictionary in fresh:
			var moment := HitFeel.moment_of(ev, null)
			if moment == HitFeel.GRAZE_DEALT or moment == HitFeel.HIT_DEALT:
				return fresh
		if core.ended:
			break
		driver.update()
	return []


func _dealt_of(fresh: Array) -> Dictionary:
	for ev: Dictionary in fresh:
		var moment := HitFeel.moment_of(ev, null)
		if moment == HitFeel.GRAZE_DEALT or moment == HitFeel.HIT_DEALT:
			return ev
	return {}


func _expected_ticks(fresh: Array) -> int:
	var msec := 0
	for ev: Dictionary in fresh:
		msec = maxi(msec, HitFeel.stop_msec(HitFeel.moment_of(ev, null), ev))
	return roundi(msec * Engine.physics_ticks_per_second / 1000.0)


func _action(action: StringName, pressed := true) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	return ev


# ================================================================ T210

func t210_values() -> String:
	var errs: Array[String] = []
	var plain := AttackData.new()
	var sweep := _sweep_root()
	var dive := _dive_root()



	# 내 공격이 닿음
	var hit := _attack(Ar.HIT)
	_expect(errs, HitFeel.moment_of(hit, null) == HitFeel.HIT_DEALT and HitFeel.stop_msec(HitFeel.HIT_DEALT) == 120, "유효타 넣음 120ms")
	_expect(errs, HitFeel.flinch(HitFeel.HIT_DEALT, hit) == Vector2(0.0, -28.0), "찌르기 유효타의 움찔은 -y 28")
	_expect(errs, HitFeel.flinch(HitFeel.HIT_DEALT, _attack(Ar.HIT, {"direction": DT.Direction.LEFT})) == Vector2(28.0, 0.0), "왼쪽 베기는 +x")
	_expect(errs, HitFeel.flinch(HitFeel.HIT_DEALT, _attack(Ar.HIT, {"direction": DT.Direction.RIGHT})) == Vector2(-28.0, 0.0), "오른쪽 베기는 -x")
	var graze1 := _attack(Ar.GRAZE)
	var graze2 := _attack(Ar.GRAZE, {"cells": 2})
	_expect(errs, HitFeel.moment_of(graze1, null) == HitFeel.GRAZE_DEALT, "스침 넣음")
	_expect(errs, HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze1) == 50 and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze2) == 70, "스침 멈칫 1칸 50 · 2칸 70")
	_expect(errs, HitFeel.flinch(HitFeel.GRAZE_DEALT, graze2).length() > HitFeel.flinch(HitFeel.GRAZE_DEALT, graze1).length() and HitFeel.flinch(HitFeel.GRAZE_DEALT, graze1).length() > 0.0, "2칸 움찔이 1칸보다 크다")
	for flag in ["spiked", "rash", "dodged"]:
		var skipped := _attack(Ar.GRAZE, {flag: true})
		_expect(errs, HitFeel.moment_of(skipped, null) == &"", "%s ATTACK은 비움" % flag)
	_expect(errs, HitFeel.moment_of({"type": DuelRecord.STAGGER_START}, null) == HitFeel.STAGGER and HitFeel.stop_msec(HitFeel.STAGGER) == 90, "무너뜨림 90ms")
	_expect(errs, HitFeel.flinch(HitFeel.STAGGER, {}) == Vector2.ZERO, "무너뜨림 움찔은 스침의 것")

	# 열린 패리와 읽어 연 끝
	var parry := _strike(Sr.PARRIED)
	_expect(errs, HitFeel.moment_of(parry, plain) == HitFeel.PARRY_OPEN and HitFeel.stop_msec(HitFeel.PARRY_OPEN) == 90, "열린 패리 90ms")
	_expect(errs, HitFeel.flinch(HitFeel.PARRY_OPEN, parry) == Vector2(0.0, -14.0), "패리 움찔 위로 14")
	_expect(errs, HitFeel.moment_of(_strike(Sr.PARRIED, 3.0), plain) == &"", "패턴 가운데의 패리는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.PARRIED, -1.0, {"closed": true}), plain) == &"", "안 열린 패리는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.PARRIED, -1.0, {"bitten": true}), plain) == &"", "속은 패리는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED), sweep) == HitFeel.SWEEP_OPEN, "휩쓸기 끝의 막기")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED), dive) == HitFeel.DIVE_OPEN, "뛰어들기 막아 엶")
	_expect(errs, HitFeel.flinch(HitFeel.SWEEP_OPEN, {}) == Vector2(0.0, -10.0) and HitFeel.stop_msec(HitFeel.DIVE_OPEN) == 70, "막아 엶: 70ms, 위로 10")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED), plain) == &"" and HitFeel.moment_of(_strike(Sr.BLOCKED), null) == &"", "보통 뿌리·뿌리 없음의 막기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED, 3.0), sweep) == &"", "패턴 가운데의 막기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED, -1.0, {"braced": true}), sweep) == &"", "버티기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED, -1.0, {"closed": true}), sweep) == &"", "안 열린 막기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.WHIFF), dive) == HitFeel.DIVE_WHIFF and HitFeel.stop_msec(HitFeel.DIVE_WHIFF) == 70, "뛰어들기 헛치게 함")
	_expect(errs, HitFeel.flinch(HitFeel.DIVE_WHIFF, {}) == Vector2.ZERO, "헛치게 한 움찔은 0")
	_expect(errs, HitFeel.moment_of(_strike(Sr.WHIFF, -1.0, {"recovery": 0.0}), dive) == &"", "빈틈 없는 헛침은 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.WHIFF), plain) == &"", "보통 공격의 헛침은 비움")

	# 내가 맞음
	_expect(errs, HitFeel.moment_of(_strike(Sr.HIT), plain) == HitFeel.HIT_TAKEN and HitFeel.stop_msec(HitFeel.HIT_TAKEN) == 120, "유효타 맞음 120ms")
	_expect(errs, HitFeel.moment_of(_strike(Sr.GRAZE), plain) == HitFeel.GRAZE_TAKEN and HitFeel.stop_msec(HitFeel.GRAZE_TAKEN) == 70, "스침 맞음 70ms")
	_expect(errs, HitFeel.flinch(HitFeel.HIT_TAKEN, {}) == Vector2.ZERO and HitFeel.flinch(HitFeel.GRAZE_TAKEN, {}) == Vector2.ZERO, "맞은 쪽은 상대가 움찔하지 않는다")

	# 위계와 상한
	var stops := HitFeel.STOP_MSEC
	_expect(errs, stops[HitFeel.HIT_DEALT] == stops[HitFeel.HIT_TAKEN] and stops[HitFeel.HIT_DEALT] > stops[HitFeel.PARRY_OPEN], "유효타 > 패리")
	_expect(errs, stops[HitFeel.PARRY_OPEN] == stops[HitFeel.STAGGER] and stops[HitFeel.STAGGER] > stops[HitFeel.SWEEP_OPEN], "패리 = 무너뜨림 > 열린 끝")
	_expect(errs, HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze2) == stops[HitFeel.SWEEP_OPEN] and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze1) < stops[HitFeel.SWEEP_OPEN] \
			and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze1) > 0, "스침 2칸 = 열린 끝 > 스침 1칸 > 0")
	for key: StringName in stops:
		_expect(errs, stops[key] <= 150, "%s 멈칫 150ms 이하" % key)

	# 손으로 만든 이벤트: 열쇠가 빠져도 오류 없이 정한 값
	var handmade_attack := {"type": DuelRecord.ATTACK, "result": Ar.GRAZE, "part": DT.Part.TORSO}
	_expect(errs, HitFeel.moment_of(handmade_attack, null) == HitFeel.GRAZE_DEALT and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, handmade_attack) == 50 \
			and HitFeel.flinch(HitFeel.GRAZE_DEALT, handmade_attack) == Vector2(0.0, -10.0), "열쇠 빠진 ATTACK: 1칸 스침, 가운데 방향")
	_expect(errs, HitFeel.moment_of({"type": DuelRecord.STRIKE, "braced": false}, plain) == &"", "result 없는 STRIKE는 비움")
	_expect(errs, HitFeel.stop_msec(&"") == 0 and HitFeel.flinch(&"", {}) == Vector2.ZERO, "비운 순간은 0")

	_check_tones(errs)
	return _result(errs)


func _check_tones(errs: Array[String]) -> void:
	var beeper := Beeper.new()
	_tree.root.add_child(beeper)
	_made.append(beeper)
	var streams: Dictionary = beeper.get("_streams")
	for key in [&"graze_dealt", &"graze_taken", &"hit_dealt", &"hit_taken", &"parry", &"dodge_open"]:
		_expect(errs, streams.has(key), "새 음 %s가 없다" % key)
	_expect(errs, not streams.has(&"graze") and not streams.has(&"hit"), "옛 graze·hit 키가 남았다")
	var dealt_min := INF
	for key in [&"graze_dealt", &"hit_dealt"]:
		dealt_min = minf(dealt_min, Beeper.TONES[key][0])
	var taken_max := 0.0
	for key in [&"graze_taken", &"hit_taken"]:
		taken_max = maxf(taken_max, Beeper.TONES[key][0])
		if (Beeper.TONES[key] as Array).size() > 2:
			taken_max = maxf(taken_max, Beeper.TONES[key][2])
	_expect(errs, dealt_min > taken_max, "넣은 쪽의 가장 낮은 음이 맞은 쪽의 가장 높은 음보다 높다")
	for key in [&"hit_dealt", &"hit_taken", &"parry"]:
		var data: PackedByteArray = (streams[key] as AudioStreamWAV).data
		var peak := 0
		for i in range(0, data.size(), 2):
			peak = maxi(peak, absi(data.decode_s16(i)))
		_expect(errs, peak <= 32767, "%s 샘플이 1.0을 넘었다" % key)
	var plain_sound := {"type": DuelRecord.STRIKE, "result": DT.StrikeResult.BLOCKED, "closed": false}
	beeper.on_event(plain_sound)
	beeper.call("play", &"block")
	var voiced := false
	for player: AudioStreamPlayer in beeper.get("_players"):
		voiced = voiced or player.stream != null
	_expect(errs, voiced, "on_event(ev)·play(&\"block\")가 소리를 내지 않았다")


# ================================================================ T211

func t211_stop_and_flinch() -> String:
	var errs: Array[String] = []
	var duel := _spawn()
	var core: DuelCore = duel.get("core")

	# (1) 살아 있는 판에서 스치면 멈칫이 선다
	var fresh := _until_dealt(duel, Bot.new(core, Bot.first_blood_cfg()))
	_expect(errs, not fresh.is_empty(), "(1) 내 공격이 닿는 순간을 못 만났다")
	if fresh.is_empty():
		return _result(errs)
	var want := _expected_ticks(fresh)
	var stop: int = duel.get("_stop_ticks_left")
	_expect(errs, want > 0 and stop == want, "(1) 멈칫 tick %d, 기대 %d" % [stop, want])

	# (2) 멈칫 동안 _physics_process는 코어 시각을 바꾸지 않고, 그다음 한 번은 바꾼다
	var before := core.time
	for i in stop:
		duel.call("_physics_process", DELTA)
	_expect(errs, core.time == before and int(duel.get("_stop_ticks_left")) == 0, "(2) 멈칫 중 코어 시각이 흘렀다")
	if not core.ended:
		duel.call("_physics_process", DELTA)
		_expect(errs, core.time > before, "(2) 멈칫 뒤 첫 걸음이 코어를 움직이지 않았다")

	# (1b) 물리를 끈 판에서는 멈칫도 움찔도 서지 않는다
	var dead := _spawn(1, false)
	var dead_core: DuelCore = dead.get("core")
	var dead_fresh := _until_dealt(dead, Bot.new(dead_core, Bot.first_blood_cfg()))
	_expect(errs, not dead_fresh.is_empty(), "(1b) 물리를 끈 판에서 내 공격이 닿는 순간을 못 만났다")
	_expect(errs, int(dead.get("_stop_ticks_left")) == 0 and (dead.get("_opponent_view") as Object).get("_flinch_vec") == Vector2.ZERO, "(1b) 물리를 끈 판에 멈칫·움찔이 섰다")

	# (3) 멈칫 중 누르면 그 자리의 마우스 칸으로 나가고 멈칫이 끝난다
	var live := _spawn()
	var live_core: DuelCore = live.get("core")
	live.set("mouse_aim_enabled", true)
	live.set("_use_virtual_mouse", true)
	var size := (live as Node2D).get_viewport_rect().size
	live.set("_virtual_mouse", Vector2(size.x * 0.9, size.y * 0.1))
	live.set("_stop_ticks_left", 3)
	live.call("_unhandled_input", _action(&"attack"))
	var starts := live_core.record.of_type(DuelRecord.ATTACK_START)
	_expect(errs, int(live.get("_stop_ticks_left")) == 0, "(3) 누름이 멈칫을 끝내지 않았다")
	_expect(errs, not starts.is_empty() and starts[-1]["direction"] == 2 and starts[-1]["height"] == 0, "(3) 공격이 누른 순간의 마우스 칸으로 나가지 않았다")

	# (4) pause()·start_duel()이 멈칫을 지운다
	live.set("_stop_ticks_left", 5)
	_expect(errs, bool(live.call("pause", &"esc")) and int(live.get("_stop_ticks_left")) == 0, "(4) pause가 멈칫을 지우지 않았다")
	live.set("_stop_ticks_left", 4)
	live.set("_hit_root", _dive_root())
	live.call("start_duel")
	_expect(errs, int(live.get("_stop_ticks_left")) == 0 and live.get("_hit_root") == null, "(4) start_duel이 멈칫·뿌리를 지우지 않았다")

	# (5) 움찔의 자리와 거둠
	var view: OpponentView = live.get("_opponent_view")
	live_core = live.get("core")
	live.set("mouse_aim_enabled", false)
	var vec := Vector2(28.0, 0.0)
	live.call("advance", DELTA)
	view.update_view(live_core, live_core.time, 0.0)
	var base: Vector2 = view.get("_base_position")
	_expect(errs, view.position == base, "(5) 움찔이 없을 때 position이 기준과 다르다")
	var label_before := (view.get_node("StateLabel") as Control).global_position
	view.start_flinch(vec, live_core.time)
	view.update_view(live_core, live_core.time, 0.0)
	_expect(errs, view.position.is_equal_approx(base + vec), "(5) 스친 직후 뿌리 = 기준 + 벡터")
	_expect(errs, (view.get_node("StateLabel") as Control).global_position.is_equal_approx(label_before), "(6) 움찔이 상태 글자를 움직였다")
	var tag := view.get("_forecast_tag") as Control
	var tag_before := tag.global_position
	var tag_was_on := tag.visible
	view.update_view(live_core, live_core.time, 0.0)
	_expect(errs, not (tag_was_on and tag.visible) or tag.global_position.is_equal_approx(tag_before), "(6) 움찔이 꼬리표를 움직였다")
	view.update_view(live_core, live_core.time + 0.16, 0.0)
	_expect(errs, view.position == view.get("_base_position"), "(5) 코어 0.15초 뒤에 기준으로 돌아오지 않았다")
	view.start_flinch(vec, live_core.time)
	view.update_view(live_core, live_core.time, 0.2)
	_expect(errs, view.position == view.get("_base_position"), "(5) _clock 0.2초 뒤에 기준으로 돌아오지 않았다")
	view.start_flinch(vec, live_core.time)
	view.on_event({"type": DuelRecord.TELL_START, "attack": null})
	view.update_view(live_core, live_core.time, 0.0)
	_expect(errs, view.position == view.get("_base_position"), "(5) TELL_START가 움찔을 지우지 않았다")
	view.start_flinch(vec, live_core.time)
	live.call("start_duel")
	view.update_view(live.get("core"), 0.0, 0.0)
	_expect(errs, view.position == view.get("_base_position"), "(5) start_duel이 움찔을 지우지 않았다")

	# (5b) 유효타로 끝난 판의 정지 장은 움찔이 선 채이고, _clock이 거둔다
	_check_final_flinch(errs)

	# (7) 휩쓸기의 끝을 쥐고 막아 열면 70ms, 보통 뿌리의 끝은 0
	var gate := _spawn()
	var sweep_stop := _stop_after_blocked_end(gate, _sweep_root())
	var plain_stop := _stop_after_blocked_end(gate, AttackData.new())
	_expect(errs, sweep_stop == 4, "(7) 휩쓸기 끝의 막기 멈칫 tick %d (기대 4)" % sweep_stop)
	_expect(errs, plain_stop == 0, "(7) 보통 단발의 막기에 멈칫이 섰다 (%d)" % plain_stop)
	return _result(errs)


## 뿌리를 기억시킨 뒤 끝의 막기 이벤트를 씬이 받게 한다. 돌려줌: 선 멈칫 tick.
func _stop_after_blocked_end(duel: Node, root: AttackData) -> int:
	var core: DuelCore = duel.get("core")
	duel.set("_stop_ticks_left", 0)
	duel.set("_hit_root", root)
	var ev := _strike(DT.StrikeResult.BLOCKED, -1.0, {
		"t": core.time, "attack": root, "situation": 0, "recovery_end": core.time + 1.0, "player_posture": 3,
		"posture_loss": 0, "height": -1, "guard_miss": false, "closed_streak": 0, "miss_limit": 0,
	})
	duel.call("_on_core_event", ev)
	return int(duel.get("_stop_ticks_left"))


func _check_final_flinch(errs: Array[String]) -> void:
	for seed_value in range(1, 6):
		var duel := _spawn(seed_value)
		var core: DuelCore = duel.get("core")
		var driver := Bot.new(core, Bot.first_blood_cfg())
		var last_attack := {}
		var seen := 0
		for i in 4000:
			duel.call("advance", DELTA)
			for ev: Dictionary in core.record.events.slice(seen):
				if ev["type"] == DuelRecord.ATTACK:
					last_attack = ev
			seen = core.record.events.size()
			if core.ended:
				break
			driver.update()
		if not core.ended or last_attack.get("result", -1) != DT.AttackResult.HIT or last_attack.get("rash", false):
			continue
		var view: OpponentView = duel.get("_opponent_view")
		var base: Vector2 = view.get("_base_position")
		_expect(errs, view.position.is_equal_approx(base + HitFeel.flinch(HitFeel.HIT_DEALT, last_attack)),
				"(5b) 유효타로 끝난 판의 정지 장이 움찔 0이다")
		view.update_view(core, core.time, 0.2)
		_expect(errs, view.position == view.get("_base_position"), "(5b) 끝난 판의 움찔이 _clock으로 거둬지지 않았다")
		return
	errs.append("(5b) 다섯 시드 안에 유효타로 끝난 판이 없다")


# ================================================================ T212

func t212_stop_budget() -> String:
	var errs: Array[String] = []
	var rules: DuelRules = ResourceLoader.load(Digest.RULES_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as DuelRules
	var weapon: WeaponData = ResourceLoader.load(Digest.WEAPON_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as WeaponData
	for path in Digest.OPPONENT_PATHS:
		var base: OpponentData = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as OpponentData
		var opponent := base.with_opening(rules.opening_chance_for(base.opening_chance, Digest.OPENING_DAY))
		var record: DuelRecord = Digest._play(rules, weapon, opponent, 1, "parry")
		var root: AttackData = null
		var per_time := {}
		var length := 0.0
		for ev: Dictionary in record.events:
			length = maxf(length, float(ev.get("t", 0.0)))
			if ev["type"] == DuelRecord.TELL_START:
				root = ev.get("attack") as AttackData
			var msec := HitFeel.stop_msec(HitFeel.moment_of(ev, root), ev)
			var at: float = ev.get("t", 0.0)
			per_time[at] = maxi(int(per_time.get(at, 0)), msec)
		var total := 0.0
		for msec: int in per_time.values():
			total += msec / 1000.0
		# 기준 6%: 계획은 4%였으나 완벽한 패리 봇이 5.6%까지 간다(사용자 2026-11-28 "6%로").
		_expect(errs, length > 0.0 and total <= length * 0.06, "%s: 멈칫 합 %.2f초 / 판 %.1f초 (6%% = %.2f)" % [path, total, length, length * 0.06])
	return _result(errs)
