extends Node
## 오토로드 GameSession. 씬 사이에 넘길 것을 보관하고, 하루 플레이의 씬 전환을 맡는다.

const DAY_PATH := "res://data/days/day_01.tres"
const ECONOMY_PATH := "res://data/economy_rules.tres"
const CATALOG_PATH := "res://data/upgrade_catalog.tres"
const SCHEDULE_PATH := "res://data/day_schedule.tres"
const REPUTATION_PATH := "res://data/reputation_rules.tres"
const TITLE_PATH := "res://scenes/ui/title.tscn"
const SELECT_PATH := "res://scenes/ui/commission_select.tscn"
# 씬 경로는 문자열로 둔다(preload하면 아직 없는 씬 때문에 이 스크립트가 로드되지 않는다).
const COUNTER_PATH := "res://scenes/counter/counter.tscn"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const SETTLEMENT_PATH := "res://scenes/settlement/settlement.tscn"
const CLOSING_PATH := "res://scenes/settlement/closing.tscn"

## 연습(의뢰 선택 화면)에서 고른 의뢰. 없으면 결투 씬은 자유 결투가 된다.
var commission: Commission
## 하루 플레이의 상태. 연습 중이거나 처음 화면이면 null이다.
var day: DayState


## 하루 단계에 해당하는 씬의 경로.
static func scene_for_phase(phase: int) -> String:
	match phase:
		DayState.Phase.COUNTER:
			return COUNTER_PATH
		DayState.Phase.DUEL:
			return DUEL_PATH
		DayState.Phase.SETTLEMENT:
			return SETTLEMENT_PATH
		DayState.Phase.CLOSING:
			return CLOSING_PATH
	return TITLE_PATH


## 하루 플레이를 새로 시작한다(1일차, 시작 소지금, 시작 평판, 가진 업그레이드 없음).
func start_day_play() -> void:
	commission = null
	# 날마다의 손님은 일정이 준다. day_01은 일정이 그날의 하루를 주지 못할 때의 대체값이다.
	day = DayState.new(load(ECONOMY_PATH) as EconomyRules, load(DAY_PATH) as DayData,
		load(CATALOG_PATH) as UpgradeCatalog, load(SCHEDULE_PATH) as DaySchedule,
		load(REPUTATION_PATH) as ReputationRules)


## 하루 플레이를 버린다.
func end_day_play() -> void:
	day = null


## 지금 단계의 씬으로 간다. 하루 플레이 중이 아니면 처음 화면으로 간다.
## 씬의 _ready 안에서는 직접 부르지 말고 call_deferred로 부른다(트리 뿌리가 자식을 준비시키는 중이다).
func go_to_phase_scene() -> void:
	var path := TITLE_PATH if day == null else scene_for_phase(day.phase)
	get_tree().change_scene_to_file(path)


func go_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_PATH)


func go_to_practice() -> void:
	end_day_play()
	get_tree().change_scene_to_file(SELECT_PATH)
