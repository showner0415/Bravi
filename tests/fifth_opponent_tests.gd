extends RefCounted
## T126~T129: 다섯째 상대 아고스티노(계획 042, 결정 636~647). 데이터의 틀·엇박의 길·가방, 박자를 읽는 판, 표시와 연습 화면.
## T129(그림 데이터, 2부)는 맨 아래다. 값(공격 수·가중치·길의 간격과 세는 말·가방·from_day)은 결정 642·643의 표를 손으로 적은 기대다.
## 결정 645의 고치는 차례가 옮길 수 있는 값(찌르기의 가중치·기본 베기의 빈틈)은 이 파일의 상수 한두 곳이 함께 옮기는 기대다.
## 도우미는 fourth_opponent_tests.gd에서 빌린다(그 파일은 고치지 않는다. 빌리는 도우미는 _tree를 쓰지 않는다).

const Fourth := preload("res://tests/fourth_opponent_tests.gd")
const Bot := preload("res://tests/duel_bots.gd")
const Plain := preload("res://tests/plain_opponent.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")

const AGOSTINO_PATH := "res://data/opponents/opponent_05.tres"
const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const COMMISSION_DIR := "res://data/commissions"
const OFFBEAT_FILE := "res://data/attacks/offbeat_thrust.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
const STYLE_NAME := "엇박 찌르기"
const SHORT_BEAT := 0.6
const LONG_BEAT := 1.3
const ROOT_TELL := 0.9
const OFFBEAT_RECOVERY := 0.55
## 두 틱 + 여유: 타격 사이의 간격은 판정 틱에 얹힌다.
const TIME_TOL := 0.04
## 고유 색(결정 640): 물빛.
const SIG_COLOR := Color(0.5, 0.95, 1.0, 1.0)
const SIG_WEIGHTS: Array[float] = [2.0, 2.0, 2.0, 3.0, 3.0, 4.0]
const BAG_SIZES: Array[int] = [5, 5, 6, 7, 8, 9]
const FROM_DAYS: Array[int] = [6, 8, 10, 12, 14]
## 찌르기의 가중치와 기본 베기(결정 641 · 645의 고치는 차례가 옮길 수 있다).
const BASIC_WEIGHTS := {"찌르기": 1.0, "왼쪽 베기": 1.0, "오른쪽 베기": 1.0}
## 좌우 베기의 끝 빈틈(결정 645의 값 고침 둘째 — 바르톨로의 0.55보다 늦게 돌아온다. 찌르기는 바르톨로와 같다).
const CUT_RECOVERY := 0.75
## 길의 이름: 걸음의 간격 차례(S 짧은 박 0.6 · L 긴 박 1.3). 뿌리는 늘 짧·긴이다(결정 642의 표).
const ROUTE_HINTS := {
	"SL": "하나, 둘 — 둘 반",
	"LS": "하나 — 둘, 둘 반",
	"LL": "하나 — 둘 — 둘 반",
	"SSL": "하나, 둘, 셋 — 셋 반",
	"LSS": "하나 — 둘, 셋, 셋 반",
	"SLS": "하나, 둘 — 셋, 셋 반",
}
const TIER_ROUTES := [
	["SL", "LS"],
	["SL", "LS", "LL"],
	["SL", "LS", "LL"],
	["SL", "LS", "LL", "SSL", "LSS"],
	["SL", "LS", "LL", "SSL", "LSS"],
	["SL", "LS", "LL", "SSL", "LSS", "SLS"],
]
const BASE_NAMES := ["찌르기", "왼쪽 베기", "오른쪽 베기", "엇박 찌르기"]
const TIER_NAMES := [
	["찌르기", "왼쪽 베기", "오른쪽 베기", "엇박 찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "엇박 찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "엇박 찌르기", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "엇박 찌르기", "겹찌르기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "엇박 찌르기", "겹찌르기", "찌르고 베기"],
	["찌르기", "왼쪽 베기", "오른쪽 베기", "엇박 찌르기", "겹찌르기", "찌르고 베기"],
]
## 4박 길의 넷째 고리는 첫 고리의 자리에서 36 x 3 아래다(같은 칸이 되풀이되면 비킨다).
const FOURTH_RING_SHIFT := 108.0

var _tree: SceneTree
var _f: Fourth = Fourth.new()
var _select: Node = null


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T126", "name": "다섯째 상대: 판정 값이 바르톨로와 같다, 가운뎃줄 한 줄, 엇박의 길과 세는 말·단·가방, 하루에는 서지 않는다", "fn": t126_fifth_opponent},
		{"id": "T127", "name": "엇박의 판: 쥔 손과 박자를 맞춘 손의 빈틈, 타격의 시각, 멈칫에 속는 손, 같은 씨앗, 박자 봇의 뜻", "fn": t127_offbeat_duel},
		{"id": "T128", "name": "표시와 연습 화면: 박자 고리의 shape·wait와 세는 말, 네 박의 넷째 고리, 연습의 다섯째 칸", "fn": t128_marks_and_practice},
		{"id": "T129", "name": "그림 데이터: 스물한 장과 팔 셋, 모자 없는 꼭대기(넷 가운데 가장 낮다)·머리 가운데의 자·모자 쓴 꼭대기·발끝, 다리 안의 지팡이", "fn": t129_agostino_art},
	]


func cleanup() -> void:
	_free_select()
	_tree = null


# ================================================================ 도우미

func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.001


## 길의 이름: 걸음의 간격 차례("SL" 등). 0.6 · 1.3이 아닌 간격은 ?다.
func _beat_key(route: AttackData) -> String:
	var key := ""
	for step in route.chain:
		var atk := step as AttackData
		if _near(atk.tell_time, SHORT_BEAT):
			key += "S"
		elif _near(atk.tell_time, LONG_BEAT):
			key += "L"
		else:
			key += "?"
	return key


## 그 단의 고유 공격에서 키(간격 차례)가 key인 길(없으면 null).
func _route_by_key(attacks: Array, key: String) -> AttackData:
	var roots: Array[AttackData] = _f._signature_roots(attacks)
	for root in roots:
		var routes: Array[AttackData] = _f._routes(root)
		for route in routes:
			if _beat_key(route) == key:
				return route
	return null


func _stop_attacks(count: int) -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.ATTACK).size() >= count


## _play와 같되 0초의 한 걸음 뒤 hook(core)을 한 번 부른다(상대의 자세를 깎아 두는 데 쓴다).
func _play_hook(opp: OpponentData, cfg: Dictionary, stop: Callable, until: float, hook: Callable) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(_f._rules(), weapon, opp, rng, none, false)
	var bot := Bot.new(core, cfg)
	core.step(1)
	hook.call(core)
	while not core.ended and core.time < until:
		core.tick(DELTA)
		bot.update()
		if stop.call(core):
			break
	return core


## 받아치기 설정: 막힘·패리 직후(delay초 뒤) aim으로 한 번 친다.
func _counter_cfg(aim: Array, delay: float, extra: Dictionary) -> Dictionary:
	var cfg: Dictionary = extra.duplicate()
	cfg["counter_fn"] = func(_ev: Dictionary) -> Variant: return aim
	if delay > 0.0:
		cfg["counter_delay"] = delay
	return cfg


