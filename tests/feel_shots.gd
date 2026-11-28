extends Node
## 타격감 찍기(계획 H03 작업 1-아). 물리를 끄고 advance로 걸으며 내 공격의 순간을 찍는다. 묶음: A 내 공격의 걸음, B 9칸의 접촉, C 결과별·못 미침.
## 실행: tests/run_feel_shots.ps1 -Group A,B,C -Shots <폴더>. 폴더가 없거나 헤드리스면 그림은 저장하지 않고 수만 잰다.
## 장마다 "feel,<이름>,<수...>,PASS|FAIL" 한 줄. 마지막 줄은 "FEEL SHOTS OK <장 수>" 또는 "FEEL SHOTS FAIL ...".

const DT := preload("res://scripts/duel/duel_types.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const States := preload("res://tests/opponent_states.gd")
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const DELTA := 1.0 / 60.0
const SETTLE_MSEC := 150
const SCREEN := Vector2(1280, 720)
const DIR_NAMES: Array[String] = ["left", "centre", "right"]
const HEIGHT_NAMES: Array[String] = ["high", "mid", "low"]
const DIST_NAMES: Array[String] = ["far", "engage", "close"]

var _shots_dir := ""
var _groups: Array[String] = []
var _plan: Array = []
var _i := -1
var _node: Node
var _since := 0
var _frames := 0
var _shot_count := 0
var _failed := 0


func _ready() -> void:
	var run_settings := get_node_or_null(^"/root/Settings")
	if run_settings != null and run_settings.has_method("detach_for_run"):
		run_settings.call("detach_for_run")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
		elif arg.begins_with("--group="):
			for g in arg.trim_prefix("--group=").split(","):
				_groups.append(g.strip_edges().to_upper())
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	_build_plan()
	_next()


func _want(group: String) -> bool:
	return _groups.is_empty() or _groups.has(group)


func _item(group: String, shot_name: String, distance: int, direction: int, height: int, at: String, lunge := false, recovery := false) -> Dictionary:
	return {"group": group, "name": shot_name, "dist": distance, "dir": direction, "h": height, "at": at, "lunge": lunge, "recovery": recovery}


func _build_plan() -> void:
	var engage := DT.Distance.ENGAGE
	var close := DT.Distance.CLOSE
	var far := DT.Distance.FAR
	if _want("A"):
		var steps := ["press", "t2", "lift", "pre3", "hit", "p3", "p8", "end"]
		for combo: Array in [["thrust-mid", 1, 1], ["cut-left-mid", 0, 1], ["cut-left-high", 0, 0]]:
			for step: String in steps:
				_plan.append(_item("A", "A-%s-%s" % [combo[0], step], engage, combo[1], combo[2], step))
		_plan.append(_item("A", "A-close-cut-left-mid-liftend", close, 0, 1, "liftend"))
	if _want("B"):
		for distance in [engage, close]:
			for d in 3:
				for h in 3:
					_plan.append(_item("B", "B-%s-%s-%s" % [DIST_NAMES[distance], DIR_NAMES[d], HEIGHT_NAMES[h]], distance, d, h, "hit"))
		for h in 3:
			_plan.append(_item("B", "B-lunge-%s" % HEIGHT_NAMES[h], far, 1, h, "hit", true))
	if _want("C"):
		_plan.append(_item("C", "C-touch", engage, 1, 1, "p4", false, true))
		_plan.append(_item("C", "C-bounce", engage, 1, 1, "p4"))
		# 송곳에 걸림은 막힘과 같은 그림이다(결정 932의 튕김). 이름만 따로 두고 같은 길로 찍는다.
		_plan.append(_item("C", "C-spike", engage, 1, 1, "p4"))
		_plan.append(_item("C", "C-dodge", engage, 1, 0, "p4", false, true))
		for d in 3:
			for h in 3:
				_plan.append(_item("C", "C-short-%s-%s" % [DIR_NAMES[d], HEIGHT_NAMES[h]], far, d, h, "hit"))
		for h in 3:
			_plan.append(_item("C", "C-lunge-%s" % HEIGHT_NAMES[h], far, 1, h, "hit", true))


func _next() -> void:
	if _node != null:
		_node.free()
		_node = null
	_i += 1
	if _i >= _plan.size():
		if _failed == 0:
			print("FEEL SHOTS OK %d" % _shot_count)
		else:
			print("FEEL SHOTS FAIL %d of %d" % [_failed, _shot_count])
		set_process(false)
		get_tree().quit(0 if _failed == 0 else 1)
		return
	_pose(_plan[_i])
	_since = Time.get_ticks_msec()
	_frames = 0


func _pose(item: Dictionary) -> void:
	var opponent := Plain.of(load(OPPONENT_PATH) as OpponentData)
	_node = (load(DUEL_PATH) as PackedScene).instantiate()
	_node.set("practice_opponent", opponent)
	_node.set("mouse_aim_enabled", false)
	_node.set("rng_seed", 1)
	add_child(_node)
	_node.set_process(false)
	_node.set_physics_process(false)
	var core: DuelCore = _node.get("core")
	var atk: AttackData = core.opponent_data.attacks[0] if item["recovery"] else null
	var state: int = DT.OpponentState.IDLE
	if item["recovery"]:
		state = DT.OpponentState.RECOVERY
	elif item["lunge"]:
		state = States.COMPLACENT
	States.put(core, state, atk, 0.0, item["dist"])
	if item["recovery"]:
		core.brain.state_end = core.time + 5.0
	core.set("_approach_at", INF)
	var opp := _node.get("_opponent_view") as OpponentView
	var sword := _node.get("_sword_view") as PlayerSwordView
	opp.setup(core.opponent_data, core.weapon, core.opponent_has_hat)
	sword.setup()
	_node.set("_display_time", core.time)
	_node.call("_update_views", 0.0)
	core.set_aim(item["dir"], item["h"])
	var rest := sword.tip_global()
	core.press_attack()
	_node.call("_update_views", 0.0)
	var windup := core.player_state_end - core.player_state_start
	var judge_tick := int(ceil(windup / DELTA - 0.001))
	var strike := minf(PlayerSwordView.STRIKE_TIME, 0.45 * windup)
	var at: String = item["at"]
	var tick := 0
	var judged := -1
	var before := core.record.of_type(DuelRecord.ATTACK).size()
	while tick < 240:
		if _matches(at, tick, judged, windup, strike, judge_tick, core):
			break
		_node.call("advance", DELTA)
		tick += 1
		if judged < 0 and core.record.of_type(DuelRecord.ATTACK).size() > before:
			judged = tick
	item["m"] = _measure(sword, rest, judged)


func _matches(at: String, tick: int, judged: int, windup: float, strike: float, judge_tick: int, core: DuelCore) -> bool:
	match at:
		"press":
			return tick == 0
		"t2":
			return tick == 2
		"lift":
			return tick == int(round(windup * 0.5 / DELTA))
		"liftend":
			return tick == int(floor((windup - strike) / DELTA))
		"pre3":
			return tick == maxi(judge_tick - 3, 1)
		"hit":
			return judged >= 0
		"p3":
			return judged >= 0 and tick == judged + 3
		"p4":
			return judged >= 0 and tick == judged + 4
		"p8":
			return judged >= 0 and tick == judged + 8
		"end":
			return judged >= 0 and core.player_state == DT.PlayerState.READY
	return true


func _measure(sword: PlayerSwordView, rest: Vector2, judged: int) -> Dictionary:
	var blade := sword.get_node("Sword") as Polygon2D
	var tip := sword.tip_global()
	var plan: Dictionary = sword.get("_hold_plan")
	var m := {"move": tip.distance_to(rest), "kink": rad_to_deg(absf(blade.rotation)), "scale": blade.scale.y,
			"sleeve": sword.sleeve_top_at(sword.position, sword.rotation), "onscreen": Rect2(Vector2.ZERO, SCREEN).has_point(tip),
			"dist": -1.0, "from_contact": -1.0, "short": false, "judged": judged}
	if not plan.is_empty():
		m["dist"] = tip.distance_to(plan["target"])
		m["from_contact"] = tip.distance_to(plan["contact"])
		m["short"] = plan["short"]
	return m


## T213과 같은 울타리: 판정 뒤 첫 장의 칼끝–목표 ≤ 6px(닿지 않는 거리는 접촉점에서 ≥ 60px), 누른 뒤 2 tick에 ≥ 8px 이동, 판정 3 tick 앞은 목표에서 ≥ 40px. 꺾임·scale.y는 수만 찍는다.
func _verdict(item: Dictionary) -> bool:
	var m: Dictionary = item["m"]
	var ok: bool = m["onscreen"]
	var at: String = item["at"]
	if at == "hit" and m["dist"] >= 0.0:
		ok = ok and m["dist"] <= 6.0
		if m["short"]:
			ok = ok and m["from_contact"] >= 60.0
	elif at == "t2":
		ok = ok and m["move"] >= 8.0
	elif at == "pre3" and m["dist"] >= 0.0:
		ok = ok and m["dist"] >= 40.0
	return ok


func _process(_delta: float) -> void:
	if _node == null:
		return
	_frames += 1
	if _frames < 3 or (_shots_dir != "" and Time.get_ticks_msec() - _since < SETTLE_MSEC):
		return
	var item: Dictionary = _plan[_i]
	var m: Dictionary = item["m"]
	if _shots_dir != "":
		var image := get_viewport().get_texture().get_image()
		if image != null and not image.is_empty():
			image.save_png(_shots_dir.path_join(String(item["name"]) + ".png"))
	var ok := _verdict(item)
	if not ok:
		_failed += 1
	_shot_count += 1
	print("feel,%s,dist=%.1f,move=%.1f,kink=%.1f,scale=%.2f,sleeve=%.1f,%s" % [item["name"], m["dist"], m["move"], m["kink"], m["scale"], m["sleeve"], "PASS" if ok else "FAIL"])
	_next()
