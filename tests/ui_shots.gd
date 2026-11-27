extends Node
## 필사본 UI 찍기(계획 033 작업 7). 견본 025와 짝이 되는 장(pair-*) 다섯을 먼저, 견본이 없는 장을 뒤에 찍는다.
## 실행: tests/run_ui_shots.ps1 (창, -- --shots=<폴더>). 폴더가 없거나 헤드리스면 저장하지 않고 돈다.
## 장마다 "state,<장>,<놓은 것>"과 "size,<장>,<w>x<h>"를 낸다. 화면은 이 씬 아래에 붙으므로 저장하지도 씬을 바꾸지도 않는다.

const DT := preload("res://scripts/duel/duel_types.gd")
const Day := preload("res://tests/day_tests.gd")
const States := preload("res://tests/opponent_states.gd")
const Session := preload("res://scripts/game_session.gd")
const WornEdge := preload("res://scripts/ui/worn_edge.gd")
const PanelStyle := preload("res://scripts/ui/manuscript_panel_style.gd")
const Select := preload("res://scripts/commission/commission_select.gd")
const Practice := preload("res://tests/practice_screen_tests.gd")

const FEATHER_PATH := "res://data/commissions/feather_cut.tres"
const USURER_PATH := "res://data/commissions/variants/first_blood_usurer.tres"
const POOR_PATH := "res://data/commissions/variants/first_blood_poor.tres"
const SPAR_PATH := "res://data/commissions/spar.tres"
const COURT_PATH := "res://data/commissions/variants/court_beehive.tres"
const NOBLE_PATH := "res://data/commissions/variants/noble_baker.tres"
## 카운터의 의뢰인이 미끄러져 들어오는 시간(0.45초)과 간격의 보간이 끝날 때까지 기다린다.
const SETTLE_MSEC := 900
const WEAPON_PATH := "res://data/weapons/rapier.tres"
const DELTA := 1.0 / 60.0
## pause-hold: 예비 동작의 이만큼 지난 순간(pattern_shots.gd의 PROGRESS와 같다).
const HOLD_PROGRESS := 0.35

var _shots_dir := ""
var _d := Day.new()
var _plan: Array = []
var _i := -1
var _node: Node
var _since := 0
var _frames := 0
## 견본의 정산·카운터 장면을 잇는 하루(클라라 100점 → 비토리오)와 폐점까지 가는 하루.
var _pair_day: DayState
var _closing_day: DayState
## 한 장에서 헤진 판의 자름 상자와 글·버튼 사각형이 겹친 수(계획 S02 작업 7).
var _wearhit := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	if _shots_dir != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	else:
		_shots_dir = ""
	# 자동 로드 Settings의 쓰기를 끈다: 찍기를 따로 돌려도 플레이어의 설정 파일을 적지 않는다(계획 S01).
	var settings := get_node_or_null(^"/root/Settings")
	if settings != null:
		if settings.has_method("detach_for_run"):
			settings.call("detach_for_run")
		else:
			settings.set("path", "")
	_d.set("_tree", get_tree())
	_plan = [
		["pair-duel", _pair_duel], ["pair-duel-warn", _pair_duel_warn], ["pair-settle", _pair_settle],
		["pair-counter", _pair_counter], ["pair-closing", _pair_closing],
		["title", _title], ["title-save", _title_save], ["help", _help], ["settings", _settings], ["select", _select],
		["settle-hurt", _settle_hurt], ["duel-far", _duel_far], ["duel-close", _duel_close],
		["duel-close-bighold", _duel_close_bighold], ["duel-right-high", _duel_right_high], ["result", _result],
		["pause-practice", _pause_practice], ["pause-day", _pause_day], ["pause-settings", _pause_settings],
		["quit-confirm", _quit_confirm], ["menu-counter", _menu_counter], ["pause-hold", _pause_hold],
		["settings-controls", _settings_controls], ["settings-controls-empty", _settings_controls_empty],
		["settings-display", _settings_display],
		["select-spare", _select_spare], ["select-many", _select_many], ["select-story", _select_story],
		["counter-spar", _counter_spar], ["duel-spar-stagger", _duel_spar_stagger], ["settle-spar", _settle_spar],
		["counter-court", _counter_court], ["counter-noble", _counter_noble],
	]
	_next()


