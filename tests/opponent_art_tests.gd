extends RefCounted
## T65~T67: 상대 그림과 포즈(계획 029). 데이터, 곡선의 값, 상대 뷰가 상태를 따르는지.
## 화면(셰이더의 결과)은 보지 못한다: 유니폼의 값만 본다(계획 029 위험 R3). 화면은 찍기 씬이 본다.

const States := preload("res://tests/opponent_states.gd")
const DT := preload("res://scripts/duel/duel_types.gd")

const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const VIEW_PATH := "res://scenes/duel/opponent_view.tscn"
const EPS := 0.01

## assets/MANIFEST.md 7~16행의 크기·관절·단위/화소. MANIFEST를 고치면 이 표도 고친다.
const MANIFEST := {
	"head": [Vector2i(225, 255), Vector2(112, 223), Vector2(0.5442, 0.5442)],
	"head_oops": [Vector2i(228, 255), Vector2(113.5, 224), Vector2(0.5442, 0.5442)],
	"head_dizzy": [Vector2i(228, 255), Vector2(113.5, 225), Vector2(0.5442, 0.5442)],
	"hat": [Vector2i(282, 127), Vector2(140, 102), Vector2(0.5579, 0.5579)],
	"feather": [Vector2i(247, 71), Vector2(-43, 81), Vector2(0.5579, 0.5579)],
	"torso": [Vector2i(257, 369), Vector2(127, 360), Vector2(0.5935, 0.5935)],
	"legs": [Vector2i(287, 338), Vector2(142, 11), Vector2(0.5935, 0.5935)],
	"arm": [Vector2i(97, 275), Vector2(48, 40), Vector2(0.4451, 0.4611)],
	"hand": [Vector2i(100, 109), Vector2(49, 12), Vector2(0.4511, 0.4511)],
	"sword": [Vector2i(147, 399), Vector2(73, 343), Vector2(0.5935, 0.5935)],
}

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T65", "name": "상대 그림과 포즈의 데이터: 파츠 열 장, 관절, 공격과 상태의 포즈", "fn": t65_art_data},
		{"id": "T66", "name": "포즈와 곡선의 값: hold 곡선, 회수, 고르게 가는 곡선", "fn": t66_motion},
		{"id": "T67", "name": "상대 뷰: 포즈·머리·색·테두리가 상태를 따른다", "fn": t67_view},
	]


func cleanup() -> void:
	_tree = null


## 일반 공격과 버릇 반응의 공격. 이름은 찌르기·왼쪽·오른쪽 베기·큰 베기를 thrust·cutl·cutr·big으로.
func _attacks(opp: OpponentData) -> Dictionary:
	var out := {}
	var all: Array[AttackData] = []
	all.append_array(opp.attacks)
	for habit in opp.habits:
		if habit.response != null:
			all.append(habit.response)
	for atk in all:
		if atk.is_big:
			out["big"] = atk
		elif atk.direction == DT.Direction.CENTER:
			out["thrust"] = atk
		elif atk.direction == DT.Direction.LEFT:
			out["cutl"] = atk
		else:
			out["cutr"] = atk
	return out


func _near(errs: Array[String], what: String, got: float, want: float, eps := EPS) -> void:
	if absf(got - want) > eps:
		errs.append("%s %.4f (기대 %.4f)" % [what, got, want])


func _ang(a: float, b: float) -> float:
	var d := fposmod(a - b, 360.0)
	return minf(d, 360.0 - d)