## 모든 타격을 패리하려는 봇(error초만큼 어긋난다. 키를 주지 않으려면 with_error를 거짓으로).
func _parry_cfg(error: float, with_error: bool) -> Dictionary:
	var cfg := {}
	cfg["guard_fn"] = func(_a: AttackData, _i: int) -> StringName: return &"parry"
	if with_error:
		cfg["parry_error_fn"] = func(_wait: float) -> float: return error
	return cfg


func _want_results(blocked: int, last: int) -> Array:
	var out: Array = []
	for i in blocked:
		out.append(DT.StrikeResult.BLOCKED)
	out.append(last)
	return out


# ================================================================ T126 데이터

func t126_fifth_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var ago := load(AGOSTINO_PATH) as OpponentData
	# ① 로드, 이름, 갈래 이름, 칼 든 팔, 그림.
	if ago == null:
		return "opponent_05.tres가 로드되지 않는다"
	if ago.display_name != "아고스티노" or ago.style_name != STYLE_NAME:
		errs.append("이름 '%s' · 갈래 '%s'" % [ago.display_name, ago.style_name])
	if ago.sword_side != DT.Direction.LEFT:
		errs.append("칼 든 팔이 왼쪽이 아니다 (%d)" % ago.sword_side)
	if ago.art == null:
		errs.append("그림 데이터(art)가 비었다")
	# ② 바르톨로와 견준다: 이름·그림·포즈 아홉과 공격 목록·갈래 이름·단만 다르다. 버릇은 견준다(결정 638).
	_f._compare(bartolo, ago, "opponent", errs, Fourth.FREE_FIELDS + ["attacks"] + Fourth.SWORD_FIELDS)
	# ③ 1단의 공격 넷과 모든 단의 높이.
	_check_first_tier(errs, ago, bartolo)
	_check_heights(errs, ago)
	# ④ 단마다의 엇박의 길.
	_check_tiers(errs, ago)
	# ⑤ 가방의 장 수.
	for k in ago.tier_count():
		var brain := OpponentBrain.new(ago.at_tier(k), _f._seeded())
		brain.start_idle(0.0)
		brain.start_tell(0.0, false)
		var cards: int = brain.bag_remaining() + 1
		if k >= BAG_SIZES.size() or cards != BAG_SIZES[k]:
			errs.append("%d단의 가방 %d장 (기대 %s)" % [k + 1, cards, str(BAG_SIZES[k]) if k < BAG_SIZES.size() else "없음"])
	# ⑥ 주인 없는 공격이 없다.
	if not SelectScript.load_spare_attacks().is_empty():
		errs.append("data/attacks/에 주인 없는 공격이 %d개 남아 있다" % SelectScript.load_spare_attacks().size())
	if ResourceLoader.exists(OFFBEAT_FILE):
		errs.append("%s가 아직 폴더에 있다" % OFFBEAT_FILE)
	# ⑦ 아고스티노를 거는 의뢰는 대련과 독촉이다(결정 646 → 043. 048이 독촉을 더했다).
	var ago_commissions: Array[String] = []
	for commission in CommissionLibrary.load_tree(COMMISSION_DIR):
		if commission.opponent != null and commission.opponent.resource_path == AGOSTINO_PATH:
			ago_commissions.append(commission.resource_path.get_file())
	if ago_commissions != ["spar.tres", "dun_master.tres"]:
		errs.append("아고스티노를 거는 의뢰 %s (기대 spar.tres · dun_master.tres, 계획 048)" % str(ago_commissions))
	# ⑧ 옛 규칙 사본은 단발 셋이고, 예비는 셋 모두 · 빈틈은 찌르기만 바르톨로의 옛 규칙 사본과 같다(베기의 빈틈은 ③이 본다).
	var plain := Plain.of(ago)
	var plain_bartolo := Plain.of(bartolo)
	if plain.attacks.size() != 3:
		errs.append("Plain.of(아고스티노)의 공격 %d개 (기대 3 — 찌르기 · 좌우 베기)" % plain.attacks.size())
	else:
		for atk in plain.attacks:
			var his: AttackData = _f._find_named(plain_bartolo.attacks, atk.attack_name)
			if his == null:
				errs.append("Plain.of(바르톨로)에 %s가 없다" % atk.attack_name)
				continue
			if atk.direction != his.direction or not _near(atk.tell_time, his.tell_time):
				errs.append("plain %s: 방향 %d · 예비 %.2f (바르톨로 %d · %.2f)" % [atk.attack_name, atk.direction, atk.tell_time, his.direction, his.tell_time])
			if atk.attack_name == "찌르기" and not _near(atk.recovery_time, his.recovery_time):
				errs.append("plain 찌르기: 빈틈 %.2f (바르톨로 %.2f)" % [atk.recovery_time, his.recovery_time])
	return _ok(errs)


## 1단: 공격 넷(찌르기 · 좌우 베기 · 엇박). 기본 셋의 예비·방향과 찌르기의 빈틈은 바르톨로와 같고, 가중치와 베기의 빈틈은 손으로 적은 값이다.
func _check_first_tier(errs: Array[String], ago: OpponentData, bartolo: OpponentData) -> void:
	if ago.attacks.size() != 4:
		errs.append("1단의 공격 %d개 (기대 4)" % ago.attacks.size())
		return
	for attack_name: String in BASIC_WEIGHTS:
		var mine: AttackData = _f._find_named(ago.attacks, attack_name)
		var his: AttackData = _f._find_named(bartolo.attacks, attack_name)
		if mine == null or his == null:
			errs.append("1단에 %s가 없다 (아고스티노 %s · 바르톨로 %s)" % [attack_name, mine != null, his != null])
			continue
		var want_recovery: float = his.recovery_time if attack_name == "찌르기" else CUT_RECOVERY
		if mine.direction != his.direction or not _near(mine.tell_time, his.tell_time) or not _near(mine.recovery_time, want_recovery):
			errs.append("%s: 방향 %d · 예비 %.2f · 빈틈 %.2f (기대 %d · %.2f · %.2f)" % [
				attack_name, mine.direction, mine.tell_time, mine.recovery_time, his.direction, his.tell_time, want_recovery])
		if not is_equal_approx(mine.weight, float(BASIC_WEIGHTS[attack_name])):
			errs.append("%s의 가중치 %.1f (기대 %.1f)" % [attack_name, mine.weight, float(BASIC_WEIGHTS[attack_name])])
		if not mine.chain.is_empty() or mine.signature or mine.is_big or mine.sweep or mine.dive or mine.needs_raised_guard:
			errs.append("%s: 걸음 %d · 고유 %s · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s (기대 모두 없음)" % [
				attack_name, mine.chain.size(), mine.signature, mine.is_big, mine.sweep, mine.dive, mine.needs_raised_guard])
	var roots: Array[AttackData] = _f._signature_roots(ago.attacks)
	if roots.size() != 1:
		errs.append("1단의 고유 공격 %d개 (기대 1)" % roots.size())
	else:
		var sig: AttackData = roots[0]
		if sig.attack_name != STYLE_NAME or sig.is_big or sig.sweep or sig.dive or sig.needs_raised_guard:
			errs.append("엇박: 이름 '%s' · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s" % [sig.attack_name, sig.is_big, sig.sweep, sig.dive, sig.needs_raised_guard])
		if sig.mark_shape != &"beat" or sig.tell_hint == "":
			errs.append("엇박: mark_shape '%s' · tell_hint '%s' (기대 beat · 글이 있다)" % [sig.mark_shape, sig.tell_hint])
	if ago.tiers.size() != FROM_DAYS.size():
		errs.append("단 %d개 (기대 %d)" % [ago.tiers.size(), FROM_DAYS.size()])
	else:
		for i in ago.tiers.size():
			if ago.tiers[i].from_day != FROM_DAYS[i]:
				errs.append("%d단의 from_day %d (기대 %d)" % [i + 2, ago.tiers[i].from_day, FROM_DAYS[i]])
	if ago.habits.size() != bartolo.habits.size():
		errs.append("버릇 %d개 (바르톨로 %d개)" % [ago.habits.size(), bartolo.habits.size()])
	# 버릇의 큰 베기는 높이가 없다(결정 641).
	for habit in ago.habits:
		var habit_routes: Array[AttackData] = _f._routes(habit.response)
		for route in habit_routes:
			if not route.heights.is_empty():
				errs.append("버릇의 반응 %s에 높이가 있다 %s" % [route.attack_name, str(route.heights)])


