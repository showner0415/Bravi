class_name SoundSynth
extends RefCounted
## 소리의 합성(계획 H03 결정 939). 조리법 하나를 층(트랜지언트·잡음·몸통·울림·바람)으로 더해 표본을 만든다.
## 판정에는 관여하지 않는다. 잡음은 조리법의 시드로 뽑아 같은 조리법은 늘 같은 표본이다.
## 감쇠의 뜻: 길이 ms는 진폭이 -30dB(약 3%)로 떨어지는 시각이다(t10은 그 3분의 2쯤). 이름을 바꾸면 T217이 깨진다.

const DECAY := 3.45
const FADE_MS := 5.0
## 띠통과 잡음은 진폭이 작아 다른 층과 맞추려고 키운다.
const WIND_GAIN := 3.0
const BAND_SPREAD := 1.5
const TRANSIENT_DECAY := 2.0
const TRANSIENT_SPAN := 2.0


## 조리법의 전체 길이(ms).
static func length_ms(recipe: Dictionary) -> float:
	var ms := 0.0
	if recipe.has("t"):
		ms = maxf(ms, TRANSIENT_SPAN * float(recipe["t"]["ms"]))
	for layer: String in ["n", "b", "r", "w"]:
		if recipe.has(layer):
			ms = maxf(ms, float(recipe[layer]["ms"]))
	return ms


