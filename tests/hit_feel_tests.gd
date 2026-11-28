extends RefCounted
## T210~T212: 타격감(계획 H02) — 순간 고르기·값·소리 / 멈칫과 움찔(살아 있는 판에서만, 읽기 층은 그대로) / 한 판의 멈칫 합.
## T211은 결투 씬을 트리에 두고 advance·_physics_process를 직접 부른다(프레임을 돌리지 않는다, 실제 시간에 기대지 않는다).

const Bot := preload("res://tests/duel_bots.gd")
const Digest := preload("res://tests/event_digest.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const StyleScript := preload("res://tests/style_tests.gd")

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
		{"id": "T212", "name": "멈칫의 합: 여덟 상대 1단 봇 한 판마다 판 길이의 10% 이하", "fn": t212_stop_budget},
		{"id": "T218", "name": "떨림: 멈칫의 tick마다 맞은 쪽 그림만 부호를 뒤집으며 0까지 줄고 읽기 층은 그대로, 내가 맞으면 내 손이 떤다, advance·pause·start_duel에서는 0", "fn": t218_shake},
		{"id": "T219", "name": "맞음의 화면: 킥·비네트(맞은 쪽이 짙고 0.35초 뒤 꺼지고 TELL_START가 지움, advance에서는 0), 결과 패널 늦춤(멈칫 + 21번, 그동안 ui_accept·R 무시, 시간 초과·advance는 곧바로)", "fn": t219_hit_screen},
		{"id": "T220", "name": "작은 것: 자세 칸의 번쩍임, 불꽃의 줄 수와 앞·뒤 반평면, 0.12초 뒤 0줄, 층의 차례, 상아색의 떨어짐", "fn": t220_small_things},
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
## via_physics가 참이면 엔진의 걸음(_physics_process)으로 걷는다: 멈칫·움찔은 그 안에서만 선다(계획 H03 결정 928).
func _until_dealt(duel: Node, driver: Bot, limit_ticks := 4000, via_physics := false) -> Array:
	var core: DuelCore = duel.get("core")
	var seen := core.record.events.size()
	for i in limit_ticks:
		duel.call("_physics_process" if via_physics else "advance", DELTA)
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
	_expect(errs, HitFeel.moment_of(hit, null) == HitFeel.HIT_DEALT and HitFeel.stop_msec(HitFeel.HIT_DEALT) == 180, "유효타 넣음 180ms")
	# 넣은 쪽의 평행이동은 0이다: 맞은 포즈·떨림이 갈음한다(계획 H03 결정 938).
	_expect(errs, HitFeel.flinch(HitFeel.HIT_DEALT, hit) == Vector2.ZERO, "유효타 넣음의 움찔은 0")
	_expect(errs, HitFeel.flinch(HitFeel.HIT_DEALT, _attack(Ar.HIT, {"direction": DT.Direction.LEFT})) == Vector2.ZERO, "왼쪽 베기도 0")
	var graze1 := _attack(Ar.GRAZE)
	var graze2 := _attack(Ar.GRAZE, {"cells": 2})
	_expect(errs, HitFeel.moment_of(graze1, null) == HitFeel.GRAZE_DEALT, "스침 넣음")
	_expect(errs, HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze1) == 80 and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze2) == 100, "스침 멈칫 1칸 80 · 2칸 100")
	_expect(errs, HitFeel.flinch(HitFeel.GRAZE_DEALT, graze2) == Vector2.ZERO and HitFeel.flinch(HitFeel.GRAZE_DEALT, graze1) == Vector2.ZERO, "스침 넣음의 움찔은 0")
	_expect(errs, absf(HitFeel.shake_px(HitFeel.GRAZE_DEALT, 3, 3, graze1)) == 4.0 and absf(HitFeel.shake_px(HitFeel.GRAZE_DEALT, 4, 4, graze2)) == 5.0, "떨림 폭 스침 1칸 4 · 2칸 5")
	for flag in ["spiked", "rash", "dodged"]:
		var skipped := _attack(Ar.GRAZE, {flag: true})
		_expect(errs, HitFeel.moment_of(skipped, null) == &"", "%s ATTACK은 비움" % flag)
	_expect(errs, HitFeel.moment_of({"type": DuelRecord.STAGGER_START}, null) == HitFeel.STAGGER and HitFeel.stop_msec(HitFeel.STAGGER) == 130, "무너뜨림 130ms")
	_expect(errs, HitFeel.flinch(HitFeel.STAGGER, {}) == Vector2.ZERO, "무너뜨림 움찔은 스침의 것")

	# 열린 패리와 읽어 연 끝
	var parry := _strike(Sr.PARRIED)
	_expect(errs, HitFeel.moment_of(parry, plain) == HitFeel.PARRY_OPEN and HitFeel.stop_msec(HitFeel.PARRY_OPEN) == 130, "열린 패리 130ms")
	_expect(errs, HitFeel.flinch(HitFeel.PARRY_OPEN, parry) == Vector2.ZERO and absf(HitFeel.shake_px(HitFeel.PARRY_OPEN, 5, 5)) == 5.0, "패리 움찔 0 · 떨림 5")
	var mid := _strike(Sr.PARRIED, 3.0)
	_expect(errs, HitFeel.moment_of(mid, plain) == HitFeel.PARRY_MID and HitFeel.stop_msec(HitFeel.PARRY_MID) == 0 \
			and HitFeel.flinch(HitFeel.PARRY_MID, mid) == Vector2.ZERO and HitFeel.shake_px(HitFeel.PARRY_MID, 3, 3) == 0.0, "패턴 가운데의 패리는 PARRY_MID — 멈칫·움찔·떨림 0")
	_expect(errs, HitFeel.moment_of(_strike(Sr.PARRIED, -1.0, {"closed": true}), plain) == &"", "안 열린 패리는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.PARRIED, -1.0, {"bitten": true}), plain) == &"", "속은 패리는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED), sweep) == HitFeel.SWEEP_OPEN, "휩쓸기 끝의 막기")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED), dive) == HitFeel.DIVE_OPEN, "뛰어들기 막아 엶")
	_expect(errs, HitFeel.flinch(HitFeel.SWEEP_OPEN, {}) == Vector2.ZERO and HitFeel.stop_msec(HitFeel.DIVE_OPEN) == 100, "막아 엶: 100ms, 움찔 0")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED), plain) == &"" and HitFeel.moment_of(_strike(Sr.BLOCKED), null) == &"", "보통 뿌리·뿌리 없음의 막기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED, 3.0), sweep) == &"", "패턴 가운데의 막기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED, -1.0, {"braced": true}), sweep) == &"", "버티기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.BLOCKED, -1.0, {"closed": true}), sweep) == &"", "안 열린 막기는 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.WHIFF), dive) == HitFeel.DIVE_WHIFF and HitFeel.stop_msec(HitFeel.DIVE_WHIFF) == 100, "뛰어들기 헛치게 함")
	_expect(errs, HitFeel.flinch(HitFeel.DIVE_WHIFF, {}) == Vector2.ZERO, "헛치게 한 움찔은 0")
	_expect(errs, HitFeel.moment_of(_strike(Sr.WHIFF, -1.0, {"recovery": 0.0}), dive) == &"", "빈틈 없는 헛침은 비움")
	_expect(errs, HitFeel.moment_of(_strike(Sr.WHIFF), plain) == &"", "보통 공격의 헛침은 비움")

	# 내가 맞음
	_expect(errs, HitFeel.moment_of(_strike(Sr.HIT), plain) == HitFeel.HIT_TAKEN and HitFeel.stop_msec(HitFeel.HIT_TAKEN) == 180, "유효타 맞음 180ms")
	_expect(errs, HitFeel.moment_of(_strike(Sr.GRAZE), plain) == HitFeel.GRAZE_TAKEN and HitFeel.stop_msec(HitFeel.GRAZE_TAKEN) == 100, "스침 맞음 100ms")
	# 맞은 쪽의 킥(결정 942): 왼쪽에서 온 타격은 -x, 오른쪽은 +x, 찌르기(방향 없음 포함)는 +y. 스침 12px, 유효타 18px.
	var from_left := AttackData.new()
	from_left.direction = DT.Direction.LEFT
	var from_right := AttackData.new()
	from_right.direction = DT.Direction.RIGHT
	_expect(errs, HitFeel.flinch(HitFeel.GRAZE_TAKEN, {"attack": from_left}) == Vector2(-12.0, 0.0), "왼쪽에서 스침: (-12, 0)")
	_expect(errs, HitFeel.flinch(HitFeel.HIT_TAKEN, {"attack": from_right}) == Vector2(18.0, 0.0), "오른쪽에서 유효타: (18, 0)")
	_expect(errs, HitFeel.flinch(HitFeel.HIT_TAKEN, {}) == Vector2(0.0, 18.0) and HitFeel.flinch(HitFeel.GRAZE_TAKEN, {"attack": AttackData.new()}) == Vector2(0.0, 12.0), "찌르기·방향 없음은 +y")
	_expect(errs, absf(HitFeel.shake_px(HitFeel.HIT_TAKEN, 8, 8)) == 8.0 and absf(HitFeel.shake_px(HitFeel.GRAZE_TAKEN, 7, 7)) == 5.0 and absf(HitFeel.shake_px(HitFeel.STAGGER, 6, 6)) == 6.0, "떨림 폭 유효타 8 · 스침 맞음 5 · 무너뜨림 6")
	_expect(errs, is_equal_approx(HitFeel.shake_px(HitFeel.HIT_DEALT, 6, 6), -HitFeel.shake_px(HitFeel.HIT_DEALT, 5, 6) * 6.0 / 5.0) and HitFeel.shake_px(HitFeel.HIT_DEALT, 0, 6) == 0.0, "떨림은 부호가 뒤집히며 0까지 곧게 준다")

	# 위계와 상한
	var stops := HitFeel.STOP_MSEC
	_expect(errs, stops[HitFeel.HIT_DEALT] == stops[HitFeel.HIT_TAKEN] and stops[HitFeel.HIT_DEALT] > stops[HitFeel.PARRY_OPEN], "유효타 > 패리")
	_expect(errs, stops[HitFeel.PARRY_OPEN] == stops[HitFeel.STAGGER] and stops[HitFeel.STAGGER] > stops[HitFeel.SWEEP_OPEN], "패리 = 무너뜨림 > 열린 끝")
	_expect(errs, HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze2) == stops[HitFeel.SWEEP_OPEN] and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze1) < stops[HitFeel.SWEEP_OPEN] \
			and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, graze1) > 0, "스침 2칸 = 열린 끝 > 스침 1칸 > 0")
	for key: StringName in stops:
		_expect(errs, stops[key] <= 200, "%s 멈칫 200ms 이하" % key)

	# 손으로 만든 이벤트: 열쇠가 빠져도 오류 없이 정한 값
	var handmade_attack := {"type": DuelRecord.ATTACK, "result": Ar.GRAZE, "part": DT.Part.TORSO}
	_expect(errs, HitFeel.moment_of(handmade_attack, null) == HitFeel.GRAZE_DEALT and HitFeel.stop_msec(HitFeel.GRAZE_DEALT, handmade_attack) == 80 \
			and HitFeel.flinch(HitFeel.GRAZE_DEALT, handmade_attack) == Vector2.ZERO, "열쇠 빠진 ATTACK: 1칸 스침, 움찔 0")
	_expect(errs, HitFeel.moment_of({"type": DuelRecord.STRIKE, "braced": false}, plain) == &"", "result 없는 STRIKE는 비움")
	_expect(errs, HitFeel.stop_msec(&"") == 0 and HitFeel.flinch(&"", {}) == Vector2.ZERO, "비운 순간은 0")

	_check_tones(errs)
	return _result(errs)


