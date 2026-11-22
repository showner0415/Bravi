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
	"sword": [Vector2i(147, 399), Vector2(73, 371), Vector2(0.5935, 0.5935)],
}

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T65", "name": "상대 그림과 포즈의 데이터: 파츠 열 장, 관절, 공격과 상태의 포즈", "fn": t65_art_data},
		{"id": "T66", "name": "포즈와 곡선의 값: hold 곡선, 회수, 고르게 가는 곡선", "fn": t66_motion},
		{"id": "T67", "name": "상대 뷰: 포즈·머리·색·테두리가 상태를 따른다", "fn": t67_view},
		{"id": "T68", "name": "따로 그린 팔의 데이터: 묶음 둘, 층의 차례·부위, 크기·관절, 포즈의 팔 그림", "fn": t68_arm_data},
		{"id": "T69", "name": "상대 뷰: 팔 그림을 국면의 경계에서 바꿔 끼운다", "fn": t69_arm_swap},
		{"id": "T70", "name": "손의 조준은 칼 위의 바깥 윤곽선", "fn": t70_hand_outline},
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
	# 데이터에 매인 값: 대기 팔 + (85 - 대기 팔) x ease_out(0.5)
	_near(errs, "찌르기 p0.1 팔", t01.arm_deg, 63.75)
	_near(errs, "찌르기 p0.1 칼", t01.sword_deg, 66.0)
	var ps := [0.2, 0.5, 0.8, 0.9, 1.0]
	# p0.9 = 93 + (타격 - 93) x 0.25, p1.0 = 타격(-50)
	var arms := [85.0, 89.0, 93.0, 57.25, -50.0]
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
	_near(errs, "고른 곡선 p0.5 팔", f05.arm_deg, 17.5) # (85 + 타격) / 2
	_near(errs, "고른 곡선 p0.5 칼", f05.sword_deg, 137.5)

	var mid := OpponentMotion.blend(opp.idle_pose, opp.stagger_pose, 0.5)
	_near(errs, "blend 0.5 팔", mid.arm_deg, 0.0) # 대기 팔 / 2
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
	_near(errs, "setup 팔", arm.rotation_degrees, 0.0)
	_near(errs, "setup 칼", _deg(view, ^"Torso/Arm/Hand/Sword"), -21.0) # 대기 칼 -21 - 대기 팔
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
	_near(errs, "p0.9999 팔", _deg(view, ^"Torso/Arm"), -50.0, 0.5)


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


## assets/MANIFEST.md의 따로 그린 팔 열한 줄(계획 030·030c). 이름: [크기, 관절, 부위]. 단위/화소는 모두 0.3165.
const ARM_MANIFEST := {
	"arm_up_sword": [Vector2i(161, 562), Vector2(78, 912), -1],
	"arm_up": [Vector2i(108, 288), Vector2(52, 233), 3],
	"arm_up_fist": [Vector2i(128, 120), Vector2(62, 350), 4],
	"arm_thrust": [Vector2i(261, 140), Vector2(136, 65), 3],
	"arm_thrust_fist": [Vector2i(261, 231), Vector2(136, -72), 4],
	"arm_thrust_sword": [Vector2i(281, 287), Vector2(137, -159), -1],
	"arm_thrust_blade": [Vector2i(75, 81), Vector2(-125, -252), -1],
	"arm_aim": [Vector2i(166, 235), Vector2(92, 65), 3],
	"arm_aim_fist": [Vector2i(166, 177), Vector2(92, -167), 4],
	"arm_aim_sword": [Vector2i(209, 205), Vector2(100, -241), -1],
	"arm_aim_blade": [Vector2i(118, 131), Vector2(-38, -208), -1],
}
const ARM_ORDER := {&"armUp": ["arm_up_sword", "arm_up", "arm_up_fist"],
		&"armThrust": ["arm_thrust", "arm_thrust_fist", "arm_thrust_sword", "arm_thrust_blade"],
		&"armAim": ["arm_aim", "arm_aim_fist", "arm_aim_sword", "arm_aim_blade"]}
const ARM_ROTATION := {&"armUp": 180.0, &"armThrust": 0.0, &"armAim": 0.0}


