extends RefCounted
## T161: 6단계 완료 기준의 수 지킴(계획 051, 결정 807). 데이터만 읽고 바닥(>=)만 본다 — 상한은 없다.
## 기준의 원본은 039 결정 571의 여섯 줄이다. 의뢰는 연습 화면과 같은 길(load_tree)로 모은다.

const COMMISSION_DIR := "res://data/commissions"
const OPPONENT_DIR := "res://data/opponents/"
const SCHEDULE_PATH := "res://data/day_schedule.tres"
## 039가 셈한 앞의 다섯 검술. 이 밖의 이름이 새 검술이다.
## 053b가 그림을 그리면 비운다: 아직 바르톨로의 몸을 빌린 상대(결정 842).
const ART_PENDING := ["opponent_08.tres"]
const OLD_STYLES := ["이어 베기", "휩쓸기", "뛰어드는 찌르기", "층층 찌르기", "엇박 찌르기"]
const NEW_FRAMES := ["pair_hatter", "court_beehive", "noble_baker", "spar"]


func list(_tree: SceneTree) -> Array:
	return [
		{"id": "T161", "name": "6단계 완료 기준의 수: 의뢰 18 · 의뢰인 13 · 상대 7과 저마다의 검술 · 두 역할 인물 2 · 새 검술 2 · 이레의 새 틀 넷", "fn": t161_stage6_counts},
	]


func cleanup() -> void:
	pass


func t161_stage6_counts() -> String:
	var errs: Array[String] = []
	var commissions := CommissionLibrary.load_tree(COMMISSION_DIR)
	var opponents := _opponents()
	_check_commissions(errs, commissions)
	_check_opponents(errs, opponents)
	_check_dual_roles(errs, commissions, opponents)
	_check_styles(errs, opponents)
	_check_week(errs)
	return "OK" if errs.is_empty() else ", ".join(errs)


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _opponents() -> Array[OpponentData]:
	var out: Array[OpponentData] = []
	var files := Array(DirAccess.get_files_at(OPPONENT_DIR))
	files.sort()
	for file: String in files:
		var name := file.trim_suffix(".remap")
		if name.get_extension() != "tres" or not name.begins_with("opponent_"):
			continue
		var data := load(OPPONENT_DIR + name) as OpponentData
		if data != null:
			out.append(data)
	return out


## ① 의뢰 18 이상. ② 서로 다른 client_name 13 이상.
func _check_commissions(errs: Array[String], commissions: Array[Commission]) -> void:
	_expect(errs, commissions.size() >= 18, "[①] 의뢰 %d (기대 18 이상)" % commissions.size())
	var names := {}
	for c in commissions:
		names[c.client_name] = true
	_expect(errs, names.size() >= 13, "[②] 의뢰인 이름 %d (기대 13 이상)" % names.size())


## ③ 상대 7 이상, 저마다 style_name 서로 다름 · 2단 이상 · 1단 고유 검술 · 제 그림.
func _check_opponents(errs: Array[String], opponents: Array[OpponentData]) -> void:
	_expect(errs, opponents.size() >= 7, "[③] 상대 %d (기대 7 이상)" % opponents.size())
	var styles := {}
	for opp in opponents:
		var tag := opp.resource_path.get_file()
		_expect(errs, not opp.style_name.is_empty(), "[③] %s의 style_name이 비었다" % tag)
		_expect(errs, not styles.has(opp.style_name), "[③] %s의 검술 이름 '%s'이 겹친다" % [tag, opp.style_name])
		styles[opp.style_name] = true
		_expect(errs, opp.tier_count() >= 2, "[③] %s의 단 수 %d (기대 2 이상)" % [tag, opp.tier_count()])
		var has_signature := false
		for attack in opp.attacks:
			if attack != null and attack.signature:
				has_signature = true
		_expect(errs, has_signature, "[③] %s의 1단에 고유 검술(signature)이 없다" % tag)
		_expect(errs, opp.art != null, "[③] %s의 art가 비었다" % tag)
		if ART_PENDING.has(tag):
			print("  INFO %s는 아직 빌린 몸이다(ART_PENDING)" % tag)
		elif opp.art != null and opp.display_name != "바르톨로":
			_expect(errs,opp.art.resource_path.get_file() != "bartolo_art.tres", "[③] %s가 바르톨로의 몸을 빌려 쓴다" % tag)


## ④ client_name이 상대의 display_name으로 끝나는 상대 둘 이상("포함"이 아니다 — 이네스는 바르톨로의 누이다).
func _check_dual_roles(errs: Array[String], commissions: Array[Commission], opponents: Array[OpponentData]) -> void:
	var hit := {}
	for opp in opponents:
		for c in commissions:
			if c.client_name.ends_with(opp.display_name):
				hit[opp.display_name] = hit.get(opp.display_name, PackedStringArray()) + PackedStringArray([c.resource_path.get_file()])
	for who: String in hit:
		print("  INFO 두 역할: %s — 의뢰 %s" % [who, ", ".join(hit[who])])
	_expect(errs, hit.size() >= 2, "[④] 의뢰인이면서 상대인 인물 %d (기대 2 이상. 맞은 상대 %s)" % [hit.size(), str(hit.keys())])


## ⑤ 층층 · 엇박이 있고 039의 앞 다섯 밖의 검술이 둘 이상.
func _check_styles(errs: Array[String], opponents: Array[OpponentData]) -> void:
	var has_tier_style := false
	var has_offbeat := false
	var fresh := 0
	for opp in opponents:
		if opp.style_name.contains("층층"):
			has_tier_style = true
		if opp.style_name.contains("엇박"):
			has_offbeat = true
		if not OLD_STYLES.has(opp.style_name):
			fresh += 1
	_expect(errs, has_tier_style, "[⑤] '층층' 검술이 없다")
	_expect(errs, has_offbeat, "[⑤] '엇박' 검술이 없다")
	_expect(errs, fresh >= 2, "[⑤] 새 검술 %d (기대 2 이상)" % fresh)


## ⑥ 일곱 날이 서로 다른 파일이고 새 틀 넷의 의뢰가 저마다 어느 날의 목록에 있다.
func _check_week(errs: Array[String]) -> void:
	var schedule := load(SCHEDULE_PATH) as DaySchedule
	if schedule == null:
		errs.append("[⑥] 일정을 읽지 못했다")
		return
	var paths := {}
	for day in schedule.days:
		if day != null:
			paths[day.resource_path] = true
	_expect(errs, schedule.days.size() >= 7 and paths.size() >= 7, "[⑥] 서로 다른 날 %d (기대 7 이상)" % paths.size())
	for stem: String in NEW_FRAMES:
		var found := false
		for day in schedule.days:
			if day == null:
				continue
			for c in day.commissions:
				if c != null and c.resource_path.get_file().get_basename() == stem:
					found = true
		_expect(errs, found, "[⑥] 새 틀 '%s'가 어느 날의 목록에도 없다" % stem)
