extends RefCounted
## T120~T122: 넷째 상대 세라피나(계획 041). 데이터의 틀과 층층 찌르기의 길(결정 609~614), 판에서 도는 모습, 고리가 제 칸에 드는 불변(결정 615).
## T123(그림 데이터)은 2부의 몫이다. 층층의 길·가방·가중치의 기대는 결정 613·614의 표를 손으로 적은 것이다(결정 622의 고침이 함께 옮긴다).

const Plain := preload("res://tests/plain_opponent.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const SERAFINA_PATH := "res://data/opponents/opponent_04.tres"
const STAIR_THRUST_PATH := "res://data/attacks/stair_thrust.tres"
const COMMISSION_DIR := "res://data/commissions"
const RULES_PATH := "res://data/duel_rules.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
const STYLE_NAME := "층층 찌르기"
const STAIR_FROM_DAYS: Array[int] = [7, 9, 11, 13, 15]
## 다를 수 있는 칸(T93과 같다): 이름·그림·포즈(표시만이고 판정에 쓰지 않는다).
const FREE_FIELDS := ["display_name", "art", "idle_pose", "stagger_pose", "complacent_pose",
	"tell_pose", "hold_arm_deg", "strike_pose", "recover_arm_deg"]
## 검술 데이터(상대마다 다르다. 결정 425의 "공격 목록 밖의 판정 값"이 아니다).
const SWORD_FIELDS := ["style_name", "tiers"]
## 단마다의 층층 찌르기 길(결정 613). 높이 0 상 · 1 중 · 2 하, 모든 타격이 가운데다. 순서는 상관없다.
const THREE_LAYER_START: Array[String] = ["012", "210", "120"]
const THREE_LAYER_BENT: Array[String] = ["012", "210", "120", "021", "201", "102"]
const FOUR_LAYER_BASE: Array[String] = ["120", "021", "201", "102", "0121", "2101", "1012", "1210"]
## 가방의 장 수(결정 614): 1·2단 5 · 3·4단 6 · 5·6단 7.
const BAG_SIZES: Array[int] = [4, 4, 5, 5, 6, 6]
## 화면과 고리의 자리(duel_scene가 anchor를 (너비 0.5, 높이 0.62)에 둔다). 조준칸은 화면을 3x3으로 가른다.
const SCREEN := Vector2(1280.0, 720.0)
const ANCHOR_RATIO := 0.62
const MAX_NOTES := 24

var _tree: SceneTree
var _select: Node = null


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T120", "name": "넷째 상대: 판정 값이 바르톨로와 같다, 기본은 가운데 찌르기뿐, 층층 찌르기의 길·가방, 하루에는 서지 않는다", "fn": t120_fourth_opponent},
		{"id": "T121", "name": "층층의 판: 높이를 따라 막으면 빈틈이 열리고 틀리면 한 번만 맞는다, 새 길과 옆 베기, 같은 씨앗, 봇의 한 판", "fn": t121_stair_duel},
		{"id": "T122", "name": "고리의 자리와 연습 화면: 모든 길의 번호 고리가 교전·밀착에서 제 칸 안에 들고, 세라피나의 칸이 선다", "fn": t122_rings_and_practice},
	]


func cleanup() -> void:
	_free_select()
	_tree = null


# ================================================================ 도우미

func _ok(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else ", ".join(errs)


## 오류가 쏟아져도 보고가 읽히게 앞의 몇 줄만 남기고 수를 적는다.
func _note(errs: Array[String], text: String) -> void:
	if errs.size() < MAX_NOTES:
		errs.append(text)
	elif errs.size() == MAX_NOTES:
		errs.append("... (이하 생략)")


## 스크립트 칸을 하나씩 견준다. 자원은 같은 규칙으로 들어가 견주고, 배열은 원소마다 견준다.
func _compare(a: Variant, b: Variant, path: String, errs: Array[String], skip: Array) -> void:
	if a is Resource and b is Resource:
		for prop in (a as Resource).get_property_list():
			if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var field: String = prop["name"]
			if skip.has(field):
				continue
			_compare((a as Resource).get(field), (b as Resource).get(field), path + "." + field, errs, skip)
	elif a is Array and b is Array:
		if (a as Array).size() != (b as Array).size():
			_note(errs, "%s: 원소 %d개 (기준 %d개)" % [path, (b as Array).size(), (a as Array).size()])
			return
		for i in (a as Array).size():
			_compare(a[i], b[i], "%s[%d]" % [path, i], errs, skip)
	elif typeof(a) != typeof(b) or a != b:
		_note(errs, "%s: %s (기준 %s)" % [path, str(b), str(a)])


## 뿌리와 변주(가방에서 나오면 이 가운데 하나를 고르게 뽑는다).
func _routes(atk: AttackData) -> Array[AttackData]:
	var out: Array[AttackData] = [atk]
	for v in atk.variants:
		out.append(v as AttackData)
	return out


## 한 길의 타격들: 뿌리와 걸음.
func _strike_list(route: AttackData) -> Array[AttackData]:
	var out: Array[AttackData] = [route]
	for s in route.chain:
		out.append(s as AttackData)
	return out


## 상대의 단마다의 공격 목록. 0번이 1단이다.
func _tier_lists(opp: OpponentData) -> Array:
	var out: Array = [opp.attacks]
	for tier in opp.tiers:
		out.append(tier.attacks)
	return out


## 변주를 뗀 사본: 길을 하나로 고정한다. 로드한 자원은 고치지 않는다.
func _solo(atk: AttackData) -> AttackData:
	var copy := atk.duplicate() as AttackData
	var none: Array[Resource] = []
	copy.variants = none
	return copy


## 공격 하나만 되풀이하는 상대(대기 1.0초 고정, 빈틈의 확률 끔).
func _drill_opp(opp: OpponentData, atk: AttackData) -> OpponentData:
	var copy := opp.drill(atk)
	copy.opening_chance = 1.0
	copy.idle_time_min = 1.0
	copy.idle_time_max = 1.0
	return copy


func _rules() -> DuelRules:
	return (load(RULES_PATH) as DuelRules).duplicate() as DuelRules


## 0초에 한 걸음 들어가 교전에서 시작한다. 엉킴을 끈 무기라 밀착에서 밀려나는 일이 판을 흔들지 않는다.
func _play(opp: OpponentData, cfg: Dictionary, stop: Callable, until: float, rules: DuelRules = null) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	var core := DuelCore.new()
	var none: Array[CommissionCondition] = []
	core.setup(rules if rules != null else _rules(), weapon, opp, rng, none, false)
	var bot := Bot.new(core, cfg)
	core.step(1)
	while not core.ended and core.time < until:
		core.tick(DELTA)
		bot.update()
		if stop.call(core):
			break
	return core


func _stop_strikes(count: int) -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.STRIKE).size() >= count


