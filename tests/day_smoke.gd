extends Node
## 하루 통째 스모크. 씬으로 실행한다(오토로드 GameSession이 떠야 하므로 --script 러너로는 볼 수 없다).
## 실행: powershell -ExecutionPolicy Bypass -File tests/run_smoke.ps1
##
## 처음 화면 → 카운터 → 결투 → 정산을 세 번 → 폐점 → 2일차 카운터까지 실제 씬 전환을 지난다.
## 테스트(T28~T33)는 화면에 day를 직접 넣으므로, GameSession의 하루 시작·씬 이동과
## 각 화면이 GameSession.day를 읽는 경로는 여기서만 확인된다.
##
## 화면 확인: 헤드리스가 아니고 "-- --shots=<폴더>"를 받으면 화면마다 PNG를 그 폴더에 저장한다.


func _ready() -> void:
	# 첫 씬의 _ready 안에서는 트리 뿌리를 건드릴 수 없다(뿌리가 자식을 준비시키는 중이다).
	call_deferred("_start")


func _start() -> void:
	var driver := Driver.new()
	driver.name = "DaySmokeDriver"
	# 뿌리에 붙여 씬이 바뀌어도 남게 한다.
	get_tree().root.add_child(driver)
	get_tree().change_scene_to_file(Driver.TITLE)


