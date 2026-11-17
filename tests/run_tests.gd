extends SceneTree
## 헤드리스 테스트 러너.
## 실행: <godot> --headless --path <프로젝트> --script res://tests/run_tests.gd --quit-after 6000
## 통과 판정: 종료 코드 0, 마지막 줄 "ALL PASS n/n", 출력에 SCRIPT ERROR / ERROR: 없음.

const TEST_FILES: Array[String] = [
	"res://tests/project_tests.gd",
	"res://tests/core_tests.gd",
	"res://tests/scene_tests.gd",
]

var _started := false
var _suites: Array = []


func _process(_delta: float) -> bool:
	if _started:
		return true
	_started = true

	var tests: Array = []
	for path in TEST_FILES:
		if not ResourceLoader.exists(path):
			continue
		var script: GDScript = load(path)
		if script == null:
			print("FAIL (로드 실패) %s" % path)
			print("FAILED 1/1")
			quit(1)
			return true
		var suite: Object = script.new()
		_suites.append(suite)  # 테스트 Callable이 살아 있도록 붙잡아 둔다
		tests.append_array(suite.call("list", self))

	var failed := 0
	for t in tests:
		var result: Variant = t["fn"].call()
		# 통과는 "OK"다. 런타임 오류로 중단된 함수는 ""나 null을 돌려주므로 실패로 본다.
		if result is String and result == "OK":
			print("PASS %s %s" % [t["id"], t["name"]])
		else:
			failed += 1
			var msg := "런타임 오류 (테스트 함수가 끝까지 실행되지 않음)"
			if result is String and result != "":
				msg = result
			print("FAIL %s %s: %s" % [t["id"], t["name"], msg])

	var total := tests.size()
	# 종료 때 누수 경고가 나오지 않도록 테스트가 붙잡은 참조를 놓는다.
	tests.clear()
	for suite in _suites:
		if suite.has_method("cleanup"):
			suite.call("cleanup")
	_suites.clear()

	if failed == 0:
		print("ALL PASS %d/%d" % [total, total])
		quit(0)
	else:
		print("FAILED %d/%d" % [failed, total])
		quit(1)
	return true