func _check_tones(errs: Array[String]) -> void:
	var beeper := Beeper.new()
	_tree.root.add_child(beeper)
	_made.append(beeper)
	for key in [&"graze_dealt", &"graze_taken", &"hit_dealt", &"hit_taken", &"parry", &"dodge_open"]:
		_expect(errs, SoundBank.has(key), "새 음 %s가 없다" % key)
	_expect(errs, not SoundBank.has(&"graze") and not SoundBank.has(&"hit"), "옛 graze·hit 키가 남았다")
	# 넣은 쪽과 맞은 쪽의 주파수 견줌은 T217이 맡는다(결정 939).
	for key in [&"hit_dealt", &"hit_taken", &"parry"]:
		var data: PackedByteArray = Beeper.stream_of(key).data
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
	var fresh := _until_dealt(duel, Bot.new(core, Bot.first_blood_cfg()), 4000, true)
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

	# (1b) advance로 직접 걸으면 물리가 켜져 있어도 꺼져 있어도 멈칫도 움찔도 서지 않는다(결정 928)
	for physics in [false, true]:
		var dead := _spawn(1, physics)
		var dead_core: DuelCore = dead.get("core")
		var dead_fresh := _until_dealt(dead, Bot.new(dead_core, Bot.first_blood_cfg()))
		_expect(errs, not dead_fresh.is_empty(), "(1b) advance로 걷는 판(물리 %s)에서 내 공격이 닿는 순간을 못 만났다" % physics)
		_expect(errs, int(dead.get("_stop_ticks_left")) == 0 and (dead.get("_opponent_view") as Object).get("_flinch_vec") == Vector2.ZERO,
				"(1b) advance로 걷는 판(물리 %s)에 멈칫·움찔이 섰다" % physics)

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
	# 막기를 떼는 것은 코어에 들어가되 멈칫은 그대로다(결정 944)
	live_core.set_guard(true)
	live.set("_stop_ticks_left", 3)
	live.call("_unhandled_input", _action(&"guard", false))
	_expect(errs, not live_core.guard_held, "(3) 멈칫 중 막기를 뗀 것이 코어에 들어가지 않았다")
	_expect(errs, int(live.get("_stop_ticks_left")) == 3, "(3) 막기를 뗌이 멈칫을 끝냈다")

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
	view.update_view(live_core, live_core.time + 0.19, 0.0)
	_expect(errs, view.position == view.get("_base_position"), "(5) 코어 0.18초 뒤에 기준으로 돌아오지 않았다")
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

	# (5c) 맞은 쪽의 킥(결정 942): 스친 직후의 뿌리 = 기준 + 킥, 0.19초 뒤 = 기준. 엔진의 걸음 밖(advance)에서는 0이다.
	var from_left := AttackData.new()
	from_left.direction = DT.Direction.LEFT
	for engine in [true, false]:
		var kicker := _spawn()
		var kick_core: DuelCore = kicker.get("core")
		var kick_view: OpponentView = kicker.get("_opponent_view")
		kicker.call("advance", DELTA)
		kick_view.update_view(kick_core, kick_core.time, 0.0)
		var kick_base: Vector2 = kick_view.get("_base_position")
		kicker.set("_engine_tick", engine)
		kicker.call("_on_core_event", _taken_event(kick_core, DT.StrikeResult.GRAZE, from_left))
		kicker.set("_engine_tick", false)
		kick_view.update_view(kick_core, kick_core.time, 0.0)
		var kick_want := kick_base + Vector2(-12.0, 0.0) if engine else kick_base
		_expect(errs, kick_view.position.is_equal_approx(kick_want), "(5c) 맞은 직후 뿌리 %s (기대 %s, 엔진 %s)" % [kick_view.position, kick_want, engine])
		kick_view.update_view(kick_core, kick_core.time + 0.19, 0.0)
		_expect(errs, kick_view.position == kick_view.get("_base_position"), "(5c) 0.18초 뒤에 기준으로 돌아오지 않았다")

	# (5b) 유효타로 끝난 판의 정지 장은 맞은 포즈가 end_floor로 남고, _clock이 거둔다
	_check_final_flinch(errs)

	# (7) 휩쓸기의 끝을 쥐고 막아 열면 70ms, 보통 뿌리의 끝은 0
	var gate := _spawn()
	var sweep_stop := _stop_after_blocked_end(gate, _sweep_root())
	var plain_stop := _stop_after_blocked_end(gate, AttackData.new())
	_expect(errs, sweep_stop == 6, "(7) 휩쓸기 끝의 막기 멈칫 tick %d (기대 6)" % sweep_stop)
	_expect(errs, plain_stop == 0, "(7) 보통 단발의 막기에 멈칫이 섰다 (%d)" % plain_stop)
	_expect(errs, roundi(HitFeel.stop_msec(HitFeel.GRAZE_DEALT, {"cells": 1}) * 60.0 / 1000.0) == 5, "(1) 스침 1칸의 멈칫 tick이 5가 아니다")
	return _result(errs)


