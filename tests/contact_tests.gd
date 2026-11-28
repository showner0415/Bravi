extends RefCounted
## T213~T214: 접촉(계획 H03 결정 930~933) — 내 칼끝이 부위에 닿는다 / 결과별 회수와 막기·패리·맞음의 내 칼.
## T213은 결투 씬을 물리 없이 세우고 advance로 걷는다. T214는 칼 뷰만 세워 코어의 값을 손으로 놓는다.

const Plain := preload("res://tests/plain_opponent.gd")
const States := preload("res://tests/opponent_states.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const VIEW_PATH := "res://scenes/duel/player_sword_view.tscn"
const DELTA := 1.0 / 60.0
const SCREEN := Vector2(1280, 720)
const NEAR := 6.0
const KINK_INFO := 0.5236
const SCALE_INFO := 0.70
const SCALE_FENCE := Vector2(0.50, 1.40)
const DIR_NAMES: Array[String] = ["왼쪽", "가운데", "오른쪽"]
const HEIGHT_NAMES: Array[String] = ["상단", "중단", "하단"]
const DIST_NAMES: Array[String] = ["멀리", "교전", "밀착"]
## T214의 견본: 부위의 자리와 상자(화면 좌표).
const CONTACT := Vector2(640.0, 330.0)
const RECT := Rect2(590.0, 270.0, 100.0, 120.0)

var _tree: SceneTree
var _made: Array[Node] = []


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T213", "name": "칼끝이 닿는다: 9칸 × 간격 × 런지에서 판정 뒤 첫 장의 칼끝 ≤ 6px, 2 tick 앞까지는 멀다, 누른 순간부터 움직인다, 닿지 않는 거리는 닿지 않는다, 접촉점 없는 호출은 겨누지 않는다", "fn": t213_reach},
		{"id": "T214", "name": "결과별 반작용: 닿음·튕김·피함·못 미침의 회수, 첫 갱신이 q 0, 색, 막기·패리·맞음의 내 칼, 열쇠 빠진 이벤트", "fn": t214_recover_and_cues},
	]


func cleanup() -> void:
	for node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()
	_tree = null


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


func _spawn_duel() -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	duel.set("practice_opponent", Plain.of(load(DuelScene.DEFAULT_OPPONENT_PATH) as OpponentData))
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	duel.set_process(false)
	duel.set_physics_process(false)
	_made.append(duel)
	return duel


func _spawn_view() -> PlayerSwordView:
	var view := (load(VIEW_PATH) as PackedScene).instantiate() as PlayerSwordView
	_tree.root.add_child(view)
	_made.append(view)
	return view


# ================================================================ T213

## 상대를 길게 대기시킨 판을 세운다. 간격과 방심을 코어에 직접 놓고 두 뷰를 그 자리에 붙인다.
func _arena(duel: Node, distance: int, lunge: bool) -> DuelCore:
	duel.call("start_duel")
	var core: DuelCore = duel.get("core")
	States.put(core, States.COMPLACENT if lunge else DT.OpponentState.IDLE, null, 0.0, distance)
	core.set("_approach_at", INF)
	(duel.get("_opponent_view") as OpponentView).setup(core.opponent_data, core.weapon, core.opponent_has_hat)
	(duel.get("_sword_view") as PlayerSwordView).setup()
	duel.set("_display_time", core.time)
	duel.call("_update_views", 0.0)
	return core