func t68_arm_data() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	var keys: Array[StringName] = []
	for arm_art in opp.art.arm_arts:
		keys.append(arm_art.key)
		if not ARM_ORDER.has(arm_art.key):
			errs.append("모르는 묶음 %s" % arm_art.key)
			continue
		_near(errs, "%s 회전" % arm_art.key, arm_art.rotation_deg, ARM_ROTATION[arm_art.key])
		var names: Array = ARM_ORDER[arm_art.key]
		if arm_art.layers.size() != names.size():
			errs.append("%s 층 %d (기대 %d)" % [arm_art.key, arm_art.layers.size(), names.size()])
			continue
		for i in names.size():
			var layer: ArmLayer = arm_art.layers[i]
			var want: Array = ARM_MANIFEST[names[i]]
			if layer.texture == null or layer.texture.resource_path.get_file() != names[i] + ".png":
				errs.append("%s 층 %d: 그림이 %s가 아님" % [arm_art.key, i, names[i]])
				continue
			if Vector2i(layer.texture.get_size()) != want[0] or not layer.joint.is_equal_approx(want[1]) \
					or not layer.units_per_px.is_equal_approx(Vector2(0.3165, 0.3165)) or layer.part != want[2]:
				errs.append("%s: 크기 %s 관절 %s 배율 %s 부위 %d" % [names[i], Vector2i(layer.texture.get_size()),
						layer.joint, layer.units_per_px, layer.part])
	if keys.size() != 3 or not keys.has(&"armUp") or not keys.has(&"armThrust") or not keys.has(&"armAim"):
		errs.append("묶음 %s (기대 armUp, armThrust, armAim)" % str(keys))
	# 모든 상대의 포즈가 가리키는 팔 그림이 그 상대의 그림에 있다.
	for file in DirAccess.get_files_at("res://data/opponents/"):
		if not file.ends_with(".tres"):
			continue
		var res := load("res://data/opponents/" + file)
		if res is OpponentData:
			_check_arm_keys(errs, file, res as OpponentData)
	var atks := _attacks(opp)
	if (atks["big"] as AttackData).tell_pose.arm_art != &"armUp" or (atks["thrust"] as AttackData).strike_pose.arm_art != &"armThrust":
		errs.append("바르톨로: 큰 베기 예비 동작이 armUp, 찌르기 타격이 armThrust가 아님")
	if opp.idle_pose.arm_art != &"armAim":
		errs.append("바르톨로: 대기가 armAim이 아님")
	return "OK" if errs.is_empty() else ", ".join(errs)


func _check_arm_keys(errs: Array[String], file: String, opp: OpponentData) -> void:
	var have := [&"Arm"]
	if opp.art != null:
		for arm_art in opp.art.arm_arts:
			have.append(arm_art.key)
	var poses: Array[PoseData] = [opp.idle_pose, opp.stagger_pose, opp.complacent_pose]
	for atk: AttackData in _attacks_all(opp):
		poses.append(atk.tell_pose)
		poses.append(atk.strike_pose)
	for pose in poses:
		if pose != null and not have.has(pose.arm_art):
			errs.append("%s: 포즈의 팔 그림 %s가 그림에 없음" % [file, pose.arm_art])


func _attacks_all(opp: OpponentData) -> Array[AttackData]:
	var all: Array[AttackData] = []
	all.append_array(opp.attacks)
	for habit in opp.habits:
		if habit.response != null:
			all.append(habit.response)
	return all


## 지금 보이는 팔 그림: Arm(보통 팔) 또는 보이는 묶음의 이름. 보통 팔과 묶음이 함께 보이면 그 둘을 다 적는다.
func _shown_arm(view: Node) -> String:
	var shown: Array[String] = []
	if (view.get_node(^"Torso/Arm/Art") as CanvasItem).visible and (view.get_node(^"Torso/Arm/Hand") as CanvasItem).visible:
		shown.append("Arm")
	for key in [&"armUp", &"armThrust", &"armAim"]:
		var group := view.get_node_or_null(NodePath("Torso/Arm/" + String(key))) as CanvasItem
		if group != null and group.visible:
			shown.append(String(key))
	return "+".join(shown)


func _arm_is(errs: Array[String], what: String, view: Node, want: String) -> void:
	var got := _shown_arm(view)
	if got != want:
		errs.append("%s: 팔 그림 %s (기대 %s)" % [what, got, want])


