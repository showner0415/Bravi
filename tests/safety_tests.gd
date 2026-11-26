extends RefCounted
## T60~T62: 2단계 점검(계획 018) — 겹친 누름, 저장의 쓰기, 헷갈리던 표기.
## 입력의 시각은 러너에서 실제로 기다릴 수 없어(모든 테스트가 한 프레임에 돈다) 시각을 인자로 받는 순수 함수를 본다.
## 실제 누름은 playtester가 본다. 하루의 도우미(규칙, 고정 점수 하루, 화면 붙이기)는 day_tests.gd의 것을 쓴다.
## 파일은 TEST_PATH와 그 임시 파일만 쓴다(처음과 끝에 지운다). 게임의 저장 파일은 읽지도 쓰지도 않는다.

const Day := preload("res://tests/day_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")
const Title := preload("res://scripts/title.gd")
const Closing := preload("res://scripts/economy/closing.gd")
const Store := preload("res://scripts/save_store.gd")
const TEST_PATH := "user://bravi_test_save_atomic.json"

var _tree: SceneTree
var _d := Day.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T60", "name": "겹친 누름: 처음 화면의 두 번째 누름, 화면이 열린 직후의 누름", "fn": t60_double_press},
		{"id": "T61", "name": "저장의 쓰기: 임시 파일에 적고 바꿔 끼운다", "fn": t61_atomic_write},
		{"id": "T62", "name": "헷갈리던 표기: 카운터의 남은 결투, 폐점의 0, 폐점의 소지금, 정산의 분모", "fn": t62_labels},
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


## 폐점 장부의 줄(Ledger<key>)에서 Name이나 Value의 글. 없으면 빈 글.
func _ledger(screen: Node, key: String, part: String) -> String:
	var row := screen.find_child("Ledger" + key, true, false)
	var label: Label = row.find_child(part, true, false) as Label if row != null else null
	return label.text if label != null else ""


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