func t213_reach() -> String:
	var errs: Array[String] = []
	var duel := _spawn_duel()
	var cases := 0
	var tag := ""
	for distance in [DT.Distance.ENGAGE, DT.Distance.CLOSE]:
		for direction in 3:
			for height in 3:
				tag = "%s %s %s" % [DIST_NAMES[distance], DIR_NAMES[direction], HEIGHT_NAMES[height]]
				_check_case(errs, duel, tag, distance, direction, height, false, 0.0)
				cases += 1
	# 누른 시각을 tick의 0.3·0.7 자리로 어긋나게 둔다: 판정이 N번째·N+1번째 tick에 갈리는 두 갈래다(T1).
	for offset in [0.3, 0.7]:
		for combo: Array in [[DT.Distance.ENGAGE, DT.Direction.CENTER, DT.Height.MID], [DT.Distance.ENGAGE, DT.Direction.LEFT, DT.Height.HIGH],
				[DT.Distance.CLOSE, DT.Direction.RIGHT, DT.Height.LOW], [DT.Distance.ENGAGE, DT.Direction.CENTER, DT.Height.LOW]]:
			tag = "어긋남 %.1f %s %s %s" % [offset, DIST_NAMES[combo[0]], DIR_NAMES[combo[1]], HEIGHT_NAMES[combo[2]]]
			_check_case(errs, duel, tag, combo[0], combo[1], combo[2], false, offset)
			cases += 1
	for height in 3:
		tag = "런지 %s" % HEIGHT_NAMES[height]
		_check_case(errs, duel, tag, DT.Distance.FAR, DT.Direction.CENTER, height, true, 0.0)
		cases += 1
	for direction in 3:
		for height in 3:
			tag = "멀리 %s %s" % [DIR_NAMES[direction], HEIGHT_NAMES[height]]
			_check_case(errs, duel, tag, DT.Distance.FAR, direction, height, false, 0.0)
			cases += 1
	print("  INFO T213 조합 %d개" % cases)
	errs.append_array(_unaimed_errors())
	return _result(errs)


