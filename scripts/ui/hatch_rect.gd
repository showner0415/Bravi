extends Control
## 평행 빗금을 채운 사각형(바이블 6절 "빗금은 띠로만"). 견본 hatchBg의 값: 간격 6, −35°, 굵기 1.1.

const SPACING := 6.0
const WIDTH := 1.1
## 견본의 무늬는 세로 줄을 −35° 돌린 것이라 줄이 오른쪽 아래로 눕는다.
const DIRECTION := Vector2(0.573576, 0.819152)

var color := Color("6B5440", 0.5)


func _ready() -> void:
	clip_contents = true


func _draw() -> void:
	var normal := Vector2(DIRECTION.y, -DIRECTION.x)
	var corners := [Vector2.ZERO, Vector2(size.x, 0), Vector2(0, size.y), size]
	var low := INF
	var high := -INF
	for corner in corners:
		low = minf(low, normal.dot(corner))
		high = maxf(high, normal.dot(corner))
	var reach := size.length()
	var k := floorf(low / SPACING) * SPACING
	while k <= high:
		var origin := normal * k
		draw_line(origin - DIRECTION * reach, origin + DIRECTION * reach, color, WIDTH, true)
		k += SPACING
