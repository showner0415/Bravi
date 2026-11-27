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
##       &"hold" 막기 유지 / &"keep" 누르고만 있기 / &"parry" 패리 / &"wrong" 틀린 방향 막기
##       / &"none" 무방비 / &"retreat" 후퇴
##       / &"wrong_height" 방향은 맞고 높이가 다른 막기(높이 없는 타격에서는 &"hold"와 같다)
##       막는 높이는 이벤트의 height를 따른다(없거나 -1이면 중단. 계획 036b).
##       &"hold"는 표시된 공격(needs_raised_guard)의 예비 동작이 보이면 막기를 뗐다가 곧바로 다시 누른다
##       (쿨다운 뒤 막기로 돌아온다 = 올린 막기). &"keep"은 떼지 않는다(들고만 있던 막기).
##       index는 1부터 세는 상대 공격 순번. 없으면 항상 &"hold".
##   counter_fn(strike_ev: Dictionary) -> Variant
##       막힘·패리 직후 받아칠 조준 [direction, height] 또는 null. 없으면 받아치지 않는다.
##   whiff_fn(strike_ev: Dictionary) -> Variant
##       상대가 헛친 뒤 칠 조준 [direction, height] 또는 null. 간격이 멀리일 때만 한 걸음 들어간다(결정 456).
##   finisher: [direction, height] — 상대가 무너지면 칠 조준.
##   max_counters: int — 받아치기 횟수 제한(-1이면 무제한).
##   want_distance: int — 이 간격이 될 때까지 전진한다. &"retreat"로 고른 예비 동작이 끝날 때까지는 쉰다(결정 456).
##   attack_at: {time, aim} — 코어 시각 time을 지난 첫 tick에 공격한다.
##   attack_before_strike: {index, lead, aim} — index번째 공격의 타격 lead초 전을 지난 첫 tick에 공격한다.
##   regrip_before_strike: {index, lead} — index번째 공격의 타격 lead초 전을 지난 첫 tick에
##       막기를 뗐다가 곧바로 다시 누른다.
##   counter_delay: float — 받아치기를 타격 시각 + 이 값(초)을 지난 첫 tick에 누른다(사람의 늦은 손).
##       없으면 타격과 같은 tick에 누른다. 무너진 상대에게 넣는 finisher에는 적용하지 않는다.
##   follow_up: {aim, max} — 내 공격의 판정 이벤트를 받으면, 입력이 받아들여지는 가장 이른 tick에
##       aim으로 한 번 더 공격한다. max는 횟수 제한(없거나 -1이면 무제한).
##   lunge: {height} — 선공 쓰기. 상대가 방심했고(게이지가 다 찼다) 간격이 교전일 때, 상대가 대기로 돌아간 직후
##       (in_out과 같은 두 순간)에 막기를 풀고 한 걸음 물러난다. 멀리에 닿아 "지금 좌클릭하면 런지"이면
##       가운데·height로 누른다. 물러나기 전에 막기를 누르고 있었으면 런지의 판정 직후 다시 누른다
##       (런지 뒤에 "새로 올린 막기"를 공짜로 얻지 않게). 게이지가 차기 전에는 아무것도 하지 않는다.
##       빈틈 없는 막기 뒤에도 치는 설정, follow_up, in_out과 함께 쓰지 않는다.
##   in_out: {enter, leave} — 들어갔다 나오기. 엉킴 게이지가 enter 이하이고 간격이 교전이면 밀착으로 들어가고,
##       leave 이상이고 간격이 밀착이면 교전으로 나온다. 이동은 상대가 대기로 돌아간 직후에만 한다:
##       막은 타격에 빈틈이 없었던 순간, 또는 내 공격의 판정이 끝난 순간. 그때 막기를 풀고 이동한다.
##       다음 예비 동작이 시작되면 guard_fn대로 다시 막는다. follow_up과 함께 쓰지 않는다
##       (밀려남으로 사라진 공격에는 판정 이벤트가 오지 않는다).
##   step_fn(attack: AttackData, index: int) -> StringName — 패턴의 걸음(index는 1부터)에서 쓸 모드.
##       없으면 그 패턴의 예비 동작에서 고른 모드를 그대로 쓴다. 걸음은 tells_seen을 올리지 않는다(결정 379).
##   parry_error_fn(wait: float) -> float — &"parry"를 누르는 때의 어긋남(초). wait는 그 타격의 예비·걸음의 간격(이벤트의 duration).
##       +면 늦게(늦으면 맞는다), -면 일찍(막힘이지 패리가 아니다). 없으면 0과 같다(계획 042 결정 644).
##   bite_fn(attack: AttackData) -> bool — 헛손질(attack.feint)의 예비 동작·걸음마다 한 번 부른다. 참이면 헛손질의 칸을 막는다(속는 손).
##       없거나 거짓이면 속지 않고 그다음 진짜 타격의 칸을 막는다(패리는 막기를 떼고 조준만, 누르기는 진짜의 걸음이 예약한다). 계획 044 결정 677.