## count번째 타격의 판정 뒤 wait초까지 본다(그 사이에 다음 타격이 안 오면 패턴이 끝난 것이다).
func _stop_after_strike(count: int, wait: float) -> Callable:
	return func(core: DuelCore) -> bool:
		var seen := core.record.of_type(DuelRecord.STRIKE)
		return seen.size() >= count and core.time >= float(seen[count - 1]["t"]) + wait


func _stop_first_tell() -> Callable:
	return func(core: DuelCore) -> bool: return core.record.of_type(DuelRecord.TELL_START).size() >= 1


func _never() -> Callable:
	return func(_core: DuelCore) -> bool: return false


func _result_text(strikes: Array) -> String:
	var out: Array[int] = []
	for ev: Dictionary in strikes:
		out.append(int(ev["result"]))
	return str(out)


func _is(strikes: Array, want: Array) -> bool:
	return _result_text(strikes) == str(want)


## 걸음에서 쓸 모드를 정한다: 그 걸음(1부터)만 mode, 나머지는 &"hold".
func _step_only(step: int, mode: StringName) -> Callable:
	return func(_a: AttackData, index: int) -> StringName: return mode if index == step else &"hold"


## 이벤트 줄(같은 씨앗이면 같아야 한다).
func _lines(core: DuelCore) -> Array[String]:
	var out: Array[String] = []
	for ev: Dictionary in core.record.events:
		var line := "%s %.4f" % [str(ev["type"]), float(ev.get("t", -1.0))]
		if ev.has("result"):
			line += " r%s" % str(ev["result"])
		if ev.get("attack") is AttackData:
			line += " " + (ev["attack"] as AttackData).attack_name
		out.append(line)
	return out


## 한 길의 높이 차례를 "0121" 같은 글로(0 상 · 1 중 · 2 하). 높이가 하나가 아닌 타격은 "?"다.
func _seq(route: AttackData) -> String:
	var text := ""
	for s in _strike_list(route):
		text += str(s.heights[0]) if s.heights.size() == 1 else "?"
	return text


func _signature_roots(attacks: Array) -> Array[AttackData]:
	var out: Array[AttackData] = []
	for atk: AttackData in attacks:
		if atk.signature:
			out.append(atk)
	return out


## 고유 공격의 길 가운데 높이 차례가 seq인 길(없으면 null). 변주를 뗀 사본이 아니라 원본 길이다.
func _route_by_seq(attacks: Array, seq: String) -> AttackData:
	for root in _signature_roots(attacks):
		for route in _routes(root):
			if _seq(route) == seq:
				return route
	return null


func _find_named(attacks: Array, attack_name: String) -> AttackData:
	for atk: AttackData in attacks:
		if atk.attack_name == attack_name:
			return atk
	return null


# ================================================================ T120 데이터