## 내가 맞은 STRIKE 이벤트(씬이 받는 열쇠를 다 갖춘다). attack은 타격의 공격이다.
func _taken_event(core: DuelCore, result: int, attack: AttackData) -> Dictionary:
	return _strike(result, -1.0, {
		"t": core.time, "attack": attack, "situation": 0, "recovery_end": core.time + 1.0, "player_posture": 3,
		"posture_loss": 0, "height": -1, "guard_miss": false, "closed_streak": 0, "miss_limit": 0,
	})


## 뿌리를 기억시킨 뒤 끝의 막기 이벤트를 씬이 받게 한다. 돌려줌: 선 멈칫 tick.
func _stop_after_blocked_end(duel: Node, root: AttackData) -> int:
	var core: DuelCore = duel.get("core")
	duel.set("_stop_ticks_left", 0)
	duel.set("_hit_root", root)
	var ev := _strike(DT.StrikeResult.BLOCKED, -1.0, {
		"t": core.time, "attack": root, "situation": 0, "recovery_end": core.time + 1.0, "player_posture": 3,
		"posture_loss": 0, "height": -1, "guard_miss": false, "closed_streak": 0, "miss_limit": 0,
	})
	duel.set("_engine_tick", true)
	duel.call("_on_core_event", ev)
	duel.set("_engine_tick", false)
	return int(duel.get("_stop_ticks_left"))