## 모든 단의 모든 타격(뿌리·걸음·변주)의 heights가 [1]이다(결정 641).
func _check_heights(errs: Array[String], ago: OpponentData) -> void:
	var lists: Array = _f._tier_lists(ago)
	for k in lists.size():
		var attacks: Array = lists[k]
		for atk: AttackData in attacks:
			var routes: Array[AttackData] = _f._routes(atk)
			for route in routes:
				var strikes: Array[AttackData] = _f._strike_list(route)
				for j in strikes.size():
					var heights: Array[int] = strikes[j].heights
					if heights.size() != 1 or heights[0] != 1:
						_f._note(errs, "%d단 %s의 %d번째 타격의 높이 %s (기대 [1])" % [k + 1, route.attack_name, j + 1, str(heights)])


## 단마다: 공격 이름의 목록, 고유 공격 하나(가중치·색), 길의 목록(간격·세는 말·예비·빈틈·방향).
func _check_tiers(errs: Array[String], ago: OpponentData) -> void:
	var lists: Array = _f._tier_lists(ago)
	if lists.size() != TIER_ROUTES.size():
		errs.append("단 %d개 (기대 %d)" % [lists.size(), TIER_ROUTES.size()])
		return
	for k in lists.size():
		var attacks: Array = lists[k]
		var names: Array[String] = []
		for atk: AttackData in attacks:
			names.append(atk.attack_name)
		if str(names) != str(TIER_NAMES[k]):
			errs.append("%d단의 공격 %s (기대 %s)" % [k + 1, str(names), str(TIER_NAMES[k])])
		var roots: Array[AttackData] = _f._signature_roots(attacks)
		if roots.size() != 1:
			errs.append("%d단의 고유 공격 %d개 (기대 1)" % [k + 1, roots.size()])
			continue
		if not is_equal_approx(roots[0].weight, SIG_WEIGHTS[k]):
			errs.append("%d단의 엇박 가중치 %.1f (기대 %.1f)" % [k + 1, roots[0].weight, SIG_WEIGHTS[k]])
		var cuts_recovery := INF
		for cut_name in ["왼쪽 베기", "오른쪽 베기"]:
			var cut: AttackData = _f._find_named(attacks, cut_name)
			if cut != null:
				cuts_recovery = minf(cuts_recovery, cut.recovery_time)
		var keys: Array[String] = []
		var routes: Array[AttackData] = _f._routes(roots[0])
		for route in routes:
			var key := _beat_key(route)
			keys.append(key)
			_check_route(errs, k, key, route, cuts_recovery)
		var want_keys: Array = (TIER_ROUTES[k] as Array).duplicate()
		want_keys.sort()
		keys.sort()
		if str(keys) != str(want_keys):
			errs.append("%d단의 길 %s (기대 %s)" % [k + 1, str(keys), str(want_keys)])
	# 뿌리는 모든 단에서 짧·긴이다.
	for k in lists.size():
		var attacks: Array = lists[k]
		var roots: Array[AttackData] = _f._signature_roots(attacks)
		if roots.size() == 1 and _beat_key(roots[0]) != "SL":
			errs.append("%d단의 뿌리의 길 %s (기대 SL — 짧·긴)" % [k + 1, _beat_key(roots[0])])


func _check_route(errs: Array[String], k: int, key: String, route: AttackData, cuts_recovery: float) -> void:
	var label := "%d단 길 %s" % [k + 1, key]
	if key.contains("?") or not key.contains("L"):
		errs.append("%s: 간격이 0.6 · 1.3 둘뿐이 아니거나 긴 박이 없다" % label)
	if ROUTE_HINTS.has(key) and route.tell_hint != ROUTE_HINTS[key]:
		errs.append("%s: 세는 말 '%s' (기대 '%s')" % [label, route.tell_hint, ROUTE_HINTS[key]])
	if route.attack_name != STYLE_NAME or not route.signature or route.is_big or route.sweep or route.dive or route.needs_raised_guard or route.mark_shape != &"beat":
		errs.append("%s: 이름 '%s' · 고유 %s · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s · 꼴 '%s'" % [
			label, route.attack_name, route.signature, route.is_big, route.sweep, route.dive, route.needs_raised_guard, route.mark_shape])
	if not _near(route.tell_time, ROOT_TELL):
		errs.append("%s: 뿌리의 예비 %.2f (기대 %.2f)" % [label, route.tell_time, ROOT_TELL])
	# 모든 길의 끝 빈틈이 0.55이고 그 단의 좌우 베기 이하다(결정 642 — D1).
	if not _near(route.recovery_time, OFFBEAT_RECOVERY):
		errs.append("%s: 끝 빈틈 %.2f (기대 %.2f)" % [label, route.recovery_time, OFFBEAT_RECOVERY])
	if route.recovery_time > cuts_recovery + 0.0001:
		errs.append("%s: 끝 빈틈 %.2f가 그 단의 좌우 베기의 빈틈 %.2f보다 크다" % [label, route.recovery_time, cuts_recovery])
	var strikes: Array[AttackData] = _f._strike_list(route)
	for j in strikes.size():
		if strikes[j].direction != DT.Direction.CENTER:
			errs.append("%s: %d번째 타격이 가운데가 아니다 (%d)" % [label, j + 1, strikes[j].direction])
		if not strikes[j].pose_color.is_equal_approx(SIG_COLOR):
			errs.append("%s: %d번째 타격의 색 %s (기대 물빛 %s)" % [label, j + 1, str(strikes[j].pose_color), str(SIG_COLOR)])


# ================================================================ T127 엇박의 판

func t127_offbeat_duel() -> String:
	var errs: Array[String] = []
	var ago := load(AGOSTINO_PATH) as OpponentData
	if ago == null or ago.tiers.size() < 5:
		return "opponent_05.tres가 없거나 단이 여섯이 아니다"
	var lists: Array = _f._tier_lists(ago)
	var first := _route_by_key(lists[0], "SL")
	var four := _route_by_key(lists[3], "SSL")
	if first == null or four == null:
		return "1단 짧·긴(%s)이나 4단 짧·짧·긴(%s) 길이 없다" % [first != null, four != null]
	# (가) 쥔 손과 박자를 맞춘 손.
	_t127_values(errs, ago, first, "1단 짧·긴")
	_t127_values(errs, ago, four, "4단 짧·짧·긴")
	# (나)(라)(마) 6단의 모든 길: 타격 수·간격의 차례·다 막으면 그 길의 빈틈·예비 동작에서 뽑힌 높이.
	_t127_routes(errs, ago, lists)
	# (다) 멈칫에 속는 손.
	_t127_traps(errs, ago, lists)
	# (바)(사)(아) 같은 씨앗, 봇의 한 판, 실제 아고스티노.
	_t127_runs(errs, ago)
	# (자) 박자 봇의 뜻.
	_t127_bot(errs, ago, first)
	return _ok(errs)