func t120_fourth_opponent() -> String:
	var errs: Array[String] = []
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var lorenzo := load(LORENZO_PATH) as OpponentData
	var serafina := load(SERAFINA_PATH) as OpponentData
	# ① 로드, 이름, 갈래 이름, 칼 든 팔, 그림.
	if serafina == null:
		return "opponent_04.tres가 로드되지 않는다"
	if serafina.display_name != "세라피나" or serafina.style_name != STYLE_NAME:
		errs.append("이름 '%s' · 갈래 '%s'" % [serafina.display_name, serafina.style_name])
	if serafina.sword_side != DT.Direction.LEFT:
		errs.append("칼 든 팔이 왼쪽이 아니다 (%d)" % serafina.sword_side)
	if serafina.art == null:
		errs.append("그림 데이터(art)가 비었다")
	# ② 바르톨로와 견준다: 이름·그림·포즈 아홉과 공격 목록·갈래 이름·단만 다르다. 버릇은 견준다(결정 609).
	_compare(bartolo, serafina, "opponent", errs, FREE_FIELDS + ["attacks"] + SWORD_FIELDS)
	# ③ 1단의 공격 둘.
	_check_first_tier(errs, serafina, lorenzo, bartolo)
	_check_directions(errs, serafina)
	# ④ 단마다의 층층 찌르기.
	_check_tiers(errs, serafina)
	# ⑤ 가방의 장 수.
	for k in serafina.tier_count():
		var brain := OpponentBrain.new(serafina.at_tier(k), _seeded())
		brain.start_idle(0.0)
		brain.start_tell(0.0, false)
		var cards := brain.bag_remaining() + 1
		if k >= BAG_SIZES.size() or cards != BAG_SIZES[k]:
			errs.append("%d단의 가방 %d장 (기대 %s)" % [k + 1, cards, str(BAG_SIZES[k]) if k < BAG_SIZES.size() else "없음"])
	# ⑥ 주인 없는 검술에서 빠졌다.
	if ResourceLoader.exists(STAIR_THRUST_PATH):
		errs.append("%s가 아직 폴더에 있다" % STAIR_THRUST_PATH)
	for spare in SelectScript.load_spare_attacks():
		if spare.attack_name == STYLE_NAME:
			errs.append("data/attacks/에 '층층 찌르기'가 남아 있다")
	# ⑦ 어느 의뢰도 세라피나를 걸지 않는다(하루에는 서지 않는다. 결정 623).
	for commission in CommissionLibrary.load_tree(COMMISSION_DIR):
		if commission.opponent != null and commission.opponent.resource_path == SERAFINA_PATH:
			errs.append("의뢰 %s가 세라피나를 건다" % commission.client_name)
	# ⑧ 옛 규칙 사본은 찌르기 하나이고 그 판정 값이 바르톨로의 사본의 찌르기와 같다.
	var plain := Plain.of(serafina)
	var plain_bartolo := Plain.of(bartolo)
	if plain.attacks.size() != 1 or plain.attacks[0].attack_name != "찌르기":
		errs.append("Plain.of(세라피나)의 공격 %d개 (기대 찌르기 하나)" % plain.attacks.size())
	else:
		var his := _find_named(plain_bartolo.attacks, "찌르기")
		if his == null:
			errs.append("Plain.of(바르톨로)에 찌르기가 없다")
		else:
			_compare(his, plain.attacks[0], "plain 찌르기", errs, FREE_FIELDS + ["heights", "weight"])
	return _ok(errs)


func _seeded() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return rng


## 1단: 공격 둘(찌르기 + 층층 찌르기). 찌르기는 로렌초의 것과 판정 값과 높이가 같고(가중치만 2 — 판이 길어 V2 뒤에 3에서 내렸다, 결정 622), 층층은 고유·가중치 2·큰 공격.
func _check_first_tier(errs: Array[String], serafina: OpponentData, lorenzo: OpponentData, bartolo: OpponentData) -> void:
	if serafina.attacks.size() != 2:
		errs.append("1단의 공격 %d개 (기대 2)" % serafina.attacks.size())
		return
	var thrust := _find_named(serafina.attacks, "찌르기")
	var stair := _find_named(serafina.attacks, STYLE_NAME)
	if thrust == null or stair == null:
		errs.append("1단에 찌르기(%s)나 층층 찌르기(%s)가 없다" % [thrust != null, stair != null])
		return
	var his := _find_named(lorenzo.attacks, "찌르기")
	if his == null:
		errs.append("로렌초에게 찌르기가 없어 견줄 수 없다")
	else:
		_compare(his, thrust, "찌르기", errs, FREE_FIELDS + ["weight"])
	if not is_equal_approx(thrust.weight, 2.0) or thrust.signature or not thrust.chain.is_empty() or thrust.dive or thrust.sweep:
		errs.append("찌르기: 가중치 %.1f · 고유 %s · 걸음 %d (기대 2.0 · 아님 · 0)" % [thrust.weight, thrust.signature, thrust.chain.size()])
	if not stair.signature or not is_equal_approx(stair.weight, 2.0) or not stair.is_big or stair.sweep or stair.dive or stair.needs_raised_guard:
		errs.append("층층 찌르기: 고유 %s · 가중치 %.1f · 큰 공격 %s · 휩쓸기 %s · 뛰어들기 %s · 올려 막기 %s (기대 참 · 2.0 · 참 · 아님 · 아님 · 아님)" % [
			stair.signature, stair.weight, stair.is_big, stair.sweep, stair.dive, stair.needs_raised_guard])
	if serafina.tiers.size() != STAIR_FROM_DAYS.size():
		errs.append("단 %d개 (기대 %d)" % [serafina.tiers.size(), STAIR_FROM_DAYS.size()])
	else:
		for i in serafina.tiers.size():
			if serafina.tiers[i].from_day != STAIR_FROM_DAYS[i]:
				errs.append("%d단의 from_day %d (기대 %d)" % [i + 2, serafina.tiers[i].from_day, STAIR_FROM_DAYS[i]])
	if serafina.habits.size() != bartolo.habits.size():
		errs.append("버릇 %d개 (바르톨로 %d개)" % [serafina.habits.size(), bartolo.habits.size()])


## 1~4단에는 가운데가 아닌 타격이 하나도 없고(뿌리·걸음·변주·버릇의 반응까지), 5·6단에서 가운데가 아닌 것은 찌르고 베기의 둘째 타격뿐이다(결정 612).
func _check_directions(errs: Array[String], serafina: OpponentData) -> void:
	var lists := _tier_lists(serafina)
	for k in lists.size():
		var attacks: Array = lists[k]
		for atk: AttackData in attacks:
			for route in _routes(atk):
				var strikes := _strike_list(route)
				for j in strikes.size():
					var side_ok := k >= 4 and route.attack_name == "찌르고 베기" and j == 1
					if strikes[j].direction != DT.Direction.CENTER and not side_ok:
						_note(errs, "%d단 %s의 %d번째 타격이 가운데가 아니다 (%d)" % [k + 1, route.attack_name, j + 1, strikes[j].direction])
	for habit in serafina.habits:
		for route in _routes(habit.response):
			for s in _strike_list(route):
				if s.direction != DT.Direction.CENTER:
					_note(errs, "버릇의 반응 %s가 가운데가 아니다" % route.attack_name)