func _check_final_flinch(errs: Array[String]) -> void:
	for seed_value in range(1, 6):
		var duel := _spawn(seed_value)
		var core: DuelCore = duel.get("core")
		var driver := Bot.new(core, Bot.first_blood_cfg())
		var last_attack := {}
		var seen := 0
		for i in 4000:
			duel.call("_physics_process", DELTA)
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
		_expect(errs, view.position.is_equal_approx(base), "(5b) 유효타로 끝난 판의 정지 장에 평행이동 움찔이 남았다(결정 938)")
		_expect(errs, float(view.get("_hit_w")) >= 0.99, "(5b) 끝낸 한 방의 맞은 포즈가 정지 장에 서 있지 않다 (w %.2f)" % float(view.get("_hit_w")))
		view.update_view(core, core.time, 5.0)
		_expect(errs, is_equal_approx(float(view.get("_hit_w")), 0.6), "(5b) 끝난 판의 맞은 포즈가 _clock으로 거둬지다 end_floor 0.6에서 멈추지 않았다 (w %.2f)" % float(view.get("_hit_w")))
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
		# 기준 10%(계획 H03 결정 944): 멈칫을 늘렸다. 넘으면 열린 패리·무너뜨림을 120으로 내려 다시 잰다 — 기준을 또 올리지 않는다.
		print("  INFO 멈칫 합 %s: %.2f초 / 판 %.1f초 = %.1f%%" % [path.get_file(), total, length, total / maxf(length, 0.001) * 100.0])
		_expect(errs, length > 0.0 and total <= length * 0.10, "%s: 멈칫 합 %.2f초 / 판 %.1f초 (10%% = %.2f)" % [path, total, length, length * 0.10])
	return _result(errs)


# ================================================================ T218

## 상대 그림(Torso·Legs 노드)의 화면 x 변화. 노드의 x는 뿌리 크기로 나눠 넣으므로 곱해 돌려준다.
func _opponent_shake(view: OpponentView, path: NodePath, home: String) -> float:
	return ((view.get_node(path) as Node2D).position.x - float(view.get(home))) * view.scale.x


## 읽기 층(뿌리의 자리, 상태 글자, 귀띔, 고리, 꼬리표)의 전역 자리.
func _layer_points(view: OpponentView) -> Array[Vector2]:
	var points: Array[Vector2] = [view.position]
	for node_name in ["StateLabel", "StateHint", "Ring", "ForecastTag"]:
		points.append((view.get_node(node_name) as Node2D).global_position if view.get_node(node_name) is Node2D else (view.get_node(node_name) as Control).global_position)
	return points