func t69_arm_swap() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	var weapon: WeaponData = load(WEAPON_PATH)
	var atks := _attacks(opp)
	var view: OpponentView = (load(VIEW_PATH) as PackedScene).instantiate()
	_tree.root.add_child(view)
	view.anchor = Vector2(640, 446.4)
	var core := States.make_core(false)
	_t69_tell_recover(errs, view, core, opp, weapon, atks)
	_t69_return(errs, view, core, opp, weapon, atks)
	var flat := opp.duplicate() as OpponentData
	flat.strike_art_on_return = false
	_t69_return_off(errs, view, core, flat, weapon, atks)
	_t69_colors(errs, view, core, opp, weapon, atks)
	_t69_rest(errs, view, core, opp, weapon, atks)
	var before := view.get_node(^"Torso/Arm").get_child_count()
	view.setup(opp, weapon, false)
	view.setup(opp, weapon, false)
	if view.get_node(^"Torso/Arm").get_child_count() != before:
		errs.append("같은 그림으로 setup을 두 번 부르니 Arm의 자식 수가 %d → %d" % [before, view.get_node(^"Torso/Arm").get_child_count()])
	view.free()
	return "OK" if errs.is_empty() else ", ".join(errs)


# 확인 1~3: 대기, 큰 베기 예비 동작, 찌르기의 예비 동작·회수, 큰 베기 회수.
func _t69_tell_recover(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData,
		weapon: WeaponData, atks: Dictionary) -> void:
	var big: AttackData = atks["big"]
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE), 0.0)
	_arm_is(errs, "대기", view, "armAim")
	for p in [0.1, 0.5, 0.9999]:
		view.setup(opp, weapon, false)
		view.update_view(core, States.put(core, DT.OpponentState.TELL, big, p, DT.Distance.ENGAGE), 0.0)
		_arm_is(errs, "큰 베기 p%.4f" % p, view, "armUp")
		var want := OpponentMotion.tell_pose(big, opp.idle_pose, p, big.tell_time, weapon.parry_window, opp)
		_near(errs, "큰 베기 p%.4f 팔" % p, _deg(view, ^"Torso/Arm"), want.arm_deg)
	_near(errs, "armUp 회전", _deg(view, ^"Torso/Arm/armUp"), 180.0)
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.TELL, atks["thrust"], 0.9999, DT.Distance.ENGAGE), 0.0)
	_arm_is(errs, "찌르기 p0.9999", view, "Arm")
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.RECOVERY, atks["thrust"], 0.5, DT.Distance.ENGAGE), 0.0)
	_arm_is(errs, "찌르기 회수", view, "armThrust")
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.RECOVERY, big, 0.5, DT.Distance.ENGAGE), 0.0)
	_arm_is(errs, "큰 베기 회수", view, "Arm")


# 앞 상태를 정해 한 번 그린 뒤 대기로 넘겨 dt초 뒤를 그린다. start_early면 대기의 시작이 앞 상태의 끝보다 0.1초 앞이다.
func _to_idle(view: OpponentView, core: DuelCore, state: int, atk: AttackData, p: float, dt: float,
		start_early := false) -> void:
	view.update_view(core, States.put(core, state, atk, p, DT.Distance.ENGAGE), 0.0)
	var start := core.brain.state_end - (0.1 if start_early else 0.0)
	view.update_view(core, States.to_idle(core, start, start + dt), 0.0)


# 확인 4·5: 돌아감 동안은 나온 국면의 그림, 끝나면 대기의 그림(결정 285).
func _t69_return(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData,
		weapon: WeaponData, atks: Dictionary) -> void:
	var after := opp.return_time + 0.05
	var cases := [
		["찌르기 회수 → 대기 0.1", DT.OpponentState.RECOVERY, atks["thrust"], 0.99, 0.1, false, "armThrust"],
		["찌르기 회수 → 대기 끝", DT.OpponentState.RECOVERY, atks["thrust"], 0.99, after, false, "armAim"],
		["막힌 찌르기 → 대기 0.1", DT.OpponentState.TELL, atks["thrust"], 0.9999, 0.1, false, "armThrust"],
		["사라진 찌르기 → 대기 0.1", DT.OpponentState.TELL, atks["thrust"], 0.5, 0.1, true, "Arm"],
		["사라진 큰 베기 → 대기 0.1", DT.OpponentState.TELL, atks["big"], 0.5, 0.1, true, "armUp"],
		["사라진 큰 베기 → 대기 끝", DT.OpponentState.TELL, atks["big"], 0.5, after, true, "armAim"],
	]
	for c in cases:
		view.setup(opp, weapon, false)
		_to_idle(view, core, c[1], c[2], c[3], c[4], c[5])
		_arm_is(errs, c[0], view, c[6])


