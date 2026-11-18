extends SceneTree
## 헤드리스 테스트 러너.
## 실행: powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1
##   (클래스 캐시 갱신 → 이 스크립트 실행 → 아래 통과 판정을 한 번에 한다.)
## 직접 실행: <godot> --headless --path <프로젝트> --script res://tests/run_tests.gd --quit-after 6000
##   새 class_name 스크립트를 더한 뒤에는 먼저 <godot> --headless --path <프로젝트> --import 로
##   클래스 캐시(.godot/, 깃에 없음)를 갱신해야 한다. 안 하면 테스트 파일이 파스 오류로 로드되지 않는다.
## 통과 판정: 종료 코드 0, 마지막 줄 "ALL PASS n/n", 출력에 SCRIPT ERROR / ERROR: 없음.

const TEST_FILES: Array[String] = [
	"res://tests/project_tests.gd",
	"res://tests/core_tests.gd",
	"res://tests/commission_tests.gd",
	"res://tests/scene_tests.gd",
	"res://tests/flow_tests.gd",
]

var _started := false
var _finished := false
var _suites: Array = []
var _exit_code := 0
var _quit_at_msec := 0

## 테스트가 끝난 뒤 종료까지 기다리는 실제 시간(밀리초).
## 비프음 재생 객체는 오디오 스레드가 놓아 준다. 바로 끝내면 가끔 누수 경고가 찍힌다.
const QUIT_DELAY_MSEC := 300


func _process(_delta: float) -> bool:
	if _started:
		if not _finished:
			# 첫 호출이 런타임 오류로 중단됐다. 그대로 두면 --quit-after가 종료 코드 0으로 끝낸다.
			_finished = true
			print("FAILED (러너가 런타임 오류로 중단됨)")
			quit(1)
			return true
		if Time.get_ticks_msec() < _quit_at_msec:
			return false
		quit(_exit_code)
		return true
	_started = true

	var tests: Array = []
	for path in TEST_FILES:
		if not ResourceLoader.exists(path):
			continue
		var script: GDScript = load(path)
		# 파스 오류가 난 스크립트는 null이 아니라 인스턴스를 만들 수 없는 GDScript로 돌아온다.
		if script == null or not script.can_instantiate():
			print("FAIL (로드 실패) %s" % path)
			print("FAILED 1/1")
			_finished = true
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

	_finished = true
	if failed == 0:
		print("ALL PASS %d/%d" % [total, total])
		_exit_code = 0
	else:
		print("FAILED %d/%d" % [failed, total])
		_exit_code = 1
	# 종료는 다음 _process 호출들이 한다(위의 QUIT_DELAY_MSEC 참고).
	_quit_at_msec = Time.get_ticks_msec() + QUIT_DELAY_MSEC
	return false
