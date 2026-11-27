extends RefCounted
## T78: 둘째 상대 브루노(계획 035). 공격 밖의 판정 값이 바르톨로와 같다(결정 357), 그림 데이터가 온전하다(결정 362), 오르솔라의 의뢰가 건다(결정 363).

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const BRUNO_ART_DIR := "res://assets/art/opponents/bruno/"
const LEGS_ONLY_PATH := "res://data/commissions/variants/legs_only.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const SPAR_PATH := "res://data/commissions/spar.tres"
const USURER_PATH := "res://data/commissions/variants/first_blood_usurer.tres"
## 다를 수 있는 칸: 이름·그림·포즈(표시만이고 판정에 쓰지 않는다. 결정 291·357).
const FREE_FIELDS := ["display_name", "art", "idle_pose", "stagger_pose", "complacent_pose",
	"tell_pose", "hold_arm_deg", "strike_pose", "recover_arm_deg"]
## 공격 목록은 상대마다 다르다(바르톨로는 이어 베기, 브루노는 휩쓸기. 결정 425). 그 밖의 판정 값만 견준다.
## 검술의 단과 갈래 이름도 공격 목록과 같은 검술 데이터다(계획 040).
const ATTACK_FIELDS := ["attacks", "style_name", "tiers"]
const PARTS := ["legs", "torso", "head", "head_oops", "head_dizzy", "hat", "feather", "arm", "hand", "sword"]
## 자른 그림의 크기(작업 6의 출력).
const SIZES := {
	"head": Vector2i(201, 206), "head_oops": Vector2i(201, 206), "head_dizzy": Vector2i(201, 206), "hat": Vector2i(192, 85),
	"feather": Vector2i(141, 45), "torso": Vector2i(284, 321), "legs": Vector2i(239, 294), "arm": Vector2i(83, 208),
	"hand": Vector2i(81, 72), "sword": Vector2i(121, 356), "arm_up_sword": Vector2i(151, 558), "arm_up": Vector2i(114, 287),
	"arm_up_fist": Vector2i(132, 117), "arm_thrust": Vector2i(268, 152), "arm_thrust_fist": Vector2i(268, 217), "arm_thrust_sword": Vector2i(275, 277),
	"arm_thrust_blade": Vector2i(76, 63), "arm_aim": Vector2i(167, 237), "arm_aim_fist": Vector2i(167, 165), "arm_aim_sword": Vector2i(187, 197),
	"arm_aim_blade": Vector2i(106, 136),
}

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T78", "name": "둘째 상대: 공격 밖의 판정 값이 바르톨로와 같다, 그림 데이터가 온전하다, 오르솔라의 의뢰가 건다", "fn": t78_second_opponent},
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
			if FREE_FIELDS.has(field) or ATTACK_FIELDS.has(field):
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
		if part == null or part.texture == null or not part.texture.resource_path.begins_with(BRUNO_ART_DIR):
			errs.append("그림 %s: 없거나 브루노의 폴더가 아님" % part_name)
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
			if layer.part != his.layers[k].part or layer.texture == null or not layer.texture.resource_path.begins_with(BRUNO_ART_DIR):
				errs.append("팔 %s 층 %d: part·그림이 어긋남" % [mine.key, k])
			elif (layer.part == 4) != (layer.outline.size() >= 6):
				errs.append("팔 %s 층 %d: 주먹의 윤곽선이 없거나 주먹이 아닌데 있음" % [mine.key, k])
	if art.hand.outline.size() < 6:
		errs.append("손의 윤곽선이 없음")
	for file: String in SIZES:
		var tex := load(BRUNO_ART_DIR + file + ".png") as Texture2D
		if tex == null or Vector2i(tex.get_size()) != SIZES[file]:
			errs.append("%s.png의 크기 %s (기대 %s)" % [file, Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO, SIZES[file]])


func t78_second_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var bruno := load(BRUNO_PATH) as OpponentData
	if bruno == null or bruno.art == null:
		return "opponent_02.tres나 그 그림이 없음"
	if bruno.display_name != "브루노" or bruno.display_name == bartolo.display_name:
		errs.append("이름 '%s'" % bruno.display_name)
	_compare(bartolo, bruno, "opponent", errs)
	_check_art(bruno.art, errs)
	var all: Array[Commission] = CommissionLibrary.load_all("res://data/commissions")
	all.append_array(CommissionLibrary.load_all("res://data/commissions/variants"))
	for c in all:
		var want: String = BARTOLO_PATH
		if c.resource_path == LEGS_ONLY_PATH:
			want = BRUNO_PATH
		elif c.resource_path == USURER_PATH:
			want = LORENZO_PATH
		elif c.resource_path == SPAR_PATH:
			want = AGOSTINO_PATH
		var got: String = c.opponent.resource_path if c.opponent != null else "(없음)"
		if got != want:
			errs.append("%s의 상대 %s (기대 %s)" % [c.resource_path.get_file(), got, want])
	var legs := load(LEGS_ONLY_PATH) as Commission
	if not legs.dialogue.begins_with("브루노가 ") or legs.dialogue.contains("바르톨로"):
		errs.append("오르솔라의 사연이 브루노를 말하지 않음")
	return "OK" if errs.is_empty() else ", ".join(errs)
