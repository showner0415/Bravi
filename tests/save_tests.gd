extends RefCounted
## T56~T58: 저장 — 아침을 내주고 아침으로 되돌리기(값), 저장 파일과 GameSession, 처음 화면·카운터·폐점의 글.
## 하루의 도우미(고정 점수 의뢰, 손으로 만든 기록, 화면 붙이기)는 day_tests.gd의 것을 쓴다.
## 통과 조건은 테스트가 직접 만든 규칙으로 본다(.tres의 값과 상관없다). 로드한 데이터를 쓰는 T57의 GameSession은
## 절대값이 아니라 "적은 값 = 하루의 값"으로 견준다.
## 파일은 TEST_PATH만 쓴다(처음과 끝에 지운다). 게임의 저장 파일은 읽지도 쓰지도 않는다.

const Day := preload("res://tests/day_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Store := preload("res://scripts/save_store.gd")
const TEST_PATH := "user://bravi_test_save.json"

var _tree: SceneTree
var _d := Day.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T56", "name": "저장의 내용: 아침을 내주고 아침으로 되돌린다 (250 → 322 → 72 → 169)", "fn": t56_saved_state},
		{"id": "T57", "name": "저장 파일과 GameSession: 쓰고, 읽고, 깨진 파일, 꺼진 저장", "fn": t57_file_and_session},
		{"id": "T58", "name": "저장의 화면: 이어서 한다, 새로 시작한다, 카운터와 폐점의 한 줄", "fn": t58_screens},
	]


func cleanup() -> void:
	Store.erase(TEST_PATH)
	_d.cleanup()
	_d = null
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


## 장부의 경제 규칙(T31·T35와 같다): 팁 문턱 70, 임대료 60, 치료비 20, 시작 소지금 250.
func _ledger_rules() -> EconomyRules:
	var rules: EconomyRules = _d._rules(70, 60, 20, 250)
	return rules


## 고정 하루(셋)와 테스트의 업그레이드 셋(40 / 90 / 120)을 가진 새 하루. with_reputation이 참이면 평판 규칙을 넣는다.
func _new_day(rules: EconomyRules, with_reputation := false) -> DayState:
	var upgrades: Array[UpgradeData] = _d._test_upgrades()
	var catalog: UpgradeCatalog = _d._catalog(upgrades)
	var data: DayData = _d._three_fixed()
	if with_reputation:
		return DayState.new(rules, data, catalog, null, _rep_rules())
	return DayState.new(rules, data, catalog)


## 테스트가 직접 만든 평판 규칙: 시작 9(별 3), 0~20, 문턱 4·8·12·16.
func _rep_rules() -> ReputationRules:
	var rep := ReputationRules.new()
	rep.enabled = true
	rep.start = 9
	rep.min_value = 0
	rep.max_value = 20
	rep.star_thresholds = PackedInt32Array([4, 8, 12, 16])
	rep.guest_delta = PackedInt32Array([0, 0, 0, 0, 0])
	rep.perfect_bonus = 1
	return rep


## 하루를 폐점까지 밀고 업그레이드를 전부 산다(소지금 250 → 322 → 72).
func _close_and_buy_all(day: DayState) -> void:
	_d._run_fixed_day(day)
	if day.catalog != null:
		for upgrade in day.catalog.upgrades:
			day.buy(upgrade)


## 저장된 값을 새 하루에 되돌린 것. 읽을 수 없는 저장이어도 그 하루를 돌려준다(되돌리지 못한 채다).
func _restored(saved: Dictionary, with_reputation := false) -> DayState:
	var day := _new_day(_ledger_rules(), with_reputation)
	day.restore(saved)
	return day


## 날을 넘는 것과 단계.
func _snapshot(day: DayState) -> Array:
	return [day.day_number, day.money, day.owned.duplicate(), day.reputation, day.dice_seed, day.phase]


