extends RefCounted
## T63·T64: 계획 019의 정리 가운데 테스트로 볼 수 있는 둘. 현재 씬인 갈래는 러너에서 만들 수 없어 스모크가 본다.

const Day := preload("res://tests/day_tests.gd")
const Session := preload("res://scripts/game_session.gd")
const Ui := preload("res://scripts/day_ui.gd")

var _tree: SceneTree
var _d := Day.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T63", "name": "화면의 세션 가드: 트리 밖과 현재 씬이 아닌 화면은 세션을 받지 않는다", "fn": t63_session_guard},
		{"id": "T64", "name": "폐점의 '저장했다': 마지막 쓰기의 결과를 따른다", "fn": t64_saved_note},
	]


func cleanup() -> void:
	_d.cleanup()
	_d = null
	_tree = null


# ================================================================ 도우미

func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


func _result(errs: Array[String]) -> String:
	return "OK" if errs.is_empty() else " / ".join(errs)


func _closed_day() -> DayState:
	var day := DayState.new(_d._rules(70, 60, 20, 250), _d._three_fixed())
	_d._run_fixed_day(day)
	return day


func _saved_notes(closing: Node) -> Array[Node]:
	return closing.find_children("SavedNote", "Label", true, false)


# ================================================================ T63 화면의 세션 가드

func t63_session_guard() -> String:
	var errs: Array[String] = []
	var node := Control.new()
	# 트리를 먼저 보지 않으면 여기서 엔진이 ERROR 줄을 찍어 러너의 판정이 깨진다.
	_expect(errs, not Ui.is_current_scene(node), "[가] 트리 밖의 노드를 현재 씬으로 봄")
	_expect(errs, Ui.current_session(node) == null, "[가] 트리 밖의 노드가 세션을 받음")
	_tree.root.add_child(node)
	_expect(errs, not Ui.is_current_scene(node), "[나] root에 붙인 노드를 현재 씬으로 봄")
	_expect(errs, Ui.current_session(node) == null, "[나] 현재 씬이 아닌 노드가 세션을 받음")
	node.free()
	return _result(errs)


# ================================================================ T64 폐점의 '저장했다'

func t64_saved_note() -> String:
	var errs: Array[String] = []
	var day := _closed_day()
	_expect(errs, day.phase == DayState.Phase.CLOSING, "[가] 하루를 끝냈는데 폐점이 아님")
	var closing: Node = _d._spawn_screen(Session.CLOSING_PATH, day)
	_expect(errs, not _d._has_node(closing, "SavedNote"), "[가] 러너에서 붙인 폐점에 SavedNote가 있음")

	var tomorrow := day.day_number + 1
	closing.call("refresh_saved_note", tomorrow)
	var note := closing.find_child("SavedNote", true, false) as Label
	_expect(errs, note != null and note.visible and note.text.contains("%d일차" % tomorrow),
		"[나] 적은 뒤 SavedNote가 없거나 보이지 않거나 '%d일차'가 없음" % tomorrow)

	closing.call("refresh_saved_note", 0)
	var notes := _saved_notes(closing)
	_expect(errs, notes.size() == 1 and not (notes[0] as Label).visible,
		"[다] 실패한 쓰기 뒤 SavedNote %d개 (기대: 하나, 숨김)" % notes.size())

	closing.call("refresh_saved_note", tomorrow)
	notes = _saved_notes(closing)
	_expect(errs, notes.size() == 1 and (notes[0] as Label).visible,
		"[라] 다시 적은 뒤 SavedNote %d개 (기대: 하나, 보임)" % notes.size())
	closing.free()

	var failed: Node = _d._spawn_screen(Session.CLOSING_PATH, _closed_day())
	failed.call("refresh_saved_note", 0)
	_expect(errs, not _d._has_node(failed, "SavedNote"), "[마] 실패한 쓰기만 있었는데 SavedNote가 생김")
	failed.free()
	return _result(errs)