## 모든 단의 층층 찌르기: 단마다 고유 공격 하나, 길이 결정 613의 표와 같고, 잇달은 두 타격의 높이가 다르다.
func _check_tiers(errs: Array[String], serafina: OpponentData) -> void:
	var skipping: Array[String] = FOUR_LAYER_BASE.duplicate()
	skipping.append_array(["1021", "1201"])
	var want_table: Array = [
		THREE_LAYER_START, THREE_LAYER_BENT, THREE_LAYER_BENT,
		FOUR_LAYER_BASE, FOUR_LAYER_BASE, skipping,
	]
	var lists := _tier_lists(serafina)
	if lists.size() != want_table.size():
		errs.append("단 %d개 (기대 %d)" % [lists.size(), want_table.size()])
		return
	for k in lists.size():
		var roots := _signature_roots(lists[k])
		if roots.size() != 1:
			errs.append("%d단의 고유 공격 %d개 (기대 1)" % [k + 1, roots.size()])
			continue
		var seqs: Array[String] = []
		for route in _routes(roots[0]):
			var seq := _seq(route)
			seqs.append(seq)
			if route.attack_name != STYLE_NAME or not route.signature or not route.is_big or route.sweep or route.dive or route.needs_raised_guard:
				errs.append("%d단 길 %s: 이름·고유·큰 공격·휩쓸기·뛰어들기·올려 막기가 어긋남" % [k + 1, seq])
			var counts := {}
			var previous := -1
			for s in _strike_list(route):
				if s.direction != DT.Direction.CENTER or s.heights.size() != 1:
					errs.append("%d단 길 %s: 가운데가 아니거나 높이가 값 하나가 아닌 타격" % [k + 1, seq])
					break
				var h: int = s.heights[0]
				if h == previous:
					errs.append("%d단 길 %s: 잇달은 두 타격의 높이가 같다" % [k + 1, seq])
				previous = h
				counts[h] = int(counts.get(h, 0)) + 1
			if seq.length() == 3 and counts.size() != 3:
				errs.append("%d단 세 층 길 %s: 세 높이가 다 다르지 않다" % [k + 1, seq])
			elif seq.length() == 4 and (counts.size() != 3 or int(counts.get(DT.Height.MID, 0)) != 2):
				errs.append("%d단 네 층 길 %s: 세 높이를 모두 지나고 중단이 두 번이어야 한다 (%s)" % [k + 1, seq, str(counts)])
			elif seq.length() != 3 and seq.length() != 4:
				errs.append("%d단 길 %s: 타격이 셋이나 넷이 아니다" % [k + 1, seq])
		var want: Array = (want_table[k] as Array).duplicate()
		want.sort()
		seqs.sort()
		if str(seqs) != str(want):
			errs.append("%d단의 길 %s (기대 %s)" % [k + 1, str(seqs), str(want)])


# ================================================================ T121 층층의 판

func t121_stair_duel() -> String:
	var errs: Array[String] = []
	var serafina := load(SERAFINA_PATH) as OpponentData
	if serafina == null or serafina.tiers.size() < 5:
		return "opponent_04.tres가 없거나 단이 여섯이 아니다"
	_t121_first_tier(errs, serafina)
	_t121_four_layer(errs, serafina)
	_t121_skip_and_side(errs, serafina)
	_t121_draw(errs, serafina)
	_t121_runs(errs, serafina)
	return _ok(errs)


## (가) 1단 상중하: 높이를 따라 막으면 셋이 다 막히고 그 길의 빈틈이 열리며 머리가 열린다. 둘째에서 높이를 안 옮기면 그 한 번만 맞고 끝난다. 마지막을 패리하면 덤이 붙는다.
func _t121_first_tier(errs: Array[String], serafina: OpponentData) -> void:
	var SR := DT.StrikeResult
	var route := _route_by_seq(serafina.attacks, "012")
	if route == null:
		errs.append("[가] 1단에 상중하 길이 없다")
		return
	var solo := _solo(route)
	var blocked := _play(_drill_opp(serafina, solo), {}, _stop_strikes(3), 30.0)
	var strikes := blocked.record.of_type(DuelRecord.STRIKE)
	if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]):
		errs.append("[가·막기] 결과 %s" % _result_text(strikes))
	elif absf(float(strikes[2]["recovery"]) - route.recovery_time) > 0.01 or not blocked.brain.wide_open or not blocked.head_open_at(blocked.time):
		errs.append("[가·막기] 마지막 빈틈 %.2f (기대 그 길의 %.2f) · 크게 열림 %s · 머리 열림 %s" % [
			float(strikes[2]["recovery"]), route.recovery_time, blocked.brain.wide_open, blocked.head_open_at(blocked.time)])
	# 둘째의 높이를 옮기지 않는다(&"stay"는 알 수 없는 모드라 봇이 아무것도 하지 않는다): 방향이 같아도 높이가 틀려 그 한 번만 맞는다.
	var stayed := _play(_drill_opp(serafina, solo), {"step_fn": _step_only(1, &"stay")}, _stop_after_strike(2, 0.9), 30.0)
	strikes = stayed.record.of_type(DuelRecord.STRIKE)
	if not _is(strikes, [SR.BLOCKED, SR.GRAZE]):
		errs.append("[가·높이를 안 옮김] 결과 %s (기대 막힘 뒤 스침에서 끝)" % _result_text(strikes))
	elif strikes[1]["guard_miss"] != &"height":
		errs.append("[가·높이를 안 옮김] 맞은 까닭 %s (기대 height)" % str(strikes[1]["guard_miss"]))
	var parried := _play(_drill_opp(serafina, solo), {"step_fn": _step_only(2, &"parry")}, _stop_strikes(3), 30.0)
	strikes = parried.record.of_type(DuelRecord.STRIKE)
	if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.PARRIED]):
		errs.append("[가·마지막 패리] 결과 %s" % _result_text(strikes))
	elif absf(float(strikes[2]["recovery"]) - (route.recovery_time + serafina.parried_recovery_bonus)) > 0.01:
		errs.append("[가·마지막 패리] 마지막 빈틈 %.2f (기대 %.2f)" % [float(strikes[2]["recovery"]), route.recovery_time + serafina.parried_recovery_bonus])


