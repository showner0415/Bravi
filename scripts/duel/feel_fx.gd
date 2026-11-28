class_name FeelFx
extends Node2D
## 맞음의 화면과 작은 것(계획 H03 결정 942·945): 비네트, 불꽃·닿은 표시·막힘의 꺾쇠, 잔상.
## 살아 있는 판(DuelScene._engine_tick)에서만 걸리고, 시계는 update_view가 받은 delta뿐이다 — 멈칫·멈춤 동안 서고 실제 시각은 쓰지 않는다(결정 928).
## 시작 시각은 이벤트 뒤 첫 update_view가 받은 시계다(결정 928 m4). 새 뜻의 색은 상아색 하나이고 비네트는 화풍의 선 색이다.

const IVORY := Color(1.0, 0.96, 0.84)
const VIGNETTE_COLOR := Color("3B2A1E")
const SIDE_LEFT := 0
const SIDE_RIGHT := 1
const SIDE_TOP := 2
const SIDE_BOTTOM := 3
const VIGNETTE_WIDTH := 110.0
const EDGE_HIT := 0.42
const EDGE_OTHER := 0.20
const HIT_GAIN := 1.3
const VIGNETTE_FILL := 2.0 / 60.0
const VIGNETTE_TIME := 0.35
const SPARK_TIME := 0.12
const SPARK_WIDTH := 3.0
const TRAIL_TIME := 0.10
const TRAIL_ALPHA := 0.5
const TRAIL_KEEP := 4
const FAN_LEN := [36.0, 56.0]
const FAN_COUNT := [5, 8]
const FAN_SPREAD := [0.7, 0.9]
const KINK_BACK := 24.0
const KINK_LEN := [18.0, 24.0]
const KINK_SPREAD := 0.45
const BURST_LEN := [22.0, 38.0]
const TICK_LEN := [14.0, 20.0]
const BLADE_FORTE := 0.25
const BLADE_MID := 0.55

var _clock := 0.0
var _vig_pending := false
var _vig_start := -INF
var _vig_side := -1
var _vig_gain := 1.0
## 불꽃 묶음: {"lines": Array[Dictionary], "start": float(-INF이면 다음 갱신이 잡는다)}. 줄: {"from", "to", "kind"}.
var _sparks: Array[Dictionary] = []
var _trails: Array[Dictionary] = []
var _samples: Array[Vector2] = []
## 닿은 표시의 마지막 자리와 칼이 온 길(테스트가 앞·뒤 반평면을 잰다).
var contact := Vector2.ZERO
var path_dir := Vector2.UP


func _init() -> void:
	z_index = 8


func clear() -> void:
	_vig_pending = false
	_vig_start = -INF
	_vig_side = -1
	_sparks.clear()
	_trails.clear()
	_samples.clear()
	queue_redraw()


## 칼끝 자리를 모은다(예비 동안만). tip이 INF면 모은 것을 비운다.
func update_view(delta: float, tip := Vector2.INF) -> void:
	_clock += delta
	if tip.is_finite():
		if delta > 0.0:
			_samples.append(tip)
			while _samples.size() > TRAIL_KEEP + 1:
				_samples.pop_front()
	else:
		_samples.clear()
	if _vig_pending:
		_vig_pending = false
		_vig_start = _clock
	for group in _sparks:
		if group["start"] == -INF:
			group["start"] = _clock
	for trail in _trails:
		if trail["start"] == -INF:
			trail["start"] = _clock
	_sparks = _alive(_sparks, SPARK_TIME)
	_trails = _alive(_trails, TRAIL_TIME)
	if _vig_start != -INF and _clock - _vig_start >= VIGNETTE_TIME:
		_vig_start = -INF
	queue_redraw()


## 이벤트 하나를 화면 효과로 옮긴다. 엔진의 걸음에서만 부른다.
func on_event(ev: Dictionary, sword: PlayerSwordView) -> void:
	var type: StringName = ev.get("type", &"")
	if type == DuelRecord.ATTACK:
		_on_attack(ev, sword)
	elif type == DuelRecord.STRIKE:
		_on_strike(ev, sword)


