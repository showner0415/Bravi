extends RefCounted
## T117~T119: 연습 화면(계획 040b). 목록·고르기·사연·막는 법, 12명·30개의 넘침, 키보드와 포커스.
## 시험 데이터는 메모리에서 만든다(결정 602·606). 수는 load_trials()·load_tree()에서 얻고 적지 않는다.
## 끝과 이른 return 길에서 static 다섯(_opening_day 1, _part_effects 거짓, _style_tier 0, _picked_* 0)을 되돌린다(_finish).

const SelectScript := preload("res://scripts/commission/commission_select.gd")
const Session := preload("res://scripts/game_session.gd")

const BARTOLO_PATH := "res://data/opponents/opponent_01.tres"
const BRUNO_PATH := "res://data/opponents/opponent_02.tres"
const LORENZO_PATH := "res://data/opponents/opponent_03.tres"
const FIRST_BLOOD_PATH := "res://data/commissions/first_blood.tres"
const LEGS_ONLY_PATH := "res://data/commissions/variants/legs_only.tres"
const USURER_PATH := "res://data/commissions/variants/first_blood_usurer.tres"
const COMMISSION_DIR := "res://data/commissions"

var _tree: SceneTree
var _live: Array[Node] = []


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T117", "name": "연습 화면: 목록·고르기·쪽·남는 값·사연과 막는 법이 잘리지 않는다", "fn": t117_lists_and_help},
		{"id": "T118", "name": "연습 화면의 넘침: 상대 12명·의뢰 30개·긴 글에서도 1280x720 안", "fn": t118_overflow},
		{"id": "T119", "name": "연습 화면의 키보드: 처음 포커스·포커스가 사라지지 않는 길·포커스 테두리·Esc", "fn": t119_keyboard_focus},
	]


func cleanup() -> void:
	_free_live()
	_tree = null


# ================================================================ 시험 데이터 (ui_shots.gd도 쓴다)

## 이어 치기(사슬)와 높이를 가진 주인 없는 공격 하나.
static func test_spare() -> Array[AttackData]:
	var tail := AttackData.new()
	tail.attack_name = "시험 뒤 타격"
	tail.direction = DuelTypes.Direction.LEFT
	var tail_heights: Array[int] = [DuelTypes.Height.MID]
	tail.heights = tail_heights
	var head := AttackData.new()
	head.attack_name = "시험 겹베기"
	head.direction = DuelTypes.Direction.RIGHT
	head.signature = true
	var head_heights: Array[int] = [DuelTypes.Height.HIGH]
	head.heights = head_heights
	var chain: Array[Resource] = [tail]
	head.chain = chain
	var out: Array[AttackData] = [head]
	return out


static func _n_attacks(proto: AttackData, count: int, name_len_base: String) -> Array[AttackData]:
	var out: Array[AttackData] = []
	for k in count:
		var atk := proto.duplicate() as AttackData
		atk.attack_name = "%s%02d" % [name_len_base, k]
		atk.signature = true
		out.append(atk)
	return out


## 주인 없는 공격 여섯.
static func big_spare() -> Array[AttackData]:
	return _n_attacks(test_spare()[0], 6, "가나다라마바사아")


## 상대 12: 이름 12자, 고유 검술 이름 12자, 고유 공격 6(이름 10자), 단 9.
static func big_trials() -> Array[OpponentData]:
	var base := load(BARTOLO_PATH) as OpponentData
	var out: Array[OpponentData] = []
	for i in 12:
		var opp := base.duplicate() as OpponentData
		opp.display_name = "가나다라마바사아자차%02d" % i
		opp.style_name = "라마바사아자차카타파%02d" % i
		opp.attacks = _n_attacks(base.attacks[0], 6, "가나다라마바사아")
		var tiers: Array[StyleTier] = []
		for t in 8:
			var tier := StyleTier.new()
			tier.from_day = 2 + t
			tier.attacks = _n_attacks(base.attacks[0], 6, "가나다라마바사아")
			tiers.append(tier)
		opp.tiers = tiers
		out.append(opp)
	return out


## 의뢰 30: 의뢰인 이름 20자, 사연 600자, 조건 4. 0·1은 이름이 같고 상대가 다르며, 2·3은 이름도 상대도 같다.
static func big_commissions(trials: Array[OpponentData]) -> Array[Commission]:
	var base := load(FIRST_BLOOD_PATH) as Commission
	var out: Array[Commission] = []
	for i in 30:
		var commission := base.duplicate() as Commission
		var key := i
		var holder: OpponentData = trials[i % trials.size()]
		if i == 1:
			key = 0
		elif i == 3:
			key = 2
			holder = trials[2]
		commission.client_name = "가나다라마바사아자차카타파하거너더러%02d" % key
		commission.dialogue = "가나다라마 ".repeat(100)
		commission.opponent = holder
		var conditions: Array[CommissionCondition] = []
		for c in 4:
			conditions.append(TargetPartCondition.new())
		commission.conditions = conditions
		out.append(commission)
	return out


