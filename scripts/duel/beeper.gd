class_name Beeper
extends Node
## 결투 사건마다 소리를 낸다. 소리는 코드로 합성한다(파일 애셋 없음. SoundBank의 조리법을 SoundSynth가 만든다).
## 판정에는 관여하지 않는다. 소리가 되풀이될 때의 변주는 판정의 rng와 따로 가진 난수로 뽑는다(골든이 같다).

const MIX_RATE := 22050
## 겹쳐 울릴 수 있는 음의 수. 휙은 따로 하나를 더 쓴다(판정 tick에 끊으려고).
const VOICES := 8
const VARIATION := 0.03
## 한 걸음에 2반음(결정 941). 한 패턴에서 받아낸 수의 상한.
const CLIMB_SEMITONES := 2.0
const CLIMB_MAX := 3
## 상대 타격의 바람이 판정보다 앞서 울리는 시간(초).
const OPP_SWING_LEAD := 0.12
const THRUST_SWING_MAX := 0.12
const CUT_SWING_MAX := 0.22
const PULL_MAX := 0.05
## 변주도 오르는 음도 없이 늘 같은 음높이로 나는 소리(알아보는 안전함. 결정 941).
const FIXED_PITCH := [&"tell", &"dive", &"closed", &"feint", &"bitten", &"spike"]
const CLIMBING := [&"block", &"parry_mid", &"parry"]
const SWINGS := [&"swing_thrust", &"swing_cut"]
const HISTORY_MAX := 64

## 합성은 프로세스에서 한 번만 한다(결투 씬을 수백 번 여는 테스트가 느려지지 않게).
static var _cache := {}

## 켜 두면 낸 소리를 [열쇠, pitch_scale]로 적어 둔다(테스트용).
var record := false
var history: Array = []

var _players: Array[AudioStreamPlayer] = []
var _swing_player: AudioStreamPlayer
var _next := 0
var _rng := RandomNumberGenerator.new()
var _climb := 0
## 예약: {key, at(코어 시각), tag(&"swing" 또는 &"opp")}.
var _scheduled: Array[Dictionary] = []


func _init() -> void:
	_rng.seed = 917


func _ready() -> void:
	# 살아 있는 창에서는 첫 패리에서 버벅이지 않게 미리 만든다. 헤드리스는 처음 쓸 때 만든다.
	if DisplayServer.get_name() != "headless":
		for key: StringName in SoundBank.keys():
			stream_of(key)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_swing_player = AudioStreamPlayer.new()
	add_child(_swing_player)


## 열쇠의 소리. 처음 부르면 만들어 캐시에 둔다.
static func stream_of(key: StringName) -> AudioStreamWAV:
	if not _cache.has(key):
		_cache[key] = to_stream(SoundSynth.render(SoundBank.RECIPES[key], MIX_RATE), MIX_RATE)
	return _cache[key]


