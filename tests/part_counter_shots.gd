extends Node
## 부위별 반격 재현 찍기(계획 R02 작업 7): 바르톨로의 왼쪽 베기 한 번을 막은 뒤 다섯 장면을 실제 코어로 놓는다.
## 실행: tests/run_part_counter_shots.ps1 (-Shots <폴더>면 창을 열어 PNG도 남긴다). 장면마다 "누르기 직전"과 "판정 직후" 두 장.
## 줄: "counter,<장면>,<누른 때>,<미리보기>,<판정>[,FAIL]"(미리보기와 판정이 기대와 다르면 FAIL), "overlap,<장>,<꼬리표|효과 글>,<노드>,<넓이>".
## "counter,flicker,..."는 멀리·대기에서 미리보기가 멀다와 알 수 없음 사이를 오간 횟수다(알릴 뿐 판정하지 않는다).

const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Bot := preload("res://tests/duel_bots.gd")

const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const EFFECTS_PATH := "res://data/part_effects.tres"
const ATTACK_NAME := "왼쪽 베기"
const DELTA := 1.0 / 60.0
const SETTLE := 1e-9
const PRESS_EPS := 1e-7
const GIVE_UP := 12.0
const SETTLE_MSEC := 250
const FLICKER_SEEDS := 5
const FLICKER_LIMIT := 40.0

## 계획 7절의 표: 막은 타격 뒤 d초에 조준 부위를 눌렀을 때의 미리보기와 판정.
const SCENES := [
	{"name": "body", "d": 0.15, "part": DT.Part.TORSO, "preview": "닿는다", "outcome": "스침 — 몸통"},
	{"name": "arm", "d": 0.15, "part": DT.Part.SWORD_ARM, "preview": "닿는다", "outcome": "스침 — 칼 든 팔 (-2) · 팔 둔함 3"},
	{"name": "late-arm", "d": 0.25, "part": DT.Part.SWORD_ARM, "preview": "늦다", "outcome": "닿지 않음"},
	{"name": "late-body", "d": 0.25, "part": DT.Part.TORSO, "preview": "닿는다", "outcome": "스침 — 몸통"},
	{"name": "too-late", "d": 0.40, "part": DT.Part.TORSO, "preview": "늦다", "outcome": "닿지 않음"},
]

var _shots_dir := ""
var _plan: Array = []
var _i := -1
var _node: Node
var _since := 0
var _frames := 0
var _shot_count := 0
var _failures := 0


func _ready() -> void:
	# 결투가 InputMap을 읽으므로 플레이어의 바꾼 키가 장에 비치지 않게 처음 값으로 돌린다(계획 S03 결정 523).
	var run_settings := get_node_or_null(^"/root/Settings")
	if run_settings != null and run_settings.has_method("detach_for_run"):
		run_settings.call("detach_for_run")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	_flicker()
	for s in SCENES.size():
		for phase in ["before", "after"]:
			_plan.append({"name": "%s-%s" % [SCENES[s]["name"], phase], "scene": s, "phase": phase})
	# 효과 글의 가장 긴 꼴(팔 둔함과 다리 흔들림 두 줄)을 재는 덤 장. 열 장의 수에는 넣지 않는다.
	_plan.append({"name": "effects-both", "scene": 1, "phase": "both"})
	_next()


func _next() -> void:
	if _node != null:
		_node.free()
		_node = null
	_i += 1
	if _i >= _plan.size():
		if _failures > 0:
			print("PART COUNTER SHOTS FAIL %d" % _failures)
		else:
			print("PART COUNTER SHOTS OK %d" % _shot_count)
		set_process(false)
		get_tree().quit(1 if _failures > 0 else 0)
		return
	_pose(_plan[_i])
	_since = Time.get_ticks_msec()
	_frames = 0


