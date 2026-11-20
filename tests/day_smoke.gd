extends Node
## 하루 통째 스모크. 씬으로 실행한다(오토로드 GameSession이 떠야 하므로 --script 러너로는 볼 수 없다).
## 실행: powershell -ExecutionPolicy Bypass -File tests/run_smoke.ps1
##
## 처음 화면 → 1일차(오는 손님을 전부 맡는다) → 폐점(업그레이드를 전부 산다)
## → 2일차(첫 손님을 돌려보내고, 둘째를 맡고, 나머지를 돌려보낸다) → 폐점 → 3일차 첫 카운터
## → 빠져나오는 길과 연습 경로까지 실제 씬 전환을 지난다.
## 테스트(T28~T39)는 화면에 day를 직접 넣으므로, GameSession의 하루 시작·씬 이동·목록과 일정의 로드,
## 각 화면이 GameSession.day를 읽는 경로, 카운터 → 카운터·카운터 → 폐점 전환, 산 것이 다음 날의
## 결투와 정산에 닿는 경로는 여기서만 확인된다.
##
## 지나는 씬의 순서와 기대값(손님 수, 결투 수, 버튼 수, 값의 합, 자세와 치료비)은 로드한
## 일정·목록·규칙에서 만든다(.tres의 수치를 바꿔도 돈다). 1일차 폐점까지는 시작할 때 만들고,
## 2일차부터는 1일차 폐점에서 만든다(2일차의 손님 수가 1일차 뒤의 평판에 달렸다).
## 2일차의 손님이 셋보다 적거나 결투 수가 둘보다 적으면 돌려보내기 구간을 건너뛰고, 첫 손님만 맡은 뒤 나간다.
##
## 저장은 끄고 돈다(GameSession.save_path를 비운다). 저장과 이어서 하기는 tests/save_tests.gd와 playtester가 본다.
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
	if driver.plan():
		get_tree().change_scene_to_file(Driver.TITLE)


