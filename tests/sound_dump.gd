extends SceneTree
## 들을 파일(계획 H03 결정 939 (나)): 모든 열쇠와 이어 붙인 토막 넷을 16비트 모노 WAV로 떨군다.
## 실행: tests/run_sound_dump.ps1 -Out <폴더>. 마지막 줄 "SOUND DUMP OK <파일 수>".

const RATE := Beeper.MIX_RATE
const TAIL := 0.3

var _out := ""
var _count := 0


func _initialize() -> void:
	_out = ProjectSettings.globalize_path("user://sound_dump")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	for key: StringName in SoundBank.keys():
		_write("%s.wav" % key, SoundSynth.render(SoundBank.RECIPES[key], RATE))
	# 토막: [열쇠, 시작(초), 음높이]. 시각은 게임에서 겹치는 간격을 따른다.
	_write("seq_touch.wav", _mix([[&"draw", 0.0, 1.0], [&"swing_thrust", 0.11, 1.0], [&"graze_dealt", 0.20, 1.0]]))
	_write("seq_ladder.wav", _mix([[&"parry_mid", 0.0, 1.0], [&"parry_mid", 0.55, _semitones(2)], [&"parry", 1.10, _semitones(4)]]))
	_write("seq_taken.wav", _mix([[&"opp_swing", 0.0, 1.0], [&"hit_taken", 0.12, 1.0]]))
	_write("seq_hit.wav", _mix([[&"draw", 0.0, 1.0], [&"swing_thrust", 0.11, 1.0], [&"hit_dealt", 0.20, 1.0], [&"stagger", 0.75, 1.0]]))
	print("SOUND DUMP OK %d" % _count)
	quit(0)


func _semitones(n: float) -> float:
	return pow(2.0, n / 12.0)


## 소리들을 시작 시각에 맞춰 겹쳐 더한다. 음높이는 재생 속도를 바꾸는 것과 같다(선형 보간).
func _mix(layers: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for layer in layers:
		var s := SoundSynth.render(SoundBank.RECIPES[layer[0]], RATE)
		var pitch: float = layer[2]
		var length := int(s.size() / pitch)
		var start := int(float(layer[1]) * RATE)
		if out.size() < start + length:
			out.resize(start + length)
		for i in length:
			var pos := i * pitch
			var j := int(pos)
			var frac := pos - j
			var next := s[j + 1] if j + 1 < s.size() else 0.0
			out[start + i] += lerpf(s[j], next, frac)
	out.resize(out.size() + int(TAIL * RATE))
	for i in out.size():
		out[i] = clampf(out[i], -1.0, 1.0)
	return out


func _write(file_name: String, samples: PackedFloat32Array) -> void:
	var file := FileAccess.open(_out.path_join(file_name), FileAccess.WRITE)
	if file == null:
		push_error("열 수 없다: %s" % file_name)
		return
	var bytes := samples.size() * 2
	file.store_string("RIFF")
	file.store_32(36 + bytes)
	file.store_string("WAVEfmt ")
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(RATE)
	file.store_32(RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_string("data")
	file.store_32(bytes)
	for v in samples:
		file.store_16(int(clampf(v, -1.0, 1.0) * 32767.0) & 0xFFFF)
	file.close()
	_count += 1
	print("wav,%s,%d,%.3f" % [file_name, bytes, float(samples.size()) / RATE])