func _trio() -> Array[OpponentData]:
	var out: Array[OpponentData] = [load(BARTOLO_PATH) as OpponentData, load(BRUNO_PATH) as OpponentData, load(LORENZO_PATH) as OpponentData]
	return out


func _comm_trio() -> Array[Commission]:
	var out: Array[Commission] = [load(FIRST_BLOOD_PATH) as Commission, load(LEGS_ONLY_PATH) as Commission, load(USURER_PATH) as Commission]
	return out


func _seven_trials() -> Array[OpponentData]:
	var one := load(BARTOLO_PATH) as OpponentData
	var out: Array[OpponentData] = []
	for i in 7:
		out.append(one)
	return out


func _seven_commissions() -> Array[Commission]:
	var one := load(FIRST_BLOOD_PATH) as Commission
	var out: Array[Commission] = []
	for i in 7:
		out.append(one)
	return out


# ================================================================ 도우미

func _reset() -> void:
	SelectScript._opening_day = 1
	SelectScript._part_effects = false
	SelectScript._style_tier = 0
	SelectScript._picked_opponent = 0
	SelectScript._picked_commission = 0


func _free_live() -> void:
	for node in _live:
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_live.clear()


func _finish(errs: Array[String]) -> String:
	_free_live()
	_reset()
	return "OK" if errs.is_empty() else ", ".join(errs)


func _open(trials: Array[OpponentData], spare: Array[AttackData], commissions: Array[Commission]) -> Node:
	var select: Node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	select.set("trial_source", trials)
	select.set("spare_source", spare)
	select.set("commission_source", commissions)
	select.set("use_sources", true)
	_tree.root.add_child(select)
	_live.append(select)
	return select


func _open_real() -> Node:
	var select: Node = (load(Session.SELECT_PATH) as PackedScene).instantiate()
	_tree.root.add_child(select)
	_live.append(select)
	return select


func _close(select: Node) -> void:
	_live.erase(select)
	if select.get_parent() != null:
		select.get_parent().remove_child(select)
	select.free()


func _find(select: Node, node_name: String) -> Node:
	return select.find_child(node_name, true, false)


func _rows(select: Node, pattern: String) -> Array[Node]:
	return select.find_children(pattern, "Button", true, false)


func _text_of(select: Node, node_name: String) -> String:
	var node := _find(select, node_name)
	if node is Label:
		return (node as Label).text
	return ""