func t218_shake() -> String:
	var errs: Array[String] = []

	# (1) 내가 넣었다: 상대의 Torso·Legs만 멈칫의 tick마다 부호를 뒤집으며 0까지 줄고, 읽기 층과 내 손은 그대로다.
	var duel := _spawn()
	var core: DuelCore = duel.get("core")
	var view: OpponentView = duel.get("_opponent_view")
	var sword: PlayerSwordView = duel.get("_sword_view")
	var fresh := _until_dealt(duel, Bot.new(core, Bot.first_blood_cfg()), 4000, true)
	if fresh.is_empty():
		return "내 공격이 닿는 순간을 못 만났다"
	# 같은 tick의 사건 가운데 가장 긴 멈칫이 떨림의 몫을 정한다(씬이 기억한 순간·이벤트를 읽는다).
	var moment: StringName = duel.get("_shake_moment")
	var ev: Dictionary = duel.get("_shake_ev")
	var total := int(duel.get("_stop_ticks_left"))
	_expect(errs, total >= 3 and int(duel.get("_stop_ticks_total")) == total, "(1) 멈칫 tick %d, 전체 %d" % [total, int(duel.get("_stop_ticks_total"))])
	var layer := _layer_points(view)
	var last := 0.0
	for remaining in range(total, -1, -1):
		if remaining < total:
			duel.call("_physics_process", DELTA)
		_expect(errs, int(duel.get("_stop_ticks_left")) == remaining, "(1) 남은 tick %d (기대 %d)" % [int(duel.get("_stop_ticks_left")), remaining])
		var want := HitFeel.shake_px(moment, remaining, total, ev)
		if remaining == total:
			var table: float = HitFeel.GRAZE_SHAKE_PX[1 if int(ev.get("cells", 1)) >= 2 else 0] if moment == HitFeel.GRAZE_DEALT else HitFeel.SHAKE_PX.get(moment, 0.0)
			_expect(errs, absf(want) >= table * 0.8 and absf(want) <= table, "(1) 첫 떨림 %.2f가 표의 값 %.2f의 80~100%%가 아니다" % [want, table])
		var torso_x := _opponent_shake(view, ^"Torso", "_torso_x0")
		var legs_x := _opponent_shake(view, ^"Legs", "_legs_x0")
		_expect(errs, absf(torso_x - want) <= 0.01 and absf(legs_x - want) <= 0.01, "(1) 남은 %d tick의 떨림 몸통 %.2f 다리 %.2f (기대 %.2f)" % [remaining, torso_x, legs_x, want])
		if remaining > 0:
			_expect(errs, absf(want) > 0.0 and (last == 0.0 or (signf(want) != signf(last) and absf(want) < absf(last))), "(1) 남은 %d tick: 부호가 뒤집히며 줄지 않았다 (%.2f → %.2f)" % [remaining, last, want])
			last = want
		var layer_now := _layer_points(view)
		for i in layer.size():
			_expect(errs, layer[i].distance_to(layer_now[i]) <= 0.01, "(1) 남은 %d tick에 읽기 층 %d이 움직였다" % [remaining, i])
		_expect(errs, float(sword.get("_shake_x")) == 0.0, "(1) 내가 넣었는데 내 손이 떨었다")
	_expect(errs, _opponent_shake(view, ^"Torso", "_torso_x0") == 0.0 and _opponent_shake(view, ^"Legs", "_legs_x0") == 0.0, "(1) 마지막 tick 뒤에 떨림이 남았다")

	# (2) 내가 맞았다: 상대가 아니라 내 손이 떤다.
	var taken := _spawn()
	var taken_core: DuelCore = taken.get("core")
	var taken_view: OpponentView = taken.get("_opponent_view")
	var taken_sword: PlayerSwordView = taken.get("_sword_view")
	taken.call("advance", DELTA)
	var from_left := AttackData.new()
	from_left.direction = DT.Direction.LEFT
	taken.set("_engine_tick", true)
	taken.call("_on_core_event", _taken_event(taken_core, Sr.HIT, from_left))
	taken.set("_engine_tick", false)
	var taken_total := int(taken.get("_stop_ticks_left"))
	_expect(errs, taken_total >= 3, "(2) 맞은 멈칫 tick %d" % taken_total)
	for remaining in range(taken_total, -1, -1):
		if remaining < taken_total:
			taken.call("_physics_process", DELTA)
		var want := HitFeel.shake_px(HitFeel.HIT_TAKEN, remaining, taken_total)
		_expect(errs, absf(float(taken_sword.get("_shake_x")) - want) <= 0.01, "(2) 남은 %d tick의 내 손 떨림 %.2f (기대 %.2f)" % [remaining, float(taken_sword.get("_shake_x")), want])
		_expect(errs, _opponent_shake(taken_view, ^"Torso", "_torso_x0") == 0.0, "(2) 내가 맞았는데 상대가 떨었다")
	_expect(errs, float(taken_sword.get("_shake_x")) == 0.0, "(2) 마지막 tick 뒤에 내 손의 떨림이 남았다")

	# (3) advance로 직접 걸으면 물리가 켜져 있어도 꺼져 있어도 떨림이 없다.
	for physics in [false, true]:
		var dead := _spawn(1, physics)
		var dead_view: OpponentView = dead.get("_opponent_view")
		var dead_fresh := _until_dealt(dead, Bot.new(dead.get("core"), Bot.first_blood_cfg()))
		_expect(errs, not dead_fresh.is_empty() and int(dead.get("_stop_ticks_total")) == 0 and _opponent_shake(dead_view, ^"Torso", "_torso_x0") == 0.0,
				"(3) advance로 걷는 판(물리 %s)에 떨림이 섰다" % physics)

	# (4) pause()·start_duel()이 떨림을 0으로 되돌린다.
	for how in ["pause", "start_duel"]:
		var cut := _spawn()
		var cut_view: OpponentView = cut.get("_opponent_view")
		var cut_fresh := _until_dealt(cut, Bot.new(cut.get("core"), Bot.first_blood_cfg()), 4000, true)
		_expect(errs, not cut_fresh.is_empty() and absf(_opponent_shake(cut_view, ^"Torso", "_torso_x0")) > 0.0, "(4) %s 전에 떨림이 서 있지 않다" % how)
		if how == "pause":
			cut.call("pause", &"esc")
		else:
			cut.call("start_duel")
		_expect(errs, _opponent_shake(cut_view, ^"Torso", "_torso_x0") == 0.0 and _opponent_shake(cut_view, ^"Legs", "_legs_x0") == 0.0 \
				and int(cut.get("_stop_ticks_total")) == 0, "(4) %s가 떨림을 지우지 않았다" % how)
	return _result(errs)


# ================================================================ T219

