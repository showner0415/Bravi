extends RefCounted
## T93: 셋째 상대 로렌초(계획 037). 판정 값과 공격이 바르톨로와 같다(결정 438), 그림 데이터가 온전하다(결정 442), 아직 어느 의뢰도 걸지 않는다(결정 443).

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const LORENZO_ART_PATH := "res://data/opponents/lorenzo_art.tres"
const LORENZO_ART_DIR := "res://assets/art/opponents/lorenzo/"
## 다를 수 있는 칸: 이름·그림·포즈(표시만이고 판정에 쓰지 않는다. 결정 291·438). 공격 목록은 빼지 않는다(037b가 바꿀 때 좁힌다).
const FREE_FIELDS := ["display_name", "art", "idle_pose", "stagger_pose", "complacent_pose",
	"tell_pose", "hold_arm_deg", "strike_pose", "recover_arm_deg"]
const PARTS := ["legs", "torso", "head", "head_oops", "head_dizzy", "hat", "feather", "arm", "hand", "sword"]
## 자른 그림의 크기(작업 4·5의 출력).
const SIZES := {
	"head": Vector2i(235, 265), "head_oops": Vector2i(235, 265), "head_dizzy": Vector2i(234, 265), "hat": Vector2i(348, 105),
	"feather": Vector2i(166, 57), "torso": Vector2i(206, 367), "legs": Vector2i(239, 331), "arm": Vector2i(90, 259),
	"hand": Vector2i(90, 81), "sword": Vector2i(133, 388), "arm_up_sword": Vector2i(154, 554), "arm_up": Vector2i(104, 268),
	"arm_up_fist": Vector2i(131, 140), "arm_thrust": Vector2i(250, 136), "arm_thrust_fist": Vector2i(250, 236), "arm_thrust_sword": Vector2i(257, 261),
	"arm_thrust_blade": Vector2i(69, 66), "arm_aim": Vector2i(177, 216), "arm_aim_fist": Vector2i(177, 181), "arm_aim_sword": Vector2i(187, 187),
	"arm_aim_blade": Vector2i(109, 116),
}

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T93", "name": "셋째 상대: 판정 값과 공격이 바르톨로와 같다, 그림 데이터가 온전하다, 아직 어느 의뢰도 걸지 않는다", "fn": t93_third_opponent},
	]


func cleanup() -> void:
	_tree = null


## 스크립트 칸을 하나씩 견준다. 자원은 같은 규칙으로 들어가 견주고, 배열은 원소마다 견준다.
func _compare(a: Variant, b: Variant, path: String, errs: Array[String]) -> void:
	if a is Resource and b is Resource:
		for prop in (a as Resource).get_property_list():
			if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var field: String = prop["name"]
			if FREE_FIELDS.has(field):
				continue
			_compare((a as Resource).get(field), (b as Resource).get(field), path + "." + field, errs)
	elif a is Array and b is Array:
		if (a as Array).size() != (b as Array).size():
			errs.append("%s: 원소 %d개 (바르톨로 %d개)" % [path, (b as Array).size(), (a as Array).size()])
			return
		for i in (a as Array).size():
			_compare(a[i], b[i], "%s[%d]" % [path, i], errs)
	elif typeof(a) != typeof(b) or a != b:
		errs.append("%s: %s (바르톨로 %s)" % [path, str(b), str(a)])


func _check_art(art: OpponentArt, errs: Array[String]) -> void:
	var bartolo := (load(BARTOLO_PATH) as OpponentData).art
	for part_name: String in PARTS:
		var part := art.get(part_name) as PartArt
		if part == null or part.texture == null or not part.texture.resource_path.begins_with(LORENZO_ART_DIR):
			errs.append("그림 %s: 없거나 로렌초의 폴더가 아님" % part_name)
		elif part.units_per_px.x <= 0.0 or part.units_per_px.y <= 0.0:
			errs.append("그림 %s: units_per_px %s" % [part_name, part.units_per_px])
	if art.arm_arts.size() != bartolo.arm_arts.size():
		errs.append("따로 그린 팔 %d개 (바르톨로 %d개)" % [art.arm_arts.size(), bartolo.arm_arts.size()])
		return
	for i in art.arm_arts.size():
		var mine := art.arm_arts[i]
		var his := bartolo.arm_arts[i]
		if mine.key != his.key or not is_equal_approx(mine.rotation_deg, his.rotation_deg) or mine.layers.size() != his.layers.size():
			errs.append("팔 %s: 키·회전·층 수가 바르톨로(%s)와 다름" % [mine.key, his.key])
			continue
		for k in mine.layers.size():
			var layer := mine.layers[k]
			if layer.part != his.layers[k].part or layer.texture == null or not layer.texture.resource_path.begins_with(LORENZO_ART_DIR):
				errs.append("팔 %s 층 %d: part·그림이 어긋남" % [mine.key, k])
			elif (layer.part == 4) != (layer.outline.size() >= 6):
				errs.append("팔 %s 층 %d: 주먹의 윤곽선이 없거나 주먹이 아닌데 있음" % [mine.key, k])
	if art.hand.outline.size() < 6:
		errs.append("손의 윤곽선이 없음")
	for file: String in SIZES:
		var tex := load(LORENZO_ART_DIR + file + ".png") as Texture2D
		if tex == null or Vector2i(tex.get_size()) != SIZES[file]:
			errs.append("%s.png의 크기 %s (기대 %s)" % [file, Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO, SIZES[file]])


func t93_third_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var lorenzo := load(LORENZO_PATH) as OpponentData
	if lorenzo == null or lorenzo.art == null:
		return "opponent_03.tres나 그 그림이 없음"
	if lorenzo.display_name != "로렌초" or lorenzo.display_name == bartolo.display_name:
		errs.append("이름 '%s'" % lorenzo.display_name)
	if lorenzo.art.resource_path != LORENZO_ART_PATH:
		errs.append("그림 데이터 %s" % lorenzo.art.resource_path)
	_compare(bartolo, lorenzo, "opponent", errs)
	_check_art(lorenzo.art, errs)
	var all: Array[Commission] = CommissionLibrary.load_all("res://data/commissions")
	all.append_array(CommissionLibrary.load_all("res://data/commissions/variants"))
	for c in all:
		if c.opponent != null and c.opponent.resource_path == LORENZO_PATH:
			errs.append("%s가 셋째를 검" % c.resource_path.get_file())
	return "OK" if errs.is_empty() else ", ".join(errs)