## TEST_PATH에 글을 그대로 적는다(깨진 파일을 만든다). ASCII만 쓴다.
func _write_text(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


## 처음 화면에 저장(되돌린 하루)과 "읽을 수 없다"를 직접 넣어 붙인다. 호출한 쪽이 free()한다.
func _spawn_title(saved: DayState, unreadable := false) -> Node:
	var screen: Node = (load(Session.TITLE_PATH) as PackedScene).instantiate()
	if saved != null:
		screen.set("saved", saved)
	if unreadable:
		screen.set("save_unreadable", true)
	_tree.root.add_child(screen)
	return screen


func _button_count(screen: Node) -> int:
	return screen.find_children("*", "Button", true, false).size()


# ================================================================ T56 저장의 내용

func t56_saved_state() -> String:
	var errs: Array[String] = []
	_check_morning(errs)
	_check_closing_and_restore(errs)
	_check_fixed_values(errs)
	_check_unreadable(errs)
	_check_dice(errs)
	return _result(errs)


## 가·나. 새 하루의 아침은 적히고, 하루 중에는 적을 것이 없다.
func _check_morning(errs: Array[String]) -> void:
	var P := DayState.Phase
	var day := _new_day(_ledger_rules())
	var morning: Dictionary = day.saved_state()
	var morning_owned: Variant = morning.get("owned")
	_expect(errs, int(morning.get("version", 0)) == DayState.SAVE_VERSION and int(morning.get("day", 0)) == 1
		and int(morning.get("money", -1)) == 250,
		"[가] 새 하루의 저장: 버전 %s, 날 %s, 소지금 %s (기대 1, 1, 250)" % [
			str(morning.get("version")), str(morning.get("day")), str(morning.get("money"))])
	_expect(errs, morning_owned is Array and str(morning_owned) == "[]", "[가] 새 하루의 저장의 owned %s (기대 빈 배열)" % str(morning_owned))
	_expect(errs, int(morning.get("dice_seed", -1)) == day.dice_seed and day.dice_seed >= 0 and day.dice_seed <= DayState.DICE_SEED_MAX,
		"[가] 저장의 씨앗 %s, 하루의 씨앗 %d" % [str(morning.get("dice_seed")), day.dice_seed])

	day.accept()
	_expect(errs, day.phase == P.DUEL and day.saved_state().is_empty(), "[나] 결투 단계인데 적을 아침이 있음")
	day.finish_duel(_d._record(DT.EndReason.CONDITION))
	_expect(errs, day.phase == P.SETTLEMENT and day.saved_state().is_empty(), "[나] 정산 단계인데 적을 아침이 있음")
	var sent := _new_day(_ledger_rules())
	sent.decline()
	_expect(errs, sent.phase == P.COUNTER and sent.index == 1 and sent.saved_state().is_empty(),
		"[나] 첫 손님을 돌려보낸 뒤의 카운터인데 적을 아침이 있음")


## 다·라. 폐점은 내일의 아침을 내주고, JSON을 지나 되돌린 하루는 다음 날로 넘어간 하루와 같다.
func _check_closing_and_restore(errs: Array[String]) -> void:
	var P := DayState.Phase
	var rules := _ledger_rules()
	var ledger := _new_day(rules)
	_d._run_fixed_day(ledger)
	var closed: Dictionary = ledger.saved_state()
	_expect(errs, int(closed.get("day", 0)) == 2 and int(closed.get("money", 0)) == 322,
		"[다] 폐점의 저장: 날 %s, 소지금 %s (기대 2, 322)" % [str(closed.get("day")), str(closed.get("money"))])
	var upgrades := ledger.catalog.upgrades
	ledger.buy(upgrades[0])
	var one: Dictionary = ledger.saved_state()
	_expect(errs, int(one.get("money", 0)) == 282 and str(one.get("owned")) == str(["t_medicine"]),
		"[다] 40짜리를 산 뒤의 저장: 소지금 %s, owned %s (기대 282, [\"t_medicine\"])" % [str(one.get("money")), str(one.get("owned"))])
	ledger.buy(upgrades[1])
	ledger.buy(upgrades[2])
	var full: Dictionary = ledger.saved_state()
	_expect(errs, int(full.get("money", 0)) == 72 and str(full.get("owned")) == str(["t_medicine", "t_chair", "t_vest"]),
		"[다] 셋을 산 뒤의 저장: 소지금 %s, owned %s (기대 72, 셋)" % [str(full.get("money")), str(full.get("owned"))])

	var json := JSON.new()
	var loaded: Dictionary = {}
	if json.parse(JSON.stringify(full)) == OK and json.data is Dictionary:
		loaded = json.data
	_expect(errs, not loaded.is_empty(), "[라] 저장이 JSON을 지나지 못함")
	var back := _new_day(rules)
	_expect(errs, back.restore(loaded), "[라] JSON을 지난 저장을 되돌리지 못함")
	_expect(errs, back.day_number == 2 and back.money == 72 and back.owned.size() == 3,
		"[라] 되돌린 하루: %d일차, 소지금 %d, 가진 것 %d (기대 2, 72, 3)" % [back.day_number, back.money, back.owned.size()])
	_expect(errs, back.phase == P.COUNTER and back.index == 0 and back.results.is_empty() and back.dice_seed == ledger.dice_seed,
		"[라] 되돌린 하루: 단계 %d, 순번 %d, 씨앗 %d (기대 카운터, 0, %d)" % [back.phase, back.index, back.dice_seed, ledger.dice_seed])
	ledger.next_day()
	_expect(errs, back.day_number == ledger.day_number and back.money == ledger.money and back.owned == ledger.owned
		and back.commission_count() == ledger.commission_count(), "[라] 되돌린 하루가 다음 날로 넘어간 하루와 다름")
	# 가진 것의 효과가 살아 있다(T35의 2일차와 같은 폐점 소지금).
	_d._run_fixed_day(back)
	_expect(errs, back.money == 169, "[라] 되돌린 하루의 폐점 소지금 %d (기대 169)" % back.money)


## 마. 저장된 값은 믿지 않는다: 가진 것은 목록에 있는 것만, 날은 1 이상, 평판은 범위로.
func _check_fixed_values(errs: Array[String]) -> void:
	var twice := _restored({"version": 1, "day": 3, "money": 5, "owned": ["nope", "t_chair", "t_chair"]})
	_expect(errs, twice.day_number == 3 and twice.owned.size() == 1 and twice.owned[0] == &"t_chair",
		"[마] 모르는 id와 겹친 id: 가진 것 %s (기대 t_chair 하나)" % str(twice.owned))
	var text_owned := _restored({"version": 1, "day": 3, "money": 5, "owned": "t_chair"})
	_expect(errs, text_owned.day_number == 3 and text_owned.owned.is_empty(), "[마] owned가 글: 가진 것 %s (기대 없음)" % str(text_owned.owned))
	var zero_day := _restored({"version": 1, "day": 0, "money": 5})
	_expect(errs, zero_day.day_number == 1 and zero_day.money == 5, "[마] 날 0: %d일차 (기대 1)" % zero_day.day_number)
	var float_day := _restored({"version": 1.0, "day": 2.0, "money": 5.0})
	_expect(errs, float_day.day_number == 2 and float_day.money == 5, "[마] 날 2.0: %d일차, 소지금 %d (기대 2, 5)" % [float_day.day_number, float_day.money])

	# 평판 규칙: 시작 9, 0~20.
	var rows := [[999, 20], [-5, 0], ["많다", 9], [13, 13]]
	for row: Array in rows:
		var day := _restored({"version": 1, "day": 3, "money": 5, "reputation": row[0]}, true)
		_expect(errs, day.day_number == 3 and day.reputation == int(row[1]),
			"[마] 저장의 평판 %s: 평판 %d (기대 %d)" % [str(row[0]), day.reputation, int(row[1])])
	var kept := _restored({"version": 1, "day": 3, "money": 5, "reputation": 13}, true)
	_expect(errs, kept.day_start_reputation == 13 and kept.reputation_stars() == 4,
		"[마] 평판 13: 그날 시작의 평판 %d, 별 %d (기대 13, 4)" % [kept.day_start_reputation, kept.reputation_stars()])
	var plain := _restored({"version": 1, "day": 3, "money": 5, "reputation": 13})
	_expect(errs, plain.reputation == 0, "[마] 평판이 없는 하루에 저장의 평판이 들어감 (%d)" % plain.reputation)


## 바. 읽을 수 없는 저장은 아무것도 바꾸지 않는다.
func _check_unreadable(errs: Array[String]) -> void:
	var cases: Array[Dictionary] = [
		{"version": 2, "day": 2, "money": 10},
		{"day": 2, "money": 10},
		{"version": 1, "day": "둘", "money": 10},
		{"version": 1, "day": 2},
		{},
	]
	for i in cases.size():
		var day := _new_day(_ledger_rules(), true)
		var before := _snapshot(day)
		_expect(errs, not DayState.is_readable_save(cases[i]) and not day.restore(cases[i]) and _snapshot(day) == before,
			"[바] 읽을 수 없는 저장 %d번이 읽히거나 하루를 바꿈" % i)


## 사. 흥정의 주사위는 씨앗·날·순번으로 정해진다. 되돌린 하루도 같은 주사위이고, 인자 없는 흥정이 그것을 쓴다.
func _check_dice(errs: Array[String]) -> void:
	var rules := _ledger_rules()
	var origin := _new_day(rules)
	_d._run_fixed_day(origin)
	var twin := _new_day(rules)
	_expect(errs, twin.restore(origin.saved_state()), "[사] 폐점의 저장을 되돌리지 못함")
	origin.next_day()
	for i in 3:
		var a := origin.haggle_roll()
		var b := twin.haggle_roll()
		_expect(errs, a == b and a == origin.haggle_roll() and a >= 0 and a <= 99,
			"[사] 순번 %d의 주사위: 원래 하루 %d, 되돌린 하루 %d (기대: 같고 0~99)" % [i, a, b])
		if i < 2:
			origin.decline()
			twin.decline()

	# 흥정이 켜진 규칙: 확률은 늘 50이다(표가 한 칸). 받아 줌은 주사위가 50보다 작을 때다.
	var economy: EconomyRules = _d._rules(70, 60, 20, 0)
	economy.haggle_bonus_percent = 30
	economy.haggle_chance_met = PackedInt32Array([50])
	economy.haggle_chance_short = PackedInt32Array([50])
	for seed_value: int in [0, 1, 12345, DayState.DICE_SEED_MAX]:
		var data: DayData = _d._three_fixed()
		for commission in data.commissions:
			commission.haggle_min_stars = 1
		var day := DayState.new(economy, data, null, null, _rep_rules())
		day.dice_seed = seed_value
		for i in 3:
			var want := day.haggle_roll() < day.haggle_chance()
			var pressed := day.haggle()
			_expect(errs, day.haggle_chance() == 50 and pressed and (day.haggle_state() == DayState.Haggle.AGREED) == want,
				"[사] 씨앗 %d, 순번 %d: 인자 없는 흥정이 정해진 주사위와 다름" % [seed_value, i])
			if i < 2:
				day.decline()


# ================================================================ T57 저장 파일과 GameSession

func t57_file_and_session() -> String:
	var errs: Array[String] = []
	Store.erase(TEST_PATH)
	_check_store(errs)
	_check_session_off(errs)
	_check_session_file(errs)
	_check_runner(errs)
	Store.erase(TEST_PATH)
	return _result(errs)


## 가·나. 파일의 왕복과 깨진 파일.
func _check_store(errs: Array[String]) -> void:
	_expect(errs, not Store.exists(TEST_PATH) and Store.read(TEST_PATH).is_empty(), "[가] 지운 뒤에 파일이 있거나 읽힘")
	var content := {"version": 1, "day": 4, "money": -78, "owned": ["a", "b"]}
	_expect(errs, Store.write(TEST_PATH, content) and Store.exists(TEST_PATH), "[가] 쓰지 못했거나 쓴 뒤에 파일이 없음")
	var got: Dictionary = Store.read(TEST_PATH)
	var got_owned: Variant = got.get("owned")
	_expect(errs, int(got.get("day", 0)) == 4 and int(got.get("money", 0)) == -78 and got_owned is Array and str(got_owned) == str(["a", "b"]),
		"[가] 읽은 값: 날 %s, 소지금 %s, owned %s (기대 4, -78, [\"a\", \"b\"])" % [str(got.get("day")), str(got.get("money")), str(got_owned)])

	for text: String in ["{{{ not json", "[1, 2]", ""]:
		_write_text(text)
		_expect(errs, Store.exists(TEST_PATH) and Store.read(TEST_PATH).is_empty(), "[나] 내용이 '%s'인 파일이 읽힘" % text)
	_expect(errs, Store.read("").is_empty() and not Store.write("", content) and not Store.exists(""), "[나] 빈 경로가 읽히거나 쓰임")
	Store.erase(TEST_PATH)


## 다. 트리 밖에서 만든 GameSession은 저장이 꺼져 있다: 파일을 만들지 않는다.
func _check_session_off(errs: Array[String]) -> void:
	var off: Node = Session.new()
	_expect(errs, str(off.get("save_path")) == "", "[다] 새로 만든 GameSession의 save_path '%s' (기대: 빈 글)" % str(off.get("save_path")))
	off.call("start_day_play")
	_expect(errs, off.get("day") is DayState and not Store.exists(TEST_PATH), "[다] 저장이 꺼진 채 시작: 하루가 없거나 파일이 생김")
	_expect(errs, not bool(off.call("save_game")) and not bool(off.call("continue_day_play")) and not bool(off.call("save_exists")),
		"[다] 저장이 꺼졌는데 적거나, 잇거나, 파일이 있다고 함")
	_expect(errs, int(off.get("saved_day")) == 0, "[다] 저장이 꺼졌는데 saved_day %d (기대 0)" % int(off.get("saved_day")))
	off.free()


## 라·마·바. 적는 때, 이어서 하기, 읽을 수 없는 파일.
func _check_session_file(errs: Array[String]) -> void:
	var P := DayState.Phase
	var writer: Node = Session.new()
	writer.set("save_path", TEST_PATH)
	writer.call("start_day_play")
	var day: DayState = writer.get("day") as DayState
	if day == null:
		errs.append("[라] start_day_play 뒤에 하루가 없음")
		writer.free()
		return

	var file1: Dictionary = Store.read(TEST_PATH)
	_expect(errs, int(file1.get("day", 0)) == 1 and int(file1.get("money", -999999)) == day.rules.starting_money
		and int(writer.get("saved_day")) == 1,
		"[라] 새로 시작한 뒤의 파일: 날 %s, 소지금 %s, saved_day %d (기대 1, %d, 1)" % [
			str(file1.get("day")), str(file1.get("money")), int(writer.get("saved_day")), day.rules.starting_money])
	_expect(errs, int(file1.get("reputation", -1)) == day.reputation and int(file1.get("dice_seed", -1)) == day.dice_seed,
		"[라] 새로 시작한 뒤의 파일의 평판 %s, 씨앗 %s (하루 %d, %d)" % [
			str(file1.get("reputation")), str(file1.get("dice_seed")), day.reputation, day.dice_seed])

	# 하루 중에는 적지 않는다(파일은 그날 아침 그대로다).
	if day.waiting_count() > 0:
		day.decline()
		var mid: Dictionary = Store.read(TEST_PATH)
		_expect(errs, not bool(writer.call("save_game")) and int(mid.get("day", 0)) == 1 and int(writer.get("saved_day")) == 1,
			"[라] 하루 중에 저장이 적힘")
	var guard := 0
	while day.phase == P.COUNTER and guard < 50:
		day.decline()
		guard += 1
	_expect(errs, day.phase == P.CLOSING, "[라] 손님을 전부 돌려보냈는데 폐점이 아님")
	_expect(errs, bool(writer.call("save_game")) and int(writer.get("saved_day")) == 2,
		"[라] 폐점에서 적지 못했거나 saved_day %d (기대 2)" % int(writer.get("saved_day")))
	var file2: Dictionary = Store.read(TEST_PATH)
	_expect(errs, int(file2.get("day", 0)) == 2 and int(file2.get("money", -999999)) == day.money
		and int(file2.get("reputation", -1)) == day.reputation,
		"[라] 폐점의 파일: 날 %s, 소지금 %s, 평판 %s (기대 2, %d, %d)" % [
			str(file2.get("day")), str(file2.get("money")), str(file2.get("reputation")), day.money, day.reputation])

	var reader: Node = Session.new()
	reader.set("save_path", TEST_PATH)
	var peek: DayState = reader.call("load_saved_day") as DayState
	_expect(errs, peek != null and reader.get("day") == null, "[마] load_saved_day가 null이거나 day를 건드림")
	_expect(errs, bool(reader.call("continue_day_play")), "[마] 이어서 하지 못함")
	var resumed: DayState = reader.get("day") as DayState
	day.next_day()
	if resumed == null:
		errs.append("[마] 이어서 한 뒤에 하루가 없음")
	else:
		_expect(errs, resumed.day_number == 2 and resumed.money == day.money and resumed.reputation == day.reputation
			and resumed.dice_seed == day.dice_seed,
			"[마] 이어서 한 하루: %d일차, 소지금 %d, 평판 %d (기대 2, %d, %d)" % [
				resumed.day_number, resumed.money, resumed.reputation, day.money, day.reputation])
		_expect(errs, resumed.phase == day.phase and resumed.commission_count() == day.commission_count() and resumed.data == day.data,
			"[마] 이어서 한 하루가 다음 날로 넘어간 하루와 다름 (단계 %d / %d, 손님 %d / %d)" % [
				resumed.phase, day.phase, resumed.commission_count(), day.commission_count()])

	_write_text("{{{")
	_expect(errs, bool(reader.call("save_exists")) and reader.call("load_saved_day") == null
		and not bool(reader.call("continue_day_play")) and reader.get("day") == resumed,
		"[바] 깨진 파일: 파일이 없다고 하거나, 읽히거나, 하루가 바뀜")
	Store.write(TEST_PATH, {"version": 2, "day": 2, "money": 10})
	_expect(errs, bool(reader.call("save_exists")) and reader.call("load_saved_day") == null
		and not bool(reader.call("continue_day_play")) and reader.get("day") == resumed,
		"[바] 버전 2의 저장: 파일이 없다고 하거나, 읽히거나, 하루가 바뀜")

	writer.free()
	reader.free()


## 사. 러너에 오토로드 GameSession이 떠 있으면 저장이 꺼져 있다(러너가 비웠다). 없으면 볼 것이 없다.
func _check_runner(errs: Array[String]) -> void:
	var autoload := _tree.root.get_node_or_null(^"GameSession")
	if autoload != null:
		_expect(errs, str(autoload.get("save_path")) == "",
			"[사] 러너의 오토로드 GameSession의 save_path '%s' (기대: 빈 글)" % str(autoload.get("save_path")))


# ================================================================ T58 저장의 화면

func t58_screens() -> String:
	var errs: Array[String] = []

	# 가. 저장이 없는 처음 화면(세션이 없거나 저장이 꺼져 있다).
	var fresh := _spawn_title(null)
	_expect(errs, _button_count(fresh) == 5 and _d._has_node(fresh, "Proceed") and _d._has_node(fresh, "Practice") and _d._has_node(fresh, "Help") and _d._has_node(fresh, "Settings") and _d._has_node(fresh, "QuitGame"),
		"[가] 저장이 없는 처음 화면의 버튼 %d개 (기대 5: Proceed, Practice, Help, Settings, QuitGame)" % _button_count(fresh))
	_expect(errs, not _d._has_node(fresh, "Continue") and not _d._has_node(fresh, "NewGame") and not _d._has_node(fresh, "SaveUnreadable"),
		"[가] 저장이 없는 처음 화면에 Continue·NewGame·SaveUnreadable이 있음")
	_expect(errs, not _d._has_node(fresh, "HelpScreen") and not _d._has_node(fresh, "HelpClose"), "[가] 열기 전인데 HelpScreen·HelpClose가 있음")
	fresh.free()

	# 나. 읽을 수 없는 저장.
	var broken := _spawn_title(null, true)
	_expect(errs, _button_count(broken) == 5 and _d._has_node(broken, "Proceed") and _d._has_node(broken, "Help") and _d._has_node(broken, "SaveUnreadable")
		and not _d._has_node(broken, "HelpScreen"),
		"[나] 읽을 수 없는 저장의 처음 화면: 버튼 %d개 (기대 5와 SaveUnreadable, HelpScreen 없음)" % _button_count(broken))
	broken.free()

	# 다. 저장이 있는 처음 화면: 2일차, 소지금 72, 가진 것 셋, 평판 없음.
	var ledger := _new_day(_ledger_rules())
	_close_and_buy_all(ledger)
	var saved := _restored(ledger.saved_state())
	var title := _spawn_title(saved)
	var resume := title.find_child("Continue", true, false) as Button
	var info: String = _d._label_text(title, "SaveInfo")
	_expect(errs, _button_count(title) == 6 and resume != null and _d._has_node(title, "NewGame") and _d._has_node(title, "Practice")
		and _d._has_node(title, "Help") and _d._has_node(title, "Settings") and _d._has_node(title, "QuitGame") and not _d._has_node(title, "HelpScreen")
		and not _d._has_node(title, "Proceed"), "[다] 저장이 있는 처음 화면의 버튼 %d개 (기대 6: Continue, NewGame, Practice, Help, Settings, QuitGame)" % _button_count(title))
	_expect(errs, resume != null and resume.text.contains("2일차"), "[다] Continue의 글에 '2일차'가 없음")
	_expect(errs, info.contains("소지금 72") and info.contains("3개") and not info.contains("평판"),
		"[다] SaveInfo '%s' (기대: '소지금 72', '3개', 평판 없음)" % info)
	_expect(errs, resume != null and _tree.root.gui_get_focus_owner() == resume, "[다] 포커스가 Continue에 없음")

	# 라. 새로 시작한다: 한 번은 알리기만 하고, 한 번 더 눌러도 붙인 화면은 아무 데도 가지 않는다.
	_expect(errs, not _d._has_node(title, "NewGameWarning"), "[라] 누르기 전에 NewGameWarning이 있음")
	_d._press(title, "NewGame")
	var new_game := title.find_child("NewGame", true, false) as Button
	var warning: String = _d._label_text(title, "NewGameWarning")
	_expect(errs, new_game != null and new_game.text.contains("한 번 더"), "[라] 한 번 누른 뒤 NewGame의 글에 '한 번 더'가 없음")
	_expect(errs, warning.contains("2일차") and warning.contains("지워진다"), "[라] NewGameWarning '%s' (기대: '2일차', '지워진다')" % warning)
	_d._press(title, "NewGame")
	_expect(errs, title.is_inside_tree() and _button_count(title) == 6 and saved.day_number == 2 and saved.money == 72,
		"[라] 두 번 누른 뒤 붙인 화면이나 저장이 달라짐")
	title.free()

	# 마. 평판이 있는 저장: 3일차, 소지금 142, 가진 것 하나, 평판 13(별 4/5).
	var rep_saved := _restored({"version": 1, "day": 3, "money": 142, "owned": ["t_chair"], "reputation": 13}, true)
	var rep_title := _spawn_title(rep_saved)
	var rep_resume := rep_title.find_child("Continue", true, false) as Button
	var rep_info: String = _d._label_text(rep_title, "SaveInfo")
	_expect(errs, rep_resume != null and rep_resume.text.contains("3일차"), "[마] Continue의 글에 '3일차'가 없음")
	_expect(errs, rep_info.contains("소지금 142") and rep_info.contains("1개") and rep_info.contains("평판 별 4/5"),
		"[마] SaveInfo '%s' (기대: '소지금 142', '1개', '평판 별 4/5')" % rep_info)
	rep_title.free()

	# 바. 카운터의 한 줄은 늘 있고, 러너에서 붙인 폐점에는 "저장했다"가 없다(적은 적이 없다).
	var day := _new_day(_ledger_rules())
	var counter: Node = _d._spawn_screen(Session.COUNTER_PATH, day)
	var quit_note: String = _d._label_text(counter, "QuitNote")
	_expect(errs, quit_note.contains("아침") and _d._has_node(counter, "Quit"), "[바] 카운터의 QuitNote '%s' (기대: '아침'을 담는다)" % quit_note)
	counter.free()
	_d._run_fixed_day(day)
	var closing: Node = _d._spawn_screen(Session.CLOSING_PATH, day)
	_expect(errs, _d._has_node(closing, "Quit") and not _d._has_node(closing, "SavedNote"), "[바] 러너에서 붙인 폐점에 SavedNote가 있음")
	closing.free()
	return _result(errs)
