extends RefCounted
## T217: 소리(계획 H03 결정 939~941, 947-5) — 합성한 표본의 모양(봉우리·위계·트랜지언트·무게중심·감쇠·비조화·바람),
## 같은 바이트와 캐시, 이벤트 → 열쇠, 예약(코어 시각), 오르는 음과 변주.
## 귀가 없어 소리를 수로 잰다: 무게중심은 512표본 Hann 창 FFT의 힘을 힘으로 가중해 센다(처음 10ms의 트랜지언트는 뺀다).

const DT := preload("res://scripts/duel/duel_types.gd")

const RATE := Beeper.MIX_RATE
const SEG := 512
const BAND_LOW := 60.0
const BAND_HIGH := 10000.0
const TRANSIENT_KEYS: Array[StringName] = [&"hop", &"draw", &"attack_blocked", &"spike", &"block", &"closed", &"parry_mid", &"parry"]
const LOW_KEYS: Array[StringName] = [&"graze_taken", &"hit_taken", &"step", &"shove", &"stagger"]
const SR := DT.StrikeResult
const AR := DT.AttackResult

var _tree: SceneTree
var _made: Array[Node] = []
var _samples := {}
var _window := PackedFloat32Array()


func list(tree: SceneTree) -> Array:
	_tree = tree
	return [
		{"id": "T217", "name": "소리: 합성 표본의 모양(위계·트랜지언트·무게중심·감쇠·비조화·바람), 캐시, 이벤트 → 열쇠, 예약, 오르는 음과 변주", "fn": t217_sound},
	]


func cleanup() -> void:
	for node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()
	_tree = null


