extends RefCounted
## 헤진 가장자리의 바깥 꼴(계획 033b, 결정 498). 판의 크기·단계·씨앗(판의 고정된 이름의 해시)으로만 정한다 — 화면 위치·형제 순서를 쓰면 판이 움직일 때 찢김이 떨린다.
## 어느 판이 헤지는지는 `pick`이 화면 단위로 정한다(화면의 UI 창 가운데 30%).

const MIN_SIDE := 160.0
const SHARE := 0.3
const STEP := 3.0
## 변의 헤짐·찢김은 모서리 자름(≤ 28)과 겹치지 않게 양 끝에서 이만큼 띄운다.
const END_GAP := 32.0
const SIDE_D := [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
const SIDE_N := [Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)]

static var _cache := {}


## 판의 바깥 꼴(판 안의 좌표, 시계 방향 단순 다각형). 자름이 없으면 네 꼭짓점.
static func outline(size: Vector2, level: int, seed_value: int) -> PackedVector2Array:
	return _build(size, level, seed_value)["outline"]


## 자름마다 {"kind": fray|tear|worn|drop, "box": Rect2, "points": PackedVector2Array}.
static func cuts(size: Vector2, level: int, seed_value: int) -> Array:
	return _build(size, level, seed_value)["cuts"]


## [0,1) 해시: 이름이 같으면 어느 실행에서도 같다.
static func hash01(s: String) -> float:
	return float(s.hash() & 0xFFFFFF) / 16777216.0


static func hash_int(s: String) -> int:
	return s.hash() & 0x7FFFFFFF


## 한 화면의 판들 가운데 헤질 판의 번호들. n = ids.size()(UI 창 전부), k = floor(0.3n + u)(u는 화면 키의 해시: 고정된 확률적 반올림),
## 헤질 수 없는 판은 고르지 않고 h가 작은 순서로 k개(자격 있는 판이 k보다 적으면 그만큼만).
static func pick(ids: PackedStringArray, eligible: Array[bool], screen_key: String) -> PackedInt32Array:
	var k := int(floor(SHARE * ids.size() + hash01(screen_key)))
	var order: Array = []
	for i in ids.size():
		if i < eligible.size() and eligible[i]:
			order.append([hash01(screen_key + "|" + ids[i]), i])
	order.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var result := PackedInt32Array()
	for j in mini(k, order.size()):
		result.append(order[j][1])
	return result


