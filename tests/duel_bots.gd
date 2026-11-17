extends RefCounted
## 테스트용 플레이어 봇.
## 입력은 절대 시각이 아니라 코어 이벤트에 반응해 넣는다:
## - 예비 동작 시작 이벤트를 받으면 막기(또는 패리 예약, 후퇴)
## - 타격 결과 이벤트를 받으면 받아치기
## - 패리는 예정 타격 시각 PARRY_LEAD초 전을 지난 첫 tick에 누른다
## 매 tick 뒤에 update()를 불러 줘야 한다.
##
## 설정(cfg) 키 — 전부 선택:
##   guard_fn(attack: AttackData, index: int) -> StringName
##       &"hold" 막기 유지 / &"parry" 패리 / &"wrong" 틀린 방향 막기 / &"none" 무방비 / &"retreat" 후퇴
##       index는 1부터 세는 상대 공격 순번. 없으면 항상 &"hold".
##   counter_fn(strike_ev: Dictionary) -> Variant
##       막힘·패리 직후 받아칠 조준 [direction, height] 또는 null. 없으면 받아치지 않는다.
##   whiff_fn(strike_ev: Dictionary) -> Variant
##       상대가 헛친 뒤 전진해서 칠 조준 [direction, height] 또는 null.
##   finisher: [direction, height] — 상대가 무너지면 칠 조준.
##   max_counters: int — 받아치기 횟수 제한(-1이면 무제한).
##   want_distance: int — 이 간격이 될 때까지 전진한다.
##   attack_at: {time, aim} — 코어 시각 time을 지난 첫 tick에 공격한다.
##   attack_before_strike: {index, lead, aim} — index번째 공격의 타격 lead초 전을 지난 첫 tick에 공격한다.

const DT := preload("res://scripts/duel/duel_types.gd")

const PARRY_LEAD := 0.10

var core: DuelCore
var cfg: Dictionary = {}

## 지금까지 본 상대 공격(예비 동작) 수.
var tells_seen := 0
var counters_done := 0

var _parry_press_at := INF
var _timed_attack_at := INF
var _timed_attack_aim: Array = []
var _pending_steps: Array[int] = []
var _pending_attack: Variant = null


func _init(p_core: DuelCore, p_cfg: Dictionary = {}) -> void:
	core = p_core
	cfg = p_cfg
	core.event.connect(_on_event)
	if cfg.has("attack_at"):
		_timed_attack_at = cfg["attack_at"]["time"]
		_timed_attack_aim = cfg["attack_at"]["aim"]


## 매 tick 뒤에 부른다.
func update() -> void:
	if core.ended:
		return
	if _parry_press_at <= core.time:
		_parry_press_at = INF
		core.set_guard(true)
	if _timed_attack_at <= core.time:
		_timed_attack_at = INF
		_attack(_timed_attack_aim)
		return

	# 이동은 READY에서만, 공격은 READY와 GUARD에서 받아들여진다.
	var ready := core.player_state == DT.PlayerState.READY
	var guarding := core.player_state == DT.PlayerState.GUARD
	if not _pending_steps.is_empty():
		if ready:
			core.step(_pending_steps.pop_front())
		return
	if _pending_attack != null:
		if ready or guarding:
			var aim: Array = _pending_attack
			_pending_attack = null
			_attack(aim)
		return
	if ready and cfg.has("want_distance") and core.distance < int(cfg["want_distance"]) \
			and not core.guard_held:
		core.step(1)


func _on_event(ev: Dictionary) -> void:
	match ev["type"]:
		DuelRecord.TELL_START:
			_on_tell(ev)
		DuelRecord.STRIKE:
			_on_strike(ev)
		DuelRecord.STAGGER_START:
			if cfg.has("finisher"):
				_pending_attack = cfg["finisher"]


func _on_tell(ev: Dictionary) -> void:
	tells_seen += 1
	var atk: AttackData = ev["attack"]
	var mode: StringName = &"hold"
	if cfg.has("guard_fn"):
		mode = cfg["guard_fn"].call(atk, tells_seen)
	match mode:
		&"hold":
			core.set_aim(atk.direction, DT.Height.MID)
			core.set_guard(true)
		&"wrong":
			core.set_aim((atk.direction + 1) % 3, DT.Height.MID)
			core.set_guard(true)
		&"parry":
			core.set_guard(false)
			core.set_aim(atk.direction, DT.Height.MID)
			_parry_press_at = float(ev["strike_time"]) - PARRY_LEAD
		&"retreat":
			core.set_guard(false)
			_pending_steps = [-1]
		_:
			core.set_guard(false)

	if cfg.has("attack_before_strike"):
		var abs_cfg: Dictionary = cfg["attack_before_strike"]
		if int(abs_cfg["index"]) == tells_seen:
			_timed_attack_at = float(ev["strike_time"]) - float(abs_cfg["lead"])
			_timed_attack_aim = abs_cfg["aim"]


func _on_strike(ev: Dictionary) -> void:
	var result: int = ev["result"]
	if result == DT.StrikeResult.BLOCKED or result == DT.StrikeResult.PARRIED:
		if not cfg.has("counter_fn"):
			return
		var limit := int(cfg.get("max_counters", -1))
		if limit >= 0 and counters_done >= limit:
			return
		var aim: Variant = cfg["counter_fn"].call(ev)
		if aim == null:
			return
		counters_done += 1
		var parrying := result == DT.StrikeResult.PARRIED
		_attack(aim)
		if parrying:
			# 패리 봇은 막기를 눌러 두지 않는다(다음 패리를 새로 눌러야 하므로).
			core.set_guard(false)
	elif result == DT.StrikeResult.WHIFF:
		if not cfg.has("whiff_fn"):
			return
		var aim: Variant = cfg["whiff_fn"].call(ev)
		if aim == null:
			return
		_pending_steps = [1]
		_pending_attack = aim


func _attack(aim: Array) -> void:
	core.set_aim(aim[0], aim[1])
	core.press_attack()