class Driver extends Node:
	const TITLE := "res://scenes/ui/title.tscn"
	const COUNTER := "res://scenes/counter/counter.tscn"
	const DUEL := "res://scenes/duel/duel.tscn"
	const SETTLEMENT := "res://scenes/settlement/settlement.tscn"
	const CLOSING := "res://scenes/settlement/closing.tscn"
	const SELECT := "res://scenes/ui/commission_select.tscn"
	## 2일차 카운터가 EXPECTED에서 몇 번째인가(1부터).
	const DAY2_COUNTER := 12
	## 지나야 하는 씬의 순서.
	const EXPECTED: Array[String] = [
		TITLE,
		COUNTER, DUEL, SETTLEMENT,
		COUNTER, DUEL, SETTLEMENT,
		COUNTER, DUEL, SETTLEMENT,
		CLOSING,
		COUNTER,  # 2일차
		# 빠져나오는 길과 연습 경로: 오늘은 그만 → 처음 화면 → 연습 → Esc → 처음 화면 → Enter → 1일차 카운터
		TITLE, SELECT, TITLE, COUNTER,
	]
	## 자체 프레임 상한(--quit-after 6000보다 작게).
	const MAX_FRAMES := 3000
	## 결투 한 판을 빨리 흘릴 때의 tick 상한(제한 시간 90초보다 넉넉하게).
	const MAX_TICKS := 7200
	const QUIT_DELAY_MSEC := 300

	var _frames := 0
	var _visited := 0
	var _scene_id := 0
	var _scene_frames := 0
	var _stage := 0
	var _results_before := 0
	var _done := false
	var _exit_code := 0
	var _quit_at_msec := 0
	## 화면에 손대기 전에 기다리는 프레임 수. PNG를 찍을 때는 그려질 시간을 준다.
	var _wait := 2
	var _shots_dir := ""
	var _shot_index := 0

	func _ready() -> void:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--shots="):
				_shots_dir = arg.trim_prefix("--shots=")
		if _shots_dir != "" and DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute(_shots_dir)
			_wait = 45
		else:
			_shots_dir = ""

	func _process(_delta: float) -> void:
		if _done:
			# 비프음 재생 객체는 오디오 스레드가 놓아 준다. 바로 끝내면 누수 줄이 찍힌다.
			if Time.get_ticks_msec() >= _quit_at_msec:
				get_tree().quit(_exit_code)
			return
		_frames += 1
		if _frames > MAX_FRAMES:
			_fail("프레임 상한 %d을 넘음 (지난 씬 %d/%d)" % [MAX_FRAMES, _visited, EXPECTED.size()])
			return
		var scene := get_tree().current_scene
		# change_scene_to_file 직후부터 그 프레임 끝까지 현재 씬은 null이다.
		if scene == null or scene.scene_file_path == "res://tests/day_smoke.tscn":
			return
		if scene.get_instance_id() != _scene_id:
			_scene_id = scene.get_instance_id()
			_scene_frames = 0
			_stage = 0
			if _visited >= EXPECTED.size() or scene.scene_file_path != EXPECTED[_visited]:
				_fail("%d번째 씬이 %s (기대 %s)" % [_visited + 1, scene.scene_file_path,
					EXPECTED[_visited] if _visited < EXPECTED.size() else "없음"])
				return
			_visited += 1
		_scene_frames += 1
		if _scene_frames < _wait:
			return
		match scene.scene_file_path:
			DUEL:
				_drive_duel(scene)
			CLOSING:
				_drive_closing(scene)
			_:
				_drive_screen(scene)

	func _session() -> Node:
		return get_node_or_null(^"/root/GameSession")

	func _day() -> DayState:
		var session := _session()
		return session.get("day") as DayState if session != null else null

	## 처음 화면·카운터·정산: Proceed를 누른다.
	func _drive_screen(scene: Node) -> void:
		if _stage != 0:
			return
		_stage = 1
		if _visited >= DAY2_COUNTER:
			_drive_tail(scene)
			return
		_shot(scene.name.to_lower())
		if not _press_proceed(scene):
			_fail("%s 에 Proceed 버튼이 없음" % scene.scene_file_path)

	## 2일차 카운터부터: 빠져나오는 길과 연습 경로를 지난다.
	func _drive_tail(scene: Node) -> void:
		var session := _session()
		var day := _day()
		match _visited:
			12:  # 2일차 카운터 → "오늘은 그만"
				if day == null or day.day_number != 2 or day.phase != DayState.Phase.COUNTER:
					_fail("폐점 뒤의 카운터가 2일차 카운터가 아님")
					return
				_shot("counter_day2")
				if not _press(scene, "Quit"):
					_fail("카운터에 Quit 버튼이 없음")
			13:  # 처음 화면 → "연습"
				if day != null:
					_fail("오늘은 그만 뒤에도 GameSession.day가 남아 있음")
					return
				if not _press(scene, "Practice"):
					_fail("처음 화면에 Practice 버튼이 없음")
			14:  # 의뢰 선택(연습) → Esc
				_shot("practice_select")
				_send_key(KEY_ESCAPE)
			15:  # 처음 화면 → 포커스된 버튼에 실제 Enter 키
				_send_key(KEY_ENTER)
			16:  # 1일차 카운터. 여기까지 오면 끝이다.
				if day == null or day.day_number != 1 or day.phase != DayState.Phase.COUNTER \
						or day.money != day.rules.starting_money:
					_fail("Enter로 연 가게가 새 1일차 카운터가 아님")
					return
				if session.get("commission") != null:
					_fail("하루 플레이를 시작했는데 연습의 의뢰가 남아 있음")
					return
				_succeed()

	func _press(scene: Node, button_name: String) -> bool:
		var button := scene.find_child(button_name, true, false) as Button
		if button == null:
			return false
		button.pressed.emit()
		return true

	## 결투: R과 Esc가 무시되는지 본 뒤, 입력 없이 끝까지 흘리고 Space로 넘긴다.
	func _drive_duel(scene: Node) -> void:
		var day := _day()
		if day == null:
			_fail("결투 씬인데 GameSession.day가 없음")
			return
		if _stage == 0:
			var core: DuelCore = scene.get("core")
			_send_key(KEY_R)
			if scene.get("core") != core:
				_fail("하루 모드의 결투에서 R이 새 판을 시작함")
				return
			_send_key(KEY_ESCAPE)
			# Esc가 무시되지 않았다면 씬이 바뀌어 현재 씬이 곧바로 null이 된다. 같은 프레임에서 본다.
			if get_tree().current_scene != scene:
				_fail("하루 모드의 결투에서 Esc가 씬을 바꿈")
				return
			# 끝나기 전의 Space는 아무것도 넘기지 않는다.
			_send_key(KEY_SPACE)
			if day.phase != DayState.Phase.DUEL:
				_fail("결투가 끝나기 전의 Space가 단계를 바꿈")
				return
			var ticks := 0
			while not core.ended and ticks < MAX_TICKS:
				scene.call("advance", 1.0 / 60.0)
				ticks += 1
			if not core.ended:
				_fail("결투가 %d tick 안에 끝나지 않음" % MAX_TICKS)
				return
			_results_before = day.results.size()
			_scene_frames = 0
			_stage = 1
		elif _stage == 1:
			_stage = 2
			_shot("duel_result")
			_send_key(KEY_SPACE)
			if day.phase != DayState.Phase.SETTLEMENT or day.results.size() != _results_before + 1:
				_fail("결투가 끝난 뒤의 Space가 정산으로 넘기지 않음 (단계 %d, 결과 %d건)" % [day.phase, day.results.size()])

	## 폐점: 장부를 확인하고 다음 날을 연다.
	func _drive_closing(scene: Node) -> void:
		if _stage != 0:
			return
		_stage = 1
		var day := _day()
		if day == null or day.phase != DayState.Phase.CLOSING:
			_fail("폐점 씬인데 단계가 폐점이 아님")
			return
		if day.results.size() != 3:
			_fail("폐점의 결과 %d건 (기대 3)" % day.results.size())
			return
		var income := 0
		var injuries := 0
		for result in day.results:
			income += int(result["total"])
			if result["injured"]:
				injuries += 1
		var want := day.rules.starting_money + income - day.rules.rent - day.rules.medical_fee * injuries
		if day.money != want:
			_fail("폐점 뒤 소지금 %d (기대 %d)" % [day.money, want])
			return
		if scene.get("shown_profit") != day.closing_summary().get("profit"):
			_fail("폐점 화면의 손익이 요약과 다름")
			return
		print("DAY SMOKE 장부: 수입 %d, 임대료 %d, 부상 %d회, 치료비 %d, 손익 %d, 소지금 %d" % [
			income, day.rules.rent, injuries, day.rules.medical_fee * injuries,
			int(day.closing_summary()["profit"]), day.money])
		_shot("closing")
		if not _press_proceed(scene):
			_fail("폐점에 Proceed 버튼이 없음")

	## 코드로 만든 버튼은 owner가 없다. owned를 끄고 찾는다.
	func _press_proceed(scene: Node) -> bool:
		var button := scene.find_child("Proceed", true, false) as Button
		if button == null:
			return false
		button.pressed.emit()
		return true

	func _send_key(key: Key) -> void:
		for pressed in [true, false]:
			var ev := InputEventKey.new()
			ev.keycode = key
			ev.physical_keycode = key
			ev.pressed = pressed
			Input.parse_input_event(ev)
			Input.flush_buffered_events()

	func _shot(label: String) -> void:
		if _shots_dir == "":
			return
		_shot_index += 1
		var image := get_viewport().get_texture().get_image()
		image.save_png(_shots_dir.path_join("%02d_%s.png" % [_shot_index, label]))

	func _succeed() -> void:
		print("DAY SMOKE OK (씬 %d개를 순서대로 지남)" % _visited)
		_finish(0)

	func _fail(reason: String) -> void:
		print("DAY SMOKE FAIL: %s" % reason)
		_finish(1)

	func _finish(code: int) -> void:
		_done = true
		_exit_code = code
		_quit_at_msec = Time.get_ticks_msec() + QUIT_DELAY_MSEC