func t65_art_data() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	if opp.art == null:
		return "opponent_01.tres에 art가 없음"
	for key: String in MANIFEST:
		var pa: PartArt = opp.art.get(key)
		var want: Array = MANIFEST[key]
		if pa == null or pa.texture == null:
			errs.append("%s: 그림 없음" % key)
			continue
		if Vector2i(pa.texture.get_size()) != want[0]:
			errs.append("%s: 크기 %s (기대 %s)" % [key, Vector2i(pa.texture.get_size()), want[0]])
		if not pa.joint.is_equal_approx(want[1]):
			errs.append("%s: 관절 %s (기대 %s)" % [key, pa.joint, want[1]])
		if not pa.units_per_px.is_equal_approx(want[2]):
			errs.append("%s: 단위/화소 %s (기대 %s)" % [key, pa.units_per_px, want[2]])
	var atks := _attacks(opp)
	if atks.size() != 4:
		errs.append("공격 넷을 찾지 못함: %s" % str(atks.keys()))
	for name: String in atks:
		var atk: AttackData = atks[name]
		if atk.tell_pose == null or atk.strike_pose == null:
			errs.append("%s: tell_pose·strike_pose 없음" % name)
	if opp.idle_pose == null or opp.stagger_pose == null or opp.complacent_pose == null:
		errs.append("대기·무너짐·방심의 포즈 없음")
		return ", ".join(errs)
	# 무너짐과 회수 끝은 넷(팔 15°, 칼 30°, 어깨 15, 고개 10°) 가운데 둘 이상에서 갈린다(바이블 15절).
	var st := opp.stagger_pose
	for name: String in atks:
		var atk: AttackData = atks[name]
		if atk.strike_pose == null:
			continue
		var rec := OpponentMotion.recover_end_of(atk)
		var apart := 0
		apart += 1 if absf(rec.arm_deg - st.arm_deg) >= 15.0 else 0
		apart += 1 if _ang(rec.sword_deg, st.sword_deg) >= 30.0 else 0
		apart += 1 if rec.shoulder.distance_to(st.shoulder) >= 15.0 else 0
		apart += 1 if absf(rec.head_deg - st.head_deg) >= 10.0 else 0
		if apart < 2:
			errs.append("%s: 회수 끝과 무너짐이 %d가지에서만 갈림" % [name, apart])
	return "OK" if errs.is_empty() else ", ".join(errs)


