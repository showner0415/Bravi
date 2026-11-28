extends RefCounted
## T213~T216: 접촉(계획 H03 결정 930~933) — 내 칼끝이 부위에 닿는다 / 결과별 회수와 막기·패리·맞음의 내 칼.
## T213은 결투 씬을 물리 없이 세우고 advance로 걷는다. T214는 칼 뷰만 세워 코어의 값을 손으로 놓는다. T215·T216은 상대 뷰만 세워 코어의 값을 손으로 놓는다.

const Plain := preload("res://tests/plain_opponent.gd")
const States := preload("res://tests/opponent_states.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const DUEL_PATH := "res://scenes/duel/duel.tscn"
const VIEW_PATH := "res://scenes/duel/player_sword_view.tscn"
const OPP_VIEW_PATH := "res://scenes/duel/opponent_view.tscn"
const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const FEEL_PATH := "res://data/hit_feel.tres"
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
		{"id": "T215", "name": "맞은 포즈: 여섯 부위 x 세 방향의 값, 2칸·유효타·그림별 배율, 거둠, 예비 동작에서 0, 쳐내진 포즈는 열린 끝에만, 읽기 층 그대로", "fn": t215_hit_pose},
		{"id": "T216", "name": "다가옴과 붙들기: 휘두름 구간의 x1.05와 2 tick 머묾, 읽기 층 그대로, 헛손질·휩쓸기 둘째 점은 x1.00, 타격 포즈 0.10초 붙들기", "fn": t216_approach_and_hold},
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


# ================================================================ T215·T216 (상대의 몸)

## 결정 934의 표(베기, 찌르기). 베기의 lean·head에는 방향 부호 s가, arm·sword에는 칼 팔 쪽 부호가 곱해진다. 찌르기 줄은 이미 최종 값이다.
const HIT_TABLE := {
	DT.Part.TORSO: [{"lean": 9.0, "head": -6.0, "arm": 14.0}, {"head": 10.0, "shoulder": Vector2(0.0, -8.0)}],
	DT.Part.HEAD: [{"lean": 3.0, "head": 22.0}, {"head": -18.0, "shoulder": Vector2(0.0, -4.0)}],
	DT.Part.SWORD_ARM: [{"lean": 4.0, "arm": 32.0, "sword": 25.0}, {"arm": 32.0, "sword": 25.0}],
	DT.Part.SWORD_HAND: [{"arm": 18.0, "sword": 45.0}, {"arm": 18.0, "sword": 45.0}],
	DT.Part.LEGS: [{"lean": 7.0, "shoulder": Vector2(0.0, 10.0)}, {"shoulder": Vector2(0.0, 12.0)}],
	DT.Part.HAT: [{"head": 8.0}, {"head": -8.0}],
}


func _spawn_opp_view() -> OpponentView:
	var view := (load(OPP_VIEW_PATH) as PackedScene).instantiate() as OpponentView
	_tree.root.add_child(view)
	view.anchor = Vector2(640.0, 446.4)
	_made.append(view)
	return view


## 포즈를 적용한 노드들의 값(맞기 전과 뺄셈으로 견준다). sword는 지역 각이다.
func _read_pose(view: OpponentView) -> Dictionary:
	return {
		"lean": (view.get_node(^"Torso") as Node2D).rotation_degrees,
		"head": (view.get_node(^"Torso/Head") as Node2D).rotation_degrees,
		"arm": (view.get_node(^"Torso/Arm") as Node2D).rotation_degrees,
		"sword": (view.get_node(^"Torso/Arm/Hand/Sword") as Node2D).rotation_degrees,
		"shoulder": (view.get_node(^"Torso/Arm") as Node2D).position,
	}


## 맞은 포즈가 더한 값의 기대(노드의 값으로): lean·head·arm, 칼의 지역 각(= sword - arm - lean), 어깨.
func _want_delta(row: Dictionary, direction: int, out: float, mult: float) -> Dictionary:
	var s := -1.0 if direction == DT.Direction.RIGHT else 1.0
	var lean := float(row.get("lean", 0.0)) * s * mult
	var head := float(row.get("head", 0.0)) * s * mult
	var arm := float(row.get("arm", 0.0)) * out * mult
	var sword := float(row.get("sword", 0.0)) * out * mult
	return {"lean": lean, "head": head, "arm": arm, "sword": sword - arm - lean, "shoulder": Vector2(row.get("shoulder", Vector2.ZERO)) * mult}


func _delta_errors(tag: String, before: Dictionary, after: Dictionary, want: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	for key in ["lean", "head", "arm", "sword"]:
		var got: float = after[key] - before[key]
		if absf(got - float(want[key])) > 0.02:
			errs.append("%s: %s 변화 %.2f (기대 %.2f)" % [tag, key, got, float(want[key])])
	var shoulder: Vector2 = after["shoulder"] - before["shoulder"]
	if not shoulder.is_equal_approx(want["shoulder"]):
		errs.append("%s: 어깨 변화 %s (기대 %s)" % [tag, shoulder, want["shoulder"]])
	return errs


func _label_points(view: OpponentView) -> Array[Vector2]:
	return [(view.get_node(^"StateLabel") as Control).global_position, (view.get_node(^"StateHint") as Control).global_position,
			(view.get_node(^"Ring") as Node2D).global_position]


func _thrust_of(opp: OpponentData) -> AttackData:
	for atk in opp.attacks:
		if atk.direction == DT.Direction.CENTER and not atk.is_big and not atk.dive and atk.chain.is_empty():
			return atk
	return null


## 이벤트를 먹이고 같은 시각의 첫 갱신을 그린 뒤 [맞기 전, 후, 시각]을 돌려준다. 이벤트 t는 일부러 tick 끝보다 0.9 tick 앞에 둔다(결정 928).
func _hit_delta_after(view: OpponentView, core: DuelCore, opp: OpponentData, weapon: WeaponData, ev: Dictionary) -> Array:
	view.setup(opp, weapon, true)
	var t := States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	var before := _read_pose(view)
	ev["t"] = t - 0.9 * DELTA
	view.on_event(ev)
	view.update_view(core, t, 0.0)
	return [before, _read_pose(view), t]


func t215_hit_pose() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	var weapon: WeaponData = load(WEAPON_PATH)
	var view := _spawn_opp_view()
	var core := States.make_core(false)
	var out := 1.0 if opp.sword_side == DT.Direction.LEFT else -1.0
	_expect(errs, opp.sword_side == DT.Direction.LEFT, "바르톨로의 칼 팔이 왼쪽이 아님 — 표의 부호 기대가 어긋난다")
	# 여섯 부위 x 세 방향: 첫 장이 맞기 전 + 표의 값.
	for part: int in HIT_TABLE:
		for direction in [DT.Direction.LEFT, DT.Direction.RIGHT, DT.Direction.CENTER]:
			var ev := {"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "part": part, "direction": direction, "cells": 1}
			var got := _hit_delta_after(view, core, opp, weapon, ev)
			var row: Dictionary = HIT_TABLE[part][1 if direction == DT.Direction.CENTER else 0]
			errs.append_array(_delta_errors("부위 %d %s" % [part, DIR_NAMES[direction]], got[0], got[1], _want_delta(row, direction, out, 1.0)))
	# 몸통을 찌르기로 맞으면 뿌리가 x0.96으로 물러서고 읽기 층의 자리는 그대로다(결정 934·947-2).
	view.setup(opp, weapon, true)
	var t := States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	var scale_before := view.scale.x
	var labels := _label_points(view)
	view.on_event({"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "part": DT.Part.TORSO, "direction": DT.Direction.CENTER})
	view.update_view(core, t, 0.0)
	_expect(errs, is_equal_approx(view.scale.x / scale_before, 0.96), "찌르기 몸통: 뿌리 크기 x%.3f (기대 0.96)" % (view.scale.x / scale_before))
	var labels_after := _label_points(view)
	for i in labels.size():
		_expect(errs, labels[i].distance_to(labels_after[i]) <= 0.01, "맞은 포즈 전후 읽기 층 %d의 전역 자리가 %.3fpx 움직임" % [i, labels[i].distance_to(labels_after[i])])
	# 세기: 2칸 x1.4, 유효타 x1.8, 그림별 배율(데이터의 scale_by_art).
	var strong := {"lean": 9.0, "head": -6.0, "arm": 14.0}
	var strengths := [["2칸", {"cells": 2}, 1.4], ["유효타", {"result": DT.AttackResult.HIT}, 1.8]]
	for strength: Array in strengths:
		var ev := {"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "part": DT.Part.TORSO, "direction": DT.Direction.LEFT, "cells": 1}
		ev.merge(strength[1], true)
		var got := _hit_delta_after(view, core, opp, weapon, ev)
		errs.append_array(_delta_errors(strength[0], got[0], got[1], _want_delta(strong, DT.Direction.LEFT, out, strength[2])))
	_expect(errs, String(view.get("_art_name")) == "bartolo_art.tres", "그림 배율의 열쇠가 그림 파일 이름이 아님: %s" % view.get("_art_name"))
	var feel := (load(FEEL_PATH) as HitFeelData).duplicate() as HitFeelData
	feel.scale_by_art = {"bartolo_art.tres": 0.5}
	view.set("_feel", feel)
	var halved := _hit_delta_after(view, core, opp, weapon, {"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "part": DT.Part.TORSO, "direction": DT.Direction.LEFT})
	errs.append_array(_delta_errors("그림 배율 0.5", halved[0], halved[1], _want_delta(strong, DT.Direction.LEFT, out, 0.5)))
	view.set("_feel", load(FEEL_PATH))
	# 거둠: 코어 0.32초 뒤 맞기 전. 판이 끝났으면 _clock이 거둬도 0.6배가 남는다. setup()이 지운다.
	var hit_ev := {"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "part": DT.Part.TORSO, "direction": DT.Direction.LEFT, "cells": 1}
	var back := _hit_delta_after(view, core, opp, weapon, hit_ev.duplicate())
	view.update_view(core, float(back[2]) + 0.33, 0.0)
	errs.append_array(_delta_errors("0.32초 뒤", back[0], _read_pose(view), _want_delta({}, DT.Direction.LEFT, out, 1.0)))
	var ended := _hit_delta_after(view, core, opp, weapon, hit_ev.duplicate())
	core.ended = true
	view.update_view(core, float(ended[2]), 1.0)
	errs.append_array(_delta_errors("끝난 판 1초 뒤", ended[0], _read_pose(view), _want_delta(strong, DT.Direction.LEFT, out, 0.6)))
	core.ended = false
	var cleared := _hit_delta_after(view, core, opp, weapon, hit_ev.duplicate())
	view.setup(opp, weapon, true)
	view.update_view(core, float(cleared[2]), 0.0)
	errs.append_array(_delta_errors("setup 뒤", cleared[0], _read_pose(view), _want_delta({}, DT.Direction.LEFT, out, 1.0)))
	_check_hit_pose_in_tell(errs, view, core, opp, weapon, hit_ev)
	_check_parried_pose(errs, view, core, opp, weapon, out)
	# 손으로 만든 열쇠 빠진 이벤트가 오류 없이 걸린다(방향은 가운데로 센다).
	var handmade: Array[Dictionary] = [{"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "part": DT.Part.TORSO}, {"type": DuelRecord.ATTACK},
			{"type": DuelRecord.STRIKE}, {"type": DuelRecord.STRIKE, "result": DT.StrikeResult.PARRIED}, {}]
	for ev: Dictionary in handmade:
		view.on_event(ev)
		view.update_view(core, t, 0.0)
	return _result(errs)


## 예비 동작의 포즈는 맞은 포즈와 상관없이 tell_pose 그대로다(결정 947-1): TELL_START가 오면, 이벤트 없이 TELL이 되어도.
func _check_hit_pose_in_tell(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData, weapon: WeaponData, hit_ev: Dictionary) -> void:
	var thrust := _thrust_of(opp)
	for with_event in [true, false]:
		_hit_delta_after(view, core, opp, weapon, hit_ev.duplicate())
		var t := States.put(core, DT.OpponentState.TELL, thrust, 0.5, DT.Distance.ENGAGE)
		if with_event:
			view.on_event({"type": DuelRecord.TELL_START, "attack": thrust})
		view.update_view(core, t, 0.0)
		var want := OpponentMotion.tell_pose(thrust, opp.idle_pose, 0.5, thrust.tell_time, weapon.parry_window, opp)
		var got := _read_pose(view)
		_expect(errs, absf(got["lean"] - want.lean_deg) <= 0.02 and absf(got["arm"] - want.arm_deg) <= 0.02 and absf(got["head"] - want.head_deg) <= 0.02,
				"예비 동작의 포즈가 tell_pose와 다름(TELL_START %s): 몸 %.2f 팔 %.2f 고개 %.2f" % [with_event, got["lean"], got["arm"], got["head"]])


## 쳐내진 포즈: 열린 끝의 패리에만(팔 +28·칼 +50·기울기 4), 휩쓸기를 읽어 연 끝은 60%, 가운데 패리·안 열림·속음·버티기·쥐고 막음은 0.
func _check_parried_pose(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData, weapon: WeaponData, out: float) -> void:
	var thrust := _thrust_of(opp)
	var base := {"type": DuelRecord.STRIKE, "attack": thrust, "next_strike": -1.0, "braced": false, "closed": false}
	var cases := [
		["열린 끝 패리", {"result": DT.StrikeResult.PARRIED}, 1.0],
		["가운데 패리", {"result": DT.StrikeResult.PARRIED, "next_strike": 3.0}, 0.0],
		["안 열린 패리", {"result": DT.StrikeResult.PARRIED, "closed": true}, 0.0],
		["속은 패리", {"result": DT.StrikeResult.PARRIED, "bitten": true}, 0.0],
		["쥐고 막음", {"result": DT.StrikeResult.BLOCKED}, 0.0],
		["버티기", {"result": DT.StrikeResult.BLOCKED, "braced": true}, 0.0],
	]
	for case: Array in cases:
		var ev := base.duplicate()
		ev.merge(case[1], true)
		var got := _hit_delta_after(view, core, opp, weapon, ev)
		errs.append_array(_delta_errors(case[0], got[0], got[1], _parried_want(out, float(case[2]))))
	# 휩쓸기를 읽어 연 끝(뿌리가 휩쓸기이고 끝 타격이 막힘): 값의 60%.
	var sweep := AttackData.new()
	sweep.sweep = true
	sweep.chain.append(AttackData.new())
	view.setup(opp, weapon, true)
	view.on_event({"type": DuelRecord.TELL_START, "attack": sweep})
	var t := States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	var before := _read_pose(view)
	var ev := base.duplicate()
	ev["result"] = DT.StrikeResult.BLOCKED
	view.on_event(ev)
	view.update_view(core, t, 0.0)
	errs.append_array(_delta_errors("휩쓸기를 읽어 연 끝", before, _read_pose(view), _parried_want(out, 0.6)))


## 쳐내진 포즈의 기대 변화: 기울기 4, 팔 28, 칼 50(화면 각)에 칼 팔 쪽 부호와 세기를 곱한다.
func _parried_want(out: float, mult: float) -> Dictionary:
	var lean := 4.0 * out * mult
	var arm := 28.0 * out * mult
	return {"lean": lean, "head": 0.0, "arm": arm, "sword": 50.0 * out * mult - arm - lean, "shoulder": Vector2.ZERO}


func t216_approach_and_hold() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	var weapon: WeaponData = load(WEAPON_PATH)
	var view := _spawn_opp_view()
	var core := States.make_core(false)
	var thrust := _thrust_of(opp)
	var dur := thrust.tell_time
	var swing := OpponentMotion.swing_time(dur, weapon.parry_window, opp)
	var base := OpponentView.DISTANCE_SCALE[DT.Distance.ENGAGE]
	# 휘두름 앞은 간격의 값, state_end와 그 뒤 2 tick은 x1.05, 타격 뒤 0.16초는 다시 간격의 값. 읽기 층의 전역 자리는 같다.
	view.setup(opp, weapon, false)
	var t := States.put(core, DT.OpponentState.TELL, thrust, 1.0 - swing / dur - 0.05, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	_expect(errs, absf(view.scale.x - base) <= 0.0005, "휘두름 앞의 크기 %.4f (기대 %.4f)" % [view.scale.x, base])
	var labels := _label_points(view)
	t = States.put(core, DT.OpponentState.TELL, thrust, 1.0, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	_expect(errs, absf(view.scale.x - base * 1.05) <= 0.001, "state_end의 크기 %.4f (기대 %.4f)" % [view.scale.x, base * 1.05])
	var labels_after := _label_points(view)
	for i in labels.size():
		_expect(errs, labels[i].distance_to(labels_after[i]) <= 0.01, "다가옴 전후 읽기 층 %d의 전역 자리가 %.3fpx 움직임" % [i, labels[i].distance_to(labels_after[i])])
	var end := core.brain.state_end
	view.update_view(core, States.to_idle(core, end, end + 2.0 * DELTA), 0.0)
	_expect(errs, absf(view.scale.x - base * 1.05) <= 0.001, "타격 뒤 2 tick의 크기 %.4f (기대 %.4f)" % [view.scale.x, base * 1.05])
	# 붙들기: 막힌 찌르기처럼 회수 0으로 곧장 대기에 가도 타격 포즈가 0.10초 서고(팔 그림 포함), 그 뒤 return_time에 대기로 섞인다.
	var strike := thrust.strike_pose
	var idle := opp.idle_pose
	view.update_view(core, States.to_idle(core, end, end + 0.05), 0.0)
	var arm := (view.get_node(^"Torso/Arm") as Node2D).rotation_degrees
	_expect(errs, absf(arm - strike.arm_deg) <= 0.02 and view.get("_art_key") == OpponentArmArt.art_of(strike), "타격 0.05초 뒤: 팔 %.2f(기대 %.2f) 그림 %s" % [arm, strike.arm_deg, view.get("_art_key")])
	view.update_view(core, States.to_idle(core, end, end + 0.10), 0.0)
	arm = (view.get_node(^"Torso/Arm") as Node2D).rotation_degrees
	_expect(errs, absf(arm - strike.arm_deg) <= 0.02, "타격 0.10초 뒤 섞임의 처음이 타격 포즈가 아님 %.2f" % arm)
	view.update_view(core, States.to_idle(core, end, end + 0.10 + opp.return_time * 0.5), 0.0)
	arm = (view.get_node(^"Torso/Arm") as Node2D).rotation_degrees
	var half := lerpf(strike.arm_deg, idle.arm_deg, 0.5)
	_expect(errs, absf(arm - half) <= 0.05, "0.10 + return_time/2: 팔 %.2f (기대 %.2f)" % [arm, half])
	view.update_view(core, States.to_idle(core, end, end + 0.10 + opp.return_time + 0.05), 0.0)
	arm = (view.get_node(^"Torso/Arm") as Node2D).rotation_degrees
	_expect(errs, absf(arm - idle.arm_deg) <= 0.02 and view.get("_art_key") == OpponentArmArt.art_of(idle), "0.10 + return_time 뒤는 대기: 팔 %.2f 그림 %s" % [arm, view.get("_art_key")])
	view.update_view(core, States.to_idle(core, end, end + 0.16), 0.0)
	_expect(errs, absf(view.scale.x - base) <= 0.001, "타격 뒤 0.16초의 크기 %.4f (기대 %.4f)" % [view.scale.x, base])
	# 헛손질의 걸음에는 다가옴도 붙들기도 없다.
	var feint := thrust.duplicate() as AttackData
	feint.feint = true
	view.setup(opp, weapon, false)
	t = States.put(core, DT.OpponentState.TELL, feint, 1.0, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	_expect(errs, absf(view.scale.x - base) <= 0.0005, "헛손질의 크기 %.4f (기대 %.4f)" % [view.scale.x, base])
	end = core.brain.state_end
	view.update_view(core, States.to_idle(core, end, end + 0.05), 0.0)
	arm = (view.get_node(^"Torso/Arm") as Node2D).rotation_degrees
	_expect(errs, absf(arm - strike.arm_deg) > 1.0, "헛손질 뒤에 타격 포즈를 붙들었다 (팔 %.2f)" % arm)
	# 휩쓸기의 둘째 점부터는 다가옴이 없다.
	var root := AttackData.new()
	root.sweep = true
	var second := thrust.duplicate() as AttackData
	root.chain.append(second)
	view.setup(opp, weapon, false)
	t = States.put(core, DT.OpponentState.TELL, second, 1.0, DT.Distance.ENGAGE)
	core.brain.pattern_root = root
	core.brain.step_index = 1
	core.brain.first_strike_time = t - 1.0
	view.update_view(core, t, 0.0)
	_expect(errs, absf(view.scale.x - base) <= 0.0005, "휩쓸기 둘째 점의 크기 %.4f (기대 %.4f)" % [view.scale.x, base])
	core.brain.pattern_root = null
	core.brain.step_index = 0
	# 회수가 있는 결과는 H03 전과 같다: 회수의 포즈가 recover_pose를 따른다.
	view.setup(opp, weapon, false)
	t = States.put(core, DT.OpponentState.RECOVERY, thrust, 0.5, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	arm = (view.get_node(^"Torso/Arm") as Node2D).rotation_degrees
	_expect(errs, absf(arm - OpponentMotion.recover_pose(thrust, 0.5).arm_deg) <= 0.02, "회수의 포즈가 recover_pose와 다름 (팔 %.2f)" % arm)
	return _result(errs)
