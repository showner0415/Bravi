class_name Beeper
extends Node
## 결투 사건마다 높이가 다른 비프음을 낸다. 음은 코드에서 사인파로 만든다(파일 애셋 없음).
## 판정에는 관여하지 않는다.

const MIX_RATE := 22050
const VOLUME := 0.35
## 겹쳐 울릴 수 있는 음의 수.
const VOICES := 4

## 사건별 [주파수(Hz), 길이(초)].
const TONES := {
	&"tell": [330.0, 0.07],
	## 뛰어들기의 예비 동작: 예비 동작음보다 낮고 길다(결정 454).
	&"dive": [200.0, 0.16],
	&"block": [520.0, 0.06],
	&"parry": [880.0, 0.12],
	## 막았는데 빈틈을 주지 않았다: 막힘보다 한 옥타브 낮고 길다(결정 404).
	&"closed": [260.0, 0.10],
	## 헛손질: 막힘보다 낮고 짧은 바람 소리. 속았으면 안 열림보다 낮고 긴 소리(결정 670).
	&"feint": [400.0, 0.04],
	&"bitten": [170.0, 0.18],
	&"graze": [660.0, 0.09],
	&"stagger": [220.0, 0.30],
	&"hit": [990.0, 0.35],
}

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for key: StringName in TONES:
		_streams[key] = _make_tone(TONES[key][0], TONES[key][1])
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## 코어 이벤트를 받아 해당하는 음을 낸다.
func on_event(ev: Dictionary) -> void:
	match ev["type"]:
		DuelRecord.TELL_START:
			_play(&"dive" if (ev["attack"] as AttackData).dive else &"tell")
		DuelRecord.FEINT:
			_play(&"bitten" if ev["bitten"] else &"feint")
		DuelRecord.PATTERN_STEP:
			_play(&"tell")
		DuelRecord.STRIKE:
			if ev.get("closed", false):
				_play(&"closed")
				return
			match ev["result"]:
				DuelTypes.StrikeResult.BLOCKED:
					_play(&"block")
				DuelTypes.StrikeResult.PARRIED:
					_play(&"parry")
				DuelTypes.StrikeResult.GRAZE:
					_play(&"graze")
				DuelTypes.StrikeResult.HIT:
					_play(&"hit")
		DuelRecord.ATTACK:
			match ev["result"]:
				DuelTypes.AttackResult.GRAZE:
					_play(&"graze")
				DuelTypes.AttackResult.HIT:
					_play(&"hit")
		DuelRecord.STAGGER_START:
			_play(&"stagger")


## 설정 화면의 미리 듣기(결정 504). _ready 전이나 모르는 키는 건너뛴다(_play의 % 0 오류 방지).
func play(key: StringName) -> void:
	if _players.is_empty() or not _streams.has(key):
		return
	_play(key)


func _play(key: StringName) -> void:
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[key]
	player.play()


## 끝이 부드럽게 줄어드는 16비트 모노 사인파.
func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var count := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / MIX_RATE
		var fade := minf(1.0, float(count - i) / (MIX_RATE * 0.02))
		var sample := sin(TAU * frequency * t) * VOLUME * fade
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