func _process(_delta: float) -> void:
	if _node == null:
		return
	_frames += 1
	if _frames >= 3 and Time.get_ticks_msec() - _since >= SETTLE_MSEC:
		var shot_name: String = _plan[_i]["name"]
		# 화면이 자리를 잡은 뒤 한 번 더 그려 꼬리표·글의 크기가 맞게 잰다.
		_node.call("_update_views", 0.0)
		_report_overlaps(shot_name)
		if _shots_dir != "":
			get_viewport().get_texture().get_image().save_png(_shots_dir.path_join(shot_name + ".png"))
		if _plan[_i]["phase"] != "both":
			_shot_count += 1
		_next()


## 멀리·대기에서 프레임마다 미리보기를 훑는다: 멀다와 알 수 없음이 바뀐 횟수와 알 수 없음이 이어진 가장 긴 초.
func _flicker() -> void:
	var changes := 0
	var longest := 0.0
	var scanned := 0.0
	var fx := load(EFFECTS_PATH) as PartEffectData
	for seed_value in range(1, FLICKER_SEEDS + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
		weapon.close_bind_time = 0.0
		var core := DuelCore.new()
		var none: Array[CommissionCondition] = []
		core.setup(load(RULES_PATH), weapon, (load(OPPONENT_PATH) as OpponentData).with_part_effects(fx), rng, none, false)
		while core.distance != DT.Distance.FAR and not core.ended and core.time < 10.0:
			core.tick(DELTA)
			if core.player_state == DT.PlayerState.READY:
				core.step(-1)
		var previous := -1
		var run_start := -1.0
		var started := core.time
		while core.distance == DT.Distance.FAR and not core.ended and core.time < FLICKER_LIMIT:
			core.tick(DELTA)
			if core.brain.state != DT.OpponentState.IDLE or core.player_state != DT.PlayerState.READY:
				continue
			var verdict: int = core.attack_forecast()["verdict"]
			if verdict == DT.Forecast.UNSURE and run_start < 0.0:
				run_start = core.time
			elif verdict != DT.Forecast.UNSURE and run_start >= 0.0:
				longest = maxf(longest, core.time - run_start)
				run_start = -1.0
			if previous >= 0 and verdict != previous \
					and (verdict == DT.Forecast.UNSURE or verdict == DT.Forecast.OUT_OF_RANGE) \
					and (previous == DT.Forecast.UNSURE or previous == DT.Forecast.OUT_OF_RANGE):
				changes += 1
			previous = verdict
		if run_start >= 0.0:
			longest = maxf(longest, core.time - run_start)
		scanned += core.time - started
	print("counter,flicker,씨앗 %d,바뀐 횟수 %d,알 수 없음 가장 긴 %.2f초,훑은 %.1f초" % [FLICKER_SEEDS, changes, longest, scanned])


## 바르톨로의 왼쪽 베기만 내는 새 규칙의 판을 열고 막은 타격 뒤 d초까지 코어를 돌린다. "after"는 눌러서 판정까지 간다.
func _pose(item: Dictionary) -> void:
	var scene: Dictionary = SCENES[item["scene"]]
	var opponent := load(OPPONENT_PATH) as OpponentData
	var atk: AttackData
	for candidate in opponent.attacks:
		if candidate.attack_name == ATTACK_NAME:
			atk = candidate
	var solo := atk.duplicate() as AttackData
	var no_variants: Array[Resource] = []
	solo.variants = no_variants
	var drilled := opponent.drill(solo).with_part_effects(load(EFFECTS_PATH) as PartEffectData)
	drilled.opening_chance = 1.0
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	_node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	_node.set("practice_opponent", drilled)
	_node.set("test_weapon", weapon)
	_node.set("mouse_aim_enabled", false)
	_node.set("rng_seed", 1)
	add_child(_node)
	_node.set_process(false)
	_node.set_physics_process(false)
	var core: DuelCore = _node.get("core")
	var seen := {"tell_end": -1.0, "struck": false, "strike_t": 0.0, "result": -1, "attack": null}
	core.event.connect(func(ev: Dictionary) -> void: _note(ev, seen))
	var guard := func(_atk: AttackData, _index: int) -> StringName:
		return &"hold"
	var bot := Bot.new(core, {"guard_fn": guard, "want_distance": DT.Distance.ENGAGE})
	while not bool(seen["struck"]) and not core.ended and core.time < GIVE_UP:
		var step := DELTA
		var tell_end := float(seen["tell_end"])
		if tell_end > core.time and tell_end - core.time < DELTA:
			step = tell_end - core.time + SETTLE
		core.tick(step)
		bot.update()
	if not bool(seen["struck"]) or int(seen["result"]) != DT.StrikeResult.BLOCKED:
		_fail(scene, item, "타격을 막지 못함")
		return
	var press_at := float(seen["strike_t"]) + float(scene["d"]) + PRESS_EPS
	if press_at > core.time:
		core.tick(press_at - core.time)
	var aim := _aim_for(core, int(scene["part"]))
	core.set_aim(aim[0], aim[1])
	var forecast := core.attack_forecast()
	_node.set("_display_time", core.time)
	_node.call("_update_views", 0.0)
	var tag := _tag()
	var word: String = DuelHud.FORECAST_WORD.get(forecast["verdict"], "")
	var tag_text := tag.text if tag.visible else ""
	if word != scene["preview"] or tag_text != scene["preview"]:
		_fail(scene, item, "미리보기 %s · 꼬리표 %s" % [word, tag_text])
		return
	if item["phase"] == "before":
		return
	core.press_attack()
	if core.player_state != DT.PlayerState.WINDUP:
		_fail(scene, item, "공격이 나가지 않음")
		return
	var until := core.time + GIVE_UP
	while seen["attack"] == null and not core.ended and core.time < until:
		core.tick(DELTA)
	var ev: Variant = seen["attack"]
	if ev == null:
		_fail(scene, item, "판정이 나오지 않음")
		return
	var outcome := _outcome(ev)
	_node.set("_display_time", core.time)
	if item["phase"] == "both":
		core.brain.parry_charges = 1
	_node.call("_update_views", 0.0)
	if item["phase"] == "after":
		var verdict_ok: bool = outcome == scene["outcome"]
		print("counter,%s,+%.2f,%s,%s%s" % [scene["name"], float(scene["d"]), word, outcome, "" if verdict_ok else ",FAIL"])
		if not verdict_ok:
			_failures += 1


func _fail(scene: Dictionary, item: Dictionary, why: String) -> void:
	print("counter,%s,+%.2f,%s,FAIL,%s" % [scene["name"], float(scene["d"]), item["phase"], why])
	_failures += 1


func _outcome(ev: Dictionary) -> String:
	var part_name: String = DT.PART_NAMES[int(ev["part"])]
	if bool(ev["dodged"]):
		return "피함"
	match int(ev["result"]):
		DT.AttackResult.GRAZE:
			var text := "스침 — %s" % part_name
			if int(ev["cells"]) >= 2:
				text += " (-%d)" % int(ev["cells"])
			if ev.has("effect") and int(ev["slow_left"]) > 0:
				text += " · 팔 둔함 %d" % int(ev["slow_left"])
			return text
		DT.AttackResult.HIT:
			return "유효타 — %s" % part_name
		DT.AttackResult.BLOCKED:
			return "닿지 않음"
	return "헛침"


func _aim_for(core: DuelCore, part: int) -> Array:
	# 몸통은 가운데 찌르기를 먼저 고른다(반대쪽 베기보다 예비가 짧은 쪽).
	for direction in [DT.Direction.CENTER, DT.Direction.LEFT, DT.Direction.RIGHT]:
		if DuelCore.aim_part(direction, DT.Height.MID, core.opponent_data.sword_side, core.opponent_has_hat) == part:
			return [direction, DT.Height.MID]
	return [DT.Direction.CENTER, DT.Height.MID]


func _tag() -> Label:
	return _node.get_node("OpponentView/ForecastTag") as Label


func _note(ev: Dictionary, seen: Dictionary) -> void:
	match ev["type"]:
		DuelRecord.TELL_START, DuelRecord.PATTERN_STEP:
			seen["tell_end"] = float(ev["strike_time"])
		DuelRecord.STRIKE:
			if float(ev["next_strike"]) < 0.0:
				seen["struck"] = true
				seen["strike_t"] = float(ev["t"])
				seen["result"] = int(ev["result"])
		DuelRecord.ATTACK:
			seen["attack"] = ev


## 조준 꼬리표(와 여유 막대)와 오른쪽 위의 효과 글이 HUD 판·글자·상태 글자와 겹치는 넓이, 그리고 화면 밖의 넓이.
func _report_overlaps(shot: String) -> void:
	var view_rect := get_viewport().get_visible_rect()
	var panels: Array = []
	var texts: Array = []
	_collect(_node.get_node("HUD"), panels, texts)
	var state := _node.get_node("OpponentView/StateLabel") as Label
	if state.visible and state.text != "":
		texts.append(["StateLabel", _text_rect(state)])
	var tag := _tag()
	var tag_boxes: Array = []
	if tag.visible:
		tag_boxes.append(["ForecastTag", tag.get_global_transform() * Rect2(Vector2.ZERO, tag.size)])
		var bar := tag.get_child(0) as Control
		if bar.visible:
			tag_boxes.append(["ForecastBar", bar.get_global_transform() * Rect2(Vector2.ZERO, bar.size)])
	var effect := _node.get_node("HUD").find_child("EffectLabel", true, false) as Label
	var effect_boxes: Array = []
	if effect != null and effect.is_visible_in_tree() and effect.text != "":
		effect_boxes.append(["EffectLabel", _text_rect(effect)])
	var tag_rect_texts := texts.duplicate()
	for box: Array in effect_boxes:
		_overlap_lines(shot, "효과 글", box, panels, texts.filter(func(t: Array) -> bool: return t[0] != "EffectLabel"), view_rect)
		for tag_box: Array in tag_boxes:
			var cut: Rect2 = (box[1] as Rect2).intersection(tag_box[1])
			if cut.get_area() >= 1.0:
				print("overlap,%s,효과 글,%s,%d" % [shot, tag_box[0], roundi(cut.get_area())])
	for box: Array in tag_boxes:
		_overlap_lines(shot, "꼬리표", box, panels, tag_rect_texts, view_rect)


func _overlap_lines(shot: String, kind: String, box: Array, panels: Array, texts: Array, view_rect: Rect2) -> void:
	var rect: Rect2 = box[1]
	var outside := rect.get_area() - rect.intersection(view_rect).get_area()
	if outside >= 1.0:
		print("overlap,%s,%s,화면 밖,%d" % [shot, kind, roundi(outside)])
	for entry: Array in panels + texts:
		var cut := rect.intersection(entry[1])
		if cut.get_area() >= 1.0:
			print("overlap,%s,%s,%s,%d" % [shot, kind, entry[0], roundi(cut.get_area())])


## 글이 실제로 차지하는 네모: 라벨의 칸 안에서 정렬대로 글의 너비만큼만 잡는다.
func _text_rect(label: Label) -> Rect2:
	var rect := label.get_global_transform() * Rect2(Vector2.ZERO, label.size)
	var need := label.get_minimum_size()
	var width := minf(rect.size.x, need.x * label.get_global_transform().get_scale().x)
	var height := need.y * label.get_global_transform().get_scale().y
	var x := rect.position.x
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = rect.end.x - width
	elif label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x = rect.position.x + (rect.size.x - width) * 0.5
	return Rect2(Vector2(x, rect.position.y), Vector2(width, height))


func _collect(node: Node, panels: Array, texts: Array) -> void:
	for child in node.get_children():
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		if child is Panel or child is PanelContainer:
			var rect := (child as Control).get_global_rect()
			# 화면을 덮는 바탕은 뺀다.
			if rect.size.x < 900.0 and rect.get_area() > 0.0:
				panels.append([String(child.name), rect])
		elif child is Label and (child as Label).text != "":
			texts.append([String(child.name), _text_rect(child as Label)])
		_collect(child, panels, texts)
