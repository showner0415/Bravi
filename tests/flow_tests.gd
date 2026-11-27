extends RefCounted
## T21~T22: 의뢰 목록 로드와 "의뢰 → 결투 → 결과 패널" 흐름.
## 결투 씬은 commission 속성을 직접 넣어 붙인다(GameSession 오토로드에 의존하지 않는다).

const Plain := preload("res://tests/plain_opponent.gd")
const Bot := preload("res://tests/duel_bots.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const SelectScript := preload("res://scripts/commission/commission_select.gd")

const COMMISSION_DIR := "res://data/commissions"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const SELECT_PATH := "res://scenes/ui/commission_select.tscn"
const TEMP_DIR := "user://bravi_test_commissions"
const DELTA := 1.0 / 60.0
## 한 판이 끝나기를 기다리는 프레임 상한(제한 시간 90초보다 넉넉하게).
const MAX_FRAMES := 7200

var _tree: SceneTree


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T21", "name": "의뢰 목록: 폴더의 .tres만큼 로드", "fn": t21_library},
		{"id": "T22", "name": "흐름: 의뢰 → 결투 → 결과 패널의 점수", "fn": t22_flow},
	]


func cleanup() -> void:
	_tree = null


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


# ================================================================ T21

func t21_library() -> String:
	var errs: Array[String] = []
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	_clear_temp()

	var saved := 0
	for name in ["b_second", "a_first"]:
		var commission := Commission.new()
		commission.client_name = name
		if ResourceSaver.save(commission, TEMP_DIR.path_join(name + ".tres")) == OK:
			saved += 1
	_expect(errs, saved == 2, "임시 의뢰 저장 %d개 (기대 2)" % saved)
	var two := CommissionLibrary.load_all(TEMP_DIR)
	_expect(errs, two.size() == 2, "임시 폴더에서 %d개 로드 (기대 2)" % two.size())
	if two.size() == 2:
		_expect(errs, two[0].client_name == "a_first" and two[1].client_name == "b_second", "파일 이름순이 아님")

	var third := Commission.new()
	third.client_name = "c_third"
	ResourceSaver.save(third, TEMP_DIR.path_join("c_third.tres"))
	_expect(errs, CommissionLibrary.load_all(TEMP_DIR).size() == 3, "하나 더 쓴 뒤 3개가 아님")

	_clear_temp()
	DirAccess.remove_absolute(TEMP_DIR)

	var real := CommissionLibrary.load_all(COMMISSION_DIR)
	_expect(errs, real.size() == 4, "%s 에서 %d개 로드 (기대 4)" % [COMMISSION_DIR, real.size()])
	return _result(errs)


func _clear_temp() -> void:
	for file in DirAccess.get_files_at(TEMP_DIR):
		DirAccess.remove_absolute(TEMP_DIR.path_join(file))


# ================================================================ T22

## 결투 씬을 의뢰와 함께 붙인다. 호출한 쪽이 free()한다.
func _spawn_duel(commission: Commission) -> Node:
	var duel: Node = (load(DUEL_PATH) as PackedScene).instantiate()
	# 다른 규칙을 보는 테스트다: 패턴·높이·확률을 끈 옛 규칙 사본이다(결정 416·426). 하루의 판 길이는 T90.
	var pinned := commission.duplicate() as Commission
	pinned.opponent = Plain.of(commission.opponent)
	duel.set("commission", pinned)
	duel.set("mouse_aim_enabled", false)
	duel.set("rng_seed", 1)
	_tree.root.add_child(duel)
	return duel


func t22_flow() -> String:
	var errs: Array[String] = []
	var commissions := CommissionLibrary.load_all(COMMISSION_DIR)
	_expect(errs, commissions.size() == 4, "의뢰 %d개 (기대 4)" % commissions.size())

	# 의뢰 4개 각각 입력 없이 → 유효타를 맞아 끝나고, 결과 패널의 점수가 같은 record의 evaluate와 같다.
	for commission in commissions:
		var duel := _spawn_duel(commission)
		var panel: ResultPanel = duel.get_node("ResultPanel")
		_expect(errs, not panel.is_showing(), "[%s] 시작부터 결과 패널이 보임" % commission.client_name)
		var core: DuelCore = duel.get("core")
		var frames := 0
		while not core.ended and frames < MAX_FRAMES:
			duel.call("advance", DELTA)
			frames += 1
		_expect(errs, core.end_reason == DT.EndReason.PLAYER_DEFEATED, "[%s] 입력 없이 패배로 끝나지 않음" % commission.client_name)
		_expect(errs, panel.is_showing(), "[%s] 끝난 뒤 결과 패널이 보이지 않음" % commission.client_name)
		_expect(errs, panel.shown_score == commission.evaluate(core.record), "[%s] 패널 점수 %d, evaluate %d" % [
			commission.client_name, panel.shown_score, commission.evaluate(core.record)])
		# 다시 하기는 패널을 닫는다.
		duel.call("start_duel")
		_expect(errs, not panel.is_showing(), "[%s] 다시 시작한 뒤에도 결과 패널이 보임" % commission.client_name)
		duel.free()

	# 첫 피 의뢰에 봇을 연결 → 결과 패널이 100을 표시한다(0이 아닌 점수 경로).
	var first_blood: Commission = null
	for commission in commissions:
		if commission.conditions.size() == 1 and commission.conditions[0] is FirstBloodCondition:
			first_blood = commission
	if first_blood == null:
		errs.append("첫 피 의뢰를 찾지 못함")
	else:
		var duel := _spawn_duel(first_blood)
		var core: DuelCore = duel.get("core")
		var mid := [DT.Direction.CENTER, DT.Height.MID]
		var counter := func(ev: Dictionary) -> Variant:
			return mid if float(ev["recovery"]) > 0.0 else null
		var bot: RefCounted = Bot.new(core, {"counter_fn": counter, "finisher": mid})
		var frames := 0
		while not core.ended and frames < MAX_FRAMES:
			duel.call("advance", DELTA)
			bot.call("update")
			frames += 1
		var panel: ResultPanel = duel.get_node("ResultPanel")
		_expect(errs, core.end_reason == DT.EndReason.CONDITION, "[첫 피 봇] 조건으로 끝나지 않음")
		_expect(errs, panel.is_showing() and panel.shown_score == 100, "[첫 피 봇] 패널 점수 %d (기대 100)" % panel.shown_score)
		duel.free()

	# 의뢰 선택 화면: 의뢰 수만큼 시작 버튼이 생긴다.
	var select: Node = (load(SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	# 카드의 시작 버튼만 센다(카드 아래에 시험용 상대의 버튼이 더 있다. 계획 036).
	var buttons: Array[Node] = []
	for button in select.find_children("*", "Button", true, false):
		if (button as Button).text == "이 의뢰를 맡는다":
			buttons.append(button)
	# 새 연습 화면은 카드 한 장이라 시작 버튼이 하나이고, 의뢰는 줄(쪽당 LIST_ROWS)로 고른다(계획 040b).
	_expect(errs, buttons.size() == 1, "의뢰 선택 화면의 시작 버튼 %d개 (기대 1)" % buttons.size())
	var picks := select.find_children("CommissionPick*", "Button", true, false).size()
	var want_picks := mini(CommissionLibrary.load_tree(COMMISSION_DIR).size(), SelectScript.LIST_ROWS)
	_expect(errs, picks == want_picks, "의뢰 선택 화면의 의뢰 줄 %d개 (기대 %d)" % [picks, want_picks])
	select.free()
	return _result(errs)