func _next() -> void:
	if _node != null:
		_node.free()
		_node = null
	# 조작 장이 바꾼 키를 되돌린다(쓰기는 꺼져 있다. 계획 S03 작업 6).
	var run_settings := get_node_or_null(^"/root/Settings")
	if run_settings != null and run_settings.has_method("reset_controls"):
		run_settings.call("reset_controls")
	_i += 1
	if _i >= _plan.size():
		# 창이 잠겼고 창을 한 번도 건드리지 않았는지(계획 S04 결정 531). run_ui_shots.ps1이 "display,1,0"만 받는다.
		if run_settings != null:
			print("display,%d,%d" % [1 if run_settings.get("window_locked") else 0, int(run_settings.get("_window_calls"))])
		_reset_select()
		print("UI SHOTS OK %d" % _plan.size())
		set_process(false)
		get_tree().quit(0)
		return
	var note: String = (_plan[_i][1] as Callable).call()
	print("state,%s,%s" % [_plan[_i][0], note])
	_since = Time.get_ticks_msec()
	_frames = 0


## 보이는 버튼·글 칸의 가장 먼 오른쪽·아래 끝(연습 화면이 1280x720 안인지).
func _far_edge(root: Node) -> Vector2:
	var far := Vector2.ZERO
	for node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if (control is Button or control is Label) and control.is_visible_in_tree():
			far = far.max(control.get_global_rect().end)
	return far


func _process(_delta: float) -> void:
	if _node == null:
		return
	_frames += 1
	if _frames >= 3 and Time.get_ticks_msec() - _since >= SETTLE_MSEC:
		# 헤드리스에는 그림이 없다: 크기는 뷰포트에서 읽는다(verify.ps1이 창 없이 돈다).
		var shot_size := Vector2i(get_viewport().get_visible_rect().size)
		if _shots_dir != "":
			var image := get_viewport().get_texture().get_image()
			image.save_png(_shots_dir.path_join(String(_plan[_i][0]) + ".png"))
			shot_size = image.get_size()
		print("size,%s,%dx%d" % [_plan[_i][0], shot_size.x, shot_size.y])
		var grid := _node.find_child("TrialGrid", true, false) as Control
		var help := _node.find_child("PatternHelp", true, false) as Control
		if grid != null and help != null:
			print("fit,%s,%d,%d" % [_plan[_i][0], int(grid.get_global_rect().end.x), int(help.get_global_rect().end.y)])
			print("practice,%s,%d,%d,%d,%d" % [_plan[_i][0], 1 if _node.find_child("PartCounterToggle", true, false) != null else 0,
					1 if _node.find_child("SlashDrill", true, false) != null else 0, int(_far_edge(_node).x), int(_far_edge(_node).y)])
		_practice_lines(String(_plan[_i][0]))
		_wearhit = 0
		_wear_lines(_node, String(_plan[_i][0]))
		print("wearhit,%s,%d" % [_plan[_i][0], _wearhit])
		var q: Dictionary = PanelStyle.quota(_node)
		print("wearq,%s,%d,%d,%d" % [_plan[_i][0], q["n"], q["k"], (q["worn"] as Dictionary).size()])
		_next()


# 헤진 판의 자름(계획 033b 작업 4b): wear,<장>,<전역 x,y,w,h>,<꼴>@<x>,<y>,<w>,<h>;… (판 안의 좌표, 자름이 없으면 -).
func _wear_lines(node: Node, shot: String) -> void:
	if node is PanelContainer and (node as Control).is_visible_in_tree():
		var pc := node as PanelContainer
		var sb := pc.get_theme_stylebox("panel")
		if sb != null and "wear" in sb and int(sb.get("wear")) > 0:
			var rect := pc.get_global_rect()
			var parts: PackedStringArray = []
			if sb.get("paper") != null and sb.get("frame") != null and minf(pc.size.x, pc.size.y) >= float(sb.get("wear_min_side")):
				var name_seed := PanelStyle.worn_seed_of(pc)
				for cut in (WornEdge.cuts(pc.size, int(sb.get("wear")), int(sb.get("wear_seed")) + name_seed) if name_seed >= 0 else []):
					var b: Rect2 = cut["box"]
					parts.append("%s@%d,%d,%d,%d" % [cut["kind"], b.position.x, b.position.y, b.size.x, b.size.y])
					_wearhit += _hits_in(pc, Rect2(rect.position + b.position, b.size))
			print("wear,%s,%d,%d,%d,%d,%s" % [shot, rect.position.x, rect.position.y, rect.size.x, rect.size.y,
				";".join(parts) if not parts.is_empty() else "-"])
	for child in node.get_children():
		_wear_lines(child, shot)