## 한 조합을 걷는다. 접촉 장의 거리·꺾임·길이·소매, 앞 장의 거리, 누른 순간과 예비 동안의 움직임을 잰다.
func _check_case(errs: Array[String], duel: Node, tag: String, distance: int, direction: int, height: int, lunge: bool, offset: float) -> void:
	var core := _arena(duel, distance, lunge)
	var sword := duel.get("_sword_view") as PlayerSwordView
	var blade := sword.get_node("Sword") as Polygon2D
	core.set_aim(direction, height)
	if offset > 0.0:
		duel.call("advance", DELTA * offset)
	var rest_tip := sword.tip_global()
	core.press_attack()
	if core.player_state != DT.PlayerState.WINDUP:
		errs.append("%s: 공격이 나가지 않음" % tag)
		return
	var attacks_before := core.record.of_type(DuelRecord.ATTACK).size()
	var tips: Array[Vector2] = []
	var strike_from := -1
	var span := core.player_state_end - core.player_state_start
	var judged := -1
	for i in 90:
		duel.call("advance", DELTA)
		tips.append(sword.tip_global())
		if core.record.of_type(DuelRecord.ATTACK).size() > attacks_before:
			judged = i
			break
	if judged < 0:
		errs.append("%s: 판정이 나오지 않음" % tag)
		return
	var plan: Dictionary = sword.get("_hold_plan")
	if plan.is_empty():
		errs.append("%s: 판정 뒤 겨눔이 비어 있음" % tag)
		return
	var contact := sword.held_contact()
	var target: Vector2 = plan["target"]
	var tip := tips[judged]
	var short: bool = plan["short"]
	if short:
		var rect: Rect2 = plan["rect"]
		_expect(errs, tip.distance_to(target) <= NEAR, "%s: 닿지 않는 거리의 접촉 장 칼끝이 목표에서 %.1fpx" % [tag, tip.distance_to(target)])
		_expect(errs, tip.distance_to(contact) >= 60.0, "%s: 닿지 않는 거리인데 칼끝이 접촉점에서 %.1fpx(60 이상이어야)" % [tag, tip.distance_to(contact)])
		_expect(errs, not rect.grow(PlayerSwordView.RECT_PAD).has_point(tip), "%s: 닿지 않는 거리인데 칼끝이 부위의 상자 안" % tag)
	else:
		_expect(errs, tip.distance_to(contact) <= NEAR, "%s: 접촉 장의 칼끝–접촉점 %.1fpx" % [tag, tip.distance_to(contact)])
	var kink := absf(blade.rotation)
	var scale_y := blade.scale.y
	_expect(errs, scale_y >= SCALE_FENCE.x and scale_y <= SCALE_FENCE.y, "%s: scale.y %.2f가 울타리 밖" % [tag, scale_y])
	var sleeve := sword.sleeve_top_at(sword.position, sword.rotation)
	_expect(errs, sleeve >= SCREEN.y + PlayerSwordView.SLEEVE_MARGIN - 0.1, "%s: 소매 끝 y %.1f가 화면 안" % [tag, sleeve])
	var travel := 0.0
	for i in judged:
		travel = maxf(travel, tips[i].distance_to(target))
	print("  INFO T213 %s: 거리 %.1fpx 꺾임 %.1f° scale.y %.2f 소매 %.1f 뻗음 %.0fpx%s" % [tag, tip.distance_to(target), rad_to_deg(kink),
			scale_y, sleeve, travel, " !" if kink > KINK_INFO or scale_y < SCALE_INFO else ""])
	# 판정 2 tick 앞까지는 목표에서 멀다(1 tick 앞의 장은 부동소수의 두 갈래라 재지 않는다).
	# 들기가 끝나 칼끝이 겨눔점에 선 뒤부터 판정 2 tick 앞까지만 잰다(쉬는 자리에서 물러나는 길에 목표 곁을 지나는 장은 접촉으로 읽히지 않는다).
	var lift_end := int(floor((span - minf(PlayerSwordView.STRIKE_TIME, 0.45 * span)) / DELTA)) + 1
	for i in range(lift_end, judged - 1):
		if tips[i].distance_to(target) <= NEAR:
			errs.append("%s: 판정 %d tick 앞의 장에 벌써 목표 %.1fpx 안" % [tag, judged - i, tips[i].distance_to(target)])
			break
	if judged >= 3:
		_expect(errs, tips[judged - 3].distance_to(target) >= 40.0, "%s: 판정 3 tick 앞의 장이 목표에서 %.1fpx(40 이상이어야)" % [tag, tips[judged - 3].distance_to(target)])
	# 누른 순간: 3 tick 안에 칼끝이 쉬는 자리에서 20px 이상 움직인다.
	var pulled := 0.0
	for i in mini(3, judged):
		pulled = maxf(pulled, tips[i].distance_to(rest_tip))
	_expect(errs, pulled >= 20.0, "%s: 누른 뒤 3 tick 안의 칼끝 이동 %.1fpx(20 이상이어야)" % [tag, pulled])
	# 뻗음의 길이: 뻗기 전 가장 먼 칼끝이 목표에서 100px 이상(닿지 않는 거리는 80).
	_expect(errs, travel >= 80.0, "%s: 뻗음의 길이 %.0fpx" % [tag, travel])
	if travel < 100.0:
		print("  INFO T213 %s: 뻗음의 길이 %.0fpx(100 미만)" % [tag, travel])
	# 찌르기의 뻗음: 칼끝 자취가 한 줄 위. 베기: 칼날의 화면 각이 한 방향으로만 바뀐다.
	strike_from = maxi(judged - int(floor(minf(PlayerSwordView.STRIKE_TIME, 0.45 * span) / DELTA)) + 1, 1)
	if judged - strike_from >= 2 and direction == DT.Direction.CENTER and not short:
		var a := tips[strike_from]
		var b := tips[judged - 1]
		var line := (b - a).normalized()
		for i in range(strike_from, judged):
			var off := absf((tips[i] - a).cross(line))
			if off > 2.0 and scale_y > SCALE_FENCE.x + 0.01 and scale_y < SCALE_FENCE.y - 0.01:
				errs.append("%s: 찌르기의 뻗음 자취가 줄에서 %.1fpx 벗어남" % [tag, off])
				break


## 접촉점 없이 뷰만 세우면 겨누지 않는다: 예비 끝의 뿌리 자리·각과 칼날의 rotation 0·scale.y 1이 H03 전과 같다.
func _unaimed_errors() -> Array[String]:
	var errs: Array[String] = []
	var view := _spawn_view()
	var core := States.make_core()
	var blade := view.get_node("Sword") as Polygon2D
	for direction in 3:
		core.player_state = DT.PlayerState.WINDUP
		core.player_state_start = 0.0
		core.player_state_end = 1.0
		core.attack_direction = direction
		core.attack_height = DT.Height.MID
		view.setup()
		view.update_view(core, 1.0, SCREEN, 1.0)
		var want := Vector2(SCREEN.x * PlayerSwordView.DIRECTION_X[direction], SCREEN.y - 70.0 - PlayerSwordView.LUNGE)
		_expect(errs, view.position.is_equal_approx(want), "겨누지 않는 예비 끝의 자리 %s (기대 %s)" % [view.position, want])
		_expect(errs, is_equal_approx(view.rotation, PlayerSwordView.DIRECTION_TILT[direction]), "겨누지 않는 예비 끝의 기울기 %.3f" % view.rotation)
		_expect(errs, blade.rotation == 0.0 and is_equal_approx(blade.scale.y, 1.0), "겨누지 않는 예비 끝의 칼날 rotation %.3f scale.y %.2f" % [blade.rotation, blade.scale.y])
	return errs