## 조리법 -> 표본(-gain~gain). recipe의 층: t(트랜지언트) n(잡음) b(몸통) r(울림) w(바람), gain, seed.
static func render(recipe: Dictionary, rate: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(recipe.get("seed", 1))
	var count := int(rate * length_ms(recipe) / 1000.0)
	var out := PackedFloat32Array()
	out.resize(count)
	if recipe.has("t"):
		var t: Dictionary = recipe["t"]
		_add_noise(out, rate, rng, float(t["ms"]) * TRANSIENT_SPAN, TRANSIENT_DECAY,
				float(t.get("amp", 2.0)), float(t.get("hp", 1500.0)), 0.0)
	if recipe.has("n"):
		var n: Dictionary = recipe["n"]
		_add_noise(out, rate, rng, float(n["ms"]), DECAY, float(n.get("amp", 1.0)),
				float(n.get("hp", 0.0)), float(n.get("lp", 0.0)))
	if recipe.has("b"):
		_add_body(out, rate, recipe["b"])
	if recipe.has("r"):
		_add_ring(out, rate, recipe["r"])
	if recipe.has("w"):
		_add_wind(out, rate, rng, recipe["w"])
	return _finish(out, rate, float(recipe.get("gain", 0.3)))


## 잡음 한 층. span_ms 끝에서 진폭이 e^-decay_k 배가 된다.
static func _add_noise(out: PackedFloat32Array, rate: int, rng: RandomNumberGenerator, span_ms: float,
		decay_k: float, amp: float, hp: float, lp: float) -> void:
	var n := mini(out.size(), int(rate * span_ms / 1000.0))
	var dt := 1.0 / rate
	var hp_alpha := 0.0
	if hp > 0.0:
		var rc_hp := 1.0 / (TAU * hp)
		hp_alpha = rc_hp / (rc_hp + dt)
	var lp_alpha := 1.0
	if lp > 0.0:
		var rc_lp := 1.0 / (TAU * lp)
		lp_alpha = dt / (rc_lp + dt)
	var prev_x := 0.0
	var hp_y := 0.0
	var lp_y := 0.0
	for i in n:
		var x := rng.randf() * 2.0 - 1.0
		var y := x
		if hp > 0.0:
			hp_y = hp_alpha * (hp_y + x - prev_x)
			y = hp_y
		prev_x = x
		if lp > 0.0:
			lp_y += lp_alpha * (y - lp_y)
			y = lp_y
		out[i] += amp * y * exp(-decay_k * float(i) * 1000.0 / (rate * span_ms))


## 몸통: f0에서 f1로 내려앉는 사인. shape가 flat이면 앞 70%를 고르게 두고 끝에서 줄어든다(예비 동작음).
static func _add_body(out: PackedFloat32Array, rate: int, b: Dictionary) -> void:
	var ms := float(b["ms"])
	var f0 := float(b["f0"])
	var f1 := float(b["f1"])
	var amp := float(b.get("amp", 1.0))
	var attack := maxf(float(b.get("att", 2.0)), 0.1)
	var h2 := float(b.get("h2", 0.0))
	var flat: bool = b.get("shape", "decay") == "flat"
	var n := mini(out.size(), int(rate * ms / 1000.0))
	var phase := 0.0
	for i in n:
		var t := float(i) * 1000.0 / rate
		phase += TAU * (f1 + (f0 - f1) * exp(-DECAY * t / ms)) / rate
		var env := exp(-DECAY * t / ms)
		if flat:
			env = 1.0 if t < 0.7 * ms else 0.5 + 0.5 * cos(PI * (t - 0.7 * ms) / (0.3 * ms))
		out[i] += amp * env * minf(1.0, t / attack) * (sin(phase) + h2 * sin(2.0 * phase))


## 울림: 기음 x 비율들의 부분음. 높은 부분음일수록 작고 빨리 죽는다(비조화는 비율이 정수가 아닌 데서 온다).
static func _add_ring(out: PackedFloat32Array, rate: int, r: Dictionary) -> void:
	var ratios: Array = r["ratios"]
	for k in ratios.size():
		var freq := float(r["f"]) * float(ratios[k])
		if freq >= rate * 0.45:
			continue
		var amp := float(r.get("amp", 0.5)) / (1.0 + 0.5 * k)
		var ms := float(r["ms"]) / (1.0 + 0.4 * k)
		var n := mini(out.size(), int(rate * ms / 1000.0))
		for i in n:
			var t := float(i) * 1000.0 / rate
			out[i] += amp * exp(-DECAY * t / ms) * minf(1.0, t / 0.3) * sin(TAU * freq * float(i) / rate)


## 바람: 띠통과 잡음. 가운데 주파수가 f 목록(로그로 이은 꺾은선)을 따라 쓸고, 음량은 peak(0~1)에서 가장 크다.
static func _add_wind(out: PackedFloat32Array, rate: int, rng: RandomNumberGenerator, w: Dictionary) -> void:
	var freqs: Array = w["f"]
	var amp := float(w.get("amp", 1.0))
	var peak := clampf(float(w.get("peak", 0.5)), 0.05, 0.95)
	var n := mini(out.size(), int(rate * float(w["ms"]) / 1000.0))
	var hi := 0.0
	var lo := 0.0
	var segs := freqs.size() - 1
	for i in n:
		var u := float(i) / maxf(float(n - 1), 1.0)
		var s := u * segs
		var seg := mini(int(s), segs - 1)
		var fc := exp(lerpf(log(float(freqs[seg])), log(float(freqs[seg + 1])), s - seg))
		var x := rng.randf() * 2.0 - 1.0
		hi += (1.0 - exp(-TAU * fc * BAND_SPREAD / rate)) * (x - hi)
		lo += (1.0 - exp(-TAU * fc / BAND_SPREAD / rate)) * (x - lo)
		var env := sin((PI * 0.5) * u / peak) if u < peak else cos((PI * 0.5) * (u - peak) / (1.0 - peak))
		out[i] += WIND_GAIN * amp * env * (hi - lo)


## 끝 5ms를 줄이고 봉우리를 gain에 맞춘다.
static func _finish(out: PackedFloat32Array, rate: int, gain: float) -> PackedFloat32Array:
	var fade := mini(out.size(), int(rate * FADE_MS / 1000.0))
	for j in fade:
		out[out.size() - fade + j] *= 1.0 - float(j + 1) / fade
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		var scale := gain / peak
		for i in out.size():
			out[i] *= scale
	return out