## 자름 상자(전역)와 겹치는, 그 판의 보이는 자손 Label·Button(글이 빈 Label은 뺀다)의 수.
func _hits_in(node: Node, cut: Rect2) -> int:
	var hits := 0
	for child in node.get_children():
		if (child is Label and not (child as Label).text.is_empty()) or child is Button:
			var control := child as Control
			if control.is_visible_in_tree() and control.get_global_rect().intersection(cut).get_area() > 0.0:
				hits += 1
		hits += _hits_in(child, cut)
	return hits


# ---------------------------------------------------------------- 하루 화면

func _screen(path: String, day: DayState) -> void:
	_node = (load(path) as PackedScene).instantiate()
	_node.set_meta("wear_screen", true)
	if day != null:
		_node.set("day", day)
	add_child(_node)


## 고정 점수의 의뢰에 실제 의뢰의 이름·한마디·평판·무대·그림을 입힌다(결투를 돌리지 않고 견본의 점수를 낸다).
func _scored(real_path: String, base_reward: int, tip_max: int, score: int) -> Commission:
	var real := load(real_path) as Commission
	var commission: Commission = _d._fixed_commission(real.client_name, base_reward, tip_max, score)
	commission.success_line = real.success_line
	commission.partial_line = real.partial_line
	commission.fail_line = real.fail_line
	commission.reputation_effect = real.reputation_effect
	commission.opponent = real.opponent
	commission.client_portrait = real.client_portrait
	return commission


func _new_day(commissions: Array[Commission]) -> DayState:
	var data := DayData.new()
	data.commissions = commissions
	return DayState.new(load(Session.ECONOMY_PATH), data, load(Session.CATALOG_PATH), null, load(Session.REPUTATION_PATH))


func _pair_settle() -> String:
	var commissions: Array[Commission] = [_scored(FEATHER_PATH, 45, 25, 100), load(USURER_PATH), load(POOR_PATH)]
	_pair_day = _new_day(commissions)
	_pair_day.accept()
	_pair_day.finish_duel(_d._record(DT.EndReason.CONDITION))
	_screen(Session.SETTLEMENT_PATH, _pair_day)
	return "클라라 100점(고정 점수 의뢰) 평판 %d" % _pair_day.reputation


func _pair_counter() -> String:
	_pair_day.proceed()
	_screen(Session.COUNTER_PATH, _pair_day)
	return "비토리오 손님 %d/%d 소지금 %d" % [_pair_day.index + 1, _pair_day.commission_count(), _pair_day.money]


## 견본의 폐점: 클라라 100 · 비토리오 85 · 토마소 60(다침). 견본의 돌려보낸 이네스는 넣지 않았다.
func _closed_day() -> DayState:
	var commissions: Array[Commission] = [_scored(FEATHER_PATH, 45, 25, 100), _scored(USURER_PATH, 55, 20, 85), _scored(POOR_PATH, 30, 10, 60)]
	var day := _new_day(commissions)
	for end_reason: int in [DT.EndReason.CONDITION, DT.EndReason.CONDITION, DT.EndReason.PLAYER_DEFEATED]:
		day.accept()
		day.finish_duel(_d._record(end_reason))
		if end_reason != DT.EndReason.PLAYER_DEFEATED:
			day.proceed()
	return day


func _pair_closing() -> String:
	_closing_day = _closed_day()
	_closing_day.proceed()
	_screen(Session.CLOSING_PATH, _closing_day)
	return "셋을 끝낸 폐점(돌려보낸 손님 없음) 소지금 %d" % _closing_day.money


func _settle_hurt() -> String:
	_screen(Session.SETTLEMENT_PATH, _closed_day())
	return "토마소 60점 다침"