## (나) 4단 상중하중: 넷을 다 막으면 그 길의 빈틈이 열린다.
func _t121_four_layer(errs: Array[String], serafina: OpponentData) -> void:
	var SR := DT.StrikeResult
	var route := _route_by_seq(serafina.tiers[2].attacks, "0121")
	if route == null:
		errs.append("[나] 4단에 상중하중 길이 없다")
		return
	var core := _play(_drill_opp(serafina, _solo(route)), {}, _stop_strikes(4), 30.0)
	var strikes := core.record.of_type(DuelRecord.STRIKE)
	if not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]):
		errs.append("[나] 결과 %s" % _result_text(strikes))
	elif absf(float(strikes[3]["recovery"]) - route.recovery_time) > 0.01 or not core.brain.wide_open:
		errs.append("[나] 마지막 빈틈 %.2f (기대 그 길의 %.2f) · 크게 열림 %s" % [float(strikes[3]["recovery"]), route.recovery_time, core.brain.wide_open])


## (다) 6단 중상하중의 높이 차례, 5단 찌르고 베기의 옆 베기(가운데만 지키면 그 한 번을 맞는다).
func _t121_skip_and_side(errs: Array[String], serafina: OpponentData) -> void:
	var SR := DT.StrikeResult
	var route := _route_by_seq(serafina.tiers[4].attacks, "1021")
	if route == null:
		errs.append("[다] 6단에 중상하중 길이 없다")
	else:
		var core := _play(_drill_opp(serafina, _solo(route)), {}, _stop_strikes(4), 30.0)
		var strikes := core.record.of_type(DuelRecord.STRIKE)
		var heights: Array[int] = []
		for ev: Dictionary in strikes:
			heights.append(int(ev["height"]))
		if str(heights) != str([1, 0, 2, 1]) or not _is(strikes, [SR.BLOCKED, SR.BLOCKED, SR.BLOCKED, SR.BLOCKED]):
			errs.append("[다·6단] 타격의 높이 %s · 결과 %s (기대 [1, 0, 2, 1] · 모두 막힘)" % [str(heights), _result_text(strikes)])
	var cut := _find_named(serafina.tiers[3].attacks, "찌르고 베기")
	if cut == null or cut.variants.size() != 1:
		errs.append("[다·5단] 5단에 변주가 하나인 찌르고 베기가 없다")
		return
	var sides: Array = [[_solo(cut), DT.Direction.LEFT, "왼쪽"], [cut.variants[0] as AttackData, DT.Direction.RIGHT, "오른쪽"]]
	for item: Array in sides:
		var side_route: AttackData = item[0]
		var label: String = item[2]
		var held := _play(_drill_opp(serafina, side_route), {}, _stop_strikes(2), 30.0)
		var held_strikes := held.record.of_type(DuelRecord.STRIKE)
		if not _is(held_strikes, [SR.BLOCKED, SR.BLOCKED]) or (held_strikes[1]["attack"] as AttackData).direction != item[1]:
			errs.append("[다·%s 베기·따라 막기] 결과 %s · 둘째의 방향 %s (기대 막힘 둘 · %d)" % [label, _result_text(held_strikes), str((held_strikes[1]["attack"] as AttackData).direction) if held_strikes.size() > 1 else "-", item[1]])
		# 걸음에서 가운데를 지킨 채 있는다: 둘째가 옆이라 그 한 번을 맞는다.
		var center := _play(_drill_opp(serafina, side_route), {"step_fn": _step_only(1, &"stay")}, _stop_strikes(2), 30.0)
		var center_strikes := center.record.of_type(DuelRecord.STRIKE)
		if not _is(center_strikes, [SR.BLOCKED, SR.GRAZE]):
			errs.append("[다·%s 베기·가운데만 지킴] 결과 %s (기대 막힘 뒤 스침)" % [label, _result_text(center_strikes)])


## (라) 예비 동작이 시작된 틱에 모든 타격의 높이가 뽑혀 있다(마지막 단의 모든 길).
func _t121_draw(errs: Array[String], serafina: OpponentData) -> void:
	var last := serafina.tiers[serafina.tiers.size() - 1].attacks
	for root in _signature_roots(last):
		for route in _routes(root):
			var core := _play(_drill_opp(serafina, _solo(route)), {}, _stop_first_tell(), 10.0)
			var tells := core.record.of_type(DuelRecord.TELL_START)
			if tells.is_empty():
				errs.append("[라] 길 %s: 10초 안에 예비 동작이 없다" % _seq(route))
				continue
			var want: Array[int] = []
			for s in _strike_list(route):
				want.append(int(s.heights[0]))
			var got: Array = tells[0]["heights"]
			if str(got) != str(want):
				errs.append("[라] 길 %s: 예비 동작의 높이 %s (기대 %s)" % [_seq(route), str(got), str(want)])