class Driver extends Node:
	const Bot := preload("res://tests/duel_bots.gd")
	const Session := preload("res://scripts/game_session.gd")

	const TITLE := "res://scenes/ui/title.tscn"
	const COUNTER := "res://scenes/counter/counter.tscn"
	const DUEL := "res://scenes/duel/duel.tscn"
	const SETTLEMENT := "res://scenes/settlement/settlement.tscn"
	const CLOSING := "res://scenes/settlement/closing.tscn"
	const SELECT := "res://scenes/ui/commission_select.tscn"
	const DUEL_RULES_PATH := "res://data/duel_rules.tres"

	## 자체 프레임 상한(--quit-after 6000보다 작게).
	const MAX_FRAMES := 3000
	## 결투 한 판을 빨리 흘릴 때의 tick 상한(제한 시간 90초보다 넉넉하게).
	const MAX_TICKS := 7200
	const QUIT_DELAY_MSEC := 300

	## 지나야 하는 씬과 그 씬에서 할 일. {"path", "kind", 그 밖의 인자}. plan()이 만든다.
	var _steps: Array[Dictionary] = []
	var _step: Dictionary = {}

	# plan()이 로드한 것. 기대값을 여기서 계산한다.
	var _rules: EconomyRules
	var _schedule: DaySchedule
	var _fallback: DayData
	var _upgrades: Array[UpgradeData] = []
	var _reputation: ReputationRules
	## 2일차의 결투 수(1일차 폐점에서 목록을 전부 산 뒤의 값)와 손님 수(1일차 폐점에서 정해진다).
	var _duels2 := 0
	var _guests2 := 0
	## 1일차에 치르는 결투의 수(손님 수와 결투 수 가운데 작은 쪽).
	var _day1_duels := 0

	var _frames := 0
	var _visited := 0
	var _scene_id := 0
	var _scene_frames := 0
	var _stage := 0
	var _results_before := 0
	var _money_mark := 0
	var _done := false
	var _exit_code := 0
	var _quit_at_msec := 0
	## 화면에 손대기 전에 기다리는 프레임 수. PNG를 찍을 때는 그려질 시간을 준다.
	var _wait := 2
	var _shots_dir := ""
	var _shot_index := 0
	## 스모크가 끄기 전의 저장 경로와 그 파일의 내용. 끝에서 파일이 그대로인지 견준다.
	var _real_save_path := ""
	var _real_save_before := ""

	func _ready() -> void:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--shots="):
				_shots_dir = arg.trim_prefix("--shots=")
		if _shots_dir != "" and DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute(_shots_dir)
			_wait = 45
		else:
			_shots_dir = ""

	# ------------------------------------------------------------ 계획

	## N일차의 손님. 게임과 같은 규칙이다: 일정이 주는 날, 주지 못하면 day_01.
	func _day_for(day_number: int) -> DayData:
		var scheduled := _schedule.day_for(day_number) if _schedule != null else null
		return scheduled if scheduled != null else _fallback

	func _add(path: String, kind: StringName, extra: Dictionary = {}) -> void:
		var step := {"path": path, "kind": kind}
		step.merge(extra)
		_steps.append(step)

	## 지나는 씬의 순서를 일정·목록·규칙에서 만든다. 몰 수 없는 설정이면 false.
	func plan() -> bool:
		# 저장을 끈다. 처음 화면이 늘 버튼 둘이고 "가게를 연다"가 새 1일차다(실제 저장 파일을 읽지도 쓰지도 않는다).
		var session := _session()
		if session == null:
			_fail("GameSession 오토로드가 없음")
			return false
		_real_save_path = String(session.get("save_path"))
		_real_save_before = _file_text(_real_save_path)
		session.set("save_path", "")
		_rules = load(Session.ECONOMY_PATH) as EconomyRules
		_schedule = load(Session.SCHEDULE_PATH) as DaySchedule
		_fallback = load(Session.DAY_PATH) as DayData
		_reputation = load(Session.REPUTATION_PATH) as ReputationRules
		var catalog := load(Session.CATALOG_PATH) as UpgradeCatalog
		if catalog != null:
			for upgrade in catalog.upgrades:
				if upgrade != null:
					_upgrades.append(upgrade)
		if _rules == null or _rules.duels_per_day <= 0:
			_fail("결투 수 0은 지원하지 않는다")
			return false
		var day1 := _day_for(1)
		var day2 := _day_for(2)
		if day1 == null or day1.commissions.is_empty() or day2 == null or day2.commissions.is_empty():
			_fail("1일차나 2일차에 손님이 없다")
			return false
		# 1일차의 손님 수도 게임과 같은 식으로 센다(기준 손님 수가 있는 날이면 시작 평판의 별에 달렸다).
		var guests1 := _guests_on(day1, _reputation.clamp_value(_reputation.start) if _has_reputation() else 0, _rules.duels_per_day)
		# 2일차의 결투 수는 1일차 폐점에서 목록을 전부 산 뒤의 적용된 규칙에서 읽는다.
		_duels2 = (UpgradeData.applied(_rules, UpgradeData.Target.ECONOMY, _upgrades) as EconomyRules).duels_per_day
		_day1_duels = mini(guests1, _rules.duels_per_day)
		print("DAY SMOKE 일정 %d일, 1일차 손님 %d, 2일차 목록 %d(기준 %d), 결투 수 %d/%d(2일차), 평판 %s" % [
			_schedule.days.size() if _schedule != null else 0, guests1, day2.commissions.size(), day2.base_guests,
			_rules.duels_per_day, _duels2, "켜짐" if _has_reputation() else "꺼짐"])

		_add(TITLE, &"title_open")
		# 1일차: 오는 손님을 전부 맡는다. 결투 수가 먼저 차면 거기서 폐점이다.
		for i in _day1_duels:
			_add(COUNTER, &"counter_accept", {"shot": "counter_day1_first" if i == 0 else "counter"})
			_add(DUEL, &"duel", {"bot": i == 0})
			_add(SETTLEMENT, &"settlement")
		_add(CLOSING, &"closing_buy_all")
		# 2일차부터는 1일차 폐점에서 붙인다(_plan_rest).
		return true

	func _has_reputation() -> bool:
		return _reputation != null and _reputation.enabled

	## 그 하루에 그 평판과 결투 수로 오는 손님 수. 게임(DayState)과 따로, 같은 순수 함수로 계산한다.
	func _guests_on(day_data: DayData, reputation: int, duels: int) -> int:
		var delta := _reputation.guest_change(_reputation.stars(reputation)) if _has_reputation() else 0
		return ReputationRules.guest_count(day_data.commissions.size(), day_data.base_guests, delta, duels)

	## 2일차부터의 순서. 1일차 폐점에서 전부 산 뒤 "다음 날을 연다"를 누르기 직전에 부른다.
	## 2일차의 손님 수는 day의 "내일의 손님 수"에서 읽고, 따로 계산한 값과 견준다.
	func _plan_rest(day: DayState) -> bool:
		var day2 := _day_for(2)
		var guests2 := day.tomorrow_guests()
		var want := _guests_on(day2, day.reputation, _duels2)
		if guests2 != want:
			_fail("1일차 폐점의 내일의 손님 %d (따로 계산한 값 %d)" % [guests2, want])
			return false
		_guests2 = guests2
		var duels2 := _duels2
		if _has_reputation():
			print("DAY SMOKE 1일차 뒤 평판 %d(별 %d), 2일차 손님 %d (기준 %d, 목록 %d)" % [
				day.reputation, day.reputation_stars(), guests2, day2.base_guests, day2.commissions.size()])
		else:
			print("DAY SMOKE 평판 꺼짐, 2일차 손님 %d (기준 %d, 목록 %d)" % [guests2, day2.base_guests, day2.commissions.size()])

		var reason := ""
		if guests2 < 3:
			reason = "2일차 손님 %d명 (셋 이상이어야 한다)" % guests2
		elif duels2 < 2:
			reason = "2일차 결투 수 %d (둘 이상이어야 한다)" % duels2
		if reason == "":
			# 2일차: 첫 손님을 돌려보내고, 둘째를 맡고, 나머지를 전부 돌려보낸다.
			_add(COUNTER, &"counter_decline", {"first": true, "shot": "counter_day2_first"})
			_add(COUNTER, &"counter_accept", {"declined_line": true, "shot": "counter_day2_declined_line"})
			_add(DUEL, &"duel", {"day2": true})
			_add(SETTLEMENT, &"settlement", {"day2": true})
			for i in range(2, guests2):
				_add(COUNTER, &"counter_decline", {"mark_money": i == guests2 - 1, "shot": "counter_day2_guest%d" % (i + 1)})
			_add(CLOSING, &"closing_day2", {"guests": guests2})
			_add(COUNTER, &"quit", {"day3": true})
		else:
			# 005의 2일차 경로: 첫 손님을 맡고, 정산 뒤의 화면(카운터 또는 폐점)에서 나간다.
			print("DAY SMOKE 돌려보내기 구간 건너뜀: %s" % reason)
			_add(COUNTER, &"counter_accept", {"day2_first": true, "shot": "counter_day2_first"})
			_add(DUEL, &"duel", {"day2": true})
			_add(SETTLEMENT, &"settlement", {"day2": true})
			# DayState.has_next_commission()과 같은 답이다.
			_add(COUNTER if guests2 >= 2 and duels2 >= 2 else CLOSING, &"quit")
		# 빠져나오는 길과 연습 경로: 처음 화면 → 연습 → Esc → 처음 화면 → Enter → 새 1일차 카운터
		_add(TITLE, &"title_practice")
		_add(SELECT, &"select_esc")
		_add(TITLE, &"title_enter")
		_add(COUNTER, &"counter_final")
		return true

	# ------------------------------------------------------------ 운전

	func _process(_delta: float) -> void:
		if _done:
			# 비프음 재생 객체는 오디오 스레드가 놓아 준다. 바로 끝내면 누수 줄이 찍힌다.
			if Time.get_ticks_msec() >= _quit_at_msec:
				get_tree().quit(_exit_code)
			return
		_frames += 1
		if _frames > MAX_FRAMES:
			_fail("프레임 상한 %d을 넘음 (지난 씬 %d/%d)" % [MAX_FRAMES, _visited, _steps.size()])
			return
		var scene := get_tree().current_scene
		# change_scene_to_file 직후부터 그 프레임 끝까지 현재 씬은 null이다.
		if scene == null or scene.scene_file_path == "res://tests/day_smoke.tscn":
			return
		# 같은 씬 파일을 다시 열어도(카운터 → 카운터) 새 인스턴스다. 인스턴스 id로 씬 바뀜을 잡는다.
		if scene.get_instance_id() != _scene_id:
			_scene_id = scene.get_instance_id()
			_scene_frames = 0
			_stage = 0
			if _visited >= _steps.size() or scene.scene_file_path != _steps[_visited]["path"]:
				_fail("%d번째 씬이 %s (기대 %s)" % [_visited + 1, scene.scene_file_path,
					_steps[_visited]["path"] if _visited < _steps.size() else "없음"])
				return
			_step = _steps[_visited]
			_visited += 1
		_scene_frames += 1
		if _scene_frames < _wait:
			return
		match _step["kind"]:
			&"duel":
				_drive_duel(scene)
			&"closing_buy_all":
				_drive_closing_buy_all(scene)
			_:
				if _stage == 0:
					_stage = 1
					_drive_once(scene)

	func _session() -> Node:
		return get_node_or_null(^"/root/GameSession")

	func _day() -> DayState:
		var session := _session()
		return session.get("day") as DayState if session != null else null

	## 그 파일의 내용. 경로가 비었거나 파일이 없으면 "<없음>"이다.
	func _file_text(path: String) -> String:
		if path == "" or not FileAccess.file_exists(path):
			return "<없음>"
		return FileAccess.get_file_as_string(path)

	## 한 번에 끝나는 화면.
	func _drive_once(scene: Node) -> void:
		var session := _session()
		var day := _day()
		match _step["kind"]:
			&"title_open":
				if scene.find_child("Continue", true, false) != null:
					_fail("저장을 껐는데 처음 화면에 Continue가 있음")
					return
				_shot("title")
				_press_or_fail(scene, "Proceed")
			&"counter_accept":
				_drive_counter_accept(scene, day)
			&"counter_decline":
				_drive_counter_decline(scene, day)
			&"settlement":
				if _step.get("day2", false):
					if not _check_day2_settlement(day):
						return
					_shot("settlement_day2")
				else:
					_shot("settlement")
				# 평판 줄은 평판이 있을 때만 있다(끈 상태에서는 없어야 한다).
				if day != null and (scene.find_child("ReputationLine", true, false) != null) != day.has_reputation():
					_fail("정산의 ReputationLine 유무가 평판의 유무와 다름")
					return
				_press_or_fail(scene, "Proceed")
			&"closing_day2":
				_drive_closing_day2(scene, day)
			&"quit":
				# 카운터의 "오늘은 그만"과 폐점의 "처음 화면으로"는 둘 다 Quit이다.
				if _step.get("day3", false):
					if day == null or day.day_number != 3 or day.phase != DayState.Phase.COUNTER or day.data != _day_for(3):
						_fail("2일차 폐점 뒤의 카운터가 일정의 3일차 첫 카운터가 아님")
						return
					_shot("counter_day3")
				_press_or_fail(scene, "Quit")
			&"title_practice":
				if day != null:
					_fail("하루 플레이에서 나갔는데 GameSession.day가 남아 있음")
					return
				_press_or_fail(scene, "Practice")
			&"select_esc":
				_shot("practice_select")
				_send_key(KEY_ESCAPE)
			&"title_enter":
				# 포커스된 버튼에 실제 Enter 키.
				_send_key(KEY_ENTER)
			&"counter_final":
				if day == null or day.day_number != 1 or day.phase != DayState.Phase.COUNTER \
						or day.money != day.rules.starting_money or day.data != _day_for(1):
					_fail("Enter로 연 가게가 새 1일차 카운터가 아님")
					return
				if not day.owned.is_empty():
					_fail("하루 플레이를 새로 시작했는데 업그레이드가 %d개 남아 있음" % day.owned.size())
					return
				if session.get("commission") != null:
					_fail("하루 플레이를 시작했는데 연습의 의뢰가 남아 있음")
					return
				if _file_text(_real_save_path) != _real_save_before:
					_fail("스모크가 실제 저장 파일을 바꿈")
					return
				print("DAY SMOKE 저장: 꺼짐, 실제 저장 파일 그대로")
				_succeed()

	## 카운터에서 손님을 맡는다.
	func _drive_counter_accept(scene: Node, day: DayState) -> void:
		if day == null or day.phase != DayState.Phase.COUNTER:
			_fail("카운터 씬인데 단계가 카운터가 아님")
			return
		if scene.find_child("Decline", true, false) == null:
			_fail("카운터에 Decline 버튼이 없음")
			return
		# 돌려보내면 결투가 하나 주는 때에만 그 안내가 있다.
		var wants_note := day.waiting_count() < day.duels_left()
		if (scene.find_child("DeclineNote", true, false) != null) != wants_note:
			_fail("카운터의 DeclineNote 유무가 다름 (기다리는 손님 %d, 남은 결투 %d)" % [day.waiting_count(), day.duels_left()])
			return
		if _step.get("day2_first", false) and not _check_day2_first(day):
			return
		if _step.get("declined_line", false):
			# 방금 돌려보낸 손님의 한마디. 화면 전체가 아니라 그 노드의 글자를 읽는다.
			var declined: Commission = _day_for(2).commissions[0]
			var label := scene.find_child("DeclinedLine", true, false) as Label
			if declined.decline_line == "":
				if label != null:
					_fail("한마디가 빈 손님을 돌려보냈는데 DeclinedLine이 있음")
					return
			elif label == null or not label.text.contains(declined.client_name) or not label.text.contains(declined.decline_line):
				_fail("돌려보낸 뒤의 카운터에 그 손님의 한마디가 없음")
				return
		_shot(String(_step.get("shot", "counter")))
		_press_or_fail(scene, "Proceed")

	## 카운터에서 손님을 돌려보낸다. 다음 화면은 다음 손님의 카운터(같은 씬 파일의 새 인스턴스)거나 폐점이다.
	func _drive_counter_decline(scene: Node, day: DayState) -> void:
		if day == null or day.phase != DayState.Phase.COUNTER:
			_fail("카운터 씬인데 단계가 카운터가 아님")
			return
		if _step.get("first", false) and not _check_day2_first(day):
			return
		if _step.has("shot"):
			_shot(String(_step["shot"]))
		var index := day.index
		var declined := day.declined.size()
		var results := day.results.size()
		var money := day.money
		var last := day.waiting_count() == 0
		if _step.get("mark_money", false):
			_money_mark = money
		if not _press(scene, "Decline"):
			_fail("카운터에 Decline 버튼이 없음")
			return
		if day.declined.size() != declined + 1 or day.results.size() != results:
			_fail("돌려보냈는데 돌려보낸 손님 %d명, 결과 %d건" % [day.declined.size(), day.results.size()])
			return
		if last:
			if day.phase != DayState.Phase.CLOSING:
				_fail("마지막 손님을 돌려보냈는데 폐점이 아님")
		elif day.phase != DayState.Phase.COUNTER or day.index != index + 1 or day.money != money:
			_fail("돌려보낸 뒤 단계 %d, 순번 %d, 소지금 %d" % [day.phase, day.index, day.money])

	## 2일차의 첫 카운터: 일정의 둘째 날이고, 1일차에 산 것이 남아 있다.
	func _check_day2_first(day: DayState) -> bool:
		if day.day_number != 2 or day.index != 0 or day.data != _day_for(2):
			_fail("1일차 폐점 뒤의 카운터가 일정의 2일차 첫 카운터가 아님")
			return false
		if day.commission_count() != _guests2:
			_fail("2일차의 손님 %d (1일차 폐점에서 본 내일의 손님 %d)" % [day.commission_count(), _guests2])
			return false
		if day.owned.size() != _upgrades.size():
			_fail("2일차로 넘어가며 가진 업그레이드가 달라짐 (%d개)" % day.owned.size())
			return false
		return true

	## 2일차 첫 정산: 유효타를 맞고 끝났으면 치료비가 업그레이드가 적용된 값이다.
	func _check_day2_settlement(day: DayState) -> bool:
		if day == null or day.phase != DayState.Phase.SETTLEMENT or day.last_result().is_empty():
			_fail("2일차 정산 씬인데 정산 결과가 없음")
			return false
		var result := day.last_result()
		if not result["injured"]:
			print("DAY SMOKE 2일차 정산: 유효타를 맞지 않고 끝나 치료비 확인을 건너뜀")
			return true
		var want := (UpgradeData.applied(day.rules, UpgradeData.Target.ECONOMY, _upgrades) as EconomyRules).medical_fee
		if int(result["medical_fee"]) != want:
			_fail("2일차 정산의 치료비 %d (기대 %d, 기본 %d)" % [result["medical_fee"], want, day.rules.medical_fee])
			return false
		print("DAY SMOKE 2일차 정산: 치료비 %d (기본 %d)" % [result["medical_fee"], day.rules.medical_fee])
		return true

	## 2일차 폐점: 사지 않고 요약만 확인한 뒤 다음 날을 연다.
	func _drive_closing_day2(scene: Node, day: DayState) -> void:
		if day == null or day.phase != DayState.Phase.CLOSING:
			_fail("폐점 씬인데 단계가 폐점이 아님")
			return
		var guests: int = _step["guests"]
		var summary := day.closing_summary()
		var declined: Array = summary.get("declined", [])
		if summary.get("duels") != 1 or declined.size() != guests - 1 or summary.get("missed") != 0:
			_fail("2일차 폐점의 요약이 다름: 결투 %s, 돌려보낸 손님 %d, 만나지 못한 손님 %s" % [
				str(summary.get("duels")), declined.size(), str(summary.get("missed"))])
			return
		var medical := 0
		for result in day.results:
			medical += int(result["medical_fee"])
		var rent := (UpgradeData.applied(day.rules, UpgradeData.Target.ECONOMY, _upgrades) as EconomyRules).rent
		if summary.get("money_before") != _money_mark or day.money != _money_mark - rent - medical:
			_fail("2일차 폐점 뒤 소지금 %d (기대 %d)" % [day.money, _money_mark - rent - medical])
			return
		var names := scene.find_child("DeclinedNames", true, false) as Label
		if names == null or not names.text.contains(String(declined[0])):
			_fail("2일차 폐점에 돌려보낸 손님 줄이 없음")
			return
		print("DAY SMOKE 2일차 폐점: 결투 %d, 돌려보낸 손님 %d, 만나지 못한 손님 %d, 소지금 %d" % [
			summary["duels"], declined.size(), summary["missed"], day.money])
		_shot("closing_day2")
		_press_or_fail(scene, "Proceed")

	func _press(scene: Node, button_name: String) -> bool:
		# 코드로 만든 버튼은 owner가 없다. owned를 끄고 찾는다.
		var button := scene.find_child(button_name, true, false) as Button
		if button == null:
			return false
		button.pressed.emit()
		return true

	func _press_or_fail(scene: Node, button_name: String) -> void:
		if not _press(scene, button_name):
			_fail("%s 에 %s 버튼이 없음" % [scene.scene_file_path, button_name])

	## 결투: R과 Esc가 무시되는지 본 뒤, 끝까지 흘리고 Space로 넘긴다.
	## 1일차 첫 판만 봇으로 친다(돈이 들어온 정산·폐점 화면을 보려고). 나머지는 입력 없이 진다.
	func _drive_duel(scene: Node) -> void:
		var day := _day()
		if day == null:
			_fail("결투 씬인데 GameSession.day가 없음")
			return
		if _stage == 0:
			var core: DuelCore = scene.get("core")
			if _step.get("day2", false) and not _check_day2_duel(day, core):
				return
			# 결과 패널이 뜨기 전의 결투 화면(모자의 유무, 조작 안내). 화면 확인용이다.
			_shot("duel_start")
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
			var bot: RefCounted = null
			if _step.get("bot", false):
				# 화면을 기다리는 프레임 동안 봇 없이 흘러간 판을 버리고 새 판으로 시작한다(스모크만의 조작).
				scene.call("start_duel")
				scene.set("mouse_aim_enabled", false)
				core = scene.get("core")
				bot = Bot.new(core, Bot.first_blood_cfg())
			var ticks := 0
			while not core.ended and ticks < MAX_TICKS:
				scene.call("advance", 1.0 / 60.0)
				if bot != null:
					bot.call("update")
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

	## 2일차 결투: 코어의 결투 규칙이 산 업그레이드가 적용된 것이다.
	func _check_day2_duel(day: DayState, core: DuelCore) -> bool:
		var base := load(DUEL_RULES_PATH) as DuelRules
		var want := (UpgradeData.applied(base, UpgradeData.Target.DUEL, _upgrades) as DuelRules).player_posture_max
		if core.rules.player_posture_max != want:
			_fail("2일차 결투의 내 자세 %d (기대 %d, 기본 %d)" % [core.rules.player_posture_max, want, base.player_posture_max])
			return false
		print("DAY SMOKE 2일차 결투: 내 자세 %d (기본 %d)" % [core.rules.player_posture_max, base.player_posture_max])
		_shot("duel_day2_hud")
		return true

	## 1일차 폐점: 장부를 확인하고, 업그레이드를 전부 사고, 다음 날을 연다.
	## 화면을 바꾼 뒤에는 _scene_frames를 0으로 돌려 다시 기다린 다음 찍는다(찍히는 것은 직전에 그려진 프레임이다).
	func _drive_closing_buy_all(scene: Node) -> void:
		var day := _day()
		if day == null or day.phase != DayState.Phase.CLOSING:
			_fail("폐점 씬인데 단계가 폐점이 아님")
			return
		match _stage:
			0:
				if not _check_ledger(scene, day):
					return
				if (scene.find_child("ReputationLedger", true, false) != null) != day.has_reputation():
					_fail("폐점의 ReputationLedger 유무가 평판의 유무와 다름")
					return
				var buttons := scene.find_children("Buy_*", "Button", true, false)
				if buttons.size() != _upgrades.size():
					_fail("폐점의 Buy_ 버튼 %d개 (목록 %d개)" % [buttons.size(), _upgrades.size()])
					return
				var cheapest := 0
				for upgrade in _upgrades:
					cheapest = upgrade.price if cheapest == 0 else mini(cheapest, upgrade.price)
				if not _upgrades.is_empty() and day.money < cheapest:
					# 살 수 없는 버튼의 신호를 코드로 발사해도 아무것도 바뀌지 않는다.
					var money := day.money
					for button in buttons:
						(button as Button).pressed.emit()
					if day.money != money or not day.owned.is_empty():
						_fail("소지금이 모자란데 버튼의 신호로 사짐")
						return
				_shot("closing_before")
				_stage = 1
			1:
				# 스모크만의 조작: 지갑에 목록의 값의 합을 직접 넣는다(벌어서 사는 경로는 T35가 숫자로 검사한다).
				var total := 0
				for upgrade in _upgrades:
					total += upgrade.price
				day.money = total
				scene.call("refresh_shop")
				print("DAY SMOKE 지갑 채움: %d" % total)
				if not _upgrades.is_empty():
					if not _press(scene, "Buy_%s" % _upgrades[0].id) or not day.owns(_upgrades[0]) \
							or day.money != total - _upgrades[0].price:
						_fail("폐점에서 %s 을(를) 사지 못함" % _upgrades[0].id)
						return
				_scene_frames = 0
				_stage = 2
			2:
				_shot("closing_one_bought")
				for i in range(1, _upgrades.size()):
					if not _press(scene, "Buy_%s" % _upgrades[i].id) or not day.owns(_upgrades[i]):
						_fail("폐점에서 %s 을(를) 사지 못함" % _upgrades[i].id)
						return
				if day.money != 0 or day.owned.size() != _upgrades.size():
					_fail("전부 산 뒤 소지금 %d, 가진 것 %d개 (기대 0, %d)" % [day.money, day.owned.size(), _upgrades.size()])
					return
				if scene.get("shown_money") != day.money:
					_fail("폐점 화면의 소지금이 day와 다름")
					return
				print("DAY SMOKE 구매: %d개를 전부 삼, 소지금 %d" % [day.owned.size(), day.money])
				_scene_frames = 0
				_stage = 3
			3:
				_stage = 4
				_shot("closing_all_bought")
				# 2일차부터의 순서를 지금 만든다(전부 산 뒤라 내일의 결투 수와 손님 수가 정해졌다).
				if not _plan_rest(day):
					return
				_press_or_fail(scene, "Proceed")

	## 1일차 폐점의 장부. 치료비는 결과들의 medical_fee 합으로 센다(결과마다 그때의 단가가 들어 있다).
	func _check_ledger(scene: Node, day: DayState) -> bool:
		if day.results.size() != _day1_duels:
			_fail("폐점의 결과 %d건 (기대 %d)" % [day.results.size(), _day1_duels])
			return false
		var income := 0
		var injuries := 0
		var medical := 0
		for result in day.results:
			income += int(result["total"])
			if result["injured"]:
				injuries += 1
				medical += int(result["medical_fee"])
		var want := day.rules.starting_money + income - day.rules.rent - medical
		if day.money != want:
			_fail("폐점 뒤 소지금 %d (기대 %d)" % [day.money, want])
			return false
		if scene.get("shown_profit") != day.closing_summary().get("profit"):
			_fail("폐점 화면의 손익이 요약과 다름")
			return false
		print("DAY SMOKE 장부: 수입 %d, 임대료 %d, 부상 %d회, 치료비 %d, 손익 %d, 소지금 %d" % [
			income, day.rules.rent, injuries, medical, int(day.closing_summary()["profit"]), day.money])
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