func _title() -> String:
	# 처음 화면은 세션에서 저장을 읽는다. 찍는 동안만 저장 자리를 비워 저장 없는 꼴을 낸다.
	var session := get_node_or_null(^"/root/GameSession")
	var kept := String(session.get("save_path")) if session != null else ""
	if session != null:
		session.set("save_path", "")
	_screen(Session.TITLE_PATH, null)
	if session != null:
		session.set("save_path", kept)
	return "저장 없음"


func _title_save() -> String:
	_node = (load(Session.TITLE_PATH) as PackedScene).instantiate()
	_node.set_meta("wear_screen", true)
	_node.set("saved", _closing_day)
	add_child(_node)
	return "저장 있음(%d일차)" % _closing_day.day_number


func _help() -> String:
	_title_save()
	(_node.find_child("Help", true, false) as Button).pressed.emit()
	return "도움말 화면"


func _settings() -> String:
	_title()
	(_node.find_child("Settings", true, false) as Button).pressed.emit()
	return "설정 화면(저장 없는 처음 화면 위)"


func _settings_controls() -> String:
	_settings()
	(_node.find_child("TabControls", true, false) as Button).pressed.emit()
	return "설정 화면의 조작 탭(처음 값)"


func _settings_display() -> String:
	_settings()
	(_node.find_child("TabDisplay", true, false) as Button).pressed.emit()
	return "설정 화면의 화면 탭(처음 값, 본보기 모니터의 크기 셋)"


## 막기를 좌클릭으로: 공격이 비고 알림·"없음"·경고가 함께 뜬 가장 긴 꼴. 화면의 _input에 직접 누름을 넣는다(버튼 밖의 자리).
func _settings_controls_empty() -> String:
	_settings_controls()
	var screen := _node.find_child("SettingsScreen", true, false)
	(_node.find_child("Bind_guard", true, false) as Button).pressed.emit()
	screen.set("_capture_msec", Time.get_ticks_msec() - 1000)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(5, 5)
	screen.call("_input", press)
	return "조작 탭: 막기를 좌클릭으로 줘 공격이 빈 모습"


func _select() -> String:
	_screen(Session.SELECT_PATH, null)
	return "연습 선택"


## 연습 화면이 남기는 static 다섯을 처음 값으로(앞의 장 `select`가 영향받지 않게 새 장은 뒤에 둔다).
func _reset_select() -> void:
	Select._opening_day = 1
	Select._part_effects = false
	Select._style_tier = 0
	Select._picked_opponent = 0
	Select._picked_commission = 0


## 시험 데이터(메모리)로 띄운 연습 화면.
func _practice_screen(trials: Array[OpponentData], spare: Array[AttackData], commissions: Array[Commission]) -> void:
	_reset_select()
	_node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_node.set_meta("wear_screen", true)
	_node.set("trial_source", trials)
	_node.set("spare_source", spare)
	_node.set("commission_source", commissions)
	_node.set("use_sources", true)
	add_child(_node)


func _select_spare() -> String:
	var trials := Select.load_trials()
	_practice_screen(trials, Practice.test_spare(), CommissionLibrary.load_tree(Select.COMMISSION_DIR))
	_node.call("pick_opponent", trials.size())
	return "연습 선택: 주인 없는 검술(시험 공격 하나)"


func _select_many() -> String:
	var trials := Practice.big_trials()
	_practice_screen(trials, Practice.big_spare(), Practice.big_commissions(trials))
	_node.call("pick_opponent", 7)
	var pick := _node.find_child("StyleTierPick", true, false) as OptionButton
	if pick != null:
		pick.item_selected.emit(pick.item_count - 1)
	_node.call("pick_commission", 17)
	return "연습 선택: 상대 12명·의뢰 30개(긴 글), 상대 7의 가장 높은 단, 의뢰 17"


func _select_story() -> String:
	var all: Array[Commission] = CommissionLibrary.load_tree(Select.COMMISSION_DIR)
	var longest := 0
	for i in all.size():
		if Select.story_lines(all[i]) > Select.story_lines(all[longest]):
			longest = i
	_practice_screen(Select.load_trials(), Select.load_spare_attacks(), all)
	_node.call("pick_commission", longest)
	return "연습 선택: 가장 긴 사연(의뢰 %d, 셈 %d줄)" % [longest, Select.story_lines(all[longest]) if not all.is_empty() else 0]


