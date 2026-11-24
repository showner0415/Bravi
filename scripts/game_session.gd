extends Node
## 오토로드 GameSession. 씬 사이에 넘길 것을 보관하고, 하루 플레이의 씬 전환을 맡는다.

const DAY_PATH := "res://data/days/day_01.tres"
const ECONOMY_PATH := "res://data/economy_rules.tres"
const CATALOG_PATH := "res://data/upgrade_catalog.tres"
const SCHEDULE_PATH := "res://data/day_schedule.tres"
const REPUTATION_PATH := "res://data/reputation_rules.tres"
const TITLE_PATH := "res://scenes/ui/title.tscn"
const SELECT_PATH := "res://scenes/ui/commission_select.tscn"
# 씬 경로는 문자열로 둔다: change_scene_to_file과 테스트의 _spawn_screen이 경로로 부르고, preload하면 오토로드가 씬 넷을 미리 불러온다.
const COUNTER_PATH := "res://scenes/counter/counter.tscn"
const DUEL_PATH := "res://scenes/duel/duel.tscn"
const SETTLEMENT_PATH := "res://scenes/settlement/settlement.tscn"
const CLOSING_PATH := "res://scenes/settlement/closing.tscn"

const SaveStore := preload("res://scripts/save_store.gd")
## 저장 파일. 환경 변수 SAVE_ENV가 있으면 그 경로를 대신 쓴다(playtester가 실제 저장을 건드리지 않게).
const SAVE_PATH := "user://bravi_save.json"
const SAVE_ENV := "BRAVI_SAVE_PATH"

## 연습(의뢰 선택 화면)에서 고른 의뢰. 없으면 결투 씬은 자유 결투가 된다.
var commission: Commission
## 연습의 "자유 결투"·"패턴만"이 고른 상대(결정 377). 의뢰 없이 결투할 때만 쓴다.
var practice_opponent: OpponentData
## 하루 플레이의 상태. 연습 중이거나 처음 화면이면 null이다.
var day: DayState
## 저장 파일의 경로. 비어 있으면 저장이 꺼져 있다(읽지도 쓰지도 않는다).
## 오토로드로 트리에 오를 때 정해진다(_ready). 테스트가 new()로 만든 것은 빈 채다.
var save_path := ""
## 이 실행에서 마지막으로 적은 저장의 "다음에 열 날". 적은 적이 없거나 마지막 쓰기가 실패했으면 0.
## 폐점 화면이 읽는다.
var saved_day := 0


## 경로만 정한다. 파일은 건드리지 않는다.
func _ready() -> void:
	var custom := OS.get_environment(SAVE_ENV)
	save_path = custom if custom != "" else SAVE_PATH


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


## 새 1일차의 하루(시작 소지금, 시작 평판, 가진 업그레이드 없음).
func _new_day() -> DayState:
	# 날마다의 손님은 일정이 준다. day_01은 일정이 그날의 하루를 주지 못할 때의 대체값이다.
	return DayState.new(load(ECONOMY_PATH) as EconomyRules, load(DAY_PATH) as DayData,
		load(CATALOG_PATH) as UpgradeCatalog, load(SCHEDULE_PATH) as DaySchedule,
		load(REPUTATION_PATH) as ReputationRules)


## 하루 플레이를 새로 시작한다(1일차, 시작 소지금, 시작 평판, 가진 업그레이드 없음).
## 그 아침을 적는다(옛 저장을 덮어쓴다).
func start_day_play() -> void:
	commission = null
	practice_opponent = null
	day = _new_day()
	save_game()


## 저장을 읽어 되돌린 하루(그날의 아침). 저장이 꺼져 있거나, 파일이 읽히지 않거나, 읽을 수 없는 저장이면 null이다.
## day를 건드리지 않는다(처음 화면이 정보 한 줄에 쓴다).
func load_saved_day() -> DayState:
	var saved: Dictionary = SaveStore.read(save_path)
	if saved.is_empty():
		return null
	var restored: DayState = _new_day()
	return restored if restored.restore(saved) else null


## 저장된 아침에서 하루 플레이를 잇는다. 읽을 수 없으면 아무것도 바꾸지 않고 false다.
func continue_day_play() -> bool:
	var loaded: DayState = load_saved_day()
	if loaded == null:
		return false
	commission = null
	practice_opponent = null
	day = loaded
	return true


## 저장 파일이 있는가(읽히는지는 보지 않는다).
func save_exists() -> bool:
	return save_path != "" and SaveStore.exists(save_path)


## 다음에 열 날의 아침을 적는다. 저장이 꺼져 있거나 하루 중이면(적을 아침이 없다) 적지 않고 false다.
func save_game() -> bool:
	if save_path == "" or day == null:
		return false
	var saved: Dictionary = day.saved_state()
	if saved.is_empty():
		return false
	if not SaveStore.write(save_path, saved):
		saved_day = 0
		push_warning("저장하지 못했다: %s" % save_path)
		return false
	saved_day = int(saved["day"])
	return true


## 하루 플레이를 버린다.
func end_day_play() -> void:
	day = null


## 지금 단계의 씬으로 간다. 하루 플레이 중이 아니면 처음 화면으로 간다.
## 씬의 _ready 안에서는 직접 부르지 말고 call_deferred로 부른다(트리 뿌리가 자식을 준비시키는 중이다).
## 폐점으로 가는 길이 전부 여기를 지나므로, 폐점이면 내일의 아침을 적는다.
func go_to_phase_scene() -> void:
	if day != null and day.phase == DayState.Phase.CLOSING:
		save_game()
	var path := TITLE_PATH if day == null else scene_for_phase(day.phase)
	get_tree().change_scene_to_file(path)


func go_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_PATH)


func go_to_practice() -> void:
	end_day_play()
	get_tree().change_scene_to_file(SELECT_PATH)