const DT := preload("res://scripts/duel/duel_types.gd")

const PARRY_LEAD := 0.10

var core: DuelCore
var cfg: Dictionary = {}

## 지금까지 본 상대 공격(예비 동작) 수.
var tells_seen := 0
var counters_done := 0
var follow_ups_done := 0

var _parry_press_at := INF
var _regrip_at := INF
var _delayed_counter_at := INF
var _delayed_counter_aim: Array = []
var _delayed_counter_release := false
var _timed_attack_at := INF
var _timed_attack_aim: Array = []
var _pending_steps: Array[int] = []
var _pending_attack: Variant = null
## 선공 쓰기: 물러나는 중인가(멀리에 닿으면 런지를 누른다), 물러나기 전에 막기를 누르고 있었는가.
var _lunge_armed := false
var _lunge_regrip := false
## 지금 패턴의 예비 동작에서 고른 모드. 걸음이 이어받는다.
var _mode: StringName = &"hold"
## &"retreat"로 고른 예비 동작이 끝나기 전: want_distance가 물러선 걸음을 되돌리지 않게 한다(결정 456).
var _retreating := false
## 방금 고른 칸이 속지 않는 헛손질이라 그다음 진짜의 칸인가(패리를 누르지 않는다).
var _skipping := false


## 첫 피를 내는 봇의 설정: 막고, 빈틈이 생기는 공격 뒤에 중단 찌르기, 무너지면 중단 찌르기.
## 테스트(T16·T22·T30·T32)와 하루 통째 스모크가 함께 쓴다.
static func first_blood_cfg() -> Dictionary:
	var aim := [DT.Direction.CENTER, DT.Height.MID]
	var counter := func(ev: Dictionary) -> Variant:
		return aim if float(ev["recovery"]) > 0.0 else null
	return {"counter_fn": counter, "finisher": aim}


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
	if _regrip_at <= core.time:
		_regrip_at = INF
		core.set_guard(false)
		core.set_guard(true)
	var can_attack := core.player_state == DT.PlayerState.READY or core.player_state == DT.PlayerState.GUARD
	if _delayed_counter_at <= core.time and can_attack:
		_delayed_counter_at = INF
		_attack(_delayed_counter_aim)
		if _delayed_counter_release:
			core.set_guard(false)
		return
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
	if _lunge_armed:
		if not ready:
			return
		# 물러나는 걸음이 끝났다. 런지가 나가는 때면 누른다(상대가 먼저 다가왔으면 누르지 않는다).
		_lunge_armed = false
		if core.is_lunge_now():
			_attack([DT.Direction.CENTER, int(cfg["lunge"].get("height", DT.Height.MID))])
		elif _lunge_regrip:
			_lunge_regrip = false
			core.set_guard(true)
		return
	if _pending_attack != null:
		if ready or guarding:
			var aim: Array = _pending_attack
			_pending_attack = null
			_attack(aim)
		return
	if ready and cfg.has("want_distance") and core.distance < int(cfg["want_distance"]) \
			and not core.guard_held and not _retreating:
		core.step(1)