## 내가 맞은 STRIKE(결정 942). extra로 열쇠를 덮는다.
func _taken_with(core: DuelCore, result: int, attack: AttackData, extra := {}) -> Dictionary:
	var ev := _taken_event(core, result, attack)
	ev.merge(extra, true)
	return ev


func _live_event(duel: Node, ev: Dictionary) -> void:
	duel.set("_engine_tick", true)
	duel.call("_on_core_event", ev)
	duel.set("_engine_tick", false)
	duel.call("_update_views", 0.0)


## 멈칫이 선 채 끝난 판의 첫 시드: _physics_process로 끝 tick까지 걷고 [duel, 끝 tick의 남은 멈칫]을 돌려준다.
func _run_to_end_via_physics() -> Array:
	for seed_value in range(1, 6):
		var duel := _spawn(seed_value)
		var core: DuelCore = duel.get("core")
		var driver := Bot.new(core, Bot.first_blood_cfg())
		for i in 4000:
			duel.call("_physics_process", DELTA)
			if core.ended:
				break
			driver.update()
		if core.ended and core.end_reason != DT.EndReason.TIME_UP and int(duel.get("_stop_ticks_left")) > 0:
			return [duel, int(duel.get("_stop_ticks_left"))]
	return []


func t219_hit_screen() -> String:
	var errs: Array[String] = []

	# (1) 맞음: 킥의 부호·크기, 비네트가 켜지고 맞은 쪽이 더 짙고 색이 선 색이다, 0.35초 뒤 꺼진다.
	var from_left := AttackData.new()
	from_left.direction = DT.Direction.LEFT
	var duel := _spawn()
	var core: DuelCore = duel.get("core")
	var fx: FeelFx = duel.get("_fx")
	var view: OpponentView = duel.get("_opponent_view")
	duel.call("advance", DELTA)
	_live_event(duel, _taken_event(core, Sr.GRAZE, from_left))
	_expect(errs, view.get("_flinch_vec") == Vector2(-12.0, 0.0), "(1) 킥이 (-12, 0)이 아니다: %s" % str(view.get("_flinch_vec")))
	var left := fx.edge_alpha(FeelFx.SIDE_LEFT)
	_expect(errs, left > 0.0 and left > fx.edge_alpha(FeelFx.SIDE_RIGHT) and fx.edge_alpha(FeelFx.SIDE_RIGHT) > 0.0, "(1) 비네트: 왼쪽 %.3f 오른쪽 %.3f" % [left, fx.edge_alpha(FeelFx.SIDE_RIGHT)])
	_expect(errs, FeelFx.VIGNETTE_COLOR == PlayerSwordView.OUTLINE_COLOR, "(1) 비네트의 색이 화풍의 선 색이 아니다")
	fx.update_view(0.2)
	_expect(errs, fx.edge_alpha(FeelFx.SIDE_LEFT) > 0.0, "(1) 0.2초에 비네트가 이미 꺼졌다")
	fx.update_view(0.2)
	_expect(errs, fx.edge_alpha(FeelFx.SIDE_LEFT) == 0.0 and fx.edge_alpha(FeelFx.SIDE_RIGHT) == 0.0, "(1) 0.35초 뒤에 비네트가 남았다")
	# 유효타는 ×1.3
	_live_event(duel, _taken_event(core, Sr.HIT, from_left))
	_expect(errs, fx.edge_alpha(FeelFx.SIDE_LEFT) > left * 1.2, "(1) 유효타의 비네트가 스침의 ×1.3이 아니다")
	# TELL_START가 지운다: 걸음으로 다음 예비 동작까지 걷는다.
	var tells := core.record.of_type(DuelRecord.TELL_START).size()
	for i in 1500:
		duel.call("_physics_process", DELTA)
		if core.record.of_type(DuelRecord.TELL_START).size() > tells or core.ended:
			break
	_expect(errs, core.record.of_type(DuelRecord.TELL_START).size() > tells and fx.edge_alpha(FeelFx.SIDE_LEFT) == 0.0, "(1) TELL_START가 비네트를 지우지 않았다")

	# (2) advance로 직접 걸으면 킥도 비네트도 0
	var dead := _spawn()
	var dead_core: DuelCore = dead.get("core")
	dead.call("advance", DELTA)
	dead.call("_on_core_event", _taken_event(dead_core, Sr.GRAZE, from_left))
	dead.call("_update_views", 0.0)
	_expect(errs, (dead.get("_opponent_view") as Object).get("_flinch_vec") == Vector2.ZERO and (dead.get("_fx") as FeelFx).edge_alpha(FeelFx.SIDE_LEFT) == 0.0, "(2) advance로 걸은 판에 킥·비네트가 섰다")

	# (3) 결과 패널 늦춤: 유효타로 끝난 판은 끝 tick에 안 뜨고 멈칫 + 21번 뒤에 뜬다
	var run := _run_to_end_via_physics()
	if run.is_empty():
		errs.append("(3) 다섯 시드 안에 멈칫이 선 채 끝난 판이 없다")
	else:
		var ended_duel: Node = run[0]
		var stop0: int = run[1]
		var panel: ResultPanel = ended_duel.get("_result_panel")
		_expect(errs, not panel.is_showing(), "(3) 끝난 tick에 패널이 떠 있다")
		# 늦춤 동안 Space·Enter는 판을 넘기지 않고 R은 판을 갈지 않는다
		var kept_core: DuelCore = ended_duel.get("core")
		ended_duel.call("_unhandled_input", _action(&"retry"))
		_expect(errs, ended_duel.get("core") == kept_core and not panel.is_showing(), "(3) 늦춤 동안 R이 판을 갈았다")
		ended_duel.set("_day_mode", true)
		ended_duel.call("_unhandled_input", _action(&"ui_accept"))
		ended_duel.set("_day_mode", false)
		_expect(errs, not bool(ended_duel.get("_day_reported")) and not panel.is_showing(), "(3) 늦춤 동안 ui_accept가 판을 넘겼다")
		var calls := 0
		while not panel.is_showing() and calls < 200:
			ended_duel.call("_physics_process", DELTA)
			calls += 1
		_expect(errs, calls == stop0 + 21, "(3) 패널이 %d번 뒤에 떴다 (기대 멈칫 %d + 21)" % [calls, stop0])
		# start_duel이 늦춤을 지운다
		ended_duel.call("start_duel")
		_expect(errs, int(ended_duel.get("_result_delay_ticks")) == 0 and not bool(ended_duel.get("_result_late")) and not panel.is_showing(), "(3) start_duel이 늦춤을 지우지 않았다")

	# (4) 손으로 세운 끝 tick(대련의 마지막 무너뜨림 — 멈칫 8): 안 뜨고 8 + 21번 뒤에 뜬다. 시간 초과는 곧바로, advance로 끝내면 같은 advance에 뜬다
	var spar := _spawn()
	var spar_core: DuelCore = spar.get("core")
	var spar_panel: ResultPanel = spar.get("_result_panel")
	spar_core.ended = true
	spar_core.end_reason = DT.EndReason.CONDITION
	spar.set("_stop_ticks_left", 8)
	spar.set("_engine_tick", true)
	spar.call("advance", DELTA)
	spar.set("_engine_tick", false)
	_expect(errs, not spar_panel.is_showing(), "(4) 대련의 끝 tick에 패널이 떠 있다")
	var spar_calls := 0
	while not spar_panel.is_showing() and spar_calls < 200:
		spar.call("_physics_process", DELTA)
		spar_calls += 1
	_expect(errs, spar_calls == 8 + 21, "(4) 대련의 패널이 %d번 뒤에 떴다 (기대 8 + 21)" % spar_calls)
	for mode in ["time_up", "direct"]:
		var quick := _spawn()
		var quick_core: DuelCore = quick.get("core")
		quick_core.ended = true
		quick_core.end_reason = DT.EndReason.TIME_UP
		quick.set("_stop_ticks_left", 0 if mode == "time_up" else 8)
		quick.set("_engine_tick", mode == "time_up")
		quick.call("advance", DELTA)
		quick.set("_engine_tick", false)
		_expect(errs, (quick.get("_result_panel") as ResultPanel).is_showing(), "(4) %s의 끝이 같은 advance에 뜨지 않았다" % mode)
	return _result(errs)