## many,<장>,<x>,<y>,<버튼 줄 수>,<상대 줄>,<의뢰 줄> 과 story,<장>,<놓인 줄>,<칸의 줄>,<내용 높이>,<칸 높이>,<칸 폭>,<셈의 폭>.
func _practice_lines(shot: String) -> void:
	if shot == "select-many":
		var margin := _node.find_child("ScreenMargin", true, false) as Control
		var grid := _node.find_child("TrialGrid", true, false) as Control
		var end := margin.get_global_rect().end.max(_far_edge(_node))
		print("many,%s,%d,%d,%d,%d,%d" % [shot, ceili(end.x), ceili(end.y), ceili(float(grid.get_child_count()) / Select.DRILL_COLUMNS),
				_node.find_children("OpponentPick*", "Button", true, false).size(), _node.find_children("CommissionPick*", "Button", true, false).size()])
	elif shot == "select-story":
		var story := _node.find_child("CommissionStory", true, false) as RichTextLabel
		if story != null:
			print("story,%s,%d,%d,%d,%d,%d,%d" % [shot, story.get_line_count(), story.get_visible_line_count(), story.get_content_height(),
					int(story.size.y), int(story.size.x), Select.STORY_WIDTH])


# ---------------------------------------------------------------- 결투

func _duel(commission_path: String, day: DayState = null) -> DuelCore:
	_node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	_node.set_meta("wear_screen", true)
	_node.set("commission", load(commission_path))
	if day != null:
		_node.set("day", day)
	_node.set("mouse_aim_enabled", false)
	_node.set("rng_seed", 1)
	add_child(_node)
	# 판과 표시를 이 씬이 놓은 값으로 묶는다. add_child 뒤에 끈다: Godot은 _ready 직전에 처리를 다시 켠다.
	_node.set_process(false)
	_node.set_physics_process(false)
	return _node.get("core")


func _big_attack(opponent: OpponentData) -> AttackData:
	for atk in opponent.attacks:
		# 패턴의 뿌리(세 번 베기)는 큰 공격이지만 버릇의 큰 베기가 아니다(결정 426).
		if atk.is_big and atk.chain.is_empty():
			return atk
	for habit in opponent.habits:
		if habit.response != null and habit.response.is_big:
			return habit.response
	return null


## 상대의 상태와 내 칼을 놓고 화면을 한 번 그린다. big_hold면 큰 베기의 예비 동작이 멈춘 자리다.
func _pose(core: DuelCore, distance: int, big_hold: bool, player_state: int, direction: int, height: int, fresh := false) -> void:
	var now := 0.0
	if big_hold:
		var big := _big_attack(core.opponent_data)
		var tell := big.tell_time * (core.opponent_data.close_tell_multiplier if distance == DT.Distance.CLOSE else 1.0)
		now = States.put(core, DT.OpponentState.TELL, big, OpponentMotion.hold_end(tell, core.weapon.parry_window, core.opponent_data), distance)
	else:
		now = States.put(core, DT.OpponentState.IDLE, null, 0.0, distance)
	core.player_state = player_state
	core.player_state_start = now - 1.0
	core.player_state_end = now + 1.0
	core.aim_direction = direction
	core.aim_height = height
	core.attack_direction = direction
	core.attack_height = height
	core.guard_fresh = fresh
	core.guard_enter_time = now if fresh else -INF
	(_node.get_node("OpponentView") as OpponentView).setup(core.opponent_data, core.weapon, core.opponent_has_hat)
	(_node.get_node("PlayerSwordView") as PlayerSwordView).setup()
	_node.set("_display_time", now)
	_node.call("_update_views", 0.0)


func _pair_duel() -> String:
	var core := _duel(FEATHER_PATH)
	_pose(core, DT.Distance.ENGAGE, true, DT.PlayerState.GUARD, DT.Direction.CENTER, DT.Height.MID, true)
	return "교전 큰 베기 hold · 갓 올린 막기 가운데 · 방심 %.2f(견본 0.45) · 엉킴 %.2f(견본 0.30) · 충족도 게이지 없음(견본 0.6)" % [
		core.complacency(), core.bind_gauge()]