func _on_event(ev: Dictionary) -> void:
	match ev["type"]:
		DuelRecord.TELL_START:
			_on_tell(ev)
		DuelRecord.STRIKE:
			_on_strike(ev)
		DuelRecord.PATTERN_STEP:
			_on_step(ev)
		DuelRecord.ATTACK:
			if ev.get("lunge", false) and _lunge_regrip:
				# 물러나기 전에 누르고 있던 막기를 다시 누른다(회수가 끝나면 들고만 있던 막기로 돌아온다).
				_lunge_regrip = false
				core.set_guard(true)
			_in_out()
			_lunge_retreat()
			if cfg.has("follow_up"):
				var limit := int(cfg["follow_up"].get("max", -1))
				if limit < 0 or follow_ups_done < limit:
					follow_ups_done += 1
					_pending_attack = cfg["follow_up"]["aim"]
		DuelRecord.STAGGER_START:
			if cfg.has("finisher"):
				_pending_attack = cfg["finisher"]


func _on_tell(ev: Dictionary) -> void:
	tells_seen += 1
	var atk: AttackData = ev["attack"]
	var cell := _aim_cell(atk, ev, 0)
	var direction: int = cell[0]
	var height: int = cell[1]
	var mode: StringName = &"hold"
	if cfg.has("guard_fn"):
		mode = cfg["guard_fn"].call(atk, tells_seen)
	_mode = mode
	_retreating = mode == &"retreat"
	match mode:
		&"hold":
			core.set_aim(direction, height)
			if atk.needs_raised_guard:
				core.set_guard(false)
			core.set_guard(true)
		&"wrong_height":
			core.set_aim(direction, _other_height(int(cell[2]), direction))
			core.set_guard(true)
		&"keep":
			core.set_aim(direction, height)
			core.set_guard(true)
		&"wrong":
			core.set_aim((direction + 1) % 3, height)
			core.set_guard(true)
		&"parry":
			core.set_guard(false)
			core.set_aim(direction, height)
			# 속지 않는 헛손질에서는 누르지 않는다: 패리는 진짜의 PATTERN_STEP이 예약한다(결정 677).
			if not _skipping:
				_parry_press_at = _parry_time(ev)
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
	if cfg.has("regrip_before_strike"):
		var regrip_cfg: Dictionary = cfg["regrip_before_strike"]
		if int(regrip_cfg["index"]) == tells_seen:
			_regrip_at = float(ev["strike_time"]) - float(regrip_cfg["lead"])


## 패턴의 다음 타격: 같은 모드로 그 방향을 따른다. 무방비·후퇴는 아무것도 하지 않는다.
func _on_step(ev: Dictionary) -> void:
	var atk: AttackData = ev["attack"]
	var cell := _aim_cell(atk, ev, int(ev["index"]))
	var direction: int = cell[0]
	var height: int = cell[1]
	var mode := _mode
	if cfg.has("step_fn"):
		mode = cfg["step_fn"].call(atk, int(ev["index"]))
	match mode:
		&"hold", &"keep":
			core.set_aim(direction, height)
		&"wrong_height":
			core.set_aim(direction, _other_height(int(cell[2]), direction))
		&"wrong":
			core.set_aim((direction + 1) % 3, height)
		&"parry":
			core.set_guard(false)
			core.set_aim(direction, height)
			if not _skipping:
				_parry_press_at = _parry_time(ev)


## 패리를 누를 코어 시각: 타격 PARRY_LEAD초 전, 키가 있으면 그 어긋남만큼 옮긴다.
func _parry_time(ev: Dictionary) -> float:
	var at := float(ev["strike_time"]) - PARRY_LEAD
	if cfg.has("parry_error_fn"):
		at += float(cfg["parry_error_fn"].call(float(ev["duration"])))
	return at


## 막을 높이: 이벤트의 타격 높이, 없으면 중단.
func _guard_height(ev: Dictionary) -> int:
	var height := int(ev.get("height", -1))
	return height if height >= 0 else DT.Height.MID


## 이 타격에서 막을 칸 [방향, 막을 높이, 이벤트의 높이(없으면 -1)]. 속지 않는 헛손질이면 그다음 진짜 타격의 칸이다
## (헛손질에서 bite_fn이 참이면 그 칸 그대로 — 속는 손. 결정 677). 헛손질이 아니면 bite_fn을 부르지 않는다.
func _aim_cell(atk: AttackData, ev: Dictionary, index: int) -> Array:
	_skipping = false
	var raw := int(ev.get("height", -1))
	var cell := [atk.direction, raw if raw >= 0 else DT.Height.MID, raw]
	if not atk.feint or (cfg.has("bite_fn") and cfg["bite_fn"].call(atk)):
		return cell
	var root := core.brain.pattern_root
	for j in range(index + 1, root.chain.size() + 1):
		var next_atk: AttackData = root.chain[j - 1] as AttackData
		if not next_atk.feint:
			var next_raw: int = core.brain.strike_heights[j] if j < core.brain.strike_heights.size() else -1
			_skipping = true
			return [next_atk.direction, next_raw if next_raw >= 0 else DT.Height.MID, next_raw]
	return cell