# ================================================================ T214

## 견본 접촉점으로 예비를 한 장 걷고 결과 이벤트를 먹인 뒤 회수의 첫 갱신까지 간다. 돌려줌: 칼 뷰, 코어.
func _after_attack(event: Dictionary, distance: int, direction: int) -> Array:
	var view := _spawn_view()
	var core := States.make_core()
	core.distance = distance
	core.attack_lunge = false
	core.attack_direction = direction
	core.attack_height = DT.Height.MID
	core.aim_direction = direction
	core.aim_height = DT.Height.MID
	core.player_state = DT.PlayerState.WINDUP
	core.player_state_start = 0.0
	core.player_state_end = 0.2
	view.setup()
	view.set_contact(CONTACT, RECT)
	view.update_view(core, 0.2, SCREEN, 0.0)
	# 판정 시각이 tick 끝보다 0.9 tick 앞이어도 첫 갱신이 q = 0이어야 한다.
	core.player_state = DT.PlayerState.RECOVER
	core.player_state_start = 0.2 - 0.9 * DELTA
	core.player_state_end = 0.5
	view.on_event(event)
	view.update_view(core, 0.2, SCREEN, 0.0)
	return [view, core]


func _at_q(view: PlayerSwordView, core: DuelCore, q: float) -> Vector2:
	view.update_view(core, 0.2 + q * 0.3, SCREEN, 0.0)
	return view.tip_global()


