extends RefCounted
## 상대 뷰의 상태를 정하는 도우미. T67과 찍기 씬(opponent_shots)이 함께 쓴다(결정 264).
## 판정을 돌리지 않고 코어·두뇌의 값을 직접 적는다. 표시만 보는 자리에서만 쓴다.

const DT := preload("res://scripts/duel/duel_types.gd")
const RULES_PATH := "res://data/duel_rules.tres"
const OPPONENT_PATH := "res://data/opponents/opponent_01.tres"
const WEAPON_PATH := "res://data/weapons/rapier.tres"

## put의 상태 자리에 넘기는 가짜 상태: 방심한 대기.
const COMPLACENT := 100
## 방심이 아닌 장의 코어 시각. 경계 시각 0에서 10초라 방심 게이지가 0.5다(방심 20초).
const NOW := 10.0
## 방심 장의 코어 시각. 방심의 시작은 max(0, 0 + 20) = 20이라 이때는 바뀜이 끝나 있다(결정 258).
const COMPLACENT_NOW := 25.0
## 상태에 들어선 지 이만큼 지난 것으로 두면 바뀜(return_time 0.2초)이 끝나 있다.
const SETTLED_AGO := 1.0
## settled가 거짓일 때: 바뀜의 가운데(0.1 / 0.2).
const FRESH_AGO := 0.1


static func make_core(has_hat := false) -> DuelCore:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var core := DuelCore.new()
	core.setup(load(RULES_PATH), load(WEAPON_PATH), load(OPPONENT_PATH), rng, [], has_hat)
	return core


## 간격과 상태를 정하고 표시 시각을 돌려준다. progress는 예비 동작·회수의 진행(0~1)이다.
## 간격을 먼저 정한다: 밀착이면 예비 시간에 밀착 배율이 든다(계획 029 기술 비차단).
static func put(core: DuelCore, state: int, atk: AttackData, progress: float, distance: int, settled := true) -> float:
	var brain := core.brain
	core.distance = distance
	brain.alert_since = 0.0
	brain.lunge_touches = 0
	brain.wide_open = false
	brain.current_attack = atk
	var ago := SETTLED_AGO if settled else FRESH_AGO
	var now := NOW
	match state:
		DT.OpponentState.TELL:
			brain.tell_duration = atk.tell_time
			if distance == DT.Distance.CLOSE:
				brain.tell_duration *= core.opponent_data.close_tell_multiplier
			brain.state_start = now - progress * brain.tell_duration
			brain.state_end = brain.state_start + brain.tell_duration
		DT.OpponentState.RECOVERY:
			var duration := maxf(atk.recovery_time, 0.5)
			brain.wide_open = atk.is_big
			brain.state_start = now - progress * duration
			brain.state_end = brain.state_start + duration
		DT.OpponentState.STAGGER:
			brain.current_attack = null
			brain.state_start = now - ago
			brain.state_end = brain.state_start + core.opponent_data.stagger_time
		COMPLACENT:
			now = COMPLACENT_NOW
			state = DT.OpponentState.IDLE
			brain.current_attack = null
			brain.state_start = 0.0
			brain.state_end = INF
		_:
			brain.current_attack = null
			brain.state_start = now - ago
			brain.state_end = now + 10.0
	brain.state = state
	core.time = now
	return now