func _pair_duel_warn() -> String:
	var core := _duel(FEATHER_PATH)
	_pose(core, DT.Distance.CLOSE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	# 엉킴과 방심의 값은 코어 밖에서 놓지 않는다. 표시만 견본의 경고 장면으로 놓는다(견본도 드문 조합이라고 적었다).
	var hud := _node.get_node("HUD")
	(hud.get("_bind_bar") as DuelHud.BindBar).set_values(0.9, true)
	(hud.get("_bind_warning") as Label).visible = true
	(hud.get("_complacency_bar") as DuelHud.ComplacencyBar).set_values(1.0, false)
	var outline := _node.get_node("PlayerSwordView/Sword/BindWarning") as Line2D
	outline.visible = true
	outline.default_color.a = 1.0
	return "밀착 대기 · 엉킴 0.9 경고와 방심 가득은 표시만 놓음"


func _duel_far() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.FAR, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	return "멀리 대기(조준 패널이 한 줄 자란다)"


func _duel_close() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.CLOSE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	return "밀착 대기"


func _duel_close_bighold() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.CLOSE, true, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	return "밀착 큰 베기 hold(칼이 위 가운데 패널 위로)"


func _duel_right_high() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.ENGAGE, false, DT.PlayerState.READY, DT.Direction.RIGHT, DT.Height.HIGH)
	return "교전 대기 · 오른쪽 상단 조준(날밑과 조준 패널)"