## (가) 쥐고만 막으면 마지막 타격의 빈틈이 길의 값이고 머리는 닫혀 있다. 마지막 박만 패리하면 그 값 + 덤이고 머리가 열린다. 닿는 조준의 차.
func _t127_values(errs: Array[String], ago: OpponentData, route: AttackData, label: String) -> void:
	var SR := DT.StrikeResult
	var AR := DT.AttackResult
	var P := DT.Part
	var solo: AttackData = _f._solo(route)
	var n := 1 + solo.chain.size()
	var opp: OpponentData = _f._drill_opp(ago, solo)
	var held: DuelCore = _f._play(opp, {}, _f._stop_strikes(n), 30.0)
	var held_strikes: Array[Dictionary] = held.record.of_type(DuelRecord.STRIKE)
	var parried: DuelCore = _f._play(opp, {"step_fn": _f._step_only(n - 1, &"parry")}, _f._stop_strikes(n), 30.0)
	var parried_strikes: Array[Dictionary] = parried.record.of_type(DuelRecord.STRIKE)
	if not _f._is(held_strikes, _want_results(n - 1, SR.BLOCKED)) or not _f._is(parried_strikes, _want_results(n - 1, SR.PARRIED)):
		errs.append("[가·%s] 결과 쥔 손 %s · 패리한 손 %s" % [label, _f._result_text(held_strikes), _f._result_text(parried_strikes)])
		return
	var held_gap: float = float(held_strikes[n - 1]["recovery"])
	var parried_gap: float = float(parried_strikes[n - 1]["recovery"])
	var want_parried: float = route.recovery_time + ago.parried_recovery_bonus
	if absf(held_gap - route.recovery_time) > 0.01 or held.brain.wide_open or held.head_open_at(held.time):
		errs.append("[가·%s·쥠] 마지막 빈틈 %.2f (기대 %.2f) · 크게 열림 %s · 머리 열림 %s (기대 닫힘)" % [
			label, held_gap, route.recovery_time, held.brain.wide_open, held.head_open_at(held.time)])
	if absf(parried_gap - want_parried) > 0.01 or not parried.brain.wide_open or not parried.head_open_at(parried.time):
		errs.append("[가·%s·패리] 마지막 빈틈 %.2f (기대 %.2f) · 크게 열림 %s · 머리 열림 %s (기대 열림)" % [
			label, parried_gap, want_parried, parried.brain.wide_open, parried.head_open_at(parried.time)])
	var left_cut: AttackData = _f._find_named(ago.attacks, "왼쪽 베기")
	if not held_gap < parried_gap:
		errs.append("[가·%s] 쥔 손의 빈틈 %.2f가 패리한 손의 빈틈 %.2f보다 짧지 않다" % [label, held_gap, parried_gap])
	if left_cut == null or held_gap > left_cut.recovery_time + 0.0001:
		errs.append("[가·%s] 쥔 손의 빈틈 %.2f가 왼쪽 베기를 막았을 때의 빈틈 %s보다 크다" % [label, held_gap, str(left_cut.recovery_time) if left_cut != null else "없음"])
	var thrust_aim := [DT.Direction.CENTER, DT.Height.MID]
	var arm_aim := [DT.Direction.LEFT, DT.Height.MID]
	var head_aim := [DT.Direction.CENTER, DT.Height.HIGH]
	var parry_step := {"step_fn": _f._step_only(n - 1, &"parry")}
	# 쥔 손: 타격 직후의 중단 찌르기는 닿고, 0.25초 뒤의 칼 쪽 중단 베기는 늦다(빈틈 안에 눌렀으니 섣부른 공격이 아니다).
	_expect_attack(errs, "[가·%s·쥠·찌르기]" % label, _first_attack(ago, solo, _counter_cfg(thrust_aim, 0.0, {}), n), AR.GRAZE, P.TORSO, ago, false)
	var late: Dictionary = _first_attack(ago, solo, _counter_cfg(arm_aim, 0.25, {}), n)
	_expect_attack(errs, "[가·%s·쥠·0.25초 뒤의 팔 베기]" % label, late, AR.BLOCKED, P.SWORD_ARM, ago, false)
	if not late.is_empty() and float(late["t"]) < float(held_strikes[n - 1]["t"]) + route.recovery_time:
		errs.append("[가·%s·쥠·0.25초 뒤의 팔 베기] 판정 시각 %.2f가 빈틈의 끝 %.2f보다 이르다 (늦음을 보려는 판이다)" % [
			label, float(late["t"]), float(held_strikes[n - 1]["t"]) + route.recovery_time])
	# 쥔 손에게 머리는 피한다(빈틈 안에 닿는 머리 찌르기 — 상단 찌르기 0.40 < 0.55).
	var dodge: Dictionary = _first_attack(ago, solo, _counter_cfg(head_aim, 0.0, {}), n)
	if dodge.is_empty() or not bool(dodge["dodged"]) or int(dodge["result"]) != AR.BLOCKED:
		errs.append("[가·%s·쥠·머리 찌르기] 피하지 않았다 (결과 %s)" % [label, str(dodge)])
	# 패리한 손: 0.25초 뒤의 칼 쪽 중단 베기(팔)와 가운데 상단 찌르기(머리)가 닿는다.
	_expect_attack(errs, "[가·%s·패리·0.25초 뒤의 팔 베기]" % label, _first_attack(ago, solo, _counter_cfg(arm_aim, 0.25, parry_step), n), AR.GRAZE, P.SWORD_ARM, ago, false)
	_expect_attack(errs, "[가·%s·패리·0.25초 뒤의 머리 찌르기]" % label, _first_attack(ago, solo, _counter_cfg(head_aim, 0.25, parry_step), n), AR.GRAZE, P.HEAD, ago, false)
	if label.begins_with("1단"):
		print("  INFO 엇박의 빈틈(%s): 쥔 손 %.2f초 · 패리한 손 %.2f초" % [label, held_gap, parried_gap])


## 받아치기 설정으로 한 판을 돌려 첫 ATTACK 이벤트를 돌려준다(없으면 빈 Dictionary). 패턴의 끝에서만 받아치므로 판의 끝은 첫 공격이다.
## 패리 설정은 cfg가 이미 step_fn을 갖고 있고, 쥔 손은 없다. n은 길의 타격 수다.
func _first_attack(ago: OpponentData, solo: AttackData, cfg: Dictionary, _n: int) -> Dictionary:
	var core: DuelCore = _f._play(_f._drill_opp(ago, solo), cfg, _stop_attacks(1), 30.0)
	var attacks: Array[Dictionary] = core.record.of_type(DuelRecord.ATTACK)
	if attacks.is_empty():
		return {}
	return attacks[0]


