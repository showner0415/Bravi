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
	&"block": [520.0, 0.06],
	&"parry": [880.0, 0.12],
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
			_play(&"tell")
		DuelRecord.PATTERN_STEP:
			_play(&"tell")
		DuelRecord.STRIKE:
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