## 일부러 틀리는 높이. 높이 없는 타격이면 중단이다(어느 높이든 막힌다).
## 헛손질이 있는 패턴에서는 틀린 높이가 헛손질의 칸이 되지 않게 비켜 간다(실수한 봇이 덤으로 속지 않게. 결정 677).
func _other_height(height: int, direction: int) -> int:
	if height < 0:
		return DT.Height.MID
	var other := (height + 1) % 3
	if _is_feint_cell(direction, other):
		other = (height + 2) % 3
	return other


## 지금 패턴에 이 칸(방향, 높이)의 헛손질이 있는가. 헛손질이 없는 패턴에서는 늘 거짓이다.
func _is_feint_cell(direction: int, height: int) -> bool:
	var root := core.brain.pattern_root
	if root == null:
		return false
	var heights := core.brain.strike_heights
	for i in root.chain.size() + 1:
		var strike: AttackData = root if i == 0 else (root.chain[i - 1] as AttackData)
		if strike.feint and strike.direction == direction and i < heights.size() and heights[i] == height:
			return true
	return false


func _on_strike(ev: Dictionary) -> void:
	var result: int = ev["result"]
	# 패턴이 이어지는 중에는 받아치지도 움직이지도 않는다(다음 타격이 온다. 결정 379).
	if float(ev.get("next_strike", -1.0)) >= 0.0:
		return
	_retreating = false
	if result == DT.StrikeResult.BLOCKED or result == DT.StrikeResult.PARRIED:
		# 빈틈이 없는 타격을 막았다: 상대는 대기로 돌아갔다. 들어가거나 나올 기회다.
		if is_zero_approx(float(ev["recovery"])):
			_in_out()
			_lunge_retreat()
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
		var delay := float(cfg.get("counter_delay", 0.0))
		if delay > 0.0:
			_delayed_counter_at = float(ev["t"]) + delay
			_delayed_counter_aim = aim
			_delayed_counter_release = parrying
			return
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
		_pending_steps = []
		if core.distance == DT.Distance.FAR:
			_pending_steps = [1]
		_pending_attack = aim


## 들어갔다 나오기: 지금의 게이지와 간격으로 이동을 정한다. 이동하기로 했으면 막기를 풀고 걸음을 예약한다
## (걸음은 READY가 되는 첫 tick에 나간다).
func _in_out() -> void:
	if not cfg.has("in_out") or core.ended or not _pending_steps.is_empty():
		return
	# 무너진 상대 앞에서는 움직이지 않는다(끝내기가 먼저다. 무너져 있는 동안에는 게이지도 차지 않는다).
	if core.brain.state == DT.OpponentState.STAGGER:
		return
	var io: Dictionary = cfg["in_out"]
	var gauge := core.bind_gauge()
	var direction := 0
	if core.distance == DT.Distance.ENGAGE and gauge <= float(io["enter"]):
		direction = 1
	elif core.distance == DT.Distance.CLOSE and gauge >= float(io["leave"]):
		direction = -1
	if direction == 0:
		return
	core.set_guard(false)
	_pending_steps = [direction]


## 선공 쓰기: 상대가 방심했으면 막기를 풀고 멀리로 물러난다(런지는 멀리에 닿은 뒤 update가 누른다).
func _lunge_retreat() -> void:
	if not cfg.has("lunge") or core.ended or _lunge_armed or not _pending_steps.is_empty():
		return
	if core.distance != DT.Distance.ENGAGE or core.complacency() < 1.0:
		return
	if core.brain.state == DT.OpponentState.STAGGER:
		return
	_lunge_regrip = core.guard_held
	core.set_guard(false)
	_pending_steps = [-1]
	_lunge_armed = true


func _attack(aim: Array) -> void:
	core.set_aim(aim[0], aim[1])
	core.press_attack()