# 확인 5의 끝: strike_art_on_return 거짓이면 섞는 중도 대기의 그림이고, 회수는 그대로 뻗은 팔.
func _t69_return_off(errs: Array[String], view: OpponentView, core: DuelCore, flat: OpponentData,
		weapon: WeaponData, atks: Dictionary) -> void:
	var cases := [
		[DT.OpponentState.RECOVERY, atks["thrust"], 0.99, false],
		[DT.OpponentState.TELL, atks["thrust"], 0.9999, false],
		[DT.OpponentState.TELL, atks["big"], 0.5, true],
	]
	for c in cases:
		view.setup(flat, weapon, false)
		core.opponent_data = flat
		_to_idle(view, core, c[0], c[1], c[2], 0.1, c[3])
		_arm_is(errs, "갈래 끔: 대기 0.1", view, "armAim")
	view.setup(flat, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.RECOVERY, atks["thrust"], 0.5, DT.Distance.ENGAGE), 0.0)
	_arm_is(errs, "갈래 끔: 찌르기 회수", view, "armThrust")
	core.opponent_data = load(OPPONENT_PATH)


# 확인 6·7: 뻗은 팔의 층 재질이 부위를 따른다. 칼 층에는 재질이 없다.
func _t69_colors(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData,
		weapon: WeaponData, atks: Dictionary) -> void:
	view.setup(opp, weapon, false)
	var t := States.put(core, DT.OpponentState.RECOVERY, atks["thrust"], 0.5, DT.Distance.ENGAGE)
	view.update_view(core, t, 0.0)
	var group := view.get_node(^"Torso/Arm/armThrust")
	var sleeve := (group.get_child(0) as CanvasItem).material as ShaderMaterial
	var fist := (group.get_child(1) as CanvasItem).material as ShaderMaterial
	if sleeve == null or fist == null:
		errs.append("뻗은 팔의 소매·주먹 층에 재질이 없음")
		return
	_tint_is(errs, "뻗은 팔 소매", sleeve, OpponentView.COLOR_RECOVERY, 0.8)
	_tint_is(errs, "뻗은 팔 주먹", fist, OpponentView.COLOR_RECOVERY, 0.8)
	for i in [2, 3]:
		if (group.get_child(i) as CanvasItem).material != null:
			errs.append("뻗은 팔의 칼 층 %d에 재질이 있음" % i)
	view.set_target(DT.Part.SWORD_ARM)
	if not sleeve.get_shader_parameter(&"outline_on") or fist.get_shader_parameter(&"outline_on"):
		errs.append("팔을 노렸는데 소매 층만 테두리가 아님")
	view.set_target(-1)
	view.on_event(_attack_event(DT.AttackResult.GRAZE, DT.Part.SWORD_HAND))
	view.update_view(core, t, 0.01)
	_tint_is(errs, "닿은 주먹 층", fist, OpponentView.COLOR_TOUCHED, 1.0)
	_tint_is(errs, "닿지 않은 소매 층", sleeve, OpponentView.COLOR_RECOVERY, 0.8)


# 확인 8(계획 030c 결정 285): 쉬는 상태는 그 포즈의 그림, 쉬는 상태끼리 넘어갈 때는 섞는 동안 보이던 그림.
func _t69_rest(errs: Array[String], view: OpponentView, core: DuelCore, opp: OpponentData,
		weapon: WeaponData, atks: Dictionary) -> void:
	var half := opp.return_time * 0.5
	var done := opp.return_time + 0.05
	view.setup(opp, weapon, false)
	_arm_is(errs, "setup 직후", view, "armAim")
	view.update_view(core, States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE, false), 0.0)
	_arm_is(errs, "setup 뒤 첫 대기 0.1", view, "armAim")
	view.update_view(core, States.put(core, DT.OpponentState.RECOVERY, atks["thrust"], 0.5, DT.Distance.ENGAGE), 0.0)
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE, false), 0.0)
	_arm_is(errs, "찌르기 회수 뒤 다시 setup, 대기 0.1", view, "armAim")
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, States.COMPLACENT, null, 0.0, DT.Distance.ENGAGE), 0.0)
	_arm_is(errs, "방심", view, "Arm")
	view.update_view(core, States.idle_at(core, States.COMPLACENT_NOW, States.COMPLACENT_NOW + half), 0.0)
	_arm_is(errs, "방심 → 대기 섞는 중", view, "Arm")
	view.update_view(core, States.idle_at(core, States.COMPLACENT_NOW, States.COMPLACENT_NOW + done), 0.0)
	_arm_is(errs, "방심 → 대기 끝", view, "armAim")
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.STAGGER, null, 0.0, DT.Distance.ENGAGE), 0.0)
	_arm_is(errs, "무너짐", view, "Arm")
	# 방심의 시작은 alert_since + complacent_time이다(결정 258). put의 대기는 alert_since 0, 지금 10.
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE), 0.0)
	view.update_view(core, States.idle_at(core, 0.0, opp.complacent_time + half), 0.0)
	_arm_is(errs, "대기 → 방심 섞는 중", view, "armAim")
	view.update_view(core, States.idle_at(core, 0.0, opp.complacent_time + done), 0.0)
	_arm_is(errs, "대기 → 방심 끝", view, "Arm")
	view.setup(opp, weapon, false)
	view.update_view(core, States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE), 0.0)
	view.update_view(core, States.idle_at(core, States.NOW + 0.5, States.NOW + 0.5 + half), 0.0)
	_arm_is(errs, "대기 중 경계를 다시 세움", view, "armAim")