static func to_stream(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


## 이벤트가 내는 소리의 열쇠(없으면 &""). moment는 HitFeel.moment_of의 답이다(비면 이벤트만 본다).
static func key_of(ev: Dictionary, moment: StringName = &"") -> StringName:
	match ev["type"]:
		DuelRecord.TELL_START:
			return &"dive" if (ev["attack"] as AttackData).dive else &"tell"
		DuelRecord.FEINT:
			return &"bitten" if ev["bitten"] else &"feint"
		DuelRecord.DISTANCE:
			return &"hop" if ev.get("by", "") == "withdraw" else &""
		DuelRecord.PATTERN_STEP:
			return &"tell"
		DuelRecord.ATTACK_START:
			return &"draw"
		DuelRecord.STEP_START:
			return &"step"
		DuelRecord.SHOVE:
			return &"shove"
		DuelRecord.STAGGER_START:
			return &"stagger"
		DuelRecord.STRIKE:
			return _strike_key(ev, moment)
		DuelRecord.ATTACK:
			return _attack_key(ev)
	return &""


static func _strike_key(ev: Dictionary, moment: StringName) -> StringName:
	if ev.get("closed", false):
		return &"closed"
	if moment == HitFeel.SWEEP_OPEN or moment == HitFeel.DIVE_OPEN:
		return &"parry"
	if moment == HitFeel.DIVE_WHIFF:
		return &"dodge_open"
	match ev["result"]:
		DuelTypes.StrikeResult.BLOCKED:
			return &"block"
		DuelTypes.StrikeResult.PARRIED:
			# 안 열린 패리에 패리의 소리를 주면 열렸다고 읽힌다(결정 947-5).
			if ev.get("bitten", false) or ev.get("braced", false):
				return &"block"
			return &"parry_mid" if float(ev.get("next_strike", -1.0)) >= 0.0 else &"parry"
		DuelTypes.StrikeResult.GRAZE:
			return &"graze_taken"
		DuelTypes.StrikeResult.HIT:
			return &"hit_taken"
	return &""


static func _attack_key(ev: Dictionary) -> StringName:
	if ev.get("spiked", false):
		return &"spike"
	match ev["result"]:
		DuelTypes.AttackResult.GRAZE:
			return &"graze_dealt"
		DuelTypes.AttackResult.HIT:
			return &"hit_dealt"
		DuelTypes.AttackResult.BLOCKED:
			return &"whiff" if ev.get("dodged", false) else &"attack_blocked"
		DuelTypes.AttackResult.WHIFF:
			return &"whiff"
	return &""


func on_event(ev: Dictionary, moment: StringName = &"") -> void:
	var type: StringName = ev["type"]
	match type:
		DuelRecord.TELL_START:
			_climb = 0
			_drop(&"opp")
			_schedule_opp_swing(ev)
		DuelRecord.PATTERN_STEP:
			_schedule_opp_swing(ev)
		DuelRecord.ATTACK_START:
			_schedule_player_swing(ev)
		DuelRecord.ATTACK:
			_drop(&"swing")
			_swing_player.stop()
		DuelRecord.STAGGER_START, DuelRecord.END:
			_scheduled.clear()
		DuelRecord.SHOVE:
			_drop(&"swing")
			_swing_player.stop()
	var key := key_of(ev, moment)
	if key != &"":
		_play(key)
	if type == DuelRecord.STRIKE:
		_count_strike(ev, key)


## 받아낸 수를 센다: 막고 패리한 타격만 올라가고 맞으면 처음으로 돌아간다.
func _count_strike(ev: Dictionary, key: StringName) -> void:
	if key == &"closed" or key == &"dodge_open":
		return
	match ev["result"]:
		DuelTypes.StrikeResult.BLOCKED, DuelTypes.StrikeResult.PARRIED:
			_climb = mini(_climb + 1, CLIMB_MAX)
		DuelTypes.StrikeResult.GRAZE, DuelTypes.StrikeResult.HIT:
			_climb = 0


func _schedule_opp_swing(ev: Dictionary) -> void:
	var attack := ev.get("attack") as AttackData
	var root := ev.get("root") as AttackData
	if attack == null or attack.feint:
		return
	# 휩쓸기의 둘째 점부터는 한 번의 긴 베기라 바람이 이어진다.
	if ev["type"] == DuelRecord.PATTERN_STEP and root != null and root.sweep:
		return
	var at := float(ev["strike_time"]) - OPP_SWING_LEAD
	if at > float(ev["t"]):
		schedule(&"opp_swing", at, &"opp")


## 휙은 뻗음에 맞춘다(찌르기는 뻗음의 길이, 베기는 칼을 옆으로 드는 끝부터). 길이의 곡선은 PlayerSwordView와 같다.
func _schedule_player_swing(ev: Dictionary) -> void:
	var judge := float(ev["judge_time"])
	var windup := judge - float(ev["t"])
	var thrust: bool = ev["direction"] == DuelTypes.Direction.CENTER
	var length: float
	if thrust:
		length = minf(THRUST_SWING_MAX, 0.45 * windup)
	else:
		length = minf(CUT_SWING_MAX, windup - minf(PULL_MAX, 0.25 * windup))
	schedule(&"swing_thrust" if thrust else &"swing_cut", judge - length, &"swing")


## 코어 시각 at에 열쇠의 소리를 내도록 맡긴다(advance_to가 낸다).
func schedule(key: StringName, at: float, tag: StringName = &"") -> void:
	_scheduled.append({"key": key, "at": at, "tag": tag})


## 코어 시각이 예약을 넘으면 낸다. 멈칫과 일시정지 동안은 코어 시각이 흐르지 않아 기다린다.
func advance_to(core_time: float) -> void:
	var i := 0
	while i < _scheduled.size():
		var item := _scheduled[i]
		if float(item["at"]) <= core_time:
			_scheduled.remove_at(i)
			_play(item["key"])
		else:
			i += 1


## 남은 예약을 지우고 휙을 멈춘다(새 판).
func clear() -> void:
	_scheduled.clear()
	_climb = 0
	if _swing_player != null:
		_swing_player.stop()


func scheduled_count() -> int:
	return _scheduled.size()


func _drop(tag: StringName) -> void:
	var i := _scheduled.size() - 1
	while i >= 0:
		if _scheduled[i]["tag"] == tag:
			_scheduled.remove_at(i)
		i -= 1


## 설정 화면의 미리 듣기(결정 504). _ready 전이나 모르는 열쇠는 건너뛴다.
func play(key: StringName) -> void:
	if _players.is_empty() or not SoundBank.has(key):
		return
	_play(key)


func _pitch_of(key: StringName) -> float:
	if key in FIXED_PITCH:
		return 1.0
	var pitch := _rng.randf_range(1.0 - VARIATION, 1.0 + VARIATION)
	if key in CLIMBING:
		pitch *= pow(2.0, CLIMB_SEMITONES * _climb / 12.0)
	return pitch


func _play(key: StringName) -> void:
	var player: AudioStreamPlayer
	if key in SWINGS:
		player = _swing_player
	else:
		player = _players[_next]
		_next = (_next + 1) % _players.size()
	player.stream = stream_of(key)
	player.pitch_scale = _pitch_of(key)
	player.play()
	if record:
		history.append([key, player.pitch_scale])
		if history.size() > HISTORY_MAX:
			history.pop_front()