func _same_list(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true


## 버튼의 pressed에 묶인 첫 인자(상대나 의뢰).
func _bound_arg(button: Button) -> Variant:
	for connection in button.pressed.get_connections():
		var args: Array = (connection["callable"] as Callable).get_bound_arguments()
		if not args.is_empty() and (args[0] is OpponentData or args[0] is Commission):
			return args[0]
	return null


## 오른쪽 기둥의 차례: 같은 부모 안에서 [TrialHead, TrialGrid, PatternHelp, CommissionCard], 저마다 하나(결정 600).
func _check_order(select: Node, errs: Array[String], label: String) -> void:
	var want: Array[String] = ["TrialHead", "TrialGrid", "PatternHelp", "CommissionCard"]
	var parent: Node = null
	for i in want.size():
		var found := select.find_children(want[i], "", true, false)
		if found.size() != 1:
			errs.append("%s: %s가 %d개" % [label, want[i], found.size()])
			return
		var node: Node = found[0]
		if parent == null:
			parent = node.get_parent()
		elif node.get_parent() != parent:
			errs.append("%s: %s의 부모가 다르다" % [label, want[i]])
			return
		if node.get_index() != i:
			errs.append("%s: %s의 차례가 %d (기대 %d)" % [label, want[i], node.get_index(), i])


func _help_has(text: String, line: String) -> bool:
	return text.contains(line.trim_prefix(" · "))


func _min_size(select: Node) -> Vector2:
	return (_find(select, "ScreenMargin") as Control).get_combined_minimum_size()


# ================================================================ T117

func t117_lists_and_help() -> String:
	var errs: Array[String] = []
	_reset()
	_t117(errs)
	return _finish(errs)


func _t117(errs: Array[String]) -> void:
	var trios := _trio()
	var comms := _comm_trio()
	var spare_test := test_spare()
	var no_spare: Array[AttackData] = []
	var no_trials: Array[OpponentData] = []
	var no_comms: Array[Commission] = []

	# (가) 폴더의 데이터: 줄이 load_trials()·load_tree의 차례다.
	var real_trials := SelectScript.load_trials()
	var real_spare := SelectScript.load_spare_attacks()
	var real_all: Array[Commission] = CommissionLibrary.load_tree(COMMISSION_DIR)
	var top: Array[Commission] = CommissionLibrary.load_all(COMMISSION_DIR)
	for i in top.size():
		if i >= real_all.size() or real_all[i] != top[i]:
			errs.append("[가] load_tree의 %d번째가 load_all의 것이 아니다" % i)
	var real := _open_real()
	var entries := 0
	if not real_trials.is_empty():
		entries = real_trials.size() + (1 if not real_spare.is_empty() else 0)
	real.call("pick_opponent", 9999)
	if entries > 0 and int(real.get("_picked_opponent")) != entries - 1:
		errs.append("[가] 상대 줄의 수 %d (기대 %d)" % [int(real.get("_picked_opponent")) + 1, entries])
	for i in real_trials.size():
		real.call("pick_opponent", i)
		var row := _find(real, "OpponentPick%d" % i) as Button
		if row == null or not row.button_pressed or not row.text.begins_with(real_trials[i].display_name):
			errs.append("[가] OpponentPick%d가 %s의 눌린 줄이 아니다" % [i, real_trials[i].display_name])
	for i in real_all.size():
		real.call("pick_commission", i)
		var row := _find(real, "CommissionPick%d" % i) as Button
		if row == null or not row.button_pressed:
			errs.append("[가] CommissionPick%d가 눌린 줄이 아니다" % i)
	_close(real)

	# (나) 데이터만 더하면 줄이 는다.
	var two_trials: Array[OpponentData] = [trios[0], trios[1]]
	var two_comms: Array[Commission] = [comms[0], comms[1]]
	var a := _open(two_trials, no_spare, two_comms)
	var a_op := _rows(a, "OpponentPick*").size()
	var a_co := _rows(a, "CommissionPick*").size()
	var a_text0 := (_find(a, "OpponentPick0") as Button).text
	var a_text1 := (_find(a, "CommissionPick1") as Button).text
	_close(a)
	var b := _open(trios, no_spare, comms)
	if _rows(b, "OpponentPick*").size() != a_op + 1 or _rows(b, "CommissionPick*").size() != a_co + 1:
		errs.append("[나] 상대·의뢰를 하나씩 더하면 줄이 하나씩 늘어야 한다 (%d·%d → %d·%d)" % [
			a_op, a_co, _rows(b, "OpponentPick*").size(), _rows(b, "CommissionPick*").size()])
	if (_find(b, "OpponentPick0") as Button).text != a_text0 or (_find(b, "CommissionPick1") as Button).text != a_text1:
		errs.append("[나] 줄을 더하면 앞의 줄의 글이 바뀌었다")
	if _find(b, "OpponentPick3") != null:
		errs.append("[나] 주인 없는 공격이 없는데 넷째 상대 줄이 있다")
	_close(b)
	var c := _open(trios, spare_test, comms)
	var spare_row := _find(c, "OpponentPick%d" % trios.size()) as Button
	if spare_row == null or spare_row.text != SelectScript.SPARE_TEXT:
		errs.append("[나] 주인 없는 공격이 있는데 끝에 '주인 없는 검술' 줄이 없다")
	_close(c)
	var d := _open(no_trials, spare_test, no_comms)
	if _rows(d, "OpponentPick*").size() != 0 or _find(d, "TrialGrid") != null:
		errs.append("[나] 상대가 0명인데 공격이 있다고 상대 줄이나 칸이 섰다")
	if _rows(d, "CommissionPick*").size() != 0 or _find(d, "CommissionStart") != null:
		errs.append("[나] 의뢰가 0개인데 의뢰 줄이나 시작 버튼이 있다")
	_close(d)

	# (다) 고르기.
	var s := _open(trios, spare_test, comms)
	for n in trios.size() + 1:
		s.call("pick_opponent", n)
		_check_order(s, errs, "[다] 상대 %d" % n)
		for row in _rows(s, "OpponentPick*"):
			if (row as Button).button_pressed != (int(row.get_meta("index")) == n):
				errs.append("[다] 상대 %d를 골랐는데 %s의 눌림이 틀리다" % [n, row.name])
		for row in _rows(s, "CommissionPick*"):
			var marked := (row as Button).has_theme_color_override("font_color")
			var want := n < trios.size() and comms[int(row.get_meta("index"))].opponent == trios[n]
			if marked != want:
				errs.append("[다] 상대 %d: %s의 표시가 %s (기대 %s)" % [n, row.name, str(marked), str(want)])
		if n < trios.size():
			var free_button := _find(s, "TrialDuel0") as Button
			if free_button == null or _bound_arg(free_button) != trios[n]:
				errs.append("[다] 상대 %d의 TrialDuel0가 그 상대를 묶고 있지 않다" % n)
			var pick := _find(s, "StyleTierPick") as OptionButton
			if pick == null:
				errs.append("[다] 상대 %d에 StyleTierPick이 없다" % n)
			else:
				pick.item_selected.emit(1)
				_check_order(s, errs, "[다] 상대 %d의 단 고르기" % n)
				var tiered := _find(s, "TrialDuel0") as Button
				var bound: OpponentData = null
				if tiered != null:
					bound = _bound_arg(tiered) as OpponentData
				if bound == null or not _same_list(bound.attacks, trios[n].tiers[0].attacks):
					errs.append("[다] 상대 %d의 2단에서 TrialDuel0의 상대가 그 단이 아니다" % n)
				pick.item_selected.emit(0)
		else:
			if _find(s, "SpareCaption") == null or _find(s, "SpareDrill0") == null or _find(s, "TrialDuel0") != null:
				errs.append("[다] 주인 없는 검술의 줄을 골랐는데 칸이 그 꼴이 아니다")
	for n in comms.size():
		s.call("pick_commission", n)
		_check_order(s, errs, "[다] 의뢰 %d" % n)
		var card := _find(s, "CommissionCard")
		var client_want := "%s · 상대: %s" % [comms[n].client_name, comms[n].opponent.display_name]
		var has_client := false
		for label in card.find_children("*", "Label", true, false):
			has_client = has_client or (label as Label).text == client_want
		if not has_client:
			errs.append("[다] 의뢰 %d의 카드에 '%s'가 없다" % [n, client_want])
		if _text_of(s, "CommissionCondition") != "\n".join(comms[n].describe()):
			errs.append("[다] 의뢰 %d의 카드의 조건 글이 그 의뢰의 것이 아니다" % n)
		var start := _find(s, "CommissionStart") as Button
		if start == null or _bound_arg(start) != comms[n]:
			errs.append("[다] 의뢰 %d의 시작 버튼이 그 의뢰를 넘기지 않는다" % n)
	_close(s)

	# (라) 쪽.
	var seven := _open(_seven_trials(), no_spare, _seven_commissions())
	for prefix in ["Opponent", "Commission"]:
		var pick_call: String = "pick_opponent" if prefix == "Opponent" else "pick_commission"
		seven.call(pick_call, 5)
		if _text_of(seven, prefix + "Page") != "2/2" or _find(seven, "%sPick5" % prefix) == null or _find(seven, "%sPick0" % prefix) != null:
			errs.append("[라] %s: 여섯째를 골랐는데 둘째 쪽이 아니다 (쪽 글 %s)" % [prefix, _text_of(seven, prefix + "Page")])
		var prev := _find(seven, prefix + "Prev") as Button
		var next := _find(seven, prefix + "Next") as Button
		if not next.disabled or prev.disabled:
			errs.append("[라] %s: 끝 쪽에서 다음이 꺼지고 이전이 켜져 있어야 한다" % prefix)
		prev.pressed.emit()
		if _text_of(seven, prefix + "Page") != "1/2" or _find(seven, "%sPick0" % prefix) == null or _find(seven, "%sPick5" % prefix) != null:
			errs.append("[라] %s: 이전을 눌렀는데 첫 쪽이 아니다" % prefix)
		var kept := int(seven.get("_picked_opponent" if prefix == "Opponent" else "_picked_commission"))
		if kept != 5:
			errs.append("[라] %s: 쪽을 넘겼더니 고른 번호가 %d로 바뀌었다 (기대 5)" % [prefix, kept])
	_close(seven)
	var single := _open(trios, no_spare, comms)
	for prefix in ["Opponent", "Commission"]:
		var prev := _find(single, prefix + "Prev") as Button
		var next := _find(single, prefix + "Next") as Button
		if not prev.disabled or not next.disabled or _text_of(single, prefix + "Page") != "1/1":
			errs.append("[라] %s: 한 쪽뿐인데 쪽 넘김이 꺼져 있지 않다" % prefix)
	_close(single)

	# (마) 화면을 지우고 새로 띄워도 남는다. 번호가 넘치면 마지막으로 잘린다.
	var first := _open(trios, spare_test, comms)
	first.call("pick_opponent", 1)
	(_find(first, "StyleTierPick") as OptionButton).item_selected.emit(1)
	(_find(first, "OpeningDay2") as Button).pressed.emit()
	(_find(first, "PartCounterToggle") as Button).button_pressed = true
	first.call("pick_commission", 2)
	_close(first)
	var second := _open(trios, spare_test, comms)
	var again_pick := _find(second, "StyleTierPick") as OptionButton
	if not (_find(second, "OpponentPick1") as Button).button_pressed or not (_find(second, "CommissionPick2") as Button).button_pressed \
			or again_pick == null or again_pick.selected != 1 or not (_find(second, "OpeningDay2") as Button).button_pressed \
			or not (_find(second, "PartCounterToggle") as Button).button_pressed:
		errs.append("[마] 새로 띄운 화면이 고른 상대·의뢰·단·빈틈의 날·반격 실험을 잃었다")
	_close(second)
	SelectScript._picked_opponent = 99
	SelectScript._picked_commission = 99
	var clamp_screen := _open(trios, spare_test, comms)
	if int(clamp_screen.get("_picked_opponent")) != trios.size() or int(clamp_screen.get("_picked_commission")) != comms.size() - 1:
		errs.append("[마] 넘치는 번호가 마지막으로 잘리지 않았다 (%d·%d)" % [int(clamp_screen.get("_picked_opponent")), int(clamp_screen.get("_picked_commission"))])
	_close(clamp_screen)
	SelectScript._picked_opponent = 1
	SelectScript._style_tier = 99
	var tier_screen := _open(trios, spare_test, comms)
	var tier_pick := _find(tier_screen, "StyleTierPick") as OptionButton
	if tier_pick == null or tier_pick.selected != tier_pick.item_count - 1:
		errs.append("[마] 넘치는 단이 그 상대의 마지막 단으로 보이지 않는다")
	_close(tier_screen)
	_reset()

	# (바) 실제 데이터는 잘리지 않는다.
	var shown := _open_real()
	var story_color: Color = shown.get_theme_color(&"font_color", &"Label")
	for i in real_all.size():
		var commission := real_all[i]
		if SelectScript.story_lines(commission) > SelectScript.STORY_LINES:
			errs.append("[바] %s의 사연이 %d줄 (한도 %d)" % [commission.client_name, SelectScript.story_lines(commission), SelectScript.STORY_LINES])
		if SelectScript.condition_lines(commission) > SelectScript.COND_LINES:
			errs.append("[바] %s의 조건 글이 %d줄 (한도 %d)" % [commission.client_name, SelectScript.condition_lines(commission), SelectScript.COND_LINES])
		shown.call("pick_commission", i)
		var story := _find(shown, "CommissionStory") as RichTextLabel
		if story == null:
			errs.append("[바] 의뢰 %d에 CommissionStory가 없다" % i)
			continue
		if story.text != commission.dialogue:
			errs.append("[바] 의뢰 %d의 사연 칸의 글이 dialogue와 다르다" % i)
		if i == 0:
			if not story.get_theme_color(&"default_color").is_equal_approx(story_color):
				errs.append("[바] 사연 칸의 글자색이 Label의 글자색이 아니다")
			if story.get_theme_font_size(&"normal_font_size") != SelectScript.STORY_FONT:
				errs.append("[바] 사연 칸의 글자 크기가 %d (기대 %d)" % [story.get_theme_font_size(&"normal_font_size"), SelectScript.STORY_FONT])
			if story.bbcode_enabled or story.fit_content:
				errs.append("[바] 사연 칸의 bbcode_enabled·fit_content가 꺼져 있지 않다")
	_close(shown)
	for opponent in real_trials:
		for t in opponent.tier_count():
			var tiered := opponent.at_tier(t)
			var lines := SelectScript.help_lines(SelectScript.help_text(tiered, tiered.attacks))
			if lines > SelectScript.HELP_LINES:
				errs.append("[바] %s %d단의 막는 법이 %d줄 (한도 %d)" % [opponent.display_name, t + 1, lines, SelectScript.HELP_LINES])
	if SelectScript.help_lines(SelectScript.help_text(trios[0], spare_test)) > SelectScript.HELP_LINES:
		errs.append("[바] 주인 없는 검술의 막는 법이 %d줄을 넘는다" % SelectScript.HELP_LINES)

	# (사) 막는 법의 줄이 그 상대(그 단)의 공격에 맞다.
	var help_screen := _open(trios, spare_test, comms)
	_check_help(help_screen, errs, "바르톨로 1단", 0, true, false, false)
	_check_help(help_screen, errs, "브루노 1단", 1, false, true, false)
	_check_help(help_screen, errs, "로렌초 1단", 2, false, false, true)
	help_screen.call("pick_opponent", 1)
	(_find(help_screen, "StyleTierPick") as OptionButton).item_selected.emit(2)
	_check_help(help_screen, errs, "브루노 3단", 1, true, null, null)
	_close(help_screen)
	var spare_screen := _open(trios, spare_test, comms)
	_check_help(spare_screen, errs, "주인 없는 검술", trios.size(), true, false, false)
	_close(spare_screen)


## 막는 법의 글: 이어 베기·휩쓸기·뛰어들기의 줄이 있는가(null이면 보지 않는다). 높이의 줄은 늘 있다.
func _check_help(select: Node, errs: Array[String], label: String, index: int, chain: Variant, sweep: Variant, dive: Variant) -> void:
	select.call("pick_opponent", index)
	var text := _text_of(select, "PatternHelp")
	var cases: Array = [["이어 베기", DuelHud.HELP_CHAIN, chain], ["휩쓸기", DuelHud.HELP_SWEEP, sweep], ["뛰어들기", DuelHud.HELP_DIVE, dive]]
	for item: Array in cases:
		if item[2] == null:
			continue
		if _help_has(text, item[1]) != bool(item[2]):
			errs.append("[사] %s의 막는 법에 %s 줄이 %s (기대 %s)" % [label, item[0], "있다" if not bool(item[2]) else "없다", "있음" if bool(item[2]) else "없음"])
	if not _help_has(text, DuelHud.HELP_HEIGHT):
		errs.append("[사] %s의 막는 법에 높이의 줄이 없다" % label)


# ================================================================ T118

func t118_overflow() -> String:
	var errs: Array[String] = []
	_reset()
	_t118(errs)
	return _finish(errs)


func _within(size: Vector2, errs: Array[String], label: String) -> void:
	if size.x <= 0.0 or size.y <= 0.0 or size.x > 1280.0 or size.y > 720.0:
		errs.append("%s: ScreenMargin의 최소 크기 %dx%d (0보다 크고 1280x720 이하여야 함)" % [label, int(size.x), int(size.y)])


func _same_size(size: Vector2, base: Vector2, errs: Array[String], label: String) -> void:
	if absf(size.x - base.x) > 1.0 or absf(size.y - base.y) > 1.0:
		errs.append("%s: 최소 크기 %dx%d가 폴더의 데이터의 것 %dx%d와 다르다" % [label, int(size.x), int(size.y), int(base.x), int(base.y)])


func _grid_checks(select: Node, errs: Array[String], label: String) -> void:
	var grid := _find(select, "TrialGrid") as Control
	if grid == null:
		errs.append("%s: TrialGrid가 없다" % label)
		return
	var count := grid.get_child_count()
	if _rows(select, "PatternDrill*").size() > SelectScript.DRILL_MAX or _rows(select, "SpareDrill*").size() > SelectScript.DRILL_MAX:
		errs.append("%s: 패턴 버튼이 %d개 (한도 %d)" % [label, count, SelectScript.DRILL_MAX])
	if ceili(float(count) / SelectScript.DRILL_COLUMNS) > 2:
		errs.append("%s: 버튼 %d개가 %d줄이다 (한도 2줄)" % [label, count, ceili(float(count) / SelectScript.DRILL_COLUMNS)])
	var width := -1.0
	for child in grid.get_children():
		var button := child as Button
		var min_width := button.get_combined_minimum_size().x
		if width < 0.0:
			width = min_width
		elif absf(min_width - width) > 0.5:
			errs.append("%s: 버튼의 최소 폭이 같지 않다 (%d·%d)" % [label, int(width), int(min_width)])
			break
		if button.tooltip_text.is_empty() or button.tooltip_text != button.text:
			errs.append("%s: %s에 전체 글의 풍선말이 없다" % [label, button.name])


func _t118(errs: Array[String]) -> void:
	var real := _open_real()
	var base := _min_size(real)
	_within(base, errs, "[폴더의 데이터]")
	_close(real)

	var trials := big_trials()
	var spare := big_spare()
	var commissions := big_commissions(trials)
	var entries := trials.size() + 1
	var op_pages := ceili(float(entries) / SelectScript.LIST_ROWS)
	var co_pages := ceili(float(commissions.size()) / SelectScript.LIST_ROWS)
	var big := _open(trials, spare, commissions)
	_within(_min_size(big), errs, "[12명·30개]")
	for n in entries:
		var label := "[상대 %d]" % n
		big.call("pick_opponent", n)
		_same_size(_min_size(big), base, errs, label)
		_within(_min_size(big), errs, label)
		var rows := _rows(big, "OpponentPick*").size()
		if rows < 1 or rows > SelectScript.LIST_ROWS:
			errs.append("%s 한 쪽의 상대 줄이 %d개 (한도 %d)" % [label, rows, SelectScript.LIST_ROWS])
		var want_page := "%d/%d" % [floori(n / float(SelectScript.LIST_ROWS)) + 1, op_pages]
		if _text_of(big, "OpponentPage") != want_page:
			errs.append("%s 쪽 글이 %s (기대 %s)" % [label, _text_of(big, "OpponentPage"), want_page])
		_grid_checks(big, errs, label)
		if n < trials.size():
			var pick := _find(big, "StyleTierPick") as OptionButton
			if pick == null or pick.item_count != 9:
				errs.append("%s StyleTierPick의 항목이 %d개 (기대 9)" % [label, 0 if pick == null else pick.item_count])
			else:
				pick.item_selected.emit(pick.item_count - 1)
				_same_size(_min_size(big), base, errs, label + " 가장 높은 단")
				_within(_min_size(big), errs, label + " 가장 높은 단")
				_grid_checks(big, errs, label + " 가장 높은 단")
				pick.item_selected.emit(0)
	for n in commissions.size():
		var label := "[의뢰 %d]" % n
		big.call("pick_commission", n)
		_same_size(_min_size(big), base, errs, label)
		_within(_min_size(big), errs, label)
		var rows := _rows(big, "CommissionPick*").size()
		if rows < 1 or rows > SelectScript.LIST_ROWS:
			errs.append("%s 한 쪽의 의뢰 줄이 %d개 (한도 %d)" % [label, rows, SelectScript.LIST_ROWS])
		var want_page := "%d/%d" % [floori(n / float(SelectScript.LIST_ROWS)) + 1, co_pages]
		if _text_of(big, "CommissionPage") != want_page:
			errs.append("%s 쪽 글이 %s (기대 %s)" % [label, _text_of(big, "CommissionPage"), want_page])
	# 의뢰인 이름이 같은 줄들의 글이 서로 다르다.
	var texts: Array = big.get("_commission_texts")
	var seen := {}
	for text: String in texts:
		if seen.has(text):
			errs.append("[이름] 줄의 글 '%s'가 겹친다" % text)
		seen[text] = true
	if texts.size() == commissions.size() and texts.size() > 3:
		if texts[0] == texts[1]:
			errs.append("[이름] 상대가 다른 두 의뢰의 줄이 같은 글이다")
		if texts[3] != "%s (2)" % texts[2]:
			errs.append("[이름] 상대까지 같은 둘째 의뢰의 줄이 ' (2)'로 갈리지 않았다 (%s)" % texts[3])
	_close(big)

	# 고유 공격이 여덟이면 버튼은 여섯뿐이다.
	var eight := (load(BARTOLO_PATH) as OpponentData).duplicate() as OpponentData
	eight.attacks = _n_attacks(eight.attacks[0], 8, "가나다라마바사아")
	var eights: Array[OpponentData] = [eight]
	var no_spare: Array[AttackData] = []
	var one: Array[Commission] = [commissions[0]]
	var eight_screen := _open(eights, no_spare, one)
	var drills := _rows(eight_screen, "PatternDrill*").size()
	if drills != SelectScript.DRILL_MAX:
		errs.append("[여덟] 고유 공격 8개인 상대의 패턴 버튼이 %d개 (기대 %d)" % [drills, SelectScript.DRILL_MAX])
	_close(eight_screen)


# ================================================================ T119

func t119_keyboard_focus() -> String:
	var errs: Array[String] = []
	_reset()
	_t119(errs)
	return _finish(errs)


func _owner_name(select: Node) -> String:
	var focused := select.get_viewport().gui_get_focus_owner()
	return "(없음)" if focused == null else String(focused.name)


func _t119(errs: Array[String]) -> void:
	var trios := _trio()
	var comms := _comm_trio()
	var spare_test := test_spare()
	var no_spare: Array[AttackData] = []

	var real := _open_real()
	var start := _find(real, "CommissionStart") as Button
	if start == null or real.get_viewport().gui_get_focus_owner() != start:
		errs.append("처음 포커스가 CommissionStart가 아니다 (%s)" % _owner_name(real))
	for node in real.find_children("*", "Control", true, false):
		var control := node as Control
		var needs := (control is Button and not (control as Button).disabled) or control is RichTextLabel
		if needs and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_ALL:
			errs.append("%s의 focus_mode가 전부가 아니다" % control.name)
	for row_name in ["OpponentPick0", "CommissionPick0"]:
		var row := _find(real, row_name) as Button
		if row == null:
			continue
		row.grab_focus()
		row.pressed.emit()
		if not is_instance_valid(row) or real.get_viewport().gui_get_focus_owner() != row:
			errs.append("%s에 포커스를 주고 눌렀더니 포커스가 그 줄에 없다 (%s)" % [row_name, _owner_name(real)])
	if start != null:
		var box := start.get_theme_stylebox(&"focus")
		if box == null or box is StyleBoxEmpty or not (box is StyleBoxFlat) or (box as StyleBoxFlat).draw_center:
			errs.append("버튼의 focus 판이 가운데를 칠하지 않는 테두리가 아니다 (결정 605)")
	var story := _find(real, "CommissionStory") as RichTextLabel
	if story != null:
		var story_box := story.get_theme_stylebox(&"focus")
		if not (story_box is StyleBoxFlat) or (story_box as StyleBoxFlat).draw_center:
			errs.append("사연 칸의 focus 판이 가운데를 칠하지 않는 테두리가 아니다")
	# Esc: 다른 씬 아래에 붙은 화면은 아무 데도 가지 않는다("간다"는 스모크 select_esc의 몫).
	var before := _tree.current_scene
	var back := InputEventAction.new()
	back.action = &"back"
	back.pressed = true
	real.call("_unhandled_input", back)
	if _tree.current_scene != before or not real.is_inside_tree():
		errs.append("Esc가 다른 씬 아래에 붙은 화면을 옮겼다")
	_close(real)

	# 쪽 넘김의 포커스.
	var seven := _open(_seven_trials(), no_spare, _seven_commissions())
	for prefix in ["Opponent", "Commission"]:
		var next := _find(seven, prefix + "Next") as Button
		next.grab_focus()
		next.pressed.emit()
		if _owner_name(seven) != prefix + "Prev":
			errs.append("%s: 끝 쪽으로 넘긴 뒤 포커스가 이전 버튼에 없다 (%s)" % [prefix, _owner_name(seven)])
		(_find(seven, prefix + "Prev") as Button).pressed.emit()
		if _owner_name(seven) != prefix + "Next":
			errs.append("%s: 첫 쪽으로 돌아온 뒤 포커스가 다음 버튼에 없다 (%s)" % [prefix, _owner_name(seven)])
	# 포커스의 주인이 null인 걸음이 없다.
	var row0 := _find(seven, "OpponentPick0") as Button
	row0.grab_focus()
	seven.call("pick_opponent", 6)
	if _owner_name(seven) != "OpponentPick6":
		errs.append("포커스를 가진 줄이 쪽 넘김으로 지워졌는데 새 줄이 잡지 않았다 (%s)" % _owner_name(seven))
	seven.get_viewport().gui_release_focus()
	seven.call("pick_opponent", 6)
	if _owner_name(seven) != "OpponentPick6":
		errs.append("포커스 없이 같은 쪽의 줄을 골랐는데 그 줄이 잡지 않았다 (%s)" % _owner_name(seven))
	seven.get_viewport().gui_release_focus()
	seven.call("pick_commission", 1)
	if _owner_name(seven) != "CommissionPick1":
		errs.append("포커스 없이 의뢰를 골랐는데 그 줄이 잡지 않았다 (%s)" % _owner_name(seven))
	_close(seven)

	# 단 고르기는 픽을 지우지 않는다.
	var tier_screen := _open(trios, spare_test, comms)
	tier_screen.call("pick_opponent", 1)
	var pick := _find(tier_screen, "StyleTierPick") as OptionButton
	if pick == null:
		errs.append("StyleTierPick이 없다")
	else:
		pick.grab_focus()
		pick.item_selected.emit(1)
		if not is_instance_valid(pick) or tier_screen.get_viewport().gui_get_focus_owner() != pick or _find(tier_screen, "StyleTierPick") != pick:
			errs.append("단을 고른 뒤 같은 StyleTierPick 노드가 포커스를 갖고 있지 않다 (%s)" % _owner_name(tier_screen))
	_close(tier_screen)