static func _build(size: Vector2, level: int, seed_value: int) -> Dictionary:
	if level <= 0 or minf(size.x, size.y) < MIN_SIDE:
		return {"outline": PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), "cuts": []}
	var key := "%.2f,%.2f,%d,%d" % [size.x, size.y, level, seed_value]
	if _cache.has(key):
		return _cache[key]
	var lv := clampi(level, 1, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(size, lv, seed_value)
	# 헤지기로 뽑힌 판은 1~3곳(단계가 낮으면 단계까지).
	var count := rng.randi_range(1, lv)
	var slots := [0, 1, 2, 3, 4, 5, 6, 7]
	for i in range(slots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = slots[i]
		slots[i] = slots[j]
		slots[j] = tmp
	var corner_kind := ["", "", "", ""]
	var edge_kind := ["", "", "", ""]
	var tear_used := false
	var drop_used := false
	for n in count:
		var slot: int = slots[n]
		if slot < 4:
			if lv >= 2 and not drop_used and rng.randf() < 0.4:
				corner_kind[slot] = "drop"
				drop_used = true
			else:
				corner_kind[slot] = "worn"
		else:
			if lv >= 2 and not tear_used and rng.randf() < 0.4:
				edge_kind[slot - 4] = "tear"
				tear_used = true
			else:
				edge_kind[slot - 4] = "fray"
	var starts := [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]
	var lens := [size.x, size.y, size.x, size.y]
	var pts := PackedVector2Array()
	var cut_list := []
	for i in 4:
		var p0: Vector2 = starts[i]
		var d: Vector2 = SIDE_D[i]
		var nrm: Vector2 = SIDE_N[i]
		if corner_kind[i] == "":
			pts.append(p0)
		else:
			var chain := _worn_corner(rng, p0, d, nrm) if corner_kind[i] == "worn" else _drop_corner(rng, p0, d, nrm)
			pts.append_array(chain)
			cut_list.append({"kind": corner_kind[i], "box": _box(chain, p0), "points": chain})
		if edge_kind[i] != "":
			var chain := _edge(rng, edge_kind[i], p0, d, nrm, lens[i])
			if chain.size() > 1:
				pts.append_array(chain)
				cut_list.append({"kind": edge_kind[i], "box": _box(chain, chain[0]), "points": chain})
	var result := {"outline": pts, "cuts": cut_list}
	_cache[key] = result
	return result


static func _mix(size: Vector2, level: int, seed_value: int) -> int:
	return (roundi(size.x) * 73856093) ^ (roundi(size.y) * 19349663) ^ (level * 2654435761) ^ (seed_value * 40503 + 977)


static func _box(chain: PackedVector2Array, first: Vector2) -> Rect2:
	var box := Rect2(first, Vector2.ZERO)
	for p in chain:
		box = box.expand(p)
	return box


# 모서리의 둥글고 거친 자름: 반지름은 안쪽으로만 흔들려 점이 사각형 밖으로 나가지 않는다.
static func _worn_corner(rng: RandomNumberGenerator, p0: Vector2, d: Vector2, n: Vector2) -> PackedVector2Array:
	var r := rng.randf_range(6.0, 12.0)
	var c := p0 + (d + n) * r
	var steps := maxi(4, ceili(r * PI * 0.5 / STEP))
	var chain := PackedVector2Array()
	for k in steps + 1:
		var phi := PI * 0.5 * float(k) / steps
		var rr := r if k == 0 or k == steps else r * (1.0 - 0.15 * rng.randf())
		chain.append(c - d * rr * cos(phi) - n * rr * sin(phi))
	return chain


# 떨어진 모서리: 두 다리를 잇는 거친 사선. 흔들림은 모서리 쪽으로만(x + y ≤ 28을 지킨다).
static func _drop_corner(rng: RandomNumberGenerator, p0: Vector2, d: Vector2, n: Vector2) -> PackedVector2Array:
	var a := rng.randf_range(12.0, 28.0)
	var b := rng.randf_range(12.0, 28.0)
	var from := p0 + n * a
	var to := p0 + d * b
	var m := maxi(3, ceili(from.distance_to(to) / STEP))
	var chain := PackedVector2Array()
	for k in m + 1:
		var t := float(k) / m
		var jitter := 0.0 if k == 0 or k == m else 3.0 * rng.randf() * sin(PI * t)
		chain.append(from.lerp(to, t) - (d + n) * (jitter * 0.7071))
	return chain


# 변의 한 토막: 양 끝은 변 위(깊이 0)에서 시작하고 끝난다. 큰 굽이와 잔 떨림을 섞는다(R10).
static func _edge(rng: RandomNumberGenerator, kind: String, p0: Vector2, d: Vector2, n: Vector2, side_len: float) -> PackedVector2Array:
	var chain := PackedVector2Array()
	var span := side_len - 2.0 * END_GAP
	var length := rng.randf_range(60.0, 160.0) if kind == "fray" else rng.randf_range(14.0, 36.0)
	length = minf(length, span)
	var max_depth := rng.randf_range(1.0, 4.0) if kind == "fray" else rng.randf_range(5.0, 10.0)
	var phase := rng.randf() * TAU
	var freq := rng.randf_range(1.5, 2.5)
	if length < 12.0:
		return chain
	var center := rng.randf_range(END_GAP + length * 0.5, side_len - END_GAP - length * 0.5)
	var s0 := center - length * 0.5
	var step := STEP if kind == "fray" else 2.0
	var m := maxi(4, ceili(length / step))
	for k in m + 1:
		var u := float(k) / m
		var depth := 0.0
		if k != 0 and k != m:
			if kind == "fray":
				var wave := 0.5 + 0.5 * sin(phase + u * TAU * freq)
				depth = max_depth * pow(sin(PI * u), 0.6) * clampf(0.35 + 0.4 * wave + 0.3 * rng.randf(), 0.0, 1.0)
			else:
				depth = max_depth * pow(1.0 - absf(2.0 * u - 1.0), 0.7) * (0.75 + 0.25 * rng.randf())
		chain.append(p0 + d * (s0 + length * u) + n * depth)
	return chain