## (마)(바)(사) 같은 씨앗의 이벤트 줄, 봇의 한 판, 실제 세라피나의 층층.
func _t121_runs(errs: Array[String], serafina: OpponentData) -> void:
	var last_tier := serafina.tier_count() - 1
	var first_run := _play(serafina.at_tier(last_tier).with_opening(1.0), {}, _never(), 40.0)
	var second_run := _play(serafina.at_tier(last_tier).with_opening(1.0), {}, _never(), 40.0)
	var first_lines := _lines(first_run)
	if first_lines.size() < 5 or first_lines != _lines(second_run):
		errs.append("[마] 마지막 단: 같은 씨앗의 이벤트 줄이 다르다 (%d줄 · %d줄)" % [first_lines.size(), _lines(second_run).size()])
	for tier in [0, last_tier]:
		var full := _play(serafina.at_tier(tier).with_opening(1.0), Bot.first_blood_cfg(), _never(), 100.0)
		if not full.ended or full.record.of_type(DuelRecord.TELL_START).is_empty():
			errs.append("[바] %d단: 봇의 한 판이 끝나지 않았다 (시각 %.1f)" % [tier + 1, full.time])
	# 실제 세라피나(1일차의 확률, 들고 막는 봇, 60초): 층층의 예비 동작이 나온다.
	var day_rules := _rules()
	day_rules.stage_day = 1
	var long_run := _play(serafina, {}, _never(), 60.0, day_rules)
	var stair_tells := 0
	for ev in long_run.record.of_type(DuelRecord.TELL_START):
		if (ev["attack"] as AttackData).attack_name == STYLE_NAME:
			stair_tells += 1
	if stair_tells < 1:
		errs.append("[사] 실제 세라피나 60초 동안 층층 찌르기의 예비 동작이 %d번 (1 이상 기대)" % stair_tells)


# ================================================================ T122 고리의 자리와 연습 화면

func t122_rings_and_practice() -> String:
	var errs: Array[String] = []
	_ring_formula_samples(errs)
	_ring_invariant(errs)
	_ring_stair_shape(errs)
	_reset_statics()
	_practice_checks(errs)
	_free_select()
	return _ok(errs)


## 화면의 자리 = 뷰의 원점(중앙, 높이 0.62 + 간격의 이동 + 뛰어들기의 당김) + 번호 고리의 자리. 고리는 간격의 배율과 상관없이 같은 크기로 그려진다(뷰의 inverse).
func _screen_point(distance: int, pull: float, pos: Vector2) -> Vector2:
	var anchor := Vector2(SCREEN.x * 0.5, SCREEN.y * ANCHOR_RATIO)
	return anchor + Vector2(0.0, OpponentView.DISTANCE_SHIFT[distance] + OpponentView.DIVE_PULL_SHIFT * pull) + pos


## 지금 공격의 번호 고리 자리들(타격 순서). 높이를 넘기면 뇌의 strike_heights를 그것으로 덮는다.
func _ring_positions(opp: OpponentData, route: AttackData, heights: Array[int]) -> Array[Vector2]:
	var rng := _seeded()
	var brain := OpponentBrain.new(_drill_opp(opp, route), rng)
	brain.start_idle(0.0)
	brain.start_tell(0.0, false)
	if not heights.is_empty():
		brain.strike_heights = heights
	var out: Array[Vector2] = []
	if brain.pattern_root == null or brain.state != DT.OpponentState.TELL:
		return out
	if route.chain.is_empty():
		var h := brain.strike_heights[0] if not brain.strike_heights.is_empty() else -1
		out.append(OpponentView.ring_position(route.direction, h))
		return out
	for mark in OpponentView.pattern_marks(brain, 0.0):
		if mark["role"] == &"path":
			continue
		var pos: Vector2 = mark["pos"]
		out.append(pos)
	return out


## 높이의 모든 조합(타격마다 올 수 있는 높이. 높이가 없는 타격은 -1 하나).
func _height_combos(strikes: Array[AttackData]) -> Array[Array]:
	var combos: Array[Array] = [[]]
	for s in strikes:
		var options: Array = []
		if s.heights.is_empty():
			options.append(-1)
		for h in s.heights:
			if not options.has(h):
				options.append(h)
		var grown: Array[Array] = []
		for combo in combos:
			for h in options:
				var longer: Array = combo.duplicate()
				longer.append(h)
				grown.append(longer)
		combos = grown
	return combos


func _built_route(cells: Array, dive: bool) -> AttackData:
	var root: AttackData = null
	var chain: Array[Resource] = []
	for cell: Array in cells:
		var atk := AttackData.new()
		atk.direction = cell[0]
		var heights: Array[int] = [cell[1]]
		atk.heights = heights
		if root == null:
			root = atk
		else:
			chain.append(atk)
	root.chain = chain
	root.dive = dive
	return root