func t66_motion() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	var parry: float = (load(WEAPON_PATH) as WeaponData).parry_window
	var atks := _attacks(opp)
	if atks.size() != 4:
		return "공격 넷을 찾지 못함: %s" % str(atks.keys())
	var thrust: AttackData = atks["thrust"]
	var cutl: AttackData = atks["cutl"]
	var big: AttackData = atks["big"]
	var before := [thrust.tell_pose.arm_deg, thrust.tell_pose.sword_deg, thrust.strike_pose.arm_deg, opp.idle_pose.arm_deg]

	_near(errs, "휘두름 찌르기", OpponentMotion.swing_time(thrust.tell_time, parry, opp), 0.13)
	_near(errs, "휘두름 베기", OpponentMotion.swing_time(cutl.tell_time, parry, opp), 0.15)
	_near(errs, "휘두름 큰 베기", OpponentMotion.swing_time(big.tell_time, parry, opp), 0.15)
	_near(errs, "휘두름 밀착 찌르기", OpponentMotion.swing_time(thrust.tell_time * opp.close_tell_multiplier, parry, opp), 0.104)
	_near(errs, "멈칫 끝 찌르기", OpponentMotion.hold_end(thrust.tell_time, parry, opp), 0.8)
	_near(errs, "멈칫 끝 베기", OpponentMotion.hold_end(cutl.tell_time, parry, opp), 0.8)
	_near(errs, "멈칫 끝 큰 베기", OpponentMotion.hold_end(big.tell_time, parry, opp), 1.0 - 0.15 / 1.1, 0.0001)

	var tell := func(atk: AttackData, p: float, o: OpponentData) -> PoseData:
		return OpponentMotion.tell_pose(atk, o.idle_pose, p, atk.tell_time, parry, o)
	var t01: PoseData = tell.call(thrust, 0.1, opp)
	_near(errs, "찌르기 p0.1 팔", t01.arm_deg, 69.5)
	_near(errs, "찌르기 p0.1 칼", t01.sword_deg, 66.0)
	var ps := [0.2, 0.5, 0.8, 0.9, 1.0]
	var arms := [85.0, 89.0, 93.0, 62.25, -30.0]
	var swords := [95.0, 95.0, 95.0, 116.25, 180.0]
	for i in ps.size():
		var pose: PoseData = tell.call(thrust, ps[i], opp)
		_near(errs, "찌르기 p%.1f 팔" % ps[i], pose.arm_deg, arms[i])
		_near(errs, "찌르기 p%.1f 칼" % ps[i], pose.sword_deg, swords[i])
	_near(errs, "큰 베기 p0.5 몸", (tell.call(big, 0.5, opp) as PoseData).lean_deg, -4.0)
	_near(errs, "큰 베기 p1 몸", (tell.call(big, 1.0, opp) as PoseData).lean_deg, 0.0)
	var rec := OpponentMotion.recover_pose(cutl, 0.5)
	_near(errs, "왼쪽 베기 회수 q0.5 팔", rec.arm_deg, 13.3)
	_near(errs, "왼쪽 베기 회수 q0.5 칼", rec.sword_deg, -120.0)

	var flat := opp.duplicate() as OpponentData
	flat.hold_curve = false
	var f05: PoseData = tell.call(thrust, 0.5, flat)
	_near(errs, "고른 곡선 p0.5 팔", f05.arm_deg, 27.5)
	_near(errs, "고른 곡선 p0.5 칼", f05.sword_deg, 137.5)

	var mid := OpponentMotion.blend(opp.idle_pose, opp.stagger_pose, 0.5)
	_near(errs, "blend 0.5 팔", mid.arm_deg, 11.5)
	_near(errs, "blend 0.5 어깨", mid.shoulder.y, 12.5)
	_near(errs, "ease_in_out 0.5", OpponentMotion.ease_in_out(0.5), 0.5)

	var after := [thrust.tell_pose.arm_deg, thrust.tell_pose.sword_deg, thrust.strike_pose.arm_deg, opp.idle_pose.arm_deg]
	if after != before:
		errs.append("받은 포즈가 고쳐짐: %s → %s" % [str(before), str(after)])
	return "OK" if errs.is_empty() else ", ".join(errs)


## 파츠 Art의 경로와 OpponentArt의 필드 이름.
const ART_NODES := {
	^"Legs/Art": "legs", ^"Torso/Art": "torso", ^"Torso/Head/Art": "head", ^"Torso/Head/Hat/Art": "hat",
	^"Torso/Head/Hat/Feather": "feather", ^"Torso/Arm/Art": "arm", ^"Torso/Arm/Hand/Art": "hand",
	^"Torso/Arm/Hand/Sword/Art": "sword",
}


func _mat(view: Node, path: NodePath) -> ShaderMaterial:
	return (view.get_node(path) as CanvasItem).material as ShaderMaterial


func _tint_is(errs: Array[String], what: String, mat: ShaderMaterial, color: Color, amount: float) -> void:
	var got: Vector3 = mat.get_shader_parameter(&"tint_color")
	if not got.is_equal_approx(Vector3(color.r, color.g, color.b)):
		errs.append("%s 색 %s (기대 %s)" % [what, got, color])
	_near(errs, what + " 양", mat.get_shader_parameter(&"tint_amount"), amount)


func _deg(view: Node, path: NodePath) -> float:
	return (view.get_node(path) as Node2D).rotation_degrees


func _head_is(errs: Array[String], what: String, view: Node, want: PartArt) -> void:
	if (view.get_node(^"Torso/Head/Art") as Sprite2D).texture != want.texture:
		errs.append("%s: 머리 그림이 다름" % what)


