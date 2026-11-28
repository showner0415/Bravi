extends RefCounted
## T59: 의뢰인의 글 — 열여덟 의뢰의 필드(채워짐, 길이, 금지 글자), 정산의 구간이 고르는 글, 흥정의 대답.
## 하루의 도우미(고정 점수 의뢰, 화면 붙이기)는 day_tests.gd의 것을 쓴다.
## 구간과 화면은 테스트가 직접 만든 의뢰와 규칙으로 본다(.tres의 값과 상관없다). 데이터는 열여덟 .tres를 로드해 본다.

const Day := preload("res://tests/day_tests.gd")
const DT := preload("res://scripts/duel/duel_types.gd")
const Session := preload("res://scripts/game_session.gd")
const Settlement := preload("res://scripts/economy/settlement.gd")
const Counter := preload("res://scripts/commission/counter.gd")

const PATHS: Array[String] = [
	"res://data/commissions/first_blood.tres",
	"res://data/commissions/spar.tres",
	"res://data/commissions/feather_cut.tres",
	"res://data/commissions/throw_match.tres",
	"res://data/commissions/variants/first_blood_poor.tres",
	"res://data/commissions/variants/first_blood_usurer.tres",
	"res://data/commissions/variants/legs_only.tres",
	"res://data/commissions/variants/throw_bet.tres",
	"res://data/commissions/variants/court_beehive.tres",
	"res://data/commissions/variants/noble_baker.tres",
	"res://data/commissions/variants/pair_hatter.tres",
	"res://data/commissions/variants/pair_baker.tres",
	"res://data/commissions/variants/after_hatter.tres",
	"res://data/commissions/variants/after_baker.tres",
	"res://data/commissions/variants/close_baker.tres",
	"res://data/commissions/variants/rival_milliner.tres",
	"res://data/commissions/variants/dun_master.tres",
	"res://data/commissions/variants/washer_ledger.tres",
]
## 글자 수의 상한(공백과 문장부호 포함). 정산의 글은 두 줄, 흥정의 대답은 한 줄에 들어가야 한다.
const SETTLE_MAX := 56
const HAGGLE_MAX := 44
## 새 글에 쓰지 않는 것. 치료비는 T33이 정산 화면에서 찾는 낱말이고, 숫자와 퍼센트는 확률을 보이지 않기 위해서다.
const FORBIDDEN: Array[String] = ["치료비", "%", "\n", "\"", "\\", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

var _tree: SceneTree
var _d := Day.new()


func list(tree: SceneTree) -> Array:
	_tree = tree
	_d.set("_tree", tree)
	return [
		{"id": "T59", "name": "의뢰인의 글: 열여덟 의뢰의 필드, 정산의 구간, 흥정의 대답", "fn": t59_client_lines},
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


## 글 다섯을 가진 고정 점수 의뢰. 눈높이 3이라 흥정할 수 있다.
func _own(score: int) -> Commission:
	var commission: Commission = _plain(score)
	commission.success_line = "해낸 글"
	commission.fail_line = "못 해낸 글"
	commission.partial_line = "모자란 글"
	commission.haggle_agree_line = "받는 글"
	commission.haggle_refuse_line = "거절하는 글"
	return commission


## 글을 넣지 않은 고정 점수 의뢰. 눈높이 3이라 흥정할 수 있다.
func _plain(score: int) -> Commission:
	var commission: Commission = _d._fixed_commission("글", 30, 15, score)
	commission.haggle_min_stars = 3
	return commission


## 손님 하나의 새 하루.
func _one_day(commission: Commission, economy: EconomyRules, rep: ReputationRules = null) -> DayState:
	var data := DayData.new()
	var one: Array[Commission] = [commission]
	data.commissions = one
	return DayState.new(economy, data, null, null, rep)


## 흥정이 켜진 경제 규칙: 확률은 차가 0 이상이면 70, 모자라면 40. 거절의 팁 감점은 없다(성향 한 줄에 꼬리가 없다).
func _haggle_rules() -> EconomyRules:
	var economy: EconomyRules = _d._duel_rules(3)
	economy.haggle_bonus_percent = 30
	economy.haggle_chance_met = PackedInt32Array([70])
	economy.haggle_chance_short = PackedInt32Array([40])
	return economy


## 테스트가 직접 만든 평판 규칙: 시작 9(별 3).
func _rep_rules() -> ReputationRules:
	var rep := ReputationRules.new()
	rep.enabled = true
	rep.start = 9
	rep.min_value = 0
	rep.max_value = 20
	rep.star_thresholds = PackedInt32Array([4, 8, 12, 16])
	rep.guest_delta = PackedInt32Array([0, 0, 0, 0, 0])
	rep.perfect_bonus = 1
	return rep


## 그 의뢰를 그 점수로 끝낸 정산 화면의 Reaction 글.
func _reaction_text(commission: Commission) -> String:
	var day := _one_day(commission, _d._duel_rules(3))
	_d._fight(day, DT.EndReason.CONDITION)
	var settlement: Node = _d._spawn_screen(Session.SETTLEMENT_PATH, day)
	var text: String = _d._label_text(settlement, "Reaction")
	settlement.free()
	return text


## 그 의뢰의 카운터의 HaggleLine 글. roll이 0 이상이면 그 주사위로 흥정한 뒤의 글이다(별 3, 눈높이 3이라 확률 70).
func _haggle_text(commission: Commission, roll := -1) -> String:
	var day := _one_day(commission, _haggle_rules(), _rep_rules())
	if roll >= 0:
		day.haggle(roll)
	var counter: Node = _d._spawn_screen(Session.COUNTER_PATH, day)
	var text: String = _d._label_text(counter, "HaggleLine")
	counter.free()
	return text


# ================================================================ T59 의뢰인의 글

func t59_client_lines() -> String:
	var errs: Array[String] = []
	_check_data(errs)
	_check_sections(errs)
	_check_settlement(errs)
	_check_counter(errs)
	return _result(errs)


## 가. 열여덟 의뢰의 필드: 채워짐, 길이, 금지 글자, 서로 다름.
func _check_data(errs: Array[String]) -> void:
	var fails := {}
	var partials := {}
	for path in PATHS:
		var commission := load(path) as Commission
		if commission == null:
			errs.append("[가] %s 이 로드되지 않음" % path)
			continue
		var who := commission.client_name
		_expect(errs, commission.fail_line != "" and commission.partial_line != "", "[가] %s: fail_line이나 partial_line이 비어 있음" % who)
		var settle_lines: Array[String] = [commission.fail_line, commission.partial_line, commission.success_line]
		for line in settle_lines:
			_expect(errs, line.length() <= SETTLE_MAX, "[가] %s: 정산의 글이 %d자 (상한 %d): '%s'" % [who, line.length(), SETTLE_MAX, line])
		var haggle_lines: Array[String] = [commission.haggle_agree_line, commission.haggle_refuse_line]
		for line in haggle_lines:
			if commission.haggle_min_stars > 0:
				_expect(errs, line != "" and line.length() <= HAGGLE_MAX,
					"[가] %s: 흥정의 대답이 비었거나 %d자 (상한 %d): '%s'" % [who, line.length(), HAGGLE_MAX, line])
			else:
				_expect(errs, line == "", "[가] %s: 흥정할 수 없는 손님인데 흥정의 대답이 있음" % who)
		var new_lines: Array[String] = [commission.fail_line, commission.partial_line,
			commission.haggle_agree_line, commission.haggle_refuse_line]
		for line in new_lines:
			for bad in FORBIDDEN:
				_expect(errs, not line.contains(bad), "[가] %s: 새 글에 쓰지 않는 글자나 낱말이 있음: '%s'" % [who, line])
		fails[commission.fail_line] = true
		partials[commission.partial_line] = true
	_expect(errs, fails.size() == PATHS.size() and partials.size() == PATHS.size(),
		"[가] 서로 다른 fail_line %d개, partial_line %d개 (기대 %d, %d)" % [fails.size(), partials.size(), PATHS.size(), PATHS.size()])


## 나. 구간의 고르기(팁 문턱 70): 그 구간의 한마디가 있으면 그것, 비었으면 공통 문구.
func _check_sections(errs: Array[String]) -> void:
	var rows := [
		[{"score": 0, "fail_line": "가"}, "가"],
		[{"score": 0}, Settlement.REACTION_NONE],
		[{"score": 60, "partial_line": "나", "success_line": "다"}, "나"],
		[{"score": 70, "partial_line": "나"}, "나"],
		[{"score": 60, "partial_line": "", "success_line": "첫째가 고마워한다"}, Settlement.REACTION_PARTIAL],
		[{"score": 71, "success_line": "다", "fail_line": "가", "partial_line": "나"}, "다"],
		[{"score": 90, "success_line": "둘째가 고마워한다"}, "둘째가 고마워한다"],
		[{"score": 85}, Settlement.REACTION_GOOD],
		[{"score": 100}, Settlement.REACTION_PERFECT],
	]
	for i in rows.size():
		var row: Array = rows[i]
		var result: Dictionary = row[0]
		var want: String = row[1]
		var got: String = Settlement.reaction_words(result, 70)
		_expect(errs, got == want, "[나] %d번째 줄: '%s' (기대 '%s')" % [i + 1, got, want])


## 다. 정산 화면: 결과에 실린 글과 말풍선의 글.
func _check_settlement(errs: Array[String]) -> void:
	var day := _one_day(_own(0), _d._duel_rules(3))
	_d._fight(day, DT.EndReason.CONDITION)
	var result: Dictionary = day.last_result()
	_expect(errs, str(result.get("fail_line")) == "못 해낸 글" and str(result.get("partial_line")) == "모자란 글",
		"[다] 결과에 실린 글: '%s', '%s' (기대 '못 해낸 글', '모자란 글')" % [str(result.get("fail_line")), str(result.get("partial_line"))])
	var none := _reaction_text(_own(0))
	_expect(errs, none == "못 해낸 글", "[다] 0점의 Reaction '%s' (기대 '못 해낸 글')" % none)
	var partial := _reaction_text(_own(60))
	_expect(errs, partial == "모자란 글", "[다] 60점의 Reaction '%s' (기대 '모자란 글')" % partial)
	var good := _reaction_text(_own(90))
	_expect(errs, good == "해낸 글", "[다] 90점의 Reaction '%s' (기대 '해낸 글')" % good)
	var plain := _reaction_text(_plain(0))
	_expect(errs, plain == Settlement.REACTION_NONE, "[다] 글이 없는 의뢰의 0점 Reaction '%s' (기대: 공통 문구)" % plain)


## 라. 카운터의 대답: 흥정 전은 성향 한 줄 그대로, 흥정한 뒤는 의뢰인의 글(없으면 공통 문구).
func _check_counter(errs: Array[String]) -> void:
	var hint: String = Counter.HAGGLE_HINTS[2]
	var before := _haggle_text(_own(100))
	_expect(errs, before == hint, "[라] 흥정 전의 HaggleLine '%s' (기대: 성향 한 줄 그대로)" % before)
	var agreed := _haggle_text(_own(100), 0)
	_expect(errs, agreed == "받는 글", "[라] 받아 준 뒤의 HaggleLine '%s' (기대 '받는 글')" % agreed)
	var refused := _haggle_text(_own(100), 99)
	_expect(errs, refused == "거절하는 글", "[라] 거절당한 뒤의 HaggleLine '%s' (기대 '거절하는 글')" % refused)
	var plain_agreed := _haggle_text(_plain(100), 0)
	_expect(errs, plain_agreed == Counter.HAGGLE_AGREED, "[라] 글이 없는 의뢰가 받아 준 뒤의 HaggleLine '%s' (기대: 공통 문구)" % plain_agreed)
	var plain_refused := _haggle_text(_plain(100), 99)
	_expect(errs, plain_refused == Counter.HAGGLE_REFUSED, "[라] 글이 없는 의뢰가 거절한 뒤의 HaggleLine '%s' (기대: 공통 문구)" % plain_refused)