func _expect_attack(errs: Array[String], label: String, ev: Dictionary, result: int, part: int, ago: OpponentData, rash: bool) -> void:
	if ev.is_empty():
		errs.append("%s 공격 이벤트가 없다" % label)
		return
	if int(ev["result"]) != result or int(ev["part"]) != part or bool(ev["rash"]) != rash:
		errs.append("%s 결과 %d · 부위 %d · 섣부름 %s (기대 %d · %d · %s)" % [label, int(ev["result"]), int(ev["part"]), bool(ev["rash"]), result, part, rash])
		return
	var want_cells := ago.graze_cells(part) if result == DT.AttackResult.GRAZE else 0
	if int(ev["cells"]) != want_cells:
		errs.append("%s 깎인 칸 %d (기대 %d)" % [label, int(ev["cells"]), want_cells])


## (나)(라)(마) 6단의 모든 길: 타격 수, 앞 타격의 판정에서 그 걸음의 간격 뒤에 다음 타격, 다 막으면 그 길의 빈틈, 예비 동작이 시작된 틱에 높이가 모두 1.
## 3단 겹찌르기와 5단 찌르고 베기의 타격이 중단으로 판정된다.
func _t127_routes(errs: Array[String], ago: OpponentData, lists: Array) -> void:
	var SR := DT.StrikeResult
	var roots: Array[AttackData] = _f._signature_roots(lists[5])
	if roots.size() != 1:
		errs.append("[나] 6단의 고유 공격 %d개" % roots.size())
		return
	var routes: Array[AttackData] = _f._routes(roots[0])
	for route in routes:
		var key := _beat_key(route)
		var solo: AttackData = _f._solo(route)
		var n := 1 + solo.chain.size()
		var opp: OpponentData = _f._drill_opp(ago, solo)
		var core: DuelCore = _f._play(opp, {}, _f._stop_strikes(n), 30.0)
		var strikes: Array[Dictionary] = core.record.of_type(DuelRecord.STRIKE)
		if not _f._is(strikes, _want_results(n - 1, SR.BLOCKED)):
			errs.append("[나·%s] 결과 %s (기대 막힘 %d번)" % [key, _f._result_text(strikes), n])
			continue
		for i in range(1, n):
			var gap := float(strikes[i]["t"]) - float(strikes[i - 1]["t"])
			var want: float = (solo.chain[i - 1] as AttackData).tell_time
			if absf(gap - want) > TIME_TOL:
				errs.append("[나·%s] %d번째와 %d번째 타격 사이 %.3f초 (기대 %.2f ± %.2f)" % [key, i, i + 1, gap, want, TIME_TOL])
		if absf(float(strikes[n - 1]["recovery"]) - route.recovery_time) > 0.01:
			errs.append("[라·%s] 다 막은 마지막 빈틈 %.2f (기대 그 길의 %.2f)" % [key, float(strikes[n - 1]["recovery"]), route.recovery_time])
		var tell_core: DuelCore = _f._play(opp, {}, _f._stop_first_tell(), 10.0)
		var tells: Array[Dictionary] = tell_core.record.of_type(DuelRecord.TELL_START)
		if tells.is_empty():
			errs.append("[마·%s] 10초 안에 예비 동작이 없다" % key)
			continue
		var got: Array = tells[0]["heights"]
		var want_heights: Array = []
		for i in n:
			want_heights.append(1)
		if str(got) != str(want_heights):
			errs.append("[마·%s] 예비 동작의 높이 %s (기대 %s)" % [key, str(got), str(want_heights)])
	# 3단 겹찌르기, 5단 찌르고 베기(그 길과 변주): 모든 타격이 중단으로 판정된다.
	var composites: Array = [[lists[2], "겹찌르기"], [lists[4], "찌르고 베기"]]
	for item: Array in composites:
		var base: AttackData = _f._find_named(item[0], item[1])
		if base == null:
			errs.append("[라] %s가 없다" % item[1])
			continue
		var composite_routes: Array[AttackData] = _f._routes(base)
		for route in composite_routes:
			var composite_solo: AttackData = _f._solo(route)
			var composite_n := 1 + composite_solo.chain.size()
			var composite_core: DuelCore = _f._play(_f._drill_opp(ago, composite_solo), {}, _f._stop_strikes(composite_n), 30.0)
			var composite_strikes: Array[Dictionary] = composite_core.record.of_type(DuelRecord.STRIKE)
			for ev in composite_strikes:
				if int(ev["height"]) != DT.Height.MID:
					errs.append("[라·%s] 타격의 높이 %d (기대 중단 1)" % [item[1], int(ev["height"])])
			if composite_strikes.size() != composite_n or not _f._is(composite_strikes, _want_results(composite_n - 1, SR.BLOCKED)):
				errs.append("[라·%s] 결과 %s (기대 막힘 %d번)" % [item[1], _f._result_text(composite_strikes), composite_n])


## (다) 긴 박 동안 막기를 떼면 그 타격을 맞고 패턴이 끝난다. 긴 박 동안 친 공격은 닿지 않고 섣부른 공격이라 상대의 자세가 돌아온다.
func _t127_traps(errs: Array[String], ago: OpponentData, lists: Array) -> void:
	var SR := DT.StrikeResult
	var AR := DT.AttackResult
	# 긴·짧·짧의 첫 걸음(긴 박)에서 막기를 뗀다(늦게 누르는 패리 봇): 그 타격을 맞고 패턴이 거기서 끝난다.
	var lss := _route_by_key(lists[5], "LSS")
	if lss == null:
		errs.append("[다] 6단에 긴·짧·짧 길이 없다")
	else:
		var late_cfg := {"step_fn": _f._step_only(1, &"parry"), "parry_error_fn": func(_wait: float) -> float: return 0.5}
		var core: DuelCore = _f._play(_f._drill_opp(ago, _f._solo(lss)), late_cfg, _f._stop_after_strike(2, 1.0), 30.0)
		var strikes: Array[Dictionary] = core.record.of_type(DuelRecord.STRIKE)
		if not _f._is(strikes, [SR.BLOCKED, SR.GRAZE]):
			errs.append("[다·막기를 뗌] 결과 %s (기대 막힘 뒤 스침에서 끝)" % _f._result_text(strikes))
	# 긴 박 동안 친 공격: 상대의 자세를 한 칸 깎아 둔 판에서 그 칸이 돌아온다.
	var ls := _route_by_key(lists[0], "LS")
	if ls == null:
		errs.append("[다] 1단에 긴·짧 길이 없다")
		return
	var solo: AttackData = _f._solo(ls)
	var opp: OpponentData = _f._drill_opp(ago, solo)
	var probe: DuelCore = _f._play(opp, {}, _f._stop_first_tell(), 10.0)
	var tells: Array[Dictionary] = probe.record.of_type(DuelRecord.TELL_START)
	if tells.is_empty():
		errs.append("[다] 긴·짧 길의 예비 동작이 10초 안에 없다")
		return
	var first_strike := float(tells[0]["strike_time"])
	var cfg := {"attack_at": {"time": first_strike + 0.5, "aim": [DT.Direction.CENTER, DT.Height.MID]}}
	var shave := func(core: DuelCore) -> void: core.brain.posture = core.opponent_data.posture_max - 1
	var rash_core: DuelCore = _play_hook(opp, cfg, _stop_attacks(1), 30.0, shave)
	var starts: Array[Dictionary] = rash_core.record.of_type(DuelRecord.ATTACK_START)
	var attacks: Array[Dictionary] = rash_core.record.of_type(DuelRecord.ATTACK)
	if starts.is_empty() or attacks.is_empty():
		errs.append("[다·긴 박에 친 공격] 공격 이벤트가 없다 (시작 %d · 판정 %d)" % [starts.size(), attacks.size()])
		return
	var hit: Dictionary = attacks[0]
	if not bool(starts[0]["rash"]) or int(hit["result"]) != AR.BLOCKED or int(hit["posture_gain"]) != 1 or int(hit["opponent_posture"]) != ago.posture_max:
		errs.append("[다·긴 박에 친 공격] 섣부름 %s · 결과 %d · 돌아온 칸 %d · 상대 자세 %d (기대 참 · 막힘 · 1 · %d)" % [
			bool(starts[0]["rash"]), int(hit["result"]), int(hit["posture_gain"]), int(hit["opponent_posture"]), ago.posture_max])


