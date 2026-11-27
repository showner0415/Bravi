extends SceneTree
## 헤드리스 테스트 러너.
## 실행: powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1
##   (클래스 캐시 갱신 → 이 스크립트 실행 → 아래 통과 판정을 한 번에 한다.)
## 직접 실행: <godot> --headless --path <프로젝트> --script res://tests/run_tests.gd --quit-after 6000
##   새 class_name 스크립트를 더한 뒤에는 먼저 <godot> --headless --path <프로젝트> --import 로
##   클래스 캐시(.godot/, 깃에 없음)를 갱신해야 한다. 안 하면 테스트 파일이 파스 오류로 로드되지 않는다.
## 통과 판정: 종료 코드 0, 마지막 줄 "ALL PASS n/n", 출력에 SCRIPT ERROR / ERROR: 없음.
## 오토로드 GameSession이 떠 있으면 저장을 끄고 돈다(save_path를 비운다). 실제 저장 파일을 읽지 않는다.
## 오토로드 Settings도 path를 비워 설정 파일을 적지 않고 조작을 처음 값으로 돌린다(detach_for_run, 계획 S03 결정 523).

const TEST_FILES: Array[String] = [
	"res://tests/project_tests.gd",
	"res://tests/core_tests.gd",
	"res://tests/commission_tests.gd",
	"res://tests/scene_tests.gd",
	"res://tests/flow_tests.gd",
	"res://tests/day_tests.gd",
	"res://tests/part_tests.gd",
	"res://tests/bind_tests.gd",
	"res://tests/lunge_tests.gd",
	"res://tests/reputation_tests.gd",
	"res://tests/haggle_tests.gd",
	"res://tests/save_tests.gd",
	"res://tests/client_line_tests.gd",
	"res://tests/safety_tests.gd",
	"res://tests/tidy_tests.gd",
	"res://tests/opponent_art_tests.gd",
	"res://tests/curve_check_tests.gd",
	"res://tests/stage_tests.gd",
	"res://tests/hand_tests.gd",
	"res://tests/manuscript_tests.gd",
	"res://tests/counter_art_tests.gd",
	"res://tests/second_opponent_tests.gd",
	"res://tests/third_opponent_tests.gd",
	"res://tests/pattern_tests.gd",
	"res://tests/pattern_cell_tests.gd",
	"res://tests/opening_chance_tests.gd",
	"res://tests/painted_ui_tests.gd",
	"res://tests/settings_tests.gd",
	"res://tests/pause_tests.gd",
	"res://tests/controls_tests.gd",
	"res://tests/display_tests.gd",
	"res://tests/part_effect_tests.gd",
	"res://tests/style_tests.gd",
	"res://tests/practice_screen_tests.gd",
	"res://tests/fourth_opponent_tests.gd",
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

	# 오토로드 GameSession이 떠 있으면 저장을 끈다. 테스트가 붙인 처음 화면이 실제 저장 파일을 읽지 않게 한다
	# (스모크와 같은 장치). --script 실행에 오토로드가 뜨는지에 기대지 않는다: 없으면 할 일이 없다.
	var session := root.get_node_or_null(^"GameSession")
	if session == null:
		print("RUNNER 저장: 오토로드 GameSession 없음")
	else:
		print("RUNNER 저장: 오토로드 GameSession 있음, save_path '%s'를 비움" % str(session.get("save_path")))
		session.set("save_path", "")

	# 자동 로드 Settings도 쓰기를 끈다(path가 빈 글이면 save()가 적지 않는다. 계획 S01 결정 500).
	var settings := root.get_node_or_null(^"Settings")
	if settings == null:
		print("RUNNER 설정: 오토로드 Settings 없음")
	else:
		print("RUNNER 설정: 오토로드 Settings 있음, path '%s'를 비우고 조작을 처음 값으로" % str(settings.get("path")))
		if settings.has_method("detach_for_run"):
			settings.call("detach_for_run")
		else:
			settings.set("path", "")

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