## 식이 맞는지 손 셈의 값에 맞춰 본다(결정 615의 본보기): 비킴 +36씩, 뛰어들기의 당김 −25, 밀착 +30.
func _ring_formula_samples(errs: Array[String]) -> void:
	var bartolo := load(BARTOLO_PATH) as OpponentData
	var none: Array[int] = []
	var L := DT.Direction.LEFT
	var C := DT.Direction.CENTER
	var R := DT.Direction.RIGHT
	var M := DT.Height.MID
	var H := DT.Height.HIGH
	var engage := DT.Distance.ENGAGE
	var close := DT.Distance.CLOSE
	# 왼중 → 가중 → 오중 → 가중: 넷째 고리는 둘째의 자리에서 한 번 비킨다.
	var returning := _ring_positions(bartolo, _built_route([[L, M], [C, M], [R, M], [C, M]], false), none)
	_expect_y(errs, "왼중·가중·오중·가중의 넷째 (교전)", returning, 3, engage, 0.0, 332.4)
	_expect_y(errs, "왼중·가중·오중·가중의 넷째 (밀착)", returning, 3, close, 0.0, 362.4)
	# 가운데 중단이 세 번(엇박 꼴): 셋째는 +72.
	var thrice := _ring_positions(bartolo, _built_route([[C, M], [C, M], [C, M]], false), none)
	_expect_y(errs, "가중 셋의 셋째 (교전)", thrice, 2, engage, 0.0, 368.4)
	_expect_y(errs, "가중 셋의 셋째 (밀착)", thrice, 2, close, 0.0, 398.4)
	# 뛰어들어 한 번 더의 상단 둘: 교전은 당김을 넣어 121.4 · 157.4, 밀착은 당김 없이 176.4 · 212.4.
	var dive_twice := _ring_positions(bartolo, _built_route([[C, H], [C, H]], true), none)
	_expect_y(errs, "뛰어든 상단의 첫째 (교전·당김)", dive_twice, 0, engage, 1.0, 121.4)
	_expect_y(errs, "뛰어든 상단의 둘째 (교전·당김)", dive_twice, 1, engage, 1.0, 157.4)
	_expect_y(errs, "뛰어든 상단의 첫째 (밀착)", dive_twice, 0, close, 0.0, 176.4)
	_expect_y(errs, "뛰어든 상단의 둘째 (밀착)", dive_twice, 1, close, 0.0, 212.4)


## index번째 고리의 화면 y가 손 셈의 값(want_y)과 같은가.
func _expect_y(errs: Array[String], label: String, positions: Array[Vector2], index: int, distance: int, pull: float, want_y: float) -> void:
	if index >= positions.size():
		_note(errs, "[식] %s: 고리가 %d개뿐이다" % [label, positions.size()])
		return
	var got := _screen_point(distance, pull, positions[index]).y
	if absf(got - want_y) > 0.01:
		_note(errs, "[식] %s: y %.2f (손 셈 %.2f)" % [label, got, want_y])


## ① 네 상대의 모든 단·모든 길(뿌리와 변주)과 주인 없는 공격에서 높이를 가진 타격의 번호 고리가 교전·밀착에서 제 칸에 든다.
func _ring_invariant(errs: Array[String]) -> void:
	var trials := SelectScript.load_trials()
	if trials.is_empty():
		errs.append("[고리] 연습의 상대가 없다")
		return
	var jobs: Array[Dictionary] = []
	var seen := {}
	for opp in trials:
		if not opp.use_heights:
			continue
		for attacks: Array in _tier_lists(opp):
			for atk: AttackData in attacks:
				for route in _routes(atk):
					if not seen.has(route.get_instance_id()):
						seen[route.get_instance_id()] = true
						jobs.append({"opp": opp, "route": route, "label": opp.display_name})
	for spare in SelectScript.load_spare_attacks():
		for route in _routes(spare):
			if not seen.has(route.get_instance_id()):
				seen[route.get_instance_id()] = true
				jobs.append({"opp": trials[0], "route": route, "label": "주인 없는 " + spare.attack_name})
	var checked := 0
	var far_total := 0
	var far_out := 0
	for job: Dictionary in jobs:
		var opp: OpponentData = job["opp"]
		var route: AttackData = job["route"]
		var solo := _solo(route)
		var strikes := _strike_list(solo)
		var pulls: Array[float] = [0.0]
		if solo.dive:
			pulls.append(1.0)
		for combo: Array in _height_combos(strikes):
			var heights: Array[int] = []
			for h in combo:
				heights.append(int(h))
			var positions := _ring_positions(opp, solo, heights)
			if positions.size() != strikes.size():
				_note(errs, "[고리] %s %s: 고리 %d개 (타격 %d개)" % [job["label"], route.attack_name, positions.size(), strikes.size()])
				continue
			for i in strikes.size():
				if heights[i] < 0:
					continue
				var want := Vector2i(strikes[i].direction, heights[i])
				for pull in pulls:
					for distance in [DT.Distance.FAR, DT.Distance.ENGAGE, DT.Distance.CLOSE]:
						var point := _screen_point(distance, pull, positions[i])
						var cell := DuelScene.aim_cell(point, SCREEN)
						if distance == DT.Distance.FAR:
							far_total += 1
							far_out += 1 if cell != want else 0
							continue
						checked += 1
						if cell != want:
							_note(errs, "[고리] %s %s 높이 %s의 %d번째: %s에서 화면 (%.1f, %.1f)이 칸 %s (기대 %s%s)" % [
								job["label"], route.attack_name, str(heights), i + 1, "교전" if distance == DT.Distance.ENGAGE else "밀착",
								point.x, point.y, str(cell), str(want), ", 당김 " + str(pull) if pull > 0.0 else ""])
	print("  INFO 고리의 칸: 길 %d개, 교전·밀착 %d번 잼 · 멀리 %d번 가운데 %d번이 제 칸 밖(적기만)" % [jobs.size(), checked, far_total, far_out])