## (바)(사)(아) 같은 씨앗의 이벤트 줄, 봇의 한 판, 실제 아고스티노(확률 켬)의 엇박.
func _t127_runs(errs: Array[String], ago: OpponentData) -> void:
	var last_tier := ago.tier_count() - 1
	var first_run: DuelCore = _f._play(ago.at_tier(last_tier).with_opening(1.0), {}, _f._never(), 40.0)
	var second_run: DuelCore = _f._play(ago.at_tier(last_tier).with_opening(1.0), {}, _f._never(), 40.0)
	var first_lines: Array[String] = _f._lines(first_run)
	var second_lines: Array[String] = _f._lines(second_run)
	if first_lines.size() < 5 or first_lines != second_lines:
		errs.append("[바] 마지막 단: 같은 씨앗의 이벤트 줄이 다르다 (%d줄 · %d줄)" % [first_lines.size(), second_lines.size()])
	for tier in [0, last_tier]:
		var full: DuelCore = _f._play(ago.at_tier(tier).with_opening(1.0), Bot.first_blood_cfg(), _f._never(), 100.0)
		if not full.ended or full.record.of_type(DuelRecord.TELL_START).is_empty():
			errs.append("[사] %d단: 봇의 한 판이 끝나지 않았다 (시각 %.1f)" % [tier + 1, full.time])
	var day_rules: DuelRules = _f._rules()
	day_rules.stage_day = 1
	var long_run: DuelCore = _f._play(ago, {}, _f._never(), 60.0, day_rules)
	var offbeat_tells := 0
	for ev in long_run.record.of_type(DuelRecord.TELL_START):
		if (ev["attack"] as AttackData).attack_name == STYLE_NAME:
			offbeat_tells += 1
	if offbeat_tells < 1:
		errs.append("[아] 실제 아고스티노 60초 동안 엇박의 예비 동작이 %d번 (1 이상 기대)" % offbeat_tells)


## (자) 박자 봇의 뜻: 어긋남 0이면 모든 타격이 패리, +0.2면 첫 타격을 맞는다, -0.2면 막힘이되 패리가 아니다. 키가 없는 패리 봇 = 0을 돌려주는 봇.
func _t127_bot(errs: Array[String], ago: OpponentData, route: AttackData) -> void:
	var SR := DT.StrikeResult
	var solo: AttackData = _f._solo(route)
	var n := 1 + solo.chain.size()
	var opp: OpponentData = _f._drill_opp(ago, solo)
	var exact: DuelCore = _f._play(opp, _parry_cfg(0.0, true), _f._stop_strikes(n), 30.0)
	var exact_strikes: Array[Dictionary] = exact.record.of_type(DuelRecord.STRIKE)
	var all_parried: Array = []
	for i in n:
		all_parried.append(SR.PARRIED)
	if not _f._is(exact_strikes, all_parried):
		errs.append("[자·0] 결과 %s (기대 모두 패리)" % _f._result_text(exact_strikes))
	var late: DuelCore = _f._play(opp, _parry_cfg(0.2, true), _f._stop_after_strike(1, 1.0), 30.0)
	var late_strikes: Array[Dictionary] = late.record.of_type(DuelRecord.STRIKE)
	if not _f._is(late_strikes, [SR.GRAZE]):
		errs.append("[자·+0.2] 결과 %s (기대 첫 타격을 맞고 거기서 끝)" % _f._result_text(late_strikes))
	var early: DuelCore = _f._play(opp, _parry_cfg(-0.2, true), _f._stop_strikes(n), 30.0)
	var early_strikes: Array[Dictionary] = early.record.of_type(DuelRecord.STRIKE)
	var all_blocked: Array = []
	for i in n:
		all_blocked.append(SR.BLOCKED)
	if not _f._is(early_strikes, all_blocked):
		errs.append("[자·-0.2] 결과 %s (기대 모두 막힘 — 패리가 아니다)" % _f._result_text(early_strikes))
	var keyless: DuelCore = _f._play(opp, _parry_cfg(0.0, false), _f._never(), 20.0)
	var zero: DuelCore = _f._play(opp, _parry_cfg(0.0, true), _f._never(), 20.0)
	var keyless_lines: Array[String] = _f._lines(keyless)
	var zero_lines: Array[String] = _f._lines(zero)
	if keyless_lines.size() < 5 or keyless_lines != zero_lines:
		errs.append("[자·키 없음] 키를 주지 않은 패리 봇의 판이 0을 돌려주는 봇과 다르다 (%d줄 · %d줄)" % [keyless_lines.size(), zero_lines.size()])


# ================================================================ T128 표시와 연습 화면

func t128_marks_and_practice() -> String:
	var errs: Array[String] = []
	var ago := load(AGOSTINO_PATH) as OpponentData
	if ago == null or ago.tiers.size() < 5:
		return "opponent_05.tres가 없거나 단이 여섯이 아니다"
	_marks_and_hints(errs, ago)
	_f._reset_statics()
	_practice_checks(errs)
	_free_select()
	return _ok(errs)


## ① 모든 길(6단의 여섯)의 번호 고리: shape가 beat, 첫 wait 0 · 나머지는 그 걸음의 간격. 귀띔이 세는 말이다. 네 박의 넷째 고리는 첫 고리 + 108.
func _marks_and_hints(errs: Array[String], ago: OpponentData) -> void:
	var lists: Array = _f._tier_lists(ago)
	var roots: Array[AttackData] = _f._signature_roots(lists[5])
	if roots.size() != 1:
		errs.append("[①] 6단의 고유 공격 %d개" % roots.size())
		return
	var routes: Array[AttackData] = _f._routes(roots[0])
	for route in routes:
		var key := _beat_key(route)
		var solo: AttackData = _f._solo(route)
		var strikes: Array[AttackData] = _f._strike_list(solo)
		var opp: OpponentData = _f._drill_opp(ago, solo)
		var brain := OpponentBrain.new(opp, _f._seeded())
		brain.start_idle(0.0)
		brain.start_tell(0.0, false)
		if brain.state != DT.OpponentState.TELL or brain.pattern_root == null:
			errs.append("[①·%s] 예비 동작에 들어가지 않는다" % key)
			continue
		var marks: Array[Dictionary] = OpponentView.pattern_marks(brain, 0.0)
		if marks.size() != strikes.size():
			errs.append("[①·%s] 고리 %d개 (타격 %d개)" % [key, marks.size(), strikes.size()])
			continue
		for i in marks.size():
			var want_wait: float = 0.0 if i == 0 else strikes[i].tell_time
			if not marks[i].has("shape") or marks[i]["shape"] != &"beat" or absf(float(marks[i].get("wait", -1.0)) - want_wait) > 0.001:
				errs.append("[①·%s] %d번째 고리: shape '%s' · wait %.3f (기대 beat · %.2f)" % [key, i + 1, str(marks[i].get("shape", "")), float(marks[i].get("wait", -1.0)), want_wait])
		var core: DuelCore = _f._play(opp, {}, _f._stop_first_tell(), 20.0)
		if core.brain.state != DT.OpponentState.TELL or core.brain.pattern_root == null:
			errs.append("[①·%s] 판이 예비 동작까지 가지 않는다" % key)
			continue
		var parts: PackedStringArray = OpponentView.tell_texts(core, false)
		var want_head := "%s (1/%d)" % [STYLE_NAME, strikes.size()]
		if parts.size() != 2 or parts[1] != route.tell_hint or not parts[0].begins_with(want_head):
			errs.append("[①·%s] 상태 글 %s (기대 첫 줄이 '%s'로 시작 · 귀띔 '%s')" % [key, str(parts), want_head, route.tell_hint])
	var four := _route_by_key(lists[3], "SSL")
	if four == null:
		errs.append("[①] 4단에 짧·짧·긴 길이 없다")
		return
	var none: Array[int] = []
	var rings: Array[Vector2] = _f._ring_positions(ago, _f._solo(four), none)
	if rings.size() != 4:
		errs.append("[①] 네 박의 고리 %d개 (기대 4)" % rings.size())
	elif not rings[3].is_equal_approx(rings[0] + Vector2(0.0, FOURTH_RING_SHIFT)):
		errs.append("[①] 네 박의 넷째 고리 %s (기대 첫 고리 %s + (0, %.0f))" % [str(rings[3]), str(rings[0]), FOURTH_RING_SHIFT])