func t67_view() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	var weapon: WeaponData = load(WEAPON_PATH)
	var atks := _attacks(opp)
	if opp.art == null or atks.size() != 4:
		return "그림이나 공격 넷이 없음"
	var view: OpponentView = (load(VIEW_PATH) as PackedScene).instantiate()
	_tree.root.add_child(view)
	view.anchor = Vector2(640, 446.4)
	var core := States.make_core(true)
	_t67_setup(errs, view, opp, weapon)
	_t67_tell(errs, view, core, opp, weapon, atks["thrust"])
	_t67_recover_stagger(errs, view, core, opp, weapon, atks)
	_t67_target_flash(errs, view, core, opp, weapon)
	view.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


# 확인 1: setup 뒤 그림·관절·대기 포즈.
func _t67_setup(errs: Array[String], view: OpponentView, opp: OpponentData, weapon: WeaponData) -> void:
	view.setup(opp, weapon, true)
	for path: NodePath in ART_NODES:
		var sprite := view.get_node(path) as Sprite2D
		var pa: PartArt = opp.art.get(ART_NODES[path])
		if sprite.texture != pa.texture:
			errs.append("%s: 그림이 데이터와 다름" % path)
		if not sprite.offset.is_equal_approx(-pa.joint) or not sprite.scale.is_equal_approx(pa.units_per_px):
			errs.append("%s: offset %s scale %s" % [path, sprite.offset, sprite.scale])
	var arm := view.get_node(^"Torso/Arm") as Node2D
	if not arm.position.is_equal_approx(opp.art.shoulder):
		errs.append("어깨 %s (기대 %s)" % [arm.position, opp.art.shoulder])
	_near(errs, "setup 팔", arm.rotation_degrees, 23.0)
	_near(errs, "setup 칼", _deg(view, ^"Torso/Arm/Hand/Sword"), -44.0)
	_head_is(errs, "setup", view, opp.art.head)