func _on_attack(ev: Dictionary, sword: PlayerSwordView) -> void:
	if bool(ev.get("dodged", false)):
		return
	add_afterimage(int(ev.get("direction", 1)) != 1)
	var result: int = ev.get("result", -1)
	var tip := sword.tip_global()
	var dir := (tip - sword.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	if result == DuelTypes.AttackResult.GRAZE or result == DuelTypes.AttackResult.HIT:
		fan(tip, dir, result == DuelTypes.AttackResult.HIT)
	elif result == DuelTypes.AttackResult.BLOCKED:
		kink(tip, dir)


func _on_strike(ev: Dictionary, sword: PlayerSwordView) -> void:
	var result: int = ev.get("result", -1)
	var attack: Variant = ev.get("attack")
	var direction: int = (attack as AttackData).direction if attack is AttackData else DuelTypes.Direction.CENTER
	# 안 열린 막기·패리와 버티기에는 열림의 표지를 주지 않는다: 쥐고 막음의 작은 불꽃이다(결정 947).
	var shut := bool(ev.get("closed", false)) or bool(ev.get("bitten", false)) or bool(ev.get("braced", false))
	match result:
		DuelTypes.StrikeResult.PARRIED:
			if shut:
				ticks(sword.blade_point(BLADE_MID), away_of(direction))
			else:
				burst(sword.blade_point(BLADE_FORTE))
		DuelTypes.StrikeResult.BLOCKED:
			ticks(sword.blade_point(BLADE_MID), away_of(direction))
		DuelTypes.StrikeResult.GRAZE, DuelTypes.StrikeResult.HIT:
			vignette(side_of(direction), result == DuelTypes.StrikeResult.HIT)


## 맞은 쪽 가장자리: 왼쪽·오른쪽 타격은 그쪽, 찌르기는 아래(킥이 +y인 쪽).
static func side_of(direction: int) -> int:
	match direction:
		DuelTypes.Direction.LEFT:
			return SIDE_LEFT
		DuelTypes.Direction.RIGHT:
			return SIDE_RIGHT
	return SIDE_BOTTOM


## 막은 칼에서 불꽃이 튀는 쪽: 타격이 온 쪽의 반대(찌르기는 위).
static func away_of(direction: int) -> Vector2:
	match direction:
		DuelTypes.Direction.LEFT:
			return Vector2.RIGHT
		DuelTypes.Direction.RIGHT:
			return Vector2.LEFT
	return Vector2.UP


func vignette(side: int, strong: bool) -> void:
	_vig_side = side
	_vig_gain = HIT_GAIN if strong else 1.0
	_vig_pending = true
	_vig_start = -INF


## 가장자리 하나의 지금 알파. 맞은 쪽이 더 짙고 차오름(2 tick)과 빠짐(0.35초)이 곱해진다.
func edge_alpha(side: int) -> float:
	if _vig_side < 0 or _vig_start == -INF:
		return 0.0
	var k := _clock - _vig_start
	if k < 0.0 or k >= VIGNETTE_TIME:
		return 0.0
	var rise := clampf((k + VIGNETTE_FILL * 0.5) / VIGNETTE_FILL, 0.0, 1.0)
	var fade := 1.0 - k / VIGNETTE_TIME
	return (EDGE_HIT if side == _vig_side else EDGE_OTHER) * _vig_gain * minf(rise, fade)


## 닿은 표시: 접촉점에서 칼이 간 방향으로 뚫고 나가는 부채. 스침 5줄(36px), 유효타 8줄(56px).
func fan(point: Vector2, dir: Vector2, strong: bool) -> void:
	var i := 1 if strong else 0
	contact = point
	path_dir = dir
	var lines: Array[Dictionary] = []
	var count: int = FAN_COUNT[i]
	for n in count:
		var angle := lerpf(-FAN_SPREAD[i], FAN_SPREAD[i], float(n) / float(count - 1))
		var length: float = FAN_LEN[i] * (1.0 if n % 2 == 0 else 0.7)
		lines.append({"from": point, "to": point + dir.rotated(angle) * length, "kind": &"fan"})
	_add_sparks(lines)


## 막힘·송곳: 칼끝이 튕겨 난 자리에서 손 쪽으로 벌어지는 꺾쇠 2줄. 부위의 번쩍임은 없다.
func kink(point: Vector2, dir: Vector2) -> void:
	contact = point
	path_dir = dir
	var origin := point - dir * KINK_BACK
	var lines: Array[Dictionary] = []
	for n in 2:
		var angle := KINK_SPREAD if n == 0 else -KINK_SPREAD
		lines.append({"from": origin, "to": origin + (-dir).rotated(angle) * KINK_LEN[n], "kind": &"kink"})
	_add_sparks(lines)


## 패리: 날밑에서 25% 자리의 사방 8줄.
func burst(point: Vector2) -> void:
	var lines: Array[Dictionary] = []
	for n in 8:
		var unit := Vector2.RIGHT.rotated(TAU * float(n) / 8.0)
		var length: float = BURST_LEN[n % 2]
		lines.append({"from": point + unit * 6.0, "to": point + unit * length, "kind": &"burst"})
	_add_sparks(lines)


## 쥐고 막음: 칼날 55% 자리에서 타격 반대쪽으로 작은 4줄.
func ticks(point: Vector2, away: Vector2) -> void:
	var lines: Array[Dictionary] = []
	for n in 4:
		var angle := lerpf(-0.6, 0.6, float(n) / 3.0)
		var length: float = TICK_LEN[n % 2]
		lines.append({"from": point, "to": point + away.rotated(angle) * length, "kind": &"tick"})
	_add_sparks(lines)


func _add_sparks(lines: Array[Dictionary]) -> void:
	_sparks.append({"lines": lines, "start": -INF})
	queue_redraw()


## 잔상: 모은 칼끝 자리의 마지막 4개를 잇는다. 베기는 호, 찌르기는 곧은 줄(처음과 끝).
func add_afterimage(is_slash: bool) -> void:
	if _samples.size() < 2:
		return
	var points: Array[Vector2] = []
	var first := maxi(_samples.size() - TRAIL_KEEP, 0)
	for i in range(first, _samples.size()):
		points.append(_samples[i])
	if not is_slash:
		points = [points[0], points[-1]]
	_trails.append({"points": points, "start": -INF})


## 아직 살아 있는 불꽃의 줄(테스트가 센다). 아직 시작을 못 잡은 묶음도 센다.
func live_lines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for group in _sparks:
		if group["start"] == -INF or _clock - float(group["start"]) < SPARK_TIME:
			out.append_array(group["lines"])
	return out


func live_trails() -> int:
	return _trails.size()


func _draw() -> void:
	_draw_vignette()
	for group in _sparks:
		if group["start"] == -INF:
			continue
		var alpha := 1.0 - (_clock - float(group["start"])) / SPARK_TIME
		for line: Dictionary in group["lines"]:
			draw_line(line["from"], line["to"], Color(VIGNETTE_COLOR, 0.5 * alpha), SPARK_WIDTH + 2.0)
			draw_line(line["from"], line["to"], Color(IVORY, alpha), SPARK_WIDTH)
	for trail in _trails:
		if trail["start"] == -INF:
			continue
		var fade := 1.0 - (_clock - float(trail["start"])) / TRAIL_TIME
		var points: Array = trail["points"]
		for i in range(1, points.size()):
			var width := 1.0 + 5.0 * float(i) / float(points.size() - 1)
			draw_line(points[i - 1], points[i], Color(IVORY, TRAIL_ALPHA * fade), width)


func _draw_vignette() -> void:
	var size := get_viewport_rect().size
	var w := VIGNETTE_WIDTH
	for side in 4:
		var a := edge_alpha(side)
		if a <= 0.0:
			continue
		var strong := Color(VIGNETTE_COLOR, a)
		var faded := Color(VIGNETTE_COLOR, 0.0)
		var quad: PackedVector2Array
		match side:
			SIDE_LEFT:
				quad = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, size.y), Vector2(0, size.y)])
				draw_polygon(quad, PackedColorArray([strong, faded, faded, strong]))
			SIDE_RIGHT:
				quad = PackedVector2Array([Vector2(size.x, 0), Vector2(size.x - w, 0), Vector2(size.x - w, size.y), Vector2(size.x, size.y)])
				draw_polygon(quad, PackedColorArray([strong, faded, faded, strong]))
			SIDE_TOP:
				quad = PackedVector2Array([Vector2(0, 0), Vector2(0, w), Vector2(size.x, w), Vector2(size.x, 0)])
				draw_polygon(quad, PackedColorArray([strong, faded, faded, strong]))
			SIDE_BOTTOM:
				quad = PackedVector2Array([Vector2(0, size.y), Vector2(0, size.y - w), Vector2(size.x, size.y - w), Vector2(size.x, size.y)])
				draw_polygon(quad, PackedColorArray([strong, faded, faded, strong]))


func _alive(groups: Array[Dictionary], life: float) -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	for group in groups:
		if _clock - float(group["start"]) < life:
			kept.append(group)
	return kept