func _free_select() -> void:
	if _select != null and is_instance_valid(_select):
		if _select.get_parent() != null:
			_select.get_parent().remove_child(_select)
		_select.free()
	_select = null
	_f._reset_statics()


## ② 연습 화면: 다섯째 칸, 머리 줄, 단 고르기 여섯, 패턴 버튼 하나, 막는 법의 줄, 상대 줄의 수.
func _practice_checks(errs: Array[String]) -> void:
	var trials := SelectScript.load_trials()
	var index := -1
	for i in trials.size():
		if trials[i].resource_path == AGOSTINO_PATH:
			index = i
	if index < 0:
		errs.append("[②] load_trials()에 아고스티노가 없다")
		return
	if index != 4:
		errs.append("[②] 아고스티노가 %d번째 칸이다 (기대 다섯째)" % (index + 1))
	_select = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(_select)
	_select.call("pick_opponent", index)
	var head := _select.find_child("TrialHead", true, false)
	var head_texts: Array[String] = []
	if head != null:
		for label in head.find_children("*", "Label", true, false):
			head_texts.append((label as Label).text)
	if not head_texts.has("아고스티노") or not head_texts.has(STYLE_NAME):
		errs.append("[②] TrialHead의 글 %s에 '아고스티노'와 '엇박 찌르기'가 없다" % str(head_texts))
	var pick := _select.find_child("StyleTierPick", true, false) as OptionButton
	if pick == null or pick.item_count != 6:
		errs.append("[②] StyleTierPick의 항목 %s (기대 6)" % ("없음" if pick == null else str(pick.item_count)))
	_check_drill_and_help(errs, "1단")
	if pick != null:
		pick.item_selected.emit(5)
		_check_drill_and_help(errs, "6단")
	# 상대 목록: 주인 없는 검술은 비었으니 줄은 상대뿐이다.
	_f._reset_statics()
	_select.call("pick_opponent", 0)
	var spare_count := _select.find_children("SpareDrill*", "Button", true, false).size()
	var entries := trials.size() + (1 if not SelectScript.load_spare_attacks().is_empty() else 0)
	var pick_rows := _select.find_children("OpponentPick*", "Button", true, false).size()
	if not SelectScript.load_spare_attacks().is_empty() or spare_count != 0 or _select.find_child("SpareCaption", true, false) != null:
		errs.append("[②] 주인 없는 검술의 줄이 남아 있다 (SpareDrill %d개)" % spare_count)
	if pick_rows != mini(entries, SelectScript.LIST_ROWS):
		errs.append("[②] 상대 줄 %d개 (기대 %d)" % [pick_rows, mini(entries, SelectScript.LIST_ROWS)])


func _check_drill_and_help(errs: Array[String], label: String) -> void:
	var drills := _select.find_children("PatternDrill*", "Button", true, false)
	if drills.size() != 1:
		errs.append("[② %s] PatternDrill %d개 (기대 1)" % [label, drills.size()])
	elif (drills[0] as Button).text != STYLE_NAME:
		errs.append("[② %s] PatternDrill의 글 '%s' (기대 '%s')" % [label, (drills[0] as Button).text, STYLE_NAME])
	if _select.find_child("SlashDrill", true, false) != null:
		errs.append("[② %s] 아고스티노에게 SlashDrill이 있다" % label)
	var help_node := _select.find_child("PatternHelp", true, false) as Label
	if help_node == null:
		errs.append("[② %s] PatternHelp가 없다" % label)
		return
	var text := help_node.text
	var has_chain: bool = _f._help_has(text, DuelHud.HELP_CHAIN)
	var has_beat: bool = _f._help_has(text, DuelHud.HELP_BEAT)
	var has_height: bool = _f._help_has(text, DuelHud.HELP_HEIGHT)
	if not has_chain or not has_beat or not has_height:
		errs.append("[② %s] 막는 법에 이어 치기(%s) · 박자(%s) · 높이(%s)의 줄이 다 있지 않다" % [label, has_chain, has_beat, has_height])
	var has_sweep: bool = _f._help_has(text, DuelHud.HELP_SWEEP)
	var has_dive: bool = _f._help_has(text, DuelHud.HELP_DIVE)
	if has_sweep or has_dive:
		errs.append("[② %s] 막는 법에 휩쓸기(%s)나 뛰어들기(%s) 줄이 있다" % [label, has_sweep, has_dive])


# ================================================================ T129 그림 데이터

const AGOSTINO_ART_PATH := "res://data/opponents/agostino_art.tres"
const AGOSTINO_ART_DIR := "res://assets/art/opponents/agostino/"
const AGO_ART_SIZES := {
	"head": Vector2i(276, 262), "head_oops": Vector2i(278, 262), "head_dizzy": Vector2i(277, 262), "hat": Vector2i(136, 70),
	"feather": Vector2i(134, 49), "torso": Vector2i(334, 403), "legs": Vector2i(281, 404), "arm": Vector2i(74, 211),
	"hand": Vector2i(80, 71), "sword": Vector2i(126, 399), "arm_up_sword": Vector2i(155, 553), "arm_up": Vector2i(102, 302),
	"arm_up_fist": Vector2i(137, 101), "arm_thrust": Vector2i(171, 125), "arm_thrust_fist": Vector2i(171, 234),
	"arm_thrust_sword": Vector2i(273, 279), "arm_thrust_blade": Vector2i(64, 46), "arm_aim": Vector2i(132, 150),
	"arm_aim_fist": Vector2i(132, 174), "arm_aim_sword": Vector2i(187, 201), "arm_aim_blade": Vector2i(104, 100),
}
## 머리 가운데의 자(결정 619의 관절 식): 꼭대기 - 머리 그림 / 2가 이 값 이상이어야 눈이 교전의 줄 위에 선다.
const MIN_HEAD_MID := 252.0
## 모자 없는 꼭대기의 상한과 발끝의 범위(판 S2의 자).
const MAX_BARE_TOP := 311.0
const MIN_FOOT := 185.0
const MAX_FOOT_TIP := 200.0
## 지팡이가 다리 그림 안에 있다: 다리 관절의 높이(단위)가 다른 넷의 6.5~10.3보다 훨씬 크다.
const MIN_LEG_JOINT_Y := 50.0