# ================================================================ T220

func _line_kinds(fx: FeelFx) -> Dictionary:
	var kinds := {}
	for line in fx.live_lines():
		kinds[line["kind"]] = int(kinds.get(line["kind"], 0)) + 1
	return kinds


func t220_small_things() -> String:
	var errs: Array[String] = []
	var atk := AttackData.new()

	# (1) 자세 칸의 번쩍임: 잃은 칸이 번쩍임 색으로 서고, 코어 0.25초 뒤 빈 칸이고, 끝난 판에서는 없다
	var duel := _spawn()
	var core: DuelCore = duel.get("core")
	var hud: DuelHud = duel.get("_hud")
	var mine: DuelHud.PostureCells = hud.get("_player_cells")
	var theirs: DuelHud.PostureCells = hud.get("_opponent_cells")
	duel.call("advance", DELTA)
	_live_event(duel, _taken_with(core, Sr.GRAZE, atk, {"posture_loss": 1, "player_posture": 2}))
	_expect(errs, mine.flash_k >= 0.0 and mine.flash_k < 0.05 and mine.flash_from == 2 and mine.flash_to == 3, "(1) 내 칸의 번쩍임: k %.2f [%d, %d)" % [mine.flash_k, mine.flash_from, mine.flash_to])
	_expect(errs, DuelHud.FLASH_COLOR == Color(1.0, 0.96, 0.84) and DuelHud.FLASH_COLOR == FeelFx.IVORY, "(1) 번쩍임 색이 상아색이 아니다")
	_live_event(duel, _taken_with(core, Sr.GRAZE, atk, {"posture_loss": 1, "player_posture": 2, "t": core.time - 0.3}))
	_expect(errs, mine.flash_k < 0.0, "(1) 0.25초가 지난 번쩍임이 남았다")
	hud.on_event({"type": DuelRecord.ATTACK, "result": Ar.GRAZE, "opponent_posture": 1, "cells": 2, "t": core.time, "part": DT.Part.TORSO,
			"direction": 1, "height": 1, "distance": 1, "rash": false, "dodged": false, "lunge": false, "posture_gain": 0, "pressed_distance": 1, "opponent_state": 0})
	duel.call("_update_views", 0.0)
	_expect(errs, theirs.flash_k >= 0.0 and theirs.flash_from == 1 and theirs.flash_to == 3, "(1) 상대 칸의 번쩍임 [%d, %d) k %.2f" % [theirs.flash_from, theirs.flash_to, theirs.flash_k])
	core.ended = true
	duel.call("_update_views", 0.0)
	_expect(errs, mine.flash_k < 0.0 and theirs.flash_k < 0.0, "(1) 끝난 판에 번쩍임이 남았다")

	# (2) 불꽃: 패리 8 · 쥐고 막음 4 · 안 열린 패리와 속은 패리와 버티기도 쥐고 막음의 4 · 내 공격의 닿음 5(유효타 8) · 막힘 2
	var live := _spawn()
	var live_core: DuelCore = live.get("core")
	var fx: FeelFx = live.get("_fx")
	var sword: PlayerSwordView = live.get("_sword_view")
	live.call("advance", DELTA)
	var cases := [
		["열린 패리", Sr.PARRIED, {}, {&"burst": 8}],
		["막기", Sr.BLOCKED, {}, {&"tick": 4}],
		["안 열린 패리", Sr.PARRIED, {"closed": true}, {&"tick": 4}],
		["속은 패리", Sr.PARRIED, {"bitten": true}, {&"tick": 4}],
		["버티기", Sr.PARRIED, {"braced": true}, {&"tick": 4}],
	]
	for item: Array in cases:
		fx.clear()
		_live_event(live, _taken_with(live_core, item[1], atk, item[2]))
		_expect(errs, _line_kinds(fx) == item[3], "(2) %s의 불꽃 %s (기대 %s)" % [item[0], str(_line_kinds(fx)), str(item[3])])
	fx.clear()
	fx.on_event(_attack(Ar.GRAZE), sword)
	fx.update_view(0.0)
	var graze_lines := fx.live_lines()
	_expect(errs, _line_kinds(fx) == {&"fan": 5}, "(2) 스침의 닿은 표시 %s" % str(_line_kinds(fx)))
	var fan_from: Vector2 = fx.contact
	for line in graze_lines:
		_expect(errs, ((line["to"] as Vector2) - fx.contact).dot(fx.path_dir) > 0.0, "(2) 닿은 표시의 줄이 온 길의 앞쪽 반평면에 없다")
	fx.clear()
	fx.on_event(_attack(Ar.HIT), sword)
	fx.update_view(0.0)
	_expect(errs, _line_kinds(fx) == {&"fan": 8}, "(2) 유효타의 닿은 표시 %s" % str(_line_kinds(fx)))
	fx.clear()
	fx.on_event(_attack(Ar.BLOCKED), sword)
	fx.update_view(0.0)
	_expect(errs, _line_kinds(fx) == {&"kink": 2}, "(2) 막힘의 꺾쇠 %s" % str(_line_kinds(fx)))
	for line in fx.live_lines():
		_expect(errs, ((line["to"] as Vector2) - fx.contact).dot(fx.path_dir) < 0.0, "(2) 막힘의 줄이 뒤쪽 반평면에 없다")
		_expect(errs, (line["from"] as Vector2).distance_to(fan_from) >= 20.0, "(2) 막힘의 시작점이 닿음의 시작점에서 20px 안이다")
	# 0.12초 뒤 0줄, 층의 차례
	fx.update_view(0.13)
	_expect(errs, fx.live_lines().is_empty(), "(2) 0.12초 뒤에 불꽃이 남았다")
	var ring := (live.get("_opponent_view") as Node).get_node(^"Ring") as CanvasItem
	var label := (live.get("_opponent_view") as Node).get_node(^"StateLabel") as CanvasItem
	_expect(errs, fx.z_index == 8 and fx.z_index < ring.z_index and fx.z_index < label.z_index, "(2) FeelFx의 z가 고리·상태 글자보다 아래가 아니다")
	# advance로 직접 걸으면 0줄
	var dead := _spawn()
	var dead_fx: FeelFx = dead.get("_fx")
	dead.call("advance", DELTA)
	dead.call("_on_core_event", _taken_event(dead.get("core"), Sr.PARRIED, atk))
	dead.call("_update_views", 0.0)
	_expect(errs, dead_fx.live_lines().is_empty(), "(2) advance로 걸은 판에 불꽃이 섰다")

	# (3) 상아색은 뜻이 있는 색·기본 색·고유 검술의 색에서 T114의 잣대로 떨어져 있다(닿음 흰색은 같은 계열이라 일부러 뺀다 — 결정 945)
	var style: RefCounted = StyleScript.new()
	var ivory := FeelFx.IVORY
	var meaning: Array = []
	for pair: Array in style.call("_state_colors") + style.call("_green_colors"):
		if pair[1] != OpponentView.COLOR_TOUCHED:
			meaning.append(pair)
	for pair: Array in meaning:
		var dist: float = style.call("_rgb_dist", ivory, pair[1])
		_expect(errs, dist >= 0.35, "(3) 상아색이 %s와 %.3f (0.35 이상)" % [pair[0], dist])
	for other: Color in style.call("_base_colors"):
		_expect(errs, float(style.call("_rgb_dist", ivory, other)) >= 0.35, "(3) 상아색이 기본 색 %s와 가깝다" % str(other))
	for pair: Array in [["빈틈 파랑", OpponentView.COLOR_RECOVERY], ["타격 빨강", OpponentView.COLOR_STRIKE]] + style.call("_green_colors"):
		_expect(errs, float(style.call("_hue_gap", ivory, pair[1])) >= 0.06, "(3) 상아색의 색상이 %s와 가깝다" % pair[0])
	for path: String in StyleScript.OPPONENT_PATHS:
		var opp := load(path) as OpponentData
		for list: Array in style.call("_tier_lists", opp):
			for root: AttackData in list:
				for route: AttackData in style.call("_routes", root):
					for strike: AttackData in style.call("_strike_list", route):
						if float(style.call("_rgb_dist", ivory, strike.pose_color)) < 0.35:
							errs.append("(3) %s '%s'의 색 %s가 상아색과 0.35 안이다" % [opp.display_name, strike.attack_name, str(strike.pose_color)])
	return _result(errs)