func t214_recover_and_cues() -> String:
	var errs: Array[String] = []
	var attack := {"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "direction": DT.Direction.CENTER, "dodged": false}
	var touched := _after_attack(attack, DT.Distance.ENGAGE, DT.Direction.CENTER)
	var view: PlayerSwordView = touched[0]
	var core: DuelCore = touched[1]
	var plan: Dictionary = view.get("_hold_plan")
	_expect(errs, not plan.is_empty(), "닿음: 판정 뒤 겨눔을 잡지 못했다")
	if plan.is_empty():
		return _result(errs)
	var in_dir: Vector2 = plan["in_dir"]
	var rest_tip: Vector2 = plan["tip_rest"]
	var blade := view.get_node("Sword") as Polygon2D
	_expect(errs, view.tip_global().distance_to(CONTACT) <= 1.0, "닿음 q0: 칼끝이 접촉점에서 %.1fpx" % view.tip_global().distance_to(CONTACT))
	_expect(errs, blade.color.is_equal_approx(PlayerSwordView.COLOR_WINDUP), "회수 q0의 색이 예비의 노랑이 아님 %s" % blade.color)
	var touch_01 := _at_q(view, core, 0.1) - CONTACT
	_expect(errs, touch_01.dot(in_dir) < 0.0 and touch_01.length() > 5.0 and touch_01.length() < 30.0, "닿음 q0.1: 온 길의 반대로 되튀지 않음 %s" % touch_01)
	_expect(errs, blade.color.is_equal_approx(PlayerSwordView.COLOR_WINDUP), "회수 0.03초의 색이 예비 색이 아님")
	_at_q(view, core, 0.3)
	_expect(errs, blade.color.is_equal_approx(PlayerSwordView.COLOR_RECOVER), "회수 0.09초의 색이 회수 색이 아님 %s" % blade.color)
	_expect(errs, _at_q(view, core, 1.0).distance_to(rest_tip) <= 1.0 and view.position.is_equal_approx(plan["h0"]), "닿음 q1: 쉬는 자리가 아님")
	_expect(errs, absf(blade.rotation) < 0.001 and is_equal_approx(blade.scale.y, 1.0), "닿음 q1: 칼날의 꺾임·길이가 남음")

	var bounced := _after_attack({"type": DuelRecord.ATTACK, "result": DT.AttackResult.BLOCKED}, DT.Distance.ENGAGE, DT.Direction.CENTER)
	var bounce_view: PlayerSwordView = bounced[0]
	var bounce_core: DuelCore = bounced[1]
	_expect(errs, bounce_view.tip_global().distance_to(CONTACT) <= 1.0, "튕김 q0: 칼끝이 접촉점에서 멀다")
	var bounce_01 := _at_q(bounce_view, bounce_core, 0.1) - CONTACT
	_expect(errs, bounce_01.dot(in_dir) < 0.0 and bounce_01.length() > touch_01.length(), "튕김 q0.1: 닿음의 되튐보다 크고 뒤쪽이어야 함 (%.1f 대 %.1f)" % [bounce_01.length(), touch_01.length()])
	_expect(errs, _at_q(bounce_view, bounce_core, 1.0).distance_to(rest_tip) <= 1.0, "튕김 q1: 쉬는 자리가 아님")
	var spiked := _after_attack({"type": DuelRecord.ATTACK, "result": DT.AttackResult.BLOCKED, "spiked": true}, DT.Distance.ENGAGE, DT.Direction.CENTER)
	_expect(errs, (spiked[0] as PlayerSwordView).get("_recover_kind") == PlayerSwordView.Recover.BOUNCE, "송곳에 걸림이 튕김이 아님")

	var dodged := _after_attack({"type": DuelRecord.ATTACK, "result": DT.AttackResult.BLOCKED, "dodged": true}, DT.Distance.ENGAGE, DT.Direction.CENTER)
	var dodge_view: PlayerSwordView = dodged[0]
	var dodge_core: DuelCore = dodged[1]
	_expect(errs, dodge_view.tip_global().distance_to(CONTACT) <= 1.0, "피함 q0: 칼끝이 접촉점에서 멀다")
	var dodge_03 := _at_q(dodge_view, dodge_core, 0.3) - CONTACT
	_expect(errs, dodge_03.dot(in_dir) > 0.0 and dodge_03.length() > 40.0, "피함 q0.3: 온 길의 앞으로 지나치지 않음 %s" % dodge_03)
	_expect(errs, _at_q(dodge_view, dodge_core, 1.0).distance_to(rest_tip) <= 1.0, "피함 q1: 쉬는 자리가 아님")

	var short := _after_attack({"type": DuelRecord.ATTACK, "result": DT.AttackResult.WHIFF, "dodged": false}, DT.Distance.FAR, DT.Direction.CENTER)
	var short_view: PlayerSwordView = short[0]
	var short_core: DuelCore = short[1]
	_expect(errs, short_view.get("_recover_kind") == PlayerSwordView.Recover.SHORT, "멀리의 헛침이 못 미침이 아님")
	_expect(errs, short_view.tip_global().distance_to(CONTACT) >= 60.0, "못 미침 q0: 접촉점에서 %.1fpx(60 이상이어야)" % short_view.tip_global().distance_to(CONTACT))
	# 상자 밖은 칼이 나갔다 들어오는 q 0.35까지다: 쉬는 자리의 칼끝이 상대의 상자 안에 걸릴 수 있다.
	for q in [0.0, 0.1, 0.3]:
		var point := _at_q(short_view, short_core, q)
		_expect(errs, not RECT.has_point(point), "못 미침 q%.1f: 칼끝이 부위의 상자 안 %s" % [q, point])
	_expect(errs, _at_q(short_view, short_core, 1.0).distance_to(rest_tip) <= 1.0, "못 미침 q1: 쉬는 자리가 아님")
	# 칼끝이 이미 접촉점에 가 있었는데 헛쳤다면(닿는 거리) 못 미침이 아니라 지나친다.
	var passed := _after_attack({"type": DuelRecord.ATTACK, "result": DT.AttackResult.WHIFF, "dodged": false}, DT.Distance.ENGAGE, DT.Direction.CENTER)
	_expect(errs, (passed[0] as PlayerSwordView).get("_recover_kind") == PlayerSwordView.Recover.DODGE, "닿는 거리의 헛침이 지나침이 아님")

	_check_cues(errs)
	_check_handmade(errs)
	return _result(errs)


## 막기·패리·맞음: 시작은 이벤트 뒤 첫 갱신이고 k = 1/4에서 가장 크며 길이 뒤 0이다.
func _check_cues(errs: Array[String]) -> void:
	var sx_left := AttackData.new()
	sx_left.direction = DT.Direction.LEFT
	var cases := [
		["쥐고 막음", {"result": DT.StrikeResult.BLOCKED}, 0.16, Vector2(8.5, 8.5), 0.0],
		["패리", {"result": DT.StrikeResult.PARRIED}, 0.12, Vector2(-11.3, -11.3), -deg_to_rad(6.0)],
		["안 열린 패리", {"result": DT.StrikeResult.PARRIED, "closed": true}, 0.16, Vector2(8.5, 8.5), 0.0],
		["속은 패리", {"result": DT.StrikeResult.PARRIED, "bitten": true}, 0.16, Vector2(8.5, 8.5), 0.0],
		["맞음", {"result": DT.StrikeResult.GRAZE}, 0.30, Vector2(10.0, 26.0), 0.0],
	]
	for row: Array in cases:
		var view := _spawn_view()
		var core := States.make_core()
		core.player_state = DT.PlayerState.GUARD
		core.guard_enter_time = -INF
		core.distance = DT.Distance.ENGAGE
		view.setup()
		view.update_view(core, 1.0, SCREEN, 0.0)
		var base := view.position
		var ev := {"type": DuelRecord.STRIKE, "attack": sx_left}
		ev.merge(row[1], true)
		view.on_event(ev)
		view.update_view(core, 1.0, SCREEN, 0.0)
		_expect(errs, view.position.is_equal_approx(base), "%s: 첫 갱신(k 0)에 이미 움직임" % row[0])
		var length: float = row[2]
		view.update_view(core, 1.0 + length * 0.25, SCREEN, 0.0)
		var moved := view.position - base
		var want: Vector2 = row[3]
		_expect(errs, moved.distance_to(want) <= 0.6, "%s: k 1/4의 이동 %s (기대 %s)" % [row[0], moved, want])
		_expect(errs, absf((view.get_node("Sword") as Polygon2D).rotation - float(row[4])) <= 0.005, "%s: 칼날의 스냅 %.3f (기대 %.3f)" % [row[0], (view.get_node("Sword") as Polygon2D).rotation, float(row[4])])
		view.update_view(core, 1.0 + length + 0.01, SCREEN, 0.0)
		_expect(errs, view.position.is_equal_approx(base) and absf((view.get_node("Sword") as Polygon2D).rotation) < 0.0001, "%s: 길이 뒤에 0으로 돌아오지 않음" % row[0])
	# 밀착의 막기는 17px.
	var close_view := _spawn_view()
	var close_core := States.make_core()
	close_core.player_state = DT.PlayerState.GUARD
	close_core.guard_enter_time = -INF
	close_core.distance = DT.Distance.CLOSE
	close_view.setup()
	close_view.update_view(close_core, 1.0, SCREEN, 0.0)
	var close_base := close_view.position
	close_view.on_event({"type": DuelRecord.STRIKE, "result": DT.StrikeResult.BLOCKED, "attack": sx_left})
	close_view.update_view(close_core, 1.0, SCREEN, 0.0)
	close_view.update_view(close_core, 1.04, SCREEN, 0.0)
	_expect(errs, absf((close_view.position - close_base).length() - 17.0) <= 0.3, "밀착의 막기 이동 %.1f(17)" % (close_view.position - close_base).length())


## 손으로 만든 열쇠 빠진 이벤트가 오류 없이 지나간다(찍기·테스트가 이런 사전을 만든다).
func _check_handmade(_errs: Array[String]) -> void:
	var view := _spawn_view()
	var core := States.make_core()
	core.player_state = DT.PlayerState.READY
	view.setup()
	for ev: Dictionary in [{"type": DuelRecord.ATTACK}, {"type": DuelRecord.STRIKE}, {"type": DuelRecord.STRIKE, "result": DT.StrikeResult.PARRIED},
			{"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE}, {}]:
		view.on_event(ev)
		view.update_view(core, 1.0, SCREEN, 0.0)