func t129_agostino_art() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var ago := load(AGOSTINO_PATH) as OpponentData
	if ago == null or ago.art == null or bartolo == null or bartolo.art == null:
		return "opponent_05.tres나 그 그림이 없음"
	var art: OpponentArt = ago.art
	if art.resource_path != AGOSTINO_ART_PATH:
		errs.append("그림 데이터 %s (기대 %s)" % [art.resource_path, AGOSTINO_ART_PATH])
	if art == bartolo.art:
		errs.append("바르톨로의 그림을 빌려 쓴다")
	_check_art_files(errs, art, bartolo.art)
	_check_art_body(errs, art, bartolo.art)
	var client := "res://assets/art/clients/agostino.png"
	if ResourceLoader.exists(client):
		var tex := load(client) as Texture2D
		if tex == null or Vector2i(tex.get_size()) != Vector2i(450, 675):
			errs.append("의뢰인 그림의 크기 %s (기대 450x675)" % (str(Vector2i(tex.get_size())) if tex != null else "읽을 수 없음"))
	else:
		print("INFO T129: assets/art/clients/agostino.png가 아직 없다(위험 R7)")
	return _ok(errs)


func _check_art_files(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	for part_name: String in Fourth.ART_PARTS:
		var part := art.get(part_name) as PartArt
		if part == null or part.texture == null or not part.texture.resource_path.begins_with(AGOSTINO_ART_DIR):
			errs.append("그림 %s: 없거나 아고스티노의 폴더가 아님" % part_name)
		elif part.units_per_px.x <= 0.0 or part.units_per_px.y <= 0.0:
			errs.append("그림 %s: units_per_px %s" % [part_name, part.units_per_px])
	if art.hand != null and art.hand.outline.size() < 6:
		errs.append("손의 윤곽선이 없음")
	if art.arm_arts.size() != bartolo_art.arm_arts.size():
		errs.append("따로 그린 팔 %d개 (바르톨로 %d개)" % [art.arm_arts.size(), bartolo_art.arm_arts.size()])
	else:
		for i in art.arm_arts.size():
			var mine := art.arm_arts[i]
			var his := bartolo_art.arm_arts[i]
			if mine.key != his.key or not is_equal_approx(mine.rotation_deg, his.rotation_deg) or mine.layers.size() != his.layers.size():
				errs.append("팔 %s: 키·회전·층 수가 바르톨로(%s)와 다름" % [mine.key, his.key])
				continue
			for k in mine.layers.size():
				var layer := mine.layers[k]
				if layer.part != his.layers[k].part or layer.texture == null or not layer.texture.resource_path.begins_with(AGOSTINO_ART_DIR):
					errs.append("팔 %s 층 %d: part·그림이 어긋남" % [mine.key, k])
				elif (layer.part == 4) != (layer.outline.size() >= 6):
					errs.append("팔 %s 층 %d: 주먹의 윤곽선이 없거나 주먹이 아닌데 있음" % [mine.key, k])
	var keys: Array[StringName] = []
	for arm_art in art.arm_arts:
		keys.append(arm_art.key)
	for want_key: StringName in [&"armUp", &"armThrust", &"armAim"]:
		if not keys.has(want_key):
			errs.append("팔 묶음 %s가 없음 (%s)" % [want_key, str(keys)])
	for file: String in AGO_ART_SIZES:
		var tex := load(AGOSTINO_ART_DIR + file + ".png") as Texture2D
		if tex == null or Vector2i(tex.get_size()) != AGO_ART_SIZES[file]:
			errs.append("%s.png의 크기 %s (기대 %s)" % [file, Vector2i(tex.get_size()) if tex != null else Vector2i.ZERO, AGO_ART_SIZES[file]])


## 몸의 값(결정 619의 식): 한계는 다른 넷의 같은 식 값에서 읽고, 고정 수는 판 S2의 자(311·252·185~200·50)만 쓴다.
func _check_art_body(errs: Array[String], art: OpponentArt, bartolo_art: OpponentArt) -> void:
	if art.neck.y < -212.0 or art.neck.y > -200.0:
		errs.append("neck.y %.1f (기대 -212~-200)" % art.neck.y)
	if art.legs == null or art.legs.texture == null or art.head == null or art.hat == null:
		return
	var others: Array[OpponentArt] = [bartolo_art]
	for path: String in [Fourth.BRUNO_PATH, Fourth.LORENZO_PATH, Fourth.SERAFINA_PATH]:
		var other := load(path) as OpponentData
		if other != null and other.art != null:
			others.append(other.art)
	if others.size() != 4:
		errs.append("다른 상대의 그림 %d개 (기대 4)" % others.size())
	var lowest: float = INF
	for other_art in others:
		lowest = minf(lowest, _f._bare_top(other_art, other_art.head))
	var hat_limit: float = _f._hat_top(bartolo_art)
	var hat_top: float = _f._hat_top(art)
	var foot: float = _f._foot_tip(art)
	var joint_y: float = art.legs.joint.y * art.legs.units_per_px.y
	print("INFO T129: 모자 쓴 꼭대기 %.1f (바르톨로 %.1f) · 발끝 %.1f · 다리 관절 %.1f · 가장 낮은 다른 상대 꼭대기 %.1f" % [hat_top, hat_limit, foot, joint_y, lowest])
	if hat_top > hat_limit + 0.01:
		errs.append("모자 쓴 꼭대기 %.2f (바르톨로의 같은 식 값 %.2f 이하여야 한다)" % [hat_top, hat_limit])
	for head_part: PartArt in [art.head, art.head_oops, art.head_dizzy]:
		if head_part == null:
			errs.append("머리 셋 가운데 빈 것이 있다")
			continue
		var top: float = _f._bare_top(art, head_part)
		var mid: float = top - head_part.joint.y * head_part.units_per_px.y / 2.0
		print("INFO T129: 모자 없는 꼭대기 %.1f · 머리 가운데 %.1f" % [top, mid])
		if top >= lowest - 0.01 or top > MAX_BARE_TOP + 0.01:
			errs.append("모자 없는 꼭대기 %.2f (다른 넷의 가장 낮은 값 %.2f보다, 그리고 %.0f보다 낮아야 한다)" % [top, lowest, MAX_BARE_TOP])
		if mid < MIN_HEAD_MID - 0.01:
			errs.append("머리 가운데의 자 %.2f (%.0f 이상이어야 한다)" % [mid, MIN_HEAD_MID])
	if foot < MIN_FOOT - 0.01 or foot > MAX_FOOT_TIP + 0.01:
		errs.append("발끝 %.2f (기대 %.0f~%.0f)" % [foot, MIN_FOOT, MAX_FOOT_TIP])
	if joint_y < MIN_LEG_JOINT_Y:
		errs.append("다리 관절의 높이 %.2f (지팡이가 다리 그림 안에 있으면 %.0f 이상)" % [joint_y, MIN_LEG_JOINT_Y])