## 그 파일에 글을 그대로 적는다(깨진 파일이나 바꿔 끼우기 전의 임시 파일을 만든다). ASCII만 쓴다.
func _write_raw(file_path: String, text: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


## 읽은 저장의 날. 없으면 0.
func _day_of(saved: Dictionary) -> int:
	return int(saved.get("day", 0))


## 그 스크립트가 직접 정의한 함수인가(Node가 원래 가진 가상 함수와 가르려고 스크립트의 목록을 본다).
func _script_defines(node: Node, method_name: String) -> bool:
	var script := node.get_script() as Script
	if script == null:
		return false
	for method: Dictionary in script.get_script_method_list():
		if String(method.get("name", "")) == method_name:
			return true
	return false


# ================================================================ T60 겹친 누름

func t60_double_press() -> String:
	var errs: Array[String] = []

	# 가. 화면이 열린 직후의 누름(열린 때 1000).
	var guard := Ui.ARRIVAL_GUARD_MSEC
	_expect(errs, guard > 0, "[가] ARRIVAL_GUARD_MSEC %d (기대: 0보다 큼)" % guard)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	var motion := InputEventMouseMotion.new()
	_expect(errs, Ui.is_arrival_press(click, 1000, 1000), "[가] 열린 그때의 클릭을 삼키지 않음")
	_expect(errs, Ui.is_arrival_press(click, 1000, 1000 + guard - 1), "[가] 막는 시간 끝 직전의 클릭을 삼키지 않음")
	_expect(errs, not Ui.is_arrival_press(click, 1000, 1000 + guard), "[가] 막는 시간이 지난 클릭을 삼킴")
	_expect(errs, Ui.is_arrival_press(key, 1000, 1100), "[가] 열린 직후의 Space를 삼키지 않음")
	_expect(errs, not Ui.is_arrival_press(motion, 1000, 1000), "[가] 마우스 움직임을 누름으로 봄")

	# 나. "새로 시작한다"의 두 번째 누름(첫 누름 1000).
	var lock := Title.NEW_GAME_LOCK_MSEC
	_expect(errs, lock > 0, "[나] NEW_GAME_LOCK_MSEC %d (기대: 0보다 큼)" % lock)
	_expect(errs, not Title.can_confirm_new_game(1000, 1000), "[나] 첫 누름과 같은 때의 두 번째 누름을 받음")
	_expect(errs, not Title.can_confirm_new_game(1000, 1000 + lock - 1), "[나] 잠금 끝 직전의 두 번째 누름을 받음")
	_expect(errs, Title.can_confirm_new_game(1000, 1000 + lock), "[나] 잠금이 지난 두 번째 누름을 받지 않음")

	# 다. 세 화면이 열린 직후의 누름을 삼키는 함수를 가진다(트리에 붙이지 않는다. _ready가 돌지 않는다).
	var paths: Array[String] = [Session.COUNTER_PATH, Session.SETTLEMENT_PATH, Session.CLOSING_PATH]
	for path in paths:
		var screen: Node = (load(path) as PackedScene).instantiate()
		_expect(errs, _script_defines(screen, "_input"), "[다] %s 에 _input이 없음" % path)
		screen.free()
	return _result(errs)


# ================================================================ T61 저장의 쓰기

func t61_atomic_write() -> String:
	var errs: Array[String] = []
	var temp := TEST_PATH + Store.TEMP_SUFFIX
	Store.erase(TEST_PATH)

	# 가. 처음 쓴다.
	_expect(errs, Store.write(TEST_PATH, {"version": 1, "day": 4, "money": 10}), "[가] 쓰지 못함")
	_expect(errs, FileAccess.file_exists(TEST_PATH) and not FileAccess.file_exists(temp), "[가] 원래 파일이 없거나 임시 파일이 남음")
	_expect(errs, _day_of(Store.read(TEST_PATH)) == 4, "[가] 읽은 날 %d (기대 4)" % _day_of(Store.read(TEST_PATH)))

	# 나. 같은 경로에 다시 쓴다(원래 파일 위로 바꿔 끼운다).
	_expect(errs, Store.write(TEST_PATH, {"version": 1, "day": 5, "money": 10}), "[나] 다시 쓰지 못함")
	_expect(errs, _day_of(Store.read(TEST_PATH)) == 5 and not FileAccess.file_exists(temp),
		"[나] 읽은 날 %d (기대 5), 임시 파일 %s" % [_day_of(Store.read(TEST_PATH)), str(FileAccess.file_exists(temp))])

	# 다. 바꿔 끼우는 사이에 꺼진 꼴: 원래 파일이 없고 다 적힌 임시 파일만 있다.
	DirAccess.remove_absolute(TEST_PATH)
	_write_raw(temp, JSON.stringify({"version": 1, "day": 6, "money": 10}))
	_expect(errs, Store.exists(TEST_PATH) and not FileAccess.file_exists(TEST_PATH), "[다] 임시 파일만 있는데 저장이 없다고 함")
	_expect(errs, _day_of(Store.read(TEST_PATH)) == 6, "[다] 임시 파일만 있을 때 읽은 날 %d (기대 6)" % _day_of(Store.read(TEST_PATH)))
	_expect(errs, Store.write(TEST_PATH, {"version": 1, "day": 7, "money": 10}), "[다] 임시 파일만 있을 때 쓰지 못함")
	_expect(errs, FileAccess.file_exists(TEST_PATH) and not FileAccess.file_exists(temp) and _day_of(Store.read(TEST_PATH)) == 7,
		"[다] 다시 쓴 뒤 원래 파일이 날 7이 아니거나 임시 파일이 남음")

	# 라. 임시 파일을 쓰다 꺼진 꼴: 원래 파일은 멀쩡하고 임시 파일이 깨졌다.
	_expect(errs, Store.write(TEST_PATH, {"version": 1, "day": 8, "money": 10}), "[라] 쓰지 못함")
	_write_raw(temp, "{{{")
	_expect(errs, _day_of(Store.read(TEST_PATH)) == 8 and Store.exists(TEST_PATH),
		"[라] 깨진 임시 파일이 있을 때 읽은 날 %d (기대 8: 원래 파일만 본다)" % _day_of(Store.read(TEST_PATH)))
	_expect(errs, Store.write(TEST_PATH, {"version": 1, "day": 9, "money": 10}), "[라] 깨진 임시 파일이 있을 때 쓰지 못함")
	_expect(errs, _day_of(Store.read(TEST_PATH)) == 9 and not FileAccess.file_exists(temp),
		"[라] 다시 쓴 뒤 읽은 날 %d (기대 9), 임시 파일 %s" % [_day_of(Store.read(TEST_PATH)), str(FileAccess.file_exists(temp))])

	# 마. 지우기는 원래 파일과 임시 파일을 함께 지운다.
	_write_raw(temp, "{}")
	Store.erase(TEST_PATH)
	_expect(errs, not FileAccess.file_exists(TEST_PATH) and not FileAccess.file_exists(temp), "[마] 지운 뒤 파일이 남음")
	_expect(errs, not Store.exists(TEST_PATH) and Store.read(TEST_PATH).is_empty(), "[마] 지운 뒤 저장이 있거나 읽힘")
	return _result(errs)


# ================================================================ T62 헷갈리던 표기

func t62_labels() -> String:
	var errs: Array[String] = []

	# 가. 카운터 머리 줄의 남은 결투는 지금 손님과 문밖 손님을 합친 수를 넘지 않는다. 계산과 안내는 그대로다.
	var day := DayState.new(_d._duel_rules(3), _d._three_fixed())
	var counter: Node = _d._spawn_screen(Session.COUNTER_PATH, day)
	var header: String = _d._label_text(counter, "Header")
	_expect(errs, header.contains("(문밖에 2명)") and header.contains("오늘 남은 결투 3"), "[가] 첫 카운터의 머리 줄 '%s'" % header)
	counter.free()
	day.decline()
	counter = _d._spawn_screen(Session.COUNTER_PATH, day)
	header = _d._label_text(counter, "Header")
	_expect(errs, header.contains("(문밖에 1명)") and header.contains("오늘 남은 결투 2"),
		"[가] 하나를 돌려보낸 뒤의 머리 줄 '%s' (기대: 문밖에 1명, 오늘 남은 결투 2)" % header)
	_expect(errs, counter.get("shown_duels_left") == day.duels_left() and day.duels_left() == 3,
		"[가] shown_duels_left %s, duels_left %d (기대: 둘 다 3)" % [str(counter.get("shown_duels_left")), day.duels_left()])
	_expect(errs, _d._has_node(counter, "DeclineNote"), "[가] 문밖 1명·남은 결투 3인데 DeclineNote가 없음")
	counter.free()

	# 나. 장부의 금액 한 칸.
	_expect(errs, Closing.ledger_amount(0, "-") == "0", "[나] (0, -) → '%s' (기대 '0')" % Closing.ledger_amount(0, "-"))
	_expect(errs, Closing.ledger_amount(20, "-") == "-20", "[나] (20, -) → '%s' (기대 '-20')" % Closing.ledger_amount(20, "-"))
	_expect(errs, Closing.ledger_amount(72, "+") == "+72", "[나] (72, +) → '%s' (기대 '+72')" % Closing.ledger_amount(72, "+"))

	# 다. 다치지 않은 날의 폐점: 치료비에 -0이 없다.
	var calm := DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed())
	for _i in 3:
		calm.accept()
		calm.finish_duel(_d._record(DT.EndReason.CONDITION))
		calm.proceed()
	var closing: Node = _d._spawn_screen(Session.CLOSING_PATH, calm)
	_expect(errs, calm.phase == DayState.Phase.CLOSING, "[다] 셋을 끝냈는데 폐점이 아님")
	_expect(errs, _ledger(closing, "Medical", "Name").contains("(0회)") and _ledger(closing, "Medical", "Value") == "0"
		and _ledger(closing, "Rent", "Value") == "-60",
		"[다] 다치지 않은 날의 폐점 장부: 치료비 '%s' '%s', 임대료 '%s' (기대 (0회)·0·-60)" % [
			_ledger(closing, "Medical", "Name"), _ledger(closing, "Medical", "Value"), _ledger(closing, "Rent", "Value")])
	_expect(errs, _ledger(closing, "Money", "Value") == "250 → 342" and _ledger(closing, "Profit", "Value") == "+92",
		"[다] 폐점의 소지금 '%s', 손익 '%s' (기대 250 → 342, +92)" % [_ledger(closing, "Money", "Value"), _ledger(closing, "Profit", "Value")])
	closing.free()

	# 라. 다친 날의 폐점: 전과 같은 글이다.
	var hurt := DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed())
	_d._run_fixed_day(hurt)
	closing = _d._spawn_screen(Session.CLOSING_PATH, hurt)
	_expect(errs, _ledger(closing, "Medical", "Name").contains("(1회)") and _ledger(closing, "Medical", "Value") == "-20",
		"[라] 다친 날의 폐점 장부의 치료비 줄: '%s' '%s' (기대 (1회)·-20)" % [_ledger(closing, "Medical", "Name"), _ledger(closing, "Medical", "Value")])
	_expect(errs, _ledger(closing, "Money", "Value") == "250 → 322",
		"[라] 다친 날의 폐점의 소지금 '%s' (기대 250 → 322)" % _ledger(closing, "Money", "Value"))
	closing.free()

	# 마. 의뢰가 없는 날의 폐점: 왼쪽은 그날 아침의 소지금이다(결정 483).
	var empty := DayState.new(_d._rules(70, 60, 20, 250), DayData.new())
	closing = _d._spawn_screen(Session.CLOSING_PATH, empty)
	_expect(errs, _ledger(closing, "Money", "Value") == "250 → 190" and _ledger(closing, "Profit", "Value") == "-60",
		"[마] 의뢰 0건의 폐점의 소지금 '%s', 손익 '%s' (기대 250 → 190, -60)" % [_ledger(closing, "Money", "Value"), _ledger(closing, "Profit", "Value")])
	closing.free()

	# 바. 정산 머리 줄의 분모는 치를 수 있는 결투 수다(결정 484).
	var won := DT.EndReason.CONDITION
	# (ㄱ) 첫째를 돌려보내면 1/2 → 2/2, 마지막 버튼은 폐점으로.
	var sent := DayState.new(_d._duel_rules(3), _d._three_fixed())
	sent.decline()
	_d._fight(sent, won)
	var settle: Node = _d._spawn_screen(Session.SETTLEMENT_PATH, sent)
	_expect(errs, _d._label_text(settle, "Header").contains("오늘의 결투 1/2"), "[바ㄱ] 첫 정산 '%s' (기대 1/2)" % _d._label_text(settle, "Header"))
	settle.free()
	sent.proceed()
	_d._fight(sent, won)
	settle = _d._spawn_screen(Session.SETTLEMENT_PATH, sent)
	var proceed_button := settle.find_child("Proceed", true, false) as Button
	_expect(errs, _d._label_text(settle, "Header").contains("오늘의 결투 2/2")
		and proceed_button != null and proceed_button.text == "가게를 닫는다",
		"[바ㄱ] 마지막 정산 '%s' (기대 2/2, 가게를 닫는다)" % _d._label_text(settle, "Header"))
	settle.free()
	# (ㄴ) 돌려보내지 않은 날은 새 하루로 1/3 · 2/3 · 3/3.
	var full := DayState.new(_d._duel_rules(3), _d._three_fixed())
	for n in [1, 2, 3]:
		_d._fight(full, won)
		settle = _d._spawn_screen(Session.SETTLEMENT_PATH, full)
		_expect(errs, _d._label_text(settle, "Header").contains("오늘의 결투 %d/3" % n),
			"[바ㄴ] %d번째 정산 '%s' (기대 %d/3)" % [n, _d._label_text(settle, "Header"), n])
		settle.free()
		full.proceed()
	# (ㄷ) 손님이 결투 자리보다 많은 날도 분모가 자리를 넘지 않는다.
	var crowded := DayState.new(_d._duel_rules(2), _d._three_fixed())
	for n in [1, 2]:
		_d._fight(crowded, won)
		settle = _d._spawn_screen(Session.SETTLEMENT_PATH, crowded)
		_expect(errs, _d._label_text(settle, "Header").contains("오늘의 결투 %d/2" % n),
			"[바ㄷ] %d번째 정산 '%s' (기대 %d/2)" % [n, _d._label_text(settle, "Header"), n])
		settle.free()
		crowded.proceed()
	# (ㄹ) 첫째를 치르고 둘째를 돌려보내면 1/3에서 2/2로 간다.
	var mid := DayState.new(_d._duel_rules(3), _d._three_fixed())
	_d._fight(mid, won)
	settle = _d._spawn_screen(Session.SETTLEMENT_PATH, mid)
	_expect(errs, _d._label_text(settle, "Header").contains("오늘의 결투 1/3"), "[바ㄹ] 첫 정산 '%s' (기대 1/3)" % _d._label_text(settle, "Header"))
	settle.free()
	mid.proceed()
	mid.decline()
	_d._fight(mid, won)
	settle = _d._spawn_screen(Session.SETTLEMENT_PATH, mid)
	_expect(errs, _d._label_text(settle, "Header").contains("오늘의 결투 2/2"), "[바ㄹ] 둘째 정산 '%s' (기대 2/2)" % _d._label_text(settle, "Header"))
	settle.free()
	return _result(errs)