func _result() -> String:
	var core := _duel(FEATHER_PATH)
	_pose(core, DT.Distance.ENGAGE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	core.ended = true
	core.end_reason = DT.EndReason.TIME_UP
	(_node.get_node("ResultPanel") as ResultPanel).show_result(core, load(FEATHER_PATH))
	return "결과 패널(시간 초과)"


# ---------------------------------------------------------------- 멈춤 화면과 확인 창(계획 S02)
# 찍기 도구는 물리를 꺼 두므로 포커스로는 멈추지 않는다: 멈춤은 pause()를 직접 부른다.

func _pause_practice() -> String:
	_pose(_duel(FEATHER_PATH), DT.Distance.ENGAGE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	_node.call("pause", &"shots")
	return "연습 결투(깃털 자르기) 교전 대기의 멈춤"


## 하루 결투의 멈춤: 처음 화면으로와 노트가 있다.
func _day_duel_paused() -> void:
	var commissions: Array[Commission] = [_scored(FEATHER_PATH, 45, 25, 100), load(USURER_PATH), load(POOR_PATH)]
	var day := _new_day(commissions)
	day.accept()
	_pose(_duel(FEATHER_PATH, day), DT.Distance.ENGAGE, false, DT.PlayerState.READY, DT.Direction.CENTER, DT.Height.MID)
	_node.call("pause", &"shots")


func _pause_day() -> String:
	_day_duel_paused()
	return "하루 결투의 멈춤(처음 화면으로와 노트)"


func _pause_settings() -> String:
	_day_duel_paused()
	(_node.find_child("PauseSettings", true, false) as Button).pressed.emit()
	return "하루 결투의 멈춤 위의 설정 화면"


func _counter_day() -> DayState:
	var commissions: Array[Commission] = [_scored(FEATHER_PATH, 45, 25, 100), load(USURER_PATH), load(POOR_PATH)]
	var day := _new_day(commissions)
	_screen(Session.COUNTER_PATH, day)
	return day


## 대련(계획 043): 카운터에 선 사범의 말풍선 · 조건 글 · "상대:" 줄이 안에 다 서는지.
func _counter_spar() -> String:
	var commissions: Array[Commission] = [load(SPAR_PATH), load(USURER_PATH), load(POOR_PATH)]
	_screen(Session.COUNTER_PATH, _new_day(commissions))
	return "카운터: 대련 의뢰(첫 손님)"


## put 뒤에 advance·tick을 부르지 않는다: 놓은 코어를 걸리면 끝나지 않는 고리다(계획 043 위험 R9).
func _duel_spar_stagger() -> String:
	var core := _duel(SPAR_PATH)
	var now := States.put(core, DT.OpponentState.STAGGER, null, 0.0, DT.Distance.ENGAGE)
	core.record.add({"type": DuelRecord.STAGGER_START, "t": now, "end_time": core.brain.state_end})
	_node.set("_display_time", now)
	_node.call("_update_views", 0.0)
	return "대련 의뢰 · 무너짐 1/3 · 귀띔 '치지 마라'"


func _settle_spar() -> String:
	var commissions: Array[Commission] = [_scored(SPAR_PATH, 32, 18, 100), load(USURER_PATH), load(POOR_PATH)]
	var day := _new_day(commissions)
	day.accept()
	day.finish_duel(_d._record(DT.EndReason.CONDITION))
	_screen(Session.SETTLEMENT_PATH, day)
	return "정산: 대련 100점(고정 점수 의뢰에 사범의 한마디)"

func _quit_confirm() -> String:
	var day := _counter_day()
	QuitConfirm.open(_node, Session.quit_note(day, 0))
	return "카운터 위의 끄기 확인 창(적힌 아침 없음)"


func _menu_counter() -> String:
	var day := _counter_day()
	PauseMenu.open_for_day(_node, day, func() -> void: pass)
	return "카운터의 Esc: 제목 잠깐"


## 연습 결투, 첫 상대(바르톨로 원본)의 이어 베기 예비 동작 중에 멈췄다가 계속해 돌아오기 대기에 든 순간.
## 예비 동작에 놓는 걸음은 pattern_shots.gd의 _pose와 같은 꼴이고, 첫 칸 막기는 뺀다(계속하면 막기가 풀린다).
func _pause_hold() -> String:
	var opponent := Select.load_trials()[0]
	var base: AttackData = null
	for atk in opponent.attacks:
		if not atk.chain.is_empty() and not atk.dive:
			base = atk
			break
	var solo := base.duplicate() as AttackData
	var no_variants: Array[Resource] = []
	solo.variants = no_variants
	var weapon := (load(WEAPON_PATH) as WeaponData).duplicate() as WeaponData
	weapon.close_bind_time = 0.0
	_node = (load(Session.DUEL_PATH) as PackedScene).instantiate()
	_node.set_meta("wear_screen", true)
	_node.set("practice_opponent", opponent.drill(solo))
	_node.set("test_weapon", weapon)
	_node.set("mouse_aim_enabled", false)
	_node.set("rng_seed", 1)
	add_child(_node)
	_node.set_process(false)
	_node.set_physics_process(false)
	var core: DuelCore = _node.get("core")
	core.distance = DT.Distance.ENGAGE
	core.brain.state_end = core.time
	var guard := 0
	while guard < 1200 and core.brain.state != DT.OpponentState.TELL:
		core.tick(DELTA)
		guard += 1
	if core.brain.state != DT.OpponentState.TELL:
		return "예비 동작이 오지 않음"
	var until := core.brain.state_start + HOLD_PROGRESS * (core.brain.state_end - core.brain.state_start)
	while core.time < until and core.brain.state == DT.OpponentState.TELL:
		core.tick(DELTA)
	_node.set("_display_time", core.time)
	_node.call("_update_views", 0.0)
	_node.call("pause", &"shots")
	_node.call("resume")
	return "%s · 이어 베기 예비 동작 중 멈춤 뒤 계속: 돌아오기 대기(물리 걸음이 꺼져 끝나지 않는다)" % solo.attack_name


## 법정 대리(계획 046): 5일차 카운터의 첫 손님. 사연 문단 둘 · 조건 글 · "상대:" 줄이 말풍선 안에 서는지(결투 씬이 없어 tick이 없다).
func _counter_court() -> String:
	var commissions: Array[Commission] = [load(COURT_PATH), load(NOBLE_PATH), load(POOR_PATH)]
	var day := _new_day(commissions)
	day.day_number = 5
	_screen(Session.COUNTER_PATH, day)
	return "카운터: 5일차 법정 대리(체칠리아, 색 도형)"


## 귀족의 궂은일(계획 046): 소문 줄 · 흥정 줄 · "상대:" 줄이 말풍선 안에 서는지.
func _counter_noble() -> String:
	var commissions: Array[Commission] = [load(NOBLE_PATH), load(COURT_PATH), load(POOR_PATH)]
	var day := _new_day(commissions)
	day.day_number = 5
	_screen(Session.COUNTER_PATH, day)
	return "카운터: 5일차 귀족의 궂은일(레안드로, 색 도형)"