func _attack_event(result: int, part: int) -> Dictionary:
	return {"type": DuelRecord.ATTACK, "result": result, "part": part, "dodged": false, "rash": false, "posture_gain": 0}


func t70_hand_outline() -> String:
	var errs: Array[String] = []
	var opp: OpponentData = load(OPPONENT_PATH)
	var weapon: WeaponData = load(WEAPON_PATH)
	var view: OpponentView = (load(VIEW_PATH) as PackedScene).instantiate()
	_tree.root.add_child(view)
	var core := States.make_core(false)
	view.setup(opp, weapon, false)
	var hand := view.get_node(^"Torso/Arm/Hand")
	var names: Array[String] = []
	for child in hand.get_children():
		names.append(String(child.name))
	# 칼자루는 손가락 밑, 손의 윤곽선은 맨 위(결정 286).
	if ", ".join(names) != "Sword, Art, Outline":
		errs.append("Hand의 자식 차례 %s" % str(names))
	var line := hand.get_node_or_null(^"Outline") as Line2D
	if line == null:
		view.free()
		errs.append("Outline이 Line2D가 아님")
		return ", ".join(errs)
	if not line.closed or line.points.size() < 8 or not is_equal_approx(line.width, OpponentView.OUTLINE_UNITS):
		errs.append("윤곽선: closed %s 점 %d 굵기 %.2f" % [line.closed, line.points.size(), line.width])
	var pa := opp.art.hand
	var poly := PackedVector2Array()
	for p in pa.outline:
		poly.append((p - pa.joint) * pa.units_per_px)
	for p in line.points:
		if Geometry2D.is_point_in_polygon(p, poly):
			errs.append("윤곽선의 점 %s가 손 그림 안에 있음(바깥 윤곽선이어야 한다)" % p)
			break
	view.set_target(DT.Part.SWORD_HAND)
	var hand_mat := (hand.get_node(^"Art") as CanvasItem).material as ShaderMaterial
	if not line.visible or hand_mat.get_shader_parameter(&"outline_on"):
		errs.append("손을 노렸는데 윤곽선 %s, 손 재질의 안쪽 테두리 %s" % [line.visible, hand_mat.get_shader_parameter(&"outline_on")])
	view.update_view(core, States.put(core, DT.OpponentState.IDLE, null, 0.0, DT.Distance.ENGAGE), 0.0)
	var aim := view.get_node(^"Torso/Arm/armAim")
	var aim_line := aim.get_child(aim.get_child_count() - 1) as Line2D
	if aim_line == null or not aim_line.is_visible_in_tree():
		errs.append("대기에서 손을 노렸는데 겨눈 팔 주먹의 윤곽선이 보이지 않음")
	view.update_view(core, States.put(core, DT.OpponentState.TELL, _attacks(opp)["big"], 0.5, DT.Distance.ENGAGE), 0.0)
	var group := view.get_node(^"Torso/Arm/armUp")
	var fist_line := group.get_child(group.get_child_count() - 1) as Line2D
	if fist_line == null or not fist_line.is_visible_in_tree():
		errs.append("큰 베기의 예비 동작에서 손을 노렸는데 든 팔 주먹의 윤곽선이 보이지 않음")
	view.set_target(-1)
	if line.visible or (fist_line != null and fist_line.visible) or (aim_line != null and aim_line.visible):
		errs.append("조준을 뗐는데 윤곽선이 보임")
	# 윤곽선이 없는 그림(테스트가 만든 상대)도 오류 없이 점 0.
	var bare := opp.duplicate() as OpponentData
	var art := opp.art.duplicate() as OpponentArt
	var plain_hand := PartArt.new()
	plain_hand.texture = pa.texture
	art.hand = plain_hand
	bare.art = art
	view.setup(bare, weapon, false)
	if line.points.size() != 0:
		errs.append("윤곽선 없는 손인데 점 %d" % line.points.size())
	view.free()
	return "OK" if errs.is_empty() else ", ".join(errs)