# 확인 2·3: 찌르기 예비 동작.
func _t67_tell(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData,
		weapon: WeaponData, thrust: AttackData) -> void:
	view.setup(opp, weapon, true)
	var t := States.put(core, DT.OpponentState.TELL, thrust, 0.5, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	var want := OpponentMotion.tell_pose(thrust, opp.idle_pose, 0.5, thrust.tell_time, weapon.parry_window, opp)
	_near(errs, "p0.5 팔", _deg(view, ^"Torso/Arm"), want.arm_deg)
	_near(errs, "p0.5 칼", _deg(view, ^"Torso/Arm/Hand/Sword"), want.sword_deg - want.arm_deg - want.lean_deg)
	_tint_is(errs, "p0.5 몸통", _mat(view, ^"Torso/Art"), thrust.pose_color, 0.8)
	_near(errs, "p0.5 모자 양", _mat(view, ^"Torso/Head/Hat/Art").get_shader_parameter(&"tint_amount"), 0.0)
	if (view.get_node(^"Torso/Arm/Hand/Sword/Art") as CanvasItem).material != null:
		errs.append("칼에 재질이 있음(상태 색을 받으면 안 된다)")
	view.setup(opp, weapon, true)
	t = States.put(core, DT.OpponentState.TELL, thrust, 0.9999, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	_near(errs, "p0.9999 팔", _deg(view, ^"Torso/Arm"), -30.0, 0.5)


# 확인 4·5·6: 회수의 머리, 무너짐, 방심.
func _t67_recover_stagger(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData,
		weapon: WeaponData, atks: Dictionary) -> void:
	view.setup(opp, weapon, true)
	var t := States.put(core, DT.OpponentState.RECOVERY, atks["cutl"], 0.5, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	_head_is(errs, "그냥 회수", view, opp.art.head_oops)
	_near(errs, "그냥 회수 머리 양", _mat(view, ^"Torso/Head/Art").get_shader_parameter(&"tint_amount"), 0.0)
	_tint_is(errs, "그냥 회수 몸통", _mat(view, ^"Torso/Art"), OpponentView.COLOR_RECOVERY, 0.8)
	view.setup(opp, weapon, true)
	t = States.put(core, DT.OpponentState.RECOVERY, atks["big"], 0.5, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	_near(errs, "크게 열림 머리 양", _mat(view, ^"Torso/Head/Art").get_shader_parameter(&"tint_amount"), 0.8)

	var st := opp.stagger_pose
	view.setup(opp, weapon, true)
	t = States.put(core, DT.OpponentState.STAGGER, null, 0.0, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	_head_is(errs, "무너짐", view, opp.art.head_dizzy)
	_near(errs, "무너짐 팔", _deg(view, ^"Torso/Arm"), st.arm_deg)
	_near(errs, "무너짐 칼", _deg(view, ^"Torso/Arm/Hand/Sword"), st.sword_deg - st.arm_deg - st.lean_deg)
	_near(errs, "무너짐 고개", _deg(view, ^"Torso/Head"), st.head_deg)
	var arm_pos := (view.get_node(^"Torso/Arm") as Node2D).position
	if not arm_pos.is_equal_approx(opp.art.shoulder + st.shoulder):
		errs.append("무너짐 어깨 %s" % arm_pos)
	_tint_is(errs, "무너짐 몸통", _mat(view, ^"Torso/Art"), OpponentView.COLOR_STAGGER, 0.8)
	view.setup(opp, weapon, true)
	t = States.put(core, DT.OpponentState.STAGGER, null, 0.0, DT.Distance.ENGAGE, false)
	view.update_view(core, t, 0.0)
	_near(errs, "무너짐 막 들어감 팔", _deg(view, ^"Torso/Arm"),
			lerpf(opp.idle_pose.arm_deg, st.arm_deg, OpponentMotion.ease_in_out(0.5)))

	view.setup(opp, weapon, true)
	t = States.put(core, States.COMPLACENT, null, 0.0, DT.Distance.FAR)
	view.update_view(core, t, 0.0)
	var cp := opp.complacent_pose
	_near(errs, "방심 칼", _deg(view, ^"Torso/Arm/Hand/Sword"), cp.sword_deg - cp.arm_deg - cp.lean_deg)
	_near(errs, "방심 칼(기대 -163)", cp.sword_deg - cp.arm_deg, -163.0)
	_head_is(errs, "방심", view, opp.art.head)
	# 방심의 시작은 알아챈 프레임이 아니라 max(state_start, alert_since + complacent_time) = 20이다(결정 258).
	_near(errs, "방심의 시작", view.get("_phase_start"), 20.0)


# 확인 7·8: 조준 테두리, 닿은 부위의 흰 번쩍임, 타격의 빨강.
func _t67_target_flash(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData,
		weapon: WeaponData) -> void:
	view.setup(opp, weapon, true)
	var outlined := func() -> String:
		var on: Array[String] = []
		for path: NodePath in ART_NODES:
			var mat := _mat(view, path)
			if mat != null and mat.get_shader_parameter(&"outline_on"):
				on.append(ART_NODES[path])
		return ",".join(on)
	view.set_target(DT.Part.TORSO)
	if outlined.call() != "torso":
		errs.append("몸통 조준의 테두리: %s" % outlined.call())
	view.set_target(DT.Part.HAT)
	if outlined.call() != "hat,feather":
		errs.append("모자 조준의 테두리: %s" % outlined.call())
	view.set_target(-1)
	if outlined.call() != "":
		errs.append("조준 없음의 테두리: %s" % outlined.call())

	var t := States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE)
	view.on_event({"type": DuelRecord.ATTACK, "result": DT.AttackResult.GRAZE, "part": DT.Part.LEGS,
			"dodged": false, "rash": false, "posture_gain": 0})
	view.update_view(core, t, 0.01)
	_tint_is(errs, "닿은 다리", _mat(view, ^"Legs/Art"), OpponentView.COLOR_TOUCHED, 1.0)
	view.on_event({"type": DuelRecord.STRIKE, "braced": false})
	view.update_view(core, t, 0.01)
	_tint_is(errs, "타격의 몸통", _mat(view, ^"Torso/Art"), OpponentView.COLOR_STRIKE, 0.8)