func _expect(errs: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		errs.append(msg)


# ================================================================ 재는 함수

func _of(key: StringName) -> PackedFloat32Array:
	if not _samples.has(key):
		_samples[key] = SoundSynth.render(SoundBank.RECIPES[key], RATE)
	return _samples[key]


func _peak(s: PackedFloat32Array, from := 0, to := -1) -> float:
	var end := s.size() if to < 0 else mini(to, s.size())
	var peak := 0.0
	for i in range(from, end):
		peak = maxf(peak, absf(s[i]))
	return peak


func _crossings(s: PackedFloat32Array, from: int, to: int) -> int:
	var count := 0
	var end := mini(to, s.size())
	for i in range(from + 1, end):
		if (s[i - 1] < 0.0) != (s[i] < 0.0):
			count += 1
	return count


func _goertzel(s: PackedFloat32Array, from: int, n: int, freq: float, hann: bool) -> float:
	var coeff := 2.0 * cos(TAU * freq / RATE)
	var s1 := 0.0
	var s2 := 0.0
	for i in n:
		var x := s[from + i]
		if hann:
			x *= _window[i]
		var s0 := x + coeff * s1 - s2
		s2 = s1
		s1 = s0
	return s1 * s1 + s2 * s2 - coeff * s1 * s2


## 기음 근처(+-2%)의 가장 센 힘. 표본 전체를 한 창으로 본다.
func _power_near(s: PackedFloat32Array, freq: float) -> float:
	var best := 0.0
	for k in [0.98, 1.0, 1.02]:
		best = maxf(best, _goertzel(s, 0, s.size(), freq * k, false))
	return best


## 힘으로 가중한 스펙트럼 무게중심(Hz). 512표본 Hann 창의 FFT 힘을 모두 더해 60Hz~10kHz 안에서 센다.
## skip 표본 앞은 건너뛴다(처음 몇 ms의 트랜지언트 잡음이 음색의 높낮이를 덮지 않게).
func _centroid(s: PackedFloat32Array, skip := 0) -> float:
	if _window.is_empty():
		_window.resize(SEG)
		for i in SEG:
			_window[i] = 0.5 - 0.5 * cos(TAU * i / (SEG - 1))
	var powers := PackedFloat64Array()
	powers.resize((SEG >> 1))
	var start := skip
	while start == skip or start + int(SEG * 0.25) <= s.size():
		var re := PackedFloat64Array()
		re.resize(SEG)
		for i in mini(SEG, s.size() - start):
			re[i] = s[start + i] * _window[i]
		var im := PackedFloat64Array()
		im.resize(SEG)
		_fft(re, im)
		for k in (SEG >> 1):
			powers[k] += re[k] * re[k] + im[k] * im[k]
		start += SEG
	var sum := 0.0
	var weighted := 0.0
	for k in (SEG >> 1):
		var freq := float(k) * RATE / SEG
		if freq >= BAND_LOW and freq <= BAND_HIGH:
			sum += powers[k]
			weighted += powers[k] * freq
	return weighted / sum if sum > 0.0 else 0.0


## 제자리 radix-2 FFT(길이는 2의 거듭제곱).
func _fft(re: PackedFloat64Array, im: PackedFloat64Array) -> void:
	var n := re.size()
	var j := 0
	for i in range(1, n):
		var bit := n >> 1
		while j & bit:
			j ^= bit
			bit >>= 1
		j ^= bit
		if i < j:
			var tr := re[i]
			re[i] = re[j]
			re[j] = tr
			var ti := im[i]
			im[i] = im[j]
			im[j] = ti
	var span := 2
	while span <= n:
		var ang := -TAU / span
		var wr := cos(ang)
		var wi := sin(ang)
		for i in range(0, n, span):
			var cr := 1.0
			var ci := 0.0
			for k in span >> 1:
				var a := i + k
				var b := a + (span >> 1)
				var xr := re[b] * cr - im[b] * ci
				var xi := re[b] * ci + im[b] * cr
				re[b] = re[a] - xr
				im[b] = im[a] - xi
				re[a] += xr
				im[a] += xi
				var nr := cr * wr - ci * wi
				ci = cr * wi + ci * wr
				cr = nr
		span <<= 1


## 10ms 창의 RMS가 봉우리 창의 10%로 떨어지는 시각(초).
func _t10(s: PackedFloat32Array) -> float:
	var win := int(RATE * 0.01)
	var hop := int(win * 0.5)
	var rms: Array[float] = []
	var i := 0
	while i + win <= s.size():
		var acc := 0.0
		for j in win:
			acc += s[i + j] * s[i + j]
		rms.append(sqrt(acc / win))
		i += hop
	if rms.is_empty():
		return 0.0
	var top := 0
	for k in rms.size():
		if rms[k] > rms[top]:
			top = k
	for k in range(top, rms.size()):
		if rms[k] < 0.1 * rms[top]:
			return (k * hop + win * 0.5) / RATE
	return float(s.size()) / RATE


## 봉우리의 90%에 처음 닿는 시각(초).
func _rise(s: PackedFloat32Array) -> float:
	var peak := _peak(s)
	for i in s.size():
		if absf(s[i]) >= 0.9 * peak:
			return float(i) / RATE
	return 0.0


# ================================================================ T217

func t217_sound() -> String:
	var errs: Array[String] = []
	_check_shapes(errs)
	_check_cache(errs)
	_check_keys(errs)
	var beeper := Beeper.new()
	_tree.root.add_child(beeper)
	_made.append(beeper)
	beeper.record = true
	_check_schedule(errs, beeper)
	_check_climb(errs)
	return "OK" if errs.is_empty() else " / ".join(errs)


func _check_shapes(errs: Array[String]) -> void:
	var centroids := {}
	var t10s := {}
	for key: StringName in SoundBank.keys():
		var s := _of(key)
		var gain := float(SoundBank.RECIPES[key]["gain"])
		var peak := _peak(s)
		_expect(errs, peak <= 1.0, "%s 표본이 1.0을 넘었다(%.3f)" % [key, peak])
		_expect(errs, absf(peak - gain) <= 0.02, "%s 봉우리 %.3f가 조리법 %.2f와 다르다" % [key, peak, gain])
		centroids[key] = _centroid(s, int(RATE * 0.01) if s.size() > int(RATE * 0.04) else 0)
		t10s[key] = _t10(s)
		print("  INFO sound,%s,%.3f,%.0f,%.3f,%.4f,span=%.3f" % [key, peak, centroids[key], t10s[key], _rise(s), float(s.size()) / RATE])
	# 위계: 누름 < 예비음 < 막기 < 스침 < 패리 < 유효타, 맞은 유효타는 넣은 것 이상
	var order: Array[StringName] = [&"draw", &"tell", &"block", &"graze_dealt", &"parry", &"hit_dealt"]
	for i in range(1, order.size()):
		_expect(errs, _peak(_of(order[i - 1])) < _peak(_of(order[i])), "위계: %s < %s" % [order[i - 1], order[i]])
	_expect(errs, _peak(_of(&"hit_taken")) >= _peak(_of(&"hit_dealt")), "hit_taken의 봉우리가 hit_dealt 이상")
	# 트랜지언트: T 층이 있는 열쇠는 처음 5ms가 잡음이다(720Hz 사인의 3배 이상의 영교차)
	var floor_cross := int(ceil(3.0 * 2.0 * 720.0 * 0.005))
	for key in TRANSIENT_KEYS:
		var s := _of(key)
		var crossed := _crossings(s, 0, int(RATE * 0.005))
		_expect(errs, crossed >= floor_cross, "%s 처음 5ms 영교차 %d < %d" % [key, crossed, floor_cross])
		_expect(errs, _peak(s, 0, int(RATE * 0.008)) >= 0.9 * _peak(s), "%s 봉우리가 처음 8ms 안에 없다" % key)
	var graze := _of(&"graze_dealt")
	var cross_rate := _crossings(graze, 0, int(RATE * 0.04)) / 0.04
	_expect(errs, cross_rate >= 0.6 * 3000.0, "graze_dealt 영교차율 %.0f/s가 1500Hz 사인의 0.6배(1800)보다 낮다" % cross_rate)
	_expect(errs, graze.size() <= int(RATE * 0.1), "graze_dealt에 0.1초 뒤 표본이 있다(울림이 있다)")
	var dealt_cross := _crossings(_of(&"hit_dealt"), 0, int(RATE * 0.04))
	var taken_cross := _crossings(_of(&"hit_taken"), 0, int(RATE * 0.04))
	_expect(errs, dealt_cross > 3 * taken_cross, "hit_dealt 영교차 %d가 hit_taken %d의 3배 이하" % [dealt_cross, taken_cross])
	# 낮은 것은 낮다
	for key in LOW_KEYS:
		_expect(errs, centroids[key] < 400.0, "%s 무게중심 %.0fHz가 400Hz 이상" % [key, centroids[key]])
	_expect(errs, centroids[&"hit_dealt"] > 2.0 * centroids[&"hit_taken"], "hit_dealt 무게중심이 hit_taken의 2배 이하")
	# 패리와 막기가 갈린다
	_expect(errs, centroids[&"parry"] >= 2.0 * centroids[&"block"], "parry 무게중심이 block의 2배 미만")
	_expect(errs, t10s[&"parry"] >= 0.25, "parry t10 %.3f < 0.25" % t10s[&"parry"])
	_expect(errs, t10s[&"parry_mid"] >= 0.08 and t10s[&"parry_mid"] <= 0.20, "parry_mid t10 %.3f가 0.08~0.20 밖" % t10s[&"parry_mid"])
	_expect(errs, t10s[&"block"] <= 0.12, "block t10 %.3f > 0.12" % t10s[&"block"])
	_expect(errs, t10s[&"closed"] <= 0.12, "closed t10 %.3f > 0.12" % t10s[&"closed"])
	_expect(errs, centroids[&"closed"] < centroids[&"block"], "closed 무게중심이 block보다 높다")
	# 비조화: 둘째 비율 자리의 힘 > 기음 x 2 자리의 힘
	for key: StringName in [&"parry", &"parry_mid", &"block"]:
		var ring: Dictionary = SoundBank.RECIPES[key]["r"]
		var base := float(ring["f"])
		var second := _power_near(_of(key), base * float(ring["ratios"][1]))
		var octave := _power_near(_of(key), base * 2.0)
		_expect(errs, second > octave, "%s 비조화: 둘째 부분음 힘 %.0f <= 기음 x 2의 힘 %.0f" % [key, second, octave])
		print("  INFO inharmonic,%s,%.0f,%.0f" % [key, second, octave])
	# 바람은 쓴다
	var thrust := _of(&"swing_thrust")
	var whiff := _of(&"whiff")
	var third := int(thrust.size() / 3.0)
	_expect(errs, _centroid(thrust.slice(0, third)) < _centroid(thrust.slice(2 * third)), "swing_thrust는 오르며 쓸어야 한다")
	third = int(whiff.size() / 3.0)
	_expect(errs, _centroid(whiff.slice(0, third)) > _centroid(whiff.slice(2 * third)), "whiff는 내리며 쓸어야 한다")


func _check_cache(errs: Array[String]) -> void:
	var recipe: Dictionary = SoundBank.RECIPES[&"parry"]
	_expect(errs, SoundSynth.render(recipe, RATE) == SoundSynth.render(recipe, RATE), "같은 조리법이 다른 표본을 만들었다")
	var a := Beeper.stream_of(&"block")
	_expect(errs, a == Beeper.stream_of(&"block"), "둘째는 캐시에서 와야 한다")
	_expect(errs, a.data == Beeper.to_stream(_of(&"block"), RATE).data, "캐시의 바이트가 표본과 다르다")
	var beeper := Beeper.new()
	_tree.root.add_child(beeper)
	_made.append(beeper)
	beeper.play(&"block")
	var voiced := false
	for player: AudioStreamPlayer in beeper.get("_players"):
		voiced = voiced or player.stream == a
	_expect(errs, voiced, "play(&\"block\")가 그 자리에서 소리를 내지 않았다")
	beeper.play(&"없는_열쇠")


func _ev(type: StringName, extra := {}) -> Dictionary:
	var ev := {"type": type, "t": 0.0}
	ev.merge(extra, true)
	return ev


func _strike(result: int, extra := {}) -> Dictionary:
	return _ev(DuelRecord.STRIKE, {"result": result, "next_strike": -1.0, "closed": false, "braced": false}.merged(extra, true))


func _attack(result: int, extra := {}) -> Dictionary:
	return _ev(DuelRecord.ATTACK, {"result": result, "dodged": false, "rash": false}.merged(extra, true))


func _check_keys(errs: Array[String]) -> void:
	var dive := AttackData.new()
	dive.dive = true
	var table := [
		[_ev(DuelRecord.TELL_START, {"attack": AttackData.new()}), &"", &"tell"],
		[_ev(DuelRecord.TELL_START, {"attack": dive}), &"", &"dive"],
		[_ev(DuelRecord.FEINT, {"bitten": true}), &"", &"bitten"],
		[_ev(DuelRecord.FEINT, {"bitten": false}), &"", &"feint"],
		[_ev(DuelRecord.DISTANCE, {"by": "withdraw"}), &"", &"hop"],
		[_ev(DuelRecord.DISTANCE, {"by": "player"}), &"", &""],
		[_ev(DuelRecord.PATTERN_STEP), &"", &"tell"],
		[_ev(DuelRecord.ATTACK_START), &"", &"draw"],
		[_ev(DuelRecord.STEP_START), &"", &"step"],
		[_ev(DuelRecord.SHOVE), &"", &"shove"],
		[_ev(DuelRecord.STAGGER_START), &"", &"stagger"],
		[_strike(SR.BLOCKED), &"", &"block"],
		[_strike(SR.BLOCKED, {"closed": true}), &"", &"closed"],
		[_strike(SR.PARRIED, {"closed": true}), &"", &"closed"],
		[_strike(SR.PARRIED, {"bitten": true}), &"", &"block"],
		[_strike(SR.PARRIED, {"braced": true}), &"", &"block"],
		[_strike(SR.PARRIED, {"next_strike": 1.0}), &"", &"parry_mid"],
		[_strike(SR.PARRIED), &"", &"parry"],
		[_strike(SR.BLOCKED), HitFeel.SWEEP_OPEN, &"parry"],
		[_strike(SR.WHIFF), HitFeel.DIVE_WHIFF, &"dodge_open"],
		[_strike(SR.GRAZE), &"", &"graze_taken"],
		[_strike(SR.HIT), &"", &"hit_taken"],
		[_strike(SR.WHIFF), &"", &""],
		[_attack(AR.BLOCKED), &"", &"attack_blocked"],
		[_attack(AR.BLOCKED, {"rash": true}), &"", &"attack_blocked"],
		[_attack(AR.BLOCKED, {"dodged": true}), &"", &"whiff"],
		[_attack(AR.BLOCKED, {"spiked": true}), &"", &"spike"],
		[_attack(AR.WHIFF), &"", &"whiff"],
		[_attack(AR.GRAZE), &"", &"graze_dealt"],
		[_attack(AR.HIT), &"", &"hit_dealt"],
	]
	for row in table:
		var got := Beeper.key_of(row[0], row[1])
		_expect(errs, got == row[2], "key_of(%s, %s) = '%s', 기대 '%s'" % [row[0]["type"], row[1], got, row[2]])
		_expect(errs, row[2] == &"" or SoundBank.has(row[2]), "열쇠 %s의 조리법이 없다" % row[2])


func _check_schedule(errs: Array[String], beeper: Beeper) -> void:
	var thrust_ev := _ev(DuelRecord.ATTACK_START, {"t": 1.0, "judge_time": 1.2, "direction": DT.Direction.CENTER})
	beeper.on_event(thrust_ev)
	_expect(errs, not beeper.history.is_empty() and beeper.history[-1][0] == &"draw", "ATTACK_START에서 draw가 곧바로 나지 않았다")
	_expect(errs, beeper.scheduled_count() == 1, "찌르기의 휙이 예약되지 않았다")
	var before := beeper.history.size()
	beeper.advance_to(1.2 - 0.09 - 0.002)
	_expect(errs, beeper.history.size() == before, "휙이 judge_time-0.09보다 일찍 났다")
	beeper.advance_to(1.2 - 0.09 + 0.002)
	_expect(errs, beeper.history[-1][0] == &"swing_thrust" and beeper.scheduled_count() == 0, "휙이 judge_time-0.09에 나지 않았다")
	beeper.on_event(_attack(AR.WHIFF, {"t": 1.2}))
	_expect(errs, not (beeper.get("_swing_player") as AudioStreamPlayer).playing, "ATTACK에서 휙이 멈추지 않았다")
	beeper.on_event(_ev(DuelRecord.ATTACK_START, {"t": 2.0, "judge_time": 2.7, "direction": DT.Direction.LEFT}))
	beeper.advance_to(2.7 - 0.22 - 0.002)
	_expect(errs, beeper.history[-1][0] != &"swing_cut", "상단 베기의 휙이 judge_time-0.22보다 일찍 났다")
	beeper.advance_to(2.7 - 0.22 + 0.002)
	_expect(errs, beeper.history[-1][0] == &"swing_cut", "상단 베기의 휙이 judge_time-0.22에 나지 않았다")
	beeper.on_event(_ev(DuelRecord.ATTACK_START, {"t": 3.0, "judge_time": 3.2, "direction": DT.Direction.CENTER}))
	beeper.on_event(_attack(AR.BLOCKED, {"t": 3.1}))
	_expect(errs, beeper.scheduled_count() == 0, "ATTACK가 남은 휙 예약을 지우지 않았다")
	# 상대 타격의 바람
	var tell := _ev(DuelRecord.TELL_START, {"t": 4.0, "strike_time": 5.0, "attack": AttackData.new()})
	beeper.on_event(tell)
	_expect(errs, beeper.scheduled_count() == 1, "TELL_START가 opp_swing을 예약하지 않았다")
	beeper.advance_to(5.0 - 0.12 - 0.002)
	_expect(errs, beeper.history[-1][0] != &"opp_swing", "opp_swing이 strike_time-0.12보다 일찍 났다")
	beeper.advance_to(5.0 - 0.12 + 0.002)
	_expect(errs, beeper.history[-1][0] == &"opp_swing", "opp_swing이 strike_time-0.12에 나지 않았다")
	var feint := AttackData.new()
	feint.feint = true
	beeper.on_event(_ev(DuelRecord.PATTERN_STEP, {"t": 6.0, "strike_time": 7.0, "attack": feint}))
	_expect(errs, beeper.scheduled_count() == 0, "헛손질의 걸음에 바람이 예약됐다")
	var sweep := AttackData.new()
	sweep.sweep = true
	beeper.on_event(_ev(DuelRecord.PATTERN_STEP, {"t": 6.0, "strike_time": 7.0, "attack": AttackData.new(), "root": sweep}))
	_expect(errs, beeper.scheduled_count() == 0, "휩쓸기의 둘째 점에 바람이 예약됐다")
	beeper.on_event(_ev(DuelRecord.TELL_START, {"t": 8.0, "strike_time": 8.05, "attack": AttackData.new()}))
	_expect(errs, beeper.scheduled_count() == 0, "이미 지난 시각의 바람이 예약됐다")
	# 비움: 무너짐·끝·새 판은 모두, 밀려남은 내 휙만
	beeper.on_event(tell)
	beeper.on_event(_ev(DuelRecord.STAGGER_START))
	_expect(errs, beeper.scheduled_count() == 0, "STAGGER_START가 예약을 지우지 않았다")
	beeper.on_event(tell)
	beeper.on_event(_ev(DuelRecord.END))
	_expect(errs, beeper.scheduled_count() == 0, "END가 예약을 지우지 않았다")
	beeper.on_event(tell)
	beeper.on_event(_ev(DuelRecord.ATTACK_START, {"t": 4.0, "judge_time": 4.2, "direction": DT.Direction.CENTER}))
	_expect(errs, beeper.scheduled_count() == 2, "상대 바람과 내 휙이 함께 예약돼야 한다")
	beeper.on_event(_ev(DuelRecord.SHOVE, {"cancelled_attack": true}))
	_expect(errs, beeper.scheduled_count() == 1, "SHOVE는 내 휙만 지워야 한다")
	beeper.clear()
	_expect(errs, beeper.scheduled_count() == 0, "clear()가 예약을 지우지 않았다")


func _pitch_ratio(beeper: Beeper, steps: int) -> float:
	return float(beeper.history[-1][1]) / pow(2.0, 2.0 * steps / 12.0)


func _check_climb(errs: Array[String]) -> void:
	var beeper := Beeper.new()
	_tree.root.add_child(beeper)
	_made.append(beeper)
	beeper.record = true
	var tell := _ev(DuelRecord.TELL_START, {"t": 0.0, "strike_time": 1.0, "attack": AttackData.new()})
	beeper.on_event(tell)
	var ladder := [_strike(SR.BLOCKED), _strike(SR.PARRIED, {"next_strike": 1.0}), _strike(SR.PARRIED, {"next_strike": 1.0}), _strike(SR.PARRIED)]
	for n in ladder.size():
		beeper.on_event(ladder[n])
		var ratio := _pitch_ratio(beeper, n)
		_expect(errs, absf(ratio - 1.0) <= 0.032, "받아낸 수 %d의 음높이 비 %.3f가 2반음 x n에서 벗어났다" % [n, ratio])
	beeper.on_event(_strike(SR.BLOCKED))
	_expect(errs, absf(_pitch_ratio(beeper, 3) - 1.0) <= 0.032, "다섯째 음은 셋째 걸음에서 멈춰야 한다")
	beeper.on_event(_strike(SR.BLOCKED, {"closed": true}))
	_expect(errs, beeper.history[-1][0] == &"closed" and beeper.history[-1][1] == 1.0, "받아낸 수 3의 closed가 1.0이 아니다")
	beeper.on_event(_ev(DuelRecord.FEINT, {"bitten": true}))
	_expect(errs, beeper.history[-1][0] == &"bitten" and beeper.history[-1][1] == 1.0, "받아낸 수 3의 bitten이 1.0이 아니다")
	beeper.on_event(tell)
	beeper.on_event(_strike(SR.BLOCKED))
	_expect(errs, absf(_pitch_ratio(beeper, 0) - 1.0) <= 0.032, "TELL_START가 오르는 음을 되돌리지 않았다")
	beeper.on_event(_strike(SR.BLOCKED))
	beeper.on_event(_strike(SR.GRAZE))
	beeper.on_event(_strike(SR.BLOCKED))
	_expect(errs, absf(_pitch_ratio(beeper, 0) - 1.0) <= 0.032, "맞으면 오르는 음이 처음으로 돌아가야 한다")
	# 변주는 0.97~1.03 안이고 tell·closed에는 없다
	var spread := {}
	for i in 12:
		beeper.on_event(_strike(SR.GRAZE))
		var pitch: float = beeper.history[-1][1]
		spread[snappedf(pitch, 0.0001)] = true
		_expect(errs, pitch >= 0.97 and pitch <= 1.03, "graze_taken 변주 %.4f가 0.97~1.03 밖" % pitch)
		beeper.on_event(tell)
		_expect(errs, beeper.history[-1][0] == &"tell" and beeper.history[-1][1] == 1.0, "tell에 변주가 걸렸다")
		beeper.on_event(_strike(SR.BLOCKED, {"closed": true}))
		_expect(errs, beeper.history[-1][1] == 1.0, "closed에 변주가 걸렸다")
	_expect(errs, spread.size() > 1, "같은 소리가 되풀이돼도 음높이가 늘 같다(변주가 없다)")
	# on_event(ev)는 둘째 인자 없이도 돈다
	beeper.on_event(_strike(SR.BLOCKED))