## ② 층층 상중하의 번호 고리 셋은 x가 하나이고 y가 셋, 상중하중의 넷째 고리는 둘째의 자리 + 36.
func _ring_stair_shape(errs: Array[String]) -> void:
	var serafina := load(SERAFINA_PATH) as OpponentData
	if serafina == null or serafina.tiers.size() < 3:
		return
	var none: Array[int] = []
	var three := _route_by_seq(serafina.attacks, "012")
	var four := _route_by_seq(serafina.tiers[2].attacks, "0121")
	if three == null or four == null:
		errs.append("[고리·층층] 상중하(%s)나 상중하중(%s) 길이 없다" % [three != null, four != null])
		return
	var marks := _ring_positions(serafina, _solo(three), none)
	if marks.size() != 3:
		errs.append("[고리·층층] 상중하의 고리 %d개 (기대 3)" % marks.size())
	else:
		var ys := {}
		for m in marks:
			ys[snappedf(m.y, 0.01)] = true
		if not (is_equal_approx(marks[0].x, marks[1].x) and is_equal_approx(marks[1].x, marks[2].x)) or ys.size() != 3:
			errs.append("[고리·층층] 상중하의 x %s · y의 가짓수 %d (기대 x 하나 · y 셋)" % [str([marks[0].x, marks[1].x, marks[2].x]), ys.size()])
	var four_marks := _ring_positions(serafina, _solo(four), none)
	if four_marks.size() != 4:
		errs.append("[고리·층층] 상중하중의 고리 %d개 (기대 4)" % four_marks.size())
	elif four_marks[3] != four_marks[1] + Vector2(0.0, OpponentView.MARK_REPEAT_SHIFT):
		errs.append("[고리·층층] 상중하중의 넷째 %s (기대 둘째 %s + 비킴 %.0f)" % [str(four_marks[3]), str(four_marks[1]), OpponentView.MARK_REPEAT_SHIFT])


## ③ 연습 화면: 세라피나의 칸과 주인 없는 검술의 칸.
func _reset_statics() -> void:
	SelectScript._opening_day = 1
	SelectScript._part_effects = false
	SelectScript._style_tier = 0
	SelectScript._picked_opponent = 0
	SelectScript._picked_commission = 0


func _free_select() -> void:
	if _select != null and is_instance_valid(_select):
		if _select.get_parent() != null:
			_select.get_parent().remove_child(_select)
		_select.free()
	_select = null
	_reset_statics()


func _help_has(text: String, line: String) -> bool:
	return text.contains(line.trim_prefix(" · "))


func _practice_checks(errs: Array[String]) -> void:
	var trials := SelectScript.load_trials()
	var index := -1
	for i in trials.size():
		if trials[i].resource_path == SERAFINA_PATH:
			index = i
	if index < 0:
		errs.append("[연습] load_trials()에 세라피나가 없다")
		return
	_select = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(_select)
	_select.call("pick_opponent", index)
	var head := _select.find_child("TrialHead", true, false)
	var head_texts: Array[String] = []
	if head != null:
		for label in head.find_children("*", "Label", true, false):
			head_texts.append((label as Label).text)
	if not head_texts.has("세라피나") or not head_texts.has(STYLE_NAME):
		errs.append("[연습] TrialHead의 글 %s에 '세라피나'와 '층층 찌르기'가 없다" % str(head_texts))
	var pick := _select.find_child("StyleTierPick", true, false) as OptionButton
	if pick == null or pick.item_count != 6:
		errs.append("[연습] StyleTierPick의 항목 %s (기대 6)" % ("없음" if pick == null else str(pick.item_count)))
	_check_drill_and_help(errs, "1단")
	if pick != null:
		pick.item_selected.emit(5)
		_check_drill_and_help(errs, "6단")
	# 상대 목록의 끝 줄(주인 없는 검술).
	_reset_statics()
	_select.call("pick_opponent", trials.size())
	var spare_count := _select.find_children("SpareDrill*", "Button", true, false).size()
	if spare_count != 1:
		errs.append("[연습] 주인 없는 검술의 SpareDrill %d개 (기대 1)" % spare_count)


func _check_drill_and_help(errs: Array[String], label: String) -> void:
	var drills := _select.find_children("PatternDrill*", "Button", true, false)
	if drills.size() != 1:
		errs.append("[연습 %s] PatternDrill %d개 (기대 1)" % [label, drills.size()])
	elif (drills[0] as Button).text != STYLE_NAME:
		errs.append("[연습 %s] PatternDrill의 글 '%s' (기대 '%s')" % [label, (drills[0] as Button).text, STYLE_NAME])
	if _select.find_child("SlashDrill", true, false) != null:
		errs.append("[연습 %s] 세라피나에게 SlashDrill이 있다" % label)
	var help_node := _select.find_child("PatternHelp", true, false) as Label
	if help_node == null:
		errs.append("[연습 %s] PatternHelp가 없다" % label)
		return
	var text := help_node.text
	if not _help_has(text, DuelHud.HELP_CHAIN) or not _help_has(text, DuelHud.HELP_HEIGHT):
		errs.append("[연습 %s] 막는 법에 이어 치기 줄(%s)이나 높이 줄(%s)이 없다" % [label, _help_has(text, DuelHud.HELP_CHAIN), _help_has(text, DuelHud.HELP_HEIGHT)])
	if _help_has(text, DuelHud.HELP_SWEEP) or _help_has(text, DuelHud.HELP_DIVE):
		errs.append("[연습 %s] 막는 법에 휩쓸기(%s)나 뛰어들기(%s) 줄이 있다" % [label, _help_has(text, DuelHud.HELP_SWEEP), _help_has(text, DuelHud.HELP_DIVE)])
